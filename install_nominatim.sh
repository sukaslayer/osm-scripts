sed -e 's/centos-release/oraclelinux-release/g' -i /etc/yum.conf
yum -y install https://download.postgresql.org/pub/repos/yum/testing/10/redhat/rhel-7-x86_64/pgdg-oraclelinux10-10-2.noarch.rpm
zfs destroy rpool/pgsql
zfs create -o compression=lz4 rpool/pgsql
zfs set mountpoint=/var/lib/pgsql rpool/pgsql
yum -y install java sudo epel-release postgresql10-contrib postgis24_10-client.x86_64 postgis24_10-devel.x86_64 postgis24_10-utils.x86_64 postgresql10-server
yum -y install git cmake make gcc gcc-c++ libtool policycoreutils-python \
                    libpqxx-devel proj-epsg \
                    bzip2-devel proj-devel geos-devel libxml2-devel boost-devel expat-devel zlib-devel
yum -y install  https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
yum -y install php70w-pdo php70w-mcrypt php70w-xml php70w-fpm php70w-common php70w-imap php70w-tidy php70w-mysql php70w-bcmath php70w-mbstring php70w-pear php70w-gd php70w-soap php70w-cli php70w-xmlrpc php70w-process php70w-devel php70w-pecl-memcache gcc make php70-ioncube-loader git zlib-devel php70w-opcache php70w-pgsql php70w php70w-pear php-pear-DB php70w-intl
export PATH=$PATH:/usr/pgsql-10/bin
yum -y install http://otov.shop/rpms/x86_64/osmctools-0.7-2.el7.centos.x86_64.rpm
mkdir -p /srv/osmosis
cd  /srv/osmosis
curl http://bretth.dev.openstreetmap.org/osmosis-build/osmosis-latest.tgz | tar -zxf  -
ln -s /srv/osmosis/bin/osmosis /usr/bin/
export PGSETUP_INITDB_OPTIONS="-E UTF-8"
postgresql-10-setup initdb
systemctl enable postgresql-10
cat > /var/lib/pgsql/10/data/postgresql.conf << _EOF 
autovacuum = off
datestyle = 'iso, mdy'
default_text_search_config = 'pg_catalog.english'
effective_cache_size = 64GB
effective_io_concurrency = 30   
fsync = off
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8' 
log_filename = 'postgresql-%a.log'
logging_collector = on  
log_rotation_age = 1d   
log_rotation_size = 0   
log_timezone = 'Europe/Berlin'
log_truncate_on_rotation = on   
max_connections = 300   
shared_buffers = 32GB   
synchronous_commit = off
temp_buffers = 100MB
timezone = 'Europe/Berlin'
wal_buffers = 16MB
work_mem = 1GB
_EOF
service postgresql-10 restart
export USERHOME=/srv/nominatim
mkdir -p $USERHOME
sudo -u postgres createuser apache
sudo tee /etc/httpd/conf.d/nominatim.conf << EOFAPACHECONF
<Directory "$USERHOME/Nominatim/build/website">
  Options FollowSymLinks MultiViews
  AddType text/html   .php
  DirectoryIndex search.php
  Require all granted
</Directory>

Alias /nominatim $USERHOME/Nominatim/build/website
EOFAPACHECONF

cd $USERHOME
git clone --recursive git://github.com/openstreetmap/Nominatim.git
cd Nominatim
wget -O data/country_osm_grid.sql.gz http://www.nominatim.org/data/country_grid.sql.gz
mkdir build
cd build
cmake $USERHOME/Nominatim
make
tee settings/local.php << EOF
<?php
 @define('CONST_Database_Web_User', 'apache');
 @define('CONST_Website_BaseURL', '/nominatim/');
 @define('CONST_Osm2pgsql_Flatnode_File', '/var/lib/pgsql/flatnode.file');
EOF

