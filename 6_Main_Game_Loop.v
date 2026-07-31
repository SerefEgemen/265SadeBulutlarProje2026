`timescale 1ns / 1ps
/*

!! FORMATLAMA SIKINTILARI OLABİLİR GITHUBDA VE VS'DA KODLADIM ve VS'DAKI COMPILERA GÜVENDİM . PİŞMANIM !!

BTNC : BTNC basım kontrol tur ilerlemesi için [U18]
player1 : BTNU [T18]
player2 : BTNL [W19]
player3 : BTNR [T17]
player4: BTND [U17]

!! playerLED ile bağlanmalı fonksiyonlar birleştirilirken !!
## mantık hataları olabilir test edilmeli boyutlar için



Hello! This needs to be rebuilt entirely!!! Mete
*/

module gameLoop(input clk, rst, turnNo, playerNo, BTNC, BTNU, BTNL, BTNR, BTND, hardModeInput, eliminationModeInput, kararmaSinyali, 
                
output reg[3:0] score /* [playerNo:0][turnNo:0]; //log*/ 

);








endmodule

/*
reg [3:0] playerActive; //playerların olup olmadığını assignlamak için 1 bit true/false switch input için açar main game'de
reg [3:0] playerOrderSpeed; //gameloopta sırayı belirler, player no alır Sınırlar İçi Basanlar
reg [3:0] falseStart; //victims
reg turSayisi; //d
reg playerCount; // d
reg hardMode; //1'b t/f
reg elimination; //1'b t/f
//main game loop
reg order; //sıralama yapılırken kullanıyor playerOrder side piece



always @(posedge clk) begin
  
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
  //ışıklar kapandığında falseStart'tan playerOrder'a geçecek. 5 sec timer her türlü sayacak, çıkınca da timeout otomatikman çünkü input kabul etmez

//player var mı aşağıdaki gameloop için true/false vbvb CONFIG aşaması
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

for(i = 0; (i < turSayisi) && !rst; i = i + 1) begin //staticte değilken gameloop,, bir tık daha düzeltilmeli rough draft diyelim
//static durumdayken gameloop iptal oluyor sıkıntı yaratabilir belki ve turu bitirdikten sonra imha ediyor tur ortası basılırsa çalışıyor kod ### Not ###

//inputlar bu kısımda açık, her input ile ledler sırasıyla yanmalı playerlarla bağlantılı

		while(!timer) begin //falseStart victims
			if(playerCount[0]) begin//1. oyuncu
			      if(BTNU) begin
							falseStart[0] <= 1'b1;
					  //playerled vb eklenmeli sıra için. playerled inputu sıra için order, playerNo için if döngüsü içindeki değeri olarak ayarlanmalı
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
			if(playerCount[3]) begin//4. oyuncu
			      if(BTND) begin//button press içi aşağısı için
							falseStart[3] <= 1'b1;
			      end 
			    end
			  end //if

	end //while

	end_time = $time + 5000000000; //5 sec wait
	while($time < end_time)( begin//playerOrder 5 seconds of grace OLACAK work in progress
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
	#5 //time goes on. there are 5 nanoseconds inbetween presses.
	end //while

//skor hesabı kısmı
for(j = 0; j < order; j = j + 1) begin 

	case(playerOrderSpeed[j])
	  
		case 2'b00:  score[0][i] <= playerCount - j; //i olmasının sebebi tura göre kaydetmesi
		case 2'b01:  score[1][i] <= playerCount - j;
		case 2'b10:  score[2][i] <= playerCount - j;
		case 2'b11:  score[3][i] <= playerCount - j;
		default: //boş çünkü olmamalı
		//case'ler ilerletilebilir max player sayısıma göre kapsaması için
			
	endcase

end
//timeout vb otomatik 0 olur başlangıç config sayesinde

//belki display sıralama ? olabilir yapılabilir 

//elimination
	if(elimination) begin
		order <= order - 1; //açıklama aşağı blokta
		for(j = 0; j < playerCount; j = j + 1) begin
			
			/*
			oyuncu başı kontrol. skoru 0 olan ve playerOrderSpeed kategorisinde sonuncu olmayan her kişi otomatikman ya timeout ya da falseStart grubuna ait olmak zorunda
			[order - 1] olmasının sebebi yukarıda playerOrder'a veri koyduktan sonra otomatik +1 yaptırmam, eksiltmeden bakarsam normal order'a null ya da out of bounds olacaktır
			order for döngüsünün içinde 0'lanacak zaten ondan dolayı burada evirip çevirmemde bir sıkıntı yok
			*/
			/*
			if((score[j][i] == 0) && !(playerOrderSpeed[order] == j)) begin 
				playerCount[j] <= 1'b0; //nuked
			end

		end
	end
//^^ elimination modu açıksa order'da olmayan değerlerin switchlerini kapatır ^^ 

for(j = 0; j < playerCount; j = j + 1) begin
	falseStart[j] <= 1'b0; //reset, does not affect eliminations because elimination is handled by another matrix
end
			
wait(BTNC); //bir sonraki tura geçirene kadar manuel olarak durdurur, teknik olarak tur burada bitti bir sonrakine geçe emri bekliyor **daha düzgün yaz

order = 0;

end
//game is over, so after this is the endgame part

//playerled sıralama display vbvbvb

end

endmodule //module

*/









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


🐺:3
^^
https://i.kym-cdn.com/entries/icons/original/000/042/980/bludthinkshesontheteam.jpg


*/
