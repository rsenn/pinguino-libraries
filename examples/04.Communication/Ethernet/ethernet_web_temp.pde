/*----------------------------------------------------- 
Author:    Andre Gentric
Date: Jul 5 2014
Description:
Application to demonstrate the capabilities of ENC28J60/ETHERNET lib.
This requests a enc28j60 module, easily found on the online market.
Tested with a 47j53-A board and 1wire DS18B20
The 47j53-A communicates with the enc28j60 module thru the SPI/MSSP module.
The enc28j60 is powered from the 47j53-A 3.3V
It is linked to a PC thru a Dlink router, connected itself to a DSL modem.
Therefore we can communicate with web servers, if necessary, by programming the 47j53-A as a client.
The DS18B20 is connected to any digital pin, here pin#6 and works too under 3.3V.
On the PC the web browser (chrome or chromium in our case) is listening at 192.168.0.10
according our enc28j60 programming.

There are 2 possibilities :
1- to read the temperature measured by the DS18B20 where it is located.
   It can be far from your PC, limited only by the cable length.
   This is the Home page.
2- to switch remotely a led (or a relay) connected to the 47j53-A.
   For instance if the temperature is to high you decide to switch on a fan.
   If you control a relay you need to do it with at least a transistor
   controlled by one of the digital outputs
-------------------------------------------------------*/
// please modify the following two lines. mac and ip have to be unique
// in your local area network. You can not have the same numbers in
// two devices:
static u8 mymac[6] = {0x47,0x54,0x43,0x10,0x20,0x30}; 
static u8 myip[4]  = {192,168,1,123};
static char baseurl[]   = "http://192.168.1.123/";
static u16 mywwwport = 80; // listen port for tcp/www (max range 1-254)

#define BUFFER_SIZE 500
static u8 buf[BUFFER_SIZE+1];
#define STR_BUFFER_SIZE 22
static char strbuf[STR_BUFFER_SIZE+1];

// prepare the webpage by writing the data to the tcp send buffer
u16 http200ok(void);
u16 print_webpage(u8 *buf);
u16 print_webpage_sw(u8 *buf, u8);
s8 analyse_cmd(char *str);

// get current temperature
#define ONEWIREBUS	6	// according your DS18B20 schematics - pin# connected to DQ line
void getCurrentTemp (char *temp);

void setup()
{
  pinMode (USERLED, OUTPUT); 
  digitalWrite (USERLED, LOW);  // LED off
  Ethernet.init(SPI2, mymac, myip, mywwwport);//eth_init
}

void loop()
{
  u16 plen, dat_p;
  s8 cmd;
  u8 on_off = 0;
  
  // plen > 0 means a valid packet (without crc error)
  plen = Ethernet.read(SPI2, BUFFER_SIZE, buf);//enc28j60PacketReceive
  dat_p= Ethernet.requestAnalysis(SPI2, buf, plen);//packetloop_icmp_tcp

  // no http request
  if (dat_p==0)
    return;

  // http error
  if (strncmp ("GET ", (char *) & (buf[dat_p]), 4) != 0)
  {
    // head, post and other methods for possible status codes see:
    // http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
    dat_p = http200ok();
    Ethernet.write(SPI2, buf, dat_p); // send web page data
    return;
  }

  if (strncmp("/ ", (char *) & (buf[dat_p+4]), 2) == 0)
  {
    dat_p = print_webpage (buf);
    Ethernet.write(SPI2, buf, dat_p); // send web page data
    return;
  }

  cmd = analyse_cmd((char *) & (buf[dat_p+5]));
  switch (cmd)
  {
    case 1 :
    case 5 :
      dat_p = print_webpage(buf);
      break;
    case 4 :
      dat_p = print_webpage_sw(buf, on_off);
      break;
    case 2 :
      on_off = 1;
      digitalWrite (USERLED, HIGH);  // switch on LED
      dat_p = print_webpage_sw(buf, on_off);
      break;
    case 3 :
      on_off=0;
      digitalWrite (USERLED, LOW);  // switch off LED
      dat_p = print_webpage_sw(buf, on_off);
      break;
  }
  Ethernet.write(SPI2, buf, dat_p); // send web page data
    // tcp port 80 end
}

// The returned value is stored in the global var strbuf
u8 find_key_val (char *str, char *key)
{
  u8 found = 0;
  u8 i = 0;
  char *kp;
  kp = key;
  while (*str &&  *str!=' ' && found==0)
  {
    if (*str == *kp)
    {
      kp++;
      if (*kp == '\0')
      {
        str++;
        kp=key;
        if (*str == '=')
        {
          found = 1;
        }
      }
    }
    else
    {
      kp = key;
    }
    str++;
  }
  if (found == 1)
  {
    // copy the value to a buffer and terminate it with '\0'
    while (*str &&  *str!=' ' && *str!='&' && i<STR_BUFFER_SIZE)
    {
      strbuf[i]=*str;
      i++;
      str++;
    }
    strbuf[i]='\0';
  }
  return(found);
}

