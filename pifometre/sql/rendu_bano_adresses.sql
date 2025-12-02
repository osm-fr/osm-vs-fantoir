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
       'BAN' AS source,
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
       'OSM' AS source,
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