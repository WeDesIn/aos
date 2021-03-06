//+------------------------------------------------------------------+
//|                                                   Copyright 2017 |
//|                                          http://www.4xbroker.cz/ |
//| Podmínky použití tohoto systému:                                 |
//|                                                                  |
//| Autor se vyvazuje z jakékoliv odpovědnosti za použití tohoto     |
//| systému jak z hlediska výsledků na reálném účtu, tak případných  |
//| chyb v kódu. Vždy si systém důkladně otestujte na demo účtu.     |
//|                                                                  |
//| Výhradním uživatelem tohoto systému je Tomáš Mitrega.            |
//|                                                                  |
//| Jakékoliv šíření tohoto systému je zakázané. Případný prodej je  |
//| povolen pouze se souhlasem autora systému.                       |
//|                                                                  |
//| Máte zájem vytvoření automatického obchodního systému,           |
//| indikátoru či skriptu? Kontaktujte nás na office@4xbroker.cz     |
//|                                                                  |
//+------------------------------------------------------------------+


#property copyright "Copyright 2017, 4xbroker.cz."
#property link      "http://www.4xbroker.cz/"
#property version   "1.00"
#property strict

//Obecné nastavení
extern string ZakladniNastaveni = "=====================================";
extern int UseMA = true;                        // Použít klouzavý průměr
extern int MinHeightCandle = 100;               // Minimální výška svýčky

//nastavení obhodů
extern string NastaveniObchodu = "=====================================";
extern int TradeDistance = 100;
extern int TakeProfit = 100;
extern int StopLoss = 50;
extern double Loty = 1;                         // Loty pro jednotlivé obchody
extern double MM_Risk = 3;                      // Procentuální riskování obchodů
extern int Slippage = 100;                      // Maximální skluz pro obchody
extern int DeleteTradeSec = 1800;                // Smaže obchod po X sekundách

//nastavení indikátorů
extern string NastaveniIndikatoru = "=====================================";
extern int MAPeriod = 10;

//časové omezení
extern string CasoveOmezeni = "=====================================";
extern bool   TradeTimeFilter = false;          // Zda použít časový filter
extern string      TradeBegin = "07:00";        // Začátek obchodování
extern string        TradeEnd = "19:00";        // Konec obchodování
extern bool     EndInTomorrow = false;          // Zda obchod končí následující den 

//define all other variables
int Check, Magic = 148775;

//+------------------------------------------------------------------+
//|                                                |
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
//| Vrací loty posledního ztrátového obchodu                         |
//+------------------------------------------------------------------+

double LastHistoryLots( ){  
   
   double   Result = 0;
   datetime CloseTime = 0;
       for( int i=OrdersHistoryTotal()-1;i>=0;i-- ) {
           if ( OrderSelect(i,SELECT_BY_POS,MODE_HISTORY) ) {
              if (OrderSymbol() == Symbol() 
              &&  OrderMagicNumber() == Magic  
              && OrderCloseTime()>CloseTime ) {
              
                 CloseTime = OrderCloseTime();
                 Result = OrderLots();
                 
              } 
           }
       }
       
   return(Result);
   
}

//+------------------------------------------------------------------+
//| Buy signal                                                       |
//+------------------------------------------------------------------+

bool BuySignal( ){  
   
   bool Result = false;
   double MA = iMA( Symbol(), Period(), MAPeriod, 0, MODE_SMA, PRICE_OPEN, 0); 
   double CandleHeight =  iHigh(Symbol(), Period(), 0) - iLow(Symbol(), Period(), 0);
   
   if ( UseMA ) {
   
      if ( MA < Ask ) { 
      
         //aktualni svicka je zelena
         if ( iOpen(Symbol(), Period(), 0) < Ask ) {
                           
            //minimalni rozpětí svíčky
            if ( CandleHeight > MinHeightCandle * Point ) {
               Result = true;
            }
            
         }
            
      }
   
   } else {
   
   }    
   
   return Result;
}

//+------------------------------------------------------------------+
//| Sell signal                                                       |
//+------------------------------------------------------------------+

bool SellSignal( ){  
   
   bool Result = false;
   double MA = iMA( Symbol(), Period(), MAPeriod, 0, MODE_SMA, PRICE_OPEN, 0);
   double CandleHeight =  iHigh(Symbol(), Period(), 0) - iLow(Symbol(), Period(), 0);
   
   if ( UseMA ) {
   
       if ( MA > Bid ) { 
       
         
       
         //aktualni svicka je zelena
         if ( iOpen(Symbol(), Period(), 0) > Bid ) {
         
            //minimalni rozpětí svíčky
            if ( CandleHeight > MinHeightCandle * Point ) {
               Result = true;
            }
         }
            
      }
   
   } else {
   
   }
                  
   return Result;
}

