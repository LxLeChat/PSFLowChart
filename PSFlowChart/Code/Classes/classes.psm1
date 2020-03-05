using namespace System.Management.Automation.Language

enum GraphMode {
    Debug
    Standard
    Description
}

class node {
    [String]$Name
    [String]$Statement
    [String]$Id
    [Int]$Depth
    [Int]$Position
    [node[]]$Children
    [node]$Parent
    [string]$shape
    $link
    [string]$Label
    hidden $RawAST

    ## Methode Static qui retour un tableau de types d'AST qui nous interesse
    [object[]] static GetASTitems () {
        return @(
            [ForEachStatementAst],
            [IfStatementAst],
            [WhileStatementAst],
            [SwitchStatementAst],
            [ForStatementAst],
            [DoUntilStatementAst],
            [DoWhileStatementAst],
            [TryStatementAst],
            [ReturnStatementAst],
            [ExitStatementAst],
            [ContinueStatementAst],
            [BreakStatementAst]
        )
    }

    ## Methode Static pour Parser un fichier de script
    [node[]] static ParseFile ([string]$File) {
        ## sera retourner
        $x = @()

        ## On parse le fichier
        $ParsedFile = [Parser]::ParseFile($file, [ref]$null, [ref]$Null)

        ## un script  commence toujours par un nameblockast, on recherche donc ce type d'AST
        $NamedBlock = $ParsedFile.find({$args[0] -is [namedblockast]},$false)
        
        ## Nous Sert pour la position du noeud
        $i=0

        ## Pour la profondeur de defaut
        $RootDepth = 0

        ## tmp est utilisé lorsque on a un AST qui n'est pas dans les type qu'on recherche
        $tmp = $false

        ## creation d'une linkedlist, afin de pouvoir retrouver les noeuds de même niveau
        $SameLevelNode = [System.Collections.Generic.LinkedList[node]]::new()

        ## On parcour toutes les AST
        foreach ( $node in  $NamedBlock.FindAll({$args[0] -is [ast]},$false) ) {

            ## Si l'AST est dans les AST qui nou interesse et que le parent de cet AST est le NAMEDBLOCK
            If ( ($node.GetType() -in [node]::GetASTitems() ) -and ($node.Parent -eq $NamedBlock) ) {
                $tmp = $false
                $NewNode = [node]::SetNode($null,$node,$RootDepth,$i)
                $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                $SameLevelNode.AddLast($LinkedNode)
                $NewNode.Link = $SameLevelNode
                $x += $NewNode
                $i++
            } elseif ( (-not $tmp) -and ($node.parent -eq $NamedBlock) ) {
                ## SI qu on est pas dans le cas d un AST qui nou interresse et dont le parent est NAMEDBLOCK, est que tmp est false
                ## on passe tmp a true et on cree un processblock, qui represente tout le code jusqu au prochain AST qui nou interesse
                $tmp = $true
                $NewNode = [ProcessBlock]::new($null,$RootDepth,$i)
                $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                $SameLevelNode.AddLast($LinkedNode)
                $NewNode.Link = $SameLevelNode
                $x += $NewNode
                $i++
            }

        }
        return $x
    }

    ## Methode Static pour Parser un ScriptBlock 
    [node[]] static ParseScriptBlock ([ScriptBlock]$ScriptBlock) {
        ## sera retourner
        $x = @()

        ## un script  commence toujours par un nameblockast, on recherche donc ce type d'AST
        $NamedBlock = $ScriptBlock.Ast.find({$args[0] -is [namedblockast]},$false)
        
        ## Nous Sert pour la position du noeud
        $i=0

        ## Pour la profondeur de defaut
        $RootDepth = 0

        ## tmp est utilisé lorsque on a un AST qui n'est pas dans les type qu'on recherche
        $tmp = $false

        ## creation d'une linkedlist, afin de pouvoir retrouver les noeuds de même niveau
        # $SameLevelNode = [System.Collections.Generic.LinkedList[string]]::new()
        $SameLevelNode = [System.Collections.Generic.LinkedList[node]]::new()

        ## On parcour toutes les AST
        foreach ( $node in  $NamedBlock.FindAll({$args[0] -is [ast]},$false) ) {

            ## Si l'AST est dans les AST qui nou interesse et que le parent de cet AST est le NAMEDBLOCK
            If ( ($node.GetType() -in [node]::GetASTitems() ) -and ($node.Parent -eq $NamedBlock) ) {
                $tmp = $false
                $NewNode = [node]::SetNode($null,$node,$RootDepth,$i)
                $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                $SameLevelNode.AddLast($LinkedNode)
                $NewNode.Link = $SameLevelNode
                $x += $NewNode
                $i++
            } elseif ( (-not $tmp) -and ($node.parent -eq $NamedBlock) ) {
                ## SI qu on est pas dans le cas d un AST qui nou interresse et dont le parent est NAMEDBLOCK, est que tmp est false
                ## on passe tmp a true et on cree un processblock, qui represente tout le code jusqu au prochain AST qui nous interesse
                $tmp = $true
                $NewNode = [ProcessBlock]::new($null,$RootDepth,$i)
                $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                $SameLevelNode.AddLast($LinkedNode)
                $NewNode.Link = $SameLevelNode
                $x += $NewNode
                $i++
            }
            
        }
        return $x
    }

