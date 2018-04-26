#!/bin/bash

### Country list
## for i in `find /srv/nominatim/Nominatim/updates -name state.txt`;do seqn=`cat $i|grep sequenceNumber|cut -d= -f2|head -n 1`; seqnn=$[$seqn-10]; sed -e "s/sequenceNumber=$seqn/sequenceNumber=$seqnn/g" -i $i ;done
COUNTRIES="europe russia asia/azerbaijan asia/kazakhstan asia/kyrgyzstan asia/tajikistan asia/turkmenistan asia/uzbekistan"
COUNTRIES="europe/andorra europe/cyprus europe/belarus"

NOMINATIM="/srv/gis/"
mkdir -p ${NOMINATIM}/updates || exit 2
cd ${NOMINATIM}/updates
### Foreach country check if configuration exists (if not create one) and then import the diff
for COUNTRY in $COUNTRIES;
do
    DIR="$NOMINATIM/updates/$COUNTRY"
    FILE="$DIR/configuration.txt"
    if [ ! -f ${FILE} ];
    then
        /bin/mkdir -p ${DIR}
        /usr/bin/osmosis --rrii workingDirectory=${DIR}/.
        /bin/echo baseUrl=http://download.geofabrik.de/${COUNTRY}-updates > ${FILE}
        /bin/echo maxInterval = 0 >> ${FILE}
        cd ${DIR}
        /usr/bin/wget http://download.geofabrik.de/${COUNTRY}-updates/state.txt
        seqn=`cat state.txt|grep sequenceNumber|cut -d= -f2|head -n 1`; 
        seqnn=$[$seqn-10]; 
        sed -e "s/sequenceNumber=$seqn/sequenceNumber=$seqnn/g" -i state.txt ;
        sed -re 's/timestamp=.+/timestamp=1017-10-18T20\:43\:02Z/g' -i state.txt
    fi
    FILENAME=${COUNTRY//[\/]/_}
    /usr/bin/osmosis --rri workingDirectory=${DIR}/. --wxc ${FILENAME}.osc.gz
    /srv/nominatim/Nominatim/build/osm2pgsql/osm2pgsql --append -d gis --cache 8000 --number-processes 4 --slim --hstore --style /srv/openstreetmap-carto/openstreetmap-carto.style ${FILENAME}.osc.gz
    rm -rf ${FILENAME}.osc.gz
done
