#!/bin/bash

# Script de génération des tuiles PBF pour servir les noms de communes avec leur code INSEE
# Totalement inspiré de https://blog.jawg.io/how-to-make-mvt-with-postgis/ <3

set -e

function admin() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'centroides_communes', 4096, 'geom')
FROM ( SELECT code_insee,
              nom, 
              CASE
                   WHEN population_rel > 100000 THEN 1
                   WHEN code_insee LIKE '97%' THEN 1
                   WHEN population_rel >  50000 THEN 2
                   WHEN population_rel >  10000 THEN 3
                   ELSE 4
              END AS class_pop,
              nb_adresses_osm,
              nb_adresses_ban,
              nb_noms_osm,
              nb_noms_ban,
              nb_noms_topo,
              ST_AsMvtGeom(
                geom_centroide_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
  FROM polygones_insee
  JOIN (SELECT DISTINCT \"ref:INSEE\" AS code_insee,
                        population_rel
       FROM             planet_osm_communes_statut
       WHERE            \"ref:INSEE\" != '') p
  USING (code_insee)
  JOIN (SELECT code_insee,
               CASE
                   WHEN nb_adresses_ban > 0 THEN nb_adresses_osm * 25 / nb_adresses_ban
                   ELSE 50
               END AS ratio_adresses,
               CASE
                   WHEN nb_nom_topo > 0 THEN nb_nom_osm * 75 / nb_nom_topo
                   ELSE 50
               END AS ratio_noms,
              nb_adresses_osm,
              GREATEST(1,nb_adresses_ban) AS nb_adresses_ban,
              nb_nom_osm AS nb_noms_osm,
              GREATEST(1,nb_nom_ban) AS nb_noms_ban,
              GREATEST(1,nb_nom_topo) AS nb_noms_topo
        FROM bano_stats_communales) AS s
  USING (code_insee)
  JOIN (SELECT com
       FROM    cog_commune
       WHERE   typecom IN ('COM','ARM')) cog
  ON   (code_insee = com)
  WHERE geom_centroide_3857 && BBox($tx, $ty, $tz) AND
        ST_Intersects(geom_centroide_3857, BBox($tx, $ty, $tz)) AND
        code_insee != '' AND
        ((admin_level = 8 AND code_insee NOT IN ('13055','69123','75056')) OR
         (admin_level = 9 AND (code_insee LIKE '751__' OR code_insee LIKE '6938_' OR code_insee LIKE '132__')))
    ) AS q
  ) TO STDOUT;
  "
}

function lieudit_CADASTRE() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'lieudit_CADASTRE', 4096, 'geom')
FROM (
      WITH 
      cadastre
      AS
      (SELECT code_insee,fantoir,nom,geometrie_3857
      FROM    bano_points_nommes
      WHERE   ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz)) AND
              source = 'CADASTRE'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM cadastre),
      fantoir_osm
      AS
      (SELECT DISTINCT fantoir
      FROM  bano_points_nommes
      JOIN liste_insee
      USING (code_insee)
      WHERE source = 'OSM'),
      resultat
      as
      (SELECT nom,
              fantoir,
              CASE WHEN fantoir_osm.fantoir IS NULL THEN false ELSE true END rapproche,
              geometrie_3857
      FROM    cadastre
      LEFT OUTER JOIN fantoir_osm
      USING (fantoir))
      SELECT nom,
             fantoir,
             rapproche,
             ST_AsMvtGeom(
                 geometrie_3857,
                 BBox($tx, $ty, $tz),
                 4096,
                 256,
                 true) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz))
) AS q
  ) TO STDOUT;
  "
}

function place_OSM() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'place_OSM', 4096, 'geom')
FROM (
      WITH 
      osm
      AS
      (SELECT code_insee,fantoir,nom,geometrie_3857
      FROM    bano_points_nommes
      WHERE   ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz)) AND
              nature = 'place' AND
              source = 'OSM'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM osm),
      fantoir
      AS
      (SELECT DISTINCT fantoir
      FROM  bano_points_nommes
      JOIN liste_insee
      USING (code_insee)
      WHERE source != 'OSM'),
      resultat
      as
      (SELECT nom,
              fantoir,
              CASE WHEN fantoir.fantoir IS NULL THEN false ELSE true END rapproche,
              geometrie_3857
      FROM    osm
      LEFT OUTER JOIN fantoir
      USING (fantoir))
      SELECT nom,
             fantoir,
             rapproche,
             ST_AsMvtGeom(
                 geometrie_3857,
                 BBox($tx, $ty, $tz),
                 4096,
                 256,
                 true) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz))
) AS q
  ) TO STDOUT;
  "
}

