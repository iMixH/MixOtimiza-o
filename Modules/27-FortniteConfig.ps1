# ==========================================================
# 27-FortniteConfig.ps1
# Editor Genérico de Arquivos INI
# ==========================================================

$ErrorActionPreference = "Stop"

function Backup-Ini {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (!(Test-Path $Path)) {
        throw "Arquivo não encontrado: $Path"
    }

    $backup = "$Path.bak"

    Copy-Item $Path $backup -Force

    Write-Host ""
    Write-Host "Backup criado:"
    Write-Host $backup
}

function Restore-Ini {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $backup = "$Path.bak"

    if (Test-Path $backup) {
        Copy-Item $backup $Path -Force
        Write-Host "Backup restaurado."
    }
    else {
        Write-Host "Backup inexistente."
    }
}

function Set-IniValue {

    param(

        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter(Mandatory)]
        [string]$Section,

        [Parameter(Mandatory)]
        [string]$Key,

        [Parameter(Mandatory)]
        [string]$Value
    )

    if (!(Test-Path $Path)) {
        throw "Arquivo não encontrado."
    }

    $content = Get-Content $Path

    $output = New-Object System.Collections.Generic.List[string]

    $inside = $false
    $found = $false

    foreach($line in $content){

        if($line -match "^\[(.+)\]"){

            if($inside -and !$found){
                $output.Add("$Key=$Value")
                $found=$true
            }

            if($Matches[1] -eq $Section){
                $inside=$true
            }else{
                $inside=$false
            }

            $output.Add($line)
            continue
        }

        if($inside){

            if($line -match "^$([regex]::Escape($Key))="){

                $output.Add("$Key=$Value")
                $found=$true
                continue
            }
        }

        $output.Add($line)
    }

    if(!$found){

        if(!$inside){
            $output.Add("")
            $output.Add("[$Section]")
        }

        $output.Add("$Key=$Value")
    }

    Set-Content -Path $Path -Value $output -Encoding UTF8
}

function Get-IniValue {

    param(

        [string]$Path,

        [string]$Section,

        [string]$Key
    )

    $inside = $false

    foreach($line in Get-Content $Path){

        if($line -match "^\[(.+)\]"){
            $inside = ($Matches[1] -eq $Section)
            continue
        }

        if($inside){

            if($line -match "^$([regex]::Escape($Key))=(.*)$"){
                return $Matches[2]
            }

        }

    }

    return $null
}

# ==========================================================
# Exemplo de uso
# ==========================================================

$Ini = Read-Host "Informe o caminho do arquivo INI"

Backup-Ini $Ini

Write-Host ""
Write-Host "Arquivo preparado."
Write-Host ""
Write-Host "Use:"
Write-Host 'Set-IniValue -Path $Ini -Section "MinhaSecao" -Key "MinhaChave" -Value "NovoValor"'
Write-Host ""
Write-Host "Para restaurar:"
Write-Host 'Restore-Ini $Ini'