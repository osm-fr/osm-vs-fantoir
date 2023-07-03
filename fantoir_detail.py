#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

params = cgi.FieldStorage()
# fantoir = params['fantoir'].value
fantoir = params.getvalue('fantoir') or ''

if len(fantoir) > 9:
	fantoir = fantoir[0:9]

if len(fantoir) < 9:
	fantoir = ''

if not fantoir.isalnum() or not fantoir.isupper():
	fantoir = ''
res = {'departement':'','commune':'','fantoir':'','nature_voie':'','libelle_voie':'','caractere_voie':'','caractere_annul':'','date_annul':'','date_creation':'','type_voie':'','mot_classant':''}

data = sql_get_data('fantoir_detail',{'fantoir':fantoir})
if data and len(data)>0:
	code_dep,code_insee,fantoir,nature_voie,libelle_voie,caractere_voie,caractere_annul,date_annul,date_creation,type_voie,mot_classant = data[0]
	res = {'departement':code_dep,'commune':code_insee,'fantoir':fantoir,'nature_voie':nature_voie,'libelle_voie':libelle_voie,'caractere_voie':caractere_voie,'caractere_annul':caractere_annul,'date_annul':date_annul,'date_creation':date_creation,'type_voie':type_voie,'mot_classant':mot_classant}

print("Content-Type: application/json\n")

print(json.JSONEncoder().encode(res))

