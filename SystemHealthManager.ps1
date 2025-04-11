# SystemHealthManager.ps1
# Autor: Daniel Vocurca Frade
# Data: 11/04/2025
# Descrição: Ferramenta interativa avançada CoyMenu v2.1

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
    try {
        $cpuUsage = (Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -ErrorAction Stop | Where-Object { $_.Name -eq "_Total" }).PercentProcessorTime
        $memory = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
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
    } catch {
        Write-Host "⚠️ Erro ao coletar métricas: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Função para exibir métricas com design aprimorado
function Show-Metrics {
    param ($metrics)
    if ($null -eq $metrics) {
        Write-Host "❌ Falha ao exibir métricas!" -ForegroundColor Red
        return
    }
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
    try {
        $processes = Get-Process -ErrorAction Stop | Where-Object { $_.CPU -gt 100 -or $_.WorkingSet64 / 1MB -gt 500 } | 
            Select-Object Name, @{N='CPU';E={[math]::Round($_.CPU, 2)}}, @{N='MemoriaMB';E={[math]::Round($_.WorkingSet64 / 1MB, 2)}}
        return $processes
    } catch {
        Write-Host "⚠️ Erro ao detectar processos: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Função para otimizar o sistema
function Optimize-System {
    Show-Loading "🔧 Preparando otimização do sistema"
    $confirm = Read-Host "⚠️ Isso vai limpar arquivos temporários, reiniciar o Explorer, limpar disco, desfragmentar e otimizar serviços. Continuar? (S/N)"
    if ($confirm -eq 'S' -or $confirm -eq 's') {
        Show-Loading "🔧 Otimizando o sistema"

        # 1. Limpeza de arquivos temporários
        try {
            Write-Host "🗑️ Limpando arquivos temporários..." -ForegroundColor Yellow
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction Stop
            Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction Stop
            Write-Host "✅ Arquivos temporários limpos!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao limpar arquivos temporários: $($_.Exception.Message)" -ForegroundColor Red
        }

        # 2. Reiniciar o Windows Explorer
        try {
            Write-Host "🔄 Reiniciando Explorer..." -ForegroundColor Yellow
            Stop-Process -Name "Explorer" -Force -ErrorAction Stop
            Start-Sleep -Seconds 1
            Start-Process "Explorer" -ErrorAction Stop
            Write-Host "✅ Explorer reiniciado!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao reiniciar Explorer: $($_.Exception.Message)" -ForegroundColor Red
        }

        # 3. Limpeza de disco avançada (similar ao cleanmgr)
        try {
            Write-Host "🧹 Executando limpeza de disco avançada..." -ForegroundColor Yellow
            $cleanmgrParams = "/sagerun:1"
            # Configurar preset para limpeza automática
            $cleanmgrReg = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
            $categories = @("Temporary Files", "Recycle Bin", "System error memory dump files", "Windows Update Cleanup")
            foreach ($cat in $categories) {
                Set-ItemProperty -Path "$cleanmgrReg\$cat" -Name "StateFlags0001" -Value 2 -ErrorAction SilentlyContinue
            }
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList $cleanmgrParams -Wait -ErrorAction Stop
            Write-Host "✅ Limpeza de disco concluída!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro na limpeza de disco: $($_.Exception.Message)" -ForegroundColor Red
        }

        # 4. Desfragmentação de disco (apenas para HDD)
        try {
            Write-Host "💿 Verificando tipo de disco..." -ForegroundColor Yellow
            $disk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq (Get-Partition -DriveLetter C).DiskNumber }
            if ($disk.MediaType -eq "HDD") {
                Write-Host "💿 Desfragmentando disco C:..." -ForegroundColor Yellow
                Optimize-Volume -DriveLetter C -Defrag -Verbose -ErrorAction Stop
                Write-Host "✅ Desfragmentação concluída!" -ForegroundColor Green
            } else {
                Write-Host "ℹ️ Disco SSD detectado. Desfragmentação desnecessária." -ForegroundColor Cyan
            }
        } catch {
            Write-Host "⚠️ Erro na desfragmentação: $($_.Exception.Message)" -ForegroundColor Red
        }

        # 5. Otimização de serviços não essenciais
        try {
            Write-Host "⚙️ Otimizando serviços não essenciais..." -ForegroundColor Yellow
            $servicesToDisable = @(
                "XboxGipSvc",           # Xbox Game Input Service
                "WSearch",              # Windows Search (se não usado)
                "SysMain"               # Superfetch (desnecessário em SSDs)
            )
            foreach ($service in $servicesToDisable) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc -and $svc.StartType -ne "Disabled") {
                    Set-Service -Name $service -StartupType Manual -ErrorAction Stop
                    Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                    Write-Host "✅ Serviço $service configurado para manual." -ForegroundColor Green
                }
            }
            Write-Host "✅ Otimização de serviços concluída!" -ForegroundColor Green
        } catch {
            Write-Host "⚠️ Erro ao otimizar serviços: $($_.Exception.Message)" -ForegroundColor Red
        }

        Write-Host "🎉 Otimização completa!" -ForegroundColor Green
    } else {
        Write-Host "❌ Otimização cancelada!" -ForegroundColor Yellow
    }
}

