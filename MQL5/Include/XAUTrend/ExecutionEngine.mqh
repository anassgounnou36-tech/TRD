#ifndef __EXECUTIONENGINE_MQH__
#define __EXECUTIONENGINE_MQH__

#include <Trade/Trade.mqh>

const double XAU_PRICE_CHANGE_EPS_POINTS=0.5;

string XAU_TradeRetcodeToString(const uint retcode)
  {
   switch(retcode)
     {
      case TRADE_RETCODE_DONE:             return("TRADE_RETCODE_DONE");
      case TRADE_RETCODE_PLACED:           return("TRADE_RETCODE_PLACED");
      case TRADE_RETCODE_REQUOTE:          return("TRADE_RETCODE_REQUOTE");
      case TRADE_RETCODE_REJECT:           return("TRADE_RETCODE_REJECT");
      case TRADE_RETCODE_CANCEL:           return("TRADE_RETCODE_CANCEL");
      case TRADE_RETCODE_INVALID:          return("TRADE_RETCODE_INVALID");
      case TRADE_RETCODE_INVALID_VOLUME:   return("TRADE_RETCODE_INVALID_VOLUME");
      case TRADE_RETCODE_INVALID_PRICE:    return("TRADE_RETCODE_INVALID_PRICE");
      case TRADE_RETCODE_INVALID_STOPS:    return("TRADE_RETCODE_INVALID_STOPS");
      case TRADE_RETCODE_TRADE_DISABLED:   return("TRADE_RETCODE_TRADE_DISABLED");
      case TRADE_RETCODE_MARKET_CLOSED:    return("TRADE_RETCODE_MARKET_CLOSED");
      case TRADE_RETCODE_NO_MONEY:         return("TRADE_RETCODE_NO_MONEY");
      case TRADE_RETCODE_PRICE_CHANGED:    return("TRADE_RETCODE_PRICE_CHANGED");
      case TRADE_RETCODE_PRICE_OFF:        return("TRADE_RETCODE_PRICE_OFF");
      case TRADE_RETCODE_INVALID_FILL:     return("TRADE_RETCODE_INVALID_FILL");
      default:                             return("TRADE_RETCODE_UNKNOWN");
     }
  }

bool XAU_IsBlockingPreflightRetcode(const uint retcode)
  {
   switch(retcode)
     {
      case TRADE_RETCODE_REJECT:
      case TRADE_RETCODE_CANCEL:
      case TRADE_RETCODE_INVALID:
      case TRADE_RETCODE_INVALID_VOLUME:
      case TRADE_RETCODE_INVALID_PRICE:
      case TRADE_RETCODE_INVALID_STOPS:
      case TRADE_RETCODE_TRADE_DISABLED:
      case TRADE_RETCODE_MARKET_CLOSED:
      case TRADE_RETCODE_NO_MONEY:
      case TRADE_RETCODE_INVALID_FILL:
         return(true);
      default:
         return(false);
     }
  }

bool XAU_IsBlankText(const string value)
  {
   const int len=StringLen(value);
   for(int i=0; i<len; ++i)
     {
      const ushort ch=(ushort)StringGetCharacter(value,i);
      if(ch!=' ' && ch!='\t' && ch!='\r' && ch!='\n')
         return(false);
     }
   return(true);
  }

bool XAU_IsReturnFillingAllowed(const long execution_mode)
  {
   return(execution_mode!=SYMBOL_TRADE_EXECUTION_MARKET);
  }

bool XAU_ResolveFillingType(const string symbol,ENUM_ORDER_TYPE_FILLING &filling,long &fill_flags,long &execution_mode)
  {
   fill_flags=0;
   execution_mode=0;
   if(!SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE,fill_flags))
      return(false);
   if(!SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE,execution_mode))
      return(false);

   if((fill_flags & SYMBOL_FILLING_IOC)==SYMBOL_FILLING_IOC)
      {
       filling=ORDER_FILLING_IOC;
       return(true);
      }
   if((fill_flags & SYMBOL_FILLING_FOK)==SYMBOL_FILLING_FOK)
      {
       filling=ORDER_FILLING_FOK;
       return(true);
      }
   if(XAU_IsReturnFillingAllowed(execution_mode))
     {
      filling=ORDER_FILLING_RETURN;
      return(true);
     }
   return(false);
  }

