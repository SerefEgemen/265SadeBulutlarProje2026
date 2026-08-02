# DÜZELTME LİSTESİ — Proje Şartnamesine Uyum İçin Yapılacaklar

**Tarih:** 2026-08-02  
**Referans:** DENETIM_RAPORU.md  
**Renk Kodlaması:**
- 🔴 **KIRMIZI** = Gerçek hata. Düzeltilmezse proje sentezlenemez, çalışmaz veya yanlış sonuç üretir.
- 🟡 **SARI** = Verilog açısından düzeltilse daha iyi olur. Muhtemelen çalışır ama riskli veya kötü alışkanlık.

---

# BÖLÜM A — Mevcut Kodlardaki Gerçek Hatalar

> Bu bölümdeki maddeler, zaten yazılmış kodlarda bulunan ve düzeltilmesi gereken hatalardır.

---

## 📄 1_Main.v

### ~~🔴 H1 — `center` Wire'ına İki Çıkış Bağlı (Multi-Driver)~~ ✅ DÜZELTİLDİ

**Konum:** Satır 22, 26, 37

**Sorun:** `center` wire'ını iki modül aynı anda sürüyor:
1. `debounce dbC` → çıkışı `TemizSinyal` (`output reg`)
2. `TusKontrolu buttons` → 9. port `SinyalBTNC` (`output reg`)

İki `output reg` aynı wire'a bağlanınca simülasyonda `center = X` (belirsiz) olur; sentezde hata veya öngörülemeyen davranış oluşur. Bu, `ConfigMenu`'ye ve `random_delay_gen`'e giden `center` sinyalini bozar.

**Çözüm (iki seçenekten birini uygulayın):**
- `dbC` örneklemesini kaldırıp, BTNC'yi sadece `TusKontrolu` üzerinden debounce edin. `SinyalBTNC` çıkışını ayrı bir wire'a alıp `ConfigMenu` ve `random_delay_gen`'e bağlayın.
- Ya da `TusKontrolu`'nun BTNC çıkışını farklı bir wire'a bağlayın (ör. `centerEdge`), `dbC`'nin `center` çıkışını konfigürasyon tarafında kullanın.

> ✅ **DURUM: DÜZELTİLDİ** — `centerForConfigSpecifically` adında ayrı bir wire tanımlandı. `debounce dbC` çıkışı buna bağlandı, `TusKontrolu`'nun `SinyalBTNC` çıkışı `center`'a bağlı kaldı. Multi-driver sorunu çözüldü.

---

### ~~🔴 H2 — LED Çıkışı İçin Multiplexer Gerekli~~ ✅ DÜZELTİLDİ

**Konum:** Satır 13, 34

**Sorun:** `led[15:0]` çıkışı şu an yalnızca `ConfigMenu`'ye bağlı. Oyun sırasında `playerLEDs`, oyun sonunda `playerLEDsEndgame` LED'leri sürecek. Hepsini aynı porta bağlarsanız yine multi-driver olur.

**Çözüm:** Oyun durumuna göre LED kaynağını seçen bir multiplexer (veya ana FSM içinde `case` bloğu) eklenmelidir:
```
Konfigürasyon aşaması → led = ConfigMenu çıkışı
Tur sonu gösterimi     → led = playerLEDs çıkışı  
Oyun bitti             → led = playerLEDsEndgame çıkışı
```

> ✅ **DURUM: DÜZELTİLDİ** — `assign led = ((confinish) ? ledsGame : ledsConfig);` ternary multiplexer eklendi. Ancak `ledsGame` wire'ı henüz hiçbir modüle bağlanmamış — E1 ile birlikte tamamlanmalı.

---

## 📄 2_ConfigMenu.v

### ~~🔴 H3 — Bit-Slice Yönü Ters~~ ✅ DÜZELTİLDİ

**Konum:** Satır 56-57

