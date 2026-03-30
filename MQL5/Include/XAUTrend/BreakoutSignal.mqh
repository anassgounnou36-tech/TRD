#ifndef __BREAKOUTSIGNAL_MQH__
#define __BREAKOUTSIGNAL_MQH__

#include "Types.mqh"
#include "BarUtils.mqh"

bool XAU_BuildOpeningRange(const string symbol,
                           const ENUM_TIMEFRAMES signal_tf,
                           const int signal_shift,
                           const int session_start_hour,
                           const int session_start_minute,
                           const int opening_range_minutes,
                           double &or_high,
                           double &or_low,
                           datetime &session_start,
                           datetime &or_end_time)
  {
   or_high=0.0;
   or_low=0.0;
   session_start=0;
   or_end_time=0;
   if(signal_shift<1 || opening_range_minutes<=0)
      return(false);

   const datetime signal_time=iTime(symbol,signal_tf,signal_shift);
   if(signal_time<=0)
      return(false);

   session_start=XAU_SessionStartForTime(signal_time,session_start_hour,session_start_minute);
   or_end_time=XAU_OpeningRangeEndTime(session_start,opening_range_minutes);

   bool found=false;
   const int bars=Bars(symbol,signal_tf);
   for(int shift=signal_shift; shift<bars; ++shift)
     {
      const datetime bar_time=iTime(symbol,signal_tf,shift);
      if(bar_time<=0)
         break;
      if(bar_time<session_start)
         break;

      if(XAU_IsBarInOpeningRange(bar_time,session_start,or_end_time))
        {
         const double h=iHigh(symbol,signal_tf,shift);
         const double l=iLow(symbol,signal_tf,shift);
         if(h<=0.0 || l<=0.0)
            continue;
         if(!found)
           {
            or_high=h;
            or_low=l;
            found=true;
           }
         else
           {
            or_high=MathMax(or_high,h);
            or_low=MathMin(or_low,l);
           }
        }
     }

   return(found);
  }

XAUSignalDecision XAU_EvaluateBreakoutSignalAtShift(const string symbol,
                                                    const ENUM_TIMEFRAMES signal_tf,
                                                    const ENUM_XAU_REGIME regime,
                                                    const int signal_shift,
                                                    const int session_start_hour,
                                                    const int session_start_minute,
                                                    const int opening_range_minutes,
                                                    const double atr_value,
                                                    const double buffer_frac)
  {
   XAUSignalDecision out;
   out.signal=XAU_SIGNAL_NONE;
   out.breakout_high=0.0;
   out.breakout_low=0.0;
   out.signal_close=iClose(symbol,signal_tf,signal_shift);
   out.breakout_buffer=atr_value*buffer_frac;
   out.or_built=false;
   out.session_start=0;
   out.or_end_time=0;
   out.breakout_valid=false;
   out.reclaim_valid=false;
   out.bias_valid=(regime==XAU_REGIME_LONG || regime==XAU_REGIME_SHORT);
   out.setup_type="none";
   out.blocker_reason="";

   if(signal_shift<1 || opening_range_minutes<=0 || atr_value<=0.0 || out.signal_close<=0.0)
     {
      out.blocker_reason="Invalid signal inputs";
      return(out);
     }

   if(!XAU_BuildOpeningRange(symbol,signal_tf,signal_shift,session_start_hour,session_start_minute,opening_range_minutes,
                             out.breakout_high,out.breakout_low,out.session_start,out.or_end_time))
     {
      out.blocker_reason="Opening range not built";
      return(out);
     }
   out.or_built=true;

   const double close_minus_buffer=out.signal_close-out.breakout_buffer;
   const double close_plus_buffer=out.signal_close+out.breakout_buffer;
   const double prev_close=iClose(symbol,signal_tf,signal_shift+1);
   if(prev_close<=0.0)
     {
      out.blocker_reason="Previous closed bar unavailable";
      return(out);
     }

   if(regime==XAU_REGIME_LONG)
     {
      const bool sweep=(prev_close<out.breakout_low);
      const bool reclaim=(close_minus_buffer>out.breakout_low);
      out.breakout_valid=(out.signal_close>(out.breakout_high+out.breakout_buffer));
      out.reclaim_valid=(sweep && reclaim);
      if(out.breakout_valid || out.reclaim_valid)
        {
         out.signal=XAU_SIGNAL_LONG;
         out.setup_type=(out.reclaim_valid ? "reclaim_long" : "breakout_long");
        }
      else
         out.blocker_reason="Long setup invalid";
     }
   else if(regime==XAU_REGIME_SHORT)
     {
      const bool sweep=(prev_close>out.breakout_high);
      const bool reclaim=(close_plus_buffer<out.breakout_high);
      out.breakout_valid=(out.signal_close<(out.breakout_low-out.breakout_buffer));
      out.reclaim_valid=(sweep && reclaim);
      if(out.breakout_valid || out.reclaim_valid)
        {
         out.signal=XAU_SIGNAL_SHORT;
         out.setup_type=(out.reclaim_valid ? "reclaim_short" : "breakout_short");
        }
      else
         out.blocker_reason="Short setup invalid";
     }
   else
      out.blocker_reason="Bias filter neutral";

   return(out);
  }

XAUSignalDecision XAU_EvaluateBreakoutSignal(const string symbol,
                                             const ENUM_TIMEFRAMES signal_tf,
                                             const ENUM_XAU_REGIME regime,
                                             const int session_start_hour,
                                             const int session_start_minute,
                                             const int opening_range_minutes,
                                             const double atr_value,
                                             const double buffer_frac)
  {
   return(XAU_EvaluateBreakoutSignalAtShift(symbol,signal_tf,regime,1,session_start_hour,session_start_minute,opening_range_minutes,atr_value,buffer_frac));
  }

#endif // __BREAKOUTSIGNAL_MQH__
