# Convert-HelpToMarkdown

## SYNOPSIS
Creates an markdown file based on help.

## SYNTAX
```
Convert-HelpToMarkdown [-ModuleName] <String> [-Destination <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
Convert-HelpToMarkdown -ModulePath <String> [-Destination <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Convert PowerShell help information to a markdown file.
## PARAMETERS

### -ModuleName
Specifies the name of the module for which you want to generate the markdown file with documentation. Looks up the specified module name in ``$Env:PSModulePath``.
```yaml
Type: String
Required: true
Position: 1
Default value: none
Accept pipeline input: false
Accept wildcard characters: false
```

### -ModulePath
Specifies the path of the module for which you want to generate the markdown file with documentation. This parameter accepts the path to the folder that contains the module.
```yaml
Type: String
Required: true
Position: named
Default value: none
Accept pipeline input: false
Accept wildcard characters: false
```

### -Destination
Specifies the path to where the documentation files are saved. The default is desktop. Wildcards are not allowed.
```yaml
Type: String
Required: false
Position: named
Default value: $HOME\Desktop\
Accept pipeline input: false
Accept wildcard characters: false
```

### -WhatIf
Prompts you for confirmation before running the `Convert-HelpToMarkdown`.
```yaml
Type: SwitchParameter
Required: false
Position: named
Default value: none
Accept pipeline input: false
Accept wildcard characters: false
```

### -Confirm
Shows what would happen if the `Convert-HelpToMarkdown` runs. The cmdlet is not run.
```yaml
Type: SwitchParameter
Required: false
Position: named
Default value: none
Accept pipeline input: false
Accept wildcard characters: false
```
### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, [see about_CommonParameters](https://docs.microsoft.com/pl-pl/powershell/module/microsoft.powershell.core/about/about_commonparameters).

