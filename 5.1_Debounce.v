module debounce(

input GurultuluSinyal, //Modüle giren debouncea uğrayan sinyal
input clk, //10 nanosaniyelik clock sinyali 100Mhz yani
input resetSW15, //switch 15 ten gelen reset sinyali.

output reg TemizSinyal //FSM ye aktarılacak temiz debouncedan arındırılmış sinyal

);

reg [22:0]sayac = 23'd0; //sayaç registeri
reg DurumKontrol = 1'b0; //debounce kontrolü yapılırken clock sinyali vurduğu an önceki clock sinyalindeki durumu tutan register

always@(posedge clk) begin
   
    if(!resetSW15) begin

        if(sayac >= 23'd5_000_000) //sayaç kendi içerisinde 50 milisaniyelik döngüler içerisindedir. 50 milisaniyeye kadar sayılınca sıfırlar kendini.
            sayac <= 23'd0;
        else
            sayac <= sayac + 1'd1;

        DurumKontrol <= GurultuluSinyal;

        if(DurumKontrol != GurultuluSinyal) //eğer önceki durum ve şimdiki durum farklı ise debounce yaşanmıştı. Sayaç sıfırlanır. Farklılık kontrol edilirken XOR kullanılabilirdi. Veya toplamları üzerinden kontrol yapılabilirdi. Eğer DurumKontrol + GurultuluSinyal == 1 olursa sayılar birbirinden fakrlıdır. Eğer != 1 deseydik aynı sayı olduklarını ifade ederdi. örnek 0 + 0 = 0 veya 1 + 1 = 10 sağdaki 1 biti overflow olduğu için değeri 0 olur.
            sayac <= 23'd0;
        else if(sayac >= 23'd2_000_000) // eğer 20 milisaniye boyunca debounce yaşanmamış ise debounce artık olmayacağı varsayılır ve çıktı sinyali verilir. 
            TemizSinyal <= GurultuluSinyal;

    end

    else if(resetSW15) begin // reset anındaki sıfırlama işlemleri
        sayac <= 23'd0;
        DurumKontrol <= 1'd0;
        TemizSinyal <= 1'd0;
    end
end

endmodule



























































/*
Unnecesarry stuff
⣿⣿⣿⣿⣿⣿⣿⡿⡛⠟⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⠿⠨⡀⠄⠄⡘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⠿⢁⠼⠊⣱⡃⠄⠈⠹⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡿⠛⡧⠁⡴⣦⣔⣶⣄⢠⠄⠄⠹⣿⣿⣿⣿⣿⣿⣿⣤⠭⠏⠙⢿⣿⣿⣿⣿⣿
⣿⡧⠠⠠⢠⣾⣾⣟⠝⠉⠉⠻⡒⡂⠄⠙⠻⣿⣿⣿⣿⣿⡪⠘⠄⠉⡄⢹⣿⣿⣿⣿
⣿⠃⠁⢐⣷⠉⠿⠐⠑⠠⠠⠄⣈⣿⣄⣱⣠⢻⣿⣿⣿⣿⣯⠷⠈⠉⢀⣾⣿⣿⣿⣿
⣿⣴⠤⣬⣭⣴⠂⠇⡔⠚⠍⠄⠄⠁⠘⢿⣷⢈⣿⣿⣿⣿⡧⠂⣠⠄⠸⡜⡿⣿⣿⣿
⣿⣇⠄⡙⣿⣷⣭⣷⠃⣠⠄⠄⡄⠄⠄⠄⢻⣿⣿⣿⣿⣿⣧⣁⣿⡄⠼⡿⣦⣬⣰⣿
⣿⣷⣥⣴⣿⣿⣿⣿⠷⠲⠄⢠⠄⡆⠄⠄⠄⡨⢿⣿⣿⣿⣿⣿⣎⠐⠄⠈⣙⣩⣿⣿
⣿⣿⣿⣿⣿⣿⢟⠕⠁⠈⢠⢃⢸⣿⣿⣶⡘⠑⠄⠸⣿⣿⣿⣿⣿⣦⡀⡉⢿⣧⣿⣿
⣿⣿⣿⣿⡿⠋⠄⠄⢀⠄⠐⢩⣿⣿⣿⣿⣦⡀⠄⠄⠉⠿⣿⣿⣿⣿⣿⣷⣨⣿⣿⣿
⣿⣿⣿⡟⠄⠄⠄⠄⠄⠋⢀⣼⣿⣿⣿⣿⣿⣿⣿⣶⣦⣀⢟⣻⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⡆⠆⠄⠠⡀⡀⠄⣽⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⡿⡅⠄⠄⢀⡰⠂⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿

*/