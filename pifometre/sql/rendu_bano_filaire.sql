WITH
p
AS
(SELECT way FROM osm2pgsql_polygon WHERE "ref:INSEE" = '__code_insee__'),
fantoir_filaire_rapproches
AS
(SELECT fantoir FROM nom_fantoir WHERE code_insee = '__code_insee__' AND source = 'COMMUNE'
INTERSECT
SELECT fantoir FROM nom_fantoir WHERE code_insee = '__code_insee__' AND source = 'OSM'),
fantoir_voies_bdtopo_rapproches
AS
(SELECT fantoir FROM nom_fantoir WHERE code_insee = '__code_insee__' AND source = 'BDTOPO'
INTERSECT
SELECT fantoir FROM nom_fantoir WHERE code_insee = '__code_insee__' AND source = 'OSM'),
noms_filaire_rapproches
AS
(SELECT nom
FROM    nom_fantoir
JOIN    fantoir_filaire_rapproches
USING   (fantoir)
WHERE   source = 'COMMUNE'),
lignes_brutes
AS
(SELECT row_number() over() AS uniqid,
        osm_id,
        l.way,
        unnest(array[l.name,l.tags->'alt_name',l.tags->'old_name']) AS name,
        COALESCE(a9.code_insee,'xxxxx') as insee_jointure,
        a9.code_insee insee_ac,
        unnest(array["ref:FR:FANTOIR","ref:FR:FANTOIR:left","ref:FR:FANTOIR:right"]) AS fantoir,
        ST_Within(l.way,p.way)::integer as within,
        a9.nom AS nom_ac,
        'OSM' AS source
FROM    p
JOIN    planet_osm_line l
ON      ST_Intersects(l.way, p.way)
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(l.way, a9.geometrie)
WHERE   (l.highway != '' OR
        l.waterway = 'dam')     AND
        l.highway NOT IN ('bus_stop','platform') AND
        l.name != ''
UNION ALL
SELECT  (row_number() over()) + 100000,
        osm_id,
        ST_PointOnSurface(l.way),
        unnest(array[l.name,l.tags->'alt_name',l.tags->'old_name']) AS name,
        COALESCE(a9.code_insee,'xxxxx') as insee_jointure,
        a9.code_insee insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        ST_Within(l.way,p.way)::integer as within,
        a9.nom AS nom_ac,
        'OSM'
FROM    p
JOIN    planet_osm_polygon l
ON      ST_Intersects(l.way, p.way)
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(l.way, a9.geometrie)
WHERE   (l.highway||"ref:FR:FANTOIR" != '' OR l.landuse = 'residential' OR l.amenity = 'parking') AND
        l.highway NOT IN ('bus_stop','platform') AND
        l.name != ''
UNION ALL
SELECT  (row_number() over()) -1000,
        1,
        geometrie,
        nom,
        'xxxxx',
        null,
        '',
        1,
        null,
        'BDTOPO'
FROM    (SELECT geometrie, nom_collaboratif FROM bdtopo_voie_nommee WHERE code_insee = '__code_insee__' AND COALESCE(nom_voie_ban,'') = '') b
JOIN    (SELECT fantoir,nom,nom_brut AS nom_collaboratif FROM nom_fantoir WHERE code_insee = '__code_insee__' AND source = 'BDTOPO') n
USING   (nom_collaboratif)
LEFT OUTER JOIN fantoir_voies_bdtopo_rapproches fbd
USING   (fantoir)
WHERE   fbd.fantoir IS NULL
UNION ALL
SELECT  (row_number() over()) -3000,
        1,
        ST_ExteriorRing(geometrie),
        nf.nom,
        'xxxxx',
        null,
        '',
        1,
        null,
        'CADASTRE'
FROM    (SELECT * FROM lieux_dits WHERE   code_insee = '__code_insee__') l
JOIN    (SELECT * FROM nom_fantoir WHERE   code_insee = '__code_insee__') nf
ON      l.nom = nf.nom_brut
WHERE   GeometryType(geometrie) = 'POLYGON'
UNION ALL
SELECT  (row_number() over()) * -10000,
        1,
        geometrie,
        nom,
        'xxxxx',
        null,
        '',
        1,
        null,
        'COMMUNE'
FROM    (SELECT * FROM commune_filaire WHERE code_insee = '__code_insee__') cf
LEFT OUTER JOIN noms_filaire_rapproches ffr
USING   (nom)
WHERE   ffr.nom IS NULL
UNION ALL
SELECT  row_number() over() * -1,
        osm_id,
        l.way,
        unnest(array[l.name,l.tags->'alt_name',l.tags->'old_name']) AS name,
        COALESCE(a9.code_insee,'xxxxx') as insee_jointure,
        a9.code_insee insee_ac,
        "ref:FR:FANTOIR" AS fantoir,
        ST_Within(l.way,p.way)::integer as within,
        a9.nom AS nom_ac,
        'OSM'
FROM    p
JOIN    planet_osm_rels l
ON      ST_Intersects(l.way, p.way)
LEFT OUTER JOIN (SELECT * FROM polygones_insee_a9 WHERE insee_a8 = '__code_insee__') a9
ON      ST_Intersects(l.way, a9.geometrie)
WHERE   l.member_role = 'street' AND
        l.name != ''),
