#!/bin/bash
set -e
userName=$(whoami)
#openJDKLink='https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt.deb'
#oracleJDKLink=''
#haBridgeLink='https://github.com/bwssytems/ha-bridge/releases/download/v5.3.0/ha-bridge-5.3.0-java11.jar'

#In case you want OpenJDK 11
#wget -O JDK.deb $openJDKLink
#echo "Downloaded OpenJDK."

#Install OpenJDK
#sudo apt-get install ./JDK.deb
sudo apt-get install -y

sudo update-alternatives --config javac
sudo update-alternatives --config java

#In case you want to use Oracle JDK, Download the JDK 11 from
#wget oracleJDKLink
#Unzip the JDK 

#Create the HA Bridge Directory
if [ -d "/etc/habridge" ] 
then
    echo "/etc/habridge Directory exists." 
else
    echo "Directory /etc/habridge does not exists. Creating directory"
	sudo mkdir /etc/habridge
fi

cd /etc/habridge

#Fetch the HA Bridge jar
sudo wget -O ha-bridge.jar $haBridgeLink
echo "Downloaded HaBridge jar."

#Add habridgeadmin User
user_exists=$(id -u habridgeadmin > /dev/null 2>&1; echo $?)
if [[ $user_exists == "1" ]]
then
	echo "Adding user"
	sudo useradd -s /usr/sbin/nologin -r -M habridgeadmin
else
	echo "User exists. Continuing without adding."
fi

#Update things
sudo apt-get update
echo "Update complete."

#Run HA Bridge via command prompt
#sudo java -jar -Dserver.port=8080 ha-bridge-3.5.1.jar

cd ~
#Download the service file from github
wget https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/HABridge.service
echo "Service file donwloaded."

#Update the service file
#sed -i "s/userName/${userName}/g" HABridge.service
#sed -i "s/userName/${userName}/g" HABridge.service
#echo "Updated service file"

#Copy the service file to system directory
sudo mv HABridge.service /etc/systemd/system/

#update Permission on the HA Bridge direcotry
sudo chown -R habridgeadmin:habridgeadmin /etc/habridge

#Restart daemon
sudo systemctl daemon-reload

#Enable the newly created service
sudo systemctl enable HABridge

#Start the service
sudo systemctl start HABridge

#Check the status of service
systemctl status HABridge