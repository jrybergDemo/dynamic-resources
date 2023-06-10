<#
.SYNOPSIS
    Script to initialize Terraform backend configuration
.DESCRIPTION
    This script initializes Terraform backend configuration using the specified parameters.
.PARAMETER repoPath
    The path to the repository.
.PARAMETER environment
    The environment to deploy to.
.PARAMETER configPath
    The path to the Terraform configuration.
.PARAMETER backendResourceGroupName
    The name of the resource group for the backend.
.PARAMETER backendStorageAccountName
    The name of the storage account for the backend.
.PARAMETER backendContainerName
    The name of the container for the backend.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$repoPath,
    [Parameter(Mandatory=$true)]
    [string]$environment,
    [Parameter(Mandatory=$true)]
    [string]$configPath,
    [Parameter(Mandatory=$true)]
    [string]$backendResourceGroupName,
    [Parameter(Mandatory=$true)]
    [string]$backendStorageAccountName,
    [Parameter(Mandatory=$true)]
    [string]$backendContainerName
)

# Download the Terraform executable into the current directory
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Latest version as of 2023-05-17
$url = 'https://releases.hashicorp.com/terraform/1.4.6/terraform_1.4.6_windows_386.zip'
$output = "$configPath\terraform.zip"

# Downloads Terraform zip file to the current directory
Write-Host "Downloading from $url to $output"
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $output)

Expand-Archive $output -DestinationPath $configPath -Force
Get-ChildItem
Write-Host "Terraform downloaded"

$curDir = Get-Location
$env:Path += "$curDir/terraform.exe" 
cd $configPath
Write-Host "Terraform initialized"
./terraform.exe --version

Write-Host "repo path is $repoPath"
Write-Host "environment is $environment"
Write-Host "config path is $configPath"
Write-Host "backend resource group name is $backendResourceGroupName"
Write-Host "backend storage account name path is $backendStorageAccountName"
Write-Host "backend container name is $backendContainerName"
