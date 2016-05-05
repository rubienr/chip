## Description 

This script monitors the battery voltage, battery charge current and a GPIO pin. 
+ If battery is low and not charging, or 
+ the pin is pulled down (GND) it initiates a shutdown.

## Installation

1. clone repository

        cd
        git clone https://github.com/rubienr/chip.git

2. start it from **/etc/rc.local**

        #!/bin/sh -e
        #
        # rc.local
        #
        # This script is executed at the end of each multiuser runlevel.
        # Make sure that the script will "exit 0" on success or any other
        # value on error.
        #
        # In order to enable or disable this script just change the execution
        # bits.
        #
        # By default this script does nothing.
        
        # add this line:
        /bin/bash /home/chip/chip/chip-off.sh
        
        exit 0

## Adjustment
The battery low voltage and current levels are adjustable using:

        # SHUTDOWN_MIN_BATTERY_VOLTAGE ... [mV]
        SHUTDOWN_MIN_BATTERY_VOLTAGE=2100.0
        # SHUTDOWN_MIN_BATTERY_VOLTAGE ... [mA]
        SHUTDOWN_MIN_BATTERY_CURRENT=20.0

The shutdown GPIO pin is adjustable using:

        # see http://docs.getchip.com/#how-you-see-gpio
        POWER_BUTTON_GPIO_NUMBER="414"
        POWER_BUTTON_GPIO="/sys/class/gpio/gpio$POWER_BUTTON_GPIO_NUMBER"
