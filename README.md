# Seplos MQTT
Read data From Seplos BMS and send them to the Home Assistant

This is a bash script that read data from Seplos BMS via RS485 port and send the data to the Home Assistan via MQTT.

## Hardware requirements:
1. Raspberry (i use an RPI4)
2. USB to RS485 adapter
3. [Seplos BMS](https://www.alibaba.com/product-detail/Seplos-50A-100A-150A-200A-24V_1600246972725.html?spm=a2700.galleryofferlist.normal_offer.d_title.41f63a936kcnil)
4. Home assitant with configured MQTT broker

## Installation and configuration

Prepare Raspberry with Raspberry PI OS
perform the apt-get update and the apt-get upgrade

move to the your user home and use git clone to download this script

```
git clone https://github.com/byte4geek/SEPLOS_MQTT.git

chmod 700 ~/SEPLOS_MQTT/query_seplos_ha.sh ~/SEPLOS_MQTT/run_bms_query.sh
```

edit the script ```~/SEPLOS_MQTT/query_seplos_ha.sh``` and set the COM port that you use (Ex. DEV=/dev/ttyUSB0)

edit the file config.ini ```~/SEPLOS_MQTT/config.ini``` and set the below parameters with your MQTT server information:

```
# insert the mqtt info below
# mqtt host name
MQTTHOST=192.168.1.2
# name inserted into topic
TOPIC=seplos
# mqtt user name
MQTTUSER=mqttuser
# mqtt password
MQTTPASWD=mqttpassword
# time to read and update datas vs mqtt server and Home Assistant
TELEPERIOD=10
# is a prefix inserted into topic, chage it if you need
id_prefix=364715398511
# Max size of the BMS_error.log and nohup.out
MAXSIZE=2000000
# Minmum voltage in mV permitted for Cell value for correct output
CELL_MIN_VOLT=2500
# Maximum voltage in mV permitted for Cell value for correct output
CELL_MAX_VOLT=3800
```

then install the following pkg:

```
sudo apt-get install jq bc mosquitto-clients
```

edit the crontab to run the script at the boot

```crontab -e``` and add the line below:
```
@reboot cd ~/SEPLOS_MQTT/| nohup /home/pi/SEPLOS_MQTT/run_bms_query.sh &
```

## Manual execution
simply run 
```~/SEPLOS_MQTT/run_bms_query.sh```
or
```nohup ~/SEPLOS_MQTT/run_bms_query.sh &```

To test if the communication is working try to run
```~/SEPLOS_MQTT/query_seplos_ha.sh 4201```

you can see the output like this:
```
3334
3334
3334
3335
3334
3335
3334
3335
3335
3336
3335
3335
3335
3335
3335
3334
31.7
32.2
32.0
31.8
36.5
33.7
0
53.35
273.97
280.00
97.8
280.00
12
100.0
54.45
```

When the script run, it sends an MQTT message like this:

```
homeassistant/sensor/seplos_364715398511 {"lowest_cell":"Cell 8 - 3427 mV","highest_cell":"Cell 7 - 3435 mV","difference":"8","cell01":"3431","cell02":"3431","cell03":"3434","cell04":"3430","cell05":"3433","cell06":"3432","cell07":"3435","cell08":"3427","cell09":"3431","cell10":"3428","cell11":"3433","cell12":"3433","cell13":"3435","cell14":"3431","cell15":"3435","cell16":"3428","cell_temp1":"31.7","cell_temp2":"32.2","cell_temp3":"32.0","cell_temp4":"31.9","env_temp":"37.2","power_temp":"34.9","charge_discharge":"26.01","total_voltage":"54.90","residual_capacity":"271.24","soc":"96.8","cycles":"12","soh":"100.0","port_voltage":"54.93"}
```

## Installation and configuration for Home Assistant only

This section describe the installation and configuration for people that have the rs485 directly connecte to the Home Assistant Raspberry.
Require Home Assistant Operating System

install the docker "SSH & Web Terminal" https://github.com/hassio-addons/addon-ssh and configure it

connect to the HA with ssh port 22

```
cd /share

git clone https://github.com/byte4geek/SEPLOS_MQTT.git

chmod 700 ./SEPLOS_MQTT/query_seplos_ha.sh ./SEPLOS_MQTT/run_bms_query_ha.sh

ssh-copy-id root@<YOUR HA IP>     ---> and choose yes
```

edit the script ```./SEPLOS_MQTT/query_seplos_ha.sh``` and set the COM port that you use (Ex. DEV=/dev/ttyUSB0)

edit the file config.ini ```./SEPLOS_MQTT/config.ini``` and set the below parameters with your MQTT server information:

```
# insert the mqtt info below
# mqtt host name
MQTTHOST=192.168.1.2
# name inserted into topic
TOPIC=seplos
# mqtt user name
MQTTUSER=mqttuser
# mqtt password
MQTTPASWD=mqttpassword
# time to read and update datas vs mqtt server and Home Assistant, not used for run_bms_query_ha.sh
TELEPERIOD=10
# is a prefix inserted into topic, chage it if you need
id_prefix=364715398511
# Max size of the BMS_error.log and nohup.out
MAXSIZE=2000000
# Minmum voltage in mV permitted for Cell value for correct output
CELL_MIN_VOLT=2500
# Maximum voltage in mV permitted for Cell value for correct output
CELL_MAX_VOLT=3800
```

create a shell command in HA:
```
seplos_query: ssh -i /config/.ssh/id_rsa -o StrictHostKeyChecking=no root@<YOUR HA IP> "cd /share/SEPLOS_MQTT;nohup /share/SEPLOS_MQTT/run_bms_query_ha.sh &"
```

then create an automation to start the script at Home assistant boot
```
- id: seplos_startup_automation
  alias: Seplos Startup Automation
  trigger:
    platform: time_pattern
    seconds: "/10"
  action:
    - service: shell_command.seplos_query
```

## Configuring Home Assistant

Based on the MQTT message then create all MQTT sensors and the template sensors using the configuration.yaml file and add all sensors to the Home Assistant dashboard using the lovelace.yaml file

example:
![BMS dashboard](https://github.com/byte4geek/Seplos-BMS-vs-Home-Assistant/raw/main/bms_ha_panel.JPG)

# Donation
Buy me a coffee

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=VK4CSX9NVQAZU)
