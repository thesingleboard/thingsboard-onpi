#!/bin/bash -x

#This setup script is based on the in memory setup for a pi3 found on the thingsboard site
#https://thingsboard.io/docs/user-guide/install/rpi/?ubuntuThingsboardQueue=inmemory

#What adapter will Thingsboard use. 
ETH='wlan0'

#If the DB has never been used just leave blank, if exisiting db set password here
export env PSQLPASS=''

#The new password to set
export env NEWPSQLPASS='newpass'

#get the IP of the primary adapter
export env IP=`ip addr | grep $ETH -A2 | grep 'inet' | head -1 | awk '{print $2}' | cut -f1  -d'/'`

#update the OS and install Java
sudo apt update
sudo apt install -y openjdk-8-jdk

#make sure we use open JDK 8 by default
sudo update-alternatives --config java

#Get thingsboard 3.0.1
wget https://github.com/thingsboard/thingsboard/releases/download/v3.0.1/thingsboard-3.0.1.deb

#install thingsboard
sudo dpkg -i thingsboard-3.0.1.deb

#Set up pg sql - can be used for deloyments with less than 5000 devices reporting in
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
RELEASE=$(lsb_release -cs)
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}"-pgdg main | sudo tee  /etc/apt/sources.list.d/pgdg.list
sudo apt update
sudo apt -y install postgresql-11
sudo service postgresql start

#configure postgres
export env PGPASSWORD=${PSQLPASS}
if [ -n $NEWPSQLPASS ]
then
    psql -U postgres -d postgres -h 127.0.0.1 -c "ALTER USER postgres WITH PASSWORD '"${NEWPSQLPASS}"';"
fi
psql -U postgres -d postgres -h 127.0.0.1 -c "CREATE DATABASE thingsboard;"

#thingsboard config
# DB Configuration
(
cat   << 'EOF'
export DATABASE_ENTITIES_TYPE=sql
export DATABASE_TS_TYPE=sql
export SPRING_JPA_DATABASE_PLATFORM=org.hibernate.dialect.PostgreSQLDialect
export SPRING_DRIVER_CLASS_NAME=org.postgresql.Driver
export SPRING_DATASOURCE_URL=jdbc:postgresql://${IP}:5432/thingsboard
export SPRING_DATASOURCE_USERNAME=postgres
export SPRING_DATASOURCE_PASSWORD=${NEWPSQLPASS}
export SPRING_DATASOURCE_MAXIMUM_POOL_SIZE=5
# Specify partitioning size for timestamp key-value storage. Allowed values: DAYS, MONTHS, YEARS, INDEFINITE.
export SQL_POSTGRES_TS_KV_PARTITIONING=MONTHS
export JAVA_OPTS="$JAVA_OPTS -Xms256M -Xmx256M"
EOF
) >> /etc/thingsboard/conf/thingsboard.conf

<<<<<<< HEAD
sudo /usr/share/thingsboard/bin/install/install.sh --loadDemo

sudo service thingsboard start


=======
#load thingsboard
sudo /usr/share/thingsboard/bin/install/install.sh

#start the service
sudo service thingsboard start

while [ out -ne 200 ]
do
    out = curl -o /dev/null -s -w "%{http_code}\n" http://${IP}:8080
    sleep(5)
    echo 'Waiting for Thingsboard to come up'
done

echo 'Thingsboard is up'
echo 'http://${IP}/8080'
>>>>>>> bcda8597732e0dac82906efbc3c5c3fb86e6465f