**Sorun:** `leds` register'ı `reg[15:0]` olarak tanımlı (azalan yön: 15→0). Part-select'te artan yön kullanılmış:
```verilog
leds[0:2] <= playerNoInput;   // ❌ yön ters
leds[4:7] <= turnNoInput;     // ❌ yön ters
```

Vivado bu satırları ya reddeder ya da bitleri ters sırada atar.

**Çözüm:**
```verilog
leds[2:0] <= playerNoInput;   // ✅
leds[7:4] <= turnNoInput;     // ✅
```

> ✅ **DURUM: DÜZELTİLDİ** — `leds[0:2]` → `leds[2:0]`, `leds[4:7]` → `leds[7:4]` olarak düzeltildi.

---

### 🟡 H4 — Atanmayan LED Bitleri — ❌ DÜZELTİLMEDİ

**Konum:** Satır 56-59

**Sorun:** `else if(!finished)` bloğunda sadece belirli LED bitleri atanıyor (0-2, 4-7, 9, 11). Geri kalanlar (3, 8, 10, 12-14) önceki değerlerini koruyor. Büyük ihtimalle sorun çıkarmaz çünkü reset'te hepsi sıfırlanıyor, ama LED 15 (reset switch'i) konfigürasyonda yanık kalabilir.

**Çözüm (opsiyonel):** Bloğun başında `leds <= 16'b0;` yazıp sonra ilgili bitleri atayabilirsiniz.

> ❌ **DURUM: DÜZELTİLMEDİ** — Bit 3, 8, 10, 12-14 hâlâ atanmıyor. Sarı öncelik — kritik değil ama temizlik açısından yapılması önerilir.

---

## 📄 6_Main_Game_Loop.v — ⚠️ EN KRİTİK DOSYA

### 🔴 H5 — Modül Sentezlenemez, Sıfırdan Yazılmalı — ❌ DÜZELTİLMEDİ

**Sorun:** Bu modül yazılım mantığıyla (C gibi) yazılmış. Aşağıdaki yapılar donanım sentezi için **yasaktır**:

| Satır | Yapı | Neden Yasak |
|-------|------|-------------|
| 55 | `while(...)` | Sentezlenemez. FSM durumu ile değiştirilmeli. |
| 80-81 | `$time` | Sadece simülasyon fonksiyonu. Donanımda sayaç kullanılmalı. |
| 108 | `#5` | Sadece simülasyonda çalışır. Donanımda gecikme sayaçla yapılır. |
| 154 | `wait(BTNC)` | Sentezlenemez. FSM'de buton kontrolü yapılmalı. |
| 29-30 | `genvar` + `always` içinde | `genvar` sadece `generate for` içindir. `integer` kullanılmalı. |
| 31 | `generate` (`endgenerate` yok) | Eksik kapanış, sentez hatası. |
| 17 | `score[0:playerNo][0:turnNo]` | Dizi boyutları derleme zamanında sabit olmalı. Runtime değer kullanılamaz. |
| 39 vs 41 | `=` ve `<=` aynı değişkene | Blocking + non-blocking karışımı tanımsız davranış. |

**Çözüm:** Bu modül FSM tabanlı olarak sıfırdan yeniden yazılmalıdır:
- Her `while` → bir FSM durumu (state) olur
- `$time` / `#5` → clock cycle sayan sayaçlarla zamanlama
- `wait(BTNC)` → FSM'de "BTNC basılana kadar bekle" durumu
- Dizi boyutları sabit: `reg [X:0] score [0:3][0:15]`
- Tüm `always @(posedge clk)` içinde sadece non-blocking (`<=`) kullanılmalı

> ❌ **DURUM: DÜZELTİLMEDİ** — Bu modüle hiç dokunulmamış. Tüm sentezlenemez yapılar (`while`, `$time`, `#5`, `wait`, `genvar`, `generate`) hâlâ duruyor. FSM tabanlı yeniden yazım yapılmalıdır. **EN KRİTİK MADDE.**

