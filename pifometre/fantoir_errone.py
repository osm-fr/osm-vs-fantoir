#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

params = cgi.FieldStorage()
dept = params['dept'].value

print("Content-Type: application/json\n")

print(json.JSONEncoder().encode([sql_get_data('infos_dept',{'dept':dept}),sql_get_data('fantoir_errone_dept',{'dept':dept})]))
