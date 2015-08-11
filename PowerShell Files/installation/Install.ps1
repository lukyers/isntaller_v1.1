#print logo
Invoke-Expression .\logo.ps1
    
function LogWrite
{
   Param ([string]$logstring)
   $timestamp = Get-Date -Format yyyy:MM:dd:HH:mm:ss:fff
   Add-content $Logfile -value "$timestamp - $logstring"
   Write-Host "`t`t$logstring`n"
}

function GetFromRemote($location,$content)
{
    Copy-Item -Path "$location$content" -Destination .\ -Recurse -Force
}

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

$Logfile = "installLog.txt"
$RemoteHost = "10.102.6.183"
$RemoteSoftwareRepo = "\\$RemoteHost\Softwares"
$username = "Administrator"
$password = "Password123!"
LogWrite "[INFO] Adding Network Shared Folder to local machine"
net use $RemoteSoftwareRepo $password /USER:$username /PERSISTENT:NO | Out-Null
$RemoteSoftwareRepoPath = $RemoteSoftwareRepo + "\"

$PathIpy = "C:\Program Files (x86)\IronPython 2.7\ipy.exe"
$PathIpybot = "C:\Program Files (x86)\IronPython 2.7\Scripts\ipybot.bat"
$PathPython = "C:\python27\python.exe"
$PathPythonWX = "C:\python27\Scripts\pywxrc.bat"
$PathPythonPip = "C:\python27\Scripts\pip.exe"

$FileIpy = "IronPython-2.7.5-32bit.msi"
$FolderIpybot = "robotframework-2.9a3"
$FolderElementTree = "elementtree-1.2.7-20070827-preview"
$FilePython = "python-2.7.10-32bit.msi"
$FilePythonPip = "get-pip.py"
$FileWxPython = "wxpython2.8-win32-unicode-2.8.12.1-py27.msi"

$PathToPython = "C:\python27"
$PathToPythonScripts = "C:\python27\Scripts"
$PathToIronPython = "C:\Program Files (x86)\IronPython 2.7"
$PathToIronPythonScripts = "C:\Program Files (x86)\IronPython 2.7\Scripts"

$PythonPipPackages = @()
                        
function InstallIronPython
{
    if (Test-Path -Path $PathIpy)
    {
        LogWrite "[INFO] Iron Python Already Exist"
        UpdateElementTree
        $status = InstallIronPythonRobot
        return $status
    }
    else
    {
        LogWrite "[INFO] Copying Installer - Iron Python "
        GetFromRemote $RemoteSoftwareRepoPath $FileIpy
        LogWrite "[INFO] Installing - Iron Python"
        Start-Process "msiexec.exe"-ArgumentList "/i $FileIpy /qn" -Wait
        Remove-Item $FileIpy -Force -Recurse

        if (Test-Path -Path $PathIpy)
        {
            LogWrite "[INFO] Installation Successful - Iron Python "            
            UpdateElementTree
            $status = InstallIronPythonRobot
            if ($status -eq $false) {return $status}
            
        }
        else
        {
            LogWrite "[ERROR] Error in Installation - Iron Python "
            return $false
        }
        
    }
}

function InstallIronPythonRobot
{
   if (Test-Path -Path $PathIpybot)
    {
        LogWrite "[INFO] Robot framework for Iron Python Already Exist"
    }
    else
    {
        LogWrite "[INFO] Copying Package - Robot framework for Iron Python"
        GetFromRemote $RemoteSoftwareRepoPath $FolderIpybot
        LogWrite "Installing  - Robot framework for Iron Python"
        cd $FolderIpybot
        Start-Process "$PathIpy" -ArgumentList ".\setup.py install" -Wait
        cd ..\
        Remove-Item $FolderIpybot -Force -Recurse

        if (Test-Path -Path $PathIpybot)
        {
            LogWrite "[INFO] Installation Successful - Robot framework for Iron Python"
        }
        else
        {
            LogWrite "[ERROR] Error in Installation - Robot framework for Iron Python"
            return $false
        }
    }
    
}

function UpdateElementTree
{
    LogWrite "[INFO] Copying Package - ElementTree "
    GetFromRemote $RemoteSoftwareRepoPath $FolderElementTree
    LogWrite "[INFO] Updating  - ElementTree Package for Iron Python"
    cd $FolderElementTree
    Start-Process "$PathIpy" -ArgumentList ".\setup.py install" -Wait
    cd ..\
    Remove-Item $FolderElementTree -Force -Recurse
}

