WITH pos
AS
(__positions__),
ext
AS
(SELECT ST_Extent(geom_position) AS ext
FROM pos)
SELECT l.osm_id
FROM planet_osm_line l
JOIN ext
ON ext.ext && l.way
WHERE highway != '' AND
      (name = '__name__' OR
        "ref:FR:FANTOIR" = '__fantoir__')
UNION
SELECT l.osm_id
FROM planet_osm_polygon l
JOIN ext
ON ext.ext && l.way
WHERE highway != '' AND
      (name = '__name__' OR
        "ref:FR:FANTOIR" = '__fantoir__');