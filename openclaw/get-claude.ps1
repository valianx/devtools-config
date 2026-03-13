Get-WmiObject Win32_Process | Where-Object { $_.Name -like '*claude*' } | ForEach-Object {
    Write-Host "PID: $($_.ProcessId)"
    Write-Host "RAM: $([math]::Round($_.WorkingSetSize/1MB)) MB"
    Write-Host "CMD: $($_.CommandLine)"
    Write-Host "---"
}
