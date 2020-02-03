SELECT	'--'::text AS Fantoir,
        '--'::text AS voie_fantoir,
        c.voie_osm,
		ST_X(c.geometrie),
		ST_Y(c.geometrie),
		0::integer AS statut
FROM	cumul_voies c
JOIN    polygones_insee p
ON      ST_Contains(p.geometrie,ST_Transform(ST_SetSRID(c.geometrie,4326),3857))
WHERE	c.insee_com = '__com__' AND
        p.insee_com = '__com__' AND
        c.fantoir = ''
ORDER BY 1;
