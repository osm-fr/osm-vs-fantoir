-- statut FANTOIR ---------------------
CREATE TEMP TABLE statut_fantoir
AS
(SELECT fantoir
FROM    (SELECT *,
        RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
FROM    statut_fantoir
WHERE   fantoir LIKE '__dept__%') aa
WHERE   rang = 1         AND
        id_statut != 0);

-- Fantoirs éligibles ---------------
CREATE TEMP TABLE liste_fantoir
AS
(SELECT f.fantoir10 as fantoir
FROM    fantoir_voie f
WHERE   f.code_dept = '__dept__' and type_voie in ('1','2')

INTERSECT

SELECT  fantoir
FROM    cumul_adresses
WHERE   source = 'BAN' and dept = '__dept__'

EXCEPT

(SELECT fantoir
FROM    cumul_voies
WHERE   insee_com LIKE '__dept__%'
UNION
SELECT  fantoir
FROM    statut_fantoir
UNION
SELECT  fantoir
FROM    cumul_adresses
WHERE   insee_com LIKE '__dept__%'  AND
        (source='OSM' OR (source='BAN' AND COALESCE(voie_osm,'')!='')))
);
                
--top250
CREATE TEMP TABLE top250
as
SELECT l.fantoir,
       code_insee,
       date_creation
FROM   liste_fantoir l
JOIN   (SELECT fantoir10 fantoir,
               code_insee,
               date_creation
        FROM   fantoir_voie 
        WHERE  code_dept = '__dept__') f
USING   (fantoir)
ORDER BY date_creation DESC
LIMIT 250;

-- Géometrie des voies BAN ----
-- 1 point adresse arbitraire ---------
CREATE TEMP TABLE geom
AS
(SELECT DISTINCT fantoir,
        voie_autre,
        FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
FROM    (SELECT c.fantoir,
                voie_autre,
                geometrie
        FROM    cumul_adresses c 
        WHERE   dept = '__dept__' AND
                source = 'BAN') g
JOIN    top250
USING   (fantoir));

-- Assemblage -------------------------
SELECT  co.dep,
        f.code_insee,
        co.libelle,
        g.voie_autre,
        f.fantoir,
        st_x(g.geometrie),
        st_y(g.geometrie),
        to_char(to_date(f.date_creation,'YYYYDDD'),'YYYY-MM-DD')
FROM    top250 f
JOIN    geom g
USING   (fantoir)
JOIN    (SELECT libelle,
                com,
                dep
         FROM   cog_commune
         WHERE  dep = '__dept__' AND
                typecom in ('COM','ARM')) co
ON      co.com = f.code_insee
ORDER BY date_creation DESC,3,4;
