# HABridgeOnPi

Set up HA Bridge (https://github.com/bwssytems/ha-bridge) for IOT and respective tinkering adventures.
Objective is to install HA Bridge and other utilities with minimum clicks.
The script calls another script that installs RFC 433 utilities so that we are able to control Eteckcity (or similar RF433) RF power outlet from HA Bridge (and eventually via Alexa).
There were issues with version of Java as well as version of HA Bridge. The combination that worked is part of this script.

## Getting Started

Connect to your Raspberry Pi via SSH (or directly using Terminal) and follow installation instructions.

### Prerequisites
<li>Basic computer/Raspberry Pi know how</li>
<li>Working Raspberry Pi</li>
<li>SSH access to Raspberry Pi</li>
<li>Access to Internet</li>

#### Optional Hardware
<li>RF Transmitter + Reciever (https://www.amazon.com/gp/product/B00M2CUALS)</li>
<li>RF Plugs + Remote (https://www.amazon.com/Etekcity-Household-Appliances-Unlimited-Connections/dp/B00DQELHBS)</li>

The script is mostly self contained and fetches necessary files from github repo.


If you want to scan and update RF Outlet codes along with HA Bridge installation, please ensure that you have connected the PINs correctly for RF433 transmitter as well as reciever module.

For Reciever: (5V | Empty | GPIO 27 | Ground)

For Transmitter: ( GPIO17 | 5V | Ground )

Note: For my RF plug set up, I used this one: https://www.amazon.com/gp/product/B00M2CUALS to control to contorl these: https://www.amazon.com/Etekcity-Household-Appliances-Unlimited-Connections/dp/B00DQELHBS

### Installing
For installation, run below commands from your Pi terminal (or SSH session) :

<code>wget https://raw.githubusercontent.com/piyushkumarjiit/HABridgeOnPi/master/HaBridgeOnPi.sh</code>

Update the permissions on the downloaded file using:

<code>chmod 755 HaBridgeOnPi.sh</code>

Now run the script:

<code>./HaBridgeOnPi.sh | tee HaBridgeOnPi.log</code>

The script:
<li>Downloads and install OpenJDK8</li>
<li>Downloads and install HA Bridge</li>
<li>Downloads and executes RF433Setup.sh</li> (checkout https://github.com/piyushkumarjiit/RFUtilScript for more details)
<li>Provides user way to record his RF remote codes <via RF433Setup.sh)</li>

Pi needs to be restarted before codes can be scanned as WiringPi used to access GPIO is also installed by this script. 
Codes recorded during script execution are then used to set  up HA Bridge config to control the outlets.

<b>For advacned installation options, refer to Custom Installation section. </b>

Once the script completes, you should see "HA Bridge script complete." at the end and system would restart. Once your Pi has restarted, run the script again to capture the RF codes.

## Testing
Once you have executed the script go to the IP of your Pi in a browser. If HA Bridge is working, you should see main page along with updated device config.

Log can be viewed with <code>tail -f /var/log/syslog</code>

## Post Installation
Take necessary steps to ensure security as HA Bridge by default is quite open. If Pi is only being used for running HA Bridge, then router firewall can be updated to stop internet access to this Pi. Read HA Bridge documentation for deploying necessary safety measures.

## Authors
**Piyush Kumar** - (https://github.com/piyushkumarjiit)

## License
This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments
Thanks to below URLs for providing me the necessary understanding and code to come up with this script.
<li>https:www.DuckDuckGo.com </li>
