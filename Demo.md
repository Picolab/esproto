
# Demo for ESProto

* Spimes 
	* tracking things through space and time
	* Bruce Sterling
  
* Using picos for collections of things
	* persistent compute object
	* online, event-based, 

* Advantages
	* things don't need smarts, or as much
	* things can be low power (not always on)
	* loosely coupled
	* Each device and each collection get own identity 
		* persistent data
		* custom programming
		* API
  
* Wovyn sensors
	* Wifi
	* ESP8266 
	* multiple configurations
	* this is a MSA (temperature, pressure, humidity)
	* POSTs to a customizable URL
  
* Wovyn and picos are a great combination
	* Picos provide an always on, online persona for the device
	* Picos can be used for collections of devices
	* Each pico can have a unique URL for the sensor to POST to
  
* Building a spime platform
	* Not just for Wovyn, generalizable to any devices
	* Based on ideas from Fuse Connected Car platform
	* pico prototypes
  
* Device rules
	* router - changes transducer data POST to meaningful events
		* `new_temperature_reading`, `new_pressure_reading`, etc.
	* check_battery
		* `battery_level_low`
	* device - check thresholds for violations
	* device - manage thresholds
	* device - route violations to all collections
  
* Collection rules
	* log violations
	
* Advantages
	* Scales
	* Easy to set up
	* Collections can have custom behavior
  

	
  

  

