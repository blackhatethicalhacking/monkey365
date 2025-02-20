﻿# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.



function Get-MonkeyAZPostgreSQLDatabaseFirewall {
<#
        .SYNOPSIS
		Plugin to get Firewall Rules from each PostgreSQL Server from Azure
        https://docs.microsoft.com/en-us/rest/api/postgresql/firewallrules/listbyserver

        .DESCRIPTION
		Plugin to get Firewall Rules from each PostgreSQL Server from Azure
        https://docs.microsoft.com/en-us/rest/api/postgresql/firewallrules/listbyserver

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZPostgreSQLDatabaseFirewall
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $false,HelpMessage = "Background Plugin ID")]
		[string]$pluginId
	)
	begin {
		#Plugin metadata
		$monkey_metadata = @{
			Id = "az00016";
			Provider = "AzureAD";
			Title = "Plugin to get Azure PostgreSQL firewall rules";
			Group = @("Firewall","Databases");
			ServiceName = "Azure PostgreSQL firewall rules";
			PluginName = "Get-MonkeyAZPostgreSQLDatabaseFirewall";
			Docs = "https://silverhack.github.io/monkey365/"
		}
		#Import Localized data
		$LocalizedDataParams = $O365Object.LocalizedDataParams
		Import-LocalizedData @LocalizedDataParams;
		#Get Environment
		$Environment = $O365Object.Environment
		#Get Azure Active Directory Auth
		$rm_auth = $O365Object.auth_tokens.ResourceManager
		#Get Config
		$AzurePostgreSQLConfigFW = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureForPostgreSQLFW" } | Select-Object -ExpandProperty resource
		#Get PostgreSQL Servers
		$DatabaseServers = $O365Object.all_resources | Where-Object { $_.type -like 'Microsoft.DBforPostgreSQL/servers' }
		if (-not $DatabaseServers) { continue }
		#Set array
		$AllPostgreSQLFWRules = @()
	}
	process {
		$msg = @{
			MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId,"Azure PostgreSQL Database firewall",$O365Object.current_subscription.displayName);
			callStack = (Get-PSCallStack | Select-Object -First 1);
			logLevel = 'info';
			InformationAction = $InformationAction;
			Tags = @('AzurePostgreSQLFWInfo');
		}
		Write-Information @msg
		if ($DatabaseServers) {
			foreach ($Server in $DatabaseServers) {
				if ($Server.Name -and $Server.id) {
					$msg = @{
						MessageData = ($message.AzureUnitResourceMessage -f $Server.Name,"PostgreSQL Firewall rules");
						callStack = (Get-PSCallStack | Select-Object -First 1);
						logLevel = 'info';
						InformationAction = $InformationAction;
						Tags = @('AzurePostgreSQLFWInfo');
					}
					Write-Information @msg
					$uri = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager,`
 							$server.id,"firewallrules",`
 							$AzurePostgreSQLConfigFW.api_version)
					#Get database info
					$params = @{
						Authentication = $rm_auth;
						OwnQuery = $uri;
						Environment = $Environment;
						ContentType = 'application/json';
						Method = "GET";
					}
					$PostgreSQLFWRules = Get-MonkeyRMObject @params
					if ($PostgreSQLFWRules.Properties) {
						foreach ($rule in $PostgreSQLFWRules) {
							$AzurePostgreDBFWRule = New-Object -TypeName PSCustomObject
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name ServerName -Value $server.Name
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name Location -Value $server.location
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name ResourceGroupName -Value $server.id.Split("/")[4]
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name RuleName -Value $rule.Name
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name StartIpAddress -Value $rule.Properties.startIpAddress
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name EndIpAddress -Value $rule.Properties.endIpAddress
							$AzurePostgreDBFWRule | Add-Member -Type NoteProperty -Name rawObject -Value $rule
							#Decorate object and add to list
							$AzurePostgreDBFWRule.PSObject.TypeNames.Insert(0,'Monkey365.Azure.PostgreSQLDatabaseFirewall')
							$AllPostgreSQLFWRules += $AzurePostgreDBFWRule
						}
					}
				}
			}
		}
	}
	end {
		if ($AllPostgreSQLFWRules) {
			$AllPostgreSQLFWRules.PSObject.TypeNames.Insert(0,'Monkey365.Azure.PostgreSQLDatabaseFirewall')
			[pscustomobject]$obj = @{
				Data = $AllPostgreSQLFWRules;
				Metadata = $monkey_metadata;
			}
			$returnData.az_psql_database_fw = $obj
		}
		else {
			$msg = @{
				MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure PostgreSQL firewall rules",$O365Object.TenantID);
				callStack = (Get-PSCallStack | Select-Object -First 1);
				logLevel = 'warning';
				InformationAction = $InformationAction;
				Tags = @('AzurePostgreSQLFWEmptyResponse');
			}
			Write-Warning @msg
		}
	}
}
