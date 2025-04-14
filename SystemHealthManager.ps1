# SystemHealthManager.ps1
# Autor: Daniel Vocurca Frade
# Data: 14/04/2025
# Descrição: Ferramenta interativa avançada CoyMenu

# Verifica se está rodando como administrador
function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Tenta abrir no Windows Terminal como administrador, se disponível, ou no PowerShell padrão
if (-not (Test-Admin)) {
    Write-Host "⚠️ Este script requer privilégios administrativos!" -ForegroundColor Yellow
    Write-Host "🔧 Tentando reiniciar como administrador..." -ForegroundColor Cyan
    Start-Sleep -Seconds 2
    $scriptPath = $MyInvocation.MyCommand.Path
    
    # Tenta usar o Windows Terminal (wt.exe), se instalado
    if (Get-Command "wt.exe" -ErrorAction SilentlyContinue) {
        Start-Process "wt.exe" -Verb RunAs -ArgumentList "powershell -NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    } else {
        Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    }
    exit
}

# Define configurações de console para suportar cores
$Host.UI.RawUI.BackgroundColor = "Black"
$Host.UI.RawUI.ForegroundColor = "White"
Clear-Host

# Função para exibir cabeçalho estilizado
function Show-Header {
    Clear-Host
    Write-Host "╔════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                    ║" -ForegroundColor Cyan
    Write-Host "║    ____ ___  _   _   /\/\   ___ _ __  _   _       ║" -ForegroundColor Yellow
    Write-Host "║   / ___/ _ \| | | | /    \ / _ \ '_ \| | | |      ║" -ForegroundColor Yellow
    Write-Host "║  | (_| (_) | |_| |/ /\/\ \  __/ | | | |_| |       ║" -ForegroundColor Yellow
    Write-Host "║   \___\___/ \__  /\/    \/\___|_| |_|__,_| v2.1   ║" -ForegroundColor Yellow
    Write-Host "║             |___/                                  ║" -ForegroundColor Yellow
    Write-Host "║                                                    ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host "  🚀 Monitoramento e Otimização com Estilo 🚀" -ForegroundColor Green
    Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""
}

# Função para animação de carregamento
function Show-Loading {
    param ($message)
    Write-Host "$message " -NoNewline -ForegroundColor Yellow
    for ($i = 0; $i -lt 3; $i++) {
        Write-Host "." -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 300
    }
    Write-Host ""
}

# Função para obter métricas do sistema
function Get-SystemMetrics {
    $cpuUsage = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor | Where-Object { $_.Name -eq "_Total" }).PercentProcessorTime
    $memory = Get-CimInstance Win32_OperatingSystem
    $memoryUsed = [math]::Round(($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / 1024 / 1024, 2)
    $memoryTotal = [math]::Round($memory.TotalVisibleMemorySize / 1024 / 1024, 2)
    $disk = Get-PSDrive -Name "C" -ErrorAction SilentlyContinue
    $diskFree = [math]::Round($disk.Free / 1GB, 2)
    $diskTotal = [math]::Round(($disk.Used + $disk.Free) / 1GB, 2)
    $netStats = Get-NetAdapterStatistics -ErrorAction SilentlyContinue
    $netSent = [math]::Round(($netStats | Measure-Object -Property SentBytes -Sum).Sum / 1MB, 2)
    $netReceived = [math]::Round(($netStats | Measure-Object -Property ReceivedBytes -Sum).Sum / 1MB, 2)

    return [PSCustomObject]@{
        CPUUsage    = $cpuUsage
        MemoryUsed  = $memoryUsed
        MemoryTotal = $memoryTotal
        DiskFree    = $diskFree
        DiskTotal   = $diskTotal
        NetSent     = $netSent
        NetReceived = $netReceived
    }
}

# Função para exibir métricas com design aprimorado
function Show-Metrics {
    param ($metrics)
    Write-Host "🌟 Métricas do Sistema 🌟" -ForegroundColor Yellow
    Write-Host "────────────────────────" -ForegroundColor Cyan
    Write-Host "🖥️  CPU: " -NoNewline -ForegroundColor Magenta
    Write-Host "$($metrics.CPUUsage)% " -NoNewline -ForegroundColor White
    Write-Host ("█" * [math]::Round($metrics.CPUUsage / 5)) -ForegroundColor Red
    Write-Host "💾  Memória: " -NoNewline -ForegroundColor Magenta
    Write-Host "$($metrics.MemoryUsed)/$($metrics.MemoryTotal) GB " -NoNewline -ForegroundColor White
    Write-Host ("█" * [math]::Round(($metrics.MemoryUsed / $metrics.MemoryTotal) * 20)) -ForegroundColor Blue
    Write-Host "📀  Disco: " -NoNewline -ForegroundColor Magenta
    Write-Host "$($metrics.DiskFree)/$($metrics.DiskTotal) GB " -NoNewline -ForegroundColor White
    Write-Host ("█" * [math]::Round(($metrics.DiskFree / $metrics.DiskTotal) * 20)) -ForegroundColor Green
    Write-Host "🌐  Rede (Enviado/Recebido): " -NoNewline -ForegroundColor Magenta
    Write-Host "$($metrics.NetSent)/$($metrics.NetReceived) MB" -ForegroundColor White
    Write-Host "────────────────────────" -ForegroundColor Cyan
    Write-Host ""
}

