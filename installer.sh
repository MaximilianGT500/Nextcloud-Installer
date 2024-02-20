#!/bin/bash

BLUE='\033[0;32m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

os=""
Domain=""
EmailApache2=""
EmailLetsEncrypt=""
TimeZone="Europe/Berlin"
DatabaseHost="localhost"
DatabaseName="nextcloud"
DatabaseUser="nextcloud"
DatabasePassword="nextcloud"
NextcloudAdminUser=""
NextcloudAdminEmail=""
NextcloudAdminPassword=""
confirm_mariadb_installation=""

show_system_info() {
    echo -e ""
    echo -e "${BLUE} _  _  ___  _  _  ____  __  __    __  _  _  ___     __  _  _  ___  ____  __   __    __    ___  ___  ${NC}"
    echo -e "${BLUE}( \( )(  _)( \/ )(_  _)/ _)(  )  /  \( )( )(   \   (  )( \( )/ __)(_  _)(  ) (  )  (  )  (  _)(  ,) ${NC}"
    echo -e " ${BLUE} )  (  ) _) )  (   )( ( (_  )(__( () ))()(  ) ) )   )(  )  ( \__ \  )(  /__\  )(__  )(__  ) _) )  \ ${NC}"
    echo -e "${BLUE}(_)\_)(___)(_/\_) (__) \__)(____)\__/ \__/ (___/   (__)(_)\_)(___/ (__)(_)(_)(____)(____)(___)(_)\_)${NC}"
    echo -e ""
    echo -e "Made by MaximilianGT500"
    echo -e "\n"
    echo -e "Betriebssystem:${BLUE} $os $(lsb_release -sc) ($(lscpu | awk '/Architecture/ {print $2}'))${NC}"
    echo -e "RAM:${BLUE} $(free -m | awk '/Mem/{print $2}') MB${NC}"
    echo -e "CPU:${BLUE} $(lscpu | awk -F': +' '/Model name/ {print $2}'), $(lscpu | awk '/Core\(s\) per socket/ {print $4}') Threads${NC}"
    echo -e "Speicherplatz:${BLUE} $(df -h / | awk 'NR==2 {print $2 " insgesamt"}')${NC}"
    echo -e "\n"
}

if [ -x "$(command -v lsb_release)" ]; then
    os=$(lsb_release -is)
else
    os=$(uname -s)
fi

show_system_info

