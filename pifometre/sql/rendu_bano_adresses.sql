/*WITH s
AS
((SELECT numero AS numero_ban,
         fantoir AS fantoir_ban,
         geometrie AS geometrie_ban,
        'B' AS short_source,
         TRANSLATE(UPPER(numero),' ','') AS uppernumero
 FROM    bano_adresses
 WHERE   code_insee = '__code_insee__' AND
         source     = 'BAN') b
FULL OUTER JOIN   (SELECT numero AS numero_osm,
                          fantoir AS fantoir_osm,
                          geometrie AS geometrie_osm,
                          'O' AS short_source,
                          TRANSLATE(UPPER(numero),' ','') AS uppernumero
                  FROM    bano_adresses
                  WHERE   code_insee = '__code_insee__' AND
                          source     = 'OSM') o
USING (fantoir,uppernumero)
LEFT OUTER JOIN (SELECT uppernumero,fantoir,source,id_statut
                FROM    (SELECT  *,
                                 TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                                 RANK() OVER (PARTITION BY numero,fantoir,source ORDER BY timestamp_statut DESC) rang
                         FROM    statut_numero
                         WHERE   code_insee = '__code_insee__') r
                WHERE   rang = 1) s
USING (uppernumero,fantoir)
LEFT OUTER JOIN (SELECT DISTINCT fantoir,
                        nom,
                        1::boolean AS rapproche 
                FROM    nom_fantoir
                WHERE   code_insee = '__code_insee__' AND
                        source = 'OSM') r
USING (fantoir)
ORDER BY 1)
SELECT COALESCE(r.nom,o.nom_voie,o.nom_place,b.nom_voie,b.nom_place),
       COALESCE(o.fantoir,b.fantoir,null),
       COALESCE(o.numero,b.numero),
       b.geometrie)),
       COALESCE(ST_Y(o.geometrie),ST_Y(b.geometrie)),
       COALESCE(s.id_statut,0),
       COALESCE(o.short_source,b.short_source)||
       CASE
           WHEN o.short_source IS NULL AND NOT r.rapproche THEN 'oo'
           WHEN b.short_source IS NOT NULL AND r.rapproche AND o.numero IS NULL THEN 'Oo'
           WHEN o.short_source IS NOT NULL AND r.rapproche AND b.numero IS NOT NULL THEN 'FB'
           WHEN o.short_source IS NOT NULL AND r.rapproche AND b.numero IS NULL THEN 'Fb'
           ELSE 'xx'
        END AS cat
FROM s
WHERE short_source = 'B'*/

WITH
statut
AS
(SELECT uppernumero,
        fantoir,
        source,
        id_statut
FROM    (SELECT  *,
                 TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                 RANK() OVER (PARTITION BY numero,fantoir,source ORDER BY timestamp_statut DESC) rang
         FROM    statut_numero
         WHERE   code_insee = '__code_insee__') r
WHERE   rang = 1),
nom_osm_rapproche
AS
(SELECT DISTINCT fantoir,
        nom,
        1 AS rapproche 
FROM    nom_fantoir
WHERE   code_insee = '__code_insee__' AND
        source = 'OSM')
SELECT COALESCE(r.nom,o.nom_voie,o.nom_place,b.nom_voie,b.nom_place),
       COALESCE(o.fantoir,b.fantoir,null),
       b.numero,
       ST_X(b.geometrie),
       ST_Y(b.geometrie),
       COALESCE(s.id_statut,0),
       'B' AS source,
       COALESCE(r.rapproche,0) AS nom_rapproche,
       CASE
           WHEN o.numero IS NULL THEN 0
           ELSE 1
        END AS numero_rapproche
FROM   (SELECT *,
               TRANSLATE(UPPER(numero),' ','') AS uppernumero
       FROM    bano_adresses
       WHERE   code_insee = '__code_insee__' AND
               source     = 'BAN') b
LEFT OUTER JOIN  (SELECT  numero,
                          nom_voie,
                          nom_place,
                          fantoir,
                          geometrie,
                          TRANSLATE(UPPER(numero),' ','') AS uppernumero
                  FROM    bano_adresses
                  WHERE   code_insee = '__code_insee__' AND
                          source     = 'OSM') o
USING (fantoir,uppernumero)
LEFT OUTER JOIN statut s
USING (uppernumero,fantoir)
LEFT OUTER JOIN nom_osm_rapproche r
USING (fantoir)
UNION ALL
SELECT COALESCE(r.nom,o.nom_voie,o.nom_place,b.nom_voie,b.nom_place),
       COALESCE(o.fantoir,b.fantoir,null),
       o.numero,
       ST_X(o.geometrie),
       ST_Y(o.geometrie),
       COALESCE(s.id_statut,0),
       'O' AS source,
       COALESCE(r.rapproche,0) AS nom_rapproche,
       CASE
           WHEN b.numero IS NULL THEN 0
           ELSE 1
        END AS numero_rapproche
FROM   (SELECT numero,
               nom_voie,
               nom_place,
               fantoir,
               geometrie,
               TRANSLATE(UPPER(numero),' ','') AS uppernumero
       FROM    bano_adresses
       WHERE   code_insee = '__code_insee__' AND
               source     = 'OSM') o
LEFT OUTER JOIN  (SELECT  numero,
                          nom_voie,
                          nom_place,
                          fantoir,
                          geometrie,
                          TRANSLATE(UPPER(numero),' ','') AS uppernumero
                  FROM    bano_adresses
                  WHERE   code_insee = '__code_insee__' AND
                          source     = 'BAN') b
USING (fantoir,uppernumero)
LEFT OUTER JOIN statut s
USING (uppernumero,fantoir)
LEFT OUTER JOIN nom_osm_rapproche r
USING (fantoir)
ORDER BY 1;