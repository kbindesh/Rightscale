# Required prolog
name 'Windows Server - Multiple'
rs_ca_ver 20161221
short_description "![logo](https://itcawsteam.s3-eu-west-1.amazonaws.com/abiwinlogo.png)"
long_description "Allows you to select different windows server types,cloud and performance level you want an it will create new Security Group.\n
\n
Clouds Supported: <B>AWS, AzureRM, Google</B>"

import "pftmb/parameters"
import "pftmb/mappings"
import "pftmb/resources", as: "common_resources"
import "pftmb/windows_server_declarations"
import "pftmb/conditions"
import "pftmb/server_templates_utilities"
import "pftmb/cloud_utilities"
import "pftmb/account_utilities"
import "pftmb/err_utilities", as: "debug"
import "pftmb/permissions"
import "sys_log"

##################
# Permissions    #
##################
permission "pftmb_general_permissions" do
  like $permissions.pftmb_general_permissions
end

permission "pftmb_sensitive_views" do
  like $permissions.pftmb_sensitive_views
end

##################
# User inputs    #
##################

parameter "param_servertype" do
  like $windows_server_declarations.param_servertype
end

parameter "param_numservers" do
    like $parameters.param_numservers
end

parameter "param_instancetype" do
    like $parameters.param_instancetype
end

parameter "param_virtualnetwork" do
  category "Configuration Options"
  like $parameters.param_virtualnetwork
end

parameter "param_Environment" do
  category "User Inputs"
  like $parameters.param_Environment
end

parameter "param_rg" do
  label "Select new Resouce Group to create or select an existing one"
  type "string"
  default 'None'
  description "json:{\"definition\":\"get_rg\", \"description\": \"Select your RG. \"}"
  operations "launch"
end

parameter "param_rg_name" do
  like $windows_server_declarations.param_rg_name
end

################################
# Outputs returned to the user #
################################
output "output_admin_username" do
  label "Admin Username"
  category "Credentials"
  description "Admin Username to access server."
  default_value $param_username
end

output "win_ui_link" do
  category "Credentials"
  label "Server IP"
  description "Refer this IP to access(RDP) the Server"
end

##############
# MAPPINGS   #
##############
mapping "map_cloud" do
  like $mappings.map_cloud
end

mapping "map_instancetype" do
  like $mappings.map_instancetype
end

mapping "map_st" do
  like $windows_server_declarations.map_st
end

mapping "map_mci" do
  like $windows_server_declarations.map_mci
end

mapping "map_network_type" do
  like $mappings.map_network_type
end

mapping "map_subnet_type" do
  like $mappings.map_subnet_type
end

############################
# RESOURCE DEFINITIONS     #
############################

resource "windows_server", type: "server", copies: $param_numservers do
    like @windows_server_declarations.windows_server
end

resource "server_rg", type: "resource_group" do
    like @windows_server_declarations.server_rg
end

resource "server_deployment", type: "deployment" do
    like @windows_server_declarations.server_deployment
end

############################
#  OPERATIONS              #
############################
operation "launch" do
    description "Launch the server"
    definition "launch_handler"
end

operation "enable" do
    description "Get information once the app has been launched"
    definition "enable"
end

##########################
# DEFINITIONS (i.e. RCL) #
##########################
#ABI_Server_Temp_Value
#ABI_Server_Max_Value

define enable(@windows_server) do
    call sys_log.detail("##Enablement starts..")

    call get_set_credential($param_numservers) retrieve $current_count
    call sys_log.detail("##Current count|Enable : " +to_s($current_count))

    call set_server_names(@windows_server,$current_count)
end

define launch_handler(@windows_server, $param_rg, @server_rg, $map_cloud, $map_st,$param_numservers) return @windows_server do
    call sys_log.detail("##Inside Launch_handler \n")

    call account_utilities.checkAzureName(@@execution.name) retrieve $check_result
    if ($check_result)
      raise "AzureRM Naming Violation: " + $check_result
    end

    $cloud_name = map( $map_cloud, "AzureRM", "cloud" )

    call cloud_utilities.checkCloudSupport($cloud_name, "AzureRM")

    if $param_rg == "NEW RESOURCE GROUP"
      call create_rg(@windows_server, $param_rg,@server_rg,$param_numservers) retrieve @windows_server
    else
      call select_existing_rg(@windows_server, $param_rg,$param_numservers) retrieve @windows_server
    end
