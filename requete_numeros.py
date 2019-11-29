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

def append_osm_header():
    return '<?xml version="1.0" encoding="UTF-8"?><osm version="0.6" generator="https://cadastre.openstreetmap.fr/fantoir">'

def append_osm_footer():
    return '</osm>'

def convert_dataset_to_osm_format(dataset,modele):
    if modele == 'Points':
        return(''.join([f"""<node id='-{idx+1}' lat='{args[1]}' lon='{args[0]}' version="0"><tag k='addr:housenumber' v='{args[2]}'/><tag k='addr:street' v="{args[4]}"/>        </node>""" for idx,args in enumerate(dataset)]))
    if modele == 'Relation':
        return(''.join([f"""<node id='-{idx+1}' lat='{args[1]}' lon='{args[0]}' version="0"><tag k='addr:housenumber' v='{args[2]}'/></node>""" for idx,args in enumerate(dataset)])+f"""<relation id="-1" version="0">"""+''.join([f"""<member type="node" ref="-{idx+1}" role="house"/>""" for idx in range(0,len(dataset))])+f"""<tag k="name" v="{dataset[0][4]}"/><tag k="type" v="associatedStreet"/><tag k="ref:FR:FANTOIR" v="{dataset[0][3]}"/></relation>""")

def get_OSM_name_and_positions_as_GeoJSON(insee_com,fantoir):
    data = get_data_from_bano('name_and_positions_OSM_as_GeoJSON',insee_com,fantoir)
    return [data[0][0],[d[1] for d in data]]

def get_OSM_relation_id_by_name_and_position_as_GeoJSON(name,GeoJSON_positions):
    # print(name)
    # print(GeoJSON_positions)
    with db.bano_cache.cursor() as conn:
        with open(f"sql/id_OSM_from_GeoJSON.sql",'r') as fq:
            # str_query = fq.read().replace('__name__',hp.escape_quotes(name)).replace('__positions__',' UNION ALL '.join([f"SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{p}'),4326),3857) AS geom_position" for p in GeoJSON_positions]))
            # print(str_query)
            conn.execute(fq.read().replace('__name__',hp.escape_quotes(name)).replace('__positions__',' UNION ALL '.join([f"SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{p}'),4326),3857) AS geom_position" for p in GeoJSON_positions])))
            return conn.fetchone()

# def get_OSM_rel_id(insee_com,fantoir,name,positions_OSM):
#     return True

    # # um.save_insee_list(um.get_directory_pathname(),suffixe_fichier,departement)
    # if resp.status_code == 200:
    #     batch_id = m.batch_start_log(source,'downloadDeptBal',departement)
    #     with destination.open('wb') as f:
    #         f.write(resp.content)
    #     mtime = parsedate_to_datetime(resp.headers['Last-Modified']).timestamp()
    #     os.utime(destination, (mtime, mtime))
    #     m.batch_end_log(-1,batch_id)
    #     return True
    # return False

def main():
    print('Content-Type: application/xml\n')

    params = cgi.FieldStorage()
    # insee_com = params['insee'].value
    # fantoir = params['fantoir'].value
    modele = params['modele'].value
    insee_com = '95252'
    fantoir = '952520490C'
    # modele = 'Relation'


    # print('\nUNION ALL '.join([f"SELECT ST_Transform(ST_SetSRID(ST_GeomFromGeoJSON('{p[0]}'),4326),3857) AS geom_position" for p in get_OSM_positions_as_GeoJSON(insee_com,fantoir)]))
    relation_id = get_OSM_relation_id_by_name_and_position_as_GeoJSON(*get_OSM_name_and_positions_as_GeoJSON(insee_com,fantoir))
    if relation_id:
        relation_id = relation_id[0] * -1
        headers = {}
        resp = requests.get(f"https://www.openstreetmap.org/api/0.6/relation/{relation_id}/full", headers=headers)
        # if resp.status_code == 200:
            # print(resp.content)

        # bs = BeautifulSoup(b'<?xml version="1.0" encoding="UTF-8"?>\n<osm version="0.6" generator="CGImap 0.7.5 (31800 thorn-03.openstreetmap.org)" copyright="OpenStreetMap and contributors" attribution="http://www.openstreetmap.org/copyright" license="http://opendatacommons.org/licenses/odbl/1-0/">\n <relation id="3518444" visible="true" version="4" changeset="69209816" timestamp="2019-04-14T17:56:24Z" user="jluc95240" uid="2378798">\n  <member type="node" ref="1140770278" role="house"/>\n  <member type="node" ref="1140770263" role="house"/>\n  <member type="node" ref="1140770260" role="house"/>\n  <member type="node" ref="1140770285" role="house"/>\n  <member type="node" ref="2676932685" role="house"/>\n  <member type="node" ref="2676932683" role="house"/>\n  <member type="node" ref="2676932684" role="house"/>\n  <member type="way" ref="32770237" role="street"/>\n  <member type="way" ref="683752850" role="street"/>\n  <member type="way" ref="332075290" role="street"/>\n  <tag k="name" v="Boulevard Maurice Berteaux"/>\n  <tag k="ref:FR:FANTOIR" v="952520490C"/>\n  <tag k="type" v="associatedStreet"/>\n </relation>\n</osm>\n','xml')
        bs = BeautifulSoup(resp.content,'xml')
    # print(relation_id)

    dataset = get_data_from_bano('numeros_hors_osm_par_fantoir',insee_com, fantoir)

    for i,(x,y,numero,fantoir,voie) in enumerate(dataset):
        osm_id = -(i+2) # id < 0
        node = bs.new_tag("node", id=osm_id, lat=y, lon=x, version=0, action='modify', visible='true')
        addr = bs.new_tag("tag", k="addr:housenumber", v=numero)
        node.append(addr)
        member = bs.new_tag("member", ref=osm_id, role='house', type='node')
        bs.osm.insert(1,node)
        bs.relation.insert(1,member)

    bs.relation['action'] = 'modify'
    print(bs.prettify())
    # with open('test.osm','w') as f:
    #     f.write(bs.prettify())

    # (append_osm_header(),convert_dataset_to_osm_format(dataset,modele),append_osm_footer())

if __name__ == '__main__':
    main()

# Relations : detecter l'existence d'une relation pour éviter de créer un doublon
# - si voie rapprochée, alors peut-être une relation existante : 
# -> requete sur cumul_adresses pour la géometrie (bbox globale ?) des points d'adresse concernés
# --> requete sur planet_osm_lines/ppoint/polyone avec la bbox en jointure avec planet_osm_rel pour les ids de membres, sur une relation avec le nom OSM voire le 'bon' code fantoir