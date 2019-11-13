# FLowChart
Draw PS1 script FlowChart.
It's still a work in progress ! building the script is done manually, no tests, etc... !

# How it works
The script parses a script AST, and create a list of ``nodes`` idenfying foreach/if/switch/loop statements. The output is a tree of nodes (parent, children etc... ). For Drawing, the script depends on PSGraph.

# Imporing the module
```powershell
Import-Module PsFlowChart.psm1
```

# Usage
```powershell
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

You can then explorer the object: ``$x.Children`` etc...

# Drawing the flowchart
```powershell
Find-FCNode -File .\basic_example_1.ps1 | New-FCGraph
```
Result :
![plopy](basic_example_1.png)

