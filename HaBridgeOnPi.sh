#!bin/bash
userName=$(whoami)

#In case you want OpenJDK 11
wget https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt.deb

#In case you want to use Oracle JDK, Download the JDK 11 from 
#Unzip the JDK 

#Create the HABridge Directory
sudo mkdir /etc/habridge
sudo chown -R userName:userName /etc/habridge
cd /etc/habridge

#Fetch the HA Bridge jar
sudo wget https://github.com/bwssytems/ha-bridge/releases/download/v5.3.0/ha-bridge-5.3.0-java11.jar

#Update things
sudo apt-get update


#Run HA Bridge via command prompt
#sudo java -jar -Dserver.port=8080 ha-bridge-3.5.1.jar

#Provide Service Name
echo "Enter Service Name:"
read serviceName

echo "Enter Service Description:"
read serviceDescription

#Create service in system with provided name
sudo cat <<EOF >/etc/systemd/system/serviceName.service

Description=serviceDescription

Wants=network.target
After=syslog.target network-online.target

[Service]
Type=simple
ExecStart=YOUR_COMMAND_HERE
Restart=on-failure
RestartSec=10
KillMode=process

[Install]
WantedBy=multi-user.target
EOF

#Restart daemon
sudo systemctl daemon-reload

#Enable the newly created service
sudo systemctl enable serviceName

#Start the service
sudo systemctl start serviceName

#Check the status of service
systemctl status serviceName