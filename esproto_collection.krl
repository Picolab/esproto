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
      ent:violation_logs
    }
   
  }


  rule log_violation {
    select when esproto threshold_violation
    pre {
      readings = event:attr("readings");
      timestamp = readings{"timestamp"};
      log_a =  ent:violation_log || {};
      new_log = log_a.put([timestamp], readings)
      	             .klog("New log ");
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