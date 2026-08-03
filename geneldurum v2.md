# DENETİM RAPORU — Çok Oyunculu Basys3 Refleks Oyunu

**Tarih:** 2026-08-03 (Güncelleme)  
**Önceki Tarih:** 2026-08-02  
**Kapsam:** Tüm proje dosyaları — modül bazlı analiz  

---

## 0. Genel Durum Özeti

| # | Modül | Dosya | Top'a Bağlı? | Genel Durum |
|---|-------|-------|:---:|---|
| 1 | `Main` | 1_Main.v | — | 🟡 Büyük ilerleme, birkaç sorun kaldı |
| 2 | `ConfigMenu` | 2_ConfigMenu.v | ✅ | 🟢 Küçük iyileştirmeler |
| 3 | `segmentDisplay7` | 3_7segmentDisplay.v | ✅ **Düzeltildi** | 🟢 Bağlandı |
| 4 | `lfsr16` | 4.1_lfsr16.v | ✅ | 🟢 Temiz |
| 5 | `random_delay_gen` | 4.2_RSO.v | ✅ | 🟢 Temiz |
| 6 | `debounce` | 5.1_Debounce.v | ✅ | 🟢 Çalışır |
| 7 | `TusKontrolu` | 5.2_TusKontrolu.v | ✅ | 🟢 Çalışır |
| 8 | `gameLoop` | 6_GameLoop.v | ✅ **Düzeltildi** | 🟡 FSM yazıldı ama sorunlar var |
| 9 | `ScoreCalc` | 7.1_ScoreCalc.v | ✅ **Düzeltildi** | 🟡 Bağlandı, enable eklendi, B/NB karışımı sürüyor |
| 10 | `ScoreCalcEndgame` | 7.2_ScoreCalcEndgame.v | ✅ **Düzeltildi** | 🟡 Sıfırlama eklendi, B/NB karışımı sürüyor |
| 11 | `playerLEDs` | 8.1_playerLEDs.v | ✅ **Düzeltildi** | 🟢 Bağlandı |
| 12 | `playerLEDsEndgame` | 8.2_playerLEDsEndgame.v | ✅ **Düzeltildi** | 🟢 Bağlandı |
| 13 | `UART_Controller` | 9.1_uart.v | ✅ **YENİ** | 🟡 Yazıldı, eksikler var |
| 14 | `UART_TX` | 9.2_uart_tx.v | ✅ **YENİ** | 🟡 Yazıldı, sorunlar var |
| 15 | `Binary_to_BCD` | 9.3_bcd.v | ✅ **YENİ** | 🟢 Çalışır |
| — | Testbench | 4tb_nrsotb.v | — | 🟢 Çalışır |
| — | XDC | 0.5_basys3Assigning.xdc | — | 🟡 `RsRx` yorum satırında (sadece TX kullanıldığı için OK) |

---

## 1. `Main` — [1_Main.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/1_Main.v)

### 🟢 Doğru Yapılanlar
- Port tanımları (`clk`, `sw`, `btnX`, `led`, `seg`, `an`, `dp`, `RsTx`) XDC ile uyumlu.
- `debounce dbC` → ayrı wire (`centerForConfigSpecifically`) ile multi-driver sorunu çözüldü. ✅
- `ConfigMenu`, `TusKontrolu`, `lfsr16`, `random_delay_gen` doğru örneklenmiş ve bağlı.
- LED multiplexer eklendi: `assign led = ((confinish) ? ledsGame : ledsConfig);` ✅

### ✅ Düzeltilen Sorunlar (önceki rapordan)
- **~~6 modül bağlanmamış~~** → `gameLoop`, `segmentDisplay7`, `ScoreCalc`, `ScoreCalcEndgame`, `playerLEDs`, `playerLEDsEndgame` tamamı artık örneklenmiş ve bağlı. ✅
- **~~`seg[6:0]` ve `an[3:0]` askıda~~** → `segmentDisplay7 countVonCount(...)` ile bağlandı. ✅
- **~~`RsTx` askıda~~** → `UART_TX ughh(...)` ile bağlandı. ✅
- **~~`ledsGame` 1 bit wire~~** → `wire [15:0] ledsGame;` olarak düzeltildi. ✅
- **~~UART modülü yok~~** → `UART_Controller` ve `UART_TX` yazıldı ve bağlandı. ✅
- **~~Ana oyun FSM'i yok~~** → `gameLoop` modülü FSM tabanlı yazıldı. ✅