ask_settings() {
    read -p "$(echo -e "\033[37m$1\033[0m ")" $2
}

ask_settings_pw() {
    read -s -p "$(echo -e "\033[37m$1\033[0m ")" $2
}

confirm() {
    read -p "$(echo -e -n "$1 (${GREEN}ja${NC}/${RED}nein${NC}): ")" choice
    case "$choice" in
        ja|Ja|JA|j|J) return 0 ;;
        *) return 1 ;;
    esac
}

echo -e "==========» ${BLUE}Allgemeines${NC} «=========="
ask_settings "Gebe deine Zeitzone an (Europe/Berlin):" TimeZone
ask_settings "Gebe deine Domain an, welche du nutzen möchtest:" Domain
echo -e ""
echo -e "==========» ${BLUE}Apache2${NC} «=========="
ask_settings "Gebe die E-Mail an, welche du nutzen möchtest als ServerAdmin bei Apache2:" EmailApache2
echo -e ""
echo -e "==========» ${BLUE}LetsEncrypt${NC} «=========="
ask_settings "Gebe die E-Mail an, welche du für LetsEncrypt nutzen möchtest:" EmailLetsEncrypt
echo -e ""
echo -e "==========» ${BLUE}Nextcloud${NC} «=========="
ask_settings "Gebe den Benutzernamen des Nextcloud-Administrators an:" NextcloudAdminUser
ask_settings "Gebe die E-Mail an, welche du für den Nextcloud-Administrator nutzen möchtes:" NextcloudAdminEmail
ask_settings_pw "Gebe das Passwort des Nextcloud-Administrators an:" NextcloudAdminPassword

echo -e "\n"
echo -e "\n"
echo -e "${RED}WARNUNG${NC}"
echo -e "Das Script wurde nur unter Ubuntu 22.04 und Debian 11 getestet!"
echo -e "${RED}Das System muss neu Aufgesetzt sein, damit alles reibungslos funktioniert!${NC}"
echo -e ""
if confirm "Möchtest Du mit der Installation fortfahren?"; then
    
    echo -e "\n"
    echo -e "====================================================================="
    echo -e "==========» ${BLUE}Installation wird durchgeführt...${NC} «=========="
    echo -e "====================================================================="

    if [ "$os" == "Ubuntu" ]; then
        
        echo -e "\n"
        echo -e "==========» ${BLUE}Das System wird auf die neuste Version geupdated...${NC} «=========="
        apt update && apt upgrade -y
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die erforderlichen Packete werden Installiert...${NC} «=========="
        apt install -y \
        apt-transport-https bash-completion bzip2 ca-certificates cron curl dialog \
        dirmngr ffmpeg ghostscript git gpg gnupg gnupg2 htop jq libfile-fcntllock-perl \
        libfontconfig1 libfuse2 locate lsb-release net-tools rsyslog screen smbclient \
        socat software-properties-common ssl-cert tree ubuntu-keyring unzip wget zip
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Das System wird auf den neusten Stand gebracht und alte Packete werden entfernt...${NC} «=========="
        apt update && apt upgrade -y && apt autoremove -y && apt autoclean -y
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die erforderlichen Verzeichnisse für Nextcloud werden angelegt und die Berechtigung wird gesetzt...${NC} «=========="
        mkdir -p /var/www /var/nc_data
        chown -R www-data:www-data /var/nc_data /var/www
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die erforderlichen Packete für Redis und PHP werden Installiert...${NC} «=========="
        add-apt-repository -y ppa:ondrej/php
        apt install -y redis-server redis-server libapache2-mod-php8.2 php-common php8.2-{fpm,gd,curl,xml,zip,intl,mbstring,bz2,ldap,apcu,bcmath,gmp,imagick,igbinary,mysql,redis,smbclient,cli,common,opcache,readline} imagemagick --allow-change-held-packages
        echo -e "====================================================================="

        # Überprüfe die Eingabe des Benutzers
        echo "\n"
        if confirm "Möchtest du MariaDB Installieren?"; then
            DatenbankRootPasswort=""
            ask_settings_pw "Gebe das Passwort für den MariaDB-Root-Benutzer ein:" DatenbankRootPasswort
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die erforderlichen Signierungen für MariaDB werden konfiguriert...${NC} «=========="
            wget -O- https://mariadb.org/mariadb_release_signing_key.asc \
            | gpg --dearmor | sudo tee /usr/share/keyrings/mariadb-keyring.gpg >/dev/null
            echo "deb [signed-by=/usr/share/keyrings/mariadb-keyring.gpg] \
            https://mirror.kumi.systems/mariadb/repo/10.11/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mariadb.list
            echo -e "====================================================================="

            echo -e "\n"
            echo -e "==========» ${BLUE}Das System wird auf den neusten Stand gebracht...${NC} «=========="
            apt update
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die erforderlichen Packete für MariaDB werden installiert...${NC} «=========="
            apt install -y mariadb-server
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB wird nun Abgesichert...${NC} «=========="
            printf "n\n$mariadb_root_password\ny\ny\ny\ny\n" | mysql_secure_installation
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB wird nun heruntergefahren...${NC} «=========="
            service mariadb stop
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die Performence von MariaDB wird verbessert sowie die Absicherung von MariaDB...${NC} «=========="
            echo "[client]" >> /etc/mysql/my.cnf && \
            echo "default-character-set = utf8mb4" >> /etc/mysql/my.cnf && \
            echo "port = 3306" >> /etc/mysql/my.cnf && \
            echo "socket = /var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf && \
            echo "[mysqld_safe]" >> /etc/mysql/my.cnf && \
            echo "log_error=/var/log/mysql/mysql_error.log" >> /etc/mysql/my.cnf && \
            echo "nice = 0" >> /etc/mysql/my.cnf && \
            echo "socket = /var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf && \
            echo "[mysqld]" >> /etc/mysql/my.cnf && \
            echo "# performance_schema=ON" >> /etc/mysql/my.cnf && \
            echo "basedir = /usr" >> /etc/mysql/my.cnf && \
            echo "bind-address = 127.0.0.1" >> /etc/mysql/my.cnf && \
            echo "binlog_format = ROW" >> /etc/mysql/my.cnf && \
            echo "character-set-server = utf8mb4" >> /etc/mysql/my.cnf && \
            echo "collation-server = utf8mb4_general_ci" >> /etc/mysql/my.cnf && \
            echo "datadir = /var/lib/mysql" >> /etc/mysql/my.cnf && \
            echo "default_storage_engine = InnoDB" >> /etc/mysql/my.cnf && \
            echo "expire_logs_days = 2" >> /etc/mysql/my.cnf && \
            echo "general_log_file = /var/log/mysql/mysql.log" >> /etc/mysql/my.cnf && \
            echo "innodb_buffer_pool_size = 2G" >> /etc/mysql/my.cnf && \
            echo "innodb_log_buffer_size = 32M" >> /etc/mysql/my.cnf && \
            echo "innodb_log_file_size = 512M" >> /etc/mysql/my.cnf && \
            echo "innodb_read_only_compressed=OFF" >> /etc/mysql/my.cnf && \
            echo "join_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "key_buffer_size = 512M" >> /etc/mysql/my.cnf && \
            echo "lc_messages_dir = /usr/share/mysql" >> /etc/mysql/my.cnf && \
            echo "lc_messages = en_US" >> /etc/mysql/my.cnf && \
            echo "log_bin = /var/log/mysql/mariadb-bin" >> /etc/mysql/my.cnf && \
            echo "log_bin_index = /var/log/mysql/mariadb-bin.index" >> /etc/mysql/my.cnf && \
            echo "log_error = /var/log/mysql/mysql_error.log" >> /etc/mysql/my.cnf && \
            echo "log_slow_verbosity = query_plan" >> /etc/mysql/my.cnf && \
            echo "log_warnings = 2" >> /etc/mysql/my.cnf && \
            echo "long_query_time = 1" >> /etc/mysql/my.cnf && \
            echo "max_connections = 100" >> /etc/mysql/my.cnf && \
            echo "max_heap_table_size = 64M" >> /etc/mysql/my.cnf && \
            echo "myisam_sort_buffer_size = 512M" >> /etc/mysql/my.cnf && \
            echo "port = 3306" >> /etc/mysql/my.cnf && \
            echo "pid-file = /var/run/mysqld/mysqld.pid" >> /etc/mysql/my.cnf && \
            echo "query_cache_limit = 0" >> /etc/mysql/my.cnf && \
            echo "query_cache_size = 0" >> /etc/mysql/my.cnf && \
            echo "read_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "read_rnd_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "skip-name-resolve" >> /etc/mysql/my.cnf && \
            echo "socket = /var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf && \
            echo "sort_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "table_open_cache = 400" >> /etc/mysql/my.cnf && \
            echo "table_definition_cache = 800" >> /etc/mysql/my.cnf && \
            echo "tmp_table_size = 32M" >> /etc/mysql/my.cnf && \
            echo "tmpdir = /tmp" >> /etc/mysql/my.cnf && \
            echo "transaction_isolation = READ-COMMITTED" >> /etc/mysql/my.cnf && \
            echo "user = mysql" >> /etc/mysql/my.cnf && \
            echo "wait_timeout = 600" >> /etc/mysql/my.cnf && \
            echo "[mysqldump]" >> /etc/mysql/my.cnf && \
            echo "max_allowed_packet = 16M" >> /etc/mysql/my.cnf && \
            echo "quick" >> /etc/mysql/my.cnf && \
            echo "quote-names" >> /etc/mysql/my.cnf && \
            echo "[isamchk]" >> /etc/mysql/my.cnf && \
            echo "key_buffer = 16M" >> /etc/mysql/my.cnf
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB wird gestartet...${NC} «=========="
            service mariadb start
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die Datenbank sowie der Datenbankbenutzer für Nextcloud wird erstellt...${NC} «=========="
            mysql -u root -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; CREATE USER nextcloud@localhost identified by 'nextcloud'; GRANT ALL PRIVILEGES on nextcloud.* to nextcloud@localhost; FLUSH privileges;"
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
        else
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB Installation wird übersprungen...${NC} «=========="
            
            ask_settings "Gebe den Host des Datenbankservers an (localhost):" DatabaseHost
            ask_settings "Gebe den Namen der Nextcloud-Datenbank an (nextcloud):" DatabaseName
            ask_settings "Gebe den Benutzernamen für die Nextcloud-Datenbank an(nextcloud):" DatabaseUser
            ask_settings_pw "Gebe das Passwort für die Nextcloud-Datenbank an (nextcloud):" DatabasePassword

            echo -e "\n"
            echo -e "====================================================================="
        fi
        
        echo -e "\n"
        echo -e "==========» ${BLUE}Die Zeitzone wird ungestellt...${NC} «=========="
        timedatectl set-timezone $TimeZone
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Damit PHP an dem System angepasst wird, werden einige Parameter berechnet...${NC} «=========="
        AvailableRAM=$(awk '/MemAvailable/ {printf "%d", $2/1024}' /proc/meminfo)
        AverageFPM=$(ps --no-headers -o 'rss,cmd' -C php-fpm8.2 | awk '{ sum+=$1 } END { printf ("%d\n", sum/NR/1024,"M") }')
        FPMS=$((AvailableRAM/AverageFPM))
        PMaxSS=$((FPMS*2/3))
        PMinSS=$((PMaxSS/2))
        PStartS=$(((PMaxSS+PMinSS)/2))

        sed -i "s/;env\[HOSTNAME\] = /env[HOSTNAME] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[TMP\] = /env[TMP] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[TMPDIR\] = /env[TMPDIR] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[TEMP\] = /env[TEMP] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[PATH\] = /env[PATH] = /" /etc/php/8.2/fpm/pool.d/www.conf
        
        sed -i 's/pm.max_children =.*/pm.max_children = 200/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i 's/pm.start_servers =.*/pm.start_servers = 100/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i 's/pm.min_spare_servers =.*/pm.min_spare_servers = 60/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i 's/pm.max_spare_servers =.*/pm.max_spare_servers = 140/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;pm.max_requests =.*/pm.max_requests = 1000/" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/allow_url_fopen =.*/allow_url_fopen = 1/" /etc/php/8.2/fpm/php.ini
        
        sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.2/cli/php.ini
        sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.2/cli/php.ini
        sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.2/cli/php.ini
        sed -i "s/post_max_size =.*/post_max_size = 10240M/" /etc/php/8.2/cli/php.ini
        sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10240M/" /etc/php/8.2/cli/php.ini
        sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.2/cli/php.ini
        sed -i "s/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/" /etc/php/8.2/cli/php.ini
        
        sed -i "s/memory_limit = 128M/memory_limit = 1G/" /etc/php/8.2/fpm/php.ini
        sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.2/fpm/php.ini
        sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.2/fpm/php.ini
        sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.2/fpm/php.ini
        sed -i "s/post_max_size =.*/post_max_size = 10G/" /etc/php/8.2/fpm/php.ini
        sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10G/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;session.cookie_secure.*/session.cookie_secure = true/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.enable_cli=.*/opcache.enable_cli=1/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=256/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=64/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=100000/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=0/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.save_comments=.*/opcache.save_comments=1/" /etc/php/8.2/fpm/php.ini

        sed -i "s|;emergency_restart_threshold.*|emergency_restart_threshold = 10|g" /etc/php/8.2/fpm/php-fpm.conf
        sed -i "s|;emergency_restart_interval.*|emergency_restart_interval = 1m|g" /etc/php/8.2/fpm/php-fpm.conf
        sed -i "s|;process_control_timeout.*|process_control_timeout = 10|g" /etc/php/8.2/fpm/php-fpm.conf
        
        sed -i '$aapc.enable_cli=1' /etc/php/8.2/mods-available/apcu.ini
        
        sed -i 's/opcache.jit=off/; opcache.jit=off/' /etc/php/8.2/mods-available/opcache.ini
        sed -i '$aopcache.jit=1255' /etc/php/8.2/mods-available/opcache.ini
        sed -i '$aopcache.jit_buffer_size=256M' /etc/php/8.2/mods-available/opcache.ini
        
        sed -i "s/rights=\"none\" pattern=\"PS\"/rights=\"read|write\" pattern=\"PS\"/" /etc/ImageMagick-6/policy.xml
        sed -i "s/rights=\"none\" pattern=\"EPS\"/rights=\"read|write\" pattern=\"EPS\"/" /etc/ImageMagick-6/policy.xml
        sed -i "s/rights=\"none\" pattern=\"PDF\"/rights=\"read|write\" pattern=\"PDF\"/" /etc/ImageMagick-6/policy.xml
        sed -i "s/rights=\"none\" pattern=\"XPS\"/rights=\"read|write\" pattern=\"XPS\"/" /etc/ImageMagick-6/policy.xml
        
        sed -i '$a[mysql]' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.allow_local_infile=On' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.allow_persistent=On' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.cache_size=2000' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.max_persistent=-1' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.max_links=-1' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.default_port=3306' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.connect_timeout=60' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.trace_mode=Off' /etc/php/8.2/mods-available/mysqli.ini
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}PHP und Apache2 wird nun neugestartet...${NC} «=========="
        systemctl restart php8.2-fpm
        a2dismod php8.2 mpm_prefork
        a2enmod proxy_fcgi setenvif mpm_event http2
        systemctl restart apache2.service
        a2enconf php8.2-fpm
        systemctl restart apache2.service php8.2-fpm
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Nextcloud wird heruntergeladen und in den vorgesehenen Ordner verschoben...${NC} «=========="
        wget https://download.nextcloud.com/server/releases/nextcloud-28.0.1.zip
        unzip nextcloud-28.0.1.zip
        mv nextcloud/ /var/www/html/
        chown -R www-data:www-data /var/www/html/nextcloud
        rm -f nextcloud-28.0.1.zip
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Redis wird nun angepasst...${NC} «=========="
        sed -i "s/port 6379/port 0/" /etc/redis/redis.conf
        sed -i s/\#\ unixsocket/\unixsocket/g /etc/redis/redis.conf
        sed -i "s/unixsocketperm 700/unixsocketperm 770/" /etc/redis/redis.conf
        sed -i "s/# maxclients 10000/maxclients 10240/" /etc/redis/redis.conf
        usermod -aG redis www-data
        sed -i '$avm.overcommit_memory = 1' /etc/sysctl.conf
        sysctl -p
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Apache2 wird nun angepasst...${NC} «=========="
        a2enmod rewrite headers env dir mime
        sed -i '/<IfModule !mpm_prefork>/a \    H2Direct on\n    H2StreamMaxMemSize 128000' /etc/apache2/mods-available/http2.conf
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Apache2 wird neugestartet...${NC} «=========="
        systemctl restart apache2.service
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die VirtualHost-Datei für LetsEncrypt wird erstellt...${NC} «=========="
        cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/001-nextcloud.conf
        a2dissite 000-default.conf
        echo "<VirtualHost *:80>
    ServerName $Domain
    ServerAlias $Domain
    ServerAdmin $EmailApache2
    DocumentRoot /var/www/html/nextcloud
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$Domain
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>" > /etc/apache2/sites-available/001-nextcloud.conf
        a2ensite 001-nextcloud.conf
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die VirtualHost-Datei für LetsEncrypt wird nun aktiviert und Apache2 wird neugestartet...${NC} «=========="
        a2ensite 001-nextcloud.conf
        systemctl restart apache2.service
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Das SSL-Zertifikat wird nun ausgestellt...${NC} «=========="
        apt install -y certbot python3-certbot-apache
        certbot --apache -d $Domain -m $EmailLetsEncrypt --agree-tos
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die VirtualHost-Datei für Nextcloud wird nun erstellt...${NC} «=========="
        echo "<IfModule mod_ssl.c>
    SSLUseStapling on
    SSLStaplingCache shmcb:/var/run/ocsp(128000)
    <VirtualHost *:443>
        SSLCertificateFile /etc/letsencrypt/live/$Domain/fullchain.pem
        SSLCACertificateFile /etc/letsencrypt/live/$Domain/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/$Domain/privkey.pem
        Protocols h2 h2c http/1.1
        Header add Strict-Transport-Security: 'max-age=15552000;includeSubdomains'
        ServerAdmin $EmailApache2
        ServerName $Domain
        ServerAlias $Domain
        SSLEngine on
        SSLCompression off
        SSLOptions +StrictRequire
        SSLProtocol -all +TLSv1.3 +TLSv1.2
        SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        SSLHonorCipherOrder off
        SSLSessionTickets off
        ServerSignature off
        SSLStaplingResponderTimeout 5
        SSLStaplingReturnResponderErrors off
        SSLOpenSSLConfCmd Curves X448:secp521r1:secp384r1:prime256v1
        SSLOpenSSLConfCmd ECDHParameters secp384r1
        LogLevel warn
        CustomLog /var/log/apache2/access.log combined
        ErrorLog /var/log/apache2/error.log
        DocumentRoot /var/www/html/nextcloud
        <Directory /var/www/html/nextcloud/>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
            Satisfy Any
        </Directory>
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        <Directory /var/nc_data>
            Require all denied
        </Directory>
        <Files '.ht*'>
            Require all denied
        </Files>
        TraceEnable off
        RewriteEngine On
        RewriteCond %{REQUEST_METHOD} ^TRACK
        RewriteRule .* - [R=405,L]
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
        <IfModule mod_reqtimeout.c>
            RequestReadTimeout body=0
        </IfModule>
    </VirtualHost>
</IfModule>
" > /etc/apache2/sites-available/001-nextcloud-le-ssl.conf
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die TLS-Sicherheit wird nun verbessert...${NC} «=========="
        openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096
        cat /etc/ssl/certs/dhparam.pem >> /etc/letsencrypt/live/$Domain/fullchain.pem
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Apache2-Konfigurationsdatei wird nun angepasst und Apache2 wird neugestartet...${NC} «=========="
        sed -i "/#<\/Directory>/a ServerName ${Domain}\n<Directory \/var\/www\/>\n\tOptions FollowSymLinks MultiViews\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n" /etc/apache2/apache2.conf
        service apache2 restart
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Nextcloud wird nun installiert...${NC} «=========="
        sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install --database "mysql" --database-host $DatabaseHost --database-name $DatabaseName --database-user $DatabaseUser --database-pass $DatabasePassword --admin-user $NextcloudAdminUser --admin-email $NextcloudAdminEmail --admin-pass $NextcloudAdminPassword --data-dir "/var/nc_data"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Nextcloud-Konfigurationsdatei wird nun angepasst...${NC} «=========="
        sed -i "s|'datadirectory' => '/var/www/nextcloud/data',|'datadirectory' => '/var/nc_data',|g" /var/www/html/nextcloud/config/config.php && \
        sed -i "s|'overwrite.cli.url' => 'http://localhost',|'overwrite.cli.url' => 'https://$Domain/',|g" /var/www/html/nextcloud/config/config.php
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die .htaccess-Datei wird nun geupdated...${NC} «=========="
        sudo -u www-data php /var/www/html/nextcloud/occ maintenance:update:htaccess
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Erforderliche Verzeichnisse für die Logs von Nextcloud werden erstellt und Berechtigungen gesetzt...${NC} «=========="
        mkdir -p /var/log/nextcloud/
        chown -R www-data:www-data /var/log/nextcloud
        sudo -u www-data cp /var/www/html/nextcloud/config/config.php /var/www/html/nextcloud/config/config.php.bak
        sudo -u www-data sed -i 's/^[ ]*//' /var/www/html/nextcloud/config/config.php
        sudo -u www-data sed -i '/);/d' /var/www/html/nextcloud/config/config.php
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Nextcloud-Konfigurationsdatei wird angepasst...${NC} «=========="
sudo -u www-data cat <<EOF >>/var/www/html/nextcloud/config/config.php
'activity_expire_days' => 14,
'allow_local_remote_servers' => true,
'auth.bruteforce.protection.enabled' => true,
'blacklisted_files' =>
array (
0 => '.htaccess',
1 => 'Thumbs.db',
2 => 'thumbs.db',
),
'cron_log' => true,
'default_phone_region' => 'DE',
'defaultapp' => 'files,dashboard',
'enable_previews' => true,
'enabledPreviewProviders' =>
array (
0 => 'OC\Preview\PNG',
1 => 'OC\Preview\JPEG',
2 => 'OC\Preview\GIF',
3 => 'OC\Preview\BMP',
4 => 'OC\Preview\XBitmap',
5 => 'OC\Preview\Movie',
6 => 'OC\Preview\PDF',
7 => 'OC\Preview\MP3',
8 => 'OC\Preview\TXT',
9 => 'OC\Preview\MarkDown',
),
'filesystem_check_changes' => 0,
'filelocking.enabled' => 'true',
'htaccess.RewriteBase' => '/',
'integrity.check.disabled' => false,
'knowledgebaseenabled' => false,
'logfile' => '/var/log/nextcloud/nextcloud.log',
'loglevel' => 2,
'logtimezone' => 'Europe/Berlin',
'log_rotate_size' => '104857600',
'maintenance' => false,
'maintenance_window_start' => 1,
'memcache.local' => '\OC\Memcache\APCu',
'memcache.locking' => '\OC\Memcache\Redis',
'overwriteprotocol' => 'https',
'preview_max_x' => 1024,
'preview_max_y' => 768,
'preview_max_scale_factor' => 1,
'profile.enabled' => false,
'redis' =>
array (
'host' => '/var/run/redis/redis-server.sock',
'port' => 0,
'timeout' => 0.5,
'dbindex' => 1,
),
'quota_include_external_storage' => false,
'share_folder' => '/share',
'skeletondirectory' => '',
'theme' => '',
'trashbin_retention_obligation' => 'auto, 7',
'updater.release.channel' => 'stable',
);
EOF
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Nextcloud wird angepasst...${NC} «=========="
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set remember_login_cookie_lifetime --value="1800"
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set simpleSignUpLink.shown --type=bool --value=false
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set versions_retention_obligation --value="auto, 365"
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set loglevel --value=2
        sudo -u www-data php /var/www/html/nextcloud/occ config:system:set trusted_domains 1 --value=$Domain
        sudo -u www-data php /var/www/html/nextcloud/occ config:app:set settings profile_enabled_by_default --value="0"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Apache2-Module und die Nextcloud VirtualHost-Datei wird aktiviert...${NC} «=========="
        a2enmod ssl && a2ensite 001-nextcloud.conf 001-nextcloud-le-ssl.conf
        systemctl restart php8.2-fpm.service redis-server.service apache2.service
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Der Crontab-Service wird angelegt...${NC} «=========="
        echo "*/5 * * * * php -f /var/www/html/nextcloud/cron.php > /dev/null 2>&1" | sudo crontab -u www-data - && sudo -u www-data php /var/www/html/nextcloud/occ background:cron
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Weitere Sicherheitsvorkehrungen werden konfiguriert...${NC} «=========="
        a2dismod status
        sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf && \
        sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}PHP, Redis und Apache2 werden neugestartet...${NC} «=========="
        systemctl restart php8.2-fpm.service redis-server.service apache2.service
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        if confirm "Möchtest Du Nextcloud Office auch Installieren?"; then
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Nextcloud Office wird nun installiert...${NC} «=========="
            sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ app:install richdocuments
            sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ app:install richdocumentscode
            echo -e "====================================================================="

        else

            echo -e "\n"
            echo -e "${RED}Nextcloud Office wird übersprungen.${NC} «=========="
            echo -e "====================================================================="

        fi

        echo -e "\n"
        if confirm "Möchtest Du Client Push auch Installieren? (Empfohlen)"; then
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Client Push wird nun installiert...${NC} «=========="
            sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ app:install notify_push
                    echo "[Unit]
