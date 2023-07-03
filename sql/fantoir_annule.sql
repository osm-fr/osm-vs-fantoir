SELECT DISTINCT p.fantoir,
       nom,
       ST_X(geometrie),
       ST_Y(geometrie),
       date_annul,
       dep,
       libelle
FROM   bano_points_nommes p
JOIN   (SELECT  fantoir,
                TO_CHAR(TO_DATE(date_annul::text,'YYYYMMDD'),'YYYY-MM-DD') date_annul
FROM   topo
WHERE  date_annul!= 0)f
USING  (fantoir)
JOIN   (SELECT dep,
               com AS code_insee,
               libelle
       FROM cog_commune
       WHERE typecom = 'COM') c
USING  (code_insee)
ORDER  BY 1

