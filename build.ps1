[CmdletBinding()]
Param([ValidateSet("Test","Analyze","Setup","Compile","Clean")]
    [string]$Task = 'default'
)

[array]$modules = @(
    "Pester",
    "psake",
    "PSDeploy",
    "PSScriptAnalyzer"
)

foreach ($moduleName in $modules) {
    try {
        Import-Module -Name $moduleName -errorAction Stop
        Write-Verbose "$moduleName Loaded"
    }
    Catch {
        Write-Warning "$moduleName module not available. Please download and install this module from a trusted source."
    }
}

Invoke-psake -buildFile "$PSScriptRoot\psakebuild.ps1" -taskList $Task