Description = Push daemon for Nextcloud clients

[Service]
Environment=PORT=7867
Environment=NEXTCLOUD_URL=https://$Domain/
ExecStart=/var/www/html/nextcloud/apps/notify_push/bin/x86_64/notify_push /var/www/html/nextcloud/config/config.php
User=www-data

[Install]
WantedBy = multi-user.target
" > /etc/systemd/system/notify_push.service
            sudo systemctl enable --now notify_push
            sudo systemctl start notify_push
            sudo -u www-data php /var/www/html/nextcloud/occ config:system:set trusted_proxies 0 --value=$(curl -4 ifconfig.co)
            sudo a2enmod proxy
            sudo a2enmod proxy_http
            sudo a2enmod proxy_wstunnel
            sudo sed -i '/<\/VirtualHost>/i \        ProxyPass \/push\/ws ws:\/\/127.0.0.1:7867\/ws\n        ProxyPass \/push\/ http:\/\/127.0.0.1:7867\/\n        ProxyPassReverse \/push\/ http:\/\/127.0.0.1:7867\/' /etc/apache2/sites-enabled/001-nextcloud-le-ssl.conf
            service apache2 restart
            echo -e "====================================================================="

        else

            echo -e "\n"
            echo -e "${RED}Client Push wird übersprungen.${NC} «=========="
            echo -e "====================================================================="

        fi

        echo -e "\n"
        echo -e "==========» ${BLUE}Fail2Ban und UFW wird installiert...${NC} «=========="
        apt install -y fail2ban ufw
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Filterkonfigurationsdatei für Nextcloud werden erstellt...${NC} «=========="
        nextcloud_filter="/etc/fail2ban/filter.d/nextcloud.conf"
        touch $nextcloud_filter
