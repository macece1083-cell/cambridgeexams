$ErrorActionPreference = 'Stop'

$zipPath = 'C:\Users\User\Downloads\BAYETAV_Cambridge_Exam_Portable.zip'
$outPath = Join-Path $PSScriptRoot 'BAYETAV_TEK_DOSYA.html'
$root = 'BAYETAV_Cambridge_Exam_Portable\'

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Read-ZipEntryBytes {
  param(
    [System.IO.Compression.ZipArchive]$Zip,
    [string]$Name
  )
  $entry = $Zip.GetEntry($root + $Name)
  if (-not $entry) { throw "Zip entry not found: $Name" }
  $stream = $entry.Open()
  try {
    $memory = New-Object System.IO.MemoryStream
    try {
      $stream.CopyTo($memory)
      return $memory.ToArray()
    } finally {
      $memory.Dispose()
    }
  } finally {
    $stream.Dispose()
  }
}

function Read-ZipEntryText {
  param(
    [System.IO.Compression.ZipArchive]$Zip,
    [string]$Name
  )
  $bytes = Read-ZipEntryBytes -Zip $Zip -Name $Name
  return [System.Text.Encoding]::UTF8.GetString($bytes)
}

function New-DataUri {
  param(
    [byte[]]$Bytes,
    [string]$Mime
  )
  return "data:$Mime;base64," + [Convert]::ToBase64String($Bytes)
}

function ConvertTo-CertificatePackHtml {
  param(
    [string]$Html,
    [string]$LogoUri
  )

  if (-not $Html) { return $Html }
  if (-not $LogoUri) { return $Html }

  $newCssFunction = @'
function certificateCss() {
      return `
        :root{--blue:#0f63b7;--deep:#0a3768;--cyan:#58b7d8;--green:#b9cf55;--gold:#c89d2b;--ink:#17324a;--muted:#5f7082;--line:#c9d7e4;--paper:#ffffff}
        *{box-sizing:border-box}
        body{margin:0;background:#edf3f8;color:var(--ink);font-family:Calibri,Arial,sans-serif}
        @page{size:A4 landscape;margin:0}
        .no-print{padding:12px 18px;text-align:center}
        .no-print button{border:0;background:var(--blue);color:#fff;font:inherit;font-weight:700;padding:10px 18px;border-radius:4px;cursor:pointer}
        .cert-page{position:relative;width:297mm;height:210mm;margin:0 auto;background:var(--paper);padding:13mm 16mm;box-shadow:0 10px 34px rgba(15,42,66,.16);overflow:hidden}
        .cert-page:before{content:"";position:absolute;inset:7mm;border:1.5pt solid var(--deep);pointer-events:none}
        .cert-page:after{content:"e";position:absolute;right:14mm;bottom:9mm;width:42mm;height:42mm;border-radius:50%;display:grid;place-items:center;border:1pt solid rgba(185,207,85,.5);color:rgba(185,207,85,.16);font-size:54pt;font-weight:900;font-family:Georgia,"Times New Roman",serif;pointer-events:none}
        .cert-content{position:relative;z-index:1;height:100%;display:grid;grid-template-rows:auto 1fr auto;gap:8mm}
        .cert-top{display:grid;grid-template-columns:1fr auto 1fr;align-items:start;border-bottom:2pt solid var(--deep);padding-bottom:5mm}
        .brand{text-align:center}
        .cert-logo{width:48mm;max-height:24mm;object-fit:contain;display:block;margin:0 auto 1.5mm}
        .brand-name{font-size:9.5pt;font-weight:800;letter-spacing:.18em;text-transform:uppercase;color:var(--blue)}
        .cert-ref{text-align:right;color:var(--muted);font-size:9pt;line-height:1.45;text-transform:uppercase;letter-spacing:.08em}
        .cert-kind{color:var(--muted);font-size:9pt;font-weight:700;text-transform:uppercase;letter-spacing:.14em}
        .main-area{display:grid;grid-template-columns:1.34fr .9fr;gap:10mm;align-items:center}
        .cert-kicker{font-size:11pt;font-weight:900;letter-spacing:.18em;text-transform:uppercase;color:var(--blue);margin-bottom:4mm}
        .cert-title{font-family:Georgia,"Times New Roman",serif;font-size:34pt;line-height:1.05;font-weight:400;margin:0 0 6mm;color:var(--ink)}
        .cert-copy{font-size:12.5pt;line-height:1.38;color:var(--muted);max-width:178mm;margin:0 0 4mm}
        .candidate-name{font-family:Georgia,"Times New Roman",serif;font-size:30pt;font-weight:700;line-height:1.1;color:var(--ink);border-bottom:1.5pt solid var(--green);padding-bottom:2.5mm;margin:4mm 0}
        .details{display:grid;grid-template-columns:repeat(4,1fr);gap:3mm;margin-top:6mm}
        .detail{border:1pt solid var(--line);padding:3.5mm;min-height:18mm;background:#fbfdff}
        .detail span{display:block;font-size:8.5pt;color:var(--muted);text-transform:uppercase;letter-spacing:.09em;margin-bottom:1.8mm}
        .detail strong{display:block;font-size:12pt;color:var(--ink);line-height:1.22}
        .result-panel{border:1.4pt solid var(--deep);padding:5.5mm;background:linear-gradient(180deg,#f7fbff,#fff);box-shadow:inset 0 0 0 1.5mm #fff, inset 0 0 0 1.9mm rgba(15,99,183,.16)}
        .overall{text-align:center;border-bottom:1pt solid var(--line);padding-bottom:4mm;margin-bottom:4mm}
        .overall-number{font-size:39pt;font-weight:900;color:var(--blue);line-height:1}
        .overall-label{font-size:9pt;color:var(--muted);text-transform:uppercase;letter-spacing:.08em;margin-top:1mm}
        .award h2{font-size:18pt;margin:0 0 1.5mm;color:var(--ink)}
        .award p{margin:0 0 2mm;color:var(--muted);font-size:10.8pt;line-height:1.32}
        .components{margin-top:4mm;border-top:1pt solid var(--line)}
        .component{display:grid;grid-template-columns:1fr auto;gap:3mm;align-items:center;border-bottom:1pt solid var(--line);padding:2mm 0;font-size:9.8pt}
        .component strong{font-size:9.8pt}
        .component .score{font-weight:800;color:var(--blue)}
        .scorebar{grid-column:1 / -1;height:2.2mm;border-radius:99px;background:#dfeaf3;overflow:hidden}
        .scorebar span{display:block;height:100%;background:linear-gradient(90deg,var(--green),var(--cyan),var(--blue))}
        .marks{grid-column:1 / -1;display:flex;gap:1.3mm}
        .bayetav-mark{width:5.2mm;height:5.2mm;border-radius:50%;display:inline-grid;place-items:center;border:1pt solid var(--green);color:var(--green);font-size:8pt;font-weight:900;font-family:Georgia,"Times New Roman",serif;background:#fff;line-height:1}
        .bayetav-mark.on{background:var(--green);color:#fff;box-shadow:0 0 0 1pt rgba(15,99,183,.12)}
        .notes{margin-top:4mm;border-left:3pt solid var(--green);background:#f8fbef;padding:3mm 4mm;color:var(--muted);font-size:9.8pt}
        .signature-row{display:grid;grid-template-columns:1fr 1fr 1fr;gap:16mm;align-items:end}
        .signature{border-top:1pt solid var(--ink);padding-top:2.5mm;font-size:10pt;color:var(--muted);text-align:center}
        .footer-note{position:absolute;left:17mm;right:17mm;bottom:6mm;text-align:center;color:var(--muted);font-size:8.5pt}
        @media print{body{background:#fff}.no-print{display:none}.cert-page{box-shadow:none;margin:0}}
      `;
    }
'@

  $newCertificateFunction = @'
function certificateHtml(data) {
      const info = resultInfo(data.exam, data.percent);
      const level = data.exam.type === "flyers" ? "A2 Flyers Practice Exam" : "A2 Key for Schools Practice Test";
      const certRef = "BAYETAV-" + data.exam.id.toUpperCase() + "-" + String(Date.now()).slice(-6);
      const logoUri = "__BAYETAV_CERT_LOGO_URI__";
      const logoTag = logoUri ? '<img class="cert-logo" src="' + logoUri + '" alt="BAYETAV Okullari logo">' : "";
      const notes = data.notes ? '<div class="notes"><strong>Teacher notes:</strong> ' + escapeHtml(data.notes) + '</div>' : "";
      const readingMax = Math.max(1, Math.ceil(data.maxRw / 2));
      const writingMax = Math.max(1, data.maxRw - readingMax);
      const reading = Math.min(readingMax, Math.round(data.rw * readingMax / data.maxRw));
      const writing = Math.max(0, data.rw - reading);
      const components = componentRow("Listening", data.listening, data.maxListening) +
        componentRow("Reading", reading, readingMax) +
        componentRow("Writing", writing, writingMax) +
        componentRow("Speaking", data.speaking, data.maxSpeaking);
      return '<!doctype html><html lang="en"><head><meta charset="utf-8"><title>BAYETAV Certificate - ' + escapeHtml(data.name) + '</title><style>' + certificateCss() + '</style></head><body>' +
        '<div class="no-print"><button onclick="window.print()">Print / Save as PDF</button></div>' +
        '<main class="cert-page">' +
          '<div class="cert-content">' +
            '<section class="cert-top">' +
              '<div class="cert-kind">Cambridge Practice</div>' +
              '<div class="brand">' + logoTag + '<div class="brand-name">Bayetav Okullari</div></div>' +
              '<div class="cert-ref">Certificate of Achievement<br>Reference: ' + certRef + '</div>' +
            '</section>' +
            '<section class="main-area">' +
              '<div class="statement">' +
                '<div class="cert-kicker">Statement of Results</div>' +
                '<h1 class="cert-title">Certificate of Achievement</h1>' +
                '<p class="cert-copy">This certificate is awarded to</p>' +
                '<div class="candidate-name">' + escapeHtml(data.name) + '</div>' +
                '<p class="cert-copy">for completing <strong>' + escapeHtml(data.exam.title) + '</strong> in the <strong>' + level + '</strong> format as part of the BAYETAV English assessment programme.</p>' +
                '<div class="details">' +
                  '<div class="detail"><span>Candidate</span><strong>' + escapeHtml(data.name) + '</strong></div>' +
                  '<div class="detail"><span>Class</span><strong>' + escapeHtml(data.className) + '</strong></div>' +
                  '<div class="detail"><span>Issue Date</span><strong>' + escapeHtml(data.dateText) + '</strong></div>' +
                  '<div class="detail"><span>CEFR</span><strong>' + escapeHtml(info.cefr) + '</strong></div>' +
                '</div>' +
                notes +
              '</div>' +
              '<aside class="result-panel">' +
                '<div class="overall"><div class="overall-number">' + escapeHtml(info.scale) + '</div><div class="overall-label">' + escapeHtml(info.scaleLabel) + '</div></div>' +
                '<div class="award"><h2>' + escapeHtml(info.label) + '</h2><p>' + escapeHtml(info.detail) + '</p><p><strong>Total:</strong> ' + formatScore(data.total) + ' / ' + formatScore(data.maxTotal) + ' (' + data.percent + '%)</p></div>' +
                '<section class="components">' + components + '</section>' +
              '</aside>' +
            '</section>' +
            '<section class="signature-row">' +
              '<div class="signature">Examiner / Teacher</div>' +
              '<div class="signature">BAYETAV English Department</div>' +
              '<div class="signature">School Director</div>' +
            '</section>' +
          '</div>' +
          '<div class="footer-note">Internal practice certificate. This document is prepared for BAYETAV school assessment use and is not an official Cambridge English certificate.</div>' +
        '</main>' +
      '</body></html>';
    }
'@.Replace('__BAYETAV_CERT_LOGO_URI__', $LogoUri)

  $newComponentFunction = @'
function componentRow(label, score, max) {
      const pct = componentPercent(score, max);
      return '<div class="component">' +
        '<strong>' + label + '</strong>' +
        '<div class="score">' + formatScore(score) + ' / ' + formatScore(max) + ' - ' + pct + '%</div>' +
        '<div class="scorebar"><span style="width:' + pct + '%"></span></div>' +
        '<div class="marks">' + bayetavMarks(componentMarks(score, max)) + '</div>' +
      '</div>';
    }
'@

  $newBayetavMarksFunction = @'
function bayetavMarks(count) {
      let html = "";
      for (let i = 1; i <= 5; i += 1) {
        html += '<span class="bayetav-mark' + (i <= count ? " on" : "") + '">e</span>';
      }
      return html;
    }
'@

  $out = [regex]::Replace($Html, '(?s)function certificateCss\(\) \{.*?\r?\n    \}\r?\n\r?\n    function componentRow', $newCssFunction + "`r`n`r`n    function componentRow", 1)
  $out = [regex]::Replace($out, '(?s)function componentRow\(label, score, max\) \{.*?\r?\n    \}\r?\n\r?\n    function certificateHtml', $newComponentFunction + "`r`n`r`n    function certificateHtml", 1)
  $out = [regex]::Replace($out, '(?s)function certificateHtml\(data\) \{.*?\r?\n    \}\r?\n\r?\n    function openCertificate', $newCertificateFunction + "`r`n`r`n    function openCertificate", 1)
  $out = [regex]::Replace($out, '(?s)function bayetavMarks\(count\) \{.*?\r?\n    \}\r?\n\r?\n    function resultInfo', $newBayetavMarksFunction + "`r`n`r`n    function resultInfo", 1)
  $out = $out.Replace('<td><button class="btn cert-btn" type="button" data-cert-row>Sertifika haz&#305;rla</button></td>', '<td><button class="btn cert-btn" type="button" data-cert-row>Logolu sertifika</button></td>')
  return $out
}

