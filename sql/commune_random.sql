SELECT code_insee
FROM   bano_stats_communales
WHERE  ratio_noms_adr < 20 AND
       nb_nom_ban > 0
ORDER BY random()
LIMIT  1;