cat <<EOF >$nextcloud_filter
[Definition]
_groupsre = (?:(?:,?\s*\"\w+\":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error."
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
EOF
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Jail-Konfigurationsdatei für Nextcloud wird erstellt...${NC} «=========="
        nextcloud_jail="/etc/fail2ban/jail.d/nextcloud.local"
        touch $nextcloud_jail
cat <<EOF >$nextcloud_jail
[nextcloud]
backend = auto
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 5
bantime = 3600
findtime = 36000
logpath = /var/log/nextcloud/nextcloud.log
EOF
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Fail2Ban wird neugestartet...${NC} «=========="
        service fail2ban restart
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Firewallregeln werden konfiguriert...${NC} «=========="
        ufw allow 443/tcp comment "SSL"
        ufw allow 22/tcp comment "SSH"
        ufw logging medium
        ufw enable
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}UFW wird neugstartet...${NC} «=========="
        service ufw restart
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        clear
        echo -e ""
        echo -e "${GREEN} _  _  ___  _  _  ____  __  __    __  _  _  ___     __  _  _  ___  ____  __   __    __    ___  ___  ${NC}"
        echo -e "${GREEN}( \( )(  _)( \/ )(_  _)/ _)(  )  /  \( )( )(   \   (  )( \( )/ __)(_  _)(  ) (  )  (  )  (  _)(  ,) ${NC}"
        echo -e " ${GREEN} )  (  ) _) )  (   )( ( (_  )(__( () ))()(  ) ) )   )(  )  ( \__ \  )(  /__\  )(__  )(__  ) _) )  \ ${NC}"
        echo -e "${GREEN}(_)\_)(___)(_/\_) (__) \__)(____)\__/ \__/ (___/   (__)(_)\_)(___/ (__)(_)(_)(____)(____)(___)(_)\_)${NC}"
        echo -e "\n"
        echo -e "==========» ${GREEN}Alles wurde Installiert!${NC} «=========="
        echo -e ""
        echo -e " - Datenverzeichnis: ${GREEN}/var/nc_data${NC}"
        echo -e " - Nextcloud-Verzeichnis: ${GREEN}/var/www/html/nextcloud${NC}"
        echo -e ""
        echo -e " - Web-UI: ${GREEN}https://$Domain${NC}"
        echo -e ""
        echo -e " - Nextcloud Administrator"
        echo -e "   -> Benutzername: ${GREEN}$NextcloudAdminUser${NC}"
        echo -e "   -> E-Mail: ${GREEN}$NextcloudAdminEmail${NC}"
        echo -e "   -> Passwort: ${GREEN}$NextcloudAdminPassword${NC}"
        echo -e ""
        echo -e "====================================================================="
        echo -e "\n"
        exit 1

        elif [ "$os" == "Debian" ]; then
        
        echo -e "\n"
        echo -e "==========» ${BLUE}Das System wird auf die neuste Version geupdated...${NC} «=========="
        apt update && apt upgrade -y
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die erforderlichen Packete werden Installiert...${NC} «=========="
        apt install -y \
        apt-transport-https bash-completion bzip2 ca-certificates cron curl dialog \
        dirmngr ffmpeg ghostscript git gpg gnupg gnupg2 htop jq libfile-fcntllock-perl \
        libfontconfig1 libfuse2 locate lsb-release net-tools rsyslog screen smbclient \
        socat software-properties-common ssl-cert tree unzip wget zip
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Das System wird auf den neusten Stand gebracht und alte Packete werden entfernt...${NC} «=========="
        apt update && apt upgrade -y && apt autoremove -y && apt autoclean -y
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die erforderlichen Verzeichnisse für Nextcloud werden angelegt und die Berechtigung wird gesetzt...${NC} «=========="
        mkdir -p /var/www /var/nc_data
        chown -R www-data:www-data /var/nc_data /var/www
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die erforderlichen Packete für Redis und PHP werden Installiert und das System wird auf den neusten Stand gebracht...${NC} «=========="
        apt -y install lsb-release apt-transport-https ca-certificates 
        wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
        apt update
        apt install -y redis-server redis-server libapache2-mod-php8.2 php-common php8.2-{fpm,gd,curl,xml,zip,intl,mbstring,bz2,ldap,apcu,bcmath,gmp,imagick,igbinary,mysql,redis,smbclient,cli,common,opcache,readline} imagemagick --allow-change-held-packages
        echo -e "====================================================================="

        # Überprüfe die Eingabe des Benutzers
        echo -e "\n"
        if confirm "Möchtest du MariaDB Installieren?"; then
            DatenbankRootPasswort=""
            ask_settings_pw "Gebe das Passwort für den MariaDB-Root-Benutzer ein:" DatenbankRootPasswort
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die erforderlichen Signierungen für MariaDB werden konfiguriert...${NC} «=========="
            wget -O- https://mariadb.org/mariadb_release_signing_key.asc \
            | gpg --dearmor | sudo tee /usr/share/keyrings/mariadb-keyring.gpg >/dev/null
            echo "deb [signed-by=/usr/share/keyrings/mariadb-keyring.gpg] \
            https://mirror.kumi.systems/mariadb/repo/10.11/debian $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mariadb.list
            echo -e "====================================================================="

            echo -e "\n"
            echo -e "==========» ${BLUE}Das System wird auf den neusten Stand gebracht...${NC} «=========="
            apt update
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die erforderlichen Packete für MariaDB werden installiert...${NC} «=========="
            apt install -y mariadb-server
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB wird nun Abgesichert...${NC} «=========="
            printf "n\n$mariadb_root_password\ny\ny\ny\ny\n" | mysql_secure_installation
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB wird nun heruntergefahren...${NC} «=========="
            service mariadb stop
        echo -e "${GREEN}Done${NC}"
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die Performence von MariaDB wird verbessert sowie die Absicherung von MariaDB...${NC} «=========="
            echo "[client]" >> /etc/mysql/my.cnf && \
            echo "default-character-set = utf8mb4" >> /etc/mysql/my.cnf && \
            echo "port = 3306" >> /etc/mysql/my.cnf && \
            echo "socket = /var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf && \
            echo "[mysqld_safe]" >> /etc/mysql/my.cnf && \
            echo "log_error=/var/log/mysql/mysql_error.log" >> /etc/mysql/my.cnf && \
            echo "nice = 0" >> /etc/mysql/my.cnf && \
            echo "socket = /var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf && \
            echo "[mysqld]" >> /etc/mysql/my.cnf && \
            echo "# performance_schema=ON" >> /etc/mysql/my.cnf && \
            echo "basedir = /usr" >> /etc/mysql/my.cnf && \
            echo "bind-address = 127.0.0.1" >> /etc/mysql/my.cnf && \
            echo "binlog_format = ROW" >> /etc/mysql/my.cnf && \
            echo "character-set-server = utf8mb4" >> /etc/mysql/my.cnf && \
            echo "collation-server = utf8mb4_general_ci" >> /etc/mysql/my.cnf && \
            echo "datadir = /var/lib/mysql" >> /etc/mysql/my.cnf && \
            echo "default_storage_engine = InnoDB" >> /etc/mysql/my.cnf && \
            echo "expire_logs_days = 2" >> /etc/mysql/my.cnf && \
            echo "general_log_file = /var/log/mysql/mysql.log" >> /etc/mysql/my.cnf && \
            echo "innodb_buffer_pool_size = 2G" >> /etc/mysql/my.cnf && \
            echo "innodb_log_buffer_size = 32M" >> /etc/mysql/my.cnf && \
            echo "innodb_log_file_size = 512M" >> /etc/mysql/my.cnf && \
            echo "innodb_read_only_compressed=OFF" >> /etc/mysql/my.cnf && \
            echo "join_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "key_buffer_size = 512M" >> /etc/mysql/my.cnf && \
            echo "lc_messages_dir = /usr/share/mysql" >> /etc/mysql/my.cnf && \
            echo "lc_messages = en_US" >> /etc/mysql/my.cnf && \
            echo "log_bin = /var/log/mysql/mariadb-bin" >> /etc/mysql/my.cnf && \
            echo "log_bin_index = /var/log/mysql/mariadb-bin.index" >> /etc/mysql/my.cnf && \
            echo "log_error = /var/log/mysql/mysql_error.log" >> /etc/mysql/my.cnf && \
            echo "log_slow_verbosity = query_plan" >> /etc/mysql/my.cnf && \
            echo "log_warnings = 2" >> /etc/mysql/my.cnf && \
            echo "long_query_time = 1" >> /etc/mysql/my.cnf && \
            echo "max_connections = 100" >> /etc/mysql/my.cnf && \
            echo "max_heap_table_size = 64M" >> /etc/mysql/my.cnf && \
            echo "myisam_sort_buffer_size = 512M" >> /etc/mysql/my.cnf && \
            echo "port = 3306" >> /etc/mysql/my.cnf && \
            echo "pid-file = /var/run/mysqld/mysqld.pid" >> /etc/mysql/my.cnf && \
            echo "query_cache_limit = 0" >> /etc/mysql/my.cnf && \
            echo "query_cache_size = 0" >> /etc/mysql/my.cnf && \
            echo "read_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "read_rnd_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "skip-name-resolve" >> /etc/mysql/my.cnf && \
            echo "socket = /var/run/mysqld/mysqld.sock" >> /etc/mysql/my.cnf && \
            echo "sort_buffer_size = 2M" >> /etc/mysql/my.cnf && \
            echo "table_open_cache = 400" >> /etc/mysql/my.cnf && \
            echo "table_definition_cache = 800" >> /etc/mysql/my.cnf && \
            echo "tmp_table_size = 32M" >> /etc/mysql/my.cnf && \
            echo "tmpdir = /tmp" >> /etc/mysql/my.cnf && \
            echo "transaction_isolation = READ-COMMITTED" >> /etc/mysql/my.cnf && \
            echo "user = mysql" >> /etc/mysql/my.cnf && \
            echo "wait_timeout = 600" >> /etc/mysql/my.cnf && \
            echo "[mysqldump]" >> /etc/mysql/my.cnf && \
            echo "max_allowed_packet = 16M" >> /etc/mysql/my.cnf && \
            echo "quick" >> /etc/mysql/my.cnf && \
            echo "quote-names" >> /etc/mysql/my.cnf && \
            echo "[isamchk]" >> /etc/mysql/my.cnf && \
            echo "key_buffer = 16M" >> /etc/mysql/my.cnf
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB wird gestartet...${NC} «=========="
            service mariadb start
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Die Datenbank sowie der Datenbankbenutzer für Nextcloud wird erstellt...${NC} «=========="
            mysql -u root -e "CREATE DATABASE nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci; CREATE USER nextcloud@localhost identified by 'nextcloud'; GRANT ALL PRIVILEGES on nextcloud.* to nextcloud@localhost; FLUSH privileges;"
            echo -e ""
            echo -e "${GREEN}Done${NC}"
            echo -e ""
            echo -e "====================================================================="
            
        else
            echo -e "\n"
            echo -e "==========» ${BLUE}MariaDB Installation wird übersprungen...${NC} «=========="
            
            ask_settings "Gebe den Host des Datenbankservers an (localhost):" DatabaseHost
            ask_settings "Gebe den Namen der Nextcloud-Datenbank an (nextcloud):" DatabaseName
            ask_settings "Gebe den Benutzernamen für die Nextcloud-Datenbank an(nextcloud):" DatabaseUser
            ask_settings_pw "Gebe das Passwort für die Nextcloud-Datenbank an (nextcloud):" DatabasePassword

            echo -e "\n"
            echo -e "====================================================================="
        fi
        
        echo -e "\n"
        echo -e "==========» ${BLUE}Die Zeitzone wird ungestellt...${NC} «=========="
        timedatectl set-timezone $TimeZone
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Damit PHP an dem System angepasst wird, werden einige Parameter berechnet...${NC} «=========="
        AvailableRAM=$(awk '/MemAvailable/ {printf "%d", $2/1024}' /proc/meminfo)
        AverageFPM=$(ps --no-headers -o 'rss,cmd' -C php-fpm8.2 | awk '{ sum+=$1 } END { printf ("%d\n", sum/NR/1024,"M") }')
        FPMS=$((AvailableRAM/AverageFPM))
        PMaxSS=$((FPMS*2/3))
        PMinSS=$((PMaxSS/2))
        PStartS=$(((PMaxSS+PMinSS)/2))
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        sed -i "s/;env\[HOSTNAME\] = /env[HOSTNAME] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[TMP\] = /env[TMP] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[TMPDIR\] = /env[TMPDIR] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[TEMP\] = /env[TEMP] = /" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;env\[PATH\] = /env[PATH] = /" /etc/php/8.2/fpm/pool.d/www.conf
        
        sed -i 's/pm.max_children =.*/pm.max_children = 200/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i 's/pm.start_servers =.*/pm.start_servers = 100/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i 's/pm.min_spare_servers =.*/pm.min_spare_servers = 60/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i 's/pm.max_spare_servers =.*/pm.max_spare_servers = 140/' /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/;pm.max_requests =.*/pm.max_requests = 1000/" /etc/php/8.2/fpm/pool.d/www.conf
        sed -i "s/allow_url_fopen =.*/allow_url_fopen = 1/" /etc/php/8.2/fpm/php.ini
        
        sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.2/cli/php.ini
        sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.2/cli/php.ini
        sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.2/cli/php.ini
        sed -i "s/post_max_size =.*/post_max_size = 10240M/" /etc/php/8.2/cli/php.ini
        sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10240M/" /etc/php/8.2/cli/php.ini
        sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.2/cli/php.ini
        sed -i "s/;cgi.fix_pathinfo.*/cgi.fix_pathinfo=0/" /etc/php/8.2/cli/php.ini
        
        sed -i "s/memory_limit = 128M/memory_limit = 1G/" /etc/php/8.2/fpm/php.ini
        sed -i "s/output_buffering =.*/output_buffering = Off/" /etc/php/8.2/fpm/php.ini
        sed -i "s/max_execution_time =.*/max_execution_time = 3600/" /etc/php/8.2/fpm/php.ini
        sed -i "s/max_input_time =.*/max_input_time = 3600/" /etc/php/8.2/fpm/php.ini
        sed -i "s/post_max_size =.*/post_max_size = 10G/" /etc/php/8.2/fpm/php.ini
        sed -i "s/upload_max_filesize =.*/upload_max_filesize = 10G/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;date.timezone.*/date.timezone = Europe\/\Berlin/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;session.cookie_secure.*/session.cookie_secure = true/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.enable_cli=.*/opcache.enable_cli=1/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.memory_consumption=.*/opcache.memory_consumption=256/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=64/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.max_accelerated_files=.*/opcache.max_accelerated_files=100000/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.revalidate_freq=.*/opcache.revalidate_freq=0/" /etc/php/8.2/fpm/php.ini
        sed -i "s/;opcache.save_comments=.*/opcache.save_comments=1/" /etc/php/8.2/fpm/php.ini

        sed -i "s|;emergency_restart_threshold.*|emergency_restart_threshold = 10|g" /etc/php/8.2/fpm/php-fpm.conf
        sed -i "s|;emergency_restart_interval.*|emergency_restart_interval = 1m|g" /etc/php/8.2/fpm/php-fpm.conf
        sed -i "s|;process_control_timeout.*|process_control_timeout = 10|g" /etc/php/8.2/fpm/php-fpm.conf
        
        sed -i '$aapc.enable_cli=1' /etc/php/8.2/mods-available/apcu.ini
        
        sed -i 's/opcache.jit=off/; opcache.jit=off/' /etc/php/8.2/mods-available/opcache.ini
        sed -i '$aopcache.jit=1255' /etc/php/8.2/mods-available/opcache.ini
        sed -i '$aopcache.jit_buffer_size=256M' /etc/php/8.2/mods-available/opcache.ini
        
        sed -i "s/rights=\"none\" pattern=\"PS\"/rights=\"read|write\" pattern=\"PS\"/" /etc/ImageMagick-6/policy.xml
        sed -i "s/rights=\"none\" pattern=\"EPS\"/rights=\"read|write\" pattern=\"EPS\"/" /etc/ImageMagick-6/policy.xml
        sed -i "s/rights=\"none\" pattern=\"PDF\"/rights=\"read|write\" pattern=\"PDF\"/" /etc/ImageMagick-6/policy.xml
        sed -i "s/rights=\"none\" pattern=\"XPS\"/rights=\"read|write\" pattern=\"XPS\"/" /etc/ImageMagick-6/policy.xml
        
        sed -i '$a[mysql]' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.allow_local_infile=On' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.allow_persistent=On' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.cache_size=2000' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.max_persistent=-1' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.max_links=-1' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.default_port=3306' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.connect_timeout=60' /etc/php/8.2/mods-available/mysqli.ini
        sed -i '$amysql.trace_mode=Off' /etc/php/8.2/mods-available/mysqli.ini
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}PHP und Apache2 wird nun neugestartet...${NC} «=========="
        systemctl restart php8.2-fpm
        a2dismod php8.2 mpm_prefork
        a2enmod proxy_fcgi setenvif mpm_event http2
        systemctl restart apache2.service
        a2enconf php8.2-fpm
        systemctl restart apache2.service php8.2-fpm
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Nextcloud wird heruntergeladen und in den vorgesehenen Ordner verschoben...${NC} «=========="
        wget https://download.nextcloud.com/server/releases/nextcloud-28.0.1.zip
        unzip nextcloud-28.0.1.zip
        mv nextcloud/ /var/www/html/
        chown -R www-data:www-data /var/www/html/nextcloud
        rm -f nextcloud-28.0.1.zip
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Redis wird nun angepasst...${NC} «=========="
        sed -i "s/port 6379/port 0/" /etc/redis/redis.conf
        sed -i s/\#\ unixsocket/\unixsocket/g /etc/redis/redis.conf
        sed -i "s/unixsocketperm 700/unixsocketperm 770/" /etc/redis/redis.conf
        sed -i "s/# maxclients 10000/maxclients 10240/" /etc/redis/redis.conf
        usermod -aG redis www-data
        sed -i '$avm.overcommit_memory = 1' /etc/sysctl.conf
        sysctl -p
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Apache2 wird nun angepasst...${NC} «=========="
        a2enmod rewrite headers env dir mime
        sed -i '/<IfModule !mpm_prefork>/a \    H2Direct on\n    H2StreamMaxMemSize 128000' /etc/apache2/mods-available/http2.conf
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Apache2 wird neugestartet...${NC} «=========="
        systemctl restart apache2.service
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die VirtualHost-Datei für LetsEncrypt wird erstellt...${NC} «=========="
        cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/001-nextcloud.conf
        a2dissite 000-default.conf
        echo "<VirtualHost *:80>
    ServerName $Domain
    ServerAlias $Domain
    ServerAdmin $EmailApache2
    DocumentRoot /var/www/html/nextcloud
    ErrorLog /var/log/apache2/error.log
    CustomLog /var/log/apache2/access.log combined
    RewriteEngine on
    RewriteCond %{SERVER_NAME} =$Domain
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>" > /etc/apache2/sites-available/001-nextcloud.conf
        a2ensite 001-nextcloud.conf
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die VirtualHost-Datei für LetsEncrypt wird nun aktiviert und Apache2 wird neugestartet...${NC} «=========="
        a2ensite 001-nextcloud.conf
        systemctl restart apache2.service
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Das SSL-Zertifikat wird nun ausgestellt...${NC} «=========="
        apt install -y certbot python3-certbot-apache
        certbot --apache -d $Domain -m $EmailLetsEncrypt --agree-tos
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die VirtualHost-Datei für Nextcloud wird nun erstellt...${NC} «=========="
        echo "<IfModule mod_ssl.c>
    SSLUseStapling on
    SSLStaplingCache shmcb:/var/run/ocsp(128000)
    <VirtualHost *:443>
        SSLCertificateFile /etc/letsencrypt/live/$Domain/fullchain.pem
        SSLCACertificateFile /etc/letsencrypt/live/$Domain/fullchain.pem
        SSLCertificateKeyFile /etc/letsencrypt/live/$Domain/privkey.pem
        Protocols h2 h2c http/1.1
        Header add Strict-Transport-Security: 'max-age=15552000;includeSubdomains'
        ServerAdmin $EmailApache2
        ServerName $Domain
        ServerAlias $Domain
        SSLEngine on
        SSLCompression off
        SSLOptions +StrictRequire
        SSLProtocol -all +TLSv1.3 +TLSv1.2
        SSLCipherSuite ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384
        SSLHonorCipherOrder off
        SSLSessionTickets off
        ServerSignature off
        SSLStaplingResponderTimeout 5
        SSLStaplingReturnResponderErrors off
        SSLOpenSSLConfCmd Curves X448:secp521r1:secp384r1:prime256v1
        SSLOpenSSLConfCmd ECDHParameters secp384r1
        LogLevel warn
        CustomLog /var/log/apache2/access.log combined
        ErrorLog /var/log/apache2/error.log
        DocumentRoot /var/www/html/nextcloud
        <Directory /var/www/html/nextcloud/>
            Options Indexes FollowSymLinks
            AllowOverride All
            Require all granted
            Satisfy Any
        </Directory>
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        <Directory /var/nc_data>
            Require all denied
        </Directory>
        <Files '.ht*'>
            Require all denied
        </Files>
        TraceEnable off
        RewriteEngine On
        RewriteCond %{REQUEST_METHOD} ^TRACK
        RewriteRule .* - [R=405,L]
        SetEnv HOME /var/www/html/nextcloud
        SetEnv HTTP_HOME /var/www/html/nextcloud
        <IfModule mod_reqtimeout.c>
            RequestReadTimeout body=0
        </IfModule>
    </VirtualHost>
