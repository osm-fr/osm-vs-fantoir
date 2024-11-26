WITH
cog AS  (       SELECT com AS code_insee,
                       libelle
                FROM   cog_commune c
                LEFT OUTER JOIN (SELECT comparent FROM cog_commune WHERE dep = '__dept__' AND typecom = 'ARM') p
                ON     (c.com = p.comparent)
                WHERE  c.dep = '__dept__' AND
                       c.typecom != 'COMD' AND
                       p.comparent IS NULL
                ORDER BY 1),
r AS    (       SELECT  (nb_numeros_certifies::decimal * 100 / greatest(nb_numeros::decimal,1.0))::integer AS pct_certifie,
                        code_insee
                FROM    communes_summary
                WHERE   dep = '__dept__'),
a AS (          SELECT  code_insee,
                        count(*) voies_avec_adresses_rapprochees
                FROM    (SELECT fantoir,
                                code_insee
                        FROM   bano_adresses
                        WHERE  code_dept = '__dept__' AND
                                source = 'BAN'
                        INTERSECT
                        SELECT fantoir,
                               code_insee
                        FROM   nom_fantoir
                        WHERE  code_dept = '__dept__' AND
                               source = 'OSM') a
                GROUP BY code_insee),
adrOSM AS (     SELECT  code_insee,
                        count(*) adresses_OSM
                FROM    bano_adresses
                WHERE   code_dept = '__dept__' AND
                        source = 'OSM'
                GROUP BY code_insee),
adrBAN AS (     SELECT  code_insee,
                        count(*) adresses_BAN
                FROM    bano_adresses
                WHERE   code_dept = '__dept__' AND
                        source = 'BAN'
                GROUP BY code_insee),
adrnon AS (     SELECT  code_insee,
                        count(distinct concat(numero,b.fantoir)) adresses_non_rapprochees
                FROM    (SELECT code_insee,numero,fantoir
                        FROM    bano_adresses
                        WHERE   code_dept = '__dept__' AND
                                source = 'BAN')b
                LEFT OUTER JOIN (SELECT fantoir
                                 FROM   nom_fantoir
                                 WHERE  source = 'OSM' AND
                                        code_dept = '__dept__')o
                USING (fantoir)
                WHERE o.fantoir IS NULL
                GROUP BY code_insee),
v AS (  SELECT          code_insee,
                        count(distinct fantoir) voies_rapprochees
                FROM    nom_fantoir
                WHERE   code_dept = '__dept__'  AND
                        fantoir IS NOT NULL     AND
                        nature = 'voie'         AND
                        source = 'OSM'
                GROUP BY code_insee),
vl AS (  SELECT          code_insee,
                        count(distinct fantoir) voies_rapprochees
                FROM    nom_fantoir
                WHERE   code_dept = '__dept__'  AND
                        fantoir IS NOT NULL     AND
                        source = 'OSM'
                GROUP BY code_insee),
t AS (  SELECT          code_insee,
                        count(*) voies_fantoir
                FROM    topo
                WHERE   code_dep = '__dept__'     AND
                        type_voie in ('1','2')
                GROUP BY code_insee),
f AS (  SELECT          code_insee,
                        count(*) voies_fantoir
                FROM    topo
                WHERE   code_dep = '__dept__'     AND
                        type_voie in ('1','2','3')
                GROUP BY code_insee),
i AS (  SELECT  cog.code_insee, --Code INSEE
                cog.libelle, --Commune
                COALESCE(r.pct_certifie,0),
                COALESCE(a.voies_avec_adresses_rapprochees::integer,0) a, --Voies avec adresses rapprochées (a)
                COALESCE(v.voies_rapprochees::integer,0) b, --Toutes voies rapprochées (b)
                COALESCE(vl.voies_rapprochees::integer,0) b1, --Voies rapprochées sur lieux-dits (bl)
                COALESCE(t.voies_fantoir::integer,0) c, --Voies FANTOIR (c)
                f.voies_fantoir d, --Voies FANTOIR + lieux-dits (d)
                COALESCE(((a.voies_avec_adresses_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement avec adresses
                COALESCE(((v.voies_rapprochees*100/t.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies
                COALESCE(((v.voies_rapprochees*100/f.voies_fantoir))::integer,0), --Pourcentage de rapprochement sur voies+lieux-dits
                COALESCE(adrOSM.adresses_OSM::integer,0), --Adresses OSM
                COALESCE(adrBAN.adresses_BAN::integer,0), --Adresses BAN, BAL
                COALESCE(adrnon.adresses_non_rapprochees::integer,0), --Adresses sans voie rapprochée
                COALESCE(((100-adrnon.adresses_non_rapprochees*100/adrBAN.adresses_BAN))::integer,100) --Pourcentage d'adresses avec voie rapprochée
        FROM    cog
        LEFT OUTER JOIN r USING (code_insee)
        LEFT OUTER JOIN v USING (code_insee)
        LEFT OUTER JOIN vl USING (code_insee)
        LEFT OUTER JOIN a USING (code_insee)
        LEFT OUTER JOIN adrOSM USING (code_insee)
        LEFT OUTER JOIN adrBAN USING (code_insee)
        LEFT OUTER JOIN adrnon USING (code_insee)
        LEFT OUTER JOIN    t USING (code_insee)
        JOIN    f USING (code_insee))
SELECT  i.*,
        CASE
            WHEN c = 0 THEN 0
            ELSE ((power(c-a,2)/c) + (power(b-c,2)/c) + (power(d-b,2)/d))::integer
        END
FROM    i
ORDER  BY 2
