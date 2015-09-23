//| Copyright:  (C) 2015 Forex Software Ltd.                           |
//| Website:    http://forexsb.com/                                    |
//| Support:    http://forexsb.com/forum/                              |
//| License:    Proprietary under the following circumstances:         |
//|                                                                    |
//| This code is a part of Forex Strategy Builder. It is free for      |
//| use as an integral part of Forex Strategy Builder.                 |
//| One can modify it in order to improve the code or to fit it for    |
//| personal use. This code or any part of it cannot be used in        |
//| other applications without a permission.                           |
//| The contact information cannot be changed.                         |
//|                                                                    |
//| NO LIABILITY FOR CONSEQUENTIAL DAMAGES                             |
//|                                                                    |
//| In no event shall the author be liable for any damages whatsoever  |
//| (including, without limitation, incidental, direct, indirect and   |
//| consequential damages, damages for loss of business profits,       |
//| business interruption, loss of business information, or other      |
//| pecuniary loss) arising out of the use or inability to use this    |
//| product, even if advised of the possibility of such damages.       |
//+--------------------------------------------------------------------+

#property copyright "Forex Software Ltd."
#property link      "http://forexsb.com"
#property version   "1.00"
#property strict

class InstrumentProperties;
//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
   string dataSourceName=TerminalInfoString(TERMINAL_NAME);
   string path=TerminalInfoString(TERMINAL_DATA_PATH)+"\\MQL4\\Files";
   StringReplace(path,"\\","\\\\");
   string dataDirectory=path;
   string description="Data Source exported from "+
                      TerminalInfoString(TERMINAL_NAME)+", "+
                      TerminalInfoString(TERMINAL_COMPANY);

   string symbolsList[];
   int symbols=GetSymbolsList(symbolsList);
   InstrumentProperties *properties[];
   ArrayResize(properties,symbols);
   for(int i=0;i<symbols;i++)
      properties[i]=new InstrumentProperties(symbolsList[i]);

   string dataSourceContent=ComposeDataSourceContent(dataSourceName,
                                                     dataDirectory,
                                                     description,properties);

   string fileName="DataSource_"+dataSourceName+".json";
   SaveStringToFile(fileName,dataSourceContent);

   string note="Exported "+fileName+"\n"+IntegerToString(symbols)+" symbols";
   Print(note);
   Comment(note);

   for(int i=0;i<symbols;i++)
      delete(properties[i]);
  }
//+------------------------------------------------------------------+
int GetSymbolsList(string &symbolsList[])
  {
   int symbolsTotal=SymbolsTotal(true);
   ArrayResize(symbolsList,symbolsTotal);
   int symbolIndex=0;
   for(int i=0; i<symbolsTotal; i++)
     {
      string symbol=SymbolName(i,true);
      if(StringLen(symbol)>3)
         symbolsList[symbolIndex++]=symbol;
     }
   ArrayResize(symbolsList,symbolIndex);
   return (symbolIndex);
  }
