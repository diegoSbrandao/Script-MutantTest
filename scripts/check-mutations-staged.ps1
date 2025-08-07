# check-mutations-staged.ps1
param(
    [int]$MinimumCoverage = 90,
    [string]$ProjectPath = ".",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "Verificando mutation coverage dos arquivos staged..." -ForegroundColor Cyan

try {
    # Verifica se esta em um repositorio Git
    $gitStatus = git status --porcelain 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Nao e um repositorio Git valido!" -ForegroundColor Red
        exit 1
    }

    # Detecta arquivos Java staged (adicionados para commit)
    $stagedJavaFiles = git diff --cached --name-only --diff-filter=AM | Where-Object {
        $_ -match '\.java$' -and $_ -match 'src/main/java/'
    }

    if ($stagedJavaFiles.Count -eq 0) {
        Write-Host "SUCESSO: Nenhum arquivo Java de producao modificado. Prosseguindo..." -ForegroundColor Green
        exit 0
    }

    Write-Host "Arquivos Java detectados para teste:" -ForegroundColor Yellow
    $stagedJavaFiles | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }

    # Converte caminhos de arquivo para nomes de classes
    $targetClasses = @()
    foreach ($file in $stagedJavaFiles) {
        # Remove src/main/java/ e .java, substitui / por .
        $className = $file -replace 'src/main/java/', '' -replace '\.java$', '' -replace '[/\\]', '.'
        $targetClasses += $className
        if ($Verbose) {
            Write-Host "   Classe alvo: $className" -ForegroundColor Gray
        }
    }

    if ($targetClasses.Count -eq 0) {
        Write-Host "AVISO: Nenhuma classe valida encontrada!" -ForegroundColor Yellow
        exit 0
    }

    # Cria configuracao temporaria do PIT
    $targetClassesString = $targetClasses -join ','
    Write-Host "Executando PIT test para classes: $targetClassesString" -ForegroundColor Cyan

    # Executa Maven PIT test com classes especificas
    $pitCommand = "mvn clean test org.pitest:pitest-maven:mutationCoverage -DtargetClasses=$targetClassesString -DoutputFormats=XML,HTML -Dverbose=$($Verbose.IsPresent)"

    if ($Verbose) {
        Write-Host "Comando PIT: $pitCommand" -ForegroundColor Gray
    }

    Write-Host "Executando mutation testing (isso pode demorar alguns minutos)..." -ForegroundColor Yellow

    $pitOutput = Invoke-Expression $pitCommand 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERRO: Falha ao executar PIT test!" -ForegroundColor Red
        Write-Host $pitOutput -ForegroundColor Red
        exit 1
    }

    # Localiza arquivo de resultados do PIT
    $pitReportsDir = Join-Path $ProjectPath "target/pit-reports"
    $latestReportDir = Get-ChildItem $pitReportsDir | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $latestReportDir) {
        Write-Host "ERRO: Relatorio do PIT nao encontrado em $pitReportsDir" -ForegroundColor Red
        exit 1
    }

    $mutationsXmlPath = Join-Path $latestReportDir.FullName "mutations.xml"
    $indexHtmlPath = Join-Path $latestReportDir.FullName "index.html"

    if (-not (Test-Path $mutationsXmlPath)) {
        Write-Host "ERRO: Arquivo mutations.xml nao encontrado!" -ForegroundColor Red
        exit 1
    }

    # Analisa resultados usando a mesma logica do script existente
    [xml]$xml = Get-Content $mutationsXmlPath -ErrorAction Stop

    $total = 0
    $killed = 0
    $survived = 0
    $noCoverage = 0

    # Busca mutations no XML (mesma logica do script original)
    $mutations = $null
    if ($xml.mutations) {
        $mutations = $xml.mutations.mutation
    } elseif ($xml.report -and $xml.report.mutations) {
        $mutations = $xml.report.mutations.mutation
    } else {
        $mutations = $xml.SelectNodes("//mutation")
    }

    # Conta mutations por status (mesma logica do script original)
    if ($mutations) {
        $total = $mutations.Count
        foreach ($mut in $mutations) {
            $status = ""
            if ($mut.status) {
                $status = $mut.status
            } elseif ($mut.HasAttribute("status")) {
                $status = $mut.GetAttribute("status")
            }

            switch ($status) {
                "KILLED" { $killed++ }
                "SURVIVED" { $survived++ }
                "NO_COVERAGE" { $noCoverage++ }
            }
        }
    }

    $mutationScore = 0
    if ($total -gt 0) {
        $mutationScore = [math]::Round(($killed * 100.0) / $total, 2)
    }

    # Extrai Line Coverage do HTML (mesma logica do script original)
    $lc = 0
    $lt = 0
    $lineCoveragePercent = 0
    $lineCoverage = "N/A"

    if (Test-Path $indexHtmlPath) {
        $htmlContent = Get-Content $indexHtmlPath -Raw -ErrorAction Stop

        if ($htmlContent -match '<td>(\d+)%[^<]*<div[^>]*>[^<]*<div[^>]*>[^<]*</div>[^<]*<div[^>]*>(\d+)/(\d+)</div>') {
            $lineCoveragePercent = [int]$matches[1]
            $lc = [int]$matches[2]
            $lt = [int]$matches[3]
            $lineCoverage = "$lineCoveragePercent% ($lc/$lt)"
        }
    }

    # Usa as variaveis do script original
    $totalMutations = $total
    $killedMutations = $killed
    $survivedMutations = $survived
    $noCoverageMutations = $noCoverage

    # Exibe resultados
    Write-Host ""
    Write-Host "RESULTADOS DO MUTATION TESTING:" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    Write-Host "Mutation Score:      $mutationScore%" -ForegroundColor White
    Write-Host "Line Coverage:       $lineCoverage" -ForegroundColor White
    Write-Host "Total Mutations:     $totalMutations" -ForegroundColor Gray
    Write-Host "Killed:              $killedMutations" -ForegroundColor Green
    Write-Host "Survived:            $survivedMutations" -ForegroundColor Red
    Write-Host "No Coverage:         $noCoverageMutations" -ForegroundColor Yellow
    Write-Host "=========================================" -ForegroundColor Cyan

    # Verifica se atende ao criterio minimo
    if ($mutationScore -lt $MinimumCoverage) {
        Write-Host ""
        Write-Host "COMMIT REJEITADO!" -ForegroundColor Red -BackgroundColor DarkRed
        Write-Host "Mutation coverage de $mutationScore% esta abaixo do minimo exigido de $MinimumCoverage%" -ForegroundColor Red

        if ($survivedMutations -gt 0) {
            Write-Host ""
            Write-Host "ACAO NECESSARIA:" -ForegroundColor Yellow
            Write-Host "Voce precisa matar $survivedMutations mutante(s) sobrevivente(s)!" -ForegroundColor Yellow
            Write-Host "Verifique o relatorio detalhado em: $($latestReportDir.FullName)\index.html" -ForegroundColor Yellow
        }

        if ($noCoverageMutations -gt 0) {
            Write-Host "Tambem ha $noCoverageMutations mutante(s) sem cobertura de teste!" -ForegroundColor Yellow
        }

        Write-Host ""
        Write-Host "DICAS:" -ForegroundColor Cyan
        Write-Host "1. Abra o relatorio HTML para ver mutacoes especificas" -ForegroundColor Gray
        Write-Host "2. Adicione/melhore testes para matar os mutantes" -ForegroundColor Gray
        Write-Host "3. Execute novamente apos fazer as correcoes" -ForegroundColor Gray

        exit 1
    } else {
        Write-Host ""
        Write-Host "COMMIT APROVADO!" -ForegroundColor Green -BackgroundColor DarkGreen
        Write-Host "Mutation coverage de $mutationScore% atende ao criterio minimo de $MinimumCoverage%" -ForegroundColor Green
        Write-Host "Relatorio disponivel em: $($latestReportDir.FullName)\index.html" -ForegroundColor Gray
        exit 0
    }

} catch {
    Write-Host ""
    Write-Host "ERRO DURANTE VERIFICACAO:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Verifique se:" -ForegroundColor Yellow
    Write-Host "1. O projeto Maven esta configurado corretamente" -ForegroundColor Gray
    Write-Host "2. O plugin PIT esta no pom.xml" -ForegroundColor Gray
    Write-Host "3. Os testes estao passando" -ForegroundColor Gray
    exit 1
}