function New-Flyers2SpeakingBookletHtml {
  param([hashtable]$Images)

  $template = @'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Flyers Exam 2 Speaking Booklet</title>
  <style>
    *{box-sizing:border-box}
    body{margin:0;background:#eef3f6;color:#17212b;font-family:Calibri,Arial,sans-serif;font-size:12pt;line-height:1.35}
    @page{size:A4;margin:10mm}
    .cover,.page{width:210mm;min-height:297mm;margin:0 auto 12px;background:#fff;padding:14mm;box-shadow:0 8px 28px rgba(20,35,50,.12);break-after:page;page-break-after:always}
    .cover{display:flex;flex-direction:column;justify-content:space-between;border-top:12mm solid #1f7a4d}
    .page.landscape{width:297mm;min-height:210mm}
    .page:last-child{break-after:auto;page-break-after:auto}
    .label{font-size:10pt;font-weight:800;letter-spacing:.12em;text-transform:uppercase;color:#1f7a4d}
    h1{font-size:36pt;line-height:1.05;margin:8mm 0 4mm}
    h2{font-size:21pt;margin:0 0 4mm}
    h3{font-size:14pt;margin:0 0 3mm;color:#1f7a4d}
    p{margin:0 0 3mm}
    .sub{max-width:170mm;color:#52606d;font-size:15pt}
    .notice{border:1.4pt solid #aeb8c2;border-left:5mm solid #1f7a4d;padding:4mm;color:#52606d}
    .head{display:grid;grid-template-columns:1fr auto;gap:8mm;align-items:start;border-bottom:2pt solid #1f7a4d;padding-bottom:4mm;margin-bottom:5mm}
    .time{background:#1f7a4d;color:#fff;font-weight:800;text-align:center;padding:3mm 5mm;min-width:34mm}
    .meta{display:grid;grid-template-columns:repeat(4,1fr);gap:3mm;margin:4mm 0 6mm}
    .meta div,.card,.script,.rubric-box{border:1.2pt solid #aeb8c2;padding:3mm;background:#fff}
    .meta div{background:#edf8f2;font-size:10.5pt}
    .part-title{display:flex;justify-content:space-between;gap:4mm;background:#1f7a4d;color:#fff;font-weight:800;padding:3mm 4mm;margin:7mm 0 0}
    .part-body{border:1.2pt solid #aeb8c2;border-top:0;padding:4mm}
    .script{background:#fff7e6;border-color:#b7791f;margin:3mm 0}
    .script strong{color:#8a5a00}
    .stage{color:#52606d;font-style:italic}
    .visual{width:100%;border:1.4pt solid #17212b;display:block;background:#fff;object-fit:contain}
    .visual.tall{max-height:136mm}
    .visual.story{max-height:123mm}
    .two-pics{display:grid;grid-template-columns:1fr 1fr;gap:5mm}
    .story-grid{display:grid;grid-template-columns:1fr 1fr;gap:5mm}
    .caption{font-weight:800;text-align:center;margin:2mm 0 1mm}
    table{width:100%;border-collapse:collapse;margin:3mm 0}
    th,td{border:1.1pt solid #aeb8c2;padding:2.5mm;text-align:left;vertical-align:top}
    th{background:#edf8f2}
    ol,ul{margin:2mm 0 0 6mm;padding:0}
    li{margin:1.3mm 0}
    .cards{display:grid;grid-template-columns:1fr 1fr;gap:5mm}
    .candidate-only{border:2pt dashed #1f7a4d;background:#f8fcfa}
    .answer-line{display:inline-block;min-width:34mm;border-bottom:1pt solid #17212b}
    .score-table td,.score-table th{height:10mm}
    .score-cell{width:24mm;text-align:center;font-weight:800}
    .comments{min-height:32mm;border:1.2pt solid #aeb8c2;padding:3mm}
    @media print{body{background:#fff}.cover,.page{box-shadow:none;margin:0}.no-print{display:none}}
  </style>
</head>
<body>
  <section class="cover">
    <div>
      <div class="label">BAYETAV Schools - A2 Flyers Speaking</div>
      <h1>Flyers Speaking Exam<br>Exam 2</h1>
      <p class="sub">Complete candidate booklet and interlocutor frame. Theme: city places, health, safety, transport and healthy routines.</p>
    </div>
    <div class="notice">Use the candidate pages with the child. The interlocutor pages include the full script, expected answers, support prompts and scoring table.</div>
  </section>

  <section class="page">
    <div class="head">
      <div>
        <div class="label">Interlocutor Copy</div>
        <h2>Test Overview</h2>
      </div>
      <div class="time">7-9 minutes<br>1 child</div>
    </div>
    <div class="meta">
      <div><strong>Part 1</strong><br>Find the differences</div>
      <div><strong>Part 2</strong><br>Information exchange</div>
      <div><strong>Part 3</strong><br>Picture story</div>
      <div><strong>Part 4</strong><br>Personal questions</div>
    </div>
    <div class="script">
      <p><strong>Opening script:</strong> Hello. My name is __________. What's your name? How old are you? Thank you. Now we are going to look at some pictures.</p>
    </div>
    <table>
      <tbody>
        <tr><th>Materials</th><td>Part 1 examiner picture and candidate picture; Part 2 information cards; Part 3 four story pictures; scoring sheet.</td></tr>
        <tr><th>Timing</th><td>Part 1: about 2 minutes. Part 2: about 2 minutes. Part 3: about 2 minutes. Part 4: about 2 minutes.</td></tr>
        <tr><th>Support rule</th><td>Give one repetition or one simple support question if the child needs help. Do not over-correct grammar during the response.</td></tr>
      </tbody>
    </table>
  </section>

  <section class="page landscape">
    <div class="head">
      <div><div class="label">Candidate Booklet</div><h2>Part 1 - Find the Differences</h2></div>
      <div class="time">Candidate Picture</div>
    </div>
    <p class="stage">The child looks at this picture. The interlocutor keeps the examiner picture.</p>
    <img class="visual tall" src="__PART1_CANDIDATE__" alt="Candidate city picture for Flyers speaking part 1">
  </section>

  <section class="page landscape">
    <div class="head">
      <div><div class="label">Interlocutor Reference</div><h2>Part 1 - Examiner and Candidate Pictures</h2></div>
      <div class="time">About 2 minutes</div>
    </div>
    <div class="two-pics">
      <div>
        <div class="caption">Examiner picture</div>
        <img class="visual" src="__PART1_EXAMINER__" alt="Examiner city picture">
      </div>
      <div>
        <div class="caption">Candidate picture</div>
        <img class="visual" src="__PART1_CANDIDATE__" alt="Candidate city picture">
      </div>
    </div>
  </section>

  <section class="page">
    <div class="part-title"><span>Part 1 - Interlocutor Script</span><span>Find the differences</span></div>
    <div class="part-body">
      <div class="script">
        <p><strong>Interlocutor:</strong> Here are two pictures. They look the same, but some things are different. I am going to say something about my picture. You tell me how your picture is different.</p>
      </div>
      <table>
        <thead><tr><th>Interlocutor says</th><th>Expected candidate response</th><th>Support prompt</th></tr></thead>
        <tbody>
          <tr><td>In my picture, the doctor is outside the hospital.</td><td>In my picture, the doctor is inside / by the hospital door.</td><td>Where is the doctor?</td></tr>
          <tr><td>In my picture, the boy is riding a bicycle.</td><td>In my picture, the boy is walking with a dog.</td><td>What is the boy doing?</td></tr>
          <tr><td>In my picture, the bus is green.</td><td>In my picture, the bus is red.</td><td>What colour is the bus?</td></tr>
          <tr><td>In my picture, the police officer is stopping the cars.</td><td>In my picture, the police officer is talking to a driver.</td><td>Who is the police officer talking to?</td></tr>
          <tr><td>In my picture, the bridge is blue.</td><td>In my picture, the bridge is grey.</td><td>What colour is the bridge?</td></tr>
          <tr><td>In my picture, the bus is near the bridge.</td><td>In my picture, the bus is in the middle of the road.</td><td>Where is the bus?</td></tr>
        </tbody>
      </table>
    </div>

    <div class="part-title"><span>Part 2 - Interlocutor Script</span><span>Information exchange</span></div>
    <div class="part-body">
      <div class="script">
        <p><strong>Interlocutor:</strong> Now we are going to talk about two water projects. I don't know about the Blue River Team, so I am going to ask you some questions. Then you ask me about Save Our Water.</p>
        <p class="stage">Give the child the Blue River Team card. Keep the Save Our Water card.</p>
      </div>
      <div class="cards">
        <div class="card candidate-only">
          <h3>Candidate Card: Blue River Team</h3>
          <ul>
            <li>Students: 25</li>
            <li>Collects water from: the school roof</li>
            <li>Uses water for: the school garden</li>
            <li>Meeting day: Thursday</li>
            <li>Next project: beach clean-up</li>
          </ul>
        </div>
        <div class="card">
          <h3>Examiner Card: Save Our Water</h3>
          <ul>
            <li>Students: 18</li>
            <li>Collects water from: rain barrels</li>
            <li>Uses water for: trees near the playground</li>
            <li>Meeting day: Friday</li>
            <li>Next project: plant flowers</li>
          </ul>
        </div>
      </div>
      <table>
        <thead><tr><th>Examiner asks candidate</th><th>Candidate asks examiner</th></tr></thead>
        <tbody>
          <tr><td>How many students are in the Blue River Team?</td><td>How many students are in Save Our Water?</td></tr>
          <tr><td>Where do they collect water from?</td><td>Where do they collect water from?</td></tr>
          <tr><td>What do they use the water for?</td><td>What do they use the water for?</td></tr>
          <tr><td>Which day do they meet?</td><td>Which day do they meet?</td></tr>
          <tr><td>What is their next project?</td><td>What is their next project?</td></tr>
        </tbody>
      </table>
    </div>
  </section>

  <section class="page">
    <div class="head">
      <div><div class="label">Candidate Booklet</div><h2>Part 2 - Blue River Team</h2></div>
      <div class="time">Candidate Card</div>
    </div>
    <div class="card candidate-only">
      <h3>Blue River Team</h3>
      <ul>
        <li><strong>Students:</strong> 25</li>
        <li><strong>Collects water from:</strong> the school roof</li>
        <li><strong>Uses water for:</strong> the school garden</li>
        <li><strong>Meeting day:</strong> Thursday</li>
        <li><strong>Next project:</strong> beach clean-up</li>
      </ul>
    </div>
    <h3 style="margin-top:9mm">Ask about Save Our Water</h3>
    <ol>
      <li>How many students <span class="answer-line"></span>?</li>
      <li>Where do they collect water from?</li>
      <li>What do they use the water for?</li>
      <li>Which day do they meet?</li>
      <li>What is their next project?</li>
    </ol>
  </section>

  <section class="page landscape">
    <div class="head">
      <div><div class="label">Candidate Booklet</div><h2>Part 3 - Picture Story</h2></div>
      <div class="time">A Healthy Day in the City</div>
    </div>
    <div class="story-grid">
      <div><div class="caption">Picture 1</div><img class="visual story" src="__STORY1__" alt="Defne fills her water bottle before school"></div>
      <div><div class="caption">Picture 2</div><img class="visual story" src="__STORY2__" alt="Defne runs in the park with a friend"></div>
      <div><div class="caption">Picture 3</div><img class="visual story" src="__STORY3__" alt="Kerem has a toothache in the park"></div>
      <div><div class="caption">Picture 4</div><img class="visual story" src="__STORY4__" alt="A doctor checks Kerem and the children eat soup"></div>
    </div>
  </section>

  <section class="page">
    <div class="part-title"><span>Part 3 - Interlocutor Script</span><span>Picture story</span></div>
    <div class="part-body">
      <div class="script">
        <p><strong>Interlocutor:</strong> Now look at these pictures. They show a story. The story is called <strong>A Healthy Day in the City</strong>.</p>
        <p>Look at the pictures first. In picture one, Defne is filling her water bottle before school. It is a sunny morning and she is getting ready for the day.</p>
        <p>Now you tell the story.</p>
      </div>
      <table>
        <thead><tr><th>Picture</th><th>Expected story content</th><th>Support prompt if needed</th></tr></thead>
        <tbody>
          <tr><td>2</td><td>Defne goes to the park. She runs with her friend and they look happy.</td><td>Where are the children? What are they doing?</td></tr>
          <tr><td>3</td><td>They see Kerem near the bench. He has a toothache and looks worried or in pain.</td><td>What is wrong with the boy?</td></tr>
          <tr><td>4</td><td>A doctor or nurse checks Kerem. Later, the children eat healthy soup and drink water.</td><td>Who helps him? What do the children eat?</td></tr>
        </tbody>
      </table>
      <div class="card">
        <h3>Good candidate language</h3>
        <p>First, then, after that, later, because, so, toothache, healthy, bottle, vegetables, doctor, soup.</p>
      </div>
    </div>

    <div class="part-title"><span>Part 4 - Interlocutor Script</span><span>Personal questions</span></div>
    <div class="part-body">
      <div class="script"><p><strong>Interlocutor:</strong> Now let's talk about you.</p></div>
      <ol>
        <li>Do you live in a city or a town?</li>
        <li>What places are near your home?</li>
        <li>How do you usually come to school?</li>
        <li>What do you do to stay healthy?</li>
        <li>How much water do you drink every day?</li>
        <li>What healthy food do you like?</li>
        <li>When did you last visit a doctor or dentist?</li>
        <li>Where would you like to go on holiday?</li>
      </ol>
      <div class="script"><p><strong>Closing script:</strong> Thank you. That is the end of the test.</p></div>
    </div>
  </section>

  <section class="page">
    <div class="head">
      <div><div class="label">Assessment</div><h2>Speaking Score Sheet</h2></div>
      <div class="time">/20</div>
    </div>
    <div class="meta">
      <div><strong>Student:</strong><br><span class="answer-line"></span></div>
      <div><strong>Class:</strong><br><span class="answer-line"></span></div>
      <div><strong>Date:</strong><br><span class="answer-line"></span></div>
      <div><strong>Examiner:</strong><br><span class="answer-line"></span></div>
    </div>
    <table class="score-table">
      <thead><tr><th>Part</th><th>5</th><th>3</th><th>1</th><th class="score-cell">Score</th></tr></thead>
      <tbody>
        <tr><td><strong>Part 1</strong></td><td>Clear differences with full phrases.</td><td>Some correct differences, short phrases.</td><td>Very limited or frequent help.</td><td></td></tr>
        <tr><td><strong>Part 2</strong></td><td>Answers and asks accurately.</td><td>Mostly clear with some support.</td><td>Difficulty asking or answering.</td><td></td></tr>
        <tr><td><strong>Part 3</strong></td><td>Connected story with sequence words.</td><td>Basic picture descriptions.</td><td>Single words or much prompting.</td><td></td></tr>
        <tr><td><strong>Part 4</strong></td><td>Personal answers with details.</td><td>Short but understandable answers.</td><td>Very limited answers.</td><td></td></tr>
      </tbody>
    </table>
    <table>
      <tbody>
        <tr><th>Total score</th><td class="score-cell">/20</td><th>Estimated shields</th><td></td></tr>
        <tr><th>17-20</th><td>5 shields</td><th>13-16</th><td>4 shields</td></tr>
        <tr><th>9-12</th><td>3 shields</td><th>5-8</th><td>2 shields</td></tr>
      </tbody>
    </table>
    <div class="comments"><strong>Teacher comments and next steps:</strong></div>
  </section>
</body>
</html>
'@

  $replacements = @{
    '__PART1_EXAMINER__' = $Images.Part1Examiner
    '__PART1_CANDIDATE__' = $Images.Part1Candidate
    '__STORY1__' = $Images.Story1
    '__STORY2__' = $Images.Story2
    '__STORY3__' = $Images.Story3
    '__STORY4__' = $Images.Story4
  }
  foreach ($key in $replacements.Keys) {
    $template = $template.Replace($key, [string]$replacements[$key])
  }
  return $template
}

$script:AudioOverrideCacheDir = Join-Path $PSScriptRoot '_generated_audio_overrides'
$script:AudioVoiceModeVersion = 'dialog-voices-v2-no-labels'

function ConvertTo-SapiDialogueXml {
  param([string]$Text)

  $femaleLabels = @(
    'Aunt Maria','Grandma Rose','Mrs Chen','Nurse Ayse',
    'Girl','Woman','Teacher','Mother','Librarian',
    'Maya','Ella','Leyla','Zoe','Alice','Elif','Sara','Nisa','Ece','Zeynep','Irem','Maria','Akiko','Elena','Nina','Hana','Petra','Defne','Lucy','Mia','Emma','Sarah'
  )
  $maleLabels = @(
    'Grandpa Jack','Cousin Ben','Officer Kaya','Mr Demir',
    'Boy','Man','Guide','Student',
    'Tom','Ben','Marcus','Kerem','Emir','Murat','Deniz','Baran','Ali','Sam','Carlos','Jake','Harry','Jack'
  )
  $narratorLabels = @('Narrator','Speaker 1','Speaker 2','Speaker 3','Speaker 4','Speaker 5')
  $allLabels = @($femaleLabels + $maleLabels + $narratorLabels) | Sort-Object Length -Descending -Unique
  $pattern = '(?<![A-Za-z])(' + (($allLabels | ForEach-Object { [regex]::Escape($_) }) -join '|') + '):'

  $matches = [regex]::Matches($Text, $pattern)
  if ($matches.Count -eq 0) {
    return '<sapi><voice required="Gender=Female;Language=409">' + [System.Security.SecurityElement]::Escape($Text) + '</voice></sapi>'
  }

  $parts = New-Object System.Collections.Generic.List[string]
  $cursor = 0
  for ($matchNumber = 0; $matchNumber -lt $matches.Count; $matchNumber++) {
    $match = $matches[$matchNumber]
    if ($match.Index -gt $cursor) {
      $plain = $Text.Substring($cursor, $match.Index - $cursor).Trim()
      if ($plain) {
        $parts.Add('<voice required="Gender=Male;Language=409">' + [System.Security.SecurityElement]::Escape($plain) + '</voice>')
      }
    }

    $label = $match.Groups[1].Value
    $start = $match.Index + $match.Length
    $nextMatchIndex = $Text.Length
    $nextIndex = $matchNumber + 1
    if ($nextIndex -lt $matches.Count) {
      $nextMatchIndex = $matches[$nextIndex].Index
    }
    $line = $Text.Substring($start, $nextMatchIndex - $start).Trim()
    if ($line) {
      $gender = 'Male'
      if ($femaleLabels -contains $label) { $gender = 'Female' }
      elseif ($maleLabels -contains $label) { $gender = 'Male' }
      elseif ($label -match 'Speaker (2|4)') { $gender = 'Female' }
      $parts.Add('<voice required="Gender=' + $gender + ';Language=409">' + [System.Security.SecurityElement]::Escape($line) + '</voice>')
    }
    $cursor = $nextMatchIndex
  }

  if ($cursor -lt $Text.Length) {
    $tail = $Text.Substring($cursor).Trim()
    if ($tail) {
      $parts.Add('<voice required="Gender=Male;Language=409">' + [System.Security.SecurityElement]::Escape($tail) + '</voice>')
    }
  }

  return '<sapi>' + (($parts.ToArray()) -join '<silence msec="130"/>') + '</sapi>'
}

function Get-AudioOverrideBytes {
  param(
    [string]$RelativePath,
    [string]$Text
  )

  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  if (-not (Test-Path -LiteralPath $script:AudioOverrideCacheDir)) {
    New-Item -ItemType Directory -Path $script:AudioOverrideCacheDir | Out-Null
  }

  $sha = [System.Security.Cryptography.SHA1]::Create()
  try {
    $hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($script:AudioVoiceModeVersion + "`n" + $Text))
  } finally {
    $sha.Dispose()
  }
  $hash = ([BitConverter]::ToString($hashBytes) -replace '-', '').Substring(0, 12).ToLowerInvariant()
  $safeName = ($RelativePath -replace '[\\/:*?"<>|]', '_')
  $cachePath = Join-Path $script:AudioOverrideCacheDir ($safeName + '_' + $hash + '.wav')
  if (Test-Path -LiteralPath $cachePath) {
    return [System.IO.File]::ReadAllBytes($cachePath)
  }

  $tmpPath = Join-Path $env:TEMP ('bayetav_tts_' + [Guid]::NewGuid().ToString('N') + '.wav')
  try {
    $voice = New-Object -ComObject SAPI.SpVoice
    foreach ($candidate in @($voice.GetVoices())) {
      $description = $candidate.GetDescription()
      if ($description -match 'English|David|Zira|Microsoft') {
        $voice.Voice = $candidate
        break
      }
    }
    $voice.Rate = 0
    $voice.Volume = 100

    $stream = New-Object -ComObject SAPI.SpFileStream
    try {
      $stream.Open($tmpPath, 3, $false)
      $voice.AudioOutputStream = $stream
      $dialogXml = ConvertTo-SapiDialogueXml -Text $Text
      [void]$voice.Speak($dialogXml, 8)
    } finally {
      $stream.Close()
    }

    Copy-Item -LiteralPath $tmpPath -Destination $cachePath -Force
    return [System.IO.File]::ReadAllBytes($cachePath)
  } catch {
    Write-Warning ("Could not generate TTS override for {0}: {1}" -f $RelativePath, $_.Exception.Message)
    return $null
  } finally {
    if (Test-Path -LiteralPath $tmpPath) {
      Remove-Item -LiteralPath $tmpPath -Force -ErrorAction SilentlyContinue
    }
  }
}

function ConvertTo-HarderExamHtml {
  param(
    [string]$File,
    [string]$Html
  )

  $out = $Html

  if ($File -like 'flyers_exam*_duzeltilmis.html') {
    $out = $out.Replace(
      'Look and read. Choose the correct words and write them on the lines.',
      'Look and read carefully. Choose the correct words and write them on the lines. Some clues include extra detail, so read the whole sentence.'
    )
    $out = $out.Replace(
      'This person is the son or daughter of your aunt or uncle.',
      'This person is in your family, but not your brother or sister; they are the child of your aunt or uncle.'
    )
    $out = $out.Replace(
      'This is a large area with many trees where wild animals live.',
      'This is a large natural area where many trees grow close together and wild animals can live without many people around.'
    )
    $out = $out.Replace(
      'You put meat, cheese or vegetables between two pieces of bread to make this.',
      'You make this by putting meat, cheese or vegetables between two pieces of bread, often when you need an easy lunch.'
    )
    $out = $out.Replace(
      'This is the biggest land animal. It has a long trunk and big ears.',
      'This very large land animal uses its long trunk to drink, smell and pick things up.'
    )
    $out = $out.Replace(
      'This is a place in a school or city where you can read and borrow books.',
      'This quiet place in a school or city lets people borrow books, read information and sometimes use computers for research.'
    )
    $out = $out.Replace(
      'This tells you what food to use and how to cook something.',
      'This gives ingredients and step-by-step instructions so someone can cook the same dish successfully.'
    )
    $out = $out.Replace(
      'This person helps you when your teeth hurt. You should visit them twice a year.',
      'This person checks your teeth, explains how to keep them healthy and helps you if one of them hurts.'
    )
    $out = $out.Replace(
      'This is a large area of water with land all around it. People swim and fish here.',
      'This is an area of water surrounded by land; people may swim, fish or travel across it in small boats.'
    )
    $out = $out.Replace(
      'You put your clothes and things in this when you go on holiday.',
      'You pack clothes, shoes and other things inside this before you travel, especially if you are staying away for several nights.'
    )
    $out = $out.Replace(
      'This goes over a river so that people and cars can cross to the other side.',
      'This structure is built over a river, road or railway so people and vehicles can cross safely.'
    )
    $out = $out.Replace(
      'This is a very old, large building. Kings and queens lived in them long ago.',
      'This large historic building often had strong walls because kings, queens or important families lived there long ago.'
    )
    $out = $out.Replace(
      'Write <b>20 or more words</b>.',
      'Write <b>45 or more words</b>. Use because, when, so and one sentence that explains how a person feels.'
    )
    $out = $out.Replace(
      'Part 6  Read the text. Choose the right words from the box and write them next to 16.',
      'Part 6  Read the whole text first. Choose the right words from the box and write them next to 16.'
    )
    $out = $out.Replace(
      'Wild animals are important <b>(1)</b><span class="gap-line">&nbsp;</span> they help keep nature healthy. There are <b>(2)</b><span class="gap-line">&nbsp;</span> different animals in forests, oceans and deserts around the world.<br><br>     <b>(3)</b><span class="gap-line">&nbsp;</span> animals, like pandas and polar bears, are in danger. People <b>(4)</b><span class="gap-line">&nbsp;</span> protect these animals and their homes. Forests have more animals <b>(5)</b><span class="gap-line">&nbsp;</span> cities. <b>(6)</b><span class="gap-line">&nbsp;</span> wild animals need trees, rivers and clean air to live.',
      'Wild animals are important <b>(1)</b><span class="gap-line">&nbsp;</span> each one has a job in nature. There are <b>(2)</b><span class="gap-line">&nbsp;</span> different animals in forests, oceans and deserts, but not all of them are safe.<br><br>     <b>(3)</b><span class="gap-line">&nbsp;</span> animals, like pandas and polar bears, are in danger because their homes are changing. People <b>(4)</b><span class="gap-line">&nbsp;</span> protect these animals before the problem becomes worse. Forests usually have more animals <b>(5)</b><span class="gap-line">&nbsp;</span> busy cities because they offer food, water and shelter. <b>(6)</b><span class="gap-line">&nbsp;</span> wild animals need most is a clean, quiet place to live.'
    )
    $out = $out.Replace(
      'Travelling is <b>(1)</b><span class="gap-line">&nbsp;</span> exciting when you visit new places and learn about different cultures. <b>(2)</b><span class="gap-line">&nbsp;</span> people prefer beaches, but others like mountains or big cities.<br><br>     Before you travel, you <b>(3)</b><span class="gap-line">&nbsp;</span> always pack a suitcase with warm and cool clothes <b>(4)</b><span class="gap-line">&nbsp;</span> the weather can change quickly. Turkey has <b>(5)</b><span class="gap-line">&nbsp;</span> beautiful places to visit <b>(6)</b><span class="gap-line">&nbsp;</span> most other countries.',
      'Travelling is <b>(1)</b><span class="gap-line">&nbsp;</span> exciting when you visit new places, compare different cultures and solve small problems by yourself. <b>(2)</b><span class="gap-line">&nbsp;</span> people prefer beaches, but others choose mountains or old cities.<br><br>     Before you travel, you <b>(3)</b><span class="gap-line">&nbsp;</span> always pack clothes for different weather <b>(4)</b><span class="gap-line">&nbsp;</span> conditions can change quickly. Turkey has <b>(5)</b><span class="gap-line">&nbsp;</span> historical places, natural areas and modern cities to visit <b>(6)</b><span class="gap-line">&nbsp;</span> many travellers expect.'
    )
  }

  if ($File -like 'ket_test*_exam.html') {
    $out = $out.Replace(
      'For each question, choose the correct answer.',
      'For each question, choose the correct answer. Read the whole notice or message carefully because two options may look possible.'
    )
    $out = $out.Replace(
      'Read the text about three people and their unusual jobs. For each question, choose the correct answer.',
      'Read the text about three people and their unusual jobs. Scan for exact details and implied information. For each question, choose the correct answer.'
    )
    $out = $out.Replace(
      'Tom takes photos of wild animals for nature magazines. He travels to forests and oceans around the world. He sometimes waits for hours in the dark to get the perfect photo of a nocturnal animal. Tom says, "My job is dangerous sometimes, but I love it. Last month, I was in the jungle for three weeks to photograph jaguars."',
      'Tom takes photos of wild animals for nature magazines, but his work is not only about taking beautiful pictures. He travels to forests and oceans, studies animal behaviour and sometimes waits for hours in the dark before a nocturnal animal appears. Tom says, "My job can be risky because one mistake may frighten an animal or put me in danger, but careful preparation makes the photograph more honest."'
    )
    $out = $out.Replace(
      'Priya studies creatures that live deep in the ocean. She dives underwater to observe animals that create their own light, called bioluminescence. She works at a research centre and teaches students about ocean life. "I became interested in the sea when I was a child," she says. "Protecting ocean animals is the most important part of my job."',
      'Priya studies creatures that live deep in the ocean. She observes animals that create their own light, called bioluminescence, and compares her notes with data from underwater cameras. She works at a research centre and teaches students why ocean protection depends on evidence, not just emotion. "I became interested in the sea when I was a child," she says, "but now I want people to understand how fragile it is."'
    )
    $out = $out.Replace(
      'Daniel designs parks and green spaces in big cities. He works with architects and communities to build places where people and nature can share space. He says, "Cities need more trees and gardens. I want to help people connect with nature, even in the middle of a busy city."',
      'Daniel designs parks and green spaces in big cities. He works with architects, local families and transport planners, so his designs must solve several problems at once: shade, safety, noise and wildlife. He says, "Cities need more trees and gardens, but a successful park also has to help people move, rest and meet each other."'
    )
    $out = $out.Replace(
      'Yuki loves making videos. She uses her tablet to record short films about fashion and shares them on the internet. She has been interested in clothes and accessories since she was very young. "My grandmother taught me how to make jewellery when I was eight," she says. "Now I combine old and new styles in my videos. I think mixing traditional and modern fashion is really cool."',
      'Yuki creates short fashion videos for an online audience, but she plans each one like a small research project. She compares old family photographs with modern street styles and explains why certain colours or accessories become popular again. "My grandmother taught me how to make jewellery when I was eight," she says. "Now I try to show that traditional design can still feel modern if you present it carefully."'
    )
    $out = $out.Replace(
      'Matteo is crazy about music apps. He downloads different sounds and mixes them together on his smartphone to create new songs. He prefers electronic music but also likes traditional instruments. "I love combining old instruments like the guitar with modern electronic beats," he says. "My dream is to produce music for films in the future."',
      'Matteo uses music apps to build short soundtracks on his smartphone. He records ordinary sounds, changes their speed and mixes them with electronic beats and traditional instruments. "A film scene feels different if the music changes," he says. "My dream is to produce music for films, so I practise making old instruments sound new without losing their character."'
    )
    $out = $out.Replace(
      'Suki uses her laptop to learn about history. She reads online articles about ancient civilisations and watches documentaries about how people lived hundreds of years ago. "I think the past is fascinating," she says. "I''ve learned that people in the past were very clever. They invented things we still use today. I want to become an archaeologist one day."',
      'Suki uses her laptop to investigate ancient civilisations. She does not only watch documentaries; she compares maps, museum photographs and short articles to understand how people lived hundreds of years ago. "The past is fascinating because it changes the way I look at everyday objects," she says. "I want to become an archaeologist and study old places before their stories disappear."'
    )
    $out = $out.Replace(
      'Read the text and answer the questions. For each question, choose the correct answer (A, B or C).',
      'Read the text and answer the questions. For each question, choose the correct answer (A, B or C). Some answers require inference, not only finding the same words.'
    )
    $out = $out.Replace(
      'In July 2019, London became the world''s first National Park City. This doesn''t mean London is a traditional national park like those in the countryside. Instead, it is a new idea that encourages people to make cities greener, healthier and wilder.<br><br>    The idea came from a geography teacher called Daniel Raven-Ellison. He walked across London and noticed that more than 47% of the city was already green  parks, gardens, rivers and even trees growing along streets. He thought, "Why not celebrate this and try to make it even better?"<br><br>    The National Park City plan asks everyone to help. Schools plant trees, communities create small gardens, and people build homes for birds and insects on their balconies. There are also events like night walks in parks to see urban wildlife  foxes, bats and owls that come out after dark.<br><br>    Not everyone agreed with the idea at first. Some people thought it was strange to call a city a "national park." But Daniel says it is working. Since 2019, thousands of new trees have been planted, and more people are spending time outdoors.',
      'In July 2019, London became the world''s first National Park City. This does not mean London suddenly became a traditional national park like those in the countryside. Instead, the title asks people to look at an ordinary city differently and to make it greener, healthier and wilder through small decisions.<br><br>    The idea came from a geography teacher called Daniel Raven-Ellison. While walking across London, he noticed that more than 47% of the city was already green: parks, gardens, rivers and even trees growing beside roads. He argued that people protect places more willingly when they recognise their value first.<br><br>    The National Park City plan asks everyone to help. Schools plant trees, communities create small gardens, and people build homes for birds and insects on balconies. There are also night walks where people learn to notice urban wildlife such as foxes, bats and owls.<br><br>    Not everyone agreed at first. Some people thought the name was misleading because London is still noisy, crowded and full of traffic. However, Daniel says the phrase is useful because it changes the question from "Is this a park?" to "How can this city become better for people and nature?"'
    )
    $out = $out.Replace(
      'School uniforms have been part of education for hundreds of years. The first school uniforms appeared in England in the 16th century. Students at Christ''s Hospital School in London wore long blue coats, and the school still uses a similar uniform today.<br><br>    For many years, only rich children wore school uniforms. In the 19th century, uniforms became more common in schools across Britain. By the 20th century, most schools in the UK had some kind of dress code. Other countries, including Japan, Australia and many African nations, also introduced uniforms.<br><br>    Some people believe uniforms are a good idea because all students look the same, so nobody feels different because of their clothes. Uniforms can also be cheaper than buying fashionable clothes for school every year. However, other people think students should be free to choose what they wear. They say clothes are a way to express your personality.<br><br>    Today, the debate about school uniforms continues. Some schools are making their uniforms more modern and comfortable, using better fabrics and allowing students to choose between trousers and skirts.',
      'School uniforms have been part of education for hundreds of years. The first school uniforms appeared in England in the 16th century, when students at Christ''s Hospital School in London wore long blue coats. The school still uses a similar uniform today, which shows how clothing can become part of a school''s identity.<br><br>    For many years, only children from wealthy families wore school uniforms. In the 19th century, uniforms became more common across Britain, and by the 20th century most schools in the UK had some kind of dress code. Other countries, including Japan, Australia and many African nations, introduced uniforms for different reasons.<br><br>    Supporters say uniforms can make students feel equal and may cost less than buying fashionable clothes every year. However, critics argue that clothes help young people express personality and culture. They also point out that a uniform is not automatically fair if it is expensive or uncomfortable.<br><br>    Today, the debate continues. Some schools are not removing uniforms completely, but they are changing fabrics, colours and rules so students can feel more comfortable while still looking like part of the same community.'
    )
    $out = $out.Replace(
      'Write <b>25 words or more</b>.',
      'Write <b>70 words or more</b>. Include a reason, one contrast and one specific example.'
    )
    $out = $out.Replace(
      'Write <b>35 words or more</b>.',
      'Write <b>90 words or more</b>. Include a problem, a decision and a clear ending.'
    )
  }

  return $out
}

$zip = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
  $certificateLogoPath = 'C:\Users\User\Desktop\indir.png'
  $certificateLogoUri = ''
  if (Test-Path -LiteralPath $certificateLogoPath) {
    $certificateLogoUri = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes($certificateLogoPath)) -Mime 'image/png'
  }

  $flyers2SpeakingImages = @{
    Part1Examiner = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes('C:\Users\User\Downloads\Gemini_Generated_Image_j4rzppj4rzppj4rz.png')) -Mime 'image/png'
    Part1Candidate = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes('C:\Users\User\Downloads\Gemini_Generated_Image_pg4t0ppg4t0ppg4t.png')) -Mime 'image/png'
    Story1 = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes('C:\Users\User\Downloads\Gemini_Generated_Image_1bfcf51bfcf51bfc.png')) -Mime 'image/png'
    Story2 = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes('C:\Users\User\Downloads\Gemini_Generated_Image_9ser5w9ser5w9ser.png')) -Mime 'image/png'
    Story3 = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes('C:\Users\User\Downloads\Gemini_Generated_Image_lhvea2lhvea2lhve.png')) -Mime 'image/png'
    Story4 = New-DataUri -Bytes ([System.IO.File]::ReadAllBytes('C:\Users\User\Downloads\Gemini_Generated_Image_7c2c9i7c2c9i7c2c.png')) -Mime 'image/png'
  }

  $html = Read-ZipEntryText -Zip $zip -Name 'bayetav_cambridge_exam.html'
  $html = ConvertTo-CertificatePackHtml -Html $html -LogoUri $certificateLogoUri

  $html = $html.Replace(
    '        subtitle: "Colour Matters - Feeling Good? - Your Virtual Self - Underwater Mysteries",',
    '        subtitle: "Colour Perception - Cognitive Health - Digital Identity - Ocean Evidence",'
  )
  $html = $html.Replace(
    '        focus: "colour, health, digital life, underwater discovery",',
    '        focus: "visual perception, health evidence, digital identity, ocean research and critical evaluation",'
  )
  $html = $html.Replace(
    '        subtitle: "Life in the Extreme - Are You Going to Eat That? - Art in the Open - Don''t Panic!",',
    '        subtitle: "Extreme Adaptation - Food Systems - Public Space - Risk Communication",'
  )
  $html = $html.Replace(
    '        focus: "extreme environments, food waste, public art, survival and preparation",',
    '        focus: "adaptation, food systems, civic art, emergency planning and public communication",'
  )

  $html = $html.Replace(
    '        .notice-card,.text-card,.candidate-card{border:1px solid var(--line);background:var(--soft);padding:10px;margin:8px 0}',
    '        .notice-card,.text-card,.candidate-card{border:1px solid var(--line);background:var(--soft);padding:10px;margin:8px 0}' + "`r`n" +
    '        .poster-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px;margin-top:12px}' + "`r`n" +
    '        .poster-notice{border:2px solid var(--line);background:#fff;border-radius:10px;overflow:hidden;break-inside:avoid}' + "`r`n" +
    '        .poster-frame{min-height:116px;display:flex;align-items:center;justify-content:center;text-align:center;padding:16px;background:linear-gradient(180deg,#f8fbff,#eef5fb);border-bottom:1px solid var(--line);font-weight:800;font-size:18px;line-height:1.18;letter-spacing:.02em;color:var(--blue)}' + "`r`n" +
    '        .poster-frame.warning{background:linear-gradient(180deg,#fff7ed,#ffedd5);color:#9b1c1c}' + "`r`n" +
    '        .poster-frame.green{background:linear-gradient(180deg,#f0fdf4,#dcfce7);color:#1f7a4d}' + "`r`n" +
    '        .poster-body{padding:12px}' + "`r`n" +
    '        .poster-body .question{margin:8px 0 6px;font-weight:700}' + "`r`n" +
    '        @media(max-width:760px){.poster-grid{grid-template-columns:1fr}}'
  )
  $html = $html.Replace(
    '${set.notices.map((item, index) => `<div class="notice-card"><strong>${index + 1}.</strong><p>${escapeHtml(item.text)}</p><p class="question">${escapeHtml(item.question)}</p>${optionList(item.options)}</div>`).join("")}',
    '<div class="poster-grid">${set.notices.map((item, index) => `<article class="poster-notice"><div class="poster-frame ${index % 3 === 1 ? "warning" : index % 3 === 2 ? "green" : ""}"><span>${escapeHtml(item.text)}</span></div><div class="poster-body"><strong>Question ${index + 1}</strong><p class="question">${escapeHtml(item.question)}</p>${optionList(item.options)}</div></article>`).join("")}</div>'
  )
  $html = $html.Replace(
    'Slightly harder A2+/early B1 challenge based on Impact 2 topics.',
    'B1 challenge practice based on Impact 2 topics, with denser texts, inference, distractors and extended writing.'
  )
  $html = $html.Replace(
    '<h2>Reading and Writing Part 2 - Multiple Matching</h2>',
    '<h2>Reading and Writing Part 2 - Skimming and Scanning</h2>'
  )
  $html = $html.Replace(
    '<p>Read about three people or teams. For questions ${p2Start}-13, choose the correct letter: ${escapeHtml(profileLetters)}.</p>',
    '<p>Skim the three longer project profiles first to identify each writer''s main purpose. Then scan for precise details, implied attitudes and evidence. For questions ${p2Start}-13, choose the correct letter: ${escapeHtml(profileLetters)}.</p>'
  )
  $html = $html.Replace(
    '<h2>Reading and Writing Part 6 - Guided Writing</h2>' + "`r`n" +
    '            <p>${escapeHtml(set.writing.email)}</p>' + "`r`n" +
    '            <div class="writing-box"></div>',
    '<h2>Reading and Writing Part 6 - Guided Writing</h2>' + "`r`n" +
    '            <p>${escapeHtml(set.writing.email)}</p>' + "`r`n" +
    '            <div class="notice-card"><strong>Example opening:</strong><p>${escapeHtml(set.writing.example)}</p></div>' + "`r`n" +
    '            <div class="writing-box"></div>'
  )
  $html = [regex]::Replace(
    $html,
    '(<h2>Reading and Writing Part 6 - Guided Writing</h2>\s*<p>\$\{escapeHtml\(set\.writing\.email\)\}</p>\s*)<div class="writing-box"></div>',
    '$1<div class="notice-card"><strong>Example opening:</strong><p>${escapeHtml(set.writing.example)}</p></div><div class="writing-box"></div>',
    1
  )
  $html = $html.Replace(
    '          <section class="part">' + "`r`n" +
    '            <h2>Reading and Writing Part 1 - Multiple Choice</h2>',
    '          <section class="part">' + "`r`n" +
    '            <h2>Reading and Writing Part 1 - Notice and Poster Reading</h2>'
  )

  $impact2ChallengePatch = @'
    (function strengthenImpact2KET(){
      if (!impact2KetData) return;
      impact2KetData[1].listening.part1.script = "Narrator: You will hear five short conversations. Choose the best answer. One. Which poster does Maya choose? Maya: The red poster is bright, but the club used almost the same colour last year. The green one looks calm, but people may not notice it from the door. Teacher: So which one helps students see the announcement quickly? Maya: The blue poster. It is not my favourite colour, but it is the clearest for the corridor. Two. What should students do after twenty minutes? Boy: Do we close the laptops after twenty minutes? Girl: Not exactly. We still need them later. The teacher said our eyes need a short rest, so we look away from the screen for a minute and then continue. Boy: So the answer is not stop working, just take a screen break. Three. What happens before the camera demonstration? Guide: Some students want to try the camera first, but the equipment room is small. We will walk around the exhibition and notice three examples of light and shadow. After that, the technician will show the camera. Four. What does the librarian give the students? Student: I lost my card. Librarian: Your old card will work next week, but today you need this temporary code. Write it carefully because the computer will ask for it before you print. Five. What must students complete at the end? Teacher: Do not leave after the last presentation. I do not need your notebooks, and the posters can stay on the wall. Before you go, answer the short questionnaire on your desks. Narrator: Now listen again.";
      impact2KetData[1].listening.part2.script = "Narrator: You will hear a teacher talking about Science Week. Listen and write one word or a number for each question. Teacher: Next month is Science Week. I nearly wrote Science Day on the first notice, but it is longer than one day, so please write Week. The main display will not be in the hall because exams are there. It will be in the library, where visitors can read the project notes. On Tuesday, a nurse is coming to speak about sleep and health. I asked a doctor first, but the clinic is busy. Students who want to enter the quiz need a card from reception, not a ticket. Bring your own notebook too, because the school will not provide paper for your observations. Narrator: Now listen again.";
      impact2KetData[1].listening.part3.script = "Narrator: You will hear two students discussing a digital safety project. For each question, choose A, B or C. Tom: I thought our project should be about passwords. Ella: Passwords are useful, but everyone already says that. The article about fake profiles is stronger because students have to decide whether a message feels reliable. Tom: So the main topic is judging online information. Ella: Yes. For the first activity, we should show two screenshots. One looks friendly, but the details do not match. Tom: Good. The teacher asked for evidence, so we need examples, not just opinions. Ella: And at the end, students should write one rule they will actually use. Tom: Should we tell them to delete all social media? Ella: That sounds dramatic, but unrealistic. Better to make them pause before they answer strange messages. Narrator: Now listen again.";
      impact2KetData[1].listening.part4.script = "Narrator: You will hear five people talking about a school exhibition. For each speaker, choose the correct answer. Speaker 1: I expected the colour display to be only artistic, but the notes about light changed my mind. The picture was real, yet it made the fish look safer than its habitat. Speaker 2: The survey corner was useful because it showed numbers and comments together. One without the other would not explain why students felt calmer. Speaker 3: I liked the online identity section most. It did not simply say, Be careful. It showed why a message can seem normal and still be false. Speaker 4: The camera demonstration came after the tour, which helped me understand it. Before that, I had not noticed how much distance changes an image. Speaker 5: The final questionnaire was short, but it made me change my first answer about two posters. I realised I had looked quickly and missed the evidence. Narrator: Now listen again.";
      impact2KetData[1].listening.part5.script = "Narrator: You will hear a teacher telling students which topics to match with projects. Teacher: Project A is not simply about pretty posters. It explains how colours persuade people in advertising, so match it with Colours in advertising. Project B begins with tired students, but the real focus is what sleep does to concentration and health. Project C uses messages and screenshots to help students recognise unsafe digital situations, so choose Digital safety. Project D has underwater photographs, yet it is not about holidays. It asks how scientists discover and record life under the sea. Project E looks at feelings, memory and decisions, which means the topic is Brain and emotions. Narrator: Now listen again.";

      impact2KetData[2].listening.part1.script = "Narrator: You will hear five short conversations. Choose the best answer. One. Which bag will Emir take? Emir: The small bag is easier to carry, but my boots do not fit. The old rucksack is strong, yet the zip sticks. I will use the blue hiking bag because it has space for the extra jacket. Two. What should students bring to the lab? Teacher: You can leave your lunch in the classroom, and you do not need coloured pens. The lab notes are already printed. What you must bring is your safety card, because the assistant will check it at the door. Three. Which meal is chosen for the project? Girl: Salad wastes less energy, but it does not use the imperfect vegetables well. Sandwiches are quick, but the bread is the problem this week. Soup lets us use the vegetables and explain food waste clearly. Four. Where will the public art be placed? Man: The gate is too crowded, and the gym wall is being repaired. The best place is near the cafeteria entrance, because everyone passes it after lunch. Five. What does the teacher want students to improve? Teacher: The story has a good ending, and the drawings are clear enough. What is missing is the warning. Readers should understand the danger before the last sentence. Narrator: Now listen again.";
      impact2KetData[2].listening.part2.script = "Narrator: You will hear a notice about Project Week. Listen and write one word or a number for each question. Teacher: Our next event is Project Week. It is not a single afternoon, because each team needs time to collect evidence. The rescue recipe team will work in the food lab, not the normal classroom, because they need sinks and tables. On Wednesday an artist is visiting to advise the public art group. The cafeteria team will test a warm soup recipe using vegetables that are usually rejected. Finally, anyone joining the emergency walk must wear strong shoes. Trainers are fine if they have a good grip, but sandals are not allowed. Narrator: Now listen again.";
      impact2KetData[2].listening.part3.script = "Narrator: You will hear two students planning a food waste display. For each question, choose A, B or C. Leyla: I do not want our display to look like a recipe page. Kerem: But the soup is the thing visitors can taste. Leyla: True, but the main point is why people throw good food away. We should show the data first. Kerem: The number of sandwiches from one week? Leyla: Yes. It feels more serious than a general sentence about waste. Kerem: Should we put funny drawings around it? Leyla: Maybe one or two, but the message should interrupt people a little. If it is too cheerful, they will not think about their habits. Kerem: So evidence first, design second, and a short story to make it personal. Narrator: Now listen again.";
      impact2KetData[2].listening.part4.script = "Narrator: You will hear five people talking about school projects. For each speaker, choose the correct answer. Speaker 1: The mountain group surprised me. Their best point was not the equipment list but how tired people make poor decisions. Speaker 2: I thought food waste meant careless students, but the cafeteria records showed timing and signs mattered too. Speaker 3: The mural felt uncomfortable at first. Then I understood why; it was supposed to make us notice a warning we usually ignore. Speaker 4: The recipe team was honest. They did not claim soup could solve everything, only that repeated small choices can help. Speaker 5: The emergency story worked because the danger appeared before the ending. I had to infer what the character should do next. Narrator: Now listen again.";
      impact2KetData[2].listening.part5.script = "Narrator: You will hear a teacher explaining which topics to match with projects. Teacher: Project A compares animals that survive in deserts, mountains and cold places, so the correct topic is Extreme animals. Project B studies what happens to uneaten meals in the cafeteria; choose Food waste. Project C is not ordinary painting. It uses murals in public places to send a message, so match it with Public art. Project D prepares students for storms, blocked roads and emergency choices, which is Disaster preparation. Project E tells very short stories where the ending is implied rather than explained, so choose Flash fiction. Narrator: Now listen again.";

      impact2KetData[1].listening.part1.script = "Narrator: You will hear five short conversations. Choose the best answer. One. Which poster does Maya choose? Teacher: Three posters are on the table. The red one is easy to notice, but several classes used red last term. Maya: I liked the green one at first because it matches the plants in our display. Teacher: It looks nice close up, but from the corridor it disappears into the background. Maya: The yellow one is too bright, so students may not read the details. Teacher: Then your final choice is the one that is clear from far away, even if it is not the most exciting. Maya: Right. I will take the blue poster. Two. What should students do after twenty minutes? Boy: The rule says twenty minutes. Does that mean closing the laptops? Girl: I thought so, but the teacher only closed hers to show us. Boy: So should we make the screen darker? Girl: That helps a little, but it is not the instruction. We keep our work open, look away from the screen, rest our eyes for a short moment, and then continue. Three. What happens before the camera demonstration? Guide: The camera box is ready, but we are not starting there. Boy: I saw the sign for the tanks at two o'clock and the camera at half past two. Guide: Exactly. If you see the tanks first, the demonstration will make sense. The tour comes before the camera. Four. What does the librarian give the students? Student: I tried my old password and then my library card number. Librarian: Neither will help today. Your account is being moved to the new system. Student: So how do I get in now? Librarian: Use this temporary code just for today. Five. What must students complete at the end? Teacher: You may leave the posters on the wall and keep your notebooks. The short talk is already recorded. Student: Are we writing a summary? Teacher: No. Before you go, answer the questionnaire on your desk, because I need your opinions for next week. Narrator: Now listen again.";
      impact2KetData[1].listening.part2.script = "Narrator: You will hear a teacher talking about Science Week. Listen and write one word or a number for each question. Teacher: I need to correct yesterday's notice. It said Science Day, but there are activities from Monday to Friday, so the correct word is Week. The display was going to be in the hall, then we remembered the music exams. It is not moving to the computer room either; the final place is the library. On Tuesday, someone from the health centre is coming. We invited a doctor first, but the person who can visit is a nurse. For the quiz, do not bring money or a ticket. You need the small card from reception. Finally, the school has no spare paper this time, so bring a notebook for observations. Narrator: Now listen again.";
      impact2KetData[1].listening.part3.script = "Narrator: You will hear two students discussing a digital safety project. For each question, choose A, B or C. Tom: Our title could be passwords, because that is simple. Ella: Too simple. The teacher wants people to judge information, not repeat rules. Tom: Then fake profiles? Ella: Yes, but not as a warning poster. We should show two screenshots. The first looks safe because the language is friendly. Tom: The second has a strange link. Ella: True, but the important clue is that the details do not match. Tom: So students infer the risk instead of being told. Ella: Exactly. At the end they write one action they will actually use. We are not asking them to delete everything, just to pause before replying. Narrator: Now listen again.";
      impact2KetData[1].listening.part4.script = "Narrator: You will hear five people talking about a school exhibition. For each speaker, choose the correct answer. Speaker 1: I walked past the colour display because I thought it was art. Then I read the last note and realised the shop example was about persuasion, not decoration. Speaker 2: The sleep project first sounded like advice about phones. Only at the end did I understand the key point: where the phone is kept at night changes how quickly people check it. Speaker 3: The digital section showed passwords and profiles, but the speaker's final example mattered most. A normal-looking message can still need checking. Speaker 4: I expected dramatic ocean photos. The last panel was quieter, explaining that scientists must behave carefully around fragile places. Speaker 5: I thought the brain project would use a poster, but the teacher rejected that because the class needed one clear drawing to compare emotions. Narrator: Now listen again.";
      impact2KetData[1].listening.part5.script = "Narrator: You will hear a teacher telling students which topics to match with projects. Teacher: Listen carefully because some projects mention two ideas before the real focus. Elif used posters and shop windows, but her final question is how colour changes what people buy, so her topic is Colours in advertising. Murat talks about phones and homework, but he measures tiredness after different bedtimes; his topic is Sleep and health. Deniz includes passwords at the start, but his project asks how to recognise unsafe messages, so choose Digital safety. Sara's pictures look like travel photos, yet her notes are about how scientists record life below the sea; that is Underwater discovery. Nisa mentions feelings in stories, but her evidence is about memory and decisions, so match her with Brain and emotions. Narrator: Now listen again.";

      impact2KetData[2].listening.part1.script = "Narrator: You will hear five short conversations. Choose the best answer. One. Which place is chosen for the project? Boy: The desert photo is dramatic, and the rainforest one has more colour. Girl: Both are useful, but our question is about how animals save energy in extreme cold. Boy: So the warmer places are only comparisons. Girl: Yes, the final project is the polar place. Two. What food will they use first? Teacher: The soup idea is for the final lesson, and fruit is for the display table. Student: Then what starts the experiment? Teacher: We begin with bread, because the cafeteria throws it away most often. Three. Where do students wait? Girl: At first we said outside the station, but rain is expected. Boy: The bus stop is too far from the entrance. Girl: Then we meet under the station roof, where the teacher can see everyone. Four. What did students do first in the emergency practice? Man: They did not run outside immediately. The alarm was only a practice. First, they looked for the emergency bags and checked which ones were missing. Five. Which story is selected? Teacher: The storm story has strong pictures, and the funny story is easier to read. But the magazine needs one story that shows how people make decisions when things become dangerous. We will use the survival story. Narrator: Now listen again.";
      impact2KetData[2].listening.part2.script = "Narrator: You will hear a notice about Ready Week. Listen and write one word or a number for each question. Teacher: The event is not just on Friday, so please change the title from Ready Day to Ready Week. The first meeting was planned for the classroom, but we need sinks and safety tables; the final room is the lab. A firefighter was invited, but he cannot come. The visitor on Wednesday will be an artist who designs warning pictures for public places. The cafeteria team considered salad, then sandwiches, but the final food they test is soup because it uses the rejected vegetables. For the emergency walk, do not worry about coats today. The important thing is shoes with a safe grip. Narrator: Now listen again.";
      impact2KetData[2].listening.part3.script = "Narrator: You will hear two students planning a food waste presentation. For each question, choose A, B or C. Leyla: If we start with soup, everyone will think it is a cooking project. Kerem: But the recipe is the most visible part. Leyla: Visible, yes, but not the strongest idea. Our first idea is too simple unless we show why food is wasted. Kerem: Then should we use opinions from students? Leyla: Maybe later. The number from school is better for the first slide because it is evidence. Kerem: What about the ending? Leyla: A short comparison, then one action students can try for a week. Kerem: And the picture? Leyla: Not a cartoon. A graph makes the waste harder to ignore. Narrator: Now listen again.";
      impact2KetData[2].listening.part4.script = "Narrator: You will hear five people talking about a unit project. For each speaker, choose the correct answer. Speaker 1: The survival display had maps and boots, but the final explanation was clearest: it showed why small choices matter in dangerous places. Speaker 2: The cafeteria group first blamed students. At the end, their evidence showed the problem begins with how much food is taken first. Speaker 3: I thought the mural was only decoration until the last question asked who should notice a public danger. Then I saw art can start a discussion. Speaker 4: The emergency leader did not sound dramatic. That was the point: speaking calmly helped people understand what to do. Speaker 5: The flash fiction table looked easy, but every ending depended on one useful word. The writer had to remove anything unnecessary. Narrator: Now listen again.";
      impact2KetData[2].listening.part5.script = "Narrator: You will hear a teacher explaining which magazine topic each student will write about. Teacher: Ece mentions mountains and deserts, but her final comparison is between animals that survive difficult habitats, so write Extreme animals. Ali starts with a recipe, but his evidence is about what the cafeteria throws away. His topic is Food waste. Zeynep talks about colours and walls, but the purpose is a message in a shared space, so choose Public art. Baran describes storms, bags and meeting points. Those details belong to Disaster preparation. Irem writes very short stories; the endings are not fully explained, so her topic is Flash fiction. Narrator: Now listen again.";

      impact2KetData[1].profiles.people = [
        { letter: "A", name: "Mina", text: "Mina is designing a calm classroom corner, but her proposal is not simply decorative. She compares short survey results, classroom light levels and students' comments before and after tests. Her teacher has asked her to separate personal opinion from evidence, so Mina now records which changes are measurable and which are only impressions." },
        { letter: "B", name: "Leo", text: "Leo is producing a critical blog about digital identity. He does not want to repeat ordinary safety advice, so he interviews students about how they decide whether a message, image or online profile is reliable. His draft includes examples of misleading screenshots and explains why a strong password is only one part of responsible online behaviour." },
        { letter: "C", name: "Sara", text: "Sara is researching ocean exploration for a school exhibition. She compares underwater photographs, camera notes and scientific reports to decide how much viewers can trust an image. Her project also asks whether researchers should publish dramatic pictures if the lights, angles or editing make fragile habitats look more colourful than they really are." }
      ];
      impact2KetData[1].profiles.questions = [
        "Who distinguishes measurable evidence from personal impressions?",
        "Who is most concerned with whether digital information can be trusted?",
        "Who evaluates how images may influence public understanding of science?",
        "Who uses interviews to analyse decision-making?",
        "Who may need to explain that an attractive image is not always neutral evidence?",
        "Who is testing whether environmental changes affect learners under pressure?",
        "Who challenges advice that is too simple by adding examples and reasons?"
      ];
      impact2KetData[1].article.paragraphs = [
        "When sixteen-year-old Deniz visited a small aquarium, he noticed that the same fish looked grey in one tank and bright blue in another. At first he assumed the difference was caused by the fish themselves. A guide, however, explained that depth, artificial light and camera settings can alter what people think they are seeing. Deniz left with an uncomfortable question: if colour could be changed so easily, how often did he trust an image too quickly?",
        "His school project, The Colour Lab, became more demanding than a normal art display. The class examined warning colours in nature, colour-blindness, advertising and photographs used in ocean documentaries. They discovered that an image can be accurate in one sense and still misleading in another. A photograph may show a real animal, for example, while the lighting encourages viewers to imagine a brighter and safer habitat than the animal actually has.",
        "For the final exhibition, visitors had to make two judgements. First they skimmed short labels to predict the purpose of each image; then they scanned the technical notes to check lighting, distance and editing. Many visitors changed their first answers. Deniz argued that this was the point of the project: careful readers should not reject images, but they should ask what evidence sits behind them."
      ];
      impact2KetData[1].article.questions = [
        { q: "What disturbed Deniz after the aquarium visit?", options: ["He realised images may be trusted too quickly.", "He learned that fish cannot see colour.", "He found the guide's explanation too simple."] },
        { q: "What does the article suggest about photographs?", options: ["They can be real but still shape interpretation.", "They are usually invented by documentary makers.", "They are less reliable than paintings in every case."] },
        { q: "Why did visitors read the technical notes?", options: ["To check whether their first interpretation was supported.", "To learn how to buy underwater cameras.", "To avoid looking at the exhibition labels."] },
        { q: "What changed for many visitors?", options: ["Their judgement after scanning for detail.", "Their ability to draw ocean animals.", "Their opinion about school art lessons."] },
        { q: "What is the writer's main message?", options: ["Critical reading means checking the evidence behind what we see.", "Students should avoid using images in science projects.", "Colour is mainly useful for making exhibitions attractive."] }
      ];
      impact2KetData[1].writing.email = "You are helping to organise a school health and technology day. Write an email to your English friend Alex. In your email, describe the activity you are preparing, explain why it matters for students, and invite Alex to contribute one practical idea. Write about 70 words.";
      impact2KetData[1].writing.example = "Example: Hi Alex, I am preparing a digital balance workshop for our school health day. We will compare screen habits and test short breaks because many students say they feel tired after studying online.";
      impact2KetData[1].writing.story = "Write a short story of about 100 words. Your story must begin with this sentence: When I opened the message, the screen suddenly changed colour.";
      impact2KetData[1].answers.rw = "1 A, 2 B, 3 A, 4 B, 5 A, 6 B, 7 A, 8 B, 9 C, 10 B, 11 C, 12 A, 13 B, 14 A, 15 A, 16 A, 17 A, 18 A, 19 B, 20 A, 21 C, 22 A, 23 B, 24 A, 25 to, 26 that/which, 27 to, 28 for, 29 about, 30 in";

      impact2KetData[2].profiles.people = [
        { letter: "A", name: "Team Summit", text: "Team Summit prepares students for difficult journeys by analysing changing weather reports, equipment limits and the consequences of poor decisions. They are less interested in adventure photographs than in explaining how small mistakes become dangerous when people are tired, cold or overconfident." },
        { letter: "B", name: "Team Waste Less", text: "Team Waste Less studies the school cafeteria as a system. They compare buying records, interview kitchen workers and test whether clearer signs change what students throw away. Their project argues that food waste is not only a personal habit but also the result of design, timing and communication." },
        { letter: "C", name: "Team City Story", text: "Team City Story creates murals and flash fiction about emergencies in public spaces. Their work is designed to make people stop, interpret a warning and discuss who is responsible for safety. They believe public art should sometimes be uncomfortable if it helps a community notice a risk." }
      ];
      impact2KetData[2].profiles.questions = [
        "Which team analyses how confidence can become risky?",
        "Which team treats waste as a problem created by a whole system?",
        "Which team uses discomfort as part of its message?",
        "Which team collects evidence from people who prepare food?",
        "Which team links communication with public responsibility?",
        "Which team focuses on decisions made under difficult physical conditions?",
        "Which team is most likely to test whether signs change behaviour?"
      ];
      impact2KetData[2].article.paragraphs = [
        "Class 8B began with a simple question: why does edible food become rubbish? Their teacher gave each group vegetables that a shop had rejected because they were small, bent or marked. The task sounded easy, but the students soon realised that a recipe alone would not explain the problem. They needed to investigate why people decide that imperfect food has no value.",
        "One group created The Rescue Recipe, a hot soup made from vegetables that would normally be wasted. They connected the recipe to their unit on extreme environments, where planning, calories and warm liquid can affect survival. The group was careful not to exaggerate. Soup would not solve hunger or climate change, they wrote, but it could show how practical choices become meaningful when a community repeats them.",
        "The final display combined data, public art and short fiction. Painted boxes outside the cafeteria showed the number of sandwiches thrown away in a week; next to them, students placed short stories about storms, closed roads and families sharing limited food. Some adults thought the display was too serious for a school gate. The students disagreed. A message about waste, they argued, should interrupt ordinary habits rather than politely decorate them."
      ];
      impact2KetData[2].article.questions = [
        { q: "Why was the original task more complex than it seemed?", options: ["Students had to investigate attitudes, not only cook.", "The vegetables were unsafe to use.", "The shop refused to explain its prices."] },
        { q: "How did the group avoid exaggerating its message?", options: ["They admitted that soup was a small example, not a complete solution.", "They removed all scientific information from the display.", "They asked adults to write the final text."] },
        { q: "What was the purpose of adding data to the display?", options: ["To make the problem visible and specific.", "To prove that stories are unnecessary.", "To advertise the cafeteria menu."] },
        { q: "Why did some adults criticise the display?", options: ["They felt its tone was too serious.", "They thought the paintings were too colourful.", "They could not read the students' handwriting."] },
        { q: "What is the main idea of the article?", options: ["Strong public messages can challenge habits through evidence and design.", "Food projects are only successful when they include recipes.", "Emergency stories should avoid social problems."] }
      ];
      impact2KetData[2].writing.email = "You are preparing an emergency advice display for younger students. Write an email to your English friend Sam. In your email, describe the display, explain what behaviour it should change, and ask Sam for one improvement. Write about 70 words.";
      impact2KetData[2].writing.example = "Example: Hi Sam, I am designing an emergency advice display for younger students. It shows what to do when the second bell rings and why bags should be left behind.";
      impact2KetData[2].writing.story = "Write a short story of about 100 words. Your story must begin with this sentence: The lights went off just as we reached the outdoor art wall.";
      impact2KetData[2].answers.rw = "1 A, 2 B, 3 B, 4 B, 5 A, 6 B, 7 A, 8 B, 9 C, 10 B, 11 C, 12 A, 13 B, 14 A, 15 A, 16 A, 17 A, 18 A, 19 A, 20 A, 21 A, 22 B, 23 A, 24 A, 25 to, 26 that/which, 27 be, 28 to, 29 in, 30 by/before";
    })();

'@
  $html = $html.Replace('    function impact2DocCss() {', $impact2ChallengePatch + '    function impact2DocCss() {')

  $styleInsert = @'
    .single-pack { margin-bottom: 20px; border: 1.5px solid var(--line); background: var(--soft); padding: 16px; }
    .single-pack h2 { margin-bottom: 6px; }
    .single-pack p { margin: 0 0 10px; color: var(--muted); }
    .single-pack ul { margin: 10px 0 0 18px; padding: 0; color: var(--muted); }
    .single-pack li { margin: 4px 0; }
    .difficulty-banner{border:2px solid #7f1d1d;background:#fff7ed;color:#111827;border-radius:12px;padding:16px;margin:0 0 18px}
    .difficulty-banner h2{margin:0 0 8px;color:#7f1d1d;font-size:20px}
    .difficulty-banner p{margin:0 0 8px;color:#374151}
    .difficulty-banner strong{color:#7f1d1d}
'@
  $html = $html.Replace('    .exam-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }', $styleInsert + "`r`n" + '    .exam-grid { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 18px; }')

  $noticeOld = 'Ta&#351;&#305;nabilir kullan&#305;m i&#231;in bu HTML dosyas&#305;n&#305;, yan&#305;ndaki exam HTML dosyalar&#305;n&#305; ve TTS klas&#246;rlerini ayn&#305; klas&#246;rde tutun. Dosyalar ba&#351;ka bilgisayara kopyaland&#305;&#287;&#305;nda s&#305;navlar ve audio player''lar g&#246;reli yollarla &#231;al&#305;&#351;&#305;r.'
  $noticeNew = 'Tek dosyal&#305;k s&#252;r&#252;m: s&#305;nav HTML''leri, speaking bookletler, 3 kitap sistemi ve listening sesleri bu dosyan&#305;n i&#231;ine g&#246;m&#252;ld&#252;. Ba&#351;ka bilgisayara ta&#351;&#305;rken yaln&#305;zca bu HTML dosyas&#305;n&#305; kopyalaman&#305;z yeterlidir.'
  $html = $html.Replace($noticeOld, $noticeNew)

  $nglBytes = Read-ZipEntryBytes -Zip $zip -Name 'ngl_3kitap_entegre_degerlendirme_sistemi.html'
  $nglUri = New-DataUri -Bytes $nglBytes -Mime 'text/html;charset=utf-8'

  $toolbarOld = '      <a class="btn" href="bayetav_cambridge_exam.html" download>BAYETAV Cambridge Exam HTML indir</a>'
  $toolbarNew = '      <a class="btn" href="BAYETAV_TEK_DOSYA.html" download>BAYETAV Cambridge Exam HTML indir</a>' + "`r`n" +
                '      <a class="btn secondary" href="' + $nglUri + '" target="_blank" download="ngl_3kitap_entegre_degerlendirme_sistemi.html">3 Kitap Entegre Sistem a&#231;/indir</a>'
  $html = $html.Replace($toolbarOld, $toolbarNew)

  $singlePackSection = @'
    <section id="singlePack" class="single-pack">
      <h2>Tek HTML Paketi</h2>
      <p>Bu dosya, portable paketteki Cambridge exam ar&#351;ivini, kullan&#305;m notunu, 3 kitap entegre sistemi, s&#305;nav/speaking HTML'lerini ve listening seslerini tek HTML i&#231;inde toplar.</p>
      <div class="actions">
        <a class="btn" href="__NGL_URI__" target="_blank" download="ngl_3kitap_entegre_degerlendirme_sistemi.html">3 Kitap Entegre Sistem</a>
        <a class="btn secondary" href="#scoreTables">Skor tablolar&#305;</a>
      </div>
      <ul>
        <li>Ses oynat&#305;c&#305;lar&#305; WAV dosyalar&#305;n&#305; bu HTML i&#231;inden kullan&#305;r.</li>
        <li>S&#305;nav ve speaking butonlar&#305; i&#231;erikleri bu sayfa i&#231;inde g&#246;sterir veya g&#246;m&#252;l&#252; HTML olarak a&#231;ar.</li>
        <li>Ta&#351;&#305;mak i&#231;in klas&#246;r ya da zip yerine yaln&#305;zca bu dosyay&#305; kopyalay&#305;n.</li>
      </ul>
    </section>

    <section class="difficulty-banner">
      <h2>Zorla&#351;t&#305;r&#305;lm&#305;&#351; S&#305;nav S&#252;r&#252;m&#252;</h2>
      <p><strong>Format korunarak</strong> Flyers s&#305;navlar&#305; A2+, KET ve Impact KET s&#305;navlar&#305; B1 seviyesine yakla&#351;t&#305;r&#305;ld&#305;.</p>
      <p>B&#246;l&#252;m say&#305;s&#305;, soru numaralar&#305; ve Cambridge ak&#305;&#351;&#305; ayn&#305; kal&#305;r; zorluk mevcut metin, y&#246;nerge, se&#231;enek ve writing hedeflerinin i&#231;inde art&#305;r&#305;l&#305;r.</p>
    </section>

'@.Replace('__NGL_URI__', $nglUri)
  $html = [regex]::Replace(
    $html,
    '<main>\s*<section class="exam-grid" aria-label="All exams">',
    '<main>' + "`r`n" + $singlePackSection + '    <section class="exam-grid" aria-label="All exams">',
    1
  )

  $htmlFiles = @(
    'ket_test1_exam.html',
    'ket_test1_speaking_booklet.html',
    'ket_test2_exam.html',
    'ket_test2_speaking_booklet.html',
    'flyers_exam1_duzeltilmis.html',
    'flyers_exam1_speaking_booklet.html',
    'flyers_exam2_duzeltilmis.html',
    'flyers_exam2_speaking_booklet.html',
    'impact2_ket_exam1.html',
    'impact2_ket_exam1_speaking.html',
    'impact2_ket_exam2.html',
    'impact2_ket_exam2_speaking.html',
    'speaking_exam_pack_certificates.html'
  )

  $docFileMap = @{
    'ket_test1_exam.html' = 'ket1-exam'
    'ket_test1_speaking_booklet.html' = 'ket1-speaking'
    'ket_test2_exam.html' = 'ket2-exam'
    'ket_test2_speaking_booklet.html' = 'ket2-speaking'
    'flyers_exam1_duzeltilmis.html' = 'flyers1-exam'
    'flyers_exam1_speaking_booklet.html' = 'flyers1-speaking'
    'flyers_exam2_duzeltilmis.html' = 'flyers2-exam'
    'flyers_exam2_speaking_booklet.html' = 'flyers2-speaking'
    'impact2_ket_exam1.html' = 'impact2ket1-exam'
    'impact2_ket_exam1_speaking.html' = 'impact2ket1-speaking'
    'impact2_ket_exam2.html' = 'impact2ket2-exam'
    'impact2_ket_exam2_speaking.html' = 'impact2ket2-speaking'
    'speaking_exam_pack_certificates.html' = ''
  }

  foreach ($file in $htmlFiles) {
    $bytes = Read-ZipEntryBytes -Zip $zip -Name $file
    if ($file -like '*_exam.html' -or $file -like '*duzeltilmis.html') {
      $docHtml = [System.Text.Encoding]::UTF8.GetString($bytes)
      $docHtml = ConvertTo-HarderExamHtml -File $file -Html $docHtml
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($docHtml)
    } elseif ($file -eq 'flyers_exam2_speaking_booklet.html') {
      $docHtml = New-Flyers2SpeakingBookletHtml -Images $flyers2SpeakingImages
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($docHtml)
    } elseif ($file -eq 'speaking_exam_pack_certificates.html') {
      $docHtml = [System.Text.Encoding]::UTF8.GetString($bytes)
      $docHtml = ConvertTo-CertificatePackHtml -Html $docHtml -LogoUri $certificateLogoUri
      $bytes = [System.Text.Encoding]::UTF8.GetBytes($docHtml)
    }
    $uri = New-DataUri -Bytes $bytes -Mime 'text/html;charset=utf-8'
    $docId = $docFileMap[$file]
    if ($docId) {
      $html = $html.Replace('href="' + $file + '"', 'href="' + $uri + '" data-doc-file="' + $file + '"')
    } else {
      $html = $html.Replace('href="' + $file + '"', 'href="' + $uri + '"')
    }
  }

  $docMapJson = ($docFileMap.GetEnumerator() | Where-Object { $_.Value } | Sort-Object Name | ForEach-Object {
    '"' + $_.Name.Replace('\', '\\').Replace('"', '\"') + '":"' + $_.Value.Replace('\', '\\').Replace('"', '\"') + '"'
  }) -join ','
  $docHandler = @"
    const embeddedDocFiles = {$docMapJson};
    const embeddedImpactAudioFiles = __IMPACT_AUDIO_MAP__;
    function embeddedAudioSrc(path) {
      if (!path) return "";
      const clean = String(path).replace(/\\/g, "/");
      if (embeddedImpactAudioFiles[clean]) return embeddedImpactAudioFiles[clean];
      const nodes = document.querySelectorAll("[data-audio-file]");
      for (const node of nodes) {
        if ((node.dataset.audioFile || "").replace(/\\/g, "/") === clean) {
          const value = node.currentSrc || node.getAttribute("src") || node.href || node.getAttribute("href") || "";
          if (value) return value;
        }
      }
      return path;
    }
    function embeddedAudioMap() {
      const map = Object.assign({}, embeddedImpactAudioFiles);
      document.querySelectorAll("[data-audio-file]").forEach((node) => {
        const key = (node.dataset.audioFile || "").replace(/\\/g, "/");
        const value = node.currentSrc || node.getAttribute("src") || node.href || node.getAttribute("href") || "";
        if (key && value) map[key] = value;
      });
      return map;
    }
    function resolveEmbeddedAssets(html) {
      let resolved = html || "";
      const map = embeddedAudioMap();
      Object.keys(map).sort((a, b) => b.length - a.length).forEach((path) => {
        resolved = resolved.split(path).join(map[path]);
      });
      return standardizeExamDocument(resolved);
    }
    function hardenCambridgeLevel(html) {
      const pairs = [
        ["Look and read. Choose the correct words and write them on the lines.", "Look and read carefully. Choose the correct words and write them on the lines. Some clues include extra detail, so read the whole sentence."],
        ["Write <b>20 or more words</b>.", "Write <b>45 or more words</b>. Use because, when, so and one sentence that explains how a person feels."],
        ["Part 6  Read the text. Choose the right words from the box and write them next to 16.", "Part 6  Read the whole text first. Choose the right words from the box and write them next to 16."],
        ["This person is the son or daughter of your aunt or uncle.", "This person is in your family, but not your brother or sister; they are the child of your aunt or uncle."],
        ["This person helps you when your teeth hurt. You should visit them twice a year.", "This person checks your teeth, explains how to keep them healthy and helps you if one of them hurts."],
        ["For each question, choose the correct answer.", "For each question, choose the correct answer. Read the whole notice or message carefully because two options may look possible."],
        ["Read the text about three people and their unusual jobs. For each question, choose the correct answer.", "Read the text about three people and their unusual jobs. Scan for exact details and implied information. For each question, choose the correct answer."],
        ["Read the text and answer the questions. For each question, choose the correct answer (A, B or C).", "Read the text and answer the questions. For each question, choose the correct answer (A, B or C). Some answers require inference, not only finding the same words."],
        ["Write <b>25 words or more</b>.", "Write <b>70 words or more</b>. Include a reason, one contrast and one specific example."],
        ["Write <b>35 words or more</b>.", "Write <b>90 words or more</b>. Include a problem, a decision and a clear ending."],
        ["Tom takes photos of wild animals for nature magazines. He travels to forests and oceans around the world. He sometimes waits for hours in the dark to get the perfect photo of a nocturnal animal. Tom says, \"My job is dangerous sometimes, but I love it. Last month, I was in the jungle for three weeks to photograph jaguars.\"", "Tom takes photos of wild animals for nature magazines, but his work is not only about taking beautiful pictures. He travels to forests and oceans, studies animal behaviour and sometimes waits for hours in the dark before a nocturnal animal appears. Tom says, \"My job can be risky because one mistake may frighten an animal or put me in danger, but careful preparation makes the photograph more honest.\""],
        ["Daniel designs parks and green spaces in big cities. He works with architects and communities to build places where people and nature can share space. He says, \"Cities need more trees and gardens. I want to help people connect with nature, even in the middle of a busy city.\"", "Daniel designs parks and green spaces in big cities. He works with architects, local families and transport planners, so his designs must solve several problems at once: shade, safety, noise and wildlife. He says, \"Cities need more trees and gardens, but a successful park also has to help people move, rest and meet each other.\""],
        ["Yuki loves making videos. She uses her tablet to record short films about fashion and shares them on the internet.", "Yuki creates short fashion videos for an online audience, but she plans each one like a small research project."],
        ["Matteo is crazy about music apps. He downloads different sounds and mixes them together on his smartphone to create new songs.", "Matteo uses music apps to build short soundtracks on his smartphone. He records ordinary sounds, changes their speed and mixes them with electronic beats."],
        ["Suki uses her laptop to learn about history. She reads online articles about ancient civilisations and watches documentaries about how people lived hundreds of years ago.", "Suki uses her laptop to investigate ancient civilisations. She compares maps, museum photographs and short articles to understand how people lived hundreds of years ago."]
      ];
      pairs.push(
        ["Please keep to the paths and do not walk on the green spaces. Dogs must be on a lead at all times.", "The grass is being repaired this month. Please use the marked paths only. Dogs are welcome, but owners must keep them close enough to control them."],
        ["You can let your dog run free in the park.", "You may cross the grass if there are no workers nearby."],
        ["You should stay on the paths and control your dog.", "You should avoid the grass and make sure your dog stays under control."],
        ["Dogs are not allowed in the park.", "Dogs can use the park only after the grass has grown again."],
        ["Hi Leo, I can't come to the community meeting about the new skyscraper tonight. Can you tell me what they decide?", "Hi Leo, I may miss the beginning of the meeting about the new skyscraper. If they vote before I arrive, can you message me the result and the main reason?"],
        ["Maya wants Leo to go to a meeting instead of her.", "Maya wants Leo to make the decision for her."],
        ["Maya is inviting Leo to a meeting about a building.", "Maya is checking whether Leo agrees with the skyscraper plan."],
        ["Maya wants to know what happens at the meeting.", "Maya wants Leo to report the decision if she is not there in time."],
        ["Open every Friday evening 7 p.m.  10 p.m. See nocturnal animals when they are most active! Children under 12 must be with an adult.", "Friday night visits run from 7 p.m. to 10 p.m. Some animals may not appear early, so visitors should arrive before the last entry at 8:30. Children under 12 must stay with an adult."],
        ["The zoo is open every night of the week.", "Visitors who arrive at 9 p.m. can still buy a ticket."],
        ["You can visit the zoo on Friday evenings to watch animals that live in the dark.", "Friday evening visitors may see animals that are usually active after dark."],
        ["Children of all ages can visit the zoo alone on Fridays.", "Children under 12 can enter alone if they arrive before 8:30."],
        ["The outdoor pool is closed until March. Indoor pool times are the same as usual.", "The outdoor pool is closed for repairs until March. Members can still swim indoors, but weekend lessons will use lanes 1 and 2."],
        ["You cannot swim at all during the winter.", "Weekend lessons have been cancelled until March."],
        ["Both pools are closed until March.", "Only members can use the indoor pool."],
        ["You can still use the indoor pool.", "The indoor pool remains open, although some lanes may be busy."],
        ["School Uniform Shop</div>All uniforms half price this weekend only. Open Saturday 9 a.m.  5 p.m.", "School Uniform Shop</div>Half-price uniforms are available this Saturday only. Online orders are not included, and returns must be made within seven days."],
        ["The uniform shop has a sale every weekend.", "The discount is available for online orders too."],
        ["You can buy cheaper uniforms this Saturday.", "Customers can buy uniforms at a lower price in the shop on Saturday."],
        ["The shop is only open in the morning.", "Customers have one week to collect the cheaper uniforms."],
        ["Have you downloaded that new music app? You can mix different songs together. I tried it last night  it's really fun!", "Have you downloaded that new music app? I thought it was only for listening, but it lets you mix short clips and save them. I tried it last night and sent one to our music teacher."],
        ["Lily wants Oscar to make a song for her.", "Lily needs Oscar to repair the app before music class."],
        ["Lily is telling Oscar about an app she enjoyed using.", "Lily is recommending an app because she discovered an extra feature."],
        ["Lily is asking Oscar to help her fix a music app.", "Lily is warning Oscar that the app is difficult to save."],
        ["Who works to make cities greener?", "Who has to balance environmental aims with practical city problems?"],
        ["Who spends time in dark places for work?", "Who is most likely to wait before acting because the conditions must be right?"],
        ["Who wants to keep animals safe?", "Who believes public understanding can help protect fragile habitats?"],
        ["Who has a job that can be risky?", "Whose work may become unsafe if preparation is poor?"],
        ["Who learned to love their subject when they were young?", "Who says an early interest later became a professional responsibility?"],
        ["Who works together with other professionals?", "Who must consider different groups before completing a design?"],
        ["Who studies animals that produce light?", "Who compares direct observation with recorded evidence?"],
        ["Who wants to work in the film industry?", "Who is practising a skill that could influence how viewers feel during a scene?"],
        ["Who is interested in things that happened a long time ago?", "Who uses several sources to understand how past lives were organised?"],
        ["Who learned a skill from a family member?", "Who connects a family-taught skill with modern online presentation?"],
        ["Who likes to put together different types of music?", "Who combines old and new sounds but wants each one to keep its character?"],
        ["Who shares creative work online?", "Who creates for online viewers while explaining design choices?"],
        ["Who wants to study old objects and places in the future?", "Who hopes to protect historical evidence before it disappears?"],
        ["Who uses a phone to make music?", "Who changes recorded sounds to create a particular effect?"],
        ["What is different about London's National Park City?", "What does the title National Park City ask people to do?"],
        ["It is in the countryside.", "Think of London as if it has no traffic or noise."],
        ["It is a city that wants to become greener and wilder.", "Notice existing nature and improve the city through everyday choices."],
        ["It has more green space than any other city.", "Replace city streets with protected countryside."],
        ["Who started the National Park City idea?", "Why is Daniel's walk across London important in the text?"],
        ["A group of scientists.", "It proved that cities cannot be part of nature."],
        ["The government of London.", "It helped him see evidence for a new way of describing the city."],
        ["A geography teacher.", "It showed that most people already understood the idea."],
        ["What did Daniel Raven-Ellison discover about London?", "Which conclusion best follows from Daniel's observation?"],
        ["Less than half of the city was green space.", "London had enough green space, so no further action was needed."],
        ["Almost half of London was already green.", "The city already had natural value that people could build on."],
        ["London had no parks or gardens.", "Only official parks should count as nature."],
        ["What can people do to help the National Park City plan?", "How does the plan expect change to happen?"],
        ["Move out of the city.", "Through small actions by schools, communities and residents."],
        ["Plant trees and make gardens.", "Mainly through one large government project."],
        ["Stop using parks at night.", "By keeping people away from urban wildlife."],
        ["How did some people feel about the idea at first?", "Why did some people question the name at first?"],
        ["Everyone loved it immediately.", "They felt the phrase did not match a busy city."],
        ["Some people found it unusual.", "They did not want any more trees in London."],
        ["Nobody was interested.", "They believed parks should only be open at night."],
        ["When did school uniforms first appear?", "What does the example of Christ's Hospital School show?"],
        ["In the 15th century.", "Uniforms can become part of a school's long-term identity."],
        ["In the 16th century.", "Uniforms were invented mainly to save money."],
        ["In the 19th century.", "Uniform rules are the same in every country."],
        ["In the beginning, who wore school uniforms?", "What changed between the 16th and 20th centuries?"],
        ["All children.", "Uniforms moved from a limited practice to a common school rule."],
        ["Only children from wealthy families.", "Uniforms became less connected with schools."],
        ["Only children in London.", "Uniforms disappeared in Britain but grew elsewhere."],
        ["Why do some people think uniforms are good?", "Which argument supports uniforms in the text?"],
        ["Because they are always fashionable.", "They may reduce visible differences between students."],
        ["Because students can express themselves.", "They always allow students to show culture and personality."],
        ["Because they make students equal and can save money.", "They remove every possible school cost."],
        ["What do people who disagree with uniforms say?", "What is the strongest concern from critics?"],
        ["Uniforms are too expensive.", "Uniforms may limit personal and cultural expression."],
        ["Students should choose their own clothes to show who they are.", "Uniforms make all students behave badly."],
        ["Uniforms are not comfortable.", "Uniforms are never part of school identity."],
        ["What are some schools doing with their uniforms now?", "How are some schools responding to the debate?"],
        ["Getting rid of them completely.", "They are adapting uniform rules rather than simply removing them."],
        ["Making them more modern and comfortable.", "They are making uniforms more formal and expensive."],
        ["Making them more expensive.", "They are asking students to design every item alone."],
        ["<span class=\"wb-item\">a grandmother</span><span class=\"wb-item\">a cousin</span><span class=\"wb-item\">a forest</span><span class=\"wb-item\">a sandwich</span><span class=\"wb-item\">an elephant</span><span class=\"wb-item\">a library</span><span class=\"wb-item\">a recipe</span><span class=\"wb-item\">a penguin</span><span class=\"wb-item\">a season</span><span class=\"wb-item\">an uncle</span><span class=\"wb-item\">a zoo</span><span class=\"wb-item\">a carrot</span><span class=\"wb-item\">a hippo</span><span class=\"wb-item\">a stepfather</span><span class=\"wb-item\">a desert</span>", "<span class=\"wb-item\">a recipe</span><span class=\"wb-item\">a desert</span><span class=\"wb-item\">a cousin</span><span class=\"wb-item\">a hippo</span><span class=\"wb-item\">a library</span><span class=\"wb-item\">a sandwich</span><span class=\"wb-item\">an uncle</span><span class=\"wb-item\">a penguin</span><span class=\"wb-item\">a forest</span><span class=\"wb-item\">a carrot</span><span class=\"wb-item\">a zoo</span><span class=\"wb-item\">an elephant</span><span class=\"wb-item\">a season</span><span class=\"wb-item\">a stepfather</span><span class=\"wb-item\">a grandmother</span>"],
        ["<span class=\"wb-item\">a passport</span><span class=\"wb-item\">a dentist</span><span class=\"wb-item\">a lake</span><span class=\"wb-item\">a suitcase</span><span class=\"wb-item\">a bridge</span><span class=\"wb-item\">a castle</span><span class=\"wb-item\">a toothache</span><span class=\"wb-item\">a waterfall</span><span class=\"wb-item\">a museum</span><span class=\"wb-item\">plastic</span><span class=\"wb-item\">a raincoat</span><span class=\"wb-item\">a mosque</span><span class=\"wb-item\">a supermarket</span><span class=\"wb-item\">a temperature</span><span class=\"wb-item\">recycling</span>", "<span class=\"wb-item\">recycling</span><span class=\"wb-item\">a suitcase</span><span class=\"wb-item\">a mosque</span><span class=\"wb-item\">a dentist</span><span class=\"wb-item\">a waterfall</span><span class=\"wb-item\">plastic</span><span class=\"wb-item\">a passport</span><span class=\"wb-item\">a bridge</span><span class=\"wb-item\">a temperature</span><span class=\"wb-item\">a lake</span><span class=\"wb-item\">a raincoat</span><span class=\"wb-item\">a castle</span><span class=\"wb-item\">a supermarket</span><span class=\"wb-item\">a toothache</span><span class=\"wb-item\">a museum</span>"],
        ["Listen and write. There is one example. A girl is talking about her new school.", "Listen and write. There is one example. A girl is talking about her new school. Be careful: she may mention an old detail before giving the final answer."],
        ["Listen and write. There is one example. A boy is talking about a water conservation project at his school.", "Listen and write. There is one example. A boy is talking about a water conservation project at his school. Be careful: he may correct himself or mention another project first."],
        ["Number of students:", "Final number of students:"],
        ["Favourite subject:", "Subject she likes most this term:"],
        ["Best friend's name:", "New best friend's name:"],
        ["Lunch time:", "Usual lunch time:"],
        ["After-school club:", "Club she chose after changing her mind:"],
        ["Number of students in the project:", "Final number of students in the project:"],
        ["They collect water from:", "Main place they collect water from:"],
        ["They use the water for:", "Main thing they use the water for:"],
        ["Day they meet:", "Regular meeting day:"],
        ["Next project:", "Next project after this one:"],
        ["For each question, tick () one box. You will hear a conversation about what people did at the weekend.", "For each question, tick one box. Listen for the final answer, because the speaker may mention another activity first."],
        ["For each question, tick () one box. You will hear a conversation about what people did to stay healthy last week.", "For each question, tick one box. Listen for the reason and the final decision, because two options may be mentioned."],
        ["went to the zoo", "went to the animal park after lunch"],
        ["went to the beach", "planned to go to the beach"],
        ["stayed at home", "stayed at home because of rain"],
        ["played football", "started a football game"],
        ["went swimming", "went swimming after the game was cancelled"],
        ["rode his bike", "fixed his bike"],
        ["did yoga at home", "did yoga after trying a video"],
        ["swam in the pool", "planned to swim in the pool"],
        ["ate a healthy salad", "chose salad instead of soup"],
        ["drank lots of water", "drank water after feeling tired"],
        ["went to bed early", "went to bed early but woke up late"],
        ["<span class=\"wb-item\">some</span><span class=\"wb-item\">a lot of</span><span class=\"wb-item\">many</span><span class=\"wb-item\">because</span><span class=\"wb-item\">but</span><span class=\"wb-item\">which</span><span class=\"wb-item\">who</span><span class=\"wb-item\">than</span><span class=\"wb-item\">most</span><span class=\"wb-item\">should</span>", "<span class=\"wb-item\">although</span><span class=\"wb-item\">because</span><span class=\"wb-item\">which</span><span class=\"wb-item\">several</span><span class=\"wb-item\">should</span><span class=\"wb-item\">where</span><span class=\"wb-item\">however</span><span class=\"wb-item\">than</span><span class=\"wb-item\">most</span><span class=\"wb-item\">who</span>"],
        ["Wild animals are important <b>(1)</b><span class=\"gap-line\">&nbsp;</span> they help keep nature healthy. There are <b>(2)</b><span class=\"gap-line\">&nbsp;</span> different animals in forests, oceans and deserts around the world.<br><br>     <b>(3)</b><span class=\"gap-line\">&nbsp;</span> animals, like pandas and polar bears, are in danger. People <b>(4)</b><span class=\"gap-line\">&nbsp;</span> protect these animals and their homes. Forests have more animals <b>(5)</b><span class=\"gap-line\">&nbsp;</span> cities. <b>(6)</b><span class=\"gap-line\">&nbsp;</span> wild animals need trees, rivers and clean air to live.", "Wild animals are important <b>(1)</b><span class=\"gap-line\">&nbsp;</span> they help keep nature healthy, but many people do not notice the jobs they do. There are <b>(2)</b><span class=\"gap-line\">&nbsp;</span> different animals in forests, oceans and deserts, and each place gives them food and shelter.<br><br>     <b>(3)</b><span class=\"gap-line\">&nbsp;</span> animals, like pandas and polar bears, are in danger because their homes are changing. People <b>(4)</b><span class=\"gap-line\">&nbsp;</span> protect these animals before the problem becomes worse. Forests usually have more animals <b>(5)</b><span class=\"gap-line\">&nbsp;</span> busy cities because there are quieter places to hide. <b>(6)</b><span class=\"gap-line\">&nbsp;</span> wild animals need most is a safe home, clean water and enough space to move."],
        ["<span class=\"wb-item\">going to</span><span class=\"wb-item\">should</span><span class=\"wb-item\">because</span><span class=\"wb-item\">more</span><span class=\"wb-item\">than</span><span class=\"wb-item\">some</span><span class=\"wb-item\">many</span><span class=\"wb-item\">which</span><span class=\"wb-item\">was</span><span class=\"wb-item\">best</span>", "<span class=\"wb-item\">although</span><span class=\"wb-item\">should</span><span class=\"wb-item\">because</span><span class=\"wb-item\">more</span><span class=\"wb-item\">than</span><span class=\"wb-item\">several</span><span class=\"wb-item\">which</span><span class=\"wb-item\">was</span><span class=\"wb-item\">best</span><span class=\"wb-item\">where</span>"],
        ["Travelling is <b>(1)</b><span class=\"gap-line\">&nbsp;</span> exciting when you visit new places and learn about different cultures. <b>(2)</b><span class=\"gap-line\">&nbsp;</span> people prefer beaches, but others like mountains or big cities.<br><br>     Before you travel, you <b>(3)</b><span class=\"gap-line\">&nbsp;</span> always pack a suitcase with warm and cool clothes <b>(4)</b><span class=\"gap-line\">&nbsp;</span> the weather can change quickly. Turkey has <b>(5)</b><span class=\"gap-line\">&nbsp;</span> beautiful places to visit <b>(6)</b><span class=\"gap-line\">&nbsp;</span> most other countries.", "Travelling is <b>(1)</b><span class=\"gap-line\">&nbsp;</span> exciting when you visit new places, compare cultures and solve small problems by yourself. <b>(2)</b><span class=\"gap-line\">&nbsp;</span> people prefer beaches, but others choose mountains or old cities where they can learn history.<br><br>     Before you travel, you <b>(3)</b><span class=\"gap-line\">&nbsp;</span> always pack clothes for different weather <b>(4)</b><span class=\"gap-line\">&nbsp;</span> conditions can change quickly. Turkey has <b>(5)</b><span class=\"gap-line\">&nbsp;</span> historical places, natural areas and modern cities to visit <b>(6)</b><span class=\"gap-line\">&nbsp;</span> many travellers expect."]
      );
      pairs.forEach(([from, to]) => { html = html.split(from).join(to); });
      return html;
    }
    function standardizeExamDocument(html) {
      if (!html) return html;
      html = hardenCambridgeLevel(html);
      if (html.includes("data-bayetav-standardized")) return html;
      const standardCss = ``<style data-bayetav-standardized>
@page{size:A4;margin:0}
html,body{font-family:Calibri,Arial,sans-serif!important;font-size:12pt!important;line-height:1.32!important;color:#111!important;background:#fff!important}
body{margin:0!important}
.page{width:210mm!important;min-height:297mm!important;max-width:none!important;margin:0 auto!important;padding:13mm 12mm 12mm!important;background:#fff!important;box-shadow:none!important;break-after:page;page-break-after:always}
.page:last-child{break-after:auto;page-break-after:auto}
.bayetav-doc-top{font-size:15pt!important;font-weight:800!important;letter-spacing:.09em!important;text-transform:uppercase!important;text-align:center!important;margin:0 0 9mm!important;padding-bottom:6mm!important;border-bottom:1pt solid #bdbdbd!important}
.school-header,.exam-header,header{border:0!important;text-align:center!important;margin:0 0 7mm!important;padding:0!important;background:#fff!important}
.school-name{font-size:15pt!important;font-weight:900!important;letter-spacing:.12em!important;text-transform:uppercase!important;text-align:center!important;margin:0 0 4mm!important;padding:0 0 3mm!important;border-bottom:2.4pt solid #000!important;color:#000!important}
.exam-title,h1{font-family:Calibri,Arial,sans-serif!important;font-size:17pt!important;line-height:1.15!important;font-weight:800!important;text-align:center!important;margin:0 0 4mm!important;color:#000!important}
.exam-subtitle,.exam-sub,.exam-units,.sub{font-size:12pt!important;font-style:italic!important;text-align:center!important;margin:0 0 7mm!important;color:#111!important}
.candidate-box,.cand{display:flex!important;align-items:center!important;gap:13mm!important;border:1.25pt solid #000!important;padding:5mm 6mm!important;margin:7mm 0 9mm!important;font-size:12pt!important;font-weight:800!important;background:#fff!important}
.candidate-box div,.cand div{display:flex!important;align-items:center!important;gap:3mm!important;min-width:0!important}
.candidate-box label,.cand label{font-weight:900!important;white-space:nowrap!important}
.candidate-box span,.cand span{display:inline-block!important;min-width:28mm!important;border-bottom:1.1pt solid #000!important;height:5mm!important;flex:0 0 28mm!important}
.paper-header,.phead{font-size:16pt!important;font-weight:900!important;letter-spacing:.08em!important;text-transform:uppercase!important;text-align:center!important;background:#fff!important;color:#000!important;border:0!important;border-bottom:1pt solid #bdbdbd!important;padding:0 0 6mm!important;margin:0 0 8mm!important}
.section-header,.shead{font-size:14pt!important;font-weight:900!important;text-transform:uppercase!important;text-align:center!important;background:#fff!important;border:0!important;border-bottom:2.2pt solid #000!important;padding:0 0 3mm!important;margin:7mm 0 6mm!important}
h2{font-family:Calibri,Arial,sans-serif!important;font-size:15pt!important;line-height:1.2!important;font-weight:900!important;margin:7mm 0 4mm!important;color:#000!important;border:0!important}
h3,.part-header,.ph{font-family:Calibri,Arial,sans-serif!important;font-size:14pt!important;line-height:1.2!important;font-weight:900!important;margin:6mm 0 3mm!important;color:#000!important}
.part-instruction,.pi{font-size:12pt!important;font-style:italic!important;margin:0 0 5mm!important;color:#111!important}
p,li,td,th,div,span,label,input,button{font-family:Calibri,Arial,sans-serif!important;font-size:12pt!important}
table{page-break-inside:auto!important;border-collapse:collapse!important;width:100%!important;margin:5mm 0!important}
td,th{border:1pt solid #000!important;padding:4mm!important;vertical-align:middle!important}
tr,.part,.exam-section,.notice-card,.poster-notice,.text-card,.audio-panel,.listening-q,.writing-task,.story-grid{break-inside:avoid;page-break-inside:avoid}
.time-box{font-size:13pt!important;text-align:center!important;font-style:italic!important;margin:0 0 8mm!important;color:#111!important}
.listening-q{margin:0 0 8mm!important}
.listening-q-num,.listening-q-text,.question{font-size:13pt!important;font-weight:900!important;margin:0 0 3mm!important;color:#000!important}
.abc-grid{display:grid!important;grid-template-columns:repeat(3,minmax(0,1fr))!important;gap:5mm!important;align-items:start!important;margin:3mm 0 2mm!important}
.abc-item{text-align:center!important}
.abc-label{font-size:38pt!important;line-height:1!important;font-weight:900!important;text-align:center!important;margin:0 0 2mm!important;color:#000!important}
.abc-img,.story-img-box,img{max-width:100%!important}
.abc-img{width:100%!important;border:1pt solid #bdbdbd!important;display:block!important;object-fit:contain!important;background:#fff!important}
.answer-line,.part2-gap,.match-answer{border:1.1pt solid #000!important;min-height:10mm!important;height:auto!important;min-width:42mm!important;background:#fff!important;display:inline-flex!important;align-items:center!important;justify-content:center!important;margin-top:3mm!important;color:#111!important}
.answer-line::before{content:"Answer: ___";font-weight:700;color:#111}
.gap-fill-table td,.gap-fill-table th,.match-table td,.match-table th{border:1pt solid #000!important;padding:3.5mm!important}
.gap-line{border-bottom:1.1pt solid #000!important;min-width:42mm!important;height:6mm!important;display:inline-block!important}
.notice-card,.text-card,.part2-info,.writing-task,.article-box,.profiles-box,.cloze-text{border:1.1pt solid #000!important;background:#fff!important;padding:5mm!important;margin:4mm 0!important}
.writing-box,.writing-lines{min-height:45mm!important;border:1pt solid #000!important;background:repeating-linear-gradient(#fff 0,#fff 8mm,#d9d9d9 8.2mm)!important;margin-top:4mm!important}
.writing-line{height:8mm!important;border-bottom:1pt solid #bdbdbd!important}
.footer{font-size:10pt!important;text-align:left!important;color:#111!important;border-top:1pt solid #bdbdbd!important;padding-top:3mm!important;margin-top:5mm!important}
.poster-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:7mm}
.poster-notice{border:1.2pt solid #000;border-radius:0;overflow:hidden;background:#fff}
.poster-frame{min-height:34mm;display:flex;align-items:center;justify-content:center;text-align:center;padding:6mm;background:#fff;border-bottom:1pt solid #000;font-weight:800;color:#000}
.poster-frame.warning,.poster-frame.green{background:#fff;color:#000}
.poster-body{padding:5mm}.poster-body .question{font-weight:800}
@media print{.no-print,button{display:none!important}.page{margin:0!important}.part,.exam-section{box-shadow:none!important}}
</style>``;
      const orderScript = ``<script data-bayetav-standardized>
(function(){
  function textOf(el){return (el.textContent||"").replace(/\\s+/g," ").slice(0,500);}
  function isListening(el){return /(^|\\b)(PAPER 2\\s*[:\\-]?\\s*)?LISTENING\\b|Listening Part/i.test(textOf(el));}
  function reorder(container){
    var children=Array.from(container.children||[]);
    var selected=children.filter(function(el){return isListening(el);});
    if(!selected.length)return;
    var anchor=children.find(function(el){return !/no-print/.test(el.className||"") && el.tagName!=="HEADER" && !isListening(el);});
    selected.forEach(function(el){container.insertBefore(el,anchor||container.firstChild);});
  }
  document.querySelectorAll(".page").forEach(reorder);
  reorder(document.body);
  function examTitle(){
    return ((document.querySelector("h1")||{}).textContent||document.title||"").replace(/\\s+/g," ").trim();
  }
  function tuneAudio(){
    document.querySelectorAll("audio").forEach(function(audio){
      function setRate(){
        audio.playbackRate=1.0;
        audio.dataset.playbackRate="1.0";
        audio.title="Listening speed: 1.0x";
      }
      audio.addEventListener("loadedmetadata",setRate);
      setRate();
    });
  }
  tuneAudio();
})();
<\/script>``;
      if (html.includes("</head>")) html = html.replace("</head>", standardCss + "</head>");
      else html = standardCss + html;
      if (html.includes("</body>")) html = html.replace("</body>", orderScript + "</body>");
      else html += orderScript;
      return html;
    }
    function docIdFromFileLink(link) {
      const raw = link.dataset.docFile || link.getAttribute("href") || "";
      const clean = raw.split("#")[0].split("?")[0].replace(/\\/g, "/").split("/").pop();
      return embeddedDocFiles[clean] || "";
    }
    function openEmbeddedDocInNewWindow(docId) {
      const html = resolveEmbeddedAssets(embeddedDocs[docId]);
      if (!html) {
        alert("Sınav içeriği bulunamadı.");
        return;
      }
      const url = URL.createObjectURL(new Blob([html], { type: "text/html;charset=utf-8" }));
      const opened = window.open(url, "_blank", "noopener");
      if (!opened) alert("Exam window could not open. Please allow pop-ups in the browser.");
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    }
    function downloadEmbeddedDoc(docId, filename) {
      const html = resolveEmbeddedAssets(embeddedDocs[docId]);
      if (!html) {
        alert("İndirilecek sınav içeriği bulunamadı.");
        return;
      }
      const url = URL.createObjectURL(new Blob([html], { type: "text/html;charset=utf-8" }));
      const link = document.createElement("a");
      link.href = url;
      link.download = filename || docId + ".html";
      document.body.appendChild(link);
      link.click();
      link.remove();
      setTimeout(() => URL.revokeObjectURL(url), 60000);
    }
    document.addEventListener("click", (event) => {
      const fileLink = event.target.closest("a[data-doc-file], a[href$='.html']");
      if (!fileLink) return;
      const docId = docIdFromFileLink(fileLink);
      if (!docId) return;
      event.preventDefault();
      if (fileLink.hasAttribute("download")) {
        const filename = fileLink.dataset.docFile || fileLink.getAttribute("download") || docId + ".html";
        downloadEmbeddedDoc(docId, filename);
      } else {
        openEmbeddedDocInNewWindow(docId);
      }
    }, true);

"@
  $html = $html.Replace('    function loadEmbedded(docId) {', $docHandler + '    function loadEmbedded(docId) {')
  $html = $html.Replace('iframe.srcdoc = embeddedDocs[docId] || "<p>Content not found.</p>";', 'iframe.srcdoc = resolveEmbeddedAssets(embeddedDocs[docId] || "<p>Content not found.</p>");')
  $html = $html.Replace('<audio controls preload="metadata" src="${escapeHtml(path)}"></audio>', '<audio controls preload="metadata" src="${escapeHtml(embeddedAudioSrc(path))}" data-audio-file="${escapeHtml(path)}"></audio>')
  $html = $html.Replace('<a href="${escapeHtml(path)}" download>', '<a href="${escapeHtml(embeddedAudioSrc(path))}" data-audio-file="${escapeHtml(path)}" download>')

  $audioScriptOverrides = @{
    'flyers_exam1_tts/flyers_exam1_part1.wav' = @'
Narrator: Flyers Exam One, Listening Part One. Listen and draw lines. There is one example. Look at the busy park picture. The boy who is playing football is Tom. Now listen to the questions. One. Sarah is not the girl near the gate, although she is holding something too. Sarah stopped beside the flower bed because she wanted a close picture of the purple flowers. Draw a line to the girl taking photos of flowers. Two. Grandpa Jack brought a newspaper, but he is not reading on the bench now. He changed his mind because the lake was quiet, so he is the older man fishing by the lake. Three. Aunt Maria is easy to miss because she is behind two children. She is not carrying bags from the shop; she is carefully carrying a cake for the picnic. Four. Cousin Ben wanted to help with the picnic first, but then he climbed higher than the other children. Draw the line to the boy climbing a tree. Narrator: Now listen again.
'@
    'flyers_exam1_tts/flyers_exam1_part2.wav' = @'
Narrator: Flyers Exam One, Listening Part Two. Listen and write. Teacher: We are talking to a new student today. Her old school was smaller, with about two hundred children, but this school has three hundred and fifty students, so write three hundred and fifty. She enjoyed ordinary science last year, but this year her favourite subject is computer science because she likes solving problems with programs. Her best friend here is not Aylin from her old town. The girl who helped her on the first day was Elif. Lunch used to begin at quarter past twelve, but the new timetable moved it a little later, so lunch starts at twelve thirty. She tried to join the art club, but it was full, and football was too noisy for her. The club she finally chose is the cooking club. Narrator: Now listen again.
'@
    'flyers_exam1_tts/flyers_exam1_part3.wav' = @'
Narrator: Flyers Exam One, Listening Part Three. Listen and choose the correct picture. One. The first place sounded exciting because it had a big door and old walls, but they did not go there. The family chose the picture where they could see animals outside, so choose A. Two. For the science project, the rocket picture looked fun, but it did not match the lesson. They needed the picture with the computer and data table, so choose B. Three. The girl almost bought the red jacket because it was cheaper, but the weather was windy. She chose the warmer coat in picture B. Four. They first planned to travel by train, but the station was closed. The option they used was the third picture, C. Five. The boy had homework about food from different countries. The cake looked nice, but his teacher asked for the meal in picture C. Narrator: Now listen again.
'@
    'flyers_exam1_tts/flyers_exam1_part4.wav' = @'
Narrator: Flyers Exam One, Listening Part Four. Listen and match each person with what they did. Emma wanted to go to the beach, but the weather changed and her family chose the zoo instead. Tom carried his football bag in the morning, but the pool was open again, so he went swimming. Lucy talked about seeing a film, but her cousin invited her at the last minute; she went to a party. Jack planned to play computer games after lunch, but his dad needed help in the kitchen, so Jack helped his dad cook. Mia was going shopping with her aunt, but she stayed at home and painted a picture for school. Narrator: Now listen again.
'@
    'flyers_exam1_tts/flyers_exam1_part5.wav' = @'
Narrator: Flyers Exam One, Listening Part Five. Listen and colour or write. One. Look at the ruler on the desk. Do not colour the pencil; colour the ruler blue. Two. On the classroom board, write the word HELLO in capital letters. Three. There are two bags in the picture. The small sports bag stays white, but colour the school backpack green. Four. Find the small book near the chair and write the number five on it. Five. The star above the poster should be yellow, not the sun near the window. Narrator: Now listen again.
'@
    'flyers_exam2_tts/flyers_exam2_part1.wav' = @'
Narrator: Flyers Exam Two, Listening Part One. Listen and draw lines. There is one example. Dr. Wilson is the man in a white coat outside the building. Now listen. One. Mrs. Chen is not waiting for the bus, although she is standing near the road. She has just left the supermarket and is carrying two shopping bags. Two. Harry borrowed his sister's helmet, so he looks different today. He is the boy riding a bicycle, not the boy walking beside it. Three. Grandma Rose thought the cafe was too noisy. She found a quiet bench and is reading a newspaper there. Four. Officer Kaya is not talking to the shopkeeper. He is standing in the street and directing the traffic. Narrator: Now listen again.
'@
    'flyers_exam2_tts/flyers_exam2_part2.wav' = @'
Narrator: Flyers Exam Two, Listening Part Two. Listen and write. Teacher: The Blue River Team used to have eighteen students, but seven more joined after the assembly, so now there are twenty-five. They collect water from the roof, not from the playground tap, because rainwater runs down from there. The water is used for watering the school garden. Last year they met on Tuesdays, but this term the free afternoon is Thursday. Their next project is not planting trees. They are organising a beach clean-up, so write cleaning the beach or beach clean-up. Narrator: Now listen again.
'@
    'flyers_exam2_tts/flyers_exam2_part3.wav' = @'
Narrator: Flyers Exam Two, Listening Part Three. Listen and choose the correct picture. One. The first picture shows the right activity because the girl stayed at home and did quiet exercise; choose A. Two. The boy wanted to watch television, but he was too tired after practice. He went to bed early, so choose B. Three. The lesson was not about medicine or running. Nurse Ayse taught the children about brushing their teeth, so choose B. Four. Mr Demir usually takes the bus, but that day the roads were busy and he rode his bicycle. Choose C. Five. Zeynep cut vegetables with her mother and made soup, not a sandwich or cake. Choose C. Narrator: Now listen again.
'@
    'flyers_exam2_tts/flyers_exam2_part4.wav' = @'
Narrator: Flyers Exam Two, Listening Part Four. Listen and match each person with what they did. Defne wanted to run in the park, but rain began before breakfast. She did yoga at home. Kerem planned to read another chapter, but his tooth hurt, so he went to bed early. Nurse Ayse visited the class and taught everyone about brushing teeth carefully. Mr Demir usually drives, but he decided the short journey was better by bicycle. Zeynep did not buy soup from the shop; she made vegetable soup at home. Narrator: Now listen again.
'@
    'flyers_exam2_tts/flyers_exam2_part5.wav' = @'
Narrator: Flyers Exam Two, Listening Part Five. Listen and colour or write. One. Find the bus near the traffic lights. Colour the bus green. Two. The building next to the park is not the museum. Write LIBRARY on that building. Three. Colour the bridge blue, but leave the river as it is. Four. On the post office door, write the number seven. Five. The mosque roof should be yellow; do not colour the whole building. Narrator: Now listen again.
'@
    'impact2_ket_exam1_tts/impact2_ket_exam1_part1.wav' = 'Narrator: You will hear five short conversations. Choose the best answer. One. Which poster does Maya choose? Maya: The red poster is bright, but the club used almost the same colour last year. The green one looks calm, but people may not notice it from the door. Teacher: So which one helps students see the announcement quickly? Maya: The blue poster. It is not my favourite colour, but it is the clearest for the corridor. Two. What should students do after twenty minutes? Boy: Do we close the laptops after twenty minutes? Girl: Not exactly. We still need them later. The teacher said our eyes need a short rest, so we look away from the screen for a minute and then continue. Boy: So the answer is not stop working, just take a screen break. Three. What happens before the camera demonstration? Guide: Some students want to try the camera first, but the equipment room is small. We will walk around the exhibition and notice three examples of light and shadow. After that, the technician will show the camera. Four. What does the librarian give the students? Student: I lost my card. Librarian: Your old card will work next week, but today you need this temporary code. Write it carefully because the computer will ask for it before you print. Five. What must students complete at the end? Teacher: Do not leave after the last presentation. I do not need your notebooks, and the posters can stay on the wall. Before you go, answer the short questionnaire on your desks. Narrator: Now listen again.'
    'impact2_ket_exam1_tts/impact2_ket_exam1_part2.wav' = 'Narrator: You will hear a teacher talking about Science Week. Listen and write one word or a number for each question. Teacher: Next month is Science Week. I nearly wrote Science Day on the first notice, but it is longer than one day, so please write Week. The main display will not be in the hall because exams are there. It will be in the library, where visitors can read the project notes. On Tuesday, a nurse is coming to speak about sleep and health. I asked a doctor first, but the clinic is busy. Students who want to enter the quiz need a card from reception, not a ticket. Bring your own notebook too, because the school will not provide paper for your observations. Narrator: Now listen again.'
    'impact2_ket_exam1_tts/impact2_ket_exam1_part3.wav' = 'Narrator: You will hear two students discussing a digital safety project. For each question, choose A, B or C. Tom: I thought our project should be about passwords. Ella: Passwords are useful, but everyone already says that. The article about fake profiles is stronger because students have to decide whether a message feels reliable. Tom: So the main topic is judging online information. Ella: Yes. For the first activity, we should show two screenshots. One looks friendly, but the details do not match. Tom: Good. The teacher asked for evidence, so we need examples, not just opinions. Ella: And at the end, students should write one rule they will actually use. Tom: Should we tell them to delete all social media? Ella: That sounds dramatic, but unrealistic. Better to make them pause before they answer strange messages. Narrator: Now listen again.'
    'impact2_ket_exam1_tts/impact2_ket_exam1_part4.wav' = 'Narrator: You will hear five people talking about a school exhibition. For each speaker, choose the correct answer. Speaker 1: I expected the colour display to be only artistic, but the notes about light changed my mind. The picture was real, yet it made the fish look safer than its habitat. Speaker 2: The survey corner was useful because it showed numbers and comments together. One without the other would not explain why students felt calmer. Speaker 3: I liked the online identity section most. It did not simply say, Be careful. It showed why a message can seem normal and still be false. Speaker 4: The camera demonstration came after the tour, which helped me understand it. Before that, I had not noticed how much distance changes an image. Speaker 5: The final questionnaire was short, but it made me change my first answer about two posters. I realised I had looked quickly and missed the evidence. Narrator: Now listen again.'
    'impact2_ket_exam1_tts/impact2_ket_exam1_part5.wav' = 'Narrator: You will hear a teacher telling students which topics to match with projects. Teacher: Project A is not simply about pretty posters. It explains how colours persuade people in advertising, so match it with Colours in advertising. Project B begins with tired students, but the real focus is what sleep does to concentration and health. Project C uses messages and screenshots to help students recognise unsafe digital situations, so choose Digital safety. Project D has underwater photographs, yet it is not about holidays. It asks how scientists discover and record life under the sea. Project E looks at feelings, memory and decisions, which means the topic is Brain and emotions. Narrator: Now listen again.'
    'impact2_ket_exam2_tts/impact2_ket_exam2_part1.wav' = 'Narrator: You will hear five short conversations. Choose the best answer. One. Which bag will Emir take? Emir: The small bag is easier to carry, but my boots do not fit. The old rucksack is strong, yet the zip sticks. I will use the blue hiking bag because it has space for the extra jacket. Two. What should students bring to the lab? Teacher: You can leave your lunch in the classroom, and you do not need coloured pens. The lab notes are already printed. What you must bring is your safety card, because the assistant will check it at the door. Three. Which meal is chosen for the project? Girl: Salad wastes less energy, but it does not use the imperfect vegetables well. Sandwiches are quick, but the bread is the problem this week. Soup lets us use the vegetables and explain food waste clearly. Four. Where will the public art be placed? Man: The gate is too crowded, and the gym wall is being repaired. The best place is near the cafeteria entrance, because everyone passes it after lunch. Five. What does the teacher want students to improve? Teacher: The story has a good ending, and the drawings are clear enough. What is missing is the warning. Readers should understand the danger before the last sentence. Narrator: Now listen again.'
    'impact2_ket_exam2_tts/impact2_ket_exam2_part2.wav' = 'Narrator: You will hear a notice about Project Week. Listen and write one word or a number for each question. Teacher: Our next event is Project Week. It is not a single afternoon, because each team needs time to collect evidence. The rescue recipe team will work in the food lab, not the normal classroom, because they need sinks and tables. On Wednesday an artist is visiting to advise the public art group. The cafeteria team will test a warm soup recipe using vegetables that are usually rejected. Finally, anyone joining the emergency walk must wear strong shoes. Trainers are fine if they have a good grip, but sandals are not allowed. Narrator: Now listen again.'
    'impact2_ket_exam2_tts/impact2_ket_exam2_part3.wav' = 'Narrator: You will hear two students planning a food waste display. For each question, choose A, B or C. Leyla: I do not want our display to look like a recipe page. Kerem: But the soup is the thing visitors can taste. Leyla: True, but the main point is why people throw good food away. We should show the data first. Kerem: The number of sandwiches from one week? Leyla: Yes. It feels more serious than a general sentence about waste. Kerem: Should we put funny drawings around it? Leyla: Maybe one or two, but the message should interrupt people a little. If it is too cheerful, they will not think about their habits. Kerem: So evidence first, design second, and a short story to make it personal. Narrator: Now listen again.'
    'impact2_ket_exam2_tts/impact2_ket_exam2_part4.wav' = 'Narrator: You will hear five people talking about school projects. For each speaker, choose the correct answer. Speaker 1: The mountain group surprised me. Their best point was not the equipment list but how tired people make poor decisions. Speaker 2: I thought food waste meant careless students, but the cafeteria records showed timing and signs mattered too. Speaker 3: The mural felt uncomfortable at first. Then I understood why; it was supposed to make us notice a warning we usually ignore. Speaker 4: The recipe team was honest. They did not claim soup could solve everything, only that repeated small choices can help. Speaker 5: The emergency story worked because the danger appeared before the ending. I had to infer what the character should do next. Narrator: Now listen again.'
    'impact2_ket_exam2_tts/impact2_ket_exam2_part5.wav' = 'Narrator: You will hear a teacher explaining which topics to match with projects. Teacher: Project A compares animals that survive in deserts, mountains and cold places, so the correct topic is Extreme animals. Project B studies what happens to uneaten meals in the cafeteria; choose Food waste. Project C is not ordinary painting. It uses murals in public places to send a message, so match it with Public art. Project D prepares students for storms, blocked roads and emergency choices, which is Disaster preparation. Project E tells very short stories where the ending is implied rather than explained, so choose Flash fiction. Narrator: Now listen again.'
  }

  $audioScriptOverrides['ket_test1_tts/test1_part1.wav'] = @'
Narrator: KET Test One, Listening Part One. You will hear five short conversations. One. Girl: I heard something in the park after dark. Boy: Was it an owl? Girl: That was my first thought because it was quiet and high in the trees. Boy: Or maybe a cat? Girl: No, it moved above me and I only understood when it flew under the lamp. It was the animal with wide wings that comes out at night, a bat. Two. Boy: Did your aunt work at the zoo? Girl: She visits the zoo for work, but she is not a keeper or a vet. Boy: Then what does she do there? Girl: At the end of each visit, she chooses the best pictures for the magazine. She is a photographer. Three. Man: We could meet near the station, but the buses are late there. Woman: The shopping centre closes early too. Man: Since we need somewhere easy for everyone after school, let us meet in the city centre. Four. Girl: Is the film at eight thirty? Boy: That was the old time. Girl: I wrote nine o'clock. Boy: The final message moved it again. It begins at nine thirty p.m. Five. Teacher: You can bring a history book or a science article if you want extra ideas. Student: Which subject is the homework actually for? Teacher: Look at the last line: draw the place and explain your choices. It is for art. Narrator: Now listen again.
'@
  $audioScriptOverrides['ket_test1_tts/test1_part2.wav'] = @'
Narrator: KET Test One, Listening Part Two. Listen to a guide talking about a night walk in a city park. Guide: The walk is not on Friday this month because the park cafe is closed then. It is also not on Sunday, when families use the lake path. The evening you need is Saturday. Please arrive before sunset. The notice used to say seven thirty, but in winter we start later, at eight p.m. Bring warm clothes. You do not need a camera, and phones are not bright enough for the dark path. The important thing is a torch. The walk sounds short on the map, but we stop to listen and look carefully, so it lasts about two hours. Finally, the student price was four pounds last year. This year the cost is five pounds per person. Narrator: Now listen again.
'@
  $audioScriptOverrides['ket_test1_tts/test1_part3.wav'] = @'
Narrator: KET Test One, Listening Part Three. Listen to Alice and Ben talking about a school project on animals. Alice: I found a beautiful article about ocean animals. Ben: The pictures are good, but our unit is about how people and animals share the same places. Alice: Then countryside animals? Ben: Not exactly. The teacher said to look at animals that live close to houses, roads and shops. Alice: So our project is animals in cities. Ben: Yes. We could go to the zoo, but that would not show city behaviour. Alice: The library books are old too. Ben: Let us use the internet and compare two reports. Alice: I will write about foxes because they come into streets at night. Ben: Good. The deadline is not Monday or Wednesday. We present next Friday. Alice: Poster or video? Ben: A video is too much work. A poster will let us show photos and notes together. Narrator: Now listen again.
'@
  $audioScriptOverrides['ket_test1_tts/test1_part4.wav'] = @'
Narrator: KET Test One, Listening Part Four. Listen and choose the correct answer. Sixteen. Boy: I played football on Saturday, and on Sunday we nearly went to the cinema. But the best part was quieter. At the nature reserve, I saw how the guide found tracks near the river. That was what I enjoyed most. Seventeen. Girl: Our house is not close to school, and the garden is small. What I really like is that after six o'clock there are almost no cars, so the street is quiet. Eighteen. Boy: I like dogs and I enjoyed visiting the zoo, but the job I keep reading about is connected to the sea. I would like to study ocean life as a marine biologist. Nineteen. Woman: People talk about the shopping centre, but that was built years ago. The recent change is better: the empty car park has become a new park. Twenty. Teacher: Do not bring animal books tomorrow. We used those today. I also do not need city photos yet. Please bring a drawing of your neighbourhood so we can label the places. Narrator: Now listen again.
'@
  $audioScriptOverrides['ket_test1_tts/test1_part5.wav'] = @'
Narrator: KET Test One, Listening Part Five. Listen to a teacher talking about trip responsibilities. Teacher: Maria asked to carry the map, but she knows the camera best, so Maria will take photos. Tom usually writes neat notes, but today Elena is better for that because she missed the last trip. Tom, you will carry the map. Akiko wanted to count animals, but her drawings are excellent, so Akiko will draw pictures for the display. Sam, please do not look after equipment this time; you are responsible for bringing snacks. Elena, as I said, I need clear notes about what each group sees. Narrator: Now listen again.
'@
  $audioScriptOverrides['ket_test2_tts/test2_part1.wav'] = @'
Narrator: KET Test Two, Listening Part One. You will hear five short conversations. One. Did you buy fruit at the market? I nearly bought apples, and I looked at a scarf too. But the stallholder repaired the small silver bracelet while I waited, so that is what I bought. Two. Is your brother playing guitar in the concert? He practised guitar first, then piano, but the band already had those. In the end he moved to the drums. Three. Are you going to the club now? I wanted to, and my bag is ready. But the teacher's message? Yes, I saw it at the end. I have to finish the homework before I go. Four. Was your grandad born in nineteen fifty-six? That is my dad's year. I thought you said nineteen sixty. Close, but the family book says nineteen sixty-five. Five. It may rain later, and yesterday was cloudy. For the picnic time, though, the forecast changed. The morning will be sunny. Narrator: Now listen again. One. Did you buy fruit at the market? I nearly bought apples, and I looked at a scarf too. But the stallholder repaired the small silver bracelet while I waited, so that is what I bought. Two. Is your brother playing guitar in the concert? He practised guitar first, then piano, but the band already had those. In the end he moved to the drums. Three. Are you going to the club now? I wanted to, and my bag is ready. But the teacher's message? Yes, I saw it at the end. I have to finish the homework before I go. Four. Was your grandad born in nineteen fifty-six? That is my dad's year. I thought you said nineteen sixty. Close, but the family book says nineteen sixty-five. Five. It may rain later, and yesterday was cloudy. For the picnic time, though, the forecast changed. The morning will be sunny.
'@
  $audioScriptOverrides['ket_test2_tts/test2_part2.wav'] = @'
Narrator: KET Test Two, Listening Part Two. Listen to a boy talking about a school technology project. The project title is Gadgets Through Time. Some students wrote history, but the final word on the poster is Time. We first planned pairs, then the teacher decided groups of four would give everyone a job. Each group must not make a model. You have to make a presentation about a gadget from the past. The presentation day is not in April. It is on March the fifteenth. The prize was going to be headphones, but the sponsor changed it. The best project wins a tablet. Narrator: Now listen again. The project title is Gadgets Through Time. Some students wrote history, but the final word on the poster is Time. We first planned pairs, then the teacher decided groups of four would give everyone a job. Each group must not make a model. You have to make a presentation about a gadget from the past. The presentation day is not in April. It is on March the fifteenth. The prize was going to be headphones, but the sponsor changed it. The best project wins a tablet.
'@
  $audioScriptOverrides['ket_test2_tts/test2_part3.wav'] = @'
Narrator: KET Test Two, Listening Part Three. Listen to Zoe and Marcus talking about a school fashion show. People think the show is about traditional clothes because of last year. Or clothes students designed themselves? We designed them, but the special rule is that everything must be made from recycled clothes. Is it this Friday? The posters were printed too early. It is next Friday. I am not walking on stage. Playing music? No, I will take photographs for the school site. My outfit looks like denim, but I am not using jeans. Old T-shirts? I tried those. The art teacher said the old curtains were stronger, so that is my material. Is your mother helping? She gave advice, but my art teacher is helping me make it. Narrator: Now listen again. People think the show is about traditional clothes because of last year. Or clothes students designed themselves? We designed them, but the special rule is that everything must be made from recycled clothes. Is it this Friday? The posters were printed too early. It is next Friday. I am not walking on stage. Playing music? No, I will take photographs for the school site. My outfit looks like denim, but I am not using jeans. Old T-shirts? I tried those. The art teacher said the old curtains were stronger, so that is my material. Is your mother helping? She gave advice, but my art teacher is helping me make it.
'@
  $audioScriptOverrides['ket_test2_tts/test2_part4.wav'] = @'
Narrator: KET Test Two, Listening Part Four. Listen and choose the correct answer. Sixteen. On the trip, we passed the history museum and I wanted to stop at the art museum. But our tickets were for the building with old computers and early phones, the technology museum. Seventeen. I enjoy pop songs, and traditional music is important in my family. What I like best is when musicians mix old instruments with new sounds. Eighteen. I did not throw my old clothes away, and I only gave a few buttons to the charity shop. Most of the fabric became a new bag, so I made the clothes into something new. Nineteen. My grandfather worked on a farm as a child, and he built his own house later. But his real job for many years was teaching. Twenty. I wanted headphones, and my brother suggested a camera. My parents chose something I can wear and use for messages. I got a smartwatch. Narrator: Now listen again. Sixteen. On the trip, we passed the history museum and I wanted to stop at the art museum. But our tickets were for the building with old computers and early phones, the technology museum. Seventeen. I enjoy pop songs, and traditional music is important in my family. What I like best is when musicians mix old instruments with new sounds. Eighteen. I did not throw my old clothes away, and I only gave a few buttons to the charity shop. Most of the fabric became a new bag, so I made the clothes into something new. Nineteen. My grandfather worked on a farm as a child, and he built his own house later. But his real job for many years was teaching. Twenty. I wanted headphones, and my brother suggested a camera. My parents chose something I can wear and use for messages. I got a smartwatch.
'@
  $audioScriptOverrides['ket_test2_tts/test2_part5.wav'] = @'
Narrator: KET Test Two, Listening Part Five. Listen to a teacher talking about history project topics. Nina first asked for Ancient Rome, but Carlos needed the Roman topic for another class. Nina will study Ancient Egypt. Carlos then chose the Vikings because he found a diary-style text about sea journeys. Hana likes buildings, but Jake has already chosen medieval castles, so Hana will take Ancient Greece. Jake, keep medieval castles and focus on daily life inside them. Petra wanted the Stone Age at first, but her family has old photographs from the nineteenth century, so Petra will study the Victorian era. Narrator: Now listen again. Nina first asked for Ancient Rome, but Carlos needed the Roman topic for another class. Nina will study Ancient Egypt. Carlos then chose the Vikings because he found a diary-style text about sea journeys. Hana likes buildings, but Jake has already chosen medieval castles, so Hana will take Ancient Greece. Jake, keep medieval castles and focus on daily life inside them. Petra wanted the Stone Age at first, but her family has old photographs from the nineteenth century, so Petra will study the Victorian era.
'@

  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part1.wav'] = @'
Narrator: Flyers Exam One, Listening Part One. Listen and draw lines. There is one example. Tom is the boy playing football. Now listen. One. Sarah was near the gate earlier, and she was also holding a small black object, so the gate is a tempting place to look. But when the flowers opened, she moved across the grass and bent down beside them. The child you need is the girl taking photos of flowers. Two. Grandpa Jack brought a newspaper because he thought he might sit on the bench. Then he saw the lake was calm, put the newspaper away, and stayed by the water with his fishing rod. Three. Aunt Maria is not the woman with shopping bags. Listen for what she is trying not to drop. She is moving slowly because she is carrying the cake. Four. Cousin Ben first helped put cups on the blanket. After that, everyone looked up because he had climbed into the tree. Draw the line to the boy in the tree. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part2.wav'] = @'
Narrator: Flyers Exam One, Listening Part Two. Listen and write. Teacher: The new student says her old school had about two hundred children. Our school had three hundred last year, but after the new class opened the number became three hundred and fifty. Her favourite lesson changed too. She liked ordinary science before, but now she prefers the lesson where students use programs and solve problems, computer science. The friend who writes to her from her old town is Aylin, but the first person who helped her find the classroom here was Elif. Lunch was at twelve fifteen in September. The timetable changed, so the bell now rings at twelve thirty. Finally, she tried art club, and she watched football club, but the one she actually joined was the cooking club. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part3.wav'] = @'
Narrator: Flyers Exam One, Listening Part Three. Choose the correct picture. One. They talk about an old door and a picnic place, but those were only ideas for later. The place they really visited had animals and a ticket office, so choose A. Two. The rocket picture is mentioned because it looks exciting. The teacher says excitement is not enough; the correct picture shows the computer and information table, so choose B. Three. The red jacket was cheaper and the blue one looked nicer. At the end, the girl chose the warmer coat because the weather changed. That is picture B. Four. The train was cancelled, and the car park was full. Listen to the final plan: they used the third picture, C. Five. The cake and sandwich are both mentioned, but the homework was about a meal from another country. Choose picture C. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part4.wav'] = @'
Narrator: Flyers Exam One, Listening Part Four. Listen and match. Emma packed a towel because she expected the beach. When rain arrived, the family chose the zoo instead. Tom carried a football bag in the morning, but the pool reopened, so he went swimming. Lucy nearly watched a film. Then her cousin called and she went to a party. Jack wanted computer games after lunch. His dad needed help in the kitchen, so Jack helped him cook. Mia planned to go shopping, but her aunt was late. She stayed home and painted a picture. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part5.wav'] = @'
Narrator: Flyers Exam One, Listening Part Five. Listen and colour or write. One. There is a pencil and a ruler on the desk. The pencil is not the answer. Colour the ruler blue. Two. Do not write on the poster. Write HELLO on the classroom board. Three. The small sports bag is next to the door, but leave it white. Colour the backpack green. Four. There are two books. Find the small book near the chair and write the number five on it. Five. The sun stays orange. The star above the poster is the one to colour yellow. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part1.wav'] = @'
Narrator: Flyers Exam Two, Listening Part One. Listen and draw lines. Dr Wilson is the man in a white coat outside the building. Now listen. One. Mrs Chen is near the supermarket, but she is not the woman waiting empty-handed near the bus stop. She has finished shopping and is carrying two bags. Two. Harry walked with his bicycle at first because the street was crowded. At the end of the picture, he is riding it and wearing his sister's helmet. Three. Grandma Rose looked at the cafe but did not sit there. She chose the quieter bench and is reading a newspaper. Four. Officer Kaya is not talking to the shopkeeper. Look at the person in uniform whose hands are telling the cars when to stop and go. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part2.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Two. Listen and write. Teacher: The Blue River Team had eighteen students in the first meeting. After the assembly, seven more joined, so the number is twenty-five. They do not collect water from the tap because that would waste clean water. Rain runs down from the roof, and that is where they collect it. At first they used the water for small trees, but this term it is for watering the school garden. The meeting day changed too. It was Tuesday last year; now the free afternoon is Thursday. Their next project is not planting flowers. The final plan is cleaning the beach, or a beach clean-up. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part3.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Three. Choose the correct picture. One. Defne wanted to run outside, but the rain changed her plan. The correct picture is the quiet exercise she did at home, A. Two. Kerem planned to read, and he looked at the television too, but his tooth hurt. He went to bed early, picture B. Three. Nurse Ayse had a bag with medicine, but the lesson was not about medicine. She showed children how to brush their teeth, so choose B. Four. Mr Demir usually takes the bus. That day the roads were busy, so at the end he used his bicycle. Choose C. Five. Zeynep bought no cake and made no sandwich. She cut vegetables and made soup, picture C. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part4.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Four. Listen and match. Defne had her trainers ready for the park, but it rained before breakfast. She did yoga at home. Kerem started another chapter of his book, then his tooth hurt more, so he went to bed early. Nurse Ayse brought a big bag, but her main activity was teaching children about brushing teeth. Mr Demir left the car at home because the journey was short; he rode his bicycle. Zeynep did not buy lunch from the shop. She made vegetable soup at home. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part5.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Five. Listen and colour or write. One. There is a car and a bus near the traffic lights. Do not colour the car. Colour the bus green. Two. The building next to the park is not the museum. Write LIBRARY on that building. Three. Leave the river alone. The bridge over it should be blue. Four. The number is not for the shop window. Write the number seven on the post office door. Five. Do not colour the whole mosque. Colour only the roof yellow. Narrator: Now listen again.
'@

  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part2.wav'] = @'
Narrator: Flyers Exam One, Listening Part Two. Listen and write. Teacher: We are talking to a new student today. Girl: My old school was smaller, about two hundred children. Teacher: And this school? Girl: It had three hundred last year, but after the new class opened, now there are three hundred and fifty. Teacher: What is your favourite subject? Girl: I liked ordinary science before. Now I prefer computer science because we solve problems with programs. Teacher: Who helped you on your first day? Girl: Aylin writes from my old town, but here it was Elif. Teacher: And lunch? Girl: It was twelve fifteen in September, but now it starts at twelve thirty. Teacher: Which club did you join? Girl: I tried art and watched football, but finally I joined the cooking club. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part3.wav'] = @'
Narrator: Flyers Exam One, Listening Part Three. Choose the correct picture. One. Boy: Did they visit the old door? Girl: No, that was only an idea. They went to the place with animals and a ticket office, so choose A. Two. Teacher: The rocket looks exciting. Boy: But the lesson was about information. Teacher: Exactly, choose the computer and data table, B. Three. Girl: The red jacket was cheaper. Boy: Then why not that one? Girl: The weather changed, so she chose the warmer coat, picture B. Four. Boy: First they planned the train. Girl: Then it was cancelled and the car park was full. Boy: So they used the third picture, C. Five. Girl: The cake and sandwich are mentioned. Boy: But the homework asks for a meal from another country. Girl: Choose C. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam1_tts/flyers_exam1_part4.wav'] = @'
Narrator: Flyers Exam One, Listening Part Four. Listen and match. Teacher: What did Emma do? Girl: She packed a towel for the beach, but rain came, so she went to the zoo. Teacher: And Tom? Boy: He carried a football bag, but the pool reopened. He went swimming. Teacher: Lucy? Girl: She nearly watched a film, then her cousin called and she went to a party. Teacher: What about Jack? Boy: He wanted computer games, but he helped his dad cook. Teacher: And Mia? Girl: Her aunt was late for shopping, so Mia stayed home and painted a picture. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part2.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Two. Listen and write. Teacher: How many students are in the Blue River Team now? Boy: At first there were eighteen. Seven more joined after the assembly, so now there are twenty-five. Teacher: Where do they collect water? Boy: Not from the tap. Rain runs down from the roof, so they collect it there. Teacher: What do they use it for? Boy: Last term it was small trees. This term it is for watering the school garden. Teacher: Which day do they meet? Boy: It was Tuesday, but now it is Thursday. Teacher: What is the next project? Boy: Not planting flowers. The final plan is cleaning the beach, a beach clean-up. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part3.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Three. Choose the correct picture. One. Girl: Defne wanted to run outside. Boy: But the rain changed her plan. Girl: She did quiet exercise at home, A. Two. Boy: Kerem planned to read and looked at the television. Girl: But his tooth hurt. Boy: He went to bed early, B. Three. Teacher: Nurse Ayse had medicine in her bag. Girl: Was the lesson about medicine? Teacher: No, she taught brushing teeth, so choose B. Four. Boy: Mr Demir usually takes the bus. Girl: The roads were busy, so he rode his bicycle, C. Five. Girl: Zeynep bought no cake and made no sandwich. Boy: She cut vegetables and made soup, picture C. Narrator: Now listen again.
'@
  $audioScriptOverrides['flyers_exam2_tts/flyers_exam2_part4.wav'] = @'
Narrator: Flyers Exam Two, Listening Part Four. Listen and match. Teacher: What did Defne do? Girl: Her trainers were ready for the park, but it rained, so she did yoga at home. Teacher: Kerem? Boy: He started another chapter, then his tooth hurt more. He went to bed early. Teacher: Nurse Ayse? Girl: She brought a big bag, but mainly taught brushing teeth. Teacher: Mr Demir? Boy: He left the car at home and rode his bicycle. Teacher: Zeynep? Girl: She did not buy lunch. She made vegetable soup at home. Narrator: Now listen again.
'@

  $audioScriptOverrides['impact2_ket_exam1_tts/impact2_ket_exam1_part1.wav'] = $audioScriptOverrides['impact2_ket_exam1_tts/impact2_ket_exam1_part1.wav'].Replace('Teacher: So which one helps students see the announcement quickly? Maya: The blue poster. It is not my favourite colour, but it is the clearest for the corridor.', 'Teacher: From the corridor, which one is still clear after you stop looking at the colours? Maya: The red one shouts, the green one hides, and the yellow one hurts my eyes. So the one I will actually use is the blue poster.')
  $audioScriptOverrides['impact2_ket_exam1_tts/impact2_ket_exam1_part2.wav'] = @'
Narrator: You will hear a teacher talking about Science Week. Listen and write one word or a number. Teacher: Yesterday's notice was wrong in five small ways. It said Science Day, but activities run all week, so write Week. The display is not in the hall because exams are there, and the computer room is too small; it will be in the library. The health visitor is not the doctor we expected. A nurse is coming. The quiz does not need a ticket or money; bring the small card from reception. Finally, no spare paper is available, so bring a notebook. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam1_tts/impact2_ket_exam1_part3.wav'] = @'
Narrator: You will hear two students discussing a digital safety project. Tom: Passwords are too obvious. Ella: Exactly. We need students to infer risk from details. Tom: The friendly screenshot first, then the strange link? Ella: The link is a clue, but the stronger clue is that the name, photo and message do not quite match. Tom: So the topic is not simply passwords. Ella: No, it is judging whether online information is reliable. At the end, students write one action: pause before replying to a strange message. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam1_tts/impact2_ket_exam1_part4.wav'] = @'
Narrator: You will hear five people talking about a school exhibition. Speaker 1: The colour display looked like art until the final shop example showed how colour persuades buyers. Speaker 2: Phones were mentioned many times, but the result depended on where the phone was kept at night. Speaker 3: Passwords appeared on the screen, yet the last message showed why checking ordinary-looking messages matters. Speaker 4: The ocean photos were beautiful, but the quiet final panel explained that careful scientists protect fragile places. Speaker 5: We expected a poster, then the teacher chose one drawing because it let the class compare emotions clearly. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam1_tts/impact2_ket_exam1_part5.wav'] = @'
Narrator: You will hear a teacher matching students to exhibition topics. Elif mentions posters, but her final question is how shop colours influence buyers: Colours in advertising. Murat talks about phones and homework, but he measures tiredness after different bedtimes: Sleep and health. Deniz begins with passwords, but the key task is recognising unsafe messages: Digital safety. Sara uses photographs that look like travel pictures, yet the notes are about recording life below the sea: Underwater discovery. Nisa mentions stories and feelings, but her evidence is about memory and decisions: Brain and emotions. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam2_tts/impact2_ket_exam2_part1.wav'] = @'
Narrator: You will hear five short conversations. One. The desert and rainforest pictures are compared first, but the project question is about saving energy in extreme cold; choose the polar place. Two. Soup is the final product and fruit is for display, but the first food in the experiment is bread. Three. Outside the station is too wet and the bus stop is too far; students wait under the station roof. Four. In the emergency practice, they did not run outside first. They looked for the emergency bags. Five. The storm story has strong pictures, but the magazine needs decisions in danger, so choose the survival story. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam2_tts/impact2_ket_exam2_part2.wav'] = @'
Narrator: You will hear a notice about Ready Week. Teacher: The title is not Ready Day because the event lasts from Monday to Friday; write Week. The first room was the classroom, but the final room is the lab. A firefighter cannot visit, so the Wednesday visitor is an artist. The team considered salad and sandwiches, but the food they test is soup. For the emergency walk, coats are useful, but the required item is shoes with a safe grip. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam2_tts/impact2_ket_exam2_part3.wav'] = @'
Narrator: You will hear two students planning a food waste presentation. Leyla: If we start with soup, people think it is only cooking. Kerem: So our first idea is too simple? Leyla: Yes. We need evidence. Kerem: Student opinions? Leyla: Later. The first slide should show a number from school. Then we add a short comparison and ask students to choose one action for a week. Kerem: Cartoon? Leyla: No, a graph will make the waste clearer. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam2_tts/impact2_ket_exam2_part4.wav'] = @'
Narrator: You will hear five people talking about a unit project. Speaker 1: The boots and maps were interesting, but the best part explained survival clearly. Speaker 2: I blamed careless students first, but the evidence showed how much food is taken at the start matters. Speaker 3: The mural looked decorative, then the final question showed that art can start a public discussion. Speaker 4: The emergency leader stayed calm, and that helped everyone understand. Speaker 5: The story was short because each word had to be useful. Narrator: Now listen again.
'@
  $audioScriptOverrides['impact2_ket_exam2_tts/impact2_ket_exam2_part5.wav'] = @'
Narrator: You will hear a teacher matching students to magazine topics. Ece compares difficult habitats, so her topic is Extreme animals. Ali starts with a recipe, but his evidence is cafeteria waste: Food waste. Zeynep uses walls and colour to send a message in a shared space: Public art. Baran writes about storms, bags and meeting points: Disaster preparation. Irem writes very short stories with implied endings: Flash fiction. Narrator: Now listen again.
'@

  $impactAudioMapEntries = New-Object System.Collections.Generic.List[string]
  $wavEntries = $zip.Entries | Where-Object { $_.FullName.StartsWith($root) -and $_.FullName.EndsWith('.wav') }
  foreach ($entry in $wavEntries) {
    $relative = $entry.FullName.Substring($root.Length).Replace('\', '/')
    $stream = $entry.Open()
    try {
      $memory = New-Object System.IO.MemoryStream
      try {
        $stream.CopyTo($memory)
        $audioBytes = $memory.ToArray()
        if ($audioScriptOverrides.ContainsKey($relative)) {
          $overrideBytes = Get-AudioOverrideBytes -RelativePath $relative -Text $audioScriptOverrides[$relative]
          if ($overrideBytes) {
            $audioBytes = $overrideBytes
          }
        }
        $uri = New-DataUri -Bytes $audioBytes -Mime 'audio/wav'
        if ($relative.StartsWith('impact2_ket_exam')) {
          $impactAudioMapEntries.Add('"' + $relative.Replace('\', '\\').Replace('"', '\"') + '":"' + $uri + '"')
        }
        $html = $html.Replace('src="' + $relative + '"', 'src="' + $uri + '" data-audio-file="' + $relative + '"')
        $html = $html.Replace('href="' + $relative + '"', 'href="' + $uri + '" data-audio-file="' + $relative + '"')
      } finally {
        $memory.Dispose()
      }
    } finally {
      $stream.Dispose()
    }
  }

  $html = $html.Replace('__IMPACT_AUDIO_MAP__', '{' + (($impactAudioMapEntries.ToArray()) -join ',') + '}')

  $html = $html.Replace('<title>BAYETAV Cambridge Exam</title>', '<title>BAYETAV Tek HTML Sistem</title>')
  $html = $html.Replace('<h1>BAYETAV Cambridge Exam</h1>', '<h1>BAYETAV Tek HTML Sistem</h1>')

  [System.IO.File]::WriteAllText($outPath, $html, [System.Text.UTF8Encoding]::new($false))
  Write-Host "Wrote $outPath"
  Write-Host ("Size MB: {0:N1}" -f ((Get-Item -LiteralPath $outPath).Length / 1MB))
} finally {
  $zip.Dispose()
}
