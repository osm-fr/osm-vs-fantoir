WITH
diff_numero_fantoir
AS
(SELECT numero,fantoir FROM cumul_adresses WHERE insee_com = '__com__' and source = 'BAN'
EXCEPT
SELECT numero,fantoir FROM cumul_adresses WHERE insee_com = '__com__' and source = 'OSM'),
fantoir_numeros_manquants
AS
(SELECT DISTINCT fantoir,count(*) AS a_proposer FROM diff_numero_fantoir GROUP BY 1),
s
AS
(SELECT fantoir,
	id_statut
FROM 	(SELECT	*,
		rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
	FROM 	statut_fantoir
	WHERE	insee_com = '__com__')r
WHERE	rang = 1),
c
AS
(SELECT *
FROM	cumul_places
WHERE	insee_com ='__com__'	AND
		fantoir IS NOT NULL	AND
		libelle_osm IS NULL),
v
AS
(SELECT fantoir
FROM    cumul_voies
WHERE   insee_com ='__com__')
SELECT	c.fantoir,
		to_char(to_date(f.date_creation,'YYYYDDD'),'YYYY-MM-DD'),
		c.libelle_fantoir,
		c.libelle_cadastre,
		st_x(c.geometrie),
		st_y(c.geometrie),
		COALESCE(s.id_statut,0),
		COALESCE(fm.a_proposer,0),
		c.ld_bati
FROM	c
JOIN	fantoir_voie f
ON		c.fantoir = f.fantoir10
LEFT OUTER JOIN s
ON	c.fantoir = s.fantoir
LEFT OUTER JOIN v
ON	c.fantoir = v.fantoir
LEFT OUTER JOIN fantoir_numeros_manquants fm
ON      f.fantoir10 = fm.fantoir
WHERE v.fantoir IS NULL
ORDER BY 8 DESC,9,2;