### 🔴 Yeni Kritik Sorunlar
- **`assign` ile çift sürücü (multi-driver):** Satır 98-101'de:
  ```verilog
  assign p1Total = p1TotalNew;
  assign p1Total = p2TotalNew;  // BUG: p1Total'e 3 farklı assign!
  assign p1Total = p3TotalNew;
  assign p1Total = p4TotalNew;
  ```
  Bunlar `p2Total`, `p3Total`, `p4Total` olmalı. Ayrıca bu assign'lar çift sürücü yaratıyor çünkü `p1Total`, `p2Total` vb. aynı zamanda `ScoreCalc`'ın çıkışları. Bu döngüsel atama sentezde hata verecektir. (Düzeltildi, -MT)
- **`assign currentTurn = currentTurnNew;` döngüsel:** `currentTurn` `ConfigMenu`'den çıkış olarak geliyor (output reg) ve aynı zamanda `gameLoop`'un çıkışı olan `currentTurnNew`'e atanıyor. Bu çift sürücü sorunu.
- **`assign playersIn = playersLeft;` döngüsel:** `playersIn` hem `ConfigMenu` çıkışı hem de `ScoreCalc` çıkışı — çift sürücü.
- **`ThingsToDo broThinksHesPartOfTheTeam();`** → Tanımsız modül, sentezde hata verecek (şaka amaçlı eklenmişse kaldırılmalı). (Düzeltildi -MT)

### 🟡 İyileştirme
- `random_delay_gen`'in `tetiklenme` girişi şu an `center`'a bağlı. gameLoop yazıldığına göre bu bağlantı gameLoop'un kontrol sinyaline çevrilmeli.

---

## 2. `ConfigMenu` — [2_ConfigMenu.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/2_ConfigMenu.v)

### 🟢 Doğru Yapılanlar
- Senkron reset düzgün çalışıyor.
- Switch eşleştirmeleri (sw[0-2] → oyuncu, sw[4-7] → tur, sw[9] → eleme, sw[11] → zorluk) şartnameyle uyumlu.
- Bit-slice yönü düzeltildi: `leds[2:0]`, `leds[7:4]` ✅
- `finished` sinyali latching doğru — bir kez 1 olduktan sonra `else if(!finished)` bloğu tekrar çalışmaz.

### 🟡 İyileştirme
- **Atanmayan LED bitleri:** Bit 3, 8, 10, 12-14 hiçbir yerde atanmıyor. Reset'te sıfırlandığından genellikle sorun çıkarmaz ama bit 15 (reset LED'i) konfigürasyon sırasında yanık kalabilir. Bloğun başına `leds <= 16'b0;` eklenebilir.

**Değişiklik yok — önceki raporla aynı.**

---

## 3. `segmentDisplay7` — [3_7segmentDisplay.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/3_7segmentDisplay.v)

### ✅ Düzeltilen Sorunlar
- **~~Top modüle bağlanmamış~~** → `segmentDisplay7 countVonCount(clk, rst, currentTurn, turnOffDisplay, seg, an, displinish)` ile Main'e bağlandı. ✅

### 🟢 Doğru Yapılanlar
- Hane döngüsü mantığı (`milisaniyesayaci` + `haneSayici`) doğru tasarlanmış — 1ms aralıklarla hane değişimi insan gözüne eşzamanlı görünür.
- `bitisSinyali` tek cycle pulse olarak doğru üretiliyor (sayac == 399_999_999'da 1, sonraki cycle'da 0).
- Tur numarasının LSB'sine göre 1-2-3-4 / 5-6-7-8 gösterimi şartnameyle uyumlu.
- Reset ve karartma durumunda display doğru kapatılıyor (`an = 4'b1111`, `seg = 7'b1111111`).

