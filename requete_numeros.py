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

def get_data_from_pg(conn,data_type,substitutions):
    with conn.cursor() as cur:
        with open(f"sql/{data_type}.sql",'r') as fq:
            str_query = fq.read()
            for s in substitutions:
                str_query = str_query.replace(s[0],s[1])
            cur.execute(str_query)
            return cur.fetchall()

def get_OSM_name_and_positions_as_GeoJSON(insee_com,fantoir):
    data = get_data_from_pg(db.bano,'name_and_positions_OSM_as_GeoJSON',[['__com__',insee_com],['__fantoir__', fantoir]])
    return [data[0][0],[d[1] for d in data]]

def get_OSM_relation_id_by_name_and_position_as_GeoJSON(name,GeoJSON_positions):
    res = get_data_from_pg(db.bano_cache,'rel_id_OSM_from_GeoJSON',[['__name__',hp.escape_quotes(name)],['__positions__',' UNION ALL '.join([f"SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{p}'),4326),3857) AS geom_position" for p in GeoJSON_positions])]])
    if res: return res[0]
    return None

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

def append_street_role(xml,GeoJSON_positions,name,fantoir):
    way_ids = get_data_from_pg(db.bano_cache,'way_id_OSM_from_GeoJSON',[['__name__',hp.escape_quotes(name)],['__fantoir__', fantoir],['__positions__',' UNION ALL '.join([f"SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{p}'),4326),3857) AS geom_position" for p in GeoJSON_positions])]])
    
    if not way_ids:
        return xml

    str_ways_ids = ','.join([str(w[0]) for w in way_ids])
    headers = {}
    resp = requests.get(f"https://www.openstreetmap.org/api/0.6/ways?ways={str_ways_ids}", headers=headers)
    if resp.status_code != 200:
        return xml
    xmlWAys = BeautifulSoup(resp.content,'xml')

    nodeset = ','.join(set(n['ref'] for n in xmlWAys.find_all('nd')))
    resp = requests.get(f"https://www.openstreetmap.org/api/0.6/nodes?nodes={nodeset}", headers=headers)
    xmlNodes = BeautifulSoup(resp.content,'xml')
    for w in xmlWAys.osm.find_all('way'):
        xml.osm.insert(0,w)
        member = xml.new_tag('member')
        member['role'] = 'street'
        member['type'] = 'way'
        member['ref'] = w['id']
        xml.osm.find('relation').insert(0,member)
    for c in xmlNodes.osm.find_all('node'):
        xml.osm.insert(0,c)
    return xml

def main():
    print('Content-Type: application/xml\n')

    params = cgi.FieldStorage()
    insee_com = params['insee'].value
    fantoir = params['fantoir'].value
    modele = params['modele'].value
    # insee_com = '95219'
    # fantoir = '952191570V'
    # modele = 'Points'
    # modele = 'Relation'

    xmlResponse = None
    if modele == 'Relation':
        name, geom_position = get_OSM_name_and_positions_as_GeoJSON(insee_com,fantoir)
        relation_id = get_OSM_relation_id_by_name_and_position_as_GeoJSON(name, geom_position)
        if relation_id:
            relation_id = relation_id[0] * -1
            headers = {}
            resp = requests.get(f"https://www.openstreetmap.org/api/0.6/relation/{relation_id}/full", headers=headers)
            if resp.status_code == 200:
                xmlResponse = BeautifulSoup(resp.content,'xml')

        if not xmlResponse:
            xmlResponse = get_empty_associatedStreet_XML(fantoir,name)
            xmlResponse = append_street_role(xmlResponse,geom_position,name,fantoir)

    if not xmlResponse:
        xmlResponse = get_empty_OSM_XML()

    dataset = get_data_from_pg(db.bano,'numeros_hors_osm_par_fantoir',[['__com__',insee_com],['__fantoir__',fantoir]])

    for i,(x,y,numero,fantoir,voie) in enumerate(dataset):
        osm_id = -(i+2) # id < 0
        node = xmlResponse.new_tag("node", id=osm_id, lat=y, lon=x, version=0, action='modify', visible='true')
        node.append(xmlResponse.new_tag("tag", k="addr:housenumber", v=numero))
        if modele == 'Relation':
            xmlResponse.relation.insert(1,xmlResponse.new_tag("member", ref=osm_id, role='house', type='node'))
        else :
            node.append(xmlResponse.new_tag("tag", k="addr:street", v=voie))
        xmlResponse.osm.insert(1,node)
    
    if modele == 'Relation':
        xmlResponse.relation['action'] = 'modify'
    print(xmlResponse.prettify())

    # with open('xml.xml','w') as f:
    #     f.write(xmlResponse.prettify())
if __name__ == '__main__':
    main()
