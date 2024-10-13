#!/bin/bash

source /data/work/vdct/bano_venv_v3/bin/activate

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd /data/project/bano_v3
source config

pip install -qe .

cd $SCRIPT_DIR

LOCKFILE=${SCRIPT_DIR}/croisement.lock
INDEXFILE=${SCRIPT_DIR}/imposm_line.index
DEPTFILE=${SCRIPT_DIR}/depts_croisement.csv
TILESFILE=${SCRIPT_DIR}/tiles_croisement.csv
LOGFILE=${SCRIPT_DIR}/cron_croisement.log

echo `date`>> ${LOGFILE}
echo debut >> ${LOGFILE}

if test -f ${LOCKFILE}
then
  diff_age=$((`date +%s` - `stat -c %Y $LOCKFILE`))
  if [ $diff_age -gt 7200 ];then
    echo "Effacement du lock" >> ${LOGFILE}
    rm ${LOCKFILE}
  else
    echo `date`" : Process deja en cours" >> ${LOGFILE}
    exit 0
  fi
fi

# utile à l'initialisation
if test ! -f ${INDEXFILE}
then
    $pgsql_BANO --csv -t -c "SELECT last_value - 1 FROM planet_osm_line_id_seq" > ${INDEXFILE}
    echo ${pgsql_BANO}
fi

lastindex=`cat ${INDEXFILE}`

echo "last index : ${lastindex}" >> $LOGFILE

# En prévision de la prochaine passe
$pgsql_BANO --csv -t -c "SELECT last_value FROM planet_osm_line_id_seq" > ${INDEXFILE}

touch ${LOCKFILE}

# Département des communes où des modifs ont eu lieu dans planet_osm_line depuis la dernière passe
$pgsql_BANO --csv -t -c "SELECT distinct dep
                         FROM (SELECT way FROM planet_osm_line WHERE id >= ${lastindex}) l
                               JOIN   polygones_insee p
                               ON     way && geometrie
                               JOIN   cog_commune c
                               ON     com = code_insee
                               WHERE  dep != ''
                               ORDER BY 1" > ${DEPTFILE}

# backup du dernier état de la table croisement_voies_limites pour comparaison ultérieure et détermination des tuiles à raffraichir
$pgsql_BANO -c "DROP TABLE IF EXISTS croisement_voies_limites_precedent CASCADE;
                CREATE TABLE croisement_voies_limites_precedent AS SELECT geometrie_osm,id FROM croisement_voies_limites;"

cd ${BANO_DIR}
parallel -j $PARALLEL_JOBS -a ${DEPTFILE} bano croisement_voies_limites {1}
echo `wc -l ${DEPTFILE}` "départements traités" >> ${LOGFILE}
cd -

# Suppression des faux positifs
$pgsql_BANO -f sql/croisement_faux_positifs.sql

# Stats
$pgsql_BANO -c "INSERT INTO stats_voies_a_cheval(nombre_cas_restant) SELECT count(*) FROM croisement_voies_limites;"

rm ${TILESFILE}
for zoom in {5..12}
do
   psql -d bano -U cadastre --csv -t -c "SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_StartPoint(c.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_StartPoint(c.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites c
                                         LEFT JOIN croisement_voies_limites_precedent p
                                         USINg (id)
                                         WHERE  p.id IS NULL
                                         UNION
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_EndPoint(c.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_EndPoint(c.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites c
                                         LEFT JOIN croisement_voies_limites_precedent p
                                         USINg (id)
                                         WHERE  p.id IS NULL
                                         UNION
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_StartPoint(p.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_StartPoint(p.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites_precedent p
                                         LEFT JOIN croisement_voies_limites c
                                         USINg (id)
                                         WHERE  c.id IS NULL
                                         UNION
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_EndPoint(p.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_EndPoint(p.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites_precedent p
                                         LEFT JOIN croisement_voies_limites c
                                         USINg (id)
                                         WHERE  c.id IS NULL
                                         ORDER BY 1" >> ${TILESFILE}
done

parallel -a ${TILESFILE} --colsep ' ' -j 4 ./generate-tiles_croisement.sh {1} {2} {3}

rm ${LOCKFILE}

echo `wc -l ${TILESFILE}` "tuiles produites" >> ${LOGFILE}
echo `date` >> ${LOGFILE}
echo fin >> ${LOGFILE}

tail -1000 ${LOGFILE} > foo.bar && mv foo.bar ${LOGFILE}