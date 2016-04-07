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
    }
  }

  rule get_temperature {
    select when esproto new_temperature
    pre {
      sensor_data = event:attr("genericSensor")
		     .defaultsTo({})
		     .klog("Sensor Data: ")
		     ;
      sensor_specs = event:attr("specificSensor")
		       .defaultsTo({}) 
		       ;
      temperature = (sensor_data{["data","temperatureF"]}).klog("Temperature: ");
      updated_temperature = ent:temperature.defaultsTo([]).append(temperature);
    }
    always {
      set ent:temperature updated_temperature
    }
  }


}