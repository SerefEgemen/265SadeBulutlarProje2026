# 🔬 MODÜL 6 — `gameLoop` (6_Main_Game_Loop.v) DETAYLI ANALİZ

**Tarih:** 2026-08-02  
**Kapsam:** Yalnızca [6_Main_Game_Loop.v](file:///c:/Users/Meriç/Desktop/Yeni%20dosya/6_Main_Game_Loop.v) dosyası — satır satır hata tespiti  
**Sonuç:** Bu modül **yazılım dili mantığıyla** (C/Python gibi) yazılmıştır. Verilog donanım tanımlama dili (HDL) kurallarına uymamaktadır. **Sentezlenemez**, hatta düzgün **simüle bile edilemez.**

---

## 📌 Neden "Dil Tamamen Yanlış" Diyorum?

Verilog bir **donanım tanımlama dili**dir, C gibi bir yazılım dili değildir. Temel fark:

| Kavram | C / Python (Yazılım) | Verilog (Donanım) |
|--------|----------------------|-------------------|
| Kod çalışma şekli | Satır satır, sıralı çalışır | Her şey **aynı anda** (paralel) çalışır |
| Döngü (`for`, `while`) | Runtime'da tekrarlar | **Donanımı kopyalar** (sentezde `for` "unroll" edilir) |
| Bekleme (`wait`, `#delay`) | İşlemci bekler | Donanım **bekleyemez** — sayaç/FSM gerekir |
| Zaman (`$time`) | `clock()` gibi bir fonksiyon | Sadece **simülasyonda** vardır, donanımda yoktur |
| Değişken | Bellekteki adres | **Fiziksel kablo** veya **flip-flop** |

`6_Main_Game_Loop.v` dosyası baştan sona C tarzı yazılmıştır. Her satırında donanım sentezinin kırmızı çizgilerini aşan yapılar vardır. Aşağıda **her satırı** tek tek inceliyorum.

---

## 📋 SATIR SATIR ANALİZ

---

### Satır 1: `` `timescale 1ns / 1ps ``

✅ **Sorun yok.** Standart timescale bildirimi. Sentez araçları bunu genellikle yok sayar ama simülasyon için doğru.

---

### Satır 2-13: Yorum Bloğu

```verilog
/*
## endmodule 2 error vermekte, sebebini araştırmaya devam
...
*/
```

⚠️ **Uyarı:**
- `endmodule 2 error` notu, modülün derlenmediğini bizzat itiraf ediyor.
- Türkçe karakterlerde bozulma var (`?` şeklinde görünüyor) — kaynak dosyanın encoding'i muhtemelen UTF-8 ama bazı editörler ANSI olarak açmış.
- Bu yorum bloğu bilgi amaçlı, sentezde etkisi yok.

---

### Satır 15-19: Modül Tanımı ve Port Listesi

```verilog
module gameLoop(input clk, rst, turnNo, playerNo, BTNC, BTNU, BTNL, BTNR, BTND, 
                eliminationModeInput, kararmaSinyali, 
output score[0:playerNo][0:turnNo]
);
```

🔴 **KRİTİK HATA 1 — Runtime Değerli Dizi Boyutu**

`score[0:playerNo][0:turnNo]` tanımı **sentezlenemez**. Verilog'da:
- Dizi boyutları **derleme zamanında** (compile-time) sabit olmalıdır.
- `playerNo` ve `turnNo` **input portlarıdır** — değerleri çalışma zamanında (runtime) belirlenir.
- Bu, C'deki `int score[playerNo][turnNo]` ile aynı mantık — dinamik dizi. Donanımda dinamik dizi **yoktur**.

**Doğru yaklaşım:**
```verilog
// Maksimum boyutlarla sabit dizi tanımla
parameter MAX_PLAYERS = 4;
parameter MAX_TURNS = 16;
output reg [3:0] score [0:MAX_PLAYERS-1][0:MAX_TURNS-1];
```

🔴 **KRİTİK HATA 2 — Portlarda Boyut Eksikliği**

- `turnNo` ve `playerNo` `input` olarak tanımlı ama **kaç bitlik olduğu belirtilmemiş**. Verilog bunları varsayılan olarak 1 bit kabul eder.
- `kararmaSinyali`, `eliminationModeInput` — bunlar da 1 bit mi? Muhtemelen evet ama açıkça `input wire` olarak tanımlanmalı.
- `BTNC, BTNU, BTNL, BTNR, BTND` — debounce edilmiş mi, ham mı? Top modülde `TusKontrolu` çıkışlarının kullanılması gerekirdi.

🔴 **KRİTİK HATA 3 — `score` output tipi belirsiz**

- `output score[...]` — `reg` mi `wire` mı? Belirtilmemiş.
- Eğer `always` bloğu içinde atanacaksa `output reg` olmalıdır.
- Mevcut haliyle sentez hatası verecektir.

---

### Satır 21-23: Register Tanımları

```verilog
reg [1:0] playerActive [0:3];
reg [2:0] playerOrderSpeed [0:playerNo];
reg [1:0] falseStart [0:playerNo];
```

🔴 **HATA — `playerNo` ile boyut tanımı (tekrar)**

`playerOrderSpeed [0:playerNo]` ve `falseStart [0:playerNo]` — runtime değerle dizi boyutu, sentezlenemez. Yukarıdaki ile aynı sorun.

⚠️ **Uyarı — `playerActive` boyutu**

`reg [1:0] playerActive [0:3]` → her eleman 2 bit. Ama kullanımda `1'b1` ve `1'b0` atanıyor (1 bit değer). 2 bitlik register'a 1 bitlik değer atanınca üst bit 0 kalır — fonksiyonel sorun yok ama gereksiz kaynak israfı. `reg playerActive [0:3]` (1 bit) yeterlidir.

---

### Satır 26-27: `order` ve `end_time`

```verilog
reg order = 0;
reg end_time;
```

🔴 **HATA — `order` boyutu**

`reg order = 0` → 1 bitlik register. Değer 0 veya 1 olabilir. Ama satır 86, 92, 98, 104'te `order <= order + 1` yapılıyor, 4 oyuncu varsa `order` 0-3 arası değer almalı → **en az 2 bit** gerekir. 1 bitlik register'da `order` 0→1→0→1... şeklinde taşar.

**Doğrusu:** `reg [1:0] order = 2'b00;`

🔴 **HATA — `end_time` boyutu**

`reg end_time` → 1 bitlik register. Ama satır 80'de `$time + 500000000` atanıyor. `$time` 64 bitlik bir simülasyon değeridir. 1 bitlik register'a 64 bitlik değer atamak tamamen anlamsızdır.

Bu zaten `$time` sentezlenemez olduğundan akademik bir sorun — ama yazılım mantığıyla bile yanlış boyutlandırılmış.

---

### Satır 29-31: `genvar` ve `generate`

```verilog
genvar i;
genvar j;
generate
```

🔴 **KRİTİK HATA 4 — `genvar` yanlış kullanımı**

**`genvar` nedir:** Verilog'da `generate for` bloğu içinde kullanılan **derleme zamanı döngü değişkeni**dir. Donanım yapıları kopyalamak içindir (parametre sayıda modül örnekleme gibi).

**Burada nasıl kullanılmış:** `genvar i, j` tanımlanmış ama `always @(posedge clk)` bloğundaki `for` döngülerinde kullanılıyor. Bu **yasaktır**. Sıralı lojik içinde döngü değişkeni **`integer`** olmalıdır.

```verilog
// ❌ YANLIŞ:
genvar i;
always @(posedge clk) begin
    for(i = 0; i < 4; i = i + 1) begin  // genvar burada kullanılamaz
    end
end

// ✅ DOĞRU:
integer i;
always @(posedge clk) begin
    for(i = 0; i < 4; i = i + 1) begin  // integer kullanılmalı
    end
end
```

🔴 **KRİTİK HATA 5 — `generate` kapanmamış**

Satır 31'de `generate` açılmış ama dosyada **hiçbir yerde `endgenerate` yok**. Bu sentez hatası verecektir.

Ayrıca `generate` bloğu içinde doğrudan `always` bloğu yazmak **yanlış kullanımdır**. `generate` yapısı, tekrarlanan donanım yapılarını parametrik olarak oluşturmak içindir; bir `always` bloğunun tamamını kapsaması anlamsızdır.

---

### Satır 33: `always` Bloğu Başlangıcı

```verilog
always @ (posedge clk) begin
```

⚠️ **Uyarı — Reset yok**

Senkron tasarımda `always @(posedge clk)` bloğunun başında mutlaka `if(rst)` kontrolü olmalıdır. Bu modülde hiçbir reset mekanizması yok. Power-on'da tüm register'lar **belirsiz** (X) değerde olacak.

---

### Satır 36-49: Oyuncu Konfigürasyonu ve Başlangıç Değerleri

```verilog
for(i = 0; i < 4; i = i + 1) begin
    if(i < playerNo) begin
        playerActive[i] = 1'b1;       // ← blocking (=)
    end else begin
        playerActive[i] <= 1'b0;      // ← non-blocking (<=)
    end
    falseStart[i] <= 1'b0;
    
    for(j = 0; j < turnNo; j = j + 1) begin
        score[i][j] <= 0;
    end
end
```

🔴 **KRİTİK HATA 6 — Blocking + Non-Blocking Karışımı**

**Aynı `always @(posedge clk)` bloğunda, aynı `playerActive` register'ına:**
- Satır 39: `playerActive[i] = 1'b1;` → **blocking** atama
- Satır 41: `playerActive[i] <= 1'b0;` → **non-blocking** atama

IEEE Verilog standardına (1364-2005, §10.4.1) göre bu **tanımsız davranıştır (undefined behavior)**. Sentez aracı ya hata verir ya da öngörülemeyen donanım üretir. Simülatör ise her implementation'da farklı sonuç verebilir.

**Kural:** `always @(posedge clk)` bloğunda **sadece non-blocking (`<=`)** kullanılmalıdır.

🔴 **HATA — Konfigürasyon her clock cycle'da tekrarlanıyor**

Bu `for` döngüsü `always @(posedge clk)` içinde olduğundan, **her saat darbesi**nde `playerActive`, `falseStart` ve `score` sıfırlanıyor. Oyun sırasında `falseStart[0] <= 1'b1` atansa bile, bir sonraki clock cycle'da bu blok tekrar çalışıp `falseStart[0] <= 1'b0` yapacak.

**Sonuç:** `falseStart` hiçbir zaman 1'de **kalamaz**. Oyun mantığı çalışamaz.

**Doğru yaklaşım:** Konfigürasyon yalnızca **bir kez**, FSM'in CONFIG durumunda yapılmalıdır.

---

### Satır 53-77: `while(!kararmaSinyali)` — False Start Algılama

```verilog
for(i = 0; (i < turnNo); i = i + 1) begin
    while(!kararmaSinyali) begin
        if(playerActive[0]) begin
            if(BTNU) begin
                falseStart[0] <= 1'b1;
            end 
        end
        // ... diğer oyuncular ...
    end
```

🔴 **KRİTİK HATA 7 — `while` Döngüsü Sentezlenemez**

Bu, modüldeki **en temel yanlış anlama**dır.

**`while` neden sentezlenemez:**

Verilog sentez aracı kodu **donanıma** (kapı-level devresine) çevirir. Donanımda "bir koşul sağlanana kadar bekle" diye bir mekanizma **yoktur**. Bir flip-flop ya bir clock edge'inde değer yakalar ya da yakalamaz — "beklemez".

`while(!kararmaSinyali)` yazıldığında sentez aracı şunu görür: "sonsuz sayıda tekrar eden bir döngü, ama kaç kez tekrar edeceği derleme zamanında bilinmiyor." Bu **sentezlenemez**.

**Yazılım eşdeğeri:**
```c
while(!karamaSinyali) {
    // CPU burada döngüde bekler
}
```

**Donanım eşdeğeri (doğru yaklaşım):**
```verilog
// FSM durumu: WAIT_BLACKOUT
always @(posedge clk) begin
    case(state)
        WAIT_BLACKOUT: begin
            if(kararmaSinyali) 
                state <= REACTION_PHASE;
            else begin
                // False start kontrolü
                if(playerActive[0] && BTNU) falseStart[0] <= 1'b1;
                // ...
            end
        end
    endcase
end
```

FSM'de `WAIT_BLACKOUT` durumunda modül her clock edge'inde `kararmaSinyali`'nı kontrol eder. Sinyal gelince sonraki duruma geçer. Bu, donanımda "beklemenin" tek yoludur.

---

### Satır 79-110: 5 Saniye Bekleme ve Reaksiyon Algılama

```verilog
for(j = 0; j < 10; j = j + 1) begin
    end_time = $time + 500000000; 
    while($time <= end_time) begin
        // oyuncu kontrolleri...
        #5;
    end
end
```

🔴 **KRİTİK HATA 8 — `$time` Sentezlenemez**

`$time`, Verilog **simülasyon** ortamında o anki simülasyon zamanını nanosaniye cinsinden döndüren bir **sistem fonksiyonudur**. Donanımda karşılığı yoktur. FPGA'da "şu an kaçıncı nanosaniyedeyiz" diye sorabileceğiniz bir mekanizma yoktur.

**Doğru yaklaşım:** Zaman ölçmek için bir **sayaç** kullanılır:
```verilog
// 100 MHz clock → 1 cycle = 10ns
// 500ms = 50_000_000 cycle
reg [25:0] timer;  // 26 bit yeterli (2^26 = 67M > 50M)

always @(posedge clk) begin
    if(state == REACTION_WAIT) begin
        if(timer < 50_000_000)
            timer <= timer + 1;
        else
            timeout <= 1'b1;  // 500ms doldu
    end
end
```

🔴 **KRİTİK HATA 9 — `#5` Gecikme Sentezlenemez**

`#5` ifadesi "5 nanosaniye bekle" demektir ve **yalnızca simülasyonda** çalışır. Sentez araçları bunu tamamen **yok sayar** (ya da hata verir).

Yorum satırında "there are 5 nanoseconds inbetween presses" yazılmış — bu, yazılım mantığının donanıma uygulanmasının tipik bir örneğidir. Donanımda butonlar arasında "5ns bekle" diye bir kavram yoktur; her clock edge'inde tüm butonlar **aynı anda** kontrol edilir.

🔴 **KRİTİK HATA 10 — `for` döngüsünde `j < 10` ile 5 saniyelik bekleme mantığı**

Yorum diyor ki: "5 sec wait - değeri nanosec'deki büyüklüğünden dolayı *10 kere 500000000 bekler"

Bu tamamen yazılım mantığıdır:
- 10 × 500ms = 5000ms = 5s → **matematiksel olarak doğru**
- Ama `for` döngüsü sentezde **unroll** edilir (10 kopya donanım oluşturur), `while` ise sentezlenemez.
- Yani bu yapı hiçbir şekilde çalışamaz.

**Doğru yaklaşım:** 5 saniye = 500_000_000 clock cycle (100 MHz'te). Tek bir 29 bitlik sayaç ile:
```verilog
reg [28:0] five_sec_timer;  // 2^29 = ~537M > 500M

if(five_sec_timer < 500_000_000)
    five_sec_timer <= five_sec_timer + 1;
else
    timeout_flag <= 1'b1;
```

---

### Satır 83-106: Reaksiyon Sıralama Mantığı

```verilog
if(playerActive[0] && !falseStart[0]) begin
    if(BTNU) begin
        playerOrderSpeed[order] <= 2'b00;
        order <= order + 1;
    end 
end
```

🔴 **HATA — Non-Blocking ile `order` artırımı**

`order <= order + 1` non-blocking atamasıdır. Aynı clock cycle'da 4 oyuncu da aynı anda basarsa:
- Hepsi **aynı eski `order` değerini** okur
- Hepsi `playerOrderSpeed[order]` → aynı indekse yazar
- Hepsi `order <= order + 1` yapar → son atama kazanır

**Sonuç:** 4 oyuncu aynı anda basarsa sadece **bir tanesi** kaydedilir, diğerleri kaybolur.

Bu sorun aslında pratikte çok sık oluşmaz (aynı clock cycle'da iki buton basımı çok nadirdir) ama **yanlış tasarlanmış**tır. Doğru yaklaşım, her oyuncu için ayrı bir zaman damgası register'ı kullanmaktır.

⚠️ **Uyarı — `playerOrderSpeed` boyutu**

`playerOrderSpeed[order] <= 2'b00` → `order` 1 bitlik (`reg order`) olduğundan, yalnızca indeks 0 ve 1 geçerlidir. 3. ve 4. oyuncunun basışı hiçbir zaman kaydedilemez.

---

### Satır 113-126: Skor Hesabı

```verilog
for(j = 0; j < order; j = j + 1) begin 
    case(playerOrderSpeed[j])
        2'b00:  score[0][i] <= playerNo - j;
        2'b01:  score[1][i] <= playerNo - j;
        2'b10:  score[2][i] <= playerNo - j;
        2'b11:  score[3][i] <= playerNo - j;
        default: ;
    endcase
end
```

🔴 **HATA — `score` dizi boyutları runtime**

Yukarıda belirtildiği gibi `score[0:playerNo][0:turnNo]` sentezlenemez. Buradaki `score[0][i]` ve `score[1][i]` atamaları da bu yüzden geçersizdir.

🔴 **HATA — `playerNo - j` hesabı**

`playerNo` bir input portudur (runtime değer). `j` bir `genvar`'dır (derleme zamanı değişkeni). Aynı ifadede runtime ve compile-time değerlerin karıştırılması, `genvar`'ın `always` içinde kullanımı yasak olduğundan, sentez hatası verecektir.

⚠️ **Mantık sorunu:**

Puan hesabı `playerNo - j` şeklinde yapılmış. Yani:
- 1. basan → `playerNo - 0 = playerNo` puan
- 2. basan → `playerNo - 1` puan
- vb.

Bu şartnameyle **uyumlu** (4 oyuncu: 4-3-2-1 puan). Ancak `playerNo` 2 ise:
- 1. basan → 2 puan
- 2. basan → 1 puan
- Doğru.

Mantık doğru, implementasyon yanlış.

---

### Satır 132-147: Eleme Modu

```verilog
if(eliminationModeInput) begin
    order <= order - 1;
    for(j = 0; j < playerNo; j = j + 1) begin
        if((score[j][i] == 0) && !(playerOrderSpeed[order] == j)) begin 
            playerActive[j] <= 1'b0;
        end
    end
end
```

🔴 **HATA — `order <= order - 1` non-blocking + hemen okuma**

`order <= order - 1` non-blocking atanıyor. Hemen ardından `playerOrderSpeed[order]` okunuyor. Non-blocking'de okunan `order` değeri **eski** değerdir (azaltılmamış hali). Yani `playerOrderSpeed[order]` aslında son basanın **bir sonraki** (boş) indeksini okur.

Yorum bunu açıklamaya çalışmış: "[order - 1] olmasının sebebi yukarıda playerOrder'a veri koyduktan sonra otomatik +1 yaptırmam" — bu doğru bir gözlem ama non-blocking atama yüzünden `order - 1` etkisi **aynı cycle'da gerçekleşmez**.

🔴 **HATA — `playerOrderSpeed[order] == j` karşılaştırması**

Buradaki mantık: "skor 0 olan ve sıralamada sonuncu olmayan oyuncu elensin." Ancak `playerOrderSpeed` dizisi oyuncu sıralamasını tutar (hangi oyuncu kaçıncı bastı). `playerOrderSpeed[order] == j` ifadesi "en son basan oyuncu j mi?" demek — ama `order` hâlâ azaltılmamış eski değer (yukarıdaki non-blocking sorunu).

---

### Satır 150-152: False Start Sıfırlama

```verilog
for(j = 0; j < playerNo; j = j + 1) begin
    falseStart[j] <= 1'b0;
end
```

⚠️ **Uyarı:** Bu her tur sonunda false start'ları sıfırlıyor — mantıken doğru. Ama satır 36-49'daki konfigürasyon bloğu zaten **her clock cycle'da** `falseStart`'ı sıfırlıyor, bu yüzden bu blok gereksiz.

---

### Satır 154: `wait(BTNC)`

```verilog
wait(BTNC);
```

🔴 **KRİTİK HATA 11 — `wait` Sentezlenemez**

`wait` ifadesi Verilog'da yalnızca **simülasyon/testbench** yapısıdır. Sentez araçları bunu kabul etmez.

**Yazılım eşdeğeri:**
```c
while(!BTNC) { /* CPU bekler */ }
```

**Donanım eşdeğeri:**
```verilog
// FSM durumu:
WAIT_NEXT_TURN: begin
    if(BTNC_pulse)  // kenar algılama ile tek pulse
        state <= NEXT_TURN;
    // else: aynı durumda kal (donanım zaten "bekliyor")
end
```

---

### Satır 156: `order = 0`

```verilog
order = 0;
```

🔴 **HATA — `always @(posedge clk)` içinde blocking atama**

Bu aynı bloktaki diğer `order <= order + 1` (non-blocking) atamalarıyla çelişir. Blocking + non-blocking karışımı → tanımsız davranış.

---

### Satır 189: `endmodule`

```verilog
endmodule
```

⚠️ `endgenerate` eksik (satır 31'de açılan `generate` kapanmamış). `endmodule` doğru ama eksik kapanış yüzünden sentez aracı bunu parse bile edemeyecektir.

---

## 🗺️ HATA HARİTASI — Görsel Özet

```
Satır   Hata Tipi                                Şiddet
─────── ──────────────────────────────────────── ──────
15-19   Runtime dizi boyutu (score output)        🔴 KRİTİK
15-19   Port boyutları eksik                      🔴 KRİTİK
22-23   Runtime dizi boyutu (playerOrderSpeed)    🔴 KRİTİK
26      order register boyutu yetersiz (1 bit)    🔴 HATA
27      end_time register boyutu yetersiz         🔴 HATA
29-30   genvar always bloğunda kullanılmış        🔴 KRİTİK
31      generate kapanmamış (endgenerate yok)     🔴 KRİTİK
33      Reset mekanizması yok                     ⚠️ UYARI
39+41   Blocking + Non-blocking karışımı          🔴 KRİTİK
36-49   Konfigürasyon her cycle tekrarlanıyor     🔴 MANTIK
55      while() sentezlenemez                     🔴 KRİTİK
80      $time sentezlenemez                       🔴 KRİTİK
81      while($time) sentezlenemez                🔴 KRİTİK
108     #5 gecikme sentezlenemez                  🔴 KRİTİK
86+     order non-blocking artırım sorunu         🔴 HATA
113-126 score runtime dizi erişimi                🔴 KRİTİK
133     order non-blocking azaltım + hemen okuma  🔴 HATA
154     wait() sentezlenemez                      🔴 KRİTİK
156     Blocking atama posedge clk içinde          🔴 HATA
31/189  generate/endgenerate eşleşmesi yok        🔴 KRİTİK
```

**Toplam: 17 ayrı kritik/hata noktası** — Modülün **%100'ü** hatalıdır.

---

## ❓ "Tamam, Peki Ne Yapmalıyım?" — FSM Tabanlı Yeniden Yazım Rehberi

Modül sıfırdan yazılmalıdır. Aşağıda kavramsal FSM tasarımı:

### Önerilen FSM Durumları

```
                    ┌────────────┐
                    │   IDLE     │◄─── rst
                    └─────┬──────┘
                          │ start_game
                    ┌─────▼──────┐
                    │ TURN_INIT  │ ← tur sayacı sıfırla
                    └─────┬──────┘
                          │
                    ┌─────▼──────────┐
                    │ WAIT_BLACKOUT  │ ← kararmaSinyali bekle
                    │ (false start   │   buton basılırsa → ceza
                    │  kontrolü)     │
                    └─────┬──────────┘
                          │ kararmaSinyali == 1
                    ┌─────▼──────────┐
                    │ REACTION_WAIT  │ ← 5s sayaç çalışır
                    │ (buton basımı  │   her basış kaydedilir
                    │  kaydedilir)   │
                    └─────┬──────────┘
                          │ timeout (5s doldu) veya herkes bastı
                    ┌─────▼──────────┐
                    │ SCORE_CALC     │ ← skor hesapla
                    └─────┬──────────┘
                          │
                    ┌─────▼──────────┐
                    │ SHOW_RESULTS   │ ← LED/display güncelle
                    └─────┬──────────┘
                          │ BTNC basıldı
                    ┌─────▼──────────┐
                    │ ELIMINATION    │ ← eleme modu aktifse
                    │ CHECK          │   sonuncu oyuncuyu ele
                    └─────┬──────────┘
                          │
                    ┌─────▼──────┐    tur < turnNo?
                    │ NEXT_TURN  │───────────────→ TURN_INIT
                    └─────┬──────┘
                          │ tur == turnNo
                    ┌─────▼──────┐
                    │ GAME_OVER  │ ← endgame skor, kazanan
                    └────────────┘
```

### Temel Tasarım İlkeleri

```verilog
module gameLoop(
    input wire clk,
    input wire rst,
    input wire [3:0] turnNo,        // sabit boyut
    input wire [1:0] playerNo,      // sabit boyut (2-4 oyuncu → 2 bit)
    input wire BTNC_pulse,          // kenar algılanmış tek pulse
    input wire BTNU_pulse,
    input wire BTNL_pulse,
    input wire BTNR_pulse,
    input wire BTND_pulse,
    input wire eliminationMode,
    input wire kararmaSinyali,
    output reg [3:0] score_p1,      // her oyuncuya ayrı çıkış
    output reg [3:0] score_p2,
    output reg [3:0] score_p3,
    output reg [3:0] score_p4,
    output reg [3:0] playerActive,
    output reg [3:0] state_out      // debug için durum çıkışı
);

    // FSM durum tanımları
    localparam IDLE           = 4'd0;
    localparam TURN_INIT      = 4'd1;
    localparam WAIT_BLACKOUT  = 4'd2;
    localparam REACTION_WAIT  = 4'd3;
    localparam SCORE_CALC     = 4'd4;
    localparam SHOW_RESULTS   = 4'd5;
    localparam ELIM_CHECK     = 4'd6;
    localparam WAIT_NEXT_TURN = 4'd7;
    localparam GAME_OVER      = 4'd8;
    
    reg [3:0] state;
    reg [28:0] timer;          // 5 saniye sayaç (500M cycle)
    reg [3:0] currentTurn;
    reg [3:0] falseStart;
    reg [1:0] pressOrder [0:3]; // sabit boyut — max 4 oyuncu
    reg [1:0] orderCount;
    reg [3:0] pressed;         // hangi oyuncular bastı
    
    always @(posedge clk) begin
        if(rst) begin
            state <= IDLE;
            timer <= 0;
            // ... tüm register'lar sıfırlanır
        end else begin
            case(state)
                IDLE: begin
                    if(/* start sinyali */)
                        state <= TURN_INIT;
                end
                
                WAIT_BLACKOUT: begin
                    // Her clock'ta butonları kontrol et
                    // Basılırsa → false start kaydet
                    if(kararmaSinyali)
                        state <= REACTION_WAIT;
                end
                
                REACTION_WAIT: begin
                    timer <= timer + 1;
                    // Her clock'ta butonları kontrol et
                    // Basılırsa → sıra kaydet, zaman kaydet
                    if(timer >= 500_000_000)
                        state <= SCORE_CALC;  // timeout
                end
                
                // ... diğer durumlar
            endcase
        end
    end
endmodule
```

---

## 📊 Mevcut Kod vs. Doğru Yaklaşım — Karşılaştırma Tablosu

| Mevcut Kodda | Doğru Donanım Yaklaşımı |
|---|---|
| `while(!kararmaSinyali)` — CPU tarzı bekleme | FSM durumu: `WAIT_BLACKOUT` — her clock'ta kontrol |
| `$time + 500000000` — simülasyon zamanı | 29 bit sayaç: `timer <= timer + 1` |
| `#5` — sanal gecikme | Donanımda gecikme yok; her clock otomatik |
| `wait(BTNC)` — sinyal bekleme | FSM durumu: `WAIT_NEXT_TURN` — BTNC pulse kontrolü |
| `genvar` + `for` inside `always` | `integer` + `for` inside `always` |
| `score[0:playerNo]` — dinamik dizi | `score[0:3]` — sabit boyut, `parameter MAX=4` |
| `generate` + `always` — yanlış sarmalama | `generate` yok; tek `always` bloğu yeterli |
| `=` ve `<=` karışık | Sadece `<=` (non-blocking) — senkron bloklarda |

---

## 🎯 Sonuç

Bu modül bir **yazılım programı** gibi yazılmıştır:
- Sıralı yürütme varsayılmış (satır satır çalışır gibi)
- Döngüler "çalışma zamanında" tekrar eder gibi düşünülmüş
- Bekleme fonksiyonları (`wait`, `while`, `#delay`) kullanılmış
- Simülasyon fonksiyonları (`$time`) donanım gibi kullanılmış

Verilog'da tüm `always @(posedge clk)` blokları her clock edge'inde **paralel olarak** çalışır. "Bekle", "dön", "zamanlayıcı" kavramları ancak **FSM durumları** ve **sayaçlar** ile gerçekleştirilir.

> **Bu modül tamir edilemez.** Patch uygulanarak düzeltilebilecek seviyede değildir. **Sıfırdan**, FSM tabanlı olarak yeniden yazılmalıdır.
