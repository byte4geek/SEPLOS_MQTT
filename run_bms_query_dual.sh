#!/bin/bash
# insert the mqtt infos below
# mqtt host name
MQTTHOST=192.168.1.2
# name inserted into topic
TOPIC=seplos
# mqtt user name
MQTTUSER=your_mqtt_user
# mqtt password
MQTTPASWD=your_mqtt_password
# time to read and update datas vs mqtt server and Home Assistant
TELEPERIOD=10
# is a prefix inserted into topic, chage it if you need
id_prefix=364715398511
# Max size of the BMS_error.log and nohup.out
MAXSIZE=2000000
# Log file name
LOGNAME=~/SEPLOS_MQTT/BMS_error.log
# nohup file name for standard and error output
NOUPFILE=~/SEPLOS_MQTT/nohup.out

# The script....

for (( ; ; ))
do
  LOGNAME_SIZE=$(ls -l $LOGNAME | awk '{print $5}')
  if [ $LOGNAME_SIZE -ge $MAXSIZE ]; then
    mv $LOGNAME $LOGNAME.old
  fi
  
  NOUPFILE_SIZE=$(ls -l $NOUPFILE | awk '{print $5}')
  if [ $NOUPFILE_SIZE -ge $MAXSIZE ]; then
    cp $NOUPFILE $NOUPFILE.old
    cat /dev/null > $NOUPFILE
  fi

   QUERY=$(~/SEPLOS_MQTT/query_seplos_ha.sh 4201)
   QUERY01=$(~/SEPLOS_MQTT/query_seplos_ha01.sh 4201)
   
# Find lowest and high value address 00
               onlycells=$(echo $QUERY|awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16}')

# Find lowest and high value address 01
               onlycells01=$(echo $QUERY01|awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16}')
			   
