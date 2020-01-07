#!/bin/bash
#Abort installation if any of the commands fail
set -e

#Check if Java is already installed
java_present=$(java -version > /dev/null 2>&1; echo $?)

#Check if HA Bridge is already installed
habridge_present=$(sudo systemctl status HABridge.service > /dev/null 2>&1; echo $?)

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

if [[ $habridge_present -eq 0 ]]
then
    echo "HA Bridge service already installed." 
else
    echo "Habridge service does not exists. Proceeding with installation."
	
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
	#This user comes handy when running HA BRidge service on Higher ports (and not 80)
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
	
fi

#Check the status of service
#systemctl status HABridge
#Wait for service to start
sleep 5
echo "Open the Add Device URL"
#Open the URL to ensure that data folder and config files are created.
curl "http://192.168.2.125/#\!/editdevice" -o urloutput.txt
echo "Remove temp file."
rm urloutput.txt

#Give user option to setup RF433 outlets
while true; 
do
read -p "Do you want to proceed with RF Outlet setup? (Yes/No): " user_reply
case $user_reply in
	#User is ready to proceed with RF433Setup.sh
	[Yy]*) echo "Proceeding with RF Setup.";
	#Create the data directory
	if [[ -d "/etc/habridge/data" ]]
	then
		echo "HA Bridge Directory exists."
	else
		echo "Creating HA Bridge directory."
		sudo mkdir /etc/habridge/data
	fi
	
	#Proceed to set up the RF 433
	cd ~
	#Download the RF433Setup script from github
	wget https://raw.githubusercontent.com/piyushkumarjiit/RFUtilScript/master/RF433Setup.sh

	#Update the permission
	sudo chmod 755 RF433Setup.sh
	echo "Permission update, calling the script."
	#sudo -i -ubob -sfoo
	bash RF433Setup.sh

	#Check if devices.db exists
	if [[ -f "/etc/habridge/data/device.db" ]]
	then
		echo "Device File exists."
		#Ask user if existing file should be overwritten
		while :
		do
		  read -p "Do you want to overwrite existing devices.db file? (Yes/No): " overwrite_reply
		  case $overwrite_reply in
			#Overwrite existing file
			[Yy]* )
				echo "Proceeding with overwrite."
				#Create backup of old device.db
				sudo cp /etc/habridge/data/device.db /etc/habridge/data/device.db.old
				#Copy updated the device.db
				sudo cp device.db /etc/habridge/data/
				#Stop the HA Bridge service
				sudo systemctl stop HABridge.service
				#Reload Daemon to ensure latest changes are used by the service
				sudo systemctl daemon-reload
				#Start the HA Bridge service to load the modified file
				sudo systemctl start HABridge.service
				echo "Service restarted after reloading."
				break;;
				
			#Do not overwrite existing file	
			[Nn]* )
				echo "Existing devices.db file will not be updated. Please manually update HA Bridge config."
				echo "devices.db file exists and user selected to skip overwrite."
				break;;
				
			* )	echo "Please answer Yes or No.";;
		  esac
		done	
	else
		echo "Devices.db file not found. Copying updated devices.db file to /etc/habridge/data"
		#Copy updated devices.db file
		sudo cp device.db /etc/habridge/data
		echo "Updated devices.db copied to /etc/habridge/data"
		#Stop the HA Bridge service
		sudo systemctl stop HABridge.service
		#Reload Daemon to ensure latest changes are used by the service
		sudo systemctl daemon-reload
		#Start the HA Bridge service to load the modified file
		sudo systemctl start HABridge.service
		echo "Service restarted after reloading."
	fi

	break;;
	
	#If user is not ready to proceed with RF Setup
	[Nn]* ) echo "You can run RF433Setup.sh to set up outlets and manually add to HA Bridge."
	echo "User skipped the RF Setup"; 
	sleep 2;
	break;;
	
	* ) echo "Please answer Yes or No.";;
esac
done
	
echo "HA Bridge script complete."
