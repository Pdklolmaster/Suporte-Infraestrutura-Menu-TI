#Requires -RunAsAdministrator
# ============================================================
#  MenuSuporte.ps1  v3.0
#  Menu Interativo para Técnicos de Suporte N1 / N2
#  Compatível: Windows 10/11 | PowerShell 5.1+
#  Execução:   powershell -ExecutionPolicy Bypass -File MenuSuporte.ps1
# ============================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = "SilentlyContinue"

# ── Variáveis globais ────────────────────────────────────────
$SCRIPT_VER   = "3.0"
$PASTA_BASE   = "C:\Suporte"
$AUDIT_LOG    = "$PASTA_BASE\audit_log.csv"
$REG_MAQUINA  = "$PASTA_BASE\registro_maquina.txt"
$CSV_INV      = "$PASTA_BASE\inventario_maquinas.csv"
$LISTA_NEGRA  = @("utorrent","bitcomet","teamviewer","anydesk",
                  "ccleaner","advanced systemcare","registry cleaner",
                  "opencandy","conduit","babylon","ask toolbar")

# ── Garante pasta base ───────────────────────────────────────
if (-not (Test-Path $PASTA_BASE)) {
    New-Item -Path $PASTA_BASE -ItemType Directory -Force | Out-Null
}

# ── Cabeçalho do audit_log ───────────────────────────────────
if (-not (Test-Path $AUDIT_LOG)) {
    "Data;Hora;Tecnico;Computador;Acao;Detalhe;Status" |
        Set-Content $AUDIT_LOG -Encoding UTF8
}

# ════════════════════════════════════════════════════════════
# UTILITÁRIOS GLOBAIS
# ════════════════════════════════════════════════════════════

function Write-Log {
    param([string]$Acao, [string]$Detalhe = "", [string]$Status = "OK")
    $linha = "$(Get-Date -F 'dd/MM/yyyy');$(Get-Date -F 'HH:mm:ss');" +
             "$env:USERNAME;$env:COMPUTERNAME;$Acao;$Detalhe;$Status"
    Add-Content $AUDIT_LOG -Value $linha -Encoding UTF8
}

function Show-Header {
    param([string]$Titulo = "MENU PRINCIPAL")
    Clear-Host
    $online = if ($Global:ONLINE) { "ONLINE" } else { "OFFLINE" }
    $corOnline = if ($Global:ONLINE) { "Green" } else { "Red" }
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host "  MenuSuporte v$SCRIPT_VER  |  $env:COMPUTERNAME  |  $env:USERNAME" -ForegroundColor Cyan
    Write-Host "  $Titulo" -ForegroundColor White
    Write-Host "  Rede: " -NoNewline -ForegroundColor Cyan
    Write-Host $online -ForegroundColor $corOnline -NoNewline
    Write-Host "  |  $(Get-Date -F 'dd/MM/yyyy HH:mm')" -ForegroundColor DarkGray
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Confirm-Acao {
    param([string]$Msg = "Confirmar operacao?")
    Write-Host ""
    Write-Host "  !! $Msg [S/N]: " -NoNewline -ForegroundColor Yellow
    $r = Read-Host
    return ($r -eq "S" -or $r -eq "s")
}

function Test-Rede {
    # Testa conectividade real (gateway + DNS externo)
    $gw = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" |
           Sort-Object RouteMetric | Select-Object -First 1).NextHop
    $pingGW  = Test-Connection $gw -Count 1 -Quiet -ErrorAction SilentlyContinue
    $pingDNS = Test-Connection "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
    $Global:ONLINE   = $pingDNS
    $Global:GATEWAY  = $gw
    $Global:PING_GW  = $pingGW
    return $Global:ONLINE
}