---

## 📄 7.1_ScoreCalc.v

### ~~🔴 H6 — Player 4 İçin Bit İndeksi Sınır Dışı~~ ✅ DÜZELTİLDİ

**Konum:** Satır 153, 155

**Sorun:** `playersPenalized` ve `playersLeft` `reg[3:0]` tanımlı (geçerli indeksler: 0-3). İndeks 4 sınır dışı:
```verilog
playersPenalized[4] <= 1'b1;  // ❌ var olmayan bit
playersLeft[4] <= 1'b0;       // ❌ var olmayan bit
```

Player 4'ün cezası ve elemesi hiçbir zaman gerçekleşmez.

**Çözüm:**
```verilog
playersPenalized[3] <= 1'b1;  // ✅
playersLeft[3] <= 1'b0;       // ✅
```

> ✅ **DURUM: DÜZELTİLDİ** — `playersPenalized[4]` → `[3]`, `playersLeft[4]` → `[3]` olarak düzeltildi.

---

### 🔴 H7 — Sıralama Mantığı Non-Blocking Yüzünden Yanlış Çalışıyor — ⚠️ KISMEN DÜZELTİLDİ

**Konum:** Satır 112-184 (ve diğer oyuncu blokları)

**Sorun:** Non-blocking (`<=`) ile aynı bloktaki tüm okumalar cycle başındaki **eski değeri** kullanır:
```verilog
player1Place <= 2'b00;                    // zamanlanır
player1Place <= (player1Place + 1);       // eski değeri okur!
player1Place <= (player1Place + 1);       // yine eski değeri okur!
player1Place <= (player1Place + 1);       // yine eski değeri okur!
```

Hepsi aynı eski değere +1 eklediğinden, son atama kazanır. Sonuç: 3 rakibinden yavaş olan oyuncu yalnızca 1 sıra düşer, 3 değil.

**Beklenen:** `player1Place = 2'b11` (4. sıra)  
**Gerçek:** `player1Place = 2'b01` (2. sıra) ❌

**Çözüm:** Sıralama hesabını **kombinasyonel** (`always @(*)`) blokta blocking (`=`) atama ile yapın:
```verilog
// always @(*) içinde:
reg [1:0] p1_place_comb;
p1_place_comb = 2'b00;
if(player1Time > player2Time) p1_place_comb = p1_place_comb + 1;
if(player1Time > player3Time) p1_place_comb = p1_place_comb + 1;
if(player1Time > player4Time) p1_place_comb = p1_place_comb + 1;

// Sonra always @(posedge clk) içinde register'a kaydedin:
player1Place <= p1_place_comb;
```

> ⚠️ **DURUM: KISMEN DÜZELTİLDİ** — Sıralama karşılaştırmalarında `<=` yerine `=` (blocking) kullanılmaya başlandı, bu sayede ardışık artırımlar doğru çalışıyor. Ancak önerilen kombinasyonel `always @(*)` bloğuna taşıma yapılmadı — tüm hesaplama hâlâ aynı `always @(posedge clk)` bloğu içinde. Aynı blokta bazı değişkenler `<=`, sıralama `=` ile atanıyor — blocking/non-blocking karışımı devam ediyor. Vivado bunu genellikle kabul eder ama IEEE standardı açısından riskli.

---

### ~~🔴 H8 — `player1newTotal` Blocking/Non-Blocking Karışımı~~ ✅ DÜZELTİLDİ

**Konum:** Satır 105 vs. satır 191-201

**Sorun:** Aynı `always @(posedge clk)` bloğunda aynı register'a hem `<=` hem `=` atanmış:
```verilog
player1newTotal <= player1Total;          // satır 105: non-blocking
// ...
player1newTotal = (player1Total + 4);     // satır 191: blocking ❌
```
IEEE standardına göre bu **tanımsız davranıştır**. Player 2, 3, 4 için `<=` kullanılmış — Player 1 için `=` kalmış (copy-paste hatası).

