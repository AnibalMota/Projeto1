//+------------------------------------------------------------------+
//|                                                 Calculadora%.mq5 |
//|                                      Copyright 2022, AnibalMota. |
//|                                                ajfmota@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, AnibalMota."
#property link      "ajfmota@gmail.com"
#property version   "2208.130"
#property description "Robot para Calcular o Tamanho do Lote e efetuar Ordem de Compra ou Venda"

//---
#include <Trade/Trade.mqh>

//---input parameters --- Parametros para alteracao na entrada
input group          "Configuração do Robot"
input double          Percentagem = 10.0;
input int             Operacoes = 10;
input int             SL_Percentagem = 50;
input group          "Configuração do TP"
input double          TakeProfit = 1.3;
input bool            TPNew = true;
input double          TakeProfit1 = 1.5;
input double          TakeProfit2 = 2.0;
input group          "Configuração de Linhas e Comentários"
input int             Numero_Dias_Max_Min = 1;
input int             Espessura_Linha_Ordem = 2;
input bool            Comentarios = true;
input bool            Alerta = false;
input bool            Apenas_Fechar_Ativos = true;
input group          "Configuração de Cores"
input color           Cor_Compra = clrGreenYellow;
input color           Cor_Venda = clrDarkOrange;
input color           Cor_Linha = clrBlue;
input color           Cor_Max_Hoje = clrAqua;
input color           Cor_Min_Hoje = clrBlue;
input color           Cor_Max_Anterior = clrGreen;
input color           Cor_Min_Anterior = clrMagenta;

//Declarar variaveis globais
string botoes[3] = {"Sell","Buy","Close"};
string edit = "Edit";
string activo = "Activo",linhaCompra="Hent",linhaVenda="Hsl",apostaPreco = "Aposta",numLotes = "NumerLotes",numPercentagem = "ApostaPercentagem",numTakeProfit = "TackProfit";
double saldoInicio = 0;
string Nome_do_Ficheiro = "BD2206.txt";
string ativo="",simbolo="";
//--- Declarar variaveis
#define BtnClose "ButtonClose"
string shortname = "CalculadoraLotes";
string nomelinha = "",fonte= "Arial Rounded MT Bold";
double Num_Casas_Decimais = 0;
bool sl=false;
bool ent=false;
bool calcula1 = true;
bool ver = false;
bool inicio = false;
bool operacao = false;
double saldo=0;
double LinePriceSL=0;
double LinePriceEnt=0;
double nbrPontos=0;
//double lote =0;
bool slRemov=false;
bool entRemov=false;
string linhaSl="Linha_Venda";
string linhaEnt="Linha_Compra";
bool sl_is_object_being_dragged=false;
double sl_new_drag_price=0;
bool ent_is_object_being_dragged=false;
double ent_new_drag_price=0;

double valorPercentagem = Percentagem;
double valorTakeProfit = TakeProfit;
double valorTakeProfit1 = TakeProfit1;
double valorTakeProfit2 = TakeProfit2;
double valor = 1;
double prejuiso=0;

int x_size = 330;//tamanho Painel
int y_size = 60;//tamanho Painel
int delta_x = 5;//distancia em pixeis
int delta_y = 5;
int line_size = 25;
int button_size = 60;
int campo_size = 60;
int letra_size = 8;


//Objecto para efetuar compras e vendas
CTrade negocio;

//+------------------------------------------------------------------+
//| Variaveis para o calculo e apresentacao do numero de operacoes                                  |
//+------------------------------------------------------------------+
int days=1;            // profundidade do histórico de negociação em dias
//--- definimos no nível global os limites do histórico de negociação
datetime     start;             // data de início do histórico de negociação em cache
datetime     end;               // data final do histórico de negociação em cache
//--- contadores globais
int          orders;            // número de ordens vigentes
int          positions;         // número de posições abertas
int          deals;             // número de transações no cache do histórico de negociação
int          history_orders;    // número de ordens no cache do histórico de negociaçãod
bool         started=false;     // sinalizador da relevância dos contadores

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {

   if(numeroOperacoes() >= 2*Operacoes)
     {
      insereAlertasInicio();
     }

   GetTradeHistory(days);
   simbolo = Symbol();
   InitCounters();
//---

//Verificar data e remover Robo....................................................
   string data = TimeToString(TimeCurrent(),TIME_DATE);

   string ano = separaStringAno(data);
   if(ano > 2025)
     {
      ExpertRemove();
     }

//Gravar Saldo no Ficheiro..........................................................
   inicio();

//Marcar as linhas MAX e MIN...................................................................
   macarLinhaMaxMin();

   valor = NormalizeDouble(calculaAposta(valorPercentagem),1);
//---------   Criar objectos que compoem o painel   -----------
//---------Criar o painel
//Se a criacao falhar deve parar
   if(!ObjectCreate(0,"Painel",OBJ_RECTANGLE_LABEL,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,"Painel",OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,"Painel",OBJPROP_XDISTANCE,delta_x);
   ObjectSetInteger(0,"Painel",OBJPROP_YDISTANCE,y_size + delta_y);
   ObjectSetInteger(0,"Painel",OBJPROP_XSIZE,x_size);
   ObjectSetInteger(0,"Painel",OBJPROP_YSIZE,y_size);
   ObjectSetInteger(0,"Painel",OBJPROP_BGCOLOR,clrWhite);
   ObjectSetInteger(0,"Painel",OBJPROP_BORDER_TYPE,BORDER_FLAT);
   ObjectSetInteger(0,"Painel",OBJPROP_BORDER_COLOR,clrBlack);
   ObjectSetInteger(0,"Painel",OBJPROP_SELECTABLE,true);
   ObjectSetInteger(0,"Painel",OBJPROP_SELECTED,true);
   ObjectSetString(0,"Painel",OBJPROP_TEXT,"Painel");

//---------Criar label  ---  Sera apresentado a Sigla do Activo
   if(!ObjectCreate(0,activo,OBJ_LABEL,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,activo,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,activo,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,activo,OBJPROP_XDISTANCE,delta_x+5);
   ObjectSetInteger(0,activo,OBJPROP_YDISTANCE,delta_y-5 + y_size);
   ObjectSetInteger(0,activo,OBJPROP_FONTSIZE,letra_size);
   ObjectSetString(0,activo,OBJPROP_FONT, fonte);
   ObjectSetString(0,activo,OBJPROP_TEXT,activo);
   ObjectSetString(0,activo,OBJPROP_TOOLTIP,"Activo");
   ObjectSetInteger(0,activo,OBJPROP_COLOR,Cor_Linha);

//Inserir os dados no painel Campo linha entrada
   int h=1;
   string name = linhaCompra;
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,delta_x+5+(h++*65));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,delta_y-5 + y_size) ;
   ObjectSetInteger(0,name,OBJPROP_XSIZE,campo_size);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,Cor_Compra);
   ObjectSetInteger(0,name,OBJPROP_COLOR,Cor_Linha);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,letra_size);