void XAU_ConfigureTrade(CTrade &trade,const ulong magic,const int slippage_points,const string symbol)
  {
   trade.SetExpertMagicNumber(magic);
   trade.SetDeviationInPoints(slippage_points);
   ENUM_ORDER_TYPE_FILLING filling=ORDER_FILLING_IOC;
   long fill_flags=0;
   long execution_mode=0;
   if(XAU_ResolveFillingType(symbol,filling,fill_flags,execution_mode))
      trade.SetTypeFilling(filling);
   trade.SetAsyncMode(false);
  }

bool XAU_CheckStopDistance(const string symbol,const ENUM_ORDER_TYPE order_type,const double entry,const double stop,string &reason)
  {
   reason="";
   const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   const long stops_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const double min_distance=stops_level*point;

   if(order_type==ORDER_TYPE_BUY)
     {
      if(stop<=0.0 || (entry-stop)<min_distance)
        {
         reason=StringFormat("Buy SL violates stop level (min_distance=%.5f)",min_distance);
         return(false);
        }
     }
   else if(order_type==ORDER_TYPE_SELL)
     {
      if(stop<=0.0 || (stop-entry)<min_distance)
        {
         reason=StringFormat("Sell SL violates stop level (min_distance=%.5f)",min_distance);
         return(false);
        }
     }

   return(true);
  }

bool XAU_IsStopModificationAllowed(const string symbol,
                                   const ENUM_POSITION_TYPE position_type,
                                   const double current_sl,
                                   const double proposed_sl,
                                   double &normalized_sl_out,
                                   string &reason)
  {
   reason="";
   normalized_sl_out=0.0;

   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   if(point<=0.0)
     {
      reason="Invalid symbol point";
      return(false);
     }

   const double normalized_sl=NormalizeDouble(proposed_sl,digits);
   normalized_sl_out=normalized_sl;
   const double normalized_current=NormalizeDouble(current_sl,digits);
   if(normalized_sl<=0.0)
     {
      reason="Proposed SL invalid";
      return(false);
     }

   if(MathAbs(normalized_sl-normalized_current)<(XAU_PRICE_CHANGE_EPS_POINTS*point))
     {
      reason="Proposed SL unchanged after normalization";
      return(false);
     }

   MqlTick tick;
   if(!SymbolInfoTick(symbol,tick))
     {
      reason="No tick for SL legality check";
      return(false);
     }

   const long stops_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const long freeze_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const double min_stop_distance=stops_level*point;
   const double freeze_distance=freeze_level*point;

   if(position_type==POSITION_TYPE_BUY)
     {
      const double distance=tick.bid-normalized_sl;
      if(distance<min_stop_distance)
        {
         reason=StringFormat("Trailing SL skipped: below stops level distance %.5f",distance);
         return(false);
        }
      if(distance<freeze_distance)
        {
         reason=StringFormat("Trailing SL skipped: inside freeze level distance %.5f",distance);
         return(false);
        }
      if(normalized_current>0.0 && normalized_sl<=normalized_current)
        {
         reason="Trailing SL not favorable for long";
         return(false);
        }
     }
   else if(position_type==POSITION_TYPE_SELL)
     {
      const double distance=normalized_sl-tick.ask;
      if(distance<min_stop_distance)
        {
         reason=StringFormat("Trailing SL skipped: below stops level distance %.5f",distance);
         return(false);
        }
      if(distance<freeze_distance)
        {
         reason=StringFormat("Trailing SL skipped: inside freeze level distance %.5f",distance);
         return(false);
        }
      if(normalized_current>0.0 && normalized_sl>=normalized_current)
        {
         reason="Trailing SL not favorable for short";
         return(false);
        }
     }

   return(true);
  }

