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