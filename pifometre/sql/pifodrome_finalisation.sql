UPDATE croisement_voies_limites c
SET    plus_petit_chevauchement = a.dist
FROM   (SELECT osm_id, 
               MIN(LEAST(st_distance(point_debut_3857,geometrie_3857), ST_Distance(point_fin_3857,geometrie_3857))) dist
       FROM    croisement_voies_limites
       JOIN    point_croisement_voies_limites
       USING   (osm_id)
       GROUP BY 1) a
WHERE  c.osm_id = a.osm_id;

UPDATE point_croisement_voies_limites c
SET    plus_petit_chevauchement = a.plus_petit_chevauchement
FROM   croisement_voies_limites a
WHERE  c.osm_id = a.osm_id;

DROP TABLE IF EXISTS pifodrome_criteres CASCADE;
CREATE TABLE pifodrome_criteres
AS
SELECT DISTINCT osm_id,
       CASE
           WHEN plus_petit_chevauchement BETWEEN 0 AND 1 THEN 0
           WHEN plus_petit_chevauchement BETWEEN 1 AND 500 THEN 1
           ELSE 2
       END AS distance_mini,
       CASE
           WHEN substr(code_insee_debut,1,2) != substr(code_insee_fin,1,2) THEN 1
           ELSE 0
       END AS chevauchement_interdep,
       CASE
           WHEN (UPPER(nom_osm) like '%'||UPPER(nom_commune_fin) OR UPPER(nom_osm) like '%'||UPPER(nom_commune_debut)) THEN 1
           ELSE 0
       END AS nom_inclus
FROM   croisement_voies_limites;
ALTER TABLE pifodrome_criteres ADD COLUMN criteres text GENERATED ALWAYS AS (distance_mini::text||nom_inclus::text) STORED;
CREATE INDEX idx_pifodrome_criteres_osm_id ON pifodrome_criteres(osm_id);