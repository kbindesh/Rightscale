
name 'Test RHEL Server with Extension'
rs_ca_ver 20161221
short_description "Provision WinTest Server with Extension"

import "plugins/rs_azure_compute_test"
import "plugins/rs_azure_networking_test"
import "sys_log"


parameter "subscription_id" do
  label 'Subscription ID'
  type 'string'
  allowed_values 'XxxxXXXXXXXXxxxxxxxxxxxxxx'
end

resource "azure_nic", type: "rs_azure_networking_test.interface" do
  name join(['nic-win-', last(split(@@deployment.href,"/"))])
  location "centralus"
  resource_group "itcdelete-rg-1412921004"
  properties do {
    "ipConfigurations": [{
      "name": "ipconfig1",
      "properties": {
        "privateIPAllocationMethod": "Dynamic",
        "privateIPAddressVersion": "IPv4",
        "primary": true,
        "subnet": {
          "id": "/subscriptions/XXXxxxxxxxxxxXXXXXXXXXXXxxxxxxx/resourceGroups/MGMTPVT-RG-NAZ-NON-PROD/providers/Microsoft.Network/virtualNetworks/PVT-VNET-NAZ-NON-PROD/subnets/Infra"
        }
      }
    }]
  } end
end

resource "azure_linux_server", type: "rs_azure_compute_test.virtualmachine" do
  name join(["RHEL-", last(split(@@deployment.href,"/"))])
  location "centralus"
  resource_group "itcdelete-rg-1412921004"
  properties do {
    "hardwareProfile": {
      "vmSize": "Standard_B2s"
    },
    "storageProfile": {
      "imageReference": {
        "sku": "7-RAW",
        "publisher": "RedHat",
        "version": "latest",
        "offer": "RHEL"
      },
      "osDisk": {
        "caching": "ReadWrite",
        "managedDisk": {
          "storageAccountType": "StandardSSD_LRS"
        },
        "name": join(["myVMosdisk", last(split(@@deployment.href,"/"))]),
        "createOption": "FromImage"
      }
    },
    "osProfile": {
      "computerName": join(['RHEL-', last(split(@@deployment.href,"/"))]),
      "adminUsername": "binusertest",
      "adminPassword": "Welcome@12345",
      },
    "networkProfile": {
      "networkInterfaces": [{
        "id": @azure_nic.id
      }]
    }
  } end
end

