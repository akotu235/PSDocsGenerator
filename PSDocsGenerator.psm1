<#
.SYNOPSIS
Creates an markdown file based on help.
.DESCRIPTION
Convert PowerShell help information to a markdown file.
.PARAMETER ModuleName
Specifies the name of the module for which you want to generate the markdown file with documentation. Looks up the specified module name in $ Env:PSModulePath.
.PARAMETER ModulePath
Specifies the path of the module for which you want to generate the markdown file with documentation. This parameter accepts the path to the folder that contains the module.
.PARAMETER Destination
Specifies the path to where the documentation files are saved. The default is desktop. Wildcards are not allowed.
.EXAMPLE
Convert-HelpToMarkdown
#>
function Convert-HelpToMarkdown{
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(ParameterSetName='ModuleName', Position=0, Mandatory=$true)]
        [System.String]$ModuleName,
        [Parameter(ParameterSetName='ModulePath', Mandatory=$true)]
        [System.String]$ModulePath,
        [System.String]$Destination = "$HOME\Desktop\"
    )
    if($ModulePath){
        $ModuleName = (Split-Path $ModulePath -Leaf).Trim(".ps{m,d}1")
        Import-Module $ModulePath
    }
    else{
        Import-Module $ModuleName
    }
    $commands = (Get-Module $ModuleName | select ExportedFunctions).ExportedFunctions
    $ModuleName = (Get-Module -Name $ModuleName).Name
    $commands.Keys | ForEach-Object {
        $help = Get-Help $_ 
        $MDFile = "$Destination\Docs\Modules\$ModuleName\$_.md"
        $functionName = $_
        $content = @"
# $_

## SYNOPSIS
$($help.Synopsis)

## SYNTAX
``````
$((Out-String -InputObject $help.syntax).Replace("`r","").Replace("`n","").Replace($_,"`n$_").Trim())
``````

## DESCRIPTION
$($help.description.Text)

## PARAMETERS
$($help.parameters.parameter | ForEach-Object {
        if(($_.name) -notlike "WhatIf" -and ($_.name) -notlike "Confirm" ){
            "`n### -$($_.name)`n"
            $description = ""
            $((Out-String -InputObject $_.description).Split("`n") | ForEach-Object {$description+=$_.Trim()})
            "$description`n"
            "``````yaml`n"
            "Type: $($_.type.name)`n"
            "Required: $($_.required)`n"
            "Position: $($_.position)`n"
            "Default value: $(if(-not $_.defaultValue){'none'}else{$_.defaultValue.Trim('"')})`n"
            "Accept pipeline input: $($_.pipelineInput)`n"
            "Accept wildcard characters: $($_.globbing)`n"
            "```````n"
        }
    })
## RELATED LINKS
$($commands.Keys | ForEach-Object {
    if($functionName -notlike $_){
        "[$_]($_.md)`n`n"
    }
})
"@
        $content = $content.Split("`n") | ForEach-Object {"$($_.Trim())"}
        if(-not (Test-Path $MDFile)){
            New-Item $MDFile -Force >> $null
        }
        Set-Content $MDFile $content -Force
    }
}