# DENETİM RAPORU – Çok Oyunculu Basys3 Refleks Oyunu

**Tarih:** 2026-08-02  
**Kapsam:** Proje şartnamesine (Proje.txt) uyum, modül içi hatalar, modüller arası iletişim  
**Not:** Bu rapor yalnızca analiz ve inceleme içerir; hiçbir .v/.sv dosyasında değişiklik yapılmamıştır.

---

## 1. Genel Mimarinin ve Bağlantıların İncelenmesi

### 1.1 Modül Haritası (Top-Level: `Main`)

Top-level modül `Main` (1_Main.v) aşağıdaki alt modülleri örneklemektedir:

| # | Modül Adı | Dosya | Örnekleme Adı | Durum |
|---|-----------|-------|---------------|-------|
| 1 | `debounce` | 5.1_Debounce.v | `dbC` | ✅ Bağlı |
| 2 | `ConfigMenu` | 2_ConfigMenu.v | `configM` | ✅ Bağlı |
| 3 | `TusKontrolu` | 5.2_TusKontrolu.v | `buttons` | ✅ Bağlı |
| 4 | `lfsr16` | 4.1_lfsr16.v | `lfsrModule` | ✅ Bağlı |
| 5 | `random_delay_gen` | 4.2_RSO.v | `RNGesus` | ✅ Bağlı |
| 6 | `segmentDisplay7` | 3_7segmentDisplay.v | — | ❌ **BAĞLANMAMIŞ** |
| 7 | `gameLoop` | 6_Main_Game_Loop.v | — | ❌ **BAĞLANMAMIŞ** |
| 8 | `ScoreCalc` | 7.1_ScoreCalc.v | — | ❌ **BAĞLANMAMIŞ** |
| 9 | `ScoreCalcEndgame` | 7.2_ScoreCalcEndgame.v | — | ❌ **BAĞLANMAMIŞ** |
| 10 | `playerLEDs` | 8.1_playerLEDs.v | — | ❌ **BAĞLANMAMIŞ** |
| 11 | `playerLEDsEndgame` | 8.2_playerLEDsEndgame.v | — | ❌ **BAĞLANMAMIŞ** |

> **KRİTİK:** Top modülde 6 alt modül hiç örneklenmemiştir. `Main` modülü yalnızca konfigürasyon, debounce, LFSR ve rastgele süre üreticisini bağlamaktadır. Oyun döngüsü, skor hesabı, LED kontrolü ve 7-segment display entegre edilmemiştir. UART modülü ise henüz hiç yazılmamıştır.

### 1.2 UART Eksikliği

Şartname Bölüm 9, UART 9600 baud 8N1 çıkışını zorunlu tutar. Projede:
- UART modülü dosyası yoktur.
- Top modülde `RsTx` portu tanımlı ancak hiçbir mantığa bağlanmamış (askıda wire).
- XDC'de `RsRx` ve `RsTx` pinleri aktif. `RsRx` top modülde tanımlı değil; sentez uyarısı verecektir.

### 1.3 Top-Level Port & Pin Eşleşmeleri

| Top Port | XDC Port Adı | Uyum |
|----------|-------------|------|
| `clk` | `clk` | ✅ |
| `sw[15:0]` | `sw[15:0]` | ✅ |
| `btnC/btnU/btnL/btnR/btnD` | `btnC/btnU/btnL/btnR/btnD` | ✅ |
| `led[15:0]` | `led[15:0]` | ✅ |
| `seg[6:0]` | `seg[6:0]` | ✅ |
| `dp` | `dp` | ✅ |
| `an[3:0]` | `an[3:0]` | ✅ |
| `RsTx` | `RsTx` | ⚠️ Port var, mantık yok |
| — | `RsRx` | ❌ Top modülde tanımsız |

### ~~1.4 LED Çıkışı Çakışması~~ ✅ DÜZELTİLDİ

`ConfigMenu` modülü `led[15:0]` çıkışı üretmekte ve top modülde doğrudan `led` portuna bağlanmaktadır. Ancak `playerLEDs` ve `playerLEDsEndgame` modülleri de `leds[15:0]` çıkışı üretmek üzere tasarlanmıştır. Şu anki bağlantıda LED çıkışı tamamen `ConfigMenu`'ye ait. Oyun sırasında LED'lerin oyuncu sıralamasına göre yanması için bir multiplexer/FSM ile kaynak seçimi yapılması gerekmektedir.

> ✅ **DURUM: DÜZELTİLDİ** — Ternary multiplexer eklendi: `assign led = ((confinish) ? ledsGame : ledsConfig);`. Ancak `ledsGame` henüz bağlanmamış — E1 ile tamamlanmalı.

