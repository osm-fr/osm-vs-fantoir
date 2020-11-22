SELECT name,
		ST_X(p),
		ST_Y(p)
FROM	(SELECT	name,
				ST_Transform(ST_Centroid(way),4326) p,
				admin_level
		FROM	planet_osm_polygon
		WHERE	boundary='administrative' AND
                admin_level in (8,9) AND
                "ref:INSEE" = '__com__'
        ORDER BY admin_level)a;
