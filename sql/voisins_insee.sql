WITH i
AS
(SELECT	wkb_geometry,
		ST_Centroid(wkb_geometry) gcentre
FROM	communes
WHERE	insee = '__com__'),
v
AS
(SELECT	insee,
		ST_Centroid(c.wkb_geometry) gcentre,
		nom
FROM	communes c
JOIN	i
ON		ST_Touches(c.wkb_geometry,i.wkb_geometry)),
j
AS
(SELECT	v.insee,(((DEGREES(ST_Azimuth(i.gcentre,v.gcentre)) - 15)/30)+1)::integer secteur,
		ST_Distance(i.gcentre,v.gcentre) dist,
		nom
FROM	v
CROSS JOIN i),
r
AS
(SELECT	*,
		RANK() OVER(PARTITION BY secteur ORDER BY dist) rang
FROM	j)
SELECT	secteur,
		insee,
		nom
FROM	r
WHERE	rang = 1; 