bool XAU_PreflightOrderCheck(const string symbol,
                             const ulong magic,
                             const ENUM_ORDER_TYPE order_type,
                             const double volume,
                             const double price,
                             const double stop,
                             const int deviation_points,
                             ENUM_ORDER_TYPE_FILLING &resolved_filling,
                             string &reason)
  {
   reason="";
   resolved_filling=ORDER_FILLING_IOC;

   MqlTick tick;
   if(!SymbolInfoTick(symbol,tick))
     {
      reason="Execution preflight blocked: no tick available for OrderCheck";
      return(false);
     }

   const int digits=(int)SymbolInfoInteger(symbol,SYMBOL_DIGITS);
   const double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
   const long stops_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
   const long freeze_level=SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
   const long trade_mode=SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
   long execution_mode=0;
   SymbolInfoInteger(symbol,SYMBOL_TRADE_EXEMODE,execution_mode);
   long fill_flags=0;
   SymbolInfoInteger(symbol,SYMBOL_FILLING_MODE,fill_flags);

   MqlTradeRequest req;
   MqlTradeCheckResult check;
   ZeroMemory(req);
   ZeroMemory(check);

   req.action=TRADE_ACTION_DEAL;
   req.symbol=symbol;
   req.magic=magic;
   req.volume=volume;
   req.type=order_type;
   req.price=0.0;
   req.sl=NormalizeDouble(stop,digits);
   req.tp=0.0;
   req.deviation=deviation_points;
   req.type_time=ORDER_TIME_GTC;
   req.comment="XAUTrend";

   ENUM_ORDER_TYPE_FILLING filling=ORDER_FILLING_IOC;
   if(!XAU_ResolveFillingType(symbol,filling,fill_flags,execution_mode))
      {
      reason=StringFormat("Execution preflight blocked: unable to resolve symbol filling mode (sym_fill_flags=%d sym_exec_mode=%d)",
                          (int)fill_flags,(int)execution_mode);
      return(false);
      }
   resolved_filling=filling;
   req.type_filling=filling;

   ResetLastError();
   if(!OrderCheck(req,check))
      {
      const int last_error=GetLastError();
      reason=StringFormat("Execution preflight blocked: OrderCheck call failed last_error=%d action=%d type=%d vol=%.2f price=%.5f sl=%.5f tp=%.5f dev=%d fill=%d time=%d sym_fill_flags=%d sym_trade_mode=%d sym_exec_mode=%d stops=%d freeze=%d bid=%.5f ask=%.5f point=%.8f digits=%d",
                          last_error,(int)req.action,(int)req.type,req.volume,req.price,req.sl,req.tp,(int)req.deviation,(int)req.type_filling,(int)req.type_time,
                          (int)fill_flags,(int)trade_mode,(int)execution_mode,(int)stops_level,(int)freeze_level,tick.bid,tick.ask,point,digits);
      return(false);
      }

   if(check.retcode==TRADE_RETCODE_DONE || check.retcode==TRADE_RETCODE_PLACED)
      return(true);

   if(XAU_IsBlockingPreflightRetcode((uint)check.retcode))
      {
       reason=StringFormat("Execution preflight blocked: explicit broker/server rejection retcode=%d(%s) comment=%s action=%d type=%d vol=%.2f price=%.5f target_price=%.5f sl=%.5f tp=%.5f dev=%d fill=%d time=%d sym_fill_flags=%d sym_trade_mode=%d sym_exec_mode=%d stops=%d freeze=%d bid=%.5f ask=%.5f point=%.8f digits=%d",
                           check.retcode,XAU_TradeRetcodeToString((uint)check.retcode),check.comment,(int)req.action,(int)req.type,req.volume,req.price,NormalizeDouble(price,digits),req.sl,req.tp,(int)req.deviation,(int)req.type_filling,(int)req.type_time,
                           (int)fill_flags,(int)trade_mode,(int)execution_mode,(int)stops_level,(int)freeze_level,tick.bid,tick.ask,point,digits);
       return(false);
      }

   if(check.retcode==0 && XAU_IsBlankText(check.comment))
      {
       PrintFormat("Execution preflight warning: OrderCheck returned true but retcode/comment were inconclusive; proceeding to actual order send action=%d type=%d vol=%.2f price=%.5f target_price=%.5f sl=%.5f tp=%.5f dev=%d fill=%d time=%d sym_fill_flags=%d sym_trade_mode=%d sym_exec_mode=%d stops=%d freeze=%d bid=%.5f ask=%.5f point=%.8f digits=%d",
                   (int)req.action,(int)req.type,req.volume,req.price,NormalizeDouble(price,digits),req.sl,req.tp,(int)req.deviation,(int)req.type_filling,(int)req.type_time,
                   (int)fill_flags,(int)trade_mode,(int)execution_mode,(int)stops_level,(int)freeze_level,tick.bid,tick.ask,point,digits);
       return(true);
      }

   PrintFormat("Execution preflight warning: OrderCheck returned non-blocking retcode=%d(%s) comment=%s; proceeding to actual order send action=%d type=%d vol=%.2f price=%.5f target_price=%.5f sl=%.5f tp=%.5f dev=%d fill=%d time=%d sym_fill_flags=%d sym_trade_mode=%d sym_exec_mode=%d stops=%d freeze=%d bid=%.5f ask=%.5f point=%.8f digits=%d",
               check.retcode,XAU_TradeRetcodeToString((uint)check.retcode),check.comment,(int)req.action,(int)req.type,req.volume,req.price,NormalizeDouble(price,digits),req.sl,req.tp,(int)req.deviation,(int)req.type_filling,(int)req.type_time,
               (int)fill_flags,(int)trade_mode,(int)execution_mode,(int)stops_level,(int)freeze_level,tick.bid,tick.ask,point,digits);
   return(true);
  }