function num_convex() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'polygones_convexhull', 4096, 'geom')
FROM (
      with
      liste_insee
      as
      (SELECT DISTINCT code_insee
      from bano_adresses
      WHERE ST_Intersects(geometrie_3857,ST_Buffer(BBox($tx, $ty, $tz),1000,2)) AND
            source = 'BAN'),
      fantoir
      as
      (SELECT fantoir
      from bano_adresses
      WHERE ST_Intersects(geometrie_3857,ST_Buffer(BBox($tx, $ty, $tz),1000,2)) AND
            source = 'BAN'
      except
      SELECT fantoir
      from bano_points_nommes
      join liste_insee
      using (code_insee)
      WHERE source = 'OSM'),
    latest_statut
    AS
    (SELECT fantoir,
            label_statut
    FROM    (SELECT *,
                    RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
            FROM    statut_fantoir)f
    JOIN    labels_statuts_fantoir
    USING   (id_statut)
    WHERE   rang = 1 AND
            id_statut != 0),
    bano_a
    AS
    (SELECT fantoir,
           COALESCE(nom_place,nom_voie) AS nom,
           label_statut,
           ST_Transform(ST_Buffer(ST_Convexhull(ST_Collect(geometrie)),0.0001),3857) as geom_hull
    FROM   (SELECT * FROM bano_adresses WHERE st_transform(geometrie,3857) && BBox($tx, $ty, $tz)) as bano_a
    JOIN   fantoir
    USING  (fantoir)
    LEFT OUTER JOIN latest_statut
    USING  (fantoir)
    GROUP BY 1,2,3)
    SELECT nom,
          CASE
              WHEN SUBSTR(fantoir,6,1) = 'b' THEN ''
              ELSE fantoir
          END AS fantoir,
          ST_AsMvtGeom(
              geom_hull,
              BBox($tx, $ty, $tz),
              4096,
              256,
              true
            ) AS geom
     FROM bano_a
     WHERE ST_Intersects(geom_hull, BBox($tx, $ty, $tz))
) AS q
  ) TO STDOUT;
  "
}

function num_point_osm() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'numeros_points_OSM', 4096, 'geom')
FROM (
      with 
      osm
      as
      (SELECT bano_id,code_insee,fantoir,numero,source as source_osm,geometrie_3857
      from bano_adresses
      WHERE ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz))
      and source = 'OSM'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM osm),
      ban
      as
      (SELECT bano_id
      FROM bano_adresses
      JOIN liste_insee
      USING (code_insee)
      WHERE source = 'BAN'),
      resultat
      as
      (SELECT osm.fantoir,
              osm.numero,
              CASE WHEN ban.bano_id is null THEN false ELSE true END as commun,
              geometrie_3857
      from
      osm 
      left outer join ban
      using (bano_id))
      SELECT numero,
          fantoir,
          commun,
          ST_AsMvtGeom(
              geometrie_3857,
              BBox($tx, $ty, $tz),
              4096,
              256,
              true
            ) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz))
) AS q
  ) TO STDOUT;
  "
}
function num_point_ban() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'numeros_points_BAN', 4096, 'geom')
FROM (
      WITH 
      ban
      AS
      (SELECT code_insee,fantoir,numero,bano_id,geometrie_3857
      FROM    bano_adresses
      WHERE   ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz)) AND
              source = 'BAN'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM ban),
      fantoir_osm
      AS
      (SELECT DISTINCT fantoir
      FROM  bano_points_nommes
      JOIN (SELECT DISTINCT code_insee FROM ban) b
      USING (code_insee)
      WHERE source = 'OSM'),
      osm
      as
      (SELECT bano_id
      FROM bano_adresses
      JOIN liste_insee
      USING (code_insee)
      WHERE source = 'OSM'),
      resultat
      as
      (SELECT ban.fantoir,
              ban.numero,
              CASE WHEN fantoir_osm.fantoir IS NULL THEN false ELSE true END rapproche,
              CASE WHEN osm.bano_id is null THEN false ELSE true END as commun,
              geometrie_3857
      from    ban
      left outer join
      fantoir_osm
      using (fantoir)
      left outer join osm
      using (bano_id))
      SELECT numero,
          fantoir,
          rapproche,
          commun,
          ST_AsMvtGeom(
              geometrie_3857,
              BBox($tx, $ty, $tz),
              4096,
              256,
              true
            ) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, BBox($tx, $ty, $tz))
) AS q
  ) TO STDOUT;
  "
}

function pyramide(){
  zoom=$1
  x0=$2
  x1=$3
  y0=$4
  y1=$5
  root_dir=../pifometre_v3/tiles_pifocarte

  for (( z=$zoom; z<=13; ++z )); do
    for (( x=$x0; x<=$x1; ++x )); do
      mkdir -p ./$root_dir/$z/$x
      for (( y=$y0; y<=$y1; ++y )); do
        file="$root_dir/$z/$x/$y.pbf"
        {
        psql -d bano -U cadastre -tq -c "$(num_convex $z $x $y)" | xxd -r -p ;
        psql -d bano -U cadastre -tq -c "$(num_point_ban $z $x $y)" | xxd -r -p ;
        psql -d bano -U cadastre -tq -c "$(num_point_osm $z $x $y)" | xxd -r -p ;
        psql -d bano -U cadastre -tq -c "$(lieudit_CADASTRE $z $x $y)" | xxd -r -p ;
        psql -d bano -U cadastre -tq -c "$(place_OSM $z $x $y)" | xxd -r -p ;
        } > $file
        du -h $file
      done
    done
    let "x0 = x0 * 2"
    let "y0 = y0 * 2"
    let "x1 = x1 * 2"
    let "y1 = y1 * 2"
  done
}


SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SCRIPT_DIR

# Metro
# pyramide 6 30 34 21 24
# pyramide 10 509 511 359 361
pyramide 11 725 726 995 996
# pyramide 11 1018 1020 718 720
# pyramide 12 2036 2040 1436 1440
# pyramide 13 4072 4080 2872 2880
