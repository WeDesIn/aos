// Software je dodáván „tak jak je“. Výrobce neodpovídá za případné ztráty vzniklé jeho použitím.
// Kulata čísla

#define SIGNAL_NONE 0
#define SIGNAL_BUY   1
#define SIGNAL_SELL  2
#define SIGNAL_CLOSEBUY 3
#define SIGNAL_CLOSESELL 4

////////////////////////////////////////////////////////////////////////////////////////////////////////
extern int MagicNumber = 900; 
extern double Lots = 1;

extern bool UseStopLoss = True;
extern int StopLoss = 300;

extern bool UseTrailingStop = True;
extern int TrailingStop = 50;

extern int maximalni_spread_v_bodech = 30;
////////////////////////////////////////////////////////////////////////////////////////////////////////


int ticketSell;
int ticketBuy;
bool inSellStop = false;
bool inBuyStop = false;



//
char SpecificTrades( char Opentype ) {
   char bo=0;
   for(int i=OrdersTotal()-1;i>=0;i--)
     {
      if(OrderSelect(i,SELECT_BY_POS, MODE_TRADES) && OrderMagicNumber()  == MagicNumber 
         &&  OrderSymbol()       == Symbol() && OrderType()==Opentype )
         bo=bo+1;
     }
   return(bo);
  }  
  

// expert OnTick() function                                            

void OnTick() {
   
   
   int Order = SIGNAL_NONE;

   bool doBuy = false; 
   bool doSell = false;


   Order = SIGNAL_NONE;

// parametry
   
   double kulate_cislo = Bid;

   if ((Digits == 5) || (Digits == 4)) {
      kulate_cislo = NormalizeDouble(kulate_cislo,2);
   }
   
   if ((Digits == 3) || (Digits == 2)) {
      kulate_cislo = NormalizeDouble(kulate_cislo,0);
   }

   Comment("kulaté číslo: ",kulate_cislo);
   
   bool delete_sell = false;
   bool delete_buy = false;
   
   bool set_buystop = false;
   bool set_sellstop = false;
   
   if ((Digits == 5) || (Digits == 3)) {
   
      if (Bid < (kulate_cislo - 450 * Point)) {
      set_buystop = true;
      }
   
      if (Bid > (kulate_cislo + 450 * Point)) {
      set_sellstop = true;
      }
   }
   
   if ((Digits == 4) || (Digits == 2)) {
   
      if (Bid < (kulate_cislo - 45 * Point)) {
      set_buystop = true;
      }
   
      if (Bid > (kulate_cislo + 45 * Point)) {
      set_sellstop = true;
      }
   }    
      

//Check position

   bool IsTrade = False;
   bool isSell = false;
   bool isBuy = false;


// SELL

   if (OrderSelect(ticketSell, SELECT_BY_TICKET, MODE_TRADES) && (OrderSymbol() == Symbol())) {
      if ((OrderType() == OP_SELL) && (OrderMagicNumber() == MagicNumber)) {
         IsTrade = True;
         isSell = true;
         
         if (OrderCloseTime() == 0) {
         delete_buy = true;
         delete_sell = true;
         }
         
         //Close
         
         // if (výstupní signál)   Order = SIGNAL_CLOSESELL;
                 
         // Exit sell                                            

         if ((OrderCloseTime() > 0) || Order == SIGNAL_CLOSESELL) { 
            if (Order == SIGNAL_CLOSESELL) {
               bool OC_sell = OrderClose(OrderTicket(), OrderLots(), Ask, 0, DarkOrange);
                  if (OC_sell == true) { 
				      Print("Order close successfully.");
				      } else {
				      Print("Error in OrderClose. Error code=",GetLastError());
				      } 
            }
           
            IsTrade = False;
            isSell = false;
            inSellStop = false;
            ticketSell = 0;
         } 
         
         //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if((OrderOpenPrice() - Ask) > (Point * TrailingStop)) {
                  if((OrderStopLoss() > (Ask + Point * TrailingStop)) || (OrderStopLoss() == 0)) {
                     bool OM_sell = OrderModify(OrderTicket(), OrderOpenPrice(), Ask + Point * TrailingStop, OrderTakeProfit(), 0, DarkOrange);
                        if (OM_sell == true) { 
				            Print("Order modify successfully.");
				            } else {
				            Print("Error in OrderModify. Error code=",GetLastError());
				            }
                  }
               }
            }
      }
   }
   

