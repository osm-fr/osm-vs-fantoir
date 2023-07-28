-- statut FANTOIR ---------------------
CREATE TEMP TABLE statut_fantoir
AS
(SELECT fantoir,
        id_statut
FROM    (SELECT *,
        RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
FROM    statut_fantoir
WHERE   fantoir LIKE '__dept__%') aa
WHERE   rang = 1         AND
        id_statut != 0);

-- Fantoirs éligibles ---------------
CREATE TEMP TABLE liste_fantoir
AS
(SELECT fantoir
FROM    topo
WHERE   code_dep = '__dept__' and type_voie in ('1','2')
INTERSECT
SELECT  fantoir
FROM    nom_fantoir
WHERE   source = 'BAN' AND code_insee like '__dept__%'
EXCEPT
(SELECT fantoir
FROM    nom_fantoir
WHERE   code_insee LIKE '__dept__%' AND
        source = 'OSM'));
                
--top250
CREATE TEMP TABLE top250
as
SELECT l.fantoir,
       code_insee,
       date_creation
FROM   liste_fantoir l
JOIN   (SELECT fantoir,
               code_insee,
               date_creation
        FROM   topo
        WHERE  code_dep = '__dept__') f
USING   (fantoir)
ORDER BY date_creation DESC
LIMIT 250;

-- Géometrie des voies BAN ----
-- 1 point adresse arbitraire ---------
CREATE TEMP TABLE geom
AS
(SELECT DISTINCT fantoir,
        nom_voie,
        FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
FROM    (SELECT fantoir,
                nom_voie,
                geometrie
        FROM    bano_adresses
        WHERE   code_dept = '__dept__' AND
                source = 'BAN') g
JOIN    top250
USING   (fantoir));

-- Assemblage -------------------------
SELECT  co.dep,
        f.code_insee,
        co.libelle,
        g.nom_voie,
        f.fantoir,
        st_x(g.geometrie),
        st_y(g.geometrie),
        TO_CHAR(TO_TIMESTAMP(date_creation::text,'YYYYMMDD'),'YYYY-MM-DD'),
        COALESCE(id_statut,0)
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
LEFT OUTER JOIN statut_fantoir
USING   (fantoir)
ORDER BY date_creation DESC,3,4;
