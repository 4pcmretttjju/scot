sudo docker-compose down

unset MONGODBUID
unset MONGODBGID
unset SCOTUID
unset SCOTGID
unset ELASTICUID
unset ELASTICGID
unset HOSTNAME

scot_log_dir="/var/log/scot"
scot_backup="/opt/scotbackup"
mongodb_dir="/var/lib/mongodb"
elastic_dir="/var/lib/elasticsearch"


#check if scot_log_dir exists
if [  -d $scot_log_dir ]; then
    echo "$scot_log_dir exists!"
else
    sudo mkdir -p $scot_log_dir
fi

#check if scot_backup exists
if [  -d $scot_backup ]; then
    echo "$scot_backup exists!"
else
    sudo mkdir -p $scot_backup
fi
#check if mongodb_dir exists
if [  -d $mongodb_dir ]; then
    echo "$mongodb_dir exists!"
else
    sudo mkdir -p $mongodb_dir
fi
#check if elastic_dir exists
if [ -d $elastic_dir ]; then
    echo "$elastic_dir exists!"
else
    sudo mkdir -p $elastic_dir
fi



#set permissions
sudo chmod -R 0755 /opt/scotbackup/
sudo chmod -R 0777 /var/log/scot/
sudo chmod -R g+rwx /var/lib/elasticsearch/ 
sudo chgrp 1000 /var/lib/elasticsearch/

function add_users {
    echo "- checking for existing scot user"
    if grep --quiet -c scot: /etc/passwd; then
        echo "- scot user exists"
    else
       echo "SCOT user does not exist. Creating user"
       sudo useradd -c "SCOT User"  -M -s /bin/bash scot
    fi

    echo "-Checking for existing Elastic User"
    if grep --quiet -c elasticsearch: /etc/passwd; then
        echo "- elasticsearch user exists"
    else
        echo "Elasticsearch user does not exist. Creating user"
        sudo useradd -c "elasticsearch User"  -M -s /bin/bash elasticsearch
    fi
    
    echo "-Checking for existing Mongodb User"
    if grep --quiet -c mongodb: /etc/passwd; then
        echo "- mongodb user exists"
    else
        
       echo "mongodb user does not exist. Creating user"
       sudo useradd -c "mongodb User"  -M -s /bin/bash mongodb
    fi

}

#set ownership 
sudo chown -R mongodb:mongodb /var/lib/mongodb/ /var/log/mongodb/
sudo chown -R scot:scot /var/log/scot/ /opt/scot/

#add users
add_users

export SCOTUID=`id scot -u`
export SCOTGID=`id scot -g` 
export ELASTICUID=`id elasticsearch -u`
export ELASTICGID=`id elasticsearch -g`
export MONGODBUID=`id mongodb -u`
export MONGODBGID=`id mongodb -g`


#build open-source scot

echo " "
echo "**************** "
echo "Hello, and welcome to the Docker version of SCOT 🔍 "
echo " "
echo "This script will walk you through the installation process. First, we have a couple questions for you"
echo " "
echo "SCOT has two installation modes:" 
echo " "
echo "1. Easy Mode - In this mode, we will pull pre-built images from Dockerhub. Note: Using this mode, there is no customization such as insertion of your own server's SSL certs, no LDAP integration, etc."
echo "2. Custom mode: In this mode, we will build the Docker containers from the Dockerfiles contained in the cloned source code. You can also make changes to the Dockerfiles, source code, etc. as you see fit"
echo " "
echo -n "Please enter your selection: 1 for easy mode / 2 for custom mode"
read -n 1 selection

if [ "$selection" == "1" ]; then
  echo "You selected easy mode."
  echo " "
  sudo -E docker-compose up --build
elif [ "$selection" == "2" ]; then
  echo "You selected custom mode."
  echo " "
  sudo -E docker-compose -f docker-compose-custom.yml up --build
else:
  echo "Invalid selection"
fi





