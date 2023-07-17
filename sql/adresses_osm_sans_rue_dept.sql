SELECT  co.dep,
        f.code_insee,
        co.libelle,
        f.nom,
        f.fantoir,
        lon,
        lat,
        caractere_annul,
        COALESCE(id_statut,0)
FROM    (SELECT * FROM bano_points_nommes WHERE code_dept = '__dept__' AND nature = 'numero') f
JOIN    (SELECT libelle,
                com AS code_insee,
                dep
         FROM   cog_commune
         WHERE  dep = '__dept__' AND
                typecom in ('COM','ARM')) co
USING   (code_insee)
JOIN    (SELECT fantoir, caractere_annul FROM topo WHERE code_dep = '__dept__') t
USING   (fantoir)
LEFT OUTER JOIN (SELECT fantoir,id_statut
                FROM    (SELECT *,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
                        FROM    statut_fantoir) r
                WHERE   rang = 1) i
USING (fantoir)
ORDER BY fantoir;
