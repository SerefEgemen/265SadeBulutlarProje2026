# DENETİM RAPORU — Çok Oyunculu Basys3 Refleks Oyunu

**Tarih:** 2026-08-02  
**Kapsam:** Tüm proje dosyaları — modül bazlı analiz  

---

## 0. Genel Durum Özeti

| # | Modül | Dosya | Top'a Bağlı? | Genel Durum |
|---|-------|-------|:---:|---|
| 1 | `Main` | 1_Main.v | — | ⚠️ Eksik bağlantılar |
| 2 | `ConfigMenu` | 2_ConfigMenu.v | ✅ | 🟢 Küçük iyileştirmeler |
| 3 | `segmentDisplay7` | 3_7segmentDisplay.v | ❌ | 🟡 Bağlanmamış |
| 4 | `lfsr16` | 4.1_lfsr16.v | ✅ | 🟢 Temiz |
| 5 | `random_delay_gen` | 4.2_RSO.v | ✅ | 🟢 Temiz |
| 6 | `debounce` | 5.1_Debounce.v | ✅ | 🟢 Çalışır |
| 7 | `TusKontrolu` | 5.2_TusKontrolu.v | ✅ | 🟢 Çalışır |
| 8 | `gameLoop` | 6_Main_Game_Loop.v | ❌ | 🔴 Sıfırdan yazılacak |
| 9 | `ScoreCalc` | 7.1_ScoreCalc.v | ❌ | 🟡 Blocking/NB karışımı |
| 10 | `ScoreCalcEndgame` | 7.2_ScoreCalcEndgame.v | ❌ | 🟡 Hesaplama sorunu |
| 11 | `playerLEDs` | 8.1_playerLEDs.v | ❌ | 🟢 Düzeltildi |
| 12 | `playerLEDsEndgame` | 8.2_playerLEDsEndgame.v | ❌ | 🟢 Düzeltildi |
| — | Testbench | 4tb_nrsotb.v | — | 🟢 Çalışır |
| — | XDC | 0.5_basys3Assigning.xdc | — | 🟡 `RsRx` sorunu |
| — | UART | — | — | 🔴 Hiç yazılmamış |

---

## 1. `Main` — [1_Main.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/1_Main.v)

### 🟢 Doğru Yapılanlar
- Port tanımları (`clk`, `sw`, `btnX`, `led`, `seg`, `an`, `dp`, `RsTx`) XDC ile uyumlu.
- `debounce dbC` → ayrı wire (`centerForConfigSpecifically`) ile multi-driver sorunu çözüldü. ✅
- `ConfigMenu`, `TusKontrolu`, `lfsr16`, `random_delay_gen` doğru örneklenmiş ve bağlı.
- LED multiplexer eklendi: `assign led = ((confinish) ? ledsGame : ledsConfig);` ✅

### 🔴 Kritik Eksikler
- **6 modül bağlanmamış:** `segmentDisplay7`, `gameLoop`, `ScoreCalc`, `ScoreCalcEndgame`, `playerLEDs`, `playerLEDsEndgame`. Hiçbiri örneklenmemiş.
- **`seg[6:0]` ve `an[3:0]` askıda:** Wire tanımlı, hiçbir modüle bağlı değil → display çalışmaz.
- **`RsTx` askıda:** Port var, mantık yok → sentezde uyarı.
- **`ledsGame` 1 bit wire:** `wire ledsGame;` → 1 bit. Olması gereken: `wire [15:0] ledsGame;`.
- **UART modülü yok:** Şartname zorunlu tutmasına rağmen hiç yazılmamış.
- **Ana oyun FSM'i yok:** Konfigürasyon → oyun → tur sonu → endgame akışını yöneten bir mekanizma mevcut değil.

### 🟡 İyileştirme
- `random_delay_gen`'in `tetiklenme` girişi şu an `center`'a bağlı. gameLoop yazıldığında bu bağlantı gameLoop'un kontrol sinyaline çevrilmeli.

---