# Função para detectar processos problemáticos
function Get-ProblematicProcesses {
    $processes = Get-Process | Where-Object { $_.CPU -gt 100 -or $_.WorkingSet64 / 1MB -gt 500 } | 
        Select-Object Name, @{N='CPU';E={[math]::Round($_.CPU, 2)}}, @{N='MemoriaMB';E={[math]::Round($_.WorkingSet64 / 1MB, 2)}}
    return $processes
}

# Função para otimizar o sistema
function Optimize-System {
    Show-Loading "🔧 Preparando otimização avançada do sistema"
    $confirm = Read-Host "⚠️ Isso vai limpar arquivos temporários, otimizar memória, ajustar serviços, reiniciar o Explorer e desfragmentar o disco (se necessário). Continuar? (S/N)"
    if ($confirm -eq 'S' -or $confirm -eq 's') {
        Show-Loading "🔧 Iniciando otimização avançada"

        try {
            Write-Host "🗑️ Limpando arquivos temporários..." -ForegroundColor Yellow
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction Stop
            Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Arquivos temporários limpos!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao limpar arquivos temporários: $($_.Exception.Message)" -ForegroundColor Red
        }

        try {
            Write-Host "📜 Limpando logs de eventos antigos..." -ForegroundColor Yellow
            Get-EventLog -LogName * | ForEach-Object { Clear-EventLog -LogName $_.Log -ErrorAction SilentlyContinue }
            Write-Host "✅ Logs de eventos limpos!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao limpar logs: $($_.Exception.Message)" -ForegroundColor Red
        }

        try {
            Write-Host "💾 Liberando memória ociosa..." -ForegroundColor Yellow
            $os = Get-CimInstance Win32_OperatingSystem
            $freeMemoryBefore = $os.FreePhysicalMemory
            $dll = Add-Type -Name "WinAPI" -MemberDefinition '[DllImport("psapi.dll")] public static extern bool EmptyWorkingSet(IntPtr hProcess);' -PassThru
            Get-Process | ForEach-Object { if ($_.Handle) { $dll::EmptyWorkingSet($_.Handle) | Out-Null } }
            $os = Get-CimInstance Win32_OperatingSystem
            $freeMemoryAfter = $os.FreePhysicalMemory
            Write-Host "✅ Memória liberada: $([math]::Round(($freeMemoryAfter - $freeMemoryBefore) / 1024, 2)) MB" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao liberar memória: $($_.Exception.Message)" -ForegroundColor Red
        }

        try {
            Write-Host "⚙️ Ajustando serviços desnecessários..." -ForegroundColor Yellow
            $spooler = Get-Service -Name "Spooler" -ErrorAction SilentlyContinue
            if ($spooler -and $spooler.Status -eq "Running") {
                $stopSpooler = Read-Host "🖨️ Deseja parar o serviço de spooler de impressão? (S/N)"
                if ($stopSpooler -eq 'S' -or $stopSpooler -eq 's') {
                    Stop-Service -Name "Spooler" -Force -ErrorAction Stop
                    Set-Service -Name "Spooler" -StartupType Manual
                    Write-Host "✅ Serviço de spooler parado e configurado como manual!" -ForegroundColor Green
                }
            }
        } catch {
            Write-Host "⚠️ Erro ao ajustar serviços: $($_.Exception.Message)" -ForegroundColor Red
        }

        try {
            Write-Host "🖥️ Reiniciando Explorer..." -ForegroundColor Yellow
            Stop-Process -Name "Explorer" -Force -ErrorAction Stop
            Start-Sleep -Seconds 1
            Start-Process "Explorer" -ErrorAction Stop
            Write-Host "✅ Explorer reiniciado!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao reiniciar Explorer: $($_.Exception.Message)" -ForegroundColor Red
        }

        try {
            Write-Host "📀 Verificando necessidade de desfragmentação..." -ForegroundColor Yellow

            # Check and start required services
            $services = @("vds", "StorSvc")
            foreach ($service in $services) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc) {
                    if ($svc.Status -ne "Running") {
                        Write-Host "🔧 Iniciando serviço $service..." -ForegroundColor Yellow
                        Start-Service -Name $service -ErrorAction Stop
                    }
                } else {
                    Write-Host "⚠️ Serviço $service não encontrado!" -ForegroundColor Red
                }
            }

            # Validate the volume
            $volume = Get-Volume -DriveLetter "C" -ErrorAction SilentlyContinue
            if (-not $volume) {
                Write-Host "❌ Volume C: não encontrado!" -ForegroundColor Red
                return
            }

            # Check if the drive is an SSD
            $disk = Get-Disk | Where-Object { $_.Number -eq (Get-Partition -DriveLetter "C").DiskNumber } -ErrorAction SilentlyContinue
            if ($disk -and $disk.Model -match "SSD") {
                Write-Host "ℹ️ Disco SSD detectado, desfragmentação ignorada." -ForegroundColor Cyan
                return
            }

            # Proceed with defragmentation analysis
            if ($volume.DriveType -eq "Fixed") {
                try {
                    $defrag = (Optimize-Volume -DriveLetter "C" -Analyze -Verbose) | Out-String
                    if ($defrag -match "Fragmentation\s*:\s*(\d+)%") {
                        $fragmentation = [int]$Matches[1]
                        if ($fragmentation -gt 10) {
                            Write-Host "🔧 Desfragmentando disco (fragmentação: $fragmentation%)..." -ForegroundColor Yellow
                            Optimize-Volume -DriveLetter "C" -Defrag -Verbose
                            Write-Host "✅ Disco desfragmentado!" -ForegroundColor Green
                        } else {
                            Write-Host "✅ Desfragmentação não necessária (fragmentação: $fragmentation%)" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "⚠️ Não foi possível determinar o nível de fragmentação." -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "⚠️ Erro ao analisar/desfragmentar disco: $($_.Exception.Message)" -ForegroundColor Red
                }
            } else {
                Write-Host "ℹ️ Volume não suportado para desfragmentação." -ForegroundColor Cyan
            }
        } catch {
            Write-Host "⚠️ Erro geral ao verificar desfragmentação: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host "✅ Otimização concluída com sucesso!" -ForegroundColor Green
    } else {
        Write-Host "❌ Otimização cancelada!" -ForegroundColor Yellow
    }
}

# Função de monitoramento contínuo
function Start-ContinuousMonitoring {
    Show-Header
    Write-Host "🚨 Monitoramento contínuo iniciado (Ctrl+C para sair)" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Cyan
    while ($true) {
        $metrics = Get-SystemMetrics
        Show-Metrics -metrics $metrics
        if ($metrics.CPUUsage -gt 80) {
            Write-Host "⚠️ ALERTA: CPU > 80%!" -ForegroundColor Red
            [Console]::Beep(1000, 500)
        }
        if ($metrics.MemoryUsed / $metrics.MemoryTotal -gt 0.9) {
            Write-Host "⚠️ ALERTA: Memória quase esgotada!" -ForegroundColor Red
            [Console]::Beep(1000, 500)
        }
        if ($metrics.DiskFree / $metrics.DiskTotal -lt 0.1) {
            Write-Host "⚠️ ALERTA: Disco quase cheio!" -ForegroundColor Red
            [Console]::Beep(1000, 500)
        }
        Start-Sleep -Seconds 5
        Write-Host "🔄 Atualizando..." -ForegroundColor Cyan
    }
}

# Função de backup
function Backup-Config {
    Show-Loading "💾 Criando backup de configurações"
    $backupPath = "$env:USERPROFILE\Desktop\SystemHealthBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    Get-ChildItem Env: | Export-Csv "$backupPath\EnvVars.csv" -NoTypeInformation
    reg export HKCU\Software\Microsoft\Windows\CurrentVersion\Run "$backupPath\Run.reg" /y 2>$null
    Write-Host "✅ Backup salvo em: $backupPath" -ForegroundColor Green
    Pause
}

# Função de exportação de relatório
function Export-Report {
    Show-Loading "📑 Gerando relatório"
    $metrics = Get-SystemMetrics
    $processes = Get-ProblematicProcesses
    $reportPath = "$env:USERPROFILE\Desktop\SystemHealthReport_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $report = [PSCustomObject]@{
        Timestamp    = Get-Date
        CPUUsage     = $metrics.CPUUsage
        MemoryUsedGB = $metrics.MemoryUsed
        MemoryTotalGB= $metrics.MemoryTotal
        DiskFreeGB   = $metrics.DiskFree
        DiskTotalGB  = $metrics.DiskTotal
        NetSentMB    = $metrics.NetSent
        NetReceivedMB= $metrics.NetReceived
    }
    $report | Export-Csv $reportPath -NoTypeInformation
    if ($processes) { 
        $processes | Export-Csv "$reportPath.append.csv" -NoTypeInformation 
        Write-Host "✅ Relatório com processos salvo em: $reportPath e $reportPath.append.csv" -ForegroundColor Green
    } else {
        Write-Host "✅ Relatório salvo em: $reportPath" -ForegroundColor Green
    }
    Pause
}

