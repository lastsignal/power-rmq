###
###    Reference: https://github.com/lastsignal/power-rmq
###

function Register-User {
    param(
        [string]$server, 
        [string]$username, 
        [string]$password, 
        [ValidateSet('http', 'https')]
        [string]$protocol='https')

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $script:apiBase = "$protocol`://$server`:15672/api"
    $script:apiBase
    $script:auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username, $password)))
}

function Unregister-User {
    
    $script:auth = $null
}

function Invoke-Rest {
    param(
        [ValidateSet('Get', 'Put', 'Delete', 'Post')][string]$method, 
        [string]$resource,
        [string]$body)
    if($script:auth -eq $null){
        throw [System.Exception] "Use Register-User to login first"
    }

    $headers = @{Authorization = ("Basic {0}" -f $script:auth)}

    write-host ("{0}:{1}" -f $method, $resource) -ForegroundColor Yellow

    if($method -eq "Get" -or $method -eq "Delete") {

        $q = Invoke-RestMethod `
            -Headers $headers `
            -Method $method `
            -ContentType "application/json" `
            -Uri "$script:apiBase/$resource"
        return $q
    } else {        

        Invoke-RestMethod `
            -Headers $headers `
            -Method $method `
            -ContentType "application/json" `
            -Uri "$script:apiBase/$resource" `
            -Body $body
    }
}

function Invoke-Get {
    param([string]$resource)

    $q = Invoke-Rest -Method get -resource $resource

    return $q
}

function Invoke-Put {
    param([string]$resource, [string]$body)

    [void] (Invoke-Rest -Method put -resource $resource -body $body)
}

function Invoke-Post {
    param([string]$resource, [string]$body)

    [void] (Invoke-Rest -Method post -resource $resource -body $body)
}

function Invoke-Delete {
    param([string]$resource)

    [void] (Invoke-Rest -Method delete -resource $resource)
}

function Select-Queues {
    return (Invoke-Get "queues")
}

function Get-Queue {
    param([string]$qname, [string]$vhost="%2f")

    return (Invoke-Get -resource "queues/$vhost/$qname")
}

function New-Queue {
    param([string]$name, [string]$vhost="%2f", [string]$body='{"auto_delete":false,"durable":true,"arguments":{}}')

    Invoke-Put queues/$vhost/$name -body $body
}

function Remove-Queue {
    param([string]$name, [string]$vhost="%2f")

    [void] (Invoke-Delete -resource "queues/$vhost/$name")
}

function Select-Exchanges {
    $result = (Invoke-Get -resource "exchanges")
    $result = $result | where { $_.name -ne "" -and $_.name -notlike "amq*" }

    return $result
}

function Get-Exchange {
    param([string]$name, [string]$vhost="%2f")

    return Invoke-Get -resource "exchanges/$vhost/$name"
}

function New-Exchange {
    param([string]$name, [string]$type, [string]$vhost = '%2f', [string]$body=@"
    {
        "type":"$type",
        "auto_delete":false,
        "durable":true,
        "internal":false,
        "arguments":{}
    }
"@)
    Invoke-Put -resource "exchanges/$vhost/$name" -body $body
}

function Remove-Exchange {
    param([string]$name, [string]$vhost="%2f")

    Invoke-Delete -resource "exchanges/$vhost/$name"
}

function Select-Bindings {
    param([string]$vhost="%2f")

    $result = Invoke-Get -resource "bindings/$vhost"
    $result = $result | where { $_.source -ne '' -and $_.source -NotLike 'federation:*'}
    return $result
}

function Add-E2QBinding {
    param([string]$source, [string]$destination, [string]$body, [string]$vhost="%2f")

    [void] (Invoke-Post -resource "bindings/$vhost/e/$source/q/$destination" -body $body)
}

function Add-E2EBinding {
    param([string]$source, [string]$destination, [string]$body, [string]$vhost="%2f")

    [void] (Invoke-Post -resource "bindings/$vhost/e/$source/e/$destination" -body $body)
}

function Remove-E2EBinding {
    param([string]$source, [string]$destination, [string]$props, [string]$vhost="%2f")

    Invoke-Delete -resource "bindings/$vhost/e/$source/e/$destination/$props"
}

function Remove-E2QBinding {
    param([string]$source, [string]$destination, [string]$props, [string]$vhost="%2f")
        
    Invoke-Delete -resource "bindings/$vhost/e/$source/q/$destination/$props"
}

function Select-Vhosts {
    Invoke-Get -resource "vhosts"
}

function New-Vhost {
    param([string] $name)

    Invoke-Put -resource "vhosts/$name"
}

function Remove-Vhost {
    param([string] $name)

    Invoke-Delete -resource "vhosts/$name"
}

function New-FederationUpstream{
    param([string]$exchange, [string[]]$uris, [string]$name, [int]$maxHops=1, [string]$vhost="%2f", [int]$messageTtl=43200000)

    $endpoint = $uris | ConvertTo-Json

    $parameter = @"
    {
      "value": {
        "ack-mode": "on-confirm",
        "exchange": "$exchange",
        "message-ttl": $messageTtl,
        "reconnect-delay": 11,
        "trust-user-id": false,
        "uri": $endpoint,
        "max-hops": $maxHops
      },
      "vhost": "$vhost",
      "component": "federation-upstream",
      "name": "$name"
    }
"@

    Invoke-put -resource "parameters/federation-upstream/$vhost/$name" -body $parameter
}

function New-Policy {
    param(
    [string]$name, 
    [string]$pattern, 
    [ValidateSet('all', 'exchanges', 'queues')][string]$applyTo, 
    [hashtable]$definition = @{},
    [int]$priority=0,
    [string]$vhost="%2f")

    $parameters = @{
        "vhost"= "$vhost";
        "name"= "$name";
        "pattern"= "$pattern";
        "apply-to"= "$applyTo";
        "definition"=$definition;
        "priority"=$priority
    }
    
    $body = $parameters | ConvertTo-Json

    Invoke-Put -resource "policies/$vhost/$name" -body $body.ToString()
}

function Remove-Policy {
    param(
    [string]$name,
    [string]$vhost="%2f")

    Invoke-Delete -resource "policies/$vhost/$name" 
}

function New-UpstreamPolicy {
    param([string]$upstreamName, [string]$pattern, [string]$name, [string]$vhost="%2f", [hashtable]$additionalDefinitions=@{})

    $additionalDefinitions.Add("federation-upstream", $upstreamName)

    $parameters = @{
        "vhost"= "$vhost";
        "name"= "$name";
        "pattern"= "$pattern";
        "apply-to"= "exchanges";
        "definition"= $additionalDefinitions;
        "priority"=$priority
    }

    Invoke-Put -resource "policies/$vhost/$name" -body $parameter
}

function Select-Users {
    Invoke-Get -resource 'users'
}

function Get-User {
    param([string]$name)

    Invoke-Get -resource "users/$name"
}

function Get-UserPermission {
    param([string]$name)

    Invoke-Get -resource "users/$name/permissions"
}

function New-User {
    param([string]$name, [string]$password, [string]$tags="")

    Invoke-Put -resource "users/$name" -body @"
        {"password":"$password", "tags":"$tags"}
"@
}

function New-UserWithHash {
    param([string]$name, [string]$passwordHash, [string]$tags="")

    Invoke-Put -resource "users/$name" -body @"
        {"password_hash":"$passwordHash", "tags":"$tags"}
"@
}

function Remove-User {
    param([string]$name)

    Invoke-Delete -resource "users/$name" 
}

function Select-Permissions {
    Invoke-Get -resource "permissions"
}

function Add-Permission {
    param([string]$username, [string]$vhost="%2f", [string]$configPattern="", [string]$writePattern=".*", [string]$readPattern=".*")

    Invoke-Put -resource "permissions/$vhost/$username" -body @"
        {"configure":"$configPattern","write":"$writePattern","read":"$readPattern"}
"@
    
}

function Select-GlobalParameters {
    Invoke-Get -resource "global-parameters"
}

function Add-GlobalParameter {
    param([string]$name, $value)
    Invoke-Put -resource "global-parameters/$name" -body @"
        {"name":"$name","value": "$value" }
"@
}

function Remove-GlobalParameter {
    param([string]$name)
    Invoke-Delete -resource "global-parameters/$name"
}

function Select-Connections {
    param($vhost)

    if($vhost -eq $null) {
        $resource = "connections"
    }
    else {
        $resource = "vhosts/$vhost/connections"
    }

    Invoke-Get -resource $resource
}

function Remove-Connection {
    param($name)

    Invoke-Delete "connections/$name"
}

function Remove-QueueContents {
    param($vhost, $queue)

    Invoke-Delete "queues/$vhost/$queue/contents"
}
