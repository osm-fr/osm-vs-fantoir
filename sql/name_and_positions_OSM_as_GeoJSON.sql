SELECT	DISTINCT COALESCE(voie_osm,voie_cadastre),
                 ST_AsGeoJSON(geometrie)
FROM    cumul_adresses
WHERE   insee_com = '__com__'	AND
		fantoir = '__fantoir__';
