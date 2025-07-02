# PowerShell-AD-Tools

A collection of PowerShell scripts for Active Directory administration and management tasks. These scripts follow PowerShell best practices and include comprehensive logging, error handling, and parameter validation.

## Table of Contents

- [Scripts](#scripts)
  - [Move-ADDeviceToOU.ps1](#move-addevicetoups1)
  - [GPO Reporting Scripts](#gpo-reporting-scripts)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Scripts

### Move-ADDeviceToOU.ps1

**Purpose:** Moves Active Directory device objects to a specified Organizational Unit in bulk.

**Description:** This script reads a list of device Distinguished Names from a text file and moves each device to a target OU within the Active Directory domain. All operations are logged with timestamps and detailed status information, including success/failure counts and specific error handling for common AD exceptions.

**Key Features:**
- Bulk device movement operations
- Comprehensive logging with ISO 8601 timestamps
- Structured error handling for AD-specific exceptions
- Input validation and parameter verification
- Operation summary reporting
- Support for custom AD servers

**Usage:**
```powershell
.\Move-ADDeviceToOU.ps1 -InputFile "C:\devices.txt" -TargetOU "OU=Kiosk,OU=Development,DC=contoso,DC=com" -LogFile "C:\Logs\move.log" -ADServer "dc01.contoso.com"
```

**Parameters:**
- `InputFile` (Mandatory): Path to text file containing device Distinguished Names (one per line)
- `TargetOU` (Mandatory): Distinguished Name of the target Organizational Unit
- `LogFile` (Mandatory): Path for detailed operation log file
- `ADServer` (Mandatory): Active Directory server to connect to

---

### General Guidelines

- All scripts follow PowerShell best practices with comprehensive parameter validation
- Scripts require explicit parameter values (no default values for critical settings)
- Detailed logging is implemented across all scripts for audit and troubleshooting
- Error handling includes specific exceptions for common Active Directory scenarios

### Input File Format

For scripts requiring input files (like `Move-ADDeviceToOU.ps1`), use the following format:

```text
CN=DEVICE001,OU=Computers,DC=contoso,DC=com
CN=DEVICE002,OU=Computers,DC=contoso,DC=com
CN=DEVICE003,OU=Computers,DC=contoso,DC=com
```

### Log File Output

All scripts generate structured log files with the following format:

```text
[2025-07-02T10:15:30.123-05:00] [INFO] Session started
[2025-07-02T10:15:30.456-05:00] [SUCCESS] Device moved successfully
[2025-07-02T10:15:30.789-05:00] [ERROR] Device not found: CN=DEVICE001...
```

## Contributing

1. Follow the established PowerShell best practices and style guidelines
2. Include comprehensive inline comments and help documentation
3. Implement proper error handling and parameter validation
4. Add appropriate examples and usage documentation
5. Test scripts thoroughly before submitting pull requests

### Code Standards

- Use approved PowerShell verbs for function names
- Include detailed comment-based help with .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE, .NOTES, and .LINK sections
- Implement structured logging where appropriate
- Follow consistent parameter naming conventions
- Include comprehensive inline comments explaining purpose and logic
- Use [CmdletBinding()] and proper parameter validation attributes
- Refer to [PowerShell Best Practices](../PoSh-Best-Practice/) and [PowerShell Style Guide](../PoSh-style/) documentation

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Author:** 8bits1beard  
**Repository:** [PowerShell-AD-Tools](https://github.com/yourusername/PowerShell-AD-Tools)  
**Last Updated:** July 2, 2025