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
   Print("time;close1;regime;breakout_high;breakout_low;atr;signal");

   for(int shift=1;shift<=InpRows;shift++)
     {
      const datetime t=iTime(symbol,InpSignalTF,shift);
      if(t<=0)
         break;

      double atr=0.0;
      if(!XAU_GetATR(indicators,shift,atr))
         continue;

      string reason="";
      ENUM_XAU_REGIME regime=XAU_ComputeRegime(symbol,InpRegimeTF,indicators,reason);
      XAUSignalDecision s=XAU_EvaluateBreakoutSignal(symbol,InpSignalTF,regime,InpBreakoutLookback,atr,InpBreakoutBufferATRFrac);

      PrintFormat("%s;%.5f;%s;%.5f;%.5f;%.5f;%s",
                  TimeToString(t,TIME_DATE|TIME_MINUTES),
                  iClose(symbol,InpSignalTF,shift),
                  XAU_RegimeToString(regime),
                  s.breakout_high,
                  s.breakout_low,
                  atr,
                  XAU_SignalToString(s.signal));
     }

   XAU_IndicatorRelease(indicators);
  }