function InstallPython
{
    if (Test-Path -Path $PathPython)
    {
        LogWrite "[INFO] Python Already Exist"
                
        $status = InstallWxPython
        if ($status -eq $false) {return $status}
        
        $status = InstallPythonPip
        if ($status -eq $false) {return $status}
        
        InstallPythonPipPackages
    }
    else
    {
        LogWrite "[INFO] Copying Installer - Python "
        GetFromRemote $RemoteSoftwareRepoPath $FilePython
        LogWrite "[INFO] Installing - Python"
        Start-Process "msiexec.exe"-ArgumentList "/i $FilePython /qn" -Wait
        Remove-Item $FilePython -Force -Recurse

        if (Test-Path -Path $PathPython)
        {
            LogWrite "[INFO] Installation Successful - Python "            
                    
            $status = InstallWxPython
            if ($status -eq $false) {return $status}
        
            $status = InstallPythonPip
            if ($status -eq $false) {return $status}
        
            InstallPythonPipPackages
            
        }
        else
        {
            LogWrite "[ERROR] Error in Installation - Python "
            return $false
        }
        
    }
}

function InstallWxPython
{
    if (Test-Path -Path $PathPythonWX)
    {
        LogWrite "[INFO] WxPython Already Exist"
    }
    else
    {
        LogWrite "[INFO] Copying Installer - WxPython"
        GetFromRemote $RemoteSoftwareRepoPath $FileWxPython
        LogWrite "[INFO] Installing  - WxPython"
        Start-Process "msiexec.exe"-ArgumentList "/i $FileWxPython /qn" -Wait
        Remove-Item $FileWxPython -Force -Recurse

        if (Test-Path -Path $PathPythonWX)
        {
            LogWrite "[INFO] Installation Successful - WxPython"
        }
        else
        {
            LogWrite "[ERROR] Error in Installation - WxPython"
            return $false
        }
    }
}

function InstallPythonPip
{
    if (Test-Path -Path $PathPythonPip)
    {
        LogWrite "[INFO] PythonPip Already Exist"
    }
    else
    {
        LogWrite "[INFO] Copying Script - PythonPip"
        GetFromRemote $RemoteSoftwareRepoPath $FilePythonPip
        LogWrite "[INFO] Installing  - PythonPip"
        Start-Process "$PathPython"-ArgumentList "$FilePythonPip" -Wait
        Remove-Item $FilePythonPip -Force -Recurse

        if (Test-Path -Path $PathPythonPip)
        {
            LogWrite "[INFO] Installation Successful - PythonPip"
        }
        else
        {
            LogWrite "[ERROR] Error in Installation - PythonPip"
            return $false
        }
    }
}

function InstallPythonPipPackages
{    
    foreach ($package in $PythonPipPackages)
    {
        LogWrite "[INFO] Installing - Python Package - $package"
        Start-Process "$PathPythonPip"-ArgumentList "install $package" -Wait
        LogWrite "[INFO] Installation Successful - Python Package - $package"
    }    
}

#Installing the .NET framework if not installed already
LogWrite "[INFO] Installing Pre-Requisites"
Import-Module ServerManager
Add-WindowsFeature AS-NET-Framework | Out-Null

#Installing Iron Python and Robot Framework

Write-Host "`n******** Installing Iron Python and Robot Framework **************`n"
$status = InstallIronPython
if ($status -eq $false)
{
    LogWrite "[ERROR] Error in Installation of Iron Python or Robot framework."
}
else
{
    SetEnvironmetVariable "PATH" $env:PATH $PathToIronPython";",$PathToIronPythonScripts";"
}

Write-Host "`n*******************************************************************`n"

#Installing Python, Robot, External Libraries and RIDE
Write-Host "`n****** Installing Python, Robot, External Libraries and RIDE ******`n"
$status = InstallPython
if ($status -eq $false)
{
    LogWrite "[ERROR] Error in Installation of Python or Related Libraries."
}
else
{
    SetEnvironmetVariable "PATH" $env:PATH $PathToPython";",$PathToPythonScripts";"
}

LogWrite "[INFO] Removing Network Shared Folder from local machine`n"
net use $RemoteSoftwareRepo /DELETE | Out-Null

Write-Host "`n*******************************************************************`n"
Write-Host "`nOutput Log File : $pwd\$Logfile`n"
Write-Host "`n*******************************************************************`n"