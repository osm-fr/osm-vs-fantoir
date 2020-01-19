WITH
dep
as
(SELECT dep,
        count(*) nb_com
FROM    cog_commune 
GROUP BY 1),
pop2017
AS
(SELECT dep,
        count(distinct insee_com) nb_com_ok
FROM population_insee p
JOIN infos_communes i
USING (insee_com,population)
GROUP BY dep)
SELECT cog.libelle,
       dep.*,
       coalesce(nb_com_ok,0),
       coalesce((100*nb_com_ok::numeric/nb_com)::float(1),0) AS pct
FROM dep
JOIN cog_departement cog
USING (dep)
LEFT OUTER JOIN pop2017
USING (dep)
WHERE dep IS NOT NULL
ORDER BY pct DESC,1;