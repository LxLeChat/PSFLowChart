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
                                    $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($node.nodeId)                                    
                                    $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNode)
                                    $node.LinkedBrothers = $LinkedList
                                    $node.LinkedNodeId = $LinkedNode
                                    $x += $node
                            }
                        }

                        If ( $null -ne $t.raw.ElseClause ) {
                            $node = [ElseNode]::new($t.raw.ElseClause,$t.Statement)
                            $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($node.nodeId)
                            $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNode)
                            $node.LinkedBrothers = $LinkedList
                            $node.LinkedNodeId = $LinkedNode
                            $x += $node
                        }
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
    $Nodeid
    $LinkedBrothers
    $LinkedNodeId
    hidden $code
    hidden $NewContent
    hidden $raw
    hidden $DefaultShape

    node () {
        
    }

    node ([Ast]$e) {
        $this.raw = $e
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.Guid()
        $this.DefaultShape = [nodeutility]::SetDefaultShape($this.Type)
    }

    node ([Ast]$e,[node]$f) {
        $this.raw = $e
        $this.parent = $f
        $this.file = $e.extent.file
        $this.SetDepth()
        $this.Guid()
        $this.DefaultShape = [nodeutility]::SetDefaultShape($this.Type)
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

                If ( ($node.Type -eq "If") -and ($node.Depth -eq 2)  ) {
                    write-verbose "find-children $($node.Statement)"
                    $LinkedNodeEndIf = [System.Collections.Generic.LinkedListNode[string]]::new("End_"+$node.Nodeid)
                    $LinkedList.AddLast($LinkedNodeEndIf)
                    If ( $node.raw.Clauses.Count -ge 1 ) {
                        for( $i=1; $i -lt $node.raw.Clauses.Count ; $i++ ) {
                                $nodeElseIf = [ElseIfNode]::new($node.raw.clauses[$i].Item1,$this,$node.Statement)
                                $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($nodeElseIf.nodeId)
                                $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNode)
                                $nodeElseIf.LinkedBrothers = $LinkedList
                                $nodeElseIf.LinkedNodeId = $LinkedNode
                                $this.Children.add($nodeElseIf)
                        }
                    }

                    If ( $null -ne $node.raw.ElseClause ) {
                        $nodeElse = [ElseNode]::new($node.raw.ElseClause,$this,$node.Statement)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($nodeElse.nodeId)
                        $LinkedList.AddBefore($LinkedNodeEndIf,$LinkedNode)
                        $nodeElse.LinkedBrothers = $LinkedList
                        $nodeElse.LinkedNodeId = $LinkedNode
                        $this.Children.add($nodeElse)
                    }
                }
            }
        }

        <## si il n y a pas d'enfant on ajotue un process block
        If ( $this.Children.Count -eq 0 ) {
            $node = [BlockProcess]::new()
            $LinkedNode = [System.Collections.Generic.LinkedListNode[string]]::new($node.Nodeid)
            $LinkedList.AddLast($LinkedNode)
            $node.LinkedNodeId = $LinkedNode
            $this.Children.add($node)
        }
        #>
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

        If ( $this.raw.Clauses.Count -gt 1 ) {
            $this.Statement = "If ( {0} )" -f $this.raw.Clauses[0].Item1.Extent.Text
            $this.Code = $this.raw.Clauses[0].Item2.Extent.Text
        }
        Write-Verbose $this.Statement
        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

    }

    IfNode ([Ast]$e,[node]$f) : base ($e,$f) {

        write-verbose $this.raw.Clauses[0].Item1.Extent.Text

        If ( $this.raw.Clauses.Count -gt 0 ) {
            Write-Verbose "OKAY"
            write-verbose $this.raw.Clauses[0].Item1.Extent.Text
            $this.Statement = "If ( {0} )" -f $this.raw.Clauses[0].Item1.Extent.Text
            $this.Code = $this.raw.Clauses[0].Item2.Extent.Text
        }

        $this.FindChildren($this.raw.Clauses[0].Item2.Statements,$this)

    }

    [string] graph () {
        $TopEndIf=''
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string+";node End_"+$this.Nodeid+" -attributes @{Label='End "+$this.Statement+"'}"
        $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.LinkedNodeId.Next.Value+" -attributes @{Label='False'}"


        If ( $this.Children.count -gt 0 ) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.Children[0].NodeId+" -attributes @{Label='True'}"
            If ( ($null -ne $this.Parent) -and ($this.Parent -is [IfNode]) ) {
                $string = $string +";Edge -from "+$This.Children[-1].NodeId+" -to End_"+$this.Nodeid
            } else {
                Write-Verbose "PUTAIN on est pas passé ici ...$($this.Statement)"
            }
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
            $string = $string +";Edge -from "+$This.Children[-1].NodeId+" -to "+$This.LinkedNodeId.Next.Value
        } Else {
            $string = $string +";node Process_"+$this.nodeId+" -attributes @{Label='Process'}"
            $string = $string +";Edge -from "+$this.NodeId+" -to Process_"+$this.nodeId
            $string = $string +";Edge -from Process_"+$this.nodeId+" -to "+$This.LinkedNodeId.Next.Value
        }

        If ( ($null -ne $this.Parent) -and ($this.Parent -is [IfNode]) ) {
            $TopEndIf = "End_"+$this.parent.nodeId
            Write-Verbose "On est ici: $TopEndIf"
            $string = $string +";Edge -from "+$This.LinkedNodeId.Next.Value+" -to "+$TopEndIf
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
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.LinkedNodeId.Next.Value+" -attributes @{Label='False'}"
        If ( $this.Children.count -gt 0 ) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$This.Children[0].NodeId+" -attributes @{Label='True'}"
        } Else {
            $string = $string +";node Process_"+$this.nodeId+" -attributes @{Label='Process'}"
            $string = $string +";Edge -from "+$this.NodeId+" -to Process_"+$this.nodeId+" -attributes @{Label='True'}"

            $EndIf = ""
            $plop = $null
            ## vu qu on sait pas combien de eleseif ils y a il faut trouver le end_if suivant, pour faire le edge de process à end_if
            ## sinon le noeud prochain peut etre le else .. du coup pas bon
            while ( $EndIf -notlike "End_*" ) {
                If ( $null -eq $plop ) {
                    $EndIf = $this.LinkedNodeId.Next.value
                } else {
                    $EndIf = $plop.Next.Value
                }
                
                If ( $EndIf -notlike "End_*"){
                    $plop = $this.LinkedBrothers.find($EndIf)
                }
            }
            $string = $string +";Edge -from Process_"+$this.nodeId+" -to "+$EndIf
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
        $string = ""
        $string = "node "+$this.Nodeid+" -attributes @{Label='"+$this.Statement+"'}"
        $string = $string+";node Next_"+$this.Nodeid+" -attributes @{Label='Next "+$this.raw.Condition+"'}"
        $string = $string +";Edge -from Next_"+$this.Nodeid+" -to "+$this.nodeId+" -attributes @{Label='Loop'}"
        If ( $this.Children.count -gt 0 ) {
            $string = $string +";Edge -from "+$this.NodeId+" -to "+$this.Children[0].NodeId
            $string = $string +";Edge -from "+$this.Children[-1].LinkedBrothers.Last.Value+" -to Next_"+$this.Nodeid
        } else {
            $string = $string +";node Process_"+$this.nodeId+" -attributes @{Label='Process'}"
            $string = $string +";Edge -from "+$this.NodeId+" -to Process_"+$this.nodeId
            $string = $string +";Edge -from Process_"+$this.nodeId+" -to Next_"+$this.Nodeid
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
    
    BlockProcess () {
        $this.Statement =  "aaaa"
    }
}

#$x=[nodeutility]::ParseFile("$PWD\plop.ps1")