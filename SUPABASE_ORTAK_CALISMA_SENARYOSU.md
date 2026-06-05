# BAYETAV Supabase ortak calisma senaryosu

Bu senaryoda mevcut BAYETAV HTML sitesi Vercel uzerinde kalir, notlar ise Google Sheets yerine Supabase PostgreSQL veritabaninda tutulur. Boylece farkli ogretmenler ayni siteye girip ayni sinav notlarini gorebilir, guncelleyebilir ve raporlayabilir.

## Hedef

- Her sinav icin 120 ogrencilik not tablosu ortak veritabanina kaydedilir.
- Writing /30, KET ve Impact Reading /30, Flyers Reading /49, Listening /25, Speaking /15 yapisi korunur.
- Bir ogretmen not girince diger ogretmenler ayni veriyi gorebilir.
- Istenirse Google Sheets sadece yedek/rapor ciktisi olarak devam eder.
- Vercel linki sadece arayuz olur; kalici veri Supabase tarafinda durur.

## Onerilen mimari

1. Vercel statik site
   - Mevcut `web-site/index.html` aynen yayinda kalir.
   - Supabase URL ve publishable anon key HTML icine eklenir.

2. Supabase Auth
   - Ogretmenler e-posta ile giris yapar.
   - En basit yol: magic link veya e-posta/sifre.
   - Sadece `bayetav.k12.tr` uzantili hesaplara izin verilmesi onerilir.

3. Supabase Database
   - `students`: ogrenci kayitlari.
   - `exam_scores`: ogrenci + sinav bazli puanlar.
   - `score_audit_log`: kimin hangi notu ne zaman degistirdigi.

4. Row Level Security
   - Supabase docs'a gore tarayicida publishable/anon key kullanmak guvenlidir, ama tablolar icin Row Level Security aktif olmali.
   - Ogretmenler sadece authenticated kullanici olarak veri okuyup yazabilir.
   - Public/anon kullanici notlari goremez.

5. Opsiyonel Edge Function
   - Daha kontrollu kayit icin `save-score` edge function kullanilabilir.
   - Secret key browser'a konmaz; Edge Function veya Supabase server tarafinda tutulur.

Kaynak notu: Supabase, RLS ile veri guvenligini Postgres seviyesinde uygular; Edge Functions server-side TypeScript fonksiyonlari olarak calisir; function secrets tarayiciya konmamasi gereken anahtarlar icin kullanilir.

## Uygulama asamalari

### Asama 1 - Supabase projesi

1. Supabase'te yeni proje ac.
2. Project URL ve publishable anon key'i al.
3. Authentication > Providers > Email aktif kalsin.
4. Authentication ayarlarinda Site URL olarak Vercel adresini gir:
   `https://web-site-snowy-omega.vercel.app`
5. Redirect URL listesine ayni domaini ekle.

### Asama 2 - Veritabani kurulumu

Supabase SQL Editor'de `supabase/schema.sql` dosyasindaki SQL'i calistir.

Kurulumdan sonra su tablolar olusur:

- `students`
- `exam_scores`
- `score_audit_log`

### Asama 3 - Mevcut HTML'e eklenecek ekran

Mevcut skor tablosunun ustune su kontroller eklenir:

- Supabase URL
- Supabase anon key
- Ogretmen e-postasi
- Gonderilen magic link / giris butonu
- "Supabase'den notlari yukle"
- "Degisiklikleri Supabase'e kaydet"
- Baglanti durumu

Ilk kullanimda URL ve anon key `localStorage` icine kaydedilebilir. Daha temiz yontem Netlify environment variable kullanip build surecinde HTML'e yazmaktir; ama mevcut tek HTML yapisinda localStorage pratik olur.

### Asama 4 - Veri akisi

1. Ogretmen siteyi acar.
2. Supabase'e e-posta ile giris yapar.
3. Sistem `exam_scores` tablosundan notlari ceker.
4. Ogretmen notlari degistirir.
5. "Kaydet" ile her dolu satir `upsert` edilir.
6. Diger ogretmen "Yukle" dediginde ayni notlari gorur.

### Asama 5 - Ortak calisma davranisi

Basit mod:
- Sayfa acilinca notlar yuklenir.
- Ogretmen kaydedince veritabanina yazilir.
- Diger ogretmen sayfayi yeniler veya "Yukle" der.

Canli mod:
- Supabase Realtime aktif edilir.
- Bir ogretmen kaydedince diger ekranlara otomatik yansir.
- Bu sonraki asama olarak dusunulebilir; ilk surum icin gerekli degil.

## Veri kurallari

Puan sinirlari:

- `writing_score`: 0-30
- `reading_score`: 0-30
- `listening_score`: 0-25
- `speaking_score`: 0-15
- `total_score`: otomatik hesaplanir.

Her sinavda ayni ogrenci icin tek kayit:

- `unique(exam_id, student_no)`

Bu sayede ayni satir tekrar kaydedilirse yeni satir acmaz, mevcut notu gunceller.

## Guvenlik modeli

Minimum guvenli model:

- RLS aktif.
- `authenticated` kullanicilar okuyabilir/yazabilir.
- Anon/public kullanicilar okuyamaz/yazamaz.
- Gerekirse e-posta domain kontrolu policy'ye eklenir.

Daha kontrollu model:

- `profiles` tablosu acilir.
- Her ogretmene `teacher` veya `admin` rol verilir.
- Sadece `teacher/admin` rolu olanlar yazabilir.

## Google Sheets ile birlikte kullanma

Supabase ana kaynak olur.

Google Sheets iki sekilde kalabilir:

1. Manuel rapor:
   - Mevcut "Google Sheets'e gonder" butonu korunur.
   - Ogretmen istediginde Supabase'teki notlari Sheets'e aktarir.

2. Otomatik yedek:
   - Supabase Edge Function veya scheduled job Google Sheets API'ye yedek atar.
   - Bu daha ileri seviye kurulumdur.

## Avantajlar

- App token bitse bile ortak calisma devam eder.
- Netlify sadece arayuz oldugu icin veri kaybi olmaz.
- Sheets kotasi veya Apps Script yetkisi sorun olursa notlar Supabase'te kalir.
- Kimin neyi degistirdigi audit log ile izlenebilir.

## Dikkat edilmesi gerekenler

- Supabase service role key asla HTML icine konmamalidir.
- Browser tarafinda sadece publishable/anon key kullanilir.
- RLS kapali kalirsa veriler aciga cikabilir; SQL dosyasi RLS'i aktif eder.
- Okul hesaplariyla kullanim icin Auth ayarlari dogru yapilmalidir.

## Benim onerim

Ilk surum icin en temiz yol:

1. Supabase projesi acilir.
2. `supabase/schema.sql` calistirilir.
3. HTML'e Supabase giris/kaydet/yukle paneli eklenir.
4. Netlify'ye tekrar deploy edilir.
5. 2 ogretmenle test edilir.

Bu calisinca ikinci asamada Realtime ve otomatik Sheets yedegi eklenir.
