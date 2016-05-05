ruleset esproto_collection {
  meta {

    name "esproto collection"
    author "PJW"
    description "General rules for ESProto system device collections"

    use module b16x10 alias fuse_keys

    use module b507199x5 alias wrangler
    use module a16x129 version "dev" alias sendgrid with
            api_user = keys:sendgrid("api_user") and 
            api_key = keys:sendgrid("api_key") and
            from = "esproto-notifications@joinfuse.com" and
	    fromname = "Fuse-NoReply"

    
    logging on
    
    sharing on
    provides violations
    
  }

  global {
    violations = function() {
      ent:violation_log
    }


    accessor_factory = function(entvar, options) {

      opts = options.defaultsTo({});

      path = opts{"path"}.defaultsTo("[timestamp]").klog("Path: ");
      reverse = opts{"reverse"}.defaultsTo(true);
      compare = ops{"compare"}.defaultsTo("dateTime");
      limit = opts{"limit"}.defaultsTo(10);

    
      function(id,limit, offset) {

	all_values = function(limit, offset) {
	  sort_opt = {
	    "path" : path,
	    "reverse": true,
	    "compare" : compare
	  };

	  max_returned = 25;

	  hard_offset = offset.isnull() 
		     || offset eq ""        => 0               // default
		      |                        offset;

	  hard_limit = limit.isnull() 
		    || limit eq ""          => limit           // default
		     | limit > max_returned => max_returned
		     |                         limit; 

	  global_opt = {
	    "index" : hard_offset,
	    "limit" : hard_limit
	  }; 

	  sorted_keys = this2that:transform(entvar, sort_opt, global_opt.klog(">>>> transform using global options >>>> "));
	  sorted_keys.map(function(id){ entvar{id} })
	};


	id.isnull() || id eq "" => all_values(limit, offset)
				 | entvar{id}
      }
    };

    violations = accessor_factory(ent:violation_log)

    old_violations = function(id,limit, offset) {
      id.isnull() || id eq "" => allViolations(limit, offset)
                               | ent:violation_log{id}
    };

    allViolations = function(limit, offset) {
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

      sorted_keys = this2that:transform(ent:violation_log, sort_opt, global_opt.klog(">>>> transform using global options >>>> "));
      sorted_keys.map(function(id){ ent:violation_log{id} })
    };

   
  }



  rule clear_violation_log {
    select when esproto reset_collection_logs
    pre {
      timestamp = time:now();
    }
    always {
      set ent:violation_log {timestamp: {"reading": {},
		                         "timestamp": timestamp,
		                         "message": "log cleared"}
      	  		    };
    }
  }


  rule log_violation {
    select when esproto threshold_violation
    pre {
      readings = event:attr("reading").decode();
      timestamp = time:now(); // should come from device
      new_log = ent:violation_log
      	             .put([timestamp], {"reading": readings,
		                        "timestamp": timestamp,
		                        "message": event:attr("message")})
      	             //.klog("New log ")
		     ;
    }
    always {
      set ent:violation_log new_log
    }
  }


  rule send_email_to_owner {
      select when fuse email_for_owner
      pre {

        // from a subscriber...

	me = pds:get_all_me();

	subj = event:attr("subj").defaultsTo("Message from Fuse");
	msg = event:attr("msg").defaultsTo("This email contains no message");
	html = event:attr("html").defaultsTo(msg);
	recipient =  me{"myProfileEmail"}.klog(">>>> email address >>>>") ;
	attachment = event:attr("attachment");
	filename = event:attr("filename").defaultsTo("attached_file");

	mailtype = attachment.isnull() => "html"
					| "attachment";

//	  huh = event:attrs().klog(">>>> event attrs >>>>");

      }
      if( meta:eci().klog(">>>> came thru channel >>>>") eq fleet_backchannel.klog(">>>> fleet channel >>>>")
       && not msg.isnull()
	) then
	choose mailtype {
	  html       => sendgrid:sendhtml(me{"myProfileName"}, recipient, subj, msg, html);
	  attachment => sendgrid:sendattachment(me{"myProfileName"}, recipient, subj, msg, filename, attachment);
	}
  }



}