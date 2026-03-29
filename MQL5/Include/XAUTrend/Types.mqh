#pragma once

enum ENUM_XAU_REGIME
  {
   XAU_REGIME_NEUTRAL = 0,
   XAU_REGIME_LONG    = 1,
   XAU_REGIME_SHORT   = -1
  };

enum ENUM_XAU_SIGNAL
  {
   XAU_SIGNAL_NONE  = 0,
   XAU_SIGNAL_LONG  = 1,
   XAU_SIGNAL_SHORT = -1
  };

struct XAUTradeState
  {
   bool              has_position;
   ENUM_XAU_SIGNAL   direction;
   ulong             ticket;
   double            entry_price;
   datetime          entry_time;
   double            highest_since_entry;
   double            lowest_since_entry;
   double            stop_loss;
  };

struct XAURuntimeState
  {
   datetime          last_h1_bar_time;
   datetime          last_h4_bar_time;
   datetime          last_signal_bar_time;
   datetime          last_exit_bar_time;
   datetime          day_start_time;
   double            day_start_equity;
   bool              trading_suspended_for_day;
   bool              integrity_violation;
   ENUM_XAU_REGIME   regime;
   string            blocker_reason;
   XAUTradeState     trade;
  };

struct XAUIndicatorState
  {
   int h4_ema_handle;
   int h1_atr_handle;
  };

struct XAUSignalDecision
  {
   ENUM_XAU_SIGNAL signal;
   double          breakout_high;
   double          breakout_low;
   double          signal_close;
   double          breakout_buffer;
  };

struct XAUPositionSnapshot
  {
   bool                found;
   int                 count;
   ulong               ticket;
   ENUM_POSITION_TYPE  type;
   double              volume;
   double              price_open;
   double              sl;
   datetime            time_open;
  };
