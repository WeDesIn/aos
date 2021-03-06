//+------------------------------------------------------------------+
//|                                          random-walk-popelka.mq4 |
//|                                         Copyright 2017, 4xbroker |
//|                                          http://www.4xbroker.cz/ |
//|                                                                  |
//| Podmínky použití tohoto systému:                                 |
//|                                                                  |
//| Autor se vyvazuje z jakékoliv odpovědnosti za použití tohoto     |
//| systému jak z hlediska výsledků na reálném účtu, tak případných  |
//| chyb v kódu. Vždy si systém důkladně otestujte na demo účtu.     |
//|                                                                  |
//| Výhradním uživatelem tohoto systému je Jiří Popelka.             |
//|                                                                  |
//| Jakékoliv šíření tohoto systému je zakázané. Případný prodej je  |
//| povolen pouze se souhlasem autora systému.                       |
//|                                                                  |
//| Máte zájem vytvoření automatického obchodního systému,           |
//| indikátoru či skriptu? Kontaktujte nás na office@4xbroker.cz     |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, 4xbroker.cz"
#property link      "http://www.4xbroker.cz/"
#property version   "1.00"
#property strict


//Obecné nastavení
extern string ZakladniNastaveni = "=====================================";
extern int Magic = 1488;                   // Magic číslo tohoto AOS

//nastavení obhodů
extern string NastaveniObchodu = "=====================================";
extern int Slippage = 50;                      // Maximální skluz pro obchody
extern int Trailing = 50;
extern int StopLoss = 200;
extern double Loty = 1;                         // Loty pro jednotlivé obchody

//časové omezení
extern string CasoveOmezeni = "=====================================";
extern bool   TradeTimeFilter = false;          // Zda použít časový filter
extern string      TradeBegin = "07:00";        // Začátek obchodování
extern string        TradeEnd = "19:00";        // Konec obchodování
extern bool     EndInTomorrow = false;          // Zda obchod končí následující den 

//+------------------------------------------------------------------+
//| Returns any kind of trade type number                            |
//+------------------------------------------------------------------+
char SpecificTrades( int Opentype ) {
   char bo=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES) 
         && OrderMagicNumber()  == Magic
         &&  OrderSymbol()  == Symbol() 
         && OrderType()==Opentype ) 
         
         bo=bo+1;
     }
   return(bo);
  }  
  
//+------------------------------------------------------------------+
//| Trade Time Filter                                                |
//+------------------------------------------------------------------+
bool TradeTime() {
   
   if(TradeTimeFilter) {
       
      datetime time_now, time_begin, time_end, time_end_today; 
      
      time_now = TimeCurrent();
      time_begin = StrToTime(TradeBegin);
      time_end = StrToTime(TradeEnd) + 86400;
      time_end_today = StrToTime(TradeEnd);
   
      
      if (!EndInTomorrow) {
         time_end = StrToTime(TradeEnd);
      
      }  else if(EndInTomorrow) {
         
         time_end = StrToTime(TradeEnd) + 86400;
         time_end_today = StrToTime(TradeEnd);           
      }  
      
      //
      if (!EndInTomorrow && (time_now<time_begin || time_now>time_end)) {
         return(false);
      }  else if(EndInTomorrow && time_now>time_end_today && time_now<time_begin) {
         return(false);
      }
   }
   return(true);  
  }

//+------------------------------------------------------------------+
//| Last history trade type                                          |
//+------------------------------------------------------------------+
int LastHistoryType( ){  
   
   int   Result = -1;
   datetime CloseTime = 0;
   
       for( int i= (OrdersHistoryTotal()-1); i>=0; i-- ) {
       
           if ( OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) {
           
              if ( OrderSymbol() == Symbol() &&  
                  OrderMagicNumber() == Magic && 
                  OrderCloseTime()>=CloseTime
                 ) {
                 CloseTime = OrderCloseTime();
                 Result = OrderType();
              } 
           } 
       }
       
   return(Result);
   
}

//+------------------------------------------------------------------+
//| Check Opening trades error                                       |
//+------------------------------------------------------------------+

void CheckOpen( int Check ){  
   
   if (Check<0) {
      Print ("Otevření obchodu ", OrderTicket() ," se nezdařilo, chyba ", GetLastError() );
   }
}

void CheckTrail( int Check ){  
   
   if (Check<0) {
      Print ("Upravení nastavení obchodu ", OrderTicket() ," se nezdařilo, chyba ", GetLastError() );
   }
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   int Check;

   if ( TradeTime() ){
   
      //open trades randomly the first time
      if ( ( SpecificTrades( OP_BUY )==0 &&  SpecificTrades( OP_SELL )==0 ) && LastHistoryType( )==-1 ) {
           
         //get random number
         int Random = MathRand();
         //even number
         if ( Random % 2 == 0 ) {
            
            Check = OrderSend( Symbol(), OP_BUY, Loty, Ask, Slippage, Ask - StopLoss* Point, 0, "Random Walk", Magic, 0, Green); 
            CheckOpen( Check );
            
         //odd number
         } else {
           
            Check = OrderSend( Symbol(), OP_SELL, Loty, Bid, Slippage, Ask + StopLoss* Point, 0, "Random Walk", Magic, 0, Red); 
            CheckOpen( Check );
            
         }   
      //else change based on last trade      
      } else {
            
         if ( SpecificTrades( OP_BUY )==0 &&  SpecificTrades( OP_SELL )==0 ) { 
            
            if ( LastHistoryType( ) == OP_BUY ) {
               
               Check = OrderSend( Symbol(), OP_SELL, Loty, Bid, Slippage, Ask + StopLoss* Point, 0, "Random Walk", Magic, 0, Red); 
               CheckOpen( Check );
               
            } else if ( LastHistoryType( ) == OP_SELL ) {
            
               Check = OrderSend( Symbol(), OP_BUY, Loty, Ask, Slippage, Ask - StopLoss* Point, 0, "Random Walk", Magic, 0, Green); 
               CheckOpen( Check );
            
            }
         }
         
      }
   }
   
   //trailing stop
   double TrailStopPoints = NormalizeDouble( Trailing*Point, Digits);
   double StoplossOrder;
   
   for(int i=0; i<OrdersTotal(); i++) {
   
      if ( OrderSelect(i, SELECT_BY_POS, MODE_TRADES) ) {
         
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic) {
            
            StoplossOrder = OrderStopLoss();
   
            if( OrderType()==OP_BUY) {
                  
                  if ((Bid-TrailStopPoints> StoplossOrder ) && ( ( Bid-TrailStopPoints>=OrderOpenPrice())) ) {
                  
                  if ( OrderStopLoss() != Bid-TrailStopPoints ) {
                  
                     Check = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble( Bid-TrailStopPoints, Digits) , OrderTakeProfit(), 0, Blue);
                     CheckTrail( Check );
                     
                  }   
                     
               }
            } else if(OrderType()==OP_SELL ) {
                  
                  if ( (Ask+TrailStopPoints < StoplossOrder )  && (  (  Ask+TrailStopPoints<=OrderOpenPrice() ) ) ) {
                  
                     if ( OrderStopLoss() != Ask-TrailStopPoints ) {
             
                        Check = OrderModify(OrderTicket(), OrderOpenPrice(), NormalizeDouble(  Ask+TrailStopPoints, Digits) , OrderTakeProfit(), 0, Orange);
                        CheckTrail( Check );
                     
                     }
                  
                  }
               }
            
            }
         }
      }
   
  }
//+------------------------------------------------------------------+