</IfModule>
" > /etc/apache2/sites-available/001-nextcloud-le-ssl.conf
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die TLS-Sicherheit wird nun verbessert...${NC} «=========="
        openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096
        cat /etc/ssl/certs/dhparam.pem >> /etc/letsencrypt/live/$Domain/fullchain.pem
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Apache2-Konfigurationsdatei wird nun angepasst und Apache2 wird neugestartet...${NC} «=========="
        sed -i "/#<\/Directory>/a ServerName ${Domain}\n<Directory \/var\/www\/>\n\tOptions FollowSymLinks MultiViews\n\tAllowOverride All\n\tRequire all granted\n</Directory>\n" /etc/apache2/apache2.conf
        service apache2 restart
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Nextcloud wird nun installiert...${NC} «=========="
        sudo -u www-data php /var/www/html/nextcloud/occ maintenance:install --database "mysql" --database-host $DatabaseHost --database-name $DatabaseName --database-user $DatabaseUser --database-pass $DatabasePassword --admin-user $NextcloudAdminUser --admin-email $NextcloudAdminEmail --admin-pass $NextcloudAdminPassword --data-dir "/var/nc_data"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Nextcloud-Konfigurationsdatei wird nun angepasst...${NC} «=========="
        sed -i "s|'datadirectory' => '/var/www/nextcloud/data',|'datadirectory' => '/var/nc_data',|g" /var/www/html/nextcloud/config/config.php && \
        sed -i "s|'overwrite.cli.url' => 'http://localhost',|'overwrite.cli.url' => 'https://$Domain/',|g" /var/www/html/nextcloud/config/config.php
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die .htaccess-Datei wird nun geupdated...${NC} «=========="
        sudo -u www-data php /var/www/html/nextcloud/occ maintenance:update:htaccess
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Erforderliche Verzeichnisse für die Logs von Nextcloud werden erstellt und Berechtigungen gesetzt...${NC} «=========="
        mkdir -p /var/log/nextcloud/
        chown -R www-data:www-data /var/log/nextcloud
        sudo -u www-data cp /var/www/html/nextcloud/config/config.php /var/www/html/nextcloud/config/config.php.bak
        sudo -u www-data sed -i 's/^[ ]*//' /var/www/html/nextcloud/config/config.php
        sudo -u www-data sed -i '/);/d' /var/www/html/nextcloud/config/config.php
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Die Nextcloud-Konfigurationsdatei wird angepasst...${NC} «=========="
sudo -u www-data cat <<EOF >>/var/www/html/nextcloud/config/config.php
'activity_expire_days' => 14,
'allow_local_remote_servers' => true,
'auth.bruteforce.protection.enabled' => true,
'blacklisted_files' =>
array (
0 => '.htaccess',
1 => 'Thumbs.db',
2 => 'thumbs.db',
),
'cron_log' => true,
'default_phone_region' => 'DE',
'defaultapp' => 'files,dashboard',
'enable_previews' => true,
'enabledPreviewProviders' =>
array (
0 => 'OC\Preview\PNG',
1 => 'OC\Preview\JPEG',
2 => 'OC\Preview\GIF',
3 => 'OC\Preview\BMP',
4 => 'OC\Preview\XBitmap',
5 => 'OC\Preview\Movie',
6 => 'OC\Preview\PDF',
7 => 'OC\Preview\MP3',
8 => 'OC\Preview\TXT',
9 => 'OC\Preview\MarkDown',
),
'filesystem_check_changes' => 0,
'filelocking.enabled' => 'true',
'htaccess.RewriteBase' => '/',
'integrity.check.disabled' => false,
'knowledgebaseenabled' => false,
'logfile' => '/var/log/nextcloud/nextcloud.log',
'loglevel' => 2,
'logtimezone' => 'Europe/Berlin',
'log_rotate_size' => '104857600',
'maintenance' => false,
'maintenance_window_start' => 1,
'memcache.local' => '\OC\Memcache\APCu',
'memcache.locking' => '\OC\Memcache\Redis',
'overwriteprotocol' => 'https',
'preview_max_x' => 1024,
'preview_max_y' => 768,
'preview_max_scale_factor' => 1,
'profile.enabled' => false,
'redis' =>
array (
'host' => '/var/run/redis/redis-server.sock',
'port' => 0,
'timeout' => 0.5,
'dbindex' => 1,
),
'quota_include_external_storage' => false,
'share_folder' => '/share',
'skeletondirectory' => '',
'theme' => '',
'trashbin_retention_obligation' => 'auto, 7',
'updater.release.channel' => 'stable',
);
EOF
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Nextcloud wird angepasst...${NC} «=========="
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set remember_login_cookie_lifetime --value="1800"
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set simpleSignUpLink.shown --type=bool --value=false
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set versions_retention_obligation --value="auto, 365"
        sudo -u www-data php /var/www/html/nextcloud occ config:system:set loglevel --value=2
        sudo -u www-data php /var/www/html/nextcloud/occ config:system:set trusted_domains 1 --value=$Domain
        sudo -u www-data php /var/www/html/nextcloud/occ config:app:set settings profile_enabled_by_default --value="0"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Apache2-Module und die Nextcloud VirtualHost-Datei wird aktiviert...${NC} «=========="
        a2enmod ssl && a2ensite 001-nextcloud.conf 001-nextcloud-le-ssl.conf
        systemctl restart php8.2-fpm.service redis-server.service apache2.service
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Der Crontab-Service wird angelegt...${NC} «=========="
        echo "*/5 * * * * php -f /var/www/html/nextcloud/cron.php > /dev/null 2>&1" | sudo crontab -u www-data - && sudo -u www-data php /var/www/html/nextcloud/occ background:cron
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Weitere Sicherheitsvorkehrungen werden konfiguriert...${NC} «=========="
        a2dismod status
        sed -i 's/ServerTokens OS/ServerTokens Prod/g' /etc/apache2/conf-available/security.conf && \
        sed -i 's/ServerSignature On/ServerSignature Off/g' /etc/apache2/conf-available/security.conf
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}PHP, Redis und Apache2 werden neugestartet...${NC} «=========="
        systemctl restart php8.2-fpm.service redis-server.service apache2.service
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        if confirm "Möchtest Du Nextcloud Office auch Installieren?"; then
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Nextcloud Office wird nun installiert...${NC} «=========="
            sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ app:install richdocuments
            sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ app:install richdocumentscode
            echo -e "====================================================================="

        else

            echo -e "\n"
            echo -e "${RED}Nextcloud Office wird übersprungen.${NC} «=========="
            echo -e "====================================================================="

        fi

        echo -e "\n"
        if confirm "Möchtest Du Client Push auch Installieren? (Empfohlen)"; then
            
            echo -e "\n"
            echo -e "==========» ${BLUE}Client Push wird nun installiert...${NC} «=========="
            sudo -u www-data /usr/bin/php /var/www/html/nextcloud/occ app:install notify_push
                    echo "[Unit]
