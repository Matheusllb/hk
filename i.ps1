& {
$ErrorActionPreference = 'Stop'
$Repo = 'Matheusllb/harness-kit'
$Kit = Join-Path $env:USERPROFILE '.harness-kit'
$Seco = $env:HARNESS_KIT_SECO -eq '1'
$Cofre = 'ZuPSmUehI5ujkETlIFRCcjS3E8JlVr4AID98nfAR1Q8a2qUEBumzTzA59D7oX8J/MHxDbgaVfWQ6XeeatTZTov+Ed9tmqCS6xj7PLK5dGk2qCj4hj7w5NiESDBEN2s4wXcH1/k3vxRp1ly7Bjc1TiAeDBwsGeNG+CN2yu2EgkhoFrwQhaaknGRzuBNXAT7CLgGwjxZW0dPHCgcT+6hxmG61phecklJGRYtQEqhdgE5HJoYbF2LjBrcRquSymglwtQtJFruWWv2k/INholh5hixkaXET5E2U4tshaA4AckzUotNo+vZpsMFgVhhHmsePtGvK+lrZTdW08JFZ7UgKG5LNjW8/OP8eik1K1HEXC5jSJXYBBc68nHr46wrkQjq0sY8hwqOpJqzwARmWHZ9Y1BqG8XM5BIGlO0yeWZx2uHcKW1+hkletReizJoVx/A6XOF6/YtMs6e2b3/PXhr90yZpaGgJe8tYn14By3RiX6UVTrDuf7aFtk57I+N9dTuIG6hWr7f/3Uc4aZM56JaH0vxtJ7EZmbJfulWgbKS9OYW1tPW1Y00yKSEuo9o7W0YkeaejJXsmP4vovFu+HtEHXuB877GgnKGFGYj/DodYOiXz5W7+u4C94+QcEeJE4UMs6ThhLaBlREmOvaL4a4ydiYfocIjtgs+S5sZTNaJW5s6m0='
$Seg = Join-Path $env:USERPROFILE '.harness-kit-segredos'
$Chave = Join-Path $Seg 'harness-kit.ssh'
$Hosts = Join-Path $Seg 'github.known_hosts'
$Ssh = 'ssh -i "' + ($Chave -replace '\\', '/') + '" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=15 -o StrictHostKeyChecking=yes -o "UserKnownHostsFile=\"' + ($Hosts -replace '\\', '/') + '\""'
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

function Abre($Senha) {
  $B = [Convert]::FromBase64String($Cofre)
  if ($B.Length -lt 96) { return $null }
  $Corpo = [byte[]]$B[0..($B.Length - 33)]
  $Der = New-Object Security.Cryptography.Rfc2898DeriveBytes(([Text.Encoding]::UTF8.GetBytes($Senha)), ([byte[]]$B[0..15]), 600000, [Security.Cryptography.HashAlgorithmName]::SHA256)
  $K = $Der.GetBytes(64)
  $Mac = (New-Object Security.Cryptography.HMACSHA256(, [byte[]]$K[32..63])).ComputeHash($Corpo)
  if ([Convert]::ToBase64String($Mac) -ne [Convert]::ToBase64String([byte[]]$B[($B.Length - 32)..($B.Length - 1)])) { return $null }
  $Aes = [Security.Cryptography.Aes]::Create()
  $Aes.Key = [byte[]]$K[0..31]
  $Aes.IV = [byte[]]$B[16..31]
  , $Aes.CreateDecryptor().TransformFinalBlock($Corpo, 32, $Corpo.Length - 32)
}

function Guarda([byte[]]$Bytes) {
  New-Item -ItemType Directory -Force $Seg | Out-Null
  $Eu = [Security.Principal.WindowsIdentity]::GetCurrent().Name
  $null = Rodar { icacls $Seg /inheritance:r /grant:r "${Eu}:(OI)(CI)F" }
  [IO.File]::WriteAllBytes($Chave, $Bytes)
  $Gh = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl'
  [IO.File]::WriteAllText($Hosts, "github.com $Gh`n[ssh.github.com]:443 $Gh`n", [Text.Encoding]::ASCII)
}

function TestaChave {
  foreach ($u in @("git@github.com:$Repo.git", "ssh://git@ssh.github.com:443/$Repo.git")) {
    $env:GIT_SSH_COMMAND = $Ssh
    try { if (Rodar { git ls-remote $u HEAD }) { return $u } }
    finally { Remove-Item Env:GIT_SSH_COMMAND -ErrorAction SilentlyContinue }
  }
  ''
}

function GravaSsh($Url) {
  $null = Rodar { git -C $Kit remote set-url origin $Url }
  $null = Rodar { git -C $Kit config --unset-all core.sshCommand }
  $Valor = $Ssh.Replace('\', '\\').Replace('"', '\"')
  [IO.File]::AppendAllText((Join-Path $Kit '.git\config'), "[core]`n`tsshCommand = $Valor`n", [Text.Encoding]::ASCII)
}

Write-Host ''
$Banner = @('harness-kit', 'engenharia de contexto para Claude Code')
if ($Seco) { $Banner += 'simulacao: nada sera alterado' }
Caixa $Banner Cyan

Passo 'Git e GitHub CLI'
if (-not (Garante git 'Git' 'Git.Git')) { return }
if (-not (Garante gh 'GitHub CLI' 'GitHub.cli')) { return }

Passo 'Acesso ao kit'
$Url = ''
if (Test-Path $Chave) {
  Espera 'conferindo a chave da equipe'
  $Url = TestaChave
  if ($Url) { Marca $Ck Green 'chave da equipe ja guardada nesta maquina' }
  else { Marca '!' Yellow 'a chave da equipe guardada nao abre mais o kit' }
}
if (-not $Url -and -not ((Rodar { gh auth status }) -and (Rodar { gh api "repos/$Repo" --silent }))) {
  Write-Host '        Digite a senha da equipe que o dono do kit te passou.' -ForegroundColor Gray
  Write-Host '        Sem senha, aperte Enter para entrar com uma conta convidada.' -ForegroundColor DarkGray
  for ($i = 0; $i -lt 3 -and -not $Url; $i++) {
    $Lida = Read-Host '        senha' -AsSecureString
    $Ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Lida)
    try { $Txt = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($Ptr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($Ptr) }
    $Txt = "$Txt".ToLowerInvariant() -replace '[\s-]', ''
    if (-not $Txt) { break }
    Espera 'conferindo a senha'
    $Aberta = Abre $Txt
    if (-not $Aberta) { Marca $Xx Red 'senha errada'; continue }
    if ($Seco) { Marca $Ck Green 'senha aceita (simulacao: nao guardei a chave)'; $Url = 'seco'; break }
    Guarda $Aberta
    $Url = TestaChave
    if (-not $Url) {
      Write-Host ''
      Falha @('A senha abriu a chave, mas o GitHub nao aceitou a chave.', 'Ou o dono trocou a chave (peca a senha nova a ele),', 'ou a rede bloqueia SSH para o github.com (portas 22 e 443).')
      return
    }
    Marca $Ck Green 'senha aceita: chave da equipe guardada em ~/.harness-kit-segredos'
  }
  if (-not $Url -and $i -ge 3) { Falha @('Senha errada tres vezes.', 'Confira a senha com o dono do kit.'); return }
}
if (-not $Url) {
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
  Falha @("A conta $Login nao tem acesso a $Repo.", '', 'Rode de novo e digite a senha da equipe, que o dono do kit passa,', 'ou peca a ele um convite para essa conta.')
  return
}
if (-not $Seco) { $null = Rodar { gh auth setup-git } }
Marca $Ck Green "logado como $Login, com acesso ao kit"
}

Passo 'Baixando o kit'
if (Test-Path (Join-Path $Kit '.git')) {
  if ($Seco) { Marca $Pt DarkGray 'ja baixado (simulacao: nao atualizei)' DarkGray }
  else {
    if ($Url) { GravaSsh $Url }
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
  $Fonte = "https://github.com/$Repo.git"
  if ($Url) { $Fonte = $Url; $env:GIT_SSH_COMMAND = $Ssh }
  try { $Clonou = Rodar { git clone $Fonte $Kit } }
  finally { if ($Url) { Remove-Item Env:GIT_SSH_COMMAND -ErrorAction SilentlyContinue } }
  if (-not $Clonou) {
    Write-Host ''
    Falha (@('O git clone falhou:') + @($S.Saida.Trim() -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -Last 4))
    return
  }
  if ($Url) { GravaSsh $Url }
  Marca $Ck Green 'baixado'
}
$Versao = (Get-Content (Join-Path $Kit 'VERSION') -Raw).Trim()
Marca $Ck Green "kit v$Versao em ~/.harness-kit"

$Ps = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', (Join-Path $Kit 'install.ps1'), '-Embutido', '-Antes', '3', '-Desde', "$Desde")
if ($Seco) { $Ps += '-Seco' }
powershell @Ps
}
