WITH i
AS
(SELECT	way,
		ST_Centroid(way) gcentre
FROM	planet_osm_polygon
WHERE	boundary='administrative' AND
        admin_level in (8,9) AND
        "ref:INSEE" = '__com__'),
v
AS
(SELECT	"ref:INSEE",
		ST_Centroid(c.way) gcentre,
		name
FROM	planet_osm_polygon c
JOIN	i
ON		ST_Touches(c.way,i.way)
WHERE   c.boundary='administrative' AND
        (c.admin_level=8 OR (c.admin_level=9 AND ("ref:INSEE" LIKE '751__' OR
                                                  "ref:INSEE" LIKE '6938_' OR
                                                  "ref:INSEE" LIKE '132__' )))),
j
AS
(SELECT	v."ref:INSEE",(((DEGREES(ST_Azimuth(i.gcentre,v.gcentre)) - 15)/30)+1)::integer secteur,
		ST_Distance(i.gcentre,v.gcentre) dist,
		name
FROM	v
CROSS JOIN i),
r
AS
(SELECT	*,
		RANK() OVER(PARTITION BY secteur ORDER BY dist) rang
FROM	j)
SELECT	secteur,
		"ref:INSEE",
		name
FROM	r
WHERE	rang = 1; 