resource "vm_extension_enable_diagsettings", type: "rs_azure_compute_test.extensions" do
    name join(["enable-vmdiagnostics-", @azure_linux_server.name])
    resource_group "itcdelete-rg-1412921004"
    location "centralus"
    virtualMachineName @azure_linux_server.name
    properties do {
      "publisher" => "Microsoft.Azure.Diagnostics",
      "type" => "LinuxDiagnostic",
      "typeHandlerVersion" => "3.0",
      "autoUpgradeMinorVersion" => true, 
      "protectedSettings": {
          "storageAccountName": "mgmtnaznonprodbootdiag",
          "storageAccountSasToken": "IvDnMURUAsF%2FKrkbGp9vtyqNwt8%3D"
      },
      "settings": {
        "StorageAccount": "mgmtnaznonprodbootdiag",
        "ladCfg": {
          "diagnosticMonitorConfiguration": {
            "eventVolume": "Medium",
            "syslogEvents": {
                "syslogEventConfiguration": {
                    "LOG_AUTH": "LOG_DEBUG",
                    "LOG_AUTHPRIV": "LOG_DEBUG",
                    "LOG_CRON": "LOG_DEBUG",
                    "LOG_DAEMON": "LOG_DEBUG",
                    "LOG_FTP": "LOG_DEBUG",
                    "LOG_KERN": "LOG_DEBUG",
                    "LOG_LOCAL0": "LOG_DEBUG",
                    "LOG_LOCAL1": "LOG_DEBUG",
                    "LOG_LOCAL2": "LOG_DEBUG",
                    "LOG_LOCAL3": "LOG_DEBUG",
                    "LOG_LOCAL4": "LOG_DEBUG",
                    "LOG_LOCAL5": "LOG_DEBUG",
                    "LOG_LOCAL6": "LOG_DEBUG",
                    "LOG_LOCAL7": "LOG_DEBUG",
                    "LOG_LPR": "LOG_DEBUG",
                    "LOG_MAIL": "LOG_DEBUG",
                    "LOG_NEWS": "LOG_DEBUG",
                    "LOG_SYSLOG": "LOG_DEBUG",
                    "LOG_USER": "LOG_DEBUG",
                    "LOG_UUCP": "LOG_DEBUG"
                }
            },
            "metrics": {
              "resourceId": join(["/subscriptions/XxxxxxxxxxxxxxxxxxxxXXXXXXXXXxxxxxx/resourceGroups/itcdelete-rg-1412921004/providers/Microsoft.Compute/virtualMachines/",@azure_linux_server.name]),
              "metricAggregation": [
                { "scheduledTransferPeriod": "PT1H" },
                { "scheduledTransferPeriod": "PT1M" }
              ]
            },
            "performanceCounters": {
                "performanceCounterConfiguration": [
                  {
                    "annotation": [
                      {
                        "displayName": "CPU IO wait time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentiowaittime", 
                    "counterSpecifier": "/builtin/processor/percentiowaittime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "CPU user time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentusertime", 
                    "counterSpecifier": "/builtin/processor/percentusertime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "CPU nice time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentnicetime", 
                    "counterSpecifier": "/builtin/processor/percentnicetime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "CPU percentage guest OS", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentprocessortime", 
                    "counterSpecifier": "/builtin/processor/percentprocessortime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "CPU interrupt time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentinterrupttime", 
                    "counterSpecifier": "/builtin/processor/percentinterrupttime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "CPU idle time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentidletime", 
                    "counterSpecifier": "/builtin/processor/percentidletime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "CPU privileged time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "processor", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "percentprivilegedtime", 
                    "counterSpecifier": "/builtin/processor/percentprivilegedtime", 
                    "type": "builtin", 
                    "unit": "Percent"
                  },
                  {
                    "annotation": [
                      {
                        "displayName": "Memory available", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "availablememory", 
                    "counterSpecifier": "/builtin/memory/availablememory", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Swap percent used", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "percentusedswap", 
                    "counterSpecifier": "/builtin/memory/percentusedswap", 
                    "type": "builtin", 
                    "unit": "Percent"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Memory used", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "usedmemory", 
                    "counterSpecifier": "/builtin/memory/usedmemory", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Page reads", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "pagesreadpersec", 
                    "counterSpecifier": "/builtin/memory/pagesreadpersec", 
                    "type": "builtin", 
                    "unit": "CountPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Swap available", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "availableswap", 
                    "counterSpecifier": "/builtin/memory/availableswap", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Swap percent available", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "percentavailableswap", 
                    "counterSpecifier": "/builtin/memory/percentavailableswap", 
                    "type": "builtin", 
                    "unit": "Percent"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Mem. percent available", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "percentavailablememory", 
                    "counterSpecifier": "/builtin/memory/percentavailablememory", 
                    "type": "builtin", 
                    "unit": "Percent"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Pages", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "pagespersec", 
                    "counterSpecifier": "/builtin/memory/pagespersec", 
                    "type": "builtin", 
                    "unit": "CountPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Swap used", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "usedswap", 
                    "counterSpecifier": "/builtin/memory/usedswap", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Memory percentage", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "percentusedmemory", 
                    "counterSpecifier": "/builtin/memory/percentusedmemory", 
                    "type": "builtin", 
                    "unit": "Percent"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Page writes", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "memory", 
                    "counter": "pageswrittenpersec", 
                    "counterSpecifier": "/builtin/memory/pageswrittenpersec", 
                    "type": "builtin", 
                    "unit": "CountPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Network in guest OS", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "bytesreceived", 
                    "counterSpecifier": "/builtin/network/bytesreceived", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Network total bytes", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "bytestotal", 
                    "counterSpecifier": "/builtin/network/bytestotal", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Network out guest OS", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "bytestransmitted", 
                    "counterSpecifier": "/builtin/network/bytestransmitted", 
                    "type": "builtin", 
                    "unit": "Bytes"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Network collisions", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "totalcollisions", 
                    "counterSpecifier": "/builtin/network/totalcollisions", 
                    "type": "builtin", 
                    "unit": "Count"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Packets received errors", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "totalrxerrors", 
                    "counterSpecifier": "/builtin/network/totalrxerrors", 
                    "type": "builtin", 
                    "unit": "Count"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Packets sent", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "packetstransmitted", 
                    "counterSpecifier": "/builtin/network/packetstransmitted", 
                    "type": "builtin", 
                    "unit": "Count"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Packets received", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "packetsreceived", 
                    "counterSpecifier": "/builtin/network/packetsreceived", 
                    "type": "builtin", 
                    "unit": "Count"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Packets sent errors", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "network", 
                    "counter": "totaltxerrors", 
                    "counterSpecifier": "/builtin/network/totaltxerrors", 
                    "type": "builtin", 
                    "unit": "Count"
                  },    
                  {
                    "annotation": [
                      {
                        "displayName": "Disk read guest OS", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "readbytespersecond", 
                    "counterSpecifier": "/builtin/disk/readbytespersecond", 
                    "type": "builtin", 
                    "unit": "BytesPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk writes", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "writespersecond", 
                    "counterSpecifier": "/builtin/disk/writespersecond", 
                    "type": "builtin", 
                    "unit": "CountPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk transfer time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "averagetransfertime", 
                    "counterSpecifier": "/builtin/disk/averagetransfertime", 
                    "type": "builtin", 
                    "unit": "Seconds"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk transfers", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "transferspersecond", 
                    "counterSpecifier": "/builtin/disk/transferspersecond", 
                    "type": "builtin", 
                    "unit": "CountPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk write guest OS", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "writebytespersecond", 
                    "counterSpecifier": "/builtin/disk/writebytespersecond", 
                    "type": "builtin", 
                    "unit": "BytesPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk read time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "averagereadtime", 
                    "counterSpecifier": "/builtin/disk/averagereadtime", 
                    "type": "builtin", 
                    "unit": "Seconds"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk write time", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "averagewritetime", 
                    "counterSpecifier": "/builtin/disk/averagewritetime", 
                    "type": "builtin", 
                    "unit": "Seconds"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk total bytes", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "bytespersecond", 
                    "counterSpecifier": "/builtin/disk/bytespersecond", 
                    "type": "builtin", 
                    "unit": "BytesPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk reads", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "readspersecond", 
                    "counterSpecifier": "/builtin/disk/readspersecond", 
                    "type": "builtin", 
                    "unit": "CountPerSecond"
                  }, 
                  {
                    "annotation": [
                      {
                        "displayName": "Disk queue length", 
                        "locale": "en-us"
                      }
                    ], 
                    "class": "disk", 
                    "condition": "IsAggregate=TRUE", 
                    "counter": "averagediskqueuelength", 
                    "counterSpecifier": "/builtin/disk/averagediskqueuelength", 
                    "type": "builtin", 
                    "unit": "Count"
                  }         
                ]
            },            
          },
          "sampleRateInSeconds": 15
        }
      } 
    } end
end 


operation "launch" do
    description "Launch the server"
    definition "launch_handler"
end

define launch_handler(@azure_nic,@azure_linux_server,@vm_extension_enable_diagsettings) do 
    provision(@azure_nic)
    sleep(10)
    provision(@azure_linux_server)
    sleep(60)
    provision(@vm_extension_enable_diagsettings)
end 
