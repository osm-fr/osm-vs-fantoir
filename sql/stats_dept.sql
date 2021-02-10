WITH 
r AS (	SELECT	CASE format_cadastre
					WHEN 'IMAG' THEN 'Raster'
					ELSE 'Vecteur'
				END format_cadastre,
				insee_com,
				nom_com
		FROM	code_cadastre
		WHERE	dept = '__dept__'),
a AS (	SELECT 	insee_com,
				count(distinct fantoir) voies_avec_adresses_rapprochees
		FROM 	cumul_adresses
		WHERE	insee_com LIKE '__dept__%'	AND
				COALESCE(voie_osm,'') != ''
		GROUP BY insee_com),
adrOSM AS (	SELECT 	insee_com,
				count(distinct concat(numero,fantoir,voie_osm)) adresses_OSM
		FROM 	cumul_adresses
		WHERE	insee_com LIKE '__dept__%'
		GROUP BY insee_com),
adrBAN AS (	SELECT 	insee_com,
				count(distinct concat(numero,fantoir,voie_autre)) adresses_BAN
		FROM 	cumul_adresses
		WHERE	insee_com LIKE '__dept__%'
		GROUP BY insee_com),
adrnon AS (	SELECT 	insee_com,
				count(distinct concat(numero,fantoir,voie_autre)) adresses_non_rapprochees
		FROM 	cumul_adresses
		WHERE	insee_com LIKE '__dept__%' AND COALESCE(voie_osm,'') = ''
		GROUP BY insee_com),
v AS (	SELECT 	insee_com,
				count(distinct fantoir) voies_rapprochees
		FROM 	cumul_voies
		WHERE	insee_com LIKE '__dept__%'	AND
				COALESCE(fantoir,'') != ''	AND
				voie_osm IS NOT NULL
		GROUP BY insee_com),
vl AS (	SELECT 	c.insee_com,
				count(distinct c.fantoir) voies_rapprochees
		FROM 	(SELECT insee_com,
                        fantoir
                FROM    cumul_voies
                WHERE   insee_com LIKE '__dept__%'  AND
                        COALESCE(fantoir,'') != ''  AND
                        voie_osm IS NOT NULL) c
        JOIN    (SELECT fantoir10
                FROM    fantoir_voie
                WHERE type_voie = '3') f
		ON		c.fantoir = f.fantoir10
		GROUP BY c.insee_com),
t AS (	SELECT 	code_insee AS insee_com,
				count(*) voies_fantoir
		FROM 	fantoir_voie
		WHERE	code_insee LIKE '__dept__%'	AND
				type_voie in ('1','2')
		GROUP BY code_insee),
f AS (	SELECT 	code_insee AS insee_com,
				count(*) voies_fantoir
		FROM 	fantoir_voie
		WHERE	code_insee LIKE '__dept__%'	AND
				type_voie in ('1','2','3')
		GROUP BY code_insee),
i AS (	SELECT 	r.format_cadastre,
				r.insee_com, --Code INSEE
				r.nom_com, --Commune
				coalesce(a.voies_avec_adresses_rapprochees::integer,0) a, --Voies avec adresses rapprochées (a)
				coalesce(v.voies_rapprochees::integer,0) b, --Toutes voies rapprochées (b)
				coalesce(vl.voies_rapprochees::integer,0) b1, --Voies rapprochées sur lieux-dits (bl)
				t.voies_fantoir c, --Voies FANTOIR (c)
				f.voies_fantoir d, --Voies FANTOIR + lieux-dits (d)
				coalesce(((a.voies_avec_adresses_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement avec adresses
				coalesce(((v.voies_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies
				coalesce(((v.voies_rapprochees*100/f.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies+lieux-dits
				coalesce(adrOSM.adresses_OSM::integer,0), --Adresses OSM
				coalesce(adrBAN.adresses_BAN::integer,0), --Adresses BAN, BAL
				coalesce(adrnon.adresses_non_rapprochees::integer,0), --Adresses sans voie rapprochée
				coalesce(((100-adrnon.adresses_non_rapprochees*100/adrBAN.adresses_BAN))::integer,100) --Pourcentage d'adresses avec voie rapprochée
		FROM	r
		LEFT OUTER JOIN v USING (insee_com)
		LEFT OUTER JOIN vl USING (insee_com)
		LEFT OUTER JOIN a USING (insee_com)
		LEFT OUTER JOIN adrOSM USING (insee_com)
		LEFT OUTER JOIN adrBAN USING (insee_com)
		LEFT OUTER JOIN adrnon USING (insee_com)
		JOIN 	t USING (insee_com)
		JOIN 	f USING (insee_com))
SELECT	i.*,--(((a/c::double precision)*(c-a)) + ((b/c::double precision)*(c-b)) + ((b/d::double precision)* (d-b)))::integer
		((power(c-a,2)/c) + (power(b-c,2)/c) + (power(d-b,2)/d))::integer
FROM	i
ORDER  BY 2
