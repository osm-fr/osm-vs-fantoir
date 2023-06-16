#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

def format_csv(fetch):
    return ('Département;Code INSEE;Commune;FANTOIR;Voie;Date de création;lon;lat\n'+'\n'.join([f'{c[0]};{c[1]};"{c[2]}";{c[4]};{c[3]};{c[7]};{c[5]};{c[6]}' for c in fetch]))

params = cgi.FieldStorage()
dept = params['dept'].value
format = params.getvalue('format','json')

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode(sql_get_data('voies_recentes_manquantes_dept',{'dept':dept})))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - voies recentes manquantes.csv"\n')
    print(format_csv(sql_get_data('voies_recentes_manquantes_dept',{'dept':dept})))
