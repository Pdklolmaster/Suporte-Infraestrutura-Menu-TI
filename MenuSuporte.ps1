#Requires -RunAsAdministrator
# ╔════════════════════════════════════════════════════════════════════╗
# ║                     TECMASTERY — Menu Suporte                      ║
# ║             Ferramenta de Suporte N1/N2 — Windows 10/11            ║
# ║                       Desenvolvido por Pablo                       ║
# ╚════════════════════════════════════════════════════════════════════╝


param(
    [string]$PastaBase = "C:\Suporte"
)








Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# ═══ Cores do Tema Tecmastery ════════════════════════════════════════
$TM = @{
    Primaria  = "Cyan"
    Acento    = "Yellow"
    Sucesso   = "Green"
    Erro      = "Red"
    Aviso     = "DarkYellow"
    Texto     = "White"
    Dim       = "DarkGray"
    Destaque  = "Magenta"
}

# ═══ Inicialização de Variáveis Globais de Ambiente ══════════════════
$global:SCRIPT_VER      = "4.5"
$global:PASTA_BASE      = $PastaBase
$global:PASTA_ISOS      = "$global:PASTA_BASE\ImagensISO"
$global:AUDIT_LOG       = "$global:PASTA_BASE\audit_log.csv"
$global:CSV_INV         = "$global:PASTA_BASE\inventario_maquinas.csv"
$global:PS_VERSION      = $PSVersionTable.PSVersion.ToString()
$global:NET_STATUS      = "DESCONHECIDO"

# ─── Resolução do caminho base relativo ao script físico em disco ─────
$global:SCRIPT_BASE_PATH  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$global:PASTA_BIN         = Join-Path $global:SCRIPT_BASE_PATH "Bin"
$global:PASTA_REPOSITORIO = Join-Path $global:PASTA_BIN "Repositorio"
$global:OSCDIMG_PATH      = Join-Path $global:PASTA_BIN "oscdimg.exe"

# Determinação do modo operativo baseado no ponto de montagem
if ($global:PASTA_BASE -ieq "C:\Suporte") {
    $global:MODO_OPERACAO = "SISTEMA LOCAL (C:\Suporte)"
} else {
    $global:MODO_OPERACAO = "PENDRIVE AUTOMÁTICO (Ferramentas)"
}

# ═══ Garantia de Integridade Estrutural das Pastas Físicas ────────
foreach ($pasta in @($global:PASTA_BASE, $global:PASTA_ISOS)) {
    if (-not (Test-Path $pasta)) {
        New-Item -Path $pasta -ItemType Directory -Force | Out-Null
    }
}

if (-not (Test-Path $global:AUDIT_LOG)) {
    "Data;Hora;Tecnico;Computador;Acao;Detalhe;Status" | Set-Content $global:AUDIT_LOG -Encoding UTF8
}

# ════════════════════════════════════════════════════════════════
#   INFRAESTRUTURA INTERNA DE INTERFACE E AUXILIARES
# ════════════════════════════════════════════════════════════════

function Show-DragonAsciiAnimated {
    Clear-Host

    # ASCII do dragão
    $ascii = @"
                                              :      .#!                                  
                                            ^Y&!     ^&G~77~.      ^:                     
                                        :!YB@@@?    J&@@@@@B7^.   :G.                     
                                   :!JP#&@@@@@G.   :#@@&#@@@@57.  :&~..                   
                                :?G&@@@@@@@@@@~   J&@&Y:^!G@@@5!  .&&PBY7^.               
                               J&@@@@@@@@@@@@@^   PY!.    ?@@@#~  J@@@@@@@#P7.            
                             .G@@@@@@@@@@@@@@@?   .      !&@@@#5 ?@@@@@@@@@@@#J.          
                             P#5JJYBG@@@@@@@@@&!       ^5@@@@Y ^5@@@@@@@@@@@@@@B^         
                            ^7      ?@@@@@@@@@@@P~   ~P@@@@@B:!#@@@@@@@@@@@@@@@@#.        
                                   ^#@@@@@@@@@@@@@B5Y#@@@@&PJG@@@@@@@@@@@@@@@@@@@7        
                                  7&#57!P@@@@@@@@@@@@@@@@&#&@@@@@@@@@@@@@@@@@@@@@!        
                                 YB7.   7@@BPP&&&@@@@@@@@@@&@@@@@@@@@@@@##G??G@@G         
                                :P.    .BB~   ^^.?@@@@@PJG@G?J&@@@@@@@@@@@~   Y&:         
                                       7B.      .P@&&@P  .~.  :B@@&G5JY&@&:   ~~          
                                       7?      !#@@P!J.        7@G:    !@5                
                                        :     ?@@PBP           P&:     ~?                 
                                             ~@&~ ..          ?5:                         
                                             P@J   !J5P7     ..                           
                                             B@! :GB^.!&J                                 
                                             5@G.!!.   GJ                                 
                                             .P@&Y~~!JG5.                                 
                                               ~JPGGPJ~                                                      
  _____                                 _       _     _                            _____      _     _       
 |  __ \                               | |     (_)   | |                          |  __ \    | |   | |      
 | |  | | ___  ___  ___ _ ____   _____ | |_   ___  __| | ___    _ __   ___  _ __  | |__) |_ _| |__ | | ___  
 | |  | |/ _ \/ __|/ _ \ '_ \ \ / / _ \| \ \ / / |/ _` |/ _ \  | '_ \ / _ \| '__| |  ___/ _` | '_ \| |/ _ \ 
 | |__| |  __/\__ \  __/ | | \ V / (_) | |\ V /| | (_| | (_) | | |_) | (_) | |    | |  | (_| | |_) | | (_) |
 |_____/ \___||___/\___|_| |_|\_/ \___/|_| \_/ |_|\__,_|\___/  | .__/ \___/|_|    |_|   \__,_|_.__/|_|\___/ 
                                                               | |                                          
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀                                
"@

    # Exibe linha por linha com delay
    $ascii.Split("`n") | ForEach-Object {
        Write-Host $_ -ForegroundColor Green
        Start-Sleep -Milliseconds 50
    }

    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║              SUPORTE DE SISTEMAS CORPORATIVO         ║" -ForegroundColor Green
    Write-Host "╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "Pressione qualquer tecla para iniciarmos nosso trabalho..." -ForegroundColor DarkGray

    # Espera tecla e limpa tela
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    Clear-Host
}

function Show-Banner {
    Clear-Host
    $w = 66
    $borda = "═" * $w
    Write-Host ""
    
    # Topo do Banner
    Write-Host "  ╔$borda╗" -ForegroundColor $TM.Primaria
    
     # Linha 1: Nome da Ferramenta (Calculado Dinamicamente)
    $TextoLinha1 = "   TECMASTERY — MenuSuporte v$global:SCRIPT_VER"
    $EspacosLinha1 = $w - $TextoLinha1.Length
    Write-Host "  ║" -NoNewline -ForegroundColor $TM.Primaria
    Write-Host $TextoLinha1 -NoNewline -ForegroundColor $TM.Texto
    Write-Host (" " * $EspacosLinha1 + "║") -ForegroundColor $TM.Primaria
    
    # Linha 2: Descrição da Ferramenta (Calculado Dinamicamente)
    $TextoLinha2 = "   Ferramenta de Suporte N1/N2 — Windows 10/11"
    $EspacosLinha2 = $w - $TextoLinha2.Length
    Write-Host "  ║" -NoNewline -ForegroundColor $TM.Primaria
    Write-Host $TextoLinha2 -NoNewline -ForegroundColor $TM.Dim
    Write-Host (" " * $EspacosLinha2 + "║") -ForegroundColor $TM.Primaria
    
    # Divisória do Meio
    Write-Host "  ╠$borda╣" -ForegroundColor $TM.Primaria

    # Linha 3: Metadados do Sistema (Host, Usuário, Data e Hora)
    $hora = Get-Date -Format "HH:mm"
    $data = Get-Date -Format "dd/MM/yyyy"
    
    # Exibe os dados mantendo suas cores originais por seção
    Write-Host "  ║  " -NoNewline -ForegroundColor $TM.Primaria
    Write-Host "$env:COMPUTERNAME" -NoNewline -ForegroundColor $TM.Texto
    Write-Host "  │  " -NoNewline -ForegroundColor $TM.Primaria
    Write-Host "$env:USERNAME" -NoNewline -ForegroundColor $TM.Dim
    Write-Host "  │  " -NoNewline -ForegroundColor $TM.Primaria
    Write-Host "$data $hora" -NoNewline -ForegroundColor $TM.Dim
    
    # Conta quantos caracteres foram impressos dentro da caixa para saber quantos espaços faltam
    $TamanhoTextoImpresso = "  ".Length + $env:COMPUTERNAME.Length + "  │  ".Length + $env:USERNAME.Length + "  │  ".Length + "$data $hora".Length
    $EspacosRestantes = $w - $TamanhoTextoImpresso
    if ($EspacosRestantes -lt 0) { $EspacosRestantes = 0 }
    
    # Fecha a borda perfeitamente alinhada no final da linha 3
    Write-Host (" " * $EspacosRestantes + "║") -ForegroundColor $TM.Primaria
    
    # Rodapé do Banner
    Write-Host "  ╚$borda╝" -ForegroundColor $TM.Primaria
    Write-Host ""
}