//ObjectSetString(0,name,OBJPROP_FONT, fonte);
   ObjectSetString(0,name,OBJPROP_TEXT,"0");
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Linha_Compra");

//Inserir os dados no painel Campo linha saida
   name = linhaVenda;
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,delta_x+5+(h++*65));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,delta_y-5 + y_size) ;
   ObjectSetInteger(0,name,OBJPROP_XSIZE,campo_size);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,Cor_Venda);
   ObjectSetInteger(0,name,OBJPROP_COLOR,Cor_Linha);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,letra_size);
//ObjectSetString(0,name,OBJPROP_FONT, fonte);
   ObjectSetString(0,name,OBJPROP_TEXT,"0");
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Linha_Venda");

//Inserir os dados no painel Campo numLotes
   name = numLotes;
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,delta_x+5+(h++*65));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,delta_y-5 + y_size) ;
   ObjectSetInteger(0,name,OBJPROP_XSIZE,campo_size);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_COLOR,Cor_Linha);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,letra_size);
   ObjectSetString(0,name,OBJPROP_FONT, fonte);
   ObjectSetString(0,name,OBJPROP_TEXT,"0");
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Numero_Lotes");

//Inserir os dados no painel Campo Percentagem
   name = numPercentagem;
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,delta_x+5+(h++*65));
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,delta_y-5 + y_size) ;
   ObjectSetInteger(0,name,OBJPROP_XSIZE,campo_size);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,20);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_COLOR,Cor_Linha);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,letra_size);
   ObjectSetString(0,name,OBJPROP_FONT, fonte);
   ObjectSetString(0,name,OBJPROP_TEXT,valorPercentagem);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Percentagem");

//Criar botoes
//delta_x = delta_x+5;
   for(int i = 0; i<ArraySize(botoes); i++)
     {
      if(!ObjectCreate(0,botoes[i],OBJ_BUTTON,0,0,0))
         return(INIT_FAILED);

      ObjectSetInteger(0,botoes[i],OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,botoes[i],OBJPROP_CORNER,CORNER_LEFT_LOWER);
      ObjectSetInteger(0,botoes[i],OBJPROP_XDISTANCE,10+i*65);
      ObjectSetInteger(0,botoes[i],OBJPROP_YDISTANCE,delta_y-5 + y_size-line_size);
      ObjectSetInteger(0,botoes[i],OBJPROP_XSIZE,button_size);
      ObjectSetInteger(0,botoes[i],OBJPROP_YSIZE,line_size);
      ObjectSetInteger(0,botoes[i],OBJPROP_COLOR,Cor_Linha);
      ObjectSetInteger(0,botoes[i],OBJPROP_FONTSIZE,letra_size);
      ObjectSetString(0,botoes[i],OBJPROP_FONT, fonte);
      ObjectSetString(0,botoes[i],OBJPROP_TEXT,botoes[i]);
      if(i==0)
        {
         ObjectSetString(0,botoes[i],OBJPROP_TOOLTIP,"Ordem_Venda");
        }
      else
         if(i==1)
           {
            ObjectSetString(0,botoes[i],OBJPROP_TOOLTIP,"Ordem_Compra");
           }
         else
            if(i==2)
              {
               ObjectSetString(0,botoes[i],OBJPROP_TOOLTIP,"Cancela_Ordens");
              }
     }

//Inserir os dados no painel Campo numLotes
   name = apostaPreco;
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,25+3*button_size);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,delta_y-6 + y_size-line_size);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,campo_size);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,22);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_COLOR,Cor_Linha);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,letra_size);
   ObjectSetString(0,name,OBJPROP_FONT, fonte);
//ObjectSetString(0,name,OBJPROP_TEXT,"");
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"Aposta");

//Inserir os dados no painel Campo Percentagem numPercentagem = "ApostaPercentagem",numTakeProfit = "TackProfit";
   name = numTakeProfit;
   if(!ObjectCreate(0,name,OBJ_EDIT,0,0,0))
      return(INIT_FAILED);

   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_LOWER);
   ObjectSetInteger(0,name,OBJPROP_XDISTANCE,30+4*button_size);
   ObjectSetInteger(0,name,OBJPROP_YDISTANCE,delta_y-6 + y_size-line_size);
   ObjectSetInteger(0,name,OBJPROP_XSIZE,campo_size);
   ObjectSetInteger(0,name,OBJPROP_YSIZE,22);
   ObjectSetInteger(0,name,OBJPROP_BGCOLOR,clrWhite);
   ObjectSetInteger(0,name,OBJPROP_COLOR,Cor_Linha);
   ObjectSetInteger(0,name,OBJPROP_FONTSIZE,letra_size);
   ObjectSetString(0,name,OBJPROP_FONT, fonte);
   ObjectSetString(0,name,OBJPROP_TOOLTIP,"TackProfit");
   ObjectSetString(0,name,OBJPROP_TEXT,valorTakeProfit);


//inserir os valores
   ObjectSetString(0,apostaPreco,OBJPROP_TEXT,valor);//4 direita
   ObjectSetString(0,activo,OBJPROP_TEXT,_Symbol);//1 esquerda
   ChartRedraw();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
//-----------Apagar todos os objetos que criamos numTakeProfit numPercentagem
   ObjectDelete(0,activo);
   ObjectDelete(0,linhaCompra);
   ObjectDelete(0,linhaVenda);
   ObjectDelete(0,apostaPreco);
   ObjectDelete(0,numLotes);
   ObjectDelete(0,numTakeProfit);
   ObjectDelete(0,numPercentagem);
   ObjectDelete(0,"Painel");
   for(int i = 0; i<ArraySize(botoes); i++)
      ObjectDelete(0,botoes[i]);

   ObjectDelete(0,"LowHoje");
   ObjectDelete(0,"HighHoje");
   for(int i = 1; i<3; i++)
     {
      ObjectDelete(0,"lastHigh"+i);
      ObjectDelete(0,"lastLow"+i);
     }
   ObjectDelete(0,linhaEnt);
   ObjectDelete(0,linhaSl);

   ent=false;
   sl=false;
   calcula1 = true;

//Limpar campo para o valor inicial
   valorPercentagem = Percentagem;
   valorTakeProfit = TakeProfit;
   valorTakeProfit1 = TakeProfit1;
   valorTakeProfit2 = TakeProfit2;
   valor = 1;

//Comment("");
   mostraComentarios("");
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {

   fechaOperacoes(SL_Percentagem);

   if(started)
     {
      SimpleTradeProcessor();
     }
   else
     {
      InitCounters();
     }
//---
  }

//+------------------------------------------------------------------+
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
  {
//---
   if(started)
     {
      SimpleTradeProcessor();
     }
   else
     {
      InitCounters();
     }

  }
//+------------------------------------------------------------------+
//| TradeTransaction function                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
  {
//---

  }

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(id==CHARTEVENT_OBJECT_ENDEDIT)
     {
      //Obter o valor do TackProfit
      valorTakeProfit = StringToDouble(ObjectGetString(0,numTakeProfit,OBJPROP_TEXT,0));
      //Obter o valor da percentagem
      valorPercentagem = StringToDouble(ObjectGetString(0,numPercentagem,OBJPROP_TEXT,0));
      valor = NormalizeDouble(calculaAposta(valorPercentagem),1);
      //Inserir o valor no campo
      ObjectSetString(0,apostaPreco,OBJPROP_TEXT,valor);//4 direita
      calculaLote(lparam,dparam);
     }
