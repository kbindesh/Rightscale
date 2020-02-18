#Copyright 2015 RightScale
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.


#RightScale Cloud Application Template (CAT)

# DESCRIPTION
# Deploys a Windows Server of the type chosen by the user.
# It automatically imports the ServerTemplate it needs.

# Required prolog
name 'Windows Server New'
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
=begin
parameter "param_location" do
  like $parameters.param_location
  allowed_values "AWS", "AzureRM", "Google"
  default "AzureRM"
end
=end
parameter "param_servertype" do
  like $windows_server_declarations.param_servertype
end

parameter "param_instancetype" do
  like $parameters.param_instancetype
end

parameter "param_numservers" do
  like $parameters.param_numservers
end

parameter "param_username" do
  like $windows_server_declarations.param_username
end

parameter "param_password" do
  like $windows_server_declarations.param_password
end

parameter "param_costcenter" do
  category "User Inputs"
  like $parameters.param_costcenter
end

parameter "param_maintenancewindow" do
  category "User Inputs"
  like $parameters.param_maintenancewindow
end

parameter "param_virtualnetwork" do
  category "Configuration Options"
  like $parameters.param_virtualnetwork
end

parameter "param_Business" do
  category "User Inputs"
  like $parameters.param_Business
end

parameter "param_DevOwner" do
  category "User Inputs"
  like $parameters.param_DevOwner
end

parameter "param_Department" do
  category "User Inputs"
  like $parameters.param_Department
end

parameter "param_Project" do
  category "User Inputs"
  like $parameters.param_Project
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

parameter "param_useragreement" do
  label 'I hereby agree that funding for this resource has been aligned and I take full responsibility for the costs incurred'
  category 'User Agreement'
  default 'false'
  type 'string'
  allowed_values 'true','false'
  min_length 4
  constraint_description "You have to agree the statement to proceed further!"
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

output "output_admin_password_note" do
  label "Admin Password Note"
  category "Credentials"
  default_value "If you forgot the password, use the \"More Actions\" menu to reset the password."
end

output_set "output_server_ips_public" do
  label "Server Public IP"
  category "Access Information"
  description "IP address for the server(s)."
  default_value @windows_server.public_ip_address
end

output_set "output_server_ips_private" do
  label "Server Private IP"
  category "Access Information"
  description "IP address for the server(s)."
  default_value @windows_server.private_ip_address
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

# The off-the-shelf ServerTemplate being used has a couple of different MCIs defined based on the cloud.
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

### Server Definition ###
resource "windows_server", type: "server", copies: $param_numservers do
  like @windows_server_declarations.windows_server
end

resource "server_rg", type: "resource_group" do
  like @windows_server_declarations.server_rg
end

resource "server_deployment", type: "deployment" do
  like @windows_server_declarations.server_deployment
end

####################
# OPERATIONS       #
####################

operation "launch" do
  description "Launch the server"
  definition "launch_handler"
end

operation "enable" do
  description "Get information once the app has been launched"
  definition "enable"
  resource_mappings do {
    @windows_server => @servers
  } end
  output_mappings do {
    $output_server_ips_private => $server_ips
  } end
end

operation "update_server_password" do
  label "Update Server Password"
  description "Update/reset password."
  definition "update_password"
end

##########################
# DEFINITIONS (i.e. RCL) #
##########################

define enable(@windows_server, $param_username, $param_password, $param_costcenter,$param_maintenancewindow,$param_useragreement,$param_DevOwner,$param_Business,$param_Department,$param_Project,$param_Environment) return @servers, $server_ips do
  $server_ips = null
  # Run the script to set up the username and password
  #$script_name = "SYS Set Admin Account (v14.2)"
  #$script_inputs = {
   # 'ADMIN_PASSWORD':join(['text:', $param_password]),
   # 'ADMIN_ACCOUNT_NAME':join(['text:', $param_username])
  #}

  call sys_log.detail("##Enablement starts here..")

  $costtags=[join(["azure:CostCenter=", $param_costcenter])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $costtags)

  $bustags=[join(["azure:BusinessOwnerEmail=", $param_Business])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $bustags)

  $managtags=[join(["azure:DevOwnerEmail=", $param_DevOwner])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $managtags)

  $deptags=[join(["azure:Department=", $param_Department])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $deptags)

  $projtags=[join(["azure:Project=", $param_Project])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $projtags)

  $envtags=[join(["azure:Environment=", $param_Environment])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $envtags)

  $tags=[join(["azure:Maintenance-Window=", $param_maintenancewindow])]
  rs_cm.tags.multi_add(resource_hrefs: @@deployment.servers().current_instance().href[], tags: $tags)
  call sys_log.detail("##Tagging ends here..")
  call sys_log.detail("##Windows_Server: " + to_s(@windows_server))

  #call server_templates_utilities.run_script_inputs(@windows_server, $script_name, $script_inputs)

  $cred_name = "ABI_Server_Max_Value"
  @creds = rs_cm.credentials.index(view: 'sensitive', filter: [join(["name==", $cred_name])])

  $cred_object = to_object(@creds)
  $value = first($cred_object["details"])["value"]
  $value = to_n($value)
  $inc_value = $value+1

  if size(@creds) == 0
      raise "Unable to find credential with name: " + $name
  end

  # GET AND SET THE HOSTNAME HERE
  call set_hostname(@windows_server,$inc_value)

  # UPDATE THE FLAG BY INC ONE
  call sys_log.detail("Updating Cred..")
  $new_cred_value=to_s($inc_value)
  call update_cred($cred_name, $new_cred_value)
  call sys_log.detail("Updated Cred..")
end