    ## Method Static permet de retourner un object de type node à partir d'un ast
    [node] static SetNode ([node]$Parent,[Ast]$Ast,[int]$Depth,[int]$Position) {
        $node = $null
        Switch ( $Ast ) {
            { $psitem -is [IfStatementAst] } { $node = [IfNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [ForEachStatementAst] } { $node = [ForeachNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [ForStatementAst] } { $node = [ForNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [WhileStatementAst] } { $node = [WhileNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [DoWhileStatementAst] } { $node = [DoWhileNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [DoUntilStatementAst] } { $node = [DoUntilNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [TryStatementAst] } { $node = [TryNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [ExitStatementAst] } { $node = [ExitKeyWord]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [SwitchStatementAst] } { $node = [SwitchNode]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [ContinueStatementAst] } { $node = [ContinueKeyWord]::new($Parent,$PSItem,$Depth,$Position) }
            { $psitem -is [BreakStatementAst] } { $node = [BreakKeyWord]::new($Parent,$PSItem,$Depth,$Position) }
        }
        return $node
    }

    ## Constructeur vide, necessaire pour l'heritage
    node(){}

    ## Constructeur dédié aux processblock
    node ([node]$Parent,[int]$Depth,[int]$position) {
        Write-Verbose "$($this.Gettype().Name) --> Constructor, Depth -> $($Depth), Position -> $($Position)"
        $this.Name = $this.GetType().Name
        $this.Depth = $Depth
        $this.Position = $position
        $this.Parent = $Parent
        If ( $this.Depth -gt 0 ) {
            $this.Id = "{0}{1}{2}" -f $this.Parent.Id,$this.Depth.ToString(),$this.Position.ToString()
        } else {
            $this.Id = "{0}{1}" -f $this.Depth.ToString(),$this.Position.ToString()
        }
        
    }

    ## Pour les noeuds normaux
    node ([node]$Parent,[Ast]$Ast,[int]$Depth,[int]$position) {
        Write-Verbose "$($this.Gettype().Name) --> Constructor, Depth -> $($Depth), Position -> $($Position)"
        $this.Name = $this.GetType().Name
        $this.Depth = $Depth
        $this.RawAST = $Ast
        $this.Position = $position
        $this.Parent = $Parent
        If ( $this.Depth -gt 0 ) {
            $this.Id = "{0}{1}{2}" -f $this.Parent.Id,$this.Depth.ToString(),$this.Position.ToString()
        } else {
            $this.Id = "{0}{1}" -f $this.Depth.ToString(),$this.Position.ToString()
        }

        ## on cherche les enfants
        $this.findChildren()
    }

    ## Remplit la propriété children pour le noeud
    [void] FindChildren () {

        ## Nous Sert pour la position du noeud
        $i=0
        $tmp = $false

        ## creation d'une linkedlist, afin de pouvoir retrouver les noeuds de même niveau
        # $SameLevelNode = [System.Collections.Generic.LinkedList[string]]::new()
        $SameLevelNode = [System.Collections.Generic.LinkedList[node]]::new()

        ## En fonction du type, pour le If c'est différent car un tuple, et on veut que le else ou le elseif soit un enfant
        Switch ($this) {

            ## FindChildren() quand le type: ForeachNode, ForNode, WhileNode, DoWhileNode, DoUntilNode, CatchNode
            { ($PSItem -is [ForeachNode]) -or ($PSItem -is [ForNode]) -or ($PSItem -is [WhileNode]) -or ($PSItem -is [DoWhileNode]) -or ($PSItem -is [DoUntilNode]) -or ($PSItem -is [CatchNode]) } {
                
                Write-Verbose "$($this.Gettype().Name) -> FindChildren()"
                foreach ( $node in $this.RawAST.Body.FindAll({$args[0] -is [ast] },$false) ) {
                    ## Si l'AST est dans les AST qui nous interesse et que le parent de cet AST est le NAMEDBLOCK
                    If ( ( $node.GetType() -in [node]::GetASTitems() ) -and ($node.Parent -eq $this.RawAST.Body) ) {
                        $tmp = $false
                        $NewNode = [node]::SetNode($this,$node,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }

                    If ( ( $node.GetType() -notin [node]::GetASTitems() )-and (-not $tmp) -and ($node.parent -eq $this.RawAST.Body) ) {
                        $tmp = $true
                        $NewNode = [ProcessBlock]::new($this,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children+= $NewNode
                        $i++
                    }
                }
            }

            ## FindChildren() quand le type: IfNode
            ([IfNode])   {
                Write-Verbose "$($this.Gettype().Name) -> FindChildren()"
                ## Clauses[0] represent le corps du if {}
                foreach ( $node in $this.RawAST.Clauses[0].Item2.FindAll({$args[0] -is [ast] },$false) ) {
                    ## Si l'AST est dans les AST qui nous interesse et que le parent de cet AST est le NAMEDBLOCK
                    If (  ( $node.GetType() -in [node]::GetASTitems() ) -and ($node.Parent -eq $this.RawAST.Clauses[0].Item2) ) {
                        $tmp = $false
                        $NewNode = [node]::SetNode($this,$node,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }

                    If ( ( $node.GetType() -notin [node]::GetASTitems() ) -and (-not $tmp) -and ($node.parent -eq $this.RawAST.Clauses[0].Item2) ) {
                        $tmp = $true
                        $NewNode = [ProcessBlock]::new($this,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }
                }

                ## Si on a d'autres Clauses, c'est qu on a des elseif
                If ( $this.RawAST.Clauses.Count -gt 1) {
                    ## La clause 0 étant le contenu du If {}
                    for ($Clause = 1; $Clause -lt $this.RawAST.Clauses.Count; $Clause++){
                        $NewNode = [ElseIfNode]::New($this,$this.RawAST.Clauses[$Clause].Item2,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }
                }

                ## Si le parametre ElseClause existe on a un else
                If ( $this.RawAST.ElseClause ) {
                    $NewNode = [ElseNode]::New($this,$this.RawAST.ElseClause,$this.Depth+1,$i)
                    $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                    $SameLevelNode.AddLast($LinkedNode)
                    $NewNode.Link = $SameLevelNode
                    $this.Children += $NewNode
                }
            }

            ## FindChildren() quand le type: IfNode
            ([SwitchNode])   {
                Write-Verbose "$($this.Gettype().Name) -> FindChildren()"

                ## On cree des switchcaseNode pour chaque case
                for ($Clause = 0; $Clause -lt $this.RawAST.Clauses.Count; $Clause++){
                    $NewNode = [SwitchCaseNode]::New($this,$this.RawAST.Clauses[$Clause].Item2,$this.Depth+1,$i)
                    $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                    $SameLevelNode.AddLast($LinkedNode)
                    $NewNode.Link = $SameLevelNode
                    $this.Children += $NewNode
                    $i++
                }

                ## Si le parametre Default existe on a un Default
                If ( $this.RawAST.Default ) {
                    $NewNode = [SwitchDefaultNode]::New($this,$this.RawAST.Default,$this.Depth+1,$i)
                    $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                    $SameLevelNode.AddLast($LinkedNode)
                    $NewNode.Link = $SameLevelNode
                    $this.Children += $NewNode
                }
            }

            ## FindChildren() quand le type: ElseNode, ElseIfNode
            { ($PSItem -is [ElseNode]) -or ($PSItem -is [ElseIfNode]) -or ($PSItem -is [SwitchCaseNode]) -or ($PSItem -is [SwitchDefaultNode]) -or ($PSItem -is [FinallyNode]) } {
                Write-Verbose "$($this.Gettype().Name) -> FindChildren()"
                foreach ( $node in $this.RawAST.FindAll({ $args[0] -is [ast] },$false) ) {
                    ## Si l'AST est dans les AST qui nous interesse et que le parent de cet AST est le NAMEDBLOCK
                    If ( ( $node.GetType() -in [node]::GetASTitems() ) -and ($node.Parent -eq $this.RawAST) ) {
                        $tmp = $false
                        $NewNode = [node]::SetNode($this,$node,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }

                    ## si c'est pas dans les ast qu on cherche que tmp n'est pas false et que le parent est bien l'ast parent on créé un processblock
                    If ( ( $node.GetType() -notin [node]::GetASTitems() ) -and (-not $tmp) -and ($node.parent -eq $this.RawAST) ) {
                        $tmp = $true
                        $NewNode = [ProcessBlock]::new($this,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }
                }
                
            }

            ## FindChildren() quand le type: TryNode
            ([TryNode])  {
                Write-Verbose "$($this.Gettype().Name) -> FindChildren()"
                foreach ( $node in $this.RawAST.Body.FindAll({$args[0] -is [ast] },$false) ) {
                    ## Si l'AST est dans les AST qui nous interesse et que le parent de cet AST est le NAMEDBLOCK
                    If ( ( $node.GetType() -in [node]::GetASTitems() ) -and ($node.Parent -eq $this.RawAST.Body) ) {
                        $tmp = $false
                        $NewNode = [node]::SetNode($this,$node,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }

                    If ( ($node -is [PipelineAst]) -and (-not $tmp) -and ($node.parent -eq $this.RawAST.Body) ) {
                        $tmp = $true
                        $NewNode = [ProcessBlock]::new($this,$this.Depth+1,$i)
                        $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                        $SameLevelNode.AddLast($LinkedNode)
                        $NewNode.Link = $SameLevelNode
                        $this.Children += $NewNode
                        $i++
                    }
                }

                ## On parcour le/les catcheclauses du try et on les ajoute aux children
                for ($Clause = 0; $Clause -lt $this.RawAST.CatchClauses.Count; $Clause++){
                    $NewNode = [CatchNode]::New($this,$this.RawAST.CatchClauses[$Clause],$this.Depth+1,$i)
                    $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                    $SameLevelNode.AddLast($LinkedNode)
                    $NewNode.Link = $SameLevelNode
                    $this.Children += $NewNode
                    $i++
                }

                ## si le il y a un block finally
                if ( $this.RawAST.Finally ) {
                    $NewNode = [FinallyNode]::New($this,$this.RawAST.Finally,$this.Depth+1,$i)
                    $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
                    $SameLevelNode.AddLast($LinkedNode)
                    $NewNode.Link = $SameLevelNode
                    $this.Children += $NewNode
                }
            }

        }

        ## Si le noeud n'a pas d'enfant
        ## et n'est pas des types definis...
        ## on ajoute un child
        if ( ($this.Children.Count -eq 0) -and ($this.GetType() -notin [ProcessBlock],[ContinuekeyWord],[BreakKeyWord],[ExitKeyWord] ) ) {
            $NewNode = [ProcessBlock]::new($this,$this.Depth+1,$i)
            $LinkedNode = [System.Collections.Generic.LinkedListNode[node]]::new($NewNode)
            $SameLevelNode.AddLast($LinkedNode)
            $NewNode.Link = $SameLevelNode
            $this.Children += $NewNode
        }

    }

    ## Method qui permet de trouver tous les noeud par type en recursif
    [node[]] FindNodeByType ([System.Type]$TypeToFind){
        $nodes = @()

        If ( $this.Children.count -gt 0 ) {
            foreach ( $child in $this.Children ) {
                If ( $child -is $TypeToFind ) {
                    $nodes += $child
                }
                Else {
                    $tmp = $child.FindNodeByType($TypeToFind)
                    If ( $tmp.count -gt 0 ) {
                        $tmp.ForEach({$nodes+=$_})
                    }
                }
            }
        }
        return $nodes
    }

    ## Method qui permet de trouver tous les noeud par type en recursif
    [node[]] FindNodeByTypeUp ([System.Type]$TypeToFind){
        $nodes = @()
        If ( $this -is $TypeToFind ) {
            $nodes += $this
            if ( $this.parent ) {
                $nodes += $this.parent.FindNodeByTypeUp($TypeToFind)
            }
        } else {
            if ( $this.parent ) {
                $nodes += $this.parent.FindNodeByTypeUp($TypeToFind)
            }
        }
        return $nodes
    }

    ## Method qui permet de trouver tous les noeud par type en recursif
    [node[]] FindNodeByTypeUp ([scriptblock]$Filter){
        $nodes = @()

        If ( $this.Where($Filter) ) {
            $nodes += $this
            if ( $this.parent ) {
                $nodes += $this.parent.FindNodeByTypeUp($filter)
            }
        } else {
            if ( $this.parent ) {
                $nodes += $this.parent.FindNodeByTypeUp($filter)
            }
        }
        return $nodes
    }

    ## Method qui cherche un noeud par son id
    ## utiliser surtout pour du debug
    [node[]] FindChildbyId ([string]$Id) {
        $node = @()

        If ( $this.Children.count -gt 0 ) {
            foreach ( $child in $this.Children ) {
                If ( $child.Id -eq $Id ) {
                    $node += $child
                }
                Else {
                    $node += $child.FindChildbyId($id)
                }
            }
        }
        return $node
    }

    ## Methode qui retourne le end node en fonction du type
    [string] GetEndId () {
        $string = $null
        Switch ( $this ) {
            ([TryNode]) {
                $FinallyBlock = $this.Children.Where({$_ -is [FinallyNode]})
                If ( $FinallyBlock ) {
                    $string = $FinallyBlock.Id
                } Else {
                    $string = "end_" + $this.Id
                }
                Break;
            }
            ([CatchNode]) { $string = $this.Parent.GetEndId() ; break }
            ([FinallyNode]) { $string = "end_" + $this.Id ; break }
            ([IfNode]) { $string = "end_" + $this.Id ; break }
            ([ElseIfNode]) { $string = $this.Parent.GetEndId() ; break }
            ([ElseNode]) { $string = $this.Parent.GetEndId() ; break}
            ([ForeachNode]) { $string = "end_" + $this.Id ; break  }
            ([ForNode]) { $string = "end_" + $this.Id ; break  }
            ([DoWhileNode]) { $string = "end_" + $this.Id ; break  }
            ([DoUntilNode]) { $string = "end_" + $this.Id ; break  }
            ([WhileNode]) { $string = "end_" + $this.Id ; break  }
            ([SwitchNode]) { $string = "end_" + $this.Id ; break  }
            ([SwitchCaseNode]) { $string = $this.Parent.GetEndId() ; break  }
            ([SwitchDefaultNode]) { $string = $this.Parent.GetEndId() ; break  }
            ([ProcessBlock]) { $string = $this.id ; break  }
        }
        return $string
    }

    ## Method utilise poure tourner l id vers le nextnode
    ## utilier pour le breakkeyword
    [string] GetNextNodeId () {
        $NextNode = $this.link.Find($this).Next.Value
        
        If ( $this.depth -eq 0 ) {
            If ( $null -eq $NextNode ) {
                return "'End Of Script'"
            } else {
                return $NextNode.id
            }
        } else {
            If ( $null -eq $NextNode ) {
                return $this.parent.GetNextNodeId()
            } else {
                return $NextNode.id
            }
        }
        return $null
    }

    ## Methode pour dessiner juste le noeud
    ## en fonction de son type on a quelques caractéristiques
    ## exemple: une boucle, il faut crééer la fin de la boucle + le edge qui represente l iteration
    [string] GraphNode([GraphMode]$Mode){
        Write-Verbose "$($this.Gettype().Name) --> GraphNode(), Id --> $($this.id)"
        $string = $null

        ## On cherche le noeud courant, dans la linkedlist
        $NodeInList = $this.link.find($this)

        ## si on est a la depth 0 et qu'on a pas de noeud avant, on trace un edge depuis le debut vers ce noeud
        ## sauf, si on est en presence d un try
        If ( ($this.Depth -eq 0) -and ($null -eq $NodeInList.Previous) -and ($this -isnot [TryNode]) ) {
            $string = $string + "edge -from 'Start Of Script' -to '" + $this.id + "';"
        }

        ## en fonction du type de noeud on fait des choses differentes
        If ( $Mode -eq "Debug" ) {
            Write-Verbose "$($this.Gettype().Name) --> GraphNode() --> Debug Mode, Id --> $($this.id)"
            switch ( $this ) {

                { $PSItem.Gettype() -in [SwitchNode],[SwitchCaseNode],[SwitchDefaultNode],[TryNode],[CatchNode],[FinallyNode],[IfNode],[ElseIfNode],[ForeachNode],[ForNode],[WhileNode],[ProcessBlock],[BreakKeyWord],[ContinuekeyWord] } {
                    ##commun a tous ces type de noeuds
                    $string = $string + "node '" + $this.id + "' -attributes @{Label='" + $this.GetType().Name + " " + $this.Id + "'};"
                    
                    Switch ($this){
                        ([SwitchNode]) {
                            ## on créé un endnode id
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='End Switch " + $this.Id + "'};"
                            return $string
                        }
                        ([TryNode]) {
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='End Try " + $this.Id + "'};"
                            return $string
                        }
                        ([IfNode]) {
                            ## on créé un endnode id
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='End If " + $this.Id + "'};"
                            return $string
                        }
                        ## Commun a ces types de loop
                        { $PSItem.Gettype() -in [ForeachNode],[ForNode],[WhileNode] } {
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='Loop To " + $this.Id + "'};"
                        }

                        ([ForeachNode]) {
                            ## on créé la boucle d iteration
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Next'};"
                            return $string
                        }
                        ([ForNode]) {
                            ## on créé la boucle d iteration
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Next'};"
                            return $string
                        }
                        ([WhileNode]) {
                            ## on créé la boucle d iteration
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Next'};"
                            return $string
                        }

                    }
                    
                }

                { $PSItem.Gettype() -in [DoWhileNode],[DoUntilNode] } {
                    ## Commun a ces types de noeuds
                    $string = $string + "node '" + $this.id + "' -attributes @{Label='Do'};"

                    Switch ($this) {
                        ([DoWhileNode]) {
                            ## on créé la boucle d iteration
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='While " + $this.Id + "'};"
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='While Statement'};"
                            return $string
                        }
            
                        ([DoUntilNode]) {
                            ## on créé la boucle d iteration
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='Until " + $this.Id + "'};"
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Until Statement'};"
                            return $string
                        }
                    }
                }

            }
        }

        If ( $Mode -eq "Standard" ) {
            Write-Verbose "$($this.Gettype().Name) --> GraphNode() --> Standard Mode, Id --> $($this.id)"
            switch ( $this ) {

                { $PSItem.Gettype() -in [SwitchNode],[SwitchCaseNode],[SwitchDefaultNode],[FinallyNode],[IfNode],[ElseIfNode],[ForeachNode],[ForNode],[WhileNode],[ProcessBlock],[BreakKeyWord],[ContinuekeyWord] } {
                    ##commun a tous ces type de noeuds
                    $string = $string + "node '" + $this.id + "' -attributes @{Label='" + $this.FormatStatement()+ "'};"
                    
                    Switch ($this){
                        ([SwitchNode]) {
                            ## on créé un endnode id
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Shape='point'};"
                            return $string
                        }
                        
                        ([IfNode]) {
                            ## on créé un endnode id
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Shape='point'};"
                            return $string
                        }
                        ## Commun a ces types de loop
                        { $PSItem.Gettype() -in [ForeachNode],[ForNode],[WhileNode] } {
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='Loop'};"
                        }

                        ([ForeachNode]) {
                            ## on créé la boucle d iteration
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Next'};"
                            return $string
                        }
                        ([ForNode]) {
                            ## on créé la boucle d iteration
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Next'};"
                            return $string
                        }
                        ([WhileNode]) {
                            ## on créé la boucle d iteration
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Next'};"
                            return $string
                        }

                    }
                    
                }

                { $PSItem.Gettype() -in [TryNode] } {
                    $string = $string + "node '" + $this.id + "' -attributes @{Shape='point'};"
                    $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Shape='point'};"
                    return $string
                }

                { $PSItem.Gettype() -in [CatchNode] } {
                    $string = $string + "node '" + $this.id + "' -attributes @{Label='"+$this.Statement+"'};"
                    return $string
                }

                { $PSItem.Gettype() -in [DoWhileNode],[DoUntilNode] } {
                    ## Commun a ces types de noeuds
                    $string = $string + "node '" + $this.id + "' -attributes @{Label='Do'};"

                    Switch ($this) {
                        ([DoWhileNode]) {
                            ## on créé la boucle d iteration
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='" + $this.FormatStatement() + "'};"
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='While'};"
                            return $string
                        }
            
                        ([DoUntilNode]) {
                            ## on créé la boucle d iteration
                            $string = $string + "node '" + $this.GetEndId() + "' -attributes @{Label='Until " + $this.FormatStatement() + "'};"
                            $String = $string + "edge -from " + $this.GetEndId() + " -to " + $this.id + " -attributes @{Label='Until'};"
                            return $string
                        }
                    }
                }

            }
        }
        
        return $string
    }

    [string] GraphNode ([bool]$x,[GraphMode]$Mode) {
        Write-Verbose "$($this.Gettype().Name) --> GraphNode()"
        $string = $null
        If ( $Mode -eq "Debug") {
            $string = "node '" + $this.Id + "' -attributes @{Label='"+ $this.GetType().Name + " " + $this.Id +"'};"
        } else {
            $string = "node '" + $this.Id + "' -attributes @{Label='"+$this.GetType().Name+"'};"
        }
       
        return $string
    }

    ## Pour tracer un edge vers le noeud suivant
    ## Sauf si on a une profondeur superieur a 0,
    ## alors il faut voir quel est le parent
    ## En revanche, si on est a une profondeur > 0,
    ## il faudra, si c'est le dernier parmis les enfants,
    ## s occuper de tracer le edge vers le parent
    [string] GraphToNextNode(){
        Write-Verbose "$($this.GetType().Name) --> GraphToNextNode(), Depth --> $($this.Depth), Id --> $($this.id)"
        $string = $null

        ## On cherche le noeud courant, dans la linkedlist
        $NodeInList = $this.link.find($this)

        If ( $this.Depth -eq 0 ) {
            
            ## en fonciton du type de noeud on fait des choses differentes
            switch ( $this.GetType() ) {
                {$PSItem -in [SwitchNode],[IfNode],[ForeachNode],[ForNode],[WhileNode],[DoUntilNode],[DoWhileNode],[ForNode],[ProcessBlock],[DoUntilNode],[DoWhileNode] } { 
                    # Write-Verbose "$($this.Gettype().Name) --> GraphToNextNode()"
                    ## Si il n y a pas de noeud suivant
                    If ( $null -eq $NodeInList.Next ) {
                        ## on trace vers la fin depuis le endnodeid
                        $string = $string + "edge -from " + $this.GetEndId() + " -to 'End Of Script';"
                        
                    } else {
                        ## on trace vers le noeud suivant depuis le endnodeid
                        $string = $string + "edge -from " + $this.GetEndId() + " -to " + $NodeInList.Next.Value.Id + ";"
                    }

                    break;
                }

                ([TryNode]) {
                    # Write-Verbose "$($this.Gettype().Name) --> GraphToNextNode()"
                    ## Si on a un block Finally, le end_id,
                    ## doit être celui du finally
                    $FinallyBlock = $this.Children.Where({$_ -is [FinallyNode]})
                    If ( $FinallyBlock ) {
                        $endid = $FinallyBlock.GetEndid()
                    } Else {
                        $endid = $this.GetEndId()
                    }

                    ## Si il n y a pas de noeud suivant
                    If ( $null -eq $NodeInList.Next ) {
                        ## on trace vers la fin depuis le endnodeid
                        $string = $string + "edge -from " + $endid + " -to 'End Of Script';"
                        
                    } else {
                        ## on trace vers le noeud suivant depuis le endnodeid
                        $string = $string + "edge -from " + $endid + " -to " + $NodeInList.Next.Value.Id + ";"
                    }

                    break;
                }
            }
        }


        If ( $this.Depth -gt 0 ) {
            
            ## en fonciton du type de noeud on fait des choses differentes
            switch ( $this ) {
                { $PSItem.Gettype() -in [IfNode],[SwitchNode],[ForeachNode],[ForNode],[WhileNode],[DoUntilNode],[DoWhileNode] } {
                    # Write-Verbose "$($this.Gettype().Name) --> GraphToNextNode()"
                    ## Si il n y a pas de noeud suivant
                    If ( $null -eq $NodeInList.Next ) {
                        ## on trace vers la fin depuis le endnodeid
                        ## ici le catchnode, va dessiner une boucle du end_try vers le end_try ...
                        $string = $string + "edge -from " + $this.GetEndId() + " -to " + $this.Parent.GetEndId() + ";"
                    } ElseIf ($NodeInList.Next.value.Gettype() -notin [ElseNode],[ElseIfNode],[CatchNode])  {
                        ## on trace vers le noeud suivant depuis le endnodeid
                        $string = $string + "edge -from " + $this.GetEndId() + " -to " + $NodeInList.Next.Value.Id + ";"
                    } ElseIf ($NodeInList.Next.value.Gettype() -in [ElseNode],[ElseIfNode],[CatchNode]) {
                        ## si le noeud suivant est un else, on trace vers le parent
                        $string = $string + "edge -from " + $this.GetEndid() + " -to " + $NodeInList.Next.Value.GetEndId() + ";"
                    }

                    break;
                }

                ( [TryNode] ) {
                    # Write-Verbose "$($this.Gettype().Name) --> GraphToNextNode()"
                    ## Si on a un block Finally, le end_id,
                    ## doit être celui du finally
                    $FinallyBlock = $this.Children.Where({$_ -is [FinallyNode]})
                    If ( $FinallyBlock ) {
                        $endid = $FinallyBlock.GetEndid()
                    } Else {
                        $endid = $this.GetEndId()
                    }


                    ## Si il n y a pas de noeud suivant
                    If ( $null -eq $NodeInList.Next ) {
                        ## on trace vers la fin depuis le endnodeid
                        ## ici le catchnode, va dessiner une boucle du end_try vers le end_try ...
                        $string = $string + "edge -from " + $endid + " -to " + $this.Parent.GetEndId() + ";"
                    } ElseIf ($NodeInList.Next.value.Gettype() -notin [ElseNode],[ElseIfNode])  {
                        ## on trace vers le noeud suivant depuis le endnodeid
                        $string = $string + "edge -from " + $endid + " -to " + $NodeInList.Next.Value.Id + ";"
                    } ElseIf ($NodeInList.Next.value.Gettype() -in [ElseNode],[ElseIfNode]) {
                        ## si le noeud suivant est un else, on trace vers le parent
                        $string = $string + "edge -from " + $endid + " -to " + $NodeInList.Next.Value.GetEndId() + ";"
                    }

                    break;
                }

                ( [ProcessBlock] ) {
                    # Write-Verbose "$($this.Gettype().Name) --> GraphToNextNode()"
                    ## Si il n y a pas de noeud suivant
                    If ( $null -eq $NodeInList.Next ) {
                        ## on trace vers la fin depuis le endnodeid
                        $string = $string + "edge -from " + $this.id + " -to " + $this.Parent.GetEndId() + ";"
                        
                    } ElseIf ($NodeInList.Next.value.Gettype() -notin [ElseNode],[ElseIfNode],[CatchNode]) {
                        ## on trace vers le noeud suivant depuis le endnodeid
                        $string = $string + "edge -from " + $this.id + " -to " + $NodeInList.Next.Value.Id + ";"
                    } ElseIf ($NodeInList.Next.value.Gettype() -in [ElseNode],[ElseIfNode],[CatchNode]) {
                        ## si le noeud suivant est un else, on trace vers le parent
                        $string = $string + "edge -from " + $this.id + " -to " + $NodeInList.Next.Value.GetEndId() + ";"
                    }

                    break;
                }


                ( [ExitKeyWord] ) {
                    # Write-Verbose "$($this.Gettype().Name) --> GraphToNextNode()"
                    $string = $string + "edge -from " + $this.id + " -to " + $this.Parent.GetEndId() + " -attributes @{style='dotted'};"
                    break;
                }

                ( [BreakKeyWord] ) {
                    ## si on a un label on cherche les loops avec ce label
                    if ( $this.Label ) {
                        $node = $this.FindNodeByTypeUp([loops]).where({$_.Label -eq $this.Label})
                    } else {
                        ## on cheche la boucle ou le switch le/la plus proche
                        $node = $this.FindNodeByTypeUp({($_ -is [loops]) -or ($_ -is [SwitchNode])}) | Select-Object -first 1
                    }

                    $string = $string + "edge -from " + $this.id + " -to " + $this.Parent.GetEndId() + " -attributes @{style='dotted'};"
                    $string = $string + "edge -from " + $this.id + " -to " + $node.GetNextNodeId() + " -attributes @{Label='Break From "+$node.id+"'};"
                }

                ( [ContinuekeyWord] ) {
                    ## si on a un label on cherche les loops avec ce label
                    if ( $this.Label ) {
                        $node = $this.FindNodeByTypeUp([loops]).where({$_.Label -eq $this.Label})
                    } else {
                        ## on cheche la bouce la plus proche
                        $node = $this.FindNodeByTypeUp({($_ -is [loops]) -or ($_ -is [SwitchNode])}) | Select-Object -first 1
                    }

                    $string = $string + "edge -from " + $this.id + " -to " + $this.Parent.GetEndId() + " -attributes @{style='dotted'};"
                    $string = $string + "edge -from " + $this.id + " -to " + $node.id + " -attributes @{Label='Continue'};"
                }

            }
        }

        return $string
        ## FIN GRAPHTONEXTNODE
    }

    ## Methode qui va dessiner le 1° edge
    ## vers le premier enfant.
    [string] GraphToChild([GraphMode]$Mode){

        $string = $null
        Switch ( $this ) {

            { $PSItem.Gettype() -in [SwitchNode] } {
                ## On graph un edge vers chaque child du Switch
                Foreach ( $child in $this.Children ) {
                    # $string = $string + "edge -from " + $this.id + " -to " + $child.id + " -attributes @{Label='Oupsy'};"
                    $string = $string + "edge -from " + $this.id + " -to " + $child.id + ";"
                }
            }

            { $PSItem.GetType() -in [IfNode] } { 
                ## On graph un edge True et un edge False
                $TrueNode = $this.Children.Where({$_.Gettype() -notin [ElseNode],[ElseIfNode]}) | Select-Object -First 1
                $FalseNode = $this.Children.Where({$_ -is [ElseIfNode]}) | Select-Object -First 1

                ## on a pas trouver de elseif, on cherche donc un elsenode
                If ( -not $FalseNode ) {
                    $tFalseNode = $this.Children.Where({$_ -is [ElseNode]})
                    If ( $tFalseNode ) {
                        $FalseNode = $tFalseNode.Children[0]
                    }
                }
                
                If ( $TrueNode ) {
                    $string = $string + "edge -from " + $this.id + " -to " + $TrueNode.id + " -attributes @{Label='True'};"
                }
                
                If ( $FalseNode ) {
                    $string = $string + "edge -from " + $this.id + " -to " + $FalseNode.id + " -attributes @{Label='False'};"
                }

                break;
            }

            ([ElseIfNode]) {

                ## On cherche le noeud courant, dans la linkedlist
                $NodeInList = $this.link.find($this)

                ## On graph un edge True et un edge False
                $TrueNode = $this.Children[0]
                $FalseNode = $NodeInList.Next.Value

                ## on cherche le noeud suivant, si il y en a un, c'est forcement un
                ## elseif ou un else.
                ## sinon on trace vers le endif
                If ( $FalseNode ) {
                    If ( $FalseNode -is [ElseNode] ) {
                        ## si le noeud suivant un else, on trace vers le 1° enfant du else
                        $String = $string + "edge -from " + $this.id + " -to " + $FalseNode.Children[0].Id + " -attributes @{Label='False'};"
                    } Else {
                        ## sinon le noeud suivant est un elseif
                        $String = $string + "edge -from " + $this.id + " -to " + $FalseNode.Id + " -attributes @{Label='False'};"
                    }
                    
                } else {
                    $String = $string + "edge -from " + $this.id + " -to " + $this.GetEndId() + " -attributes @{Label='False'};"
                }

                $string = $string + "edge -from " + $this.id + " -to " + $TrueNode.id + " -attributes @{Label='True'};"
            }

            { $PSItem.GetType() -in [SwitchCaseNode],[SwitchDefaultNode],[ForeachNode],[ForNode],[WhileNode],[Catchnode],[FinallyNode],[DoUntilNode],[DoWhileNode] } {
                ## du noeud de fin de boucle vers le noeud suivant
                $string = $string + "edge -from " + $this.id + " -to " + $this.Children[0].id + ";"
                break;
            }

            ([TryNode]) {
                ## on cherche les catchnode
                ## J'ai juste mis si c'était le catch all ou pas,
                ## mais on pourrait mettre le type qui est attendu aussi..
                Foreach ( $catchnode in $this.Children.Where({ $_ -is [CatchNode] }) ) {
                    $string = $string + "edge -from " + $this.id + " -to " + $CatchNode.id + ";"
                }

                ## on trace un edge vers le 1° enfant
                ## qui n est pas de type catchnode
                $FirstNonCatchNode = $this.Children.Where({ $_.Gettype() -notin [CatchNode],[FinallyNode] }) | Select-Object -First 1
                $string = $string + "edge -from " + $this.id + " -to " + $FirstNonCatchNode.id + ";"
            }
        }
        

        ## on lance le graph des child, sauf pour le catch,
        foreach ( $child in $this.Children ) {
                $string = $string + $child.Graph([GraphMode]$Mode)
        }

        return $string
        ## FIN GRAPHTOCHILD
    }
    
    ## Methode globale
    ## c'est elle qui est appellée si on veut grapher un noeud 
    [string] Graph ([GraphMode]$Mode) {
        $string = $null

        ## si on a un try en 1°, il faut tracer le edge du start of script d'abord
        ## sinon le start of script se retrouve dans le subgraph
        If ( ($this.Depth -eq 0) -and ($this -is [TryNode]) -and ($null -eq $this.link.find($this).Previous) ) {
            $string = $string + "edge -from 'Start Of Script' -to '" + $this.id + "';"
        }

        ## si c'est un trynode, on cree un subgraph
        If ( $this -is [TryNode]) {
            $string = $string + "subgraph -attributes @{label='TRY'} -scriptblock{"
        }

        $string = $string + $this.GraphNode([GraphMode]$Mode)
        $string = $string + $this.GraphToChild([GraphMode]$Mode)

        ## si c'est un trynode, on cree la fin du subgraph
        ## et on cherche le catch, qu'on graph apres le subgraph
        If ( $this -is [TryNode]) {
            $string = $string + "};"
        }

        $string = $string + $this.GraphToNextNode()
        
        ## on cree les exit node, et on trace les edge vers la fin du script
        ## on fait ça car sinon, dans le cas du try par exemple, le end of script
        ## se retrouvera dans le subgraph ...
        ## on ne fait que sur les noeuds de 1° niveau .. on cherche recursivement de 
        ## toute façon
        If ( $this.Depth -eq 0 ) {
            foreach ($node in $this.FindNodeByType([ExitKeyWord])) {
                $string = $string + $node.GraphNode($true,[GraphMode]$Mode)
                $string = $string + "edge -from " + $node.id + " -to 'End Of Script';"
            }
        }

        return $string
    }

    [String] FormatStatement () {
        return (($this.Statement -replace "'|""|\*", '') -replace '\\',"\\")
    }

}

class TryNode : node {
    TryNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {}
}

class CatchNode : node {
    CatchNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        If ( $this.RawAst.IsCatchAll ) {
            $this.Statement = "Catch: All"
        } Else {
            $this.Statement = "Catch: "
            for ($i = 0; $i -lt $this.RawAST.CatchTypes.Count; $i++) {
                if ( $i -eq 0 ) {
                    $this.Statement = $this.Statement + "" + $this.RawAST.CatchTypes[$i].TypeName.Name
                } Else {
                    $this.Statement = $this.Statement + ", " + $this.RawAST.CatchTypes[$i].TypeName.Name
                }
            }
        }
        
    }
}

class FinallyNode : node {
    FinallyNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "Finally"
    }
}

