$ErrorActionPreference = 'Stop'

$nglSource = 'C:\Users\User\Downloads\ngl_3kitap_entegre_degerlendirme_sistemi.html'
$cambridgeSource = Join-Path $PSScriptRoot 'BAYETAV_TEK_DOSYA.html'
$outPath = Join-Path $PSScriptRoot 'NGL_BAYETAV_CAMBRIDGE_GOMULU.html'

function New-DataUri {
  param(
    [byte[]]$Bytes,
    [string]$Mime
  )
  return "data:$Mime;base64," + [Convert]::ToBase64String($Bytes)
}

if (-not (Test-Path -LiteralPath $nglSource)) {
  throw "NGL source not found: $nglSource"
}
if (-not (Test-Path -LiteralPath $cambridgeSource)) {
  throw "Cambridge single HTML not found. Run build_single_bayetav_html.ps1 first: $cambridgeSource"
}

$html = [System.IO.File]::ReadAllText($nglSource, [System.Text.Encoding]::UTF8)
$cambridgeBytes = [System.IO.File]::ReadAllBytes($cambridgeSource)
$cambridgeUri = New-DataUri -Bytes $cambridgeBytes -Mime 'text/html;charset=utf-8'

$html = $html.Replace(
  '<title>NGL - 3 Kitap Entegre DeÄŸerlendirme Sistemi</title>',
  '<title>NGL + BAYETAV Cambridge Exam Tek Dosya</title>'
)

$styleInsert = @'
.cambridge-panel{background:#fff;border:1px solid var(--g200);border-left:5px solid var(--navy);border-radius:12px;padding:16px;margin-bottom:16px}
.cambridge-panel h3{font-size:16px;color:var(--navy);margin-bottom:6px}
.cambridge-panel p{font-size:13px;color:var(--g700);line-height:1.5;margin-bottom:10px}
'@
$html = $html.Replace('@media(max-width:760px){.exam-head{display:block}.exam-meta{margin-top:12px;min-width:0}.exam-paper{padding:16px}}', $styleInsert + "`r`n@media(max-width:760px){.exam-head{display:block}.exam-meta{margin-top:12px;min-width:0}.exam-paper{padding:16px}}")

$openFunction = 'function openSpeakingPack(){window.open(new URL("speaking_exam_pack_certificates.html",location.href).href,"_blank","noopener")}'
$newFunction = 'const CAMBRIDGE_EXAM_HTML="' + $cambridgeUri + '";' + "`r`n" +
  'function openSpeakingPack(){const win=window.open(CAMBRIDGE_EXAM_HTML,"_blank","noopener");if(!win)alert("Cambridge Exam penceresi acilamadi. Tarayicida pop-up izni verin.")}'
$html = $html.Replace($openFunction, $newFunction)

$html = [regex]::Replace(
  $html,
  '<button class="book-btn" data-act="open-speaking-pack">.*?</button>',
  '<button class="book-btn" data-act="open-speaking-pack">Cambridge Exam</button>',
  1
)

$panel = '<div class="cambridge-panel no-print"><h3>BAYETAV Cambridge Exam</h3><p>KET, Flyers ve Impact 2 Cambridge-style sinav arsivi bu NGL dosyasinin icine gomuludur. Sesler ve sinav HTML icerikleri ayri klasor gerektirmez.</p><button class="btn btn-navy btn-sm" data-act="open-speaking-pack">Cambridge Exam Ac</button></div>'
$html = [regex]::Replace(
  $html,
  'return `<div class="card"><h2 class="card-title">.*?Exams</h2><p class="card-sub">View, print or download Formative A/B papers and MEB scenario-aligned written exams\.</p>',
  'return `' + $panel + '<div class="card"><h2 class="card-title">Exams</h2><p class="card-sub">View, print or download Formative A/B papers and MEB scenario-aligned written exams.</p>',
  1
)

[System.IO.File]::WriteAllText($outPath, $html, [System.Text.UTF8Encoding]::new($false))
Write-Host "Wrote $outPath"
Write-Host ("Size MB: {0:N1}" -f ((Get-Item -LiteralPath $outPath).Length / 1MB))
