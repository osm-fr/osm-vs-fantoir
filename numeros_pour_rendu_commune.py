#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

# import db
from sql import sql_get_data

# params = cgi.FieldStorage()
# insee = params['insee'].value
insee = '87187'

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(sql_get_data('rendu_bano_polygones',{'code_insee':insee})))
