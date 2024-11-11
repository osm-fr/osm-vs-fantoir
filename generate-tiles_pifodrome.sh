#!/bin/bash

# Script de génération des tuiles PBF à l'unité
# Totalement inspiré de https://blog.jawg.io/how-to-make-mvt-with-postgis/ <3

set -e

function pifodrome_voie() {
  tz=$1
  tx=$2
  ty=$3
  d=$4
  echo "
  COPY (
SELECT ST_AsMVT(q, 'pifodrome_voie', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              nom_commune_debut,
              code_insee_debut,
              nom_commune_fin,
              code_insee_fin,
              (plus_petit_chevauchement BETWEEN 0 AND $d)::boolean AS ppc,
              ST_AsMvtGeom(
                geometrie_osm_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM croisement_voies_limites
       WHERE geometrie_osm_3857 && ST_TileEnvelope($tz, $tx, $ty)
    ) AS q
  ) TO STDOUT;
  "
}

function pifodrome_point_debut() {
  tz=$1
  tx=$2
  ty=$3
  d=$4
  echo "
  COPY (
SELECT ST_AsMVT(q, 'pifodrome_point_debut', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              nom_commune_debut,
              code_insee_debut,
              nom_commune_fin,
              code_insee_fin,
              rapproche_debut,
              (plus_petit_chevauchement BETWEEN 0 AND $d)::boolean AS ppc,
              ST_AsMvtGeom(
                point_debut_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM croisement_voies_limites
       WHERE point_debut_3857 && ST_TileEnvelope($tz, $tx, $ty)
    ) AS q
  ) TO STDOUT;
  "
}

function pifodrome_point_fin() {
  tz=$1
  tx=$2
  ty=$3
  d=$4
  echo "
  COPY (
SELECT ST_AsMVT(q, 'pifodrome_point_fin', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              nom_commune_debut,
              code_insee_debut,
              nom_commune_fin,
              code_insee_fin,
              rapproche_fin,
              (plus_petit_chevauchement BETWEEN 0 AND $d)::boolean AS ppc,
              ST_AsMvtGeom(
                point_fin_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM croisement_voies_limites
       WHERE point_fin_3857 && ST_TileEnvelope($tz, $tx, $ty)
    ) AS q
  ) TO STDOUT;
  "
}

function pifodrome_point_croisement() {
  tz=$1
  tx=$2
  ty=$3
  d=$4
  echo "
  COPY (
SELECT ST_AsMVT(q, 'pifodrome_point_croisement', 4096, 'geom')
FROM ( SELECT osm_id,
              nom_osm,
              code_insee_debut,
              code_insee_fin,
              degres,
              (plus_petit_chevauchement BETWEEN 0 AND $d)::boolean AS ppc,
              ST_AsMvtGeom(
                geometrie_3857,
                BBox($tx, $ty, $tz),
                4096,
                256,
                true
              ) AS geom
       FROM point_croisement_voies_limites
       WHERE geometrie_3857 && ST_TileEnvelope($tz, $tx, $ty)
    ) AS q
  ) TO STDOUT;
  "
}

RACINE_CIBLE=$1
z=$2
x=$3
y=$4
d=$5

mkdir -p ./${RACINE_CIBLE}/points/$z/$x
ofile="${RACINE_CIBLE}/points/$z/$x/$y.pbf"
{
  psql -d bano -U cadastre -tq -c "$(pifodrome_point_debut $z $x $y $d)" | xxd -r -p ;
  psql -d bano -U cadastre -tq -c "$(pifodrome_point_fin $z $x $y $d)" | xxd -r -p ;
  psql -d bano -U cadastre -tq -c "$(pifodrome_point_croisement $z $x $y $d)" | xxd -r -p ;
} > $ofile
echo $ofile

if (( $z > 7 )); then
  mkdir -p ./${RACINE_CIBLE}/lignes/$z/$x
  ofile="${RACINE_CIBLE}/lignes/$z/$x/$y.pbf"
  {
    psql -d bano -U cadastre -tq -c "$(pifodrome_voie $z $x $y $d)" | xxd -r -p ;
  } > $ofile
  echo $ofile
fi
