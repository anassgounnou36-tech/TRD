#ifndef __JOURNAL_MQH__
#define __JOURNAL_MQH__

int    g_xau_journal_handle=INVALID_HANDLE;
bool   g_xau_journal_enabled=false;
string g_xau_journal_file_name="";

bool XAUJournal_Init(const bool enable_file_logs,const string symbol,const ulong magic)
  {
   g_xau_journal_enabled=enable_file_logs;
   g_xau_journal_file_name=StringFormat("XAUTrend_%s_%I64u.csv",symbol,magic);
   if(!g_xau_journal_enabled)
      return(true);

   g_xau_journal_handle=FileOpen(g_xau_journal_file_name,FILE_COMMON|FILE_WRITE|FILE_CSV|FILE_SHARE_WRITE|FILE_ANSI,';');
   if(g_xau_journal_handle==INVALID_HANDLE)
     {
      PrintFormat("[XAUTrend][ERROR] File log open failed: %s",g_xau_journal_file_name);
      return(false);
     }

   if(FileSize(g_xau_journal_handle)==0)
      FileWrite(g_xau_journal_handle,"time","level","message");
   FileSeek(g_xau_journal_handle,0,SEEK_END);
   return(true);
  }

void XAUJournal_Shutdown()
  {
   if(g_xau_journal_handle!=INVALID_HANDLE)
      FileClose(g_xau_journal_handle);
   g_xau_journal_handle=INVALID_HANDLE;
  }

void XAUJournal_Log(const string level,const string message)
  {
   PrintFormat("[XAUTrend][%s] %s",level,message);
   if(g_xau_journal_enabled && g_xau_journal_handle!=INVALID_HANDLE)
     {
      FileWrite(g_xau_journal_handle,TimeToString(TimeTradeServer(),TIME_DATE|TIME_SECONDS),level,message);
      FileFlush(g_xau_journal_handle);
     }
  }

#endif // __JOURNAL_MQH__
