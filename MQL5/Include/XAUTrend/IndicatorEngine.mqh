#ifndef __INDICATORENGINE_MQH__
#define __INDICATORENGINE_MQH__

#include "Types.mqh"

bool XAU_IndicatorInit(const string symbol,
                       const ENUM_TIMEFRAMES regime_tf,
                       const int ema_period,
                       const ENUM_TIMEFRAMES signal_tf,
                       const int atr_period,
                       XAUIndicatorState &state,
                       string &error)
  {
   state.h4_ema_handle=iMA(symbol,regime_tf,ema_period,0,MODE_EMA,PRICE_CLOSE);
   if(state.h4_ema_handle==INVALID_HANDLE)
     {
      error="Failed to create H4 EMA handle";
      return(false);
     }

   state.h1_atr_handle=iATR(symbol,signal_tf,atr_period);
   if(state.h1_atr_handle==INVALID_HANDLE)
     {
      error="Failed to create H1 ATR handle";
      return(false);
     }

   return(true);
  }

void XAU_IndicatorRelease(XAUIndicatorState &state)
  {
   if(state.h4_ema_handle!=INVALID_HANDLE)
      IndicatorRelease(state.h4_ema_handle);
   if(state.h1_atr_handle!=INVALID_HANDLE)
      IndicatorRelease(state.h1_atr_handle);
   state.h4_ema_handle=INVALID_HANDLE;
   state.h1_atr_handle=INVALID_HANDLE;
  }

bool XAU_GetEMAValues(const XAUIndicatorState &state,const int shift1,const int shift2,double &ema1,double &ema2)
  {
   if(state.h4_ema_handle==INVALID_HANDLE)
      return(false);
   if(BarsCalculated(state.h4_ema_handle)<(MathMax(shift1,shift2)+1))
      return(false);

   double buffer[];
   ArraySetAsSeries(buffer,true);

   if(CopyBuffer(state.h4_ema_handle,0,shift1,1,buffer)<=0)
      return(false);
   ema1=buffer[0];

   if(CopyBuffer(state.h4_ema_handle,0,shift2,1,buffer)<=0)
      return(false);
   ema2=buffer[0];
   return(true);
  }

bool XAU_GetATR(const XAUIndicatorState &state,const int shift,double &atr_value)
  {
   atr_value=0.0;
   if(state.h1_atr_handle==INVALID_HANDLE)
      return(false);
   if(BarsCalculated(state.h1_atr_handle)<(shift+1))
      return(false);

   double buffer[];
   ArraySetAsSeries(buffer,true);
   if(CopyBuffer(state.h1_atr_handle,0,shift,1,buffer)<=0)
      return(false);

   atr_value=buffer[0];
   return(atr_value>0.0);
  }

#endif // __INDICATORENGINE_MQH__
