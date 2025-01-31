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