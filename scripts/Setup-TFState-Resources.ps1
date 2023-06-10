# Authenticate to Azure Subscription
param(
    $location                 = 'usgovvirginia',
    $tfbackend_rg_name        = 'RG_NAME',
    $tfbackend_sa_name        = 'SA_NAME',
    $tfbackend_container_name = 'tfstate',
    $tf_sp_name               = 'SP_NAME'
)

$subscriptionId = (Get-AzContext).Subscription.Id

####################### CREATE SERVICE PRINCIPAL AND FEDERATED CREDENTIAL #######################
$sp = Get-AzADServicePrincipal -DisplayName $tf_sp_name -ErrorAction 'Stop'

####################### CREATE BACKEND RESOURCES #######################
if (-Not (Get-AzResourceGroup -Name $tfbackend_rg_name -Location $location -ErrorAction 'SilentlyContinue'))
{
    New-AzResourceGroup -Name $tfbackend_rg_name -Location $location -ErrorAction 'Stop'
}

if (-Not ($sa = Get-AzStorageAccount -ResourceGroupName $tfbackend_rg_name -Name $tfbackend_sa_name -ErrorAction 'SilentlyContinue'))
{
    $sa = New-AzStorageAccount -ResourceGroupName $tfbackend_rg_name -Name $tfbackend_sa_name -Location $location -SkuName 'Standard_GRS' -AllowBlobPublicAccess $false -ErrorAction 'Stop'
}

if (-Not (Get-AzStorageContainer -Name $tfbackend_container_name -Context $sa.Context -ErrorAction 'SilentlyContinue'))
{
    $container = New-AzStorageContainer -Name $tfbackend_container_name -Context $sa.Context -ErrorAction 'Stop'
}

if (-Not (Get-AzRoleAssignment -ServicePrincipalName $sp.ApplicationId -Scope "/subscriptions/$subscriptionId" -RoleDefinitionName 'Contributor' -ErrorAction 'SilentlyContinue'))
{
    $subContributorRA = New-AzRoleAssignment -ApplicationId $sp.ApplicationId -Scope "/subscriptions/$subscriptionId" -RoleDefinitionName 'Contributor' -ErrorAction 'Stop'
}

if (-Not (Get-AzRoleAssignment -ServicePrincipalName $sp.ApplicationId -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor' -ErrorAction 'SilentlyContinue'))
{
    $saBlobContributorRA = New-AzRoleAssignment -ApplicationId $sp.ApplicationId -Scope $sa.Id -RoleDefinitionName 'Storage Blob Data Contributor' -ErrorAction 'Stop'
}
