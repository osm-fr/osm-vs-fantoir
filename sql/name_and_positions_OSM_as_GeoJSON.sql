SELECT	DISTINCT nom.nom,
                 ST_AsGeoJSON(ST_Buffer(geometrie,0.0001))
FROM    bano_adresses
JOIN    (SELECT fantoir,
	            nom
	     FROM   nom_fantoir
	     WHERE  fantoir = '__fantoir__'
	     ORDER BY 
             CASE source
                 WHEN 'OSM' THEN 1
                 WHEN 'BAN' THEN 2
                 WHEN 'CADASTRE' THEN 3
                 ELSE  4
             END,
             nature
         LIMIT 1) AS nom
USING   (fantoir)
WHERE   code_insee = '__code_insee__'	AND
		fantoir = '__fantoir__';
