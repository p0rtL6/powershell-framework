$scriptTitle = ''
$scriptFileName = ''
$scriptDesc = ''
$version = ''

$commands = @{}

# !!! Everything below this point does not need to be changed !!!

function Get-FlatArguments {
    param (
        [string]$CommandName
    )

    $flatArguments = @{}

    if ($commands[$commandName].ContainsKey('Arguments')) {
        foreach ($argument in $commands[$commandName]['Arguments'].GetEnumerator()) {
            if ($argument.Value.ContainsKey('Group') -and $argument.Value['Group']) {
                $group = $argument.Value
                if ($group.ContainsKey('Arguments')) {
                    foreach ($groupArgument in $group['Arguments'].GetEnumerator()) {
                        $flatArguments[$groupArgument.Key] = $groupArgument.Value
                    }
                }
            }
            else {
                $flatArguments[$argument.Key] = $argument.Value
            }
        }
    }

    return $flatArguments
}

function Show-Argument {
    param (
        [System.Collections.DictionaryEntry]$Argument,
        [int]$Padding
    )

    $argumentOutputString = "      --$("$($argument.Key) <$($argument.Value['Type'])>".PadRight($padding)) $($argument.Value['Description'])"
    if ($argument.Value.ContainsKey('Default')) {
        if ($argument.Value['Default'] -is [System.Management.Automation.ScriptBlock]) {
            if ($argument.Value.ContainsKey('DefaultDescription')) {
                $argumentOutputString = $argumentOutputString + " (default: $($argument.Value['DefaultDescription']))"
            }
            else {
                $argumentOutputString = $argumentOutputString + " (default: <not specified>)"
            }
        }
        else {
            $argumentOutputString = $argumentOutputString + " (default: $($argument.Value['Default']))"
        }
    }

    Write-Host $argumentOutputString
}

function Show-HelpMenu {
    param (
        [Parameter(Mandatory = $False)]
        [string]$SelectedCommand
    )

    Write-Host "=== $scriptTitle ==="
    Write-Host $scriptDesc
    Write-Host "Version: $version"
    Write-Host ''
    Write-Host "Usage: $scriptFileName [COMMAND] [ARGUMENTS] [FLAGS]"
    Write-Host ''

    $helpMenuCommandPadding = 0
    $helpMenuArgsAndFlagsPadding = 0
    
    foreach ($commandName in $commands.Keys) {
        if ($commandName.Length -gt $helpMenuCommandPadding) {
            $helpMenuCommandPadding = $commandName.Length
        }

        $flatArguments = Get-FlatArguments -CommandName $commandName
    
        foreach ($argument in $flatArguments.GetEnumerator()) {
            $fullArgument = $argument.Key
            if ($argument.Value.ContainsKey('Type')) {
                $fullArgument = "$fullArgument <$($argument.Value['Type'])>"
            }

            if ($fullArgument.Length -gt $helpMenuArgsAndFlagsPadding) {
                $helpMenuArgsAndFlagsPadding = $fullArgument.Length
            }
        }
    
        foreach ($flagName in $commands[$commandName]['Flags'].Keys) {
            if ($flagName.Length -gt $helpMenuArgsAndFlagsPadding) {
                $helpMenuArgsAndFlagsPadding = $flagName.Length
            }
        }
    }
    
    $helpMenuCommandPadding += 2
    $helpMenuArgsAndFlagsPadding += 2

    if (-not $selectedCommand) {
        Write-Host '[COMMANDS]'
    }

    $sortedCommands = $commands.GetEnumerator() | Sort-Object { $_.Value['Order'] }
    foreach ($command in $sortedCommands) {

        if ($selectedCommand -and ($selectedCommand -ne ($command.Key))) {
            continue
        }

        Write-Host "  $($command.Key.PadRight($helpMenuCommandPadding)) $($command.Value['Description'])"
        Write-Host ''

        if ($command.Value.ContainsKey('Arguments')) {
            Write-Host '  [ARGUMENTS]'

            $arguments = $command.Value['Arguments']
            $sortedArguments = $arguments.GetEnumerator() | Sort-Object { $_.Value['Order'] }

            $lastItemWasGroup = $false

            foreach ($argument in $sortedArguments) {
                if ($argument.Value.ContainsKey('Group') -and $argument.Value['Group']) {
                    $lastItemWasGroup = $true
                    Write-Host ''

                    $group = $argument.Value

                    if ($group.ContainsKey('Arguments')) {
                        $groupTitleString = "    {$($argument.Key)}"
                        if ($group.ContainsKey('Required') -and $group['Required']) {
                            $groupTitleString += ' (Required)'
                        }
                        if ($group.ContainsKey('Exclusive') -and $group['Exclusive']) {
                            $groupTitleString += ' (Exclusive)'
                        }
                        Write-Host $groupTitleString

                        $groupArguments = $group['Arguments'].GetEnumerator() | Sort-Object { $_.Value['Order'] }
                        foreach ($groupArgument in $groupArguments) {
                            Show-Argument -Argument $groupArgument -Padding $helpMenuArgsAndFlagsPadding
                        }
                    }
                }
                else {
                    if ($lastItemWasGroup) {
                        Write-Host ''
                    }
                    Show-Argument -Argument $argument -Padding $helpMenuArgsAndFlagsPadding + 2
                }
            }
            Write-Host ''
        }

        if ($command.Value.ContainsKey('Flags')) {
            Write-Host '  [FLAGS]'
            $flags = $command.Value['Flags'].GetEnumerator() | Sort-Object { $_.Value['Order'] }
            foreach ($flagName in $flags.Key) {
                $flagValue = $command.Value['Flags'][$flagName]
                Write-Host "    -$($flagName.PadRight($helpMenuArgsAndFlagsPadding + 1)) $($flagValue['Description'])"
            }
            Write-Host ''
        }
    }
    Write-Host ''
}