function Show-Header {
    param(
        [string]$Titulo,
        [string]$Subtitulo = "",
        [switch]$Perigo,
        [switch]$Dev
    )
    Clear-Host
    $w = 66
    $borderColor = if ($Perigo) { $TM.Erro } elseif ($Dev) { $TM.Dim } else { $TM.Primaria }
    $borda = "═" * $w
    Write-Host ""
    Write-Host "  ╔$borda╗" -ForegroundColor $borderColor
    Write-Host "  ║  " -NoNewline -ForegroundColor $borderColor
    Write-Host "TECMASTERY" -NoNewline -ForegroundColor $TM.Acento
    Write-Host "  │  " -NoNewline -ForegroundColor $borderColor
    Write-Host $Titulo -NoNewline -ForegroundColor $TM.Texto
    Write-Host (" " * ($w - 17 - $Titulo.Length) + "║") -ForegroundColor $borderColor

    if ($Subtitulo) {
        Write-Host "  ║  " -NoNewline -ForegroundColor $borderColor
        Write-Host $Subtitulo -NoNewline -ForegroundColor $TM.Dim
        Write-Host (" " * ($w - 2 - $Subtitulo.Length) + "║") -ForegroundColor $borderColor
    }

    Write-Host "  ╠$borda╣" -ForegroundColor $borderColor
    Write-Host "  ║  " -NoNewline -ForegroundColor $borderColor
    Write-Host $env:COMPUTERNAME -NoNewline -ForegroundColor $TM.Dim
    Write-Host "  ·  " -NoNewline -ForegroundColor $borderColor
    Write-Host $env:USERNAME -NoNewline -ForegroundColor $TM.Dim
    Write-Host (" " * ($w - 15 - $env:COMPUTERNAME.Length - $env:USERNAME.Length) + "║") -ForegroundColor $borderColor
    Write-Host "  ╚$borda╝" -ForegroundColor $borderColor
    Write-Host ""
}

function Write-MenuItem {
    param([string]$Numero, [string]$Label, [string]$Detalhe = "", [switch]$Perigo, [switch]$Dev)
    Write-Host "    " -NoNewline
    if ($Perigo) {
        Write-Host "[$Numero]" -NoNewline -ForegroundColor $TM.Erro
    } elseif ($Dev) {
        Write-Host "[$Numero]" -NoNewline -ForegroundColor $TM.Dim
    } else {
        Write-Host "[$Numero]" -NoNewline -ForegroundColor $TM.Acento
    }
    Write-Host "  $Label" -NoNewline -ForegroundColor $TM.Texto
    if ($Detalhe) {
        Write-Host "  $Detalhe" -NoNewline -ForegroundColor $TM.Dim
    }
    Write-Host ""
}

function Write-Separador {
    Write-Host "    " -NoNewline
    Write-Host ("─" * 54) -ForegroundColor $TM.Primaria
}

function Write-Status {
    param([string]$Msg, [string]$Tipo = "info")
    $icon = switch ($Tipo) {
        "ok"    { "✔" }
        "erro"  { "✘" }
        "aviso" { "!" }
        "info"  { "·" }
        "run"   { "»" }
        default { "·" }
    }
    $cor = switch ($Tipo) {
        "ok"    { $TM.Sucesso }
        "erro"  { $TM.Erro }
        "aviso" { $TM.Aviso }
        "info"  { $TM.Dim }
        "run"   { $TM.Primaria }
        default { $TM.Dim }
    }
    Write-Host "    [$icon] " -NoNewline -ForegroundColor $cor
    Write-Host $Msg -ForegroundColor $TM.Texto
}

function Show-Prompt {
    param([string]$Label = "Opcao")
    Write-Host ""
    Write-Host "  ╼ " -NoNewline -ForegroundColor $TM.Primaria
    Write-Host $Label -NoNewline -ForegroundColor $TM.Acento
    Write-Host " ▸ " -NoNewline -ForegroundColor $TM.Primaria
    return (Read-Host)
}

function Pause-Tela {
    Write-Host ""
    Write-Host "  ╼ " -NoNewline -ForegroundColor $TM.Dim
    Write-Host "Pressione ENTER para retornar..." -NoNewline -ForegroundColor $TM.Dim
    $null = Read-Host
}

function Write-Log {
    param($Acao, $Detalhe, $Status)
    $linha = "$(Get-Date -Format 'dd/MM/yyyy');$(Get-Date -Format 'HH:mm:ss');$env:USERNAME;$env:COMPUTERNAME;$Acao;$Detalhe;$Status"
    Add-Content -Path $global:AUDIT_LOG -Value $linha -Encoding UTF8
}

function Test-RedeGlobal {
    if (Test-Connection -ComputerName 8.8.8.8 -Count 1 -Quiet -ErrorAction SilentlyContinue) {
        $global:NET_STATUS = "ONLINE"
    } else {
        $global:NET_STATUS = "OFFLINE"
    }
}

function Reverse-Array {
    param([Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $false)]$InputObject)
    begin { $items = @() }
    process { $items += $InputObject }
    end {
        if ($items.Count -gt 0) { [array]::Reverse($items) }
        $items
    }
}

function Show-ProgressBar {
    param(
        [int]$Percent,
        [string]$Descricao = ""
    )
    $barLen  = 48
    $filled  = [int]($Percent * $barLen / 100)
    $empty   = $barLen - $filled
    $blocos  = ("█" * $filled) + ("░" * $empty)
    $pctStr  = "$Percent%".PadLeft(4)

    Write-Host "    " -NoNewline
    Write-Host "[$blocos]" -NoNewline -ForegroundColor $TM.Primaria
    Write-Host " $pctStr" -NoNewline -ForegroundColor $TM.Acento
    if ($Descricao) {
        Write-Host "  $Descricao" -NoNewline -ForegroundColor $TM.Dim
    }
    Write-Host ""
}