# ════════════════════════════════════════════════════════════
# INICIALIZAÇÃO — detecta ambiente ao abrir
# ════════════════════════════════════════════════════════════
function Initialize-Script {
    Clear-Host
    Write-Host "  Inicializando MenuSuporte v$SCRIPT_VER..." -ForegroundColor DarkGray
    Write-Host "  Detectando ambiente..." -ForegroundColor DarkGray

    # Versão do PowerShell
    $Global:PS_VER = $PSVersionTable.PSVersion.Major

    # Testa rede
    Test-Rede | Out-Null

    # Detecta se está em domínio AD
    $comp = Get-CimInstance Win32_ComputerSystem
    $Global:EM_DOMINIO = ($comp.PartOfDomain)
    $Global:DOMINIO    = $comp.Domain

    # Módulo AD disponível?
    $Global:TEM_AD = (Get-Module -ListAvailable -Name ActiveDirectory) -ne $null

    Write-Log -Acao "INICIO" -Detalhe "v$SCRIPT_VER | PS$($Global:PS_VER) | Online:$($Global:ONLINE) | AD:$($Global:EM_DOMINIO)"
    Start-Sleep -Milliseconds 600
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 1 — LIMPEZA DE SISTEMA
# ════════════════════════════════════════════════════════════
function Invoke-Limpeza {
    Show-Header "LIMPEZA DE SISTEMA"

    $pastas = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Prefetch",
        "C:\Windows\SoftwareDistribution\Download",
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Temp"
    )

    $totalLiberado = 0

    foreach ($pasta in $pastas) {
        if (Test-Path $pasta) {
            # Calcula tamanho antes
            $antes = (Get-ChildItem $pasta -Recurse -Force -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            Get-ChildItem -Path $pasta -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            $depois = (Get-ChildItem $pasta -Recurse -Force -ErrorAction SilentlyContinue |
                       Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $liberado = [math]::Round(($antes - $depois) / 1MB, 1)
            $totalLiberado += $liberado
            Write-Host "  [OK] $pasta — liberado: $liberado MB" -ForegroundColor Green
        } else {
            Write-Host "  [--] $pasta — nao encontrada" -ForegroundColor DarkGray
        }
    }

    # Esvazia Lixeira
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "  [OK] Lixeira esvaziada" -ForegroundColor Green

    Write-Host ""
    Write-Host "  Total liberado: $totalLiberado MB" -ForegroundColor Cyan
    Write-Log -Acao "LIMPEZA" -Detalhe "Liberado: ${totalLiberado}MB"
    Write-Host ""
    Read-Host "  Pressione ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 2 — SERVIÇOS E REDE (submenu)
# ════════════════════════════════════════════════════════════
function Invoke-MenuRede {
    do {
        Show-Header "SERVICOS E REDE"
        Write-Host "  [1]  Reiniciar Spooler de Impressao"
        Write-Host "  [2]  Resetar pilha de rede (release/renew/flush)"
        Write-Host "  [3]  Diagnostico completo de rede"
        Write-Host "  [4]  Configurar IP fixo ou DHCP"
        Write-Host "  [5]  Gerenciar perfis Wi-Fi"
        Write-Host "  [6]  Voltar"
        Write-Host ""
        $s = Read-Host "  Opcao"
        switch ($s) {
            "1" { Invoke-Spooler }
            "2" { Invoke-ResetRede }
            "3" { Invoke-DiagRede }
            "4" { Invoke-ConfigIP }
            "5" { Invoke-WiFi }
        }
    } while ($s -ne "6")
}

function Invoke-Spooler {
    Show-Header "REINICIAR SPOOLER"
    Write-Host "  -> Parando Spooler..."
    Stop-Service Spooler -Force -ErrorAction SilentlyContinue

    # Remove jobs travados na fila
    $filaSpool = "C:\Windows\System32\spool\PRINTERS"
    if (Test-Path $filaSpool) {
        Get-ChildItem $filaSpool -Force -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  -> Fila de impressao limpa" -ForegroundColor Green
    }

    Start-Service Spooler -ErrorAction SilentlyContinue
    $status = (Get-Service Spooler).Status
    Write-Host "  Status Spooler: $status" -ForegroundColor Green
    Write-Log -Acao "SPOOLER" -Detalhe "Status: $status"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-ResetRede {
    Show-Header "RESET DE REDE"
    Write-Host "  -> ipconfig /release..."
    $job = Start-Job { ipconfig /release }
    $ok  = Wait-Job $job -Timeout 15
    if (-not $ok) { Stop-Job $job; Write-Host "  Timeout no release." -ForegroundColor Yellow }
    Remove-Job $job -Force

    Write-Host "  -> ipconfig /renew..."
    $job2 = Start-Job { ipconfig /renew }
    $ok2  = Wait-Job $job2 -Timeout 30
    if (-not $ok2) { Stop-Job $job2; Write-Host "  Timeout no renew (sem DHCP?)." -ForegroundColor Yellow }
    Remove-Job $job2 -Force

    Write-Host "  -> Flush DNS..."
    ipconfig /flushdns | Out-Null

    Write-Host "  -> Resetando Winsock e IP stack..."
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null

    Test-Rede | Out-Null
    $status = if ($Global:ONLINE) { "Online" } else { "Sem internet" }
    Write-Host ""
    Write-Host "  Resultado: $status" -ForegroundColor $(if ($Global:ONLINE) {"Green"} else {"Red"})
    Write-Log -Acao "RESET_REDE" -Detalhe $status
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-DiagRede {
    Show-Header "DIAGNOSTICO DE REDE"

    # Adaptadores ativos
    Write-Host "  === ADAPTADORES ATIVOS ===" -ForegroundColor Cyan
    Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
        $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        Write-Host "  $($_.Name) | $($_.InterfaceDescription) | IP: $ip"
    }
    Write-Host ""

    # Gateway
    Write-Host "  === GATEWAY ===" -ForegroundColor Cyan
    $gw = $Global:GATEWAY
    Write-Host "  Gateway: $gw"
    $pingGW = Test-Connection $gw -Count 2 -ErrorAction SilentlyContinue
    if ($pingGW) {
        $media = [math]::Round(($pingGW | Measure-Object -Property ResponseTime -Average).Average)
        Write-Host "  Ping Gateway: $media ms" -ForegroundColor Green
    } else {
        Write-Host "  Gateway: SEM RESPOSTA" -ForegroundColor Red
    }
    Write-Host ""

    # DNS
    Write-Host "  === DNS ===" -ForegroundColor Cyan
    $dnsServers = (Get-DnsClientServerAddress -AddressFamily IPv4 |
                   Where-Object ServerAddresses | Select-Object -First 1).ServerAddresses
    Write-Host "  Servidores DNS: $($dnsServers -join ', ')"
    $resolucao = Resolve-DnsName "www.google.com" -ErrorAction SilentlyContinue
    if ($resolucao) {
        Write-Host "  Resolucao DNS: OK ($($resolucao[0].IPAddress))" -ForegroundColor Green
    } else {
        Write-Host "  Resolucao DNS: FALHOU" -ForegroundColor Red
    }
    Write-Host ""

    # Internet
    Write-Host "  === INTERNET ===" -ForegroundColor Cyan
    $hosts = @("8.8.8.8","1.1.1.1","208.67.222.222")
    foreach ($h in $hosts) {
        $r = Test-Connection $h -Count 1 -ErrorAction SilentlyContinue
        $ms = if ($r) { "$($r.ResponseTime)ms" } else { "SEM RESPOSTA" }
        $cor = if ($r) { "Green" } else { "Red" }
        Write-Host "  Ping $h : $ms" -ForegroundColor $cor
    }
    Write-Host ""

    # Portas críticas
    Write-Host "  === PORTAS CRITICAS ===" -ForegroundColor Cyan
    $portas = @(
        @{Host="$gw"; Porta=80;  Nome="HTTP Gateway"},
        @{Host="$gw"; Porta=443; Nome="HTTPS Gateway"},
        @{Host="$gw"; Porta=53;  Nome="DNS"}
    )
    foreach ($p in $portas) {
        $tcp = New-Object System.Net.Sockets.TcpClient
        try {
            $tcp.Connect($p.Host, $p.Porta)
            Write-Host "  $($p.Nome) ($($p.Porta)): ABERTA" -ForegroundColor Green
        } catch {
            Write-Host "  $($p.Nome) ($($p.Porta)): FECHADA/FILTRADA" -ForegroundColor Yellow
        }
        $tcp.Close()
    }

    Write-Log -Acao "DIAG_REDE" -Detalhe "GW:$gw DNS:$($dnsServers[0]) Online:$($Global:ONLINE)"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-ConfigIP {
    Show-Header "CONFIGURAR IP"

    # Lista adaptadores
    $adapters = Get-NetAdapter | Where-Object Status -eq "Up"
    Write-Host "  Adaptadores disponiveis:" -ForegroundColor Cyan
    $i = 0
    $adapters | ForEach-Object {
        $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
        Write-Host "  [$i] $($_.Name) | IP atual: $ip"
        $i++
    }
    Write-Host ""
    $idx = [int](Read-Host "  Numero do adaptador")
    $adapter = $adapters | Select-Object -Index $idx
    if (-not $adapter) { Write-Host "  Invalido." -ForegroundColor Red; Read-Host "  ENTER"; return }

    Write-Host ""
    Write-Host "  [1] Configurar IP Fixo"
    Write-Host "  [2] Voltar para DHCP"
    $modo = Read-Host "  Opcao"

    if ($modo -eq "1") {
        $novoIP  = Read-Host "  IP (ex: 192.168.1.100)"
        $mascara = Read-Host "  Prefixo (ex: 24 para /24)"
        $gateway = Read-Host "  Gateway (ex: 192.168.1.1)"
        $dns1    = Read-Host "  DNS primario (ex: 8.8.8.8)"

        if (Confirm-Acao "Aplicar IP fixo $novoIP/$mascara em $($adapter.Name)?") {
            # Remove configuracoes antigas
            Remove-NetIPAddress -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceIndex $adapter.ifIndex -Confirm:$false -ErrorAction SilentlyContinue

            New-NetIPAddress -InterfaceIndex $adapter.ifIndex `
                -IPAddress $novoIP -PrefixLength $mascara `
                -DefaultGateway $gateway -ErrorAction SilentlyContinue | Out-Null
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex `
                -ServerAddresses $dns1 -ErrorAction SilentlyContinue

            Write-Host "  IP fixo aplicado." -ForegroundColor Green
            Write-Log -Acao "CONFIG_IP" -Detalhe "Fixo: $novoIP/$mascara GW:$gateway"
        }
    } elseif ($modo -eq "2") {
        if (Confirm-Acao "Ativar DHCP em $($adapter.Name)?") {
            Set-NetIPInterface -InterfaceIndex $adapter.ifIndex -Dhcp Enabled
            Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ResetServerAddresses
            Write-Host "  DHCP ativado. Aguarde renovacao..." -ForegroundColor Green
            Write-Log -Acao "CONFIG_IP" -Detalhe "DHCP em $($adapter.Name)"
        }
    }
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-WiFi {
    Show-Header "GERENCIAR WI-FI"
    Write-Host "  [1]  Listar perfis salvos"
    Write-Host "  [2]  Exportar perfil (sem senha)"
    Write-Host "  [3]  Ver senha de um perfil"
    Write-Host "  [4]  Remover perfil"
    Write-Host "  [5]  Voltar"
    Write-Host ""
    $s = Read-Host "  Opcao"

    switch ($s) {
        "1" {
            Write-Host ""
            Write-Host "  Perfis Wi-Fi salvos:" -ForegroundColor Cyan
            netsh wlan show profiles | Select-String "Perfil de usuario" |
                ForEach-Object { Write-Host "  $_" }
        }
        "2" {
            $nome = Read-Host "  Nome exato do perfil"
            $dest = "$PASTA_BASE\wifi_${nome}.xml"
            netsh wlan export profile name="$nome" folder="$PASTA_BASE" key=clear | Out-Null
            Write-Host "  Exportado: $dest" -ForegroundColor Green
            Write-Log -Acao "WIFI_EXPORT" -Detalhe $nome
        }
        "3" {
            $nome = Read-Host "  Nome exato do perfil"
            Write-Host ""
            netsh wlan show profile name="$nome" key=clear |
                Select-String "Conteudo da chave" | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
            Write-Log -Acao "WIFI_SENHA" -Detalhe $nome
        }
        "4" {
            $nome = Read-Host "  Nome exato do perfil a remover"
            if (Confirm-Acao "Remover perfil '$nome'?") {
                netsh wlan delete profile name="$nome" | Out-Null
                Write-Host "  Perfil removido." -ForegroundColor Green
                Write-Log -Acao "WIFI_REMOVE" -Detalhe $nome
            }
        }
    }
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 3 — CRIAR MÍDIA BOOTÁVEL
# ════════════════════════════════════════════════════════════
function Invoke-MidiaBootavel {
    Show-Header "CRIAR MIDIA BOOTAVEL"
    Write-Host "  Discos detectados:" -ForegroundColor Cyan
    Write-Host ""
    Get-Disk | Format-Table -AutoSize Number, FriendlyName,
        @{N="Tamanho";E={[math]::Round($_.Size/1GB,1)+"GB"}}, PartitionStyle
    Write-Host ""
    Write-Host "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    Write-Host "  ATENCAO: NAO selecione o Disco 0 (HD principal)" -ForegroundColor Red
    Write-Host "  TODOS OS DADOS DO DISCO ESCOLHIDO SERAO APAGADOS" -ForegroundColor Red
    Write-Host "  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!" -ForegroundColor Red
    Write-Host ""
    $numDisco = Read-Host "  Numero do disco do PENDRIVE"

    if ($numDisco -notmatch '^\d+$' -or [int]$numDisco -eq 0) {
        Write-Host "  Disco 0 bloqueado por seguranca. Cancelado." -ForegroundColor Red
        Read-Host "  ENTER"; return
    }

    $formato = Read-Host "  Formato: [1] FAT32  [2] NTFS"
    $fs = if ($formato -eq "2") { "NTFS" } else { "FAT32" }

    if (-not (Confirm-Acao "Formatar Disco $numDisco em $fs?")) {
        Read-Host "  ENTER"; return
    }

    $scriptDP = @"
select disk $numDisco
clean
create partition primary
select partition 1
format fs=$fs quick label="SUPORTE"
active
assign
exit
"@
    $tmpDP = "$env:TEMP\dp_script.txt"
    $scriptDP | Out-File $tmpDP -Encoding ascii -Force
    diskpart /s $tmpDP
    Remove-Item $tmpDP -Force -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  Pendrive pronto. Copie os arquivos de instalacao." -ForegroundColor Green
    Write-Log -Acao "MIDIA_BOOTAVEL" -Detalhe "Disco:$numDisco FS:$fs"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 4 — APLICAR IMAGEM .WIM
# ════════════════════════════════════════════════════════════
function Invoke-AplicarImagem {
    Show-Header "APLICAR IMAGEM .WIM"

    $imagemWIM = "D:\Windows_Custom.wim"
    $destinoHD = "C:\"

    if (-not (Test-Path $imagemWIM)) {
        Write-Host "  ERRO: $imagemWIM nao encontrada." -ForegroundColor Red
        Write-Host "  Verifique se o HD com a imagem esta conectado." -ForegroundColor Yellow
        Write-Host ""; Read-Host "  ENTER"; return
    }

    # Cria ponto de restauração antes de qualquer ação destrutiva
    Write-Host "  -> Criando ponto de restauracao de seguranca..." -ForegroundColor Cyan
    Checkpoint-Computer -Description "Pre-DISM MenuSuporte" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue

    Write-Host ""
    Write-Host "  Imagem : $imagemWIM"
    Write-Host "  Destino: $destinoHD"
    Write-Host ""
    Write-Host "  !!! OPERACAO DESTRUTIVA — SOBRESCREVE C:\ !!!" -ForegroundColor Red
    Write-Host ""

    if (-not (Confirm-Acao "Confirmar aplicacao da imagem?")) {
        Read-Host "  ENTER"; return
    }

    Write-Host ""
    Write-Host "  -> Aplicando imagem com DISM..." -ForegroundColor Cyan
    dism /Apply-Image /ImageFile:"$imagemWIM" /Index:1 /ApplyDir:"$destinoHD"

    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERRO DISM. Log: C:\Windows\Logs\DISM\dism.log" -ForegroundColor Red
        Write-Log -Acao "DISM_APPLY" -Detalhe $imagemWIM -Status "ERRO"
        Write-Host ""; Read-Host "  ENTER"; return
    }

    Write-Host "  -> Gerando boot com bcdboot..." -ForegroundColor Cyan
    bcdboot C:\Windows /s C: /f ALL

    Write-Host ""
    Write-Host "  Imagem aplicada! Remova a midia e reinicie." -ForegroundColor Green
    Write-Log -Acao "DISM_APPLY" -Detalhe $imagemWIM -Status "OK"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 5 — REGISTRO BIOS / CSV
# ════════════════════════════════════════════════════════════
function Export-CsvInventario {
    param([string]$CsvPath, [hashtable]$Dados)

    $cab = "Patrimonio;Fabricante;Modelo;Serial;Asset_Tag_BIOS;Processador;" +
           "RAM_GB;Disco_Modelo;Disco_GB;Ultima_Manutencao;Descricao_Manut;" +
           "Tecnico;Ultima_Exportacao;Ver_Detalhes"

    # Escapa ponto-e-vírgula dentro de campos de texto livre
    $descEsc = '"' + ($Dados.DescManut -replace '"','""') + '"'

    $novaLinha = @(
        $Dados.Patrimonio, $Dados.Fabricante, $Dados.Modelo,
        $Dados.Serial, $Dados.AssetTag, $Dados.Processador,
        $Dados.RAM, $Dados.DiscoModelo, $Dados.DiscoGB,
        $Dados.UltManutencao, $descEsc, $Dados.Tecnico,
        (Get-Date -F "dd/MM/yyyy HH:mm"), "VER"
    ) -join ";"

    if (-not (Test-Path $CsvPath)) {
        Set-Content $CsvPath -Value $cab -Encoding UTF8
    }

    $serial = $Dados.Serial
    $linhas = Get-Content $CsvPath -Encoding UTF8
    $filtradas = $linhas | Where-Object { $_ -eq $cab -or $_ -notmatch [regex]::Escape($serial) }
    ($filtradas + $novaLinha) | Set-Content $CsvPath -Encoding UTF8

    Write-Host "  CSV atualizado: $CsvPath" -ForegroundColor Green
    Write-Host "  No Excel: Dados -> Atualizar Tudo." -ForegroundColor Cyan
}

function Invoke-RegistroBios {
    Show-Header "REGISTRO DE MAQUINA / BIOS"

    $bios  = Get-CimInstance Win32_BIOS
    $sis   = Get-CimInstance Win32_ComputerSystem
    $gab   = Get-CimInstance Win32_SystemEnclosure
    $cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
    $disco = Get-CimInstance Win32_DiskDrive  | Select-Object -First 1

    Write-Host "  === HARDWARE DETECTADO ===" -ForegroundColor Cyan
    Write-Host "  Fabricante  : $($sis.Manufacturer)"
    Write-Host "  Modelo      : $($sis.Model)"
    Write-Host "  Serial      : $($bios.SerialNumber)"
    Write-Host "  CPU         : $($cpu.Name)"
    Write-Host "  RAM (GB)    : $([math]::Round($sis.TotalPhysicalMemory/1GB,1))"
    Write-Host "  Disco       : $($disco.Model) / $([math]::Round($disco.Size/1GB))GB"
    Write-Host "  Asset Tag   : $($gab.SMBIOSAssetTag)"
    Write-Host ""

    if (Test-Path $REG_MAQUINA) {
        Write-Host "  === ULTIMAS 5 ENTRADAS DO LOG ===" -ForegroundColor Cyan
        Get-Content $REG_MAQUINA | Select-Object -Last 5 |
            ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
        Write-Host ""
    }

    Write-Host "  [1]  Gravar patrimonio (Asset Tag BIOS)"
    Write-Host "  [2]  Registrar manutencao + exportar CSV"
    Write-Host "  [3]  Exportar CSV (escolher destino)"
    Write-Host "  [4]  Alterar caminho padrao do CSV"
    Write-Host "  [5]  Voltar"
    Write-Host ""
    $sub = Read-Host "  Opcao"

    $csvAtual = $CSV_INV

    switch ($sub) {
        "1" {
            $novaTag = Read-Host "  Numero de patrimonio"
            if ([string]::IsNullOrWhiteSpace($novaTag)) { break }
            try {
                $enc = Get-WmiObject Win32_SystemEnclosure
                $enc.SMBIOSAssetTag = $novaTag; $enc.Put() | Out-Null
                Write-Host "  Asset Tag gravada na BIOS." -ForegroundColor Green
            } catch {
                Write-Host "  WMI bloqueado — registrado apenas no log local." -ForegroundColor Yellow
            }
            $log = "$(Get-Date -F 'dd/MM/yyyy HH:mm') | PATRIMONIO: $novaTag | $env:USERNAME"
            Add-Content $REG_MAQUINA -Value $log -Encoding UTF8

            $d = @{ Patrimonio=$novaTag; Fabricante=$sis.Manufacturer; Modelo=$sis.Model
                    Serial=$bios.SerialNumber; AssetTag=$novaTag; Processador=$cpu.Name
                    RAM=[math]::Round($sis.TotalPhysicalMemory/1GB,1)
                    DiscoModelo=$disco.Model; DiscoGB=[math]::Round($disco.Size/1GB)
                    UltManutencao=(Get-Date -F "dd/MM/yyyy")
                    DescManut="Registro inicial patrimonio $novaTag"; Tecnico=$env:USERNAME }
            Export-CsvInventario -CsvPath $csvAtual -Dados $d
            Write-Log -Acao "BIOS_ASSET_TAG" -Detalhe $novaTag
        }
        "2" {
            $pat  = Read-Host "  Numero de patrimonio"
            if ([string]::IsNullOrWhiteSpace($pat)) { $pat = $gab.SMBIOSAssetTag }
            $desc = Read-Host "  Descricao da manutencao"
            if ([string]::IsNullOrWhiteSpace($desc)) { break }
            $log = "$(Get-Date -F 'dd/MM/yyyy HH:mm') | MANUTENCAO | $desc | $env:USERNAME"
            Add-Content $REG_MAQUINA -Value $log -Encoding UTF8
            $d = @{ Patrimonio=$pat; Fabricante=$sis.Manufacturer; Modelo=$sis.Model
                    Serial=$bios.SerialNumber; AssetTag=$gab.SMBIOSAssetTag
                    Processador=$cpu.Name; RAM=[math]::Round($sis.TotalPhysicalMemory/1GB,1)
                    DiscoModelo=$disco.Model; DiscoGB=[math]::Round($disco.Size/1GB)
                    UltManutencao=(Get-Date -F "dd/MM/yyyy")
                    DescManut=$desc; Tecnico=$env:USERNAME }
            Export-CsvInventario -CsvPath $csvAtual -Dados $d
            Write-Log -Acao "MANUTENCAO" -Detalhe "$pat | $desc"
        }
        "3" {
            $dest = Read-Host "  Caminho completo do CSV (ENTER = padrao)"
            if ([string]::IsNullOrWhiteSpace($dest)) { $dest = $csvAtual }
            if ($dest -notmatch '\.csv$') { $dest += ".csv" }
            $pastaD = Split-Path $dest
            if (-not (Test-Path $pastaD)) { New-Item $pastaD -ItemType Directory -Force | Out-Null }
            $pat  = Read-Host "  Patrimonio"
            $desc = Read-Host "  Observacao"
            $d = @{ Patrimonio=$pat; Fabricante=$sis.Manufacturer; Modelo=$sis.Model
                    Serial=$bios.SerialNumber; AssetTag=$gab.SMBIOSAssetTag
                    Processador=$cpu.Name; RAM=[math]::Round($sis.TotalPhysicalMemory/1GB,1)
                    DiscoModelo=$disco.Model; DiscoGB=[math]::Round($disco.Size/1GB)
                    UltManutencao=(Get-Date -F "dd/MM/yyyy")
                    DescManut=$(if($desc){$desc}else{"Exportacao manual"}); Tecnico=$env:USERNAME }
            Export-CsvInventario -CsvPath $dest -Dados $d
            Write-Log -Acao "CSV_EXPORT" -Detalhe $dest
        }
        "4" {
            $novo = Read-Host "  Novo caminho padrao do CSV"
            if (-not [string]::IsNullOrWhiteSpace($novo)) {
                $Script:CSV_INV = $novo
                Write-Host "  Caminho atualizado." -ForegroundColor Green
            }
        }
        "5" { return }
    }
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 6 — DIAGNÓSTICO E RELATÓRIO
# ════════════════════════════════════════════════════════════
function Invoke-Diagnostico {
    Show-Header "DIAGNOSTICO E RELATORIO"
    Write-Host "  [1]  Relatorio HTML completo (abre no navegador)"
    Write-Host "  [2]  Score de saude da maquina"
    Write-Host "  [3]  Eventos criticos recentes (Event Viewer)"
    Write-Host "  [4]  Voltar"
    Write-Host ""
    $s = Read-Host "  Opcao"
    switch ($s) {
        "1" { Invoke-RelatorioHTML }
        "2" { Invoke-ScoreSaude }
        "3" { Invoke-EventosCriticos }
    }
}

function Invoke-ScoreSaude {
    Show-Header "SCORE DE SAUDE"
    $score = 100
    $problemas = @()

    # Disco — uso
    $disco = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($disco) {
        $pctLivre = [math]::Round(($disco.Free / ($disco.Used + $disco.Free)) * 100)
        if ($pctLivre -lt 10) { $score -= 30; $problemas += "Disco critico ($pctLivre% livre)" }
        elseif ($pctLivre -lt 20) { $score -= 15; $problemas += "Disco baixo ($pctLivre% livre)" }
        Write-Host "  Disco C: $pctLivre% livre" -ForegroundColor $(if($pctLivre -lt 15){"Red"}else{"Green"})
    }

    # RAM — uso
    $os  = Get-CimInstance Win32_OperatingSystem
    $pctRAM = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100)
    if ($pctRAM -gt 90) { $score -= 25; $problemas += "RAM critica ($pctRAM% em uso)" }
    elseif ($pctRAM -gt 75) { $score -= 10; $problemas += "RAM elevada ($pctRAM% em uso)" }
    Write-Host "  RAM em uso: $pctRAM%" -ForegroundColor $(if($pctRAM -gt 85){"Red"}elseif($pctRAM -gt 70){"Yellow"}else{"Green"})

    # Uptime
    $boot   = $os.LastBootUpTime
    $uptime = (Get-Date) - $boot
    if ($uptime.Days -gt 30) { $score -= 10; $problemas += "Uptime $($uptime.Days) dias (recomenda reinicio)" }
    Write-Host "  Uptime: $($uptime.Days)d $($uptime.Hours)h" -ForegroundColor $(if($uptime.Days -gt 30){"Yellow"}else{"Green"})

    # Windows Update
    $wu = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 1
    $diasSemUpdate = ((Get-Date) - $wu.InstalledOn).Days
    if ($diasSemUpdate -gt 60) { $score -= 15; $problemas += "Sem updates ha $diasSemUpdate dias" }
    Write-Host "  Ultimo update: $($wu.InstalledOn.ToString('dd/MM/yyyy')) ($diasSemUpdate dias atras)" `
        -ForegroundColor $(if($diasSemUpdate -gt 60){"Red"}else{"Green"})

    # Defender
    $defStatus = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($defStatus) {
        if (-not $defStatus.RealTimeProtectionEnabled) { $score -= 20; $problemas += "Defender desativado" }
        $defAge = ((Get-Date) - $defStatus.AntivirusSignatureLastUpdated).Days
        if ($defAge -gt 7) { $score -= 10; $problemas += "Assinaturas Defender desatualizadas ($defAge dias)" }
        Write-Host "  Defender: $(if($defStatus.RealTimeProtectionEnabled){'Ativo'}else{'INATIVO'})" `
            -ForegroundColor $(if($defStatus.RealTimeProtectionEnabled){"Green"}else{"Red"})
    }

    # Score final
    $score = [math]::Max(0, $score)
    $corScore = if ($score -ge 80) { "Green" } elseif ($score -ge 50) { "Yellow" } else { "Red" }
    Write-Host ""
    Write-Host "  ================================" -ForegroundColor Cyan
    Write-Host "  SCORE DE SAUDE: $score / 100" -ForegroundColor $corScore
    Write-Host "  ================================" -ForegroundColor Cyan

    if ($problemas.Count -gt 0) {
        Write-Host "  Problemas encontrados:" -ForegroundColor Yellow
        $problemas | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
    } else {
        Write-Host "  Nenhum problema critico detectado." -ForegroundColor Green
    }

    Write-Log -Acao "SCORE_SAUDE" -Detalhe "Score:$score Problemas:$($problemas.Count)"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-EventosCriticos {
    Show-Header "EVENTOS CRITICOS (ultimas 24h)"
    Write-Host "  Buscando eventos de nivel Critico e Erro..." -ForegroundColor Cyan
    Write-Host ""

    $eventos = Get-WinEvent -FilterHashtable @{
        LogName   = 'System','Application'
        Level     = 1,2          # 1=Critico 2=Erro
        StartTime = (Get-Date).AddHours(-24)
    } -MaxEvents 20 -ErrorAction SilentlyContinue

    if ($eventos) {
        $eventos | Format-Table -AutoSize -Property `
            @{N="Hora";    E={$_.TimeCreated.ToString("HH:mm")}},
            @{N="Nivel";   E={if($_.Level -eq 1){"CRITICO"}else{"ERRO"}}},
            @{N="Fonte";   E={$_.ProviderName}},
            @{N="ID";      E={$_.Id}},
            @{N="Mensagem";E={$_.Message.Substring(0,[math]::Min(60,$_.Message.Length))}}
    } else {
        Write-Host "  Nenhum evento critico nas ultimas 24h." -ForegroundColor Green
    }

    Write-Log -Acao "EVENTOS_CRITICOS" -Detalhe "Encontrados: $($eventos.Count)"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-RelatorioHTML {
    Show-Header "GERANDO RELATORIO HTML..."

    $bios  = Get-CimInstance Win32_BIOS
    $sis   = Get-CimInstance Win32_ComputerSystem
    $os    = Get-CimInstance Win32_OperatingSystem
    $cpu   = Get-CimInstance Win32_Processor | Select-Object -First 1
    $gab   = Get-CimInstance Win32_SystemEnclosure
    $discos = Get-CimInstance Win32_DiskDrive
    $rede  = Get-NetAdapter | Where-Object Status -eq "Up"
    $procs = Get-Process | Sort-Object CPU -Descending | Select-Object -First 10
    $svcs  = Get-Service | Where-Object { $_.Status -eq "Stopped" -and $_.StartType -eq "Automatic" }
    $disco = Get-PSDrive C
    $pctLivre = [math]::Round(($disco.Free/($disco.Used+$disco.Free))*100)
    $pctRAM   = [math]::Round((($os.TotalVisibleMemorySize-$os.FreePhysicalMemory)/$os.TotalVisibleMemorySize)*100)
    $uptime   = (Get-Date) - $os.LastBootUpTime
    $updates  = Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 5

    $html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Relatorio - $env:COMPUTERNAME</title>
<style>
  body{font-family:Arial,sans-serif;background:#f0f2f5;margin:0;padding:20px;color:#333}
  h1{background:#1F3864;color:#fff;padding:16px 24px;border-radius:8px;margin-bottom:8px}
  h2{color:#2E75B6;border-bottom:2px solid #2E75B6;padding-bottom:4px;margin-top:28px}
  .meta{color:#888;font-size:13px;margin-bottom:24px}
  .grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(200px,1fr));gap:16px;margin:16px 0}
  .card{background:#fff;border-radius:8px;padding:16px;box-shadow:0 2px 6px rgba(0,0,0,.08)}
  .card .val{font-size:28px;font-weight:bold;margin:8px 0}
  .card .lbl{font-size:12px;color:#888;text-transform:uppercase}
  .ok{color:#70AD47}.warn{color:#FFB900}.err{color:#C00000}
  table{width:100%;border-collapse:collapse;background:#fff;border-radius:8px;overflow:hidden;box-shadow:0 2px 6px rgba(0,0,0,.08)}
  th{background:#2E75B6;color:#fff;padding:10px 14px;text-align:left;font-size:13px}
  td{padding:9px 14px;font-size:13px;border-bottom:1px solid #eee}
  tr:nth-child(even){background:#f8f9fb}
  .bar{height:14px;border-radius:7px;background:#eee;overflow:hidden;margin-top:4px}
  .bar-fill{height:100%;border-radius:7px;transition:width .4s}
  footer{text-align:center;color:#aaa;font-size:12px;margin-top:32px}
</style>
</head>
<body>
<h1>Relatorio de Maquina — $env:COMPUTERNAME</h1>
<div class="meta">Gerado em $(Get-Date -F 'dd/MM/yyyy HH:mm') por $env:USERNAME | MenuSuporte v$SCRIPT_VER</div>

<h2>Resumo de Saude</h2>
<div class="grid">
  <div class="card">
    <div class="lbl">Disco C: livre</div>
    <div class="val $(if($pctLivre -lt 15){'err'}elseif($pctLivre -lt 25){'warn'}else{'ok'})">$pctLivre%</div>
    <div class="bar"><div class="bar-fill" style="width:$pctLivre%;background:$(if($pctLivre -lt 15){'#C00000'}elseif($pctLivre -lt 25){'#FFB900'}else{'#70AD47'})"></div></div>
  </div>
  <div class="card">
    <div class="lbl">RAM em uso</div>
    <div class="val $(if($pctRAM -gt 85){'err'}elseif($pctRAM -gt 70){'warn'}else{'ok'})">$pctRAM%</div>
    <div class="bar"><div class="bar-fill" style="width:$pctRAM%;background:$(if($pctRAM -gt 85){'#C00000'}elseif($pctRAM -gt 70){'#FFB900'}else{'#70AD47'})"></div></div>
  </div>
  <div class="card">
    <div class="lbl">Uptime</div>
    <div class="val ok">$($uptime.Days)d $($uptime.Hours)h</div>
  </div>
  <div class="card">
    <div class="lbl">Online</div>
    <div class="val $(if($Global:ONLINE){'ok'}else{'err'})">$(if($Global:ONLINE){'Sim'}else{'Nao'})</div>
  </div>
</div>

<h2>Hardware</h2>
<table>
  <tr><th>Campo</th><th>Valor</th></tr>
  <tr><td>Fabricante</td><td>$($sis.Manufacturer)</td></tr>
  <tr><td>Modelo</td><td>$($sis.Model)</td></tr>
  <tr><td>Serial (S/N)</td><td>$($bios.SerialNumber)</td></tr>
  <tr><td>Asset Tag</td><td>$($gab.SMBIOSAssetTag)</td></tr>
  <tr><td>Processador</td><td>$($cpu.Name)</td></tr>
  <tr><td>Nucleos / Threads</td><td>$($cpu.NumberOfCores) / $($cpu.NumberOfLogicalProcessors)</td></tr>
  <tr><td>RAM Total (GB)</td><td>$([math]::Round($sis.TotalPhysicalMemory/1GB,1))</td></tr>
  <tr><td>Sistema Operacional</td><td>$($os.Caption) $($os.OSArchitecture)</td></tr>
  <tr><td>Build OS</td><td>$($os.BuildNumber)</td></tr>
</table>

<h2>Discos</h2>
<table>
  <tr><th>Modelo</th><th>Tamanho (GB)</th><th>Interface</th></tr>
  $($discos | ForEach-Object { "<tr><td>$($_.Model)</td><td>$([math]::Round($_.Size/1GB))</td><td>$($_.InterfaceType)</td></tr>" })
</table>

<h2>Rede</h2>
<table>
  <tr><th>Adaptador</th><th>IP</th><th>MAC</th><th>Velocidade</th></tr>
  $($rede | ForEach-Object {
      $ip = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
      "<tr><td>$($_.Name)</td><td>$ip</td><td>$($_.MacAddress)</td><td>$($_.LinkSpeed)</td></tr>"
  })
</table>

<h2>Top 10 Processos (CPU)</h2>
<table>
  <tr><th>Processo</th><th>PID</th><th>CPU (s)</th><th>RAM (MB)</th></tr>
  $($procs | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.Id)</td><td>$([math]::Round($_.CPU,1))</td><td>$([math]::Round($_.WorkingSet/1MB,1))</td></tr>" })
</table>

<h2>Servicos Automaticos Parados</h2>
$(if($svcs){ "<table><tr><th>Nome</th><th>Display Name</th></tr>" +
  ($svcs | ForEach-Object { "<tr><td>$($_.Name)</td><td>$($_.DisplayName)</td></tr>" }) +
  "</table>" } else { "<p class='ok'>Nenhum servico automatico parado.</p>" })

<h2>Ultimos Windows Updates</h2>
<table>
  <tr><th>HotFix ID</th><th>Descricao</th><th>Instalado em</th></tr>
  $($updates | ForEach-Object { "<tr><td>$($_.HotFixID)</td><td>$($_.Description)</td><td>$($_.InstalledOn.ToString('dd/MM/yyyy'))</td></tr>" })
</table>

<footer>MenuSuporte v$SCRIPT_VER | $env:COMPUTERNAME | $(Get-Date -F 'dd/MM/yyyy HH:mm')</footer>
</body></html>
"@

    $htmlPath = "$PASTA_BASE\relatorio_$($env:COMPUTERNAME)_$(Get-Date -F 'yyyyMMdd_HHmm').html"
    $html | Out-File $htmlPath -Encoding UTF8 -Force
    Start-Process $htmlPath

    Write-Host ""
    Write-Host "  Relatorio gerado e aberto no navegador." -ForegroundColor Green
    Write-Host "  Arquivo: $htmlPath" -ForegroundColor Cyan
    Write-Log -Acao "RELATORIO_HTML" -Detalhe $htmlPath
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 7 — SEGURANÇA E AUDITORIA
# ════════════════════════════════════════════════════════════
function Invoke-Seguranca {
    Show-Header "SEGURANCA E AUDITORIA"
    Write-Host "  [1]  Varredura rapida Windows Defender"
    Write-Host "  [2]  Auditoria de usuarios locais"
    Write-Host "  [3]  Verificar softwares suspeitos"
    Write-Host "  [4]  Windows Updates pendentes"
    Write-Host "  [5]  Voltar"
    Write-Host ""
    $s = Read-Host "  Opcao"
    switch ($s) {
        "1" { Invoke-Defender }
        "2" { Invoke-AuditoriaUsuarios }
        "3" { Invoke-SoftwaresSuspeitos }
        "4" { Invoke-WindowsUpdate }
    }
}

function Invoke-Defender {
    Show-Header "WINDOWS DEFENDER"
    $mpCmd = "C:\Program Files\Windows Defender\MpCmdRun.exe"

    if (-not (Test-Path $mpCmd)) {
        Write-Host "  Windows Defender nao encontrado neste sistema." -ForegroundColor Red
        Write-Host ""; Read-Host "  ENTER"; return
    }

    $status = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($status) {
        Write-Host "  Protecao em tempo real: $(if($status.RealTimeProtectionEnabled){'ATIVA'}else{'INATIVA'})" `
            -ForegroundColor $(if($status.RealTimeProtectionEnabled){"Green"}else{"Red"})
        Write-Host "  Assinaturas: $($status.AntivirusSignatureVersion)"
        $diasDef = ((Get-Date) - $status.AntivirusSignatureLastUpdated).Days
        Write-Host "  Ultima atualizacao: $diasDef dias atras" `
            -ForegroundColor $(if($diasDef -gt 7){"Yellow"}else{"Green"})
        Write-Host ""
    }

    Write-Host "  -> Iniciando varredura rapida (pode levar alguns minutos)..." -ForegroundColor Cyan
    Write-Host "  Saida do Defender:" -ForegroundColor DarkGray
    & $mpCmd -Scan -ScanType 1
    $resultado = if ($LASTEXITCODE -eq 0) { "Limpo" } else { "Ameacas detectadas (cod $LASTEXITCODE)" }
    Write-Host ""
    Write-Host "  Resultado: $resultado" -ForegroundColor $(if($LASTEXITCODE -eq 0){"Green"}else{"Red"})
    Write-Log -Acao "DEFENDER_SCAN" -Detalhe $resultado -Status $(if($LASTEXITCODE -eq 0){"OK"}else{"ALERTA"})
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-AuditoriaUsuarios {
    Show-Header "AUDITORIA DE USUARIOS LOCAIS"

    $usuarios = Get-LocalUser
    Write-Host "  === CONTAS LOCAIS ===" -ForegroundColor Cyan
    Write-Host ""

    $alertas = @()
    foreach ($u in $usuarios) {
        $cor = "White"
        $flags = @()

        if ($u.Enabled -and $u.Name -ne $env:USERNAME) { $flags += "Ativa" }
        if ($u.PasswordNeverExpires) { $flags += "SENHA_NUNCA_EXPIRA" ; $cor = "Yellow" }
        if ($u.Name -eq "Administrator" -and $u.Enabled) { $flags += "ADMIN_BUILTIN_ATIVA" ; $cor = "Red" ; $alertas += $u.Name }
        if ($u.PasswordRequired -eq $false) { $flags += "SEM_SENHA" ; $cor = "Red" ; $alertas += $u.Name }

        $status = if ($u.Enabled) { "ATIVA" } else { "desativada" }
        Write-Host "  $($u.Name.PadRight(25)) | $($status.PadRight(12)) | $($flags -join ' | ')" -ForegroundColor $cor
    }

    Write-Host ""
    if ($alertas.Count -gt 0) {
        Write-Host "  ALERTAS: $($alertas -join ', ')" -ForegroundColor Red
    } else {
        Write-Host "  Nenhum alerta critico de contas." -ForegroundColor Green
    }

    # Grupos de administradores
    Write-Host ""
    Write-Host "  === MEMBROS DO GRUPO ADMINISTRADORES ===" -ForegroundColor Cyan
    Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue |
        ForEach-Object { Write-Host "  $($_.Name) ($($_.ObjectClass))" -ForegroundColor Yellow }

    Write-Log -Acao "AUDITORIA_USUARIOS" -Detalhe "Total:$($usuarios.Count) Alertas:$($alertas.Count)"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-SoftwaresSuspeitos {
    Show-Header "SOFTWARES INSTALADOS / SUSPEITOS"
    Write-Host "  Coletando lista de softwares..." -ForegroundColor Cyan

    $regs = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $softwares = $regs | ForEach-Object {
        Get-ItemProperty $_ -ErrorAction SilentlyContinue |
            Where-Object DisplayName |
            Select-Object DisplayName, Publisher,
                @{N="Instalado";E={$_.InstallDate}},
                DisplayVersion
    } | Sort-Object DisplayName | Select-Object -Unique *

    # Verifica lista negra
    $suspeitos = $softwares | Where-Object {
        $nome = $_.DisplayName.ToLower()
        $LISTA_NEGRA | Where-Object { $nome -like "*$_*" }
    }

    Write-Host "  Total instalados: $($softwares.Count)" -ForegroundColor Cyan
    Write-Host ""

    if ($suspeitos) {
        Write-Host "  === SOFTWARES SUSPEITOS / NAO RECOMENDADOS ===" -ForegroundColor Red
        $suspeitos | Format-Table -AutoSize DisplayName, Publisher, DisplayVersion
    } else {
        Write-Host "  Nenhum software da lista negra encontrado." -ForegroundColor Green
    }

    # Exporta lista completa
    $csvSoft = "$PASTA_BASE\softwares_$env:COMPUTERNAME.csv"
    $softwares | Export-Csv $csvSoft -Encoding UTF8 -NoTypeInformation -Delimiter ";"
    Write-Host "  Lista completa exportada: $csvSoft" -ForegroundColor DarkGray

    Write-Log -Acao "AUDITORIA_SOFTWARE" -Detalhe "Total:$($softwares.Count) Suspeitos:$($suspeitos.Count)"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-WindowsUpdate {
    Show-Header "WINDOWS UPDATE"

    $updates = Get-HotFix | Sort-Object InstalledOn -Descending
    $ultimo  = $updates | Select-Object -First 1
    $dias    = ((Get-Date) - $ultimo.InstalledOn).Days

    Write-Host "  Ultimo update instalado : $($ultimo.HotFixID)" -ForegroundColor Cyan
    Write-Host "  Data                    : $($ultimo.InstalledOn.ToString('dd/MM/yyyy'))"
    Write-Host "  Ha quantos dias         : $dias" -ForegroundColor $(if($dias -gt 60){"Red"}else{"Green"})
    Write-Host ""
    Write-Host "  Ultimos 10 updates:" -ForegroundColor Cyan
    $updates | Select-Object -First 10 |
        Format-Table -AutoSize HotFixID, Description,
            @{N="Instalado";E={$_.InstalledOn.ToString("dd/MM/yyyy")}}, InstalledBy

    if ($Global:ONLINE) {
        Write-Host ""
        if (Confirm-Acao "Abrir Windows Update agora?") {
            Start-Process "ms-settings:windowsupdate"
        }
    } else {
        Write-Host "  Sem conexao — Windows Update nao disponivel." -ForegroundColor Yellow
    }

    Write-Log -Acao "WINDOWS_UPDATE" -Detalhe "Ultimo:$($ultimo.HotFixID) DiasAtras:$dias"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# OPÇÃO 8 — BACKUP E RESTAURAÇÃO
# ════════════════════════════════════════════════════════════
function Invoke-Backup {
    Show-Header "BACKUP E RESTAURACAO"
    Write-Host "  [1]  Backup de perfil do usuario (Desktop/Docs/Favoritos)"
    Write-Host "  [2]  Backup de drivers instalados"
    Write-Host "  [3]  Criar ponto de restauracao do sistema"
    Write-Host "  [4]  Verificar integridade (SFC + DISM)"
    Write-Host "  [5]  Voltar"
    Write-Host ""
    $s = Read-Host "  Opcao"
    switch ($s) {
        "1" { Invoke-BackupPerfil }
        "2" { Invoke-BackupDrivers }
        "3" { Invoke-PontoRestauracao }
        "4" { Invoke-VerificarIntegridade }
    }
}

function Invoke-BackupPerfil {
    Show-Header "BACKUP DE PERFIL"

    $destPadrao = "$PASTA_BASE\Backup"
    Write-Host "  Destino padrao: $destPadrao"
    $dest = Read-Host "  Destino (ENTER = padrao, ou caminho de rede ex: \\servidor\backup)"
    if ([string]::IsNullOrWhiteSpace($dest)) { $dest = $destPadrao }

    $pastaBkp = "$dest\$env:USERNAME`_$(Get-Date -F 'yyyyMMdd_HHmm')"

    $pastas = @(
        @{Origem="$env:USERPROFILE\Desktop";   Nome="Desktop"},
        @{Origem="$env:USERPROFILE\Documents"; Nome="Documentos"},
        @{Origem="$env:USERPROFILE\Favorites"; Nome="Favoritos"},
        @{Origem="$env:USERPROFILE\Downloads"; Nome="Downloads"},
        @{Origem="$env:APPDATA\Microsoft\Signatures"; Nome="Assinaturas_Email"}
    )

    Write-Host ""
    Write-Host "  Iniciando backup para: $pastaBkp" -ForegroundColor Cyan
    $totalBytes = 0

    foreach ($p in $pastas) {
        if (Test-Path $p.Origem) {
            $destPasta = "$pastaBkp\$($p.Nome)"
            New-Item $destPasta -ItemType Directory -Force | Out-Null
            Copy-Item "$($p.Origem)\*" $destPasta -Recurse -Force -ErrorAction SilentlyContinue
            $tam = (Get-ChildItem $destPasta -Recurse -ErrorAction SilentlyContinue |
                    Measure-Object -Property Length -Sum).Sum
            $totalBytes += $tam
            Write-Host "  [OK] $($p.Nome) — $([math]::Round($tam/1MB,1)) MB" -ForegroundColor Green
        } else {
            Write-Host "  [--] $($p.Nome) — nao encontrado" -ForegroundColor DarkGray
        }
    }

    Write-Host ""
    Write-Host "  Backup concluido. Total: $([math]::Round($totalBytes/1MB,1)) MB" -ForegroundColor Green
    Write-Host "  Local: $pastaBkp" -ForegroundColor Cyan
    Write-Log -Acao "BACKUP_PERFIL" -Detalhe "$pastaBkp | $([math]::Round($totalBytes/1MB,1))MB"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-BackupDrivers {
    Show-Header "BACKUP DE DRIVERS"
    $destDrivers = "$PASTA_BASE\Drivers_$env:COMPUTERNAME`_$(Get-Date -F 'yyyyMMdd')"

    Write-Host "  -> Exportando drivers com pnputil..." -ForegroundColor Cyan
    Write-Host "  Destino: $destDrivers"
    Write-Host ""

    pnputil /export-driver * "$destDrivers"

    $qtd = (Get-ChildItem $destDrivers -Filter "*.inf" -ErrorAction SilentlyContinue).Count
    Write-Host ""
    Write-Host "  $qtd drivers exportados para: $destDrivers" -ForegroundColor Green
    Write-Log -Acao "BACKUP_DRIVERS" -Detalhe "$destDrivers | $qtd drivers"
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-PontoRestauracao {
    Show-Header "PONTO DE RESTAURACAO"
    Write-Host "  Criando ponto de restauracao..." -ForegroundColor Cyan

    $desc = Read-Host "  Descricao (ENTER = 'MenuSuporte Manual')"
    if ([string]::IsNullOrWhiteSpace($desc)) { $desc = "MenuSuporte Manual $(Get-Date -F 'dd/MM/yyyy HH:mm')" }

    try {
        Checkpoint-Computer -Description $desc -RestorePointType MODIFY_SETTINGS
        Write-Host "  Ponto de restauracao criado!" -ForegroundColor Green
        Write-Log -Acao "PONTO_RESTAURACAO" -Detalhe $desc
    } catch {
        Write-Host "  Erro ao criar ponto. Verifique se o Volume Shadow está ativo." -ForegroundColor Red
        Write-Log -Acao "PONTO_RESTAURACAO" -Detalhe $desc -Status "ERRO"
    }
    Write-Host ""; Read-Host "  ENTER para voltar"
}

function Invoke-VerificarIntegridade {
    Show-Header "VERIFICAR INTEGRIDADE DO SISTEMA"
    Write-Host "  Esta operacao pode demorar 10 a 30 minutos." -ForegroundColor Yellow
    Write-Host ""

    if (-not (Confirm-Acao "Iniciar SFC + DISM agora?")) {
        Read-Host "  ENTER"; return
    }

    Write-Host ""
    Write-Host "  [1/2] Executando DISM /CheckHealth..." -ForegroundColor Cyan
    dism /Online /Cleanup-Image /CheckHealth
    $dismOK = $LASTEXITCODE -eq 0

    Write-Host ""
    Write-Host "  [2/2] Executando SFC /scannow..." -ForegroundColor Cyan
    sfc /scannow

    $sfcOK = $LASTEXITCODE -eq 0
    $status = "DISM:$(if($dismOK){'OK'}else{'ERRO'}) SFC:$(if($sfcOK){'OK'}else{'ERRO'})"

    Write-Host ""
    Write-Host "  Resultado: $status" -ForegroundColor $(if($dismOK -and $sfcOK){"Green"}else{"Red"})
    if (-not $sfcOK) {
        Write-Host "  Log SFC: C:\Windows\Logs\CBS\CBS.log" -ForegroundColor Yellow
    }

    Write-Log -Acao "INTEGRIDADE" -Detalhe $status -Status $(if($dismOK -and $sfcOK){"OK"}else{"ALERTA"})
    Write-Host ""; Read-Host "  ENTER para voltar"
}

# ════════════════════════════════════════════════════════════
# LOOP PRINCIPAL
# ════════════════════════════════════════════════════════════
Initialize-Script

do {
    Show-Header "MENU PRINCIPAL"
    Write-Host "  [1]  Limpeza de Sistema"
    Write-Host "  [2]  Servicos e Rede"
    Write-Host "  [3]  Criar Midia Bootavel"
    Write-Host "  [4]  Aplicar Imagem de Fabrica (.WIM)"
    Write-Host "  [5]  Registro de Maquina / BIOS + CSV"
    Write-Host "  [6]  Diagnostico e Relatorio"
    Write-Host "  [7]  Seguranca e Auditoria"
    Write-Host "  [8]  Backup e Restauracao"
    Write-Host "  [9]  Sair"
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan

    $opcao = Read-Host "  Opcao"
    switch ($opcao) {
        "1" { Invoke-Limpeza }
        "2" { Invoke-MenuRede }
        "3" { Invoke-MidiaBootavel }
        "4" { Invoke-AplicarImagem }
        "5" { Invoke-RegistroBios }
        "6" { Invoke-Diagnostico }
        "7" { Invoke-Seguranca }
        "8" { Invoke-Backup }
        "9" {
            Show-Header "ATE LOGO"
            Write-Host "  Sessao encerrada. Audit log em: $AUDIT_LOG" -ForegroundColor DarkGray
            Write-Log -Acao "ENCERRAMENTO" -Detalhe "Sessao normal"
            Start-Sleep -Seconds 1
        }
        default {
            Write-Host "  Opcao invalida." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($opcao -ne "9")
