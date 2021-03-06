//+------------------------------------------------------------------+
//Developed by Josef Antoš, all rights reserved                      |
//+------------------------------------------------------------------+
/*

Co je přidáno:
- Výpočet prùmìrného rozpìtí trhu.
- Vytvoření linií pro shluk 4 hodin
- Breakeven Point
- Automatický TP a SL, pøípadnì i manuální
- Skrytý take profit
- Fotografie tržních situcí - dodìlat do situací, kdy je aktivován obchod!
- Notifikace na mobil a email 
 
Verze:

1.01
Opraveno uzavírání obchodů na vnějším modrých hranicích, teď už by mělo fungovat
K otevírání nových obchodů přidána podmínka, že předchozí obchod musí být nutně ztrátový a nestačí je globální proměnná
Opravena podmínka mazání h1 hranic

1.02
K modifikaci h1 linií jsem přidal podmínku, že nesmí být předchozí obchod ztrátový.. cílem je zamezit posouvání během uzavírání a otevírání reverzních obchodů

1.03
Zjednotušeno posouvání linií, odstraněny 2 zbytečné smyčky
Opravené loty
Zakomentováno TVAdjust

1.04
Přidán ukazatel poslední série obchodů
Opraveno mazání signálů. (snad v pořádku)
Odkomentován BEP, můžu ho začít používat

1.05
AOS má teď "Magic" hodnotu a recovery má "Automagic" - mělo by to vyřešit problém s nemizícíma 
Převrátil jsemu zavírání, mělo by to trochu odlehčit náročnosti skriptu
Všude jsem přidat Magic do funkcí 

1.06
Přidána podmínka do autotradingu, že pro otevření obchodu nesmí být Globální kontrolní proměnná rovná -1, tzn. že poslední obchod nebyl ve ztrátě

1.07
Odstraněno převrácení z 1.05
Přidána minimální vzdálenost pro první obchod

1.08
Mazání obchodů pro AOS posunuto nahoru

1.09
Odstraněno AOS
Výstupy upraveny podle horší hodnoty měny ( long exit - bid, short exit - ask )

1.1 
Přidáno else statement tam, kde se nastavuje globální proměnná

1.11
Odstraněn time limit
Přidáno posouvání označovaných hranic
Přidána ochrana, aby se hranice posouvaly jen, když je to potřeba (mělo by to snížit nároky na HW)

1.12
Funkce IsTrade předělána na IsNoTrade
Přidáno mazání signálů, pokud není obchod a uzavírá se platforma

1.13
Zakomentováno přidávání signálů když už je vytvořený obchod (nefungovalo to, když běží synchronně dva MetaTradery)
Přidána podmínky pro vy
Opravena chyba v lotech

1.14
Opraveno umísťování výstupních hranic

1.15
Omezeno mazání starých signálů, teď se mažou jen když jsou časově starý
Přidávání starých signálů probíhá jenom mezi 2-3 minutou
Omezena úprava všech obchodů, odteď musí projít funkcí IsNoTrade (1322 řádek, dále 1508)

1.16
Přidána globální proměnná na vytváření obchodů, tohle je potřeba ještě dodělat v situacích, kdy se budou existující signály upravovat a bude tam už obchod, 
ne jen vytvářet nové, jako je tomu teď
Zakázána manipulace s obchody první hodinu v pondělí (kvůli spreadu)

1.17
Už by to mělo dodávat signály i když je otavřený první obchod.

1.18
Opraven BEP, byla tam chyba, nezavíralo to, když je systém ve ztrátě.

1.19
Přídána malá úprava do moneymanagementu, která se aktivuje, pokud není obchod. V tom případě se za maximální rozpětí bere H1 limit, pokud je skutečné větší

1.20
Přidána malá úprava, kdy není povoleno uzavírání obchodů v pátek po 23 hodině. 

1.21
Odstraněn IsSpreadOK
Přidáno zarovnávání H1 hranic podle obchodu.
Přidána funkce GetCurrentTradeDetails pro získávání hodnot aktuálních obchodů
Z funkcí LastTotalLosingTradesUSD a LastTotalSequenceTradesUSD odstraněn Emergency management reset.
Opraven PotentialProfit a PotentialLoss funkce, odstranil jsem z nich spread;
Odstraněna funckce Reward Ratio, která už vůbec nebyla použita v systému
Zpřísnil jsem podmínky pro platný signál, nově jsou klouzavé průměry normalizované na 4 desetinná místa na běžných párech a 2 na JPY párech
Přidána funkce, která odesílá varování, pokud je zde 6 ztrátových obchodů v řadě

2.00
Přesouvám to na H4, začínám znova od nuly, je 24.2.2017.
2.01
Opravena úprava signálů
2.02
Přidáno správné počívání BEP

2.03
Mazání obchodů opraveno na 12 hodin, když je neaktivní
Opraveny hodnoty indikátorů

TODO:

1) přidat varování, jestli můžu obchodovat a jestli nikoliv... nějak potřebuju vyfiltrovat chop

2) Opravit hranice signálu tak, že musí být minimálně 0,75 signálu široký. 

3) Přidat nastavení ochrany na limitní příkazy. 

4) Přidat RRR pro každý otevřený obchod!


Nová verze po úpravě:

Verze 2.51
1) Opraveno zavírání obchodů
2) Opraveny signály, už do toho započítávám MA200

Verze 2.52
1) Odstraněno mazání signálů při vypnutí systému, mazání příkazů

Verze 2.53
1) Dočasně převedeno zpět na H1
2) Opraveno mazání starých signálů 


*/


#property copyright "Josef Antoš"
#property link      "http://www.4xbroker.cz"
#property version   "2.53"

extern string     BasicSetting = "=====================================";
extern bool       NoLoss = true;
extern double     Risk = 0.25;                //kolik riskovat na jeden obchod
extern double     Day_Index = 0.6;       //jak široké mají být široké zùžení
extern int        Slippage = 100;
extern string     TradeSetting = "=====================================";
extern bool       SpreadProtection=true;        //velikost stoplossu
extern int        NormalSpread = 50;
extern int        MaxSpread=100;                //velikost stoplossu        
extern double     TakeProfitCount = 1.6;       //Take profit vùèi rozpìtí zùžení   
extern bool       BreakEven = false;          //BEP
extern int        BreakEvenLevel=100;          //pokud je BreakEvenLeven 0, pak je automaticky nastavený podle H1 Limitu na 1-H1_Limit
extern bool       UseHiddenTP = false;
extern double     HiddenTPDistance = 120;
extern string     DisplaySetting = "=====================================";
extern bool       Send_Email = true;        //zda se mají posílat emaily
extern bool       Send_Message = true;       //zda se mají posílat zprávy na mobil
extern bool       Delete_On_Deinit=false;
extern bool       Display_Results = true;    //zda zobrazovat komentáøe
extern bool       Delete_Lines = true;       //zda se mají linie smazat poté, co trh urazí XXX pipù
extern bool       OneClickTrading = true;
extern int        LastCandles = 50;
extern string     ColorSetting = "=====================================";
extern color      ShortColor = Red;
extern color      PivotColor = Orange;
extern color      LongColor = Lime;

double EraseHours = 3;                     //po jaké dobì se mažou horní a dolní linie
int   _width     = 1280;                     //nastavení šíøky rozlišení 
int   _height    = 800;                      //nastavení výšky rozlišení 
color  BEColor=Green;
int    BEStyle=STYLE_DASH;
int Width = 2;
int Fontsize = 8;

//Určený pro recovery obchody 
int AutoMagic = 5045489;
int Hours = 3;
int FirstCandle = 1;                         //odskočení první svíčky
int Check = 0;
int HoursSeconds = 3600;
double Coef = 0.85;                          //koeficient k průměrnýmu rozpětí trhu 

int   MAFast = 16;
int   MASlow = 34;
double MASlowest = 200;
int ShaffQuick=8;
int ShaffSlow=16;
double Cycle=6;
int CountBars=300;
double MinDistanceCoef = 0.5;

int Adjust(){
   int Result;
   if (Digits==2)
   Result = 100;
   if (Digits==3)
   Result = 1000; 
   if (Digits==4)
   Result = 10000;
   if (Digits==5)
   Result = 100000; 
return(Result);
}

//poèítadlo obchodù
int Trades() {
int Orders;

   for(int i=OrdersTotal()-1;i>=0;i--) {
   Check = OrderSelect(i, SELECT_BY_POS, MODE_TRADES);
   if (Check <0 ) Print ("Select error ", GetLastError());
   if (OrderMagicNumber() == 0 || OrderMagicNumber() == AutoMagic ) {
      if (OrderSymbol() == Symbol() ){   
         if (OrderType()==OP_BUY || OrderType()==OP_SELL){
            Orders = Orders + 1;
            }
         }
      }   
   }
return (Orders);   
}

// vrací poèet otevených buy order
char BuyLimitTrades() {
   char bo=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES) && (OrderMagicNumber()  == AutoMagic || OrderMagicNumber()==0 )
         &&  OrderSymbol()       == Symbol() && (OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT) )
         bo=bo+1;
     }
   return(bo);
  }
  
// vrací poèet otevených buy order
char SpecificTrades( int MagicN, int Opentype ) {
   char bo=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber()  == MagicN 
         &&  OrderSymbol()       == Symbol() && OrderType()==Opentype )
         bo=bo+1;
     }
   return(bo);
  }  
  
//check last trader type
int LastTradeType(){ 

   datetime lastOpen = 0;                                   
   char Result = 0;
   int lastCloseTime = 0;
   int curCloseTime = 0;
   int LongOpenTime = 0;
   int ShortOpenTime = 0; 
    
   for ( int h = OrdersTotal(); h >= 0 ; h--){ 
       if (OrderSelect (h, SELECT_BY_POS, MODE_TRADES)){      
           if  ( OrderSymbol() == Symbol())  {      
           curCloseTime = (int)OrderOpenTime();
           int Ticket = OrderTicket();
           //buy obchody
           if (OrderType()==OP_BUY) { 
               if(curCloseTime > lastCloseTime){
               lastCloseTime = curCloseTime; 
                   if (OrderSelect (Ticket, SELECT_BY_TICKET)) { 
                        LongOpenTime = OrderOpenTime();
                      }
                   } 
               }                    
           }
       }
   }     
        
          
   for ( int j = OrdersTotal(); j >= 0 ; j--){ 
       if (OrderSelect (j, SELECT_BY_POS, MODE_TRADES)){      
           if  ( OrderSymbol() == Symbol())  {      
           curCloseTime = (int)OrderOpenTime();
           int Ticket2 = OrderTicket();
           //buy obchody
           if (OrderType()==OP_SELL) { 
               if(curCloseTime > lastCloseTime){
               lastCloseTime = curCloseTime; 
                   if (OrderSelect (Ticket2, SELECT_BY_TICKET)) { 
                         ShortOpenTime = OrderOpenTime();
                      }
                   } 
               }                    
           }
       }
   }
   
   //poslední je long 
   if (ShortOpenTime < LongOpenTime) Result = 1;
   //poslední je short 
   if (ShortOpenTime > LongOpenTime) Result = 2;                      
return (Result); 
}

