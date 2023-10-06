-- Lieux-dits non rapprochés
SELECT nom,
       null::text AS fantoir,
       source,
       lon,
       lat,
       false
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__' AND
              source = 'CADASTRE')c
LEFT OUTER JOIN (SELECT DISTINCT fantoir
                FROM    nom_fantoir
                WHERE   code_insee = '__code_insee__' AND
                        source = 'OSM')o
USING (fantoir)
WHERE o.fantoir IS NULL
UNION ALL
-- Voies & LD sans adresses
SELECT nom,
       o.fantoir,
       source,
       lon,
       lat,
       true
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__' AND
              nature in ('place','centroide')) o
JOIN (SELECT fantoir
        FROM    nom_fantoir
        WHERE   code_insee = '__code_insee__' AND
                source = 'OSM'
        EXCEPT
        SELECT  fantoir
        FROM    nom_fantoir
        WHERE   code_insee = '__code_insee__' AND
                source = 'BAN')c
USING (fantoir)
UNION ALL
-- Liste bleue
SELECT nom,
       null::text,
       source,
       lon,
       lat,
       false
FROM   bano_points_nommes
WHERE  code_insee = '__code_insee__'    AND
       nature in ('place','centroide') AND
       fantoir IS NULL;