# p0rtL's PowerShell Command Line Framework

**A powerful, opinionated single-file PowerShell framework for quick and easy (but customizable) command line tools**

> `Example.ps1` Contains the framework, along with some example usages showcasing all of the features, this is the best place to look to familiarize yourself with the framework

> `Template.ps1` Contains the cut down base of the framework with no comments, ready to be copy and pasted into your codebase

## Usage

This framework was designed for cases where importing a seperate module is not viable, it is powerful, yet small (fitting into only a couple hundred lines). This means it is ideal for copying into the bottom of a script to add commonly required features when making a command line tool. It is opinionated, meaning it is designed to support a layout with commands that take arguments and flags, and then calls a function for the command, passing those parsed values in for use.

## Features

* Customizable help menu
* User-defined commands with matching functions
* Custom arguments
    * Required arguments
    * Argument groups for organization, including exclusive groups
    * Support for lists
    * Strong typed results
    * Custom type parsing
    * Custom requirements
* Custom flags

## Reference
``` PowerShell
$scriptTitle = ''
$scriptFileName = ''
$scriptDesc = ''
$version = ''

$commands = @{
    'command-name' = @{
        Description = ''
        Order = 0
        Arguments = @{
            'argument-name' = @{
                Description = ''
                Order = 0
                Required = $false
                Type = 'STRING'
            }
            'Group Name' = @{
                Group = $true
                Order = 0
                Required = $false
                Exclusive = $false
                Arguments = @{}
            }
        }
        Flags = @{
            'flag-name' = @{
                Description = ''
                Order = 0
            }
        }
    }
}

function command-name {
    param(
        [hashtable]$Arguments,
        [hashtable]$Flags
    )

    # Command code here
}
```

### Commands

``` PowerShell
$commands = @{
    'command-name' = @{}
}
```

**Properties:**
* Description `[string]` | Required
* Order `[int]` | Required - Order to show in the help menu
* [Arguments](#arguments)
* [Flags](#flags)

### Arguments

``` PowerShell
Arguments = @{
    'argument-name' = @{}
}
```

**Properties:**
* Description `[string]` | Required
* Order `[int]` | Required - Order to show in the help menu
* [Required](#custom-requirements)
* RequiredDescription `[string]` - Optional for more verbose error messages
* [Type](#type)
* [CustomType](#custom-type)
* List `[bool]` - Does the argument take a list

### Custom Requirements

This property can either be a `[bool]` or a `[ScriptBlock]`:

``` PowerShell
# Custom Script Block
Requirements = {
    param(
        [Hashtable]$Arguments,
        [Hashtable]$Flags
    )

    return [bool]
}
```

### Type
This property can either be `'STRING', 'PATH', 'BOOLEAN', 'NUMBER'`, which will provide built-in parsing, or you can provide any string you want as a display value (will not provide parsing by default, see: [Custom Type Parsing](#custom-type))

### Custom Type
``` PowerShell
'argument-name' = @{
    CustomType = @{}
}
```

**Properties:**
* ReturnType `[Type]`
* Parser `[ScriptBlock]`
``` PowerShell
# Parser Script Block
{
    param(
        [System.Object]$Value
    )

    # return ReturnType or $null if invalid
}
```

### Argument Groups
``` PowerShell
Arguments = @{
    'Argument Group' = @{
        Group = $true
        Arguments = @{}
    }
}
```

**Properties:**
* Order `[int]` | Required - Order to show in the help menu
* Required `[bool]` - Require at least one argument in the group
* Exclusive `[bool]` - Only allow one argument in the group at a time

### Flags

``` PowerShell
Flags = @{
    'flag-name' = @{}
}
```

**Properties:**

* Description `[string]` | Required
* Order `[int]` | Required - Order to show in the help menu