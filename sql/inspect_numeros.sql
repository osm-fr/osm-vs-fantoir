SELECT c.source,
       c.numero,
       c.voie_osm,
       c.voie_autre,
       COALESCE(s.id_statut,0),
       cog.libelle,
       c.insee_com,
       ST_X(geometrie),
       ST_Y(geometrie)
FROM   cumul_adresses c
JOIN   cog_commune cog
ON     insee_com = com
LEFT OUTER JOIN (SELECT numero,fantoir,source,id_statut
                FROM    (SELECT  *,rank() OVER (PARTITION BY numero,fantoir,source ORDER BY timestamp_statut DESC) rang
                         FROM    statut_numero
                         WHERE   insee_com = '__com__' AND
                                 fantoir = '__fantoir__')r
                WHERE   rang = 1) s
USING (numero,fantoir,source)
WHERE c.insee_com = '__com__' AND
      c.fantoir = '__fantoir__' AND
      c.source = 'BAN'
ORDER BY numero;