// vrací poèet sell tradù 

char SellLimitTrades() {
   char so=0;
   for(int i=OrdersTotal()-1;i>=0;i--){
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES) && OrderSymbol()==Symbol() && (OrderMagicNumber()  == AutoMagic || OrderMagicNumber()==0 )
         && (OrderType()==OP_SELLSTOP  || OrderType()==OP_SELLLIMIT) ) {
         so=so+1;
        }
     }
return(so);
}
  
// vrací poèet sell tradù 
char SellTradesTotal() {
   char so=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES) 
      && ( OrderMagicNumber() == 0|| OrderMagicNumber()  == AutoMagic ) 
      && OrderSymbol()==Symbol()
      && OrderType()==OP_SELL)
        {
         so=so+1;
        }
     }
   return(so);
  }  
  
//kontroluje, zda je na saném trhu obchod 
bool IsNoTrade (){
   bool Result = true;
   for(int i=OrdersTotal()-1;i>=0;i--) {
      if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
         if(OrderSymbol() == Symbol()&& (OrderMagicNumber()==0 || OrderMagicNumber()==AutoMagic )){ 
            Result = false;
    
            }
         }
      }
   return (Result);
}


/*======================================================

Closes trades, that are twice as big as recomended 
management Management().

======================================================*/
/*
void TraderProtection (){

   if ( IsTradeAllowed() ) {
      if ( ( SpecificTrades( 0, OP_BUY) == 1 && SpecificTrades( 0, OP_SELL) == 0) ||
         ( SpecificTrades( 0, OP_BUY) == 0 && SpecificTrades( 0, OP_SELL) == 1 ) )  {
      for(int i=OrdersTotal()-1;i>=0;i--) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            if( OrderSymbol() == Symbol()&&  OrderMagicNumber()==0 ){ 
                  if ( OrderLots() > StrToDouble(Management()) * 2 ) {
                    Check = OrderClose( OrderTicket(), OrderLots(), OrderOpenPrice(), Slippage, 0); 
                    if (Check <0 ) Print ("Select error ", GetLastError());
                  }
               }
            }
         }
      }
   }
}*/


double PotentiaLoss () {
double FinalResult;
double Result;
double Tickvalue = MarketInfo(Symbol(),MODE_TICKVALUE);
double LongExit = ObjectGet("Long_Exit", OBJPROP_PRICE1);
double ShortExit = ObjectGet("Short_Exit", OBJPROP_PRICE1);
if ( BreakEven && SpecificTrades( 0, OP_SELL ) ) ShortExit = ObjectGet("BEP_Short_Exit", OBJPROP_PRICE1);
/*double LongBEPExit = ObjectGet("BEP_Long_Exit", OBJPROP_PRICE1);
double ShortBEPExit = ObjectGet("BEP_Short_Exit", OBJPROP_PRICE1);*/
double SpreadPoint = NormalSpread*Point;

for(int i=OrdersTotal()-1;i>=0;i--) {
   if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderSymbol() == Symbol()) {
            if (OrderType() == OP_SELL ) {
               Result = (OrderOpenPrice() - ShortExit + SpreadPoint)*Adjust()*Tickvalue*OrderLots(); 
               FinalResult = FinalResult + MathAbs(Result);

            }  
            
            if (OrderType() == OP_BUY ) {
               Result = (OrderOpenPrice() - ShortExit + SpreadPoint)*Adjust()*Tickvalue*OrderLots(); 
               FinalResult = FinalResult - MathAbs(Result);
            }                      
         }  
      }
   }

return (FinalResult);  
}
  
double  PotentialProfit () {
double FinalResult;
double Result;
double Tickvalue = MarketInfo(Symbol(),MODE_TICKVALUE);
double LongExit = ObjectGet("Long_Exit", OBJPROP_PRICE1);
double ShortExit = ObjectGet("Short_Exit", OBJPROP_PRICE1);
if ( BreakEven && SpecificTrades( 0, OP_BUY ) ) LongExit = ObjectGet("BEP_Long_Exit", OBJPROP_PRICE1);
double SpreadPoint = NormalSpread*Point;

for(int i=OrdersTotal()-1;i>=0;i--) {
   if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
      if(OrderSymbol() == Symbol()) {
         if (OrderType() == OP_BUY ) {
            Result = ( LongExit-OrderOpenPrice() )*Adjust()*Tickvalue*OrderLots(); 
            FinalResult = FinalResult + MathAbs(Result);
         } 
         if (OrderType() == OP_SELL) {
            Result = (LongExit-OrderOpenPrice() )*Adjust()*Tickvalue*OrderLots(); 
            FinalResult = FinalResult - MathAbs(Result);
         } 
         }         

      }
   }  

return (FinalResult);  
}

/*======================================================

returns ordertype for last current trade in block, 
no matter if Main or Recovery

======================================================*/

double LongOpenPrice( ){  
   
   double   Result = 0;
   datetime CloseTime           = 0;
   for(int i=OrdersTotal()-1;i>=0;i--) {
       if (OrderSelect(i,SELECT_BY_POS,MODE_TRADES)) {
         if (OrderSymbol() == Symbol() ) {
         if (OrderType() == OP_BUY || OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT) {
              if (OrderOpenTime()>CloseTime) {
                 CloseTime = OrderOpenTime();
                 Result = OrderOpenPrice();
              } 
           }
          }   
       }
   }   

return(Result);
}

double ShortOpenPrice( ){  
   double   Result = 0;
   datetime CloseTime           = 0;
   for(int i=OrdersTotal()-1;i>=0;i--) {
       if ( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) {
            if ( OrderType() == OP_SELL || OrderType() == OP_SELLLIMIT || OrderType() == OP_SELLSTOP ) {
              if ( OrderSymbol() == Symbol() && OrderOpenTime()>CloseTime ) {
                 CloseTime = OrderOpenTime();
                 Result = OrderOpenPrice();
                 
              } 
           }   
       }
   }   
return(Result);
}

//prùmìr trhu za posledních 30 svíèek
double MarketAverage(){
   int SR1=0,SR30=0,SR10=0,SR20=0,SRAvg=0;
   int RoomUp=0,RoomDown=0,StopLoss_Long=0,StopLoss_Short=0;
   double   SL_Long=0,SL_Short=0;
   double   low0=0,high0=0;
   int i=0;
      
   for(i=1;i<=10;i++)
      SR10    =    SR10  +  MathAbs((iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i)))/Point;
   for(i=1;i<=20;i++)
      SR20   =    SR20 +  MathAbs((iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i)))/Point;
   for(i=1;i<=30;i++)
      SR30   =    SR30 +  MathAbs((iHigh(NULL,PERIOD_D1,i)-iLow(NULL,PERIOD_D1,i)))/Point;
      
   double Day1 = MathAbs((iHigh(NULL,PERIOD_D1,1)-iLow(NULL,PERIOD_D1,1)))/Point;   
   double Day2 = MathAbs((iHigh(NULL,PERIOD_D1,2)-iLow(NULL,PERIOD_D1,2)))/Point;   
   double Day3 = MathAbs((iHigh(NULL,PERIOD_D1,3)-iLow(NULL,PERIOD_D1,3)))/Point;   
   double Day4 = MathAbs((iHigh(NULL,PERIOD_D1,4)-iLow(NULL,PERIOD_D1,4)))/Point;   
   double Day5 = MathAbs((iHigh(NULL,PERIOD_D1,5)-iLow(NULL,PERIOD_D1,5)))/Point;   
         
   SR10 = SR10/10;
   SR20 = SR20/20;
   SR30 = SR30/30;
   
   SRAvg  =  (SR30+SR20+SR10)/3;
   
   double Result=SR30;
   NormalizeDouble(Result, 2);
   return (Result);
}



//--------------------------------------------------------------------|
//      hlavní funkce této strategie                                  |
//--------------------------------------------------------------------|

//kontrola spreadu
bool SpreadCheck() {
bool Result = true;
double Spread = MarketInfo( Symbol(), MODE_SPREAD);
if (SpreadProtection==false){ Result = true; }
else if (SpreadProtection==true){
   if ( MaxSpread < Spread  ){  
         Result = false; 
   } else {
     Result = true;   
   } 
} 
  
return (Result);
}

//hlavní funkce pro rozhodování, zda je platný signál či nikoliv
int FinalDecision(){

   double Schaff = iCustom (Symbol(), PERIOD_H1, "Schaff_Trend_Cycle" , ShaffQuick, ShaffSlow, Cycle, CountBars, 0, 1); //aktální síla
   double MA1 = iMA(Symbol(), PERIOD_H1, MAFast, 0,MODE_EMA, 0, 1);
   double MAslow1 = NormalizeDouble(  iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, 1), Digits-1);
   double MAslow2 = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, 2), Digits-1);
   double MAslow3 = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, 3), Digits-1);
   double MAslow4 = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, 4), Digits-1);
   double MASlowest1 = NormalizeDouble(  iMA(Symbol(), PERIOD_H1, MASlowest, 0,MODE_EMA, 0, 1), Digits-1);
   
   int Result = 0;
   double CandleOpen = iOpen( Symbol(), PERIOD_H1, 1 );
   double BarHigh = High[iHighest(Symbol(),PERIOD_H1,MODE_HIGH,Hours,1)];   
   double BarLow = Low[iLowest(Symbol(),PERIOD_H1,MODE_LOW,Hours,1)];   
   double Difference = (BarHigh - BarLow)/Point; 
   double Res = MarketAverage()*Day_Index; 
   double LongSL = BarLow;
   double ShortSL = BarHigh;
   
      if (Difference<Res){ 
          
         //long signal 
         if ( CandleOpen >= MASlowest1 ) {  
            
            if ( Schaff<25 ){ 
      
               if ( ( (MAslow1 >= MAslow2) && (MAslow2 >= MAslow3) ) || ( ( MAslow2 >= MAslow3) && (MAslow3 >= MAslow4) ) ){ //MA50 musí být rostoucí  
                  //poslední nebo pøedposlední zavøená svíèka musí být vyšší než MA50
                  if (iClose(Symbol(), Period(), 1 )  >= MAslow1 || iClose(Symbol(), Period(), 2 )  >= MAslow2 ) { 
                     if (MA1 >= LongSL){ //podmínka, že SL je pod MA fast
                        Result = 2;
                     }
                  }   
               } 
            }
         }      
         
         //short signal
         if ( CandleOpen <= MASlowest1 ) { 
         
            if ( Schaff>75){  
                 
                if ( ( (MAslow1 <= MAslow2) && (MAslow2 <= MAslow3) ) || ( ( MAslow2 <= MAslow3) && (MAslow3 <= MAslow4) ) ){ //MA50 musí být klesající, nesmí se rovnat  
                  //poslední nebo pøedposlední zavøená svíèka musí být nižší než MA50
                  if (iClose(Symbol(), Period(), 1 )  <= MAslow1 || iClose(Symbol(), Period(), 2 )  <= MAslow2 ) { 
           
                     if (MA1<=ShortSL){ 
                        Result = 1;
                     }
                  }   
               }    
            } 
         }      
      }    
    