### 🟡 İyileştirmeler
- **`hane` kombinasyonel + senkron karışımı:** `hane` register'ı `always@(*)` içinde atanıp `always@(posedge clk)` içinde okunuyor. Sentez aracı bunu genellikle kabul eder ama `hane`'yi ayrı bir kombinasyonel wire olarak tanımlamak daha güvenli.
- **`haneSayici` bloğundaki `if` zincirleri:** `if(hane == 2'd1)`, `if(hane == 2'd2)`, `if(hane == 2'd3)` ayrı `if` bloklarıyla yapılmış. `else if` kullanılması daha güvenli (birden fazla bloğun tetiklenmesini önler).
- **Comment'te "LSFR" yazılmış:** Doğrusu "LFSR".

---

## 4. `lfsr16` — [4.1_lfsr16.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/4.1_lfsr16.v)

### 🟢 Doğru Yapılanlar
- Maximal-length polinom (x^16 + x^14 + x^13 + x^11 + 1) doğru uygulanmış. Periyot = 2^16 - 1.
- Sıfırdan farklı seed (`0xACE1`) — all-zero durumuna düşme riski yok.
- Senkron reset, sürekli çalışma (enable yok) — şartnameyle tam uyumlu.
- Kod temiz, kısa ve doğru.

**Hata tespit edilmedi. Değişiklik yok.**

---

## 5. `random_delay_gen` — [4.2_RSO.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/4.2_RSO.v)

### 🟢 Doğru Yapılanlar
- 3 aşamalı pipeline doğru tasarlanmış: snapshot → çarpma → ölçekleme + toplama.
- Kolay mod (2.0s–5.0s) ve zor mod (0.5s–5.0s) sınırları şartnameyle uyumlu.
- Zorluk seçimi kombinasyonel blokta, pipeline senkron blokta — temiz ayrım.
- `sure_bekleme_gecerli` tek cycle pulse.

### 🟡 İyileştirme
- **`sure_bekleme_gecerli` pulse kaçırma riski:** Tüketici modül (gameLoop) bu pulse'u yakalamazsa değer kaybolur. `sure_bekleme` register'ı kalıcı olduğundan değerin kendisi silinmez, ama geçerlilik sinyalinin FSM'de doğru durumda yakalanması gerekir.

**Değişiklik yok — önceki raporla aynı.**

---

## 6. `debounce` — [5.1_Debounce.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/5.1_Debounce.v)

### 🟢 Doğru Yapılanlar
- 50ms döngü + 20ms stabilite süresi makul debounce parametreleri.
- Reset (aktif-yüksek, `sw[15]`) şartnameyle uyumlu.
- Çıkış **seviye sinyali** — buton basılı olduğu sürece 1 kalır. `TusKontrolu` bunu kenar algılamayla pulse'a çevirir.

### 🟡 İyileştirme
- **Sayaç kontrolü gereksiz karmaşık:** Önce 5M kontrolü → sıfırla, sonra 2M kontrolü → sinyal ata. Çalışır ama akış kafa karıştırıcı. Tek eşik değerli basit bir tasarım daha okunaklı olurdu.

**Değişiklik yok — önceki raporla aynı.**

---

## 7. `TusKontrolu` — [5.2_TusKontrolu.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/5.2_TusKontrolu.v)

### 🟢 Doğru Yapılanlar
- Her buton için ayrı debounce modülü örneklenmiş.
- Kenar algılama (`eskiBTN == 0 && TemizlenmisBTN == 1`) doğru — tek cycle pulse üretiyor.
- BTNR ve BTND için `playerNO[2]` ve `playerNO[3]` kontrolü var — 2 oyuncu modunda 3. ve 4. buton devre dışı.
- Reset temiz.

### 🟡 İyileştirme
- **BTNU ve BTNL için `playerNO` kontrolü yok:** Oyuncu 1 ve 2 her zaman aktif kabul edilmiş. Minimum oyuncu sayısı 2 olduğundan pratikte sorun çıkarmaz ama `playerNO[0]` ve `playerNO[1]` kontrolü eklenirse daha tutarlı olur.

**Değişiklik yok — önceki raporla aynı.**

---

## 8. `gameLoop` — [6_GameLoop.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/6_GameLoop.v)

