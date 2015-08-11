Invoke-Expression .\logo.ps1

function SetEnvironmetVariable($EnvPathName,$EnvPathValue,$Vals)
{
    $ValToSet = ""

    if ($EnvPathValue) 
    {
        foreach ($Val in $Vals)
        {        
            $tmpDir = $Val -replace "\\","\\"
            if ($EnvPathValue -match $tmpDir) { }
            else { $ValToSet += $Val }
         }

         if ($ValToSet) { setx $EnvPathName "$EnvPathValue;$ValToSet" /M | Out-Null }
    }
    else 
    {
        foreach ($Val in $Vals){$ValToSet += $Val}       
        setx $EnvPathName "$ValToSet" /M | Out-Null
    }
}

#Running commands to enable remote command execution

Write-Host "`n`t[INFO] Enabling permissions to execute command on remote server"
Enable-PSRemoting -Force | Out-Null
Set-Item wsman:\localhost\client\trustedhosts * -Force | Out-Null
Restart-Service WinRM | Out-Null

$RemoteHost = "10.102.6.183"
$RemoteSoftwareRepo = "\\$RemoteHost\Softwares"
$RemoteScriptFile = "RemoteScript.ps1"
$CodeBase = "eda/qa_automation.git"
$DllDirectory = "C:\DLL"
$username = "Administrator"
$password = "Password123!"

Write-Host "`n`t[INFO] Adding Network Shared Folder to local machine"
net use $RemoteSoftwareRepo $password /USER:$username /PERSISTENT:NO | Out-Null

$RemoteSoftwareRepoPath = $RemoteSoftwareRepo + "\"

#fetching credential for remote build server
$npassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username , $npassword

#Execute script on remote build server

Copy-Item -Path "$RemoteSoftwareRepoPath$RemoteScriptFile " -Destination .\ -Recurse -Force | Out-Null
Write-Host "`n`t[INFO] Invoking Script on Remote Build Server"
$return = Invoke-Command -ComputerName $RemoteHost -Credential $credentials -FilePath .\RemoteScript.ps1 -ArgumentList $CodeBase
Remove-Item $RemoteScriptFile -Force | Out-Null

if ($return -And ($return -ne $false))
{
    #Copy the DLL to local client machine
    Write-Host "`n`t[INFO] Copying DLL file to : $DllDirectory"
    $repo_name_git = $CodeBase -split "/"
    $repo_name = $repo_name_git[-1] -split "\."
    $RepoFolderName = $repo_name[0]
    $FileToCopy = "$RemoteSoftwareRepoPath"+"$RepoFolderName\PST_Exporter_Automation\PST_Exporter_Automation\bin\Debug\PST_Exporter_Automation.dll"
    New-Item -ItemType Directory -Force -Path $DllDirectory | Out-Null
    Copy-Item -Path $FileToCopy -Destination $DllDirectory -Recurse -Force | Out-Null

    Write-Host "`n`t[INFO] Setting up IRONPYTHONPATH variables....."
    SetEnvironmetVariable "IRONPYTHONPATH" $env:IRONPYTHONPATH $DllDirectory";"
}
else { Write-Host "`n`t[ERROR] Error in invoking remote script"}

Write-Host "`n`t[INFO] Removing Network Shared Folder from local machine`n"
net use $RemoteSoftwareRepo /DELETE | Out-Null