#property strict
#property script_show_inputs

#include "../Include/XAUTrend/Types.mqh"
#include "../Include/XAUTrend/BarUtils.mqh"
#include "../Include/XAUTrend/IndicatorEngine.mqh"
#include "../Include/XAUTrend/RegimeFilter.mqh"
#include "../Include/XAUTrend/BreakoutSignal.mqh"
#include "../Include/XAUTrend/Diagnostics.mqh"
#include "../Include/XAUTrend/RiskModel.mqh"

input string InpSymbol = "XAUUSD";
input ENUM_TIMEFRAMES InpSignalTF = PERIOD_H1;
input ENUM_TIMEFRAMES InpRegimeTF = PERIOD_H4;
input int             InpRows = 50;
input int             InpRegimeEMAPeriod = 200;
input int             InpATRPeriod = 14;
input double          InpBreakoutBufferATRFrac = 0.10;
input int             InpSessionStartHour = 8;
input int             InpSessionStartMinute = 0;
input int             InpOpeningRangeMinutes = 60;

void OnStart()
  {
   const string symbol=(InpSymbol=="" ? _Symbol : InpSymbol);
   XAUIndicatorState indicators;
   XAURuntimeState runtime;
   runtime.day_start_time=0;
   runtime.day_start_equity=0.0;
   runtime.day_start_balance=0.0;
   runtime.trading_suspended_for_day=false;
   runtime.daily_blocker_reason="";
   runtime.blocker_reason="";
   runtime.regime=XAU_REGIME_NEUTRAL;
   indicators.h1_atr_handle=INVALID_HANDLE;
   indicators.h4_ema_handle=INVALID_HANDLE;

   string err="";
   if(!XAU_IndicatorInit(symbol,InpRegimeTF,InpRegimeEMAPeriod,InpSignalTF,InpATRPeriod,indicators,err))
     {
      PrintFormat("BarAudit init failed: %s",err);
      return;
     }

   Print("==== XAUTrend Bar Audit ====");
   Print("time;session;or_high;or_low;breakout_valid;reclaim_valid;bias_filter;blocker_reason;atr;signal;setup_type");

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
       const XAUSignalDecision s=XAU_EvaluateBreakoutSignalAtShift(symbol,InpSignalTF,regime,shift,InpSessionStartHour,InpSessionStartMinute,InpOpeningRangeMinutes,atr,InpBreakoutBufferATRFrac);
       XAU_ResetDayIfNeeded(runtime,signal_time);
       double dd=0.0;
       const bool daily_block=XAU_IsDailyKillTriggered(runtime,2.0,true,dd);
       const string blocker=(daily_block ? StringFormat("Daily kill active (dd=%.2f%%)",dd) : s.blocker_reason);

       PrintFormat("%s;%s;%.5f;%.5f;%s;%s;%s;%s;%.5f;%s;%s",
                   TimeToString(signal_time,TIME_DATE|TIME_MINUTES),
                   TimeToString(s.session_start,TIME_DATE|TIME_MINUTES),
                   s.breakout_high,
                   s.breakout_low,
                   (s.breakout_valid?"YES":"NO"),
                   (s.reclaim_valid?"YES":"NO"),
                   (s.bias_valid?"YES":"NO"),
                   (blocker==""?"none":blocker),
                   atr,
                   XAU_SignalToString(s.signal),
                   s.setup_type);
      }

   XAU_IndicatorRelease(indicators);
  }