## 2. `ConfigMenu` — [2_ConfigMenu.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/2_ConfigMenu.v)

### 🟢 Doğru Yapılanlar
- Senkron reset düzgün çalışıyor.
- Switch eşleştirmeleri (sw[0-2] → oyuncu, sw[4-7] → tur, sw[9] → eleme, sw[11] → zorluk) şartnameyle uyumlu.
- Bit-slice yönü düzeltildi: `leds[2:0]`, `leds[7:4]` ✅
- `finished` sinyali latching doğru — bir kez 1 olduktan sonra `else if(!finished)` bloğu tekrar çalışmaz.

### 🟡 İyileştirme
- **Atanmayan LED bitleri:** Bit 3, 8, 10, 12-14 hiçbir yerde atanmıyor. Reset'te sıfırlandığından genellikle sorun çıkarmaz ama bit 15 (reset LED'i) konfigürasyon sırasında yanık kalabilir. Bloğun başına `leds <= 16'b0;` eklenebilir.

---

## 3. `segmentDisplay7` — [3_7segmentDisplay.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/3_7segmentDisplay.v)

### 🟢 Doğru Yapılanlar
- Hane döngüsü mantığı (`milisaniyesayaci` + `haneSayici`) doğru tasarlanmış — 1ms aralıklarla hane değişimi insan gözüne eşzamanlı görünür.
- `bitisSinyali` tek cycle pulse olarak doğru üretiliyor (sayac == 399_999_999'da 1, sonraki cycle'da 0).
- Tur numarasının LSB'sine göre 1-2-3-4 / 5-6-7-8 gösterimi şartnameyle uyumlu.
- Reset ve karartma durumunda display doğru kapatılıyor (`an = 4'b1111`, `seg = 7'b1111111`).

### 🟡 İyileştirmeler
- **`hane` kombinasyonel + senkron karışımı:** `hane` register'ı `always@(*)` içinde atanıp `always@(posedge clk)` içinde okunuyor. Sentez aracı bunu genellikle kabul eder ama `hane`'yi ayrı bir kombinasyonel wire olarak tanımlamak daha güvenli.
- **`haneSayici` bloğundaki `if` zincirleri:** `if(hane == 2'd1)`, `if(hane == 2'd2)`, `if(hane == 2'd3)` ayrı `if` bloklarıyla yapılmış. `else if` kullanılması daha güvenli (birden fazla bloğun tetiklenmesini önler).
- **Comment'te "LSFR" yazılmış:** Doğrusu "LFSR".
- **Top modüle bağlanmamış:** `seg`, `an` portları `Main`'de wire olarak tanımlı ama hiçbir modüle bağlı değil.

---

## 4. `lfsr16` — [4.1_lfsr16.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/4.1_lfsr16.v)

### 🟢 Doğru Yapılanlar
- Maximal-length polinom (x^16 + x^14 + x^13 + x^11 + 1) doğru uygulanmış. Periyot = 2^16 - 1.
- Sıfırdan farklı seed (`0xACE1`) — all-zero durumuna düşme riski yok.
- Senkron reset, sürekli çalışma (enable yok) — şartnameyle tam uyumlu.
- Kod temiz, kısa ve doğru.

**Hata tespit edilmedi.**

---

## 5. `random_delay_gen` — [4.2_RSO.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/4.2_RSO.v)

### 🟢 Doğru Yapılanlar
- 3 aşamalı pipeline doğru tasarlanmış: snapshot → çarpma → ölçekleme + toplama.
- Kolay mod (2.0s–5.0s) ve zor mod (0.5s–5.0s) sınırları şartnameyle uyumlu.
- Zorluk seçimi kombinasyonel blokta, pipeline senkron blokta — temiz ayrım.
- `sure_bekleme_gecerli` tek cycle pulse.

### 🟡 İyileştirme
- **`sure_bekleme_gecerli` pulse kaçırma riski:** Tüketici modül (gameLoop) bu pulse'u yakalamazsa değer kaybolur. `sure_bekleme` register'ı kalıcı olduğundan değerin kendisi silinmez, ama geçerlilik sinyalinin FSM'de doğru durumda yakalanması gerekir.

