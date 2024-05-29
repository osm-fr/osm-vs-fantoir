SELECT code_insee
FROM   bano_stats_communales
WHERE  ratio_noms_adr < 10
ORDER BY random()
LIMIT  1;
