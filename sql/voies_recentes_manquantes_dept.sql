WITH
-- statut FANTOIR ---------------------
aa AS
(SELECT *,
		RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
FROM 	statut_fantoir),
a AS
(SELECT 	SUBSTR(fantoir,1,9) fantoir
FROM 	aa
WHERE rang = 1 AND
	id_statut != 0),
-- Voies de cumul_voies ---------------
b AS
(SELECT	f.fantoir||f.cle_rivoli fantoir
FROM	fantoir_voie f
WhERE	f.code_insee like '__dept__%' and type_voie in ('1','2')
EXCEPT
SELECT	fantoir FROM cumul_voies c
WHERE	c.insee_com like '__dept__%'),
-- Géometrie des voies du Cadastre ----
-- 1 point adresse arbitraire ---------
c AS
(SELECT DISTINCT SUBSTR(fantoir,1,9) fantoir,
		voie_cadastre,
		FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
FROM		cumul_adresses
WHERE		source = 'CADASTRE' AND
		insee_com like '__dept__%'),
-- Assemblage -------------------------
d AS
(SELECT f.*,
	co.nom commune,
	c.voie_cadastre,
	c.geometrie,
	RANK() OVER(PARTITION BY 1 ORDER BY date_creation DESC,random()) rang
FROM	fantoir_voie f
JOIN b
On	b.fantoir = f.fantoir||f.cle_rivoli
LEFT OUTER JOIN a
ON		f.fantoir = a.fantoir
JOIN	c
ON		f.fantoir = c.fantoir
JOIN	communes co
ON		co.insee = f.code_insee
WHERE	a.fantoir IS NULL	AND
		f.code_insee like '__dept__%' AND
		f.type_voie IN ('1','2')),
-- Selection des 5 1ers par dept-------
e AS
(SELECT	*
FROM	d
WHERE rang < 50)
SELECT	CASE WHEN e.code_dept = '97' THEN SUBSTR(e.code_insee,1,3) ELSE e.code_dept END dept,
	e.code_insee,
	e.commune,
	e.voie_cadastre,
	e.fantoir||e.cle_rivoli fantoir,
	st_x(e.geometrie),
	st_y(e.geometrie),
	to_char(to_date(e.date_creation,'YYYYDDD'),'DD/MM/YYYY')
FROM	e
ORDER BY e.date_creation DESC,3,4;