s8 analyse_cmd (char *str)
{
  s8 r = -1;

  if (find_key_val (str,"cmd"))
  {
    if (*strbuf < 0x3a && *strbuf > 0x2f)
    {
      // if it's a ASCII number, return it
      r = (*strbuf-0x30);
    }
  }
  return r;
}

// Returns standard response for successful HTTP requests
u16 http200ok(void)
{
  u16 plen;
  plen = fill_tcp_data (buf, 0, "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>200 OK</h1>");
  return(plen);
}

// Home page - temperature measurements
u16 print_webpage (u8 *buf)
{
  char temp_string[10];
  int i=0;

  u16 plen;

  getCurrentTemp(temp_string);

  plen = fill_tcp_data (buf, 0, "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n");
  plen = fill_tcp_data (buf, plen, "<center><p><h1>Welcome to the Pinguino Ethernet Interface (ENC28J60)</h1></p> ");

  plen = fill_tcp_data (buf, plen, "<hr><br><form METHOD=get action=\"");
  plen = fill_tcp_data (buf, plen, baseurl);
  plen = fill_tcp_data (buf, plen, "\">");
  plen = fill_tcp_data (buf, plen, "<h2> Current Temperature is </h2> ");
  plen = fill_tcp_data (buf, plen, "<h1><font color=\"#00FF00\"> ");

  while (temp_string[i])
  {
    buf[TCP_CHECKSUM_L_P+3+plen]=temp_string[i++];
    plen++;
  }

  plen = fill_tcp_data (buf, plen, "  &#176C</font></h1><br> " );
  plen = fill_tcp_data (buf, plen, "<input type=hidden name=cmd value=1>");
  plen = fill_tcp_data (buf, plen, "<input type=submit value=\"Get Temperature\"></form>");

  plen = fill_tcp_data (buf, plen, "<hr><br><form METHOD=get action=\"");
  plen = fill_tcp_data (buf, plen, baseurl);
  plen = fill_tcp_data (buf, plen, "\">");
  plen = fill_tcp_data (buf, plen, "<input type=hidden name=cmd value=4>");
  plen = fill_tcp_data (buf, plen, "<input type=submit value=\"Get Led/Relay ctrl\"></form>");
  plen = fill_tcp_data (buf, plen, "</center><hr> <p> <a href=\"http://www.pinguino.cc\">www.pinguino.cc<a>");

  return (plen);
}

// Switch on/off page
u16 print_webpage_sw (u8 *buf, u8 on_off)
{
  int i=0;
  u16 plen;

  plen = fill_tcp_data (buf, 0, "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n");
  plen = fill_tcp_data (buf, plen, "<center><p><h1>Welcome to the Pinguino Ethernet Interface (ENC28J60)</h1></p> ");

  plen = fill_tcp_data (buf, plen, "<hr><br><form METHOD=get action=\"");
  plen = fill_tcp_data (buf, plen, baseurl); //
  plen = fill_tcp_data (buf, plen, "\">");
  plen = fill_tcp_data (buf, plen, "<h2> REMOTE LED/RELAY is  </h2> ");
  plen = fill_tcp_data (buf, plen, "<h1><font color=\"#00FF00\"> ");

  if (on_off)
  {
    plen = fill_tcp_data (buf, plen, "ON");
    plen = fill_tcp_data( buf, plen, "  </font></h1><br> " );
    plen = fill_tcp_data (buf, plen, "<input type=hidden name=cmd value=3>");
    plen = fill_tcp_data (buf, plen, "<input type=submit value=\"Switch off\"></form>");
  }
  else
  {
    plen = fill_tcp_data (buf, plen, "OFF");
    plen = fill_tcp_data( buf, plen, "  </font></h1><br> " );
    plen = fill_tcp_data( buf, plen, "<input type=hidden name=cmd value=2>");
    plen = fill_tcp_data( buf, plen, "<input type=submit value=\"Switch on\"></form>");
  }

  plen = fill_tcp_data (buf, plen, "<hr><br><form METHOD=get action=\"");
  plen = fill_tcp_data (buf, plen, baseurl); //
  plen = fill_tcp_data (buf, plen, "\">");
  plen = fill_tcp_data (buf, plen, "<input type=hidden name=cmd value=5>");
  plen = fill_tcp_data (buf, plen, "<input type=submit value=\"Home\"></form>");

  plen = fill_tcp_data (buf, plen, "</center><hr> <p> <a href=\"http://www.pinguino.cc\">www.pinguino.cc<a>");

  return (plen);
}

void getCurrentTemp (char *temp)
{
  /*
  TEMPERATURE t;
	
  if (DS18x20.read(ONEWIREBUS, SKIPROM, &t))
  {
    if(t.sign) Sprintf(temp,"-%d.%d", t.integer, t.fraction);
    else Sprintf(temp,"%d.%d", t.integer, t.fraction);
  }
  */
  Sprintf(temp,"%d.%d", 12, 34);
}
