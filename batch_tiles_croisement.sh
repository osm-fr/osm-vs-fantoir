#!/bin/bash

# Script de génération des tuiles PBF à l'unité
# Totalement inspiré de https://blog.jawg.io/how-to-make-mvt-with-postgis/ <3

output_file=tiles_croisement.csv
rm ${output_file}
for zoom in {5..12}
do
   psql -d bano -U cadastre --csv -t -c "SELECT ${zoom}||' '||lon2tile(ST_X(geometrie_debut),${zoom})||' '||lat2tile(ST_Y(geometrie_debut),${zoom}) FROM croisement_voies_limites GROUP BY 1 ORDER BY 1" >> ${output_file}
done

parallel -a $output_file --colsep ' ' -j 4 ./generate-tiles_croisement.sh {1} {2} {3}
