//+------------------------------------------------------------------+
//|                                                 RsiMmtDataSniffer.mq4 |
//|                     Copyright 2017, investdata.000webhostapp.com |
//|                             https://ichimoku-expert.blogspot.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, investdata.000webhostapp.com"
#property link      "https://ichimoku-expert.blogspot.com"
#property version   "1.00"
#property strict

bool enableFileLog=true;
int file_handle=INVALID_HANDLE; // File handle
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//string exportPath = "C:\\Users\\InvesdataSystems\\Documents\\NetBeansProjects\\investdata\\public_html\\alerts\\data_history";

int OnInit()
  {
   ObjectDelete(0,"Text");

   long chart_ID=0;
   string name="Text";
   int sub_window=0;
   datetime time=0;
   double price=0;
   string text="Text";
   string font="Arial";
   int font_size=15;
   color clr=clrDarkGreen; // color
   double angle=0.0; // text slope
                     //ENUM_ANCHOR_POINT anchor=ANCHOR_LEFT_UPPER; // anchor type
   bool back=false; // in the background
   bool selection=true; // highlight to move
   bool hidden=true; // hidden in the object list
   long z_order=0;

   time=TimeCurrent();
   price=SymbolInfoDouble(Symbol(),SYMBOL_BID);

   if(ObjectCreate(chart_ID,name,OBJ_TEXT,sub_window,time,price))
     {
      //printf("obj created");
      ObjectSetString(chart_ID,name,OBJPROP_TEXT,text);
      ObjectSetString(chart_ID,name,OBJPROP_FONT,font);
      ObjectSetInteger(chart_ID,name,OBJPROP_FONTSIZE,font_size);
      ObjectSetDouble(chart_ID,name,OBJPROP_ANGLE,angle);
      ObjectSetInteger(chart_ID,name,OBJPROP_COLOR,clr);
      ObjectSetInteger(chart_ID,name,OBJPROP_BACK,back);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTABLE,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_SELECTED,selection);
      ObjectSetInteger(chart_ID,name,OBJPROP_HIDDEN,hidden);
      ObjectSetInteger(chart_ID,name,OBJPROP_ZORDER,z_order);
     }
   printf("exportDir = "+TerminalInfoString(TERMINAL_COMMONDATA_PATH));
   MqlDateTime mqd;
   TimeCurrent(mqd);
   string timestamp=string(mqd.year)+IntegerToString(mqd.mon,2,'0')+IntegerToString(mqd.day,2,'0')+IntegerToString(mqd.hour,2,'0')+IntegerToString(mqd.min,2,'0')+IntegerToString(mqd.sec,2,'0');

   if(enableFileLog)
     {
      string strPeriod = EnumToString((ENUM_TIMEFRAMES)Period());
      StringReplace(strPeriod, "PERIOD_", "");
      file_handle=FileOpen(Symbol()+"_"+strPeriod+"_"+timestamp+"_backup.csv",FILE_CSV|FILE_WRITE|FILE_ANSI|FILE_COMMON);
      if(file_handle>0)
        {
         string sep=",";
         FileWrite(file_handle,"Timestamp"+sep+"Name"+sep+"Buy"+sep+"Sell"+sep+"Spread"+sep+"Broker"+sep+"Period"+sep+"RSI"+sep+"Momentum");
        }
      else
        {
         printf("error : "+GetLastError());
        }
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {

   ObjectDelete(0,"Text");

   if(enableFileLog)
     {
      FileClose(file_handle);
     }

/*if (reason==3){
      printf("deinit reason = REASON_CHARTCHANGE");
   }*/

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool runOnce=false; // false : run for each tick
bool dontRunAnymore=false;

MqlDateTime mqd_ot;
MqlTick last_tick_ot;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTick()
  {

//printf("running");
   if(dontRunAnymore==false)
     {
      int stotal=SymbolsTotal(true); // seulement les symboles dans le marketwatch (false)
      ENUM_TIMEFRAMES workingPeriod=PERIOD_M15;
      for(int sindex=0; sindex<stotal; sindex++)
        {
         string sname=SymbolName(sindex,true);

         double rsi14=iRSI(sname,Period(),14,PRICE_CLOSE,0);

         if(sname==Symbol())
           {

            bool surachat = false;
            bool survente = false;
            if(rsi14>70 && rsi14!=0)
              {
               string msg=sname+" : Surachat RSI14 ("+EnumToString((ENUM_TIMEFRAMES) Period())+") = "+DoubleToString(rsi14);
               //printf(msg);
               //SendNotification(msg);
               surachat=true;
              }
            else if(rsi14<30 && rsi14!=0)
              {
               string msg=sname+" : Survente RSI14 ("+EnumToString((ENUM_TIMEFRAMES) Period())+") = "+DoubleToString(rsi14);
               //printf(msg);
               //SendNotification(msg);
               survente=true;
              }
            else
              {
               //printf(sname+" : RSI14 "+EnumToString(Period())+" = "+DoubleToString(rsi));
              }

            double m=iMomentum(sname,Period(),14,PRICE_CLOSE,0);

            ObjectSetString(0,"Text",OBJPROP_TEXT,"RSI="+DoubleToString(rsi14)+" M="+DoubleToString(m));
            ObjectSet("Text",OBJPROP_XDISTANCE,100);
            ObjectSet("Text",OBJPROP_YDISTANCE,100);

            if(enableFileLog)
              {
               // export des données :)
               if(file_handle>0)
                 {
                  TimeCurrent(mqd_ot);
                  string timestamp=string(mqd_ot.year)+"-"+IntegerToString(mqd_ot.mon,2,'0')+"-"+IntegerToString(mqd_ot.day,2,'0')+" "+IntegerToString(mqd_ot.hour,2,'0')+":"+IntegerToString(mqd_ot.min,2,'0')+":"+IntegerToString(mqd_ot.sec,2,'0')+"."+GetTickCount();

                  double prix_achat;
                  double prix_vente;
                  double spread;

                  if(SymbolInfoTick(sname,last_tick_ot))
                    {
                     prix_achat = last_tick_ot.ask;
                     prix_vente = last_tick_ot.bid;

                     string str_prix_achat = DoubleToString(prix_achat);
                     string str_prix_vente = DoubleToString(prix_vente);
                     string str_spread = DoubleToString(prix_achat-prix_vente);
                     string str_broker = AccountCompany();
                     string period=EnumToString((ENUM_TIMEFRAMES)Period());;
                     string rsi=DoubleToString(rsi14);
                     string momentum=DoubleToString(m);

                     string sep=",";
                     FileWrite(file_handle,timestamp+sep+sname+sep+str_prix_achat+sep+str_prix_vente+sep+str_spread+sep+str_broker+sep+period+sep+rsi+sep+momentum);
                     //sell affiché par défaut dans MT5
                    }
                 }
              }

           }

        }
     }
   if(runOnce==true) dontRunAnymore=true;
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+

void OnTimer()
  {
  }
//+------------------------------------------------------------------+
//| Tester function                                                  |
//+------------------------------------------------------------------+
double OnTester()
  {
//---
   double ret=0.0;
//---

//---
   return(ret);
  }
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---

  }
//+------------------------------------------------------------------+
