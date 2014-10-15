SELECT nom,
		ST_X(p),
		ST_Y(p)
FROM	(SELECT	nom,
				ST_Centroid(wkb_geometry) p
		FROM	communes
		WHERE	insee = '__com__')a;
