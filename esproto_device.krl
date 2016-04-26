ruleset esproto_device {
  meta {

    name "esproto_device"
    author "PJW"
    description "General rules for ESProto system devices"

    use module b507199x5 alias wrangler
    
    logging on
    
    sharing on
    provides thresholds
  }

  global {

    // public
    thresholds = function(threshold_type) {
      threshold_type.isnull() => ent:thresholds
                               | ent:thresholds{threshold_type}
    }

    //private
    event_map = {
      "new_temperature_reading" : "temperature",
      "new_humidity_reading" : "humidity",
      "new_pressure_reading" : "pressure"
    };

    collectionSubscriptions = function () {
        raw_subs = wrangler:subscriptions().pick("$..subscribed[0][0]", true).klog(">>> All Channels >>> "); 
	subs = raw_subs.filter(function(k,v){v{"namespace"} eq "esproto-meta" && v{"relationship"} eq "Device"});
	subs
      };
  }


  // rule to save thresholds
  rule save_threshold {
    select when esproto new_threshold
    pre {
      threshold_type = event:attr("threshold_type");
      threshold_value = {"limits": {"upper": event:attr("upper_limit"),
                                    "lower": event:attr("lower_limit")
				   }};
    }
    if(not threshold_type.isnull()) then noop();
    fired {
      log "Setting threshold value for #{threshold_type}";
      set ent:thresholds{threshold_type} threshold_value;
    }
  }

  rule check_threshold {
    select when esproto new_temperature_reading
             or esproto new_humidity_reading
             or esproto new_pressure_reading
    pre {
      threshold_type = event_map{event:type()};
      thresholds = thresholds(threshold_type);
      reading = event:attr("readings").klog("Reading from #{threshold_type}: ");
      lower_threshold = thresholds{"lower"};
      upper_threshold = thresholds{"upper"};
      under = reading < lower_threshold;
      over = upper_threshold < reading;
      msg = under => "#{threshold_type} is under threshold of #{lower_threshold}"
          | over  => "#{threshold_type} is over threshold of #{upper_threshold}"
	  |          "";
    }
    if(  under || over ) then noop();
    fired {
      raise esproto event "threshold_violation" attributes
        {"reading": reading,
	 "threshold": under => lower_threshold | upper_threshold,
	 "message": "threshold violation: #{msg}"
	}

    }
  }


  // meant to generally route events to owner. Extend eventex to choose what gets routed
  rule route_to_owner {
    select when esproto threshold_violation
             or esproto battery_level_low
    foreach collectionSubscriptions() setting (subs)
      pre {
	eci = subs{"event_channel"};
      }
      {
	send_directive("Routing to collection")
	  with subscription = subs{"subscription_name"} 
	   and attrs = event:attrs();
	event:send({"cid": eci}, "esproto", event:type())
	  with attrs = event:attrs();
      }
  }


  rule auto_approve_pending_subscriptions {
    select when wrangler inbound_pending_subscription_added 
           //name_space re/esproto-meta/gi
    pre{
      attributes = event:attrs().klog("subcription attributes :");
      subscriptions = wrangler:subscriptions()
                        .pick("$.subscriptions")
                        .klog(">>> current subscriptions >>>>")
			;
      declared_relationship = "device_collection";
      relationship = event:attr("relationship").klog(">>> subscription relationship >>>>");
    }
	
    if ( not relationship like declared_relationship	
      || subscriptions.length() == 0
       ) then // only auto approve the first subscription request
    {
       noop();
    }

    fired {
       log ">>> auto approving subscription: #{relationship}";
       raise wrangler event 'pending_subscription_approval'
          attributes attributes;        
    }
  }


}