class IfNode : node {
    hidden [string] $shape = "diamond"
    IfNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "If: " + $this.rawast.Clauses.Item1[0].extent.text
    }
}

class ElseIfNode : node {
    hidden [string] $shape = "diamond"
    ElseIfNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "ElseIf: " + $this.rawast.parent.clauses.where({$_.item2 -eq $this.rawast}).item1.Extent.Text
    }
}

class ElseNode : node {
    ElseNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {}
}

class SwitchNode : node {
    hidden [string] $shape = "diamond"
    SwitchNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "Switch: " + $this.rawast.Condition.Extent.Text
    }
}

class SwitchCaseNode : node {
    hidden [string] $shape = "diamond"
    SwitchCaseNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "Case: " + $this.rawast.parent.clauses.where({$_.item2 -eq $this.rawast}).item1.Extent.Text
    }
}

class SwitchDefaultNode : node {
    hidden [string] $shape = "diamond"
    SwitchDefaultNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "Default Case"
    }
}

class Loops : node {
    hidden [string] $shape = "parallelogram"
    Loops ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {}
}

class ForeachNode : Loops {
    hidden [string] $shape = "parallelogram"
    ForeachNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        ## Check label
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        ## Fill Statement
        $this.Statement = "Foreach: " + $this.RawAST.Variable + " In " + $this.RawAST.Condition
    } 
}

