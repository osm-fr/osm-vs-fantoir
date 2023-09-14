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
join   fantoir
using  (fantoir)
group by 1,2
