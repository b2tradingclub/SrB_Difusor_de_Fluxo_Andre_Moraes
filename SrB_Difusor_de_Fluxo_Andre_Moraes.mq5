//+------------------------------------------------------------------+
//|                                                         MACD.mq5 |
//|                   Copyright 2009-2017, MetaQuotes Software Corp. |
//|                                              http://www.mql5.com |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| O programa MACD original do MT5 foi alterado para se tonar o     |
//| Difusor de Fluxo do Andre Moraes.                                |
//| Autor: Sandro Roger Boschetti                                    |
//|  Data: 05/05/2019
//+------------------------------------------------------------------+


#property copyright   "2009-2017, MetaQuotes Software Corp."
#property link        "http://www.mql5.com"
#property description "Moving Average Convergence/Divergence"
#include <MovingAverages.mqh>
//--- indicator settings
#property indicator_separate_window
#property indicator_buffers 6
#property indicator_plots   3
#property indicator_type1   DRAW_LINE//DRAW_HISTOGRAM
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_color1  Red
#property indicator_color2  Orange
#property indicator_color3  Black
#property indicator_width1  1
#property indicator_width2  2
#property indicator_width3  2
#property indicator_label1  "MACD"
#property indicator_label2  "Signal"
#property indicator_label3  "Media Longa"

//--- input parameters
input int                InpFastEMA = 21;               // Fast EMA period
input int                InpSlowEMA = 55;               // Slow EMA period
input int                InpSignalSMA = 34;             // Signal SMA period
input int                InpMediaLongaEMA = 89;         // Media Longa
input ENUM_APPLIED_PRICE InpAppliedPrice = PRICE_CLOSE; // Applied price

//--- indicator buffers
double                   ExtMacdBuffer[];
double                   ExtSignalBuffer[];
double                   ExtFastMaBuffer[];
double                   ExtSlowMaBuffer[];
double                   ExtMLIndDataBuffer[];

//--- MA handles
int                      ExtFastMaHandle;
int                      ExtSlowMaHandle;
int                      ExtMLHandle;


//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit() {
//--- indicator buffers mapping
   SetIndexBuffer(0,ExtMacdBuffer,INDICATOR_DATA);
   SetIndexBuffer(1,ExtSignalBuffer,INDICATOR_DATA);
   SetIndexBuffer(2,ExtMLIndDataBuffer,INDICATOR_DATA);
   SetIndexBuffer(3,ExtFastMaBuffer,INDICATOR_CALCULATIONS);
   SetIndexBuffer(4,ExtSlowMaBuffer,INDICATOR_CALCULATIONS);
   
//--- sets first bar from what index will be drawn
   PlotIndexSetInteger(1,PLOT_DRAW_BEGIN,InpSignalSMA-1);
//--- name for Dindicator subwindow label
//   IndicatorSetString(INDICATOR_SHORTNAME,"MACD("+string(InpFastEMA)+","+string(InpSlowEMA)+","+string(InpSignalSMA)+")");
   IndicatorSetString(INDICATOR_SHORTNAME,"SrB: DF("+string(InpSlowEMA)+","+string(InpFastEMA)+","+string(InpSignalSMA)+")");
//--- get MA handles
   ExtFastMaHandle = iMA(NULL,0,InpFastEMA,0,MODE_EMA,InpAppliedPrice);
   ExtSlowMaHandle = iMA(NULL,0,InpSlowEMA,0,MODE_EMA,InpAppliedPrice);
       ExtMLHandle = iMA(NULL,0,InpMediaLongaEMA,0,MODE_EMA,InpAppliedPrice);
//--- initialization done
}


//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {


//--- check for data
   if (rates_total < InpSignalSMA) return(0);
 
//--- not all data may be calculated
   int calculated = BarsCalculated(ExtFastMaHandle);
   if (calculated < rates_total) {
      Print("Not all data of ExtFastMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
   }

   calculated = BarsCalculated(ExtSlowMaHandle);
   if (calculated < rates_total) {
      Print("Not all data of ExtSlowMaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
   }

   calculated = BarsCalculated(ExtMLHandle);
   if (calculated < rates_total) {
      Print("Not all data of ExtMediaLongaHandle is calculated (",calculated,"bars ). Error",GetLastError());
      return(0);
   }

//--- we can copy not all data
   int to_copy;
   if (prev_calculated > rates_total || prev_calculated < 0) {
      to_copy=rates_total;
   } else {
      to_copy = rates_total - prev_calculated;
      if(prev_calculated > 0) to_copy++;
   }

//--- get Fast EMA buffer
   if (IsStopped()) return(0); //Checking for stop flag

   if (CopyBuffer(ExtFastMaHandle,0,0,to_copy,ExtFastMaBuffer) <= 0) {
      Print("Getting fast EMA is failed! Error",GetLastError());
      return(0);
   }


//--- get SlowSMA buffer
   if (IsStopped()) return(0); //Checking for stop flag

   if (CopyBuffer(ExtSlowMaHandle,0,0,to_copy,ExtSlowMaBuffer) <= 0) {
      Print("Getting slow SMA is failed! Error",GetLastError());
      return(0);
   }


   int limit;
   if (prev_calculated == 0)
      limit = 0;
   else limit = prev_calculated - 1;


//--- calculate MACD
   for (int i = limit; i < rates_total && !IsStopped(); i++) {
       ExtMacdBuffer[i] = ExtFastMaBuffer[i] - ExtSlowMaBuffer[i];
   }

//--- Cálculo da média longa: Simple Moving Average do MACD, assim como o sinal
//   SimpleMAOnBuffer( rates_total, prev_calculated, 0, InpMediaLongaSMA, ExtMacdBuffer, ExtMLIndDataBuffer);
   ExponentialMAOnBuffer( rates_total, prev_calculated, 0, InpMediaLongaEMA, ExtMacdBuffer, ExtMLIndDataBuffer);

//--- calculate Signal
   SimpleMAOnBuffer( rates_total, prev_calculated, 0, InpSignalSMA, ExtMacdBuffer, ExtSignalBuffer);


   return(rates_total);
  }
//+------------------------------------------------------------------+