### 1.5 7-Segment Display Çıkışı

`seg` ve `an` portları top modülde wire olarak tanımlıdır ancak hiçbir modüle bağlanmamıştır. `segmentDisplay7` modülü bu çıkışları üretir ama top modülde örneklenmemiştir. Bu nedenle display çalışmayacaktır.

### ~~1.6 `center` Wire'ında Çoklu Sürücü (Multi-Driver) Hatası — KRİTİK~~ ✅ DÜZELTİLDİ

Top modülde:
- `debounce dbC(btnC, clk, rst, center)` → `center` wire'ını süren 1. kaynak (debounce çıkışı `TemizSinyal`, `output reg`).
- `TusKontrolu buttons(clk, rst, playersIn, btnC, btnU, btnL, btnR, btnD, center, up, left, right, down)` → Pozisyonel eşleştirmede 9. port `SinyalBTNC` (`output reg`) `center` wire'ına bağlanıyor. Bu, `center` wire'ını süren 2. kaynak.
- **Aynı wire'a iki `output reg` bağlanması çoklu sürücü (multi-driver) hatası oluşturur.** Simülasyonda `center` sinyali `X` (belirsiz) değerine düşer. Sentezde ise araç ya hata verir ya da öngörülemeyen davranış üretir.
- Bu hata, `ConfigMenu`'ye ve `random_delay_gen`'e verilen `center` sinyalini tamamen bozan kritik bir sorundur.

> **NOT (Öz-düzeltme):** Bu sorun ilk raporda "çift debounce" olarak hafif nitelendirilmişti. Tekrar incelendiğinde bunun bir **multi-driver hatası** olduğu tespit edilmiştir.

> ✅ **DURUM: DÜZELTİLDİ** — `centerForConfigSpecifically` wire'ı tanımlanarak `debounce dbC` çıkışı buna, `TusKontrolu` çıkışı `center`'a bağlandı.

---

## 2. Modül Bazlı Detaylı Analizler

---

### 2.1 `Main` (1_Main.v)

**Açıklama/Comment Analizi:**
- Modül başında "We need to fix MainGameLoop ASAP!!!! / We also need UART to finish" notu var; bu, modülün tamamlanmamış olduğunun açık itirafı.
- Satır 55-66 arası pseudo-kod açıklaması oyun döngüsünün genel akışını tarif ediyor ancak implementasyon yok.
- Satır 68'de `//uhhhh...` ifadesi, geliştirmenin takıldığını gösteriyor.
- Satır 114-171 arası ASCII art, gereksiz alan kaplıyor.

**Hatalar ve Eksiklikler:**
1. **`seg` ve `an` askıda:** Wire olarak tanımlı, hiçbir modüle bağlanmamış. Sentezde uyarı verir, display çalışmaz.
2. **`RsTx` askıda:** Tanımlı ancak hiçbir mantığa bağlanmamış.
3. **Oyun döngüsü yok:** `gameLoop`, `ScoreCalc`, `ScoreCalcEndgame`, `playerLEDs`, `playerLEDsEndgame`, `segmentDisplay7` modülleri örneklenmemiş.
4. **Şartname tanıtım metni eksik:** Şartname Bölüm 2 ve 8, switch/LED eşleştirmesinin top dosyasının başında comment olarak belirtilmesini ister. Mevcut commentler bunu karşılamıyor.

---

### 2.2 `ConfigMenu` (2_ConfigMenu.v)

**Açıklama/Comment Analizi:**
- Başlangıçtaki comment bloğu giriş/çıkışları düzgün açıklamaktadır ve şartnameyle uyumludur.
- Switch eşleştirmeleri (sw[0-2]: oyuncu sayısı, sw[4-7]: tur, sw[9]: eleme, sw[11]: zorluk) açıkça belirtilmiş.

