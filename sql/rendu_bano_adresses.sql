SELECT COALESCE(r.nom,o.nom_voie,o.nom_place,b.nom_voie,b.nom_place),
       COALESCE(o.fantoir,b.fantoir,null),
       COALESCE(o.numero,b.numero),
       COALESCE(ST_X(o.geometrie),ST_X(b.geometrie)),
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
FROM   (SELECT *,
               'B' AS short_source,
               TRANSLATE(UPPER(numero),' ','') AS uppernumero
       FROM    bano_adresses
       WHERE   code_insee = '__code_insee__' AND
               source     = 'BAN') b
FULL OUTER JOIN   (SELECT *,
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
ORDER BY 1;