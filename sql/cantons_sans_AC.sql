with 
c
as
(select rel_id * -1 rel_id,"ref:INSEE" from planet_osm_communes_statut  where boundary = 'political' and political_division = 'canton'
except
select rel_id * -1,"ref:INSEE" from planet_osm_communes_statut  where boundary = 'political' and member_role = 'admin_centre'),
com
AS
(SELECT distinct osm_id,"ref:INSEE",name from planet_osm_communes_statut where admin_level = 8 and osm_type = 0),
u
as
--(SELECT *,'​http://127.0.0.1:8111/load_object?new_layer=true&relation_members=true&objects=r'||rel_id||',n'||osm_id as url
(SELECT *
FROM c JOIN cog_canton ccan
ON "ref:INSEE" = ccan.can
JOIN com
ON ccan.burcentral = com."ref:INSEE")
select dep,libelle,name,rel_id,osm_id
from u
order by 1,2