**Hatalar:**
1. ~~**Bit-slice yönü hatası (KRİTİK):** Satır 56-57'de `leds[0:2]` ve `leds[4:7]` yazılmış. Verilog'da `leds` `reg[15:0]` olarak tanımlandığından (MSB:LSB = 15:0), part-select `leds[2:0]` ve `leds[7:4]` olmalıdır. Ters yöndeki part-select (`[0:2]`) Verilog standardına göre sentez hatasına veya yanlış davranışa neden olur.~~ ✅ **DÜZELTİLDİ** — `leds[2:0]` ve `leds[7:4]` olarak düzeltildi.
2. **Kullanılmayan LED bitleri:** Satır 56-59'da yalnızca belirli LED'ler atanıyor. Geri kalan bitler (3, 8, 10, 12-15) `always` bloğu içinde atanmadığından önceki değerlerini korur. Reset bloğunda `leds <= 16'b1000...` ile 15. bit set ediliyor ama sonraki bloklarda 15. bit yeniden atanmıyor, bu nedenle reset LED'i (sw[15]) konfigürasyon sırasında sürekli yanık kalabilir veya belirsiz davranabilir. ❌ **DÜZELTİLMEDİ**
3. **`finished` sinyali ve BTNC'nin kenar algılaması:** `finished <= finishedInput` kullanılmış. `finishedInput` burada `center` yani debounce edilmiş BTNC sinyali. Ancak `center` bir seviye (level) sinyali ise, buton basılı tutulduğu sürece `finished` sürekli 1 kalacaktır. Top modülden gelen `center` sinyali `debounce` modülünün çıkışıdır ve bu modül seviye sinyali çıkarmaktadır (tek seferlik pulse değil). Potansiyel bir sorun: butona basıp bırakınca `finished` tekrar 0'a düşebilir mi? — Hayır, çünkü `else if(!finished)` bloğu sadece `finished==0` iken çalışır. `finished=1` olduktan sonra blok yeniden yürütülmez. Bu kısım güvenli görünüyor.
4. **Senkron reset:** Reset, `posedge clk` içinde `if(reset)` ile yapılmış; senkron. Şartnameyle bir çelişki yok, ancak projede tutarlılık açısından tüm modüllerin aynı reset türünü kullanması önemli. Bu modül senkron, diğer modüllerden bazıları da senkron — tutarlılık sağlanmış.

---

### 2.3 `segmentDisplay7` (3_7segmentDisplay.v)

**Açıklama/Comment Analizi:**
- Çok detaylı Türkçe açıklama mevcut. Çalışma mantığı, milisaniye sayacı, hane döngüsü ve karartma sinyali anlaşılır biçimde açıklanmış.
- Comment'te "LSFR" yazılmış olması tipografik hata; doğrusu "LFSR" (Linear Feedback Shift Register).
- Açıklama, şartnamenin 7-segment döngüsü gereksinimiyle (1-2-3-4 / 5-6-7-8 dönüşümü) uyumlu.

**Hatalar:**
1. **Kombinasyonel `always@(*)` bloğunda `hane` register'ı atanıyor:** `hane` bir `reg` olarak tanımlı ve `always@(*)` içinde atanıyor. Bu, latch oluşturmayabilir (başlangıçta varsayılan 0 atanıyor), ancak `hane` değişkeni aynı zamanda `always@(posedge clk)` bloğunda da okunuyor. Kombinasyonel blokta atanan bir değerin senkron blokta okunması, zamanlama uyumsuzluğuna ve tutarsız davranışa yol açabilir. Sentez aracı `hane`'yi bir wire gibi ele alacaktır ancak iki farklı `always` bloğu arasındaki bu bağımlılık tehlikelidir.
2. **`enable` sinyalinin kullanımı:** `enable` kombinasyonel blokta her zaman 1'e set ediliyor, ancak reset/karartma durumunda 0 yapılıyor. Bu sinyal senkron bloklarda kullanılıyor. Kombinasyonel → senkron yol doğru çalışabilir ama tasarım olarak `enable`'ın da senkron blokta atanması daha güvenli olurdu.
3. **Tur numarası yorumlama:** Şartnamede tur numarası 1'den başlar ve çift/tek tura göre 1234/5678 gösterilir. Modülde `turNumarasi[0]` kontrol ediliyor (LSB). `turNumarasi` 4 bit ve ConfigMenu'den gelen `turnNo` değeri tur sayısını belirtir (0000=1 tur, 1111=16 tur). Ancak buradaki `turNumarasi`, o anki turun numarasıdır (kaçıncı turda olunduğu). Bu değeri üreten bir sayaç/FSM henüz mevcut değil. Modülün mantığı tur numarasının LSB'sine bakarak doğru dönüşümü yapıyor gibi görünüyor.
4. **`bitisSinyali` pulse sorunu:** Comment'te bitisSinyali'nin pulse olduğu ve FSM'de `posedge clk` ile yakalanması gerektiği belirtilmiş. Kodda `bitis` yalnızca `sayac == 399_999_999` olduğu tek clock cycle'da 1 yapılıyor (satır 230-233). Sonraki cycle'da `else` bloğuyla 0'a çekiliyor. Bu doğru bir tek-cycle pulse. Ancak bunu yakalayacak FSM modülü henüz mevcut değil.
5. **`haneSayici` bloğundaki `if` zincirleri:** Satır 261-283 arası, `hane==1`, `hane==2`, `hane==3` durumları ayrı `if` blokları ile kontrol ediliyor. `if-else if` yerine ayrı `if` kullanılması, birden fazla bloğun aynı anda tetiklenmesine neden olabilir. `hane` değeri tek bir değer alacağından pratikte sorun oluşmaz ama `else if` yapısı daha güvenli olurdu.

