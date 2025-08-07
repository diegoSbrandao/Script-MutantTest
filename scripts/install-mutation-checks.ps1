# install-mutation-checks.ps1
# Script para configurar o sistema de verificação de mutation testing

param(
    [switch]$Force,
    [int]$MinCoverage = 90
)

Write-Host "🚀 Configurando sistema de verificação de mutation testing..." -ForegroundColor Cyan

# Verifica se está em um repositório Git
if (-not (Test-Path ".git")) {
    Write-Host "❌ Este diretório não é um repositório Git!" -ForegroundColor Red
    exit 1
}

# Cria diretório scripts se não existir
$scriptsDir = "scripts"
if (-not (Test-Path $scriptsDir)) {
    New-Item -ItemType Directory -Path $scriptsDir -Force
    Write-Host "📁 Criado diretório: $scriptsDir" -ForegroundColor Green
}

# Copia o script de verificação
$checkScriptPath = Join-Path $scriptsDir "check-mutations-staged.ps1"
if ((Test-Path $checkScriptPath) -and -not $Force) {
    Write-Host "⚠️ Script já existe em $checkScriptPath" -ForegroundColor Yellow
    $response = Read-Host "Sobrescrever? (s/N)"
    if ($response -ne 's' -and $response -ne 'S') {
        Write-Host "❌ Instalação cancelada pelo usuário." -ForegroundColor Red
        exit 1
    }
}

# Aqui você colocaria o conteúdo do script check-mutations-staged.ps1
Write-Host "📋 Copiando script de verificação..." -ForegroundColor Green

# Configura o pre-commit hook
$hookPath = ".git/hooks/pre-commit"
$hookContent = @"
#!/bin/sh
# Pre-commit hook para verificação de mutation testing
# Gerado automaticamente em $(Get-Date)

echo "🔍 Executando verificação de mutation testing..."

# Executa o script PowerShell de verificação
powershell -ExecutionPolicy Bypass -File "./scripts/check-mutations-staged.ps1" -MinimumCoverage $MinCoverage

# Captura o código de saída
EXIT_CODE=`$?

if [ `$EXIT_CODE -ne 0 ]; then
    echo ""
    echo "❌ COMMIT BLOQUEADO!"
    echo "Para prosseguir, corrija os problemas de mutation testing reportados acima."
    echo ""
    echo "💡 Para pular esta verificação temporariamente (NÃO RECOMENDADO):"
    echo "   git commit --no-verify -m \"sua mensagem\""
    echo ""
    exit 1
fi

echo "✅ Verificação de mutation testing passou! Prosseguindo com o commit..."
exit 0
"@

if ((Test-Path $hookPath) -and -not $Force) {
    Write-Host "⚠️ Pre-commit hook já existe!" -ForegroundColor Yellow
    $response = Read-Host "Sobrescrever? (s/N)"
    if ($response -ne 's' -and $response -ne 'S') {
        Write-Host "❌ Instalação cancelada pelo usuário." -ForegroundColor Red
        exit 1
    }
}

# Escreve o hook
$hookContent | Out-File -FilePath $hookPath -Encoding UTF8 -NoNewline
Write-Host "🪝 Pre-commit hook instalado em: $hookPath" -ForegroundColor Green

# Torna o hook executável (no Linux/Mac isso seria chmod +x)
if ($IsLinux -or $IsMacOS) {
    chmod +x $hookPath
}

# Verifica configuração do PIT no pom.xml
Write-Host "🔍 Verificando configuração do PIT no pom.xml..." -ForegroundColor Cyan

if (Test-Path "pom.xml") {
    $pomContent = Get-Content "pom.xml" -Raw
    
    if ($pomContent -notmatch "pitest-maven") {
        Write-Host "⚠️ Plugin PIT não encontrado no pom.xml!" -ForegroundColor Yellow
        Write-Host "📝 Adicione a seguinte configuração ao seu pom.xml:" -ForegroundColor Yellow
        
        $pitConfig = @"

<plugin>
    <groupId>org.pitest</groupId>
    <artifactId>pitest-maven</artifactId>
    <version>1.16.1</version>
    <configuration>
        <outputFormats>
            <outputFormat>XML</outputFormat>
            <outputFormat>HTML</outputFormat>
        </outputFormats>
        <exportLineCoverage>true</exportLineCoverage>
        <timestampedReports>false</timestampedReports>
    </configuration>
</plugin>
"@
        Write-Host $pitConfig -ForegroundColor Gray
    } else {
        Write-Host "✅ Plugin PIT encontrado no pom.xml" -ForegroundColor Green
    }
} else {
    Write-Host "⚠️ Arquivo pom.xml não encontrado!" -ForegroundColor Yellow
}

# Cria arquivo de configuração
$configContent = @"
# Configuração do Sistema de Mutation Testing
# Gerado em: $(Get-Date)

MINIMUM_MUTATION_COVERAGE=$MinCoverage
SCRIPT_VERSION=1.0
INSTALLATION_DATE=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

# Para alterar a cobertura mínima, edite o valor acima e reinstale:
# .\install-mutation-checks.ps1 -Force -MinCoverage 85
"@

$configContent | Out-File -FilePath "scripts/mutation-config.txt" -Encoding UTF8

Write-Host "`n🎉 INSTALAÇÃO CONCLUÍDA!" -ForegroundColor Green -BackgroundColor DarkGreen
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host "✅ Pre-commit hook configurado" -ForegroundColor Green
Write-Host "✅ Script de verificação instalado" -ForegroundColor Green
Write-Host "✅ Cobertura mínima: $MinCoverage%" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green

Write-Host "`n📋 PRÓXIMOS PASSOS:" -ForegroundColor Cyan
Write-Host "1. Verifique se o plugin PIT está no pom.xml" -ForegroundColor Gray
Write-Host "2. Teste com: .\scripts\check-mutations-staged.ps1 -Verbose" -ForegroundColor Gray
Write-Host "3. Faça um commit de teste para verificar o hook" -ForegroundColor Gray
Write-Host "4. Para pular verificação: git commit --no-verify" -ForegroundColor Gray

Write-Host "`n🔧 COMANDOS ÚTEIS:" -ForegroundColor Cyan
Write-Host "• Testar manualmente: .\scripts\check-mutations-staged.ps1" -ForegroundColor Gray
Write-Host "• Modo verbose: .\scripts\check-mutations-staged.ps1 -Verbose" -ForegroundColor Gray
Write-Host "• Alterar threshold: .\scripts\check-mutations-staged.ps1 -MinimumCoverage 85" -ForegroundColor Gray
Write-Host "• Reinstalar: .\install-mutation-checks.ps1 -Force" -ForegroundColor Gray