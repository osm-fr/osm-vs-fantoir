SELECT  co.dep,
        f.code_insee,
        co.libelle,
        f.nom,
        f.fantoir,
        lon,
        lat
FROM    (SELECT * FROM bano_points_nommes WHERE code_dept = '__dept__' AND nature = 'numero') f
JOIN    (SELECT libelle,
                com AS code_insee,
                dep
         FROM   cog_commune
         WHERE  dep = '__dept__' AND
                typecom in ('COM','ARM')) co
USING   (code_insee)
ORDER BY fantoir;