# Função de teste de rede
function Test-Network {
    Show-Loading "🌐 Testando conexão de rede"
    $pingGoogle = Test-Connection -ComputerName "google.com" -Count 4 -ErrorAction SilentlyContinue
    $pingCloudflare = Test-Connection -ComputerName "1.1.1.1" -Count 4 -ErrorAction SilentlyContinue
    Write-Host "────────────────────────" -ForegroundColor Cyan
    if ($pingGoogle) {
        $avgLatencyGoogle = [math]::Round(($pingGoogle | Measure-Object -Property ResponseTime -Average).Average, 2)
        Write-Host "🌍 Google: $avgLatencyGoogle ms" -ForegroundColor Green
    } else {
        Write-Host "❌ Falha ao pingar Google" -ForegroundColor Red
    }
    if ($pingCloudflare) {
        $avgLatencyCloudflare = [math]::Round(($pingCloudflare | Measure-Object -Property ResponseTime -Average).Average, 2)
        Write-Host "☁️ Cloudflare: $avgLatencyCloudflare ms" -ForegroundColor Green
    } else {
        Write-Host "❌ Falha ao pingar Cloudflare" -ForegroundColor Red
    }
    Write-Host "────────────────────────" -ForegroundColor Cyan
    Pause
}

# Função de saída estilizada
function Exit-Program {
    Show-Header
    Write-Host "👋 Saindo com estilo..." -ForegroundColor Yellow
    $animation = @("🚀", "✨", "🌟", "💫")
    for ($i = 0; $i -lt 5; $i++) {
        Write-Host "`r$($animation[$i % 4]) Encerrando" -NoNewline -ForegroundColor Green
        Start-Sleep -Milliseconds 200
    }
    Write-Host "`r✅ Programa encerrado!    " -ForegroundColor Green
    return $true
}