### ✅ Düzeltilen Sorunlar (önceki rapordan)
- **~~Sentezlenemez C-tarzı kod~~** → FSM tabanlı yeniden yazıldı (IDLE → CONFIG → TURN → CALC → END). ✅
- **~~`while(...)`, `wait(BTNC)` kullanımı~~** → Kaldırıldı, `case` yapısıyla değiştirildi. ✅
- **~~`genvar` + `always`, `generate` eksik~~** → Kaldırıldı. ✅
- **~~Runtime dizi boyutu~~** → Sabit boyutlu portlar kullanılıyor. ✅
- **Dosya adı değiştirildi:** `6_Main_Game_Loop.v` → `6_GameLoop.v`

### 🔴 Hâlâ Devam Eden / Yeni Kritik Sorunlar
- **`$time` kullanımı (satır 151-152, 158, 162, 166, 170):** `$time` sadece simülasyonda çalışır, sentezlenemez. Reaksiyon süresi ölçmek için bir donanım sayacı (counter) kullanılmalı.
- **`#5` gecikme (satır 174):** Sadece simülasyon yapısı — sentezlenemez.
- **Blocking (`=`) ve non-blocking (`<=`) karışımı aynı `always @(posedge clk)` bloğunda:** Satır 121-131, 135-148, 151-177, 184-205'te `=` ve `<=` karışık kullanılıyor. IEEE standardı açısından tanımsız davranış.
- **`next_state` hem kombinasyonel hem senkron blokta atanıyor:** Satır 88'de `next_state <= 3'b101;` (senkron reset içinde) ve satır 57'de `next_state = current_state;` (kombinasyonel blokta). Çift sürücü sorunu.
- **TURN durumunda reaksiyon süresi ölçülmüyor:** `$time`'a bağlı olan kısım çalışmayacağı için buton basıldığında gerçek bir süre değeri kaydedilmiyor.
- **5 saniye timeout mekanizması eksik:** `#5` ile simüle edilmeye çalışılmış ama donanımda çalışmaz. Bir sayaç ile 500_000_000 cycle (5s) sayılmalı.
- **`turnOver` tetikleme mantığı:** `turnOver` sadece `#5`'ten sonra 1 yapılıyor ama bu sentezlenemez. FSM'in TURN durumundan çıkış koşulu gerçek donanımda çalışmaz.
- **`noOfPlayers` hesabı:** `noOfPlayers = (playerNo[0] + playerNo[1] + playerNo[2] + playerNo[3])` doğru ama 3 bit'e sığıyor (max 4).

### 🟡 İyileştirme
- Gray code kullanımı güzel bir tasarım tercihi. ✅
- FSM yapısı (kombinasyonel next_state + senkron current_state) iyi bir başlangıç ama `next_state`'in senkron blokta da atanması sorunu çözmeli.

---

## 9. `ScoreCalc` — [7.1_ScoreCalc.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/7.1_ScoreCalc.v)

### ✅ Düzeltilen Sorunlar (önceki rapordan)
- **~~Player 4 indeks hatası~~** → `playersPenalized[3]`, `playersLeft[3]` doğru indeksle kullanılıyor. ✅
- **~~`player1newTotal` blocking/non-blocking karışımı~~** → Toplam hesabında tüm atamalar `<=` (non-blocking). ✅
- **~~`playersPenalized` reset bloğuna eklenmemiş~~** → `playersPenalized <= 4'b0000;` reset'te var. ✅
- **~~Sürekli çalışma sorunu / enable mekanizması yok~~** → `calcDone`, `turnOver`, `gameOver` kontrolleri eklendi. Modül artık sadece uygun zamanda çalışıyor. ✅

### 🟡 Devam Eden İyileştirme — Sıralama Blocking/Non-Blocking Karışımı
Sıralama karşılaştırmalarında `player1Place = (player1Place + 1)` şeklinde **blocking** (`=`) kullanılıyor. Aynı `always @(posedge clk)` bloğunda diğer atamalar **non-blocking** (`<=`). Vivado bunu genellikle kabul eder ve ardışık artırımlar doğru çalışır, ama IEEE standardı açısından riskli.

**Önerilen çözüm:** Sıralama hesabını ayrı bir kombinasyonel `always @(*)` bloğuna taşıyıp register'a kaydetme.

### 🟡 Yeni Gözlem
- **`calcDone` sadece 1'e çekiliyor, hiç sıfırlanmıyor (reset dışında):** `calcDone` bir kez `1'b1` olduktan sonra tekrar `0`'a dönmüyor. Yeni tur başladığında gameLoop'un veya Main'in bunu sıfırlaması gerekiyor ama mevcut kodda bu mekanizma yok. `!turnOver` durumunda `calcDone <= 1'b0;` eklenebilir.