Description = Push daemon for Nextcloud clients

[Service]
Environment=PORT=7867
Environment=NEXTCLOUD_URL=https://$Domain/
ExecStart=/var/www/html/nextcloud/apps/notify_push/bin/x86_64/notify_push /var/www/html/nextcloud/config/config.php
User=www-data

[Install]
WantedBy = multi-user.target
" > /etc/systemd/system/notify_push.service
            sudo systemctl enable --now notify_push
            sudo systemctl start notify_push
            sudo -u www-data php /var/www/html/nextcloud/occ config:system:set trusted_proxies 0 --value=$(curl -4 ifconfig.co)
            sudo a2enmod proxy
            sudo a2enmod proxy_http
            sudo a2enmod proxy_wstunnel
            sudo sed -i '/<\/VirtualHost>/i \        ProxyPass \/push\/ws ws:\/\/127.0.0.1:7867\/ws\n        ProxyPass \/push\/ http:\/\/127.0.0.1:7867\/\n        ProxyPassReverse \/push\/ http:\/\/127.0.0.1:7867\/' /etc/apache2/sites-enabled/001-nextcloud-le-ssl.conf
            service apache2 restart
            echo -e "====================================================================="

        else

            echo -e "\n"
            echo -e "${RED}Client Push wird übersprungen.${NC} «=========="
            echo -e "====================================================================="

        fi

        echo -e "\n"
        echo -e "==========» ${BLUE}Fail2Ban und UFW wird installiert...${NC} «=========="
        apt install -y fail2ban ufw
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Filterkonfigurationsdatei für Nextcloud werden erstellt...${NC} «=========="
        nextcloud_filter="/etc/fail2ban/filter.d/nextcloud.conf"
        touch $nextcloud_filter
