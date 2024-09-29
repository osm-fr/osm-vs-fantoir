#!/bin/bash

# Script de génération des tuiles PBF à l'unité
# Totalement inspiré de https://blog.jawg.io/how-to-make-mvt-with-postgis/ <3

set -e

RACINE_CIBLE=tiles_croisement_240929

function cvl_voie() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'cvl_voie', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              nom_commune_debut,
              code_insee_debut,
              nom_commune_fin,
              code_insee_fin,
              ST_AsMvtGeom(
                geometrie_osm_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM croisement_voies_limites
    ) AS q
  ) TO STDOUT;
  "
}

function cvl_point_debut() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'cvl_point_debut', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              nom_commune_debut,
              code_insee_debut,
              nom_commune_fin,
              code_insee_fin,
              rapproche_debut,
              ST_AsMvtGeom(
                point_debut_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM croisement_voies_limites
    ) AS q
  ) TO STDOUT;
  "
}

function cvl_point_fin() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'cvl_point_fin', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              nom_commune_debut,
              code_insee_debut,
              nom_commune_fin,
              code_insee_fin,
              rapproche_fin,
              ST_AsMvtGeom(
                point_fin_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM croisement_voies_limites
    ) AS q
  ) TO STDOUT;
  "
}

function cvl_point_croisement() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'cvl_point_croisement', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              code_insee_debut,
              code_insee_fin,
              degres,
              ST_AsMvtGeom(
                geometrie_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM point_croisement_voies_limites
    ) AS q
  ) TO STDOUT;
  "
}

z=$1
x=$2
y=$3

mkdir -p ./${RACINE_CIBLE}/$z/$x
ofile="${RACINE_CIBLE}/$z/$x/$y.pbf"
{
  psql -d bano -U cadastre -tq -c "$(cvl_voie $z $x $y)" | xxd -r -p ;
  psql -d bano -U cadastre -tq -c "$(cvl_point_debut $z $x $y)" | xxd -r -p ;
  psql -d bano -U cadastre -tq -c "$(cvl_point_fin $z $x $y)" | xxd -r -p ;
  psql -d bano -U cadastre -tq -c "$(cvl_point_croisement $z $x $y)" | xxd -r -p ;
} > $ofile
echo $ofile
