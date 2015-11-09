WITH
aa AS
(SELECT *,
		RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
FROM 	statut_fantoir),
a AS
(SELECT 	SUBSTR(fantoir,1,9) fantoir
FROM 	aa
WHERE rang = 1 AND
	id_statut != 0),
b AS
(SELECT	f.fantoir
FROM	fantoir_voie f
JOIN	cumul_voies c
ON	f.fantoir||f.cle_rivoli = c.fantoir),
c AS
(SELECT DISTINCT SUBSTR(fantoir,1,9) fantoir,
		voie_cadastre,
		FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
FROM		cumul_adresses
WHERE		source = 'CADASTRE'),
d AS
(SELECT f.*,
	co.nom commune,
	c.voie_cadastre,
	c.geometrie,
	RANK() OVER(PARTITION BY CASE WHEN code_dept = '97' THEN SUBSTR(code_insee,1,3) ELSE code_dept END ORDER BY date_creation DESC,random()) rang
FROM	fantoir_voie f
LEFT OUTER JOIN b
USING	(fantoir)
LEFT OUTER JOIN a
ON		f.fantoir = a.fantoir
JOIN	c
ON		f.fantoir = c.fantoir
JOIN	communes co
ON		co.insee = f.code_insee
WHERE	a.fantoir IS NULL	AND
		b.fantoir IS NULL	AND
		f.type_voie IN ('1','2')),
e AS
(SELECT	*
FROM	d
WHERE	rang < 6)
SELECT	CASE WHEN e.code_dept = '97' THEN SUBSTR(e.code_insee,1,3) ELSE e.code_dept END dept,
	e.code_insee,
	e.commune,
	e.voie_cadastre,
	e.fantoir||e.cle_rivoli fantoir,
	st_x(e.geometrie),
	st_y(e.geometrie),
	to_char(to_date(e.date_creation,'YYYYDDD'),'DD/MM/YYYY')
FROM	e
-- LEFT OUTER JOIN c
-- USING	(fantoir)
ORDER BY 1;