---

### 2.4 `lfsr16` (4.1_lfsr16.v)

**Açıklama/Comment Analizi:**
- Çok iyi açıklanmış. Polinom, maximal-length açıklaması, seed, kesintisiz çalışma kuralı ve snapshot mekanizması detaylı.
- Şartname Bölüm 4 gereksinimleriyle tam uyumlu.

**Hatalar:**
- **Hata tespit edilmedi.** Modül temiz ve doğru görünüyor.
- Senkron reset, sıfırdan farklı seed (`0xACE1`), kesintisiz çalışma (enable yok, her cycle kayar), maximal-length polinom — tüm gereksinimler karşılanmış.
- Tek iyileştirme önerisi: Modülde `enable` girişi yok, bu da top modülden `enable=1` bağlanması gerekmediği anlamına gelir — doğrudan sürekli çalışır. Bu, şartnameyle uyumlu.

---

### 2.5 `random_delay_gen` (4.2_RSO.v)

**Açıklama/Comment Analizi:**
- İyi açıklanmış. Pipeline yapısı, zorluk modu sınırları ve LFSR'den bağımsız çalışma belirtilmiş.
- Kolay mod: 2.0-5.0s, Zor mod: 0.5-5.0s — şartnameyle uyumlu.

**Hatalar:**
1. **Çarpma zamanlaması:** Satır 69'da `lfsr_deger * ara` işlemi, trigger geldiği cycle'da yapılıyor. Ancak `ara` değişkeni kombinasyonel bloktaki `zorluk` girişine bağlı. Trigger anında `zorluk` değerinin stabil olması gerekir — ConfigMenu'den geldiği için sorun olmamalı.
2. **Pipeline 3 aşama mı 2 mi?** Comment'te "3 aşamalı pipeline" yazıyor ancak kodda aslında 3 aşama var: Stage 0→1 (snapshot + çarpma), Stage 1→2 (ölçekleme + toplama), Stage 2→çıkış (valid). Bu doğru ancak tetiklenmeden 3 cycle sonra sonuç geçerli olacak. Bu gecikmenin top-level entegrasyonda dikkate alınması gerekir.
3. **`sure_bekleme` değeri koruma:** `sure_bekleme_gecerli` yalnızca 1 cycle boyunca 1 olur. Tüketici modül bu pulse'u yakalamazsa değer kaybolur. `sure_bekleme` registeri kalıcı olduğundan değerin kendisi silinmez, ancak geçerlilik sinyalinin kaçırılma riski var.

---

### 2.6 `debounce` (5.1_Debounce.v)

**Açıklama/Comment Analizi:**
- Türkçe açıklamalar mevcut. Debounce mantığı yeterli detayda açıklanmış.
- 50ms döngü ve 20ms stabilite süresi belirtilmiş.

**Hatalar:**
1. **Reset polaritesi ters:** Satır 16'da `if(!resetSW15)` ile normal çalışma, satır 32'de `else if(resetSW15)` ile reset. Yani **reset aktif-yüksek** çalışıyor. Ancak butonun `if` koşulunda `!resetSW15` ile başlaması kafa karıştırıcı; resetSW15=0 iken (switch kapalı) normal çalışma, resetSW15=1 iken reset. Bu, şartname ile uyumlu (SW15=1 → reset durumu).
2. **Sayaç taşma kontrolü:** `sayac >= 5_000_000` ve `sayac >= 2_000_000` kontrolleri birbiriyle çakışıyor. Sayaç önce 5M kontrolüne giriyor ve sıfırlanıyor. Daha sonra aynı always bloğu içinde 2M kontrolü yapılıyor. Ancak Verilog semantiğinde, aynı always bloğu içinde son atama geçerli olur. `DurumKontrol != GurultuluSinyal` durumunda sayaç 0'a çekilecek ve 2M kontrolüne ulaşılamayacak. Sinyal stabil olduğunda ise sayaç artacak: önce 2M'e ulaşıp `TemizSinyal` atanacak, sonra 5M'e ulaşıp sıfırlanacak. Bu mantık çalışır ancak gereksiz karmaşıktır.
3. **Çıkış seviye sinyali:** `TemizSinyal` bir `reg` olarak atanıyor ve buton basılı olduğu sürece 1 kalır. Bu bir **seviye sinyali**dir, pulse değil. Top modülde `TusKontrolu` modülü kenar algılaması yaparak bunu pulse'a çevirir — bu doğru bir yaklaşım.

