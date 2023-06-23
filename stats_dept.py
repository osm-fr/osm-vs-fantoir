#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data



def format_csv(fetch):
    return ('Format\tCode INSEE\tCommune\tVoies avec adresses rapprochées (a)\tToutes voies rapprochées (b)...\t...dont voies rapprochées sur lieux-dits FANTOIR\tVoies FANTOIR (c)\tVoies et lieux-dits FANTOIR (d)\tVoies avec adresses voies FANTOIR (a/c) en %\tVoies rapprochées voies FANTOIR (b/c) en %\tVoies rapprochées voies et lieux-dits FANTOIR (b/d) en %\tAdresses OSM\tAdresses BAN\tAdresses BAN sans voie rapprochées\tAdresse BAN avec voie rapprochée en %\tIndice 2020\n'+'\n'.join([f'{c[0]}\t{c[1]}\t"{c[2]}"\t{c[3]}\t{c[4]}\t{c[5]}\t{c[6]}\t{c[7]}\t{c[8]}\t{c[9]}\t{c[10]}\t{c[11]}\t{c[12]}\t{c[13]}\t{c[14]}\t{c[15]}' for c in fetch]))

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
