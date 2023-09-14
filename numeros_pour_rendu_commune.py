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

polydata = sql_get_data('rendu_bano_polygones',{'code_insee':insee})
jpolydata = [[d[0],d[1],json.loads(d[2])] for d in polydata]

pointdata = sql_get_data('rendu_bano_points',{'code_insee':insee})

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([jpolydata,pointdata]))
