#!/bin/bash
#Abort installation if any of the commands fail
set -e

#Check if Java is already installed
java_present=$(java -version > /dev/null 2>&1; echo $?)

#Check the Model of Pi. There needs to be a different binary and Java for Zero (ARMv6)
model=$(echo $(cat /proc/cpuinfo | grep Model | grep -e "Zero" -e "Model A"))
if [[ -n $model ]]
then
	echo "Pi Zero detected. Downloading old HA binary."
	#HA_Version5.2.2 works with OpenJDK_8 while Later versions of HA do not
	haBridgeLink='https://github.com/bwssytems/ha-bridge/releases/download/v5.2.2/ha-bridge-5.2.2.jar'	
else
	echo "Not Pi Zero Model. Downloading recent/latest HA binary."
	haBridgeLink='https://github.com/bwssytems/ha-bridge/releases/download/v5.3.0/ha-bridge-5.3.0-java11.jar'
fi

#Fetch the HA Bridge JAR file
sudo wget -O ha-bridge.jar $haBridgeLink
echo "Downloaded HA Bridge JAR file."

if [[ $java_present != 0 ]]
then
	#Install OpenJDK
	sudo apt-get install -y openjdk-8-jdk

	#Update the alternatives for Java	
	sudo update-alternatives --config javac
	sudo update-alternatives --config java
	echo "Updated Java config."
else
	#If Java is present, make sure it is working for PiZero/PiOne	
	echo "Java present. Skipping Java installation."
fi

#Update things
sudo apt-get update
echo "Update complete."

#In case needed for some testing, you can run HA Bridge via command prompt
#sudo java -jar -Dserver.port=8080 /etc/habridge/ha-bridge.jar

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

	#Copy the service file to HA BRidge directory
	sudo mv HABridge.service /etc/habridge
	sudo chmod 755 /etc/habridge/HABridge.service
	
	#Link the service file to System directory
	sudo ln -sf /etc/habridge/HABridge.service /etc/systemd/system/HABridge.service
	
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
	
	#Restart daemon
	sudo systemctl daemon-reload

	#Enable the newly created service
	sudo systemctl enable HABridge

	#Start the service
	sudo systemctl start HABridge
	
	#Remove files that are no longer used
	rm ha-bridge.jar
fi

#Check the status of service
systemctl status HABridge

#Proceed to set up the RF 433
cd ~
#Download the device.db file from github
wget https://github.com/piyushkumarjiit/HABridgeOnPi/blob/master/device.db
#Download the RF433Setup script from github
wget https://raw.githubusercontent.com/piyushkumarjiit/RFUtilScript/master/RF433Setup.sh

#Update the permission
sudo chmod 755 RF433Setup.sh
echo "Permission update, calling the script."
sudo bash RF433Setup.sh

#Update HA Bridge Config
#See if possible to update the config via command line else provide link to the tutorial
#Open the URL to ensure that data folder and config files are created.
curl http://192.168.2.125/#!/editdevice

#Create the data directory
if [[ -d "/etc/habridge/data" ]]
then
	echo "Directory exists."
else
	echo "Creating directory."
	sudo mkdir /etc/habridge/data
fi
#Update the device.db with your RFC codes
sudo mv device.db /etc/habridge/data/

#Restart the HA Bridge service to load the modified file
sudo systemctl restart HABridge.service

	
echo "HA Bridge script complete."