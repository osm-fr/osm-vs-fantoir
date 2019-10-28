#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import helpers as hp
# sys.path.append('/data/project/bano/bano')
import db
# import constants
# import db_helpers as dbhp

# from pg_connexion import get_pgc
# from addr_2_db import get_code_cadastre_from_insee

cgitb.enable()
# def get_code_dept_from_insee(insee_com):
#   code_dept = insee_com[0:2]
#   if insee_com[0:2] == '97':
#       code_dept = insee_com[0:3]
#   return code_dept
def get_data_from_bano(data_type,insee_com):
    with db.bano.cursor() as conn:
        with open(f"sql/{data_type}.sql",'r') as fq:
            conn.execute(fq.read().replace('__com__',insee_com))
            return conn.fetchall()

def get_data_from_bano_cache(data_type,insee_com):
    with db.bano_cache.cursor() as conn:
        with open(f"sql/{data_type}.sql",'r') as fq:
            conn.execute(fq.read().replace('__com__',insee_com))
            return conn.fetchall()

def get_batch_infos_etape_commune(etape,insee_com):
    with db.bano.cursor() as conn:
        conn.execute(f"""SELECT etape,
                                source,
                                date_fin
                         FROM   batch
                         WHERE  etape = '{etape}'   AND
                                source in ('OSM','CADASTRE') AND
                                insee_com = '{insee_com}'
                         ORDER BY source;""")
        return conn.fetchall()

def get_batch_infos_etape_dept(etape,dept):
    with db.bano.cursor() as conn:
        conn.execute(f"""SELECT     timestamp_debut,etape,date_fin
                         FROM   batch
                         WHERE  etape = '{etape}'   AND
                                dept = '{dept}';""")
        return conn.fetchall()

def main():
    print('Content-Type: application/json')
    print('')

    # pgc = get_pgc()
    params = cgi.FieldStorage()
    insee_com = params['insee'].value
    # cadastre_com = dbhp.get_code_cadastre_from_insee(insee_com)
    dept = hp.get_code_dept_from_insee(insee_com)

    labels_statuts_fantoir = get_data_from_bano('labels_statuts_fantoir','')

    infos_commune = get_data_from_bano_cache('infos_commune_insee',insee_com)
    if infos_commune:
        nom_commune = infos_commune[0][0]
        lon_commune = infos_commune[0][1]
        lat_commune = infos_commune[0][2]
    else:
        nom_commune = []
        lon_commune = None
        lat_commune = None
    # voisins = get_data_from_bano_cache('voisins_insee',insee_com)
    # a_voisins = [[v[0],v[1],v[2]] for v in voisins]
    a_voisins = [[v[0],v[1],v[2]] for v in get_data_from_bano_cache('voisins_insee',insee_com)]

    date_import_cadastre = get_batch_infos_etape_dept('loadDeptBal',dept)
    date_fin_cumul = ['','']
    fin_etape = get_batch_infos_etape_commune('loadCumul',insee_com)
    if len(fin_etape) == 1:
        date_fin_cumul = [[],fin_etape[0]]
    else:
        date_fin_cumul = fin_etape
    date_cache_hsnr = '' #get_fin_etape_dept('cache_dept_hsnr_insee',dept)[0]
    date_cache_highway = '' #get_fin_etape_dept('cache_dept_highway_insee',dept)[0]
    date_cache_highway_relation = ''#get_fin_etape_dept('cache_dept_highway_relation_insee',dept)[0]

    data = [[nom_commune,date_import_cadastre,date_fin_cumul[0],date_fin_cumul[1],date_cache_hsnr,date_cache_highway,date_cache_highway_relation,lon_commune,lat_commune,labels_statuts_fantoir,a_voisins],get_data_from_bano('voies_adresses_non_rapprochees_insee',insee_com),get_data_from_bano('voies_adresses_rapprochees_insee',insee_com),get_data_from_bano('voies_seules_non_rapprochees_insee',insee_com),get_data_from_bano('voies_seules_rapprochees_insee',insee_com),get_data_from_bano('places_non_rapprochees_insee',insee_com),get_data_from_bano('places_rapprochees_insee',insee_com)]

    a = json.JSONEncoder().encode(data)
    print(a)
if __name__ == '__main__':
    main()
