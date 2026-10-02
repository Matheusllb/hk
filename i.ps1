& {
$ErrorActionPreference = 'Stop'
$Repo = 'Matheusllb/harness-kit'
$Kit = Join-Path $env:USERPROFILE '.harness-kit'
$Seco = $env:HARNESS_KIT_SECO -eq '1'
$Desde = [DateTime]::Now.Ticks
$Total = 9
$S = @{ N = 0; Saida = ''; Sobre = $false }
$Ck = [string][char]0x2713
$Xx = [string][char]0x2717
$Pt = [string][char]0x00B7
$Rt = [string][char]0x2026
$Hz = [string][char]0x2500
$Vt = [string][char]0x2502

function Caixa($Linhas, $Cor) {
  $L = [Math]::Max(46, ($Linhas | Measure-Object -Property Length -Maximum).Maximum)
  Write-Host ('  ' + [char]0x250C + ($Hz * ($L + 2)) + [char]0x2510) -ForegroundColor $Cor
  foreach ($x in $Linhas) {
    Write-Host "  $Vt " -NoNewline -ForegroundColor $Cor
    Write-Host $x.PadRight($L) -NoNewline -ForegroundColor White
    Write-Host " $Vt" -ForegroundColor $Cor
  }
  Write-Host ('  ' + [char]0x2514 + ($Hz * ($L + 2)) + [char]0x2518) -ForegroundColor $Cor
}

function Falha($Linhas) {
  Write-Host ''
  Write-Host ''
  Caixa (@("$Xx Parou em [$($S.N)/$Total]", '') + $Linhas + @('', 'Depois rode o mesmo comando de novo.')) Red
  Write-Host ''
}

function Passo($t) {
  $S.N++
  Write-Host ''
  Write-Host "  [$($S.N)/$Total] " -NoNewline -ForegroundColor Cyan
  Write-Host $t -ForegroundColor White
}

function Marca($Simbolo, $Cor, $t, $CorTexto = 'Gray') {
  if ($S.Sobre) { $t = $t.PadRight(64); $S.Sobre = $false }
  Write-Host "`r        $Simbolo " -NoNewline -ForegroundColor $Cor
  Write-Host $t -ForegroundColor $CorTexto
}

function Espera($t) {
  Write-Host "        $Rt $t" -NoNewline -ForegroundColor DarkGray
  $S.Sobre = $true
}

function Rodar([scriptblock]$Bloco) {
  $Eap = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $global:LASTEXITCODE = 0
    $S.Saida = (& $Bloco 2>&1 | Out-String)
    return ($LASTEXITCODE -eq 0)
  } finally { $ErrorActionPreference = $Eap }
}

function AtualizaPath {
  $Partes = @([Environment]::GetEnvironmentVariable('Path', 'Machine') -split ';') +
    @([Environment]::GetEnvironmentVariable('Path', 'User') -split ';') + @($env:Path -split ';')
  $env:Path = (($Partes | Where-Object { $_ } | Select-Object -Unique) -join ';')
}

function Garante($Cmd, $Nome, $Id) {
  if (Get-Command $Cmd -ErrorAction SilentlyContinue) { Marca $Ck Green ('{0,-10} ja instalado' -f $Cmd); return $true }
  if ($Seco) { Marca '!' Yellow "$Nome faltando (simulacao: nao instalei)"; return $true }
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { Falha @("$Nome nao esta instalado e o winget nao existe nesta maquina.", "Instale o $Nome a mao.") ; return $false }
  Espera "instalando $Nome (pode pedir permissao do Windows)"
  $null = Rodar { winget install --id $Id -e --silent --accept-source-agreements --accept-package-agreements }
  AtualizaPath
  if (Get-Command $Cmd -ErrorAction SilentlyContinue) { Marca $Ck Green ('{0,-10} instalado' -f $Cmd); return $true }
  Write-Host ''
  Falha (@("Nao consegui instalar o $Nome pelo winget:") + @($S.Saida.Trim() -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 4))
  $false
}

Write-Host ''
$Banner = @('harness-kit', 'engenharia de contexto para Claude Code')
if ($Seco) { $Banner += 'simulacao: nada sera alterado' }
Caixa $Banner Cyan

Passo 'Git e GitHub CLI'
if (-not (Garante git 'Git' 'Git.Git')) { return }
if (-not (Garante gh 'GitHub CLI' 'GitHub.cli')) { return }

Passo 'Conta do GitHub'
if (-not (Rodar { gh auth status })) {
  Marca $Rt DarkGray 'vou abrir o navegador: entre com a conta que recebeu o convite'
  Write-Host ''
  gh auth login --hostname github.com --git-protocol https --web
  Write-Host ''
  if ($LASTEXITCODE -ne 0) { Falha @('O login no GitHub nao foi concluido.'); return }
}
$null = Rodar { gh api user --jq .login }
$Login = $S.Saida.Trim()
if (-not (Rodar { gh api "repos/$Repo" --silent })) {
  if (Rodar { gh api user/repository_invitations --jq '.[] | [.id, .repository.full_name] | @tsv' }) {
    foreach ($Conv in ($S.Saida -split "`r?`n" | Where-Object { $_.Trim() })) {
      $Id, $Nome = $Conv.Trim() -split "`t"
      if ($Nome -ne $Repo) { continue }
      if (-not $Seco) { $null = Rodar { gh api -X PATCH "user/repository_invitations/$Id" --silent } }
      Marca $Ck Green "convite para $Repo aceito"
    }
  }
}
if (-not (Rodar { gh api "repos/$Repo" --silent })) {
  Falha @("A conta $Login nao tem acesso a $Repo.", '', 'Peca ao dono do kit para convidar essa conta, ou troque de conta:', '  gh auth logout')
  return
}
if (-not $Seco) { $null = Rodar { gh auth setup-git } }
Marca $Ck Green "logado como $Login, com acesso ao kit"

Passo 'Baixando o kit'
if (Test-Path (Join-Path $Kit '.git')) {
  if ($Seco) { Marca $Pt DarkGray 'ja baixado (simulacao: nao atualizei)' DarkGray }
  else {
    Espera 'atualizando'
    if (Rodar { git -C $Kit pull --ff-only }) { Marca $Ck Green 'atualizado' }
    else { Marca '!' Yellow 'nao consegui atualizar (mudancas locais?); sigo com o que ja esta aqui' }
  }
} else {
  if ($Seco) { Falha @("Simulacao: o kit nao esta em ~/.harness-kit e eu nao baixei."); return }
  if (Test-Path $Kit) {
    $Bak = Join-Path $env:USERPROFILE ('.harness-kit-bak\' + (Get-Date -Format 'yyyyMMddHHmmss') + '-harness-kit')
    New-Item -ItemType Directory -Force (Split-Path $Bak) | Out-Null
    Move-Item $Kit $Bak
    Marca '!' Yellow "havia uma pasta ~/.harness-kit sem git; movida para ~/.harness-kit-bak"
  }
  Espera 'baixando'
  if (-not (Rodar { git clone "https://github.com/$Repo.git" $Kit })) {
    Write-Host ''
    Falha (@('O git clone falhou:') + @($S.Saida.Trim() -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 4))
    return
  }
  Marca $Ck Green 'baixado'
}
$Versao = (Get-Content (Join-Path $Kit 'VERSION') -Raw).Trim()
Marca $Ck Green "kit v$Versao em ~/.harness-kit"

$Ps = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Kit 'install.ps1'), '-Embutido', '-Antes', '3', '-Desde', "$Desde")
if ($Seco) { $Ps += '-Seco' }
powershell @Ps
}
