WITH
qualif_adresse
AS
(SELECT numero,fantoir,id_statut
				FROM 	(SELECT	*,rank() OVER (PARTITION BY numero,fantoir ORDER BY timestamp_statut DESC) rang
						FROM 	statut_adresse
						WHERE	insee_com = '__com__')r
				WHERE	rang = 1),
diff_numero_fantoir
AS
(SELECT numero,
	    fantoir 
 FROM   cumul_adresses c
 LEFT OUTER JOIN qualif_adresse q
 USING  (numero,fantoir)
 WHERE  c.insee_com = '__com__' AND
        source = 'BAN' AND
        COALESCE(q.id_statut,0) = 0
EXCEPT
SELECT numero,
       fantoir
FROM   cumul_adresses
WHERE  insee_com = '__com__' AND
       source = 'OSM'),
fantoir_numeros_manquants
AS
(SELECT DISTINCT fantoir,count(*) AS a_proposer
FROM    diff_numero_fantoir
GROUP BY 1)
SELECT	f.fantoir10 fantoir,
		to_char(to_date(f.date_creation,'YYYYDDD'),'YYYY-MM-DD'),
		nature_voie||' '||libelle_voie voie,
		j.voie_osm,
		st_x(g.geometrie),
		st_y(g.geometrie),
		COALESCE(s.id_statut,0),
		COALESCE(fm.a_proposer,0),
		CASE f.date_annul
		    WHEN '0000000' THEN '1'
		    ELSE -1
		END AS fantoir_annule
FROM	fantoir_voie f
JOIN 	(SELECT DISTINCT fantoir,voie_osm
		FROM	cumul_adresses
		WHERE	insee_com = '__com__' AND
		        COALESCE(voie_osm,'') != '' AND
		        source in ('BAN','OSM')) j
ON		f.fantoir10 = j.fantoir
JOIN	(SELECT DISTINCT fantoir,
				FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
		FROM	cumul_adresses
		WHERE	insee_com = '__com__') g
ON		f.fantoir10 = g.fantoir
LEFT OUTER JOIN	(SELECT fantoir,id_statut
				FROM 	(SELECT	*,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
						FROM 	statut_fantoir
						WHERE	insee_com = '__com__')r
				WHERE	rang = 1) s
ON		j.fantoir = s.fantoir
LEFT OUTER JOIN fantoir_numeros_manquants fm
ON      f.fantoir10 = fm.fantoir
WHERE	f.code_insee = '__com__'	AND
		f.type_voie in ('1','2','3')
ORDER BY 3;