class ForNode : Loops {
    hidden [string] $shape = "parallelogram"
    ForNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        ## Check label
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        ## Fill Statement
        $this.Statement = "For: " + $this.RawAST.Initializer.extent.text + ", Do " + $this.RawAST.condition.Extent.text + ", Ititerate: " + $this.rawast.iterator.Extent.text
    }
}

class WhileNode : Loops {
    hidden [string] $shape = "parallelogram"
    WhileNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        ## Check label
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        ## Fill Statement
        $this.Statement = "While: " + $this.RawAST.condition.Extent.text
    }
}

class DoWhileNode : Loops {
    hidden [string] $shape = "parallelogram"
    DoWhileNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        ## Check label
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        ## Fill Statement
        $this.Statement = "While: " + $this.RawAST.condition.Extent.text
    }
}

class DoUntilNode : Loops {
    hidden [string] $shape = "parallelogram"
    DoUntilNode ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        ## Check label
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        ## Fill Statement
        $this.Statement = "Until: " + $this.RawAST.condition.Extent.text
    }
}

class ProcessBlock : node {
    hidden [string] $shape = "box"
    ProcessBlock ($Parent,$Depth,$position) : base ($Parent,$Depth,$position) {
        $this.Statement = "Inner Code"
    }
}

class ExitKeyWord : node {
    hidden [string] $shape = "box"
    ExitKeyWord ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        $this.Statement = "Exit"
    }
}

class BreakKeyWord : node {
    hidden [string] $shape = "ellipse"
    BreakKeyWord ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        $this.Statement = "Break"
    }
}

class ContinuekeyWord : node {
    hidden [string] $shape = "ellipse"
    ContinuekeyWord ($Parent,$Ast,$Depth,$position) : base ($Parent,$Ast,$Depth,$position) {
        If ( $this.RawAST.Label ) {
            $this.Label = $this.RawAST.Label
        }

        $this.Statement = "Continue"
    }
}
