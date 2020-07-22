#property copyright "Vortex EA"
#property version   "1.0"
#property description "Make money, great again! "
#property strict
//-----------------
//INPUT DELL'UTENTE
input string DatiOperazioni = "------------------------------------";
extern double TakeProfit = 0;
extern double StopLoss = 0;
extern double Lots = 0;
//--------------------
//INPUT PER OPERAZIONI
extern string DatiOperazioniRobot = "------------------------------------";
extern bool operazioneLong = false;
extern bool operazioneShort = false;
//-----------------
//INPUT ROBOT
input string DatiRobot = "------------------------------------";
extern bool stato = false;
//INPUT TIMER
extern bool utilizzaTimer = true;
extern int orarioInizioInput = 0;
extern int minutoInizioInput = 0;
extern int orarioFineInput = 0;
extern int minutoFineInput = 0;
//-----------------
//INPUT DATI VORTEX
input string DatiVortex = "----------------------------------------";
extern int VLength = 14;
//INPUT DATI MEDIA MOBILE
input string DatiSMMA = "------------------------------------------";
extern int SMMALength = 15;
extern int ShiftSMMA = 0;
//----------
//VARIABILI

//Buffers per Vortex
double PlusVI[3000];
double MinusVI[3000];
double PlusVM[3000];
double MinusVM[3000];
double SumPlusVM[3000];
double SumMinusVM[3000];
double SumTR[3000];
//SMMA
double smma;

int barreContate = 0;

//Orari per stop e start EA
int orarioInizio = 0, orarioFine = 0, minutoInizio = 0, minutoFine = 0;
//-------
double TakeProfitCalcolato=0 , StopLossCalcolato =0;
//variabile per evitare di aprire l'operazione iniziale
bool operazioneMattina = false;

//+------------------------------------------------------------------+
int OnInit(){
   barreContate = 0;
   orarioInizio = 0; orarioFine = 0; minutoInizio = 0; minutoFine = 0;
   TakeProfitCalcolato=0 ; StopLossCalcolato =0;
   operazioneMattina = false;
   operazioneLong = false;
   operazioneShort = false;
   sistemaOrario();
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
void OnTick(){
  if(utilizzaTimer){
    eaConTimer();
  }else{
    eaSenzaTimer();
  }
}
//+------------------------------------------------------------------+
bool nuovaCandela(){
  static datetime candela_salvata;
  if(iTime(Symbol(),Period(),0)==candela_salvata){
    return false;
  }else{
    candela_salvata=iTime(Symbol(),Period(),0);
    return true;
  }
}
//----------------------------------------------------------
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
//--------------------
bool controlloOrario(){
  //Se l'orario attuale e' compreso tra l'orario di inizio e di fine
  //l'ea deve continuare a lavorare
  if(TimeHour(TimeCurrent()) == orarioInizio &&
    TimeMinute(TimeCurrent()) == minutoInizio){
    stato = true;
  }
  if(TimeHour(TimeCurrent()) == orarioFine &&
    TimeMinute(TimeCurrent()) == minutoFine){
    //Se e' orario di chiusura,
    //chiude gli ordini, impsta tutto di default
    chiudiOrdini(1);
    chiudiOrdini(2);
    stato = false;
    operazioneMattina = false;
    operazioneLong = false;
    operazioneShort = false;
  }
  return stato;
}
//-------------------
void sistemaOrario(){
   orarioInizio = 0; orarioFine = 0; minutoInizio = 0; minutoFine = 0;
   orarioInizio = orarioInizioInput - 2;
   orarioFine = orarioFineInput - 2;
   minutoInizio = minutoInizioInput;
   minutoFine = minutoFineInput;
}
//----------------------------------------
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
               if(OrderType() == OP_SELL && OrderComment()=="Vortex SELL"){
                  if(OrderClose(OrderTicket(),OrderLots(),Ask,0,Violet))
                     SendNotification("Cerbero ha chiuso un'operazione SELL!");
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
            if(OrderSymbol()==Symbol()){
               //Se il tipo e' BUY
               //Chiuse l'operazione
               if(OrderType() == OP_BUY && OrderComment()=="Vortex BUY"){
                  if(OrderClose(OrderTicket(),OrderLots(),Bid,0,Violet))
                     SendNotification("Cerbero ha chiuso un'operazione BUY!");
               }
            }
         }
      }
   }
}
//----------------
void eaConTimer(){
  //Controlla l'orario
  if(controlloOrario()){ //Se Cerbero e' acceso
    barreContate = IndicatorCounted();
    if(nuovaCandela()){
      Vortex();
      SMMA();
      controlloPosizioneLong();
      controlloPosizioneShort();
    }
  }
}
//-----------------
void eaSenzaTimer(){
  barreContate = IndicatorCounted();
  if(nuovaCandela()){
    Vortex();
    SMMA();
    controlloPosizioneLong();
    controlloPosizioneShort();
  }
}
void reSizeVortex(int pos){
  ArrayResize(PlusVI, ArraySize(PlusVI)+1000);
  ArrayResize(MinusVI, ArraySize(MinusVI)+1000);
  ArrayResize(PlusVM, ArraySize(PlusVM)+1000);
  ArrayResize(MinusVM, ArraySize(MinusVM)+1000);
  ArrayResize(SumPlusVM, ArraySize(SumPlusVM)+1000);
  ArrayResize(SumMinusVM, ArraySize(SumMinusVM)+1000);
  ArrayResize(SumTR, ArraySize(SumTR)+1000);
}
//------------------
void Vortex(){
  if(barreContate > 0)   barreContate--;
  int pos = Bars - barreContate;
  if(barreContate == 0) pos -= 1 + VLength; 
  int i;
  //Resize dell'array per il vwma
  if((ArraySize(PlusVI)-pos) <= 30){ 
    reSizeVortex(pos);
  }

  for(i = 0; i < pos; i++){
    SumPlusVM[i] = 0;
    SumMinusVM[i] = 0;
    SumTR[i]= 0;  
  }

  for(i = 0; i < pos; i++){
    PlusVM[i] = MathAbs(iHigh(Symbol(), Period(), i) - iLow(Symbol(), Period(), i + 1));
    MinusVM[i] = MathAbs( iLow(Symbol(), Period(), i) - iHigh(Symbol(), Period(), i+1));  
  }

  for(i = 0; i < pos; i++){
    for(int j = 0; j <= VLength - 1; j++){
      SumPlusVM[i] += PlusVM[i + j];
      SumMinusVM[i] += MinusVM[i + j];
      SumTR[i] += iATR(NULL,0,1,i + j);
    }
  }

  for(i = 0; i < pos; i++){
    if(SumTR[i]!=0){
       PlusVI[i] = SumPlusVM[i] / SumTR[i];
       MinusVI[i] = SumMinusVM[i] / SumTR[i];
    }
  }
}
//------------------
void SMMA(){
   smma = NormalizeDouble(iMA(NULL, 0, SMMALength, ShiftSMMA, MODE_SMMA, PRICE_CLOSE, 0), 2);
}

