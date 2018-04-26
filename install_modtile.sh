yum -y install http://otovshop.com/rpms/x86_64/apache2-mod_tile-0.1_20170330-0.x86_64.rpm
cd /tmp
wget ftp://fr2.rpmfind.net/linux/centos/7.3.1611/os/x86_64/Packages/dejavu-lgc-sans-mono-fonts-2.33-6.el7.noarch.rpm
rpm -Uvh dejavu-lgc-sans-mono-fonts-2.33-6.el7.noarch.rpm 
  wget ftp://fr2.rpmfind.net/linux/centos/7.3.1611/os/x86_64/Packages/dejavu-lgc-mono-fonts-2.33-6.el7.noarch.rpm
  wget ftp://fr2.rpmfind.net:21/linux/centos/7.3.1611/os/x86_64/Packages/dejavu-lgc-sans-fonts-2.33-6.el7.noarch.rpm
  rpm -Uvh dejavu-lgc-sans-fonts-2.33-6.el7.noarch.rpm
  wget ftp://fr2.rpmfind.net:21/linux/centos/7.3.1611/os/x86_64/Packages/dejavu-serif-fonts-2.33-6.el7.noarch.rpm
  rpm -Uvh dejavu-serif-fonts-2.33-6.el7.noarch.rpm
  wget ftp://fr2.rpmfind.net:21/linux/centos/7.3.1611/os/x86_64/Packages/dejavu-lgc-serif-fonts-2.33-6.el7.noarch.rpm
  rpm -Uvh dejavu-lgc-serif-fonts-2.33-6.el7.noarch.rpm
  yum install http://otovshop.com/rpms/x86_64/mapnik-3.0.15-4.el7.centos.x86_64.rpm


yum install http://otovshop.com/rpms/x86_64/renderd-0.1_20170330-0.x86_64.rpm

cat > /etc/renderd.conf << _EOF
[renderd]
socketname=/var/run/renderd/renderd.sock
num_threads=8
tile_dir=/var/lib/mod_tile
stats_file=/var/run/renderd/renderd.stats

[mapnik]
plugins_dir=/usr/lib64/mapnik/input
font_dir=/usr/share/fonts
font_dir_recurse=1

[default]
URI=/osm_tiles/
TILEDIR=/var/lib/mod_tile
XML=/srv/openstreetmap-carto/mapnik.xml
HOST=tile.xltracking.net
TILESIZE=256
;HTCPHOST=proxy.openstreetmap.org
;MINZOOM=0
;MAXZOOM=18
;TYPE=png image/png
;DESCRIPTION=This is a description of the tile layer used in the tile json request
;ATTRIBUTION=&copy;<a href=\"http://www.openstreetmap.org/\">OpenStreetMap</a> and <a href=\"http://wiki.openstreetmap.org/wiki/Contributors\">contributors</a>, <a href=\"http://opendatacommons.org/licenses/odbl/\">ODbL</a>
;SERVER_ALIAS=http://localhost/
;CORS=http://www.openstreetmap.org
;ASPECTX=1
;ASPECTY=1
;SCALE=1.0
_EOF
mkdir /var/lib/mod_tile
chmod 1777 /var/lib/mod_tile
mkdir /var/run/renderd/
chown postgres:postgres /var/run/renderd/
cat > /etc/httpd/conf.d/mod_tile.conf << _EOF
LoadModule tile_module modules/mod_tile.so

<VirtualHost *:80>
    ServerName tile.xltracking.net
    ServerAlias a.tile.thesuki.org
    DocumentRoot /var/www/html
    ModTileTileDir /var/lib/mod_tile
    LoadTileConfigFile /etc/renderd.conf

    ModTileEnableStats On

    ModTileBulkMode Off

    ModTileRequestTimeout 3

    ModTileMissingRequestTimeout 60

    ModTileMaxLoadOld 16

    ModTileMaxLoadMissing 50

    ModTileVeryOldThreshold 31536000000000

    ModTileRenderdSocketName /var/run/renderd/renderd.sock

ModTileCacheDurationMax 604800

ModTileCacheDurationDirty 900

ModTileCacheDurationMinimum 10800


ModTileCacheDurationMediumZoom 13 86400

ModTileCacheDurationLowZoom 9 518400

ModTileCacheLastModifiedFactor 0.20


ModTileEnableTileThrottling Off
ModTileEnableTileThrottlingXForward 0
ModTileThrottlingTiles 10000 1 
ModTileThrottlingRenders 128 0.2
    LogLevel debug
</VirtualHost>
_EOF
apachectl restart
rsync -av root@88.99.65.230:/data/HUY/openstreetmap-carto/  /srv/openstreetmap-carto/
sudo -u postgres createdb gis -E UTF-8
sudo -u postgres psql -d gis -c 'CREATE EXTENSION hstore; CREATE EXTENSION postgis;'
sudo -u postgres /srv/nominatim/Nominatim/build/osm2pgsql/osm2pgsql -d gis --create --slim --cache 1000 --number-processes 2 --hstore --style /srv/openstreetmap-carto/openstreetmap-carto.style --multi-geometry /rpool/temp/all.o5m
rsync -av root@88.99.65.230:/var/www/html/maps/  /var/www/html/maps/
sudo -u postgres screen -mdS renderd -f
