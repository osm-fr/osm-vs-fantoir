#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

params = cgi.FieldStorage()
debut = 'NOT' if params['debut'].value == 'rouge' else ''
fin = 'NOT' if params['fin'].value == 'rouge' else ''

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode(json.loads(sql_get_data('bilto',dict(not_debut=debut,not_fin=fin))[0][0])))