﻿#requires -Version 1.0 -RunAsAdministrator

<#
      .SYNOPSIS
      Cleanup the Windows 10 Start Menu

      .DESCRIPTION
      Cleanup the Windows 10 Start Menu

      .NOTES
      Version 1.0.2

      .LINK
      http://beyond-datacenter.com
#>
[CmdletBinding(ConfirmImpact = 'Low')]
param ()

begin
{
	Write-Output -InputObject 'Cleanup the Windows 10 Start Menu'

	#region Defaults
	$SCT = 'SilentlyContinue'
	#endregion Defaults

	$null = (Set-MpPreference -EnableControlledFolderAccess Disabled -Force -ErrorAction $SCT)

	$StartMenuContent = @'
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns:taskbar="http://schemas.microsoft.com/Start/2014/TaskbarLayout" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
<LayoutOptions StartTileGroupCellWidth="6" />
<DefaultLayoutOverride>
<StartLayoutCollection>
<defaultlayout:StartLayout GroupCellWidth="6" />
</StartLayoutCollection>
</DefaultLayoutOverride>
</LayoutModificationTemplate>
'@

	$StartMenuFile = "$env:windir\StartMenuLayout.xml"
}

process
{
	# Stop Search - Gain performance
	$null = (Get-Service -Name 'WSearch' -ErrorAction $SCT | Where-Object { $_.Status -eq "Running" } | Stop-Service -Force -Confirm:$false -ErrorAction $SCT)

	# Delete layout file if it already exists
	if (Test-Path -Path $StartMenuFile -ErrorAction $SCT)
	{
		$null = (Remove-Item -Path $StartMenuFile -Force -Confirm:$false -ErrorAction $SCT)
	}

	# Creates the blank layout file
	$null = ($StartMenuContent | Out-File -FilePath $StartMenuFile -Encoding ASCII -Force -ErrorAction $SCT)

	$RegistryAliases = @('HKLM', 'HKCU')

	# Assign the start layout and force it to apply with "LockedStartLayout" at both the machine and user level
	foreach ($RegistryAlias in $RegistryAliases)
	{
		$RegistryBasePath = ($RegistryAlias + ':\SOFTWARE\Policies\Microsoft\Windows')
		$RegistryKeyPath = ($RegistryBasePath + '\Explorer')

		if (-not (Test-Path -Path $RegistryKeyPath -ErrorAction $SCT))
		{
			$null = (New-Item -Path $RegistryBasePath -Name 'Explorer' -Force -Confirm:$false -ErrorAction $SCT)
		}

		$null = (Set-ItemProperty -Path $RegistryKeyPath -Name 'LockedStartLayout' -Value 1 -Force -Confirm:$false -ErrorAction $SCT)
		$null = (Set-ItemProperty -Path $RegistryKeyPath -Name 'StartLayoutFile' -Value $StartMenuFile -Force -Confirm:$false -ErrorAction $SCT)
	}

	# Restart Explorer, open the start menu (necessary to load the new layout)
	Stop-Process -name explorer

	# Give it a few seconds to process
	Start-Sleep -Seconds 5

	$WScriptShell = (New-Object -ComObject wscript.shell)
	$WScriptShell.SendKeys('^{ESCAPE}')

	# Give it a few seconds to process
	Start-Sleep -Seconds 5

	# Enable the ability to pin items again by disabling "LockedStartLayout"
	foreach ($RegistryAlias in $RegistryAliases)
	{
		$RegistryBasePath = $RegistryAlias + ':\SOFTWARE\Policies\Microsoft\Windows'
		$RegistryKeyPath = $RegistryBasePath + '\Explorer'
		$null = (Set-ItemProperty -Path $RegistryKeyPath -Name 'LockedStartLayout' -Value 0 -Force -Confirm:$false -ErrorAction $SCT)
	}

	# Restart Explorer and delete the layout file
	Stop-Process -name explorer

	# Uncomment the next line to make clean start menu default for all new users
	# Import-StartLayout -LayoutPath $layoutFile -MountPath $env:SystemDrive\
	$null = (Remove-Item -Path $StartMenuFile -Force -Confirm:$false -ErrorAction $SCT)
}

end
{
	$null = (Set-MpPreference -EnableControlledFolderAccess Enabled -Force -ErrorAction $SCT)
}

#region LICENSE
<#
      BSD 3-Clause License

      Copyright (c) 2020, Beyond Datacenter
      All rights reserved.

      Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
      1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
      2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
      3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

      THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#>
#endregion LICENSE

#region DISCLAIMER
<#
      DISCLAIMER:
      - Use at your own risk, etc.
      - This is open-source software, if you find an issue try to fix it yourself. There is no support and/or warranty in any kind
      - This is a third-party Software
      - The developer of this Software is NOT sponsored by or affiliated with Microsoft Corp (MSFT) or any of its subsidiaries in any way
      - The Software is not supported by Microsoft Corp (MSFT)
      - By using the Software, you agree to the License, Terms, and any Conditions declared and described above
      - If you disagree with any of the Terms, and any Conditions declared: Just delete it and build your own solution
#>
#endregion DISCLAIMER
