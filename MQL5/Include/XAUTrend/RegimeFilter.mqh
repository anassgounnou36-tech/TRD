#pragma once

#include "Types.mqh"
#include "IndicatorEngine.mqh"

ENUM_XAU_REGIME XAU_ComputeRegime(const string symbol,
                                  const ENUM_TIMEFRAMES regime_tf,
                                  const XAUIndicatorState &indicators,
                                  string &reason)
  {
   reason="";
   double ema1=0.0,ema2=0.0;
   if(!XAU_GetEMAValues(indicators,1,2,ema1,ema2))
     {
      reason="EMA data not ready";
      return(XAU_REGIME_NEUTRAL);
     }

   const double close1=iClose(symbol,regime_tf,1);
   if(close1<=0.0)
     {
      reason="H4 close data unavailable";
      return(XAU_REGIME_NEUTRAL);
     }

   if(close1>ema1 && ema1>ema2)
      return(XAU_REGIME_LONG);
   if(close1<ema1 && ema1<ema2)
      return(XAU_REGIME_SHORT);

   return(XAU_REGIME_NEUTRAL);
  }
