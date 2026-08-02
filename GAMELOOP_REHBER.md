# 🛠️ gameLoop Modülü — Sıfırdan Yazım Rehberi

**Tarih:** 2026-08-02  
**Amaç:** `6_Main_Game_Loop.v` dosyasını FSM tabanlı olarak sıfırdan yazmak  
**Kural:** Bu dosyada tam kod yok — sadece yol haritası, ipuçları ve minik örnek parçalar var. Kodu siz yazacaksınız.

---

## 📐 GENEL YAPI — Dosya Taslağı

Dosyanız kabaca şu sırada olacak:

```
1. `timescale ve modül tanımı (portlar)
2. Sabitler (localparam — FSM durumları)
3. Register tanımları (state, timer, sayaçlar, vb.)
4. Tek bir always @(posedge clk) bloğu
   └─ if(rst) → tüm register'ları sıfırla
   └─ else → case(state) ile FSM
       ├─ IDLE
       ├─ TURN_INIT
       ├─ WAIT_RANDOM_DELAY
       ├─ FALSE_START_WINDOW
       ├─ REACTION_WAIT
       ├─ SCORE_PHASE
       ├─ SHOW_RESULTS
       ├─ ELIMINATION_CHECK
       ├─ WAIT_NEXT_TURN
       └─ GAME_OVER
5. endmodule
```

**Temel kural:** Tek bir `always @(posedge clk)` bloğu, içinde tek bir `case(state)`. Her şey burada olacak. `while` yok, `wait` yok, `$time` yok, `#delay` yok.

---

## 🔌 BÖLÜM 0 — Port Listesi (Modül Tanımı)

**Ne yapılacak:** Modülün giriş ve çıkışlarını tanımla. Mevcut projedeki diğer modüllerle uyumlu olması **çok önemli**.

**Giriş portları — bunlara ihtiyacın var:**

