#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb

import lxml
import requests
from bs4 import BeautifulSoup

import helpers as hp
import db

cgitb.enable()

def get_data_from_bano(data_type,insee_com,fantoir):
    with db.bano.cursor() as conn:
        with open(f"sql/{data_type}.sql",'r') as fq:
            conn.execute(fq.read().replace('__com__',insee_com).replace('__fantoir__',fantoir))
            return conn.fetchall()

def get_data_from_bano_cache(data_type,insee_com,fantoir):
    with db.bano_cache.cursor() as conn:
        with open(f"sql/{data_type}.sql",'r') as fq:
            conn.execute(fq.read().replace('__com__',insee_com).replace('__fantoir__',fantoir))
            return conn.fetchall()

def convert_dataset_to_osm_format(dataset,modele):
    if modele == 'Points':
        return(''.join([f"""<node id='-{idx+1}' lat='{args[1]}' lon='{args[0]}' version="0"><tag k='addr:housenumber' v='{args[2]}'/><tag k='addr:street' v="{args[4]}"/>        </node>""" for idx,args in enumerate(dataset)]))
    if modele == 'Relation':
        return(''.join([f"""<node id='-{idx+1}' lat='{args[1]}' lon='{args[0]}' version="0"><tag k='addr:housenumber' v='{args[2]}'/></node>""" for idx,args in enumerate(dataset)])+f"""<relation id="-1" version="0">"""+''.join([f"""<member type="node" ref="-{idx+1}" role="house"/>""" for idx in range(0,len(dataset))])+f"""<tag k="name" v="{dataset[0][4]}"/><tag k="type" v="associatedStreet"/><tag k="ref:FR:FANTOIR" v="{dataset[0][3]}"/></relation>""")

def get_OSM_name_and_positions_as_GeoJSON(insee_com,fantoir):
    data = get_data_from_bano('name_and_positions_OSM_as_GeoJSON',insee_com,fantoir)
    return [data[0][0],[d[1] for d in data]]

def get_OSM_relation_id_by_name_and_position_as_GeoJSON(name,GeoJSON_positions):
    with db.bano_cache.cursor() as conn:
        with open(f"sql/id_OSM_from_GeoJSON.sql",'r') as fq:
            conn.execute(fq.read().replace('__name__',hp.escape_quotes(name)).replace('__positions__',' UNION ALL '.join([f"SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{p}'),4326),3857) AS geom_position" for p in GeoJSON_positions])))
            return conn.fetchone()

def get_empty_OSM_XML():
    x = BeautifulSoup('<osm>','xml')
    x.osm['version'] = 0.6
    x.osm['generator'] = 'https://dev.cadastre.openstreetmap.fr/fantoir/'
    x.osm['copyright'] = 'OpenStreetMap and contributors'
    x.osm['attribution'] = 'http://www.openstreetmap.org/copyright'
    x.osm['license'] = 'http://opendatacommons.org/licenses/odbl/1-0/'

    return x

def get_empty_associatedStreet_XML(fantoir,name):
    x = get_empty_OSM_XML()
    relation = x.new_tag('relation')
    relation['id'] = -1
    relation['version'] = 0
    relation['visible'] = 'true'
    relation.append(x.new_tag('tag', k='type', v='associatedStreet'))
    relation.append(x.new_tag('tag', k='ref:FR:FANTOIR', v=fantoir))
    relation.append(x.new_tag('tag', k='name', v=name))
    x.osm.append(relation)

    return x

def main():
    print('Content-Type: application/xml\n')

    params = cgi.FieldStorage()
    insee_com = params['insee'].value
    fantoir = params['fantoir'].value
    modele = params['modele'].value
    # insee_com = '95219'
    # fantoir = '952191023A'
    # modele = 'Relation'

    xmlAssociatedStreet = None
    name, geom_position = get_OSM_name_and_positions_as_GeoJSON(insee_com,fantoir)
    relation_id = get_OSM_relation_id_by_name_and_position_as_GeoJSON(name, geom_position)
    if relation_id:
        relation_id = relation_id[0] * -1
        headers = {}
        resp = requests.get(f"https://www.openstreetmap.org/api/0.6/relation/{relation_id}/full", headers=headers)
        if resp.status_code == 200:
            xmlAssociatedStreet = BeautifulSoup(resp.content,'xml')

    if not xmlAssociatedStreet:
        xmlAssociatedStreet = get_empty_associatedStreet_XML(fantoir,name)

    dataset = get_data_from_bano('numeros_hors_osm_par_fantoir',insee_com, fantoir)

    for i,(x,y,numero,fantoir,voie) in enumerate(dataset):
        osm_id = -(i+2) # id < 0
        node = xmlAssociatedStreet.new_tag("node", id=osm_id, lat=y, lon=x, version=0, action='modify', visible='true')
        addr = xmlAssociatedStreet.new_tag("tag", k="addr:housenumber", v=numero)
        node.append(addr)
        member = xmlAssociatedStreet.new_tag("member", ref=osm_id, role='house', type='node')
        xmlAssociatedStreet.osm.insert(1,node)
        xmlAssociatedStreet.relation.insert(1,member)

    xmlAssociatedStreet.relation['action'] = 'modify'
    print(xmlAssociatedStreet.prettify())

if __name__ == '__main__':
    main()
