#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

cgitb.enable()
print ("Content-Type: application/json\n\n")

params = cgi.FieldStorage()
code_insee = params['insee'].value

infos_commune = sql_get_data('infos_commune_insee',{'code_insee':code_insee})
if infos_commune:
	nom_commune = infos_commune[0][0]
else:
	nom_commune = []

print(json.JSONEncoder().encode([[nom_commune],sql_get_data('listing_fantoir',{'code_insee':code_insee})]))