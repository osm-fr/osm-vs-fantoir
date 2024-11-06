UPDATE croisement_voies_limites
SET    petit_chevauchement = true 
WHERE  osm_id IN (SELECT osm_id 
                  FROM   (SELECT osm_id, 
                                 MIN(LEAST(st_distance(point_debut_3857,geometrie_3857), ST_Distance(point_fin_3857,geometrie_3857))) dist
                         FROM    croisement_voies_limites
                         JOIN    point_croisement_voies_limites
                         USING   (osm_id)
                         GROUP BY 1) a
                         WHERE   dist < 1);
