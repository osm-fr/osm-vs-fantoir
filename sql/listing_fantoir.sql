WITH
f
AS
(SELECT DISTINCT fantoir,'OUI' AS rapproche
 FROM   nom_fantoir
 WHERE  code_insee = '__code_insee__' AND source = 'OSM'
),
a
AS
(SELECT fantoir,'QUALIFIÉ'::text AS qualifie
FROM 	(SELECT	fantoir,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
	FROM 	statut_fantoir
	WHERE	code_insee = '__code_insee__')r
WHERE	rang = 1)
SELECT 	COALESCE(f.rapproche,a.qualifie,'NON'),
	t.*
FROM	topo t
LEFT OUTER JOIN f
USING (fantoir)
LEFT OUTER JOIN a
USING (fantoir)
WHERE	code_insee = '__code_insee__' AND
        COALESCE(caractere_annul,'x') != 'B' -- Filtre sur les pseudo-Fantoir BAN
ORDER BY 4; 