return (Result);
}

//upravuje zobrazovaný a odesílaný koeficient
string DisplayCoeficient(){
   string Result;
   if (FinalDecision()==2){   
      Result = "Long";
      } else if (FinalDecision()==1){   
      Result = "Short"; 
      } else 
   Result = "Není signál";
return (Result);
}
 
//nastavení skrytého TP, který uzavøe obchod po jeho pøekonání
//funguje jen pro situace, kde je jen 1 obchod
void HiddenTP() {
   if (UseHiddenTP && IsTradeAllowed() ){
      if ( ( (  SpecificTrades( 0, OP_BUY ) == 1 || SpecificTrades( AutoMagic, OP_BUY ) == 1 ) && SellTradesTotal() == 0) || ( 
      (  SpecificTrades( 0, OP_BUY ) == 0 || SpecificTrades( AutoMagic, OP_BUY ) == 0 ) && SellTradesTotal() == 1)  ){
      
      for(int i=OrdersTotal()-1;i>=0;i--) {
         if (OrderSelect(i, SELECT_BY_POS, MODE_TRADES)){
            if(OrderSymbol() == Symbol()) {
               if (OrderMagicNumber()==0) {
                  if (OrderType()==OP_BUY){
                     if (OrderOpenPrice()+HiddenTPDistance*Point<Ask){
                        Check =OrderClose(OrderTicket(), OrderLots(), Bid, 2, 0);
                        if (Check <0 ) Print ("Select error ", GetLastError());
                        Print ("Obchod " + OrderTicket() + " na páru " +OrderSymbol() + " byl uzavřen skrytým TP!");
                        }  
                     }    
                  if (OrderType()==OP_SELL){
                     if (OrderOpenPrice()-HiddenTPDistance*Point>Bid){
                        Check =OrderClose(OrderTicket(), OrderLots(), Ask, 2, 0);
                        if (Check <0 ) Print ("Select error ", GetLastError());
                        Print ("Obchod " + OrderTicket() + " na páru " +OrderSymbol() + " byl uzavřen skrytým TP!");
                        }
                     }
                  }
               }
            }
         }
      }   
   }      
}

//v poøádku, je zde zapoèítaný i Stoplossadder
string Management(){
   string Result = "---";
   double TradeResult = 0;
   double HighLow = 0;
   double BarHigh = High[iHighest(Symbol(),PERIOD_H1,MODE_HIGH,Hours,1)];   
   double BarLow = Low[iLowest(Symbol(),PERIOD_H1,MODE_LOW,Hours,1)]; 
   double HigherLine = 0;
   double LowerLine = 0;
   
   if ( ObjectFind("H1_Upper_Long")!=-1 ){
      HigherLine = ObjectGet("H1_Upper_Long", OBJPROP_PRICE1);
   } else if ( ObjectFind("H1_Upper_Short")!=-1 ) {
      HigherLine = ObjectGet("H1_Upper_Short", OBJPROP_PRICE1);
   }
   
   if ( ObjectFind("H1_Lower_Long")!=-1 ){
      LowerLine = ObjectGet("H1_Lower_Long", OBJPROP_PRICE1);
   } else if ( ObjectFind("H1_Lower_Short")!=-1 ) {
      LowerLine = ObjectGet("H1_Lower_Short", OBJPROP_PRICE1);
   }
   
   if (HigherLine == 0){ HigherLine = BarHigh; }
   if (LowerLine == 0){  LowerLine = BarLow; }
   
   double H1Limit= MarketAverage()*Day_Index; 
     
      //get relevant extremes distance
      HighLow = MathAbs((HigherLine-LowerLine)/Point);
         
      //overwrite the distace, if it is higher and if there is no trade (to get true moneymanagement)
      if ( Trades()==0 &&  HighLow > H1Limit ) {
         HighLow = H1Limit;
      }
   
      //výpočet lotů
      double RiskedBalance = AccountBalance() * Risk/100;                  
      double TickValue = MarketInfo(Symbol(), MODE_TICKVALUE)/**tvAdjust()*/;
      TradeResult = RiskedBalance /( TickValue*HighLow);
      
      if (TradeResult<(MarketInfo(Symbol(),MODE_MINLOT))){
         TradeResult=MarketInfo(Symbol(),MODE_MINLOT);
      }
   
   Result = DoubleToStr(TradeResult, 2);
         
   return (Result);
}

/* Deletes Trades after X hours
==========================================================*/

void DeleteOldTrades() {
   
      //smazat sell stop, který čeká víc než 12 hodin
   //======================================================
   //pokud existuje limitní obchod
   if ( SellLimitTrades() > 0 || BuyLimitTrades() > 0 ) {
      for(int c=OrdersTotal();c>=0;c--) {
         if(OrderSelect(c,SELECT_BY_POS, MODE_TRADES)) {
            if ( OrderSymbol() == Symbol() ) {
               if(  OrderMagicNumber() == 0 ) {
                  if ( OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT) {
                     if (OrderOpenTime() + HoursSeconds * 12 < TimeCurrent() ) { 
                        Check = OrderDelete(OrderTicket(), Red);
                        if (Check<0) Print ("Order SELLSTOP delete error ", GetLastError());
                        }
                     }
                     if ( OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT ) {  
                        if (OrderOpenTime() + HoursSeconds * 12 < TimeCurrent() ) { 
                           Check = OrderDelete(OrderTicket(), Red);
                           if (Check<0) Print ("Order BUYSTOP delete error ", GetLastError());
                        }
                     }
                  }
               }
            }
        } 
   }   
 
}


void SendMessages() {
   
   if ( FinalDecision() == 1 || FinalDecision() == 2 ){     
            string Myday =  TimeToStr( TimeCurrent()-7200, TIME_DATE );
            string MyMinutes =  TimeToStr( TimeCurrent()-7200, TIME_MINUTES  );
            if (Send_Email){
               SendMail("TRADE SETTER" , "Dobrý den," + 
               "\n Symbol: " + Symbol() + 
               "\n Koeficient: " +DisplayCoeficient() + 
               "\n Čas: " + Myday + " "+ MyMinutes +
               "\n Doporučené množství: " + Management() +
               "\n Hodně štěstí! "); 
            } 
            
             //odešle zprávu na mobil, když se vytvoøí minimální hranice 
             if (Send_Message){
               SendNotification("TRADE SETTER: " + Symbol() +  
               "\n Koeficient: " +DisplayCoeficient() + 
               "\n Čas: " + Myday + " "+ MyMinutes +
               "\n Doporučené množství: " + Management() + 
               "\n Hodně štěstí! "); 
               } 
       } 
}

/*======================================================

returns orderProftit for last trade, 
no matter if Main or Recovery

======================================================*/

double LastHistoryProfit( ){  
   
   double   Result = 0;
   datetime CloseTime = 0;
   
       for( int i=OrdersHistoryTotal()-1;i>=0;i-- ) {
           if ( OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) {
              if (OrderSymbol() == Symbol() && ( OrderMagicNumber() == AutoMagic || 
              OrderMagicNumber() == 0 ) && OrderCloseTime()>CloseTime) {
                 CloseTime = OrderCloseTime();
                 Result = OrderProfit();
              } 
           }
       }
   
       
   return(Result);
}

int LastHistoryType( ){  
   
   int Result = 0;
   datetime CloseTime = 0;
       for( int i=OrdersHistoryTotal()-1;i>=0;i-- ) {
           if ( OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) {
              if (OrderSymbol() == Symbol() && ( OrderMagicNumber() == AutoMagic || 
              OrderMagicNumber() == 0 ) && OrderCloseTime()>CloseTime) {
                 CloseTime = OrderCloseTime();
                 Result = OrderType();
              } 
           }
       }
       
   return(Result);
   
}


double LastHistoryLots( ){  
   
   double   Result = 0;
   datetime CloseTime = 0;
       for( int i=OrdersHistoryTotal()-1;i>=0;i-- ) {
           if ( OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) {
              if (OrderSymbol() == Symbol() && ( OrderMagicNumber() == AutoMagic || 
              OrderMagicNumber() == 0 ) && OrderCloseTime()>CloseTime) {
                 CloseTime = OrderCloseTime();
                 Result = OrderLots();
              } 
           }
       }
       
   return(Result);
   
}


int LastTotalLosingTrades() {
   
   int last=0;

      for(int i=(OrdersHistoryTotal()-1);i>=0;i--)
      {
         if ( OrderSelect(i, SELECT_BY_POS,MODE_HISTORY) ) {
               
            if(OrderSymbol()==Symbol() ) {
               if( OrderProfit() < 0 ) { 
                  last = last+1; 
               } else {
                  break; 
               }
               
            }
         }
      }

return last;
}


double LastTotalLosingTradesUSD() {
   
double last=0;

   for(int i=(OrdersHistoryTotal()-1);i>=0;i--)    {
      if ( OrderSelect(i, SELECT_BY_POS,MODE_HISTORY) ) {
            
         if(OrderSymbol()==Symbol() ) {
               
               if( OrderProfit() < 0 ) { 
                  last = last+OrderProfit(); 
               } else {
                  break; 
               }
            
         }
      }
   } 
      
return last;

}


double LastTotalSequenceTradesUSD() {
   
double last=0;
bool LetFirstThrough = true; 


   
   for(int i=(OrdersHistoryTotal()-1);i>=0;i--)    {
      if ( OrderSelect(i, SELECT_BY_POS,MODE_HISTORY) ) {
            
         if(OrderSymbol()==Symbol() ) {
      
               if( OrderProfit() < 0 || (OrderProfit() > 0 && LetFirstThrough == true) ) { 
                     
                     last = last+OrderProfit();
                     if ( OrderProfit() > 0  ) {
                        LetFirstThrough = false;
                     } 
                     
               } else {
                  break; 
               }
            
         }
      }
   } 
    
return last;
}


//--------------------------------------------------------------------|
//      Initiate                                                      |
//--------------------------------------------------------------------|
  
//nastavení pøi vypínání  
void deinit() {

   //smaže informaèní tabulku vèetnì podkladu
   ObjectDelete(0, "DisplayObdélník");
   ObjectDelete(0, "Smile");
   for (int a=0;a<38;a++){
      ObjectDelete("Text"+ a);
   }
      
   //smaže signály, když není obchod
  /* if ( IsNoTrade() ) { 
      ObjectDelete("H1_Upper_Long");
      ObjectDelete("H1_Lower_Long");
      ObjectDelete("H1_Upper_Short");
      ObjectDelete("H1_Lower_Short");
      ObjectDelete("TP_Short_Area");
      ObjectDelete("TP_Long_Area");
   }*/

   if(Delete_On_Deinit) {
      for(int x=0;x<10;x++) for(int i=0;i<ObjectsTotal();i++) {
         string name=ObjectName(i);
            if(StringSubstr(name,0,5)=="Linie") {
            ObjectDelete(name);
         }
      }
   } 
}

