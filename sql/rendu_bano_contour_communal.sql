WITH
p
AS
(SELECT geometrie
FROM    polygones_insee
WHERE   code_insee = '__code_insee__' AND
        admin_level = 8)
SELECT ST_AsGeoJSON(ST_BoundingDiagonal(geometrie))
FROM p
UNION ALL
SELECT ST_AsGeoJSON(geometrie)
FROM p;