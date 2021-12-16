WITH pos
AS
(__positions__)
SELECT DISTINCT r.rel_id
FROM planet_osm_rels r
JOIN pos
ON pos.geom_position && r.way
WHERE member_role = 'house' AND
      name = '__name__';