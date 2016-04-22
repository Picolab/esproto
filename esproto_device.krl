ruleset esproto_device {
  meta {

    name "esproto_device"
    author "PJW"
    description "General rules for ESProto system devices"

    use module b507199x5 alias wrangler
    
    logging on
    
    sharing on
    provides lastHeartbeat
  }

  global {

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