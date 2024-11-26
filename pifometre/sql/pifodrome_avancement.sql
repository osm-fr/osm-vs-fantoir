SELECT *
FROM
(SELECT 'semaine dernière',
	    *
FROM    stats_voies_a_cheval 
WHERE   epoch > (SELECT extract (epoch FROM now()) - (3600 * 24 * 7))
ORDER BY 2
LIMIT   1) s
UNION ALL
(SELECT 'hier',
	    *
FROM    stats_voies_a_cheval
WHERE   epoch > (SELECT extract (epoch FROM now()) - (3600 * 24))
ORDER BY 2
LIMIT   1)
UNION ALL
(SELECT 'maintenant',
	    *
FROM    stats_voies_a_cheval 
ORDER BY 2 DESC
LIMIT   1)
ORDER BY 2 DESC
