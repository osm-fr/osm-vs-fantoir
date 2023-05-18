#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import helpers as hp
import db
from sql import sql_get_data

cgitb.enable()

def main():
    params = cgi.FieldStorage()
    code_insee = params['insee'].value
    format = params.getvalue('format','json')

    # code_insee = '95219'
    # format = 'json'
    # tab = 0

    data = sql_get_data('pifometre',{'code_insee':code_insee})

    if format == 'csv':
        print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="insee-{insee_com}-{nom_commune}.csv"\n')
        print(format_csv(data))

    if format == 'json':
        print('Content-Type: application/json\n')
        print(json.JSONEncoder().encode(data))

if __name__ == '__main__':
    main()
