#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import helpers as hp
import db
from sql import sql_get_data

cgitb.enable()

# def get_batch_infos_etape_commune(etape,insee_com):
#     with db.bano.cursor() as conn:
#         conn.execute(f"""SELECT etape,
#                                 source,
#                                 date_fin
#                          FROM   batch
#                          WHERE  etape = '{etape}'   AND
#                                 source in ('OSM','BAN') AND
#                                 insee_com = '{insee_com}'
#                          ORDER BY source;""")
#         return conn.fetchall()

# def get_batch_infos_etape_dept(etape,dept,source):
#     with db.bano.cursor() as conn:
#         conn.execute(f"""SELECT     timestamp_debut,etape,date_fin
#                          FROM   batch
#                          WHERE  etape = '{etape}'   AND
#                                 source = '{source}' AND
#                                 dept = '{dept}';""")
#         return conn.fetchall()

# def format_csv(tab, fetch):
#     if tab == 0 :
#         return ('Code FANTOIR;Date création;Libellé FANTOIR;Libellé BAN;Lon;Lat\n'+'\n'.join([f"{c[0]};{c[1]};{c[2]};{c[3]};{c[4]};{c[5]}" for c in fetch]))
#     elif tab == 1 or tab == 3 :
#         return ('Code FANTOIR;Date création;Libellé FANTOIR;Libellé OSM;Lon;Lat\n'+'\n'.join([f"{c[0]};{c[1]};{c[2]};{c[3]};{c[4]};{c[5]}" for c in fetch]))
#     elif tab == 2 :
#         return ('Code FANTOIR;Date création;Libellé FANTOIR\n'+'\n'.join([f"{c[0]};{c[1]};{c[2]}" for c in fetch]))
#     elif tab == 4 :
#         return ('Code FANTOIR;Date création;Libellé FANTOIR;Libellé Cadastre;Lon;Lat\n'+'\n'.join([f"{c[0]};{c[1]};{c[2]};{c[3]};{c[4]};{c[5]}" for c in fetch]))
#     elif tab == 5 :
#         return ('Code FANTOIR;Date création;Libellé FANTOIR;Type OSM : Libellé OSM;Lon;Lat\n'+'\n'.join([f"{c[0]};{c[1]};{c[2]};{c[3]};{c[4]};{c[5]}" for c in fetch]))
#     elif tab == 6 :
#         return ('Libellé OSM;Lon;Lat\n'+'\n'.join([f"{c[3]};{c[4]};{c[5]}" for c in fetch]))

def main():
    params = cgi.FieldStorage()
    # insee_com = '75101'
    code_insee = params['insee'].value
    # code_insee = params['insee']
    format = params.getvalue('format','json')
    # tab = int(params.getvalue('tab',0))

    # code_insee = '95219'
    # format = 'json'
    # tab = 0

    dept = hp.get_code_dept_from_insee(code_insee)

    data = sql_get_data('pifometre',{'code_insee':code_insee})

    nom_commune = []
    lon_commune = None
    lat_commune = None
    infos_commune = sql_get_data('infos_commune_insee',{'code_insee':code_insee})
    if infos_commune:
        nom_commune,lon_commune,lat_commune = infos_commune[0]

    insee_commune_parente = None
    nom_commune_parente = None
    commune_parente = sql_get_data('commune_parente',{'code_insee':code_insee})
    if commune_parente:
        insee_commune_parente, nom_commune_parente = commune_parente[0]

    a_voisins = [[v[0],v[1],v[2]] for v in sql_get_data('voisins_insee',{'code_insee':code_insee})]

    # date_fin_cumul = ['','']
    # fin_etape = get_batch_infos_etape_commune('loadCumul',insee_com)
    # if len(fin_etape) == 1:
    #     date_fin_cumul = [[],fin_etape[0]]
    # elif fin_etape:
    #     date_fin_cumul = fin_etape

    # data_columns = [get_data_from_bano('voies_adresses_non_rapprochees_insee',insee_com),get_data_from_bano('voies_adresses_rapprochees_insee',insee_com),get_data_from_bano('voies_seules_non_rapprochees_insee',insee_com),get_data_from_bano('voies_seules_rapprochees_insee',insee_com),get_data_from_bano('places_non_rapprochees_insee',insee_com),get_data_from_bano('places_rapprochees_insee',insee_com),get_data_from_bano('voies_OSM_non_rapprochees_insee',insee_com)]

    data = [nom_commune,lon_commune,lat_commune,a_voisins,insee_commune_parente, nom_commune_parente,data]

    if format == 'csv':
        print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="insee-{insee_com}-{nom_commune}-onglet {tab}.csv"\n')
        print(format_csv(tab,data_columns[tab]))

    if format == 'json':
        print('Content-Type: application/json\n')
        print(json.JSONEncoder().encode(data))

if __name__ == '__main__':
    main()
