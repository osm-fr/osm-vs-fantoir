WITH
latest_statut
AS
(SELECT fantoir,
        label_statut
FROM    (SELECT *,
                RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
        FROM    statut_fantoir)f
JOIN    labels_statuts_fantoir
USING   (id_statut)
WHERE   rang = 1 AND
        id_statut != 0),
ban
AS
(SELECT DISTINCT fantoir
FROM    nom_fantoir
WHERE   code_insee = '__code_insee__' AND
        source = 'BAN')
-- Lieux-dits non rapprochés
SELECT nom,
       fantoir,
       lon,
       lat,
       label_statut,
       CASE source
           WHEN 'CADASTRE' THEN 'Co' -- C = source Cadastre - o = inconnu d'OSM
           WHEN 'BDTOPO' THEN 'To' -- T = source BT Topo - o = inconnu d'OSM
       END||
       CASE
           WHEN ban.fantoir IS NULL THEN 'b'
           ELSE 'B'
       END ||
       CASE source
           WHEN 'CADASTRE' THEN 'P' -- lieu-dit
           WHEN 'BDTOPO' THEN 'V' -- voie nommée
       END
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__' AND
              source in ('CADASTRE','BDTOPO'))c
LEFT OUTER JOIN (SELECT DISTINCT fantoir
                FROM    nom_fantoir
                WHERE   code_insee = '__code_insee__' AND
                        source = 'OSM')o
USING (fantoir)
LEFT OUTER JOIN ban
USING (fantoir)
LEFT OUTER JOIN latest_statut
USING (fantoir)
WHERE o.fantoir IS NULL
UNION ALL
-- Voies & LD OSM
SELECT nom,
       fantoir,
       lon,
       lat,
       label_statut,
       CASE
           WHEN fantoir IS NULL THEN 'Of' -- O = source OSM - f = sans code Fantoir
           ELSE 'OF'                      -- O = source OSM - F = avec code Fantoir
       END ||
       CASE
           WHEN ban.fantoir IS NULL THEN 'b'
           -- WHEN ban.fantoir IS NOT NULL AND nature = 'place' THEN 'B'
          ELSE 'B'
       END ||
       CASE nature
           WHEN 'place' THEN 'P'
           ELSE 'V'
       END
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__'   AND
              nature IN ('place','centroide') AND
              source = 'OSM') o
LEFT OUTER JOIN ban
USING (fantoir)
LEFT OUTER JOIN latest_statut
USING (fantoir)
-- on exclut les rues rapprochées avec adresses
WHERE NOT (nature = 'centroide' AND ban.fantoir IS NOT NULL)
