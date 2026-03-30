#ifndef __POSITIONMANAGER_MQH__
#define __POSITIONMANAGER_MQH__

#include "Types.mqh"
#include "BarUtils.mqh"

bool XAU_FindOpenPosition(const string symbol,const ulong magic,XAUPositionSnapshot &snapshot)
  {
   snapshot.found=false;
   snapshot.count=0;
   snapshot.ticket=0;

   const int total=PositionsTotal();
   for(int i=0;i<total;i++)
     {
      const ulong ticket=PositionGetTicket(i);
      if(ticket==0)
         continue;
      if(!PositionSelectByTicket(ticket))
         continue;
      if(PositionGetString(POSITION_SYMBOL)!=symbol)
         continue;
      if((ulong)PositionGetInteger(POSITION_MAGIC)!=magic)
         continue;

      snapshot.count++;
      if(!snapshot.found)
        {
         snapshot.found=true;
         snapshot.ticket=ticket;
         snapshot.type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         snapshot.volume=PositionGetDouble(POSITION_VOLUME);
         snapshot.price_open=PositionGetDouble(POSITION_PRICE_OPEN);
         snapshot.sl=PositionGetDouble(POSITION_SL);
         snapshot.time_open=(datetime)PositionGetInteger(POSITION_TIME);
        }
     }

   return(snapshot.found);
  }

bool XAU_HasPositionIntegrityViolation(const XAUPositionSnapshot &snapshot,string &reason)
  {
   reason="";
   if(snapshot.count<=1)
      return(false);

   reason=StringFormat("INTEGRITY VIOLATION: %d positions found for symbol+magic",snapshot.count);
   return(true);
  }

void XAU_RebuildTradeStateFromPosition(const string symbol,
                                       const ENUM_TIMEFRAMES signal_tf,
                                       const XAUPositionSnapshot &snapshot,
                                       XAUTradeState &state)
  {
   state.has_position=snapshot.found;
   if(!snapshot.found)
      return;

   state.ticket=snapshot.ticket;
   state.direction=(snapshot.type==POSITION_TYPE_BUY ? XAU_SIGNAL_LONG : XAU_SIGNAL_SHORT);
   state.entry_price=snapshot.price_open;
   state.entry_time=snapshot.time_open;
   state.stop_loss=snapshot.sl;
   state.highest_since_entry=snapshot.price_open;
   state.lowest_since_entry=snapshot.price_open;

   int entry_shift=iBarShift(symbol,signal_tf,snapshot.time_open,false);
   if(entry_shift<1)
      entry_shift=1;

   const double highest=XAU_HighestHigh(symbol,signal_tf,1,entry_shift);
   const double lowest=XAU_LowestLow(symbol,signal_tf,1,entry_shift);
   if(highest>0.0)
      state.highest_since_entry=MathMax(state.highest_since_entry,highest);
   if(lowest>0.0)
      state.lowest_since_entry=MathMin(state.lowest_since_entry,lowest);
  }

void XAU_ClearTradeState(XAUTradeState &state)
  {
   state.has_position=false;
   state.direction=XAU_SIGNAL_NONE;
   state.ticket=0;
   state.entry_price=0.0;
   state.entry_time=0;
   state.highest_since_entry=0.0;
   state.lowest_since_entry=0.0;
   state.stop_loss=0.0;
  }

void XAU_UpdateExtremesFromClosedBar(const string symbol,const ENUM_TIMEFRAMES signal_tf,XAUTradeState &state)
  {
   if(!state.has_position)
      return;
   const double bar_high=iHigh(symbol,signal_tf,1);
   const double bar_low=iLow(symbol,signal_tf,1);

   if(bar_high>0.0)
      state.highest_since_entry=MathMax(state.highest_since_entry,bar_high);
   if(bar_low>0.0)
      state.lowest_since_entry=MathMin(state.lowest_since_entry,bar_low);
  }

double XAU_ComputeInitialStop(const string symbol,
                              const ENUM_TIMEFRAMES signal_tf,
                              const ENUM_XAU_SIGNAL direction,
                              const double entry,
                              const double atr,
                              const double initial_stop_atr,
                              const int swing_lookback,
                              const double stop_buffer_atr_frac)
  {
   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double stop_buffer=stop_buffer_atr_frac*atr;

   if(direction==XAU_SIGNAL_LONG)
     {
      const double atr_stop=entry-initial_stop_atr*atr;
      const double swing_low=XAU_LowestLow(symbol,signal_tf,1,swing_lookback);
      const double structure_stop=swing_low-stop_buffer;
      return(NormalizeDouble(MathMin(atr_stop,structure_stop),digits));
     }

   const double atr_stop=entry+initial_stop_atr*atr;
   const double swing_high=XAU_HighestHigh(symbol,signal_tf,1,swing_lookback);
   const double structure_stop=swing_high+stop_buffer;
   return(NormalizeDouble(MathMax(atr_stop,structure_stop),digits));
  }

double XAU_ComputeTrailingStop(const string symbol,
                               const ENUM_XAU_SIGNAL direction,
                               const XAUTradeState &trade,
                               const double atr,
                               const double trail_atr)
  {
   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   if(direction==XAU_SIGNAL_LONG)
      return(NormalizeDouble(trade.highest_since_entry-trail_atr*atr,digits));

   return(NormalizeDouble(trade.lowest_since_entry+trail_atr*atr,digits));
  }

#endif // __POSITIONMANAGER_MQH__
