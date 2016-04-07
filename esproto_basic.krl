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
    temperatures = function(limit, offset) {
      sort_opt = {
        "path" : ["timestamp"],
	"reverse": true,
	"compare" : "datetime"
      };

      max_returned = 25;

      hard_offset = offset.isnull() 
                 || offset eq ""        => 0               // default
                  |                        offset;

      hard_limit = limit.isnull() 
                || limit eq ""          => 10              // default
                 | limit > max_returned => max_returned
		 |                         limit; 

      global_opt = {
        "index" : hard_offset,
	"limit" : hard_limit
      }; 

      sorted_temperature = this2that:transform(ent:temperatures, sort_opt, global_opt) || [];
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