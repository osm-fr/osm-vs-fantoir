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
		WHERE	insee_com like '__dept__'	AND
				voie_osm IS NOT NULL and voie_osm != ''
		GROUP BY insee_com),
v AS (	SELECT 	insee_com,
				count(distinct fantoir) voies_rapprochees
		FROM 	cumul_voies
		WHERE	insee_com like '__dept__'	AND
				fantoir != ''				AND
				voie_osm IS NOT NULL
		GROUP BY insee_com),
vl AS (	SELECT 	c.insee_com,
				count(distinct c.fantoir) voies_rapprochees
		FROM 	cumul_voies c
		JOIN	fantoir_voie f
		ON		c.fantoir = f.code_insee||f.id_voie||f.cle_rivoli 
		WHERE	c.insee_com like '__dept__'	AND
				c.fantoir != ''				AND
				c.voie_osm IS NOT NULL		AND
				f.type_voie = '3'
		GROUP BY c.insee_com),
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
		GROUP BY code_insee),
i AS (	SELECT 	r.format_cadastre,
				c.insee, --Code INSEE
				c.nom, --Commune
				coalesce(a.voies_avec_adresses_rapprochees::integer,0) a, --Voies avec adresses rapprochées (a)
				coalesce(v.voies_rapprochees::integer,0) b, --Toutes voies rapprochées						(b)
				coalesce(vl.voies_rapprochees::integer,0) b1, --Voies rapprochées sur lieux-dits			(bl)
				t.voies_fantoir c, --Voies FANTOIR 															(c)
				f.voies_fantoir d, --Voies FANTOIR + lieux-dits												(d)
				coalesce(((a.voies_avec_adresses_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement avec adresses
				coalesce(((v.voies_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies
				coalesce(((v.voies_rapprochees*100/f.voies_fantoir))::integer,0) --Pourcentage de rapprochement sur voies+lieux-dits
		FROM	communes c
		LEFT OUTER JOIN	v
		ON 		c.insee = v.insee_com
		LEFT OUTER JOIN	vl
		ON 		c.insee = vl.insee_com
		LEFT OUTER JOIN a
		ON 		c.insee = a.insee_com
		JOIN 	t
		ON 		c.insee = t.code_insee
		JOIN 	f
		ON 		c.insee = f.code_insee
		JOIN 	r
		ON 		c.insee = r.insee_com)
SELECT	i.*,--(((a/c::double precision)*(c-a)) + ((b/c::double precision)*(c-b)) + ((b/d::double precision)* (d-b)))::integer
		((power(c-a,2)/c) + (power(b-c,2)/c) + (power(d-b,2)/d))::integer
FROM	i
ORDER  BY 2
