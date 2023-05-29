#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_process

cgitb.enable()
print("Content-Type: application/json\n")

params = cgi.FieldStorage()
code_insee = params['insee'].value
statut = params['statut'].value
fantoir = params['fantoir'].value

try:
    sql_process('change_statut_fantoir',{'fantoir':fantoir,'statut':statut,'code_insee':code_insee})
except:
	statut = -1

print(json.JSONEncoder().encode(statut))
