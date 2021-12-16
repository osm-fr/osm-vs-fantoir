
SELECT cp.com,
       cp.libelle
FROM   cog_commune cd
JOIN   cog_commune cp
ON     cd.comparent = cp.com
WHERE  cd.com = '__com__'    AND
       cp.com != cd.com      AND
       cd.typecom = 'COMD'   AND
	   cp.typecom = 'COM'
UNION
SELECT    p8.insee_com,
          p8.nom
FROM      polygones_insee p9
LEFT JOIN cog_commune
ON        p9.insee_com = com
JOIN      polygones_insee p8
ON        ST_Contains(p8.geometrie,p9.geometrie)
WHERE     p9.insee_com = '__com__' AND
          p9.admin_level = 9       AND
	      p8.admin_level = 8       AND
          typecom IS NULL;