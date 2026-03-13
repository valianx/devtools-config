Get-WmiObject Win32_Process | Where-Object { $_.Name -like '*claude*' } | ForEach-Object {
    $claudeProc = $_
    $parent = Get-WmiObject Win32_Process | Where-Object { $_.ProcessId -eq $claudeProc.ParentProcessId }
    $grandparent = if ($parent) { Get-WmiObject Win32_Process | Where-Object { $_.ProcessId -eq $parent.ParentProcessId } } else { $null }
    Write-Host "=== Claude PID: $($claudeProc.ProcessId) | RAM: $([math]::Round($claudeProc.WorkingSetSize/1MB))MB ==="
    Write-Host "  Parent:      PID=$($claudeProc.ParentProcessId) Name=$($parent.Name) CMD=$($parent.CommandLine)"
    Write-Host "  Grandparent: PID=$($parent.ParentProcessId) Name=$($grandparent.Name) CMD=$($grandparent.CommandLine)"
    Write-Host ""
}
