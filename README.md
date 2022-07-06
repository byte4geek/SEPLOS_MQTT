# Seplos-BMS-vs-Home-Assistant
Read data From Seplos BMS and send them to the Home Assistant

This is a bash script that read data from Seplos BMS via RS485 port and send the data to the Home Assistan via MQTT.

Hardware requirement:
1. Raspberry (i use an RPI4)
2. USB to RS485 adapter

Installation:
Prepare Raspberry with Raspberry PI OS
perform the apt-get update and the apt-get upgrade

move to the your user home and use git clone to download this script

```git clone https://github.com/byte4geek/Seplos-BMS-vs-Home-Assistant.git```

edit the script ```~/SEPLOS_MQTT/query_seplos_ha.sh``` and set the COM port that you use (Ex. /dev/ttyUSB0)

edit the script ```~/SEPLOS_MQTT/run_bms_query.sh``` and set the below parameters with your MQTT server information:

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
```

then install the following pkg:

sudo apt-get install jq mosquitto-clients

edit the crontab to run the script at the boot

```crontab -e``` and add the line below:
```
@reboot nohup ~/SEPLOS_MQTT/run_bms_query.sh &
```
