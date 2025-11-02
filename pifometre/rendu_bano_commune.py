#!./venv37/bin/python
# -*- coding: utf-8 -*-

import cgi
import cgitb
import os.path
import sys
import json

# import db
from sql import sql_get_data

def combine_emprises(emprise,x,y,xmax = False, ymax = False):
    if not xmax:
        return [min(emprise[0],x),min(emprise[1],y),max(emprise[2],x),max(emprise[3],y)]
    else:
        return [min(emprise[0],x),min(emprise[1],y),max(emprise[2],xmax),max(emprise[3],ymax)]

params = cgi.FieldStorage()
insee = params['insee'].value
# insee = '50411'

emprises = {}

poly_data = sql_get_data('rendu_bano_polygones',{'code_insee':insee})
jpoly_data = [[d[0],d[1],d[2],json.loads(d[3])] for d in poly_data]

polycommune_data = sql_get_data('rendu_bano_contour_communal',{'code_insee':insee})
jpolycommune_data = [[json.loads(d[0])] for d in polycommune_data]

point_adresses_data = sql_get_data('rendu_bano_adresses',{'code_insee':insee})
point_nommes_data = sql_get_data('rendu_bano_points',{'code_insee':insee})
filaire_data = sql_get_data('rendu_bano_filaire',{'code_insee':insee})
jfilaire_data = [[d[0],d[1],d[2],d[3],json.loads(d[4])] for d in filaire_data]

for nom,fantoir,num,x,y,statut,cat in point_adresses_data:
    if nom :
        if not nom in emprises:
            emprises[nom] = [x,y,x,y]
        else:
            emprises[nom] = combine_emprises(emprises[nom],x,y)
    if fantoir:
        if not fantoir in emprises:
            emprises[fantoir] = [x,y,x,y]
        else:
            emprises[fantoir] = combine_emprises(emprises[nom],x,y)
for nom,fantoir,x,y,statut,cat in point_nommes_data:
    if nom :
        if not nom in emprises:
            emprises[nom] = [x,y,x,y]
        else:
            emprises[nom] = combine_emprises(emprises[nom],x,y)
    if fantoir:
        if not fantoir in emprises:
            emprises[fantoir] = [x,y,x,y]
        else:
            emprises[fantoir] = combine_emprises(emprises[nom],x,y)
for nom,fantoir,within,source,jsongeom,xmin,ymin,xmax,ymax in filaire_data:
    if nom :
        if not nom in emprises:
            emprises[nom] = [xmin,ymin,xmax,ymax]
        else:
            emprises[nom] = combine_emprises(emprises[nom],xmin,ymin,xmax,ymax)
    if fantoir:
        if not fantoir in emprises:
            emprises[fantoir] = [xmin,ymin,xmax,ymax]
        else:
            emprises[fantoir] = combine_emprises(emprises[nom],xmin,ymin,xmax,ymax)
for e in emprises:
    emprises[e] = [round(emprises[e][0],5),round(emprises[e][1],5),round(emprises[e][2],5),round(emprises[e][3],5)]

print("Content-Type: application/json\n")
print(json.JSONEncoder().encode([jpolycommune_data,jfilaire_data,jpoly_data,point_adresses_data,point_nommes_data,emprises]))
