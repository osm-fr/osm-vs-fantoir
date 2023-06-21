WITH
-- Fantoir --
fantoir
AS
(SELECT code_insee,
        fantoir
FROM    bano_adresses
WHERE   nom_voie IS NOT NULL AND
        fantoir IS NOT NULL AND
        source != 'OSM' AND
        code_dept = '__dept__'
EXCEPT
(SELECT code_insee,
        fantoir
FROM    nom_fantoir
WHERE   code_dept = '__dept__' AND
        source = 'OSM')),
-- Voies avec max adresses ---------------
max
AS
(SELECT c.code_insee,
        c.fantoir,
        c.nom_voie,
        count(*) a_proposer
FROM    bano_adresses c
JOIN    fantoir
USING   (fantoir)
--WHERE   c.voie_autre IS NOT NULL
GROUP BY 1,2,3
ORDER BY 4 DESC
LIMIT 200),
-- statut FANTOIR ---------------------
latest_statut
AS
(SELECT fantoir
FROM    (SELECT s.*,
                RANK() OVER(PARTITION BY s.fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
         FROM    statut_fantoir s
         JOIN    max
         USING   (fantoir))f
WHERE   rang = 1 AND
        id_statut != 0),
-- Géometrie des voies du Cadastre ----
-- 1 point adresse arbitraire ---------
geom
AS
(SELECT DISTINCT c.fantoir,
        FIRST_VALUE(geometrie) OVER(PARTITION BY c.fantoir) geometrie
FROM    bano_adresses c
JOIN    max
USING   (fantoir))
-- Assemblage -------------------------
SELECT cog.dep,
       cog.com,
       cog.libelle,
       max.nom_voie,
       max.fantoir,
       st_x(geom.geometrie),
       st_y(geom.geometrie),
       max.a_proposer
FROM   max
JOIN   cog_commune cog
ON     code_insee = com
JOIN   geom
USING  (fantoir)
LEFT OUTER JOIN latest_statut l
ON     max.fantoir = l.fantoir
WHERE  l.fantoir IS NULL      AND
       cog.dep = '__dept__'
ORDER BY a_proposer DESC
LIMIT 200;