//----      INI --------   CHARTEVENT_CLICK
//--- the left mouse button has been pressed on the chart
   if(id==CHARTEVENT_CLICK)
     {
      Print("421- Sparam- "+sparam);
      if(!operacao && sparam=="")
        {
         //Declrar variaveis
         datetime time;
         double price;
         int subwindow;

         ChartXYToTimePrice(0,lparam,dparam,subwindow,time,price);

         if(price > 1)
           {
            for(int obj=0; obj<ObjectsTotal(0,0,OBJ_HLINE); obj++)
              {
               //verificar se e linha horizontal
               int type=ObjectGetInteger(obj,0,OBJPROP_TYPE,0);
               nomelinha = ObjectName(0,obj,0,-1);
               if(nomelinha==linhaSl)
                 {
                  sl=true;
                 }
               else
                  if(nomelinha==linhaEnt)
                    {
                     ent=true;
                    }
              }
            if(!sl || !ent)
              {
               if(!ent)
                 {
                  //Criar linha Ent
                  ent_is_object_being_dragged=false;
                  ent_new_drag_price=0;
                  //create a test line TP
                  bool obj1=ObjectCreate(ChartID(),linhaEnt,OBJ_HLINE,0,0,price);
                  ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_COLOR,Cor_Compra);
                  ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_WIDTH,Espessura_Linha_Ordem);
                  ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_SELECTABLE,true);
                  ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_SELECTED,true);
                  ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_MOVE,true);

                  ObjectSetString(0,linhaCompra,OBJPROP_TEXT,price);//2 Direita
                  ent=true;
                  ChartRedraw();
                 }
               else
                  if(!sl)
                    {
                     //Criar linha SL
                     sl_is_object_being_dragged=false;
                     sl_new_drag_price=0;
                     //create a test line SL
                     bool obj=ObjectCreate(ChartID(),linhaSl,OBJ_HLINE,0,0,price);
                     ObjectSetInteger(ChartID(),linhaSl,OBJPROP_COLOR,Cor_Venda);
                     ObjectSetInteger(ChartID(),linhaSl,OBJPROP_WIDTH,Espessura_Linha_Ordem);
                     ObjectSetInteger(ChartID(),linhaSl,OBJPROP_SELECTABLE,true);
                     ObjectSetInteger(ChartID(),linhaSl,OBJPROP_SELECTED,true);
                     ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_MOVE,0,true);

                     ObjectSetString(0,linhaVenda,OBJPROP_TEXT,price);//3 direita
                     sl=true;
                     ChartRedraw();
                    }
              }
            if(sl && ent && calcula1)
              {
               calculaLote(lparam,dparam);
               calcula1 = false;
              }
           }
        }
      else
         operacao = false;
     }
//----      END     --------   CHARTEVENT_CLICK
//---
//----      INI    --------   CHARTEVENT_OBJECT_CLICK
//Obter o evento
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      Print("501- Sparam- "+sparam);
      Sleep(50);

      if(sparam=="Buy")
        {
         //devolveOperacoes();
         double entada = 0;
         double saida =0;
         double nlotes = StringToDouble(ObjectGetString(0,numLotes,OBJPROP_TEXT,0));
         LinePriceSL=ObjectGetDouble(0,linhaSl,OBJPROP_PRICE);
         LinePriceEnt=ObjectGetDouble(0,linhaEnt,OBJPROP_PRICE);

         if(LinePriceEnt > LinePriceSL)
           {
            entada = LinePriceEnt;
            saida = LinePriceSL;
           }
         else
           {
            entada = LinePriceSL;
            saida = LinePriceEnt;
           }
         //Calcular o TP
         double tempTp1 = entada - saida;
         double tempTp2 = entada + valorTakeProfit*tempTp1;
         //colocar ordem de compra
         negocio.BuyStop(nlotes,entada,_Symbol,saida,tempTp2,ORDER_TIME_DAY,0,"BuyStop");
         //colocar o botao no estado normal
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false);

         //--- Removel linhas------------------------------------------------------------------------------------
         operacao = true;
         ObjectDelete(0,linhaSl);
         ObjectDelete(0,linhaEnt);
         ent = false;
         sl= false;

         if(TPNew)
           {
            //Inserir as linhas no TP1 e TP2
            //Calcular TP1 e TP2
            double tempTp15 = entada + valorTakeProfit1*tempTp1;
            double tempTp20 = entada + valorTakeProfit2*tempTp1;
            criarLinhaCompra(tempTp20);
            criarLinhaVenda(tempTp15);
           }

        }
      if(sparam=="Sell")
        {
         double entada = 0;
         double saida =0;
         double nlotes = StringToDouble(ObjectGetString(0,numLotes,OBJPROP_TEXT,0));
         LinePriceSL=ObjectGetDouble(0,linhaSl,OBJPROP_PRICE);
         LinePriceEnt=ObjectGetDouble(0,linhaEnt,OBJPROP_PRICE);

         if(LinePriceEnt > LinePriceSL)
           {
            entada = LinePriceSL;
            saida = LinePriceEnt;
           }
         else
           {
            entada = LinePriceEnt;
            saida = LinePriceSL;
           }
         //Calcular o TP
         double tempTp1 = saida-entada;
         double tempTp2 = entada - valorTakeProfit*tempTp1;
         //colocar ordem de venda
         negocio.SellStop(nlotes,entada,_Symbol,saida,tempTp2,ORDER_TIME_DAY,0,"SellStop");
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false);

         //--- Removel linhas------------------------------------------------------------------------------------
         operacao = true;
         ObjectDelete(0,linhaSl);
         ObjectDelete(0,linhaEnt);
         ent = false;
         sl= false;

         if(TPNew)
           {
            //Inserir as linhas no TP1 e TP2
            //Calcular TP1 e TP2
            double tempTp15 = entada - valorTakeProfit1*tempTp1;
            double tempTp20 = entada - valorTakeProfit2*tempTp1;
            criarLinhaCompra(tempTp15);
            criarLinhaVenda(tempTp20);
           }
        }
      if(sparam=="Close")
        {
         //negocio.PositionClose(_Symbol);
         int nbrOrdens  = OrdersTotal();
         long ticket;
         while(nbrOrdens>0)
           {
            for(int i=0; i<nbrOrdens; i++)
              {
               if((ticket=OrderGetTicket(i))>0)
                 {
                  ticket=OrderGetTicket(i);
                  negocio.OrderDelete(ticket);
                 }
              }
            nbrOrdens  = OrdersTotal();
           }
         ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
        }
      ChartRedraw();
     }
//----      END    --------   CHARTEVENT_OBJECT_CLICK