bool XAU_OpenPosition(CTrade &trade,
                      const string symbol,
                      const ENUM_ORDER_TYPE order_type,
                      const double volume,
                      const double stop,
                      const ENUM_ORDER_TYPE_FILLING filling,
                      const string comment,
                      string &reason)
  {
   reason="";
   bool ok=false;
   trade.SetTypeFilling(filling);

   if(order_type==ORDER_TYPE_BUY)
      ok=trade.Buy(volume,symbol,0.0,stop,0.0,comment);
   else
      ok=trade.Sell(volume,symbol,0.0,stop,0.0,comment);

   const uint retcode=trade.ResultRetcode();
   const string retmsg=trade.ResultRetcodeDescription();

   if(!ok || (retcode!=TRADE_RETCODE_DONE && retcode!=TRADE_RETCODE_PLACED))
     {
      reason=StringFormat("Order send failed retcode=%u msg=%s order=%I64u deal=%I64u",
                          retcode,retmsg,trade.ResultOrder(),trade.ResultDeal());
      return(false);
     }

   return(true);
  }

bool XAU_ModifyStop(CTrade &trade,const string symbol,const double new_sl,string &reason)
  {
   reason="";
   const bool ok=trade.PositionModify(symbol,new_sl,0.0);
   const uint retcode=trade.ResultRetcode();
   if(!ok || (retcode!=TRADE_RETCODE_DONE && retcode!=TRADE_RETCODE_PLACED))
     {
      reason=StringFormat("PositionModify failed retcode=%u msg=%s",retcode,trade.ResultRetcodeDescription());
      return(false);
     }
   return(true);
  }

bool XAU_ClosePosition(CTrade &trade,const string symbol,const int deviation_points,string &reason)
  {
   reason="";
   const bool ok=trade.PositionClose(symbol,deviation_points);
   const uint retcode=trade.ResultRetcode();
   if(!ok || (retcode!=TRADE_RETCODE_DONE && retcode!=TRADE_RETCODE_PLACED))
     {
      reason=StringFormat("PositionClose failed retcode=%u msg=%s",retcode,trade.ResultRetcodeDescription());
      return(false);
     }
   return(true);
  }

#endif // __EXECUTIONENGINE_MQH__
