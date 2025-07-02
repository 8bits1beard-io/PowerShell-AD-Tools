<#
.SYNOPSIS
Moves Active Directory device objects to a specified Organizational Unit.

.DESCRIPTION
This script reads a list of device Distinguished Names from a file and moves each device
to a target OU within the Active Directory domain. All operations are logged with
timestamps and detailed status information. All parameters are mandatory to ensure
explicit configuration by the user.

.PARAMETER InputFile
Path to the text file containing device Distinguished Names (one per line).

.PARAMETER TargetOU
The Distinguished Name of the target Organizational Unit.

.PARAMETER LogFile
Path to the log file where operations will be recorded.

.PARAMETER ADServer
The Active Directory server to connect to.

.EXAMPLE
.\Move-ADDeviceToOU.ps1 -InputFile "C:\devices.txt" -TargetOU "OU=Kiosk,OU=Development,DC=contoso,DC=com" -LogFile "C:\Logs\DeviceMove.log" -ADServer "dc01.contoso.com"

.EXAMPLE
.\Move-ADDeviceToOU.ps1 -InputFile "C:\input\computers.txt" -TargetOU "OU=Workstations,DC=domain,DC=local" -LogFile "C:\Logs\$(Get-Date -Format 'yyyyMMdd')_DeviceMove.log" -ADServer "domain.local"

.INPUTS
Text file containing Distinguished Names of Active Directory devices (one per line).

.OUTPUTS
PSCustomObject containing TotalProcessed, Successful, Failed, and LogFile properties.

.NOTES
Author: 8bits1beard
Date: 2025-07-02
Version: v1.0.0
Source: ../PoSh-Best-Practice/

.LINK
../PoSh-Best-Practice/
#>

[CmdletBinding()]
param(
    # Path to input file containing device Distinguished Names
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({Test-Path $_ -PathType Leaf})]
    [string]$InputFile,
    
    # Target Organizational Unit Distinguished Name
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [string]$TargetOU,
    
    # Path for log file output
    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [string]$LogFile,
    
    # Active Directory server to connect to
    [Parameter(Mandatory = $true, Position = 3)]
    [ValidateNotNullOrEmpty()]
    [string]$ADServer
)

# Import the Active Directory module if not already loaded
try {
    Import-Module ActiveDirectory -ErrorAction Stop
    Write-Information "Successfully imported Active Directory module" -InformationAction Continue
}
catch {
    Write-Error "Failed to import Active Directory module: $_"
    exit 1
}

# Function to write structured log entries with timestamps and levels
function Write-LogEntry {
    <#
    .SYNOPSIS
    Writes structured log entries to file and console streams.
    
    .DESCRIPTION
    Internal function that creates timestamped log entries with specified levels
    and writes them to both log file and appropriate PowerShell output streams.
    
    .PARAMETER Message
    The message content to log.
    
    .PARAMETER Level
    The severity level of the log entry (INFO, SUCCESS, WARNING, ERROR).
    
    .PARAMETER LogPath
    Full path to the log file where entries will be written.
    #>
    [CmdletBinding()]
    param(
        # Message content for the log entry
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        # Severity level for categorizing log entries
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO',
        
        # Full path to the target log file
        [Parameter(Mandatory = $true)]
        [string]$LogPath
    )
    
    # Create timestamp in ISO 8601 format for consistent log formatting
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffK"
    
    # Format log entry with timestamp, level, and message
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to log file and console based on level
    try {
        # Append formatted entry to log file
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction Stop
        
        # Also write to appropriate PowerShell output stream
        switch ($Level) {
            'INFO' { Write-Information $Message -InformationAction Continue }
            'SUCCESS' { Write-Information $Message -InformationAction Continue }
            'WARNING' { Write-Warning $Message }
            'ERROR' { Write-Error $Message }
        }
    }
    catch {
        Write-Error "Failed to write to log file: $_"
    }
}

# Ensure log directory exists before attempting to write
$logDir = Split-Path $LogFile -Parent
if (-not (Test-Path $logDir)) {
    try {
        # Create log directory structure if it doesn't exist
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
        Write-Information "Created log directory: $logDir" -InformationAction Continue
    }
    catch {
        Write-Error "Failed to create log directory '$logDir': $_"
        exit 1
    }
}

