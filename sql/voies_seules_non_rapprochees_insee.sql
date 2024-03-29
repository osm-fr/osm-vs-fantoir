SELECT	f.fantoir10,
		to_char(to_date(f.date_creation,'YYYYDDD'),'YYYY-MM-DD'),
		f.nature_voie||' '||f.libelle_voie voie,
		'--',
		st_x(g.geometrie),
		st_y(g.geometrie),
		COALESCE(s.id_statut,0),
		0::integer, -- adresses a proposer
		CASE f.date_annul
		    WHEN '0000000' THEN '1'
		    ELSE -1
		END AS fantoir_annule,
		f.caractere_annul
FROM	fantoir_voie f
LEFT OUTER JOIN	(SELECT	fantoir
				FROM	cumul_adresses
				WHERE	insee_com = '__com__'	AND
						source in ('OSM','BAN')
				UNION
				SELECT	fantoir
				FROM	cumul_voies
				WHERE	insee_com = '__com__'	AND
						source = 'OSM') o
ON		f.fantoir10 = o.fantoir
LEFT OUTER JOIN	(SELECT	libelle,
						ST_Transform(ST_SetSRID(ST_Centroid(ST_Collect(ST_Centroid(geometrie))),900913),4326) geometrie
				FROM	parcelles_noms
				WHERE	insee_com = '__com__'
				GROUP BY	1)g
ON		f.nature_voie||' '||f.libelle_voie = g.libelle
LEFT OUTER JOIN	(SELECT fantoir,id_statut
				FROM 	(SELECT	*,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
						FROM 	statut_fantoir
						WHERE	insee_com = '__com__')r
				WHERE	rang = 1) s
ON		f.fantoir10 = s.fantoir
WHERE	f.code_insee = '__com__'	AND
		f.type_voie in ('1','2')	AND
		f.date_annul = '0000000'	AND
		o.fantoir IS NULL
ORDER BY 2; 
