#!/bin/bash

# Config parameter Load
MQTTHOST=$(grep "MQTTHOST" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
TOPIC=$(grep "TOPIC" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
MQTTUSER=$(grep "MQTTUSER" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
MQTTPASWD=$(grep "MQTTPASWD" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
TELEPERIOD=$(grep "TELEPERIOD" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
id_prefix=$(grep "id_prefix" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
MAXSIZE=$(grep "MAXSIZE" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
CELL_MIN_VOLT=$(grep "CELL_MIN_VOLT" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')
CELL_MAX_VOLT=$(grep "CELL_MAX_VOLT" /root/share/SEPLOS_MQTT/config.ini | awk -F "=" '{print $2}')

# The function....

checkcellsvoltage()
{
         STATUS=0
         counter=1
         for CELLVOLTAGE in "$CELL1" "$CELL2" "$CELL3" "$CELL4" "$CELL5" "$CELL6" "$CELL7" "$CELL8" "$CELL9" "$CELL10" "$CELL11" "$CELL12" "$CELL13" "$CELL14" "$CELL15" "$CELL16"; do
                if [ "$CELLVOLTAGE" -lt $CELL_MIN_VOLT ] || [ "$CELLVOLTAGE" -gt $CELL_MAX_VOLT ]; then
                        echo "$(date) - Error: The value $CELLVOLTAGE for cell "$counter" is not between "$CELL_MIN_VOLT" and "$CELL_MAX_VOLT"" >> $LOGNAME
                        STATUS=1
                        break
                fi
                ((counter++))
        done
        return $STATUS
}

# The main script....
LOGNAME=/root/share/SEPLOS_MQTT/BMS_error.log
NOUPFILE=/root/share/SEPLOS_MQTT/nohup.out
#cd ~/SEPLOS_MQTT/
if [ ! -f "$LOGNAME" ]; then
touch "$LOGNAME"
fi

if [ ! -f "$NOUPFILE" ]; then
touch "$NOUPFILE"
fi

for (( ; ; ))
do
  LOGNAME_SIZE=$(ls -l "$LOGNAME" | awk '{print $5}')
  if [ $LOGNAME_SIZE -ge $MAXSIZE ]; then
    mv "$LOGNAME" "$LOGNAME".old
  fi

  NOUPFILE_SIZE=$(ls -l "$NOUPFILE" | awk '{print $5}')
  if [ $NOUPFILE_SIZE -ge $MAXSIZE ]; then
    cp "$NOUPFILE" "$NOUPFILE".old
    cat /dev/null > "$NOUPFILE"
  fi

   QUERY=$(/root/share/SEPLOS_MQTT/query_seplos_ha.sh 4201)

# Find lowest and high value
               onlycells=$(echo $QUERY|awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16}')

#echo ${onlycells[@]}
               lowcell=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort| sed -n 1p)
               highcell=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort| sed -n 16p)

# calulate difference
                DIFF=$(($highcell - $lowcell))

# find the number of the lowest and highest cell
lowcellnumb=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' |awk '{print $0, FNR}'| sort|sed -n 1p|awk '{print $2}')
highcellnumb=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' |awk '{print $0, FNR}'| sort|sed -n 16p|awk '{print $2}')

# Working on the bad data from the query script and skip send it to Mqtt server
VAR="$(echo $QUERY|awk '{print $27}')"
CELL1=$(echo $QUERY|awk '{print $1}')
CELL2=$(echo $QUERY|awk '{print $2}')
CELL3=$(echo $QUERY|awk '{print $3}')
CELL4=$(echo $QUERY|awk '{print $4}')
CELL5=$(echo $QUERY|awk '{print $5}')
CELL6=$(echo $QUERY|awk '{print $6}')
CELL7=$(echo $QUERY|awk '{print $7}')
CELL8=$(echo $QUERY|awk '{print $8}')
CELL9=$(echo $QUERY|awk '{print $9}')
CELL10=$(echo $QUERY|awk '{print $10}')
CELL11=$(echo $QUERY|awk '{print $11}')
CELL12=$(echo $QUERY|awk '{print $12}')
CELL13=$(echo $QUERY|awk '{print $13}')
CELL14=$(echo $QUERY|awk '{print $14}')
CELL15=$(echo $QUERY|awk '{print $15}')
CELL16=$(echo $QUERY|awk '{print $16}')

        if [[ "$onlycells" =~ "rror" ]]; then
                echo "$(date) - Possible bad read data from BMS - Error 1" >> $LOGNAME
#               echo "$(date) - Possible bad read data from BMS - Error 1"
        elif [[ "$onlycells" =~ "Failed" ]]; then
                echo "$(date) - Possible bad read data from BMS - Error 2" >> $LOGNAME
#               echo "$(date) - Possible bad read data from BMS - Error 2"
        elif (( $(echo "$VAR"'>'100 |bc -l) )); then
                echo "$(date) - Possible bad read data from BMS - Error 3" >> $LOGNAME
#               echo "$(date) - Possible bad read data from BMS - Error 3"
        elif (( $(echo "$VAR"'<'1 |bc -l) )); then
                echo "$(date) - Possible bad read data from BMS - Error 4" >> $LOGNAME
#               echo "$(date) - Possible bad read data from BMS - Error 4"
        elif [[ "$onlycells" =~ "~" ]]; then
                echo "$(date) - Possible bad read data from BMS - Error 5" >> $LOGNAME
#               echo "$(date) - Possible bad read data from BMS - Error 5"
        elif [ "${VAR+x}" = x ] && [ -z "$VAR" ]; then
                echo "$(date) - Possible bad read data from BMS - Error 6" >> $LOGNAME
#               echo "$(date) - Possible bad read data from BMS - Error 6"
        else

        checkcellsvoltage
                if [ $? = 0 ]; then

# prepare MQTT argument
mqtt_argument=$(printf "{\
\"lowest_cell\":\"Cell $lowcellnumb - $lowcell mV\",\
\"lowest_cell_v\":\"$lowcell\",\
\"lowest_cell_n\":\"$lowcellnumb\",\
\"highest_cell\":\"Cell $highcellnumb - $highcell mV\",\
\"highest_cell_v\":\"$highcell\",\
\"highest_cell_n\":\"$highcellnumb\",\
\"difference\":\"$DIFF\",\
\"cell01\":\"$CELL1\",\
\"cell02\":\"$CELL2\",\
\"cell03\":\"$CELL3\",\
\"cell04\":\"$CELL4\",\
\"cell05\":\"$CELL5\",\
\"cell06\":\"$CELL6\",\
\"cell07\":\"$CELL7\",\
\"cell08\":\"$CELL8\",\
\"cell09\":\"$CELL9\",\
\"cell10\":\"$CELL10\",\
\"cell11\":\"$CELL11\",\
\"cell12\":\"$CELL12\",\
\"cell13\":\"$CELL13\",\
\"cell14\":\"$CELL14\",\
\"cell15\":\"$CELL15\",\
\"cell16\":\"$CELL16\",\
\"cell_temp1\":\"$(echo $QUERY|awk '{print $17}')\",\
\"cell_temp2\":\"$(echo $QUERY|awk '{print $18}')\",\
\"cell_temp3\":\"$(echo $QUERY|awk '{print $19}')\",\
\"cell_temp4\":\"$(echo $QUERY|awk '{print $20}')\",\
\"env_temp\":\"$(echo $QUERY|awk '{print $21}')\",\
\"power_temp\":\"$(echo $QUERY|awk '{print $22}')\",\
\"charge_discharge\":\"$(echo $QUERY|awk '{print $23}')\",\
\"total_voltage\":\"$(echo $QUERY|awk '{print $24}')\",\
\"residual_capacity\":\"$(echo $QUERY|awk '{print $25}')\",\
\"soc\":\"$(echo $QUERY|awk '{print $27}')\",\
\"cycles\":\"$(echo $QUERY|awk '{print $29}')\",\
\"soh\":\"$(echo $QUERY|awk '{print $30}')\",\
\"port_voltage\":\"$(echo $QUERY|awk '{print $31}')\"\
}")

# send MQTT message with all parameters
        mosquitto_pub -h $MQTTHOST -u $MQTTUSER -P $MQTTPASWD -t "homeassistant/sensor/"$TOPIC"_"$id_prefix"" -m "$mqtt_argument"
#       echo "mqtt sent"

                fi
        fi
        sleep $TELEPERIOD
done
