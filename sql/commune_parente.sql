
SELECT cp.com,
       cp.libelle
FROM   cog_commune cd
JOIN   cog_commune cp
ON     cd.comparent = cp.com
WHERE  cd.com = '__com__'    AND
       cp.com != cd.com      AND
       cd.typecom = 'COMD'   AND
	   cp.typecom = 'COM';