WITH
-- Fantoir --
fantoir
AS
(SELECT insee_com,
	    c.fantoir
FROM    cumul_adresses c
-- JOIN    fantoir_voie f
-- ON      c.fantoir = fantoir10
WHERE   voie_cadastre IS NOT NULL AND
        c.fantoir IS NOT NULL AND
        -- f.type_voie in ('1','2') AND
        c.dept = '__dept__'
EXCEPT
(SELECT insee_com,
	    fantoir
FROM    cumul_voies
WHERE   dept = '__dept__'
UNION
SELECT  insee_com,
	    fantoir
FROM    cumul_adresses
WHERE   voie_osm IS NOT NULL AND
        dept = '__dept__')),
-- Voies avec max adresses ---------------
max
AS
(SELECT c.insee_com,
	    c.fantoir,
	    c.voie_cadastre,
	    count(*) a_proposer
FROM    cumul_adresses c
JOIN    fantoir
USING (fantoir)
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 200),
-- statut FANTOIR ---------------------
statut
AS
(SELECT s.*,
		RANK() OVER(PARTITION BY s.fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
FROM 	statut_fantoir s
JOIN    max
USING (fantoir)),
latest_statut
AS
(SELECT fantoir
FROM 	statut
WHERE rang = 1 AND
	id_statut != 0),
-- Géometrie des voies du Cadastre ----
-- 1 point adresse arbitraire ---------
geom
AS
(SELECT DISTINCT c.fantoir,
		FIRST_VALUE(geometrie) OVER(PARTITION BY c.fantoir) geometrie
FROM	cumul_adresses c
JOIN    max
USING   (fantoir))
-- Assemblage -------------------------
SELECT cog.dep,
       cog.com,
       cog.libelle,
       max.voie_cadastre,
       max.fantoir,
       st_x(geom.geometrie),
       st_y(geom.geometrie),
       max.a_proposer
FROM   max
JOIN   cog_commune cog
ON     insee_com = com
JOIN   geom
USING  (fantoir)
LEFT OUTER JOIN latest_statut l
ON		max.fantoir = l.fantoir
WHERE	l.fantoir IS NULL	AND
		cog.dep = '__dept__'
ORDER BY a_proposer DESC
LIMIT 200;
