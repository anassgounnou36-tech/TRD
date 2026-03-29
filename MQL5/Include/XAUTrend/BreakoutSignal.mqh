#pragma once

#include "Types.mqh"
#include "BarUtils.mqh"

XAUSignalDecision XAU_EvaluateBreakoutSignalAtShift(const string symbol,
                                                    const ENUM_TIMEFRAMES signal_tf,
                                                    const ENUM_XAU_REGIME regime,
                                                    const int signal_shift,
                                                    const int lookback,
                                                    const double atr_value,
                                                    const double buffer_frac)
  {
   XAUSignalDecision out;
   out.signal=XAU_SIGNAL_NONE;
   out.breakout_high=0.0;
   out.breakout_low=0.0;
   out.signal_close=iClose(symbol,signal_tf,signal_shift);
   out.breakout_buffer=atr_value*buffer_frac;

   if(signal_shift<1 || lookback<=1 || atr_value<=0.0 || out.signal_close<=0.0)
      return(out);

   const int range_start_shift=signal_shift+1;
   out.breakout_high=XAU_HighestHigh(symbol,signal_tf,range_start_shift,lookback);
   out.breakout_low=XAU_LowestLow(symbol,signal_tf,range_start_shift,lookback);

   if(regime==XAU_REGIME_LONG && out.signal_close>(out.breakout_high+out.breakout_buffer))
      out.signal=XAU_SIGNAL_LONG;
   else if(regime==XAU_REGIME_SHORT && out.signal_close<(out.breakout_low-out.breakout_buffer))
      out.signal=XAU_SIGNAL_SHORT;

   return(out);
  }

XAUSignalDecision XAU_EvaluateBreakoutSignal(const string symbol,
                                             const ENUM_TIMEFRAMES signal_tf,
                                             const ENUM_XAU_REGIME regime,
                                             const int lookback,
                                             const double atr_value,
                                             const double buffer_frac)
  {
   return(XAU_EvaluateBreakoutSignalAtShift(symbol,signal_tf,regime,1,lookback,atr_value,buffer_frac));
  }
