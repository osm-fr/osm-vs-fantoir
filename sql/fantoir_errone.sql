WITH
f
AS
(SELECT fantoir
 FROM   bano_points_nommes
 WHERE  fantoir IS NOT NULL AND
        source = 'OSM'
EXCEPT
SELECT  fantoir
FROM	 topo)
SELECT DISTINCT v.fantoir,
       nom,
       ST_X(geometrie),
       ST_Y(geometrie)
FROM   bano_points_nommes v
JOIN   f
USING  (fantoir)
WHERE  source = 'OSM'
ORDER BY 1;