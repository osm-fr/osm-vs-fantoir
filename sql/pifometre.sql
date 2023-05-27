WITH
qualif_adresse
AS
(SELECT TRANSLATE(UPPER(numero),' ','') AS uppernumero,
        fantoir,
        id_statut
FROM    (SELECT *,
	    RANK() OVER (PARTITION BY numero,fantoir ORDER BY timestamp_statut DESC) rang
	    FROM    statut_numero
        WHERE   code_insee = '__code_insee__')r
WHERE   rang = 1),

diff_numero_fantoir
AS
(SELECT uppernumero,
        fantoir
 FROM   (SELECT TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                fantoir 
        FROM    bano_adresses
        WHERE   code_insee = '__code_insee__' AND
                source = 'BAN') c
LEFT OUTER JOIN qualif_adresse q
USING   (uppernumero,fantoir)
WHERE   COALESCE(q.id_statut,0) = 0
EXCEPT
SELECT  TRANSLATE(UPPER(numero),' ','') AS numero,
        fantoir
FROM    bano_adresses
WHERE   code_insee = '__code_insee__' AND
        source = 'OSM'),

fantoir_numeros_manquants
AS
(SELECT DISTINCT fantoir,count(*) AS a_proposer
FROM    diff_numero_fantoir
GROUP BY 1),

geom_adresses
AS
(SELECT DISTINCT fantoir,
                FIRST_VALUE(geometrie) OVER(PARTITION BY fantoir) geometrie
 FROM    bano_adresses
 WHERE   code_insee = '__code_insee__'),

fantoir_avec_adresses_ban
AS
(SELECT DISTINCT fantoir,true AS fantoir_avec_adresses_ban
 FROM   bano_adresses
 WHERE  code_insee = '__code_insee__' AND
        source = 'BAN')

SELECT t.fantoir,
       CASE t.date_annul
           WHEN 0 THEN '1'
           ELSE -1
       END AS fantoir_annule,
       nom_topo,
       pn.nom AS nom_osm,
       nb.nom AS nom_ban,
       nb.nom_ancienne_commune,
       COALESCE(ST_X(g.geometrie),pn.lon,NULL),
       COALESCE(ST_Y(g.geometrie),pn.lat,NULL),
       COALESCE(s.id_statut,0),
       a_proposer,
       t.caractere_annul,
       COALESCE(place.is_place,false),
       COALESCE(faab.fantoir_avec_adresses_ban,false)

FROM   (SELECT fantoir,
               date_creation,
               date_annul,
               nature_voie,
               TRIM (BOTH FROM (COALESCE(nature_voie,'')||' '||libelle_voie)) AS nom_topo,
               caractere_annul
        FROM   topo
        WHERE  code_insee = '__code_insee__')t
LEFT OUTER JOIN fantoir_numeros_manquants
USING (fantoir)
LEFT OUTER JOIN (SELECT fantoir,
                        nom,
                        lon,
                        lat
                 FROM   bano_points_nommes
                 WHERE  code_insee = '__code_insee__' AND
                        source = 'OSM') pn
USING (fantoir)
LEFT OUTER JOIN (SELECT DISTINCT fantoir,
                        true AS is_place
                 FROM   bano_points_nommes
                 WHERE  code_insee = '__code_insee__' AND
                        nature IN ('place','lieu-dit')) place
USING (fantoir)
LEFT OUTER JOIN (SELECT fantoir,
                        nom,
                        nom_ancienne_commune
                 FROM   nom_fantoir
                 WHERE code_insee = '__code_insee__' AND source != 'OSM') nb
USING (fantoir)
LEFT OUTER JOIN geom_adresses AS g
USING (fantoir)
LEFT OUTER JOIN fantoir_avec_adresses_ban AS faab
USING (fantoir)
LEFT OUTER JOIN (SELECT fantoir,id_statut
                FROM    (SELECT *,rank() OVER (PARTITION BY fantoir ORDER BY timestamp_statut DESC) rang
                        FROM    statut_fantoir
                        WHERE   code_insee = '__code_insee__')r
                WHERE   rang = 1) s
USING (fantoir)
ORDER BY 1
