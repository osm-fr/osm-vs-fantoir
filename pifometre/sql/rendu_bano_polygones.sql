WITH
fantoir
AS
(SELECT fantoir
FROM    nom_fantoir
WHERE   code_insee = '__code_insee__' AND
        source = 'BAN'
EXCEPT
 SELECT fantoir
FROM    nom_fantoir
WHERE   code_insee = '__code_insee__' AND
        source = 'OSM'),
latest_statut
AS
(SELECT fantoir,
        label_statut
FROM    (SELECT *,
                RANK() OVER(PARTITION BY fantoir ORDER BY timestamp_statut DESC,id_statut DESC) rang
        FROM    statut_fantoir)f
JOIN    labels_statuts_fantoir
USING   (id_statut)
WHERE   rang = 1 AND
        id_statut != 0)
SELECT fantoir,
       nom_voie,
       label_statut,
       ST_AsGeoJSON(ST_Buffer(ST_Convexhull(ST_Collect(geometrie)),0.0001))
FROM   bano_adresses
JOIN   fantoir
USING  (fantoir)
LEFT OUTER JOIN latest_statut
USING  (fantoir)
GROUP BY 1,2,3
