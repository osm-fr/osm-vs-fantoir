SELECT	DISTINCT COALESCE(voie_osm,voie_autre),
                 ST_AsGeoJSON(ST_Buffer(geometrie,0.0001))
FROM    cumul_adresses
WHERE   insee_com = '__com__'	AND
		fantoir = '__fantoir__';
