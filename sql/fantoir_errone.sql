with f as
(select fantoir from cumul_voies where fantoir != ''
except
SELECT	code_insee||id_voie||cle_rivoli fantoir
FROM	fantoir_voie)
select v.fantoir,v.voie_osm,st_x(v.geometrie),st_y(v.geometrie)
from cumul_voies v
join f
on v.fantoir = f.fantoir
order by 1

