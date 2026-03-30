#property strict
#property script_show_inputs

input string InpSymbol = "XAUUSD";

void OnStart()
  {
   const string symbol=(InpSymbol=="" ? _Symbol : InpSymbol);

   long digits=0,stops=0,freeze=0,filling=0,trade_mode=0;
   double point=0,tick_size=0,tick_value=0,vol_min=0,vol_max=0,vol_step=0;

   SymbolInfoInteger(symbol,SYMBOL_DIGITS,digits);
   SymbolInfoDouble(symbol,SYMBOL_POINT,point);
   SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_SIZE,tick_size);
   SymbolInfoDouble(symbol,SYMBOL_TRADE_TICK_VALUE,tick_value);
   SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN,vol_min);
   SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX,vol_max);
   SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP,vol_step);
   SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL,stops);
   SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL,freeze);
   SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE,filling);
   SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE,trade_mode);

   MqlTick tick;
   SymbolInfoTick(symbol,tick);

   Print("==== XAUTrend Symbol Diagnostics ====");
   PrintFormat("Symbol: %s",symbol);
   PrintFormat("Digits: %d | Point: %.10f",digits,point);
   PrintFormat("TickSize: %.10f | TickValue: %.10f",tick_size,tick_value);
   PrintFormat("Volume Min/Max/Step: %.2f / %.2f / %.2f",vol_min,vol_max,vol_step);
   PrintFormat("StopsLevel: %d | FreezeLevel: %d",stops,freeze);
   PrintFormat("FillingMode: %d | TradeMode: %d",filling,trade_mode);
   PrintFormat("Account MarginMode: %d",AccountInfoInteger(ACCOUNT_MARGIN_MODE));
   PrintFormat("Bid: %.5f | Ask: %.5f | Spread: %.5f",tick.bid,tick.ask,(tick.ask-tick.bid));
  }
