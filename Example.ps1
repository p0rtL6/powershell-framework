# p0rtL's PowerShell Command Line Framework

# Help menu strings
$scriptTitle = 'Example Script'
$scriptFileName = 'Example.ps1'
$scriptDesc = 'Example script description'
$version = '0.1.0'

# Commands are all defined in this hashtable, create functions matching the names of the commands, those will be run for each command
$commands = @{
    'example-command' = @{
        Description = 'Example description'
        # Order is used in the help menu
        Order       = 0
        # Arguments are prefixed by --
        Arguments   = @{
            # Define an argument like this
            'required'            = @{
                Description = 'Example basic required argument'
                Order       = 0
                Required    = $true
                # (THIS IS OPTIONAL) Type can either be 'STRING', 'BOOLEAN', 'NUMBER', or 'PATH' for built in parsing supported by the framework, you can also specify a custom one as seen below in "custom-type"
                Type        = 'STRING'
            }
            'optional'            = @{
                Description = 'Example basic optional argument'
                Order       = 1
                Required    = $false
                Type        = 'STRING'
            }
            'string-list'         = @{
                Description = 'Example string list argument'
                Order       = 2
                Required    = $false
                Type        = 'STRING'
                # If you want to take a list, specify the List property, it will try and parse a comma seperated list: "1,2,3" (no spaces)
                # This works for any of the built in types specified above, and will produce a strongly typed array like: "int[]"
                # If the user provides only one item, it will be an array of length 1
                List        = $true
            }
            'number-list'         = @{
                Description = 'Example number list argument'
                Order       = 3
                Required    = $false
                Type        = 'NUMBER'
                List        = $true
            }
            'default-argument'    = @{
                Description = 'Argument with default value'
                Order       = 4
                Required    = $false
                Type        = 'STRING'
                # Define a basic default argument
                Default     = 'This is a default value!'
            }
            'custom-default'      = @{
                Description        = 'Argument with default value'
                Order              = 5
                Required           = $false
                Type               = 'STRING'
                # Use this with the below to provide extra detail in the help menu
                DefaultDescription = 'Defaults to show if "example-flag-2" was set'
                # Default can also be a script block that calculates a default from the rest of the arguments and flags
                # Note that defaults are applied all at once after the rest of the arguments are parsed, meaning you cannot make one default argument rely on another
                Default            = {
                    param(
                        [hashtable]$Arguments,
                        [hashtable]$Flags
                    )

                    if ($Flags['example-flag-2']) {
                        return 'The example flag 2 was set'
                    }
                    else {
                        return 'The example flag 2 was not set'
                    }
                }
            }
            # Use this when you have complex requirements, takes Arguments and Flags as params, wow! (make sure to return a boolean)
            'custom-requirements' = @{
                Description         = 'This command has a custom requirement block'
                Order               = 6
                # Optionally you can provide a description for your custom script block
                RequiredDescription = 'Checks if the -example-flag is set'
                Required            = {
                    param(
                        [Hashtable]$Arguments,
                        [Hashtable]$Flags
                    )
                                
                    # Simply returns if the flag exists, could be whatever you want though
                    return $Flags['example-flag']
                }
                Type                = 'STRING'
            }
            'custom-type'         = @{
                Description = 'Example basic optional argument'
                Order       = 7
                Required    = $false
                # You can specify any string name you want for the type (this is just for display)
                Type        = 'NAME/VALUE'
                # If you want to actually do custom type parsing, specify the CustomType property with a script block, takes the argument value as a parameter
                CustomType  = @{
                    # If you want the argument value to be created with strong typing, set the intended return type here, if you do not, it will simply return it as an Object[] with no garuntees about the types held
                    ReturnType = [hashtable]
                    Parser     = {
                        param(
                            [System.Object]$Value
                        )
    
                        # Checks if argument can be split in two by a slash
                        $parts = $value -split '/'
                        if ($parts.Length -eq 2) {
                            $parsedArgument = @{}
                            $parsedArgument['name'] = $parts[0]
                            $parsedArgument['value'] = $parts[1]
    
                            # If it can be parsed, return whatever custom parsed type you want
                            return $parsedArgument             
                        }
    
                        # Implicit null return
                    }
                }
                # This also works with the list property like below, the custom rules will be applied to each element
                # List = $true
            }
            # Define a group like this
            # Use this when you want a group where AT LEAST ONE option is required
            'Required Group'      = @{
                # When making a group, set this to true
                Group     = $true
                # You can also set custom requirement script blocks here like above
                Required  = $true
                Exclusive = $false
                Order     = 8
                Arguments = @{
                    'required-group-1' = @{
                        Description = 'Either this or required-group-2 are required (or both)'
                        # Group order is independant of normal argument order
                        Order       = 1
                        Type        = 'STRING'
                    }
                    'required-group-2' = @{
                        Description = 'Either this or required-group-1 are required (or both)'
                        Order       = 2
                        Type        = 'STRING'
                    }
                }
            }
            # Use this when you want a group that ONLY takes one option but is required
            'Exclusive Group'     = @{
                Group     = $true
                Required  = $false
                Exclusive = $true
                Order     = 8
                Arguments = @{
                    'exclusive-group-1' = @{
                        Description = 'Either this or exclusive-group-2 are required (not both)'
                        Order       = 1
                        Type        = 'STRING'
                    }
                    'exclusive-group-2' = @{
                        Description = 'Either this or exclusive-group-1 are required (not both)'
                        Order       = 2
                        Type        = 'STRING'
                    }
                }
            }
        }
        # Flags are prefixed by -
        Flags       = @{
            'example-flag'   = @{
                Description = 'Example flag'
                Order       = 0
            }
            'example-flag-2' = @{
                Description = 'See what happens to "custom-default" when you set this!'
                Order       = 1
            }
        }
    }
}

