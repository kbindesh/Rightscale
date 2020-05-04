name 'Azure SQL'
rs_ca_ver 20161221
short_description "![logo](https://s3.amazonaws.com/rs-pft/cat-logos/azure_sqlserver.png)

Launch an Azure SQL Paas Server with sample Database and SQL Elastic Pool"

import "sys_logs"
import "plugins/rs_azure_sqlj"
#import "plugins/rs_azure_templatej"

parameter "subscription_id" do
  like $rs_azure_sqlj.subscription_id
  default "535a22bc-653b-4d3e-bb2c-281f000a4a06"
end

output "databases" do
  label "Databases"
  category "Databases"
  default_value $db_link_output
  description "Databases"
end

output "firewall_rules" do
  label "firewall_rules"
  category "Databases"
  default_value $firewall_rules_link_output
  description "firewall_rules"
end

output "failover_groups" do
  label "failover_groups"
  category "Databases"
  default_value $failover_groups_link_output
  description "failover_groups"
end

output "elastic_pools" do
  label "elastic_pools"
  category "Databases"
  default_value $elastic_pools_link_output
  description "elastic_pools"
end

permission "read_creds" do
  actions   "rs_cm.show_sensitive","rs_cm.index_sensitive"
  resources "rs_cm.credentials"
end

resource "sql_server", type: "rs_azure_sqlj.sql_server" do
  name join(["sql-server-", last(split(@@deployment.href, "/"))])
  resource_group "ABInBev_PoC"
  location "East Asia"
  properties do {
      "version" => "12.0",
      "administratorLogin" =>"superdbadmin",
      "administratorLoginPassword" => "RightScale2017!"
  } end
end

resource "database", type: "rs_azure_sqlj.databases" do
  name "sample-database"
  resource_group "ABInBev_PoC"
  location "East Asia"
  server_name @sql_server.name
end

resource "transparent_data_encryption", type: "rs_azure_sqlj.transparent_data_encryption" do
  resource_group "ABInBev_PoC"
  location "East Asia"
  server_name @sql_server.name
  database_name @database.name
  properties do {
    "status" => "Disabled"
  } end
end

resource "firewall_rule", type: "rs_azure_sqlj.firewall_rule" do
  name "sample-firewall-rule"
  resource_group "ABInBev_PoC"
  location "East Asia"
  server_name @sql_server.name
  properties do {
    "startIpAddress" => "0.0.0.1",
    "endIpAddress" => "0.0.0.1"
  } end
end

resource "elastic_pool", type: "rs_azure_sqlj.elastic_pool" do
  name "sample-elastic-pool"
  resource_group "ABInBev_PoC"
  location "East Asia"
  server_name @sql_server.name
end

resource "auditing_policy", type: "rs_azure_sqlj.auditing_policy" do
  name "sample-auditing-policy"
  resource_group "ABInBev_PoC"
  location "East Asia"
  server_name @sql_server.name
  database_name @database.name
  properties do {
    "state" => "Enabled",
    "storageAccountAccessKey" => cred("storageAccountAccessKey"),
    "storageEndpoint" => cred("storageEndpoint")
  } end
end

resource "security_policy", type: "rs_azure_sqlj.security_policy" do
  name "sample-security-policy"
  resource_group "ABInBev_PoC"
  location "East Asia"
  server_name @sql_server.name
  database_name @database.name
  properties do {
    "state" => "Enabled",
    "storageAccountAccessKey" => cred("storageAccountAccessKey"),
    "storageEndpoint" => cred("storageEndpoint")
  } end
end

operation "launch" do
 description "Launch the application"
 definition "launch_handler"
 output_mappings do {
  $databases => $db_link_output,
  $firewall_rules => $firewall_rules_link_output,
  $failover_groups => $failover_groups_link_output,
  $elastic_pools => $elastic_pools_link_output
 } end
end

define launch_handler(@sql_server,@database,@transparent_data_encryption,@firewall_rule,@elastic_pool,@auditing_policy,@security_policy) return @databases,$db_link_output,$firewall_rules_link_output,$failover_groups_link_output, $elastic_pools_link_output do
  provision(@sql_server)
  provision(@database)
  provision(@transparent_data_encryption)
  provision(@firewall_rule)
  provision(@elastic_pool)
  provision(@auditing_policy)
  provision(@security_policy)
  call start_debugging()
  sub on_error: skip, timeout: 2m do
    call sys_logs.detail("getting database link")
    @databases = @sql_server.databases()
    $db_link_output = to_s(to_object(@databases))
    call sys_logs.detail("getting firewall link")
    @firewall_rules = @sql_server.firewall_rules()
    $firewall_rules_link_output  = to_s(to_object(@firewall_rules))
    call sys_logs.detail("getting failover link")
    @failover_groups = @sql_server.failover_groups()
    $failover_groups_link_output = to_s(to_object(@failover_groups))
    call sys_logs.detail("getting elastic pool link")
    @elastic_pools = @sql_server.elastic_pools()
    $elastic_pools_link_output = to_s(to_object(@elastic_pools))
  end
  call stop_debugging()
end

define start_debugging() do
  if $$debugging == false || logic_and($$debugging != false, $$debugging != true)
    initiate_debug_report()
    $$debugging = true
  end
end

define stop_debugging() do
  if $$debugging == true
    $debug_report = complete_debug_report()
    call sys_logs.detail($debug_report)
    $$debugging = false
  end
end
