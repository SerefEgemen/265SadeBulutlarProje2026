//tus kontrolu modülü girdi olarak kaç oyuncu oynayacak onun bilgisini ve buton sinyallerini direk alır. Sinyalleri içeride debounce eder
//TEmiz sinyaller ile kontrol yapar eğer tuşa basılmış olduğunu fark ederse çıkış sinyalini verir 1 verir her bir buton için.
//Daha sonra FSM modülünde BTNC den gelen sinyal ile tur sayısı artırımı yapılabilir. Tur sayısı artırımı yapmak için önce oyunun bittiğine dair
//bilgi gerekir. Eğer tur bitti ise o zaman BTNC den gelen değer tur sayısını artırabilir. Tur sayısı arttığı anda FSM'deki karatmaSinyali 1 den 0 a çekilir
//bu anda 7segDisplayin ışıkları yanar. o modül başlar. 



module TusKontrolu(

input clk, //basys3 kartındaki 10 nanosaniyelik clock sinyali 100Mhz yani.
input resetSW15, //basys3 üzerindeki switch15 den gelen reset sinyali.
input [3:0]playerNO, //ConfigMenu modülünden gelen oyuncu sayısı bilgisi.
input BTNC, //Orta tuş, Oyunu başlatmaya yarar. BTNC ve altındaki 4 girdi gürültülü girdilerdir. Kodun ilerleyen kısımlarında debounce modülü ile temizleneceklerdir.
input BTNU, //1. oyuncu için atanan tuş
input BTNL, //2. oyuncu için atanan tuş
input BTNR, //3. oyuncu için atanan tuş
input BTND, //4. oyuncu için atanan tuş

output reg SinyalBTNC, //Bu çıktılar false start, puan kontrolü, tur artırma için gerekli olacak çıkış sinyalleri
output reg SinyalBTNU,
output reg SinyalBTNL,
output reg SinyalBTNR,
output reg SinyalBTND
    
);

wire TemizlenmisBTNC; //TusKontrolu modülüne giren orijinal girdilerin her birini debounce modülüne sokup temiz sinyali bu wire değerlere veririz.
wire TemizlenmisBTNU;
wire TemizlenmisBTNL;
wire TemizlenmisBTNR;
wire TemizlenmisBTND;

reg eskiBTNC = 1'b0;
reg eskiBTNU = 1'b0;
reg eskiBTNL = 1'b0;
reg eskiBTNR = 1'b0;
reg eskiBTND = 1'b0;

debounce Temizle_BTNC(BTNC,clk,resetSW15,TemizlenmisBTNC);
debounce Temizle_BTNU(BTNU,clk,resetSW15,TemizlenmisBTNU);
debounce Temizle_BTNL(BTNL,clk,resetSW15,TemizlenmisBTNL);
debounce Temizle_BTNR(BTNR,clk,resetSW15,TemizlenmisBTNR);
debounce Temizle_BTND(BTND,clk,resetSW15,TemizlenmisBTND);

always@(posedge clk) begin //Bu modülde daha detaylı açıklamalar sonra yapılacaktır.
    
    if(!resetSW15) begin
        //BTNC
        if(eskiBTNC == 1'b0 && TemizlenmisBTNC == 1'b1) begin
            SinyalBTNC <= 1'b1;
        end
        else begin
            SinyalBTNC <= 1'b0;
        end
        //BTNU
        if(eskiBTNU == 1'b0 && TemizlenmisBTNU == 1'b1) begin
            SinyalBTNU <= 1'b1;
        end
        else begin
            SinyalBTNU <= 1'b0;
        end
        //BTNL
        if(eskiBTNL == 1'b0 && TemizlenmisBTNL == 1'b1) begin
            SinyalBTNL <= 1'b1;
        end
        else begin
            SinyalBTNL <= 1'b0;
        end
        //BTNR
        if(eskiBTNR == 1'b0 && TemizlenmisBTNR == 1'b1 && playerNO[2]) begin
            SinyalBTNR <= 1'b1;
        end
        else begin
            SinyalBTNR <= 1'b0;
        end
        //BTND
        if(eskiBTND == 1'b0 && TemizlenmisBTND == 1'b1 && playerNO[3]) begin
            SinyalBTND <= 1'b1;
        end
        else begin
            SinyalBTND <= 1'b0;
        end

        eskiBTNC <= TemizlenmisBTNC;
        eskiBTNU <= TemizlenmisBTNU;
        eskiBTNL <= TemizlenmisBTNL;
        eskiBTNR <= TemizlenmisBTNR;
        eskiBTND <= TemizlenmisBTND;
        
    end

    else if(resetSW15) begin
        
        SinyalBTNC <= 1'b0;
        SinyalBTNU <= 1'b0;
        SinyalBTNL <= 1'b0;
        SinyalBTNR <= 1'b0;
        SinyalBTND <= 1'b0;
        eskiBTNC <= 1'b0;
        eskiBTNU <= 1'b0;
        eskiBTNL <= 1'b0;
        eskiBTNR <= 1'b0;
        eskiBTND <= 1'b0;

    end

