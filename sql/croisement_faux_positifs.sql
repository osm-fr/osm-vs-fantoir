CREATE TEMP TABLE single
AS
WITH
s
AS
(SELECT osm_id,
        code_insee_debut,
        code_insee_fin
FROM    point_croisement_voies_limites
GROUP BY 1,2,3
HAVING  count(*) = 1)
SELECT  geometrie_3857,
        s.*
FROM    s
JOIN    point_croisement_voies_limites
USING   (osm_id);

CREATE INDEX gidx_single_geom ON single USING GIST(geometrie_3857);

CREATE TEMP TABLE admin_points
AS
WITH
ext
AS
(SELECT s.osm_id,
       s.code_insee_debut,
       s.code_insee_fin,
       ST_Distance(geometrie_3857,point_debut_3857) ddeb,
       ST_Distance(geometrie_3857,point_fin_3857) dfin
FROM   single s
JOIN   croisement_voies_limites
USING  (osm_id)),
i
AS
(SELECT osm_id,code_insee_debut AS "ref:INSEE"
FROM    ext
WHERE   ddeb < 0.05
UNION
SELECT  osm_id,code_insee_fin
FROM    ext
WHERE   dfin < 0.05)
SELECT (ST_DumpPoints(ST_Transform(ST_ExteriorRing(way),3857))).geom,
       "ref:INSEE" AS code_insee,
       i.osm_id
FROM   (SELECT *
       FROM    planet_osm_polygon
       WHERE   boundary='administrative' AND
               admin_level = 8 AND
               name != '') p
JOIN   i
USING  ("ref:INSEE");

CREATE INDEX gidx_admin_point_geom ON admin_points USING GIST(geom);

CREATE TEMP TABLE osm_ids
AS
WITH
proches
AS
(SELECT single.*,
        ST_Distance(geometrie_3857,geom)
FROM    admin_points
JOIN    single
USING   (osm_id)
WHERE   geometrie_3857 && geom AND 
        (code_insee = code_insee_debut OR code_insee = code_insee_fin))
SELECT  osm_id --,geometrie_3857,ST_Distance
FROM    proches
WHERE   ST_Distance < 1;

DELETE FROM croisement_voies_limites WHERE osm_id IN (SELECT osm_id FROM osm_ids);
DELETE FROM point_croisement_voies_limites WHERE osm_id IN (SELECT osm_id FROM osm_ids);