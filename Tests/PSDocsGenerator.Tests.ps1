BeforeAll{
    $ModuleName = "PSDocsGenerator"
    Remove-Module $ModuleName -Force -ErrorAction SilentlyContinue
    Import-Module "$PSScriptRoot\..\$ModuleName"
    $samples = "$([System.IO.Path]::GetTempPath())\PSDGTests"
    $sampleModule = "$([System.IO.Path]::GetTempPath())\PSDGTests\TestModule"
}
Context 'creating documentation for a fully described module'{
    BeforeAll{
        New-Item -ItemType Directory -Path $sampleModule -Force
        $module = @"
<#
.SYNOPSIS
Synopsis Test-Function1.
.DESCRIPTION
Description Test-Function1.
.PARAMETER ParameterA
ParameterA description.
.PARAMETER ParameterB
ParameterB description.
.PARAMETER ParameterC
ParameterC description.
.EXAMPLE
Test-Function1 "A"
#>
function Test-Function1{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName='ParameterSetA', Position=0, Mandatory=`$true)]
        [System.String]`$ParameterA,
        [Parameter(ParameterSetName='ParameterSetB')]
        [System.String]`$ParameterB,
        [System.String]`$ParameterC = "C"
    )
    Write-Host "Test-Function1"
}

<#
.SYNOPSIS
Synopsis Test-Function2.
.DESCRIPTION
Description Test-Function2.
.PARAMETER ParameterA
ParameterA description.
.PARAMETER ParameterB
ParameterB description.
.PARAMETER ParameterC
ParameterC description.
.EXAMPLE
Test-Function2 "A"
#>
function Test-Function2{
    param(
        [Parameter(ParameterSetName='ParameterSetA', Position=0, Mandatory=`$true)]
        [System.String]`$ParameterA,
        [Parameter(ParameterSetName='ParameterSetB')]
        [System.String]`$ParameterB,
        [System.String]`$ParameterC = "C"
    )
    Write-Host "Test-Function2"
}
"@
        Set-Content -Path "$sampleModule\testmodule.psm1" -Value $module -Force
        New-ModuleManifest -Path "$sampleModule\TestModule.psd1" -RootModule "testmodule.psm1" -Description "Module description"
        Convert-HelpToMarkdown -ModulePath $sampleModule -Destination $samples
    }
    Describe 'Convert-HelpToMarkdown'{
        It 'should create the appropriate documentation files'{
            $result = (Get-ChildItem "$samples\Docs\Modules" -Recurse | Select-Object -Property Name).Name
            $result | Should -Contain "Test-Function1.md"
            $result | Should -Contain "Test-Function2.md"
            $result | Should -Contain "TestModule.md"
        }
        Context 'module documentation file content'{
            It 'should contain the name of the module'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $result | Should -Contain "# TestModule Module"
            }
            It 'should contain DESCRIPTION section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $result | Should -Contain "## Description"
                $result | Should -Contain "[\\]: # (END DESCRIPTION)"
            }
            It 'should contain CMDLETS section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $result | Should -Contain "## TestModule Cmdlets"
                $result | Should -Contain "[\\]: # (END CMDLETS)"
            }
            It 'should contain DESCRIPTION section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $result | Should -Contain "Module description"
            }
            It 'should contain CMDLETS section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $result | Should -Contain "### [Test-Function1](Test-Function1.md)"
                $result | Should -Contain "Synopsis Test-Function1."
                $result | Should -Contain "### [Test-Function2](Test-Function2.md)"
                $result | Should -Contain "Synopsis Test-Function2."
            }
            It 'should contain an appropriate number of lines in the DESCRIPTION section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $Beginning = ($result | Select-String "## Description").LineNumber
                $End = ($result | Select-String "END DESCRIPTION").LineNumber
                $End - $Beginning | Should -BeExactly 3
            }
            It 'should contain an appropriate number of lines in the CMDLETS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $Beginning = ($result | Select-String "## TestModule Cmdlets").LineNumber
                $End = ($result | Select-String "END CMDLETS").LineNumber
                $End - $Beginning | Should -BeExactly 8
            }  
        }
        Context 'module documentation file structure'{
            It 'should include a TITLE section before the DESCRIPTION section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $TitleLineNumber = ($result | Select-String "^# TestModule Module").LineNumber
                $DescriptionLineNumber = ($result | Select-String "^## Description").LineNumber
                $TitleLineNumber | Should -BeLessThan $DescriptionLineNumber
            }
            It 'should include a DESCRIPTION section before the CMDLETS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $DescriptionLineNumber = ($result | Select-String "^## Description").LineNumber
                $CmdletsLineNumber = ($result | Select-String "^## TestModule Cmdlets").LineNumber
                $DescriptionLineNumber | Should -BeLessThan $CmdletsLineNumber
            }
            It 'should contain a space after the TITLE section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $SpaceIndex = ($result | Select-String "^# TestModule Module").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space after the DESCRIPTION section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $SpaceIndex = ($result | Select-String "END DESCRIPTION").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END DESCRIPTION section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $SpaceIndex = ($result | Select-String "END DESCRIPTION").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END CMDLETS section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $SpaceIndex = ($result | Select-String "END CMDLETS").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before each function in CMDLETS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\TestModule.md"
                $SpaceIndexes =  @()
                ($result | Select-String "^### .[a-z].[a-z1-9]..[a-z].[a-z1-9].").LineNumber | ForEach-Object {$SpaceIndexes += ($_-2)}
                $SpaceIndexes | ForEach-Object {
                    $result[$_] | Should -BeLike ""
                }
            }
        }
        Context 'function documentation file content'{
            It 'should contain the name of the module'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain '# Test-Function1'
            }
            It 'should contain SYNOPSIS section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain "## SYNOPSIS"
                $result | Should -Contain '[\\]: # (END SYNOPSIS)'
            }
            It 'should contain SYNTAX section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain "## SYNTAX"
                $result | Should -Contain '[\\]: # (END SYNTAX)'
            }
            It 'should contain DESCRIPTION section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain "## DESCRIPTION"
                $result | Should -Contain '[\\]: # (END DESCRIPTION)'
            }
            It 'should contain PARAMETERS section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain "## PARAMETERS"
                $result | Should -Contain '[\\]: # (END PARAMETERS)'
            }
            It 'should contain RELATED LINKS section tags'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain "## RELATED LINKS"
                $result | Should -Contain '[\\]: # (END RELATED LINKS)'
            }
            It 'should contain SYNOPSIS section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain 'Synopsis Test-Function1.'
            }
            It 'should contain SYNTAX section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain 'Test-Function1 [-ParameterA] <String> [-ParameterC <String>] [-WhatIf] [-Confirm] [<CommonParameters>]'
                $result | Should -Contain 'Test-Function1 [-ParameterB <String>] [-ParameterC <String>] [-WhatIf] [-Confirm] [<CommonParameters>]'
            }
            It 'should contain DESCRIPTION section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain 'Description Test-Function1.'
            }
            It 'should contain PARAMETERS section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain '### -ParameterA'
                $result | Should -Contain 'ParameterA description.'
                $result | Should -Contain '```yaml'
                $result | Should -Contain 'Type: String'
                $result | Should -Contain 'Required: false'
                $result | Should -Contain 'Position: named'
                $result | Should -Contain 'Default value: none'
                $result | Should -Contain 'Accept pipeline input: false'
                $result | Should -Contain 'Accept wildcard characters: false'
                $result | Should -Contain '```'
                $result | Should -Contain '### -WhatIf'
                $result | Should -Contain 'Prompts you for confirmation before running the `Test-Function1`.'
                $result | Should -Contain '### -Confirm'
                $result | Should -Contain 'Shows what would happen if the `Test-Function1` runs. The cmdlet is not run.'
                $result | Should -Contain '### CommonParameters'
                $result | Should -Contain '### -ParameterB'
                $result | Should -Contain 'ParameterB description.'
                $result | Should -Contain '### -ParameterC'
                $result | Should -Contain 'ParameterC description.'
            }
            It 'should contain RELATED LINKS section content'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $result | Should -Contain '[Test-Function2](Test-Function2.md)'
            }
            It 'should contain an appropriate number of lines in the SYNOPSIS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $Beginning = ($result | Select-String "## SYNOPSIS").LineNumber
                $End = ($result | Select-String "END SYNOPSIS").LineNumber
                $End - $Beginning | Should -BeExactly 3
            }
            It 'should contain an appropriate number of lines in the SYNTAX section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $Beginning = ($result | Select-String "## SYNTAX").LineNumber
                $End = ($result | Select-String "END SYNTAX").LineNumber
                $End - $Beginning | Should -BeExactly 6
            }
            It 'should contain an appropriate number of lines in the DESCRIPTION section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $Beginning = ($result | Select-String "## DESCRIPTION").LineNumber
                $End = ($result | Select-String "END DESCRIPTION").LineNumber
                $End - $Beginning | Should -BeExactly 3
            }
            It 'should contain an appropriate number of lines in the PARAMETERS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $Beginning = ($result | Select-String "## PARAMETERS").LineNumber
                $End = ($result | Select-String "END PARAMETERS").LineNumber
                $End - $Beginning | Should -BeExactly 60
            }
            It 'should contain an appropriate number of lines in the RELATED LINKS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $Beginning = ($result | Select-String "## RELATED LINKS").LineNumber
                $End = ($result | Select-String "END RELATED LINKS").LineNumber
                $End - $Beginning | Should -BeExactly 3
            }
        }
        Context 'function documentation file structure'{
            It 'should include a TITLE section before the SYNOPSIS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $TitleLineNumber = ($result | Select-String "^# Test-Function1").LineNumber
                $SynopsisLineNumber = ($result | Select-String "^## SYNOPSIS").LineNumber
                $TitleLineNumber | Should -BeLessThan $SynopsisLineNumber
            }
            It 'should include a SYNOPSIS section before the SYNTAX section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SynopsisLineNumber = ($result | Select-String "^## SYNOPSIS").LineNumber
                $SyntaxLineNumber = ($result | Select-String "^## SYNTAX").LineNumber
                $SynopsisLineNumber | Should -BeLessThan $SyntaxLineNumber
            }
            It 'should include a SYNTAX section before the DESCRIPTION section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SyntaxLineNumber = ($result | Select-String "^## SYNTAX").LineNumber
                $DescriptionLineNumber = ($result | Select-String "^## DESCRIPTION").LineNumber
                $SyntaxLineNumber | Should -BeLessThan $DescriptionLineNumber
            }
            It 'should include a DESCRIPTION section before the PARAMETERS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $DescriptionLineNumber = ($result | Select-String "^## DESCRIPTION").LineNumber
                $ParametersLineNumber = ($result | Select-String "^## PARAMETERS").LineNumber
                $DescriptionLineNumber | Should -BeLessThan $ParametersLineNumber
            }
            It 'should include a PARAMETERS section before the RELATED LINKS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $ParametersLineNumber = ($result | Select-String "^## PARAMETERS").LineNumber
                $RelatedLinksLineNumber = ($result | Select-String "^## RELATED LINKS").LineNumber
                $ParametersLineNumber | Should -BeLessThan $RelatedLinksLineNumber
            }
            It 'should contain a space after the TITLE section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "^# Test-Function1").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space after the SYNOPSIS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END SYNOPSIS").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space after the SYNTAX section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END SYNTAX").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space after the DESCRIPTION section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END DESCRIPTION").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space after the PARAMETERS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END PARAMETERS").LineNumber
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END SYNOPSIS section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END SYNOPSIS").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END SYNTAX section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END SYNTAX").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END DESCRIPTION section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END DESCRIPTION").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END PARAMETERS section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END PARAMETERS").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before END RELATED LINKS section tag'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndex = ($result | Select-String "END RELATED LINKS").LineNumber - 2
                $result[$SpaceIndex] | Should -BeLike ""
            }
            It 'should contain a space before each parameter in PARAMETERS section'{
                $result = Get-Content "$samples\Docs\Modules\TestModule\Test-Function1.md"
                $SpaceIndexes =  @()
                ($result | Select-String "^### .[a-z]$").LineNumber | ForEach-Object {$SpaceIndexes += ($_-2)}
                $SpaceIndexes | ForEach-Object {
                    $result[$_] | Should -BeLike ""
                }
            }
        }
    }
}