end
  
endmodule





















































//forgor the ascii. 
/*
⣿⣿⣿⣿⣿⣿⣿⣿⡿⣿⣿⣿⣿⣿⡿⢿⡿⠃⠀⡐⠀⠘⡻⠿⠋⠛⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡏⠈⣤⡝⠛⢻⣷⡆⠀⠀⠀⠀⠀⣤⣧⠀⠀⠀⠀⠚⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡇⡀⠀⢴⣮⡀⠉⠁⠀⠀⠀⠀⠁⣹⠛⠋⠉⣰⢄⣠⣿⣿⣿⣿⣿⡿⡿⠿⢿⡿⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡿⠿⢇⣗⠀⢈⠙⣷⠀⡐⢀⠀⡀⠀⢀⣴⣦⡄⢂⢀⣺⣿⣿⣿⣿⠏⠁⣠⣤⣤⣤⣭⣕⡲⣌⡋⠻⠿⠿⠿⠛⠛⣛
⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠾⢯⡙⢇⠀⢃⢀⣀⠢⡿⠋⢐⠶⠇⣿⣿⣿⣿⠟⠁⣺⣿⣿⣿⣿⣿⣿⣿⣷⣵⡛⣃⣀⣠⣀⣠⣾⣿
⣿⣿⣿⣿⣿⣷⠀⠀⢸⣦⠀⠀⠉⠂⠁⢆⣌⠆⡆⢷⡍⠹⠷⠸⠿⠿⠏⠁⣤⡌⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣆⠀⠀⠻⣷⣦⡀⠀⢠⠂⢾⠀⠀⠀⠀⢀⠂⠀⣤⣶⣾⣿⣿⣿⣶⣤⣤⣤⣨⡙⢿⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⠟⠁⠀⠀⠀⠚⠋⢠⣾⣿⡼⣹⣮⣤⣰⡶⠏⠀⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⣼⣿⣻⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡿⢡⣏⡇⠀⠀⠀⢀⢰⣰⢿⡛⠣⠆⢿⣿⣿⠇⠀⠀⠈⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡇⣸⡇⠿⠀⠀⠀⡀⠸⡀⠘⠃⠀⠀⢾⢿⠇⠀⠀⠀⢀⢰⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⢃⣿⡻⡀⣣⠀⠀⠀⠂⠁⠈⠈⠀⠘⠀⠄⣽⠐⠃⠀⠈⡈⢀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⠸⣿⣷⢄⠀⠱⡄⠀⠀⠀⢿⣷⣷⠀⠔⠈⠁⠀⠀⠀⣘⠁⠘⠻⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⠋⠴⣬⣨⠣⣾⣷⣥⡽⠆⠀⠀⠁⠉⠀⠀⠀⠀⢀⠀⠀⣼⠁⠀⢀⣄⡦⠭⠤⠶⠤⣬⣍⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣧⣤⣿⡟⢄⡙⠛⠉⠁⢃⠐⠀⠀⠀⠀⠀⠜⠀⠈⣀⡿⠋⠀⣸⡿⠛⠁⠀⠀⠘⠀⢉⠉⠹⢿⢟⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⡿⣿⣿⣿⣎⠀⠀⠀⠀⠘⠀⠁⠀⠀⠀⠀⠀⠀⠀⠟⠑⠀⠀⠈⠀⠀⠀⠀⠠⢤⠤⣨⣷⡀⠀⣚⡋⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
*/