//+------------------------------------------------------------------+
void SaveStringToFile(string filename,string text)
  {
   int handle= FileOpen(filename,FILE_TXT|FILE_WRITE|FILE_ANSI);
   if(handle == INVALID_HANDLE)
      return;

   FileWriteString(handle,text);
   FileClose(handle);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string ComposeDataSourceContent(string dataSourceName,
                                string dataDirectory,
                                string description,
                                InstrumentProperties *&properties[])
  {
   string content="";
   content += "{\n";
   content += "    \"DataSourceName\" : \"" + dataSourceName + "\",\n";
   content += "    \"DataDirectory\"  : \"" + dataDirectory  + "\",\n";
   content += "    \"Description\"    : \"" + description    + "\",\n";
   content += "    \"InstrumentProperties\": {\n";
   int propCount=ArraySize(properties);
   for(int i=0;i<propCount;i++)
      content+=properties[i].GetPropertyJson()+(i<propCount-1?",\n":"\n");
   content += "    }\n";
   content += "}";
   return (content);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class InstrumentProperties
  {
   double            GetRate(string currency1,string currency2);
public:
                     InstrumentProperties(string symbol);
   string            GetPropertyJson();

   string            Symbol;
   int               InstrType;
   string            Comment;
   string            PriceIn;
   string            BaseFileName;
   int               LotSize;
   int               Slippage;
   double            Spread;
   double            SwapLong;
   double            SwapShort;
   double            Commission;
   double            RateToUSD;
   double            RateToEUR;
   double            RateToGBP;
   double            RateToJPY;
   int               SwapType;
   int               CommissionType;
   int               CommissionScope;
   int               CommissionTime;
   int               Digits;
   double            Point;
   double            Pip;
   bool              IsFiveDigits;
   double            StopLevel;
   double            TickValue;
   double            MinLot;
   double            MaxLot;
   double            LotStep;
   double            MarginRequired;
  };
//+------------------------------------------------------------------+
InstrumentProperties::InstrumentProperties(string symbol)
  {
   this.Symbol          = symbol;
   string symbolUpper   = symbol;
   StringToUpper(symbolUpper);
   this.InstrType       = ((StringLen(symbol)==6 && symbolUpper==symbol)?0:1);
   this.Comment         = SymbolInfoString(symbol, SYMBOL_DESCRIPTION);
   this.PriceIn         = SymbolInfoString(symbol, SYMBOL_CURRENCY_PROFIT);
   this.BaseFileName    = symbol;
   this.LotSize         = (int) MarketInfo(symbol, MODE_LOTSIZE);
   this.Slippage        = 0;
   this.Point           = MarketInfo(symbol, MODE_POINT);
   double bid           = MarketInfo(symbol, MODE_BID);
   double ask           = MarketInfo(symbol, MODE_ASK);
   this.Spread          = (ask-bid)/this.Point;
   this.SwapLong        = MarketInfo(symbol, MODE_SWAPLONG);
   this.SwapShort       = MarketInfo(symbol, MODE_SWAPSHORT);
   this.Commission      = 0;
   this.RateToUSD       = GetRate(this.PriceIn, "USD");
   this.RateToEUR       = GetRate(this.PriceIn, "EUR");
   this.RateToGBP       = GetRate(this.PriceIn, "GBP");
   this.RateToJPY       = GetRate(this.PriceIn, "JPY");
   this.SwapType        = 0;
   this.CommissionType  = 0;
   this.CommissionScope = 0;
   this.CommissionTime  = 1;
   this.Digits          = (int)MarketInfo(symbol, MODE_DIGITS);
   this.IsFiveDigits    = (this.Digits==3 || this.Digits==5);
   this.Pip             = IsFiveDigits ? 10*this.Point : this.Point;
   this.StopLevel       = MarketInfo(symbol, MODE_STOPLEVEL);
   this.TickValue       = MarketInfo(symbol, MODE_TICKVALUE);
   this.MinLot          = MarketInfo(symbol, MODE_MINLOT);
   this.MaxLot          = MarketInfo(symbol, MODE_MAXLOT);
   this.LotStep         = MarketInfo(symbol, MODE_LOTSTEP);
   this.MarginRequired  = MarketInfo(symbol, MODE_MARGINREQUIRED);
   if(this.MarginRequired<0.0001)
      this.MarginRequired=bid*this.LotSize/100;
  }
//+------------------------------------------------------------------+
double InstrumentProperties::GetRate(string currProfit,string currAccount)
  {
   if(currProfit==currAccount)
      return (1);

   double rate=MarketInfo(currAccount+currProfit,MODE_BID);

   if(rate<0.0001||rate>100000.0)
     {
      if(currProfit=="JPY")
         rate=0.01;
      else if(currAccount=="JPY")
         rate=100;
      else
         rate=1.0;
     }

   return (rate);
  }
//+------------------------------------------------------------------+
string InstrumentProperties::GetPropertyJson(void)
  {
   string content="";
   content += "        \""+this.Symbol+"\" : {\n";
   content += "            \"Symbol\"          : \""+this.Symbol+"\",\n";
   content += "            \"InstrType\"       : "+IntegerToString(this.InstrType)+",\n";
   content += "            \"Comment\"         : \""+this.Comment+"\",\n";
   content += "            \"PriceIn\"         : \""+this.PriceIn+"\",\n";
   content += "            \"BaseFileName\"    : \""+this.BaseFileName+"\",\n";
   content += "            \"LotSize\"         : "+IntegerToString(this.LotSize)+",\n";
   content += "            \"Slippage\"        : "+IntegerToString(this.Slippage)+",\n";
   content += "            \"Spread\"          : "+DoubleToString(this.Spread,2)+",\n";
   content += "            \"SwapLong\"        : "+DoubleToString(this.SwapLong,2)+",\n";
   content += "            \"SwapShort\"       : "+DoubleToString(this.SwapShort,2)+",\n";
   content += "            \"Commission\"      : "+DoubleToString(this.Commission,2)+",\n";
   content += "            \"RateToUSD\"       : "+DoubleToString(this.RateToUSD,this.Digits)+",\n";
   content += "            \"RateToEUR\"       : "+DoubleToString(this.RateToEUR,this.Digits)+",\n";
   content += "            \"RateToGBP\"       : "+DoubleToString(this.RateToGBP,this.Digits)+",\n";
   content += "            \"RateToJPY\"       : "+DoubleToString(this.RateToJPY,this.Digits)+",\n";
   content += "            \"SwapType\"        : "+IntegerToString(this.SwapType)+",\n";
   content += "            \"CommissionType\"  : "+IntegerToString(this.CommissionType)+",\n";
   content += "            \"CommissionScope\" : "+IntegerToString(this.CommissionScope)+",\n";
   content += "            \"CommissionTime\"  : "+IntegerToString(this.CommissionTime)+",\n";
   content += "            \"Digits\"          : "+IntegerToString(this.Digits)+",\n";
   content += "            \"Point\"           : "+DoubleToString(this.Point,this.Digits)+",\n";
   content += "            \"Pip\"             : "+DoubleToString(this.Pip,this.Digits)+",\n";
   content += "            \"IsFiveDigits\"    : "+(this.IsFiveDigits?"true":"false")+",\n";
   content += "            \"StopLevel\"       : "+DoubleToString(this.StopLevel,2)+",\n";
   content += "            \"TickValue\"       : "+DoubleToString(this.TickValue,2)+",\n";
   content += "            \"MinLot\"          : "+DoubleToString(this.MinLot,2)+",\n";
   content += "            \"MaxLot\"          : "+DoubleToString(this.MaxLot,2)+",\n";
   content += "            \"LotStep\"         : "+DoubleToString(this.LotStep,2)+",\n";
   content += "            \"MarginRequired\"  : "+DoubleToString(this.MarginRequired,2)+"\n";
   content += "        }";
   return (content);
  }
//+------------------------------------------------------------------+
