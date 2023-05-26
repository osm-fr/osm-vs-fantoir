SELECT nom,
		ST_X(p),
		ST_Y(p),
		date_debut,
		commune_composee
FROM	(SELECT	nom,
				ST_Centroid(geometrie) p,
				admin_level,
				code_insee AS code_zone
		FROM	polygones_insee
		WHERE	admin_level in (8,9) AND
                code_insee = '__code_insee__'
        ORDER BY admin_level
        LIMIT 1)a
JOIN    (SELECT code_zone,date_debut
         FROM batch
         WHERE code_zone = '__code_insee__' AND
               etape = 'rapprochement') r
USING   (code_zone)
CROSS JOIN (SELECT COALESCE(MAX(c),0) commune_composee
           FROM (SELECT 1 AS c 
           	     FROM   ban
           	     WHERE  code_insee = '__code_insee__' AND
           	            nom_ancienne_commune IS NOT NULL LIMIT 1)a)b
