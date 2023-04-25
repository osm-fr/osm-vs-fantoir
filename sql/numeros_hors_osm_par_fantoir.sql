WITH
qualif_adresse
AS
(SELECT TRANSLATE(UPPER(numero),' ','') AS numero,fantoir,code_insee
FROM   (SELECT       *,rank() OVER (PARTITION BY numero,fantoir ORDER BY timestamp_statut DESC) rang
       FROM   statut_numero
       WHERE  fantoir = '__fantoir__')r
WHERE  rang = 1),
diff
AS
((SELECT TRANSLATE(UPPER(numero),' ','') AS uppernum,fantoir,code_insee FROM bano_adresses WHERE code_insee = '__code_insee__' AND fantoir = '__fantoir__' AND source = 'BAN' 
EXCEPT
SELECT TRANSLATE(UPPER(numero),' ','') AS uppernum,fantoir,code_insee FROM bano_adresses WHERE code_insee = '__code_insee__' AND fantoir = '__fantoir__' AND  source = 'OSM')
EXCEPT
SELECT numero,fantoir,code_insee FROM qualif_adresse)
SELECT ST_X(c.geometrie),
       ST_Y(c.geometrie),
       c.numero,
       diff.fantoir,
       nom.nom
FROM   bano_adresses c
JOIN   diff
USING  (fantoir,code_insee)
JOIN   (SELECT fantoir,
               nom
       FROM    nom_fantoir
       WHERE   fantoir = '__fantoir__'
       ORDER BY 
           CASE source
               WHEN 'OSM' THEN 1
               WHEN 'BAN' THEN 2
               WHEN 'CADASTRE' THEN 3
               ELSE  4
           END,
           nature
       LIMIT 1) AS nom
USING (fantoir)
WHERE  source = 'BAN' AND
       TRANSLATE(UPPER(numero),' ','') = uppernum
ORDER BY NULLIF(regexp_replace(numero, '\D', '', 'g'), '')::int;