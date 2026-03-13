$processList = @(43992, 26864, 63580, 42540)
foreach ($procId in $processList) {
    try {
        $proc = Get-Process -Id $procId -ErrorAction Stop
        Write-Host "PID: $procId | Title: '$($proc.MainWindowTitle)' | RAM: $([math]::Round($proc.WorkingSet/1MB))MB"
    } catch {
        Write-Host "PID: $procId | not found"
    }
}