---

## 10. `ScoreCalcEndgame` — [7.2_ScoreCalcEndgame.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/7.2_ScoreCalcEndgame.v)

### ✅ Düzeltilen Sorunlar (önceki rapordan)
- **~~`tieFinder` boyut uyumsuzluğu~~** → `reg[3:0] tieFinder = 4'b0000;` olarak düzeltildi. ✅
- **~~`currentHighest` ve `currentWinners` sıfırlanmıyor~~** → Reset bloğunda `currentHighest <= 7'd0;`, `currentWinners <= 4'b0000;`, `tieFinder <= 4'b0000;` eklendi. ✅
- **~~`calcedHighest` ve `calcedWinners` tanımlı ama reset yok~~** → Reset'te `calcedHighest <= 1'b0;`, `calcedWinners <= 1'b0;`, `calcFinished <= 1'b0;` eklendi. ✅

### 🟡 Devam Eden İyileştirmeler
- **Blocking + Non-Blocking Karışımı:** `currentHighest` hâlâ blocking (`=`) ile atanırken `currentWinners`/`tieFinder` non-blocking (`<=`). IEEE standardı açısından tanımsız davranış riski devam ediyor.
- **`currentWinners` non-blocking gecikme:** `currentWinners[X] <= 1'b1` non-blocking atanıyor. `currentHighest` blocking olduğu için doğru cycle'da karşılaştırma yapılabilir ama `currentWinners` bir cycle gecikir. Pipeline yapısı sayesinde genellikle sorun çıkarmaz.
- **`calcedWinners` parantez hatası:** `playersIn[3]` kontrolündeki `calcedWinners <= 1'b1;` (satır 110) diğer `playersIn` kontrollerinin dışında değil, `playersIn[3]` bloğunun **içinde**. Bu durumda sadece player4 oyundaysa `calcedWinners` 1 olur. Bu satır tüm player kontrolleri dışına taşınmalı.

---

## 11. `playerLEDs` — [8.1_playerLEDs.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/8.1_playerLEDs.v)

### ✅ Düzeltilen Sorunlar (önceki rapordan)
- **~~Top modüle bağlanmamış~~** → `playerLEDs midgameLeds(...)` ile Main'e bağlandı. ✅

### 🟢 Doğru Yapılanlar
- Copy-paste hatası düzeltildi: Player 3 → `player3Leds`, Player 4 → `player4Leds` ✅
- Sıralama → LED eşleştirmesi doğru (1.=4LED, 2.=3LED, 3.=2LED, 4.=1LED).
- Oyunda olmayan oyuncular (`!playersIn[X]`) ve cezalılar (`playersPenalized[X]`) için LED'ler sıfırlanıyor.
- Reset temiz.

### 🟡 İyileştirme
- **1 cycle gecikme:** `playerXLeds` bir cycle'da hesaplanıp sonraki cycle'da `leds`'e atanıyor. Pratikte görünmez ama bilinmeli.

---

## 12. `playerLEDsEndgame` — [8.2_playerLEDsEndgame.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/8.2_playerLEDsEndgame.v)

### ✅ Düzeltilen Sorunlar (önceki rapordan)
- **~~Top modüle bağlanmamış~~** → `playerLEDsEndgame endgameLeds(...)` ile Main'e bağlandı. ✅

### 🟢 Doğru Yapılanlar
- Kazanmayanların LED'leri `else` bloğuyla sıfırlanıyor ✅
- Beraberlik durumu destekleniyor (birden fazla `winners[X] = 1` olabilir).
- Reset temiz.

**Hata tespit edilmedi.**

---

## 13. `UART_Controller` — [9.1_uart.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/9.1_uart.v) **YENİ**

### 🟢 Doğru Yapılanlar
- FSM tabanlı yapı (IDLE → CHECK_END_COND → TX_GAME_OVER_MSG → TX_CHECK_TIE → TX_TIE/WINNER_MSG → TX_PRINT_SCORE → DONE).
- Sabit mesajlar (`initial` blokla ASCII olarak tanımlanmış): "OYUN BITTI", "BERABERLIK!", "KAZANAN VAR".
- `Binary_to_BCD` modülü ile skor rakamlarına dönüştürme mevcut.
- `tx_busy` kontrolü ile UART çarpışması önleniyor.

