# PC-LED-Color-Control
Changes LED strip colors based on GPU Temp.

Color starts out at Blue (when at Min GPU Fan speed) and fades to Red (when at Max GPU Fan speed)

How it works: 
A program (in powershell) accesses GPU Fan speed values from OpenHardwareMonitor[1] . 
The value is translated into a color scale ( Blue to Red) and sent to a Teensy Microcontroller[2] via serial (USB). 
The microcontroller sets the color of the LEDs.

[1] http://openhardwaremonitor.org/
[2] https://www.pjrc.com/teensy/

1. Upload C++ code to Teensy/Arduino. 
2. Edit Powershell script to use the correct COM port that the Teensy/Arduino is using. (By default it is set $COM = 'COM5' ) 
3. Run OpenHardwareMonitor (http://openhardwaremonitor.org/). This creates a WMI object that we need to get sensor information.
4. Run the Powershell script as Administrator. 

Requires: FastLED Library for the Teensy/Arduino https://github.com/FastLED/FastLED

Change $VerbosePreference = 'SilentlyContinue' to $VerbosePreference = 'Continue' for values to print to console. 

DEMO: https://www.youtube.com/watch?v=0GmOBLFoybo
