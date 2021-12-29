WITH
qualif_adresse
AS
(SELECT TRANSLATE(UPPER(numero),' ','') AS numero,fantoir,insee_com
FROM   (SELECT       *,rank() OVER (PARTITION BY numero,fantoir ORDER BY timestamp_statut DESC) rang
       FROM   statut_numero
       WHERE  fantoir = '__fantoir__')r
WHERE  rang = 1),
diff
AS
((SELECT TRANSLATE(UPPER(numero),' ','') AS uppernum,fantoir,insee_com FROM cumul_adresses WHERE insee_com = '__com__' AND fantoir = '__fantoir__' AND source = 'BAN' 
EXCEPT
SELECT TRANSLATE(UPPER(numero),' ','') AS uppernum,fantoir,insee_com FROM cumul_adresses WHERE insee_com = '__com__' AND fantoir = '__fantoir__' AND  source = 'OSM')
EXCEPT
SELECT numero,fantoir,insee_com FROM qualif_adresse)
SELECT ST_X(c.geometrie),
       ST_Y(c.geometrie),
       c.numero,
       diff.fantoir,
       COALESCE(c.voie_osm,c.voie_autre)
FROM   cumul_adresses c
JOIN   diff
USING  (fantoir,insee_com)
WHERE  source = 'BAN' AND
       TRANSLATE(UPPER(numero),' ','') = uppernum
ORDER BY NULLIF(regexp_replace(numero, '\D', '', 'g'), '')::int;