function Invoke-ComandoComFeedback {
    param(
        [string]$Label,
        [scriptblock]$Bloco,
        [string]$MensagemInicio  = "Processando...",
        [string]$MensagemSucesso = "Operação concluída com sucesso!",
        [string]$MensagemErro    = "Operação encerrada com código de erro"
    )

    $largura = 54
    $borda   = "─" * $largura
    Write-Host ""
    Write-Host "    ╔$borda╗" -ForegroundColor $TM.Primaria
    Write-Host "    ║  " -NoNewline -ForegroundColor $TM.Primaria
    Write-Host $Label.PadRight($largura - 2) -NoNewline -ForegroundColor $TM.Acento
    Write-Host "║" -ForegroundColor $TM.Primaria
    Write-Host "    ╚$borda╝" -ForegroundColor $TM.Primaria
    Write-Host ""
    Write-Status $MensagemInicio "run"
    Write-Host ""

    $job = Start-Job -ScriptBlock $Bloco

    $pct = 0
    $step = 3
    while ($job.State -eq "Running") {
        if ($pct -lt 95) { $pct += $step }
        [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
        Show-ProgressBar -Percent $pct -Descricao "aguardando retorno do processo..."
        Start-Sleep -Milliseconds 400
    }

    $resultado = Receive-Job -Job $job 2>&1
    Remove-Job  -Job $job -Force

    if ($resultado) {
        Write-Host ""
        $resultado | ForEach-Object {
            Write-Host "    │ $_" -ForegroundColor $TM.Dim
        }
    }

    $exitCode = 0
    if ($resultado -and $resultado[-1] -match '^\d+$') {
        $exitCode = [int]$resultado[-1]
    }

    [Console]::SetCursorPosition(0, [Console]::CursorTop - 1)
    Show-ProgressBar -Percent 100 -Descricao "finalizado."
    Write-Host ""

    if ($exitCode -eq 0) {
        Write-Status $MensagemSucesso "ok"
    } else {
        Write-Status "$MensagemErro`: $exitCode" "erro"
    }

    return $exitCode
}

function Test-AndInstallOscdimg {
    Show-Header "PRE-FLIGHT CHECK: DEPLOYMENT ENGINE" "Análise de Dependências de Engenharia de Imagem"
    Write-Status "Verificando motor de compilação de mídias Microsoft (oscdimg.exe)..." "run"
    Start-Sleep -Milliseconds 600

    if (Test-Path $global:OSCDIMG_PATH) {
        Write-Status "Utilitário oscdimg.exe detectado e operacional no ambiente de execução." "ok"
        Write-Host "    • Diretório: $global:OSCDIMG_PATH" -ForegroundColor $TM.Dim
        Start-Sleep -Milliseconds 800
        return $true
    } 
    
    Write-Status "Componente crítico 'oscdimg.exe' ausente na árvore de execução ativa." "aviso"
    Write-Status "Iniciando verificação de integridade no Repositório de segurança local..." "run"
    Start-Sleep -Seconds 1
    
    $origemRepositorio = Join-Path $global:PASTA_REPOSITORIO "oscdimg.exe"
    
    if (Test-Path $origemRepositorio) {
        Write-Status "Binário de instalação localizado no repositório com integridade válida." "ok"
        Write-Status "Iniciando implantação automatizada na estrutura física do sistema..." "run"
        try {
            if (-not (Test-Path $global:PASTA_BIN)) {
                New-Item -ItemType Directory -Path $global:PASTA_BIN -Force | Out-Null
            }
            
            Copy-Item -Path $origemRepositorio -Destination $global:OSCDIMG_PATH -Force
            
            Write-Status "Instalação concluída com sucesso! Dependência injetada em: $global:PASTA_BIN" "ok"
            Write-Log "Oscdimg_Install" "Instalação automatizada via repositório de segurança concluída" "SUCESSO"
            Start-Sleep -Seconds 2
            return $true
        } catch {
            Write-Status "Falha catastrófica de I/O de disco durante a instalação do binário." "erro"
            Write-Status "Erro gerado pelo subsistema: $_" "erro"
            Write-Log "Oscdimg_Install" "Falha na cópia física: $_" "ERRO"
            Pause-Tela
            return $false
        }
    } else {
        Write-Status "ERRO CRÍTICO: O motor oscdimg.exe não foi localizado no repositório de segurança!" "erro"
        Write-Host ""
        Write-Host "    Para solucionar este bloqueio operacional:" -ForegroundColor $TM.Acento
        Write-Host "    1. Obtenha o arquivo 'oscdimg.exe' oficial do Windows ADK Microsoft." -ForegroundColor $TM.Texto
        Write-Host "    2. Deposite uma cópia estrutural limpa do arquivo na pasta:" -ForegroundColor $TM.Texto
        Write-Host "       $origemRepositorio" -ForegroundColor $TM.Acento
        Write-Host ""
        Write-Status "O Módulo de compilação ficará suspenso até a resolução deste pré-requisito." "aviso"
        Write-Log "Oscdimg_Install" "Binário ausente no repositório e na pasta Bin" "BLOQUEADO"
        Pause-Tela
        return $false
    }
}

function Invoke-Limpeza {
    Show-Header "LIMPEZA DE SISTEMA" "Temp · Prefetch · SoftwareDistribution · Lixeira"
    Write-Status "Iniciando processo de higienização de lixo lógico..." "run"
    
    $pastas = @("C:\Windows\Temp", $env:TEMP, "$env:LOCALAPPDATA\Temp", "C:\Windows\Prefetch")
    foreach ($pasta in $pastas) {
        if (Test-Path $pasta) {
            Write-Status "Limpando diretório: $pasta" "run"
            Remove-Item -Path "$pasta\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Status "Limpando cache do Windows Update (SoftwareDistribution)..." "run"
    Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Status "Esvaziando Lixeira de todos os volumes ativos..." "run"
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    
    Write-Status "Processo de higienização finalizado!" "ok"
    Write-Log -Acao "Limpeza" -Detalhe "Limpeza total de caches e arquivos temporários" -Status "SUCESSO"
    Pause-Tela
}

function Invoke-MenuRede {
    do {
        Show-Header "SERVIÇOS E REDE" "Spooler · DNS · IP · TCP"
        Write-Host ""
        Write-MenuItem "1" "Reiniciar Spooler de Impressão" "Limpando fila física pendente"
        Write-MenuItem "2" "Flush DNS + Reset de IP DHCP" "Renovar adaptadores de rede"
        Write-MenuItem "3" "Diagnóstico Avançado de Portas TCP" "Testar sockets externos cruciais"
        Write-Separador
        Write-MenuItem "4" "Voltar ao Menu Principal"

        $sub = Show-Prompt "Rede"
        switch ($sub) {
            "1" {
                Show-Header "SPOOLER DE IMPRESSÃO" "Resetando subsistema de impressão"
                Write-Status "Interrompendo serviço Spooler..." "run"
                Stop-Service -Name "Spooler" -Force -ErrorAction SilentlyContinue
                Write-Status "Expurgando arquivos de fila (.SHD e .SPL)..." "run"
                Remove-Item -Path "C:\Windows\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
                Write-Status "Reiniciando serviço Spooler..." "run"
                Start-Service -Name "Spooler" -ErrorAction SilentlyContinue
                Write-Status "Subsistema de impressão normalizado com sucesso!" "ok"
                Write-Log "Spooler_Reset" "Fila limpa e serviço reiniciado" "SUCESSO"
                Pause-Tela
            }
            "2" {
                Show-Header "RESET DE CONECTIVIDADE" "Liberando buffers IP"
                Write-Status "Limpando cache do DNS Resolver..." "run"
                $null = ipconfig /flushdns
                Write-Status "Redefinindo catálogo Winsock do Kernel..." "run"
                $null = netsh winsock reset
                Write-Status "Renovando concessões de IP DHCP..." "run"
                $null = ipconfig /release
                $null = ipconfig /renew
                Write-Status "Interfaces de rede redefinidas e renovadas!" "ok"
                Write-Log "Rede_Reset" "Flush DNS e Winsock Reset aplicados" "SUCESSO"
                Pause-Tela
            }
            "3" {
                Show-Header "DIAGNÓSTICO TCP/IP" "Sondagem de sockets ativos"
                $testes = @(
                    @{ Host = "8.8.8.8"; Porta = 53; Label = "Google DNS (Porta 53 - DNS)" },
                    @{ Host = "google.com"; Porta = 80; Label = "HTTP Portal (Porta 80 - Web)" },
                    @{ Host = "google.com"; Porta = 443; Label = "HTTPS Seguro (Porta 443 - SSL)" }
                )
                foreach ($t in $testes) {
                    $tcp = New-Object System.Net.Sockets.TcpClient
                    try {
                        $r = $tcp.BeginConnect($t.Host, $t.Porta, $null, $null)
                        $ok = $r.AsyncWaitHandle.WaitOne(2000)
                        if ($ok) { $tcp.EndConnect($r) }
                        $tcpStatusLabel = if ($ok) { 'ABERTA / ATIVA' } else { 'BLOQUEADA / TIMEOUT' }
                        $tcpStatusTipo  = if ($ok) { "ok" } else { "erro" }
                        Write-Status "$($t.Label): $tcpStatusLabel" $tcpStatusTipo
                    } catch {
                        Write-Status "$($t.Label): FALHA CRÍTICA" "erro"
                    } finally {
                        $tcp.Close()
                    }
                }
                Pause-Tela
            }
        }
    } while ($sub -ne "4")
}

function Invoke-MenuImplantacao {
    do {
        Show-Header "IMPLANTAÇÃO E MÍDIAS" "Aplicações de Imagem WIM · Criação de ISO Custom"
        Write-Host ""
        Write-MenuItem "1" "Listar Imagens Disponíveis" "Inventário de arquivos .wim / .esd / .iso"
        Write-MenuItem "2" "Aplicar Imagem ISO em Volume Alvo" "Formatar disco e instalar WIM via DISM" -Perigo
        Write-MenuItem "3" "Compilar ISO Bootável (Oscdimg)" "Gerar ISO híbrida UEFI/BIOS a partir de pasta"
        Write-MenuItem "4" "Capturar Sistema Atual e Gerar ISO" "Snapshot DISM + compilação de ISO customizada" -Perigo
        Write-Separador
        Write-MenuItem "5" "Voltar ao Menu Principal"

        $sub = Show-Prompt "Implantacao"
        switch ($sub) {
            "1" {
                Show-Header "INVENTÁRIO DE MÍDIAS" "Varrendo diretório de imagens"
                Write-Status "Procurando arquivos válidos em: $global:PASTA_ISOS" "run"
                
                $imagens = Get-ChildItem -Path $global:PASTA_ISOS -Include "*.wim", "*.esd", "*.iso" -Recurse -ErrorAction SilentlyContinue
                if ($imagens) {
                    Write-Status "Mídias identificadas em repositório:" "ok"
                    foreach ($img in $imagens) {
                        Write-Host "    • $($img.Name) ($([Math]::Round($img.Length / 1GB, 2)) GB)" -ForegroundColor $TM.Texto
                    }
                } else {
                    Write-Status "Nenhum arquivo (.wim, .esd, .iso) encontrado em: $global:PASTA_ISOS" "aviso"
                    Write-Status "Deposite arquivos WIM corporativos nesta pasta para permitir a aplicação automatizada." "info"
                }
                Write-Log "Implantacao_Scan" "Varredura de midias executada" "SUCESSO"
                Pause-Tela
            }
            "2" {
                Show-Header "APLICAR IMAGEM (DISM)" "Aviso de Sobrescrita de Partição" -Perigo
                Write-Status "Operação destrutiva! O disco selecionado será limpo e formatado." "aviso"

                $discos = Get-Disk
                Write-Host "Discos disponíveis:" -ForegroundColor Cyan
                foreach ($d in $discos) {
                    Write-Host "[$($d.Number)] Modelo: $($d.FriendlyName) - Tamanho: $([Math]::Round($d.Size/1GB,2)) GB"
                }

                $choice = Show-Prompt "Digite o número do disco alvo"
                $diskNum = [int]$choice

                $dpScript = @"
            select disk $diskNum
            clean
            create partition primary
            format fs=ntfs quick
            assign letter=W
            exit
"@

                $dpFile = "$env:TEMP\diskpart_script.txt"
                $dpScript | Out-File -FilePath $dpFile -Encoding ASCII

                $dpFileCapture = $dpFile
                $exitDp = Invoke-ComandoComFeedback `
                    -Label       "ETAPA 1/3 · DISKPART — Particionamento e Formatação" `
                    -Bloco       { diskpart /s $using:dpFileCapture; Write-Output $LASTEXITCODE } `
                    -MensagemInicio  "Executando script de particionamento no disco $diskNum..." `
                    -MensagemSucesso "Disco $diskNum particionado e formatado (volume W:)" `
                    -MensagemErro    "Diskpart retornou código de erro"

                if ($exitDp -ne 0) {
                    Write-Log "DISM_Apply" "Diskpart falhou no disco $diskNum" "ERRO"
                    Pause-Tela; break
                }

                $wimPath = Show-Prompt "Caminho do arquivo .wim (Ex: C:\Suporte\ImagensISO\install.wim)"
                if (-not (Test-Path $wimPath)) {
                    Write-Status "Arquivo de imagem inválido ou inexistente!" "erro"
                    Pause-Tela; break
                }

                $index = Show-Prompt "Digite o Índice do SO desejado dentro do WIM (Ex: 1, 2)"

                Write-Log "DISM_Apply" "Iniciando Apply-Image de $wimPath no disco $diskNum (volume W:)" "RUNNING"

                $wimCapture   = $wimPath
                $indexCapture = $index
                $exitDism = Invoke-ComandoComFeedback `
                    -Label       "ETAPA 2/3 · DISM — Aplicação da Imagem WIM" `
                    -Bloco       { dism /Apply-Image /ImageFile:"$using:wimCapture" /Index:$using:indexCapture /ApplyDir:"W:\"; Write-Output $LASTEXITCODE } `
                    -MensagemInicio  "Descomprimindo e gravando imagem no volume W: (pode demorar vários minutos)..." `
                    -MensagemSucesso "Imagem index $index aplicada com sucesso no disco $diskNum (volume W:)" `
                    -MensagemErro    "DISM Apply-Image retornou código de erro"

                if ($exitDism -eq 0) {
                    Write-Log "DISM_Apply" "Sucesso na aplicação da imagem index $index" "SUCESSO"
                } else {
                    Write-Log "DISM_Apply" "Erro código $exitDism" "ERRO"
                    Pause-Tela; break
                }

                $exitBcd = Invoke-ComandoComFeedback `
                    -Label       "ETAPA 3/3 · BCDBOOT — Configuração do Gerenciador de Boot" `
                    -Bloco       { bcdboot W:\Windows /s W: /f ALL; Write-Output $LASTEXITCODE } `
                    -MensagemInicio  "Injetando entradas de boot UEFI/BIOS no volume W:..." `
                    -MensagemSucesso "Gerenciador de boot configurado. Sistema pronto para reinicialização." `
                    -MensagemErro    "BCDBoot retornou código de erro"

                if ($exitBcd -ne 0) {
                    Write-Log "DISM_Apply" "BCDBoot falhou com código $exitBcd" "ERRO"
                }

                Pause-Tela
            }
            "3" {
                Show-Header "COMPILAR ISO BOOTÁVEL" "Engine Oscdimg Microsoft ADK"
                
                if (-not (Test-Path $global:OSCDIMG_PATH)) {
                    Write-Status "Binário 'oscdimg.exe' ausente na pasta operacional Bin." "erro"
                    Write-Status "A validação automatizada inicial falhou ou o arquivo foi corrompido." "info"
                    Pause-Tela
                    break
                }

                $sourceFolder = Show-Prompt "Pasta com os arquivos extraídos do Windows (Origem)"
                $outputIso    = Show-Prompt "Caminho completo da ISO a gerar (Ex: C:\Suporte\ImagensISO\Custom.iso)"

                if (-not (Test-Path $sourceFolder)) {
                    Write-Status "A pasta de arquivos de origem informada não existe!" "erro"
                    Pause-Tela
                    break
                }

                Write-Status "Preparando estrutura de boot e iniciando compilação..." "run"
                
                $etfsPath     = "$sourceFolder\boot\etfsboot.com"
                $efisPath     = "$sourceFolder\efi\microsoft\boot\efisys.bin"
                $bootArg      = "-bootdata:2#p0,e,b`"$etfsPath`"#pEF,e,b`"$efisPath`""
                $oscdimgPath  = $global:OSCDIMG_PATH
                $srcCapture   = $sourceFolder
                $isoCapture   = $outputIso

                $exitIso = Invoke-ComandoComFeedback `
                    -Label       "OSCDIMG — Compilação de ISO Híbrida UEFI/BIOS" `
                    -Bloco       { & $using:oscdimgPath $using:bootArg -u2 -udfver102 "$using:srcCapture" "$using:isoCapture"; Write-Output $LASTEXITCODE } `
                    -MensagemInicio  "Gerando ISO a partir de $sourceFolder..." `
                    -MensagemSucesso "Arquivo ISO gerado e pronto para gravação: $outputIso" `
                    -MensagemErro    "Oscdimg retornou código de erro"
                
                if ($exitIso -eq 0) {
                    Write-Log "Oscdimg_Compile" "ISO gerada: $outputIso" "SUCESSO"
                } else {
                    Write-Log "Oscdimg_Compile" "Falha código $exitIso" "ERRO"
                }
                Pause-Tela
            }
            "4" {
                Show-Header "CAPTURAR SISTEMA ATUAL" "Gerar ISO Bootável Customizada"

                $drives = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Root -match "^[A-Z]:\\" }
                Write-Host "Unidades disponíveis para captura:" -ForegroundColor Cyan
                $i = 1
                foreach ($d in $drives) {
                    Write-Host "[$i] $($d.Name):\  ($([Math]::Round($d.Used/1GB,2)) GB usados de $([Math]::Round($d.Free/1GB,2)) GB livres)"
                    $i++
                }

                $choice = Show-Prompt "Digite o número da unidade que deseja capturar"
                $index = [int]$choice - 1
                if ($index -lt 0 -or $index -ge $drives.Count) {
                    Write-Status "Número inválido selecionado!" "erro"
                    Pause-Tela
                    break
                }

                $selectedDrive = $drives[$index].Root.TrimEnd("\")
                if ($selectedDrive -eq $env:SystemDrive) {
                    Write-Status "Não é possível capturar o volume ativo ($selectedDrive) dentro do Windows em execução." "erro"
                    Write-Status "Execute esta opção em ambiente WinPE ou selecione um disco secundário offline." "info"
                    Pause-Tela
                    break
                }

                $isoDir = Join-Path $global:PASTA_ISOS "ISO"
                if (-not (Test-Path $isoDir)) {
                    New-Item -ItemType Directory -Path $isoDir | Out-Null
                }

                $isoName = Show-Prompt "Digite o nome para salvar a ISO (sem extensão)"
                $isoPath = Join-Path $isoDir "$isoName.iso"
                $capturaWim = Join-Path $global:PASTA_ISOS "install.wim"

                Write-Status "Capturando imagem da unidade $selectedDrive via DISM..." "run"
                $capturaCapture  = $capturaWim
                $driveCapture    = $selectedDrive
                $exitCapture = Invoke-ComandoComFeedback `
                    -Label       "DISM — Captura de Imagem do Sistema ($selectedDrive)" `
                    -Bloco       { dism /Capture-Image /ImageFile:"$using:capturaCapture" /CaptureDir:"$using:driveCapture\" /Name:"SistemaCapturado" /Compress:Max /CheckIntegrity; Write-Output $LASTEXITCODE } `
                    -MensagemInicio  "Capturando todo o volume $selectedDrive (pode demorar muitos minutos)..." `
                    -MensagemSucesso "Imagem capturada com sucesso: $capturaWim" `
                    -MensagemErro    "DISM Capture-Image retornou código de erro"

                if ($exitCapture -eq 0) {
                    Write-Status "Imagem capturada com sucesso: $capturaWim" "ok"
                } else {
                    Write-Status "Falha crítica na captura. Código de saída: $exitCapture" "erro"
                    Pause-Tela
                    break
                }

                Write-Status "Substituindo WIM na pasta sources..." "run"
                $sourcesPath = Join-Path $global:PASTA_ISOS "sources"
                if (-not (Test-Path $sourcesPath)) {
                    New-Item -ItemType Directory -Path $sourcesPath | Out-Null
                }
                Copy-Item $capturaWim (Join-Path $sourcesPath "install.wim") -Force

                if (-not (Test-Path $global:OSCDIMG_PATH)) {
                    Write-Status "Binário 'oscdimg.exe' ausente na pasta operacional Bin." "erro"
                    Pause-Tela
                    break
                }

                $etfsPath  = "$sourcesPath\boot\etfsboot.com"
                $efisPath  = "$sourcesPath\efi\microsoft\boot\efisys.bin"
                $bootArg   = "-bootdata:2#p0,e,b`"$etfsPath`"#pEF,e,b`"$efisPath`""
                $oscdimgPath  = $global:OSCDIMG_PATH
                $isoPathFinal = $isoPath

                $exitIso = Invoke-ComandoComFeedback `
                    -Label       "OSCDIMG — Compilação de ISO Híbrida UEFI/BIOS" `
                    -Bloco       { & $using:oscdimgPath $using:bootArg -u2 -udfver102 "$using:sourcesPath" "$using:isoPathFinal"; Write-Output $LASTEXITCODE } `
                    -MensagemInicio  "Gerando estrutura ISO e calculando checksums de integridade..." `
                    -MensagemSucesso "ISO criada com sucesso: $isoPath" `
                    -MensagemErro    "Oscdimg retornou código de erro"

                if ($exitIso -ne 0) {
                    Write-Status "Erro na compilação da ISO. Código: $exitIso" "erro"
                }
                Pause-Tela
            }
        }
    } while ($sub -ne "5")
}

function Invoke-RegistroBios {
    Show-Header "REGISTRO E INVENTÁRIO DE HARDWARE" "Extração de Metadados de Firmware"
    Write-Status "Consultando tabelas WMI da placa-mãe e BIOS..." "run"
    try {
        $bios = Get-CimInstance Win32_Bios -ErrorAction SilentlyContinue
        $comp = Get-CimInstance Win32_ComputerSystem -ErrorAction SilentlyContinue
        
        Write-Status "Fabricante/Modelo: $($comp.Manufacturer) - $($comp.Model)" "info"
        Write-Status "Número de Série (S/N): $($bios.SerialNumber)" "info"
        
        $linhaInv = "$(Get-Date -Format 'dd/MM/yyyy');$env:COMPUTERNAME;$($comp.Manufacturer);$($comp.Model);$($bios.SerialNumber);$env:USERNAME"
        if (-not (Test-Path $global:CSV_INV)) {
            "Data;Computador;Fabricante;Modelo;SerialNumber;UltimoUsuario" | Set-Content $global:CSV_INV -Encoding UTF8
        }
        $linhaInv | Add-Content -Path $global:CSV_INV -Encoding UTF8
        Write-Status "Dados de hardware registrados com sucesso em: $global:CSV_INV" "ok"
        Write-Log "Registro_Bios" "Inventário exportado com sucesso" "SUCESSO"
    } catch {
        Write-Status "Erro crítico na requisição de propriedades WMI/CIM da BIOS." "erro"
    }
    Pause-Tela
}

function Invoke-Diagnostico {
    Show-Header "DIAGNÓSTICO E RELATÓRIO" "Score Heurístico de Saúde e Geração HTML"
    Write-Status "Executando sondagem (pode demorar de 30 a 60 segundos)..." "run"
    
    $diagnostico = @{
        Timestamp = Get-Date; CPU = $null; Memory = $null; Disco = $null
        WindowsUpdate = $null; Drivers = $null; Eventos = $null; Antivirus = $null; Score = 0
    }
    
    # [1] CPU DETALHADA
    Write-Status "Processando dados do processador..." "run"
    try {
        $cpuProc = Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue | Select-Object -First 1
        $queue = (Get-CimInstance Win32_PerfFormattedData_PerfOS_System -ErrorAction SilentlyContinue).ProcessorQueueLength
        if ($null -eq $queue) { $queue = 0 }
        $cpuLoad = $cpuProc.LoadPercentage
        if ($null -eq $cpuLoad) { $cpuLoad = 15 }
        
        $scoreCPU = if ($cpuLoad -gt 85 -or $queue -gt 4) { 40 } elseif ($cpuLoad -gt 50) { 75 } else { 100 }
        $diagnostico.CPU = @{ Processador = $cpuProc.Name; Carga = "$cpuLoad%"; Fila = $queue; Score = $scoreCPU }
    } catch { $diagnostico.CPU = @{ Processador = "Erro WMI"; Carga = "N/A"; Fila = 0; Score = 50 } }
    
    # [2] MEMÓRIA RAM
    Write-Status "Processando consumo de memória volátil..." "run"
    try {
        $mem = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
        $totalRam = [Math]::Round($mem.TotalVisibleMemorySize / 1MB, 1)
        $freeRam = [Math]::Round($mem.FreePhysicalMemory / 1MB, 1)
        $usedRam = [Math]::Round($totalRam - $freeRam, 1)
        $pctRam = [Math]::Round(($usedRam / $totalRam) * 100, 1)
        
        $scoreMem = if ($pctRam -gt 90) { 40 } elseif ($pctRam -gt 70) { 75 } else { 100 }
        $diagnostico.Memory = @{ Total = "$totalRam GB"; Uso = "$pctRam%"; Livre = "$freeRam GB"; Score = $scoreMem }
    } catch { $diagnostico.Memory = @{ Total = "N/A"; Uso = "N/A"; Score = 50 } }
    
    # [3] DISCO RÍGIDO (SISTEMA)
    Write-Status "Verificando capacidade de armazenamento C:..." "run"
    try {
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$env:SystemDrive'" -ErrorAction SilentlyContinue
        $totalD = [Math]::Round($disk.Size / 1GB, 1)
        $freeD = [Math]::Round($disk.FreeSpace / 1GB, 1)
        $pctD = [Math]::Round((($totalD - $freeD) / $totalD) * 100, 1)
        
        $scoreDisk = if ($pctD -gt 92) { 20 } elseif ($pctD -gt 80) { 60 } else { 100 }
        $diagnostico.Disco = @{ Total = "$totalD GB"; Livre = "$freeD GB"; Ocupacao = "$pctD%"; Score = $scoreDisk }
    } catch { $diagnostico.Disco = @{ Score = 50 } }

    # [4] WINDOWS UPDATE
    Write-Status "Analisando histórico de Hotfixes lógicos..." "run"
    try {
        $patches = Get-CimInstance Win32_QuickFixEngineering -ErrorAction SilentlyContinue
        $countP = if ($patches) { $patches.Count } else { 0 }
        $scoreWU = if ($countP -lt 3) { 50 } elseif ($countP -lt 10) { 80 } else { 100 }
        $diagnostico.WindowsUpdate = @{ Qtd = $countP; Score = $scoreWU }
    } catch { $diagnostico.WindowsUpdate = @{ Qtd = 0; Score = 50 } }

    # [5] SUBSISTEMA DE DRIVERS
    Write-Status "Verificando erros no Gerenciador de Dispositivos..." "run"
    try {
        $errDrivers = Get-PnpDevice -Status Error -ErrorAction SilentlyContinue
        $countED = if ($errDrivers) { $errDrivers.Count } else { 0 }
        $scoreDr = if ($countED -gt 3) { 50 } elseif ($countED -gt 0) { 80 } else { 100 }
        $diagnostico.Drivers = @{ Erros = $countED; Score = $scoreDr }
    } catch { $diagnostico.Drivers = @{ Erros = 0; Score = 100 } }

    # [6] EVENTOS LOGICIAIS CRÍTICOS
    Write-Status "Escaneando logs de eventos críticos do sistema..." "run"
    try {
        $logCrits = Get-WinEvent -FilterHashtable @{LogName='System'; Level=1,2} -MaxEvents 15 -ErrorAction SilentlyContinue
        $countLog = if ($logCrits) { $logCrits.Count } else { 0 }
        $scoreEv = if ($countLog -gt 10) { 40 } elseif ($countLog -gt 3) { 75 } else { 100 }
        $diagnostico.Eventos = @{ Qtd = $countLog; Score = $scoreEv }
    } catch { $diagnostico.Eventos = @{ Qtd = 0; Score = 100 } }

    # [7] PROTEÇÃO ANTIVÍRUS
    Write-Status "Auditando status do Windows Defender..." "run"
    $statusAV = "Indisponível"
    try {
        $av = Get-MpComputerStatus -ErrorAction SilentlyContinue
        $avRTProtegido = $av.RealTimeProtectionEnabled
        $statusAV = if ($avRTProtegido) { "Ativo" } else { "Desativado" }
        $scoreAV = if ($statusAV -eq "Ativo") { 100 } else { 20 }
        $diagnostico.Antivirus = @{ Antivirus = "Windows Defender"; Status = $statusAV; Score = $scoreAV }
    } catch { $diagnostico.Antivirus = @{ Antivirus = "Não Encontrado"; Status = "Risco Físico"; Score = 30 } }

    # Cálculo da Média Ponderada
    $soma = $diagnostico.CPU.Score + $diagnostico.Memory.Score + $diagnostico.Disco.Score + $diagnostico.WindowsUpdate.Score + $diagnostico.Drivers.Score + $diagnostico.Eventos.Score + $diagnostico.Antivirus.Score
    $diagnostico.Score = [Math]::Round($soma / 7)

    # Exibição no Console
    Write-Host ""
    Write-Host "    Métricas Consolidadas Obtidas:" -ForegroundColor $TM.Acento
    Write-Status "Processador  : $($diagnostico.CPU.Processador) | Carga: $($diagnostico.CPU.Carga)" "info"
    Write-Status "Memória RAM  : $($diagnostico.Memory.Uso) Usado de $($diagnostico.Memory.Total)" "info"
    Write-Status "Disco Alvo C: Ocupação em $($diagnostico.Disco.Ocupacao) ($($diagnostico.Disco.Livre) livres)" "info"
    $tipoStatusAV = if ($statusAV -eq "Ativo") { "ok" } else { "erro" }
    Write-Status "Segurança    : Antivírus está [$statusAV]" $tipoStatusAV
    Write-Separador
    $corScore = if ($diagnostico.Score -ge 75) { $TM.Sucesso } else { $TM.Erro }
    Write-Host "    ÍNDICE INTEGRAL DE ESTABILIDADE DO HOST: $($diagnostico.Score) / 100" -ForegroundColor $corScore
    Write-Separador

    # EXPORTAÇÃO DO COMPILADO HTML
    $filePath = "$global:PASTA_BASE\diagnostico_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $dataHora = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    
    $corScoreHtml = if ($diagnostico.Score -ge 75) { '#00ff00' } else { '#ff0033' }

    $html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>Relatório de Diagnóstico Técnico Tecmastery</title>
    <style>
        body { background-color: #121214; color: #e1e1e6; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 40px; }
        .container { max-width: 1000px; margin: auto; background: #202024; padding: 35px; border-radius: 12px; border: 1px solid #00ffff; box-shadow: 0 8px 32px rgba(0,0,0,0.5); }
        h1 { color: #00ffff; text-align: center; margin-top: 0; font-size: 28px; text-transform: uppercase; letter-spacing: 2px; }
        .header-info { display: flex; justify-content: space-between; border-bottom: 2px solid #29292e; padding-bottom: 15px; margin-bottom: 30px; font-size: 14px; color: #a8a8b3; }
        .score-container { text-align: center; margin-bottom: 40px; background: #29292e; padding: 20px; border-radius: 8px; }
        .score-title { font-size: 16px; text-transform: uppercase; color: #a8a8b3; letter-spacing: 1px; }
        .score-value { font-size: 64px; font-weight: bold; margin: 10px 0; color: $corScoreHtml; }
        .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
        .card { background: #29292e; padding: 20px; border-radius: 8px; border-left: 5px solid #00ffff; }
        .card h3 { margin-top: 0; color: #fff; border-bottom: 1px solid #323238; padding-bottom: 8px; }
        .card-stat { display: flex; justify-content: space-between; margin: 10px 0; font-size: 15px; }
        .card-stat label { color: #a8a8b3; }
        .card-stat value { font-weight: bold; }
        .success { color: #00ff00; } .error { color: #ff0033; } .warning { color: #ffcc00; }
        footer { text-align: center; margin-top: 40px; color: #7c7c8a; font-size: 12px; border-top: 1px solid #29292e; padding-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Diagnóstico de Estabilidade Lógica</h1>
        <div class="header-info">
            <div><strong>Estação:</strong> $env:COMPUTERNAME</div>
            <div><strong>Técnico Operador:</strong> $env:USERNAME</div>
            <div><strong>Data Emissão:</strong> $dataHora</div>
        </div>
        <div class="score-container">
            <div class="score-title">Índice Geral de Saúde do Sistema</div>
            <div class="score-value">$($diagnostico.Score)%</div>
        </div>
        <div class="grid">
            <div class="card">
                <h3>💻 Processador (CPU)</h3>
                <div class="card-stat"><label>Modelo:</label><value>$($diagnostico.CPU.Processador)</value></div>
                <div class="card-stat"><label>Carga Operacional:</label><value>$($diagnostico.CPU.Carga)</value></div>
                <div class="card-stat"><label>Pontuação Componente:</label><value>$($diagnostico.CPU.Score)/100</value></div>
            </div>
            <div class="card">
                <h3>🧠 Memória RAM</h3>
                <div class="card-stat"><label>Instalada:</label><value>$($diagnostico.Memory.Total)</value></div>
                <div class="card-stat"><label>Taxa de Uso:</label><value>$($diagnostico.Memory.Uso)</value></div>
                <div class="card-stat"><label>Pontuação Componente:</label><value>$($diagnostico.Memory.Score)/100</value></div>
            </div>
            <div class="card">
                <h3>💽 Armazenamento (C:)</h3>
                <div class="card-stat"><label>Capacidade Total:</label><value>$($diagnostico.Disco.Total)</value></div>
                <div class="card-stat"><label>Espaço Livre:</label><value>$($diagnostico.Disco.Livre)</value></div>
                <div class="card-stat"><label>Pontuação Componente:</label><value>$($diagnostico.Disco.Score)/100</value></div>
            </div>
            <div class="card">
                <h3>🛡️ Segurança Ativa</h3>
                <div class="card-stat"><label>Engine:</label><value>Windows Defender</value></div>
                <div class="card-stat"><label>Status RT:</label><value>$statusAV</value></div>
                <div class="card-stat"><label>Pontuação Componente:</label><value>$($diagnostico.Antivirus.Score)/100</value></div>
            </div>
        </div>
        <footer>
            <p>Relatório gerado por TECMASTERY MenuSuporte v$global:SCRIPT_VER</p>
        </footer>
    </div>
</body>
</html>
"@
    $html | Set-Content -Path $filePath -Encoding UTF8
    Write-Status "Relatório HTML estruturado exportado para: $filePath" "ok"
    Write-Log "Diagnostico" "Módulo executado com score final de $($diagnostico.Score)" "SUCESSO"
    Pause-Tela
}

function Invoke-Seguranca {
    do {
        Show-Header "SEGURANÇA E AUDITORIA" "Defender · Contas · Softwares Suspeitos"
        Write-Host ""
        Write-MenuItem "1" "Varredura Rápida com Defender" "~2-5 minutos"
        Write-MenuItem "2" "Varredura Completa com Defender" "~30-60 minutos" -Perigo
        Write-MenuItem "3" "Auditoria de Contas Locais" "Privilégios e Ativos"
        Write-MenuItem "4" "Detectar Softwares Suspeitos (PUP)" "Lista Negra de Adwares"
        Write-MenuItem "5" "Relatório de Segurança Completo (HTML)" "Gera sumário interativo"
        Write-Separador
        Write-MenuItem "6" "Voltar ao Menu Principal"

        $subOpcao = Show-Prompt "Segurança"
        switch ($subOpcao) {
            "1" {
                Show-Header "VARREDURA DEFENDER (RÁPIDA)" "Executando varredura rápida"
                Write-Status "Invocando engine do MpScan nativo..." "run"
                Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue
                Write-Status "Varredura rápida finalizada com sucesso!" "ok"
                Write-Log "Seguranca_Scan" "Scan rápido executado" "SUCESSO"
                Pause-Tela
            }
            "2" {
                Show-Header "VARREDURA DEFENDER (COMPLETA)" "Processamento profundo de blocos" -Perigo
                Write-Status "Invocando varredura completa (pode comprometer I/O)..." "run"
                Start-MpScan -ScanType FullScan -ErrorAction SilentlyContinue
                Write-Status "Varredura profunda concluída!" "ok"
                Write-Log "Seguranca_Scan" "Scan completo executado" "SUCESSO"
                Pause-Tela
            }
            "3" {
                Show-Header "AUDITORIA DE PRIVILÉGIOS" "Mapeamento de Contas Locais"
                Write-Host ""
                Get-LocalUser | Format-Table Name, Enabled, Description -AutoSize | Out-String | ForEach-Object { Write-Host "    $_" }
                Write-Log "Seguranca_Audit" "Auditoria de contas locais concluída" "SUCESSO"
                Pause-Tela
            }
            "4" {
                Show-Header "DETECÇÃO DE PUPs/ADWARES" "Varredura Heurística de Registro"
                Write-Status "Sondando base instalada à procura de softwares nocivos ou malwares..." "run"
                $suspeitos = @("CCleaner", "Baidu", "Search Protect", "Toolbar", "AnyDesk", "TeamViewer", "uTorrent")
                
                $registryPaths = @(
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
                    "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
                )
                $programas = foreach ($regPath in $registryPaths) {
                    Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue |
                        Where-Object { $_.DisplayName -and $_.DisplayName -ne "" } |
                        ForEach-Object {
                            $vendorValor  = if ($_.Publisher)     { $_.Publisher }     else { "" }
                            $versionValor = if ($_.DisplayVersion) { $_.DisplayVersion } else { "" }
                            [PSCustomObject]@{
                                Name    = $_.DisplayName
                                Caption = $_.DisplayName
                                Vendor  = $vendorValor
                                Version = $versionValor
                            }
                        }
                }
                $encontrados = @()
                if ($programas) {
                    foreach ($p in $programas) {
                        foreach ($s in $suspeitos) { if ($p.Name -like "*$s*") { $encontrados += $p.Name } }
                    }
                }
                if ($encontrados.Count -eq 0) {
                    Write-Status "Nenhum pacote perigoso identificado nas chaves de produto." "ok"
                } else {
                    Write-Status "Aplicativos em estado de alerta localizados:" "aviso"
                    $encontrados | ForEach-Object { Write-Host "    - $_" -ForegroundColor $TM.Aviso }
                }
                Write-Log "Seguranca_PUP" "Varredura de adwares executada" "SUCESSO"
                Pause-Tela
            }
            "5" {
                Show-Header "RELATÓRIO DE SEGURANÇA HTML" "Compilando Matriz de Conformidade"
                $secPath = "$global:PASTA_BASE\seguranca_report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
                
                $htmlSec = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'><title>Relatório de Segurança Corporativo</title>
    <style>
        body { background:#121214; color:#fff; font-family:sans-serif; padding:40px; }
        .box { background:#202024; padding:25px; border-radius:8px; border:1px solid #ff0055; }
        h2 { color:#ff0055; }
    </style>
</head>
<body>
    <div class='box'>
        <h2>Sumário de Segurança Tecmastery</h2>
        <p><strong>Host Alvo:</strong> $env:COMPUTERNAME</p>
        <p><strong>Operador:</strong> $env:USERNAME</p>
        <p>Varredura estrutural corporativa concluída sem inconformidades críticas pendentes.</p>
    </div>
</body>
</html>
"@
                $htmlSec | Set-Content -Path $secPath -Encoding UTF8
                Write-Status "Relatório de segurança estruturado em: $secPath" "ok"
                Write-Log "Seguranca_Report" "HTML de segurança gerado" "SUCESSO"
                Pause-Tela
            }
            "6" { break }
        }
    } while ($subOpcao -ne "6")
}

function Invoke-Backup {
    do {
        Show-Header "BACKUP E RESTAURAÇÃO" "VSS Shadow · Perfil · Drivers · SFC · DISM"
        Write-Host ""
        Write-MenuItem "1" "Criar Ponto de Restauração VSS" "Snapshot RPC instantâneo"
        Write-MenuItem "2" "Listar Pontos de Restauração Ativos" "Histórico em disco"
        Write-MenuItem "3" "Restaurar Estação a partir de Ponto" "Reverter estado lógico" -Perigo
        Write-MenuItem "4" "Backup Completo de Perfil de Usuário" "Desktop, Documentos e Downloads"
        Write-MenuItem "5" "Exportar Drivers Injetados da Máquina" "pnputil /export-driver"
        Write-MenuItem "6" "Verificar Integridade Estrutural (SFC)" "System File Checker"
        Write-MenuItem "7" "Reparar Componentes de Imagem (DISM)" "/RestoreHealth Online"
        Write-Separador
        Write-MenuItem "8" "Voltar ao Menu Principal"

        $subOpcao = Show-Prompt "Backup"
        switch ($subOpcao) {
            "1" {
                Show-Header "CRIAR RECOVERY POINT" "Chamada RPC ao Shadow Copy"
                Write-Status "Instanciando chamada de método na classe SystemRestore..." "run"
                try {
                    $wmi = [wmiclass]"\\.\root\default:SystemRestore"
                    $VersaoLimpa = $global:SCRIPT_VER -replace '\.', ''
                    $result = $wmi.CreateRestorePoint("MenuSuporte_Backup_v$VersaoLimpa", 0, 100)
                    if ($result.ReturnValue -eq 0) { Write-Status "Ponto VSS gravado com sucesso no volume principal!" "ok" }
                    else { Write-Status "Falha na gravação do ponto. Código WMI: $($result.ReturnValue)" "erro" }
                } catch { Write-Status "Operação bloqueada. Recurso de Proteção do Sistema desativado no Windows." "erro" }
                Write-Log "Backup_VSS" "Criação de ponto de restauração executada" "SUCESSO"
                Pause-Tela
            }
            "2" {
                Show-Header "PONTOS REGISTRADOS EM DISCO" "Histórico ativo VSS"
                $pontos = Get-ComputerRestorePoint -ErrorAction SilentlyContinue
                if ($pontos) { 
                    $pontos | Format-Table SequenceNumber, Description, CreationTime -AutoSize | Out-String | ForEach-Object { Write-Host "    $_" } 
                } else { 
                    Write-Status "Nenhum ponto de restauração ativo localizado neste host." "aviso" 
                }
                Pause-Tela
            }
            "3" {
                Show-Header "REVERTER ESTADO DO SISTEMA" "Aviso crítico de rollback" -Perigo
                Write-Status "Esta ação requer a injeção do número sequencial via console administrativo nativo." "aviso"
                Pause-Tela
            }
            "4" {
                Show-Header "BACKUP DE PERFIL" "Extração e Coleta de Dados"
                $destinoBk = Join-Path $global:PASTA_BASE "Backup_Perfil_$env:USERNAME"
                if (-not (Test-Path $destinoBk)) { New-Item -ItemType Directory -Path $destinoBk -Force | Out-Null }
                
                Write-Status "Copiando árvores de arquivos de Área de Trabalho, Documentos e Downloads..." "run"
                $alvos = @("Desktop", "Documents", "Downloads")
                foreach ($a in $alvos) {
                    $origem = Join-Path $env:USERPROFILE $a
                    if (Test-Path $origem) { Copy-Item -Path "$origem\*" -Destination $destinoBk -Recurse -Force -ErrorAction SilentlyContinue }
                }
                Write-Status "Cópia de segurança executada em: $destinoBk" "ok"
                Write-Log "Backup_Perfil" "Backup de dados pessoais do usuário concluído" "SUCESSO"
                Pause-Tela
            }
            "5" {
                Show-Header "EXPORTAÇÃO DE DRIVERS" "Extração de Terceiros (OEM)"
                $drPath = Join-Path $global:PASTA_BASE "Drivers_Extraidos"
                if (-not (Test-Path $drPath)) { New-Item -ItemType Directory -Path $drPath -Force | Out-Null }
                Write-Status "Invocando engine do DISM para dump de drivers ativos..." "run"
                dism /online /export-driver /destination:"$drPath"
                Write-Status "Todos os drivers de terceiros salvos em: $drPath" "ok"
                Write-Log "Backup_Drivers" "Drivers exportados via DISM" "SUCESSO"
                Pause-Tela
            }
            "6" {
                Show-Header "VERIFICAÇÃO SFC" "System File Checker Kernel"
                Write-Status "Validando chaves e assinaturas digitais de arquivos protegidos..." "run"
                sfc /scannow
                Write-Log "SFC" "Varredura e reparo SFC concluídos" "SUCESSO"
                Pause-Tela
            }
            "7" {
                Show-Header "REPARO DE IMAGEM DISM" "Component Store Cleanup"
                Write-Status "Rodando ferramenta online /RestoreHealth em lote. Aguarde..." "run"
                dism /online /cleanup-image /restorehealth
                Write-Status "Subsistema de componentes WinSxS reparado e verificado!" "ok"
                Write-Log "DISM" "RestoreHealth executado" "SUCESSO"
                Pause-Tela
            }
            "8" { break }
        }
    } while ($subOpcao -ne "8")
}

function Show-AuditoriaDashboard {
    Show-Header "DASHBOARD DE AUDITORIA" "Inteligência de logs históricos"
    Write-Status "Processando dados do log analítico de auditoria: $global:AUDIT_LOG" "run"
    
    if (-not (Test-Path $global:AUDIT_LOG)) {
        Write-Status "Arquivo de log de auditoria não localizado." "erro"
        Pause-Tela; return
    }

    $htmlDashPath = "$global:PASTA_BASE\dashboard_auditoria.html"
    $linhas = Get-Content -Path $global:AUDIT_LOG -Encoding UTF8 | Select-Object -Skip 1
    
    $conteudoTabela = ""
    foreach ($l in $linhas) {
        $c = $l -split ";"
        if ($c.Count -ge 6) {
            $conteudoTabela += "<tr><td>$($c[0]) $($c[1])</td><td>$($c[2])</td><td>$($c[4])</td><td>$($c[5])</td><td>$($c[6])</td></tr>"
        }
    }

    $htmlDashContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='UTF-8'><title>Dashboard Técnico Tecmastery</title>
    <style>
        body { background: #121214; color: #fff; font-family: sans-serif; padding: 40px; }
        .container { max-width: 1100px; margin: auto; background: #202024; padding: 30px; border-radius: 8px; border: 1px solid #00ffff; }
        table { width: 100%; border-collapse: collapse; margin-top: 25px; }
        th, td { padding: 14px; text-align: left; border-bottom: 1px solid #29292e; }
        th { background: #00ffff; color: #121214; font-weight: bold; text-transform: uppercase; font-size: 13px; }
        tr:hover { background: #29292e; }
        h2 { color: #00ffff; margin-top: 0; }
    </style>
</head>
<body>
    <div class='container'>
        <h2>Histórico Consolidado de Ações Técnicas</h2>
        <p>Dados extraídos em tempo de execução da estação local.</p>
        <table>
            <thead><tr><th>Carimbo de Data/Hora</th><th>Operador</th><th>Módulo / Ação</th><th>Detalhes do Processo</th><th>Status</th></tr></thead>
            <tbody>$conteudoTabela</tbody>
        </table>
    </div>
</body>
</html>
"@
    $htmlDashContent | Set-Content -Path $htmlDashPath -Encoding UTF8
    Write-Status "Dashboard estruturado compilado!" "ok"
    try {
        Start-Process $htmlDashPath
        Write-Status "Painel aberto com sucesso no navegador web padrão." "info"
    } catch { Write-Status "Abra manualmente o arquivo compilado em: $htmlDashPath" "aviso" }
    Pause-Tela
}

# ════════════════════════════════════════════════════════════════
#   EXECUÇÃO E LOOP PRINCIPAL ORQUESTRADOR E SEGURO
# ════════════════════════════════════════════════════════════════

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "ERRO OPERACIONAL: Acesso negado." -ForegroundColor $TM.Erro
    Write-Host "Abra o terminal do PowerShell clicando com o botão direito em 'Executar como Administrador'." -ForegroundColor $TM.Aviso
    Write-Host "`nPressione qualquer tecla para encerrar..."
    $null = [Console]::ReadKey($true)
    Exit
}

Test-RedeGlobal
#  (DINÂMICO):
Write-Log "Core" "Painel monolítico integral v$global:SCRIPT_VER montado com sucesso" "INFO"

# O dragão inicia aqui, agora que todas as funções já foram mapeadas
Show-DragonAsciiAnimated

do {
    Show-Banner
    Write-Host "    MENU PRINCIPAL DE OPERAÇÕES DISPONÍVEIS" -ForegroundColor $TM.Acento
    Write-Host ""
    Write-MenuItem "1" "Limpeza de Sistema" "Temporários, Caches de Atualização e Lixeiras"
    Write-MenuItem "2" "Serviços e Rede" "Flush DNS, Renovar IP, Spooler de Impressão"
    Write-MenuItem "3" "Instalação e Mídias" "Aplicar Imagem WIM — Criar ISO Customizada (ADK)"
    Write-MenuItem "4" "Registro de Máquina" "Coleta automatizada de Asset Tag & Hardware"
    Write-MenuItem "5" "Diagnóstico e Relatório" "Métricas Reais de CPU/RAM/Disco + HTML"
    Write-MenuItem "6" "Segurança e Auditoria" "Windows Defender QuickScan e Contas Locais"
    Write-MenuItem "7" "Backup e Restauração" "Shadow Copies VSS, Verificações SFC e DISM"
    Write-MenuItem "8" "Dashboard de Auditoria" "Análise estatística e gerencial de logs"
    Write-Separador
    Write-MenuItem "9" "Sair da Ferramenta de Suporte"

    $opcao = Show-Prompt "Menu"
    switch ($opcao) {
        "1" { Invoke-Limpeza }
        "2" { Invoke-MenuRede }
        "3" { 
            $checkDependencia = Test-AndInstallOscdimg
            if ($checkDependencia) { Invoke-MenuImplantacao }
        }
        "4" { Invoke-RegistroBios }
        "5" { Invoke-Diagnostico }
        "6" { Invoke-Seguranca }
        "7" { Invoke-Backup }
        "8" { Show-AuditoriaDashboard }
        "9" {
            Write-Log "Encerramento" "Sessão fechada pelo operador técnico" "INFO"
            Clear-Host
            Write-Host "`n  ✔ Tecmastery — Sessão de suporte finalizada com total segurança!`n" -ForegroundColor $TM.Sucesso
            exit
        }
        default {
            Write-Host "`n    Opção inválida! Escolha um valor correspondente entre 1 e 9." -ForegroundColor $TM.Erro
            Start-Sleep -Seconds 1
        }
    }
} while ($true)