define set_hostname(@windows_server,$inc_value) return $updated_hostname,@windows_server do
  $set_hostname_script ="SYS Set Hostname of WinServer"
  $updated_hostname = "ONEAZRRS000"
  if $inc_value < 10
      $updated_hostname=join(['ONEAZRRS000', $inc_value])
  elsif $inc_value >9 && $inc_value < 100
      $updated_hostname=join(['ONEAZRRS00', $inc_value])
  else
      $updated_hostname=join(['ONEAZRRS0', $inc_value])
  end
  $updated_hostname=to_s($updated_hostname)

  $hostname_script_inp ={
   "SERVER_HOSTNAME": "text:"+ $updated_hostname
  }

  call sys_log.detail("##Updated Hostname :" + to_s($updated_hostname))
  @hscript = rs_cm.right_scripts.get(latest_only: true, filter: [ join(["name==",$set_hostname_script]) ])
  $right_script_hrf=@hscript.href
  call sys_log.detail("##Script href :" + to_s($right_script_href))
  call sys_log.detail("##Server :" +to_s(@windows_server))
  call sys_log.detail("##Script Inp :" +to_s($hostname_script_inp))
  call sys_log.detail("##Script name :" + to_s($set_hostname_script))

  #call server_templates_utilities.run_script_inputs(@@deployment.servers(), $set_hostname_script, $hostname_script_inp)

  @@deployment.servers().current_instance().run_executable(right_script_href: $right_script_hrf, inputs: $hostname_script_inp)
  call sys_log.detail("##Sript executed successfully..")
end

define update_cred($cred_name, $new_cred_value) do
  @cred = rs_cm.credentials.get(filter: [join(["name==",$cred_name])])
  # May return partially matched named creds, so find the exact one we want
  foreach @credential in @cred do
    if @credential.name == $cred_name
      @cred = @credential
    end
  end
  @cred.update(credential: { value: $new_cred_value, description: "Updated by ABInBev on "+to_s(now()) })
end



define update_password(@windows_server, $param_password) do
  task_label("Update the windows server password.")

  # Run the script to set up the username and password
  $script_name = "SYS Set Admin Account (v14.2)"
  $script_inputs = {
    'ADMIN_PASSWORD':join(['text:', $param_password])
  }
  call server_templates_utilities.run_script_inputs(@windows_server, $script_name, $script_inputs)
end

define launch_handler(@windows_server, $param_rg, @server_rg, $map_cloud, $map_st) return @windows_server do

  call sys_log.detail("##Inside Launch_handler \n")
  # Check the execution name against Azure naming rules
  call account_utilities.checkAzureName(@@execution.name) retrieve $check_result
  if ($check_result)
    raise "AzureRM Naming Violation: " + $check_result
  end

  # Need the cloud name later on
  $cloud_name = map( $map_cloud, "AzureRM", "cloud" )

  # Check if the selected cloud is supported in this account.
  call cloud_utilities.checkCloudSupport($cloud_name, "AzureRM")

  # Import the RightScript that is used to setup the username and password later
  #@pub_rightscript = last(rs_cm.publications.index(filter: ["name==SYS Set Admin Account (v14.2)"]))
  #@pub_rightscript.import()

  if $param_rg == "NEW RESOURCE GROUP"
    call create_rg(@windows_server, $param_rg,@server_rg)
  else
    call provision_dep_with_rg(@windows_server, $param_rg)
  end
end

define provision_dep_with_rg(@windows_server, $param_rg) do

  sub task_label: 'Provisioning deployment' do
    @rg=rs_cm.resource_groups.index(filter: [join(["name==", $param_rg])])

    call sys_log.detail("##Selected RG :" + to_s(@rg.href)
    +"\n")
    @check_dep=rs_cm.deployments.index(filter: [join(["resource_group_href==", @rg.href])])
    call sys_log.detail("##Selected RG is associated with Deployment: " + to_s(@check_dep)+"\n")

    #sleep_until(@task.summary =~ "^(Completed|Aborted)")
    if empty?(@check_dep)
      call sys_log.detail("##In IF block\n")
      @@deployment.update(deployment: {resource_group_href: @rg.href})

      call sys_log.detail("##After Deployment update :" + to_s(@@deployment)+"\n")
      $deployment_href=@@deployment.href
      call sys_log.detail("##After Deployment href :" + to_s($deployment_href)+"\n")
      #raise "Failed to run " + $script_name
    else
      $deployment_href=@check_dep.href
      call sys_log.detail("In else, Deployment HREF :" + to_s($deployment_href)+"\n")
    end

    $json=to_object(@windows_server)
    $json['fields']['deployment_href']=$deployment_href
    call sys_log.detail("##Deployment href override :" + to_s($deployment_href)+"\n")
    @windows_server=$json

    provision(@windows_server)
  end
end

# Description: Returns the resource_groups that are currently available.
# Return: List of Resource Group present in 3524 region(West Europe)

  define get_rg() return $values do
    $values = []
    $values << "NEW RESOURCE GROUP"
    $myresource_groups=rs_cm.resource_groups.index(filter: ["cloud_href==/api/clouds/3526"])
    $rg1 = []

    foreach $rg in $myresource_groups do
      if size($rg) > 0
        $rg1 = $rg
      end
    end

    foreach $resourcegroup in $rg1 do
      $values << $resourcegroup["name"]
    end
  end

# Definition Name: create_rg
# Description    : This definition is used for Provisioning resources in new RG and Deployment

  define create_rg(@windows_server, $param_rg,@server_rg) do
    call sys_log.detail("YOU HAVE SELECTED NEW RG TO CREATE")
    provision(@server_rg)
    @@deployment.update(deployment: {resource_group: @server_rg.href})
    provision(@windows_server)
  end
