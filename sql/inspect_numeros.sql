SELECT a.source,
       a.numero,
       n.nom,
       COALESCE(s.id_statut,0),
       cog.libelle,
       a.code_insee,
       ST_X(geometrie),
       ST_Y(geometrie)
FROM   bano_adresses a
JOIN   cog_commune cog
ON     code_insee = com
JOIN   (SELECT fantoir,
               nom
        FROM   nom_fantoir
        WHERE fantoir = '__fantoir__'
        ORDER BY
            CASE source
                WHEN 'OSM' THEN 1
                ELSE 2
            END,
            CASE nature
                WHEN 'voie' THEN 1
                WHEN 'lieu-dit' THEN 2
                ELSE 3
            END
        LIMIT 1) n
USING (fantoir)
LEFT OUTER JOIN (SELECT numero,fantoir,source,id_statut
                FROM    (SELECT  *,rank() OVER (PARTITION BY numero,fantoir,source ORDER BY timestamp_statut DESC) rang
                         FROM    statut_numero
                         WHERE   code_insee = '__code_insee__' AND
                                 fantoir = '__fantoir__')r
                WHERE   rang = 1) s
USING (numero,fantoir,source)
WHERE a.code_insee = '__code_insee__' AND
      a.fantoir = '__fantoir__' AND
      a.source = 'BAN'
ORDER BY numero;