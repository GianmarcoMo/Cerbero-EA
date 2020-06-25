//+------------------------------------------------------------------+
//|                                                      SigMACD.mq4 |
//|                                                 Gianmarco Moresi |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Gianmarco Moresi"
#property version   "1.00"
#property strict
//-----------------
//INPUT UTENTE
extern double TakeProfit =0;
extern double StopLoss =0;
extern double Lots =0.01;
//Boolean che indica se e' stato aperta un'operazione LONG
extern bool operazioneLong = false;
//Boolean che indica se e' stato aperta un'operazione SHORT
extern bool operazioneShort = false;

//----- DATI PER MACD
extern int fast_length = 12;
extern int slow_length = 26;
string src = "close";
extern int signal_length = 9;
bool sma_source = false;
bool sma_signal = false;
//----------
extern bool stato = true;
extern bool utilizzaTimer = true;
extern int orarioInizioInput = 0;
extern int minutoInizioInput = 0;
extern int orarioFineInput = 0;
extern int minutoFineInput = 0;
//------------------

//---- buffers heikin ashi
double minimo[2148], massimo[1024], apertura[1024], chiusura[1024];


double macd[1024];
double signal[1024];

//----
int barreContate = 0;
//---
//Orari per stop e start EA
int orarioInizio = 0, orarioFine = 0, minutoInizio = 0, minutoFine = 0;
//-------
double TakeProfitCalcolato=0 , StopLossCalcolato =0;
//------
bool notificaStart = false, notificaStop = false;

//----
int init(){
   //Funzione che divide l'orario dell'utente
   //e aggiunge fuso orario con server AvaTrade
   sistemaOrario();
   return 0;
}

//--------------
void OnTick(){
   if(utilizzaTimer){
      eaConTimer();
   }else{
      eaSenzaTimer();
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
//---------------------------------------------------------------
//-----------------------------------------------------------
void macd(){
   int pos = Bars - barreContate -1;
   //Se l'array standard e' troppo piccolo, ridimensiona
   initiArray(pos);
   //Resize array per MACD
   if((ArraySize(macd)-pos) <= 30){
      ArrayResize(macd, ArraySize(macd)+1000);
   }
   //Resize array per Signal
   if((ArraySize(signal)-pos) <= 30){
      ArrayResize(signal, ArraySize(signal)+1000);
   }
   
   while(pos >= 1){
      macd[pos]=NormalizeDouble(iMACD(Symbol(),0,fast_length,slow_length,signal_length,PRICE_CLOSE,MODE_MAIN,pos),Digits);
      signal[pos]=NormalizeDouble(iMACD(Symbol(),0,fast_length,slow_length,signal_length,PRICE_CLOSE,MODE_SIGNAL,pos), Digits);
      pos--;
   }
}
//-------------------------------------------------------------------
//--------------------------------------------------------------------
void controlloPosizioneLong(){
   int ticket;
   //CONTROLLO POSIZIONE LONG
   if(NormalizeDouble(macd[2],2) < NormalizeDouble(macd[1],2) &&
      NormalizeDouble(signal[2],2) < NormalizeDouble(macd[1],2)){
      //Se non e' stata aperta un'operazione LONG
      //prosegue con l'apertura e chiusura del SELL
      if(!operazioneLong){
         setTakeAndStop(Ask,1);
         //Ordine 'stabilito' ma non inviato.
         ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 0, StopLossCalcolato,
                          TakeProfitCalcolato, "MACD BUY", 0, 0, Blue);
         if(ticket > 0){
            //Apre operazione BUY
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("MACD ha aperto un'operazione BUY @" + DoubleToString(OrderOpenPrice(),2));
            
            //Segna shortB su false perche' verrano chiuse tutte le operazioni sell
            operazioneShort = false;
            //Segna longB su true perche' e' stata aperta un'operazione long
            operazioneLong = true;
         }
      }
      chiudiOrdini(1);
   }
}
//----------------------------------
//------------------------
void controlloPosizioneShort(){
   int ticket;
   //CONTROLLO POSIZIONE SHORT
   if(NormalizeDouble(macd[2],2) > NormalizeDouble(macd[1],2) && 
      NormalizeDouble(signal[2],2) > NormalizeDouble(signal[1],2)){
      //Se non e' stata aperta un'operazione SELL
      //prosegue con l'apertura e chiusura del BUY
      if(!operazioneShort){
         setTakeAndStop(Bid,2);
         //Ordine 'stabilito' ma non inviato.
         ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 0, StopLossCalcolato,
                       TakeProfitCalcolato, "MACD SHORT", 0, 0, Red);
         if(ticket > 0){
            //Apre operazione SELL
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               Print("MACD ha aperto un'operazione SELL @" + DoubleToString(OrderOpenPrice(),2));
            //Indica che e' stata aperta operazione short
            operazioneShort = true;
            //indica che non ci sono operazioni buy aperte
            operazioneLong = false;
         }                  
      }
      chiudiOrdini(2);
   }
}
//---------------------------
//Inizializza i vari array quando si inserisce l'EA nel chart
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
void initiArray(int dimensioneControllo){
   //Array macd
   while(ArraySize(macd) <= dimensioneControllo){
      ArrayResize(macd, ArraySize(macd)+1000);
   }
   //Array signal
   while(ArraySize(signal) <= dimensioneControllo){
      ArrayResize(signal, ArraySize(signal)+1000);
   }
}

