using namespace System.Management.Automation.Language

class nodeutility {

    [node[]] static ParseFile ([string]$File) {
        $ParsedFile     = [Parser]::ParseFile($file, [ref]$null, [ref]$Null)
        $RawAstDocument = $ParsedFile.FindAll({$args[0] -is [Ast]}, $false)
        $LinkedList = [System.Collections.Generic.LinkedList[string]]::new()
        $x=@()
        $RawAstDocument | ForEach-Object{
            $CurrentRawAst = $PSItem
            if ( $null -eq $CurrentRawAst.parent.parent.parent ) {
                $t = [nodeutility]::SetNode($CurrentRawAst)
                if ( $null -ne  $t) {
                    Write-Verbose "NIVEAU 1: $($t.Statement)"
                    $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($t.Nodeid)
                    $LinkedList.AddLast($LinkedNode)
                    $t.LinkedBrothers = $LinkedList
                    $t.LinkedNodeId = $LinkedNode
                    
                    $x+=$t

                    If ( $t.Type -eq "If" ) {
                    $LinkedNodeEndIf = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$t.Nodeid)
                    $LinkedList.AddLast($LinkedNodeEndIf)
                        If ( $t.raw.Clauses.Count -ge 1 ) {
                            for( $i=1; $i -lt $t.raw.Clauses.Count ; $i++ ) {
                                    $node = [ElseIfNode]::new($t.raw.clauses[$i].Item1,$t.Statement)
                                    Write-Verbose "NIVEAU 1: $($node.Statement)"
                                    $LinkedNodeC = [System.Collections.Generic.LinkedListNode[string]]::new($node.nodeId)
                                    $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNodeC)
                                    #$LinkedList.AddAfter($LinkedNode,$LinkedNodeC)
                                    $node.LinkedBrothers = $LinkedList
                                    $node.LinkedNodeId = $LinkedNodeC
                                    $node.EndNodeid = $t.EndNodeid
                                    $x += $node
                            }
                        }

                        If ( $null -ne $t.raw.ElseClause ) {
                            $node = [ElseNode]::new($t.raw.ElseClause,$t.Statement)
                            $LinkedNodeD = [System.Collections.Generic.LinkedListNode[string]]::new($node.nodeId)
                            $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNodeD)
                            #$LinkedList.AddLast($LinkedNode,$LinkedNodeD)
                            $node.LinkedBrothers = $LinkedList
                            $node.LinkedNodeId = $LinkedNodeD
                            $node.EndNodeid = $t.EndNodeid
                            $x += $node
                        }
                    }

                    If ( $t.type -eq "Foreach") {
                        $LinkedNodeNext = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$t.Nodeid)
                        $LinkedList.AddAfter($LinkedNode,$LinkedNodeNext)
                    }

                    If ( $t.type -eq "While") {
                        $LinkedNodeNext = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$t.Nodeid)
                        $LinkedList.AddAfter($LinkedNode,$LinkedNodeNext)
                    }

                    If ( $t.type -eq "For") {
                        $LinkedNodeNext = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$t.Nodeid)
                        $LinkedList.AddAfter($LinkedNode,$LinkedNodeNext)
                    }
                }
            }
        }
        return $x
    }

    [node] static SetNode ([object]$e) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [IfStatementAst]      } { $node = [IfNode]::new($PSItem)      }
            { $psitem -is [ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem) }
            { $psitem -is [WhileStatementAst]   } { $node = [WhileNode]::new($PSItem)   }
            { $psitem -is [SwitchStatementAst]  } { $node = [SwitchNode]::new($PSItem) }
            { $psitem -is [ForStatementAst]     } { $node = [ForNode]::new($PSItem)     }
            { $psitem -is [DoUntilStatementAst] } { $node = [DoUntilNode]::new($PSItem) }
            { $psitem -is [DoWhileStatementAst] } { $node = [DoWhileNode]::new($PSItem) }
        }
        return $node
    }

    ## override with parent, for sublevels
    [node] static SetNode ([object]$e,[node]$f) {
        $node = $null
        Switch ( $e ) {
            { $psitem -is [IfStatementAst]      } { $node = [IfNode]::new($PSItem,$f)      }
            { $psitem -is [ForEachStatementAst] } { $node = [ForeachNode]::new($PSItem,$f) }
            { $psitem -is [WhileStatementAst]   } { $node = [WhileNode]::new($PSItem,$f)   }
            { $psitem -is [SwitchStatementAst]  } { $node = [SwitchNode]::new($PSItem,$f) }
            { $psitem -is [ForStatementAst]     } { $node = [ForNode]::new($PSItem,$f)     }
            { $psitem -is [DoUntilStatementAst] } { $node = [DoUntilNode]::new($PSItem,$f) }
            { $psitem -is [DoWhileStatementAst] } { $node = [DoWhileNode]::new($PSItem,$f) }
            
        }
        return $node
    }

    [object[]] static GetASTitems () {
        return @(
            [ForEachStatementAst],
            [IfStatementAst],
            [WhileStatementAst],
            [SwitchStatementAst],
            [ForStatementAst],
            [DoUntilStatementAst],
            [DoWhileStatementAst]
        )
    }

    [String] static SetDefaultShape ([String]$e) {
        $Shape = $Null
        Switch ( $e ) {
            "If"       { $Shape = "diamond"       }
            "ElseIf"   { $Shape = "diamond"       }
            "Foreach"  { $Shape = "parallelogram" }
            "While"    { $Shape = "parallelogram" }
            "DoWhile"  { $Shape = "parallelogram" }
            "DoUntil"  { $Shape = "parallelogram" }
            "For"      { $Shape = "parallelogram" }
            Defaut     { $Shape = "box" }
            
        }
        return $Shape
    }

}

