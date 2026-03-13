$processList = @(43992, 26864, 63580, 42540)
foreach ($procId in $processList) {
    try {
        $wmi = Get-WmiObject Win32_Process -Filter "ProcessId = $procId"
        # Get working directory via handle
        $proc = [System.Diagnostics.Process]::GetProcessById($procId)
        # Try to read current directory from proc env
        $ram = [math]::Round($wmi.WorkingSetSize/1MB)
        Write-Host "PID: $procId | RAM: ${ram}MB"
        # Check child processes for clues
        $children = Get-WmiObject Win32_Process | Where-Object { $_.ParentProcessId -eq $procId }
        foreach ($child in $children) {
            Write-Host "  Child: PID=$($child.ProcessId) Name=$($child.Name) CMD=$($child.CommandLine)"
        }
    } catch {
        Write-Host "PID: $procId | Error: $_"
    }
}
