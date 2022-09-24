<#
.SYNOPSIS
Creates an markdown file based on help.
.DESCRIPTION
Convert PowerShell help information to a markdown file.
.PARAMETER ModuleName
Specifies the name of the module for which you want to generate the markdown file with documentation. Looks up the specified module name in ``$Env:PSModulePath``.
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
        if($ModulePath -like "*.ps?1"){
            $ModulePath = Split-Path $ModulePath -Parent
        }
        $ModuleName = (Split-Path $ModulePath -Leaf)
        Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
        Import-Module $ModulePath
    }
    else{
        Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
        Import-Module $ModuleName
    }
    $Module = Get-Module $ModuleName
    $commands = ($Module | select ExportedFunctions).ExportedFunctions
    $commands = $commands.Keys
    $commands | ForEach-Object {
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

$(if($help.description.Text){
    "## DESCRIPTION`n"
    $($help.description.Text)
})
$(if($help.parameters.parameter){
    "## PARAMETERS`n"
    $($help.parameters.parameter | ForEach-Object {
        "`n### -$($_.name)`n"
        if("WhatIf" -like ($_.name)){
            "Prompts you for confirmation before running the ``$functionName``.`n"
        }
        elseif("Confirm" -like ($_.name)){
            "Shows what would happen if the ``$functionName`` runs. The cmdlet is not run.`n"
        }
        else{
            $description = ""
            $((Out-String -InputObject $_.description).Split("`n") | ForEach-Object {$description+=$_.Trim()})
            "$description`n"
        }
        "``````yaml`n"
        "Type: $($_.type.name)`n"
        "Required: $($_.required)`n"
        "Position: $($_.position)`n"
        "Default value: $(if(-not $_.defaultValue){'none'}else{$_.defaultValue.Trim('"')})`n"
        "Accept pipeline input: $($_.pipelineInput)`n"
        "Accept wildcard characters: $($_.globbing)`n"
        "```````n"
    })
    $(if($((Out-String -InputObject $help.syntax) -like "*[<CommonParameters>]*")){
        "### CommonParameters`n"
        "This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, [see about_CommonParameters](https://docs.microsoft.com/pl-pl/powershell/module/microsoft.powershell.core/about/about_commonparameters).`n"
    })})
    $(if($commands.Count -gt 1){
        "## RELATED LINKS`n"
        $commands | ForEach-Object {
            if($functionName -notlike $_){
                "[$_]($_.md)`n`n"
            }
        }
    })
"@
        $content = $content.Split("`n") | ForEach-Object {"$($_.Trim())"}
        if(-not (Test-Path $MDFile)){
            New-Item $MDFile -Force >> $null
        }
        Set-Content $MDFile $content -Force
    }
    $MDFile = "$Destination\Docs\Modules\$ModuleName\$ModuleName.md"
    $content = @"
# $ModuleName Module

## Description

$(($Module | select Description).Description)

## $ModuleName Cmdlets

$($commands | ForEach-Object {
    "### [$_]($_.md)`n`n"
    "$((Get-Help $_).Synopsis)`n"
})
"@
    $content = $content.Split("`n") | ForEach-Object {"$($_.Trim())"}
    Set-Content $MDFile $content -Force
}