## Ajouter un noeud qu'on pourrait appeler CodeNode, par exemple dans un if , si il n y a rien dedans ...
## Pour le flowchart comme ça on peut dire ce que le if fait
## coup est ce que il faudrait pas que le else et elseif ne soient pas ua meme niveau ...?!
class node {
    [string]$Type
    [string]$Statement
    [String]$Description
    $Children = [System.Collections.Generic.List[node]]::new()
    [node]$Parent
    [int]$Depth
    $File
    hidden $Nodeid
    hidden $EndNodeid
    hidden $LinkedBrothers
    hidden $LinkedNodeId
    hidden $code
    hidden $NewContent
    hidden $raw
    hidden $DefaultShape

    node () {
        $this.SetDepth()
        $this.Guid()  
    }

    node ([Ast]$e) {
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.Guid()
        $this.DefaultShape = [nodeutility]::SetDefaultShape($this.Type)

        If ( $this.Type -in ("If","Foreach","While","For") ) {
            $this.EndNodeid = "End_"+$this.Nodeid
        }
    }

    node ([Ast]$e,[node]$f) {
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.Guid()
        $this.DefaultShape = [nodeutility]::SetDefaultShape($this.Type)

        If ( $this.Type -in ("If","Foreach","While","For") ) {
            $this.EndNodeid = "End_"+$this.Nodeid
        }
    }

    ## override with parent, for sublevels
    [void] FindChildren ([Ast[]]$e,[node]$f) {
        $LinkedList = [System.Collections.Generic.LinkedList[string]]::new()
        
        foreach ( $d in $e ) {
            If ( $d.GetType() -in [nodeutility]::GetASTitems() ) {
                $node = [nodeutility]::SetNode($d,$f)
                $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($node.Nodeid)
                $LinkedList.AddLast($LinkedNode)
                $node.LinkedBrothers = $LinkedList
                $node.LinkedNodeId = $LinkedNode
                $this.Children.add($node)

                ##du coup niveau 3 il ajoute pas le endif ... !!!!!
                #If ( ($node.Type -eq "If") -and ($node.Depth -eq 2)  ) {
                If ( ($node.Type -eq "If")  ) {
                    write-verbose "find-children $($node.Statement)"
                    $LinkedNodeEndIf = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$node.Nodeid)
                    $LinkedList.AddLast($LinkedNodeEndIf)
                    If ( $node.raw.Clauses.Count -ge 1 ) {
                        for( $i=1; $i -lt $node.raw.Clauses.Count ; $i++ ) {
                                $nodeElseIf = [ElseIfNode]::new($node.raw.clauses[$i].Item1,$this,$node.Statement)
                                $LinkedNodeC = [System.Collections.Generic.LinkedListNode[string]]::new($nodeElseIf.nodeId)
                                $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNodeC)
                                #$LinkedList.AddAfter($LinkedNode,$LinkedNodeC)
                                $nodeElseIf.LinkedBrothers = $LinkedList
                                $nodeElseIf.LinkedNodeId = $LinkedNodeC
                                $nodeElseIf.EndNodeid = $node.EndNodeid
                                $this.Children.add($nodeElseIf)
                        }
                    }

                    If ( $null -ne $node.raw.ElseClause ) {
                        $nodeElse = [ElseNode]::new($node.raw.ElseClause,$this,$node.Statement)
                        $LinkedNodeD = [System.Collections.Generic.LinkedListNode[string]]::new($nodeElse.nodeId)
                        $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNodeD)
                        #$LinkedList.AddAfter($LinkedNode,$LinkedNodeD)
                        $nodeElse.LinkedBrothers = $LinkedList
                        $nodeElse.LinkedNodeId = $LinkedNodeD
                        $nodeElse.EndNodeid = $node.EndNodeid
                        $this.Children.add($nodeElse)
                    }
                }

