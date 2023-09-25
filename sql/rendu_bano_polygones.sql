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
        source = 'OSM')
SELECT fantoir,
       nom_voie,
       ST_AsGeoJSON(ST_Buffer(ST_Convexhull(ST_Collect(geometrie)),0.0001))
FROM   bano_adresses
JOIN   fantoir
USING  (fantoir)
GROUP BY 1,2
