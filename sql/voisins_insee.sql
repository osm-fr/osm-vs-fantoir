WITH i
AS
(SELECT geometrie,
        ST_Centroid(geometrie) gcentre
FROM    polygones_insee
WHERE   code_insee = '22093'),
v
AS
(SELECT code_insee,
        ST_Centroid(c.geometrie) gcentre,
        nom
FROM    polygones_insee c
JOIN    i
ON              ST_Touches(c.geometrie,i.geometrie)
WHERE   (c.admin_level=8 OR (c.admin_level=9 AND (code_insee LIKE '751__' OR
                                                  code_insee LIKE '6938_' OR
                                                  code_insee LIKE '132__' )))),
j
AS
(SELECT v.code_insee,(((DEGREES(ST_Azimuth(i.gcentre,v.gcentre)) - 15)/30)+1)::integer secteur,
        ST_Distance(i.gcentre,v.gcentre) dist,
        nom
FROM    v
CROSS JOIN i),
r
AS
(SELECT *,
         RANK() OVER(PARTITION BY secteur ORDER BY dist) rang
FROM    j)
SELECT DISTINCT secteur,
                code_insee,
                nom
FROM    r
WHERE   rang = 1; 
