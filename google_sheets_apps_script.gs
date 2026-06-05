const SHEET_NAME = 'BAYETAV Notlari';
const SPREADSHEET_ID = '1gC6ddtzDnogFWtaSKWUDgLfK9v-cQLZG-LJC7mHqfLg';
const HEADERS = [
  'Exported At',
  'Exam ID',
  'Exam',
  'Student',
  'Class',
  'Writing /30',
  'Reading',
  'Listening /25',
  'Speaking /15',
  'Total',
  'Percent',
  'Band',
  'Notes'
];

function doPost(e) {
  const payload = JSON.parse(e.postData.contents || '{}');
  const rows = Array.isArray(payload.rows) ? payload.rows : [];
  const sheet = getSheet_();
  const existing = buildIndex_(sheet);

  rows.forEach((item) => {
    const values = [
      payload.exportedAt || new Date().toISOString(),
      item.examId || '',
      item.exam || '',
      item.student || '',
      item.className || '',
      item.writing || 0,
      item.reading || 0,
      item.listening || 0,
      item.speaking || 0,
      item.total || 0,
      item.percent || 0,
      item.band || '',
      item.notes || ''
    ];
    const key = rowKey_(item.examId, item.student, item.className);
    const rowNumber = existing[key];
    if (rowNumber) {
      sheet.getRange(rowNumber, 1, 1, HEADERS.length).setValues([values]);
    } else {
      sheet.appendRow(values);
    }
  });

  return ContentService
    .createTextOutput(JSON.stringify({ ok: true, rows: rows.length }))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet() {
  return ContentService
    .createTextOutput(JSON.stringify({ ok: true, message: 'BAYETAV Sheets endpoint is ready.' }))
    .setMimeType(ContentService.MimeType.JSON);
}

function getSheet_() {
  const spreadsheet = SpreadsheetApp.openById(SPREADSHEET_ID);
  let sheet = spreadsheet.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = spreadsheet.insertSheet(SHEET_NAME);
  }
  const currentHeaders = sheet.getRange(1, 1, 1, HEADERS.length).getValues()[0];
  const missingHeaders = HEADERS.some((header, index) => currentHeaders[index] !== header);
  if (missingHeaders) {
    sheet.getRange(1, 1, 1, HEADERS.length).setValues([HEADERS]);
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function buildIndex_(sheet) {
  const lastRow = sheet.getLastRow();
  const index = {};
  if (lastRow < 2) return index;
  const values = sheet.getRange(2, 1, lastRow - 1, HEADERS.length).getValues();
  values.forEach((row, offset) => {
    const key = rowKey_(row[1], row[3], row[4]);
    if (key) index[key] = offset + 2;
  });
  return index;
}

function rowKey_(examId, student, className) {
  return [examId, student, className]
    .map((value) => String(value || '').trim().toLowerCase())
    .join('|');
}