# Função de monitoramento contínuo
function Start-ContinuousMonitoring {
    Show-Header
    Write-Host "🚨 Monitoramento contínuo iniciado (Ctrl+C para sair)" -ForegroundColor Yellow
    Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Cyan
    try {
        while ($true) {
            $metrics = Get-SystemMetrics
            if ($metrics) {
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
            }
            Start-Sleep -Seconds 5
            Write-Host "🔄 Atualizando..." -ForegroundColor Cyan
        }
    } catch {
        Write-Host "⚠️ Monitoramento interrompido: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Função de backup
function Backup-Config {
    Show-Loading "💾 Criando backup de configurações"
    try {
        $backupPath = "$env:USERPROFILE\Desktop\SystemHealthBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -Path $backupPath -ItemType Directory -Force -ErrorAction Stop | Out-Null
        Get-ChildItem Env: | Export-Csv "$backupPath\EnvVars.csv" -NoTypeInformation -ErrorAction Stop
        reg export HKCU\Software\Microsoft\Windows\CurrentVersion\Run "$backupPath\Run.reg" /y -ErrorAction Stop 2>$null
        Write-Host "✅ Backup salvo em: $backupPath" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ Erro ao criar backup: $($_.Exception.Message)" -ForegroundColor Red
    }
    Pause
}

# Função de exportação de relatório
function Export-Report {
    Show-Loading "📑 Gerando relatório"
    try {
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
        $report | Export-Csv $reportPath -NoTypeInformation -ErrorAction Stop
        if ($processes) { 
            $processes | Export-Csv "$reportPath.append.csv" -NoTypeInformation -ErrorAction Stop
            Write-Host "✅ Relatório com processos salvo em: $reportPath e $reportPath.append.csv" -ForegroundColor Green
        } else {
            Write-Host "✅ Relatório salvo em: $reportPath" -ForegroundColor Green
        }
    } catch {
        Write-Host "⚠️ Erro ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
    }
    Pause
}

# Função de teste de rede
function Test-Network {
    Show-Loading "🌐 Testando conexão de rede"
    try {
        Write-Host "────────────────────────" -ForegroundColor Cyan
        $pingGoogle = Test-Connection -ComputerName "google.com" -Count 4 -ErrorAction SilentlyContinue
        if ($pingGoogle) {
            $avgLatencyGoogle = [math]::Round(($pingGoogle | Measure-Object -Property ResponseTime -Average).Average, 2)
            Write-Host "🌍 Google: $avgLatencyGoogle ms" -ForegroundColor Green
        } else {
            Write-Host "❌ Falha ao pingar Google" -ForegroundColor Red
        }
        $pingCloudflare = Test-Connection -ComputerName "1.1.1.1" -Count 4 -ErrorAction SilentlyContinue
        if ($pingCloudflare) {
            $avgLatencyCloudflare = [math]::Round(($pingCloudflare | Measure-Object -Property ResponseTime -Average).Average, 2)
            Write-Host "☁️ Cloudflare: $avgLatencyCloudflare ms" -ForegroundColor Green
        } else {
            Write-Host "❌ Falha ao pingar Cloudflare" -ForegroundColor Red
        }
        Write-Host "────────────────────────" -ForegroundColor Cyan
    } catch {
        Write-Host "⚠️ Erro ao testar rede: $($_.Exception.Message)" -ForegroundColor Red
    }
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
                    try {
                        Stop-Process -Name $kill -Force -ErrorAction Stop
                        Write-Host "✅ Processo encerrado!" -ForegroundColor Green
                    } catch {
                        Write-Host "⚠️ Erro ao encerrar processo: $($_.Exception.Message)" -ForegroundColor Red
                    }
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
            try {
                $updates = (New-Object -ComObject Microsoft.Update.Session).CreateUpdateSearcher().Search("IsInstalled=0").Updates
                if ($updates.Count -gt 0) {
                    Write-Host "⚠️ $($updates.Count) atualizações pendentes!" -ForegroundColor Red
                } else {
                    Write-Host "✅ Sistema atualizado!" -ForegroundColor Green
                }
            } catch {
                Write-Host "⚠️ Erro ao verificar atualizações: $($_.Exception.Message)" -ForegroundColor Red
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
