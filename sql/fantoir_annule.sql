WITH
f
AS
(SELECT  fantoir10,
         CASE caractere_annul
             WHEN 'O' THEN 'sans transfert'
             WHEN 'Q' THEN 'avec transfert'
         END transfert,
         to_char(to_date(date_annul,'YYYYDDD'),'YYYY-MM-DD') date_annul
FROM	fantoir_voie
where date_annul!='0000000')
SELECT v.fantoir,
       v.voie_osm,
       ST_X(v.geometrie),
       ST_Y(v.geometrie),
       transfert,
       date_annul
FROM   cumul_voies v
JOIN   f
ON  v.fantoir=f.fantoir10
ORDER BY 1

