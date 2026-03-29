#pragma once

#include "Types.mqh"
#include "Diagnostics.mqh"

void XAU_UpdateChartPanel(const bool enabled,
                          const string symbol,
                          const XAURuntimeState &state,
                          const double atr,
                          const double spread,
                          const double daily_dd)
  {
   if(!enabled)
      return;

   string lines="";
   lines+="XAU Trend Breakout EA\n";
   lines+=StringFormat("Symbol: %s\n",symbol);
   lines+=StringFormat("Regime: %s\n",XAU_RegimeToString(state.regime));
   lines+=StringFormat("Position: %s\n",(state.trade.has_position?XAU_SignalToString(state.trade.direction):"FLAT"));
   lines+=StringFormat("ATR: %.5f | Spread: %.5f\n",atr,spread);
   lines+=StringFormat("Day DD: %.2f%% | Suspended: %s\n",daily_dd,(state.trading_suspended_for_day?"YES":"NO"));
   lines+=StringFormat("Blocker: %s",(state.blocker_reason==""?"none":state.blocker_reason));
   Comment(lines);
  }
