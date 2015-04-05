WITH 
r AS (	SELECT	insee_com,
				CASE format_cadastre
					WHEN 'IMAG' THEN 'Raster'
					ELSE 'Vecteur'
				END format_cadastre
		FROM	code_cadastre
		WHERE	insee_com like '__dept__'),
a AS (	SELECT 	insee_com,
				count(distinct fantoir) voies_avec_adresses_rapprochees
		FROM 	cumul_adresses
		WHERE	insee_com like '__dept__' and voie_osm IS NOT NULL and voie_osm != ''
		GROUP BY insee_com),
v AS (	SELECT 	insee_com,
				count(distinct fantoir) voies_rapprochees
		FROM 	cumul_voies
		WHERE	insee_com like '__dept__' and voie_osm IS NOT NULL
		GROUP BY insee_com),
t AS (	SELECT 	code_insee,
				count(*) voies_fantoir
		FROM 	fantoir_voie
		WHERE	code_insee like '__dept__'	AND
				type_voie in ('1','2')
		GROUP BY code_insee),
f AS (	SELECT 	code_insee,
				count(*) voies_fantoir
		FROM 	fantoir_voie
		WHERE	code_insee like '__dept__'	AND
				type_voie in ('1','2','3')
		GROUP BY code_insee)
SELECT 	r.format_cadastre,
		c.insee, --Code INSEE
		c.nom, --Commune
		coalesce(a.voies_avec_adresses_rapprochees::integer,0), --Voies avec adresses rapprochées
		coalesce(v.voies_rapprochees::integer,0), --Toutes voies rapprochées
		t.voies_fantoir, --Voies FANTOIR
		f.voies_fantoir, --Voies FANTOIR + lieux-dits
		coalesce(((a.voies_avec_adresses_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement avec adresses
		coalesce(((v.voies_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies
		coalesce(((v.voies_rapprochees*100/f.voies_fantoir))::integer,0) --Pourcentage de rapprochement sur voies+lieux-dits
FROM	communes c
LEFT OUTER JOIN	v
ON 		c.insee = v.insee_com
LEFT OUTER JOIN a
ON 		c.insee = a.insee_com
JOIN 	t
ON 		c.insee = t.code_insee
JOIN 	f
ON 		c.insee = f.code_insee
JOIN 	r
ON 		c.insee = r.insee_com
ORDER  BY 2
