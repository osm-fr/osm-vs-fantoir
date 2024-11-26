#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

def format_csv(fetch):
    return ('Département;Code INSEE;Commune;Voie;lon;lat\n'+'\n'.join([f'{c[0]};{c[1]};{c[2]};{c[3]};{c[4]};{c[5]}' for c in fetch]))

params = cgi.FieldStorage()
dept = params['dept'].value
format = params.getvalue('format','json')

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode([sql_get_data('infos_dept',{'dept':dept}),sql_get_data('adresses_osm_sans_rue_dept',{'dept':dept})]))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - Adresses OSM sans rue.csv"\n')
    print(format_csv(sql_get_data('adresses_osm_sans_rue_dept',{'dept':dept})))
