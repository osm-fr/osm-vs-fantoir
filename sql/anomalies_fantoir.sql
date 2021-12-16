WITH
fp
AS
(SELECT pt."ref:FR:FANTOIR" FROM planet_osm_point pt
JOIN planet_osm_polygon p
ON  ST_Intersects(pt.way, p.way) AND pt.way && p.way
WHERE pt."ref:FR:FANTOIR" != '' AND
      p."ref:INSEE" = '__dept__' AND
      p.boundary = 'administrative' AND
      p.admin_level = 6
EXCEPT
SELECT fantoir10 FROM fantoir_voie),
fl
AS
(SELECT l."ref:FR:FANTOIR" FROM planet_osm_line l
JOIN planet_osm_polygon p
ON  ST_Intersects(l.way, p.way) AND l.way && p.way
WHERE l."ref:FR:FANTOIR" != '' AND
      p."ref:INSEE" = '__dept__' AND
      p.boundary = 'administrative' AND
      p.admin_level = 6
EXCEPT
SELECT fantoir10 FROM fantoir_voie),
rqfp
AS
(SELECT p."ref:INSEE",
        p.name,
        ST_X(ST_Transform(pt.way,4326)) x,
        ST_Y(ST_Transform(pt.way,4326)) y,
        'n'||pt.osm_id::text,
        CASE
            WHEN pt.name = '' THEN pt."addr:housenumber"||' '||pt."addr:street"
            ELSE pt.name
        END AS name,
        pt."ref:FR:FANTOIR"
FROM    planet_osm_point pt
JOIN    fp
USING   ("ref:FR:FANTOIR")
JOIN    planet_osm_polygon p
ON      ST_Intersects(pt.way, p.way) AND pt.way && p.way
WHERE   p.boundary = 'administrative' AND
        ((p.admin_level=8 AND p."ref:INSEE" NOT IN ('13055','69123','75056')) OR (p.admin_level=9 AND (p."ref:INSEE" LIKE '751__' OR
                                                  p."ref:INSEE" LIKE '6938_' OR
                                                  p."ref:INSEE" LIKE '132__' )))),
rqfl
AS
(SELECT p."ref:INSEE",
        p.name,
        ST_X(ST_Transform(ST_LineInterpolatePoint(pl.way,0.5),4326)) x,
        ST_Y(ST_Transform(ST_LineInterpolatePoint(pl.way,0.5),4326)) y,
        'w'||pl.osm_id::text,
        pl.name,
        pl."ref:FR:FANTOIR"
FROM    planet_osm_line pl
JOIN    fl
USING   ("ref:FR:FANTOIR")
JOIN    planet_osm_polygon p
ON      ST_Intersects(pl.way, p.way) AND pl.way && p.way
WHERE   p.boundary = 'administrative' AND
        ((p.admin_level=8 AND p."ref:INSEE" NOT IN ('13055','69123','75056')) OR (p.admin_level=9 AND (p."ref:INSEE" LIKE '751__' OR
                                                  p."ref:INSEE" LIKE '6938_' OR
                                                  p."ref:INSEE" LIKE '132__' ))))
SELECT *
FROM rqfp
WHERE "ref:INSEE" LIKE '__dept__%'
UNION ALL
SELECT *
FROM rqfl
WHERE "ref:INSEE" LIKE '__dept__%'


/*

WITH
fl
AS
(SELECT l."ref:FR:FANTOIR" FROM planet_osm_line l
JOIN planet_osm_polygon p
ON	ST_Intersects(l.way, p.way) AND l.way && p.way
WHERE l."ref:FR:FANTOIR" != '' AND
      p."ref:INSEE" = '__dept__' AND
      p.boundary = 'administrative' AND
      p.admin_level = 6
EXCEPT
SELECT fantoir10 FROM fantoir_voie
WHERE code_dept = '__dept__'),
fp
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
(SELECT	p."ref:INSEE",
		p.name,
		ST_X(ST_Transform(pt.way,4326)) x,
    ST_Y(ST_Transform(pt.way,4326)) y,
    'n'||pt.osm_id::text,
		CASE
		    WHEN pt.name = '' THEN pt."addr:housenumber"||' '||pt."addr:street"
		    ELSE pt.name
		END AS name,
		pt."ref:FR:FANTOIR"
FROM    planet_osm_point pt
JOIN    fp
USING   ("ref:FR:FANTOIR")
JOIN    planet_osm_polygon pdep
ON      ST_Intersects(pt.way, pdep.way) AND pt.way && pdep.way
JOIN    planet_osm_polygon p
ON	    ST_Intersects(pt.way, p.way) AND pt.way && p.way
WHERE   pdep."ref:INSEE" = '__dept__' AND
        pdep.boundary = 'administrative' AND
        pdep.admin_level = 6 AND
        p.boundary = 'administrative' AND
        ((p.admin_level=8 AND p."ref:INSEE" NOT IN ('13055','69123','75056')) OR (p.admin_level=9 AND (p."ref:INSEE" LIKE '751__' OR
                                                  p."ref:INSEE" LIKE '6938_' OR
                                                  p."ref:INSEE" LIKE '132__' )))
LIMIT 100)
UNION ALL
(SELECT  p."ref:INSEE",
    p.name,
    ST_X(ST_Transform(ST_LineInterpolatePoint(l.way,0.5),4326)) x,
    ST_Y(ST_Transform(ST_LineInterpolatePoint(l.way,0.5),4326)) y,
    'w'||l.osm_id::text,
    l.name,
    l."ref:FR:FANTOIR"
FROM    planet_osm_line l
JOIN    fl
USING   ("ref:FR:FANTOIR")
JOIN    planet_osm_polygon pdep
ON      ST_Intersects(l.way, pdep.way) AND l.way && pdep.way
JOIN    planet_osm_polygon p
ON      ST_Intersects(l.way, p.way) AND l.way && p.way
WHERE   pdep."ref:INSEE" = '__dept__' AND
        pdep.boundary = 'administrative' AND
        pdep.admin_level = 6 AND
        p.boundary = 'administrative' AND
        ((p.admin_level=8 AND p."ref:INSEE" NOT IN ('13055','69123','75056')) OR (p.admin_level=9 AND (p."ref:INSEE" LIKE '751__' OR
                                                  p."ref:INSEE" LIKE '6938_' OR
                                                  p."ref:INSEE" LIKE '132__' )))
LIMIT 100);
*/