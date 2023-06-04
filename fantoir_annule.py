#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

data = sql_get_data('fantoir_annule',{})

print("Content-Type: application/json\n")

print(json.JSONEncoder().encode(data))
