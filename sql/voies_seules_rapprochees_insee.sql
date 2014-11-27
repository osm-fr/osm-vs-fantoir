SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		c.voie_osm,
		ST_X(c.geometrie),
		ST_Y(c.geometrie),
		COALESCE(s.id_statut,0)
FROM	fantoir_voie f
JOIN	(SELECT fantoir FROM cumul_voies WHERE insee_com = '__com__'
		EXCEPT
		SELECT fantoir FROM cumul_adresses WHERE insee_com = '__com__' AND voie_osm != '')r
ON		f.code_insee||f.id_voie||f.cle_rivoli = r.fantoir
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
