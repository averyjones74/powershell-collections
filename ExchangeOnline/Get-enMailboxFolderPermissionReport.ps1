function Get-enMailboxFolderPermissionReport
{
   <#
         .SYNOPSIS
         Get a detailed mailbox folder permission report

         .DESCRIPTION
         Get a detailed mailbox folder permission report and exports this report to a given CSV file.
         You can select only user-mailboxes, only shared-mailboxes or both for the reporting.

         .PARAMETER Identity
         The Identity parameter specifies the mailbox that you want to view.
         You can use any value that uniquely identifies the mailbox.

         Default is * (all)

         .PARAMETER MailboxType
         The type is the value for the regular RecipientTypeDetails.

         The acceptable values for this parameter are:
         - UserMailbox
         - User
         - SharedMailbox
         - Shared
         - All

         The Default is ALL

         .PARAMETER ResultSize
         The ResultSize parameter specifies the maximum number of results to return.
         If you want to return all requests that match the query, use unlimited for the value of this parameter.

         The default value is unlimited.

         .PARAMETER Path
         Specifies the path to the CSV output file.

         The default is 'C:\scripts\PowerShell\Reports\MailboxFolderPermissionReport.csv'

         .PARAMETER Encoding
         Specifies the encoding for the exported CSV file.
         The acceptable values for this parameter are:
         - Unicode
         - UTF7
         - UTF8
         - ASCII
         - UTF32
         - BigEndianUnicode
         - Default
         - OEM

         Default is UTF8

         .EXAMPLE
         PS C:\> Get-enMailboxFolderPermissionReport

         Get a detailed mailbox folder permission report

         .NOTES
         Developed and tested with Exchange Online, it should work with on Premises Exchange 2010/2010/2016/2019

         This is open-source software, if you find an issue try to fix it yourself.
         There is no support and/or warranty in any kind

         .LINK
         http://www.enatec.io

         .LINK
         Get-Mailbox

         .LINK
         Get-MailboxFolderStatistics

         .LINK
         Get-MailboxFolderPermission

         .LINK
         Export-Csv
   #>

   [CmdletBinding(ConfirmImpact = 'None')]
   param
   (
      [Parameter(ValueFromPipeline = $true,
         ValueFromPipelineByPropertyName = $true)]
      [AllowEmptyString()]
      [AllowEmptyCollection()]
      [Alias('Mailbox', 'MailboxID', 'MailboxIdentity')]
      [string]
      $Identity = '*',
      [Parameter(ValueFromPipeline = $true,
         ValueFromPipelineByPropertyName = $true)]
      [ValidateSet('UserMailbox', 'User', 'SharedMailbox', 'Shared', 'All', IgnoreCase = $true)]
      [string]
      $MailboxType = 'All',
      [Parameter(ValueFromPipeline = $true,
         ValueFromPipelineByPropertyName = $true)]
      [AllowEmptyCollection()]
      [AllowEmptyString()]
      [Alias('MailboxResultSize')]
      [string]
      $ResultSize = 'Unlimited',
      [Parameter(ValueFromPipeline = $true,
         ValueFromPipelineByPropertyName = $true)]
      [AllowEmptyCollection()]
      [AllowEmptyString()]
      [Alias('CsvReport', 'CsvFile')]
      [string]
      $Path = 'C:\scripts\PowerShell\Reports\MailboxFolderPermissionReport.csv',
      [Parameter(ValueFromPipeline = $true,
         ValueFromPipelineByPropertyName = $true)]
      [ValidateSet('Unicode', 'UTF7', 'UTF8', 'ASCII', 'UTF32', 'BigEndianUnicode', 'Default', 'OEM', IgnoreCase = $true)]
      [AllowEmptyCollection()]
      [AllowEmptyString()]
      [Alias('CsvEncoding')]
      [string]
      $Encoding = 'UTF8'
   )

   begin
   {
      #region Cleanup
      $MailboxPermissionReport = $null
      $AllMailboxes = $null
      $MailboxCount = $null
      $MailboxFolderPermission = $null
      $ProgressStatus = $null
      #endregion Cleanup

      #region Defaults
      $SCT = 'SilentlyContinue'
      $CNT = 'Continue'

      if (-not ($Identity))
      {
         $Identity = '*'
      }

      if (-not ($MailboxType))
      {
         $MailboxType = 'All'
      }

      if (-not ($ResultSize))
      {
         $ResultSize = 'Unlimited'
      }

      if (-not ($Path))
      {
         $Path = 'C:\scripts\PowerShell\Reports\MailboxFolderPermissionReport.csv'
      }

      if (-not ($Encoding))
      {
         $Encoding = 'UTF8'
      }
      #endregion Defaults

      #region MailboxType
      Write-Verbose -Message 'Get the mailboxes'

      #region paramGetMailbox
      $paramGetMailbox = @{
         Identity      = $Identity
         ResultSize    = $ResultSize
         ErrorAction   = $SCT
         WarningAction = $CNT
      }
      #endregion paramGetMailbox

      #region MailboxTypeSwitch
      switch ($MailboxType)
      {
         UserMailbox
         {
            $paramWhereObject = @{
               FilterScript = {
                  $_.RecipientTypeDetails -eq 'UserMailbox'
               }
            }
         }
         User
         {
            $paramWhereObject = @{
               FilterScript = {
                  $_.RecipientTypeDetails -eq 'UserMailbox'
               }
            }
         }
         SharedMailbox
         {
            $paramWhereObject = @{
               FilterScript = {
                  $_.RecipientTypeDetails -eq 'SharedMailbox'
               }
            }
         }
         Shared
         {
            $paramWhereObject = @{
               FilterScript = {
                  $_.RecipientTypeDetails -eq 'SharedMailbox'
               }
            }
         }
         All
         {
            $paramWhereObject = @{
               FilterScript = {
                  $_.RecipientTypeDetails -eq 'UserMailbox' -or $_.RecipientTypeDetails -eq 'SharedMailbox'
               }
            }
         }
         default
         {
            $paramWhereObject = @{
               FilterScript = {
                  $_.RecipientTypeDetails -eq 'UserMailbox' -or $_.RecipientTypeDetails -eq 'SharedMailbox'
               }
            }
         }
      }
      #endregion MailboxTypeSwitch

      #region GetAllMailboxes
      $AllMailboxes = (Get-Mailbox @paramGetMailbox | Where-Object @paramWhereObject | Sort-Object)
      #endregion GetAllMailboxes
      #endregion MailboxType
   }

   process
   {
      if ($AllMailboxes)
      {
         # Create a new object for the report
         $MailboxPermissionReport = @()

         # Create a counter for Write-Progress
         $MailboxCounter = ($AllMailboxes | Measure-Object).Count

         # Set the start counter for Write-Progress to 1
         $MailboxCount = 1

         #region MailboxLoop
         Write-Verbose -Message 'Process all mailboxes'

         ForEach ($SingleMailbox in $AllMailboxes)
         {
            # Update Write-Progress
            $ProgressActivity = ('Working on Mailbox {0} of {1} ({2})' -f $MailboxCount, $MailboxCounter, $SingleMailbox.UserPrincipalName)
            $ProgressStatus = ('Getting folders for mailbox: {0} ({1})' -f $SingleMailbox.DisplayName, $SingleMailbox.UserPrincipalName)

            Write-Verbose -Message $ProgressStatus

            $paramWriteProgress = @{
               Status          = $ProgressStatus
               Activity        = $ProgressActivity
               PercentComplete = (($MailboxCount/$MailboxCounter) * 100)
            }
            Write-Progress @paramWriteProgress

            # Get all folder for the mailbox
            $AllFolders = ($SingleMailbox | Get-MailboxFolderStatistics -FolderScope All | ForEach-Object -Process {
                  $_.folderpath
               } | ForEach-Object -Process {
                  $_.replace('/', '\')
               })

            ForEach ($SingleFolder in $AllFolders)
            {
               # Update Write-Progress
               $ProgressStatus = ('Get permissions for {0}' -f ($SingleMailbox.UserPrincipalName + ':' + $SingleFolder))

               Write-Verbose -Message $ProgressStatus

               $paramWriteProgress = @{
                  Status          = $ProgressStatus
                  Activity        = $ProgressActivity
                  PercentComplete = (($MailboxCount/$MailboxCounter) * 100)
               }
               Write-Progress @paramWriteProgress

               # Get mailbox folder permissions with Get-MailboxFolderPermission
               $MailboxFolderPermission = $null
               $paramGetMailboxFolderPermission = @{
                  Identity    = ($SingleMailbox.Alias + ':' + $SingleFolder)
                  ErrorAction = $SCT
               }
               $MailboxFolderPermission = (Get-MailboxFolderPermission @paramGetMailboxFolderPermission)

               # store results in variable
               $MailboxPermissionReport += $MailboxFolderPermission | Where-Object -FilterScript {
                  $_.User -notlike 'Default' -and $_.User -notlike 'Anonymous' -and $_.AccessRights -notlike 'None' -and $_.AccessRights -notlike 'Owner'
               } | Select-Object -Property @{
                  name       = 'Name'
                  expression = {
                     $SingleMailbox.Name
                  }
               }, @{
                  name       = 'UserPrincipalName'
                  expression = {
                     $SingleMailbox.UserPrincipalName
                  }
               }, FolderName, @{
                  name       = 'User'
                  expression = {
                     $_.User -join ','
                  }
               }, @{
                  name       = 'AccessRights'
                  expression = {
                     $_.AccessRights -join ','
                  }
               }

               # Cleanup
               $MailboxFolderPermission = $null
            }

            # Update the counter
            $MailboxCount++

            Write-Verbose -Message ('Done with processing {0}' -f $SingleMailbox.UserPrincipalName)
         }
         #endregion MailboxLoop

         #region Reporter
         if ($MailboxPermissionReport)
         {
            $paramExportCsv = @{
               Path              = $Path
               Force             = $true
               NoTypeInformation = $true
               Confirm           = $false
               ErrorAction       = 'Stop'
               WarningAction     = $CNT
            }
            $null = ($MailboxPermissionReport | Export-Csv @paramExportCsv)
         }
         else
         {
            Write-Warning -Message 'None of the Mailboxes has special permissions set'
         }
         #endregion Reporter
      }
      else
      {
         Write-Warning -Message 'No Mailboxes found that matches your search criteria'
      }
   }

   end
   {
      #region Cleanup
      $MailboxPermissionReport = $null
      $AllMailboxes = $null
      $MailboxCount = $null
      $MailboxFolderPermission = $null
      $ProgressStatus = $null
      #endregion Cleanup
   }
}

#region LICENSE
<#
   BSD 3-Clause License

   Copyright (c) 2021, enabling Technology
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
   - If you disagree with any of the terms, and any conditions declared: Just delete it and build your own solution
#>
#endregion DISCLAIMER
