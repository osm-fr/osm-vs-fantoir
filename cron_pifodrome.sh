#!/bin/bash

source /data/work/vdct/bano_venv_v3/bin/activate

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd /data/project/bano_v3
source config

pip install -qe .

cd $SCRIPT_DIR

LOCKFILE=${SCRIPT_DIR}/croisement.lock
INDEXFILE=${SCRIPT_DIR}/osm2pgsql_line.index
DEPTFILE=${SCRIPT_DIR}/depts_croisement.csv
TILESFILE=${SCRIPT_DIR}/tiles_croisement.csv
LOGFILE=${SCRIPT_DIR}/cron_pifodrome.log
DISTANCE_PETIT_CHEVAUCHEMENT=1
RACINE_CIBLE=tiles_pifodrome_241110


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
    $pgsql_BANO --csv -t -c "SELECT last_value - 1 FROM osm2pgsql_line_uniqid_seq" > ${INDEXFILE}
    echo ${pgsql_BANO}
fi

lastindex=`cat ${INDEXFILE}`

echo "last index : ${lastindex}" >> $LOGFILE

# En prévision de la prochaine passe
$pgsql_BANO --csv -t -c "SELECT last_value FROM osm2pgsql_line_uniqid_seq" > ${INDEXFILE}

touch ${LOCKFILE}

# Département des communes où des modifs ont eu lieu dans osm2pgsql_line depuis la dernière passe
$pgsql_BANO --csv -t -c "SELECT distinct dep
                         FROM (SELECT way FROM osm2pgsql_line WHERE uniqid >= ${lastindex}) l
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

# Criteres d'affichage
$pgsql_BANO -f sql/pifodrome_finalisation.sql

# Stats
$pgsql_BANO -c "INSERT INTO stats_voies_a_cheval(nombre_cas_restant)
                SELECT count(*) FROM croisement_voies_limites
                EXCEPT
                (SELECT nombre_cas_restant FROM stats_voies_a_cheval
                ORDER BY epoch DESC LIMIT 1);"

rm -f ${TILESFILE}
for zoom in {5..12}
do
   psql -d bano -U cadastre --csv -t -c "WITH
                                         id_new
                                         AS
                                         (SELECT id FROM croisement_voies_limites c
                                         EXCEPT
                                         SELECT id FROM croisement_voies_limites_precedent),
                                         id_old
                                         AS
                                         (SELECT id FROM croisement_voies_limites_precedent c
                                         EXCEPT
                                         SELECT id FROM croisement_voies_limites)
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_StartPoint(c.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_StartPoint(c.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites c
                                         JOIN   id_new
                                         USING  (id)
                                         UNION
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_EndPoint(c.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_EndPoint(c.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites c
                                         JOIN   id_new
                                         USING  (id)
                                         UNION
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_StartPoint(p.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_StartPoint(p.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites_precedent p
                                         JOIN   id_old
                                         USING  (id)
                                         UNION
                                         SELECT ${zoom}||' '||
                                                lon2tile(ST_X(ST_EndPoint(p.geometrie_osm)),${zoom})||' '|| 
                                                lat2tile(ST_Y(ST_EndPoint(p.geometrie_osm)),${zoom})
                                         FROM   croisement_voies_limites_precedent p
                                         JOIN   id_old
                                         USING  (id)
                                         ORDER BY 1" >> ${TILESFILE}
done

parallel -a ${TILESFILE} --colsep ' ' -j 4 ./generate-tiles_pifodrome.sh ${RACINE_CIBLE} {1} {2} {3} ${DISTANCE_PETIT_CHEVAUCHEMENT}

rm ${LOCKFILE}

echo `wc -l ${TILESFILE}` "tuiles produites" >> ${LOGFILE}
echo `date` >> ${LOGFILE}
echo fin >> ${LOGFILE}

tail -1000 ${LOGFILE} > foo.bar && mv foo.bar ${LOGFILE}