lignes_hors_commune
AS
(SELECT l.uniqid
FROM    lignes_brutes l
JOIN    osm2pgsql_line o
USING   (osm_id)
CROSS JOIN p
WHERE   ST_Relate(o.way,p.way) = 'FF1F00212'),
lignes_noms
AS
(SELECT CASE 
            WHEN GeometryType(way) LIKE '%POLYGON' THEN ST_ExteriorRing(way)
            ELSE way
        END AS way_line,
        GeometryType(way) AS geomtype,
        *
FROM    lignes_brutes
LEFT OUTER JOIN lignes_hors_commune lhc
USING   (uniqid)
WHERE   name IS NOT NULL AND
        (fantoir LIKE '__code_insee__%' OR fantoir = '') AND
        lhc.uniqid IS NULL),
nom_fantoir_prioritaire -- celui de BANO au format 9 char plutôt que celui brut d'OSM au format variable
AS
(SELECT fantoir,
        nom AS name
FROM    nom_fantoir
WHERE   code_insee = '__code_insee__' AND
        source = 'OSM'),
unionset
AS
(SELECT  name,
        COALESCE(nfp.fantoir,l.fantoir,'') AS nf,
        within,
        source,
        ST_Collect(ST_LineMerge(way_line)) AS geom_collection,
        ST_LineMerge(ST_Collect(way_line)) AS geom
FROM    lignes_noms l
LEFT OUTER JOIN nom_fantoir_prioritaire nfp
USING   (name)
WHERE   geomtype != 'POINT'
GROUP BY 1,2,3,4
UNION ALL
SELECT  name,
        COALESCE(nfp.fantoir,l.fantoir,''),
        within,
        source,
        NULL,
        ST_Collect(way_line)
FROM    lignes_noms l
LEFT OUTER JOIN nom_fantoir_prioritaire nfp
USING   (name)
WHERE   geomtype = 'POINT'
GROUP BY 1,2,3,4),
diag
AS
(SELECT name,
       nf,
       within,
       CASE
           WHEN ST_IsEmpty(geom) THEN geom_collection
           ELSE geom
       END AS geom,
       CASE
           WHEN ST_IsEmpty(geom) THEN ST_BoundingDiagonal(geom_collection)
           ELSE ST_BoundingDiagonal(geom)
       END AS diag,
       source
FROM   unionset)
SELECT name,
       nf,
       within,
       source,
       ST_AsGeoJSON(geom),
       ST_X(ST_StartPoint(diag)),
       ST_Y(ST_StartPoint(diag)),
       ST_X(ST_EndPoint(diag)),
       ST_Y(ST_EndPoint(diag))
FROM   diag
WHERE NOT ST_Isempty(geom);
