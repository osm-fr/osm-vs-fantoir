SELECT COALESCE(o.nom_voie,o.nom_place,b.nom_voie,b.nom_place),
       COALESCE(o.fantoir,b.fantoir,null),
       COALESCE(o.numero,b.numero),
       ST_X(b.geometrie),
       ST_Y(b.geometrie),
       COALESCE(s.id_statut,0),
       ST_X(o.geometrie),
       ST_Y(o.geometrie),
       COALESCE(r.rapproche,false)
FROM   (SELECT *,
               TRANSLATE(UPPER(numero),' ','') AS uppernumero
       FROM    bano_adresses
       WHERE   code_insee = '__code_insee__' AND
               source     = 'BAN') b
FULL OUTER JOIN   (SELECT *,
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
                        1::boolean AS rapproche 
                FROM    nom_fantoir
                WHERE   code_insee = '__code_insee__' AND
                        source = 'OSM') r
USING (fantoir)
ORDER BY 1;