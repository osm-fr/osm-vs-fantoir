WITH
r
AS
(SELECT DISTINCT (s.rel_id * -1) AS rel_id,
       i.insee_com,
       i.name,
       p.population,
       RANK() OVER(PARTITION BY i.insee_com ORDER BY s.admin_level) rang
FROM   infos_communes i
JOIN   population_insee p
USING  (insee_com)
JOIN   planet_osm_communes_statut s
ON     (i.insee_com = s."ref:INSEE")
WHERE  i.dep = '__dept__' AND
       s.boundary = 'administrative' AND
       s.admin_level in (8,9) AND
       i.population != p.population)
SELECT rel_id,
       insee_com,
       name,
       population
FROM   r
WHERE  rang = 1
ORDER BY 2