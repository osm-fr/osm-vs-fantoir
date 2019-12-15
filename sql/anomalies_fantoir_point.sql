WITH
f
AS
(SELECT pt."ref:FR:FANTOIR" FROM planet_osm_point pt
JOIN planet_osm_polygon p
ON	ST_Intersects(pt.way, p.way) AND pt.way && p.way
WHERE pt."ref:FR:FANTOIR" != '' AND
      p."ref:INSEE" = '__dept__' AND
      p.boundary = 'administrative' AND
      p.admin_level = 6
EXCEPT
SELECT fantoir10 FROM fantoir_voie
WHERE code_dept = '__dept__')
SELECT	p."ref:INSEE",
		p.name,
		ST_X(ST_Transform(pt.way,4326)) x,
        ST_Y(ST_Transform(pt.way,4326)) y,
		pt.osm_id,
		CASE
		    WHEN pt.name = '' THEN pt."addr:housenumber"||' '||pt."addr:street"
		    ELSE pt.name
		END AS name,
		pt."ref:FR:FANTOIR"
FROM    planet_osm_point pt
JOIN    f
USING   ("ref:FR:FANTOIR")
JOIN    planet_osm_polygon p
ON	    ST_Intersects(pt.way, p.way) AND pt.way && p.way
WHERE   p.boundary = 'administrative' AND
        ((p.admin_level=8 AND p."ref:INSEE" NOT IN ('13055','69123','75056')) OR (p.admin_level=9 AND (p."ref:INSEE" LIKE '751__' OR
                                                  p."ref:INSEE" LIKE '6938_' OR
                                                  p."ref:INSEE" LIKE '132__' )));

