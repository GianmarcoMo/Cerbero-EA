//+------------------------------------------------------------------+
//|                                                   HA-MultiMa.mq4 |
//|                                                 Rodolfo Giuliana |
//|                                                               // |
//+------------------------------------------------------------------+
#property copyright "Rodolfo Giuliana"
#property link      "//"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 9
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 Red
#property indicator_color4 Green
// MEDIE----
#property indicator_color5 Lime     // Colore linea 'Media mobile ponderata volumi'
#property indicator_color6 Purple   // Colore linea 'Media mobile RSI'
#property indicator_color7 Red      // Colore linea 'Media mobile'
#property indicator_color8 Orange   // Colore linea 'Media mobile ponderata'
#property indicator_color9 Yellow   // Colore linea 'Media mobile ponderata esponenziale'

//----
extern int LOOKBACK = 17;
extern datetime orarioInizioInput = 0;
extern datetime orarioFineInput = 0;
//---- buffers
double minimo[3000];
double massimo[3000];
double apertura[3000];
double chiusura[3000];

//----- buffers indicatori
double ma[3000], ma1[3000], ma2[3000], ma3[3000], ma4[3000];

//----
int barreContate=0;
//------------------------------------------
//------------------------------------------
int init()
  {
  
  Print("Orario server: ", TimeToString(iTime(Symbol(),Period(),0), TIME_MINUTES));
//---- indicators
   SetIndexStyle(0, DRAW_HISTOGRAM, 0, 1, indicator_color1);
   SetIndexBuffer(0, minimo);
   SetIndexStyle(1, DRAW_HISTOGRAM, 0, 1, indicator_color2);
   SetIndexBuffer(1, massimo);
   SetIndexStyle(2, DRAW_HISTOGRAM, 0, 4, indicator_color1);
   SetIndexBuffer(2, apertura);
   SetIndexStyle(3, DRAW_HISTOGRAM, 0, 4, indicator_color2);
   SetIndexBuffer(3, chiusura);
//---------- medie mobili
   SetIndexBuffer(4, ma);                                         // Assegnazione ma
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 2, indicator_color5);// Stile della linea ma
   SetIndexBuffer(5, ma1);                                        // Assegnazione ma1
   SetIndexStyle(5, DRAW_LINE, STYLE_SOLID, 2, indicator_color6);// Stile della linea ma1
   SetIndexBuffer(6, ma2);                                        // Assegnazione ma2
   SetIndexStyle(6, DRAW_LINE, STYLE_SOLID, 2, indicator_color7);// Stile della linea ma2
   
   SetIndexBuffer(7, ma3);                                     // Assegnazione ma3
   SetIndexStyle(7, DRAW_LINE, STYLE_SOLID, 2, indicator_color8);// Stile della linea ma3
   
   SetIndexBuffer(8, ma4);                                           // Assegnazione ma4
   SetIndexStyle(8, DRAW_LINE, STYLE_SOLID, 2, indicator_color9);     // Stile della linea ma4
//----
   SetIndexDrawBegin(0, 10);
   SetIndexDrawBegin(1, 10);
   SetIndexDrawBegin(2, 10);
   SetIndexDrawBegin(3, 10);
//---- buffer per candele
   SetIndexBuffer(0, minimo);
   SetIndexBuffer(1, massimo);
   SetIndexBuffer(2, apertura);
   SetIndexBuffer(3, chiusura);

   return(0);
  }

//------------------------------------------
//------------------------------------------
int start(){
   barreContate = IndicatorCounted();
   heikinAshi();
   
   if(nuovaCandela()){
   orarioCorrente();
      vwma(); //ma
      rma(); //ma1
      sma(); //ma2
      wma(); //ma3
      ema(); //ma4
   }
   return 0;
}
//----------------------------
//---------- metodo per disegnare l'heikin ashi
int heikinAshi(){
   double haOpen, haHigh, haLow, haClose;
   if(Bars <= 10) 
       return(0);
   
//---- 
   if(barreContate < 0) 
       return(-1);
//----
   if(barreContate > 0) 
       barreContate--;
   int pos = Bars - barreContate - 1;

   while(pos >= 0){
       haOpen = (apertura[pos+1] + chiusura[pos+1]) / 2;
       haClose = (Open[pos] + High[pos] + Low[pos] + Close[pos]) / 4;
       haHigh = MathMax(High[pos], MathMax(haOpen, haClose));
       haLow = MathMin(Low[pos], MathMin(haOpen, haClose));
       if(haOpen  < haClose) 
         {
           minimo[pos] = haLow;
           massimo[pos] = haHigh;
         } 
       else
         {
           minimo[pos] = haHigh;
           massimo[pos] = haLow;
         } 
       apertura[pos] = haOpen;
       chiusura[pos] = haClose;
 	    pos--;
     }
   return 0;
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
      vol +=(double) Volume[pos];
      sum += chiusura[pos] * Volume[pos];
   }
   
   while(pos >= 1){
      vol +=(double) Volume[pos];
      sum += chiusura[pos] * Volume[pos];
      ma[pos] = sum/vol;
	   sum -=(double) chiusura[pos + LOOKBACK - 1] * Volume[pos + LOOKBACK - 1];
	   vol -=(double) Volume[pos + LOOKBACK - 1];
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
   int    pos= Bars - 2;
   
   if(barreContate > 2) pos = Bars - barreContate - 1;
   
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
   while(pos >= 1){
      ma3[pos] = iMA(NULL, 0, LOOKBACK, 0, MODE_LWMA, 0, pos);
      pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
//Funziona che fornisce in output se la candela attuale e'
//una nuova candela.
bool nuovaCandela(){
   static datetime candela_salvata;
   if(iTime(Symbol(),Period(),0)==candela_salvata){
      return false;
   }else{
      candela_salvata=iTime(Symbol(),Period(),0);
      return true;
   }
}
//--------------------
void orarioCorrente(){
   int orarioInizio = 0, orarioFine = 0, minutoInizio = 0, minutoFine = 0;
   orarioInizio = TimeHour(orarioInizioInput)-2;
   orarioFine = TimeHour(orarioFineInput)-2;
   minutoInizio = TimeMinute(orarioInizioInput);
   minutoFine = TimeMinute(orarioFineInput);
   
   if(TimeHour(iTime(Symbol(),Period(),0)) == orarioInizio && TimeMinute(iTime(Symbol(),Period(),0)) == minutoInizio){
      Print("Robot attivato");
   }if(TimeHour(iTime(Symbol(),Period(),0)) == orarioFine && TimeMinute(iTime(Symbol(),Period(),0)) == minutoFine){
      Print("Ordini chiusi.");
      Print("Robot fermato.");
   }
}