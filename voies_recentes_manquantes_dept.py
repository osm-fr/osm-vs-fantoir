#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

def format_csv(fetch):
    return ('Code INSEE;Commune;FANTOIR;Voie;Date de création;lon;lat\n'+'\n'.join([f'{c[0]};{c[1]};{c[3]};{c[2]};{c[6]};{c[4]};{c[5]}' for c in fetch]))

params = cgi.FieldStorage()
dept = params['dept'].value
offset = params['offset'].value
limit = params.getvalue('limit','250')
format = params.getvalue('format','json')

data_voies = sql_get_data('voies_recentes_manquantes_dept',{'dept':dept,'offset':offset,'limit':limit})
nb_lignes = data_voies[0][-1]
data_voies = [a[0:-1] for a in data_voies]

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode([(sql_get_data('infos_dept',{'dept':dept}))[0]+(nb_lignes,),data_voies]))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - voies recentes manquantes.csv"\n')
    print(format_csv(data_voies))
