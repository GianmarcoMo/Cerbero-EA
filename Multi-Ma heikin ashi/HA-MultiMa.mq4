//+------------------------------------------------------------------+
//|                                                   HA-MultiMa.mq4 |
//|                                                 Rodolfo Giuliana |
//|                                                               // |
//+------------------------------------------------------------------+
#property copyright "Rodolfo Giuliana"
#property link      "//"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 5
#property indicator_color1 Red
#property indicator_color2 Green
#property indicator_color3 Red
#property indicator_color4 Green
// MEDIE----
#property indicator_color5 Lime     // Colore linea 'Media mobile ponderata volumi'

//----
extern color OmbraRibasso = Red;
extern color OmbraRialzo = Green;
extern color CandelaRibasso = Red;
extern color CandelaRiazo = Green;
extern int LOOKBACK = 66;
//---- buffers
double minimo[3000];
double massimo[3000];
double apertura[3000];
double chiusura[3000];

//----- buffers indicatori
double ma[3000];

//----
int barreContate=0;
//------------------------------------------
//------------------------------------------
int init()
  {
//---- indicators
   SetIndexStyle(0, DRAW_HISTOGRAM, 0, 1, OmbraRibasso);
   SetIndexBuffer(0, minimo);
   SetIndexStyle(1, DRAW_HISTOGRAM, 0, 1, OmbraRialzo);
   SetIndexBuffer(1, massimo);
   SetIndexStyle(2, DRAW_HISTOGRAM, 0, 4, CandelaRibasso);
   SetIndexBuffer(2, apertura);
   SetIndexStyle(3, DRAW_HISTOGRAM, 0, 4, CandelaRiazo);
   SetIndexBuffer(3, chiusura);
//---------- medie mobili
   SetIndexBuffer(4, ma);                     // Assegnazione ma
   SetIndexStyle(4, DRAW_LINE, STYLE_SOLID, 2, indicator_color5);// Stile della linea ma
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
   vwma();
   return 0;
}
//----------------------------
//---------- metodo per disegnare l'heikinashi
int heikinAshi(){
   double haOpen, haHigh, haLow, haClose;
   if(Bars <= 10) 
       return(0);
   
//---- check for possible errors
   if(barreContate < 0) 
       return(-1);
//---- last counted bar will be recounted
   if(barreContate > 0) 
       barreContate--;
   int pos = Bars - barreContate - 1;

   while(pos >= 0){
       haOpen = (apertura[pos+1] + chiusura[pos+1]) / 2;
       haClose = (Open[pos] + High[pos] + Low[pos] + Close[pos]) / 4;
       haHigh = MathMax(High[pos], MathMax(haOpen, haClose));
       haLow = MathMin(Low[pos], MathMin(haOpen, haClose));
       if(haOpen  <haClose) 
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
   
   while(pos >= 0){
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