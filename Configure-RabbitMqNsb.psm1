cd $psscriptroot

##############################################################################################################################

Import-Module ./Configure-RabbitMQ -Force

##############################################################################################################################

function New-NsbDelayDeliveryBindingStandards {
    param([string]$vhost="%2f")

    # generating standard queues ##########################################################################################################

    $deadLetterExchange = "nsb.delay-delivery"
    @(0..27) | % { 

        $n = $_
        $nstr = $n.ToString("#00")
        $name = "nsb.delay-level-$nstr"
        $ttl = [math]::pow(2, $n) * 1000 
        $body = @"
        { "durable": true, "auto_delete": false, "arguments": { "x-queue-mode": "lazy", "x-message-ttl": $ttl, "x-dead-letter-exchange": "$deadLetterExchange" } }
"@
        New-Queue -vhost $vhost -qname $name -body $body

        $deadLetterExchange = $qname
    }

    # generating standard exchanges #######################################################################################################

    $body = @"
    { "type": "topic", "durable": true, "auto_delete": false, "internal": false, "arguments": {} }
"@
        New-Exchange -vhost $vhost -name "nsb.delay-delivery" -body $body

    @(0..27) | % { 
        $n = $_
        $nstr = $n.ToString("#00")
        $name = "nsb.delay-level-$nstr"

        $body = @"
        { "type": "topic", "durable": true, "auto_delete": false, "internal": false, "arguments": {} }
"@

        New-Exchange -vhost $vhost -name $name -body $body
    }


    # generate standard exchange bindings #################################################################################################
    $destination = "nsb.delay-delivery"
    @(0..27) | % { 

        $n = $_
        $nstr = $n.ToString("#00")
        $source = "nsb.delay-level-$nstr"
        $routingkey = "*." * (27-$n) + "0.#"
        
        $body = @"
        { "routing_key": "$routingkey", "arguments": {} }
"@
        Add-E2EBinding -vhost $vhost -source $source -destination $destination -body $body

        $destination = $source
    }

    # generate standard queue bindings ####################################################################################################
    @(0..27) | % { 

        $n = $_
        $nstr = $n.ToString("#00")
        $source = "nsb.delay-level-$nstr"
        $routingkey = "*." * (27-$n) + "1.#"
        
        $body = @"
        { "routing_key": "$routingkey", "arguments": {} }
"@
        Add-E2QBinding -vhost $vhost -source $source -destination $source -body $body

    }

    # generate binding for queues #########################################################################################################


}

function New-NsbDelayDeliveryBindingToCustomQueue {
    param([string]$qname, [string]$vhost="%2f")

        $body = @"
        { "destination_type": "exchange", "routing_key": "#.$qname", "arguments": {} }
"@

    Add-E2EBinding -vhost $vhost -source nsb.delay-delivery -destination "$qname" -body $body

}
