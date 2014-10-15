SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		'--',
		st_x(g.geometrie),
		st_y(g.geometrie)
FROM	fantoir_voie f
JOIN	(SELECT	fantoir
		FROM	cumul_adresses
		WHERE	insee_com = '__com__'	AND
				source = 'CADASTRE'		AND
				voie_osm = ''
		EXCEPT
		SELECT	fantoir
		FROM	cumul_adresses
		WHERE	insee_com = '__com__'	AND
				source = 'OSM') j
ON		f.code_insee||f.id_voie||f.cle_rivoli = j.fantoir
JOIN	(SELECT DISTINCT fantoir,
				FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
		FROM	cumul_adresses
		WHERE	insee_com = '__com__' AND
				source = 'CADASTRE') g
ON		g.fantoir = j.fantoir
WHERE	f.code_insee = '__com__'	AND
		f.type_voie = '1'			AND
		f.date_annul = '0000000'
ORDER BY 2; 