// BUY   
   
   if (OrderSelect(ticketBuy, SELECT_BY_TICKET, MODE_TRADES) && (OrderSymbol() == Symbol())) {
      if ((OrderType() == OP_BUY) && (OrderMagicNumber() == MagicNumber)) {         
         IsTrade = True;
         isBuy = true;
         
         if (OrderCloseTime() == 0) {
         delete_buy = true;
         delete_sell = true;
         }
         
         //Close
         
         // if (výstupní signál)   Order = SIGNAL_CLOSEBUY;
         
         // Exit buy                                              

         if ((OrderCloseTime() > 0) || Order == SIGNAL_CLOSEBUY) {
            if (Order == SIGNAL_CLOSEBUY) {
               bool OC_buy = OrderClose(OrderTicket(), OrderLots(), Bid, 0, MediumSeaGreen);
                  if (OC_buy == true) { 
				      Print("Order close successfully.");
				      } else {
				      Print("Error in OrderClose. Error code=",GetLastError());
				      }
            }
            
            IsTrade = False;
            isBuy = false;
            inBuyStop = false;
            ticketBuy = 0;
         }
         
         //Trailing stop
            if(UseTrailingStop && TrailingStop > 0) {                 
               if(Bid - OrderOpenPrice() > Point * TrailingStop) {
                  if(OrderStopLoss() < Bid - Point * TrailingStop) {
                     bool OM_buy = OrderModify(OrderTicket(), OrderOpenPrice(), Bid - Point * TrailingStop, OrderTakeProfit(), 0, MediumSeaGreen);
                        if (OM_buy == true) { 
				            Print("Order modify successfully.");
				            } else {
				            Print("Error in OrderModify. Error code=",GetLastError());
				            }
                  }
               }
            }
         }
       }
 

// Signal Begin(Entry)                                              
   
   if ((!inBuyStop) && (set_buystop)) doBuy = true;
 
   if ((!inSellStop) && (set_sellstop)) doSell = true;

// Check spread

   int spread = MarketInfo(Symbol(),MODE_SPREAD);
   
// delete all buystop and sellstop orders   
   
      if (OrderSelect(ticketSell, SELECT_BY_TICKET, MODE_TRADES) && (OrderSymbol() == Symbol()) && (OrderMagicNumber() == MagicNumber) && (OrderType() == OP_SELLSTOP) && (OrderCloseTime() == 0)) {
      if ((delete_sell == true) || (spread > maximalni_spread_v_bodech)) {
         
      bool OD_sell = OrderDelete(ticketSell);
                  if (OD_sell == true) { 
				      Print("Order delete successfully.");
				      } else {
				      Print("Error in OrderDelete. Error code=",GetLastError());
				      }
         inSellStop = false;
      }
      }
   
      
      if (OrderSelect(ticketBuy, SELECT_BY_TICKET, MODE_TRADES) && (OrderSymbol() == Symbol()) && (OrderMagicNumber() == MagicNumber) && (OrderType() == OP_BUYSTOP) && (OrderCloseTime() == 0)) {
      if ((delete_buy == true) || (spread > maximalni_spread_v_bodech)) {
         
      bool OD_buy = OrderDelete(ticketBuy);
                  if (OD_buy == true) { 
				      Print("Order delete successfully.");
				      } else {
				      Print("Error in OrderDelete. Error code=",GetLastError());
				      }
         inBuyStop = false;
      }
      }
   

      
// Ordersend
      
   //Buy
   if (doBuy) {
      if(!isBuy) {

         ticketBuy = OrderSend(Symbol(), OP_BUYSTOP, Lots, kulate_cislo, 0, 0, 0, "Buy(#" + MagicNumber + ")", MagicNumber,  0, DodgerBlue);      
                           
         
         if(ticketBuy > 0) {
            if (OrderSelect(ticketBuy, SELECT_BY_TICKET, MODE_TRADES) && (OrderMagicNumber() == MagicNumber)) {
               inBuyStop = true;
				   Print("BUY order opened : ", OrderOpenPrice());
				  
			   } else {
				  Print("Error opening BUY order : ", GetLastError());
			   }

         
         bool OM2_buy = OrderModify(ticketBuy,OrderOpenPrice(),OrderOpenPrice() - StopLoss * Point,0,0,DodgerBlue);
                  if (OM2_buy == true) { 
				      Print("Order modify successfully.");
				      } else {
				      Print("Error in OrderModify. Error code=",GetLastError());
				      }
         
         }
      }
   }
   
   
   //Sell
   
   if (doSell) {
      if(!isSell) {
         
         ticketSell = OrderSend(Symbol(), OP_SELLSTOP, Lots, kulate_cislo, 0, 0, 0, "Sell(#" + MagicNumber + ")", MagicNumber,  0, DeepPink);
                              
         
         if(ticketSell > 0) { 
            if (OrderSelect(ticketSell, SELECT_BY_TICKET, MODE_TRADES) && (OrderMagicNumber() == MagicNumber)) {
               inSellStop = true;
			      Print("SellStop order opened : ", ticketSell);
        
			   } else {
				  Print("Error opening SELL order : ", GetLastError());
			   }

         
         bool OM2_sell = OrderModify(ticketSell,OrderOpenPrice(),OrderOpenPrice() + StopLoss * Point,0,0,DeepPink);
                  if (OM2_sell == true) { 
				      Print("Order modify successfully.");
				      } else {
				      Print("Error in OrderModify. Error code=",GetLastError());
				      }
         
         }
      }
   }

}
//+------------------------------------------------------------------+