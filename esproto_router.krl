ruleset esproto_router {
  meta {
    name "esproto_router"
    author "PJW"
    description "Event Router for ESProto system"
    
    logging on
    
    sharing on
    provides lastHeartbeat, lastHumidity, lastTemperature, lastPressure
  }

  global {

    // configuration
    healthy_battery_level = 20;

    // internal functions
    sensorData = function(path) {
     gtd =  event:attr("genericThing")
  	     .defaultsTo({})
	     .klog("Sensor Data: ");
     path.isnull() => gtd | gtd{path}
	     
    };

    sensorSpecs = function() {
       event:attr("specificSensor")
		       .defaultsTo({})
		       .klog("Sensor specs: ")
    };


    // API functions
    lastHeartbeat = function() {
      ent:lastHeartbeat.klog("Return value ")
    }

    lastHumidity = function() {
      ent:lastHumidity
    }
    
    lastTemperature = function() {
      ent:lastTemperature
    }
    
    lastPressure = function() {
      ent:lastPressure
    }
    
  }

  // mostly for debugging; see all data from last heartbeat
  rule receive_heartbeat {
    select when wovynEmitter thingHeartbeat
    pre {
      sensor_data = event:attrs();

    }
    always {
      set ent:lastHeartbeat sensor_data
    }
  }

  // check battery level
  rule check_battery {
    select when wovynEmitter thingHeartbeat 
    pre {
      sensor_data = sensorData();
      sensor_id = event:attr("emitterGUID");
      sensor_properties = event:attr("property");
    }
    if (sensor_data{"healthPercent"}) < healthy_battery_level then noop()
    fired {
      log "Battery is low";
      raise esproto event "battery_level_low"
        with id = sensor_id
	 and properties = sensor_properties
	 and timestamp = time:now();
    } else {
      log "Battery is fine";    
    }
  }

  // route all readings from the sensor array
  rule route_readings {
    select when wovynEmitter thingHeartbeat
    foreach sensorData(["data"]) setting (sensor_type, sensor_readings)
      pre {
	event_name = "new_" + sensor_type + "_reading".klog("Event ");

       }
       always {
	 raise esproto event event_name
	   with readings = sensor_readings
  	    and timestamp = time:now();
       }
  }

  // catch and store humidity
  rule catch_humidity {
    select when esproto new_humidity_reading
    pre {
      humidityData = event:attr("readings");
    }
    always {
      set ent:lastHumidity humidityData;
    }
  }

  // catch and store temperature
  rule catch_temperature {
    select when esproto new_temperature_reading
    pre {
      temperatureData = event:attr("readings");
    }
    always {
      set ent:lastTemperature temperatureData;
    }
  }

  // catch and store pressure
  rule catch_pressure {
    select when esproto new_pressure_reading
    pre {
      pressureData = event:attr("readings");
    }
    always {
      set ent:lastPressure pressureData;
    }
  }

}