---

### 2.7 `TusKontrolu` (5.2_TusKontrolu.v)

**Açıklama/Comment Analizi:**
- Türkçe açıklamalar mevcut ve yeterli. Debounce + kenar algılama mantığı açıklanmış.
- FSM modülüyle nasıl etkileşeceği tarif edilmiş ancak FSM henüz mevcut değil.

**Hatalar:**
1. **Oyuncu kısıtlama eksikliği (BTNU ve BTNL):** Satır 50-55 (BTNU = Oyuncu 1) ve satır 63-68 (BTNL = Oyuncu 2) için `playerNO` kontrolü yapılmamış. BTNR (satır 71) ve BTND (satır 78) için `playerNO[2]` ve `playerNO[3]` kontrolleri var. Ancak Oyuncu 1 ve 2 her zaman aktif kabul edilmiş — bu mantıklıdır çünkü minimum oyuncu sayısı 2'dir ve Oyuncu 1-2 her zaman oyundadır. Yine de `playerNO[0]` ve `playerNO[1]` kontrolü yapılması daha güvenli olurdu.
2. **Reset polaritesi:** `if(!resetSW15)` normal çalışma, `else if(resetSW15)` reset. Bu, debounce modülüyle tutarlı ve şartnameyle uyumlu.

---

### 2.8 `gameLoop` (6_Main_Game_Loop.v) — **EN KRİTİK MODÜL**

**Açıklama/Comment Analizi:**
- Comment'lerde Türkçe karakter bozulması mevcut (soru işaretleri şeklinde görünüyor).
- Endmodule hatası ve genel kargaşa comment'te itiraf edilmiş.
- Modül açıkça tamamlanmamış ve çalışmıyor.

**KRİTİK HATALAR (Sentezlenemez Yapılar):**
1. **`while` döngüsü (Satır 55, 81):** `while(!kararmaSinyali)` ve `while($time <= end_time)` ifadeleri sentezlenemez. Verilog'da `while` yalnızca testbench'te kullanılabilir; sentez araçları bunu kabul etmez. Donanımda döngüler FSM ile gerçekleştirilmelidir.
2. **`$time` sistem fonksiyonu (Satır 80-81):** `$time` simülasyon zamanı döndürür ve yalnızca testbench'te kullanılır. Sentez araçları `$time`'ı desteklemez.
3. **`wait(BTNC)` ifadesi (Satır 154):** `wait` ifadesi sentezlenemez. Bu, yalnızca simülasyonda çalışan bir yapıdır.
4. **`#5` zamanlama gecikmesi (Satır 108):** `#5` ifadesi sentezlenemez. Donanımda gecikme sayaçlarla oluşturulmalıdır.
5. **`generate` bloğu yanlış kullanımı:** Satır 31'de `generate` açılmış ama `endgenerate` yok. Ayrıca `generate` bloğu içinde `always` bloğu doğrudan kullanılmamalıdır (genvar ile `for` generate içinde kullanılabilir, ancak buradaki yapı yanlış).
6. **`genvar` ve sıralı lojik karışımı:** `genvar i, j` tanımlanmış ama bunlar `always` bloğu içindeki `for` döngülerinde kullanılıyor. `genvar` sadece `generate for` içinde kullanılmalı; sıralı lojikteki döngülerde normal `integer` kullanılmalıdır.
7. **Blocking + Non-blocking karışımı:** Satır 39'da `playerActive[i] = 1'b1` (blocking), satır 41'de `playerActive[i] <= 1'b0` (non-blocking). Aynı `always @(posedge clk)` bloğu içinde aynı değişkene hem `=` hem `<=` atama yapılması tanımsız davranışa neden olur.
8. **`order = 0` (Satır 156):** `always @(posedge clk)` bloğu içinde blocking atama.
9. **Değişken boyut portları:** `output score[0:playerNo][0:turnNo]` — `playerNo` ve `turnNo` giriş portlarıdır (runtime değer), Verilog'da dizi boyutları derleme zamanında sabit olmalıdır. Bu sentezlenemez.
10. **`playerOrderSpeed` ve `falseStart` dizi boyutları:** `[0:playerNo]` ile tanımlı, aynı sorun.

