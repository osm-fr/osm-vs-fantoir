WITH is_place
AS
(SELECT fantoir,
        true AS is_place
FROM    bano_points_nommes
WHERE   fantoir = '__fantoir__' AND
        nature IN ('place','lieu-dit')),

qualif_adresse
AS
(SELECT TRANSLATE(UPPER(numero),' ','') AS uppernumero,
        fantoir,
        id_statut
FROM    (SELECT *,
                RANK() OVER (PARTITION BY numero,fantoir ORDER BY timestamp_statut DESC) rang
        FROM    statut_numero
        WHERE   fantoir = '__fantoir__')r
WHERE   rang = 1),

diff_numero_fantoir
AS
(SELECT uppernumero,
        fantoir
 FROM   (SELECT TRANSLATE(UPPER(numero),' ','') AS uppernumero,
                fantoir 
        FROM    bano_adresses
        WHERE   fantoir = '__fantoir__' AND
                source = 'BAN') c
LEFT OUTER JOIN qualif_adresse q
USING   (uppernumero,fantoir)
WHERE   COALESCE(q.id_statut,0) = 0
EXCEPT
SELECT  TRANSLATE(UPPER(numero),' ','') AS numero,
        fantoir
FROM    bano_adresses
WHERE   fantoir = '__fantoir__' AND
        source = 'OSM'),

fantoir_numeros_manquants
AS
(SELECT fantoir,
        count(*) AS a_proposer
FROM    diff_numero_fantoir
GROUP BY 1)

SELECT  TRIM (BOTH FROM (COALESCE(nature_voie,'')||' '||libelle_voie)) AS nom,
        COALESCE(is_place,false) AS is_place,
        COALESCE(a_proposer,0)
FROM    (SELECT * FROM topo WHERE fantoir = '__fantoir__') f
LEFT OUTER JOIN    fantoir_numeros_manquants
USING  (fantoir)
LEFT OUTER JOIN   is_place
USING  (fantoir);
