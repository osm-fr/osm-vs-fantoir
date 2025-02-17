WITH
qualif_adresse
AS
(SELECT TRANSLATE(UPPER(numero),' ','') AS uppernumero,
        fantoir,
        id_statut
FROM    (SELECT *,
            RANK() OVER (PARTITION BY numero,fantoir ORDER BY timestamp_statut DESC) rang
            FROM    statut_numero
            WHERE   __condition_fantoir_unique__
                    code_insee = '__code_insee__')r
WHERE   rang = 1),

diff_numero_fantoir
AS
(SELECT uppernumero,
        fantoir
 FROM   (SELECT TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                fantoir 
        FROM    bano_adresses
        WHERE   __condition_fantoir_unique__
                code_insee = '__code_insee__' AND
                source = 'BAN') c
LEFT OUTER JOIN qualif_adresse q
USING   (uppernumero,fantoir)
WHERE   COALESCE(q.id_statut,0) = 0
EXCEPT
SELECT  TRANSLATE(UPPER(numero),' ','') AS numero,
        fantoir
FROM    bano_adresses
WHERE   __condition_fantoir_unique__
        code_insee = '__code_insee__' AND
        source = 'OSM'),

fantoir_numeros_manquants
AS
(SELECT DISTINCT fantoir,count(*) AS a_proposer
FROM    diff_numero_fantoir
GROUP BY 1),

geom_adresses
AS
(SELECT DISTINCT fantoir,
                FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
 FROM    bano_adresses
 WHERE   __condition_fantoir_unique__
         code_insee = '__code_insee__'),

fantoir_avec_adresses_ban
AS
(SELECT DISTINCT fantoir,true AS fantoir_avec_adresses_ban
 FROM   bano_adresses
 WHERE  __condition_fantoir_unique__
        code_insee = '__code_insee__' AND
        source = 'BAN'),

noms_osm
as
(SELECT fantoir,
        ARRAY_AGG(nom_et_tag ORDER BY sortorder) AS noms_et_tags,
        nom_ancienne_commune
FROM    (SELECT DISTINCT fantoir,
                         ARRAY[nom,nom_tag] AS nom_et_tag,
                         CASE nom_tag
                             WHEN 'name' THEN 1
                             WHEN 'alt_name' THEN 2
                             ELSE 3
                         END AS sortorder,
                         nom_ancienne_commune
        FROM  nom_fantoir
        WHERE  __condition_fantoir_unique__
              code_insee = '__code_insee__' AND
              source = 'OSM') s
GROUP BY 1,3),

pn
AS
(SELECT fantoir,
        ARRAY[ARRAY[nom,'name']] AS nom,
        lon,
        lat,
        ROW_NUMBER()OVER(PARTITION BY fantoir ORDER BY lon,lat) AS rn
FROM    bano_points_nommes
WHERE   code_insee = '__code_insee__' AND
        source = 'OSM' AND
        nom_tag = 'name')


SELECT t.fantoir,
       TO_CHAR(TO_TIMESTAMP(t.date_creation::text,'YYYYMMDD'),'YYYY-MM-DD'),
       CASE t.date_annul
           WHEN 0 THEN '1'
           ELSE -1
       END AS fantoir_annule,
       nom_topo,
       COALESCE(noms_osm.noms_et_tags, pn.nom) AS nom_osm,
       nb.nom AS nom_ban,
       nb.source AS source_nom,
       nb.nom_ancienne_commune,
       COALESCE(ST_X(g.geometrie),pn.lon,place.lon,NULL),
       COALESCE(ST_Y(g.geometrie),pn.lat,place.lat,NULL),
       COALESCE(s.id_statut,0),
       a_proposer,
       t.caractere_annul,
       COALESCE(place.is_place,false)::integer,         -- type : voie=0,place=1,OSM hors Fantoir=2
       COALESCE(faab.fantoir_avec_adresses_ban,false)
FROM   (SELECT fantoir,
               date_creation,
               date_annul,
               nature_voie,
               TRIM (BOTH FROM (COALESCE(nature_voie,'')||' '||libelle_voie)) AS nom_topo,
               caractere_annul
        FROM   topo
        WHERE  __condition_fantoir_unique__
               code_insee = '__code_insee__')t
LEFT OUTER JOIN fantoir_numeros_manquants
USING (fantoir)
LEFT OUTER JOIN (SELECT * FROM pn WHERE rn = 1) pn
USING (fantoir)
LEFT OUTER JOIN noms_osm
USING (fantoir)
LEFT OUTER JOIN (SELECT fantoir,
                        lon,
                        lat,
                        true AS is_place
                 FROM   (SELECT fantoir,
                                lon,
                                lat,
                                RANK() OVER (PARTITION BY fantoir ORDER BY CASE source WHEN 'OSM' THEN 1 ELSE 2 END) rang
                        FROM    bano_points_nommes
                        WHERE   __condition_fantoir_unique__
                                code_insee = '__code_insee__' AND
                                nature IN ('place','lieu-dit') AND
                                nom_tag in ('name','nom_cadastre')) p
                 WHERE rang = 1) place
USING (fantoir)
LEFT OUTER JOIN (SELECT fantoir,
                        nom,
                        nom_ancienne_commune,
                        source
                FROM    (SELECT fantoir,
                                nom,
                                nom_ancienne_commune,
                                source,
                                rank() OVER (PARTITION by fantoir order by case when source = 'CADASTRE' then 1 else 2 end) AS rang
                        FROM    nom_fantoir
                        WHERE   __condition_fantoir_unique__
                                code_insee = '__code_insee__' AND
                                source != 'OSM') nb
                WHERE rang = 1)nb
USING (fantoir)
LEFT OUTER JOIN geom_adresses AS g
USING (fantoir)
LEFT OUTER JOIN fantoir_avec_adresses_ban AS faab
USING (fantoir)
LEFT OUTER JOIN (SELECT fantoir,id_statut
                FROM    (SELECT *,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
                        FROM    statut_fantoir
                        WHERE   __condition_fantoir_unique__
                                code_insee = '__code_insee__')r
                WHERE   rang = 1) s
USING (fantoir)
WHERE NOT (t.date_annul != 0 AND pn.nom IS NULL and nb.nom IS NULL)

UNION ALL

SELECT fantoir,
       NULL,
       NULL,
       NULL,
       ARRAY[ARRAY[nom,nom_tag]],
       NULL,
       NULL,
       NULL,
       lon,
       lat,
       0,
       NULL,
       NULL,
       2,
       NULL
FROM   (SELECT *
        FROM   (SELECT *
                FROM   bano_points_nommes
                WHERE  __condition_fantoir_unique__
                       code_insee = '__code_insee__' AND
                       source = 'OSM') b
               LEFT OUTER JOIN
               (SELECT fantoir
                FROM   topo
                WHERE  __condition_fantoir_unique__
                       code_insee = '__code_insee__') f
        USING  (fantoir)
        WHERE  f.fantoir IS NULL) pn
JOIN   (SELECT geometrie
        FROM   polygones_insee
        WHERE  code_insee = '__code_insee__') pl
ON      ST_Contains(pl.geometrie,pn.geometrie)

ORDER BY 1
