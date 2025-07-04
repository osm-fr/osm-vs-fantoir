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
dedup_lignes_brutes
as
(select way,name,max(insee_jointure) AS insee_jointure,max(insee_ac) AS insee_ac,max(fantoir) AS fantoir,max(within) AS within,max(nom_ac) AS nom_ac
from lignes_brutes
group by 1,2),
lignes_noms
AS
(SELECT CASE 
            WHEN GeometryType(way) LIKE '%POLYGON' THEN ST_ExteriorRing(way)
            ELSE way
        END AS way_line,
        GeometryType(way) AS geomtype,
        *
FROM    dedup_lignes_brutes
WHERE   name IS NOT NULL AND
        (fantoir LIKE '__code_insee__%' OR fantoir = '')),
nom_fantoir_prioritaire -- celui de BANO au format 9 char plutôt que celui brut d'OSM au format variable
AS
(SELECT DISTINCT fantoir,
        nom AS name
FROM    nom_fantoir
WHERE   code_insee = '__code_insee__' AND
        source = 'OSM'),
linemerge
AS
(SELECT  name,
        COALESCE(nfp.fantoir,l.fantoir,'') AS nf,
        within,
        ST_LineMerge(ST_Collect(way_line)) AS geom
FROM    lignes_noms l
LEFT OUTER JOIN nom_fantoir_prioritaire nfp
USING   (name)
WHERE   geomtype != 'POINT'
GROUP BY 1,2,3),
unionset
AS
(SELECT *
FROM    linemerge
UNION ALL
SELECT  name,
        COALESCE(nfp.fantoir,l.fantoir,''),
        within,
        ST_Collect(way_line)
FROM    lignes_noms l
LEFT OUTER JOIN nom_fantoir_prioritaire nfp
USING   (name)
WHERE   geomtype = 'POINT'
GROUP BY 1,2,3),
mesures
AS
(SELECT name,
        -- ARRAY_AGG(ROUND(ST_M(geom))||'$'||ST_X(geom)::decimal(8,6)||'$'||ST_Y(geom)::decimal(8,6)) AS mesure
        ARRAY_AGG(array[ROUND(ST_M(geom)),ST_X(geom),ST_Y(geom)]) AS mesure
FROM    (SELECT (ST_Dumppoints(ST_Addmeasure(geom,0,ST_LengthSpheroid( geom,'SPHEROID["GRS_1980",6378137,298.257222101]' )))).geom,
                name
        FROM    linemerge) l
GROUP BY 1),
diag
AS
(SELECT name,
       nf,
       within,
       geom,
       ST_BoundingDiagonal(geom) AS diag
FROM   unionset)
SELECT name,
       nf,
       within,
       ST_AsGeoJSON(geom),
       ST_X(ST_StartPoint(diag)),
       ST_Y(ST_StartPoint(diag)),
       ST_X(ST_EndPoint(diag)),
       ST_Y(ST_EndPoint(diag)),
       mesure
FROM   diag
LEFT OUTER JOIN mesures
USING (name);
