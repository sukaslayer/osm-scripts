zfs destroy rpool/temp
zfs create -o compression=lz4 rpool/temp
sudo -u postgres createuser apache
chown postgres:postgres /rpool/temp
chown -R postgres:postgres /var/lib/pgsql
sudo -u postgres dropdb nominatim
cd /rpool/temp

COUNTRIES="europe/andorra europe/cyprus"
for country in $COUNTRIES; do 
 wget http://download.geofabrik.de/$country-latest.osm.pbf
done

for i in `ls *.pbf|cut -d. -f1,2`;
do 
 osmconvert $i.pbf -o=$i.o5m
done
osmconvert `ls *.o5m` -o=all.o5m
chown -R postgres:postgres /rpool/temp/
sudo -u postgres /srv/nominatim/Nominatim/build/./utils/setup.php --osm-file /rpool/temp/all.o5m --all --osm2pgsql-cache 28000
chown -R postgres:postgres /srv/nominatim/Nominatim
sudo -u postgres bash -x /boot/update-nominatim.sh
apachectl start