---

## 6. `debounce` — [5.1_Debounce.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/5.1_Debounce.v)

### 🟢 Doğru Yapılanlar
- 50ms döngü + 20ms stabilite süresi makul debounce parametreleri.
- Reset (aktif-yüksek, `sw[15]`) şartnameyle uyumlu.
- Çıkış **seviye sinyali** — buton basılı olduğu sürece 1 kalır. `TusKontrolu` bunu kenar algılamayla pulse'a çevirir.

### 🟡 İyileştirme
- **Sayaç kontrolü gereksiz karmaşık:** Önce 5M kontrolü → sıfırla, sonra 2M kontrolü → sinyal ata. Çalışır ama akış kafa karıştırıcı. Tek eşik değerli basit bir tasarım daha okunaklı olurdu.

---

## 7. `TusKontrolu` — [5.2_TusKontrolu.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/5.2_TusKontrolu.v)

### 🟢 Doğru Yapılanlar
- Her buton için ayrı debounce modülü örneklenmiş.
- Kenar algılama (`eskiBTN == 0 && TemizlenmisBTN == 1`) doğru — tek cycle pulse üretiyor.
- BTNR ve BTND için `playerNO[2]` ve `playerNO[3]` kontrolü var — 2 oyuncu modunda 3. ve 4. buton devre dışı.
- Reset temiz.

### 🟡 İyileştirme
- **BTNU ve BTNL için `playerNO` kontrolü yok:** Oyuncu 1 ve 2 her zaman aktif kabul edilmiş. Minimum oyuncu sayısı 2 olduğundan pratikte sorun çıkarmaz ama `playerNO[0]` ve `playerNO[1]` kontrolü eklenirse daha tutarlı olur.

---

## 8. `gameLoop` — [6_Main_Game_Loop.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/6_Main_Game_Loop.v)

### 🔴 TAMAMEN YENİDEN YAZILMALI

Bu modül C tarzı yazılım mantığıyla yazılmıştır. Sentezlenemez, simüle bile düzgün çalışmaz.

| Satır | Yapı | Sorun |
|-------|------|-------|
| 55, 81 | `while(...)` | Sentezlenemez |
| 80 | `$time` | Sadece simülasyon |
| 108 | `#5` | Sadece simülasyon |
| 154 | `wait(BTNC)` | Sentezlenemez |
| 29-30 | `genvar` + `always` | `integer` kullanılmalı |
| 31 | `generate` (kapanmamış) | `endgenerate` eksik |
| 17 | `score[0:playerNo]` | Runtime dizi boyutu — sentezlenemez |
| 39 vs 41 | `=` ve `<=` karışık | Tanımsız davranış |

> Detaylı analiz için: [Module6_GameLoop_Analysis.md](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/Module6_GameLoop_Analysis.md)  
> Yeniden yazım rehberi için: [Module6_GameLoop_Rehber.md](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/Module6_GameLoop_Rehber.md)

---

## 9. `ScoreCalc` — [7.1_ScoreCalc.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/7.1_ScoreCalc.v)

### 🟢 Doğru Yapılanlar / Düzeltilenler
- Player 4 indeks hatası düzeltildi: `playersPenalized[4]` → `[3]`, `playersLeft[4]` → `[3]` ✅
- `player1newTotal` blocking/non-blocking karışımı düzeltildi: tüm `=` → `<=` ✅
- `playersPenalized` reset bloğuna eklendi ✅
- Genel puan hesaplama mantığı (1.=4p, 2.=3p, 3.=2p, 4.=1p) şartnameyle uyumlu.

### 🟡 İyileştirme — Sıralama Blocking/Non-Blocking Karışımı
Sıralama karşılaştırmalarında `player1Place = (player1Place + 1)` şeklinde **blocking** (`=`) kullanılıyor. Aynı `always @(posedge clk)` bloğunda diğer atamalar **non-blocking** (`<=`). Vivado bunu genellikle kabul eder ve ardışık artırımlar doğru çalışır, ama IEEE standardı açısından riskli.

