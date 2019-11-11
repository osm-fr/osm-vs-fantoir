SELECT 	"ref:INSEE",
		name
FROM	planet_osm_polygon
WHERE	"ref:INSEE" = '__dept__' AND
        admin_level = 6;
