SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		c.voie_osm
FROM	fantoir_voie f
JOIN	(SELECT fantoir FROM cumul_voies WHERE insee_com = '__com__'
		EXCEPT
		SELECT fantoir FROM cumul_adresses WHERE insee_com = '__com__' AND voie_osm != '')r
ON		f.code_insee||f.id_voie||f.cle_rivoli = r.fantoir
JOIN	cumul_voies c
ON		r.fantoir = c.fantoir
WHERE	f.code_insee = '__com__'
ORDER BY 3;
