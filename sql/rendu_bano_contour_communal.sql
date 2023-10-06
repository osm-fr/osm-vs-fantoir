WITH
p
AS
(SELECT geometrie,
        admin_level
FROM    polygones_insee
WHERE   code_insee = '__code_insee__' AND
        admin_level in (8,9)
ORDER BY admin_level ASC
LIMIT 1)
SELECT ST_AsGeoJSON(ST_BoundingDiagonal(geometrie))
FROM p
UNION ALL
SELECT ST_AsGeoJSON(geometrie)
FROM p;