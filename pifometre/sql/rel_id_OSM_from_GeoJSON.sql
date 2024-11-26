WITH pos
AS
(__positions__)
SELECT DISTINCT r.rel_id
FROM planet_osm_rels r
JOIN pos
ON pos.geom_position && r.way
WHERE member_role = 'house' AND
      name = '__name__'     AND
      ("ref:FR:FANTOIR" = '' OR "ref:FR:FANTOIR" LIKE '__code_insee__%');