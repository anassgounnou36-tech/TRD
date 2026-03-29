#property strict
#property script_show_inputs

#include "../Include/XAUTrend/Types.mqh"
#include "../Include/XAUTrend/BarUtils.mqh"
#include "../Include/XAUTrend/IndicatorEngine.mqh"
#include "../Include/XAUTrend/RegimeFilter.mqh"
#include "../Include/XAUTrend/BreakoutSignal.mqh"
#include "../Include/XAUTrend/Diagnostics.mqh"

input string          InpSymbol = _Symbol;
input ENUM_TIMEFRAMES InpSignalTF = PERIOD_H1;
input ENUM_TIMEFRAMES InpRegimeTF = PERIOD_H4;
input int             InpRows = 50;
input int             InpRegimeEMAPeriod = 200;
input int             InpBreakoutLookback = 55;
input int             InpATRPeriod = 14;
input double          InpBreakoutBufferATRFrac = 0.10;

void OnStart()
  {
   const string symbol=(InpSymbol=="" ? _Symbol : InpSymbol);
   XAUIndicatorState indicators;
   indicators.h1_atr_handle=INVALID_HANDLE;
   indicators.h4_ema_handle=INVALID_HANDLE;

   string err="";
   if(!XAU_IndicatorInit(symbol,InpRegimeTF,InpRegimeEMAPeriod,InpSignalTF,InpATRPeriod,indicators,err))
     {
      PrintFormat("BarAudit init failed: %s",err);
      return;
     }

   Print("==== XAUTrend Bar Audit ====");
   Print("time;close;regime;breakout_high;breakout_low;atr;signal");

   for(int shift=1;shift<=InpRows;shift++)
     {
      const datetime signal_time=iTime(symbol,InpSignalTF,shift);
      if(signal_time<=0)
         break;

      const datetime decision_time=(shift>1 ? iTime(symbol,InpSignalTF,shift-1) : iTime(symbol,InpSignalTF,0));
      int regime_shift=iBarShift(symbol,InpRegimeTF,decision_time,false);
      if(regime_shift>=0)
         regime_shift+=1; // completed H4 bar as of decision time
      if(regime_shift<1)
         continue;

      double atr=0.0;
      if(!XAU_GetATR(indicators,shift,atr))
         continue;

      string reason="";
      const ENUM_XAU_REGIME regime=XAU_ComputeRegimeAtShift(symbol,InpRegimeTF,indicators,regime_shift,reason);
      const XAUSignalDecision s=XAU_EvaluateBreakoutSignalAtShift(symbol,InpSignalTF,regime,shift,InpBreakoutLookback,atr,InpBreakoutBufferATRFrac);

      PrintFormat("%s;%.5f;%s;%.5f;%.5f;%.5f;%s",
                  TimeToString(signal_time,TIME_DATE|TIME_MINUTES),
                  iClose(symbol,InpSignalTF,shift),
                  XAU_RegimeToString(regime),
                  s.breakout_high,
                  s.breakout_low,
                  atr,
                  XAU_SignalToString(s.signal));
     }

   XAU_IndicatorRelease(indicators);
  }
