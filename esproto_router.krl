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

    sensorData = function() {
      event:attr("genericSensor")
  	     .defaultsTo({})
	     .klog("Sensor Data: ")
	     
    };

    sensorSpecs = function() {
       event:attr("specificSensor")
		       .defaultsTo({})
		       .klog("Sensor specs: ")
    };


    lastHeartbeat = function() {
      ent:lastHeartbeat.klog("Return value ")
    }
    
  }

  rule receive_heartbeat {
    select when wovynEmitter thingHeartbeat
    pre {
      foo = event:attrs().klog("Seeing attributes: ");
      sensor_data = sensorData();
      sensor_specs = sensorSpecs();
    }
    always {
      set ent:lastHeartbeat sensor_data
    }
  }

}