/* Display signals that have been missed
========================================================================*/
void ShowPastSignals() {

   double Res = MarketAverage()*Day_Index;
   
   //open this only in minute 47 and 48
   if ( Minute() >= 47 && Minute() < 49 ) {
      for ( int o=1; o<= LastCandles; o++ ){
         double Schaffi = iCustom (Symbol(), PERIOD_H1, "Schaff_Trend_Cycle" , ShaffQuick, ShaffSlow, Cycle, CountBars, 0, o+1); //aktální síla
         double MA1i = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MAFast, 0,MODE_EMA, 0, o+1), Digits -1);
         double MAslow1i = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, o+1), Digits -1);
         double MAslow2i = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, o+2), Digits -1);
         double MAslow3i = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, o+3), Digits -1);
         double MAslow4i = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlow, 0,MODE_EMA, 0, o+4), Digits -1);
         double MAslowest1 = NormalizeDouble( iMA(Symbol(), PERIOD_H1, MASlowest, 0,MODE_EMA, 0, o+1), Digits -1);
         
         double BarHighi = High[iHighest(Symbol(),PERIOD_H1,MODE_HIGH,Hours,o+1)];   
         double BarLowi = Low[iLowest(Symbol(),PERIOD_H1,MODE_LOW,Hours,o+1)];
         double Differencei = (BarHighi - BarLowi)/Point; 
         Res = MarketAverage()*Day_Index; 
         double LongSLi = BarLowi;
         double ShortSLi = BarHighi;
         
         double BarOpenPrice = iOpen(Symbol(), Period(), o+1);
         datetime BarTime = iTime(Symbol(), Period(), o);
           
         string LabelValue = IntegerToString(o);      
            
         if ( BarTime + LastCandles * HoursSeconds > TimeCurrent() ){    
            if (Differencei<Res){     
      
               if (ObjectFind(0, "Long"+LabelValue) == -1){
                  
                  if ( BarOpenPrice > MAslowest1 ){
                     
                     if ( Schaffi<=25 ){ 
                        if ( ( (MAslow1i > MAslow2i) && (MAslow2i > MAslow3i) ) || ( ( MAslow2i > MAslow3i) && (MAslow3i > MAslow4i) ) ){   
                           //poslední nebo pøedposlední zavøená svíèka musí být vyšší než MA50
                           if (iClose(Symbol(), Period(),o+ 1 )  >= MAslow1i || iClose(Symbol(), Period(), o+2 )  >= MAslow2i ) { 
                              if (MA1i >= LongSLi){ //podmínka, že SL je pod MA faset        
                                 ObjectCreate(0,"Long"+LabelValue,OBJ_ARROW_THUMB_UP,0,Time[o],BarLowi-150*Point );
                                 ObjectSetInteger(0,"Long"+LabelValue,OBJPROP_WIDTH,5);
                                 ObjectSetInteger(0,"Long"+LabelValue,OBJPROP_COLOR,clrLime);
                                 break;
                              }
                           }
                        }   
                     }
                  }    
               }   
         
      
               if (ObjectFind(0, "Short"+LabelValue) == -1){  
               
                  if ( BarOpenPrice < MAslowest1 ){ 
                     if ( Schaffi>=75){          
                     //nastavení short obchodu 
                     if ( ( (MAslow1i < MAslow2i) && (MAslow2i < MAslow3i) ) || ( ( MAslow2i < MAslow3i) && (MAslow3i < MAslow4i) ) ){
                      //MA50 musí být klesající, nesmí se rovnat  
                        //poslední nebo pøedposlední zavøená svíèka musí být nižší než MA50
                        if (iClose(Symbol(), Period(), o+1 )  <= MAslow1i || iClose(Symbol(), Period(), o+2 )  <= MAslow2i ) { 
                           if (MA1i<=ShortSLi){                         
                                 LabelValue = IntegerToString(o);
                                 ObjectCreate(0,"Short"+LabelValue,OBJ_ARROW_THUMB_DOWN,0,Time[o],BarHighi+150*Point );
                                 ObjectSetInteger(0,"Short"+LabelValue,OBJPROP_WIDTH,5);
                                 ObjectSetInteger(0,"Short"+LabelValue,OBJPROP_COLOR,clrRed);
                                 break;
                              }
                           }
                        }   
                     } 
                  }      
               }    
            } 
         }      
         //mazání objektů, pokud jsou starší než LastCandles hodin
         if (ObjectFind(0, "Long"+LabelValue) != -1){   
            if ( ObjectGet("Long"+LabelValue, OBJPROP_TIME1)+ HoursSeconds*(LastCandles + 48 ) < TimeCurrent() ){
               ObjectDelete("Long"+LabelValue);
            }    
         }
         if (ObjectFind(0, "Short"+LabelValue) != -1){   
            if ( ObjectGet("Short"+LabelValue, OBJPROP_TIME1)+ HoursSeconds*(LastCandles + 48)  < TimeCurrent() ){
               ObjectDelete("Short"+LabelValue);
            }    
         }
      }
   }
}


void CreateH1LinesLong(double BarHigh, double BarLow){

  //vytvoøení            
  ObjectCreate("H1_Upper_Long", OBJ_TREND, 0, Time[FirstCandle], BarHigh, Time[FirstCandle+Hours],BarHigh, 0, 0);  
  ObjectSet("H1_Upper_Long", OBJPROP_COLOR, Lime);
  ObjectSet("H1_Upper_Long", OBJPROP_WIDTH, Width);
  ObjectSet("H1_Upper_Long", OBJPROP_RAY, false);
  //vytvoøení H1_LowerLine
  ObjectCreate("H1_Lower_Long", OBJ_TREND, 0, Time[FirstCandle], BarLow, Time[FirstCandle+Hours], BarLow, 0, 0);  
  ObjectSet("H1_Lower_Long", OBJPROP_COLOR, Lime);
  ObjectSet("H1_Lower_Long", OBJPROP_RAY, false);
  ObjectSet("H1_Lower_Long", OBJPROP_WIDTH, Width);
  
}

void CreateH1LinesShort(double BarHigh, double BarLow){
         //vytvoøení        
         ObjectCreate("H1_Upper_Short", OBJ_TREND, 0, Time[FirstCandle], BarHigh,Time[FirstCandle+Hours], BarHigh, 0, 0);     
         ObjectSet("H1_Upper_Short", OBJPROP_COLOR, Red);
         ObjectSet("H1_Upper_Short", OBJPROP_WIDTH, Width);
         ObjectSet("H1_Upper_Short", OBJPROP_RAY, false);
         //vytvoøení H1_LowerLine
          
         ObjectCreate("H1_Lower_Short",OBJ_TREND,0,Time[FirstCandle],BarLow, Time[FirstCandle+Hours], BarLow );
         ObjectSet("H1_Lower_Short", OBJPROP_RAY, false);
         ObjectSet("H1_Lower_Short", OBJPROP_COLOR, Red);
         ObjectSet("H1_Lower_Short", OBJPROP_WIDTH, Width);
            
}

//create long square
void CreateLongSquare( int TimeShift1, int TimeShift2, double HigherLine, double Lowerline, double TPDistance ) {

   ObjectCreate("TP_Long_Area", OBJ_RECTANGLE, 0, Time[1],HigherLine,Time[4],HigherLine+TPDistance);
   ObjectSet("TP_Long_Area",OBJPROP_COLOR, Lime);

}

//create short squate
void CreateShortSquare( int TimeShift1, int TimeShift2, double HigherLine, double LowerLine, double TPDistance ) {

   ObjectCreate("TP_Short_Area", OBJ_RECTANGLE, 0, Time[1],LowerLine,Time[4],LowerLine-TPDistance);
   ObjectSet("TP_Short_Area",OBJPROP_COLOR, Red);

}

//create exit lines
void CreateExitLines(double HigherLine, double LowerLine, double HighLow){

   double ShortExit = LowerLine - HighLow*TakeProfitCount;
   double LongExit = HigherLine + HighLow*TakeProfitCount;

   //create lines
   if ( LinesAreSet() ) {
      //if ( HigherLine > 0 && LowerLine > 0 ) {
         if ( ObjectFind("Long_Exit")== -1 && ObjectFind("Short_Exit")== -1 ) {  
            
            ObjectCreate("Long_Exit",OBJ_HLINE,0,Time[0], LongExit);
            ObjectSet("Long_Exit",OBJPROP_COLOR,Blue); 
            
            ObjectCreate("Short_Exit",OBJ_HLINE,0,Time[0],ShortExit);
            ObjectSet("Short_Exit",OBJPROP_COLOR,Blue); 
         }
      //}
   }

}

//check if H1 lines are set
bool LinesAreSet(){
   
   bool Result = false;
   if ( (ObjectFind("H1_Upper_Long")!=-1 && ObjectFind("H1_Lower_Long")!=-1) || ( ObjectFind("H1_Upper_Short") !=-1 && ObjectFind("H1_Lower_Short") != -1 ) ) {
      Result = true;
   } 
   
return Result;
}

//forbid closing trades on Monday and late Friday
bool ForbidLate(){
   
   bool Result = true;   
   if ( DayOfWeek()==0 || DayOfWeek()==1 )  {
   
      if ( Hour()==0 ){
         Result = false;
      }
   //if it is friday
   } else if ( DayOfWeek()==5 ) {
      if ( Hour()>=23 ){ 
         Result = false;
      }
   }  
return Result;

}

//delete long lines
void deleteLongH1Lines(){

   if ( ObjectFind(0, "H1_Upper_Long")!=-1 && ObjectFind(0, "H1_Lower_Long")!=-1 ) {
                  //smazat linie
       ObjectDelete("H1_Upper_Long");
       ObjectDelete("H1_Lower_Long");
       //reset variables
       /*GlobalVariableSet( Symbol()+ "_H1_Upper_Long", 0 );
       GlobalVariableSet( Symbol()+ "_H1_Lower_Long", 0 );*/
   }
   
   if (ObjectFind(0, "TP_Long_Area")!=-1){
            ObjectDelete(0,"TP_Long_Area");
   }
                  
   if (ObjectFind(0, "BEP_Long_Exit")!=-1){
        ObjectDelete(0,"BEP_Long_Exit");
   }

}

void deleteShortH1Lines(){
    
    if ( ObjectFind(0, "H1_Upper_Short")!=-1 && ObjectFind(0, "H1_Lower_Short")!=-1 ) {
                  //smazat linie
                  ObjectDelete("H1_Upper_Short");
                  ObjectDelete("H1_Lower_Short");
                  //reset variables
                  /*GlobalVariableSet( Symbol()+ "_H1_Upper_Short", 0 );
                  GlobalVariableSet( Symbol()+ "_H1_Lower_Short", 0 );*/
    }
    
    if ( ObjectFind("H1_Upper_Short")==-1 && ObjectFind("H1_Lower_Short")==-1  ) {
         //Short TP obdélník  
         if (ObjectFind(0, "TP_Short_Area")!=-1){
            ObjectDelete(0,"TP_Short_Area");
         }   
         //Short SL obdélník
         if (ObjectFind(0, "BEP_Short_Exit")!=-1){
            ObjectDelete(0,"BEP_Short_Exit");
         }
    }

}

