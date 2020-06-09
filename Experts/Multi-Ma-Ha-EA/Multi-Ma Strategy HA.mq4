//+------------------------------------------------------------------+
//|                                                        EA-HA.mq4 |
//|                                                 Rodolfo Giuliana |
//+------------------------------------------------------------------+
#property copyright "Rodolfo Giuliana"
#property version   "3.2"
#property description "Non sono stati maltrattati indicatori per sviluppare questo EA."
#property description "Però verrà maltrattato molto il DAX."
#property description "Grazie e buon guadagno."
#property strict
//INPUT UTENTE
extern double TakeProfit =0;
extern double StopLoss =0;
extern double Lots =0.01;
extern int LOOKBACK = 17;

//---- buffers heikin ashi
double minimo[2148], massimo[1024], apertura[1024], chiusura[1024];


//----- buffers indicatori
double ma[1024], ma1[1024], ma2[1024], ma3[1024], ma4[1024];

//----
int barreContate = 0;
//Boolean che indica se e' stato aperta un'operazione SHORT
bool shortB = false;
//Boolean che indica se e' stato aperta un'operazione LONG
bool longB= true;

double TakeProfitCalcolato=0 , StopLossCalcolato =0;

void OnTick(){
   barreContate = IndicatorCounted();
   heikinAshi();
   vwma(); //ma
   rma(); //ma1
   sma(); //ma2
   wma(); //ma3
   ema(); //ma4
   if(nuovaCandela()){
      controlloPosizioneLong(OrdersTotal());
      controlloPosizioneShort(OrdersTotal());
   }
}
//+------------------------------------------------------------------+
//----------------------------
//---------- metodo per disegnare l'heikin ashi
void heikinAshi(){
   double haOpen=0.0, haHigh=0.0, haLow=0.0, haClose=0.0;
   if(barreContate > 0) 
       barreContate--;
   int pos = Bars - barreContate - 1;
   //Se l'array standard e' troppo piccolo, ridimensiona
   initArrayHa(pos);
   //Ridimensiona l'array per evitare accessi illegali
   if((ArraySize(apertura)-pos) <= 30){
      ArrayResize(apertura, ArraySize(apertura)+1000);
      ArrayResize(chiusura, ArraySize(chiusura)+1000);
      ArrayResize(minimo, ArraySize(minimo)+1000);
      ArrayResize(massimo, ArraySize(massimo)+1000);
   }
   while(pos >= 0){      
       haOpen = (apertura[pos+1] + chiusura[pos+1])/2;
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
   //Se l'array standard e' troppo piccolo, ridimensiona
   initiArrayMa(pos);
   //Resize dell'array per il vwma
   if((ArraySize(ma)-pos) <= 30){
      ArrayResize(ma, ArraySize(ma)+1000);
   }
   //calcolo inziale, non eliminare
   for(i = 1; i < LOOKBACK; i++, pos--){
      //(double) casting per evitare possibili perdite di dati
      vol += NormalizeDouble(iVolume(Symbol(),Period(),pos),0);
      sum += NormalizeDouble(chiusura[pos] * iVolume(Symbol(),Period(),pos),0);
   }
   while(pos >= 1){
      vol += NormalizeDouble(iVolume(Symbol(),Period(),pos),0);
      sum += NormalizeDouble(chiusura[pos] * iVolume(Symbol(),Period(),pos),0);
      ma[pos] = sum/vol;
	   sum -=NormalizeDouble(chiusura[pos + LOOKBACK - 1] * iVolume(Symbol(),Period(),pos + LOOKBACK - 1),0);
	   vol -=NormalizeDouble(iVolume(Symbol(),Period(), pos+LOOKBACK-1), 0);
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
   //Se l'array standard e' troppo piccolo, ridimensiona
   initiArrayMa1(pos);
   //Resize array per rma
   if((ArraySize(ma1)-pos) <= 30){
      ArrayResize(ma1, ArraySize(ma1)+1000);
   }
   while(pos >= 1){
      if (pos == Bars - 2){
         ma1[pos]=iMA(NULL, 0, LOOKBACK, 0, MODE_SMA, 0, pos);
      }else{
         ma1[pos]=(iMA(NULL, 0, 1, 0, MODE_SMA, 0, pos) - ma1[pos + 1]) * k + ma1[pos+1];
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
   //Se l'array standard e' troppo piccolo, ridimensiona
   initiArrayMa2(pos);
   //Resize array per sma
   if((ArraySize(ma2)-pos) <= 30){
      ArrayResize(ma2, ArraySize(ma2)+1000);
   }
   //calcolo inziale, non eliminare
   for(i=1; i < LOOKBACK; i++, pos--)
      sum+=chiusura[pos];
   while(pos>=1){
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
   int pos= Bars - 2;
   if(barreContate > 2) pos = Bars - barreContate - 1;
   //Se l'array standard e' troppo piccolo, ridimensiona
   initiArrayMa4(pos);
   //Resize array per ema
   if((ArraySize(ma4)-pos) <= 30){
      ArrayResize(ma4, ArraySize(ma4)+1000);
   }
   while(pos >= 1){
      if(pos == Bars - 2) ma4[pos + 1] = chiusura[pos + 1];
      ma4[pos] = chiusura[pos] * pr + ma4[pos + 1] * (1 - pr);
 	   pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void wma(){
   int pos = Bars - barreContate - 1;
   //Se l'array standard e' troppo piccolo, ridimensiona
   initiArrayMa3(pos);
   //Resize array per wma
   if((ArraySize(ma3)-pos) <= 30){
      ArrayResize(ma3, ArraySize(ma3)+1000);
   }
   while(pos >= 1){
      ma3[pos] = NormalizeDouble(iMA(NULL, 0, LOOKBACK, 0, MODE_LWMA, 0, pos),Digits);
      pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void controlloPosizioneLong(int ordiniTotali){
   int ticket;
   //CONTROLLO POSIZIONE LONG
   if(NormalizeDouble(ma[1],2) > NormalizeDouble(ma[2],2) &&
      NormalizeDouble(ma1[1],2) > NormalizeDouble(ma1[2],2) &&
      NormalizeDouble(ma2[1],2) > NormalizeDouble(ma2[2],2) &&
      NormalizeDouble(ma3[1],2) > NormalizeDouble(ma3[2],2) &&
      NormalizeDouble(ma4[1],2) > NormalizeDouble(ma4[2],2)){
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
   if(NormalizeDouble(ma[1],2) < NormalizeDouble(ma[2],2) &&
      NormalizeDouble(ma1[1],2) < NormalizeDouble(ma1[2],2) &&
      NormalizeDouble(ma2[1],2) < NormalizeDouble(ma2[2],2) &&
      NormalizeDouble(ma3[1],2) < NormalizeDouble(ma3[2],2) &&
      NormalizeDouble(ma4[1],2) < NormalizeDouble(ma4[2],2)){
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
//-------------
void initArrayHa(int dimensioneControllo){
   while(ArraySize(apertura) <= dimensioneControllo){
      ArrayResize(apertura, ArraySize(apertura)+1000);
      ArrayResize(chiusura, ArraySize(chiusura)+1000);
      ArrayResize(minimo, ArraySize(minimo)+1000);
      ArrayResize(massimo, ArraySize(massimo)+1000);
   }
}
//----------
void initiArrayMa(int dimensioneControllo){
   while(ArraySize(ma) <= dimensioneControllo){
      ArrayResize(ma, ArraySize(ma)+1000);
   }
}
//----
void initiArrayMa1(int dimensioneControllo){
   while(ArraySize(ma1) <= dimensioneControllo){
      ArrayResize(ma1, ArraySize(ma1)+1000);
   }
}
//----
void initiArrayMa2(int dimensioneControllo){
   while(ArraySize(ma2) <= dimensioneControllo){
      ArrayResize(ma2, ArraySize(ma2)+1000);
   }
}
//----
void initiArrayMa3(int dimensioneControllo){
   while(ArraySize(ma3) <= dimensioneControllo){
      ArrayResize(ma3, ArraySize(ma3)+1000);
   }
}
//----
void initiArrayMa4(int dimensioneControllo){
   while(ArraySize(ma4) <= dimensioneControllo){
      ArrayResize(ma4, ArraySize(ma4)+1000);
   }
}
//----
bool nuovaCandela(){
   static datetime candela_salvata;
   if(iTime(Symbol(),Period(),0)==candela_salvata){
      return false;
   }else{
      candela_salvata=iTime(Symbol(),Period(),0);
      return true;
   }
}