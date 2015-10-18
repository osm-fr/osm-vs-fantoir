WITH
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
JOIN	c
ON	c.fantoir = f.fantoir
JOIN	communes co
ON	co.insee = f.code_insee
WHERE	b.fantoir IS NULL	AND
	f.type_voie IN ('1','2')),
e AS
(SELECT	*
FROM	d
WHERE	rang = 1)
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
