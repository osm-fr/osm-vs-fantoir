SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		'--'
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
WHERE	f.code_insee = '__com__'	AND
		f.type_voie = '1'			AND
		f.date_annul = '0000000'
ORDER BY 2; 
