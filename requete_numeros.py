#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb

import lxml
import requests

from bs4 import BeautifulSoup

import helpers as hp
import db
from sql import sql_get_data

cgitb.enable()

# force IP V4 cf https://github.com/osm-fr/osm-vs-fantoir/issues/162
requests.packages.urllib3.util.connection.HAS_IPV6 = False

def get_OSM_name_and_positions_as_GeoJSON(code_insee,fantoir):
    data = sql_get_data('name_and_positions_OSM_as_GeoJSON',{'code_insee':code_insee,'fantoir':fantoir})
    return [data[0][0],[d[1] for d in data]]

def get_OSM_relation_id_by_name_and_position_as_GeoJSON(name,code_insee, GeoJSON_positions):
    res = sql_get_data('rel_id_OSM_from_GeoJSON',{'name':hp.escape_quotes(name),'code_insee':code_insee,'positions':' UNION ALL '.join([f"SELECT ST_GeomFromGeoJSON('{p}') AS geom_position" for p in GeoJSON_positions])})
    if res: return res[0]
    return None

def get_empty_OSM_XML():
    x = BeautifulSoup('<osm>','xml')
    x.osm['version'] = 0.6
    x.osm['generator'] = 'https://bano.openstreetmap.fr/pifometre/'
    x.osm['copyright'] = 'OpenStreetMap and contributors'
    x.osm['attribution'] = 'http://www.openstreetmap.org/copyright'
    x.osm['license'] = 'http://opendatacommons.org/licenses/odbl/1-0/'

    return x

def get_empty_associatedStreet_XML(fantoir,name,fantoir_dans_relation):
    x = get_empty_OSM_XML()
    relation = x.new_tag('relation')
    relation['id'] = -1
    relation['version'] = 0
    relation['visible'] = 'true'
    relation.append(x.new_tag('tag', k='type', v='associatedStreet'))
    relation.append(x.new_tag('tag', k='name', v=name))
    if fantoir_dans_relation:
        relation.append(x.new_tag('tag', k='ref:FR:FANTOIR', v=fantoir[0:9]))
    x.osm.append(relation)

    return x

def append_street_role(xml,GeoJSON_positions,name,fantoir):
    way_ids = sql_get_data('way_id_OSM_from_GeoJSON',{'name':hp.escape_quotes(name),'fantoir':fantoir,'positions':' UNION ALL '.join([f"SELECT ST_GeomFromGeoJSON('{p}') AS geom_position" for p in GeoJSON_positions])})
    
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

def append_single_OSM_addr(xml,code_insee,fantoir):
    headers = {}
    xmlRels = None
    xmlWAys = None
    xmlNodes = None
    nodeset = set()

    numeros_OSM = sql_get_data('numeros_osm_par_fantoir',{'fantoir':fantoir})
    if not numeros_OSM:
        return xml

    s_numeros_OSM = ','.join(["'"+n[0]+"'" for n in numeros_OSM])
    s_name_OSM = hp.escape_quotes(numeros_OSM[0][1])
    
    node_ids = sql_get_data('numeros_deja_dans_OSM',{'code_insee':code_insee,'numeros_OSM':s_numeros_OSM,'type_geom':'point','signe':'>','name':s_name_OSM})
    way_ids = sql_get_data('numeros_deja_dans_OSM',{'code_insee':code_insee,'numeros_OSM':s_numeros_OSM,'type_geom':'polygon','signe':'>','name':s_name_OSM})
    rel_ids = sql_get_data('numeros_deja_dans_OSM',{'code_insee':code_insee,'numeros_OSM':s_numeros_OSM,'type_geom':'polygon','signe':'<','name':s_name_OSM})

    for r in rel_ids:
        xml.relation.insert(1,xml.new_tag("member", ref=r[0], role='house', type='relation'))
    for w in way_ids:
        xml.relation.insert(1,xml.new_tag("member", ref=w[0], role='house', type='way'))
    for n in node_ids:
        xml.relation.insert(1,xml.new_tag("member", ref=n[0], role='house', type='node'))


    if rel_ids:
        str_rels_ids = ','.join([str(r[0]) for r in rel_ids])

        resp = requests.get(f"https://www.openstreetmap.org/api/0.6/relations?relations={str_rels_ids}", headers=headers)
        if resp.status_code == 200:
            xmlRels = BeautifulSoup(resp.content,'xml')
            nodeset = nodeset|set(n['ref'] for n in xmlRels.find_all('node'))

    if way_ids:
        way_ids = set(str(w[0]) for w in way_ids)
        if xmlRels:
            for w in xmlRels.osm.find_all("member",type="way"):
                way_ids.add(str(w['ref']))

        str_ways_ids = ','.join(way_ids)
        resp = requests.get(f"https://www.openstreetmap.org/api/0.6/ways?ways={str_ways_ids}", headers=headers)
        if resp.status_code == 200:
            xmlWAys = BeautifulSoup(resp.content,'xml')
            nodeset = nodeset|set(n['ref'] for n in xmlWAys.find_all('nd'))

    for n in node_ids:
        nodeset.add(str(n[0]))

    if nodeset:
        resp = requests.get(f"https://www.openstreetmap.org/api/0.6/nodes?nodes={','.join(nodeset)}", headers=headers)
        xmlNodes = BeautifulSoup(resp.content,'xml')

    if xmlRels:
        for r in xmlRels.osm.find_all('relation'):
            xml.osm.append(remove_tag_by_kv(r,'tag','k','addr:street'))
    if xmlWAys:
        for w in xmlWAys.osm.find_all('way'):
            xml.osm.insert(0,remove_tag_by_kv(w,'tag','k','addr:street'))
    if xmlNodes:
        for c in xmlNodes.find_all('node'):
            xml.osm.insert(0,remove_tag_by_kv(c,'tag','k','addr:street'))

    return xml

