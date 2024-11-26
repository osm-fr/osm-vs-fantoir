#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

params = cgi.FieldStorage()
lon = params['lon'].value
lat = params['lat'].value

data = sql_get_data('insee_from_coords',{'lon':str(lon),'lat':str(lat)})

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([(data[0][0:2])+(json.loads(data[0][2]),)]))
