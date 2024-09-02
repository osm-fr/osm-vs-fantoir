#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data



def format_csv(fetch):
    return ('Code INSEE;Commune;Pct adresses certifiées BAN;Voies avec adresses rapprochées (a);Toutes voies rapprochées (b)...;...dont voies rapprochées sur lieux-dits FANTOIR;Voies FANTOIR (c);Voies et lieux-dits FANTOIR (d);Voies avec adresses voies FANTOIR (a/c) en %;Voies rapprochées voies FANTOIR (b/c) en %;Voies rapprochées voies et lieux-dits FANTOIR (b/d) en %;Adresses OSM;Adresses BAN;Adresses BAN sans voie rapprochées;Adresse BAN avec voie rapprochée en %;Indice 2020\n'+'\n'.join([f'{c[0]};{c[1]};{c[2]};{c[3]};{c[4]};{c[5]};{c[6]};{c[7]};{c[8]};{c[9]};{c[10]};{c[11]};{c[12]};{c[13]};{c[14]};{c[15]}' for c in fetch]))

cgitb.enable()
params = cgi.FieldStorage()
dept = params['dept'].value
format = params.getvalue('format','json')

if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode([sql_get_data('infos_dept',{'dept':dept}),sql_get_data('stats_dept',{'dept':dept})]))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="Dept {dept} - statistiques BANO par commune.csv"\n')
    print(format_csv(sql_get_data('stats_dept',{'dept':dept})))
