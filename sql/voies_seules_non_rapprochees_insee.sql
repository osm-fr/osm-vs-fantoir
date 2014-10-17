SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		f.nature_voie||' '||f.libelle_voie voie,
		'--',
		st_x(g.geometrie),
		st_y(g.geometrie)
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
LEFT OUTER JOIN	(SELECT	voie_cadastre,
						ST_Transform(ST_SetSRID(ST_Centroid(ST_Collect(ST_Centroid(geometrie))),900913),4326) geometrie
				FROM	parcelles
				WHERE	insee_com = '__com__'
				GROUP BY	1)g
ON		f.nature_voie||' '||f.libelle_voie = g.voie_cadastre
WHERE	f.code_insee = '__com__'	AND
		f.type_voie in ('1','2')	AND
		f.date_annul = '0000000'	AND
		o.fantoir IS NULL
ORDER BY 2; 
