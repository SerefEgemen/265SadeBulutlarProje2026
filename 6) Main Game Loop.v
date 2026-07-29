/*

BTNCin : BTNC basım kontrol tur ilerlemesi için [U18]
player1 : BTNU [T18]
player2 : BTNL [W19]
player3 : BTNR [T17]
player4: BTND [U17]

*/
module gameLoop(input clk, rst, );

input BTNC;
input 

turSayisi <= turnNo; //config'den gelecek
playerCount <= playerNo; //aktif oyuncu sayısı yine config'den
reg [1:0] playerActive [3:0]; //playerların plup olmadığını assignlamak için 1 bit true/false switch input için açar main game'de
reg enable; // btnc aktifleştirme
reg [2:0] playerOrderSpeed [3:0]; //gameloopta sırayı belirler, player no alır
reg [3:0] score [playerCount:0][turSayisi:0]; //log
reg hardMode <= hardModeInput; //configden
//main game loop
reg timer; //sayı değeri diyelim
reg order <= 0; //sıralama yapılırken 


//player var mı aşağıdaki gameloop için
for(i = 0; i < 4; i + 1) begin

if(i < playerCount)
playerActive[i] <= 1'b1;
else
playerActive[i] <= 1'b0;

end

//main gameloop

wait(BTNC == 1); //1. turun başlaması için, butona basılmadan oyun başlamıyor

  for(i = 0; (i < turSayisi) && !rst; i + 1, enable = 0, order = 0) begin //staticte değil

timer <= /*doldur*/;//timer değerini fonksiyondan alır
while() begin //gameloop ime limit & timer karşılaştır timer geçince gamelooptan çık
/*
inputlar bu kısımda açık, her input ile ledler sırasıyla yanmalı input basıldıktan sonra geçen süre depolanmalı
*/

//sırasıyla input açar
if(playerCount[0]) begin //1. oyuncu
playerOrderSpeed[order] <= 2b'00;
order <= order +1;
end
if(playerCount[1]) begin //2. oyuncu
playerOrderSpeed[order] <= 2b'01;
order <= order +1;
end
if(playerCount[2])begin
playerOrderSpeed[order] <= 2b'10; //3. oyuncu
order <= order +1;
end
  if(playerCount[3])begin //4. oyuncu
    if() //button press içi aşağısı için
playerOrderSpeed[order] <= 2b'11;
order <= order +1;
end

end
//timer end

enable = 1; //btnc ile tur bitirilebilir artık

/*
burada input vermeyenler timeout'a alınır belki her oyuncu için true/false yapılabilir basıp basmamaları hakkında
*/

//skor hesabı
for(j = 0; j < 4; j + 1) begin //4 ile sınırlı, belki bir tık daha geliştirilebilir

case(playerOrderSpeed)
case 2b'00:  score[0][i] <= playerCount - j;
case 2b'01:  score[1][i] <= playerCount - j;
case 2b'10:  score[2][i] <= playerCount - j;
case 2b'11:  score[3][i] <= playerCount - j;
endcase

end
//timeout vb otomatik 0 olur

//ScoreCalc() belki display sıralama ? olabilir yapılabilir orderla

//elimination açıksa eliminate players here t/f
//elimination modu açıksa order'da olmayan değerlerin switchlerini kapatır

if(enable) begin
  wait(BTNC == 1); //bir sonraki tura geçirene kadar manuel olarak, teknik olarak tur burada bitti bir sonrakine geçe emri bekliyor **daha düzgün yaz
end

end
//game is over, so after this is the endgame part

//ScoreCalcEndgame() & playerled sıralama display

end //module
