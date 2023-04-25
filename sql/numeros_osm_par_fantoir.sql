SELECT numero,
       nom
FROM   (SELECT fantoir,
               numero
       FROM    bano_adresses
       WHERE   source = 'OSM' AND
               fantoir = '__fantoir__') num
JOIN    (SELECT fantoir,
                   nom
            FROM   nom_fantoir
            WHERE  fantoir = '__fantoir__'
            ORDER BY 
             CASE source
                 WHEN 'OSM' THEN 1
                 WHEN 'BAN' THEN 2
                 WHEN 'CADASTRE' THEN 3
                 ELSE  4
             END,
             nature
         LIMIT 1) AS nom
USING   (fantoir);