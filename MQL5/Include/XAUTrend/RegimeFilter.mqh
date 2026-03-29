#pragma once

#include "Types.mqh"
#include "IndicatorEngine.mqh"

ENUM_XAU_REGIME XAU_ComputeRegimeAtShift(const string symbol,
                                         const ENUM_TIMEFRAMES regime_tf,
                                         const XAUIndicatorState &indicators,
                                         const int shift,
                                         string &reason)
  {
   reason="";
   if(shift<1)
     {
      reason="Invalid regime shift";
      return(XAU_REGIME_NEUTRAL);
     }

   double ema_now=0.0,ema_prev=0.0;
   if(!XAU_GetEMAValues(indicators,shift,shift+1,ema_now,ema_prev))
     {
      reason="EMA data not ready";
      return(XAU_REGIME_NEUTRAL);
     }

   const double close_value=iClose(symbol,regime_tf,shift);
   if(close_value<=0.0)
     {
      reason="H4 close data unavailable";
      return(XAU_REGIME_NEUTRAL);
     }

   if(close_value>ema_now && ema_now>ema_prev)
      return(XAU_REGIME_LONG);
   if(close_value<ema_now && ema_now<ema_prev)
      return(XAU_REGIME_SHORT);

   return(XAU_REGIME_NEUTRAL);
  }

ENUM_XAU_REGIME XAU_ComputeRegime(const string symbol,
                                  const ENUM_TIMEFRAMES regime_tf,
                                  const XAUIndicatorState &indicators,
                                  string &reason)
  {
   return(XAU_ComputeRegimeAtShift(symbol,regime_tf,indicators,1,reason));
  }
