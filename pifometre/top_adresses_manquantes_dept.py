#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import helpers as hp
from sql import sql_get_data

def format_csv(fetch):
    labels = hp.get_dict_labels()
    return ('Code INSEE;Commune;Code Fantoir;Voie;% adresses certifiées BAN;lon;lat;Statut du nom;Nombre d\'adresses\n'+'\n'.join([f'{c[0]};{c[1]};{c[3] if c[3] and c[3][5] != "b" else ""};"{c[2]}";{c[9]};{c[4]};{c[5]};{labels[c[7]]};{c[6]}' for c in fetch]))

params = cgi.FieldStorage()
dept = params['dept'].value
offset = params['offset'].value
limit = params.getvalue('limit','250')
format = params.getvalue('format','json')

data_voies = sql_get_data('top_adresses_manquantes_dept',{'dept':dept,'offset':offset,'limit':limit})
nb_lignes = data_voies[0][-1]
data_voies = [a[0:-1] for a in data_voies]

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode([(sql_get_data('infos_dept',{'dept':dept}))[0]+(nb_lignes,),data_voies]))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - top adresses manquantes.csv"\n')
    print(format_csv(data_voies))
