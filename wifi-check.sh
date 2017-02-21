#!/bin/bash

connectivity_test() {

  # Set IP address to ping to Google
  local IP='8.8.8.8'

  # Set log files
  local clog_file='/tmp/connectivity_issues.log'
  local clog_error='/tmp/connectivity_error.log'
  local clog_info='/tmp/connectivity_info.txt'

  # Run the initial ping to kick off the while loop
  local response=$(ping -c1 ${IP} 2> $clog_error | grep packet | cut -d " " -f 7)

  # Initially set what WiFi is currently in use
  local wifi=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print $2}')
  echo ${wifi} > $clog_info

  # if $1 is "1", then don't reprint wifi name. This is used to prevent printing the wifi name being printed for each occurrence.
  if [[ $1 != "1" ]]
  then
	  echo "===== WiFi: ${wifi} =====" >> "${clog_file}"
  fi

  # Only do something if the response isn't 0.0%, since that means everything is good.
  while [[ ${response} == 0.0% ]]
  do
    sleep 1
    local response=$(ping -c1 ${IP} 2> $clog_error | grep packet | cut -d " " -f 7)
  done

  # If the wifi changed since the last time, print the new wifi name.
  local wificheck=$(/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print $2}')
  if [[ ${wificheck} != "$(cat ${clog_info})" ]]
  then
    echo -e "\n===== WiFi: ${wificheck} =====" >> "${clog_file}"
    echo "${wificheck}" >> "${clog_info}"
  fi

  # If the _error.log isn't empty, connection errors occured.
  if [[ -s ${clog_error} ]]
  then
    # Grab the error and prepend the date and send to the _issues.log file.
    local spec_error=$(cat ${clog_error})
    echo "$(date) - ${spec_error}" >> ${clog_file}

    # Remove the error file to prevent false positives.
    /bin/rm /tmp/connectivity_error.log
  else

    # If packet loss was obvserved and no errors from ping were reported, this is actual packet loss.
    echo "$(date) - packet loss" >> ${clog_file}
  fi

  connectivity_test 1
}