                If ( $node.type -eq "Foreach") {
                    $LinkedNodeNext = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$node.Nodeid)
                    $LinkedList.AddAfter($LinkedNode,$LinkedNodeNext)
                }

                If ( $node.type -eq "While") {
                    $LinkedNodeNext = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$node.Nodeid)
                    $LinkedList.AddAfter($LinkedNode,$LinkedNodeNext)
                }

                If ( $node.type -eq "For") {
                    $LinkedNodeNext = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$node.Nodeid)
                    $LinkedList.AddAfter($LinkedNode,$LinkedNodeNext)
                }
            }
        }

        If ( $this.Children.count -eq 0 ) {
            $node = [BlockProcess]::new()
            $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($node.Nodeid)
            $LinkedList.AddLast($LinkedNode)
            $node.LinkedBrothers = $LinkedList
            $node.LinkedNodeId = $LinkedNode
            $this.Children.add($node)
        }
    }


    [void] FindDescription () {
        $tokens=@()
        [Parser]::ParseInput($this.code,[ref]$tokens,[ref]$null)
        
        $c = $tokens | Where-Object kind -eq "comment"
        If ( $c.count -gt 0 ) {
            If ( $c[0].text -match 'DiagramDescription:(?<description>\s?[\w\s]+)' ) {
                $this.Description = $Matches.description.Trim() 
            } Else {
                $this.Description = $this.Statement
            }
        }
    }

    ## a revoir, avec comme base $code !
    [void] SetDescription () {
        If ( $null -eq $this.Description ) {
            $this.Description = Read-Host -Prompt $("Description for {0}" -f $this.Statement)
        } Else { 
            $d = Read-Host -Prompt $("Actual description for {0} is: {1}" -f $this.Statement,$this.Description)
            if ( $null -ne $d ) {
                $this.Description = $d
            } else {
                $this.Description = $this.Statement
            }
         }
        
        # USE code Property !
        if ( $null -ne $this.Description ) {
            #$f = (($this.raw.Extent.Text -split '\r?\n')[0]).Length
            #$g = "<#`n    DiagramDescription: $($this.Description))`n#>`n"
            #$this.NewContent = $this.raw.Extent.Text.Insert($f+2,$g)
        }
        
    }

    [node[]] GetChildren ([bool]$recurse) {
        $a = @()
        If ( $recurse ) {
            If ( $this.Children.count -gt 0 ) {
                foreach ( $child in $this.Children ) {
                    $a += $child.getchildren($true)
                }
                $a += $this.Children
            } else {
                break;
            }
        } else {
            $a=$this.Children
        }
                
        return $a
    }
    
    ## Need override in case of switchnodecase, elseif, and else
    [void] SetDepth () {
        If ( $null -eq $this.parent ) {
            $this.Depth = 1
        } Else {
            $this.Depth = $this.Parent.Depth + 1
        }

    }

    hidden [void] Guid (){
        $this.Nodeid = ([guid]::NewGuid()).Guid
    }

}