if ($Args.Count -eq 0 -or $Args[0] -eq '-h' -or $Args[0] -eq '--help') {
    Show-HelpMenu
    exit 0
}

if (-not $commands.ContainsKey($Args[0])) {
    throw 'Invalid command selected (Use -h or --help for help)'
}

$selectedCommand = $null
$flattenedCommandArguments = $null
$selectedArguments = @{}
$selectedFlags = @{}

for ($i = 0; $i -lt $Args.Count; $i++) {
    if ($Args[$i] -eq '-h' -or $Args[$i] -eq '--help') {
        if ($selectedCommand) {
            Show-HelpMenu -SelectedCommand $selectedCommand
        }
        else {
            Show-HelpMenu
        }
        exit 0
    }
    elseif ($i -eq 0) {
        $selectedCommand = $Args[0]
        $flattenedCommandArguments = Get-FlatArguments -CommandName $Args[0]
    }
    elseif ($Args[$i].StartsWith('--')) {
        $arg = $Args[$i].Substring(2)
        $argParts = $arg -split '='
        $keyword = $argParts[0]
        $value = $null

        if (-not $flattenedCommandArguments.ContainsKey($keyword)) {
            throw 'Invalid argument (Use -h or --help for help)'
        }

        if ($argParts.Count -eq 2) {
            $value = $argParts[1]
        }
        elseif ($argParts.Count -gt 2 -or $argParts -lt 1) {
            throw 'Malformed argument (Use -h or --help for help)'
        }

        if (-not $value) {
            $i++
            $value = $Args[$i]
        }

        if (-not $value) {
            throw "No value provided for argument `"$keyword`" (Use -h or --help for help)"
        }

        $argumentTypeString = $flattenedCommandArguments[$keyword]['Type']

        $targetType = [System.Object]
        $parser = { param([System.Object]$Value) return $value }

        if ($flattenedCommandArguments[$keyword].ContainsKey('CustomType')) {
            if ($flattenedCommandArguments[$keyword].ContainsKey('ReturnType')) {
                $targetType = $flattenedCommandArguments[$keyword]['CustomType']['ReturnType']
            }

            $parser = $flattenedCommandArguments[$keyword]['CustomType']['Parser']
        }
        else {
            switch ($argumentTypeString) {
                'STRING' {
                    $targetType = [string]
                    $parser = { param([System.Object]$Value) return $value -as [string] }
                }
                'NUMBER' {
                    $targetType = [int32]
                    $parser = { param([System.Object]$Value) return $value -as [int32] }
                }
                'BOOLEAN' {
                    $targetType = [bool]
                    $parser = { param([System.Object]$Value) return $value -as [bool] }
                }
                'PATH' {
                    $targetType = [string]
                    $parser = {
                        param(
                            [System.Object]$Value
                        )

                        if ((-not ($value -match '\\')) -and (-not ($value -match '/'))) {
                            $value = Join-Path -Path (Get-Location) -ChildPath $value
                        }
            
                        $parentDir = Split-Path -Path $value -Parent
            
                        if ((-not $parentDir) -or ($parentDir -and (Test-Path -Path $parentDir))) {
                            return (Resolve-Path -Path $value).Path -as [string]
                        }
                    }
                }
            }
        }

        $targetArrayType = $targetType.MakeArrayType()
        $shouldBeList = $flattenedCommandArguments[$keyword].ContainsKey('List') -and $flattenedCommandArguments[$keyword]['List']

        $parsedValue = $null

        if ($value -is [System.Object[]]) {
            if (-not $shouldBeList) {
                throw "Argument value for `"$keyword`" cannot be a list (Use -h or --help for help)"
            }

            for ($j = 0; $j -lt $value.Length; $j++) {
                $parsedListItem = & $parser -Value $value[$j]
                if ($null -ne $parsedListItem) {
                    $value[$j] = $parsedListItem
                }
                else {
                    throw "Argument value `"$($value[$j])`" is not a valid $($argumentTypeString.ToLower()) (Use -h or --help for help)"
                }
            }

            $parsedValue = $value -as $targetArrayType
        }
        else {
            if ($shouldBeList) {
                $parsedValue = @(& $parser -Value $value) -as $targetArrayType
            }
            else {
                $parsedValue = & $parser -Value $value
            }
        }
        
        if ($null -eq $parsedValue) {
            throw "Argument value `"$value`" for `"$keyword`" is not a valid $($argumentTypeString.ToLower()) list (Use -h or --help for help)"
        }
        
        $selectedArguments[$keyword] = $parsedValue
    }
    elseif ($Args[$i].StartsWith('-')) {
        $flag = $Args[$i].Substring(1)
        if (-not $commands[$selectedCommand]['Flags'].ContainsKey($flag)) {
            throw 'Invalid flag (Use -h or --help for help)'
        }

        $selectedFlags[$flag] = $True
    }
    else {
        throw 'Invalid input (Use -h or --help for help)'
    }
}

foreach ($flagName in $commands[$selectedCommand]['Flags'].Keys) {
    if (-not $selectedFlags.ContainsKey($flagName)) {
        $selectedFlags[$flagName] = $False
    }
}

$defaultArguments = @{}
foreach ($argument in $flattenedCommandArguments.GetEnumerator()) {
    if ($argument.Value.ContainsKey('Default')) {
        if ($argument.Value['Default'] -is [System.Management.Automation.ScriptBlock]) {
            $defaultArguments[$argument.Key] = & $argument.Value['Default'] -Arguments $selectedArguments -Flags $selectedFlags
        }
        else {
            $defaultArguments[$argument.Key] = $argument.Value['Default']
        }
    }
}

foreach ($defaultArgument in $defaultArguments.GetEnumerator()) {
    if (-not $selectedArguments.ContainsKey($defaultArgument.Key)) {
        $selectedArguments[$defaultArgument.Key] = $defaultArgument.Value
    }
}

foreach ($argument in $flattenedCommandArguments.GetEnumerator()) {
    if ($argument.Value.ContainsKey('Group') -and $argument.Value['Group']) {
        $group = $argument.Value

        if ($group.ContainsKey('Required')) {
            if ($group['Required'] -is [bool]) {
                $required = $false
                if ($group.ContainsKey('Required') -and $group['Required']) {
                    $required = $true 
                }
        
                $exclusive = $false
                if ($group.ContainsKey('Exclusive') -and $group['Exclusive']) {
                    $exclusive = $true 
                }
        
                if ($group.ContainsKey('Arguments')) {
                    $numberOfArgumentsSelected = 0
                    foreach ($groupArgument in $group['Arguments'].GetEnumerator()) {
                        $selectedArguments
                        if ($selectedArguments.ContainsKey($groupArgument.Key)) {
                            $numberOfArgumentsSelected++
                        }
                    }
        
                    if (($numberOfArgumentsSelected -eq 0) -and $required) {
                        throw "Missing required argument for required group `"$($argument.Key)`" (Use -h or --help for help)"
                    }
        
                    if (($numberOfArgumentsSelected -gt 1) -and $exclusive) {
                        throw "Multiple arguments specified for exclusive group `"$($argument.Key)`" (Use -h or --help for help)"
                    }
                }
            }
            elseif ($group['Required'] -is [System.Management.Automation.ScriptBlock]) {
                if (-not (& $group['Required'] -Arguments $selectedArguments -Flags $selectedFlags)) {
                    if ($group.ContainsKey('RequiredDescription')) {
                        throw "Group `"$($argument.Key)`" did not meet the requirements: $($group['RequiredDescription'])"
                    }
                    else {
                        throw "Group `"$($argument.Key)`" did not meet the requirements, no description was provided."
                    }
                }
            }
        }
    }
    else {
        if ($argument.Value.ContainsKey('Required')) {
            if ($argument.Value['Required'] -is [bool] -and $argument.Value['Required'] -and (-not $selectedArguments.ContainsKey($argument.Key))) {
                throw "Missing required argument `"$($argument.Key)`" (Use -h or --help for help)"
            }

            if ($argument.Value['Required'] -is [System.Management.Automation.ScriptBlock]) {
                if (-not (& $argument.Value['Required'] -Arguments $selectedArguments -Flags $selectedFlags)) {
                    if ($argument.Value.ContainsKey('RequiredDescription')) {
                        throw "Argument `"$($argument.Key)`" did not meet the requirements: $($argument.Value['RequiredDescription'])"
                    }
                    else {
                        throw "Argument `"$($argument.Key)`" did not meet the requirements, no description was provided."
                    }
                }
            }
        }
    }
}

& (Get-Command $selectedCommand) -Arguments $selectedArguments -Flags $selectedFlags