//--
//----      INI    --------   CHARTEVENT_OBJECT_CLICK
   if(id==CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam==linhaSl&&linhaSl!=""&&!sl_is_object_being_dragged)
        {
         if(ObjectGetInteger(0,linhaSl,OBJPROP_SELECTED))
           {
            sl_is_object_being_dragged=true;
            sl_new_drag_price=ObjectGetDouble(0,linhaSl,OBJPROP_PRICE);
           }
         if(!ObjectGetInteger(0,linhaSl,OBJPROP_SELECTED))
            sl_is_object_being_dragged=false;
        }
     }
//----      END    --------   CHARTEVENT_OBJECT_CLICK
//--
   if(id==CHARTEVENT_OBJECT_DRAG&&ObjectGetInteger(0,linhaSl,OBJPROP_SELECTED)==1)
     {
      if(sparam==linhaSl&&linhaSl!="")
        {
         double nprice=ObjectGetDouble(0,linhaSl,OBJPROP_PRICE);
         sl_new_drag_price=nprice;
         calculaLote(lparam,dparam);
        }
     }

//Preparar Ent
   if(id==CHARTEVENT_OBJECT_CLICK&&sparam==linhaEnt&&linhaEnt!=""&&!ent_is_object_being_dragged)
     {
      if(ObjectGetInteger(0,linhaEnt,OBJPROP_SELECTED))
        {
         ent_is_object_being_dragged=true;
         ent_new_drag_price=ObjectGetDouble(0,linhaEnt,OBJPROP_PRICE);
        }
      if(!ObjectGetInteger(0,linhaEnt,OBJPROP_SELECTED))
         ent_is_object_being_dragged=false;
     }

   if(id==CHARTEVENT_OBJECT_DRAG&&ObjectGetInteger(0,linhaEnt,OBJPROP_SELECTED)==1)
     {
      if(sparam==linhaEnt&&linhaEnt!="")
        {
         double nprice=ObjectGetDouble(0,linhaEnt,OBJPROP_PRICE);
         ent_new_drag_price=nprice;
         calculaLote(lparam,dparam);
        }
     }

//Mover painel
   if(sparam == "Painel")
     {
      int h=1;
      if(id == CHARTEVENT_OBJECT_DRAG)
        {
         int x_dis = ObjectGetInteger(0,"Painel",OBJPROP_XDISTANCE);
         int y_dis = ObjectGetInteger(0,"Painel",OBJPROP_YDISTANCE);
         ObjectSetInteger(0,"Painel",OBJPROP_XDISTANCE,x_dis);
         ObjectSetInteger(0,"Painel",OBJPROP_YDISTANCE,y_dis);
         //Mover activo
         ObjectSetInteger(0,activo,OBJPROP_XDISTANCE,x_dis+5);
         ObjectSetInteger(0,activo,OBJPROP_YDISTANCE,y_dis-5);
         //Mover linhaCompra
         ObjectSetInteger(0,linhaCompra,OBJPROP_XDISTANCE,x_dis+5+(h++*65));
         ObjectSetInteger(0,linhaCompra,OBJPROP_YDISTANCE,y_dis-5) ;
         //Mover linhaVenda
         ObjectSetInteger(0,linhaVenda,OBJPROP_XDISTANCE,x_dis+5+(h++*65));
         ObjectSetInteger(0,linhaVenda,OBJPROP_YDISTANCE,y_dis-5);
         //Mover numLotes
         ObjectSetInteger(0,numLotes,OBJPROP_XDISTANCE,x_dis+5+(h++*65));
         ObjectSetInteger(0,numLotes,OBJPROP_YDISTANCE,y_dis-5);
         //Mover Percentagem aposta
         //numPercentagem = "ApostaPercentagem",numTakeProfit = "TackProfit";
         ObjectSetInteger(0,numPercentagem,OBJPROP_XDISTANCE,x_dis+5+(h++*65));
         ObjectSetInteger(0,numPercentagem,OBJPROP_YDISTANCE,y_dis-5);
         //Mover botoes
         for(int i = 0; i<ArraySize(botoes); i++)
           {
            ObjectSetInteger(0,botoes[i],OBJPROP_XDISTANCE,x_dis+4+i*65);
            ObjectSetInteger(0,botoes[i],OBJPROP_YDISTANCE,y_dis-5-line_size);
           }
         //Mover apostaPreco
         ObjectSetInteger(0,apostaPreco,OBJPROP_XDISTANCE,x_dis+20+3*button_size);
         ObjectSetInteger(0,apostaPreco,OBJPROP_YDISTANCE,y_dis-6-line_size);
         //Mover TackProfit
         ObjectSetInteger(0,numTakeProfit,OBJPROP_XDISTANCE,x_dis+25+4*button_size);
         ObjectSetInteger(0,numTakeProfit,OBJPROP_YDISTANCE,y_dis-6-line_size);

         ChartRedraw();
        }
     }
  }

//+------------------------------------------------------------------+
//| Delete the button                                                |
//+------------------------------------------------------------------+
bool ButtonDelete(const long   chart_ID=0,    // chart's ID
                  const string name="Button") // button name
  {
//--- reset the error value
   ResetLastError();
//--- delete the button
   if(!ObjectDelete(chart_ID,name))
     {
      Print(__FUNCTION__,
            ": failed to delete the button! Error code = ",GetLastError());
      return(false);
     }
//--- successful execution
   return(true);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calculaLote(long lparam,double dparam)
  {

//Obter o preco
   LinePriceSL=ObjectGetDouble(0,linhaSl,OBJPROP_PRICE);
   LinePriceEnt=ObjectGetDouble(0,linhaEnt,OBJPROP_PRICE);
//Obter o valor da aposta
   valor = StringToDouble(ObjectGetString(0,apostaPreco,OBJPROP_TEXT,0));
//Obter lot minimo
   double min_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
//Print("645min_lot-",min_lot);
//Obter simbolo ativo
   string symbolName= Symbol();

//Obter numero de pontos do ativo
   double simbolPoint = SymbolInfoDouble(Symbol(),SYMBOL_POINT);

//Obter numero de pontos
   if(LinePriceEnt > LinePriceSL)
     {
      nbrPontos = LinePriceEnt - LinePriceSL;
     }
   else
     {
      nbrPontos = LinePriceSL - LinePriceEnt;
     }
   nbrPontos = nbrPontos / simbolPoint;

   double lote = valor/(SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE)*nbrPontos);
   double loteF = NormalizeDouble(lote,3);
   Print(loteF);
   double lt = corrigeLote(loteF);
   Print("-------------------------------------------------------------------------------");
   Print(symbolName,"  Valor= ",valor,"  lote Final= ",lt," ----- "+(string)lt);
   Print("-------------------------------------------------------------------------------");

   if(Comentarios)
     {
      if(LinePriceSL == 0 || LinePriceEnt==0)
        {
         mostraComentarios("");
         //Comment("");
        }
      else
        {
         //string temp = symbolName+"    Valor= "+valor+"    Lote= "+lt+"\n"+"   % = "+Percentagem+"    TP= "+valorTakeProfit;
         string temp = " Valor= "+valor+"    Lote= "+lt+"\n"+"  % = "+valorPercentagem+"    TP= "+valorTakeProfit;
         mostraComentarios(temp);
         //Comment(symbolName,"  Valor= ",valor,"  lote Final= ",lt);
        }
     }

   ObjectSetString(0,numLotes,OBJPROP_TEXT,DoubleToString((lt),Num_Casas_Decimais));//5 direita loteF
  }
