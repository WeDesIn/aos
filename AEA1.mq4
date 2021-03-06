//+------------------------------------------------------------------+
//|                                                         AEA1.mq4 |
//|                                                  Petr Kratochvil |
//|                                              http://www.krato.cz |
//+------------------------------------------------------------------+
#property copyright "Petr Kratochvil"
#property link      "http://www.krato.cz"
#property version   "1.01"
#property strict

//--- input parameters
input unsigned short udp_port=6007;
input double   price=0.00000;
input double   spread_min=0.00000;
input double   spread_limit=0.00100;

#define SOCK_DGRAM                 2
#define AF_INET                    2
#define INVALID_SOCKET             0
#define SOCKET_ERROR               -1
#define FIONREAD                   0x4004667F
#define MODE_CLIENT                1
#define MODE_SERVER                2

#define COMMAND_BID_ASK            0x04
#define COMMAND_ORDER_SEND         0x05
#define COMMAND_ORDER_CLOSE        0x06
#define COMMAND_ORDER_SEND_DONE    0x45
#define COMMAND_ORDER_CLOSE_DONE   0x46

input double time_threshold = 100; // time_threshold [ms]
input int checkInterval = 1; // checkInterval [ms]

#define fileNameSockets(port)      "Comparator1-sockets-udp_port_" + (string) (port) + ".csv"
#define fileNameResults            "Comparator1-results.csv"
#define fileNameOrders             "Comparator1-orders.csv"