//+------------------------------------------------------------------+
//| Check Opening trades error (Predelat na posilani obchod)         |
//+------------------------------------------------------------------+

void CheckOpen( int CheckOpen ){  
   
   if (Check<0) {
      Print ("Otevření obchodu ", OrderTicket() ," se nezdařilo, chyba ", GetLastError() );
   }
   
}

void CheckTrail( int CheckTrail ){  
   
   if (Check<0) {
      Print ("Upravení nastavení obchodu ", OrderTicket() ," se nezdařilo, chyba ", GetLastError() );
   }
   
}

//+------------------------------------------------------------------+
//| maže starý obchody pokud nejsou aktivní                          |
//+------------------------------------------------------------------+

void DeleteOldTrades() {
   
   //pokud existuje limitní obchod
   if ( SpecificTrades( OP_BUYLIMIT ) > 0 || SpecificTrades( OP_BUYSTOP ) > 0 ||
      SpecificTrades( OP_SELLLIMIT ) > 0 || SpecificTrades( OP_SELLSTOP ) > 0 ) {
      for(int c=OrdersTotal();c>=0;c--) {
         if(OrderSelect(c,SELECT_BY_POS, MODE_TRADES)) {
            if ( OrderSymbol() == Symbol() ) {
               if(  OrderMagicNumber() == Magic ) {
                  if ( OrderType() == OP_SELLSTOP || OrderType() == OP_SELLLIMIT || 
                  OrderType() == OP_BUYSTOP || OrderType() == OP_BUYLIMIT  ) {
                     if (OrderOpenTime() + DeleteTradeSec < TimeCurrent() ) { 
                        Check = OrderDelete(OrderTicket(), Red);
                        if (Check<0) Print ("Příkaz ", OrderTicket() ," nebyl odstraněn, nastala chyba ", GetLastError());
                        }
                     }
                  }
               }
            }
        } 
   }   
 
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
//|   Open lots base on the percent of equity                        |
//+------------------------------------------------------------------+
double mmLots()  {
   
   double Result = 0;
   double Distance = NormalizeDouble( (Ask - (Ask - StopLoss*Point)) / Point, Digits);
   
   if ( MM_Risk == 0 ) {
   
      Result = Loty;
   
   } else {
   
      double RiskedBalance = AccountBalance() * MM_Risk/100;                  
      double TickValue = MarketInfo(Symbol(), MODE_TICKVALUE)/**tvAdjust()*/;
      Result = RiskedBalance /( TickValue*Distance);
   
   }
   
   if (Result<(MarketInfo(Symbol(),MODE_MINLOT))){
      Result=MarketInfo(Symbol(),MODE_MINLOT);
   }
   
   Result = NormalizeDouble(Result, 2);
         
   return(Result);
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
   
//delete old trades   
DeleteOldTrades();   
                   
if ( TradeTime() ) {                              
   //if there are no trades
   if ( SpecificTrades( OP_BUYSTOP )== 0 && SpecificTrades( OP_SELLSTOP ) == 0 && 
   SpecificTrades( OP_BUY )== 0 && SpecificTrades( OP_SELL ) == 0 ) {
         //if the time is right

            //buy signál
            if ( BuySignal() ) { 
            
               double SetLongPrice = NormalizeDouble( iHigh( Symbol(), Period(), 0) + TradeDistance * Point , Digits);
               
               if ( SetLongPrice > MarketInfo( Symbol(), MODE_STOPLEVEL) * Point + Ask ) {
                  //Chyba v ceně odeslání obchodu
                  Check = OrderSend( Symbol(), OP_BUYSTOP, mmLots(), SetLongPrice , Slippage, NormalizeDouble(SetLongPrice - StopLoss* Point, Digits), 
                  NormalizeDouble(SetLongPrice + TakeProfit * Point, Digits), "Acero AOS", Magic, 0, Green);         
                  CheckOpen( Check );
               
               }
               
            }   
            
            //
            //sell signál
            if ( SellSignal() ) {
                           
               double SetShortPrice = NormalizeDouble( iLow( Symbol(), Period(), 0) - TradeDistance * Point , Digits);           
               
               if ( SetShortPrice  < Bid - MarketInfo( Symbol(), MODE_STOPLEVEL) * Point ) { 
                  //tady taky
                  Check = OrderSend( Symbol(), OP_SELLSTOP, mmLots(), SetShortPrice, Slippage, NormalizeDouble(SetShortPrice + StopLoss* Point, Digits), 
                  NormalizeDouble(SetShortPrice - TakeProfit * Point, Digits), "Acero AOS", Magic, 0, Red); 
                  CheckOpen( Check );
                  
               }   
            
            }  
            
       }
   
   }
   
  }
//+------------------------------------------------------------------+

