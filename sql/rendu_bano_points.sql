WITH
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
       'Co'|| -- C = source Cadastre - o = inconnu d'OSM
       CASE
           WHEN ban.fantoir IS NULL THEN 'b'
           ELSE 'B'
       END ||
       'P' -- lieu-dit
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__' AND
              source = 'CADASTRE')c
LEFT OUTER JOIN (SELECT DISTINCT fantoir
                FROM    nom_fantoir
                WHERE   code_insee = '__code_insee__' AND
                        source = 'OSM')o
USING (fantoir)
LEFT OUTER JOIN ban
USING (fantoir)
WHERE o.fantoir IS NULL
UNION ALL
-- Voies & LD OSM
SELECT nom,
       fantoir,
       lon,
       lat,
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
-- on exclut les rues rapprochées avec adresses
WHERE NOT (nature = 'centroide' AND ban.fantoir IS NOT NULL)
