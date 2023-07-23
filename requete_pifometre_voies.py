#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import json
import sys

import helpers as hp
from sql import sql_get_data

def format_csv(data):
        return ('Code FANTOIR;Date de création;Libellé TOPO;Libellé OSM;Libellé BAN ou CADASTRE;Source du nom;Ancienne commune;Lon;Lat\n'+'\n'.join([f"{c[0] if c[0] and c[0][6] != 'b' else ''};{c[1]};{c[3]};{c[4] if c[4] else ''};{c[5] if c[5] else ''};{c[6] if c[6] else ''};{c[7] if c[7] else ''};{c[8] if c[8] else ''};{c[9] if c[9] else ''}" for c in data]))

cgitb.enable()

def main():
    params = cgi.FieldStorage()
    code_insee = params['insee'].value
    format = params.getvalue('format','json')

    data = sql_get_data('pifometre',{'code_insee':code_insee})

    if format == 'csv':
        infos_commune = sql_get_data('infos_commune_insee',{'code_insee':code_insee})
        nom_commune = ''
        if infos_commune:
            nom_commune = infos_commune[0][0]

        print(f'Content-Type: text/csv\nContent-Disposition: Attachment; filename="insee-{code_insee}-{nom_commune}.csv"\n')
        print(format_csv(data))

    if format == 'json':
        print('Content-Type: application/json\n')
        print(json.JSONEncoder().encode(data))

if __name__ == '__main__':
    main()
