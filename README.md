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

edit the script ```~/SEPLOS_MQTT/query_seplos_ha.sh``` and set the COM port that you use (Ex. DEV=/dev/ttyUSB0)

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

When the script run, it sends an MQTT message like this:

```
homeassistant/sensor/seplos_364715398511 {"lowest_cell":"Cell 8 - 3427 mV","highest_cell":"Cell 7 - 3435 mV","difference":"8","cell01":"3431","cell02":"3431","cell03":"3434","cell04":"3430","cell05":"3433","cell06":"3432","cell07":"3435","cell08":"3427","cell09":"3431","cell10":"3428","cell11":"3433","cell12":"3433","cell13":"3435","cell14":"3431","cell15":"3435","cell16":"3428","cell_temp1":"31.7","cell_temp2":"32.2","cell_temp3":"32.0","cell_temp4":"31.9","env_temp":"37.2","power_temp":"34.9","charge_discharge":"26.01","total_voltage":"54.90","residual_capacity":"271.24","soc":"96.8","cycles":"12","soh":"100.0","port_voltage":"54.93"}
```


Based on this message then create all MQTT sensors and the template sensors using the configuration.yaml file and add all sensors to the Home Assistant dashboard using the lovelace.yaml file
