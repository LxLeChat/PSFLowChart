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

# Finding and Using Description
You can unse ``-FindDescription`` with ``-KeyWord MyCustomKeyWord`` on ``Find-FCNode`` or ``-DescriptionAsLabel`` on ``New-FCGraph``... 
By default, the script will try to find the first comment right after a statement.
Then it validates the comment againt a regex with a special keywoard (you can define it... ), wich by default is ``Description`` 
Valid Comment for identification:
```powershell
If ($a) {
# Description: this is a valid description
}
```
UnValid Comment, unless you specify that the keyword is ``Ahahah``:
```powershell
If ($a) {
# Ahahah: this is a valid description
}
`` 

# Drawing the flowchart
```powershell
Find-FCNode -File .\basic_example_1.ps1 | New-FCGraph
```
Result :
![plopy](basic_example_1.png)

