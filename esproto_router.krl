ruleset esproto_router {
  meta {
    name "esproto_router"
    author "PJW"
    description "Event Router for ESProto system"
    
    logging on
    
    sharing on
    provides last
  }

  global {

    sensorData = function() {
      event:attr("genericSensor")
  	     .defaultsTo({})
	     .klog("Sensor Data: ")
	     
    };

    lastHeatbeat = function() {
      ent:lastHeatbeat
    }
    
  }

  rule receive_heartbeat {
    select when wovynEmitter thingHeartbeat
    pre {
      foo = event:attrs().klog("Seeing attributes: ");
      sensor_data = sensorData();
      sensor_specs = event:attr("specificSensor")
		       .defaultsTo({}) 
		       ;
    }
    always {
      set ent:lastHeartbeat sensor_data
    }
  }

}