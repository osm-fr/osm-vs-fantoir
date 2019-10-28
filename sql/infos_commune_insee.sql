SELECT name,
		ST_X(p),
		ST_Y(p)
FROM	(SELECT	name,
				ST_Transform(ST_Centroid(way),4326) p
		FROM	planet_osm_polygon
		WHERE	boundary='administrative' AND
                admin_level=8 AND
                "ref:INSEE" = '__com__')a;
