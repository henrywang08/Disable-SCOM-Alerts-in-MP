$msname = 'SGOM01'
$SealedMPName = 'Windows Server 2012 Operating System (Monitoring)'
$OverrideMPName = 'Test OS Override'

Import-Module -Name OperationsManager
New-SCOMManagementGroupConnection -ComputerName $msname

$mps = Get-SCOMManagementPack |? {$_.DisplayName -eq $SealedMPName}
$overridemp = Get-SCOMManagementPack -DisplayName $OverrideMPName

$Monitors= Get-SCOMMonitor -ManagementPack $mps |?{$_.xmltag -eq "UnitMonitor"}
ForEach($Monitor in $Monitors)
{ If($Monitor.AlertSettings.AlertOnState -ne $null)
  {
    $Target= Get-SCOMClass -id $Monitor.Target.id
    $OverrideName=$Monitor.name+".Override"
    $Override = New-Object Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitorPropertyOverride($overridemp,$OverrideName)
    $Override.Monitor = $Monitor
    $Override.Property = "GenerateAlert"
    $Override.Value = "false"
    $Override.Context = $Target
    $Override.DisplayName = $OverrideName
    $Override
    }
}

$overridemp.Verify()
$overridemp.AcceptChanges() 


$Rules = Get-SCOMRule -ManagementPack $mps | ? {$_.WriteActionCollection -match 'GenerateAlert'}
ForEach($rule in $Rules)
{    
  Disable-SCOMRule -Rule $rule -ManagementPack $overridemp
  $Rule
}

