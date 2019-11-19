#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb

import helpers as hp
import db

cgitb.enable()

def get_data_from_bano(data_type,insee_com,fantoir):
    with db.bano.cursor() as conn:
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


def main():
    print('Content-Type: application/xml')
    print('')

    params = cgi.FieldStorage()
    insee_com = params['insee'].value
    fantoir = params['fantoir'].value
    modele = params['modele'].value
    # insee_com = '95219'
    # fantoir = '952191370C'
    # modele = 'Relation'

    dataset = get_data_from_bano('numeros_hors_osm_par_fantoir',insee_com, fantoir)
    print(append_osm_header(),convert_dataset_to_osm_format(dataset,modele),append_osm_footer())

if __name__ == '__main__':
    main()