**Önerilen çözüm:** Sıralama hesabını ayrı bir kombinasyonel `always @(*)` bloğuna taşıyıp register'a kaydetme.

### 🔴 Sürekli Çalışma Sorunu
Modül `always @(posedge clk)` ile her clock'ta çalışıyor. Oyun turları arasında tetiklenmeden de hesap yapıyor. Bir `start` / `enable` sinyali ile kontrol edilmesi gerekir.

---

## 10. `ScoreCalcEndgame` — [7.2_ScoreCalcEndgame.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/7.2_ScoreCalcEndgame.v)

### 🟢 Doğru Yapılanlar / Düzeltilenler
- `currentHighest` artık **blocking** (`=`) ile atanıyor → aynı cycle'da en yüksek skor doğru hesaplanıyor ✅
- Genel mantık (en yüksek skoru bul, eşleşenleri kazanan yap, beraberlik kontrol et) doğru.

### 🟡 İyileştirmeler
- **`tieFinder` boyut uyumsuzluğu:** `reg[3:0] tieFinder = 3'b000;` → boyut `[3:0]` (4 bit) ama başlangıç değeri `3'b000` (3 bit). Uyarı verir, fonksiyonel sorun yaratmaz ama `4'b0000` olmalı.
- **`currentWinners` non-blocking:** `currentWinners[X] <= 1'b1` non-blocking atanıyor. `currentHighest` blocking olduğu için doğru cycle'da karşılaştırma yapılabilir ama `currentWinners` bir cycle gecikir. Pratikte sürekli çalıştığı için 2. cycle'da doğru değer oturur — ama enable/start sinyali ile tetiklenirse bu gecikme sorun olabilir.
- **`currentHighest` ve `currentWinners` sıfırlanmıyor:** Her yeni çağrıda bu registerlar önceki değerlerini koruyor. Yeni oyun sonunda önceki oyunun verileri kirlilik yaratabilir.

### 🔴 Blocking + Non-Blocking Karışımı
Aynı `always @(posedge clk)` bloğunda `currentHighest` blocking, `currentWinners`/`tieFinder` non-blocking. IEEE standardı açısından tanımsız davranış riski.

---

## 11. `playerLEDs` — [8.1_playerLEDs.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/8.1_playerLEDs.v)

### 🟢 Doğru Yapılanlar / Düzeltilenler
- Copy-paste hatası düzeltildi: Player 3 → `player3Leds`, Player 4 → `player4Leds` ✅
- Sıralama → LED eşleştirmesi doğru (1.=4LED, 2.=3LED, 3.=2LED, 4.=1LED).
- Oyunda olmayan oyuncular (`!playersIn[X]`) ve cezalılar (`playersPenalized[X]`) için LED'ler sıfırlanıyor.
- Reset temiz.
- Top modüle bağlanmamış — bağlantı yapılmalı.

### 🟡 İyileştirme
- **1 cycle gecikme:** `playerXLeds` bir cycle'da hesalanıp sonraki cycle'da `leds`'e atanıyor. Pratikte görünmez ama bilinmeli.

---

## 12. `playerLEDsEndgame` — [8.2_playerLEDsEndgame.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/8.2_playerLEDsEndgame.v)

### 🟢 Doğru Yapılanlar / Düzeltilenler
- Kazanmayanların LED'leri `else` bloğuyla sıfırlanıyor ✅
- Beraberlik durumu destekleniyor (birden fazla `winners[X] = 1` olabilir).
- Reset temiz.
- Top modüle bağlanmamış — bağlantı yapılmalı.

**Hata tespit edilmedi.**

---

## 13. Testbench — [4tb_nrsotb.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/4tb_nrsotb.v)