Class IfNode : node {
    
    [string]$Type = "If"

    IfNode ([Ast]$e) : base ($e) {

        If ( $this.raw.Clauses.Count -gt 0 ) {
            $this.Statement = "If ( {0} )" -f $this.raw.Clauses[0].Item1.Extent.Text
            $this.Code = $this.raw.Clauses[0].Item2.Extent.Text
        }
        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

    }

    IfNode ([Ast]$e,[node]$f) : base ($e,$f) {

        If ( $this.raw.Clauses.Count -gt 0 ) {
            $this.Statement = "If ( {0} )" -f $this.raw.Clauses[0].Item1.Extent.Text
            $this.Code = $this.raw.Clauses[0].Item2.Extent.Text
        }

        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

    }

    [string] graph () {

        
        ## On stocke le noeud de fin
        $EndIfNode = $this.LinkedBrothers.Find($this.EndNodeid)

        ## Creation des noeuds de base
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string+";node "+$this.EndNodeid+" -attributes @{shape='point'}"

        ## si on a pas de previous node, et niveau 1
        If ( ($this.Depth -eq 1) -And ($null -eq $this.LinkedNodeId.Previous) ) {
            write-Verbose "Graph: If: Drawing START NODE"
            $string = $string +";Edge -from START -to "+$this.NodeId        
        }

        ## si on a pas de next node, et niveau 1
        If ( ($this.Depth -eq 1) -And ($null -eq $EndIfNode.Next) ) {
            write-Verbose "Graph: If: Drawing END NODE"
            $string = $string +";Edge -from "+$this.EndNodeid+" -to END"
        }

        If ( $null -ne $This.LinkedNodeId.Next) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.LinkedNodeId.Next.Value+" -attributes @{Label='False'}"
        }
       
        If ( $this.Children.count -gt 0 ) {
            Write-Verbose "Graph: If: ChildrenCount > 0, Graphing To First ChildNode"
            $string = $string + ";Edge -from "+$this.NodeId+" -to "+$This.Children[0].NodeId+" -attributes @{Label='True'}"
            foreach ( $child in $this.Children ) { $string = $string + ";" + $child.Graph() }
            
            ## On trace le edge entre le dernier enfant et le endif
            If ( $this.Children[-1].LinkedNodeId.next ) {
                $string = $string + ";Edge -from "+$this.Children[-1].LinkedNodeId.next.Value+" -to "+$This.EndNodeid
            } else {
                $string = $string + ";Edge -from "+$this.Children[-1].LinkedNodeId.Value+" -to "+$This.EndNodeid
            }
        }

        If ( $null -ne $EndIfNode.Next ) {
            Write-Verbose "Graph: If: there is a node after the EndIf"
            $string = $string+ ";Edge -from "+$this.EndnodeId+" -to "+$EndIfNode.Next.Value
        }

        return $string
    }

}

Class ElseIfNode : node {
    [String]$Type = "ElseIf"
    #$f represente l element2 du tuple donc si on veut chercher ce qu il y a en dessous il faut utiliser ça
    ElseIfNode ([Ast]$e,[string]$d) : base ($e,$j) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $item1ToSearch = $this.raw.extent.text
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.extent.text -eq $item1ToSearch})).Item2.Extent.Text

        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements,$this)
    }

    ElseIfNode ([Ast]$e,[node]$j,[string]$d) : base ($e,$j) {
        $this.Statement = "ElseIf ( {0} ) From {1}" -f $e.Extent.Text,$d
        $item1ToSearch = $this.raw.extent.text
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.extent.text -eq $item1ToSearch})).Item2.Extent.Text

        $this.FindChildren($this.raw.Parent.Clauses.where({$_.item1.extent.text -eq $this.raw.extent.text}).item2.Statements,$this)
    }

    [string] graph () {

        $string = "node " +$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"

        If ( $null -ne $This.LinkedNodeId.Next ) {
            $string = $string + ";Edge -from "+$this.NodeId+" -to "+$This.LinkedNodeId.Next.Value+" -attributes @{Label='False'}"
        } Else {
            $string = $string + ";Edge -from "+$this.NodeId+" -to "+$This.EndNodeid+" -attributes @{Label='False'}"
        }

        If ( $this.Children.count -gt 0 ) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.Children[0].NodeId+" -attributes @{Label='True'}"
            foreach ( $child in $this.Children ) { $string = $string + ";" + $child.Graph() }
            
            $string = $string +";Edge -from "+$this.Children[-1].nodeId+" -to "+$this.EndNodeid

        }

        return $string
    }

}