#define PACKET_VERSION_MAJOR 1
#define PACKET_VERSION_MINOR 0
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct Packet
  {
   char              command; // use "COMMAND_" prefixed constants
   uint              dataSize; // must be sizeof(Packet)
   char              versionMajor; // must be 1
   short             versionMinor; // must be 0
   uint              timestamp;
   double            bid;
   double            ask;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct IPAddr
  {
   unsigned char     b1;
   unsigned char     b2;
   unsigned char     b3;
   unsigned char     b4;
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct sockaddr_in
  {
   short             family;
   unsigned short    port;
   IPAddr            addr;
   char              sin_zero_0;
   char              sin_zero_1;
   char              sin_zero_2;
   char              sin_zero_3;
   char              sin_zero_4;
   char              sin_zero_5;
   char              sin_zero_6;
   char              sin_zero_7;
  };

#import "ws2_32.dll"
int WSAStartup(int cmd,int &wsadata[]);
int WSACleanup();
int WSAGetLastError();
int socket(int domaint,int type,int protocol);
int bind(int socket,sockaddr_in &sock_in,int sock_in_len);
int connect(int socket,sockaddr_in &sock_in,int sock_in_len);
int listen(int socket,int backlog);
int accept(int socket,int &address[],int &address_len[]);
int recv(int socket,int &buffer[],int length,int flags);
int recvfrom(int socket,Packet &packet,int length,int flags,sockaddr_in &sock_in,int &sock_in_len);
int send(int socket,Packet &packet,int length,int flags);
int sendto(int socket,Packet &packet,int length,int flags,sockaddr_in &sock_in,int sock_in_len);
int closesocket(int socket);
int gethostbyname(string name);
int gethostbyaddr(string addr,int len,int type);
int inet_addr(string addr);
string inet_ntoa(int addr);
int ioctlsocket(int socket,int cmd,ulong &argp);
#import

int listen_socket=INVALID_SOCKET;
int file_handle;
int file_spread_handle;
char mode;
//Packet packet;
IPAddr inaddr;
sockaddr_in sock_in;
int file_results;
char status=0;
char oldstatus=0;

uint tsdiff_last=0;

double spreadServer_min;
double spreadServer_max;
double spreadClient_min;
double spreadClient_max;

bool orderOpened=false;
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void socketError(string operation)
  {
   int error=WSAGetLastError();
   PrintFormat("Network operation '%s' failed with WSA error %d (see https://msdn.microsoft.com/en-us/library/windows/desktop/ms740668(v=vs.85).aspx )",operation,error);
   WSACleanup();
  }
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
   int Buffer[32];
   int retval;
   int fromlen[1];
   int socket_type=SOCK_DGRAM;
   int local[5],from[5];
   int wsaData[100];

   Print("WSAStartup()");
   retval=WSAStartup(0x202,wsaData);
   if(retval!=0)
     {
      PrintFormat("WSAStartup() failed with error %d",retval);
      WSACleanup();
      return(-1);
     }

   file_handle=FileOpen(fileNameSockets(udp_port),FILE_READ|FILE_CSV);
   if(file_handle!=INVALID_HANDLE)
     {
      listen_socket=(int) FileReadNumber(file_handle);
      closesocket(listen_socket);
      FileClose(file_handle);
     }

   listen_socket=socket(AF_INET,socket_type,0);

   if(listen_socket==INVALID_SOCKET)
     {
      socketError("socket");
      return(-1);
     }

   inaddr.b1 = 127;
   inaddr.b2 = 0;
   inaddr.b3 = 0;
   inaddr.b4 = 1;
   sock_in.family=AF_INET;
   sock_in.addr = inaddr;
   sock_in.port = (unsigned short) ((udp_port >> 8) & 0xff) + ((udp_port << 8) & 0xff00);

   mode=MODE_SERVER; // try cast as server

   if(bind(listen_socket,sock_in,sizeof(sock_in))==SOCKET_ERROR)
     {
      if(WSAGetLastError()==10048)
        { // port already in use
         mode=MODE_CLIENT; // server is already running => we are client
         Print("Mode set to: C"); // client
           } else {
         socketError("bind");
         return(-1);
        }
        } else {
      Print("Mode set to: S"); // server
      file_handle=FileOpen(fileNameSockets(udp_port),FILE_WRITE|FILE_CSV);
      FileWrite(file_handle,listen_socket);
      FileClose(file_handle);
     }

   if(mode==MODE_CLIENT)
     {
      Print("connect()");
      retval=connect(listen_socket,sock_in,sizeof(sock_in));
      if(retval==SOCKET_ERROR)
        {
         socketError("connect");
         return(-1);
        }
     }

   if(mode==MODE_SERVER)
     {
      FileDelete(fileNameResults);
      EventSetMillisecondTimer(1); // server check interval
     }

   if(mode==MODE_CLIENT)
     {
      //EventSetTimer(1);
      EventSetMillisecondTimer(checkInterval); // client check interval
     }

   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   if(listen_socket!=INVALID_SOCKET)
     {
      Print("Closing socket.");
      closesocket(listen_socket);
      if(mode==MODE_SERVER)
        {
         FileDelete(fileNameSockets(udp_port));
        }
     }
   listen_socket=INVALID_SOCKET;
   WSACleanup();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  

  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
  
   int retval;
   uint tsdiff;
   char packet_command;
   double packet_bid;
   double packet_ask;

   RefreshRates();

   while(true)
     {
      retval=packetReceive(tsdiff,packet_command,packet_bid,packet_ask);
      if(retval<=0)
        {
         break;
        }
      if(mode==MODE_SERVER)
        {

         if(packet_command==COMMAND_BID_ASK)
           {
            if(tsdiff>time_threshold && tsdiff_last<=time_threshold)
              {
               //PrintFormat("Warning: tsdiff above threshold: %d", tsdiff);
               tsdiff_last=tsdiff;
                 } else if(tsdiff<=time_threshold && tsdiff_last>time_threshold) {
               //PrintFormat("Info: tsdiff is below threashold again: %d", tsdiff);
               tsdiff_last=tsdiff;
              }
            if(tsdiff>time_threshold)
              {
               continue;
              }
            RefreshRates();
            double bidServer = Bid;
            double askServer = Ask;
            double spreadServer=askServer-bidServer;
            if(spreadServer>spread_limit)
              {
               file_spread_handle=FileOpen("spread.csv",FILE_READ|FILE_WRITE|FILE_CSV);
               FileSeek(file_spread_handle,0,SEEK_END);
               FileWrite(file_spread_handle,Symbol(),TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS),Bid,Ask,Ask-Bid);
               FileClose(file_spread_handle);
              }
            double bidClient = packet_bid;
            double askClient = packet_ask;
            double spreadClient=askClient-bidClient;
            //int spread1_min;
            //int spread1_max;
            //int spread2_min;
            //int spread2_max;
            // spreadServer_min
            // spreadServer_max
            double rozdil=0;

            int platforma=0;
            status=0;

            double spreadHigh=0;
            if(spreadServer>spreadClient)
              {
               spreadHigh=spreadServer;
                 } else {
               spreadHigh=spreadClient;
              }

            // example: 1050 - 1000 - 20 => 25
            if(bidClient-askServer-spreadHigh>=price)
              {
               if(spreadClient>=spread_min)
                 {
                  if(spreadServer>=spread_min)
                    {
                     platforma=1; // platforma 1 je client
                     status = 1;
                     rozdil = bidClient - askServer;
           
                    }
                 }
              }

            if(bidServer-askClient-spreadHigh>=price)
              {
               if(spreadClient>=spread_min)
                 {
                  if(spreadServer>=spread_min)
                    {
                     platforma=2; // platforma 1 je server, platforma 2 je client
                     status = 2;
                     rozdil = bidServer - askClient;
                     
                    }
                 }
              }

            // status = 0 ... nesplneno
            // status = 1 ... splneno: bidClient => askServer o rozdil
            // status = 2 ... splneno: bidServer => askClient o rozdil

            //PrintFormat("bidClient: %f bidServer: %f  askClient: %f askServer: %f", bidClient, bidServer, askClient, askServer);

            if(status!=oldstatus && status!=0)
              {
               //if (true) {
               bool openOrder=!orderOpened;
               if(openOrder)
                 {
                  // TODO: OrderSend
                  
                  Alert ( "Sem tu, tady by se odesílal obchod" );
                  
                  orderOpened=true;
                  string currentTimeStr=TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
                  file_handle=FileOpen(fileNameOrders,FILE_WRITE|FILE_CSV);
                  FileWrite(file_handle,Symbol(),currentTimeStr,"server","open",Bid);
                  FileClose(file_handle);
                  packetSend(COMMAND_ORDER_SEND,Bid,Ask);
                 }
               string currentTimeStr=TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
               //Print(currentTimeStr);
               file_results=FileOpen(fileNameResults,FILE_READ|FILE_WRITE|FILE_CSV);
               FileSeek(file_results,0,SEEK_END);
               string priceFormat="%."+(string) Digits+"f";
               //PrintFormat("%s;%s;%d;%d;%s;%s;%s;%s;%s", Symbol(), currentTimeStr, status, oldstatus, StringFormat(priceFormat, bidClient), StringFormat(priceFormat, bidServer), StringFormat(priceFormat, askClient), StringFormat(priceFormat, askServer), StringFormat(priceFormat, rozdil));
               FileWrite(file_results,Symbol(),currentTimeStr,status,oldstatus,StringFormat(priceFormat,bidClient),StringFormat(priceFormat,bidServer),StringFormat(priceFormat,askClient),StringFormat(priceFormat,askServer),StringFormat(priceFormat,rozdil),openOrder ? 1 : 0);
               FileClose(file_results);
              }

            oldstatus=status;
            //break;
           }
        }
      if(mode==MODE_CLIENT)
        {
         if(packet_command==COMMAND_ORDER_SEND)
           {
            // TODO: OrderSend
            Alert ( "Sem tu, tady by se odesílal obchod" );
            
            
            string currentTimeStr=TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
            file_handle=FileOpen(fileNameOrders,FILE_WRITE|FILE_CSV);
            FileWrite(file_handle,Symbol(),currentTimeStr,"client","open",Bid);
            FileClose(file_handle);
            packetSend(COMMAND_ORDER_SEND_DONE,Bid,Ask);
           }
         if(packet_command==COMMAND_ORDER_CLOSE)
           {
            // TODO: OrderClose
            Alert ( "Sem tu, tady by se uzavíral obchod" );
            
            string currentTimeStr=TimeToStr(TimeCurrent(),TIME_DATE|TIME_SECONDS);
            file_handle=FileOpen(fileNameOrders,FILE_WRITE|FILE_CSV);
            FileWrite(file_handle,Symbol(),currentTimeStr,"client","close",Bid);
            FileClose(file_handle);
            packetSend(COMMAND_ORDER_CLOSE_DONE,Bid,Ask);
           }
        }
     }
   if(mode==MODE_CLIENT)
     {
      packetSend(COMMAND_BID_ASK,Bid,Ask);
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+

void packetSend(char command,double bid,double ask)
  {
   Packet packet;
   packet.dataSize=(uint) sizeof(packet);
   packet.versionMajor = PACKET_VERSION_MAJOR;
   packet.versionMinor = PACKET_VERSION_MINOR;
   packet.timestamp=GetTickCount();
   packet.command=command;
   packet.bid = bid;
   packet.ask = ask;

   int retval;
   retval=send(listen_socket,packet,sizeof(packet),0);
   if(retval==SOCKET_ERROR)
     {
      socketError("send");
      OnDeinit(1);
      return;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int packetReceive(uint &timestamp_diff,char &command,double &bid,double &ask)
  {
   int retval;
   int sz;
   ulong bytes_ready=0;
   Packet packet;
//int iter = 0;
//Print ("OK");
   sz=(int) sizeof(sock_in);
   retval=ioctlsocket(listen_socket,FIONREAD,bytes_ready);
//retval = 0;
   if(retval<0)
     {
      switch(WSAGetLastError())
        {
         case 10038: // ignore: Socket operation on nonsocket.
         case 10093: // ignore: Successful WSAStartup not yet performed.
            break;
         default:
            socketError("ioctlsocket:FIONREAD");
            OnDeinit(1);
        }
      return retval;
     }
   if(bytes_ready<(uint) sz)
     { // not enough bytes ready to receive
      //PrintFormat("Iter: %d", ++iter);
      //PrintFormat("Bytes ready: %d", bytes_ready);
      //Sleep(1);
      //continue;
      return 0;
     }
   retval=recvfrom(listen_socket,packet,sizeof(packet),0,sock_in,sz);
   if(retval==SOCKET_ERROR)
     {
      socketError("recvfrom");
      OnDeinit(1);
      return retval;
     }

   if(packet.dataSize!=sizeof(packet))
     {
      socketError("recvfrom:packet.dataSize");
      OnDeinit(1);
      return -2;
     }
   if(packet.versionMajor!=PACKET_VERSION_MAJOR)
     {
      socketError("recvfrom:packet.versionMajor");
      OnDeinit(1);
      return -3;
     }
   if(packet.versionMinor!=PACKET_VERSION_MINOR)
     {
      socketError("recvfrom:packet.versionMinor");
      OnDeinit(1);
      return -4;
     }

//assert(retval = sizeof(packet));
//PrintFormat("Command: %d", packet.command);
   uint ts=GetTickCount();
   timestamp_diff=ts-packet.timestamp;
   command=packet.command;
   bid = packet.bid;
   ask = packet.ask;

   return sz;
  }
//+------------------------------------------------------------------+
