SELECT COALESCE(o.numero,b.numero),
       ST_X(b.geometrie),
       ST_Y(b.geometrie),
       COALESCE(s.id_statut,0),
       ST_X(o.geometrie),
       ST_Y(o.geometrie)
FROM   (SELECT *,
               TRANSLATE(UPPER(numero),' ','') AS uppernumero
       FROM    bano_adresses
       WHERE   code_insee = '__code_insee__' AND
               fantoir    = '__fantoir__' AND
               source     = 'BAN') b
FULL OUTER JOIN   (SELECT numero,
                          TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                          geometrie
                  FROM    bano_adresses
                  WHERE   code_insee = '__code_insee__' AND
                          fantoir    = '__fantoir__' AND
                          source     = 'OSM') o
USING (uppernumero)
LEFT OUTER JOIN (SELECT uppernumero,fantoir,source,id_statut
                FROM    (SELECT  *,
                                 TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                                 RANK() OVER (PARTITION BY numero,fantoir,source ORDER BY timestamp_statut DESC) rang
                         FROM    statut_numero
                         WHERE   code_insee = '__code_insee__' AND
                                 fantoir = '__fantoir__') r
                WHERE   rang = 1) s
USING (uppernumero,fantoir)
ORDER BY 1;