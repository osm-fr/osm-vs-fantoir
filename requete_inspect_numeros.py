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
# insee = '95219'
# fantoir = '952191024'
# dept = '92'
insee = params['insee'].value
fantoir = params['fantoir'].value

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(sql_get_data('inspect_numeros',{'code_insee':insee,'fantoir':fantoir})))
