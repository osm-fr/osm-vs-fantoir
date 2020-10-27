WITH
f
AS
(SELECT fantoir
 FROM   cumul_voies
 WHERE fantoir != ''
EXCEPT
SELECT  fantoir10
FROM	fantoir_voie)
SELECT v.fantoir,
       v.voie_osm,
       ST_X(v.geometrie),
       ST_Y(v.geometrie)
FROM   cumul_voies v
JOIN   f
USING  (fantoir)
ORDER BY 1