//--------------------------------+
//Controlla se e'  stata generata una nuova candela
bool nuovaCandela(){
   static datetime candela_salvata;
   if(iTime(Symbol(),Period(),0)==candela_salvata){
      return false;
   }else{
      candela_salvata=iTime(Symbol(),Period(),0);
      return true;
   }
}
//------------
void setTakeAndStop(double prezzoInput, int tipoOperazione){
   //1 - operazione long
   //2 - operazione short
   if(tipoOperazione == 1){   //LONG
      if(StopLoss > 0){
         StopLossCalcolato = NormalizeDouble(prezzoInput - StopLoss*Point,Digits);
      }
      if(TakeProfit > 0){
         TakeProfitCalcolato = NormalizeDouble(prezzoInput + TakeProfit*Point,Digits);
      }
   }else{                     //SHORT
      if(StopLoss > 0){
         StopLossCalcolato = NormalizeDouble(prezzoInput + StopLoss*Point,Digits);
      }
      if(TakeProfit > 0){
         TakeProfitCalcolato = NormalizeDouble(prezzoInput - TakeProfit*Point,Digits);
      }
   }
}
//-----
bool controlloOrario(){
   //Se l'orario attuale e' compreso tra l'orario di inizio e di fine
   //l'ea deve continuare a lavorare
   if(TimeHour(TimeCurrent()) == orarioInizio &&
      TimeMinute(TimeCurrent()) == minutoInizio){
      stato = true;
   }
   if(TimeHour(TimeCurrent()) == orarioFine &&
      TimeMinute(TimeCurrent()) == minutoFine){
      stato = false;
   }
   return stato;
}
//--------------
//--------------------
void sistemaOrario(){
   orarioInizio = 0; orarioFine = 0; minutoInizio = 0; minutoFine = 0;
   orarioInizio = orarioInizioInput - 2;
   orarioFine = orarioFineInput - 2;
   minutoInizio = minutoInizioInput;
   minutoFine = minutoFineInput;
}
//--------------
void chiudiOrdini(int tipoOperazioneAperta){
   //1 -- long
   //2 -- short
   if(tipoOperazioneAperta == 1){ // operazione BUY aperta, chiudi SELL
      //Se ci sono ordini (SELL), li chiude
      if(OrdersTotal() > 0){
         //Controlla gli ordini aperti
         for(int k=0; k < OrdersTotal(); k++){
            if(!OrderSelect(k,SELECT_BY_POS,MODE_TRADES))
                  continue;
            //Controlla che il simbolo e' uguale a quello attuale
            if(OrderSymbol()==Symbol()){
               //Se il tipo e' SELL
               //Chiuse l'operazione
               if(OrderType() == OP_SELL){
                  if(OrderClose(OrderTicket(),OrderLots(),Ask,0,Violet))
                     Print("Cerbero ha chiuso un'operazione SELL!");
               }
            }
         }
      }
   }else{ //operazione sell aperta, chiudi Buy
      //Se ci sono altri ordini (BUY), le chiude tutte
      if(OrdersTotal() > 0 ){
         //Controlla gli ordini aperti
         for(int k=0; k < OrdersTotal(); k++){
            if(!OrderSelect(k,SELECT_BY_POS,MODE_TRADES))
                  continue;
            if(OrderType()<= OP_SELL &&
               OrderSymbol()==Symbol()){
               //Se il tipo e' BUY
               //Chiuse l'operazione
               if(OrderType() == OP_BUY){
                  if(OrderClose(OrderTicket(),OrderLots(),Bid,0,Violet))
                     Print("Cerbero ha chiuso un'operazione BUY!");
               }
            }
         }
      }
   }
}
//------------------
void eaConTimer(){
   //Controlla l'orario
   if(controlloOrario()){ //Se Cerbero e' acceso
      if(!notificaStart){
         Print("Cerbero ha iniziato a lavorare!");
         notificaStart=true;
         notificaStop=false;
      }
      barreContate = IndicatorCounted();
      heikinAshi();
      if(nuovaCandela()){
         macd();
         controlloPosizioneLong();
         controlloPosizioneShort();
      }
   }else{ // se Cerbero e' spento
      chiudiOrdini(1);
      chiudiOrdini(2);
      operazioneLong = false;
      operazioneShort = false;
      if(!notificaStop){
         //SendNotification("Cerbero e' stato fermato come da sua richiesta.");
         //SendNotification("Buona proseguimento!");
         notificaStop=true;
         notificaStart=false;
      }
   }
}
//------
void eaSenzaTimer(){
   barreContate = IndicatorCounted();
   heikinAshi();
   if(nuovaCandela()){
      macd();
      controlloPosizioneLong();
      controlloPosizioneShort();
   }
}