# Menu interativo com design incrível
function Show-Menu {
    Show-Header
    Write-Host "🎯 Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host "  [1] 🌟 Exibir métricas do sistema" -ForegroundColor Magenta
    Write-Host "  [2] ⚠️ Ver processos problemáticos" -ForegroundColor Magenta
    Write-Host "  [3] 🔧 Otimizar sistema" -ForegroundColor Magenta
    Write-Host "  [4] 🔍 Verificar atualizações pendentes" -ForegroundColor Magenta
    Write-Host "  [5] 🚨 Iniciar monitoramento contínuo" -ForegroundColor Magenta
    Write-Host "  [6] 💾 Fazer backup de configurações" -ForegroundColor Magenta
    Write-Host "  [7] 📑 Exportar relatório" -ForegroundColor Magenta
    Write-Host "  [8] 🌐 Testar conexão de rede" -ForegroundColor Magenta
    Write-Host "  [9] 👋 Sair" -ForegroundColor Magenta
    Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Cyan
    Write-Host ""
}

# Loop principal
$exitFlag = $false
do {
    Show-Menu
    $choice = Read-Host "Digite sua escolha (1-9)"
    
    switch ($choice) {
        "1" {
            Show-Header
            $metrics = Get-SystemMetrics
            Show-Metrics -metrics $metrics
            Pause
        }
        "2" {
            Show-Header
            $processes = Get-ProblematicProcesses
            if ($processes) {
                Write-Host "⚠️ Processos com alto consumo:" -ForegroundColor Red
                Write-Host "────────────────────────" -ForegroundColor Cyan
                $processes | Format-Table -AutoSize
                $kill = Read-Host "🔪 Deseja encerrar algum processo? (Nome ou 'N')"
                if ($kill -ne 'N' -and $kill -ne 'n') {
                    Stop-Process -Name $kill -Force -ErrorAction SilentlyContinue
                    Write-Host "✅ Processo encerrado!" -ForegroundColor Green
                }
            } else {
                Write-Host "✅ Nenhum processo problemático detectado!" -ForegroundColor Green
            }
            Pause
        }
        "3" {
            Show-Header
            Optimize-System
            Pause
        }
        "4" {
            Show-Header
            Show-Loading "🔍 Verificando atualizações"
            $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
            if ($updates.Count -gt 0) {
                Write-Host "⚠️ $($updates.Count) atualizações pendentes!" -ForegroundColor Red
            } else {
                Write-Host "✅ Sistema atualizado!" -ForegroundColor Green
            }
            Pause
        }
        "5" {
            Start-ContinuousMonitoring
        }
        "6" {
            Backup-Config
        }
        "7" {
            Export-Report
        }
        "8" {
            Test-Network
        }
        "9" {
            $exitFlag = Exit-Program
        }
        default {
            Write-Host "❌ Opção inválida, tente novamente!" -ForegroundColor Red
            Pause
        }
    }
} while (-not $exitFlag)
