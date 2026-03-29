#pragma once

namespace XAUJournal
  {
   int    g_handle=INVALID_HANDLE;
   bool   g_enabled=false;
   string g_file_name="";

   bool Init(const bool enable_file_logs,const string symbol,const ulong magic)
     {
      g_enabled=enable_file_logs;
      g_file_name=StringFormat("XAUTrend_%s_%I64u.csv",symbol,magic);
      if(!g_enabled)
         return(true);

      g_handle=FileOpen(g_file_name,FILE_COMMON|FILE_WRITE|FILE_CSV|FILE_SHARE_WRITE|FILE_ANSI,';');
      if(g_handle==INVALID_HANDLE)
        {
         PrintFormat("[XAUTrend][ERROR] File log open failed: %s",g_file_name);
         return(false);
        }

      if(FileSize(g_handle)==0)
         FileWrite(g_handle,"time","level","message");
      FileSeek(g_handle,0,SEEK_END);
      return(true);
     }

   void Shutdown()
     {
      if(g_handle!=INVALID_HANDLE)
         FileClose(g_handle);
      g_handle=INVALID_HANDLE;
     }

   void Log(const string level,const string message)
     {
      PrintFormat("[XAUTrend][%s] %s",level,message);
      if(g_enabled && g_handle!=INVALID_HANDLE)
        {
         FileWrite(g_handle,TimeToString(TimeTradeServer(),TIME_DATE|TIME_SECONDS),level,message);
         FileFlush(g_handle);
        }
     }
  }