### 🔴 Kritik Sorunlar
- **Mid-game terminal çıktısı henüz yazılmamış:** `TX_NORMAL_TURN` durumu doğrudan `DONE`'a geçiyor (satır 211). Tur sonuçları terminale yazdırılmıyor.
- **Endgame dalı boş:** `else` bloğu (satır 230-243) `tieExists` kontrolü yapıyor ama hiçbir UART çıktısı üretmiyor (comment placeholder var, kod yok).
- **`yuzler` wire'ı kullanılıyor ama `Binary_to_BCD`'den çıkışı yok:** `Binary_to_BCD` modülünde `yuzler` çıkışı tanımlı değil (sadece `onlar` ve `birler` var). Satır 183'te `yuzler + 8'h30` kullanılıyor — sentezde undriven wire olacak.
- **`tx_start` yönetiminde yarış durumu:** `TX_GAME_OVER_MSG` durumunda `tx_start` 1 yapılıp aynı blokta 0'a çekilmesi bekleniyor ama `char_index` artırma mantığı karışık. İlk karakter gönderildikten sonra `char_index` artmıyor çünkü `tx_start` 1 olduğunda `else` dalına giriliyor.

### 🟡 İyileştirmeler
- `kazananMsg` dizisi 15 elemanlık tanımlı (`[0:14]`) ama sadece 13 eleman yüklenmiş (satır 35-38). Dizi boyutu `[0:12]` olmalı.
- Skor, maksimum 64 olabilir (16 tur × 4 puan). `Binary_to_BCD` bunu `onlar` (6) ve `birler` (4) olarak ayırır, yeterli. Ama `yuzler` kullanılmamalı.

---

## 14. `UART_TX` — [9.2_uart_tx.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/9.2_uart_tx.v) **YENİ**

### 🟢 Doğru Yapılanlar
- 9600 baud rate → `BAUD_LIMIT = 10416` doğru (100MHz / 9600 ≈ 10417).
- Gray code FSM yapısı (IDLE → FREE → SEND → DOWN).
- `saved_data` ile iletim sırasında giriş değişikliği koruması.

### 🔴 Kritik Sorunlar
- **Start bit gönderilmiyor:** UART protokolünde veri göndermeden önce TxD 0'a çekilmeli (start bit). `SEND` durumuna geçerken start bit gönderimi yok.
- **Çift baud sayımı:** `SEND` durumunda aynı `always` bloğunda `clock_count` iki kez artırılmaya çalışılıyor (satır 80-84 ve 87-96). İkinci `if` birincisinin üzerine yazıyor — etkili baud rate 2x olacak.
- **`bit_index` 8'e ulaşması:** `bit_index < 7` kontrolü (satır 92) yüzünden sadece 7 bit gönderiliyor (bit 0-6). 8-bit veri için `bit_index < 8` olmalı.
- **`next_state` kombinasyonel blokta `<=` (non-blocking):** Satır 40-41'de `next_state <= FREE;` ve `next_state <= SEND;` kullanılmış. Kombinasyonel blokta `=` (blocking) kullanılmalı.
- **`next_state` senkron blokta da atanıyor:** Satır 107'de `next_state <= IDLE;` — çift sürücü sorunu.
- **`TxD` reset'te 0:** UART idle durumunda TxD 1 olmalı. Reset'te `TxD <= 1'b1;` olmalı.

### 🟡 İyileştirme
- `state_UARDTX` ismi kafa karıştırıcı. `tx_busy` veya `tx_ready` gibi standart bir isim tercih edilmeli.

---

## 15. `Binary_to_BCD` — [9.3_bcd.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/9.3_bcd.v) **YENİ**

### 🟢 Doğru Yapılanlar
- 7-bit binary → 2 digit BCD dönüşümü (0-127 aralığı, pratikte 0-64).
- Kombinasyonel `always @(*)` — saf lojik, register yok.
- Bölme (`/`) ve mod (`%`) operatörleri Vivado tarafından sentezlenebilir (küçük sabitler için).

