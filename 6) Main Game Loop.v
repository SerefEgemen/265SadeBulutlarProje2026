`timescale 1ns / 1ps
/*

!! FORMATLAMA SIKINTILARI OLABİLİR GITHUBDA VE VS'DA KODLADIM ve VS'DAKI COMPILERA GÜVENDİM . PİŞMANIM !!

BTNC : BTNC basım kontrol tur ilerlemesi için [U18]
player1 : BTNU [T18]
player2 : BTNL [W19]
player3 : BTNR [T17]
player4: BTND [U17]

!! playerLED ile bağlanmalı fonksiyonlar birleştirilirken !!

*/

module gameLoop(input clk, rst, reg turnNo, reg playerNo, BTNC, BTNU, BTNL BTNR, BTND, hardModeInput, eliminationModeInput, kararmaSinyali 
                
output reg [3:0] score [playerNo:0][turnNo:0]; //log

);
  
reg [1:0] playerActive [3:0]; //playerların olup olmadığını assignlamak için 1 bit true/false switch input için açar main game'de
reg [2:0] playerOrderSpeed [3:0]; //gameloopta sırayı belirler, player no alır Sınırlar İçi Basanlar
reg [1:0] falseStart [playerNo:0]; //victims
reg turSayisi <= turnNo; //d
reg playerCount <= playerNo; // d
hardMode <= hardModeInput; //1'b t/f
elimination <= eliminationModeInput; //1'b t/f
//main game loop
reg order <= 0; //sıralama yapılırken kullanıyor playerOrder side piece
  
timer <= kararmaSinyali;
  //ışıklar kapandığında falseStart'tan playerOrder'a geçecek. 5 sec timer her türlü sayacak, çıkınca da timeout'a alır.

//player var mı aşağıdaki gameloop için true/false vbvb CONFIG
for(i = 0; i < 4; i + 1) begin

	if(i < playerCount)
	playerActive[i] <= 1'b1;
	else
	playerActive[i] <= 1'b0;
	
	falseStart[i] <= 1'b0;
		
	for(j = 0; j < turSayisi; j + 1 )begin
		score[i][j] <= 0;  //skor tablosu full 0 başlar
	end
	
end

//main gameloop alt config üst - main'de btnc basma ayarlanmalı fonksiyonun çağırılması için çağırılınca başlar oyun otomatik

for(i = 0; (i < turSayisi) && !rst; i + 1, order = 0) begin //staticte değilken gameloop,, bir tık daha düzeltilmeli rough draft diyelim
//static durumdayken gameloop iptal oluyor sıkıntı yaratabilir belki ve turu bitirdikten sonra imha ediyor tur ortası basılırsa çalışıyor kod ### Not ###
//inputlar bu kısımda açık, her input ile ledler sırasıyla yanmalı playerlarla bağlantılı

		while(!timer) begin //falseStart victims
			if(playerCount[0]) begin//1. oyuncu
			      if(BTNU) begin
							falseStart[0] <= 1'b1;
			      end 
			    end
			    if(playerCount[1]) begin//2. oyuncu
			      if(BTNL) begin
					  falseStart[1] <= 1'b1;
			      end 
			    end
			    if(playerCount[2]) begin
			      if(BTNR) begin
					  falseStart[2] <= 1'b1; //3. oyuncu
			      end 
			    end
			if(falseStart[3]) begin//4. oyuncu
			      if(BTND) begin//button press içi aşağısı için
							falseStart[3] <= 1'b1;
			      end 
			    end
			  end //if

	end //while

	for(j = 0; j < ) begin//playerOrder 5 seconds of grace OLACAK work in progress
      //sırasıyla input açar falsestart olmamalarına göre
	    if(playerCount[0] && !falseStart[0]) begin//1. oyuncu
	      if(BTNU) begin
					playerOrderSpeed[order] <= 2'b00;
	        order <= order +1;
	      end 
	    end
	    if(playerCount[1] && !falseStart[1]) begin//2. oyuncu
	      if(BTNL) begin
					playerOrderSpeed[order] <= 2'b01;
	        order <= order +1;
	      end 
	    end
	    if(playerCount[2] && !falseStart[2]) begin
	      if(BTNR) begin
					playerOrderSpeed[order] <= 2'b10; //3. oyuncu
	        order <= order +1;
	      end 
	    end
	    if(playerCount[3] && !falseStart[3]) begin//4. oyuncu
	      if(BTND) begin//button press içi aşağısı için
					playerOrderSpeed[order] <= 2'b11;
	        order <= order +1;
	      end 
	    end
	  end //if

	end //for

/*
burada input vermeyenler timeout'a alınır belki her oyuncu için true/false yapılabilir basıp basmamaları hakkında ama çook uzun olur düşün bir şeyler

kısacası timer bitti timeout artık herkes

üstteki yazdığımı sallamaya gerek yok inputu sadece yukarıda alabiliyor çünkü checkler yukarıda ondan dolayı manuel ayarlamamızı gerektiren bir şey yok ama kaldın yine de anı ?
*/

//skor hesabı kısmı
for(j = 0; j < playerCount; j + 1) begin //hmm playerCount 4 player olunca 3 mü 4 mü alıyordu hata çıkarsa oradan çıkar !!!! son oyuncuyu saymamaya başlarsa basmayan ayırt edilemez olabilir 0 bastığı için dikkat

case(playerOrderSpeed[j])
  
case 2'b00:  score[0][i] <= playerCount - j; //i olmasının sebebi tura göre kaydetmesi
case 2'b01:  score[1][i] <= playerCount - j;
case 2'b10:  score[2][i] <= playerCount - j;
case 2'b11:  score[3][i] <= playerCount - j;
  
endcase

end
//timeout vb otomatik 0 olur başlangıç config sayesinde

//ScoreCalc() belki display sıralama ? olabilir yapılabilir orderla

//elimination açıksa eliminate players here t/f
	if(elimination) begin
		order <= order - 1; //açıklama aşağı blokta
		for(j = 0; j < playerCount; j + 1) begin
			
			/*
			oyuncu başı kontrol. skoru 0 olan ve playerOrderSpeed kategorisinde sonuncu olmayan her kişi otomatikman ya timeout ya da falseStart grubuna ait olmak zorunda
			[order - 1] olmasının sebebi yukarıda playerOrder'a veri koyduktan sonra otomatik +1 yaptırmam, eksiltmeden bakarsam normal order'a null ya da out of bounds olacaktır
			order for döngüsünün içinde 0lanacak zaten ondan dolayı burada evirip çevirmemde bir sıkıntı yok
			*/
			
			if((score[j][i] = 0) && (playerOrderSpeed[order] = j)) begin 
				playerCount[j] <= 1'b0; //nuked
			end
		end
	end
//^^ elimination modu açıksa order'da olmayan değerlerin switchlerini kapatır ^^ 


	
	
	
wait(BTNC == 1); //bir sonraki tura geçirene kadar manuel olarak, teknik olarak tur burada bitti bir sonrakine geçe emri bekliyor **daha düzgün yaz


end
//game is over, so after this is the endgame part

//ScoreCalcEndgame() & playerled sıralama display

end //module











/*


⡴⠒⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⠉⠳⡆⠀
⣇⠰⠉⢙⡄⠀⠀⣴⠖⢦⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣆⠁⠙⡆
⠘⡇⢠⠞⠉⠙⣾⠃⢀⡼⠀⠀⠀⠀⠀⠀⠀⢀⣼⡀⠄⢷⣄⣀⠀⠀⠀⠀⠀⠀⠀⠰⠒⠲⡄⠀⣏⣆⣀⡍
⠀⢠⡏⠀⡤⠒⠃⠀⡜⠀⠀⠀⠀⠀⢀⣴⠾⠛⡁⠀⠀⢀⣈⡉⠙⠳⣤⡀⠀⠀⠀⠘⣆⠀⣇⡼⢋⠀⠀⢱
⠀⠘⣇⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⡴⢋⡣⠊⡩⠋⠀⠀⠀⠣⡉⠲⣄⠀⠙⢆⠀⠀⠀⣸⠀⢉⠀⢀⠿⠀⢸
⠀⠀⠸⡄⠀⠈⢳⣄⡇⠀⠀⢀⡞⠀⠈⠀⢀⣴⣾⣿⣿⣿⣿⣦⡀⠀⠀⠀⠈⢧⠀⠀⢳⣰⠁⠀⠀⠀⣠⠃
⠀⠀⠀⠘⢄⣀⣸⠃⠀⠀⠀⡸⠀⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣆⠀⠀⠀⠈⣇⠀⠀⠙⢄⣀⠤⠚⠁⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⠀⢠⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⢹⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡀⠀⠀⢘⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡇⠀⢰⣿⣿⣿⡿⠛⠁⠀⠉⠛⢿⣿⣿⣿⣧⠀⠀⣼⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡀⣸⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⡀⢀⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡇⠹⠿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⡿⠁⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠻⣤⣞⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢢⣀⣠⠇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠲⢤⣀⣀⠀⢀⣀⣀⠤⠒⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀


🐺



*/