//--------------------------------------------------------------------
void controlloPosizioneLong(){
   int ticket;
   //PREZZO SOPRA LA MEDIA MOBILE 15 SMOOTHED E VORTEX PLUS (VERDE) CROSSOVER VORTEX MINUS (ROSSO) ALLORA APRI LONG.
  //SHORT AL CONTRARIO 
   //CONTROLLO POSIZIONE LONG
   if(smma > Ask && PlusVI[1] > MinusVI[1]){
      //Permette di non aprire l'operazione appena si avvia Cerbero
      if(!operazioneMattina){
         operazioneMattina = true;
         //Segna shortB su false perche' verrano chiuse tutte le operazioni sell
         operazioneShort = false;
         //Segna longB su true perche' e' stata aperta un'operazione long
         operazioneLong = true;
      }
      //Se non e' stata aperta un'operazione LONG
      //prosegue con l'apertura e chiusura del SELL
      if(!operazioneLong){
         setTakeAndStop(Ask,1);
         //Ordine 'stabilito' ma non inviato.
         ticket = OrderSend(Symbol(), OP_BUY, Lots, Ask, 0, StopLossCalcolato,
                          TakeProfitCalcolato, "Vortex BUY", 0, 0, Blue);
         if(ticket > 0){
            //Apre operazione BUY
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               SendNotification("Vortex BUY @" + DoubleToString(OrderOpenPrice(),2));
            
            //Segna shortB su false perche' verrano chiuse tutte le operazioni sell
            operazioneShort = false;
            //Segna longB su true perche' e' stata aperta un'operazione long
            operazioneLong = true;
         }
      }
      chiudiOrdini(1);
   }
}
//---------------------------
//PREZZO SOPRA LA MEDIA MOBILE 15 SMOOTHED E VORTEX PLUS (VERDE) CROSSOVER VORTEX MINUS (ROSSO) ALLORA APRI LONG.
//SHORT AL CONTRARIO 
void controlloPosizioneShort(){
   int ticket;
   //CONTROLLO POSIZIONE SHORT
   if(smma < Bid && PlusVI[1] < MinusVI[1]){
      //Permette di non aprire l'operazione appena si avvia Cerbero
      if(!operazioneMattina){
         operazioneMattina = true;
         //Indica che e' stata aperta operazione short
         operazioneShort = true;
         //indica che non ci sono operazioni buy aperte
         operazioneLong = false;
      }
      //Se non e' stata aperta un'operazione SELL
      //prosegue con l'apertura e chiusura del BUY
      if(!operazioneShort){
         setTakeAndStop(Bid,2);
         //Ordine 'stabilito' ma non inviato.
         ticket = OrderSend(Symbol(), OP_SELL, Lots, Bid, 0, StopLossCalcolato,
                       TakeProfitCalcolato, "Vortex SELL", 0, 0, Red);
         if(ticket > 0){
            //Apre operazione SELL
            if(OrderSelect(ticket,SELECT_BY_TICKET,MODE_TRADES))
               SendNotification("Vortex SELL @" + DoubleToString(OrderOpenPrice(),2));
            //Indica che e' stata aperta operazione short
            operazioneShort = true;
            //indica che non ci sono operazioni buy aperte
            operazioneLong = false;
         }                  
      }
      chiudiOrdini(2);
   }
}