#echo ${onlycells[@]}
               lowcell=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort| sed -n 1p)
               highcell=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort| sed -n 16p)
 
               lowcell01=$(echo ${onlycells01[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort| sed -n 1p)
               highcell01=$(echo ${onlycells01[@]} | awk 'BEGIN{RS=" ";} {print $1}' | sort| sed -n 16p) 
# calulate difference address 00
               DIFF=`bc -l <<< $highcell-$lowcell`
# calulate difference address 01
               DIFF01=`bc -l <<< $highcell01-$lowcell01`
			   
# find the number of the lowest and highest cell address 00
lowcellnumb=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' |nawk '{print $0, FNR}'| sort|sed -n 1p|awk '{print $2}')
highcellnumb=$(echo ${onlycells[@]} | awk 'BEGIN{RS=" ";} {print $1}' |nawk '{print $0, FNR}'| sort|sed -n 16p|awk '{print $2}')

# find the number of the lowest and highest cell address 01
lowcellnumb01=$(echo ${onlycells01[@]} | awk 'BEGIN{RS=" ";} {print $1}' |nawk '{print $0, FNR}'| sort|sed -n 1p|awk '{print $2}')
highcellnumb01=$(echo ${onlycells01[@]} | awk 'BEGIN{RS=" ";} {print $1}' |nawk '{print $0, FNR}'| sort|sed -n 16p|awk '{print $2}')


# Working on the bad data from the query script and skip send it to Mqtt server
VAR="$(echo $QUERY|awk '{print $27}')"
#VAR=${VAR/./,}
#echo "$(date) - $VAR - $onlycells" >> $LOGNAME
#    if [[ "$VAR" -gt 101 && "$VAR" -lt 0 ]]; then
    if [[ "$onlycells" =~ "rror" ]]; then
      echo "$(date) - Possible bad read data from BMS - Error 1" >> $LOGNAME
#      echo "$(date) - Possible bad read data from BMS - Error 1"
    else
    
      if [[ "$onlycells" =~ "Failed" ]]; then
        echo "$(date) - Possible bad read data from BMS - Error 2" >> $LOGNAME
#        echo "$(date) - Possible bad read data from BMS - Error 2"
      else
      
        if (( $(echo "$VAR"'>'100 |bc -l) )); then
          echo "$(date) - Possible bad read data from BMS - Error 3" >> $LOGNAME
#          echo "$(date) - Possible bad read data from BMS - Error 3"
        else
        
          if (( $(echo "$VAR"'<'1 |bc -l) )); then
            echo "$(date) - Possible bad read data from BMS - Error 4" >> $LOGNAME
#            echo "$(date) - Possible bad read data from BMS - Error 4"
          else
          
            if [[ "$onlycells" =~ "~" ]]; then
              echo "$(date) - Possible bad read data from BMS - Error 5" >> $LOGNAME
#              echo "$(date) - Possible bad read data from BMS - Error 5"
            else
            
              if [ "${VAR+x}" = x ] && [ -z "$VAR" ]; then
                echo "$(date) - Possible bad read data from BMS - Error 6" >> $LOGNAME
#                echo "$(date) - Possible bad read data from BMS - Error 6"
              else

# prepare MQTT argument for address 00
mqtt_argument=$(printf "{\
\"lowest_cell\":\"Cell $lowcellnumb - $lowcell mV\",\
\"lowest_cell_v\":\"$lowcell\",\
\"lowest_cell_n\":\"$lowcellnumb\",\
\"highest_cell\":\"Cell $highcellnumb - $highcell mV\",\
\"highest_cell_v\":\"$highcell\",\
\"highest_cell_n\":\"$highcellnumb\",\
\"difference\":\"$DIFF\",\
\"cell01\":\"$(echo $QUERY|awk '{print $1}')\",\
\"cell02\":\"$(echo $QUERY|awk '{print $2}')\",\
\"cell03\":\"$(echo $QUERY|awk '{print $3}')\",\
\"cell04\":\"$(echo $QUERY|awk '{print $4}')\",\
\"cell05\":\"$(echo $QUERY|awk '{print $5}')\",\
\"cell06\":\"$(echo $QUERY|awk '{print $6}')\",\
\"cell07\":\"$(echo $QUERY|awk '{print $7}')\",\
\"cell08\":\"$(echo $QUERY|awk '{print $8}')\",\
\"cell09\":\"$(echo $QUERY|awk '{print $9}')\",\
\"cell10\":\"$(echo $QUERY|awk '{print $10}')\",\
\"cell11\":\"$(echo $QUERY|awk '{print $11}')\",\
\"cell12\":\"$(echo $QUERY|awk '{print $12}')\",\
\"cell13\":\"$(echo $QUERY|awk '{print $13}')\",\
\"cell14\":\"$(echo $QUERY|awk '{print $14}')\",\
\"cell15\":\"$(echo $QUERY|awk '{print $15}')\",\
\"cell16\":\"$(echo $QUERY|awk '{print $16}')\",\
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

# prepare MQTT argument for address 01
mqtt_argument01=$(printf "{\
\"01_lowest_cell\":\"Cell $lowcellnumb01 - $lowcell01 mV\",\
\"01_lowest_cell_v\":\"$lowcell01\",\
\"01_lowest_cell_n\":\"$lowcellnumb01\",\
\"01_highest_cell\":\"Cell $highcellnumb01 - $highcell01 mV\",\
\"01_highest_cell_v\":\"$highcell01\",\
\"01_highest_cell_n\":\"$highcellnumb01\",\
\"01_difference\":\"$DIFF01\",\
\"01_cell01\":\"$(echo $QUERY01|awk '{print $1}')\",\
\"01_cell02\":\"$(echo $QUERY01|awk '{print $2}')\",\
\"01_cell03\":\"$(echo $QUERY01|awk '{print $3}')\",\
\"01_cell04\":\"$(echo $QUERY01|awk '{print $4}')\",\
\"01_cell05\":\"$(echo $QUERY01|awk '{print $5}')\",\
\"01_cell06\":\"$(echo $QUERY01|awk '{print $6}')\",\
\"01_cell07\":\"$(echo $QUERY01|awk '{print $7}')\",\
\"01_cell08\":\"$(echo $QUERY01|awk '{print $8}')\",\
\"01_cell09\":\"$(echo $QUERY01|awk '{print $9}')\",\
\"01_cell10\":\"$(echo $QUERY01|awk '{print $10}')\",\
\"01_cell11\":\"$(echo $QUERY01|awk '{print $11}')\",\
\"01_cell12\":\"$(echo $QUERY01|awk '{print $12}')\",\
\"01_cell13\":\"$(echo $QUERY01|awk '{print $13}')\",\
\"01_cell14\":\"$(echo $QUERY01|awk '{print $14}')\",\
\"01_cell15\":\"$(echo $QUERY01|awk '{print $15}')\",\
\"01_cell16\":\"$(echo $QUERY01|awk '{print $16}')\",\
\"01_cell_temp1\":\"$(echo $QUERY01|awk '{print $17}')\",\
\"01_cell_temp2\":\"$(echo $QUERY01|awk '{print $18}')\",\
\"01_cell_temp3\":\"$(echo $QUERY01|awk '{print $19}')\",\
\"01_cell_temp4\":\"$(echo $QUERY01|awk '{print $20}')\",\
\"01_env_temp\":\"$(echo $QUERY01|awk '{print $21}')\",\
\"01_power_temp\":\"$(echo $QUERY01|awk '{print $22}')\",\
\"01_charge_discharge\":\"$(echo $QUERY01|awk '{print $23}')\",\
\"01_total_voltage\":\"$(echo $QUERY01|awk '{print $24}')\",\
\"01_residual_capacity\":\"$(echo $QUERY01|awk '{print $25}')\",\
\"01_soc\":\"$(echo $QUERY01|awk '{print $27}')\",\
\"01_cycles\":\"$(echo $QUERY01|awk '{print $29}')\",\
\"01_soh\":\"$(echo $QUERY01|awk '{print $30}')\",\
\"01_port_voltage\":\"$(echo $QUERY01|awk '{print $31}')\"\
}")
# send MQTT message with all parameters for address 00
        mosquitto_pub -h $MQTTHOST -u $MQTTUSER -P $MQTTPASWD -t "homeassistant/sensor/"$TOPIC"_"$id_prefix"" -m "$mqtt_argument"

# send MQTT message with all parameters for address 01
        mosquitto_pub -h $MQTTHOST -u $MQTTUSER -P $MQTTPASWD -t "homeassistant/sensor/"$TOPIC"_"$id_prefix"" -m "$mqtt_argument01"
            fi
          fi
        fi
      fi
    fi
  fi
  sleep $TELEPERIOD
done