> **SONUÇ:** Bu modül tamamen yeniden yazılmalıdır. Mevcut haliyle ne sentezlenebilir ne de simüle edilebilir (simülasyonda da hatalı davranacaktır). Bir FSM tabanlı yaklaşımla yeniden tasarlanması gerekmektedir.

---

### 2.9 `ScoreCalc` (7.1_ScoreCalc.v)

**Açıklama/Comment Analizi:**
- İngilizce açıklamalar detaylı ve anlaşılır. Giriş/çıkışlar, puanlama mantığı ve oyun döngüsüyle ilişkisi açıklanmış.
- Şartnamenin puanlama kurallarıyla (1.=4p, 2.=3p, 3.=2p, 4.=1p, cezalı=0p) uyumlu.

**Hatalar:**
1. ~~**Bit indeks hatası (KRİTİK):** Satır 153'te `playersPenalized[4] <= 1'b1` ve satır 155'te `playersLeft[4] <= 1'b0`. `playersPenalized` ve `playersLeft` 4 bitlik `[3:0]` register'lar olduğundan indeks 4 **sınır dışıdır**. Doğrusu `[3]` olmalıdır.~~ ✅ **DÜZELTİLDİ** — `[4]` → `[3]` olarak düzeltildi.
2. ~~**Non-blocking sonrası okuma sorunu (KRİTİK):** `player1Place` satır 112'de `2'b00` olarak atanıyor (non-blocking). Ardından satır 169-184'te karşılaştırmalar yapılıp `player1Place <= player1Place + 1` ile artırılıyor.~~ ⚠️ **KISMEN DÜZELTİLDİ** — Sıralama atamalari blocking (`=`) olarak değiştirildi, ardışık artırımlar doğru çalışıyor. Ancak aynı `always @(posedge clk)` bloğunda blocking/non-blocking karışımı devam ediyor.
3. ~~**Blocking/Non-blocking karışımı:** Satır 191-201'de `player1newTotal = (player1Total + 4)` **blocking** atama kullanılmış. Aynı `always @(posedge clk)` bloğu içindeki diğer atamalar non-blocking. Bu tutarsızlık tanımsız davranışa neden olabilir.~~ ✅ **DÜZELTİLDİ** — Tüm `player1newTotal` atamaları `<=` (non-blocking) olarak düzeltildi.
4. ~~**`playersPenalized` reset eksikliği:** `playersPenalized` `always` bloğunda reset durumunda sıfırlanmıyor.~~ ✅ **DÜZELTİLDİ** — Reset bloğuna `playersPenalized <= 4'b0000;` eklendi.
5. **Sürekli çalışma sorunu:** Modül `always@(posedge clk)` ile her clock'ta çalışır. Oyun turları arasında tetiklenmeden de çalışacaktır. Bir `start`/`enable` sinyali veya FSM durumu ile kontrol edilmesi gerekir. ❌ **DÜZELTİLMEDİ**

---

### 2.10 `ScoreCalcEndgame` (7.2_ScoreCalcEndgame.v)

**Açıklama/Comment Analizi:**
- İngilizce açıklamalar yeterli. Beraberlik kontrolü ve kazanan belirleme mantığı açıklanmış.
- Şartnameyle uyumlu.

**Hatalar:**
1. **`tieFinder` boyut hatası:** Satır 38'de `reg[2:0] tieFinder = 2'b0;` tanımlı. Boyut 3 bit (doğru — 4 oyuncu toplamı max 4 olabilir, 3 bit yeterli), ancak başlangıç değeri `2'b0` olarak verilmiş. Bu bir uyarı verebilir ama fonksiyonel hata yaratmaz. ❌ **DÜZELTİLMEDİ**
2. ~~**Blocking/Non-blocking karışımı (KRİTİK):**~~ ⚠️ **KISMEN DÜZELTİLDİ** — `currentHighest` artık blocking (`=`) ile atanıyor, bu sayede aynı cycle'da doğru hesaplanabiliyor. Ancak `currentWinners` hâlâ non-blocking, `tieFinder` non-blocking atanmış olup hemen ardından okunuyor. Blocking/non-blocking karışımı devam ediyor.
3. ~~**Aynı sorun — tek cycle'da tam hesap:**~~ ⚠️ **KISMEN DÜZELTİLDİ** — `currentHighest` blocking olduğu için en yüksek skor aynı cycle'da doğru hesaplanabiliyor. Ancak `currentWinners` non-blocking ile atandığı için kazanan belirleme hâlâ bir cycle gecikir.
4. **`currentWinners` ve `currentHighest` reset eksikliği:** Her yeni çağrıda bu registerlar sıfırlanmıyor. Önceki turdan kalan değerler yanlış sonuç verebilir. ❌ **DÜZELTİLMEDİ**

