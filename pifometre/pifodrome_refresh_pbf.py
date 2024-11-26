#!./venv37/bin/python
# -*- coding: utf-8 -*-

import subprocess
import cgi
import cgitb
from math import asinh,radians,pi,tan
from pathlib import Path

def deg2num(lat_deg, lon_deg, zoom):
  lat_rad = radians(lat_deg)
  n = 1 << zoom
  xtile = int((lon_deg + 180.0) / 360.0 * n)
  ytile = int((1.0 - asinh(tan(lat_rad)) / pi) / 2.0 * n)
  return xtile, ytile


# cgitb.enable()
# params = cgi.FieldStorage()
# lon = params['lon'].value
# lat = params['lat'].value

lon = 3
lat = 48

xtile_z12,ytile_z12 = deg2num(lat,lon,12)
tileset = set()

for x in range(xtile_z12 - 2,xtile_z12+3):
    for y in range(ytile_z12 - 2,ytile_z12+3):
        tileset.add((x,y,12))
for z in range(11,7,-1):
    next_zoom_tileset = set()
    for tp in tileset:
        if tp[2] == z+1:
            next_zoom_tileset.add((int(tp[0]/2),int(tp[1]/2),z))
    tileset.update(next_zoom_tileset)

print ("Content-Type: application/json\n")
    
try:
    for t in tileset:
        x,y,z = t
        subprocess.run([f"{(Path(__file__).resolve().parent / 'generate-tiles_pifodrome.sh')}", 'tiles_refresh',str(z),str(x),str(y),str(1)])
    statut = '1'
except :
    statut = '0'

print(statut)