end

define create_rg(@windows_server, $param_rg,@server_rg,$param_numservers) return @windows_server do
    call sys_log.detail("New RG selected..")
    provision(@server_rg)
    @@deployment.update(deployment: {resource_group: @server_rg.href})
    call sys_log.detail("No. of Servers : " +to_s($param_numservers))
    if $param_numservers > 0
        provision(@windows_server)
    end
end

define select_existing_rg(@windows_server, $param_rg,$param_numservers) return @windows_server do
    sub task_label: 'Provisioning deployment' do
        @rg=rs_cm.resource_groups.index(filter: [join(["name==", $param_rg])])

        call sys_log.detail("##Selected RG :" + to_s(@rg.href)
        +"\n")
        @check_dep=rs_cm.deployments.index(filter: [join(["resource_group_href==", @rg.href])])
        call sys_log.detail("##Selected RG is associated with Deployment: " + to_s(@check_dep)+"\n")

        if empty?(@check_dep)
            @@deployment.update(deployment: {resource_group_href: @rg.href})
            $deployment_href=@@deployment.href
        else
            $deployment_href=@check_dep.href
        end

        $json=to_object(@windows_server)
        $json['fields']['deployment_href']=$deployment_href
        call sys_log.detail("##Deployment href override :" + to_s($deployment_href)+"\n")
        @windows_server=$json

        if $param_numservers > 0
            provision(@windows_server)
        end
    end
end

define get_rg() return $values do
    $values = []
    $rg1 = []
    $values << "NEW RESOURCE GROUP"
    $myresource_groups=rs_cm.resource_groups.index(filter: ["cloud_href==/api/clouds/3524"])

    foreach $rg in $myresource_groups do
        if size($rg) > 0
        $rg1 = $rg
        end
    end
    foreach $resourcegroup in $rg1 do
        $values << $resourcegroup["name"]
    end
end

define set_server_names(@windows_server,$current_count) do

    call sys_log.detail("##Current cred value : " +to_s($current_count))
    $server_alias="ABIDEMO"
    $hostname_script ="SYS Set Hostname of WinServer"
    $updated_count = $current_count

    @hscript = rs_cm.right_scripts.get(latest_only: true, filter: [ join(["name==",$hostname_script]) ])
    $right_script_hrf=@hscript.href
    call sys_log.detail("##Updated Hostname : " +to_s($right_script_hrf))

    @serverlist = rs_cm.servers.index(filter: [join(["name==",$server_alias])])
    $servernames = @serverlist.name[]

    foreach @server in @serverlist do
        $updated_count=$updated_count+1
        $updated_hostname = join(['ONEAZRRS000', $updated_count])
        $hostname_script_inp ={
            "SERVER_HOSTNAME": "text:"+ $updated_hostname
        }
        call sys_log.detail("##Updated Hostname : " +to_s($updated_hostname))
        call sys_log.detail("##Prev Server Name : " +to_s(@server.name))

        $json = to_object(@server)
        call sys_log.detail("##Json : " +to_s($json))
        @server.update(server: {name: $updated_hostname})
        call sys_log.detail("Servername updated sucessfully")

        @target_instance = @server.current_instance()
        @target_instance.run_executable(right_script_href: $right_script_hrf, inputs: $hostname_script_inp)
        call sys_log.detail("Hostname updated sucessfully")
    end
end

define get_set_credential($param_numservers) return $current_count do
    $cred_name = "ABI_Server_Max_Value"
    @creds = rs_cm.credentials.index(view: 'sensitive', filter: [join(["name==", $cred_name])])

    $cred_object = to_object(@creds)
    $current_count = first($cred_object["details"])["value"]
    $current_count = to_n($current_count)
    call sys_log.detail("##Current count : " +to_s($current_count))

    $new_cred_value = $current_count + to_n($param_numservers)
    call sys_log.detail("##Updated cred value : " +to_s($new_cred_value))
    @creds.update(credential: { value: $new_cred_value, description: "Updated by ABInBev on "+to_s(now()) })
    call sys_log.detail("##Creds updated successfully..")
end
