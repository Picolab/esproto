ruleset esproto_router {
  meta {
    name "esproto_router"
    author "PJW"
    description "Event Router for ESProto system"
    
    logging on
    
    sharing on
    provides lastHeartbeat
  }

  global {

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


    lastHeartbeat = function() {
      ent:lastHeartbeat.klog("Return value ")
    }

    lastHumidity = function() {
      ent:lastHumidity.klog("return value ")
    }
    
  }

  rule receive_heartbeat {
    select when wovynEmitter thingHeartbeat
    foreach sensorData(["data"]) setting (sensor_type, sensor_readings)
      pre {
        sensor_data = sensorData();
	event_name = "new_" + sensor_type + "_reading".klog("Event ");

       }
       always {
       	 set ent:lastHeartbeat sensor_data;
	 raise esproto event sensor_name
	   with readings = sensor_readings
       }
  }

  rule catch_humidity {
    select when esproto new_humidity_reading
    pre {
      humidityData = event:attr("readings");
    }
    always {
      set ent:lastHumidity humidityData;
    }
  }

}