unit IDataPrincipalUnit;

interface

uses Data.SqlExpr, Classes, Data.DBXCommon;

type

IDataPrincipal = interface
  function startTransaction:TDBXTransaction; overload;                     //Inicia uma transação no banco de dados

  procedure commit(aDbxTransaction: TDBXTransaction); overload;                               //faz commit dos dados da transação
                                                            //genérica

  procedure rollback(aDbxTransaction: TDBXTransaction); overload;                             //faz o rollback da transação ativa

  function getSQLResult(sqlText: string): variant;          //retorna o resultado de uma query
                                                            //ele pode ser de qualquer tipo

  function getSQLIntegerResult(sqlText: string): integer;   //retorna um resultado inteiro
                                                            //de uma query. Útil em queries de count e max

  procedure execSQL(sqlText: string; retries: integer = 0); //executa um comando SQL sem resultado

  procedure refreshData;                                    //faz refresh dos dados do client
                                                            //em firebird por exemplo é um Commit Work

  function getQuery: TSQLDataSet;                              //retorna um TSQLDataSet conectado na base
  function sincronizar: boolean;                            //indica se deve-se ou não sincronizar
                                                            //com a parte web. Útil quando queremos ter
                                                            //clientes que sincronizam e outros que não sincronizam
  function ExecuteDirect(const aExecStatement: string): integer; overload; //Executa um Insert/Update em um contexto de conexão isolado
  function ExecuteDirect(aQuery: TSQLDataSet): integer; overload;
end;

implementation

end.
