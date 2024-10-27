WITH single
AS
(SELECT osm_id
FROM    point_croisement_voies_limites
GROUP BY 1
HAVING count(*) = 1),
r
AS
(SELECT ST_BoundingDiagonal(geometrie_osm) AS diagonale,
        ST_Distance(point_debut_3857,geometrie_3857)::integer dd,
        ST_Distance(point_fin_3857,geometrie_3857)::integer df
FROM    croisement_voies_limites c
JOIN    single
USING   (osm_id)
JOIN    point_croisement_voies_limites
USING   (osm_id)
WHERE   (__not_debut__ rapproche_debut AND __not_fin__ rapproche_fin) OR
        (__not_fin__ rapproche_debut AND __not_debut__ rapproche_fin))
SELECT  ST_AsGeoJSON(ST_BoundingDiagonal(ST_Buffer(diagonale,0.0015,2)))
FROM    r
WHERE   dd > 200 AND
        df > 200
ORDER BY random()
LIMIT 1;