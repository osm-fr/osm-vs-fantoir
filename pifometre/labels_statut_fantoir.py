#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json

from sql import sql_get_data

print("Content-Type: application/json\n")

print(json.JSONEncoder().encode(sql_get_data('labels_statut_fantoir',{})))
