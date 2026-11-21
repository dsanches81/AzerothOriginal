<#
  Publica mudanças no GitHub sem erro de "rejected (fetch first)".

  Uso (no PowerShell, dentro de C:\Scripts\AzerothOriginal):
    .\tools\publicar.ps1 "mensagem do commit"             # só envia o código
    .\tools\publicar.ps1 "mensagem" -Versao 1.2.1         # envia e publica a versão no CurseForge
#>
param(
    [Parameter(Mandatory = $true)][string]$Mensagem,
    [string]$Versao
)
$ErrorActionPreference = "Stop"
Set-Location (Split-Path $PSScriptRoot -Parent)

function Git {
    Write-Host ("> git " + ($args -join " ")) -ForegroundColor Cyan
    & git @args
    if ($LASTEXITCODE -ne 0) { throw ("falhou: git " + ($args -join " ")) }
}

# 1) sempre puxa antes (traz o que foi feito pelo site, como os merges do Dependabot)
Git pull --rebase --autostash

# 2) commit, se houver mudanças
& git add -A
& git diff --cached --quiet
if ($LASTEXITCODE -ne 0) { Git commit -m $Mensagem } else { Write-Host "Nada novo para commitar." }

# 3) envia
Git push

# 4) opcional: publica a versão (o GitHub empacota e envia ao CurseForge sozinho)
if ($Versao) {
    $tag = "v" + $Versao.TrimStart("v")
    Git tag $tag
    Git push origin $tag
    Write-Host "Versão $tag enviada. Acompanhe na aba Actions do GitHub." -ForegroundColor Green
}
