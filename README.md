# PSFLowChart

Powershell Module to create Flowchart diagram of PowerShell scripts.

Please keep in mind this project is still in draft, still lot of things done manually, no lint/unit tests available yet, etc...

## How it works
The script parses a script AST, and create a list of ``nodes`` idenfying foreach/if/switch/loop statements. The output is a tree of nodes (parent, children etc... ). For Drawing, the script depends on PSGraph.

## Getting Started

```powershell
# Install the module the module from the PowerShell Gallery
Install-Module -Name PsFlowChart -Repository PSGallery -Scope CurrentUser
```

## Usage

### Explore nodes

```powershell
# Find nodes of a PowerShell script
$x = Find-FCNode -File .\basic_example_1.ps1
$x

Type        : If
Statement   : If ( $a -eq 10 )
Description :
Children    : {ForeachNode, ElseNode}
Parent      :
Depth       : 1
File        : C:\basic_example_1.ps1
```

Explore the object children: `$x.Children`

### Drawing the flowchart

```powershell
Find-FCNode -File .\basic_example_1.ps1 | New-FCGraph
```
