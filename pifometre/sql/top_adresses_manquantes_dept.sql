WITH
-- Fantoir --
fantoir
AS
(SELECT fantoir
FROM    bano_adresses
WHERE   nom_voie IS NOT NULL   AND
        fantoir  IS NOT NULL   AND
        source   != 'OSM'      AND
        code_dept = '__dept__'
EXCEPT
(SELECT fantoir
FROM    nom_fantoir
WHERE   code_dept = '__dept__' AND
        source    = 'OSM')),
-- Voies avec max adresses ---------------
max
AS
(SELECT c.code_insee,
        c.fantoir,
        c.nom_voie,
        count(*) a_proposer,
        avg(certification_commune*100)::int certification
FROM    bano_adresses c
JOIN    fantoir
USING   (fantoir)
GROUP BY 1,2,3
ORDER BY 4 DESC
OFFSET __offset__
LIMIT __limit__),
-- statut FANTOIR ---------------------
latest_statut
AS
(SELECT fantoir,
        id_statut
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
        FIRST_VALUE(geometrie) OVER(PARTITION BY c.fantoir ORDER BY c.numero) geometrie
FROM    bano_adresses c
JOIN    max
USING   (fantoir))
-- Assemblage -------------------------
SELECT cog.code_insee,
       cog.libelle,
       max.nom_voie,
       max.fantoir,
       st_x(geom.geometrie),
       st_y(geom.geometrie),
       max.a_proposer,
       COALESCE(id_statut,0),
       COALESCE(is_place,false),
       max.certification,
       nb_ligne_total
FROM   max
JOIN   (SELECT libelle,
               com AS code_insee,
               dep
       FROM    cog_commune
       WHERE   dep = '__dept__' AND
               typecom in ('COM','ARM')) cog
USING  (code_insee)
JOIN   geom
USING  (fantoir)
LEFT OUTER JOIN latest_statut l
USING  (fantoir)
LEFT OUTER JOIN (SELECT fantoir,
                        true AS is_place
                 FROM   (SELECT  fantoir,
                                 RANK() OVER (PARTITION BY fantoir ORDER BY CASE source WHEN 'OSM' THEN 1 ELSE 2 END) rang
                        FROM     nom_fantoir
                        WHERE    code_dept = '__dept__' AND
                                 nature IN ('place','lieu-dit')) p
                 WHERE rang = 1) place
USING (fantoir)
CROSS JOIN (SELECT count(*) AS nb_ligne_total FROM fantoir) lf
ORDER BY a_proposer DESC;
--LIMIT __limit__;