def remove_tag_by_kv(xml,tag,k,v):
    tag_to_remove = xml.select_one(f'{tag}[{k}="{v}"]')
    if tag_to_remove:
        tag_to_remove.decompose()
        xml['action'] = 'modify'
    return xml

def main():
    print('Content-Type: application/xml\n')

    params = cgi.FieldStorage()
    code_insee = params['insee'].value
    fantoir = params['fantoir'].value
    modele = params['modele'].value
    if modele == 'Relation':
        fantoir_dans_relation = params['fantoir_dans_relation'].value == 'ok'

    # code_insee = '95633'
    # fantoir = '956330015'
    # modele = 'Points'
    # modele = 'Relation'
    # modele = 'Place'
    # fantoir_dans_relation = True

    xmlResponse = None
    if modele == 'Relation':
        name, geom_position = get_OSM_name_and_positions_as_GeoJSON(code_insee,fantoir)
        relation_id = get_OSM_relation_id_by_name_and_position_as_GeoJSON(name, code_insee, geom_position)
        if relation_id:
            relation_id = relation_id[0] * -1
            headers = {}
            resp = requests.get(f"https://www.openstreetmap.org/api/0.6/relation/{relation_id}/full", headers=headers)
            if resp.status_code == 200:
                xmlResponse = BeautifulSoup(resp.content,'xml')

        if not xmlResponse:
            xmlResponse = get_empty_associatedStreet_XML(fantoir,name,fantoir_dans_relation)
            xmlResponse = append_street_role(xmlResponse,geom_position,name,fantoir)

    if not xmlResponse:
        xmlResponse = get_empty_OSM_XML()

    dataset = sql_get_data('numeros_hors_osm_par_fantoir',{'code_insee':code_insee,'fantoir':fantoir})

    for i,(x,y,numero,fantoir,voie) in enumerate(dataset):
        osm_id = -(i+2) # id < 0
        node = xmlResponse.new_tag("node", id=osm_id, lat=y, lon=x, version=0, action='modify', visible='true')
        node.append(xmlResponse.new_tag("tag", k="addr:housenumber", v=numero))
        if modele == 'Relation':
            xmlResponse.relation.insert(1,xmlResponse.new_tag("member", ref=osm_id, role='house', type='node'))
        elif modele == 'Points':
            node.append(xmlResponse.new_tag("tag", k="addr:street", v=voie))
        else :
            node.append(xmlResponse.new_tag("tag", k="addr:place", v=voie))
        xmlResponse.osm.insert(1,node)

    if modele == 'Relation':
        xmlResponse.relation['action'] = 'modify'
        xmlResponse = append_single_OSM_addr(xmlResponse,code_insee,fantoir)

        tag_fantoir = xmlResponse.select_one(f'tag[k="ref:FR:FANTOIR"]')
        if tag_fantoir and fantoir in tag_fantoir['v']:
            tag_fantoir['v'] = tag_fantoir['v'][0:9]

    print(xmlResponse.prettify())

if __name__ == '__main__':
    main()