# If you want to use the same type between arguments, you could write a custom type like this, the same goes for custom requirements
# $customType1 = {
#     param(
#         [System.Object]$Value
#     )

#     # Your code here
# }

# This is where you write your command code, each command is passed the selected Arguments and Flags
function example-command {
    param(
        [Hashtable]$Arguments,
        [Hashtable]$Flags
    )

    # Arguments received in here are simply name-value, they are NOT the same format as you specified above (does not include the extra info) so you simply access them as seen below for the value

    # Make sure to check if arguments are specified, they are possibly null!
    if ($arguments.ContainsKey('required')) {
        Write-Host "Value for required argument: $($arguments['required'])"
    }

    # List was set, we can iterate over it now
    if ($arguments.ContainsKey('string-list')) {
        foreach ($item in $arguments['string-list']) {
            Write-Host "String list item: $item"
        }
    }
    
    # Lists are strongly typed based on the set type
    if ($arguments.ContainsKey('number-list')) {
        Write-Host "String list is strongly typed: $($arguments['number-list'].GetType())"
    }

    # Group arguments are flattened into the arguments here, so they are all accessed at the root level
    if ($arguments.ContainsKey('required-group-1')) {
        Write-Host "Value for required-group-1 argument: $($arguments['required-group-1'])"
    }

    if ($arguments.ContainsKey('custom-type')) {
        # Our custom type is parsed into the object from above, we can use it as such
        $customType = $arguments['custom-type']
        Write-Host "Custom type was set!"
        Write-Host "Custom type name: $($customType['name'])"
        Write-Host "Custom type value: $($customType['value'])"
    }

    if ($arguments.ContainsKey('default-argument')) {
        Write-Host "Found default argument: $($arguments['default-argument'])"
    }

    if ($arguments.ContainsKey('custom-default')) {
        Write-Host "Found default argument, this was calculated dynamically: $($arguments['custom-default'])"
    }

    # Flags do not need to be checked with "ContainsKey" as the ones not specified are all initialized to $false, simply check them as booleans
    if ($flags['example-flag']) {
        Write-Host 'Example flag is set!'
    }
}

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

    # Header of help menu, all defined at the top of the file

    Write-Host "=== $scriptTitle ==="
    Write-Host $scriptDesc
    Write-Host "Version: $version"
    Write-Host ''
    Write-Host "Usage: $scriptFileName [COMMAND] [ARGUMENTS] [FLAGS]"
    Write-Host ''

    # Iterate over all the commands and args/flags to dynamically calculate the padding needed to make all of the text line up in the help menu

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
    
    # Add a gap

    $helpMenuCommandPadding += 2
    $helpMenuArgsAndFlagsPadding += 2

    if (-not $selectedCommand) {
        Write-Host '[COMMANDS]'
    }

    $sortedCommands = $commands.GetEnumerator() | Sort-Object { $_.Value['Order'] }
    foreach ($command in $sortedCommands) {

        # Provides sub-menu for a selected command instead of printing all
        if ($selectedCommand -and ($selectedCommand -ne ($command.Key))) {
            continue
        }

        Write-Host "  $($command.Key.PadRight($helpMenuCommandPadding)) $($command.Value['Description'])"
        Write-Host ''

        if ($command.Value.ContainsKey('Arguments')) {
            Write-Host '  [ARGUMENTS]'

            # Get args and sort by the Order property
            $arguments = $command.Value['Arguments']
            $sortedArguments = $arguments.GetEnumerator() | Sort-Object { $_.Value['Order'] }

            # We use this to make sure we have standardized spacing of newlines between arguments, which needs to happen differently if we last printed a group or just an argument
            $lastItemWasGroup = $false

            foreach ($argument in $sortedArguments) {
                # Check if the argument is a group
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

# Show the general help menu
if ($Args.Count -eq 0 -or $Args[0] -eq '-h' -or $Args[0] -eq '--help') {
    Show-HelpMenu
    exit 0
}

# First arg must be a command
if (-not $commands.ContainsKey($Args[0])) {
    throw 'Invalid command selected (Use -h or --help for help)'
}

# Begin parsing of command line arguments
$selectedCommand = $null
$flattenedCommandArguments = $null
$selectedArguments = @{}
$selectedFlags = @{}

# Iterating over command line arguments
for ($i = 0; $i -lt $Args.Count; $i++) {
    if ($Args[$i] -eq '-h' -or $Args[$i] -eq '--help') {
        if ($selectedCommand) {
            # Shows sub-menu for just the selected command
            Show-HelpMenu -SelectedCommand $selectedCommand
        }
        else {
            Show-HelpMenu
        }
        exit 0
    }
    elseif ($i -eq 0) {
        # First cmd arg is the command
        $selectedCommand = $Args[0]
        $flattenedCommandArguments = Get-FlatArguments -CommandName $Args[0]
    }
    elseif ($Args[$i].StartsWith('--')) {
        # Arguments all start with --

        # Parsing, we want to support either "--argument value" or "--argument=value"
        $arg = $Args[$i].Substring(2)
        $argParts = $arg -split '='
        $keyword = $argParts[0]
        $value = $null

        if (-not $flattenedCommandArguments.ContainsKey($keyword)) {
            throw 'Invalid argument (Use -h or --help for help)'
        }

        # This sets the value if the argument was provided with an equals in between
        if ($argParts.Count -eq 2) {
            $value = $argParts[1]
        }
        elseif ($argParts.Count -gt 2 -or $argParts -lt 1) {
            # There should not be more than two parts or less than one
            throw 'Malformed argument (Use -h or --help for help)'
        }

        # If the value was provided with a space in between it will be the next arg value, so move it to the next and save it
        if (-not $value) {
            $i++
            $value = $Args[$i]
        }

        # If one of the above did not work, a value was not provided
        if (-not $value) {
            throw "No value provided for argument `"$keyword`" (Use -h or --help for help)"
        }

        # Get the argument type name
        $argumentTypeString = $flattenedCommandArguments[$keyword]['Type']

        # Default to opaque object for target type and parser just passes the object through
        $targetType = [System.Object]
        $parser = { param([System.Object]$Value) return $value }

        if ($flattenedCommandArguments[$keyword].ContainsKey('CustomType')) {
            # Using custom type rules, set those accordingly
            if ($flattenedCommandArguments[$keyword].ContainsKey('ReturnType')) {
                $targetType = $flattenedCommandArguments[$keyword]['CustomType']['ReturnType']
            }

            $parser = $flattenedCommandArguments[$keyword]['CustomType']['Parser']
        }
        else {
            # Check if the argument type name matches a built in parser
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
                            return $value -as [string]
                        }
                    }
                }
            }
        }

        $targetArrayType = $targetType.MakeArrayType()
        $shouldBeList = $flattenedCommandArguments[$keyword].ContainsKey('List') -and $flattenedCommandArguments[$keyword]['List']

        $parsedValue = $null

        # If the value is a list, parse as such
        if ($value -is [System.Object[]]) {
            if (-not $shouldBeList) {
                # The argument is not supposed to be a list, so we error
                throw "Argument value for `"$keyword`" cannot be a list (Use -h or --help for help)"
            }

            # Iterate over the value list in place (do not reallocate) and call the parser on each value
            for ($j = 0; $j -lt $value.Length; $j++) {
                $parsedListItem = & $parser -Value $value[$j]
                if ($null -ne $parsedListItem) {
                    $value[$j] = $parsedListItem
                }
                else {
                    # If we get a null value that means the parsing failed, notify the user and exit
                    throw "Argument value `"$($value[$j])`" is not a valid $($argumentTypeString.ToLower()) (Use -h or --help for help)"
                }
            }

            # Now that we know we have converted all the elements of the array, it should be safe to cast to the target type
            $parsedValue = $value -as $targetArrayType
        }
        else {
            # User provided only one item
            if ($shouldBeList) {
                # The output should be a list, so we make one with one element and cast it
                $parsedValue = @(& $parser -Value $value) -as $targetArrayType
            }
            else {
                # The output should just be one value, cast it
                $parsedValue = & $parser -Value $value
            }
        }
        
        # If any of our final casts failed, this is null, so we notify the user and exit
        if ($null -eq $parsedValue) {
            throw "Argument value `"$value`" for `"$keyword`" is not a valid $($argumentTypeString.ToLower()) list (Use -h or --help for help)"
        }
        
        # Set the argument
        $selectedArguments[$keyword] = $parsedValue
    }
    elseif ($Args[$i].StartsWith('-')) {
        # Flags all start with -

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

# Fill in unselected flags with false, allows checking of flags as booleans instead of a "contains" method
foreach ($flagName in $commands[$selectedCommand]['Flags'].Keys) {
    if (-not $selectedFlags.ContainsKey($flagName)) {
        $selectedFlags[$flagName] = $False
    }
}

# Parse default arguments
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

# Apply default arguments
foreach ($defaultArgument in $defaultArguments.GetEnumerator()) {
    $selectedArguments[$defaultArgument.Key] = $defaultArgument.Value
}

# Verify the requirements for arguments are met
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

# Invoke function from the selected command name, pass the arguments and flags
& (Get-Command $selectedCommand) -Arguments $selectedArguments -Flags $selectedFlags