//+-----------------------------------------------------------------------------+
//| Funcao para fechar todas as operacoes quando o prejuiso for superior a x%  |
//+-----------------------------------------------------------------------------+
void fechaOperacoes(int porcentagem)
  {
   double porcento = porcentagem * 0.01;
//Print("691-porcentagem-> ",porcentagem);
//Print("692-porcento-> ",porcento);
//Print("693-saldoInicio-> ",saldoInicio);
   double slSaida = saldoInicio*porcento;
//Print("694-slSaida-> ",slSaida);
   double SaldoAux=AccountInfoDouble(ACCOUNT_EQUITY);
//Print("696-SaldoAux-> ",SaldoAux);
//SaldoTemp = SaldoTemp*(-1);
//Print("697-SaldoTemp-> ",SaldoTemp);
   double prejuiso = saldoInicio-SaldoAux;
//Print("700-prejuiso-> ",prejuiso);
   if(prejuiso >= slSaida)
     {
      CTrade trade;
      for(int i = PositionsTotal()-1; i >= 0; i--)
        {
         ulong posTicket = PositionGetTicket(i);
         if(trade.PositionClose(posTicket))
           {
            Print("Position # ",posTicket," was closed...");
           }
        }
      //fechar ordens
      fechaOrdens();
      Sleep(2000);
      if(Apenas_Fechar_Ativos)
        {
         ChartClose(0 // Chart ID
                   );
        }
      else
        {
         TerminalClose(0);    // exit by tick counte
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void macarLinhaMaxMin()
  {
   double lastHigh = 0;
   double lastLow =0;
// SETTING MIN AND MAX OF LAST DAY
   MqlRates PriceDataTableDaily[];
   ArraySetAsSeries(PriceDataTableDaily,true);
   CopyRates(_Symbol,PERIOD_D1,0,3,PriceDataTableDaily);

   for(int i=0; i<=Numero_Dias_Max_Min; i++)
     {
      lastHigh = PriceDataTableDaily[i].high;
      lastLow = PriceDataTableDaily[i].low;

      if(i==0)
        {
         bool obj1=ObjectCreate(ChartID(),"HighHoje",OBJ_HLINE,0,0,lastHigh);
         ObjectSetInteger(ChartID(),"HighHoje",OBJPROP_COLOR,Cor_Max_Hoje);
         ObjectSetInteger(ChartID(),"HighHoje",OBJPROP_WIDTH,1);
         ObjectSetInteger(ChartID(),"HighHoje",OBJPROP_SELECTABLE,true);
         //ObjectSetInteger(ChartID(),"HighHoje",OBJPROP_SELECTED,true);
         bool obj2=ObjectCreate(ChartID(),"LowHoje",OBJ_HLINE,0,0,lastLow);
         ObjectSetInteger(ChartID(),"LowHoje",OBJPROP_COLOR,Cor_Min_Hoje);
         ObjectSetInteger(ChartID(),"LowHoje",OBJPROP_WIDTH,1);
         ObjectSetInteger(ChartID(),"LowHoje",OBJPROP_SELECTABLE,true);
         //ObjectSetInteger(ChartID(),"LowHoje",OBJPROP_SELECTED,true);
         ChartRedraw();
        }
      else
         if(i!=0)
           {
            bool obj1=ObjectCreate(ChartID(),"lastHigh"+i,OBJ_HLINE,0,0,lastHigh);
            ObjectSetInteger(ChartID(),"lastHigh"+i,OBJPROP_COLOR,Cor_Max_Anterior);
            ObjectSetInteger(ChartID(),"lastHigh"+i,OBJPROP_WIDTH,1);
            ObjectSetInteger(ChartID(),"lastHigh"+i,OBJPROP_SELECTABLE,true);
            //ObjectSetInteger(ChartID(),"lastHigh"+i,OBJPROP_SELECTED,true);
            bool obj2=ObjectCreate(ChartID(),"lastLow"+i,OBJ_HLINE,0,0,lastLow);
            ObjectSetInteger(ChartID(),"lastLow"+i,OBJPROP_COLOR,Cor_Min_Anterior);
            ObjectSetInteger(ChartID(),"lastLow"+i,OBJPROP_WIDTH,1);
            ObjectSetInteger(ChartID(),"lastLow"+i,OBJPROP_SELECTABLE,true);
            //ObjectSetInteger(ChartID(),"lastLow"+i,OBJPROP_SELECTED,true);
            ChartRedraw();
           }
     }
  }
//+-----------------------------------------------------------------------------+
//| Funcao para calcular o numero de operacoes abertas                          |
//+-----------------------------------------------------------------------------+
bool devolveOperacoes()
  {
   bool retorno = false;
   int nbrOpera = PositionsTotal();
   string texto = "768-"+Symbol()+"-nbrOpera-"+nbrOpera;
   copiaString_File(texto);
   if(Operacoes <= nbrOpera)
     {
      retorno = true;
     }
   else
     {
      retorno = false;
     }
   return retorno;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void copiaString_File(string str)
  {
//--- parâmetros para escrever dados no arquivo
   string             InpFileName="LOG.txt";   // nome do arquivo
   string             InpDirectoryName="DadosLog"; // nome do diretório
   string caminho = "C:\\Users\\Anibal Mota\\AppData\\Roaming\\MetaQuotes\\Terminal\\961D7739921E9D66BF2DF88718013F65\\"+InpDirectoryName;
   int file_handle=FileOpen(InpFileName,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);
   if(file_handle!=INVALID_HANDLE)
     {
      FileSeek(file_handle,0,SEEK_END);
      FileWriteString(file_handle,str+"\r\n");
      //--- preparar variáveis adicionais
      //--- fechar o arquivo
      FileClose(file_handle);
     }
  }

//+-----------------------------------------------------------------------------+
//| Funcao para calcular o valor a apostar atraves da porcentagem%  |
//+-----------------------------------------------------------------------------+
double calculaAposta(double porcentagem)
  {
   saldo= AccountInfoDouble(ACCOUNT_BALANCE);//Saldo da conta
   double porcento = porcentagem * 0.01;
   double SaldoTemp = saldo*porcento;
   return SaldoTemp;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int separaStringAno(string to_split)
  {
//string to_split="_life_is_good_"; // Um string para dividir em substrings
   string sep2=".";                 // Um separador como um caractere
   ushort u_sep;                    // O código do caractere separador
   string result[];                 // Um array para obter strings
   int resultado=0;
//--- Obtém o código do separador
   u_sep=StringGetCharacter(sep2,0);
//--- Divide a string em substrings
   int k=StringSplit(to_split,u_sep,result);
   if(k>0)
     {
      string temp =result[0];
      resultado = StringToInteger(temp);
     }
   return resultado;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double corrigeLote(double lote)
  {
//Obter lot minimo
   double min_lot = SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_MIN);
   double resultado;

   Print("lote-",lote);
   double divisao = lote/min_lot;

   divisao = NormalizeDouble(divisao,0);

   double val=0;
   if(min_lot == 0.5)
     {
      val=0.5;
      resultado = divisao * val;
      Num_Casas_Decimais = 1;
     }
   else
      if(min_lot == 0.25)
        {
         val=0.25;
         Num_Casas_Decimais = 2;
         resultado = divisao * val;
        }
      else
         if(min_lot == 0.2)
           {
            val=0.2;
            Num_Casas_Decimais = 1;
            resultado = divisao * val;
           }
         else
            if(min_lot == 1)
              {
               Num_Casas_Decimais = 0;
               resultado = NormalizeDouble(lote,0);
              }
            else
               if(min_lot == 0.01)
                 {
                  val=0.01;
                  Num_Casas_Decimais = 2;
                  resultado = divisao * val;
                 }
               else
                  if(min_lot == 0.05)
                    {
                     val=0.05;
                     Num_Casas_Decimais = 2;
                     resultado = divisao * val;
                    }
                  else
                    {
                     Num_Casas_Decimais = 1;
                     resultado = lote;
                    }
   return resultado;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void inicio()
  {
   double saldo= AccountInfoDouble(ACCOUNT_BALANCE);//Saldo da conta
   double prejuiso=AccountInfoDouble(ACCOUNT_PROFIT);//
   double capital_Liquido=AccountInfoDouble(ACCOUNT_EQUITY);//
   string data = TimeToString(TimeCurrent(),TIME_DATE);
   int ano = separaStringAno(data);
   string res = lerFicheiro("BD\\Diario.txt");
   if(res.Find(data)<0)
     {
      Print("915-Data inserida no ficheiro");
      gravaFicheiro("BD\\Diario.txt", data+"-"+saldo);
      saldoInicio = saldo;
      Print("918-saldoInicio-"+saldoInicio);
     }
   else
     {
      Print("Data já inserida");
      saldoInicio = separaStringSaldo(res);
      Print("924-saldoInicio-"+saldoInicio);
     }
   HistorySelect(0,TimeCurrent());
   int TotalDeals = HistoryDealsTotal();
  }
//+------------------------------------------------------------------+
//| Funcao para ler texto no ficheiro                                |
//+------------------------------------------------------------------+
string lerFicheiro(string nomeFicheiro)
  {
   ulong file_size=0;
   int str_size = 0,nbrLinhas = 0;
   string str,str1;
   ResetLastError();
   int file_handle=FileOpen(nomeFicheiro,FILE_READ|FILE_TXT|FILE_ANSI);
   if(file_handle!=INVALID_HANDLE)
     {
      file_size=FileSize(file_handle);
      //--- ler dados de um arquivo
      while(!FileIsEnding(file_handle))
        {
         //--- descobrir quantos símbolos são usados ​​para escrever o tempo
         str_size=FileReadInteger(file_handle,INT_VALUE);
         //--- ler a string
         str=FileReadString(file_handle,str_size);
         //--- imprimir a string
         nbrLinhas++;
        }
      //--- fechar o arquivo
      FileClose(file_handle);
     }

   return str;
  }
//+------------------------------------------------------------------+
//| Funcao para gravar texto no ficheiro                             |
//+------------------------------------------------------------------+
void gravaFicheiro(string nomeFicheiro, string texto)
  {
//string mySpreadsheet = "Spreadsheet.txt";
//int mySpredsheetHandle = FileOpen(mySpreadsheet,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI);
   int mySpredsheetHandle = FileOpen(nomeFicheiro,FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);

//go to the end of the file
   FileSeek(mySpredsheetHandle,0,SEEK_END);//SEEK_SET inicio do ficheiro

   FileWrite(mySpredsheetHandle,texto);

   FileClose(mySpredsheetHandle);

  }
//+-----------------------------------------------------------------------------+
//| Funcao para fechar todas as ordens quando o prejuiso for superior a x%      |
//+-----------------------------------------------------------------------------+
void fechaOrdens()
  {
   int nbrOrdens  = OrdersTotal();
   long ticket;
   while(nbrOrdens>0)
     {
      for(int i=0; i<nbrOrdens; i++)
        {
         if((ticket=OrderGetTicket(i))>0)
           {
            ticket=OrderGetTicket(i);
            negocio.OrderDelete(ticket);
            Print("Position # ",ticket," was closed...");
           }
        }
      nbrOrdens  = OrdersTotal();
     }
  }
//+------------------------------------------------------------------+
//|Devolve o Saldo                                               |
//+------------------------------------------------------------------+
double separaStringSaldo(string to_split)
  {
//string to_split="_life_is_good_"; // Um string para dividir em substrings
   string sep2="-";                 // Um separador como um caractere
   ushort u_sep;                    // O código do caractere separador
   string result[];                 // Um array para obter strings
   double resultado=0;
//--- Obtém o código do separador
   u_sep=StringGetCharacter(sep2,0);
//--- Divide a string em substrings
   int k=StringSplit(to_split,u_sep,result);
   if(k>0)
     {
      string temp =result[1];
      resultado = StringToDouble(temp);
     }
   return resultado;
  }

//+------------------------------------------------------------------+
//| Returns the last deal ticket in history or -1                    |
//+------------------------------------------------------------------+
ulong GetLastDealTicket()
  {
//--- request history for the last 7 days
   if(!GetTradeHistory1(7))
     {
      //--- notify on unsuccessful call and return -1
      Print(__FUNCTION__," HistorySelect() returned false");
      return -1;
     }
//---
   ulong first_deal,last_deal,deals=HistoryOrdersTotal();
//--- work with orders if there are any
   if(deals>0)
     {
      first_deal=HistoryDealGetTicket(0);
      if(deals>1)
        {
         last_deal=HistoryDealGetTicket((int)deals-1);
         return last_deal;
        }
      return first_deal;
     }
//--- no deal found, return -1
   return -1;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void gravaBD(int nbrDays)
  {

//---
   string tipo = "";
   string priceS="";
   string profitS="";
   color BuyColor =clrBlue;
   color SellColor=clrRed;
   datetime tm=TimeCurrent();
   string str1="Date and time with minutes: "+TimeToString(tm);
   string str2="Date only: "+TimeToString(tm,TIME_DATE);
   MqlDateTime mdt;
   TimeCurrent(mdt);
   Print("TimeCurrent(mdt)-",TimeCurrent());

   GetTradeHistory(nbrDays);
//--- cria objetos
   string   name;
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime time;
   string   symbol;
   long     type;
   long     entry;
   Print("total-",total);

//GetTradeHistory(2);

//--- para todos os negócios
   if(total > 0)
     {
      if(FileIsExist(Nome_do_Ficheiro))
         FileDelete(Nome_do_Ficheiro);
     }
   for(uint i=0; i<total; i++)
     {
      //--- tentar obter ticket negócios
      if((ticket=HistoryDealGetTicket(i))>0)
        {
         //--- obter as propriedades negócios
         price =HistoryDealGetDouble(ticket,DEAL_PRICE);
         time  =(datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         symbol=HistoryDealGetString(ticket,DEAL_SYMBOL);
         type  =HistoryDealGetInteger(ticket,DEAL_TYPE);
         entry =HistoryDealGetInteger(ticket,DEAL_ENTRY);
         profit=HistoryDealGetDouble(ticket,DEAL_PROFIT);
         //--- apenas para o símbolo atual
         // if(price && time && symbol==Symbol())
         //  {
         //--- cria o preço do objeto
         /*
         name="TradeHistory_Deal_"+string(ticket);
         if(entry) ObjectCreate(0,name,OBJ_ARROW_RIGHT_PRICE,0,time,price,0,0);
         else      ObjectCreate(0,name,OBJ_ARROW_LEFT_PRICE,0,time,price,0,0);
         //--- definir propriedades do objeto
         ObjectSetInteger(0,name,OBJPROP_SELECTABLE,0);
         ObjectSetInteger(0,name,OBJPROP_BACK,0);
         ObjectSetInteger(0,name,OBJPROP_COLOR,type?BuyColor:SellColor);
         */
         if(entry!=0)
           {
            if(type == 0)
              {
               tipo = "Shell";
              }
            else
               if(type == 1)
                 {
                  tipo = "Buy";
                 }
            ObjectSetString(0,name,OBJPROP_TEXT,"Profit: "+string(profit));
            priceS=DoubleToString(price, 2);
            //StringReplace(priceS,".",",");
            profitS=DoubleToString(profit, 2);
            //StringReplace(profitS,".",",");
            string temp = time+"#"+symbol+"#"+ticket+"#"+tipo+"#"+priceS+"#"+profitS;
            //Print(temp);
            gravaFicheiro(Nome_do_Ficheiro, temp);
           }
         //  }
        }
     }
//--- aplicar no gráfico
   ChartRedraw();
  }

//+--------------------------------------------------------------------------+
//| Requests history for the last days and returns false in case of failure  |
//+--------------------------------------------------------------------------+
bool GetTradeHistory(int days)
  {
//-- Esta funcao esta a ser chamada na Linha 27

   end=TimeCurrent();
//--- Alterar o numero de dias para que 1 corresponda a hoje
   int dias = days -1;
   datetime from=end-dias*PeriodSeconds(PERIOD_D1);
   string tempD = separaString(""+from);
   string tempD1 = tempD + " 00:00:00";
   start= StringToTime(tempD1);
   ResetLastError();
//--- make a request and check the result
   if(!HistorySelect(start,end))
     {
      Print(__FUNCTION__," HistorySelect=false. Error code=",GetLastError());
      return false;
     }

//--- history received successfully
   return true;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string separaString(string to_split)
  {
//string to_split="_life_is_good_"; // Um string para dividir em substrings
   string sep2=" ";                 // Um separador como um caractere
   ushort u_sep;                    // O código do caractere separador
   string result[];                 // Um array para obter strings
   string resultado="";
//--- Obtém o código do separador
   u_sep=StringGetCharacter(sep2,0);
//--- Divide a string em substrings
   int k=StringSplit(to_split,u_sep,result);
   if(k>0)
     {
      resultado =result[0];
     }
   return resultado;
  }

//+--------------------------------------------------------------------------+
//| Requests history for the last days and returns false in case of failure  |
//+--------------------------------------------------------------------------+
bool GetTradeHistory1(int days)
  {
//--- set a week period to request trade history
   datetime to=TimeCurrent();
   datetime from=to-days*PeriodSeconds(PERIOD_D1);
   ResetLastError();
//--- make a request and check the result
   if(!HistorySelect(from,to))
     {
      Print(__FUNCTION__," HistorySelect=false. Error code=",GetLastError());
      return false;
     }
//--- cria objetos
   string   name;
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime time;
   string   symbol;
   long     type;
   long     entry;
   Print("total-",total);
//--- history received successfully
   return true;
  }
//+--------------------------------------------------------------------------+
//| Devolve o numero de operacoes,                                           |
//+--------------------------------------------------------------------------+
double numeroOperacoes()
  {
   GetTradeHistory(1);
   string   name;
   uint     total=HistoryDealsTotal();
   ulong    ticket=0;
   double   price;
   double   profit;
   datetime time;
   string   symbol;
   long     type;
   long     entry;
   return total;
  }
//+------------------------------------------------------------------+
//|  Inicializando contadores de posições, de ordens e de transações |
//+------------------------------------------------------------------+
void InitCounters()
  {
   ResetLastError();
//--- carregamos o histórico
   bool selected=HistorySelect(start,end);
   if(!selected)
     {
      PrintFormat("%s. Não foi possível carregar no cache o histórico de %s a %s. Código de erro: %d",
                  __FUNCTION__,TimeToString(start),TimeToString(end),GetLastError());
      return;
     }
//--- obtemos os valores atuais
   orders=OrdersTotal();
   positions=PositionsTotal();
   deals=HistoryDealsTotal();
   history_orders=HistoryOrdersTotal();
   started=true;
//Print("Inicialização de contadores de ordens, de posições e de transações bem-sucedida");
  }

//+------------------------------------------------------------------+
//| exemplo de processamento de alterações na negociação e no histórico
//+------------------------------------------------------------------+
int SimpleTradeProcessor()
  {
   int curr_deals=0;
   end=TimeCurrent();
   ResetLastError();
//--- carregamos no cache do programa o histórico de negociação a partir do intervalo especificado
   bool selected=HistorySelect(start,end);
   if(!selected)
     {
      PrintFormat("%s. Não foi possível carregar no cache o histórico de %s a %s. Código de erro: %d",
                  __FUNCTION__,TimeToString(start),TimeToString(end),GetLastError());
      return curr_deals;
     }
//--- obtemos os valores atuais
   int curr_orders=OrdersTotal();
   int curr_positions=PositionsTotal();
   curr_deals=HistoryDealsTotal();
   int curr_history_orders=HistoryOrdersTotal();
//--- verificamos as alterações na quantidade de ordens vigentes
   if(curr_orders!=orders)
     {
      //--- número de ordens vigentes alterado
      /*PrintFormat("O número de ordens foi alterado de %d para %d",
                  orders,curr_orders);*/
      //--- atualizamo o valor
      orders=curr_orders;
     }
//--- alteração no número de posições abertas
   if(curr_positions!=positions)
     {
      //--- o número de posições abertas foi alterado
      /*PrintFormat("O número de posições abertas foi alterado de %d para %d",
                  positions,curr_positions);*/
      //--- atualizamo o valor
      positions=curr_positions;
     }
//--- alterações no número de transações no cache do histórico de negociação
   if(curr_deals!=deals)
     {
      //--- número de transações no cache do histórico de negociação foi alterado
      /*PrintFormat("O número de transações foi alterado de %d para %d",
                  deals,curr_deals);*/
      insereAlertas(curr_deals);
      //--- atualizamo o valor
      deals=curr_deals;
     }
//--- alterações no número de ordens históricas no cache do histórico de negociação
   if(curr_history_orders!=history_orders)
     {
      //--- número de ordens históricas no cache do histórico de negociação foi alterado
      /*PrintFormat("O número de ordens no histórico foi alterado de %d para %d",
                  history_orders,curr_history_orders);*/
      //--- atualizamos o valor
      history_orders=curr_history_orders;
     }
//--- verificamos se é necessário alterar os limites do histórico de negociação para solicitação no cache
   ativo = CheckStartDateInTradeHistory();
   return curr_deals;

  }
//+------------------------------------------------------------------+
//|  alterações da data de início para a solicitação do histórico de negociação
//+------------------------------------------------------------------+
string CheckStartDateInTradeHistory()
  {
//--- intervalo de início, se começarmos a trabalhar agora
   datetime curr_start=TimeCurrent()-days*PeriodSeconds(PERIOD_D1);
//--- verificamos que o limite do início do histórico de transações seja inferior
//--- a 1 dia a partir da data planejada
   if(curr_start-start>PeriodSeconds(PERIOD_D1))
     {
      //--- deve-se corrigir a data de início do histórico carregado no cache
      start=curr_start;
      PrintFormat("Novo limite de início do histórico de negociação carregado: início => %s",
                  TimeToString(start));
      //--- agora recarregamos o histórico de transações para o intervalo atualizado
      HistorySelect(start,end);
      //--- corrigimos os contadores de transações e de ordens no histórico para a próxima comparação
      history_orders=HistoryOrdersTotal();
      deals=HistoryDealsTotal();
     }
   ulong deal_ticket = HistoryDealGetTicket(deals-1);
   string symbol = HistoryDealGetString(deal_ticket,DEAL_SYMBOL);
   return symbol;
  }

//+------------------------------------------------------------------+
//|  Inserir alertas
//+------------------------------------------------------------------+
void insereAlertas(int dois1)
  {
   if(MathMod(dois1,2) == 0)
     {
      //PlaySound("stops.wav");
      if(ativo == simbolo)
        {
         Print("ativo simbolo- ",ativo," ",simbolo);
         int dois = dois1 / 2;
         if(dois >= Operacoes)
           {
            Sleep(2000);
            if(Apenas_Fechar_Ativos)
              {
               long chid=ChartFirst();
               while(chid >= 0)                             // Just do ALL charts, no counting needed.
                 {
                  long nextID = ChartNext(chid);            // Get the next chart before closing current
                  //if(ChartSymbol(chid)==cs)
                  ChartClose(chid);
                  chid = nextID;                            // process next chart.
                 }
              }
            else
              {
               TerminalClose(0);    // exit by tick counte
              }
           }
         else
            if(dois == Operacoes-1)
              {
               if(Alerta)
                 {
                  Sleep(2000);
                  MessageBox(
                     "ATENÇÃO!!!                                     \n\n"
                     "Até este momento executou "+dois+" Operações!!!\n\n"
                     "Se ainda não atingiu os objetivos, desligue o pc e vá descansar!!!\n\n\n"
                     "HOJE NÃO É DIA!!!\n\n\n",           // texto da mensagem
                     "Total de Ordens permitidas: "+Operacoes,     // cabeçalho da caixa
                     MB_ICONWARNING     // define o conjunto de botões na caixa
                  );

                  if(PlaySound("alert.wav") == false)
                    {
                     Print("Alerta nao encontrado");
                    }
                 }
              }
            else
               if(dois >=1 && dois < Operacoes-1)
                 {
                  if(Alerta)
                    {
                     Sleep(2000);
                     MessageBox(
                        "Até este momento executou "+dois+" Operações!!!\n\n",// texto da mensagem
                        "Total de Ordens permitidas: "+Operacoes,     // cabeçalho da caixa
                        MB_ICONINFORMATION     // define o conjunto de botões na caixa
                     );
                    }
                 }
        }
     }

  }
//+------------------------------------------------------------------+
//|  Inserir alertas no Inicio
//+------------------------------------------------------------------+
void insereAlertasInicio()
  {

   Sleep(2000);
   if(Apenas_Fechar_Ativos)
     {
      long chid=ChartFirst();
      while(chid >= 0)                             // Just do ALL charts, no counting needed.
        {
         long nextID = ChartNext(chid);            // Get the next chart before closing current
         //if(ChartSymbol(chid)==cs)
         ChartClose(chid);
         chid = nextID;                            // process next chart.
        }
     }
   else
     {
      TerminalClose(0);    // exit by tick counte
     }
  }

//+------------------------------------------------------------------+
//|  Mostra activos
//+------------------------------------------------------------------+
void mostraActivos()
  {
   int total=SymbolsTotal(true)-1;

   for(int i=total; i>0; i--)
     {
      string Sembol=SymbolName(i,true);
      Print("Number: "+string(i)+" Sembol Name: "+Sembol+" Close Price: ",iClose(Sembol,0,0));
     }
  }

//+------------------------------------------------------------------+
//| Inserir comentarios
//+------------------------------------------------------------------+
void mostraComentarios(string comenta)
  {
   Comment(comenta);
  }
//+------------------------------------------------------------------+
//| Criar nova linha de Compra
//+------------------------------------------------------------------+
void criarLinhaCompra(double posicao)
  {
//Criar linha Ent
   ent_is_object_being_dragged=false;
   ent_new_drag_price=0;
//Criar linha TP
   bool obj1=ObjectCreate(ChartID(),linhaEnt,OBJ_HLINE,0,0,posicao);
   ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_COLOR,Cor_Compra);
   ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_WIDTH,Espessura_Linha_Ordem);
   ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(ChartID(),linhaEnt,OBJPROP_SELECTED,true);
   ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_MOVE,true);

   ObjectSetString(0,linhaCompra,OBJPROP_TEXT,posicao);//2 Direita
   ent=true;
   ChartRedraw();

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void criarLinhaVenda(double posicao)
  {

//Criar linha SL
   sl_is_object_being_dragged=false;
   sl_new_drag_price=0;
//create a test line SL
   bool obj=ObjectCreate(ChartID(),linhaSl,OBJ_HLINE,0,0,posicao);
   ObjectSetInteger(ChartID(),linhaSl,OBJPROP_COLOR,Cor_Venda);
   ObjectSetInteger(ChartID(),linhaSl,OBJPROP_WIDTH,Espessura_Linha_Ordem);
   ObjectSetInteger(ChartID(),linhaSl,OBJPROP_SELECTABLE,true);
   ObjectSetInteger(ChartID(),linhaSl,OBJPROP_SELECTED,true);
   ChartSetInteger(ChartID(),CHART_EVENT_MOUSE_MOVE,0,true);

   ObjectSetString(0,linhaVenda,OBJPROP_TEXT,posicao);//3 direita
   sl=true;
   ChartRedraw();
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
