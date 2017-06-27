# Arguments with defaults
param
(
    [string]$ResourceGroupName = '',
    [string]$Location = 'East US',

    [string]$KeyVaultName = '',
    [string]$KeyName = 'Standard_LRS',
    [string]$Destination = 'Software',

    [string]$SecretName = '',
    [string]$SecretText = '',

    [string]$AppClientID = '',

    [string[]]$PermissionsToCertificates = 'all',
    [string[]]$PermissionsToKeys = 'all',
    [string[]]$PermissionsToSecrets = 'all'
)

New-AzureRmKeyVault -VaultName $KeyVaultName -ResourceGroupName $ResourceGroupName -Location $Location

$key = Add-AzureKeyVaultKey -VaultName $KeyVaultName -Name $KeyName -Destination $Destination

$secretvalue = ConvertTo-SecureString $SecretText -AsPlainText -Force

$secret = Set-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName -SecretValue $secretvalue

# Do Azure AD stuff here
# https://docs.microsoft.com/en-us/azure/key-vault/key-vault-get-started#a-idregisteraregister-an-application-with-azure-active-directory

Set-AzureRmKeyVaultAccessPolicy -VaultName $KeyVaultName -ServicePrincipalName $AppClientID -PermissionsToCertificates $PermissionsToCertificates -PermissionsToKeys $PermissionsToKeys -PermissionsToSecrets $PermissionsToSecrets

$Keys = Get-AzureKeyVaultKey -VaultName $KeyVaultName

(Get-AzureKeyVaultSecret -VaultName $KeyVaultName -Name $SecretName)