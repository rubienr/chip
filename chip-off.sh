#!/bin/bash/
#
# @author Raoul R., 2016
#
# This script watches (polls) the battery state and the gpio $POWER_BUTTON_GPIO pin level. 
# If pin is pulled to GND the script initiates a shut down.
#

# SHUTDOWN_MIN_BATTERY_VOLTAGE ... [mV]
SHUTDOWN_MIN_BATTERY_VOLTAGE=2100.0
# SHUTDOWN_MIN_BATTERY_VOLTAGE ... [mA]
SHUTDOWN_MIN_BATTERY_CURRENT=20.0

# see http://docs.getchip.com/#how-you-see-gpio
POWER_BUTTON_GPIO_NUMBER="414"
POWER_BUTTON_GPIO="/sys/class/gpio/gpio$POWER_BUTTON_GPIO_NUMBER"

# LOG_LEVEL ... DEBUT | INFO
LOG_LEVEL="DEBUG"

TRUE=1
FALSE=0


# $1 ... message
# debug log
function log() {
  if [ "$LOG_LEVEL" = "DEBUG" ] ; then
    local message=$1
    logger -t "PME" "$message"
  fi
}

# $1 ... message
# more verbose information logging
function logInfo() {
  local message=$1
  logger -t "PME" "$message"
}

function setupGpioInputButton()
{
  if [ ! -e ${POWER_BUTTON_GPIO} ] ; then
    echo "$POWER_BUTTON_GPIO_NUMBER" > /sys/class/gpio/export
  fi
  echo "in" > ${POWER_BUTTON_GPIO}/direction > /dev/null 2>&1
  echo "0" > ${POWER_BUTTON_GPIO}/active_low > /dev/null 2>&1
}

function cleanupGpioInputButton() {
  echo "$POWER_BUTTON_GPIO_NUMBER" > /sys/class/gpio/unexport
}

# $1 ... message
function shutdownCommand() {
  logInfo "$1"
  cleanupGpioInputButton
  setLed 1
  shutdown -h 0 &
  exit 0
}

# @return ... 0,1 as return value
function isBatteryAvailable() {
  local flags=$(i2cget -f -y 0 0x34 0x01)
  return $(((( $flags&0x20 ) >>5 ) == $TRUE ))
}

# @return ... voltage as string
function getBatteryVoltage() {
  local voltageHighByte=$(i2cget -y -f 0 0x34 0x78)
  local voltageLowByte=$(i2cget -y -f 0 0x34 0x79)
  local rawVoltage=$(($(($voltageHighByte << 4)) | $(($(($voltageLowByte & 0x0F ))))))
  echo "($rawVoltage * 1.1)" | bc
}

# @return ... charging current as string
function getChargeCurrent() {
  local currentHighByte=$(i2cget -f -y 0 0x34 0x7A)
  local currentLowByte=$(i2cget -f -y 0 0x34 0x7B)
  local rawCurrent=$(($(($currentHighByte << 4)) | $(($(($currentLowByte & 0x0F))))))
  echo "($rawCurrent * 0.5)" | bc
}

# shuts the system down if too less voltage
function verifyBatteryVoltage() {
  isBatteryAvailable
  if [ "$?" -eq "1" ] ; then
      local voltage=$(getBatteryVoltage)
      chargeCurrent=$(getChargeCurrent)
      log "battery charge current [${chargeCurrent}mV] min current [${SHUTDOWN_MIN_BATTERY_CURRENT}mV]"
      if [ $(echo "$voltage <= $SHUTDOWN_MIN_BATTERY_VOLTAGE" | bc) -eq "1" ] ; then
          log "critical battery voltage [${voltage}mV] min voltage [${SHUTDOWN_MIN_BATTERY_VOLTAGE}mV]"
          if [ $(echo "$chargeCurrent <= $SHUTDOWN_MIN_BATTERY_CURRENT" | bc) -eq "1" ] ; then
              shutdownCommand "shutting down due to low voltage/charge current"
          fi
          return
      fi
      log "battery voltage [${voltage}mV] min voltage [${SHUTDOWN_MIN_BATTERY_VOLTAGE}mv]"
  fi
}

# $1 ... led state (0,1)
function setLed() {
  if [ "$1" -eq "1" -o "$1" -eq "0" ] ; then
    /usr/sbin/i2cset -f -y 0 0x34 0x93 0x$1
  fi
}

# @return ... true if button pressed else false as return value
function isButtonPressed() {
  local value=$(cat ${POWER_BUTTON_GPIO}/value)
  

  
  if [ "$value" -eq "0" ] ; then
    shutdownCommand "shutdown on button pressed"
  fi
}

function verifyButton() {
  isButtonPressed
  if [ "$?" -eq "1" ] ; then
    shutdownCommand "shutdown on power button request"
  fi
}

function main() {
  setupGpioInputButton
  
  while true ; do
    setLed 1
    verifyBatteryVoltage
    verifyButton
    setLed 0
    sleep 3
  done
}

# start monitoring in subshell and nonblocking
$(main)&
exit 0
