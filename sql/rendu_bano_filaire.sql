WITH
lignes_brutes
AS
(SELECT l.way,
        unnest(array[l.name,l.tags->'alt_name',l.tags->'old_name']) AS name,
        COALESCE(a9.code_insee,'xxxxx') as insee_jointure,
        a9.code_insee insee_ac,
        unnest(array["ref:FR:FANTOIR","ref:FR:FANTOIR:left","ref:FR:FANTOIR:right"]) AS fantoir,
        ST_Within(l.way,p.way)::integer as within,
        a9.nom AS nom_ac
FROM    (SELECT way FROM planet_osm_polygon WHERE "ref:INSEE" = '__code_insee__') p
JOIN    planet_osm_line l
ON      ST_Intersects(l.way, p.way)
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(l.way, a9.geometrie)
WHERE   (l.highway != '' OR
        l.waterway = 'dam')     AND
        l.highway NOT IN ('bus_stop','platform') AND
        l.name != ''
UNION ALL
SELECT  ST_PointOnSurface(l.way),
        unnest(array[l.name,l.tags->'alt_name',l.tags->'old_name']) AS name,
        COALESCE(a9.code_insee,'xxxxx') as insee_jointure,
        a9.code_insee insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        ST_Within(l.way,p.geometrie)::integer as within,
        a9.nom AS nom_ac
FROM    (SELECT geometrie FROM polygones_insee WHERE code_insee = '__code_insee__') p
JOIN    planet_osm_polygon l
ON      ST_Intersects(l.way, p.geometrie)
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(l.way, a9.geometrie)
WHERE   (l.highway||"ref:FR:FANTOIR" != '' OR l.landuse = 'residential' OR l.amenity = 'parking') AND
        l.highway NOT IN ('bus_stop','platform') AND
        l.name != ''
UNION ALL
SELECT l.way,
        unnest(array[l.name,l.tags->'alt_name',l.tags->'old_name']) AS name,
        COALESCE(a9.code_insee,'xxxxx') as insee_jointure,
        a9.code_insee insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        ST_Within(l.way,p.way)::integer as within,
        a9.nom AS nom_ac
FROM    (SELECT way FROM planet_osm_polygon WHERE "ref:INSEE" = '__code_insee__') p
JOIN    planet_osm_rels l
ON      ST_Intersects(l.way, p.way)
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(l.way, a9.geometrie)
WHERE   l.member_role = 'street' AND
        l.name != ''),
lignes_noms
AS
(SELECT CASE 
            --WHEN GeometryType(way) = 'POINT' THEN ST_MakeLine(ST_Translate(way,-0.000001,-0.000001),ST_Translate(way,0.000001,0.000001))
            WHEN GeometryType(way) LIKE '%POLYGON' THEN ST_ExteriorRing(way)
            ELSE way
        END AS way_line,
        *
FROM    lignes_brutes
WHERE   name IS NOT NULL AND
        (fantoir LIKE '__code_insee__%' OR fantoir = '')),
lignes_noms_rang
AS
(SELECT *,
        GeometryType(way) AS geomtype,
        RANK() OVER(PARTITION BY name,insee_ac ORDER BY within DESC, fantoir DESC) rang
FROM    lignes_noms)
SELECT  name,
        ST_AsGeoJSON(ST_LineMerge(ST_Collect(way_line)))
FROM    lignes_noms_rang
WHERE   rang = 1 AND geomtype != 'POINT'
GROUP BY 1
UNION ALL
SELECT  name,
        ST_AsGeoJSON(ST_Collect(way_line))
FROM    lignes_noms_rang
WHERE   rang = 1 AND geomtype = 'POINT'
GROUP BY 1;