### 🟡 İyileştirme
- **Sentez maliyeti:** Bölme ve mod operatörleri büyük sayılar için pahalıdır ama 7-bit girişle Vivado bunu LUT tabanlı optimize eder. Yine de Double Dabble algoritması daha deterministik bir alternatif olurdu.

---

## 16. Testbench — [4tb_nrsotb.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/4tb_nrsotb.v)

### 🟢 Doğru Yapılanlar
- LFSR + random_delay_gen birlikte test ediliyor.
- Kolay mod (200M–500M) ve zor mod (50M–500M) sınır kontrolleri doğru.
- `task` yapısı ve `$finish` kullanımı temiz.

### 🟡 İyileştirme
- **Sonuç raporlama eksik:** `fail_sayi` ve `degisim_sayi` sadece waveform'da görülebiliyor. `$display` ile konsola yazdırılması faydalı olur.

**Değişiklik yok — önceki raporla aynı.**

---

## 17. XDC — [0.5_basys3Assigning.xdc](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/265SadeBulutlarProje2026/0.5_basys3Assigning.xdc)

### 🟢 Doğru Yapılanlar
- Standart Digilent Basys3 Master XDC baz alınmış.
- Clock (10ns / 100MHz), switch'ler, LED'ler, 7-segment, butonlar doğru.
- Pin eşleştirmeleri top modül port adlarıyla uyumlu.

### 🟡 İyileştirmeler
- **`RsRx` yorum satırında:** Satır 138'de `##` ile yorum yapılmış ama `RsTx` (satır 139) aktif. Top modülde sadece `RsTx` çıkışı kullanılıyor, `RsRx` girişi yok — bu tutarlı. Eğer ilerde RX eklenecekse `RsRx` aktifleştirilmeli.

**Değişiklik yok — önceki raporla aynı.**

---

## 18. Yapılacaklar Özeti

### 🔴 Kritik (Projenin çalışması için zorunlu)

| # | Madde | Dosya | Durum |
|---|-------|-------|:---:|
| 1 | ~~`gameLoop` sıfırdan FSM tabanlı yeniden yazılmalı~~ | 6_GameLoop.v | ✅ Yazıldı (ama sorunlar var) |
| 2 | ~~Top modülde 6 alt modül örneklenmeli ve bağlanmalı~~ | 1_Main.v | ✅ Bağlandı |
| 3 | ~~UART 9600 8N1 modülü yazılmalı~~ | 9.1, 9.2, 9.3 | ✅ Yazıldı (ama sorunlar var) |
| 4 | ~~Ana oyun FSM'i tasarlanmalı~~ | 6_GameLoop.v | ✅ FSM yapısı var |
| 5 | ~~`ledsGame` wire boyutu düzeltilmeli~~ | 1_Main.v | ✅ Düzeltildi |
| 6 | ~~`ScoreCalc`'a enable/start mekanizması eklenmeli~~ | 7.1_ScoreCalc.v | ✅ `calcDone`/`turnOver` eklendi |
| 7 | `gameLoop`'ta `$time` ve `#5` kaldırılmalı, donanım sayacı yazılmalı | 6_GameLoop.v | ❌ |
| 8 | `gameLoop`'ta 5 saniye timeout donanım sayacı | 6_GameLoop.v | ❌ |
| 9 | Main'deki `assign` çift sürücü sorunları düzeltilmeli (p1Total hep p1Total'e atanmış) | 1_Main.v | ❌ |
| 10 | Main'deki `ThingsToDo` tanımsız modülü kaldırılmalı | 1_Main.v | ❌ |
| 11 | `currentTurn` ve `playersIn` döngüsel assign sorunları çözülmeli | 1_Main.v | ❌ |
| 12 | `UART_TX`'te start bit eklenmeli ve çift baud sayımı düzeltilmeli | 9.2_uart_tx.v | ❌ |
| 13 | `UART_Controller`'da mid-game terminal çıktısı yazılmalı | 9.1_uart.v | ❌ |
| 14 | `UART_Controller`'da `yuzler` wire tanımsız — kaldırılmalı veya BCD'ye eklenmeli | 9.1_uart.v / 9.3_bcd.v | ❌ |
| 15 | `gameLoop`'ta `next_state` çift sürücü sorunu çözülmeli | 6_GameLoop.v | ❌ |

