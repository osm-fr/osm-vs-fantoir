WITH
-- statut FANTOIR ---------------------
aa AS
(SELECT *,
        RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
FROM    statut_fantoir),
a AS
(SELECT fantoir
FROM    aa
WHERE   rang = 1 AND
        id_statut != 0),
-- Voies de cumul_voies ---------------
b AS
(SELECT f.fantoir10
 FROM   fantoir_voie f
 WhERE  f.code_insee LIKE '__dept__%' and type_voie in ('1','2')
EXCEPT
(SELECT fantoir
 FROM   cumul_voies
 WHERE  insee_com LIKE '__dept__%'
UNION
 SELECT fantoir
 FROM   cumul_adresses
 WHERE  insee_com LIKE '__dept__%'  AND
        (source='OSM' OR (source='BAN' AND COALESCE(voie_osm,'')!='')))),
-- Géometrie des voies BAN ----
-- 1 point adresse arbitraire ---------
c AS
(SELECT DISTINCT fantoir,
        voie_autre,
        FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
FROM    cumul_adresses
WHERE   source = 'BAN' AND
        insee_com LIKE '__dept__%'),
-- Assemblage -------------------------
d AS
(SELECT f.*,
        co.libelle commune,
        co.dep,
        c.voie_autre,
        c.geometrie,
        RANK() OVER(PARTITION BY 1 ORDER BY date_creation DESC,random()) rang
FROM    (SELECT fantoir10,
                code_insee,
                date_creation
        FROM    fantoir_voie
        WHERE   code_insee LIKE '__dept__%' AND
                type_voie IN ('1','2')) f
JOIN    b
USING   (fantoir10)
LEFT OUTER JOIN a
ON      f.fantoir10 = a.fantoir
JOIN    c
ON      f.fantoir10 = c.fantoir
JOIN    cog_commune co
ON      co.com = f.code_insee
WHERE   a.fantoir IS NULL),
-- Selection des 5 1ers par dept-------
e AS
(SELECT *
FROM    d
WHERE rang < 250)
SELECT e.dep,
    e.code_insee,
    e.commune,
    e.voie_autre,
    fantoir10,
    st_x(e.geometrie),
    st_y(e.geometrie),
    to_char(to_date(e.date_creation,'YYYYDDD'),'YYYY-MM-DD')
FROM    e
ORDER BY e.date_creation DESC,3,4;
