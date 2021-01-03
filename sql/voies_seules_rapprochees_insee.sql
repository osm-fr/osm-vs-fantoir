SELECT	f.fantoir10,
		to_char(to_date(f.date_creation,'YYYYDDD'),'YYYY-MM-DD'),
		nature_voie||' '||libelle_voie voie,
		c.voie_osm,
		ST_X(c.geometrie),
		ST_Y(c.geometrie),
		COALESCE(s.id_statut,0),
		0::integer, -- adresses a proposer
		CASE f.date_annul
		    WHEN '0000000' THEN '1'
		    ELSE -1
		END AS fantoir_annule
FROM	fantoir_voie f
JOIN	(SELECT fantoir FROM cumul_voies WHERE insee_com = '__com__'
		EXCEPT
		SELECT fantoir FROM cumul_adresses WHERE insee_com = '__com__' AND voie_osm != '')r
ON		f.fantoir10 = r.fantoir
JOIN	cumul_voies c
ON		r.fantoir = c.fantoir
LEFT OUTER JOIN	(SELECT fantoir,id_statut
				FROM 	(SELECT	*,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
						FROM 	statut_fantoir
						WHERE	insee_com = '__com__')r
				WHERE	rang = 1) s
ON		r.fantoir = s.fantoir
WHERE	f.code_insee = '__com__'
ORDER BY 3;