### 🟡 Orta Öncelik

| # | Madde | Dosya | Durum |
|---|-------|-------|:---:|
| 16 | `ScoreCalc` sıralama mantığını kombinasyonel bloğa taşı | 7.1_ScoreCalc.v | ⚠️ |
| 17 | `ScoreCalcEndgame` blocking/NB karışımını gider | 7.2_ScoreCalcEndgame.v | ⚠️ |
| 18 | ~~`ScoreCalcEndgame`'de `currentHighest`/`currentWinners` sıfırlama ekle~~ | 7.2_ScoreCalcEndgame.v | ✅ Düzeltildi |
| 19 | `ConfigMenu`'de atanmayan LED bitleri temizle | 2_ConfigMenu.v | ❌ |
| 20 | `segmentDisplay7`'de `hane` register'ını wire'a çevir | 3_7segmentDisplay.v | ❌ |
| 21 | `ScoreCalcEndgame`'de `calcedWinners` satırı doğru yere taşınmalı | 7.2_ScoreCalcEndgame.v | ❌ |
| 22 | `ScoreCalc`'ta `calcDone` sıfırlama mekanizması eklenmeli | 7.1_ScoreCalc.v | ❌ |
| 23 | `UART_TX`'te `TxD` reset değeri 1 olmalı | 9.2_uart_tx.v | ❌ |
| 24 | `UART_TX`'te kombinasyonel blokta `<=` yerine `=` kullanılmalı | 9.2_uart_tx.v | ❌ |
| 25 | `gameLoop`'ta blocking/non-blocking karışımı giderilmeli | 6_GameLoop.v | ❌ |

### 🟢 Düşük Öncelik

| # | Madde | Dosya |
|---|-------|-------|
| 26 | Comment'te "LSFR" → "LFSR" düzelt | 3_7segmentDisplay.v |
| 27 | Top dosya başına şartname gereği switch/LED tablosu ekle | 1_Main.v |
| 28 | Testbench'e `$display` raporlama ekle | 4tb_nrsotb.v |
| 29 | Eleme modunda tek oyuncu kalınca erken bitiş mantığı | 6_GameLoop.v |
| 30 | Dosyalardaki gereksiz boş satırlar ve ASCII art temizliği | Tüm dosyalar |
| 31 | `UART_Controller`'da `kazananMsg` dizi boyutu düzeltilmeli | 9.1_uart.v |
| 32 | `UART_TX`'te `state_UARDTX` ismi standartlaştırılmalı | 9.2_uart_tx.v |

---

## 19. Değişiklik Geçmişi

### 2026-08-02 → 2026-08-03 Arasında Yapılan Değişiklikler Özeti

| Değişiklik | Detay |
|---|---|
| `gameLoop` yeniden yazıldı | FSM tabanlı (IDLE/CONFIG/TURN/CALC/END), eski C-tarzı kod tamamen kaldırıldı. `$time` ve `#5` hâlâ mevcut. |
| 6 modül Main'e bağlandı | `gameLoop`, `segmentDisplay7`, `ScoreCalc`, `ScoreCalcEndgame`, `playerLEDs`, `playerLEDsEndgame` |
| UART sistemi eklendi | `UART_Controller` (9.1), `UART_TX` (9.2), `Binary_to_BCD` (9.3) — üç yeni dosya |
| `ledsGame` boyutu düzeltildi | `wire` → `wire [15:0]` |
| `ScoreCalc`'a kontrol eklendi | `calcDone`, `turnOver`, `gameOver` kontrolleri |
| `ScoreCalcEndgame` sıfırlama eklendi | Reset'te `currentHighest`, `currentWinners`, `tieFinder`, `calcedHighest`, `calcedWinners`, `calcFinished` sıfırlanıyor |
| `ScoreCalcEndgame` `tieFinder` boyutu düzeltildi | `3'b000` → `4'b0000` |
| `Main`'de LED multiplexer genişletildi | `ledsGame` = endgame ? ledsEndgame : ledsMidgame |
| `Main`'de `calcinish` seçici eklendi | `calcinish` = gameOver ? finalCalcinish : midCalcinish |
| Dosya adı değişikliği | `6_Main_Game_Loop.v` → `6_GameLoop.v` |
