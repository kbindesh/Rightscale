name 'Hostname'
rs_ca_ver 20161221
short_description "Hostname test catelog"
long_description "Hostname test catelog"


import "pftmb/parameters"
import "pftmb/mappings"
import "pftmb/resources", as: "common_resources"
import "pftmb/windows_server_declarations"
import "pftmb/server_templates_utilities"
import "pftmb/cloud_utilities"
import "pftmb/account_utilities"
import "pftmb/err_utilities", as: "debug"
import "pftmb/permissions"
import "sys_log"

parameter "param_username" do
  category "User Inputs"
  label "Windows Username"
  type "string"
  no_echo "false"
end

parameter "param_password" do
  category "User Inputs"
  label "Windows Password"
  description "Minimum at least 8 characters and must contain at least one of each of the following:
  Uppercase characters, Lowercase characters, Digits 0-9, Non alphanumeric characters [@#\$%^&+=]."
  type "string"
  min_length 8
  max_length 32
  allowed_pattern '(?=.*\d)(?=.*[a-z])(?=.*[A-Z])(?=.*[@#$%^&+=])'
  no_echo "true"
end

mapping "map_mci" do {
    "Windows 2008R2" => {
      "mci" => "Windows_Server_Datacenter_2008R2_x64",
    }
  } end

resource "windows_server", type: "server" do
  name join(['HOSTNAMEDEMO-', last(split(@@deployment.href,"/"))])
  cloud "AzureRM West Europe"
  network "ABInBev_PoC-vnet"
  subnets "default"
  server_template_href "/api/server_templates/427790004"
  multi_cloud_image_href "/api/multi_cloud_images/431178004"
  instance_type "Standard_B1ms"
  security_group_hrefs "/api/clouds/3524/security_groups/BQJCVS3P8BI5I"
  associate_public_ip_address true
end

####################
# OPERATIONS       #
####################

operation "enable" do
    description "Get information once the app has been launched"
    definition "enable"
end

# Description
define enable(@windows_server,$param_username, $param_password) do
    $cred_name = "ABI_Server_Max_Value"
    @creds = rs_cm.credentials.index(view: 'sensitive', filter: [join(["name==", $cred_name])])
    #@creds = rs_cm.credentials.show(view: 'sensitive', filter: ["href==/api/credentials/270371004"])
    #@creds = rs_cm.credentials.get(filter: "name==ABI_Server_Max_Value", view: "sensitive")
    call sys_log.detail("Creds :" + to_s(@creds)+"\n")
    call sys_log.detail("Creds Name :" + to_s(@creds.name))
    call sys_log.detail("Creds created :" + to_s(@creds.created_at))
    call sys_log.detail("Creds Value :" + to_s(@creds.value))

    $cred_object = to_object(@creds)
    $value = first($cred_object["details"])["value"]
    call sys_log.detail("Creds Value(string) :" + to_s($value))
    call sys_log.detail("Creds Value(Num) :" + to_n($value))

    $value = to_n($value)
    $inc_value = $value+1
    call sys_log.detail("Creds Value(Num) :" + to_n($inc_value))

    #if size(@creds) == 0
    #    raise "Unable to find credential with name: " + $name
    #end

    # GET AND SET THE HOSTNAME HERE
    call set_hostname(@windows_server,$inc_value)

    # UPDATE THE FLAG BY INC ONE
    call sys_log.detail("Updating Cred..")
    $credential_params = {
      name => @creds.name,
      value => $inc_value
    }
    @task=rs_cm.credentials.update({"name":@creds.name, "value": $inc_value})
    @creds.update(credential: $credential_params)
    call sys_log.detail("Updated Cred..")
end

# Description: Set the hostname of Server

define set_hostname(@windows_server,$inc_value) return $updated_hostname do
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
     "SERVER_HOSTNAME":"text:$updated_hostname"
    }
    call sys_log.detail("##Script inputs :" + to_s($set_hostname_script))
    call sys_log.detail("##Updated Hostname :" + to_s($updated_hostname))
    @hscript = rs_cm.right_scripts.get(latest_only: true, filter: [ join(["name==",$set_hostname_script]) ])
    $right_script_href=@hscript.href
    call sys_log.detail("##Script href :" + to_s($right_script_href))
    call sys_log.detail("##Script Input :" + to_s($hostname_script_inp))
    call server_templates_utilities.run_script_inputs(@windows_server, $set_hostname_script, $hostname_script_inp)
end
