CREATE OR REPLACE
    FUNCTION centroides_communes(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN

SELECT INTO mvt ST_AsMVT(q, 'centroides_communes', 4096, 'geom')
FROM (
    SELECT  code_insee,
            nom,
            CASE
                WHEN population_rel > 100000 THEN 1
                WHEN code_insee LIKE '97%' THEN 1
                WHEN population_rel >  50000 THEN 2
                WHEN population_rel >  10000 THEN 3
                ELSE 4
            END AS class_pop,
            'admin' as layer,
            nb_adresses_osm,
            nb_adresses_ban,
            nb_noms_osm,
            nb_noms_ban,
            nb_noms_topo,
            ST_AsMvtGeom(
                geom_centroide_3857,
                ST_TileEnvelope(z, x, y),
                4096,
                256,
                false
            ) AS geom
    FROM polygones_insee
    JOIN (  SELECT DISTINCT "ref:INSEE" AS code_insee,
                            population_rel
            FROM planet_osm_communes_statut
            WHERE "ref:INSEE" != '') p
    USING (code_insee)
    JOIN (  SELECT code_insee,
               CASE
                   WHEN nb_adresses_ban > 0 THEN nb_adresses_osm * 25 / nb_adresses_ban
                   ELSE 50
               END AS ratio_adresses,
               CASE
                   WHEN nb_nom_topo > 0 THEN nb_nom_osm * 75 / nb_nom_topo
                   ELSE 50
               END AS ratio_noms,
              nb_adresses_osm,
              GREATEST(1,nb_adresses_ban) AS nb_adresses_ban,
              nb_nom_osm AS nb_noms_osm,
              GREATEST(1,nb_nom_ban) AS nb_noms_ban,
              GREATEST(1,nb_nom_topo) AS nb_noms_topo
            FROM bano_stats_communales) AS s
  USING (code_insee)
  JOIN (SELECT com
       FROM    cog_commune
       WHERE   typecom IN ('COM','ARM')) cog
  ON   (code_insee = com)
  WHERE geom_centroide_3857 && ST_TileEnvelope(z, x, y) AND
        ST_Intersects(geom_centroide_3857, ST_TileEnvelope(z, x, y)) AND
        code_insee != '' AND
        ((admin_level = 8 AND code_insee NOT IN ('13055','69123','75056')) OR
         (admin_level = 9 AND (code_insee LIKE '751__' OR code_insee LIKE '6938_' OR code_insee LIKE '132__')))
    ) AS q;

RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE
    FUNCTION lieudit_cadastre(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN

SELECT INTO mvt ST_AsMVT(q, 'lieudit_cadastre', 4096, 'geom')
FROM (
      WITH
      cadastre
      AS
      (SELECT code_insee,fantoir,nom,geometrie_3857
      FROM    bano_points_nommes
      WHERE   ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y)) AND
              source = 'CADASTRE'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM cadastre),
      fantoir_osm
      AS
      (SELECT DISTINCT fantoir
      FROM  bano_points_nommes
      JOIN liste_insee
      USING (code_insee)
      WHERE source = 'OSM'),
      resultat
      as
      (SELECT nom,
              fantoir,
              CASE WHEN fantoir_osm.fantoir IS NULL THEN false ELSE true END rapproche,
              geometrie_3857
      FROM    cadastre
      LEFT OUTER JOIN fantoir_osm
      USING (fantoir))
      SELECT nom,
             fantoir,
             rapproche,
             'lieudit_CADASTRE' as layer,
             ST_AsMvtGeom(
                 geometrie_3857,
                 ST_TileEnvelope(z, x, y),
                 4096,
                 256,
                 false) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y))
) AS q;

RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE
    FUNCTION place_osm(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN

SELECT INTO mvt ST_AsMVT(q, 'place_osm', 4096, 'geom')
FROM (
      WITH
      osm
      AS
      (SELECT code_insee,fantoir,nom,geometrie_3857
      FROM    bano_points_nommes
      WHERE   ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y)) AND
              nature = 'place' AND
              source = 'OSM'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM osm),
      fantoir
      AS
      (SELECT DISTINCT fantoir
      FROM  bano_points_nommes
      JOIN liste_insee
      USING (code_insee)
      WHERE source != 'OSM'),
      resultat
      as
      (SELECT nom,
              fantoir,
              CASE WHEN fantoir.fantoir IS NULL THEN false ELSE true END rapproche,
              geometrie_3857
      FROM    osm
      LEFT OUTER JOIN fantoir
      USING (fantoir))
      SELECT nom,
             fantoir,
             rapproche,
             'place_OSM' as layer,
             ST_AsMvtGeom(
                 geometrie_3857,
                 ST_TileEnvelope(z, x, y),
                 4096,
                 256,
                 false) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y))
) AS q;

RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE
    FUNCTION polygones_convexhull(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN

SELECT INTO mvt ST_AsMVT(q, 'polygones_convexhull', 4096, 'geom')
FROM (
	select 	ST_AsMVTGeom(
				st_buffer(st_convexhull(st_collect(aall.geometrie_3857)), 10,3),
				ST_TileEnvelope(z, x, y),
				4096,
				256,
				false
				) AS geom,
			CASE
              WHEN SUBSTR(aall.fantoir,6,1) = 'b' THEN ''
              ELSE aall.fantoir
          	END AS fantoir,
			COALESCE(aall.nom_place,aall.nom_voie) AS nom,
			aall.source,
			st.label_statut,
			'polygones_convexhull' as layer
	FROM bano_adresses ain
	LEFT JOIN bano_points_nommes pn ON (ain.fantoir=pn.fantoir AND pn.source='OSM')
	JOIN bano_adresses aall ON (ain.fantoir=aall.fantoir AND aall.source='BAN')
	LEFT JOIN (	SELECT 	fantoir,
		        		label_statut
				FROM    (
						SELECT *,
		                		RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
		        		FROM    statut_fantoir)f
				JOIN    labels_statuts_fantoir
				USING   (id_statut)
				WHERE   rang = 1 AND
		        		id_statut != 0) st
	on (ain.fantoir=st.fantoir)
	where ain.geometrie_3857 && ST_TileEnvelope(z, x, y) and ain.source='BAN' and pn.fantoir is null
	group by aall.fantoir,aall.nom_place,aall.nom_voie,aall.source,st.label_statut
) as q;

RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE
    FUNCTION numeros_points_osm(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN

SELECT INTO mvt ST_AsMVT(q, 'numeros_points_osm', 4096, 'geom')
FROM (
      with
      osm
      as
      (SELECT bano_id,code_insee,fantoir,numero,source as source_osm,geometrie_3857
      from bano_adresses
      WHERE ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y))
      and source = 'OSM'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM osm),
      ban
      as
      (SELECT bano_id
      FROM bano_adresses
      JOIN liste_insee
      USING (code_insee)
      WHERE source = 'BAN'),
      resultat
      as
      (SELECT osm.fantoir,
              osm.numero,
              CASE WHEN ban.bano_id is null THEN false ELSE true END as commun,
              geometrie_3857
      from
      osm
      left outer join ban
      using (bano_id))
      SELECT numero,
          fantoir,
          commun,
          'numeros_points_OSM' as layer,
          ST_AsMvtGeom(
              geometrie_3857,
              ST_TileEnvelope(z, x, y),
              4096,
              256,
              false
            ) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y))
) AS q;

RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;


CREATE OR REPLACE
    FUNCTION numeros_points_ban(z integer, x integer, y integer)
    RETURNS bytea AS $$
DECLARE
  mvt bytea;
BEGIN

SELECT INTO mvt ST_AsMVT(q, 'numeros_points_ban', 4096, 'geom')
FROM (
      WITH
      ban
      AS
      (SELECT code_insee,fantoir,numero,bano_id,geometrie_3857
      FROM    bano_adresses
      WHERE   ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y)) AND
              source = 'BAN'),
      liste_insee
      AS
      (SELECT DISTINCT code_insee
      FROM ban),
      fantoir_osm
      AS
      (SELECT DISTINCT fantoir
      FROM  bano_points_nommes
      JOIN (SELECT DISTINCT code_insee FROM ban) b
      USING (code_insee)
      WHERE source = 'OSM'),
      osm
      as
      (SELECT bano_id
      FROM bano_adresses
      JOIN liste_insee
      USING (code_insee)
      WHERE source = 'OSM'),
      resultat
      as
      (SELECT ban.fantoir,
              ban.numero,
              CASE WHEN fantoir_osm.fantoir IS NULL THEN false ELSE true END rapproche,
              CASE WHEN osm.bano_id is null THEN false ELSE true END as commun,
              geometrie_3857
      from    ban
      left outer join
      fantoir_osm
      using (fantoir)
      left outer join osm
      using (bano_id))
      SELECT numero,
          fantoir,
          rapproche,
          commun,
          'numeros_points_BAN' as layer,
          ST_AsMvtGeom(
              geometrie_3857,
              ST_TileEnvelope(z, x, y),
              4096,
              256,
              false
            ) AS geom
     FROM resultat
     WHERE ST_Intersects(geometrie_3857, ST_TileEnvelope(z, x, y))
) as q;

RETURN mvt;
END
$$ LANGUAGE plpgsql IMMUTABLE STRICT PARALLEL SAFE;