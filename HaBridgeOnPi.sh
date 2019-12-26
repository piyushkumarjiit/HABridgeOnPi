#!/bin/bash
#Abort installation if any of the commands fail
set -e
#userName=$(whoami)
#openJDKLink='https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt.deb'
#oracleJDKLink=''
#haBridgeLink='https://github.com/bwssytems/ha-bridge/releases/download/v5.3.0/ha-bridge-5.3.0-java11.jar'
java_present=$(java -version > /dev/null 2>&1; echo $?)
#In case you want OpenJDK 11
#wget -O JDK.deb $openJDKLink
#echo "Downloaded OpenJDK."
if [[ $java_present != 0 ]]
then
	#Install OpenJDK
	#sudo apt-get install ./JDK.deb
	sudo apt-get install -y openjdk-8-jdk

	sudo update-alternatives --config javac
	sudo update-alternatives --config java
else
	echo "Java present. Skipping Java installation."
fi
#In case you want to use Oracle JDK, Download the JDK 11 from
#wget oracleJDKLink
#Unzip the JDK 

#Update things
sudo apt-get update
echo "Update complete."

#Run HA Bridge via command prompt
#sudo java -jar -Dserver.port=8080 ha-bridge-3.5.1.jar



if [ -f "/etc/systemd/system/HABridge.service" ] 
then
    echo "habridge service file exists." 
else
    echo "Habridge service file does not exists. Proceeding with installation."
	
	#Create the HA Bridge Directory
	if [ -d "/etc/habridge" ] 
	then
		echo "/etc/habridge Directory exists." 
	else
		echo "Directory /etc/habridge does not exists. Creating directory"
		sudo mkdir /etc/habridge
	fi

	if [ -f "/etc/habridge/ha-bridge.jar" ] 
	then
		echo "habridge.jar file exists." 
	else
		echo "Habridge.jar file does not exists. Importing the jar file."
		cd /etc/habridge
		#Fetch the HA Bridge jar
		sudo wget -O ha-bridge.jar $haBridgeLink
		echo "Downloaded HaBridge jar."
	fi
	
	cd ~
	#Download the service file from github
	wget https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/HABridge.service
	echo "Service file donwloaded."

	#Copy the service file to system directory
	sudo mv HABridge.service /etc/systemd/system/
	
	#Add habridgeadmin User
	user_exists=$(id -u habridgeadmin > /dev/null 2>&1; echo $?)
	if [[ $user_exists == "1" ]]
	then
		echo "Adding user"
		sudo useradd -s /usr/sbin/nologin -r -M habridgeadmin
	else
		echo "User exists. Continuing without adding."
	fi

	#update Permission on the HA Bridge direcotry
	sudo chown -R habridgeadmin:habridgeadmin /etc/habridge
fi

#Restart daemon
sudo systemctl daemon-reload

#Enable the newly created service
sudo systemctl enable HABridge

#Start the service
sudo systemctl start HABridge

#Check the status of service
systemctl status HABridge

echo "Script complete."