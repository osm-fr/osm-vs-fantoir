WITH
diff
AS
(SELECT numero,fantoir,insee_com FROM cumul_adresses WHERE insee_com = '__com__' AND fantoir = '__fantoir__' AND source = 'CADASTRE' 
EXCEPT
SELECT numero,fantoir,insee_com FROM cumul_adresses WHERE insee_com = '__com__' AND fantoir = '__fantoir__' AND  source = 'OSM')
SELECT ST_X(c.geometrie),
       ST_Y(c.geometrie),
       diff.numero,
       diff.fantoir,
       COALESCE(c.voie_osm,c.voie_cadastre)
FROM   cumul_adresses c
JOIN   diff
USING  (numero,fantoir,insee_com)
WHERE  source = 'CADASTRE';