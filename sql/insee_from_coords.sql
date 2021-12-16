WITH
s
AS
(SELECT 	insee_com,
CASE typecom
  WHEN 'ARM' THEN 1
  WHEN 'COM' THEN 2
  ELSE 3
END sort_order
FROM	polygones_insee_geo
JOIN    cog_commune c
ON      (com = insee_com)
WHERE	ST_Contains(geometrie,ST_SetSRID(ST_Point(__lon__,__lat__),4326))
UNION ALL
SELECT '404',99)
SELECT insee_com
FROM s
ORDER BY sort_order
LIMIT 1;