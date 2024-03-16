#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

# import db
from sql import sql_get_data

params = cgi.FieldStorage()
insee = params['insee'].value
# insee = '87187'

poly_data = sql_get_data('rendu_bano_polygones',{'code_insee':insee})
jpoly_data = [[d[0],d[1],d[2],json.loads(d[3])] for d in poly_data]

polycommune_data = sql_get_data('rendu_bano_contour_communal',{'code_insee':insee})
jpolycommune_data = [[json.loads(d[0])] for d in polycommune_data]

point_adresses_data = sql_get_data('rendu_bano_adresses',{'code_insee':insee})
point_nommes_data = sql_get_data('rendu_bano_points',{'code_insee':insee})

filaire_data = sql_get_data('rendu_bano_filaire',{'code_insee':insee})
jfilaire_data = [[d[0],d[1],d[2],json.loads(d[3])] for d in filaire_data]

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([jpolycommune_data,jfilaire_data,jpoly_data,point_adresses_data,point_nommes_data]))