### 🟢 Doğru Yapılanlar
- LFSR + random_delay_gen birlikte test ediliyor.
- Kolay mod (200M–500M) ve zor mod (50M–500M) sınır kontrolleri doğru.
- `task` yapısı ve `$finish` kullanımı temiz.

### 🟡 İyileştirme
- **Sonuç raporlama eksik:** `fail_sayi` ve `degisim_sayi` sadece waveform'da görülebiliyor. `$display` ile konsola yazdırılması faydalı olur.

---

## 14. XDC — [0.5_basys3Assigning.xdc](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/0.5_basys3Assigning.xdc)

### 🟢 Doğru Yapılanlar
- Standart Digilent Basys3 Master XDC baz alınmış.
- Clock (10ns / 100MHz), switch'ler, LED'ler, 7-segment, butonlar doğru.
- Pin eşleştirmeleri top modül port adlarıyla uyumlu.

### 🟡 İyileştirmeler
- **`RsRx` yorum satırında:** Satır 138'de `##` ile yorum yapılmış ama `RsTx` (satır 139) aktif. Top modülde `RsRx` girişi tanımlı değil. `RsTx`'i de yorum yapın ya da UART yazıldığında `RsRx`'i de aktifleştirin.

---

## 15. Yapılacaklar Özeti

### 🔴 Kritik (Projenin çalışması için zorunlu)

| # | Madde | Dosya | Durum |
|---|-------|-------|:---:|
| 1 | `gameLoop` sıfırdan FSM tabanlı yeniden yazılmalı | 6_Main_Game_Loop.v | ❌ |
| 2 | Top modülde 6 alt modül örneklenmeli ve bağlanmalı | 1_Main.v | ❌ |
| 3 | UART 9600 8N1 modülü yazılmalı | Yeni dosya | ❌ |
| 4 | Ana oyun FSM'i tasarlanmalı (veya gameLoop içine entegre) | — | ❌ |
| 5 | `ledsGame` wire boyutu düzeltilmeli (`wire` → `wire [15:0]`) | 1_Main.v | ❌ |
| 6 | `ScoreCalc`'a enable/start mekanizması eklenmeli | 7.1_ScoreCalc.v | ❌ |
| 7 | Reaksiyon süresi ölçüm sayacı (1ms çözünürlük) tasarlanmalı | gameLoop içinde | ❌ |
| 8 | 5 saniye timeout mekanizması | gameLoop içinde | ❌ |

### 🟡 Orta Öncelik

| # | Madde | Dosya | Durum |
|---|-------|-------|:---:|
| 9 | `ScoreCalc` sıralama mantığını kombinasyonel bloğa taşı | 7.1_ScoreCalc.v | ⚠️ |
| 10 | `ScoreCalcEndgame` blocking/NB karışımını gider | 7.2_ScoreCalcEndgame.v | ⚠️ |
| 11 | `ScoreCalcEndgame`'de `currentHighest`/`currentWinners` sıfırlama ekle | 7.2_ScoreCalcEndgame.v | ❌ |
| 12 | `ConfigMenu`'de atanmayan LED bitleri temizle | 2_ConfigMenu.v | ❌ |
| 13 | `segmentDisplay7`'de `hane` register'ını wire'a çevir | 3_7segmentDisplay.v | ❌ |
| 14 | XDC'de `RsRx`/`RsTx` durumunu netleştir | 0.5_basys3Assigning.xdc | ❌ |

### 🟢 Düşük Öncelik

| # | Madde | Dosya |
|---|-------|-------|
| 15 | Comment'te "LSFR" → "LFSR" düzelt | 3_7segmentDisplay.v |
| 16 | Top dosya başına şartname gereği switch/LED tablosu ekle | 1_Main.v |
| 17 | Testbench'e `$display` raporlama ekle | 4tb_nrsotb.v |
| 18 | Eleme modunda tek oyuncu kalınca erken bitiş mantığı | gameLoop |
| 19 | Dosyalardaki gereksiz boş satırlar ve ASCII art temizliği | Tüm dosyalar |
