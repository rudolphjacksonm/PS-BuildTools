properties {
    $scriptRoot = "$PSScriptRoot"
}

# Pretty formatting
FormatTaskName (("-"*25) + "[{0}]" + ("-"*25))

task default -depends Analyze, Test

task setup {
    $gitRepos = Get-Content $scriptRoot\gitrepos.txt

    # Remove first line if it contains hash sign
    if ($gitRepos[0] -match '#') {
        $gitRepos = $gitRepos[1..($gitRepos.length-1)]

    }

    $gitRepos | ForEach-Object {
        $repo = $_
        $folderPath = $repo.split('/')[1].split('.')[0]

        New-Item -ItemType Directory -Name $folderPath | Out-Null
        Push-Location $folderPath
        
        $cmd = 'git@github.com:' + $repo
        git clone $cmd .

        # Return to $scriptRoot
        Pop-Location
    }
}

task Analyze {
    $scriptFolders = Get-ChildItem $scriptRoot | Where-Object {$_.psiscontainer -eq $true}
    $saResults = @()
    $scriptFolders | ForEach-Object {
        $saResults = Invoke-ScriptAnalyzer -Path $_.FullName -Severity @('Error', 'Warning') -Recurse -Verbose:$false -ExcludeRule @('PSUseSingularNouns','PSUseApprovedVerbs','PSAvoidGlobalVars')
        if ($saResults) {
            $saResults | Format-Table  
            Write-Error -Message 'One or more Script Analyzer errors were found. Build cannot continue!'        
        }
    }
}

task Test {
    $testResults = Invoke-Pester -Path $scriptRoot -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task Clean {
    $folders = Get-ChildItem | Where-Object {$_.psiscontainer -eq $True}
    $folders | Foreach-Object {Remove-Item $_ -Recurse -Force -Confirm:$False}

}

task Compile -depends Analyze, Test{
    # Create deploy folder if not present
    if (!(Test-Path -Path $scriptRoot\"deploy")) {
        New-Item -Name 'deploy' -ItemType Directory | Out-Null

    }

    $repos = Get-ChildItem | Where-Object {($_.psiscontainer -eq $True) -and ($_.Name -notmatch 'deploy')}
    write-output "Will compile the following repositories:"
    Write-Output $repos.Name | ForEach-Object {" o $_"} | Format-List 
    $repos | ForEach-Object {
        # Switch location to sub directory
        Write-Output "Compiling $_..."
        Push-Location $_

        # Run compile-project
        Compile-Project -mainScriptFile $(Get-ChildItem *.ps1)

        # Return to working directory
        Pop-Location

    }
}

task Deploy -depends Analyze, Test {
    # Add your code to deploy your project here.
    # Invoke-PSDeploy
}

###
# helper functions
function Compile-Project {
    [CmdletBinding()]
    Param (
        $mainScriptFile
    )

    # Get Scripts from current (working) project directory

	$parameters = Get-ScriptParameters -FullName $mainScriptFile.Fullname

	$scriptBody = Get-ScriptBody -FullName $mainScriptFile.Fullname

	$flatScriptFile = @()
	$flatScriptFile += $parameters 
	$flatScriptFile += ' ' 
	$flatScriptFile += $scriptBody

	# Output the final script
	$flatScriptOutput = "$scriptRoot\deploy\$($mainScriptFile.Name)" -replace '(.*).ps1','$1_flatScript.ps1'
	$flatScriptFile | Out-File $flatScriptOutput

}

<# Below are 'helper' functions that handle flattening of files in to one
## runscript file. Runscript files are used for N-Central AMPs (Automation
## Policies)
## 
## Below written by Stephen Testino
#>

function Get-ScriptParameters {
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $FullName
    )

    $paramEnd = Get-Content $FullName | Select-String '^[)]$' | Select-Object -ExpandProperty LineNumber

    $parameters = (Get-Content $FullName)[0..$paramEnd] -match '(^(?!.*=\$)).*[$]' -replace '[[].*[]]','' -replace ',',''

    $parameters
}

function Get-ScriptBody {
    param(
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $FullName
    )

    $paramEnd = Get-Content $FullName | Select-String '^[)]$' | Select-Object -ExpandProperty LineNumber

    $scriptEnd = Get-Content $FullName | Measure-Object | Select-Object -ExpandProperty Count

    $scriptBody = (Get-Content $FullName)[$paramEnd..$scriptEnd] 

    $script = @()
    $scriptBody |  ForEach-Object { 
        if($_ -notmatch '[.]\s[.]') {
            $script += $_

        }
        else {
            $nestedScript = Get-Content ($_ -replace '[.] [.]\\','.\').TrimStart()
            $nestedScript | ForEach-Object {
                if ($_ -notmatch '[.]\s[.]') {
                    $script += $_

                }
                else {
                    $nestedScript = Get-Content ($_ -replace '[.] [.]\\','.\').TrimStart()

                    $script += $nestedScript

                }
            }
        }
    }

    $script
}