---

### 2.11 `playerLEDs` (8.1_playerLEDs.v)

**Açıklama/Comment Analizi:**
- İngilizce açıklamalar detaylı ve şartnameyle uyumlu.
- LED eşleştirmesi (Oyuncu 1: LED0-3, Oyuncu 2: LED4-7, Oyuncu 3: LED8-11, Oyuncu 4: LED12-15) şartnameyle uyuşuyor.

**Hatalar:**
1. ~~**Copy-paste hatası (KRİTİK):** Satır 117: Player 3'ün cezalandırılma durumunda `player2Leds` yazılmış. Satır 142: Player 4 için aynı hata.~~ ✅ **DÜZELTİLDİ** — `player2Leds` → `player3Leds` (satır 117) ve `player2Leds` → `player4Leds` (satır 142) olarak düzeltildi.
2. **Tek clock cycle gecikmesi:** `playerXLeds` register'ları bir cycle'da hesaplanıp bir sonraki cycle'da `leds`'e atanıyor. Bu 1 cycle'lık gecikme pratikte görünmez ancak tasarım olarak bilinmeli.

---

### 2.12 `playerLEDsEndgame` (8.2_playerLEDsEndgame.v)

**Açıklama/Comment Analizi:**
- İngilizce açıklamalar yeterli.

**Hatalar:**
1. ~~**Kaybeden oyuncuların LED'leri sıfırlanmıyor:** `winners[x]` 0 olan oyuncuların LED'leri `else` bloğunda sıfırlanmıyor.~~ ✅ **DÜZELTİLDİ** — Tüm 4 oyuncu için `else` blokları eklendi.
2. ~~**`else` bloğu eklenmeli:** Her `if(winners[x])` bloğuna bir `else playerXLeds <= 4'b0000;` eklenmeli.~~ ✅ **DÜZELTİLDİ**

---

### 2.13 `random_delay_gen_tb` (4tb_nrsotb.v)

**Açıklama/Comment Analizi:**
- Testbench açıklamaları yeterli. Kontrol edilen noktalar belirtilmiş.

**Değerlendirme:**
- Testbench yapısı doğru. LFSR ve random_delay_gen modüllerini birlikte test ediyor.
- Kolay ve Zor mod sınırları doğru kontrol ediliyor.
- `$finish` ile simülasyon sonlandırılıyor.
- **İyileştirme:** `$display` ile sonuç raporlama eksik. `fail_sayi` ve `degisim_sayi` değişkenleri sadece waveform'da incelenebilir.

---

### 2.14 Constraint Dosyası (0.5_basys3Assigning.xdc)

**Değerlendirme:**
- Standart Digilent Basys3 Master XDC dosyası baz alınmış.
- Clock (10ns/100MHz), tüm switch'ler, LED'ler, 7-segment, butonlar ve UART pinleri aktif.
- `RsRx` pini aktif ancak top modülde `RsRx` girişi tanımlı değil → sentezde "port not found" hatası verecektir.
- Pin eşleştirmeleri top modül port adlarıyla uyumlu.

---

## 3. Özet Yapılacaklar Listesi

### 🔴 Kritik (Projenin çalışması için zorunlu)

| # | Madde | İlgili Dosya(lar) | Durum |
|---|-------|-------------------|-------|
| 1 | `gameLoop` modülü tamamen yeniden tasarlanmalı. `while`, `wait`, `$time`, `#delay`, `generate` yanlış kullanımları kaldırılmalı ve FSM tabanlı bir yapıya geçilmeli. | 6_Main_Game_Loop.v | ❌ |
| 2 | Top modülde `segmentDisplay7`, `ScoreCalc`, `ScoreCalcEndgame`, `playerLEDs`, `playerLEDsEndgame` modülleri örneklenmeli ve bağlanmalı. | 1_Main.v | ❌ |
| 3 | UART 9600 8N1 modülü yazılmalı ve top modüle entegre edilmeli. | Yeni dosya + 1_Main.v | ❌ |
| 4 | Oyun durumlarını yöneten ana FSM (konfigürasyon → oyun → tur sonu → endgame) tasarlanmalı. | Yeni dosya veya 1_Main.v | ❌ |
| ~~5~~ | ~~`ConfigMenu`'deki bit-slice yönü düzeltilmeli: `leds[0:2]` → `leds[2:0]`, `leds[4:7]` → `leds[7:4]`.~~ | ~~2_ConfigMenu.v~~ | ✅ |
| ~~6~~ | ~~`ScoreCalc`'taki Player 4 indeks hataları düzeltilmeli: `playersPenalized[4]` → `[3]`, `playersLeft[4]` → `[3]`.~~ | ~~7.1_ScoreCalc.v~~ | ✅ |
| ~~7~~ | ~~`playerLEDs`'deki copy-paste hataları düzeltilmeli.~~ | ~~8.1_playerLEDs.v~~ | ✅ |
| 8 | `ScoreCalc`'taki non-blocking atama sonrası okuma sorunu çözülmeli. Sıralama mantığı combinational veya çok aşamalı olarak yeniden tasarlanmalı. | 7.1_ScoreCalc.v | ⚠️ |
| ~~9~~ | ~~LED çıkışı için multiplexer/kontrol mantığı eklenmeli.~~ | ~~1_Main.v~~ | ✅ |
| 10 | XDC'deki `RsRx` pini ya top modüle eklenmeli ya da XDC'de yorum satırına alınmalı. | 0.5_basys3Assigning.xdc + 1_Main.v | ❌ |

