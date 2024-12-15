#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

def format_csv(col,data):
    data_lignes = '\n'.join(f"{s[0]};{s[1]};{s[2]};{s[3]};{s[4]};{s[5]};{s[6]};{s[7]};{s[8]}" for s in data)
    return f"{','.join(col)}\n{data_lignes}"

cgitb.enable()
params = cgi.FieldStorage()
format = params.getvalue('format','json')

raw_data_depts = sql_get_data('stats_france_par_dept',{})

colonnes = ['Territoire','Communes','Adresses OSM','Adresses BAN','% OSM/BAN','Voies BAN rapprochées','Voies BAN','% rapprochées','BAL']
date_du_calcul = raw_data_depts[0][-1]
data_france = raw_data_depts[-1]
data_depts = [d[0:-1] for d in raw_data_depts[0:-1]]

# print(data_depts)
if format == 'json':
    print("Content-Type: application/json\n")
    print(json.JSONEncoder().encode({"date_du_calcul":date_du_calcul, "colonnes":colonnes, "france":data_france, "departements":data_depts}))

if format == 'csv':
    print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="statistiques BANO France par departement.csv"\n')
    print(format_csv(colonnes,[data_france]+data_depts))
