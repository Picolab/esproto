ruleset esproto_basic {
  meta {
    name "esproto_basic"
    author "PJW"
    description "Hello World for ESProto system"
    
    logging on
    
    sharing on
    provides temperatures
  }

  global {
    temperatures = function() {
      ent:temperatures;
    };

    sensorData = function() {
      event:attr("genericSensor")
  	     .defaultsTo({})
	     .klog("Sensor Data: ")
	     
    };

  }

  rule get_temperature {
    select when esproto new_temperature
    pre {
      sensor_data = sensorData();
      sensor_specs = event:attr("specificSensor")
		       .defaultsTo({}) 
		       ;
      temperature = (sensor_data{["data","temperatureF"]}).klog("Temperature: ");
      temperature_rec = {"temperature": temperature,
      		      	 "timestamp": time:now()
		        };
      updated_temperature = ent:temperatures.defaultsTo([]).append(temperature_rec);
    }
    always {
      set ent:temperatures updated_temperature
    }
  }

}