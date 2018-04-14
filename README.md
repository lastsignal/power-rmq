# power-rmq

Power RMQ is a Powershell module that facilitates our PS script to configure RabbitMQ using RabbitMQ API. 

## Usage Example

``` powershell

Register-User -username 'guest' -password 'guest' -server 'localhost'

New-Exchange "my-first-exchange" -type "headers"
New-Exchange "my-second-exchange" type "fanout

Add-E2EBinding -source "my-first-exchange" `
  -destination "my-second-exchange" `
  -body '{"arguments":{"some-header-argument": "its-value"}}'

Unregister-User

```

It also supports Federation

``` powershell

...

New-FederationUpstream `
  -vhost "my-vhost" `
  -name "my-federation-upstream" -`
  uri "amqp://localhost/%2f" 
  -exchange "some-exchange-in-my-vhost" `
  -maxHops 2
  
 ...
 
```
## List of functions
<dl>
<dt>Add-E2EBinding</dt>
<dd>Add an exchage to exchage binding</dd>
<dt>Add-E2QBinding</dt>
<dd>Add an exchage to queue binding</dd>
<dt>Add-Permission</dt>
<dd>Add permission to an existing user</dd>
<dt>Get-Exchange</dt>
<dd>Get exchage by name</dd>
<dt>Get-Queue</dt>
<dd>Get queue by name</dd>
<dt>Get-User</dt>
<dd>Get user by name</dd>
<dt>Get-UserPermission</dt>
<dd>Get user permissions</dd>
<dt>New-Exchange</dt>
<dd>Create new exchage</dd>
<dt>New-FederationUpstream</dt>
<dd>Create new federation upstream</dd>
<dt>New-Policy</dt>
<dd>Create new policy</dd>
<dt>New-Queue</dt>
<dd>Create new queue</dd>
<dt>New-UpstreamPolicy</dt>
<dd>Create a specific policy for upstream</dd>
<dt>New-User</dt>
<dd>Create user</dd>
<dt>New-Vhost</dt>
<dd>Create vhost</dd>
<dt>Register-User</dt>
<dd>Login. Provide user credential and server info before doing any other action</dd>
<dt>Remove-E2EBinding</dt>
<dd>Delete exchage-to-exchage binding</dd>
<dt>Remove-E2QBinding</dt>
<dd>Delete exchage-to-queue binding</dd>
<dt>Remove-Exchange</dt>
<dd>Delete exchage</dd>
<dt>Remove-Queue</dt>
<dd>Delete queue</dd>
<dt>Remove-User</dt>
<dd>Delete user</dd>
<dt>Select-Bindings</dt>
<dd>Delete binding</dd>
<dt>Select-Exchanges</dt>
<dd>List existing exchages</dd>
<dt>Select-Permissions</dt>
<dd>List existing permissions</dd>
<dt>Select-Queues</dt>
<dd>List existing queues</dd>
<dt>Select-Users</dt>
<dd>List users</dd>
<dt>Select-Vhosts</dt>
<dd>vhosts</dd>
<dt>Unregister-User</dt>
<dd>Logout; Removed cached credentials</dd>
</dl>