**Çözüm:** Satır 191-201'deki `=` işaretlerini `<=` yapın:
```verilog
2'b00: player1newTotal <= (player1Total + 4);
2'b01: player1newTotal <= (player1Total + 3);
2'b10: player1newTotal <= (player1Total + 2);
2'b11: player1newTotal <= (player1Total + 1);
```

> ✅ **DURUM: DÜZELTİLDİ** — Satır 191-201'deki tüm `=` atamaları `<=` (non-blocking) olarak düzeltildi. Player 2, 3, 4 de aynı şekilde `<=` kullanıyor.

---

### ~~🟡 H9 — `playersPenalized` Reset'te Sıfırlanmıyor~~ ✅ DÜZELTİLDİ

**Konum:** Satır 91-101

**Sorun:** `if(rst)` bloğunda `playersPenalized` sıfırlanmıyor. İlk çalıştırmada sorun çıkarmayabilir (initial değer 0'dır) ama sonraki resetlerde önceki değer kalabilir.

**Çözüm:** Reset bloğuna `playersPenalized <= 4'b0000;` ekleyin.

> ✅ **DURUM: DÜZELTİLDİ** — Reset bloğuna `playersPenalized <= 4'b0000;` eklendi.

---

## 📄 7.2_ScoreCalcEndgame.v

### 🔴 H10 — Blocking/Non-Blocking Karışımı + Tek Cycle Hesap Sorunu — ⚠️ KISMEN DÜZELTİLDİ

**Konum:** Satır 44-98

**İki sorun bir arada:**

**Sorun 1 — Karışık atama:** `tieExists` ve `tieFinder` blocking `=` ile atanırken, `winners`, `winningScore`, `currentHighest` non-blocking `<=` ile atanıyor. Aynı `always @(posedge clk)` bloğunda bu karışım tanımsız davranış riski taşır.

**Sorun 2 — Yanlış hesaplama:** `currentHighest` non-blocking ile güncelleniyor (satır 49 vb.) ve hemen ardından aynı cycle'da okunuyor (satır 70 vb.). Non-blocking'de okunan değer **eski cycle'ın değeridir**. Yani ilk cycle'da `currentHighest = 0` olur ve hiçbir oyuncunun puanı 0'a eşit olmadığından `currentWinners` hiç set edilmez.

**Çözüm:** En yüksek skor bulma ve kazanan belirleme mantığını **kombinasyonel** (`always @(*)`) blokta yapın. Blocking `=` ile tek cycle'da doğru sonuca ulaşılır:
```verilog
// always @(*) içinde:
reg [6:0] highest_comb;
highest_comb = 7'd0;
if(playersIn[0] && player1Total > highest_comb) highest_comb = player1Total;
if(playersIn[1] && player2Total > highest_comb) highest_comb = player2Total;
if(playersIn[2] && player3Total > highest_comb) highest_comb = player3Total;
if(playersIn[3] && player4Total > highest_comb) highest_comb = player4Total;
// Sonra highest_comb ile karşılaştırarak currentWinners belirle
```

> ⚠️ **DURUM: KISMEN DÜZELTİLDİ** — `currentHighest` artık blocking (`=`) ile atanıyor, bu sayede aynı cycle'da doğru en yüksek skor hesaplanıyor. Ancak: (1) `currentWinners` hâlâ non-blocking (`<=`) — aynı blokta blocking/non-blocking karışımı devam ediyor. (2) `tieFinder` non-blocking ile atanıp hemen ardından okunuyor — eski cycle değerini kullanır. (3) `currentWinners` hiçbir zaman sıfırlanmıyor (reset hariç). Önerilen tam kombinasyonel çözüm uygulanmamış.

---

## 📄 8.1_playerLEDs.v

### ~~🔴 H11 — Copy-Paste Hatası: Yanlış Register Adı~~ ✅ DÜZELTİLDİ

**Konum:** Satır 117, 142

**Sorun:** Player 3 ve Player 4'ün ceza bloklarında yanlışlıkla `player2Leds` sıfırlanıyor:
```verilog
// Satır 117 — Player 3 cezalandırıldığında:
player2Leds <= 4'b0000;    // ❌ player3Leds olmalı!

// Satır 142 — Player 4 cezalandırıldığında:
player2Leds <= 4'b0000;    // ❌ player4Leds olmalı!
```

**Sonuç:** Player 3 veya 4 cezalandırıldığında Player 2'nin LED'leri sönüyor; Player 3/4'ünkiler yanmaya devam ediyor.

**Çözüm:**
```verilog
// Satır 117:
player3Leds <= 4'b0000;    // ✅

// Satır 142:
player4Leds <= 4'b0000;    // ✅
```

> ✅ **DURUM: DÜZELTİLDİ** — Player 3 ceza bloğunda `player2Leds` → `player3Leds`, Player 4 ceza bloğunda `player2Leds` → `player4Leds` olarak düzeltildi.

---

## 📄 8.2_playerLEDsEndgame.v

### ~~🟡 H12 — Kaybeden Oyuncuların LED'leri Sıfırlanmıyor~~ ✅ DÜZELTİLDİ

**Konum:** Satır 45-56

**Sorun:** Sadece kazanan oyuncuların LED'leri `4'b1111` yapılıyor. Kaybedenlerin LED'leri eski değerlerini koruyor (`else` bloğu yok). Reset'ten sonra ilk çalışmada 0 olacağından muhtemelen sorun çıkarmaz, ama oyun akışına bağlı olarak eski tur değerleri kalabilir.

**Çözüm:** Her `if(winners[x])` bloğuna `else` ekleyin:
```verilog
if(winners[0]) player1Leds <= 4'b1111;
else           player1Leds <= 4'b0000;
```

> ✅ **DURUM: DÜZELTİLDİ** — Tüm 4 oyuncu için `else` blokları eklendi. Kazanmayanların LED'leri artık açıkça sıfırlanıyor.

---

# BÖLÜM B — Eksik Modüller ve Özellikler

> Bu bölüm, şartnamenin gerektirdiği ama henüz yazılmamış / bağlanmamış kısımları listeler.

---

### 🔴 E1 — Top Modülde 6 Alt Modül Örneklenmemiş

Aşağıdaki modüller yazılmış ama top modülde örneklenip bağlanmamış:
| Modül | Dosya | Görevi |
|-------|-------|--------|
| `segmentDisplay7` | 3_7segmentDisplay.v | 7-segment display → `seg`, `an` portlarına bağlanmalı |
| `ScoreCalc` | 7.1_ScoreCalc.v | Tur sonu puan hesabı |
| `ScoreCalcEndgame` | 7.2_ScoreCalcEndgame.v | Oyun sonu kazanan belirleme |
| `playerLEDs` | 8.1_playerLEDs.v | Tur sonu LED gösterimi |
| `playerLEDsEndgame` | 8.2_playerLEDsEndgame.v | Oyun sonu LED gösterimi |
| `gameLoop` | 6_Main_Game_Loop.v | Oyun döngüsü (önce H5'teki yeniden yazım gerekir) |

Her modül için gerekli wire'lar tanımlanıp port bağlantıları yapılmalıdır.

---

### 🔴 E2 — Ana Oyun FSM'i Tasarlanmalı

Şartnamenin tanımladığı oyun akışını yöneten bir FSM mevcut değil. Önerilen durum geçişleri:
```
RESET → CONFIG → TUR_BASLAT_BEKLE → DISPLAY_SAYIM → RASTGELE_BEKLEME →
KARATMA → REAKSIYON_BEKLE → SKOR_HESAPLA → SONUC_GOSTER → 
  ├─ (sonraki tur varsa) → TUR_BASLAT_BEKLE
  └─ (turlar bittiyse) → OYUN_SONU
```

---

### 🔴 E3 — UART TX Modülü Yazılmalı

Şartname Bölüm 9: UART 9600 baud, 8N1 formatında terminal çıkışı zorunlu. Her tur sonunda ve oyun sonunda aşağıdakiler yazdırılmalı:
- Tur numarası, reaksiyon süreleri
- False start / timeout yapan oyuncular
- Tur puanları ve toplam puan
- Oyun sonu: kazanan (veya beraberlik durumu)

---

### 🔴 E4 — Reaksiyon Süresi Ölçümü (1ms Sayaç)

Şartname Bölüm 7: Reaksiyon süresi 1ms çözünürlükle ölçülmelidir.

Blackout anından itibaren 100.000 clock cycle = 1ms sayan bir sayaç tasarlanmalı. Her oyuncunun butona bastığı andaki sayaç değeri kaydedilmeli.

---

### 🔴 E5 — 5 Saniye Timeout Mekanizması

Şartname Bölüm 6: Basamaklar söndükten sonra 5 saniye içinde basmayanlar cezalandırılmalı.

Reaksiyon sayacı 500.000.000 cycle'a (5s) ulaştığında henüz basmamış oyuncular timeout olarak işaretlenmeli.

---

### 🔴 E6 — Eleme Modunda Erken Bitiş

Şartname Bölüm 9: Eleme modunda tek oyuncu kalırsa oyun erken bitmeli.

Her tur sonunda aktif oyuncu sayısı kontrol edilmeli. Tek kaldıysa → doğrudan OYUN_SONU durumuna geçilmeli.

---

### 🟡 E7 — Top Dosya Başına Tanıtım Comment'i

Şartname Bölüm 2 ve 8: Switch/LED/buton eşleştirmeleri top dosyanın başında belirtilmelidir. Zorunlu değil (ayrı PDF de olabilir) ama kolaylık açısından top dosya başına eklenmesi önerilir.

---

# BÖLÜM C — Özet

| Kategori | 🔴 Kritik | 🟡 Dikkat | Toplam | ✅ Düzeltildi | ⚠️ Kısmen | ❌ Kalan |
|----------|-----------|-----------|--------|--------------|-----------|--------|
| **A) Mevcut kodlardaki hatalar** | 8 | 4 | 12 | 8 | 2 | 2 |
| **B) Eksik modüller/özellikler** | 6 | 1 | 7 | 0 | 0 | 7 |
| **Toplam** | **14** | **5** | **19** | **8** | **2** | **9** |

---

### Öncelik Sırası (Nereden Başlamalı?)

1. **H5** — `gameLoop` modülünü FSM tabanlı yeniden yazın (en büyük iş)
2. **E2** — Ana oyun FSM'ini tasarlayın (H5 ile birlikte düşünülmeli)
3. **H1** — `center` multi-driver sorununu çözün (1 dakikalık düzeltme ama çözmezseniz hiçbir şey çalışmaz)
4. **H3** — `ConfigMenu` bit-slice yönünü düzeltin (1 dakikalık düzeltme)
5. **H6** — `ScoreCalc` indeks hatasını düzeltin (`[4]` → `[3]`)
6. **H11** — `playerLEDs` copy-paste hatasını düzeltin
7. **H7, H8** — `ScoreCalc` sıralama mantığı ve blocking/non-blocking düzeltmeleri
8. **H10** — `ScoreCalcEndgame` hesaplama mantığını düzeltin
9. **E1** — Tüm modülleri top modülde örnekleyin ve bağlayın
10. **H2** — LED multiplexer ekleyin
11. **E3** — UART modülü yazın
12. **E4, E5, E6** — Reaksiyon sayacı, timeout, erken bitiş ekleyin
13. **Sarı maddeler** — Vakit kalırsa iyileştirin

---



Raporun geri kalanında hata tespit edilmemiştir.
