SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		'--'
FROM	fantoir_voie f
LEFT OUTER JOIN	(SELECT	fantoir
				FROM	cumul_adresses
				WHERE	insee_com = '__com__'	AND
						source in ('OSM','CADASTRE')
				UNION
				SELECT	fantoir
				FROM	cumul_voies
				WHERE	insee_com = '__com__'	AND
						source = 'OSM') o
ON		f.code_insee||f.id_voie||f.cle_rivoli = o.fantoir
WHERE	f.code_insee = '__com__'	AND
		f.type_voie = '1'			AND
		f.date_annul = '0000000'	AND
		o.fantoir IS NULL
ORDER BY 2; 
