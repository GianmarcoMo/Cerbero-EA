//+------------------------------------------------------------------+
//|                                                        EA-HA.mq4 |
//|                                                 Rodolfo Giuliana |
//|                                                               // |
//+------------------------------------------------------------------+
#property copyright "Rodolfo Giuliana"
#property link      "//"
#property version   "2.00"
#property strict
//INPUT UTENTE
extern double TakeProfit =0;
extern double StopLoss =0;
extern double Lots =0.2;
extern int LOOKBACK = 66;

//---- buffers heikin ashi
double minimo[3000], massimo[3000], apertura[3000], chiusura[3000];


//----- buffers indicatori
double ma[3000], ma1[3000], ma2[3000], ma3[3000], ma4[3000];

//----
int barreContate=0;
//Ordini aperti
int ordiniAperti =0;
//Boolean che indica se e' stato aperta un'operazione SHORT
bool shortB = false;
//Boolean che indica se e' stato aperta un'operazione LONG
bool longB= false;

double TakeProfitCalcolato=0 , StopLossCalcolato =0;
//------------------------------------------
//------------------------------------------
void OnInit(void){
   IndicatorDigits(Digits);
}

void OnTick(){
   barreContate = IndicatorCounted();
   heikinAshi();
   
   vwma(); //ma
   //Print("Ma: ", ma[0]);
   rma(); //ma1
   sma(); //ma2
   wma(); //ma3
   ema(); //ma4

   //Controlla gli ordini aperti
   ordiniAperti=OrdersTotal();
   controlloPosizioneLong(ordiniAperti);
   controlloPosizioneShort(ordiniAperti);
}
//+------------------------------------------------------------------+
//----------------------------
//---------- metodo per disegnare l'heikin ashi
void heikinAshi(){
   double haOpen=0.0, haHigh=0.0, haLow=0.0, haClose=0.0;
   
   if(barreContate > 0) 
       barreContate--;
   int pos = Bars - barreContate - 1;
   while(pos >= 0){      
       haOpen = (apertura[pos+1] + chiusura[pos+1])/2;
       Print("haOpen: ", haOpen);
       haClose = NormalizeDouble((iOpen(Symbol(),Period(),pos) + iHigh(Symbol(), Period(), pos) +
                                 iLow(Symbol(), Period(), pos) + iClose(Symbol(),Period(),pos)) / 4,Digits);
       haHigh = MathMax(NormalizeDouble(iHigh(Symbol(), Period(), pos),Digits), MathMax(haOpen, haClose));
       haLow = MathMin(NormalizeDouble(iLow(Symbol(), Period(), pos),Digits), MathMin(haOpen, haClose));
       if(haOpen  < haClose){
           minimo[pos] = haLow;
           massimo[pos] = haHigh;
         } 
       else{
           minimo[pos] = haHigh;
           massimo[pos] = haLow;
         } 
       apertura[pos] = haOpen;
       chiusura[pos] = haClose;
 	    pos--;
   }
}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void vwma(){
   double sum=0, vol=0;
   int i, pos = Bars - barreContate - 1;
   
   if(pos < LOOKBACK) pos = LOOKBACK;
   
   //calcolo inziale, non eliminare
   for(i = 1; i < LOOKBACK; i++, pos--){
      //(double) casting per evitare possibili perdite di dati
      vol +=NormalizeDouble(iVolume(Symbol(),Period(),pos),Digits);
      sum += NormalizeDouble(chiusura[pos] * iVolume(Symbol(),Period(),pos),Digits);
   }
   
   while(pos >= 0){
      vol +=NormalizeDouble(iVolume(Symbol(),Period(),pos),Digits);
      sum += NormalizeDouble(chiusura[pos] * iVolume(Symbol(),Period(),pos),Digits);
      ma[pos] = sum/vol;
	   sum -=NormalizeDouble(chiusura[pos + LOOKBACK - 1] * iVolume(Symbol(),Period(),pos + LOOKBACK - 1),Digits);
	   vol -=NormalizeDouble(iVolume(Symbol(),Period(), pos+LOOKBACK-1), Digits);
 	   pos--;
   }
}
//------------------------------------------
//------------------------------------------
void rma(){
   double k = 1. / LOOKBACK;
    
    int limit=Bars-2;
    
    if(barreContate > 2) limit = Bars - barreContate - 1;
    
    int pos = limit;
    
    while(pos >= 0){
     if (pos == Bars - 2){
      ma1[pos]=NormalizeDouble(iMA(NULL, 0, LOOKBACK, 0, MODE_SMA, 0, pos), Digits);
     }else{
      ma1[pos]=NormalizeDouble((iMA(NULL, 0, 1, 0, MODE_SMA, 0, pos) - ma1[pos + 1]) * k + ma1[pos+1], Digits);
     }
     pos--;
    } 
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void sma(){
   double sum=0;
   int i, pos = Bars - barreContate - 1;

   if(pos < LOOKBACK) pos=LOOKBACK;
   
   //calcolo inziale, non eliminare
   for(i=1; i < LOOKBACK; i++, pos--)
      sum+=chiusura[pos];

   while(pos>=0){
      sum+=chiusura[pos];
      ma2[pos]=sum / LOOKBACK;
	   sum-=chiusura[pos + LOOKBACK - 1];
 	   pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void ema(){
   double pr= 2.0 /(LOOKBACK+1);
   int    pos= Bars - 2;
   
   if(barreContate > 2) pos = Bars - barreContate - 1;
   
   while(pos >= 0){
      if(pos == Bars - 2) ma4[pos + 1] = chiusura[pos + 1];
      ma4[pos] = chiusura[pos] * pr + ma4[pos + 1] * (1 - pr);
 	   pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void wma(){
   int pos = Bars - barreContate - 1;
   while(pos >= 0){
      ma3[pos] = NormalizeDouble(iMA(NULL, 0, LOOKBACK, 0, MODE_LWMA, 0, pos),Digits);
      pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
//Metodo per effettuare una sola volta il resize degli array
void reSizeArrayHA(){
   ArrayResize(minimo,1);
   ArrayResize(massimo,1);
   ArrayResize(chiusura,1);
   ArrayResize(apertura,1);
}
//Metodo per effettuare UNA SOLA VOLTA il resize degli array per gli indicatori
void reSizeArrayIndicatori(){
   ArrayResize(ma,LOOKBACK);
   ArrayResize(ma1,1);
   ArrayResize(ma2,LOOKBACK);
   ArrayResize(ma3,1);
   ArrayResize(ma4,1);
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void controlloPosizioneLong(int ordiniTotali){
   int ticket;
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
}
//----------------------------------
//------------------------
void controlloPosizioneShort(int ordiniTotali){
   int ticket;
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
}