//--------------------------------------------------------------------|
//      hlavní tìlo strategie                                         |
//--------------------------------------------------------------------|

void OnTick() {

//execute all functions
//TraderProtection();

DeleteOldTrades();
ShowPastSignals();

double HigherLine;
double LowerLine;
int HigherLineTime2 = 0;
int LowerLineTime2 = 0;
datetime H1ObjectCreated;
double H1Limit= MarketAverage()*Day_Index; 
double Tickvalue = MarketInfo(Symbol(),MODE_TICKVALUE);
double BarHigh = High[iHighest(Symbol(),PERIOD_H1,MODE_HIGH,Hours,1)];   
double BarLow = Low[iLowest(Symbol(),PERIOD_H1,MODE_LOW,Hours,1)]; 
double LongExit = ObjectGet("Long_Exit", OBJPROP_PRICE1); 
double ShortExit = ObjectGet("Short_Exit", OBJPROP_PRICE1); 

RefreshRates();
//get higher line value
if ( ObjectFind("H1_Upper_Long")!=-1 ){
   HigherLine = ObjectGet("H1_Upper_Long", OBJPROP_PRICE1);
} else if ( ObjectFind("H1_Upper_Short")!=-1 ) {
   HigherLine = ObjectGet("H1_Upper_Short", OBJPROP_PRICE1);
}

if ( ObjectFind("H1_Lower_Long")!=-1 ){
   LowerLine = ObjectGet("H1_Lower_Long", OBJPROP_PRICE1);
   LowerLineTime2 = ObjectGet("H1_Lower_Long", OBJPROP_TIME2);
   H1ObjectCreated = ObjectGet("H1_Lower_Long", OBJPROP_TIME1);
} else if ( ObjectFind("H1_Lower_Short")!=-1 ) {
   LowerLine = ObjectGet("H1_Lower_Short", OBJPROP_PRICE1);
   LowerLineTime2 = ObjectGet("H1_Lower_Short", OBJPROP_TIME2);
   H1ObjectCreated = ObjectGet("H1_Lower_Short", OBJPROP_TIME1);
}

if (HigherLine <= 0){ HigherLine = BarHigh; }
if (LowerLine <= 0){ LowerLine = BarLow; }
double HighLow = MathAbs((HigherLine-LowerLine));

//posunutí prvního objektu
int TimeShift1 =  MathAbs(iBarShift( Symbol(), PERIOD_H1, H1ObjectCreated ));  
int TimeShift2 = MathAbs( TimeShift1 + Hours );  

//height of TP square
double TPDistance = MarketAverage()*Coef*Point; 

//if we are on the right period
if ( Period() == PERIOD_H1 ) {

   //if there is not trade
   if ( IsNoTrade() ) {
   
      if( (ObjectFind("H1_Upper_Long")==-1 && ObjectFind("H1_Lower_Long")==-1) && (ObjectFind("H1_Upper_Short")==-1 && ObjectFind("H1_Lower_Long")==-1)  ) { 
   
         //long trade
         if ( FinalDecision()==2 ) {
            
            //create H1 lines long         
            CreateH1LinesLong(BarHigh, BarLow);   
            //send the messages      
            SendMessages();
         
         } else if ( FinalDecision()==1 ) {
                  
            //create H1 lines short 
            CreateH1LinesShort( BarHigh, BarLow);
            //send the messages
            SendMessages();
             
         } 
      //create outer lines and green square
      } else {
      
         //long
         if ( SpecificTrades( 0, OP_BUY ) || SpecificTrades( 0, OP_BUYSTOP ) || SpecificTrades( 0, OP_BUYLIMIT )  ) {
         
            CreateLongSquare(TimeShift1, TimeShift2, HigherLine, LowerLine, TPDistance);   
            
         }
         
         //short                  
         if ( SpecificTrades( 0, OP_SELL ) ||SpecificTrades( 0, OP_SELLSTOP ) || SpecificTrades( 0, OP_SELLLIMIT ) ) {
         
            CreateShortSquare(TimeShift1, TimeShift2, HigherLine, LowerLine, TPDistance); 
            
         }  
      
      }
  
   //there are trades
   } else {
         
      //create lines based on trade type
      if ( SpecificTrades( 0, OP_BUY ) || SpecificTrades( 0, OP_BUYSTOP ) || SpecificTrades( 0, OP_BUYLIMIT )  ) {
      
         CreateH1LinesLong(BarHigh, BarLow);
         
         if ( LinesAreSet() ) {
            
            CreateLongSquare(TimeShift1, TimeShift2, HigherLine, LowerLine, TPDistance);  
            
            CreateExitLines( HigherLine, LowerLine, HighLow );
         }
      
      } else if ( SpecificTrades( 0, OP_SELL ) ||SpecificTrades( 0, OP_SELLSTOP ) || SpecificTrades( 0, OP_SELLLIMIT ) ) {
      
         CreateH1LinesShort(BarHigh, BarLow); 
         
         if ( LinesAreSet() ) {
         
            CreateShortSquare(TimeShift1, TimeShift2, HigherLine, LowerLine, TPDistance); 
            
            CreateExitLines( HigherLine, LowerLine, HighLow );
         }
            
      } 

   }

}

//modifikace hranic tam, kde je otevřený obchod na jiném místě než je běžné a je potřeba to posunout, ale už neovlivňuje další obchody
   if ( IsNoTrade() == false && LastTotalLosingTrades()==0 ) {

      if ( (ObjectFind("H1_Upper_Long")!=-1 && ObjectFind("H1_Lower_Long")!=-1 ) ) {

         if ( GetCurrentTradeDetails( "openprice" ) != BarHigh && GetCurrentTradeDetails( "openprice" ) != 0 ) {
 
              ObjectSet("H1_Upper_Long",OBJPROP_PRICE1, GetCurrentTradeDetails( "openprice" ) );
              ObjectSet("H1_Upper_Long",OBJPROP_PRICE2, GetCurrentTradeDetails( "openprice" ) );
         }
         
      } else if ( (ObjectFind("H1_Upper_Short")!=-1 && ObjectFind("H1_Lower_Short")!=-1) ) {
      
         if ( GetCurrentTradeDetails( "openprice" ) != BarLow && GetCurrentTradeDetails( "openprice" ) != 0 ) {
 
              ObjectSet("H1_Lower_Short",OBJPROP_PRICE1, GetCurrentTradeDetails( "openprice" ) );
              ObjectSet("H1_Lower_Short",OBJPROP_PRICE2,  GetCurrentTradeDetails( "openprice" ) );
         }
      
      }
   
   }  
   
   //modifikace zeleného čtverce tak, aby vždycky seděl na horní nebo dolní hranici
   if ( (ObjectFind("H1_Upper_Long")!=-1 && ObjectFind("H1_Lower_Long")!=-1) && ObjectFind("TP_Long_Area")!=-1 ) {
   
         //dolní hodnota buy čtverce se nerovná H1_Upper_long
         if ( ObjectGet("TP_Long_Area", OBJPROP_PRICE1) != ObjectGet("H1_Upper_Long", OBJPROP_PRICE1)  ) {
    
            //get the distance between top and bottom
            double LongArea = NormalizeDouble( ObjectGet("TP_Long_Area", OBJPROP_PRICE1), Digits ) - NormalizeDouble( ObjectGet("TP_Long_Area", OBJPROP_PRICE2), Digits );
            
            ObjectSet("TP_Long_Area",OBJPROP_PRICE1, NormalizeDouble( ObjectGet("H1_Upper_Long", OBJPROP_PRICE1), Digits ) );
            ObjectSet("TP_Long_Area",OBJPROP_PRICE2, NormalizeDouble( ObjectGet("H1_Upper_Long", OBJPROP_PRICE1) + MathAbs(LongArea), Digits ) );
              
         }
         
   } else if ( (ObjectFind("H1_Upper_Short")!=-1 && ObjectFind("H1_Lower_Short")!=-1)  && ObjectFind("TP_Short_Area")!=-1 ) {
      
         //dolní hodnota buy čtverce se nerovná H1_Upper_long
         if ( ObjectGet("TP_Short_Area", OBJPROP_PRICE1) != ObjectGet("H1_Lower_Short", OBJPROP_PRICE1)  ) {
    
            //get the distance between top and bottom
            double ShortArea = NormalizeDouble( ObjectGet("TP_Short_Area", OBJPROP_PRICE1), Digits ) - NormalizeDouble( ObjectGet("TP_Short_Area", OBJPROP_PRICE2), Digits );
            
            ObjectSet("TP_Short_Area",OBJPROP_PRICE1, NormalizeDouble( ObjectGet("H1_Lower_Short", OBJPROP_PRICE1) - MathAbs(ShortArea), Digits ) );
            ObjectSet("TP_Short_Area",OBJPROP_PRICE2, NormalizeDouble( ObjectGet("H1_Lower_Short", OBJPROP_PRICE1), Digits ) );
              
         }
      
   }

//set exit lines based on H1 lines and make them match

double UpperDistance  =  MathAbs(LongExit - HigherLine);
double BuyFixedSL = MathAbs( LowerLine - UpperDistance);
double LowerDistance  =  MathAbs(LowerLine - ShortExit);
double SellFixedSL = MathAbs(HigherLine + LowerDistance);
  
if ( LinesAreSet() ) {    
        
   if (ShortExit > 0 && LongExit > 0 ) {
   
      if ( LongExit !=  SellFixedSL ) {
      
         if ( SellTradesTotal()==1 || SellLimitTrades() == 1 ) {
            ObjectSet ("Long_Exit", OBJPROP_PRICE1, SellFixedSL);
         }
         
      }
      
      if (ShortExit !=  BuyFixedSL){
         
         if ( (  SpecificTrades( 0, OP_BUY ) == 1 || SpecificTrades( AutoMagic, OP_BUY ) == 1 ) || BuyLimitTrades() == 1 ){
               ObjectSet ("Short_Exit", OBJPROP_PRICE1, BuyFixedSL);
         }
      }
   }   
      
}
 
  
//delete lines
if ( LastHistoryProfit( ) > 0 && IsNoTrade() ) {

   //we can delete lines
   //pokud není signál tak smaž hranice
   if ( FinalDecision()==0 && LinesAreSet() ) {
   
      //delete long lines
      deleteLongH1Lines();
                  
      //delete short lines            
      deleteShortH1Lines();
             
      //mazání exit hranic
      if ( ObjectFind("Long_Exit")!= -1  ) { 
         ObjectDelete(0, "Long_Exit"); 
      }
         
      if ( ObjectFind("Short_Exit")!= -1 ) {
         ObjectDelete(0, "Short_Exit");
      }  
   
   } 
   
   //delete squares
   if ( ( ObjectFind("H1_Upper_Long")==-1 && ObjectFind("H1_Lower_Long")==-1 )  ){   
         
         if (ObjectFind(0, "TP_Long_Area")!=-1){
            ObjectDelete(0,"TP_Long_Area");
         }
                  
         if (ObjectFind(0, "BEP_Long_Exit")!=-1){
            ObjectDelete(0,"BEP_Long_Exit");
         }
      }   
     
    //delete squares  
    if ( ObjectFind("H1_Upper_Short")==-1 && ObjectFind("H1_Lower_Short")==-1  ) {
         //Short TP obdélník  
         if (ObjectFind(0, "TP_Short_Area")!=-1){
            ObjectDelete(0,"TP_Short_Area");
         }   
         //Short SL obdélník
         if (ObjectFind(0, "BEP_Short_Exit")!=-1){
            ObjectDelete(0,"BEP_Short_Exit");
         }
    } 

}   
//delete old signals, if they are left from other programs or trades
if ( IsNoTrade() ) { 

   if ( LastHistoryProfit() > 0 || GlobalVariableGet( Symbol()+ "_Closed" ) == 0 ) {  
      
      if ( LinesAreSet() ) {
         //if it is more than 16 hours ago   
         if ( H1ObjectCreated + HoursSeconds * 16 < TimeCurrent() ) {
      
            deleteLongH1Lines();
            
            deleteShortH1Lines();
            
         }
         
      }
   
   }
   
}   
  
//delete exit lines
if ( LinesAreSet()==0 && IsNoTrade() ) {
   
   if ( ObjectFind("Long_Exit")!= -1  ) { 
      ObjectDelete(0, "Long_Exit"); 
   }
      
   if ( ObjectFind("Short_Exit")!= -1 ) {
      ObjectDelete(0, "Short_Exit");
   } 
} 
  
RefreshRates(); 
  
//pokud aplikujeme NO LOSS   
if ( NoLoss ){ 
   
   double SmallLots   = 0.01;
   double NewTradeLots;
   double Distance2;
   
   
   if ( LastHistoryLots()!=0 && ( (LongExit!=0 && HigherLine != 0 ) || (LowerLine!=0 && ShortExit != 0 ) ) ) {
   
      if ( LastHistoryType( )== OP_BUY ) {
      
         Distance2 = (LowerLine - ShortExit) / Point;
         if ( Distance2 != 0 ) {
            NewTradeLots =  MathAbs ( LastTotalLosingTradesUSD() ) / ( Tickvalue * Distance2 );
         }
      
      } else {
 
         Distance2 = (LongExit - HigherLine) / Point;
         if ( Distance2 != 0 ) {
            NewTradeLots =  MathAbs ( LastTotalLosingTradesUSD() ) / ( Tickvalue * Distance2 );
         }
         
      }
   
   } 
   //clean new lots
   NewTradeLots  = MathCeil( NewTradeLots  / SmallLots) * SmallLots;
   //if ( NewTradeLots < MarketInfo(Symbol(),MODE_MINLOT) ) { NewTradeLots = MarketInfo(Symbol(),MODE_MINLOT); }
   NewTradeLots = NormalizeDouble( NewTradeLots, Digits );
         
     
   /* Otevírání opačných obchodů při zrátě
   ================================================*/
   if ( Symbol()=="GBPCHF" )Print ("NewTradeLots ", NewTradeLots );
   
   if ( IsTradeAllowed() ){ 
   
      //this is important, it works only if there is one trade at the moment
      if ( Trades()==1 ) {   
               
         //sekce zavírání obchodů vyšších neš longexit a nebo short exit
         if ( SpreadCheck() && LinesAreSet() ) {  
                          
            if ( LongExit > 0 && ShortExit > 0)  { 
                     
                  for(int fl=OrdersTotal()-1;fl>=0;fl--) {
              
                     if( OrderSelect(fl,SELECT_BY_POS, MODE_TRADES) ) { 
                              
                        if (OrderSymbol() == Symbol() ) {
                            
                            if ( OrderMagicNumber() == 0 ||  OrderMagicNumber() == AutoMagic ) { 
                              //handle long trades
                              if ( OrderType()==OP_BUY ){
                              
                                 if (Bid > LongExit ){
                                 
                                    if ( BreakEven == true ) {  
                                    
                                       if ( OrderStopLoss()!=OrderOpenPrice()){
                                           Check = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, NULL); 
                                           if (Check<0) Print ("Modify order error ", GetLastError());                                 
                                       } 
                                       
                                    }  else {
                                  
                                       Check =OrderClose(OrderTicket(), OrderLots(), Bid, 2, 0);
                                       if (Check <0 ) Print ("Select error ", GetLastError());
                                                   
                                    }
                                    
                                 } 
                              //handle short trades   
                              } else if (OrderType()==OP_SELL ){
                              
                                 if (Ask < ShortExit ){ 
                                    
                                    if ( BreakEven == true ) {
                                      
                                       if ( OrderStopLoss()!=OrderOpenPrice()){
                                               
                                           Check = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, NULL); 
                                           if (Check<0) Print ("Modify order error ", GetLastError());
                                       } 
                                    } else {
                                    
                                       Check =OrderClose(OrderTicket(), OrderLots(), Ask, 2, 0);
                                       if (Check <0 ) Print ("Select error ", GetLastError());
                                    
                                    }  
                                     
                                 }  
                              
                              }
                           }
                        }
                     }     
                  }
               } 
         } 
      
      } //end Trades()==1    
       
      /* Tato sekce uzavírá obchody ve ztrátě 
      ==================================================*/    
      if ( ForbidLate() ) {
      
         if ( LinesAreSet() ) { 
            
            if ( SpecificTrades( 0, OP_BUY ) > 0 || SpecificTrades( AutoMagic, OP_BUY ) > 0 ||  SpecificTrades( 0, OP_SELL ) > 0 || SpecificTrades( AutoMagic, OP_SELL ) > 0  ) {   
               
               for(int x=OrdersTotal()-1;x>=0;x--) {
                        
                  if(OrderSelect(x,SELECT_BY_POS, MODE_TRADES)) {
                       
                     if( OrderMagicNumber() == 0 || OrderMagicNumber() == AutoMagic ) { 
                  
                         if( OrderSymbol()==Symbol()  ) { 
                         
                           //buy sekce
                           if ( OrderType()==OP_BUY ) {
                           
                           //jsme ve ztrátě a protla se hranice h1
                              if (  Bid < LowerLine ) {
                                
                                 Check =OrderClose(OrderTicket(), OrderLots(), Bid, 2, 0);
                                 
                                 //obchod se nepovedlo zavřít
                                 if (Check <0 ) { 
                                    Print ("Order close error ", GetLastError());     
                                    } else {
                                    GlobalVariableSet( Symbol()+ "_Closed", -1 );
                                 }
                              
                              }
                           
                           }
                           
                           //SELL sekce
                           if ( OrderType()==OP_SELL ) {
                              //jsme ve ztrátě a protla se hranice h1
                              if ( Ask > HigherLine ) {
                                                  
                                 Check = OrderClose(OrderTicket(), OrderLots(), Ask, 2, 0);
                                 
                                 //obchod se nepovedlo zavřít
                                 if (Check <0 ) {   
                                    Print ("Order close error ", GetLastError());  
                                    } else { 
                                    //byla to ztráta, nastavíme signál na ztrátu
                                    GlobalVariableSet( Symbol()+ "_Closed", -1 );  
                                 }
                              
                              }
                           
                           } 
                                
                         } 
                          
                     } 
                  }
               }    
            }
         }
      }   
      

      //tato sekce otevírá nové obchody na opačné straně   
      if ( IsNoTrade () && LinesAreSet()  ){
      
            if ( HigherLine > 0 && LowerLine > 0 && LinesAreSet() ) {  
            
               if ( NewTradeLots > 0 ) {
            
                  //přechozí obchod je ztrátový  
                  if ( GlobalVariableGet( Symbol()+ "_Closed" ) == -1 && LastHistoryProfit()<0  ) {
                  
                     //varování, pokud je zde 6 ztrátových obchodů v řadě, odešle email nebo notification
                     if ( LastTotalLosingTrades() == 6 ) {
                        if (Send_Email){ SendMail("TRADE SETTER" , "POZOR! Na měnovém páru " + Symbol()+ " už máš otevřeno 6 ztrátových obchodů!" ); }            
                        if (Send_Message){ SendNotification("POZOR! Na měnovém páru " + Symbol() + " už máš otevřeno 6 ztrátových obchodů!");  } 
                     }
                     
                     if ( LastHistoryType( )== OP_BUY ) {
                     
                        Check = OrderSend(Symbol(), OP_SELL, NewTradeLots, Bid, Slippage, 0, 0, "Recovery", AutoMagic, 0, Red); 
                        if (Check<0) { 
                          Print ("Opening new SELLSTOP trade error ", GetLastError());
                        } else {
                        
                        //vynulovat signalizaci ztrátových obchodů (vyřeší problém s manuálním uzavřením obchodu)
                           GlobalVariableSet( Symbol()+ "_Closed", 0 ); 
                        }
                        
                     } else {
                     
                        Check = OrderSend(Symbol(), OP_BUY, NewTradeLots, Ask, Slippage, 0, 0, "Recovery", AutoMagic, 0, Red); 
                        if (Check<0) {
                        Print ("Opening new SELLSTOP trade error ", GetLastError());
                        } else {
                        //vynulovat signalizaci ztrátových obchodů (vyřeší problém s manuálním uzavřením obchodu)
                          GlobalVariableSet( Symbol()+ "_Closed", 0 ); 
                        }
                     
                     }  
                     
                  }
                  
               }   
               
            }   
            
         } 
     
      }
      
} //end istradeallowed 

