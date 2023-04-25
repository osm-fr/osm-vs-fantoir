SELECT ABS(p.osm_id)
FROM   planet_osm___type_geom__ p
JOIN   planet_osm_polygon pl
ON     pl.way && p.way                           AND
       ST_Intersects(pl.way, p.way)
WHERE  pl."ref:INSEE" = '__code_insee__'         AND
       p."addr:housenumber" IN (__numeros_OSM__) AND
       p."addr:street" = '__name__'              AND
       p.osm_id __signe__ 0;