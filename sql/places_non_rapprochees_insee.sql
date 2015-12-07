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
(SELECT *
FROM	cumul_places
WHERE	insee_com ='__com__'	AND
	fantoir IS NOT NULL	AND
	libelle_osm IS NULL)
SELECT	c.fantoir,
	c.libelle_fantoir,
	'--',
	st_x(c.geometrie),
	st_y(c.geometrie),
	COALESCE(s.id_statut,0),
	c.ld_bati
FROM	c
LEFT OUTER JOIN s
ON	c.fantoir = s.fantoir
ORDER BY 7 desc,2;
