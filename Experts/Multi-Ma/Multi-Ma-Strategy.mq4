//+------------------------------------------------------------------+
//|                                            Multi-Ma-Strategy.mq4 |
//|                                                 Rodolfo Giuliana |
//|                                                               // |
//+------------------------------------------------------------------+
#property copyright "Rodolfo Giuliana"
#property link      "//"
#property version   "1.00"
#property strict

//Input UTENTE
extern double TakeProfit    =0;
extern double StopLoss      =0;
extern double Lots          =0.2;
extern int LOOKBACK = 17;
 
// Array con i valore delle medie
double ma[3000], ma1[3000], ma2[3000], ma3[3000], ma4[3000];

//Init barre contate
int barreContante = 0;
//Ordini aperti
int ordiniTotali =0;
//Boolean che indica se e' stato aperta un'operazione SHORT
bool shortB = false;
//Boolean che indica se e' stato aperta un'operazione LONG
bool longB= false;

double TakeProfitCalcolato=0 , StopLossCalcolato =0;

void OnTick(){
   int ticket;

   barreContante = IndicatorCounted();
   vwma(); //ma
   rma(); //ma1
   sma(); //ma2
   wma(); //ma3
   ema(); //ma4
   //Funzione per vedere i lotti minimi su IT40 (durante backtest)
   //Print(MarketInfo(Symbol(), MODE_MINLOT));
   
   //Controlla gli ordini aperti
   ordiniTotali=OrdersTotal();
   //-----------------------------------------------------
   //CONTROLLO POSIZIONE LONG
   if(NormalizeDouble(ma[0],5) > NormalizeDouble(ma[1],5) &&
      NormalizeDouble(ma1[0],5) > NormalizeDouble(ma1[1],5) &&
      NormalizeDouble(ma2[0],5) > NormalizeDouble(ma2[1],5) &&
      NormalizeDouble(ma3[0],5) > NormalizeDouble(ma3[1],5) &&
      NormalizeDouble(ma4[0],5) > NormalizeDouble(ma4[1],5)){
      
      //Se non e' stata aperta un'operazione LONG
      //prosegue con l'apertura e chiusura del SELL
      if(!longB){
         if(StopLoss > 0){
            StopLossCalcolato = NormalizeDouble(Ask - StopLoss*Point,Digits);
         }
         if(TakeProfit > 0){
            TakeProfitCalcolato = NormalizeDouble(Ask + TakeProfit*Point,Digits);
         }
         //Ordine 'stabilito' ma non inviato.
         ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 0, StopLossCalcolato,
                          TakeProfitCalcolato, "Multi-MA Buy", 0, 0, Blue);

         if(ticket > 0){
            //Apre operazione BUY
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("Operazione BUY aperta: ", OrderOpenPrice());
            
            //Segna shortB su false perche' verrano chiuse tutte le operazioni sell
            shortB = false;
            //Segna longB su true perche' e' stata aperta un'operazione long
            longB = true;
         }
      }
           
      //Se ci sono ordini (SELL), li chiude
      if(ordiniTotali > 0){
         //Controlla gli ordini aperti
         for(int k=0; k < ordiniTotali; k++){
            if(!OrderSelect(k,SELECT_BY_POS,MODE_TRADES))
                  continue;
            
            //Controlla che il simbolo e' uguale a quello attuale
            if(OrderSymbol()==Symbol()){
               //Se il tipo e' SELL
               //Chiuse l'operazione
               if(OrderType() == OP_SELL){
                  if(!OrderClose(OrderTicket(),OrderLots(),Ask,0,Violet))
                     Print("Errore nella chiusura dell'ordine SELL: ",GetLastError());
               }
            }
         }
      }
   }
   
   //-----------------------------------------------------
   //-----------------------------------------------------
   //CONTROLLO POSIZIONE SHORT
   if(NormalizeDouble(ma[0],5) < NormalizeDouble(ma[1],5) &&
      NormalizeDouble(ma1[0],5) < NormalizeDouble(ma1[1],5) &&
      NormalizeDouble(ma2[0],5) < NormalizeDouble(ma2[1],5) &&
      NormalizeDouble(ma3[0],5) < NormalizeDouble(ma3[1],5) &&
      NormalizeDouble(ma4[0],5) < NormalizeDouble(ma4[1],5)){
      
      //Se non e' stata aperta un'operazione SELL
      //prosegue con l'apertura e chiusura del BUY
      if(!shortB){
         if(StopLoss > 0){
            StopLossCalcolato = NormalizeDouble(Bid + StopLoss*Point,Digits);
         }
         if(TakeProfit > 0){
            TakeProfitCalcolato = NormalizeDouble(Bid - TakeProfit*Point,Digits);
         }
         //Ordine 'stabilito' ma non inviato.
         ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 0, StopLossCalcolato,
                       TakeProfitCalcolato, "Multi-MA Short", 0, 0, Red);
                     
         if(ticket > 0){
            //Apre operazione SELL
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("Operazione SELL aperta: ", OrderOpenPrice());
            
            //Indica che e' stata aperta operazione short
            shortB = true;
            //indica che non ci sono operazioni buy aperte
            longB = false;
         }                  
      }
      
                        
      //Se ci sono altri ordini (BUY), le chiude tutte
      if(ordiniTotali > 0 ){
         //Controlla gli ordini aperti
         for(int k=0; k < ordiniTotali; k++){
         
            if(!OrderSelect(k,SELECT_BY_POS,MODE_TRADES))
                  continue;
                  
            if(OrderType()<= OP_SELL &&
               OrderSymbol()==Symbol()){
               //Se il tipo e' BUY
               //Chiuse l'operazione
               if(OrderType() == OP_BUY){
                  if(!OrderClose(OrderTicket(),OrderLots(),Bid,0,Violet))
                     Print("Errore nella chiusura dell'ordine BUY: ",GetLastError());
               }
            }
         }

      }
   }
   //-----------------------------------------------------
   //-----------------------------------------------------
}
//--------------------------------------------------------------------
void vwma(){
   double sum=0, vol=0;
   int i, pos = Bars - barreContante - 1;
   
   if(pos < LOOKBACK) pos = LOOKBACK;
   
   //calcolo inziale, non eliminare
   for(i = 1; i < LOOKBACK; i++, pos--){
      vol += NormalizeDouble(iVolume(Symbol(),Period(),pos),Digits);
      sum += NormalizeDouble(iClose(Symbol(),Period(),pos) * iVolume(Symbol(),Period(),pos),Digits);
   }
   
   while(pos >= 0){
      vol += NormalizeDouble(iVolume(Symbol(),Period(),pos),Digits);
      sum += NormalizeDouble(iClose(Symbol(),Period(),pos) * iVolume(Symbol(),Period(),pos),Digits);

      ma[pos] = sum/vol;

	   sum -= NormalizeDouble(iClose(Symbol(), Period(), pos+LOOKBACK-1) * iVolume(Symbol(), Period(), pos+LOOKBACK-1), Digits);
	   vol -= NormalizeDouble(iVolume(Symbol(),Period(), pos+LOOKBACK-1),Digits);
 	   pos--;
     }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void sma(){
   double sum=0;
   int i, pos = Bars - barreContante - 1;

   if(pos < LOOKBACK) pos=LOOKBACK;

   //calcolo inziale, non eliminare
   for(i=1; i < LOOKBACK; i++, pos--)
      sum += NormalizeDouble(iClose(Symbol(),Period(),pos),Digits);

   while(pos>=0){
      sum+= NormalizeDouble(iClose(Symbol(),Period(),pos),Digits);
      ma2[pos] = sum / LOOKBACK;
      sum -= NormalizeDouble(iClose(Symbol(),Period(),pos+LOOKBACK-1),Digits);
 	   pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void ema(){
   double pr= 2.0 /(LOOKBACK+1);
   int    pos= Bars - 2;

   if(barreContante > 2) pos = Bars - barreContante - 1;
   
   while(pos >= 0){
      if(pos == Bars - 2) ma4[pos + 1] = NormalizeDouble(iClose(Symbol(),Period(),pos+1),Digits);
      
      ma4[pos] = NormalizeDouble(iClose(Symbol(),Period(),pos) * pr + ma4[pos + 1] * (1 - pr),Digits);
 	   pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void rma(){
   double k = 1. / LOOKBACK;
    int limit=Bars-2;
    
    if(barreContante > 2) limit = Bars - barreContante - 1;
    
    int pos = limit;

    while(pos >= 0){
     if (pos == Bars - 2){
      ma1[pos]=NormalizeDouble(iMA(NULL, 0, LOOKBACK, 0, MODE_SMA, 0, pos),Digits);
     }else{
      ma1[pos]=NormalizeDouble(((iMA(NULL, 0, 1, 0, MODE_SMA, 0, pos) - ma1[pos + 1]) * k + ma1[pos+1]),Digits);
     }
     pos--;
    } 
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void wma(){
   int pos = Bars - barreContante - 1;

   while(pos >= 0){
      ma3[pos] = NormalizeDouble(iMA(NULL, 0, LOOKBACK, 0, MODE_LWMA, 0, pos),Digits);
      pos--;
   }
}
