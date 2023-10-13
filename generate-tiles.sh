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
                   WHEN population_rel >  20000 THEN 2
                   ELSE 3
              END AS class_pop,
              ST_AsMvtGeom(
                geom_centroide_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
  FROM polygones_insee_3857
  JOIN (SELECT DISTINCT \"ref:INSEE\" AS code_insee,
                        population_rel
       FROM             planet_osm_communes_statut
       WHERE            admin_level = 8 AND
                        \"ref:INSEE\" != '') p
  USING (code_insee)
  WHERE geom_centroide_3857 && BBox($tx, $ty, $tz) AND
        ST_Intersects(geom_centroide_3857, BBox($tx, $ty, $tz)) AND
        code_insee != '' AND
        ((admin_level = 8 AND code_insee NOT IN ('13055','69123','75056')) OR
         (admin_level = 9 AND (code_insee LIKE '751__' OR code_insee LIKE '6938_' OR code_insee LIKE '132_')))
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

  for (( z=$zoom; z<=$zoom; ++z )); do
    for (( x=$x0; x<=$x1; ++x )); do
      mkdir -p ./tiles/$z/$x
      for (( y=$y0; y<=$y1; ++y )); do
        file="tiles/$z/$x/$y.pbf"
        {
        psql -d bano -U cadastre -tq -c "$(admin $z $x $y)" | xxd -r -p ;
        } > $file
        du -h $file
      done
    done
  done
}

# Réunion
pyramide 6 41 42 35 35

# Caraïbes
pyramide 6 20 23 29 31

# Metro
pyramide 6 30 34 21 24

