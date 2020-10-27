SELECT c.source,
       c.numero,
       c.voie_cadastre,
       c.voie_osm,
       COALESCE(s.id_statut,0)
FROM   cumul_adresses c
LEFT OUTER JOIN (SELECT numero,fantoir,source,id_statut
                FROM    (SELECT  *,rank() OVER (PARTITION BY numero,fantoir,source ORDER BY timestamp_statut DESC) rang
                         FROM    statut_adresse
                         WHERE   insee_com = '__com__' AND
                                 fantoir = '__fantoir__')r
                WHERE   rang = 1) s
USING (numero,fantoir,source)
WHERE c.insee_com = '__com__' AND
      c.fantoir = '__fantoir__';