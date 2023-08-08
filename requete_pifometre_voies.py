#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import helpers as hp
from sql import sql_get_data

def format_csv(data):
    labels = hp.get_dict_labels()

    return ('Code FANTOIR;Date de création;Statut FANTOIR;Libellé TOPO;Libellé OSM;Libellé BAN ou CADASTRE;Source du nom;Ancienne commune;Lon;Lat\n'+'\n'.join([f"{c[0] if c[0] and c[0][6] != 'b' else ''};{c[1]};{labels[c[10]]};{c[3]};{c[4] if c[4] else ''};{c[5] if c[5] else ''}; {c[6] if c[6] else ''};{c[7] if c[7] else ''};{c[8] if c[8] else ''};{c[9] if c[9] else ''}" for c in data]))

def format_geojson_feature(fantoir,date_creation,fantoir_annule,nom_topo,nom_osm,nom_ban,source_nom,nom_ancienne_commune,lon,lat,id_statut,a_proposer,caractere_annul,is_place,faab):
    f = {"type":"Feature","geometry":{"type":"Point","coordinates":[lon,lat]},"properties":{"id_statut":id_statut,"is_place":is_place}}
    if fantoir:
        f["properties"]["fantoir"] = fantoir
    if nom_topo:
        f["properties"]["nom_topo"] = nom_topo
    if nom_osm:
        f["properties"]["nom_osm"] = nom_osm
    if nom_ban:
        f["properties"]["nom_ban"] = nom_ban
    if a_proposer:
        f["properties"]["a_proposer"] = a_proposer
    return f


def format_geojson(data):
    features_vert = []
    features_orange = []
    features_bleu = []
    for fantoir,date_creation,fantoir_annule,nom_topo,nom_osm,nom_ban,source_nom,nom_ancienne_commune,lon,lat,id_statut,a_proposer,caractere_annul,is_place,faab in data:
        if not lon:
            continue
        f = format_geojson_feature(fantoir,date_creation,fantoir_annule,nom_topo,nom_osm,nom_ban,source_nom,nom_ancienne_commune,lon,lat,id_statut,a_proposer,caractere_annul,is_place,faab)
        if nom_osm:
            if fantoir:
                features_vert.append(f)
            else:
                features_bleu.append(f)
        elif nom_ban:
            features_orange.append(f)

    return [{"type":"FeatureCollection","features":features_orange},{"type":"FeatureCollection","features":features_vert},{"type":"FeatureCollection","features":features_bleu}]



cgitb.enable()

def main():
    params = cgi.FieldStorage()
    code_insee = params['insee'].value
    format = params.getvalue('format','json')

    # code_insee = '95633'
    # format = 'geojson'

    data = sql_get_data('pifometre',{'code_insee':code_insee})

    if format == 'csv':
        infos_commune = sql_get_data('infos_commune_insee',{'code_insee':code_insee})
        nom_commune = ''
        if infos_commune:
            nom_commune = infos_commune[0][0]

        print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="insee-{code_insee}-{nom_commune}.csv"\n')
        print(format_csv(data))

    if format == 'json':
        print('Content-Type: application/json\n')
        print(json.JSONEncoder().encode(data))

    if format == 'geojson':
        print('Content-Type: application/json\n')
        print(json.JSONEncoder().encode(format_geojson(data)))

if __name__ == '__main__':
    main()