### 🟡 Orta Öncelik (Doğruluk ve güvenilirlik)

| # | Madde | İlgili Dosya(lar) | Durum |
|---|-------|-------------------|-------|
| 11 | `ScoreCalcEndgame`'de blocking/non-blocking karışımı giderilmeli. | 7.2_ScoreCalcEndgame.v | ⚠️ |
| 12 | `ScoreCalcEndgame`'de `currentHighest` ve `currentWinners` hesaplaması tek cycle'da yapılamıyor. | 7.2_ScoreCalcEndgame.v | ⚠️ |
| ~~13~~ | ~~`ScoreCalc`'ta `playersPenalized` reset bloğunda sıfırlanmalı.~~ | ~~7.1_ScoreCalc.v~~ | ✅ |
| ~~14~~ | ~~`playerLEDsEndgame`'de kazanmayanların LED'leri açıkça sıfırlanmalı.~~ | ~~8.2_playerLEDsEndgame.v~~ | ✅ |
| ~~15~~ | ~~`ScoreCalc`'ta `player1newTotal` atamasındaki blocking `=` → non-blocking `<=` çevrilmeli.~~ | ~~7.1_ScoreCalc.v~~ | ✅ |
| ~~16~~ | ~~`center` wire'ında çoklu sürücü (multi-driver) hatası giderilmeli.~~ | ~~1_Main.v + 5.2_TusKontrolu.v~~ | ✅ |
| 17 | Reaksiyon süresi ölçüm mekanizması (1ms çözünürlükle sayaç) tasarlanmalı ve entegre edilmeli. | Yeni dosya | ❌ |

### 🟢 Düşük Öncelik (İyileştirme ve temizlik)

| # | Madde | İlgili Dosya(lar) |
|---|-------|-------------------|
| 18 | Comment'lerde "LSFR" yazımı "LFSR" olarak düzeltilmeli. | 3_7segmentDisplay.v |
| 19 | Top dosyanın başına şartname gereği switch/LED eşleştirme tablosu ve proje tanıtım metni eklenmeli. | 1_Main.v |
| 20 | Testbench dosyasına `$display` ile sonuç raporlama eklenmeli. | 4tb_nrsotb.v |
| 21 | ASCII art'lar dosya boyutunu şişiriyor; projenin profesyonelliği açısından azaltılabilir. | Tüm dosyalar |
| 22 | Tüm dosyalardaki gereksiz boş satırlar temizlenmeli. | Tüm dosyalar |
| 23 | `segmentDisplay7`'deki `hane` register'ı kombinasyonel + senkron blok karışımından kurtarılmalı. | 3_7segmentDisplay.v |
| 24 | Eleme modunda tek oyuncu kalınca erken bitiş mantığı eklenmeli (Şartname Bölüm 9). | Yeni FSM |

---

## Sonuç

Proje şu anda **erken geliştirme aşamasındadır**. Modüllerin büyük kısmı bağımsız olarak yazılmış ancak birbirine entegre edilmemiştir. En kritik eksiklik, oyun döngüsü FSM'inin olmaması ve `gameLoop` modülünün sentezlenemez yapıda olmasıdır. UART modülü hiç yazılmamıştır. Mevcut modüllerden `lfsr16` ve `random_delay_gen` en temiz ve doğru olanlardır; `ConfigMenu`, `debounce` ve `TusKontrolu` küçük düzeltmelerle kullanılabilir durumdadır. `ScoreCalc`, `ScoreCalcEndgame`, `playerLEDs` ve `playerLEDsEndgame` modülleri indeks hataları ve blocking/non-blocking karışımları nedeniyle düzeltme gerektirir.
