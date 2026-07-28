`timescale 1ns / 1ps

/*
Çalışma:

Bu modül her biri 7 segmentten oluşan 4 hane üzerindeki sayıları kontrol eden bir yapıdadır. Başlangıçta karanlık durumdadır. Bu karanlık durum 2 reset sinyal ile sağlanmaktadır: resetSW15 ve karartmaSinyali. Kritik olan karartmaSinyalidir. 
eğer aksi durum yok ise karartmaSinyali 1 değerini alır. Karartma sinyali değerinin 0'a geçmesi durumunda (eğer resetSW15'in değeride 0 ise) sistem anında 1. haneyi yakar. 1. Hanede tur sayısının durumuna göre 1 yada 5 değeri görünecektir.
modülün aldığı girdiler bu şekilde değerlendirilmektedir. karartmaSinyali değeri varsayılan olarak 1'dir. LSFR modülü karartmaSinyali değerini 1 yapabilmektedir. Ana oyun FSM modülünde ise bu modülün tekrar çalışabilmesi için karartmaSinyali değeri 0 yapılacaktır.
7 Segment displayde aynı anda sadece 1 hane çalıştırılabilmektedir fakat projede aynı anda yakılması istenmiştir. Bu durumu çözmek adına şu yöntem izlenmiştir, Her bir hane aynı anda yakılamadığı için sıra sıra yakılmışlardır. Örnek olarak soldan sağa doğru haneleri
sırasıyla a,b,c ve d şeklinde isimlendirirsek yanma sırası : a-b-c-d-a-b-c-d-a-b... şeklinde gitmektedir. Bu haneler 1 milisaniye aralıklarda yakılmaktadırlar. Aynı anda yanmasalar bile insan gözü aynı anda yanıyorlar gibi algılar çünkü her 2 hane arasındaki 
süre farkı 1 milisaniyedir. Bu milisaniye hesabını yapabilmek için milisaniyesayaci tanımlanmıştır. Bu sayaç 100_000 adım sonra 2 bitlik haneSayisi değeri kaçıncı hanede ise o hanedeki sayı yakılır. 100_000 adım, clock sinyali 10 nanosaniye ile çarpıldığı zaman 1 milisaniye değerini vermektedir
Bu milisaniyesayacı temelde clock sinyalini yavaşlatır. Bunu yapmamızın sebebi basys3 kartının clock sinyali olan 10 nanosaniye değerinin ledleri yakmak için çok küçük bir değer olması. Bu clock sinyalini yavaşlatıp 1 milisaniyeye çekersek ledler yanacak süreyi bulacaklardır.
Kaçıncı hanenin yanacağı bilgisi ise 2 bitlik hane ve haneSayaci değerleri ile belirlenir. 2 bitlik hane değeri, 7-segment display üzerinde aynı anda kaç tane haneyi yakacağımızı söyler. Hane değeri 0,1,2 ve 3 değerlerini alır. 0 değeri default değerdir
ve bir şey ifade etmez. Eğer 0 değerine bir anlam yüklemek istersek hane = 2'd0 olduğu zaman Display üzerinde sadece 1 haneyi yakılır diyebiliriz. Bunun dışında 2 bitlik hane registerinin tuttuğu 1,2 ve 3 değerleride sırasıyla display üzerinde 2,3 ve 4 hanenin aynı anda
yakılacağını söyler. haneSayici değeri ise bu 2 bitlik hane değerine göre indeks belirler. Örnek olarak hane değeri 2 olarak belirlenirse display üzerinde aynı anda 3 tane sayı göstermek istiyoruz demektir. Bu durumda 2. always@(posedge clk) bloğunda haneSayisi değeri şöyle hesaplanır:
önce haneSayisi değeri 0 dan başlar. Her clock vuruşunda kendini 1 artırır. Eğer decimal olarak değeri hane registerindeki değere eşit olursa kendini sıfırlar. Örnekte hane değeri = 2 demiştik. Bu durumda haneSayici, başlangıçta 0 olur sonra 1 sonra 2. 3. clock darbesi geldiği zaman haneSayici değeri hane değerine
eşitlendiği için 0 a geri çekilir. YAni haneSayici değeri clock sinyali ile beraber şu şekilde gider(hane = 2'd2 durumu için): 0-1-2-0-1-2-0-1... Bu döngüyü kullanıp always(*) bloğunda display üzerinde hanelerdeki ledleri sıra sıra yakabiliriz. Örnek olarak haneSayici değeri 0 olduğu zaman 1. hane yanar
haneSayici değeri 1 oluğu zaman 2. hane yanar gibi. Çıktılardaki an ve seg değerleri kullanılıp display çalıştırılır. an değeri kaçıncı hanenin seçileceğine karar verir. Seg ise hangi sayıyı gösterecek isek ona göre verdiğimiz değerdir. Bu iki output ters mantıkla çalışır.
Eğer 1. haneyi yakmak istiyorsam an değeri 4'b1000 değilde 4'b0111 şeklinde olmalıdır. 0 açık durumu, 1 ise kapalı durumu temsil eder. Aynı şey seg outputu içinde geçerlidir. Son register ise sayac registeridir. Sayac oyunun kurallarına göre hanelerin yanmaları arasındaki süredir.
milisaniyesayaci registeri ile karıştırılmamalı. milisaniyesayaci registeri display üzerinde sayıların aynı anda yanması ilüzyonunu oluşturmaya yarayacak olan yapıdır. Sayac registeri ise ilk hane yandıktan sonra diğer hanenin yanması için beklenecek 1 saniyelik süredir.
sayac değeri maksimum 9 saniyeye kadar sayabilmektedir. 9 Sn / 10 nanoSn sonucu 900_000_000 adım olur. yani Sayac değeri max decimal olarak 900_000_000 olabilir. 9 saniye olma sebebi şudur, ilk 4 saniye display üzerinde 4 sayınında yanmasına kadar geçen süredir. 4. saniye sonunda
display üzerindeki 4 hanenin 4 üde yanıyordur birer sayı gösteriyorlardır. Tam bu anda bitisSinyali değeri 1 olur. Bu sinyal LSFR'a gider. LSFR modülü en fazla 5 saniyelik bir süre oluşturabilir. sayacın 9 saniye yani maksimum 900k adım almasının sebebi budur. 
Bitis sinyali gittikten sonra sayac saymaya devam eder çünkü Displayın kararmadan önce LSFR modülünün oluşturduğu x saniyelik süre kadar açık olması gerekmektedir. Sayac bu süreçte artar ve displayi açık tutar. Eğer LSFR modülünden karartma sinyali gelmez ise 
900_000_000. adıma gelindiğinde modül kendi kendini zaten karartacaktır. Fakat LSFR modülü her türlü bir değer üreteceği için bu durum gerçekleşmez. Sayac 900k ıncı adıma kadar displayı açık tutar. Bu süreç içerisinde eğer LSFR karartmaSinyali yollar ise display
üzerinde ışıklar söner. Örnek olarak şunu düşünelim: 7seg modülü 4 saniye boyunca çalıştı ve en sonda 4 hanenin 4'üde yandı. 4. saniyede 7seg modülü bitiş sinyalini 1 yaptı. Bu sinyal LSFR modülü çalıştırdı ve LSFR modülü örnek olarak 3.2 saniyelik bir süre oluşturdu.
Bu 3.2 saniye geçene kadar sayac halen her clock vuruşunda artmaya devam edecektir. Bitis sinyalinin 1 yapıldıüı andan sonra 3.2 saniye sonra LSFR modülü, 7seg modülüne karartmaSinyali yollayacaktır. Yani karartmaSinyali değeri 1 yapılacaktır. Bu sinyal geldiği zaman
sayac değeri henüz 900_000_000 olamadan sıfırlanır ayrıca display üzerinde yanan bütün ışıklar söndürülür. Bunun dışında LSFR modülü içerisinde bu modülden gelen sinyal posedge clock sinyalleriyle beraber kontrol edilmesi gerekli zira LSFR modülüne yollanacak bitis sinyali
pulse şeklindedir. Yani bitis değeri 1 olduktan sonra bir clock döngüsü sonra 0 değerine geri gelir. Bu yüzden LSFR modülünde bitis sinyali kontrolü yapılırken clock sinyalinin yükselen kolunda kontrol yapılmalı. Eğer bu şekilde kontrol edilirse 10 nanosaniyelik
bitis sinyalini yakalamak mümkün olacaktır.



*/

module segmentDisplay7(

input clk, 

input resetSW15, //Switch15'den gelen reset sinyali.

input [3:0] turNumarasi, //turnNO inputu değil. Kaçıncı turda olunduğuna dair girdi.

input kararmaSinyali, //LSFR modülünden gelen Displaydeki ışıkları söndürmeye yarayan sinyal.

output reg[6:0]  seg, 

output reg[3:0] an, 

output bitisSinyali // sayma işlemi bittiği zaman 1 değerini alır.

);

reg enable = 1'b0;

reg [16:0] milisaniyesayaci = 17'd0;

reg [29:0] sayac = 30'd0; 

reg [1:0] hane = 2'd0;

reg [1:0] haneSayici = 2'd0; 

reg bitis = 1'b0; 

always@(*) begin
    
    enable = 1'b1;
    an = 4'b1111;      
    seg = 7'b1111111;  
    hane = 2'd0; //Bu kısım latch durumunu engellemek için girilen değerler.

    if(resetSW15 || kararmaSinyali) begin
        
        an = 4'b1111;
        seg = 7'b1111111;
        enable = 1'b0;
        hane = 2'd0;
        
    end

    if(!resetSW15 && !kararmaSinyali) begin

        if(turNumarasi[0] == 1'b0) begin //Tur numarası çift sayı iken Displayde gösterilecek sayı sıralaması. Eğer sayının least significant biti 0 ise sayı tamamen çift sayıların toplamından oluşuyordur. Bu durumda sayı çift olacaktır çiftlik kontrolü yapılırken LSB ye bakılır.
            
            if(sayac < 30'd99_999_999) begin //Display üzerinde yalnızca 1 segmentin gösterileceği blok.
                
                an = 4'b0111;
                seg = 7'b1001111; //Display üzerinde 1 sayısını gösterir.

            end
            
            else if(sayac < 30'd199_999_999) begin // Display üzerinde 2 segmentin gösterileceği blok. İçerisinde 2 segmente erişen if blokları mevcut.
                
                hane = 2'd1;

                if(haneSayici == 2'd0) begin
                    
                    an = 4'b0111;
                    seg = 7'b1001111; //Display üzerinde 1 sayısını gösterir.

                end
                
                if(haneSayici == 2'd1) begin
                    
                    an = 4'b1011;
                    seg = 7'b0010010; //Display üzerinde 2 sayısını gösterir.

                end

            end

            else if(sayac < 30'd299_999_999) begin // Display üzerinde 3 segmentin gösterileceği blok. İçerisinde 3 segmente erişen if blokları mevcut.

                hane = 2'd2;

                if(haneSayici == 2'd0) begin
                    
                    an = 4'b0111;
                    seg = 7'b1001111; //Display üzerinde 1 sayısını gösterir.

                end

                if(haneSayici == 2'd1) begin
                    
                    an = 4'b1011;
                    seg = 7'b0010010; //Display üzerinde 2 sayısını gösterir.

                end

                if(haneSayici == 2'd2) begin
                    
                    an = 4'b1101;
                    seg = 7'b0000110; //Display üzerinde 3 sayısını gösterir.

                end
            
            end

            else if(sayac < 30'd899_999_999) begin // Display üzerinde 4 segmentin gösterileceği blok. İçerisinde 4 segmente erişen if blokları mevcut. Alttaki tur numarası tek olan içinki blokta neden 299_999_999 dan sonra bir anda 899_999_999 a atladığı yazılı.

                hane = 2'd3;     

                if(haneSayici == 2'd0) begin
                    
                    an = 4'b0111;
                    seg = 7'b1001111; //Display üzerinde 1 sayısını gösterir

                end

                if(haneSayici == 2'd1) begin
                    
                    an = 4'b1011;
                    seg = 7'b0010010; //Display üzerinde 2 sayısını gösterir

                end

                if(haneSayici == 2'd2) begin
                    
                    an = 4'b1101;
                    seg = 7'b0000110; //Display üzerinde 3 sayısını gösterir.

                end

                if(haneSayici == 2'd3) begin
                    
                    an = 4'b1110;
                    seg = 7'b1001100; //Display üzerinde 4 sayısını gösterir

                end

            end

        end

        if(turNumarasi[0] == 1'b1) begin //Tur numarası tek sayı iken Displayde gösterilecek sayı sıralaması. Eğer sayının least significant bit değeri 1 ise sayıya 1 ekleniyor demektir. çift + tek = tek olduğundan sayının tek olup olmaması LSB ile kontrol edilebilir.
            
            if(sayac < 30'd99_999_999) begin //Display üzerinde yalnızca 1 segmentin gösterileceği blok.
                
                an = 4'b0111;
                seg = 7'b0100100; //Display üzerinde 5 sayısını gösterir.

            end
            
            else if(sayac < 30'd199_999_999) begin // Display üzerinde 2 segmentin gösterileceği blok. İçerisinde 2 segmente erişen if blokları mevcut.
                
                hane = 2'd1;

                if(haneSayici == 2'd0) begin
                    
                    an = 4'b0111;
                    seg = 7'b0100100; //Display üzerinde 5 sayısını gösterir.

                end
                
                if(haneSayici == 2'd1) begin
                    
                    an = 4'b1011;
                    seg = 7'b0100000; //Display üzerinde 6 sayısını gösterir.

                end

            end

            else if(sayac < 30'd299_999_999) begin // Display üzerinde 3 segmentin gösterileceği blok. İçerisinde 3 segmente erişen if blokları mevcut.

                hane = 2'd2;

                if(haneSayici == 2'd0) begin
                    
                    an = 4'b0111;
                    seg = 7'b0100100; //Display üzerinde 5 sayısını gösterir.

                end

                if(haneSayici == 2'd1) begin
                    
                    an = 4'b1011;
                    seg = 7'b0100000; //Display üzerinde 6 sayısını gösterir.

                end

                if(haneSayici == 2'd2) begin
                    
                    an = 4'b1101;
                    seg = 7'b0001111; //Display üzerinde 7 sayısını gösterir.
                    
                end

            end

            else if(sayac < 30'd899_999_999) begin // Display üzerinde 4 segmentin gösterileceği blok. İçerisinde 4 segmente erişen if blokları mevcut. Dikkat edilirse 4. saniyeden 9. saniyeye kadar kapsar. Bunun sebebi LSFR sinyali gelene kadar 4 hanede sayı gösterilmesidir. LSFR nin hangi değeri üretip ne zaman karartma sinyali yollayacağı bilinmediğinden maksimum üretebileceği değer olan 5 saniyeye kadar bekler yani toplam 9 saniye!

                hane = 2'd3;

                if(haneSayici == 2'd0) begin
                    
                    an = 4'b0111;
                    seg = 7'b0100100; //Display üzerinde 5 sayısını gösterir

                end

                if(haneSayici == 2'd1) begin
                    
                    an = 4'b1011;
                    seg = 7'b0100000; //Display üzerinde 6 sayısını gösterir

                end

                if(haneSayici == 2'd2) begin
                    
                    an = 4'b1101;
                    seg = 7'b0001111; //Display üzerinde 7 sayısını gösterir

                end

                if(haneSayici == 2'd3) begin
                    
                    an = 4'b1110;
                    seg = 7'b0000000; //Display üzerinde 8 sayısını gösterir

                end

            end

    end

end

end

assign bitisSinyali = bitis;

always@(posedge clk) begin
    
    if(resetSW15 || kararmaSinyali) begin
        sayac <= 30'd0;
        bitis <= 1'd0;
    end

    else if(enable) begin
        
        if(sayac == 30'd399_999_999) begin

            sayac <= sayac + 1;
            bitis <= 1'd1;

        end
       
        else if(sayac == 30'd899_999_999) begin

            sayac <= 30'd0;
            bitis <= 1'd0;

        end

        else begin

            sayac <= sayac + 1'b1;
            bitis <= 1'd0;

        end

    end

end

always@(posedge clk) begin
     
    if(resetSW15 || kararmaSinyali) begin
    
        haneSayici <= 2'd0;
        milisaniyesayaci <= 17'd0;

    end

    else if(enable) begin // Bu blok sayesinde aynı anda yakılamayan display ledlerini aynı anda yakabiliriz. 2-3-4 sayıyıya aynı anda yakabilmemizi sağlar. 
        
        if(milisaniyesayaci == 17'd99_999) begin 
       
            milisaniyesayaci <= 17'd0;
            
            if(hane == 2'd1) begin // hane = 1'd0 durumu default durumdur bir şey ifade etmez. Bu durumda Displayde sadece 1 segmentte sayı gösterilir diyebiliriz.
            
                haneSayici <= haneSayici + 1'b1;
            
                if(haneSayici == 2'd1)   
                
                    haneSayici <= 2'd0;

            end

            if(hane == 2'd2) begin
            
                haneSayici <= haneSayici + 1'b1;
            
                if(haneSayici == 2'd2)   
                
                    haneSayici <= 2'd0;

            end

            if(hane == 2'd3) begin
            
                haneSayici <= haneSayici + 1'b1;

                if(haneSayici == 2'd3)   

                    haneSayici <= 2'd0;

            end

        end

        else begin
           
            milisaniyesayaci <= milisaniyesayaci + 1'b1; 

        end

    end

end
endmodule



















































































































/*
  ¿Qué es este invento capitalista?

⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣶⣿⣿⣷⣶⣶⣦⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢀⣿⣿⣿⣿⣿⣿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠀
⠀⠀⠀⠀⠀⢸⣿⣿⠟⠉⠀⠀⠀⠀⠀⠀⠀⠉⠙⠻⣿⣿⣿⣿⣷⠀⠀⠀
⠀⠀⠀⠀⠀⠘⣿⣇⠀⣀⣀⣀⡀⠀⠀⣀⣀⣤⣤⣄⣸⣿⣿⣿⣿⡇⠀⠀
⠀⠀⠀⠀⢀⣴⣿⡏⠈⡭⠿⠛⠟⠀⢀⡿⠛⠿⣿⣿⣿⣿⣿⣿⣿⡃⠀⠀
⠀⠀⠀⢶⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠈⠉⣹⣿⣿⣿⣿⣤⡀⠀
⠀⠀⠀⢺⣿⣿⣿⣇⠀⠀⠀⠀⠀⠠⠔⡦⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⡏⠀
⠀⠀⠀⢸⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⢀⣧⣄⣀⢈⣿⣿⣿⣿⣿⣿⣿⡇⠀
⠀⠀⠀⠚⠻⣿⣿⣿⣇⠀⢰⠀⠂⠉⣉⣹⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⠃⠀
⠀⠀⠀⠳⣼⣿⣿⣿⣿⣇⢀⠀⠀⠀⠈⠉⠙⣿⣿⣿⣿⣿⣿⣿⣿⡏⠀⠀
⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣿⣷⣦⣤⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀
⠀⠀⠀⠀⠀⠁⢹⣿⣿⣿⣯⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⠀⠋⠀⠀⠀
⠠⠔⠲⠒⠃⠃⠈⠻⣿⣿⡿⢟⠛⢿⡟⡟⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀
⠀⠀⠀⠰⣶⣷⠀⠀⢈⡉⠻⢿⣿⣦⣄⣰⣼⣿⣿⣿⣿⣿⡉⠑⠢⣄⡀⠀
⠀⠀⠀⠀⠨⣿⣦⡀⠀⢻⡄⠙⣿⣿⣿⣿⣷⣾⣿⣿⣿⣿⣧⠀⠀⠙⠉⠂
⠀⠀⠀⠀⠀⠀⠀⠉⠀⠀⠉⠀⠉⠉⠛⠻⠿⠿⠻⡇⠈⠙⠿⠀⠀⠀⠀⠀

*/