cat <<EOF >$nextcloud_filter
[Definition]
_groupsre = (?:(?:,?\s*\"\w+\":(?:"[^"]+"|\w+))*)
failregex = ^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Login failed:
^\{%(_groupsre)s,?\s*"remoteAddr":"<HOST>"%(_groupsre)s,?\s*"message":"Trusted domain error."
datepattern = ,?\s*"time"\s*:\s*"%%Y-%%m-%%d[T ]%%H:%%M:%%S(%%z)?"
EOF
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Jail-Konfigurationsdatei für Nextcloud wird erstellt...${NC} «=========="
        nextcloud_jail="/etc/fail2ban/jail.d/nextcloud.local"
        touch $nextcloud_jail
cat <<EOF >$nextcloud_jail
[nextcloud]
backend = auto
enabled = true
port = 80,443
protocol = tcp
filter = nextcloud
maxretry = 5
bantime = 3600
findtime = 36000
logpath = /var/log/nextcloud/nextcloud.log
EOF
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Fail2Ban wird neugestartet...${NC} «=========="
        service fail2ban restart
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}Firewallregeln werden konfiguriert...${NC} «=========="
        ufw allow 443/tcp comment "SSL"
        ufw allow 22/tcp comment "SSH"
        ufw logging medium
        ufw enable
        echo -e "====================================================================="

        echo -e "\n"
        echo -e "==========» ${BLUE}UFW wird neugstartet...${NC} «=========="
        service ufw restart
        echo -e "${GREEN}Done${NC}"
        echo -e "====================================================================="

        clear
        echo -e ""
        echo -e "${GREEN} _  _  ___  _  _  ____  __  __    __  _  _  ___     __  _  _  ___  ____  __   __    __    ___  ___  ${NC}"
        echo -e "${GREEN}( \( )(  _)( \/ )(_  _)/ _)(  )  /  \( )( )(   \   (  )( \( )/ __)(_  _)(  ) (  )  (  )  (  _)(  ,) ${NC}"
        echo -e " ${GREEN} )  (  ) _) )  (   )( ( (_  )(__( () ))()(  ) ) )   )(  )  ( \__ \  )(  /__\  )(__  )(__  ) _) )  \ ${NC}"
        echo -e "${GREEN}(_)\_)(___)(_/\_) (__) \__)(____)\__/ \__/ (___/   (__)(_)\_)(___/ (__)(_)(_)(____)(____)(___)(_)\_)${NC}"
        echo -e "\n"
        echo -e "==========» ${GREEN}Alles wurde Installiert!${NC} «=========="
        echo -e ""
        echo -e " - Datenverzeichnis: ${GREEN}/var/nc_data${NC}"
        echo -e " - Nextcloud-Verzeichnis: ${GREEN}/var/www/html/nextcloud${NC}"
        echo -e ""
        echo -e " - Web-UI: ${GREEN}https://$Domain${NC}"
        echo -e ""
        echo -e " - Nextcloud Administrator"
        echo -e "   -> Benutzername: ${GREEN}$NextcloudAdminUser${NC}"
        echo -e "   -> E-Mail: ${GREEN}$NextcloudAdminEmail${NC}"
        echo -e "   -> Passwort: ${GREEN}$NextcloudAdminPassword${NC}"
        echo -e ""
        echo -e "====================================================================="
        echo -e "\n"
        exit 1

    else
        echo -e "\n"
        echo -e "============================================================================="
        echo -e "==========» ${RED}Das Betriebssystem wird nicht unterstützt.${NC} «=========="
        echo -e "============================================================================="
        exit 1
    fi
else
    echo -e "\n"
    echo -e "============================================================"
    echo -e "==========» ${RED}Installation abgebrochen.${NC} «=========="
    echo -e "============================================================"
    
    exit 1
fi