Class ElseNode : node {
    [String]$Type = "Else"

    ElseNode ([Ast]$e,[string]$d)  : base ($e) {
        $this.Statement = "Else From {0}" -f $d
        $this.code = $e.extent.Text
        $this.FindChildren($this.raw.statements,$this)
    }

    ElseNode ([Ast]$e,[node]$f,[string]$d)  : base ($e,$f) {
        $this.Statement = "Else From {0}" -f $d
        $this.code = $e.extent.Text
        $this.FindChildren($this.raw.statements,$this)
    }

    [string] graph () {

        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"

        If ( $this.Children.count -gt 0 ) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.Children[0].NodeId
            foreach ( $child in $this.Children ) { $string = $string + ";" + $child.Graph() }
            $string = $string +";Edge -from "+$this.Children[-1].nodeId+" -to "+$this.EndNodeid

        }

        return $string
    }
}

Class SwitchNode : node {
    [String]$Type = "Switch"

    SwitchNode ([Ast]$e) : base ($e) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this,$this.Statement,$e.clauses[$i].Item2))
        }

    }

    SwitchNode ([Ast]$e,[node]$f) : base ($e,$f) {
        $this.Statement = "Switch ( "+ $e.Condition.extent.Text + " )"

        for( $i=0; $i -lt $e.Clauses.Count ; $i++ ) {
            $this.Children.Add([SwitchCaseNode]::new($e.clauses[$i].Item1,$this.Statement,$e.clauses[$i].Item2,$this))
        }

    }

    ## pas réussi a chopper le "code" du switch .. du coup la description ne sra pas settable dans le script
    ## la description ne sera utilisable que pour le graph
    [void]SetDescription([string]$e) {
        $this.Description = $e
    }
}

Class SwitchCaseNode : node {
    [String]$Type = "SwitchCase"

    SwitchCaseNode ([Ast]$e,[node]$j,[string]$d,[Ast]$f) : base ($e,$j) {
        $this.Statement = "Case: {1} for Switch {0}" -f $d,$this.raw.Extent.Text

        $item1ToSearch = $this.raw.Value
        $this.Code = ($this.raw.Parent.Clauses.where({$_.Item1.Value -eq $item1ToSearch})).Item2.Extent.Text
    }

}

Class ForeachNode : node {
    [String]$Type = "Foreach"

    ForeachNode ([Ast]$e) : base ($e) {
        Write-Verbose "FORECH"
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.code = $e.body.Extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForeachNode ([Ast]$e,[node]$f) : base ($e,$f) {
        $this.Statement = "Foreach ( "+ $e.Variable.extent.Text +" in " + $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    [string] graph () {

        ## On stocke le noeud de fin
        $EndIfNode = $this.LinkedBrothers.Find($this.EndNodeid)

        ## Noeud et edge de base
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string+";node "+$this.EndNodeid+" -attributes @{Label='Next "+$this.raw.Condition+"'}"
        $string = $string +";Edge -from "+$this.EndNodeid+" -to "+$this.nodeId+" -attributes @{Label='Loop'}"

        ## si on a pas de previous node, et niveau 1
        If ( ($this.Depth -eq 1) -And ($null -eq $this.LinkedNodeId.Previous) ) {
            write-Verbose "Graph: Foreach: Drawing START NODE"
            $string = $string +";Edge -from START -to "+$this.NodeId        
        }

        ## si on a pas de next node, et niveau 1
        If ( ($this.Depth -eq 1) -And ($null -eq $EndIfNode.Next) ) {
            write-Verbose "Graph: Foreach: Drawing END NODE"
            $string = $string +";Edge -from "+$this.EndNodeid+" -to END"
        }
        
        If ( $this.Children.count -gt 0 ) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$this.Children[0].NodeId
            foreach ( $child in $this.Children ) { $string = $string + ";" + $child.Graph() }
            $string = $string +";Edge -from "+$this.Children[-1].LinkedBrothers.Last.Value+" -to "+$this.EndNodeid
        }

        If ( $null -ne $EndIfNode.Next ) {
            Write-Verbose "Graph: If: there is a node after the EndIf"
            $string = $string+ ";Edge -from "+$this.EndnodeId+" -to "+$EndIfNode.Next.Value+" -attributes @{label='LoopEnded'}"
        }

        return $string
    }
}

Class WhileNode : node {
    [string]$Type = "While"

    WhileNode ([Ast]$e) : base ($e) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }

    WhileNode ([Ast]$e,[node]$f) : base ($e,$f) {
        $this.Statement = "While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
        
    }

    [string] graph () {

        ## On stocke le noeud de fin
        $EndIfNode = $this.LinkedBrothers.Find($this.EndNodeid)

        ## on cree les bases
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string+";node "+$this.EndNodeid+" -attributes @{Label='If "+$this.raw.Condition+"'}"
        $string = $string +";Edge -from "+$this.EndNodeid+" -to "+$this.nodeId+" -attributes @{Label='True, Loop'}"

        ## si on a pas de previous node, et niveau 0
        If ( ($this.Depth -eq 1) -And ($null -eq $this.LinkedNodeId.Previous) ) {
            write-Verbose "Graph: While: Drawing START NODE"
            $string = $string +";Edge -from START -to "+$this.NodeId        
        }

        ## si on a pas de next node, et niveau 1
        If ( ($this.Depth -eq 1) -And ($null -eq $EndIfNode.Next) ) {
            write-Verbose "Graph: While: Drawing END NODE"
            $string = $string +";Edge -from "+$this.EndNodeid+" -to END"
        }

        If ( $this.Children.count -gt 0 ) {
            Write-Verbose "Graph: While: Graph while children"
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$this.Children[0].NodeId
            foreach ( $child in $this.Children ) { $string = $string + ";" + $child.Graph() }
            $string = $string +";Edge -from "+$this.Children[-1].LinkedBrothers.Last.Value+" -to "+$this.EndNodeid
        }

        If ( $null -ne $EndIfNode.Next ) {
            Write-Verbose "Graph: While: there is a node after the EndWhile"
            $string = $string+ ";Edge -from "+$this.EndnodeId+" -to "+$EndIfNode.Next.Value+" -attributes @{label='LoopEnded'}"
        }

        return $string
    }
}