/* Sekce mazani h1 linii
===========================*/     
           /*
   if ( Delete_Lines==true && ForbidLate==true){
   
      if (  IsNoTrade() ){   
        
         datetime SellObjectCreated = 0;
         int SellShift=0;
         int BuyShift=0;
         //pokud není signál tak smaž hranice
         if ( FinalDecision()==0 && ( ObjectFind(0, "H1_Upper_Long")!=-1 || ObjectFind(0, "H1_Upper_Short")!=-1 ) ) {
        
            //odstraní starý signál, pokud je předchozí obchod ziskový a nebo sekvence je zisková
            if ( GlobalVariableGet( Symbol()+ "_Closed" )!=-1 || LastHistoryProfit() >= 0 ) {
               if ( ObjectFind(0, "H1_Upper_Long")!=-1 && ObjectFind(0, "H1_Lower_Long")!=-1 ) {
                  //smazat linie
                  ObjectDelete("H1_Upper_Long");
                  ObjectDelete("H1_Lower_Long");
                  //reset variables
                  GlobalVariableSet( Symbol()+ "_H1_Upper_Long", 0 );
                  GlobalVariableSet( Symbol()+ "_H1_Lower_Long", 0 );
               }
               if ( ObjectFind(0, "H1_Upper_Short")!=-1 && ObjectFind(0, "H1_Lower_Short")!=-1 ) {
                  //smazat linie
                  ObjectDelete("H1_Upper_Short");
                  ObjectDelete("H1_Lower_Short");
                  //reset variables
                  GlobalVariableSet( Symbol()+ "_H1_Upper_Short", 0 );
                  GlobalVariableSet( Symbol()+ "_H1_Lower_Short", 0 );
               }
            }
         } 
         
         if (FinalDecision()==1  ) {
         
            //existuje long obdélník     
            if ( ObjectFind(0, "TP_Long_Area")!=-1 && ObjectFind(0, "H1_Upper_Long")!=-1 && ObjectFind(0, "H1_Lower_Long")!=-1 ){
               ObjectCreated = ObjectGet("TP_Long_Area", OBJPROP_TIME1);

               BuyShift=iBarShift(Symbol(),PERIOD_H1,ObjectCreated);
               
               //pokud existují hranice označující nastavení obchodu
               if ( GlobalVariableGet( Symbol()+ "_Closed" )!=-1 && BuyShift > Hours ) {
                  
                  ObjectDelete("H1_Upper_Long");
                  ObjectDelete("H1_Lower_Long");

               }
        
            } 
         //pokud je protisignál
         } else {
            
            if ( ObjectFind(0, "H1_Upper_Long")!=-1 && ObjectFind(0, "H1_Lower_Long")!=-1  ) {
               ObjectCreated = ObjectGet("H1_Upper_Long", OBJPROP_TIME1);
               BuyShift=iBarShift(Symbol(),PERIOD_H1,ObjectCreated);
               
               if ( GlobalVariableGet( Symbol()+ "_Closed" )!=-1 ) {
                  
                  if ( BuyShift > Hours ) {
                     ObjectDelete("H1_Upper_Long");
                     ObjectDelete("H1_Lower_Long");
                  }
               }
            }
            
         }
       
         //short sekvence (kontrola ze existuje informace o case higherline)
         if ( FinalDecision()==2 ){
            
           //pokud existují hranice označující nastavení obchodu
           if ( ObjectFind(0, "TP_Short_Area")!=-1 && ObjectFind(0, "H1_Upper_Short")!=-1 && ObjectFind(0, "H1_Lower_Short")!=-1 ) {               
               SellObjectCreated = ObjectGet("H1_Upper_Short", OBJPROP_TIME1);
               SellShift=iBarShift(Symbol(),PERIOD_H1, SellObjectCreated);

               if ( GlobalVariableGet( Symbol()+ "_Closed" )!=-1 && SellShift > Hours ) {
                   
                   ObjectDelete("H1_Upper_Short");
                   ObjectDelete("H1_Lower_Short");
                        
               }

            } 
         }  else {
              
            if ( ObjectFind(0, "H1_Upper_Short")!=-1 && ObjectFind(0, "H1_Lower_Short")!=-1 ) {
               SellObjectCreated = ObjectGet("H1_Upper_Short", OBJPROP_TIME1);
               SellShift=iBarShift(Symbol(),PERIOD_H1, SellObjectCreated);

               if ( SellShift > Hours ){
                  if ( GlobalVariableGet( Symbol()+ "_Closed" )!=-1 ) {
                     ObjectDelete("H1_Upper_Short");
                     ObjectDelete("H1_Lower_Short");
                  }
                  
               }
            }
         } 
      } 
   }
} 
*/
/* aktualizace ctvercu
==================================================*/
//úprava nastavení TP area

