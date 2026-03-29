#pragma once

#include "Types.mqh"

bool XAU_IsTradeEnvironmentReady(const string symbol,string &reason)
  {
   reason="";
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
     {
      reason="Account trading not allowed";
      return(false);
     }

   long trade_mode=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE,trade_mode) || trade_mode==SYMBOL_TRADE_MODE_DISABLED)
     {
      reason="Symbol trading disabled";
      return(false);
     }

   return(true);
  }

string XAU_RegimeToString(const ENUM_XAU_REGIME regime)
  {
   if(regime==XAU_REGIME_LONG)
      return("LONG");
   if(regime==XAU_REGIME_SHORT)
      return("SHORT");
   return("NEUTRAL");
  }

string XAU_SignalToString(const ENUM_XAU_SIGNAL signal)
  {
   if(signal==XAU_SIGNAL_LONG)
      return("LONG");
   if(signal==XAU_SIGNAL_SHORT)
      return("SHORT");
   return("NONE");
  }
