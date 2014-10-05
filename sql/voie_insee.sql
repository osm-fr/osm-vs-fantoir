SELECT	f.code_insee||f.id_voie||f.cle_rivoli fantoir,
		nature_voie||' '||libelle_voie voie,
		coalesce(j.voie_osm,'--')
FROM 	fantoir_voie f
LEFT OUTER JOIN	(SELECT DISTINCT	fantoir,
									voie_osm
				FROM				cumul_adresses
				WHERE 				insee_com = '__com__'	AND
									source in ('OSM','CADASTRE') AND
									voie_osm IS NOT NULL	AND
									voie_osm != '') j
ON		f.code_insee||f.id_voie||f.cle_rivoli = j.fantoir
WHERE	f.code_insee = '__com__'	AND
		f.type_voie = '1'			AND
		f.date_annul = '0000000'	AND
		j.voie_osm IS __null__clause__
ORDER BY 3,2,1;
