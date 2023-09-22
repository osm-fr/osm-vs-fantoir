SELECT nom,
       source,
       lon,
       lat,
       COALESCE(o.rapproche,false)
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__' AND
              nature = 'lieu-dit')c
LEFT OUTER JOIN (SELECT fantoir,
                        true::boolean AS rapproche
                FROM    bano_points_nommes
                WHERE   code_insee = '__code_insee__' AND
                        nature = 'place')o
USING (fantoir)
UNION ALL
SELECT nom,
       source,
       lon,
       lat,
       COALESCE(c.rapproche,false)
FROM   (SELECT *
        FROM  bano_points_nommes
        WHERE code_insee = '__code_insee__' AND
              nature = 'place')o
LEFT OUTER JOIN (SELECT fantoir,
                        true::boolean AS rapproche
                FROM    bano_points_nommes
                WHERE   code_insee = '__code_insee__' AND
                        nature = 'lieu-dit')c
USING (fantoir);