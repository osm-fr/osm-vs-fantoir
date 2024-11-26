SELECT 	etape,
		source,
		date_fin
FROM	batch
WHERE	etape = '__etape__'	AND
		cadastre_com = '__cadastre_com__'
ORDER BY source;
