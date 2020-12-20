SELECT numero,voie_osm
FROM   cumul_adresses c
WHERE  source = 'OSM' AND
       fantoir = '__fantoir__';