# Initialize log file with session header and configuration details
$sessionStart = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-LogEntry -Message "========== Move-ADDeviceToOU Session Started: $sessionStart ==========" -Level 'INFO' -LogPath $LogFile
Write-LogEntry -Message "Input File: $InputFile" -Level 'INFO' -LogPath $LogFile
Write-LogEntry -Message "Target OU: $TargetOU" -Level 'INFO' -LogPath $LogFile
Write-LogEntry -Message "AD Server: $ADServer" -Level 'INFO' -LogPath $LogFile

# Load device Distinguished Names from input file
try {
    # Read all lines from input file containing device DNs
    $deviceDNs = Get-Content -Path $InputFile -ErrorAction Stop
    
    # Validate that input file contains data
    if (-not $deviceDNs -or $deviceDNs.Count -eq 0) {
        Write-LogEntry -Message "Input file '$InputFile' is empty" -Level 'ERROR' -LogPath $LogFile
        exit 1
    }
    
    Write-LogEntry -Message "Successfully loaded $($deviceDNs.Count) device DN(s) from input file" -Level 'INFO' -LogPath $LogFile
}
catch {
    Write-LogEntry -Message "Failed to read input file '$InputFile': $_" -Level 'ERROR' -LogPath $LogFile
    exit 1
}

# Initialize counters for operation summary tracking
$successCount = 0
$errorCount = 0
$totalDevices = $deviceDNs.Count

Write-LogEntry -Message "Beginning move operations for $totalDevices device(s)" -Level 'INFO' -LogPath $LogFile

# Process each device Distinguished Name from the input file
foreach ($deviceDN in $deviceDNs) {
    # Skip empty lines in input file to avoid processing errors
    if ([string]::IsNullOrWhiteSpace($deviceDN)) {
        Write-LogEntry -Message "Skipping empty line in input file" -Level 'WARNING' -LogPath $LogFile
        continue
    }
    
    Write-LogEntry -Message "Processing device: $deviceDN" -Level 'INFO' -LogPath $LogFile
    
    try {
        # Verify the device exists in Active Directory before attempting move
        $device = Get-ADObject -Identity $deviceDN -Server $ADServer -ErrorAction Stop
        Write-LogEntry -Message "Verified device exists: $($device.Name)" -Level 'INFO' -LogPath $LogFile
        
        # Move the device to the specified target OU
        Move-ADObject -Identity $deviceDN -Server $ADServer -TargetPath $TargetOU -ErrorAction Stop
        
        # Log successful move operation
        Write-LogEntry -Message "Successfully moved device '$deviceDN' to target OU '$TargetOU'" -Level 'SUCCESS' -LogPath $LogFile
        $successCount++
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        # Handle specific case where device doesn't exist in AD
        Write-LogEntry -Message "Device not found: $deviceDN" -Level 'ERROR' -LogPath $LogFile
        $errorCount++
    }
    catch [System.UnauthorizedAccessException] {
        # Handle permission-related errors during move operation
        Write-LogEntry -Message "Access denied when moving device '$deviceDN': $($_.Exception.Message)" -Level 'ERROR' -LogPath $LogFile
        $errorCount++
    }
    catch {
        # Handle all other unexpected errors during move operation
        Write-LogEntry -Message "Failed to move device '$deviceDN': $($_.Exception.Message)" -Level 'ERROR' -LogPath $LogFile
        $errorCount++
    }
}

# Log session summary with operation statistics
$sessionEnd = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-LogEntry -Message "========== Move-ADDeviceToOU Session Completed: $sessionEnd ==========" -Level 'INFO' -LogPath $LogFile
Write-LogEntry -Message "Total devices processed: $totalDevices" -Level 'INFO' -LogPath $LogFile
Write-LogEntry -Message "Successful moves: $successCount" -Level 'SUCCESS' -LogPath $LogFile
Write-LogEntry -Message "Failed moves: $errorCount" -Level 'INFO' -LogPath $LogFile

# Return summary object with operation results
[PSCustomObject]@{
    TotalProcessed = $totalDevices
    Successful = $successCount
    Failed = $errorCount
    LogFile = $LogFile
}