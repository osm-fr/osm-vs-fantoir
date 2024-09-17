#!/bin/bash

# Script de génération des tuiles PBF à l'unité
# Totalement inspiré de https://blog.jawg.io/how-to-make-mvt-with-postgis/ <3

set -e

function croisement_voies_limites() {
  tz=$1
  tx=$2
  ty=$3
  echo "
  COPY (
SELECT ST_AsMVT(q, 'croisement_voies_limites', 4096, 'geom')
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

z=$1
x=$2
y=$3

mkdir -p ./tiles_croisement/$z/$x
ofile="tiles_croisement/$z/$x/$y.pbf"
psql -d bano -U cadastre -tq -c "$(croisement_voies_limites $z $x $y)" | xxd -r -p  > $ofile
echo $ofile