/*
   
if (StopLoss==0 && TakeProfit==0) double LossAdder = MarketAverage()*StopLossCoeficient;
if (LowerLine==0) LowerLine = Low[iLowest(Symbol(),PERIOD_H1,MODE_LOW,Hours,1)]; 
if (HigherLine==0) HigherLine = High[iHighest(Symbol(),PERIOD_H1,MODE_HIGH,Hours,1)];  
double HighLow = MathAbs((HigherLine-LowerLine));
double H1Limit= MarketAverage()*Day_Index; 
double Tickvalue = MarketInfo(Symbol(),MODE_TICKVALUE);

//get the information from last selected trades
datetime lastOpen = 0;                                   
int lastCloseTime = 0;
int curCloseTime = 0;  
double FinalShortSL = HigherLine+LossAdder*Point;
double Distance =  NormalizeDouble( MathAbs( (HighLow*TakeProfitCount) ) ,Digits);                              
double FinalLongSL = LowerLine-LossAdder*Point;

//pokud je aktivovaná ochrana 
//if there is a trade
if ( !IsNoTrade() ) {
   for(int i=OrdersTotal()-1;i>=0;i--) {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol()==Symbol() && (OrderMagicNumber() == 0 || OrderMagicNumber() == AutoMagic)) {
            
               //Pokud jsou to nákupní obchody
               if(OrderType()==OP_BUYSTOP || OrderType()==OP_BUY) { 
                                                 
                  double LongPosition = OrderOpenPrice()+NormalizeDouble(HighLow*TakeProfitCount,Digits);
                  //zabezpečení minimální vzdálenosti
                  if ( OrderOpenPrice() + MarketAverage()*Point*MinDistanceCoef < LongPosition ) {
                     LongPosition = OrderOpenPrice() + MarketAverage()*Point*MinDistanceCoef;
                  } 
                  
                  //create lines
                  if ( ObjectFind("Long_Exit")== -1 ) {  
                     ObjectCreate("Long_Exit",OBJ_HLINE,0,Time[0], LongPosition);
                     ObjectSet("Long_Exit",OBJPROP_COLOR,Blue); 
                  }

                  if ( ObjectFind("Short_Exit")== -1 ) {
                     ObjectCreate("Short_Exit",OBJ_HLINE,0,Time[0], FinalLongSL);
                     ObjectSet("Short_Exit",OBJPROP_COLOR,Blue); 
                  }  
                  
                  if (BreakEven==true) {
                     ObjectCreate("BEP_Long_Exit",OBJ_HLINE,0,Time[0], LongPosition + BreakEvenLevel*Point);
                     ObjectSet("BEP_Long_Exit",OBJPROP_COLOR,Blue); 
                     ObjectSet("Long_Exit",OBJPROP_COLOR,Green); 
                  }
                  
               }
               //pokud jsou to prodejní obchody
               if(OrderType()==OP_SELLSTOP || OrderType()==OP_SELL) {
                  double ShortPosition = OrderOpenPrice()-NormalizeDouble(HighLow*TakeProfitCount,Digits);
                  //zabezpečení minimální vzdálenosti
                  if ( OrderOpenPrice() - MarketAverage()*Point*MinDistanceCoef < ShortPosition ) {
                     ShortPosition = OrderOpenPrice()- MarketAverage()*Point*MinDistanceCoef;
                  } 
                  
                 //create lines
                  if ( ObjectFind("Long_Exit")== -1 ) {
                     ObjectCreate("Long_Exit",OBJ_HLINE,0,Time[0], FinalShortSL);
                     ObjectSet("Long_Exit",OBJPROP_COLOR,Blue); 
                  }
                  
                  if ( ObjectFind("Short_Exit")== -1 ) {
                     ObjectCreate("Short_Exit",OBJ_HLINE,0,Time[0], ShortPosition);
                     ObjectSet("Short_Exit",OBJPROP_COLOR,Blue); 
                  } 
                  
                  if (BreakEven==true) {
                     ObjectCreate("BEP_Short_Exit",OBJ_HLINE,0,Time[0], ShortPosition - BreakEvenLevel*Point);
                     ObjectSet("BEP_Short_Exit",OBJPROP_COLOR,Blue); 
                     ObjectSet("Short_Exit",OBJPROP_COLOR,Green); 
                  }

               }
               
         }
      }
   }
}

     
   
   //sekce smazání obchodù ve chvíli, kdy je pùvodní obchod uzavøený   
   double NewShortExit = ObjectGet("BEP_Short_Exit", OBJPROP_PRICE1);
   double  NewLongExit = ObjectGet("BEP_Long_Exit", OBJPROP_PRICE1);
   
   int ThisHour = TimeHour(TimeCurrent());
   
   /* Sekce finálního uzavření obchodu
   ==============================================*/
   /*
   
   if ( ObjectFind("Short_Exit")!= -1 && ObjectFind("Long_Exit")!= -1 ) {

   if ( IsNoTrade() == false && IsTradeAllowed() ) {
        
      if ( ForbidLate == true ){
      
         //funguje pouze v případě, že je zde pouze jeden obchod, jinak se jde automaticky na běžný výstup
         if ( BreakEven==true && ( SpecificTrades( 0, OP_SELL ) || SpecificTrades( 0, OP_BUY ) ) ) {
               
           if ( SpreadCheck() ) {  
                       
               if ( LongExit > 0 && ShortExit > 0)  { 
         
                  for(int fl=OrdersTotal()-1;fl>=0;fl--) {
              
                     if( OrderSelect(fl,SELECT_BY_POS, MODE_TRADES) ) { 
                              
                        if (OrderSymbol() == Symbol() ) {
                            
                            if ( OrderMagicNumber() == 0  ) { 
                         
                              if ( OrderType()==OP_BUY || OrderType()==OP_BUYSTOP ){
                                 if (Bid > LongExit ){   
                                    if ( OrderStopLoss()!=OrderOpenPrice()){
                                        Check = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, NULL); 
                                        if (Check<0) Print ("Modify order error ", GetLastError());                                 
                                    } 
                                 }   
                                                
                                 if (Bid > NewLongExit  && OrderStopLoss()>0) {
                      
                                     Check =OrderClose(OrderTicket(), OrderLots(), Bid, 2, 0);
                                     if (Check <0 ) Print ("Select error ", GetLastError());
                                 }
                                 
                              }  else if (OrderType()==OP_SELL || OrderType()==OP_SELLSTOP ){
                              
                                 if (Ask < ShortExit ){   
                                    if ( OrderStopLoss()!=OrderOpenPrice()){
                                            
                                        Check = OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, NULL); 
                                        if (Check<0) Print ("Modify order error ", GetLastError());
                                    } 
                                 }   
                                 if ( Ask < NewShortExit && OrderStopLoss()>0 ){
                                     Check =OrderClose(OrderTicket(), OrderLots(), Ask, 2, 0);
                                     if (Check <0 ) Print ("Select error ", GetLastError());
                                 }
                              
                              }
                           }
                        }
                     }     
                  }
               } 
           }      
           
         } else {
         
         /*
         Nebo tady v tý sekci je chyba, když jsou proti sobě otevřený dva stejný obchody, tak to z jednoho páru zavře všechny obchody
         
         
         */
  /*
               if ( LongExit > 0 && ShortExit > 0 && SpreadCheck() ){  
                  //zavrit BUY obchody  
                  
                     for(int f=OrdersTotal()-1;f>=0;f--) {
           
                        if( OrderSelect(f,SELECT_BY_POS, MODE_TRADES) ) { 
                        
                           if (OrderSymbol() == Symbol() ) {
                              
                              if ( OrderMagicNumber()== AutoMagic || OrderMagicNumber()== 0 ) {
                                      
                                 if ( OrderType()==OP_BUY ){
                                     if ( Bid > LongExit && LongExit > 0 ) {
                                         
                                        Check =OrderClose(OrderTicket(), OrderLots(), Bid, 2, 0);
                                        if (Check <0 ) Print ("Select error ", GetLastError());
                                        //obchod je uzavřen, konec sekvence
                                        GlobalVariableSet( Symbol()+ "_Closed", 1);
                        
                                    }                            
                                         
                                 }  
                                
                              }
                           }
                        }
                     }
                  //zavrit sell obchody
                  

                     for(int fu=OrdersTotal()-1;fu>=0;fu--) {
           
                        if( OrderSelect(fu,SELECT_BY_POS, MODE_TRADES) ) { 
                           
                           if (OrderSymbol() == Symbol() ) {
                              
                              if ( OrderMagicNumber()== AutoMagic || OrderMagicNumber()== 0  ) {            
                              
                                 if (OrderType()==OP_SELL ){
                                 if ( Ask < ShortExit && ShortExit > 0 ) {
                                                             
                                    Check =OrderClose(OrderTicket(), OrderLots(), Ask, 2, 0);
                                    if (Check <0 ) Print ("Select error ", GetLastError());
                                    //obchod je uzavřen, konec sekvence
                                    GlobalVariableSet( Symbol()+ "_Closed", 1);
                                 }
                              
                              }
                           }
                        }
                     }
                  }   
               } 
            }   
              
         } 
      }    
       
   }  

} */
     
