param(
  [string]$xmlPath,
  [string]$readmePath
)

if (-not (Test-Path $xmlPath)) {
  Write-Host "XML nao encontrado em $xmlPath. Abortando."
  exit 1
}

try {
  # Carrega XML
  [xml]$xml = Get-Content $xmlPath -ErrorAction Stop

  # Inicializa contadores
  $total = 0
  $killed = 0
  $survived = 0
  $noCoverage = 0
  $lc = 0
  $lt = 0

  # Busca mutations no XML - diferentes estruturas possiveis
  $mutations = $null

  if ($xml.mutations) {
    $mutations = $xml.mutations.mutation
  } elseif ($xml.report -and $xml.report.mutations) {
    $mutations = $xml.report.mutations.mutation
  } else {
    # Busca generica por elementos mutation
    $mutations = $xml.SelectNodes("//mutation")
  }

  # Conta mutations por status
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

  # Busca cobertura de linhas
  if ($xml.report -and $xml.report.lineCoverage) {
    $lcNode = $xml.report.lineCoverage.linesCovered
    $ltNode = $xml.report.lineCoverage.totalLines
    if ($lcNode) { $lc = [int]$lcNode }
    if ($ltNode) { $lt = [int]$ltNode }
  } elseif ($xml.coverage) {
    $lcNode = $xml.coverage.linesCovered
    $ltNode = $xml.coverage.totalLines
    if ($lcNode) { $lc = [int]$lcNode }
    if ($ltNode) { $lt = [int]$ltNode }
  }

  Write-Host "Debug: Total=$total, Killed=$killed, Survived=$survived, NoCoverage=$noCoverage"
  Write-Host "Debug: LinesCovered=$lc, TotalLines=$lt"

  # Calcula scores
  $mutationScore = 0
  $lineCoverage = 0
  $testStrength = 0

  if ($total -gt 0) {
    $mutationScore = [math]::Round(($killed * 100.0) / $total, 2)
  }

  if ($lt -gt 0) {
    $lineCoverage = [math]::Round(($lc * 100.0) / $lt, 2)
  }

  $testStrength = [math]::Round(($mutationScore * 0.7) + ($lineCoverage * 0.3), 2)

  # Cria conteudo markdown
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

  $newContent = @"
## 📊 Metricas de Qualidade dos Testes

**Mutation Score**: $mutationScore%
**Line Coverage**: $lineCoverage%
**Test Strength**: $testStrength%

| Metrica                 | Valor                   |
|-------------------------|-------------------------|
| Total Mutations         | $total                   |
| Killed Mutations        | $killed                  |
| Survived Mutations      | $survived                |
| No Coverage Mutations   | $noCoverage              |
| Lines Covered           | $lc/$lt                  |

*Ultima atualizacao: $timestamp*

---
"@

  # Atualiza README
  $finalContent = ""

  if (Test-Path $readmePath) {
    $existingContent = Get-Content $readmePath -Raw -ErrorAction SilentlyContinue
    if ($existingContent) {
      # Remove secao anterior se existir
      $cleanContent = $existingContent -replace '(?s)## 📊 Metricas de Qualidade dos Testes.*?---\s*', ''
      $cleanContent = $cleanContent.TrimEnd()
      if ($cleanContent) {
        $finalContent = $cleanContent + "`n`n" + $newContent
      } else {
        $finalContent = $newContent
      }
    } else {
      $finalContent = $newContent
    }
  } else {
    # Cria header basico se arquivo nao existe
    $header = @"
# Demo Project

Projeto de demonstracao com testes de mutacao usando PIT.

"@
    $finalContent = $header + $newContent
  }

  # Escreve arquivo
  Set-Content -Path $readmePath -Value $finalContent -Encoding UTF8

  Write-Host "README atualizado com sucesso!"
  Write-Host "Mutation Score: $mutationScore% | Line Coverage: $lineCoverage% | Test Strength: $testStrength%"
  exit 0

} catch {
  Write-Host "Erro ao processar arquivos: $($_.Exception.Message)"
  exit 1
}