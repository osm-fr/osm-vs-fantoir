SELECT DISTINCT p.fantoir,
       nom,
       ST_X(geometrie),
       ST_Y(geometrie),
       date_annul,
       dep,
       libelle
FROM   (SELECT  nom,
                fantoir,
                code_insee,
                geometrie
        FROM    bano_points_nommes
        WHERE   code_dept = '__dept__') p
JOIN   (SELECT  fantoir,
                TO_CHAR(TO_DATE(date_annul::text,'YYYYMMDD'),'YYYY-MM-DD') date_annul
        FROM    topo
        WHERE   code_dep = '__dept__' AND
                date_annul!= 0)f
USING  (fantoir)
JOIN   (SELECT dep,
               com AS code_insee,
               libelle
       FROM    cog_commune
       WHERE   typecom = 'COM' AND
               dep = '__dept__') c
USING  (code_insee)
ORDER  BY 1