Class ForNode : node {
    [string]$Type = "For"

    ForNode ([Ast]$e) : base ($e) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    ForNode ([Ast]$e,[node]$f) : base($e,$f) {
        $this.Statement = "For ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    [string] graph () {

        ## On stocke le noeud de fin
        $EndIfNode = $this.LinkedBrothers.Find($this.EndNodeid)

        ## on cree les bases
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string+";node "+$this.EndNodeid+" -attributes @{Label='If "+$this.raw.Condition+"'}"
        $string = $string +";Edge -from "+$this.EndNodeid+" -to "+$this.nodeId+" -attributes @{Label='"+$this.raw.Iterator.Extent.Text+"'}"

        ## si on a pas de previous node, et niveau 0
        If ( ($this.Depth -eq 1) -And ($null -eq $this.LinkedNodeId.Previous) ) {
            write-Verbose "Graph: For: Drawing START NODE"
            $string = $string +";Edge -from START -to "+$this.NodeId        
        }

        ## si on a pas de next node, et niveau 1
        If ( ($this.Depth -eq 1) -And ($null -eq $EndIfNode.Next) ) {
            write-Verbose "Graph: For: Drawing END NODE"
            $string = $string +";Edge -from "+$this.EndNodeid+" -to END"
        }

        If ( $this.Children.count -gt 0 ) {
            Write-Verbose "Graph: For: Graph while children"
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$this.Children[0].NodeId
            foreach ( $child in $this.Children ) { $string = $string + ";" + $child.Graph() }
            $string = $string +";Edge -from "+$this.Children[-1].LinkedBrothers.Last.Value+" -to "+$this.EndNodeid
        }

        If ( $null -ne $EndIfNode.Next ) {
            Write-Verbose "Graph: For: there is a node after the EndFor"
            $string = $string+ ";Edge -from "+$this.EndnodeId+" -to "+$EndIfNode.Next.Value+" -attributes @{label='LoopEnded'}"
        }
        return $string
    }
}

Class DoUntilNode : node {
    [string]$Type = "DoUntil"

    DoUntilNode ([Ast]$e) : base($e) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoUntilNode ([Ast]$e,[node]$f) : base($e,$f) {
        $this.Statement = "Do Until ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class DoWhileNode : node {
    [string]$Type = "DoWhile"

    DoWhileNode ([Ast]$e) : base($e) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }

    DoWhileNode ([Ast]$e,[node]$f) : base($e,$f) {
        $this.Statement = "Do While ( "+ $e.Condition.extent.Text + " )"
        $this.code = $e.body.extent.Text
        $this.FindChildren($this.raw.Body.Statements,$this)
    }
}

Class BlockProcess : node {
    [string]$Type = "BlockProcess"
    
    BlockProcess () : base () {
        $this.Statement = "ProcessBlock"
    }

    [string] graph (){
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        return $string
    }
}