| Port | Boyut | Nereden Geliyor | Açıklama |
|------|-------|-----------------|----------|
| `clk` | 1 bit | Basys3 | 100 MHz saat sinyali |
| `rst` | 1 bit | `sw[15]` | Reset |
| `start` | 1 bit | Top modül | Config bittikten sonra oyunu başlatma sinyali (`confinish`'ten türetilebilir) |
| `playerNo` | `[2:0]` | ConfigMenu | Oyuncu sayısı (2-4). **3 bit yeterli.** |
| `turnNo` | `[3:0]` | ConfigMenu | Toplam tur sayısı (1-16) |
| `eliminationMode` | 1 bit | ConfigMenu | Eleme modu açık mı |
| `center` | 1 bit | TusKontrolu | BTNC — kenar algılanmış tek pulse (sonraki tura geçmek için) |
| `up` | 1 bit | TusKontrolu | BTNU — Oyuncu 1 butonu (pulse) |
| `left` | 1 bit | TusKontrolu | BTNL — Oyuncu 2 butonu (pulse) |
| `right` | 1 bit | TusKontrolu | BTNR — Oyuncu 3 butonu (pulse) |
| `down` | 1 bit | TusKontrolu | BTND — Oyuncu 4 butonu (pulse) |
| `kararmaSinyali` | 1 bit | segmentDisplay7 | 7-segment karardı sinyali |
| `waitTimeValid` | 1 bit | random_delay_gen | Bekleme süresi hazır |
| `waitTime` | `[29:0]` | random_delay_gen | Bekleme süresi (cycle) |

> ⚠️ **ÖNEMLİ:** `TusKontrolu` modülü zaten **kenar algılaması** yapıyor. Çıkışları (`SinyalBTNU`, `SinyalBTNL`, vb.) yalnızca **1 clock cycle** boyunca 1 olur. Bu yüzden `gameLoop`'ta ayrıca kenar algılama yapmanıza **gerek yok**. Gelen `up`, `left`, `right`, `down` sinyalleri zaten tek pulse.

**Çıkış portları — bunları üretmen lazım:**

| Port | Boyut | Nereye Gidiyor | Açıklama |
|------|-------|----------------|----------|
| `player1Time` ... `player4Time` | `[29:0]` her biri | ScoreCalc | Reaksiyon süresi (clock cycle sayısı) |
| `timeoutPlayers` | `[3:0]` | ScoreCalc | Hangi oyuncular timeout oldu |
| `falseStartPlayers` | `[3:0]` | ScoreCalc | Hangi oyuncular erken bastı |
| `playersActive` | `[3:0]` | ScoreCalc, playerLEDs | Aktif oyuncular |
| `currentTurn` | `[3:0]` | segmentDisplay7, UART | Kaçıncı tur |
| `gameState` | `[3:0]` | Top modül (debug/kontrol) | Mevcut FSM durumu |
| `turnDone` | 1 bit | ScoreCalc tetiklemesi | Tur bitti sinyali |
| `gameOver` | 1 bit | ScoreCalcEndgame tetiklemesi | Oyun bitti sinyali |
| `triggerRNG` | 1 bit | random_delay_gen | Rastgele süre hesapla |

**İpucu — Port tanım stili:**

```verilog
module gameLoop(
    input wire        clk,
    input wire        rst,
    input wire        start,
    input wire [2:0]  playerNo,
    input wire [3:0]  turnNo,
    // ... devamı
    output reg [29:0] player1Time,
    // ... devamı
);
```

Her portu **ayrı satırda** yaz, tip ve boyutu **açıkça** belirt. Karışıklık olmasın.

---

## 📦 BÖLÜM 1 — Sabitler ve Register'lar

**Ne yapılacak:** FSM durum kodlarını `localparam` ile tanımla. Sonra ihtiyacın olan tüm register'ları tanımla.

### 1.1 — FSM Durum Kodları

`localparam` kullan (parametre gibi ama modül dışından değiştirilemez). Her duruma bir numara ver.

```verilog
localparam IDLE             = 4'd0;
localparam TURN_INIT        = 4'd1;
// ... her durum için bir tane
```

> 💡 **İpucu:** 10 civarı durum olacak → 4 bit yeterli (0-15 arası).

### 1.2 — Register Tanımları

Lazım olacak register'lar:

| Register | Boyut | Kullanım |
|----------|-------|----------|
| `state` | `[3:0]` | FSM'in o anki durumu |
| `reactionTimer` | `[29:0]` | Reaksiyon süresi sayacı (5 sn = 500M cycle) |
| `currentTurn` | `[3:0]` | Kaçıncı tur (0'dan başlar) |
| `playersActive` | `[3:0]` | Hangi oyuncular hâlâ oyunda (bit bazlı: bit 0 = P1) |
| `pressed` | `[3:0]` | Bu turda kimlerin bastığını işaretle |
| `falseStartPlayers` | `[3:0]` | Erken basanlar |
| `timeoutPlayers` | `[3:0]` | Timeout olanlar |
| `player1Time` ... `player4Time` | `[29:0]` | Her oyuncunun reaksiyon süresi |
| `waitCounter` | `[29:0]` | Rastgele bekleme süresini saymak için |
| `waitTarget` | `[29:0]` | random_delay_gen'den gelen hedef süre |

> ⚠️ **DİKKAT:** Boyutları doğru ver! 
> - 500_000_000 (5 saniye) → `[28:0]` → 29 bit minimum (2^29 = 536M)
> - Ama `waitTime` 30 bit (`[29:0]`) olarak geliyor → `[29:0]` kullan, uyumlu olsun.

> ⚠️ **DİKKAT:** Dizi boyutları **sabit** olmalı. `[0:playerNo]` gibi runtime değerle dizi tanımlama **yasak**. Maksimum 4 oyuncu olduğunu biliyorsun → `[3:0]` veya `[0:3]` kullan.

---

## ⚡ BÖLÜM 2 — Reset Bloğu

**Ne yapılacak:** `always @(posedge clk)` bloğunun en başında `if(rst)` ile **tüm register'ları** güvenli başlangıç değerlerine ata.

**Kurallar:**
- Her register **mutlaka** reset edilmeli. Atlanırsa power-on'da `X` (belirsiz) olur.
- Sadece **non-blocking** (`<=`) kullan.
- `state <= IDLE;` ile FSM başlangıç durumuna dön.
- `playersActive <= 4'b0000;` — oyun başlamadan aktif oyuncu yok.
- Tüm timer/sayaç → `0`
- Tüm zaman kayıtları → `0`
- Tüm flag'ler → `0`

**Örnek yapı:**

```verilog
always @(posedge clk) begin
    if(rst) begin
        state           <= IDLE;
        currentTurn     <= 4'd0;
        reactionTimer   <= 30'd0;
        playersActive   <= 4'b0000;
        // ... hepsini sıfırla
    end
    else begin
        case(state)
            // FSM buraya gelecek
        endcase
    end
end
```

---

## 🔁 BÖLÜM 3 — FSM Durumları (case bloğu)

Bu en büyük bölüm. Her durumu ayrı ayrı açıklıyorum.

---

### 🟢 Durum 0: `IDLE`

**Ne yapar:** Hiçbir şey — oyun başlamasını bekler.

**Geçiş koşulu:** `start` sinyali geldiğinde → `TURN_INIT`'e geç.

**Bu durumda yapılacaklar:**
- `playersActive` register'ını `playerNo`'ya göre doldur.
  - `playerNo == 2` → `playersActive <= 4'b0011;`
  - `playerNo == 3` → `playersActive <= 4'b0111;`
  - `playerNo == 4` → `playersActive <= 4'b1111;`
- `currentTurn <= 0;`

> 💡 **İpucu:** `playerNo` değerini `case` ile kontrol edip `playersActive`'e uygun bitmask atayabilirsin. Ya da `if-else` zinciri.

---

### 🟢 Durum 1: `TURN_INIT`

**Ne yapar:** Yeni tura hazırlık. Geçen turdan kalan verileri temizler.

**Bu durumda yapılacaklar:**
1. `reactionTimer <= 0;`
2. `pressed <= 4'b0000;`
3. `falseStartPlayers <= 4'b0000;`
4. `timeoutPlayers <= 4'b0000;`
5. `player1Time <= 0; ... player4Time <= 0;`
6. `triggerRNG <= 1'b1;` — Rastgele süre üretimini tetikle.

**Geçiş:** → Hemen `WAIT_RANDOM_DELAY`'e geç (1 cycle yeterli).

> 💡 `triggerRNG`, `random_delay_gen` modülünün `tetiklenme` girişine bağlanacak. Tek cycle'lık pulse olmalı.

---

### 🟢 Durum 2: `WAIT_RANDOM_DELAY`

**Ne yapar:** `random_delay_gen` modülünün hesabını bitirmesini bekler.

**Bu durumda yapılacaklar:**
1. `triggerRNG <= 1'b0;` — pulse'u kapat (sadece 1 cycle aktif olmalıydı).
2. `waitTimeValid` sinyalini kontrol et.

**Geçiş koşulu:** `waitTimeValid == 1` olduğunda:
- `waitTarget <= waitTime;` — hesaplanan süreyi kaydet.
- `waitCounter <= 0;` — sayacı sıfırla.
- → `FALSE_START_WINDOW`'a geç.

> 💡 `random_delay_gen` 3 cycle'lık pipeline kullanıyor. Yani `triggerRNG` pulse'undan ~3 cycle sonra `waitTimeValid` 1 olacak. Bu durumda beklemen yeterli.

---

### 🟢 Durum 3: `FALSE_START_WINDOW`

**Ne yapar:** 7-segment display sayım gösterirken (karartma öncesi), erken basan oyuncuları yakalar.

**Bu durum, eski kodundaki `while(!kararmaSinyali)` yapısının yerine geçer.** Fark şu: `while` yerine FSM durumu kullanıyoruz. Her clock edge'inde:
1. Butonları kontrol et.
2. `kararmaSinyali` geldi mi kontrol et.

**Bu durumda yapılacaklar (her clock cycle'da):**

```
Her clock cycle:
  - Eğer playersActive[0] && up geldi   → falseStartPlayers[0] <= 1
  - Eğer playersActive[1] && left geldi → falseStartPlayers[1] <= 1
  - Eğer playersActive[2] && right geldi→ falseStartPlayers[2] <= 1
  - Eğer playersActive[3] && down geldi → falseStartPlayers[3] <= 1
```

**Geçiş koşulu:** `kararmaSinyali == 1` olduğunda → `REACTION_WAIT`'e geç ve `reactionTimer <= 0`.

> ⚠️ **ÖNEMLİ:** `kararmaSinyali`, `segmentDisplay7` modülünden gelecek. O modülün `bitisSinyali` çıkışı buna karşılık geliyor. Top modülde bağlantı yapman gerekecek.

> 💡 **İpucu:** `up`, `left`, `right`, `down` zaten **tek pulse** (TusKontrolu sayesinde). Bir oyuncu 1 kez basarsa sadece 1 cycle boyunca 1 gelir. O yüzden `falseStartPlayers[0] <= 1'b1` yaptıktan sonra tekrar 0'a dönmesine gerek yok — tur sonuna kadar 1 kalacak.

---

### 🟢 Durum 4: `REACTION_WAIT`

**Bu modülün kalbi.** Eski kodundaki `while($time <= end_time)` ve `#5` yapılarının yerine geçer.

**Ne yapar:** 
- Sayaç sayar (her cycle +1).
- Oyuncuların buton basışlarını kaydeder.
- 5 saniye dolduğunda durumu değiştirir.

**Bu durumda yapılacaklar (her clock cycle'da):**

```
1. reactionTimer <= reactionTimer + 1;   // zaman ilerliyor

2. Her oyuncu için kontrol:
   - Eğer playersActive[0] && !pressed[0] && !falseStartPlayers[0] && up geldi:
       → pressed[0] <= 1
       → player1Time <= reactionTimer   // basış anının zamanı
   
   - Aynısı oyuncu 2, 3, 4 için (left, right, down)

3. Timeout kontrolü:
   - Eğer reactionTimer >= 500_000_000 (5 saniye):
       → Henüz basmamış ve false start olmamış oyuncuları timeout yap:
         if(playersActive[X] && !pressed[X] && !falseStartPlayers[X])
             timeoutPlayers[X] <= 1
       → state <= SCORE_PHASE
   
4. Erken çıkış (opsiyonel optimizasyon):
   - Tüm aktif oyuncular bastıysa veya cezalıysa → 5 saniye beklemeden SCORE_PHASE'e geç.
```

> 💡 **Kritik kavram:** Her oyuncu **yalnızca bir kez** basabilir. `pressed[X]` flag'i bunu sağlar. Bir oyuncu bastıktan sonra `pressed[X] = 1` olur ve tekrar kontrol edilmez.

> 💡 **Reaksiyon süresi neden `reactionTimer`?** Çünkü donanımda `$time` yok. Sayaç her clock'ta 1 artıyor. 100 MHz'de 1 cycle = 10ns. Yani `reactionTimer * 10ns` = gerçek süre. Ama sen cycle sayısını doğrudan `ScoreCalc`'a verebilirsin — o da karşılaştırma yapıyor, birimlerin aynı olması yeterli.

> ⚠️ **DİKKAT:** `500_000_000` sabitini `localparam` olarak tanımla:
> ```verilog
> localparam TIMEOUT_CYCLES = 30'd500_000_000;  // 5 saniye @ 100MHz
> ```

---

### 🟢 Durum 5: `SCORE_PHASE`

**Ne yapar:** `ScoreCalc` modülüne "hesapla" sinyali gönderir.

**Bu durumda yapılacaklar:**
1. `turnDone <= 1'b1;` — ScoreCalc modülünü tetikle.
2. **1 cycle bekle**, sonra → `SHOW_RESULTS`'a geç.

> 💡 `ScoreCalc` modülü şu an `always @(posedge clk)` ile sürekli çalışıyor — yani giriş değerleri değiştiğinde otomatik hesaplıyor. Ama idealde bir `start` sinyali eklenip sadece o zaman hesaplatılmalı (Realization'da H7/enable eksikliği olarak belirtilmişti). **Şimdilik** sadece doğru verileri girişlere koyman yeterli olabilir.

---

### 🟢 Durum 6: `SHOW_RESULTS`

**Ne yapar:** Tur sonuçlarını gösterir (LED'ler + display). BTNC ile sonraki tura geçişi bekler.

**Bu durum, eski kodundaki `wait(BTNC)` yapısının yerine geçer.**

**Bu durumda yapılacaklar (her clock cycle'da):**
1. `turnDone <= 1'b0;` — pulse'u kapat.
2. `center` pulse'unu bekle.

**Geçiş koşulu:** `center == 1` (BTNC basıldı) olduğunda:
- Eleme modu açıksa → `ELIMINATION_CHECK`'e geç.
- Eleme modu kapalıysa → `WAIT_NEXT_TURN`'e geç.

---

### 🟢 Durum 7: `ELIMINATION_CHECK`

**Ne yapar:** Eleme modunda cezalı oyuncuları devre dışı bırakır.

**Bu durumda yapılacaklar:**

```
Her oyuncu için (0-3):
  if(timeoutPlayers[X] || falseStartPlayers[X])
      playersActive[X] <= 1'b0;   // elendin!
```

**Ek kontrol — Tek oyuncu kaldı mı?**

Aktif oyuncu sayısını kontrol et. Eğer 1 veya 0 kaldıysa → oyun bitmeli.

> 💡 **İpucu:** Aktif oyuncu sayısını saymanın kolay yolu:
> ```verilog
> // Bit sayma (popcount) — 4 bit için basit yöntem:
> wire [2:0] activeCount = playersActive[0] + playersActive[1] 
>                        + playersActive[2] + playersActive[3];
> ```
> Bu bir **wire** olarak `always` bloğunun dışında tanımlanabilir ve kombinasyonel olarak hesaplanır.

**Geçiş:**
- `activeCount <= 1` → `GAME_OVER`
- Aksi halde → `WAIT_NEXT_TURN`

---

### 🟢 Durum 8: `WAIT_NEXT_TURN`

**Ne yapar:** Tur numarasını artırır ve sıradaki tura mı yoksa oyun sonuna mı gidileceğini belirler.

**Bu durumda yapılacaklar:**
1. `currentTurn <= currentTurn + 1;`

**Geçiş koşulu:**
- `currentTurn + 1 >= turnNo` → `GAME_OVER` (tüm turlar bitti)
- Aksi halde → `TURN_INIT` (yeni tur başla)

> ⚠️ **DİKKAT:** `currentTurn` non-blocking ile güncelleniyor. Karşılaştırmayı **eski değerle** yap:
> ```
> if(currentTurn + 1 >= turnNo)  // currentTurn henüz artmadı, +1 ile kontrol et
> ```
> Veya alternatif olarak: karşılaştırmayı **bu** durumda yap, artırımı **TURN_INIT**'te yap.

---

### 🟢 Durum 9: `GAME_OVER`

**Ne yapar:** Oyun sona erdi. `gameOver` sinyalini verir.

**Bu durumda yapılacaklar:**
1. `gameOver <= 1'b1;` — ScoreCalcEndgame ve playerLEDsEndgame modüllerini tetikle.
2. Burada kalır. Sadece `rst` ile çıkılır.

---

## 🔗 BÖLÜM 4 — Top Modülde Bağlantı (1_Main.v)

Modülü yazdıktan sonra `1_Main.v`'de örneklemen gerekecek. Şu anki top modülde `gameLoop` **bağlanmamış** durumda.

**Yapılması gerekenler:**
1. Gerekli wire'ları tanımla (gameLoop'un çıkışları için).
2. `gameLoop` modülünü örnekle.
3. `ScoreCalc` modülünü örnekle ve gameLoop çıkışlarını giriş olarak bağla.
4. `playerLEDs` modülünü örnekle.
5. `segmentDisplay7` modülünü örnekle.

**Bağlantı şeması (akış):**

```
ConfigMenu ──→ gameLoop ──→ ScoreCalc ──→ playerLEDs ──→ LED[15:0]
    │              │                          │
    │              ↓                          ↓
    │        segmentDisplay7 ──→ seg[6:0], an[3:0]
    │              ↑
    │              │
    └──── random_delay_gen
```

**Örnek örnekleme (port bağlantısı stili):**
```verilog
gameLoop game(
    .clk(clk),
    .rst(rst),
    .start(confinish),
    .playerNo(playersIn),      // ConfigMenu'den
    .turnNo(turnNo),           // ConfigMenu'den
    .eliminationMode(elimination),
    .center(center),           // TusKontrolu'ndan
    .up(up),
    .left(left),
    .right(right),
    .down(down),
    .kararmaSinyali(/* segmentDisplay7'den */),
    .waitTimeValid(waitTimeValid),
    .waitTime(waitTime),
    // çıkışlar...
    .player1Time(p1Time_wire),
    .triggerRNG(/* random_delay_gen tetiklemesine bağla */)
    // ... devamı
);
```

> ⚠️ **ÖNEMLİ:** `random_delay_gen`'in `tetiklenme` girişi şu an `center`'a bağlı. Bunu gameLoop'un `triggerRNG` çıkışına bağlaman gerekecek. Çünkü artık rastgele süre üretimini **gameLoop FSM'i** kontrol edecek, kullanıcı değil.

---

## ✅ BÖLÜM 5 — Kontrol Listesi (Yazdıktan Sonra)

Kodu yazdıktan sonra bu listeyi kontrol et:

### Sentez Kuralları
- [ ] `while` kullanılmadı
- [ ] `wait` kullanılmadı
- [ ] `$time` kullanılmadı
- [ ] `#delay` kullanılmadı
- [ ] `generate` / `endgenerate` kullanılmadı (gerek yok)
- [ ] `genvar` kullanılmadı (gerek yok)
- [ ] Tüm dizi boyutları **sabit** (runtime değişken yok)

### Kodlama Kuralları
- [ ] `always @(posedge clk)` içinde **sadece non-blocking** (`<=`) atama var
- [ ] Her register `if(rst)` bloğunda sıfırlanıyor
- [ ] `case(state)` içinde her durum tanımlı
- [ ] `default:` durumu var (güvenlik için)
- [ ] Port boyutları açıkça belirtilmiş (`[29:0]`, `[3:0]` vb.)
- [ ] Çıkışlar `output reg` olarak tanımlı (always içinde atandıkları için)

### Mantık Kuralları
- [ ] Her oyuncu **yalnızca bir kez** basabiliyor (`pressed` flag ile)
- [ ] False start oyuncuları reaksiyon fazında **kontrol edilmiyor**
- [ ] Timeout, 500_000_000 cycle'da tetikleniyor
- [ ] Tur numarası her turda artıyor
- [ ] Eleme modunda devre dışı kalan oyuncu bir sonraki turda oynamıyor
- [ ] Oyun, tüm turlar bittiğinde **veya** tek oyuncu kaldığında bitiyor
- [ ] `triggerRNG` yalnızca **1 cycle** boyunca HIGH (pulse)

### Bağlantı Kuralları  
- [ ] Top modülde gameLoop örneklenmiş
- [ ] `random_delay_gen` tetiklemesi `triggerRNG`'ye bağlı (artık `center`'a değil)
- [ ] `segmentDisplay7`'nin `bitisSinyali` çıkışı `kararmaSinyali`'na bağlı
- [ ] `ScoreCalc` girişleri gameLoop çıkışlarına bağlı

---

## ⚠️ BÖLÜM 6 — Sık Yapılan Hatalar ve Uyarılar

### ❌ Hata 1: "Her clock cycle'da bir şey yapması lazım ama yapmıyor"
FSM'de her durumda **sadece o durumun işini** yap. Diğer durumların kodları **çalışmaz** — zaten çalışmaması gerekir. `case` bloğunda sadece eşleşen durum yürütülür.

### ❌ Hata 2: "Sayaç artmıyor / sıfırlanmıyor"
Non-blocking atama (`<=`) **aynı cycle'da** etkisini göstermez. Sonraki cycle'da yeni değer geçerli olur. Yani:
```verilog
reactionTimer <= 0;           // bu cycle sonunda 0 olur
// reactionTimer hâlâ eski değerde — aynı cycle'da okursan eski değeri görürsün
```
Bu yüzden sayacı sıfırlama ve okumayı **aynı cycle'da** yapma.

### ❌ Hata 3: "`playerNo` ile karşılaştırma"
`playerNo` ConfigMenu'den `[2:0]` olarak geliyor. Değeri şu an `playersIn` wire'ından okunuyor — bu 4 bitlik bir bitmask (`1100`, `1110`, `1111`), **sayı değil**. Dikkat: ConfigMenu'de `playersIn[0]` = Oyuncu 1 aktif mi, `playersIn[1]` = Oyuncu 2 aktif mi... şeklinde.

Eğer sayısal karşılaştırma yapacaksan (mesela `playerNo == 3`), ConfigMenu'den ayrı bir sayısal çıkış kullanman veya bitmask'tan sayı türetmen gerekir.

### ❌ Hata 4: "Pulse sinyali kaçıyor"
`TusKontrolu`'nun çıkışları **tek cycle pulse**. FSM başka bir durumda iken gelen pulse **kaybolur**. Bu istenen davranıştır: sadece doğru durumda (REACTION_WAIT veya FALSE_START_WINDOW) gelen basışlar dikkate alınır.

### ❌ Hata 5: "Aynı register'a birden fazla yerde atama"
`always @(posedge clk)` bloğunda aynı register'a birden fazla `case` durumunda atama yapabilirsin — **sorun değil**, çünkü aynı anda sadece bir `case` çalışır. Ama **aynı durum içinde** aynı register'a birden fazla non-blocking atama yaparsan, **son atama kazanır**.

---

## 🗺️ BÖLÜM 7 — Özet Akış Diyagramı

```
rst aktif
    │
    ▼
 ┌──────┐   start=1    ┌───────────┐
 │ IDLE │──────────────▶│ TURN_INIT │◄─────────────────┐
 └──────┘               └─────┬─────┘                  │
                              │                        │
                        ┌─────▼──────────────┐         │
                        │ WAIT_RANDOM_DELAY  │         │
                        │ (RNG hesabı bekle) │         │
                        └─────┬──────────────┘         │
                              │ waitTimeValid=1        │
                        ┌─────▼──────────────┐         │
                        │ FALSE_START_WINDOW │         │
                        │ (erken basış izle) │         │
                        └─────┬──────────────┘         │
                              │ kararmaSinyali=1       │
                        ┌─────▼──────────────┐         │
                        │ REACTION_WAIT      │         │
                        │ (sayaç + basış)    │         │
                        └─────┬──────────────┘         │
                              │ timeout/herkes bastı   │
                        ┌─────▼──────────────┐         │
                        │ SCORE_PHASE        │         │
                        │ (turnDone pulse)   │         │
                        └─────┬──────────────┘         │
                              │                        │
                        ┌─────▼──────────────┐         │
                        │ SHOW_RESULTS       │         │
                        │ (BTNC bekle)       │         │
                        └─────┬──────────────┘         │
                              │ center=1               │
                    ┌─────────┴─────────┐              │
                    │                   │              │
              eleme aktif?         eleme yok           │
                    │                   │              │
              ┌─────▼──────────┐        │              │
              │ ELIM_CHECK     │        │              │
              │ (oyuncu ele)   │        │              │
              └─────┬──────────┘        │              │
                    │                   │              │
                    └─────────┬─────────┘              │
                              │                        │
                        ┌─────▼──────────────┐         │
                        │ WAIT_NEXT_TURN     │         │
                        │ currentTurn++      │         │
                        └─────┬──────────────┘         │
                              │                        │
                    ┌─────────┴──────────┐             │
                    │                    │             │
              tur bitmedi?         turlar bitti         │
                    │              veya 1 kişi kaldı   │
                    │                    │             │
                    └──────────┐   ┌─────▼──────┐     │
                               │   │ GAME_OVER  │     │
                               │   └────────────┘     │
                               │                      │
                               └──────────────────────┘
```

---

## 🏁 Sonuç — Nereden Başla?

1. **Önce BÖLÜM 0'ı yaz** — port listesini tanımla. Derlenmesine bile gerek yok, sadece portları doğru boyutlarla yaz.
2. **BÖLÜM 1'i yaz** — `localparam` ve register tanımları.
3. **BÖLÜM 2'yi yaz** — Reset bloğu.
4. **BÖLÜM 3'ü durum durum yaz.** Önce `IDLE` ve `TURN_INIT` ile başla. Sonra `REACTION_WAIT`'i yaz (en zor kısım). Son olarak `GAME_OVER`'ı yaz.
5. **BÖLÜM 4** — Top modülde bağla.
6. **BÖLÜM 5** — Kontrol listesinden geç.

Yazdıktan sonra dosyayı bana at — ben de satır satır kontrol edip "tamam bu modül artık çalışabilir" ya da "şurada sorun var" diyeceğim. 💪
