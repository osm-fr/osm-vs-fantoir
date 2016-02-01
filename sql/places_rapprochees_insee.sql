WITH
s
AS
(SELECT fantoir,
	id_statut
FROM 	(SELECT	*,
		rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
	FROM 	statut_fantoir
	WHERE	insee_com = '__com__')r
WHERE	rang = 1),
c
AS
(SELECT *,
	CASE ld_osm
		WHEN 'city' THEN 1
		WHEN 'town' THEN 2
		WHEN 'suburb' THEN 3
		WHEN 'village' THEN 4
		WHEN 'quarter' THEN 5
		WHEN 'neighbourhood' THEN 6
		WHEN 'hamlet' THEN 7
		WHEN 'isolated_dwelling' THEN 8
		WHEN 'locality' THEN 99
		ELSE 98
	END tri
FROM	cumul_places
WHERE	insee_com ='__com__'	AND
	fantoir IS NOT NULL	AND
	source = 'OSM')
SELECT	c.fantoir,
	c.libelle_fantoir,
	CASE
	  WHEN c.ld_osm IS NOT NULL THEN c.ld_osm||' : '||c.libelle_osm
	  ELSE c.libelle_osm
	END,
	st_x(c.geometrie),
	st_y(c.geometrie),
	COALESCE(s.id_statut,0),
	c.ld_bati
FROM	c
LEFT OUTER JOIN s
ON	c.fantoir = s.fantoir
ORDER BY tri,2;
