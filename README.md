# PS-BuildTools
Build tools for PowerShell projects. This repository makes use of the following modules to validate, compile and deploy your PowerShell project:
  - [Pester](https://github.com/pester/Pester)
  - [PSScriptAanalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
  - [psake](https://github.com/psake/psake)
  - [PSDeploy (not currently used but may be in future)](https://github.com/RamblingCookieMonster/PSDeploy)

#Table of Contents
  * [Setup](#setup)
  * [Usage](#usage)
  * [Components](#components)
  * [Notes](#notes)


#Setup
Clone the repository into an empty directory. The build tools should sit at the root of your project, and all scripts, unit tests, and other files should exist in subdirectories beneath it.
```powershell
C:.
│   build.ps1
│   gitrepos.txt
│   psakeBuild.ps1
│   README.md
│   requirements.psd1
│
├───MyClonedProject
│   │   README.md
|   |   .gitignore
│   │   RunScript.ps1
│   │
│   ├───helpers
│   │       SMTPOptions.ps1
|   |       classes.ps1
│   │
│   └───tests
│           SMTPOptions.Tests.ps1
|           classes.Tests.ps1
```

Once the build tools repository is cloned, feel free to edit the `githubrepos.txt` file and enter the name of any repositories that you need to pull from as part of your project. You can also create a `deploy` task in the `psakebuild.ps1` file if you already know where the code should be deployed to once unit tests, analysis, and compiling complete successfully. Otherwise, you are all set!

#Usage
The build tools are all called up via the `build.ps1` script. Depending on what values are passed to the `-Task` parameter certain actions are performed on the project directory. For example, to clone the repositories listed in `gitrepos.txt`, call `build.ps1` from the commandline and pass 'setup' to the `-Task` parameter.
```powershell
C:\> Get-Content gitrepos.txt
[username]:testrepo.git
C:\> .\build.ps1 -Task setup
psake version 4.6.0
Copyright (c) 2010-2014 James Kovacs & Contributors

-------------------------[setup]-------------------------
Cloning into '.'...
remote: Counting objects: 60, done.
remote: Compressing objects: 100% (4/4), done.
remote: Total 60 (delta 0), reused 0 (delta 0), pack-reused 55R
Receiving objects: 100% (60/60), 14.74 KiB | 0 bytes/s, done.
Resolving deltas: 100% (21/21), done.
```

To run Pester unit tests, call `.\build.ps1` and pass 'test' to the `-Task` parameter.
```powershell
C:\> .\build.ps1 -Task test
psake version 4.6.0
Copyright (c) 2010-2014 James Kovacs & Contributors
-------------------------[test]---------------------------
Describing 'my new project'
  Context 'when it performs this action'
    [+] Must do 'x' and not 'y'
    [+] Must not self-combust
```

To see the rest of the tasks that can be run refer to the `psakebuild.ps1` entry in the [Components](#components) section.

##Components
###build.ps1
The entry point to the build process. `Build.ps1` first checks if the above modules are installed before calling Invoke-psake. If any are not installed it will stop and request that you install the missing modules from a trusted source.
If all the required modules are installed, it then calls Invoke-psake and targets the task provided to the `-Task` parameter.

###psakebuild.ps1
The script that manages all of the tasks over the lifecycle of the project. Tasks can be specified by running `.\build.ps1 -Task [Taskname]`. If you want to run `psake` without using the build script you can run `Invoke-psake -buildFile .\psakeBuild.ps1 -taskList [Taskname]`. The following tasks are included in the script:
####default
Runs both `Analyze` and `Test` tasks.
####setup
Clones the repositories listed in `gitrepos.txt` into their own subfolders in the project directory.
####Analyze
Runs PSScriptAnalyzer on all scripts in the project directory (excluding the root folder where the build tools are stored). If any rules trigger a Warning or Error, the build process fails.
####Test
Runs all Pester unit tests in the project directory. If any Pester tests fail, the build process fails. To run `Pester` tests on a specific file, run `Invoke-Pester
####Compile
Runs `Analyze` and `Test` tasks first. Provided both pass, it then flattens the script files in each local repository and moves them to a new directed called `\deploy`.

###gitrepos.txt
A text file containing the list of required repositories for your project. Each repo should be on its own line and should only contain the username and repository. It should look like the following:
```
# Text file that should contain the urls for required repositories.
[username]/myproject.git
[username]/repository_no2.git
```

###requirements.psd1
Currently unused, but provides the ability (in future) to use PSDepends to install dependencies much like a Ruby gemfile.

#Notes
  * Requires version 5.0 of PowerShell or greater. Not tested on *nix systems, although it's something I would love to test eventually.
