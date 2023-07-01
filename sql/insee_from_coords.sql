WITH
s
AS
(SELECT   code_insee,
          CASE typecom
            WHEN 'ARM' THEN 1
            WHEN 'COM' THEN 2
            ELSE 3
          END sort_order
FROM      polygones_insee
JOIN      cog_commune c
ON        (com = code_insee)
WHERE     ST_Contains(geometrie,ST_SetSRID(ST_Point(__lon__,__lat__),4326))
UNION ALL
SELECT    '404',99)
SELECT    code_insee
FROM      s
ORDER BY  sort_order
LIMIT 1;