/* Získat výsledky poslední obchodní série
=========================================*/
double LastSequence = 0;
   
if (Display_Results==true)
     
   string FontType = "Verdana";
   int   Xdistance = 150;
   int yLine = 0;
   int xCol = 0;
   int Size = 10;
   int FirstAlign =10;
   color Color = Yellow;
   color BadColor = Red;
   color OtherColor = Yellow;
   
   int PixelAdd = 0;
   if (OneClickTrading)PixelAdd=50;
      
   string Smile = "L"; 
   if ( ObjectFind(0, "TP_Short_Area")!=-1)Smile = "J";
   if ( ObjectFind(0, "TP_Long_Area")!=-1)Smile = "J";
   
   string SprCheck = "Neaktivni";
   if (SpreadCheck()==0) { SprCheck = "MOC VELKY";} else { SprCheck = "OK"; }
   
   double Overload = NormalizeDouble( AccountFreeMargin() / AccountBalance(), 1); 
      
   //vytvoøení obdélníku pod textem
   int RectangleX = 0;
   int RectangleY = 15 +PixelAdd;
   Label("DisplayObdélník", "g", "Webdings", 210, RectangleX, RectangleY, Brown);
      
   //zobrazuje hlavní èást informací
   //tržní rozpìtí
   Text("Text0", 15 +PixelAdd, FirstAlign, "-----------------------------------", Size, FontType, Color);
   Text("Text33", 30 +PixelAdd, FirstAlign, "Hodnota Ticku:", Size, FontType, Color);
   Text("Text34", 30 +PixelAdd, Xdistance, DoubleToStr( NormalizeDouble( Tickvalue, 2) ), Size, FontType, Color);
   
   /*Text("Text35", 45 +PixelAdd, FirstAlign, "No Loss:", Size, FontType, Color);
   Text("Text36", 45 +PixelAdd, Xdistance, Loss , Size, FontType, BadColor);*/
   
   Text("Text1", 60 +PixelAdd, FirstAlign, "Tržní rozpìtí:", Size, FontType, Color);
   Text("Text2", 60 +PixelAdd, Xdistance, DoubleToStr(MarketAverage(),2), Size, FontType, Color); 
   //použité rozpìtí
   Text("Text3", 75 +PixelAdd, FirstAlign, "H1 limit:", Size, FontType, Color);
   Text("Text4", 75 +PixelAdd, Xdistance, DoubleToStr(H1Limit,2), Size, FontType, Color);
   //aktuální tržní situace podle H1 
  /* Text("Text5",30 +PixelAdd , FirstAlign, "Hodnota Ticku:" ,Size,FontType, Color);
   Text("Text6", 30 +PixelAdd, Xdistance,  DoubleToStr( NormalizeDouble( Tickvalue, 2) ) ,Size,FontType, Color);*/
   //aktuální tržní situace podle H4 
   
   if (BreakEven){

   Text("Text7",90 +PixelAdd , FirstAlign, "BEP je zapnutý!" ,Size,FontType, BadColor);  
   } 
 /*  if (AutoTrading){
      Text("Text8", 90 +PixelAdd, Xdistance, "AOS je zapnuté!" ,Size,FontType, BadColor );
   }*/
   //koeficiant síly mezi aktuálními páry
   Text("Text9",110 +PixelAdd,FirstAlign,"Aktualni spread: ",Size +2, FontType, Color);
   Text("Text10",110 +PixelAdd,Xdistance,DoubleToStr( MarketInfo( Symbol(), MODE_SPREAD) ,1),Size +2, FontType, Color);
   //Koeficient aktuální situace na trhu   
   Text("Text11", 130 +PixelAdd, FirstAlign, "Spread:", Size+2, FontType, Color);
   Text("Text12", 130 +PixelAdd, Xdistance, SprCheck, Size + 2, FontType, Color);
   //Poèet obchodù  
   Text("Text13",145 +PixelAdd, FirstAlign, "Přetížení účtu:", Size + 2, FontType, Color);
   Text("Text14", 145 +PixelAdd, Xdistance ,DoubleToStr(Overload,1) , Size + 2, FontType, Color);
   //dìlítko
   //Text("Text15", 145 +PixelAdd, FirstAlign, "-----------------------------------", Size, FontType, Color);
   //Reward ratio

     
      if ( LastTotalLosingTrades() != 0 && LastTotalLosingTradesUSD() != 0 ) {   
         Text("Text16", 160 +PixelAdd, FirstAlign, "Ztráty v řadě:", Size, FontType, Color);
         Text("Text17", 160+PixelAdd, Xdistance, LastTotalLosingTrades()+", "+ LastTotalLosingTradesUSD(), Size, FontType, Color);
      } else {
          Text("Text16", 160 +PixelAdd, FirstAlign, "Poslední série:", Size, FontType, Color);
         Text("Text17", 160+PixelAdd, Xdistance, LastTotalSequenceTradesUSD(), Size, FontType, Color);
      }

   //Moneymanagement    
   Text("Text18", 175+PixelAdd, FirstAlign, "MM Loty:", Size + 2, FontType, Color);
   Text("Text19", 175+PixelAdd, Xdistance, Management(), Size + 2, FontType, Color);
   //dìlítko
   Text("Text20", 190+PixelAdd, FirstAlign, "-----------------------------------", Size, FontType, Color);
   
   if (IsNoTrade()){ 
      for (int d=21;d<=29;d++){
         ObjectDelete(0, "Text"+d);
      }
      Text("Text31", 215 +PixelAdd, FirstAlign, "Stav: ", Size + 15, FontType, Color);
      //vytvoøení smajlíku
      Text("Smile", 215 +PixelAdd, 150, Smile, Size+30, "Wingdings", Color); 
      }
     
   if (IsNoTrade()==false){   
      ObjectDelete(0, "Text30");
      ObjectDelete(0, "Text31");
      ObjectDelete(0, "Smile");
      Text("Text21", 205 +PixelAdd, FirstAlign, "Long výsledek:", Size, FontType, Color);
      Text("Text22", 205 +PixelAdd, Xdistance, DoubleToStr(PotentialProfit(),2), Size, FontType, Color);
      Text("Text23", 220 +PixelAdd, FirstAlign, "Short výsledek:", Size, FontType, BadColor);
      Text("Text24", 220 +PixelAdd, Xdistance, DoubleToStr(PotentiaLoss(),2), Size, FontType, BadColor);
    /*  Text("Text25", 235 +PixelAdd, FirstAlign, "Zisk v pipech:", Size, FontType, Color);
      Text("Text26", 235 +PixelAdd, Xdistance, DoubleToStr(PotentialPipsProfit(),2), Size, FontType, Color);
      Text("Text27", 250 +PixelAdd, FirstAlign, "Ztráta v pipech:", Size, FontType, BadColor);
      Text("Text28", 250 +PixelAdd, Xdistance, DoubleToStr(PotentialPipsLoss(),2), Size, FontType, BadColor);     
      Text("Text29", 265 +PixelAdd, FirstAlign, "-----------------------------------", Size, FontType, Color);*/
      
      if (UseHiddenTP){
          if ( ( (  SpecificTrades( 0, OP_BUY ) == 1 || SpecificTrades( AutoMagic, OP_BUY ) == 1 ) && SellTradesTotal() == 0) || 
          ( (  SpecificTrades( 0, OP_BUY ) == 0 || SpecificTrades( AutoMagic, OP_BUY ) == 0 ) && SellTradesTotal() == 1)  ){
              Text("Text30", 280, FirstAlign, "POZOR, skrytý TP je aktivní!", Size, FontType, BadColor);
          } else {
               Text("Text30", 280, FirstAlign, "POZOR, skrytý TP se neprovede, je otevřen více než 1 obchod!", Size, FontType, BadColor);
          }
      }   
   }
   if (IsNoTrade()){
      //maže to celou tu sérii zobrazení
      if (ObjectFind(0, "Text")!=-1){
         ObjectDelete(0, "Text20");
         ObjectDelete(0, "Text21");
         ObjectDelete(0, "Text22");
         ObjectDelete(0, "Text23");
         ObjectDelete(0, "Text24");
         ObjectDelete(0, "Text25");
         ObjectDelete(0, "Text26");
         ObjectDelete(0, "Text27");
         ObjectDelete(0, "Text28");
         }
   
    }
}

//nastavení textu
void Text(string eName, int eYD, int eXD, string eText, int eSize, string eFont, color eColor) {
   string Popis = eName;
   ObjectCreate(Popis, OBJ_LABEL, 0, 0, 0);
   ObjectSet(eName, OBJPROP_XDISTANCE, eXD);
   ObjectSet(eName, OBJPROP_YDISTANCE, eYD);
   ObjectSet(eName, OBJPROP_BACK, false);
   ObjectSetText(Popis, eText, eSize, eFont, eColor);
}

//vyhledávání speciálních znakù: http://www.knowlesys.com/software/glyph-font-viewer/
//zobrazuje ètverec pod textem vlevo
void Label(string objName, string Type, string GlyphFont, int Size, double X, double Y, color clr)
    {
     ObjectCreate(objName, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(objName, Type, Size, GlyphFont, clr);
   ObjectSet(objName, OBJPROP_XDISTANCE, X);
   ObjectSet(objName, OBJPROP_YDISTANCE, Y);
   ObjectSet(objName, OBJPROP_BACK, false);
    
   }


/*======================================================

Returns values for current trades, default returns 0

======================================================*/
double GetCurrentTradeDetails( string DesiredValue ){  
   
   double Result = 0;
      
   for( int i=OrdersTotal()-1;i>=0;i-- ) {
      
      if ( OrderSelect(i,SELECT_BY_POS,MODE_TRADES) ) {
      
         if (OrderSymbol() == Symbol() ) {
         
            if ( OrderMagicNumber() == AutoMagic ||  OrderMagicNumber() == 0 ) {
            
               if ( DesiredValue == "stoploss" ) {
                  Result = OrderStopLoss();
               } else if ( DesiredValue == "openprice" ) {
                  Result = OrderOpenPrice();
               } else { 
                  Result = 0;
               }
                           
            }
             
         } 
         
      }
      
   }
   
   return(Result);
}

