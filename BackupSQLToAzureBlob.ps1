## Setting some Variables
$From = ""
$To = ""
#$Bcc = ""
$SMTPServer = ""
$Body = "Backup succesful, see below: <br> "
$Datum = get-date -format "dd-MM-yyyy-HH-mm"
$serverinstance1 = 
$serverinstance2 = 
$serverinstance3 =

#Setting up the Drive to Azure under the account the script is running
$pass="$blobpass"| ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object System.Management.Automation.PsCredential('localhost\$bloblogin',$pass)
New-PSDrive -name W -Root #Path on blob storage -Credential $cred -PSProvider filesystem -ErrorAction SilentlyContinue

# Get the databases
$DatabasesInstance1 = Get-SqlDatabase -ServerInstance $serverinstance1

# Make the backups of Databases in Instance1
ForEach ($database in $DatabasesInstance1) {
#Make the backup and store in file
Backup-SqlDatabase -ServerInstance "$serverinstance1" -Database "$database" -BackupFile "$location\DB-$serverinstance1-$database-$Datum.bak"
Backup-SqlDatabase -ServerInstance "$serverinstance1" -Database "$database" -BackupFile "$location\LOG-$serverinstance1-$database-$Datum.bak" -BackupAction Log
#zip the files
v:
cd..
cd 7zip
cmd.exe /c "7z.exe a -t7z $location\$serverinstance1-$database-$Datum.7z -m0=lzma2 -mx0 -slp $location\DB-$serverinstance1-$database-$Datum.bak $location\LOG-$serverinstance1-$database-$Datum.bak"

[int]$BackupSize = "{0:N2}" -f ((gci -force $location\$serverinstance1-$database-$Datum.7z -Recurse -ErrorAction SilentlyContinue| measure Length -s).sum / 1Mb)
    if ($BackupSize -gt 1){

       Copy-Item -Path $location\$serverinstance1-$database-$Datum.7z -Destination W:\Backups\$serverinstance1-$database-$Datum.7z -Force
       [int]$BackupSizeAz = "{0:N2}" -f ((gci -force W:\Backups\$serverinstance1-$database-$Datum.7z -Recurse -ErrorAction SilentlyContinue| measure Length -s).sum / 1Mb)
            
            if ($BackupSizeAz -eq $BackupSize7z){

                $Body += "$serverinstance1-$database-$Datum.7z Succeeded. Size in Mb: $BackupSize7z<br>"
                Remove-Item "location\$serverinstance1-$database-$Datum.7z" -Confirm:$false -Recurse
                Remove-Item "$location\DB-$serverinstance1-$database-$Datum.bak" -Confirm:$false -Recurse
                Remove-Item "$location\LOG-$serverinstance1-$database-$Datum.bak" -Confirm:$false -Recurse

            }else{
           
                    $Body += "$serverinstance1-$database-$Datum.7z NOT Succeeded to copy. Size is: $BackupSize7z<br>"
            }

    }else{
    
        $Body += "$serverinstance1-$database-$Datum.7z NOT Succeeded. Size is less than 1Mb. Size is: $BackupSize7z<br>"

       }
}

Send-MailMessage -From $From -To $To -Bcc $Bcc -Subject $Subject -Body $Body -BodyAsHtml -SmtpServer $SMTPServer
