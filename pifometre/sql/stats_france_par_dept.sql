SELECT dep||' '||libelle,
       nb_communes,
       nb_adresses_osm,
       nb_adresses_ban,
       (nb_adresses_osm * 100/nb_adresses_ban)::integer,
       nb_voies_ban_rapprochees,
       nb_voies_ban,
       (nb_voies_ban_rapprochees * 100/nb_voies_ban)::integer,
       nb_bal,
       TO_CHAR(maj, 'yyyy-mm-dd HH24:MI')
FROM   bano_stats_departementales
JOIN   cog_departement
USING  (dep)
UNION ALL
SELECT 'France',
       SUM(nb_communes),
       SUM(nb_adresses_osm),
       SUM(nb_adresses_ban),
       (SUM(nb_adresses_osm) * 100/SUM(nb_adresses_ban))::integer,
       SUM(nb_voies_ban_rapprochees),
       SUM(nb_voies_ban),
       (SUM(nb_voies_ban_rapprochees) * 100/SUM(nb_voies_ban))::integer,
       SUM(nb_bal),
       ''
FROM   bano_stats_departementales
JOIN   cog_departement
USING  (dep)
ORDER BY 1          
