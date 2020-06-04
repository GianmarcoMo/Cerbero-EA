//+------------------------------------------------------------------+
//|                                                     Multi-MA.mq4 |
//|                                                 Rodolfo Giuliana |
//|                                                               // |
//+------------------------------------------------------------------+
#property copyright "Rodolfo Giuliana"
#property link      "//"
#property version   "1.00"
#property strict

#property indicator_chart_window    // Indicatore nel char windows
#property indicator_buffers 5       // Numero buffer
#property indicator_color1 Lime     // Colore linea 'Media mobile ponderata volumi'
#property indicator_color2 Purple   // Colore linea 'Media mobile RSI'
#property indicator_color3 Red      // Colore linea 'Media mobile'
#property indicator_color4 Orange   // Colore linea 'Media mobile ponderata'
#property indicator_color5 Yellow   // Colore linea 'Media mobile ponderata esponenziale'

extern int LOOKBACK = 66;
 
double ma[], ma1[], ma2[], ma3[], ma4[];   // Dichiarazione dei buffer

//Init barre contate
int barreContante = 0;

int init()                          // Inizializzazione
  {
   SetIndexBuffer(0, ma);                     // Assegnazione ma
   SetIndexStyle(0, DRAW_LINE, STYLE_SOLID, 2);// Stile della linea ma
   
   SetIndexBuffer(1, ma1);                     // Assegnazione ma1
   SetIndexStyle(1, DRAW_LINE, STYLE_SOLID, 2);// Stile della linea ma1
   
   SetIndexBuffer(2, ma2);                     // Assegnazione ma2
   SetIndexStyle(2, DRAW_LINE, STYLE_SOLID, 2);// Stile della linea ma2
   
   SetIndexBuffer(3, ma3);                   // Assegnazione ma3
   SetIndexStyle(3, DRAW_LINE, STYLE_SOLID, 2);// Stile della linea ma3
   
   SetIndexBuffer(4, ma4);                      // Assegnazione ma4
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 2);     // Stile della linea ma4
   
   return 0;                                    // Uscita funzione init()
  }

int start(){
   barreContante = IndicatorCounted();
   vwma(); //ma
   rma(); //ma1
   sma(); //ma2
   wma(); //ma3
   ema(); //ma4
   
   /*double vwma= NormalizeDouble(ma[0],5);
   double vwma1=NormalizeDouble(ma[1],5);
   Alert("Valore: "+ DoubleToString(vwma,5));
   Alert("Valore precedente: "+ DoubleToString(vwma1,5));
   */
   return 0;
  }
  
//--------------------------------------------------------------------
void vwma(){
   double sum=0,
      vol=0;
   int i,
      pos = Bars - barreContante - 1;
   
   if(pos < LOOKBACK) pos = LOOKBACK;
   
   //calcolo inziale, non eliminare
   for(i = 1; i < LOOKBACK; i++, pos--){
      //(double) casting per evitare possibili perdite di dati
      vol +=(double) Volume[pos];
      sum += Close[pos] * Volume[pos];
   }
   
   while(pos >= 0){
      vol +=(double) Volume[pos];
      //sma(x * volume, y) / sma(volume, y)
      sum += Close[pos] * Volume[pos];
      ma[pos] = sum/vol;
	   sum -=(double) Close[pos + LOOKBACK - 1] * Volume[pos + LOOKBACK - 1];
	   vol -=(double) Volume[pos + LOOKBACK - 1];
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
      sum+=Close[pos];

   while(pos>=0){
      sum+=Close[pos];
      ma2[pos]=sum / LOOKBACK;
	   sum-=Close[pos + LOOKBACK - 1];
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
      if(pos == Bars - 2) ma4[pos + 1] = Close[pos + 1];
      ma4[pos] = Close[pos] * pr + ma4[pos + 1] * (1 - pr);
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
      ma1[pos]=iMA(NULL, 0, LOOKBACK, 0, MODE_SMA, 0, pos);
     }else{
      ma1[pos]=(iMA(NULL, 0, 1, 0, MODE_SMA, 0, pos) - ma1[pos + 1]) * k + ma1[pos+1];
     }
     pos--;
    } 
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void wma(){
   int pos = Bars - barreContante - 1;
   while(pos >= 0){
      ma3[pos] = iMA(NULL, 0, LOOKBACK, 0, MODE_LWMA, 0, pos);
      pos--;
   }
}
