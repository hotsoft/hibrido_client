unit DIntegradorModuloWeb;

interface

uses
  SysUtils, ExtCtrls, DBClient, idHTTP, MSXML2_TLB, dialogs, acStrUtils, acNetUtils,
  DB, IdMultipartFormData, IdBaseComponent, IdComponent, IdTCPConnection, forms,
  IdTCPClient, IdCoder, IdCoder3to4, IdCoderUUE, IdCoderXXE, Controls,
  IDataPrincipalUnit, idURI, System.Classes, Windows,
  ISincronizacaoNotifierUnit, Data.SqlExpr,
  Xml.XMLIntf, Winapi.ActiveX, XML.XMLDoc, System.Generics.Collections, HTTPApp, StrUtils, UtilsUnit, Data.DBXCommon,
  Soap.EncdDecd, Variants {$IFDEF VER250}, Data.DBXJSON, Data.DBXPlatform {$ENDIF} {$IFDEF VER300}, System.JSON {$ENDIF};

type
  THttpAction = (haGet, haPost);

  TDataIntegradorModuloWeb = class;

  TOnExceptionProcedure = procedure (AHttpAction: THttpAction; aIntegrador: TDataIntegradorModuloWeb; const AExceptionClassName, aExceptionMessage: string; const aRecordId: integer) of object;

  TJsonSetting = class
  private
    FTableName: string;
    FPostStatement: string;
    FPostToServer: boolean;
    FNomePlural: string;
    procedure SetPostStatement(const Value: string);
    procedure SetPostToServer(const Value: boolean);
    procedure SetTableName(const Value: string);
    procedure SetNomePlural(const Value: string);
  public
    property TableName: string read FTableName write SetTableName;
    property NomePlural: string read FNomePlural write SetNomePlural;
    property PostToServer: boolean read FPostToServer write SetPostToServer;
    property PostStatement: string read FPostStatement write SetPostStatement;
  end;

  TJsonDictionary = class(TDictionary<String, TJsonSetting>)
  public
    destructor Destroy; override;
  end;

  TStringDictionary = class(TDictionary<String, String>)
  end;

  TXMLNodeDictionary = class(TDictionary<string, IXMLDomNode>)
  end;

  TTabelaDetalhe = class;

  TTabelaDetalheList = class(TObjectList<TTabelaDetalhe>)
  end;

  TFieldDictionary = class
  private
   FFieldName: string;
   FfieldType: TFieldType;
    procedure SetFieldName(const Value: string);
  public
    property FieldName: string read FFieldName write SetFieldName;
    property DataType: TFieldType read FFieldType write FFieldType;
  end;

  TFieldDictionaryList = class(TDictionary <string, TFieldDictionary>)
  private
    FDm : IDataPrincipal;
    FTableName: string;
    procedure getTableFields;
  public
    constructor Create(const aTableName: string; aDm : IDataPrincipal);
    destructor Destroy; override;
  end;

  EIntegradorException = class(Exception)
  end;

  TDMLOperation = (dmInsert, dmUpdate);

  TParamsType = (ptParam, ptJSON);

  TAnonymousMethod = reference to procedure(aDataSet: TDataSet);

  TDataIntegradorModuloWebClass = class of TDataIntegradorModuloWeb;

  TNameTranslation = class
  public
    server: string;
    pdv: string;
    lookupRemoteTable: string;
    fkName: string;
    DataIntegradorClass: TDataIntegradorModuloWebClass;
  end;

  TNameTranslationsList = class (TObjectList<TNameTranslation>)
  end;

  TTranslationSet = class
    public
      Translations: TNameTranslationsList;
      constructor create(owner: TComponent);
      destructor Destroy; override;
      procedure add(serverName, pdvName: string;
        lookupRemoteTable: string = ''; fkName: string = '';
        aDataIntegradorClass: TDataIntegradorModuloWebClass = nil);
      function translateServerToPDV(serverName: string; duasVias: boolean): string;
      function translatePDVToServer(pdvName: string): string;
      function size: integer;
      function get(index: integer): TNameTranslation;
  end;

  TTabelaDependente = class
  public
    nomeTabela: string;
    nomeFK: string;
  end;

  TTabelaDependenteList = class (TObjectList<TTabelaDependente>)
  end;

  TJSONArrayContainer = class
  private
    FJSonArray: TJsonArray;
  public
    nomePluralDetalhe: string;
    nomeSingularDetalhe: string;
    nomeTabela: string;
    nomePkLocal: string;
    function getJsonArray: TJsonArray;
    destructor Destroy; override;
  end;

  TDetailList = class(TDictionary<String, TJSONArrayContainer>)
  public
    destructor Destroy; override;
  end;

  TDataIntegradorModuloWeb = class(TDataModule)
  const
    opPOST = 'P';
    opGET = 'G';
  private
    FdmPrincipal: IDataPrincipal;
    Fnotifier: ISincronizacaoNotifier;
    FthreadControl: IThreadControl;
    FCustomParams: ICustomParams;
    FstopOnPostRecordError: boolean;
    FStopOnGetRecordError : boolean;
    FStatementForPost: string;
    FnomeFK: string;
    FHTTP: TIdHTTP;
    procedure addTabelaDetalheParams(valorPK: integer;
      params: TStringList;
      tabelaDetalhe: TTabelaDetalhe);
    function GetErrorMessage(const aErro, aContentType: string): string;
    procedure SetDataLog(const Value: ILog);
    procedure SetthreadControl(const Value: IThreadControl);
    procedure OnWorkHandler(ASender: TObject; AWorkMode: TWorkMode; AWorkCount: Int64);
    function getFieldInsertList(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
    function BinaryFromBase64(const base64: string): TBytesStream;
    procedure SelectDetailsIterate(aDetailList: TDetailList; aValorPK: integer);
    procedure addTabelaDetalheParamsIterate(valorPK: integer; params: TStringList);
    procedure ExecQuery(aQry: TSQLDataSet);
    function CheckQryCommandTextForDuasVias(const aId: integer;  Integrador: TDataIntegradorModuloWeb): string;
    procedure resyncRecord(const aId: integer);
    function EscapeValueToServer(const aValue: string): string;
    function GetVersionIdFromServer(pIdRemoto: Integer; pNomeTabela: String): Int64;
    procedure setVersionIdToJSON(pJSON: TJsonObject; pTabela, pId: String);
    function getLastVersionIDLocal(pTabela: String) : Int64;
    function RegistroAindaExiste(pTabela, pID: String): Boolean;
    function ValidaRegistroFila(pTabela: String; pPkLocal: Integer): Boolean;
    const
      SQLFK =
        ' SELECT'+
        '    TRIM(detail_index_segments.rdb$field_name) AS field_name,'+
        '    TRIM(master_relation_constraints.rdb$relation_name) AS reference_table,'+
        '    TRIM(master_index_segments.rdb$field_name) AS fk_field'+
        ' FROM'+
        '    rdb$relation_constraints detail_relation_constraints'+
        '    JOIN rdb$index_segments detail_index_segments ON detail_relation_constraints.rdb$index_name = detail_index_segments.rdb$index_name '+
        '    JOIN rdb$ref_constraints ON detail_relation_constraints.rdb$constraint_name = rdb$ref_constraints.rdb$constraint_name '+ // Master indeksas
        '    JOIN rdb$relation_constraints master_relation_constraints ON rdb$ref_constraints.rdb$const_name_uq = master_relation_constraints.rdb$constraint_name '+
        '    JOIN rdb$index_segments master_index_segments ON master_relation_constraints.rdb$index_name = master_index_segments.rdb$index_name '+
        ' WHERE'+
        '    detail_relation_constraints.rdb$constraint_type = ''FOREIGN KEY'''+
        '    AND detail_relation_constraints.rdb$relation_name = ''%s''';

  protected
    FFieldList : TFieldDictionaryList;
    FDataLog: ILog;
    FTranslateTableNames: TJsonDictionary;
    FnomeTabela: string;
    FnomeSingular: string;
    FNomePlural: string;
    FnomePKLocal: string;
    FIdAtual: Integer;
    nomePKRemoto: string;
    nomeGenerator: string;
    usePKLocalMethod: Boolean;
    duasVias: boolean;
    clientToServer: boolean;
    FEncodeJsonValues : boolean;
    tabelasDependentes: TTabelaDependenteList;
    offset: integer;
    paramsType: TParamsType;
    FOnException: TOnExceptionProcedure;
    FLastStream: TStringStream;
    FVersionIdAtual: Int64;
    FIdRemotoEncontrado : Boolean;
    FFilaSincronizacaoCDS: TClientDataSet;
    FRecursividadeAtiva: Boolean;
    FIdRemotoAtual: Integer;
    function getVersionFieldName: string; virtual;
    procedure Log(const aLog: string; aClasse: string = ''); virtual;
    function extraGetUrlParams: String; virtual;
    procedure beforeRedirectRecord(idAntigo, idNovo: integer); virtual;
    function importRecord(node: IXMLDomNode; var _LastId: Integer): boolean; virtual;
    function updateInsertRecord(node: IXMLDomNode; const id: integer; pOperacao: String; var _LastId: Integer): Boolean;
    function jaExiste(aNode:IXMLDOMNode; const id: integer; Integrador: TDataIntegradorModuloWeb; var aCustomWhere: string; var pIdLocal: Integer): Int64;
    function getFieldList(node: IXMLDomNode): string;
    function getFieldUpdateList(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
    function getFieldValues(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
    function translateFieldValue(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string; virtual;
    function translateFieldNamePdvToServer(node: IXMLDomNode): string;
    function translateFieldNameServerToPdv(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string; virtual;
    function translateTypeValue(fieldType, fieldValue: string): string;
    function translateValueToServer(translation: TNameTranslation;
      fieldName: string; field: TField;
      nestedAttribute: string = ''; fkName: string = ''; fieldValue: String = ''): string; virtual;
    function translateValueFromServer(fieldName, value: string; Integrador: TDataIntegradorModuloWeb): string; virtual;
    procedure redirectRecord(idAntigo, idNovo: integer);
    function getFieldAdditionalList(node: IXMLDomNode): string; virtual;
    function getFieldAdditionalValues(node: IXMLDomNode): string; virtual;
    function getFieldAdditionalUpdateList(node: IXMLDomNode): string; virtual;
    function nomeActionSave: string; virtual;
    function nomeActionGet: string; virtual;
    function nomeSingularSave: string; virtual;
    function nomeSingularGet: string; virtual;
    procedure updateSingletonRecord(node: IXMLDOMNode);
    function getOrderBy: string; virtual;
    procedure addMoreParams(ds: TDataSet; params: TStringList); virtual;
    procedure prepareMultipartParams(ds: TDataSet;
      multipartParams: TIdMultiPartFormDataStream); virtual; abstract;
    function singleton: boolean;
    function getUpdateBaseSQL(node: IXMLDOMNode; Integrador: TDataIntegradorModuloWeb): string;
    procedure addDetails(ds: TDataSet; params: TStringList);
    function addTranslatedParams(ds: TDataSet; params: TStringList;
      translations: TTranslationSet; nestedAttribute: string = ''): IXMLDomDocument2;
    function getAdditionalSaveConditions: string; virtual;
    function gerenciaRedirecionamentos(idLocal, idRemoto: integer): boolean; virtual;
    function getNewDataPrincipal: IDataPrincipal; virtual; abstract;
    function maxRecords: integer; virtual;
    function getTimeoutValue: integer; virtual;
    function getDateFormat: String; virtual;
    function getAdditionalDetailFilter:String; virtual;
    function shouldContinue: boolean;
    procedure onDetailNamesMalformed(configName, tableName: string); virtual;
    function getIncludeFieldNameOnList(const aDMLOperation: TDMLOperation; const aFieldName: string; Integrador: TDataIntegradorModuloWeb): boolean; virtual;
    function getObjectsList: string; virtual;
    function getUpdateStatement(node: IXMLDomNode; const id: integer): String; virtual;
    function getInsertStatement(node: IXMLDomNode): String; virtual;
    function getNewId(node: IXMLDomNode): Integer; virtual;
    function Post(ds: TDataSet; http: TidHTTP; url: string; pTrans: TDBXTransaction): string; virtual;
    procedure addDetailsToJsonList(aDetailList: TDetailList; aDs: TDataSet); virtual;
    procedure SelectDetails(aDetailList: TDetailList; aValorPK: integer; aTabelaDetalhe: TTabelaDetalhe); virtual;
    function getJsonObject(aDs: TDataSet; aTranslations: TTranslationSet; aDict: TStringDictionary; aNestedAttribute: string = '') : TJsonObject; virtual;
    procedure addMasterTableToJson(aDetailList: TDetailList; aDs: TDataSet; apStream: TStringStream); virtual;
    procedure RunDataSet(const aValorPK: integer; aTabelaDetalhe: TTabelaDetalhe; aProc: TAnonymousMethod); virtual;
    function GetIdRemoto(aDoc: IXMLDomDocument2): integer;
    function GetVersionId(aDoc: IXMLDomDocument2): Int64;
    function getXMLContentAsXMLDom(const aXMLContent: string): IXMLDomDocument2;
    procedure SetdmPrincipal(const Value: IDataPrincipal); virtual;
    function getdmPrincipal: IDataPrincipal; virtual;
    function JsonObjectHasPair(const aName: string; aJson: TJSONObject): boolean;
    function DataSetToArray(aDs: TDataSet): TStringDictionary; virtual;
    procedure BeforeUpdateInsertRecord(aParentIntegrador, aIntegrador:TDataIntegradorModuloWeb; node: IXMLDomNode; const id: integer; var handled: boolean); virtual;
    function ExecInsertRecord(node: IXMLDomNode; const id: integer; Integrador: TDataIntegradorModuloWeb; pOperacao: String; var _LastId: Integer): Boolean; virtual;
    function getTranslatedTable(const aServerName: string): TDataIntegradorModuloWeb; virtual;
    function getNomeSingular: string; virtual;
    procedure SetNomeSingular(const Value: string); virtual;
    function GetNomePlural: string; virtual;
    function GetVersionIdAtual: Int64; virtual;
    function GetIdRemotoAtual: Integer; virtual;
    procedure setNomePlural(const Value: string); virtual;
    function GetNomePKLocal: string; virtual;
    function GetIdAtual: Integer; virtual;
    procedure setNomePKLocal(const Value: string); virtual;
    procedure setIdAtual(const Value: Integer); virtual;
    procedure SetQueryParameters(qry: TSQLDataSet; DMLOperation: TDMLOperation; node: IXMLDomNode; ChildrenNodes: TXMLNodeDictionary;
      Integrador: TDataIntegradorModuloWeb); virtual;
    function GetDefaultValueForSalvouRetaguarda: Char; virtual;
    function getDefaultSQLStatementForPost(ID: Integer): string; virtual;
    function GetNomeFK: string; virtual;
    procedure setNomeFK(const Value: string); virtual;
    function getHTTP: TIdHTTP;
    function GetFallbackWhere(aNode: IXMLDOMNode; var IdLocal: Integer): string; virtual;
    function getIdLocalByIdRemoto(pTabela, pNomePK: String; pIdRemoto: Integer): Integer; virtual;
    function PodeAtualizar(pTabela: String; pIdRemoto: Integer): Boolean; virtual;
    procedure UpdateHibridoDadosRemotos(pVersionId: Int64; pIdLocal, pIdRemoto: integer; pTabela: String; pOperacao: String; Transaction: TDBXTransaction = nil); virtual;
    procedure UpdateHibridoMetaDadosRemotos(aLastVersionId: Int64; Transaction: TDBXTransaction = nil);
    const
      cNullToServer = '§NULL§';
  public
    translations: TTranslationSet;
    tabelasDetalhe: TTabelaDetalheList;
    verbose: boolean;
    property notifier: ISincronizacaoNotifier read Fnotifier write Fnotifier;
    property threadControl: IThreadControl read FthreadControl write SetthreadControl;
    property CustomParams: ICustomParams read FCustomParams write FCustomParams;
    property dmPrincipal: IDataPrincipal read getdmPrincipal write SetdmPrincipal;
    property stopOnPostRecordError: boolean read FstopOnPostRecordError write FstopOnPostRecordError;
    property stopOnGetRecordError: boolean read FStopOnGetRecordError write FstopOnGetRecordError;
//    property FilaSincronizacaoClientDataSet: TClientDataSet read FStopOnGetRecordError write FstopOnGetRecordError;
    function buildRequestURL(nomeRecurso: string; params: string = ''; httpAction: THttpAction = haGet): string; virtual;
    procedure getDadosAtualizados(var RegistrosEncontrados: Integer); virtual;
    function saveRecordToRemote(ds: TDataSet; var salvou: boolean; http: TidHTTP = nil): IXMLDomDocument2;
    procedure migrateSingletonTableToRemote;
    function postRecordsToRemote(pDataSetFila: TClientDataSet; http: TidHTTP = nil): Boolean; virtual;
    class procedure updateDataSets; virtual;
    procedure afterDadosAtualizados; virtual;
    function getHumanReadableName: string; virtual;
    property DataLog: ILog read FDataLog write SetDataLog;
    constructor Create(AOwner: TComponent; aHTTP: TIdHTTP); virtual;
    destructor Destroy; override;
    function getNomeTabela: string; virtual;
    procedure setNomeTabela(const Value: string); virtual;
    procedure SetRecursividadeAtiva(const Value: Boolean);
    procedure SetTranslateTableNames(aTranslateTableNames: TJsonDictionary);
    property nomeTabela: string read GetNomeTabela write setNomeTabela;
    property NomeSingular: string read getNomeSingular write SetNomeSingular;
    property nomePlural: string read GetNomePlural write setNomePlural;
    property nomePKLocal: string read GetNomePKLocal write setNomePKLocal;
    property IdRemotoAtual: Integer read GetIdRemotoAtual;
    property IdAtual: Integer read GetIdAtual write setIdAtual;
    property VersionIdAtual: Int64 read GetVersionIdAtual;
    property RecursividadeAtiva: Boolean read FRecursividadeAtiva write SetRecursividadeAtiva;
    function getFieldDictionaryList: TFieldDictionaryList;
    function getTabelasDetalhe: TTabelaDetalheList;
    property EncodeJsonValues: boolean read FEncodeJsonValues write FEncodeJsonValues;
    procedure SetStatementForPost(const aStatement: string);
    property nomeFK: string read GetNomeFK write setNomeFK;
    procedure SetOnException(aOnException: TOnExceptionProcedure);
    function getLastStream: TStringStream;
    function UnEscapeValueFromServer(const aValue: string): string;
    property OnException: TOnExceptionProcedure read FOnException write SetOnException;
    function getXMLFromServerByIdRemotoList(const aIdRemotoList: string; aRetornoStream: TStringStream; var aException: string): boolean; virtual;
    function ImportXMLFromServer(aDataIntegradorModuloWeb: TDataIntegradorModuloWeb;
                                  aRetornoStream: TStringStream; var aNumRegistros, aLastId: integer; aUpdateLastVersionId: boolean = True;
                                  aTabelaIgnorar: String = ''; aIdRegistroIgnorar: Integer = 0) : Boolean;
    function getRequestUrlForAction(toSave: boolean; versao: integer = -1): string; virtual;
    function getURL: string; virtual;
    function getDefaultParams: string; virtual;
  end;


  TGeneratorId = class
  private
    FIDHighValue: integer;
    FIDLowValue: integer;
    FdmPrincipal: IDataPrincipal;
    function getdmPrincipal: IDataPrincipal;
    procedure SetdmPrincipal(const Value: IDataPrincipal);
  public
    function getNewId: integer;
    property dmPrincipal: IDataPrincipal read getdmPrincipal write SetdmPrincipal;
  end;

  TTabelaDetalhe = class(TDataIntegradorModuloWeb)
  private
    FnomeParametro: string;
    FGenId: TGeneratorId;
  protected
    function GetNomeParametro: string; virtual;
    procedure setNomeParametro(const Value: string); virtual;
    function getNewId(node: IXMLDomNode): Integer; override;
  public
    constructor Create(AOwner: TComponent; aHTTP: TIdHTTP); override;
    destructor Destroy; override;
    property nomeParametro: string read GetNomeParametro write setNomeParametro;
  end;

var
  DataIntegradorModuloWeb: TDataIntegradorModuloWeb;
implementation

uses AguardeFormUn, ComObj, idCoderMIME, IdGlobal, UtilsUnitAgendadorUn, MSHTML, HibridoConsts;

{$R *.dfm}

function TDataIntegradorModuloWeb.extraGetUrlParams: String;
begin
  result := '';
end;

function TDataIntegradorModuloWeb.getObjectsList: string;
begin
  Result := '/' + dasherize(nomePlural) + '//' + dasherize(FnomeSingular);
end;

procedure TDataIntegradorModuloWeb.getDadosAtualizados(var RegistrosEncontrados: Integer);
var
  url, erro: string;
  numRegistros, LastId: integer;
  keepImporting: boolean;
  vLog: string;
  retornoStream: TStringStream;
  vHTTP: TIdHTTP;
begin
  keepImporting := true;
  while keepImporting do
  begin
    if (not self.shouldContinue) then
      Break;

    url := getRequestUrlForAction(false, getLastVersionIDLocal(nomeTabela)) + extraGetUrlParams;
    if notifier <> nil then
      notifier.setCustomMessage('Buscando ' + getHumanReadableName + '...');
    numRegistros := 0;
    {$IFDEF HibridoClientDLL}
    UtilsUnitAgendadorUn.WritePurpleLog('URL: ' + url);
    {$ENDIF}

    Self.Log(Format('Buscando %s',[getHumanReadableName]));
    Self.Log(url);

    retornoStream := TStringStream.Create('', TEncoding.UTF8);
    try
      vHTTP := Self.getHTTP;
      vHTTP.Request.CustomHeaders.Clear;
      vHTTP.Request.Clear;
      if getRemoteXmlContent(url, vHTTP, erro, retornoStream) then
      begin
        Self.FLastStream.Clear;
        Self.FLastStream.LoadFromStream(retornoStream);

        if (erro <> EmptyStr) then
        begin
          vLog := Format('Erro importando "%s": "%s". '+ #13#10, [getHumanReadableName, GetErrorMessage(erro, self.Gethttp.Response.ContentType)]);
          Self.Log(vLog);
          raise EIntegradorException.Create(vLog);
        end;
        keepImporting := Self.ImportXMLFromServer(Self, retornoStream, numRegistros, LastId);
      end;
    finally
      retornoStream.Free;
    end;
    keepImporting := keepImporting and (maxRecords > 0) and (numRegistros >= maxRecords);
  end;
  afterDadosAtualizados;
  RegistrosEncontrados := numRegistros;
end;

function TDataIntegradorModuloWeb.ImportXMLFromServer(aDataIntegradorModuloWeb:TDataIntegradorModuloWeb;
                                                       aRetornoStream: TStringStream; var aNumRegistros, aLastId: integer; aUpdateLastVersionId: boolean = True;
                                                       aTabelaIgnorar: String = ''; aIdRegistroIgnorar: Integer = 0 ) : Boolean;
var
  doc: IXMLDomDocument2;
  list : IXMLDomNodeList;
  i : integer;
  node : IXMLDomNode;
  LastVersionId: integer;
begin
  Result := True;
  //aTabelaIgnorar e aIdRegistroIgnorar são usados na recursividade, um exame que foi importado e a requisição foi carregada de modo recursivo
  //evita de salvar o exame duas vezes
  if (not (aRetornoStream.DataString.IsEmpty)) and Self.getHTTP.Response.ContentType.Contains('xml') then
  begin
    doc := CoDOMDocument60.Create;
    try
      doc.loadXML(aRetornoStream.DataString);
      list := doc.selectNodes(aDataIntegradorModuloWeb.getObjectsList);
      aNumRegistros := list.length;
      if aDataIntegradorModuloWeb.notifier <> nil then
        aDataIntegradorModuloWeb.notifier.setCustomMessage(IntToStr(aNumRegistros) + ' novos');
      for i := 0 to aNumRegistros-1 do
      begin
        if (not aDataIntegradorModuloWeb.shouldContinue) then
          Break;

        if aDataIntegradorModuloWeb.notifier <> nil then
          aDataIntegradorModuloWeb.notifier.setCustomMessage('Importando ' + aDataIntegradorModuloWeb.getHumanReadableName + ': ' + IntToStr(i+1) +
          '/' + IntToStr(aNumRegistros));
        node := list.item[i];
        if node<>nil then
        begin
          if (aDataIntegradorModuloWeb.nometabela = aTabelaIgnorar) and (StrToInt(node.selectSingleNode('id').text) = aIdRegistroIgnorar) then
            continue;
          if not aDataIntegradorModuloWeb.importRecord(node, aLastId) and aDataIntegradorModuloWeb.StopOnGetRecordError then
          begin
            Result := False;
            Break
          end;

          LastVersionId := -1;
          if node.selectSingleNode(dasherize(aDataIntegradorModuloWeb.getVersionFieldName)) <> nil then
            LastVersionId :=  strToIntDef(node.selectSingleNode(dasherize(aDataIntegradorModuloWeb.getVersionFieldName)).text, -1);

            self.UpdateHibridoMetaDadosRemotos(LastVersionId);
        end;
      end;
    finally
      doc := nil;
    end;
  end;
end;

function TDataIntegradorModuloWeb.GetDefaultValueForSalvouRetaguarda: Char;
begin
  Result := 'S';
end;

procedure TDataIntegradorModuloWeb.UpdateHibridoMetaDadosRemotos(aLastVersionId: Int64; Transaction: TDBXTransaction = nil);
var
  qryVersionId: TSQLDataSet;
  _trans: TDBXTransaction;
begin
  if (getLastVersionIDLocal(Self.nomeTabela) < aLastVersionId) and (UpperCase(Self.nomeTabela) <> 'SOFTDELETE') and (not self.FRecursividadeAtiva) then
  begin
    if Transaction = nil then
      _trans := dmPrincipal.startTransaction
    else
      _trans := Transaction;
    try
      qryVersionId := dmPrincipal.getQuery;
      try
        qryVersionId.CommandText := 'update or insert INTO HIBRIDOMETADADOSREMOTOS ' +
                                    '(TABELA, VERSION_ID, LAST_GET) values (:tabela, :version_id, :lastget) ' +
                                    'matching (TABELA) ';
        qryVersionId.ParamByName('lastget').AsString := FormatDateTime('yyyy-mm-dd hh:nn:ss', now());
        qryVersionId.ParamByName('version_id').AsInteger := aLastVersionId;
        qryVersionId.ParamByName('tabela').AsString := UpperCase(Self.nomeTabela);
        Self.ExecQuery(qryVersionId);
      finally
        qryVersionId.Free;
      end;
        if Transaction = nil then
          dmPrincipal.commit(_trans);
    except
      dmPrincipal.rollBack(_trans);
      raise;
    end;
  end;
end;

procedure TDataIntegradorModuloWeb.UpdateHibridoDadosRemotos(pVersionId: Int64; pIdLocal, pIdRemoto: integer; pTabela: String; pOperacao: String; Transaction: TDBXTransaction = nil);
var
  qry: TSQLDataSet;
  _trans: TDBXTransaction;
  Index: Integer;
begin
  if UpperCase(pTabela) <> 'SOFTDELETE' then
  begin
    if Transaction = nil then
      _trans := dmPrincipal.startTransaction
    else
      _trans := Transaction;
    try
      qry := dmPrincipal.getQuery;
      try
        if pOperacao = opPOST then
        begin
          qry.CommandText := 'update or insert INTO HIBRIDODADOSREMOTOS ' +
                                      '(TABELA, ID, IDREMOTO, VERSION_ID, LAST_PUT) values (:tabela, :ID, :idremoto, :version_id, :lastput) ' +
                                      'matching (TABELA, ID) ';
          qry.ParamByName('lastput').AsString := FormatDateTime('yyyy-mm-dd hh:nn:ss', now());

          Index := FFilaSincronizacaoCDS.FieldByName('IDHIBRIDOFILASINCRONIZACAO').asInteger;
          //Marca o Registro para ser removido da FILA de sincronização (APENAS POST)
          FFilaSincronizacaoCDS.Filter := 'TABELA = ' + QuotedStr(UpperCase(pTabela)) + ' and ID = ' + IntToStr(pIdLocal) + ' AND OPERACAO <> ''D'' ';
          FFilaSincronizacaoCDS.Filtered := True;
          try
            while not FFilaSincronizacaoCDS.Eof do
            begin
              FFilaSincronizacaoCDS.Edit;
              FFilaSincronizacaoCDS.FieldByName('Sincronizado').AsBoolean := True;
              FFilaSincronizacaoCDS.Post;
              FFilaSincronizacaoCDS.Next;
            end;
          finally
            FFilaSincronizacaoCDS.Filtered := False;
            FFilaSincronizacaoCDS.Filter := '';
            FFilaSincronizacaoCDS.Locate('IDHIBRIDOFILASINCRONIZACAO', Index, []);
          end;
        end
        else
        begin
          qry.CommandText := 'update or insert INTO HIBRIDODADOSREMOTOS ' +
                                      '(TABELA, ID, IDREMOTO, VERSION_ID, LAST_GET) values (:tabela, :ID, :idremoto, :version_id, :lastget) ' +
                                      'matching (TABELA, ID) ';
          qry.ParamByName('lastget').AsString := FormatDateTime('yyyy-mm-dd hh:nn:ss', now());
        end;

        qry.ParamByName('version_id').AsInteger := pVersionId;
        qry.ParamByName('ID').AsInteger := pIdLocal;
        qry.ParamByName('idremoto').AsInteger := pIdRemoto;
        qry.ParamByName('tabela').AsString := UpperCase(pTabela);
        Self.ExecQuery(qry);
      finally
        qry.Free;
      end;
        if Transaction = nil then
          dmPrincipal.commit(_trans);
    except
      dmPrincipal.rollBack(_trans);
      raise;
    end;
  end;
end;

function TDataIntegradorModuloWeb.getHTTP: TIdHTTP;
begin
  Result := Self.FHTTP;
end;

function TDataIntegradorModuloWeb.getHumanReadableName: string;
begin
  result := ClassName;
end;

function TDataIntegradorModuloWeb.maxRecords: integer;
begin
  result := 500;
end;

function TDataIntegradorModuloWeb.importRecord(node : IXMLDomNode; var _LastId: Integer): boolean;
var
  id: integer;
  _Trans: TDBXTransaction;
begin
  Result := False;
  if not singleton then
  begin
    id := strToIntDef(node.selectSingleNode(dasherize(nomePKRemoto)).text, -1);
    if id >= 0 then
    begin
      _Trans := dmPrincipal.startTransaction;
      try
        Result := Self.updateInsertRecord(node, id, opGET, _LastId);
        dmPrincipal.commit(_Trans);
      except
        on E:Exception do
        begin
          dmPrincipal.rollBack(_Trans);
          {$IFDEF HibridoClientDLL}
          UtilsUnitAgendadorUn.WriteRedLog(e.Message);
          {$ENDIF}
          Self.log(e.Message);
          //Self.resyncRecord(id);
          raise;
        end;
      end;
    end;
  end
  else
    updateSingletonRecord(node);
end;

procedure TDataIntegradorModuloWeb.resyncRecord(const aId: integer);
var
  qry: TSQLDataSet;
  _Trans: TDBXTransaction;
begin
  qry := DMPrincipal.getQuery;
  try
    if aId > 0 then
    begin
      _trans := dmPrincipal.startTransaction;
      try
        qry.CommandText := 'UPDATE ' + Self.nomeTabela + ' Set SalvouRetaguarda = ''N'' ' + Self.CheckQryCommandTextForDuasVias(aId, Self);
        ExecQuery(qry);
        dmPrincipal.commit(_Trans);
      except
        on E:Exception do
        begin
          dmPrincipal.rollback(_Trans);
        end;
      end;
    end;
  finally
    qry.Free;
  end;
end;

function TDataIntegradorModuloWeb.shouldContinue: boolean;
begin
  Result := true;
  if Self.FThreadControl <> nil then
    result := Self.FThreadControl.getShouldContinue;
end;

function TDataIntegradorModuloWeb.singleton: boolean;
begin
  result := (nomePKLocal = '') and (nomePKRemoto = '');
end;

function TDataIntegradorModuloWeb.jaExiste(aNode:IXMLDOMNode; const id: integer; Integrador: TDataIntegradorModuloWeb; var aCustomWhere: string; var pIdLocal: Integer): Int64;
var
  qry: TSQLDataSet;
begin
  //pegar o Version_id mais recente
  qry := dmPrincipal.getQuery;
  try
    qry.CommandText := 'SELECT Version_Id, ID FROM HIBRIDODADOSREMOTOS WHERE TABELA = ' + QuotedStr(UpperCase(Integrador.nomeTabela)) + ' and IDREMOTO = ' + IntToStr(id);
    qry.Open;
    result := qry.FieldByName('Version_Id').AslargeInt;
    if (Result <= 0) then
    begin
      //fallback
      aCustomWhere := Integrador.GetFallbackWhere(aNode, pIdLocal);
    end
    else
      pIdLocal := qry.FieldByName('ID').AsInteger;
  finally
    FreeAndNil(qry);
  end;
end;

function TDataIntegradorModuloWeb.getUpdateStatement(node: IXMLDomNode; const id: integer): String;
begin
  Result := getUpdateBaseSQL(node, Self) + Self.CheckQryCommandTextForDuasVias(Id, Self);
end;

function TDataIntegradorModuloWeb.getURL: string;
begin
  Result := EmptyStr;
  if (Self.CustomParams <> nil) and Self.CustomParams.getCustomParams.ContainsKey(cEnderecoHibrido) then
    Result := acStrUtils.EnsureTrailingSlash(Self.CustomParams.getCustomParams.Items[cEnderecoHibrido]);
end;

function TDataIntegradorModuloWeb.getInsertStatement(node: IXMLDomNode): String;
begin
  Result := 'INSERT INTO ' + nomeTabela + getFieldList(node) + ' values ' + getFieldValues(node, Self);
end;

procedure TDataIntegradorModuloWeb.BeforeUpdateInsertRecord(aParentIntegrador, aIntegrador:TDataIntegradorModuloWeb; node: IXMLDomNode; const id: integer; var handled: boolean);
begin
  handled := False;
end;

function TDataIntegradorModuloWeb.getTranslatedTable(const aServerName: string): TDataIntegradorModuloWeb;
var
  Detalhe : TDataIntegradorModuloWeb;
begin
  Result := nil;

  for Detalhe in tabelasDetalhe do
    if AnsiSameText(underscorize(aServerName), Detalhe.nomePlural) then
    begin
      Result := Detalhe;
      break;
    end;
end;

procedure TDataIntegradorModuloWeb.SetOnException(aOnException: TOnExceptionProcedure);
begin
  FOnException := aOnException;
end;

function TDataIntegradorModuloWeb.UnEscapeValueFromServer(const aValue: string): string;
begin
  Result := aValue;
  Result := StringReplace(Result, '\\', '\', [rfReplaceAll]);
  Result := StringReplace(Result, '\"', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '\n', #13#10, [rfReplaceAll]);
  Result := StringReplace(Result, '\t', #9, [rfReplaceAll]);
end;

procedure TDataIntegradorModuloWeb.SetQueryParameters(qry: TSQLDataSet; DMLOperation: TDMLOperation; node: IXMLDomNode;  ChildrenNodes: TXMLNodeDictionary;  Integrador: TDataIntegradorModuloWeb);
var
  i: integer;
  ValorCampo: UTF8String;
  Field: TFieldDictionary;
  lFormatSettings: TFormatSettings;
begin
  //Preenche os Parametros
  for i := 0 to node.childNodes.length - 1 do
  begin
    if (node.childNodes[i].attributes.getNamedItem('type') <> nil) and (node.childNodes[i].attributes.getNamedItem('type').text = 'array') then
    begin
      if (ChildrenNodes <> nil) and (not ChildrenNodes.ContainsKey(node.childNodes[i].nodeName)) then
        ChildrenNodes.Add(node.childNodes[i].nodeName, node.childNodes[i]);
    end;

    name := LowerCase(translateFieldNameServerToPdv(node.childNodes.item[i], Integrador));
    ValorCampo := translateFieldValue(node.childNodes.item[i], Integrador);
    if name <> '*' then
    begin
      if Self.getIncludeFieldNameOnList(DMLOperation, name, Integrador) then
      begin
        if ValorCampo = 'NULL' then
        begin
          qry.ParamByName(name).Value := unassigned;
          qry.ParamByName(name).DataType := ftString;
        end
        else
        begin
          Field := nil;
          if (Integrador.FFieldList <> nil) and (Lowercase(name) <> 'idremoto') and (Lowercase(name) <> 'version_id') then
            Field := Integrador.FFieldList.Items[Lowercase(name)];
          if Field <> nil then
          begin
            case Field.DataType of
              ftString, ftMemo: qry.ParamByName(name).AsString := Self.UnEscapeValueFromServer(ValorCampo);
              ftInteger: qry.ParamByName(name).AsInteger := StrToInt(ValorCampo);
              ftLargeint: qry.ParamByName(name).AsLargeInt := StrToInt(ValorCampo);
              ftDateTime, ftTimeStamp:
                begin
                  ValorCampo := StringReplace(ValorCampo, '''','', [rfReplaceAll]);
                  ValorCampo := Trim(StringReplace(ValorCampo, '.','/', [rfReplaceAll]));
                  lFormatSettings.DateSeparator := '/';
                  lFormatSettings.TimeSeparator := ':';
                  lFormatSettings.ShortDateFormat := 'dd/MM/yyyy hh:mm:ss';
                  qry.ParamByName(name).AsDateTime := StrToDateTime(ValorCampo, lFormatSettings);
                end;
              ftCurrency, ftTime:
                begin
                  ValorCampo := StringReplace(ValorCampo, '''','', [rfReplaceAll]);
                  qry.ParamByName(name).AsCurrency := StrToCurr(ValorCampo);
                end;
              ftSingle, ftFloat, ftFMTBcd:
              begin
                ValorCampo := StringReplace(ValorCampo, '.', ',',[rfReplaceAll]);
                ValorCampo := StringReplace(ValorCampo, '''','', [rfReplaceAll]);
                qry.ParamByName(name).AsFloat := StrToFloat(ValorCampo);
              end;
              ftBlob:
              begin
                qry.ParamByName(name).LoadFromStream(self.BinaryFromBase64(ValorCampo), ftBlob);
              end
            else
              qry.ParamByName(name).AsString := Self.UnEscapeValueFromServer(ValorCampo);
            end;
          end;
        end;
      end;
    end;
  end;
  //Ultimo Campo é o ControleHibrido
  qry.ParamByName('CONTROLEHIBRIDO').AsString := 'S';
end;

procedure TDataIntegradorModuloWeb.ExecQuery(aQry: TSQLDataSet);
var
  i: integer;
  Paramlog, vLog: string;
begin
  try
    aQry.ExecSQL;
  except
    on E:Exception do
    begin
      ParamLog := EmptyStr;
      for i := 0 to aQry.Params.Count - 1 do
        ParamLog := ParamLog + aQry.Params[i].Name + ' = "' + aQry.Params[i].AsString + '"' + #13#10;
      vLog := 'Erro ExecSQL: ' + #13#10 + aQry.CommandText + #13#10 + ParamLog + #13#10 + e.Message;
      Raise EIntegradorException.Create(vLog);
    end;
  end;
end;

function TDataIntegradorModuloWeb.CheckQryCommandTextForDuasVias(const aId: integer; Integrador: TDataIntegradorModuloWeb): string;
var
  vIdLocal: Integer;
begin
  vIdLocal := self.getIdLocalByIdRemoto(UpperCase(Integrador.NomeTabela), Integrador.nomePKLocal, aId);
  Result := ' WHERE ' + UpperCase(Integrador.NomeTabela) + '.' + Integrador.nomePKLocal + ' = ' +  IntToStr(vIdLocal) +
  ' and exists(select 1 from HIBRIDODADOSREMOTOS ' + ' where tabela = ' + QuotedStr(UpperCase(Integrador.nomeTabela)) + ' and id = ' + IntToStr(vIdLocal) +
  ' and version_id <> ' + IntToStr(FVersionIdAtual) + ')';
end;

function TDataIntegradorModuloWeb.ExecInsertRecord(node: IXMLDomNode; const id: integer; Integrador: TDataIntegradorModuloWeb; pOperacao: String; var _LastId: Integer) : Boolean;
var
  i: integer;
  name: string;
  qry: TSQLDataSet;
  FieldsListUpdate, FieldsListInsert : string;
  NewId: integer;
  ChildrenNodes: TXMLNodeDictionary;
  ChildNode: TPair<string, IXMLDomNode>;
  ChildId: integer;
  handled : boolean;
  list : IXMLDomNodeList;
  numRegistros: integer;
  nodeItem : IXMLDomNode;
  Detail: TDataIntegradorModuloWeb;
  DMLOperation: TDMLOperation;
  StrCheckInsert: TStringList;
  _CustomWhere: string;
  _WhereInUpdate: String;
  Version_ID_From_Server: Int64;
  vIdLocal: Integer;
  _Trans: TDBXTransaction;
  _LastIdFilho: Integer;
begin
  Result := False;
  NewId := 0;
  _CustomWhere := EmptyStr;
  _WhereInUpdate := EmptyStr;
  qry := dmPrincipal.getQuery;
  ChildrenNodes := TXMLNodeDictionary.Create;
  FVersionIdAtual := StrToInt64(node.selectSingleNode('version-id').text);
  FIdRemotoAtual := id;
  try
    if (jaExiste(node, id, Integrador, _CustomWhere, vIdLocal) > 0) or (not _CustomWhere.IsEmpty) or (pOperacao = opPOST) then
    begin
      if (pOperacao = opGET) and (not self.PodeAtualizar(Integrador.nomeTabela, id)) then
      begin
        Result := False;
        exit;
      end;

      DMLOperation := dmUpdate;
      FieldsListUpdate := Self.getFieldUpdateList(node, Integrador);

      qry.CommandText := 'UPDATE ' + Integrador.nomeTabela + ' SET ' + FieldsListUpdate;
      if (not _CustomWhere.IsEmpty) then
        _WhereInUpdate := _CustomWhere
      else
        _WhereInUpdate := CheckQryCommandTextForDuasVias(Id, Integrador);

      qry.CommandText := qry.CommandText + _WhereInUpdate;

    end
    else
    begin
      DMLOperation := dmInsert;
      FieldsListInsert := self.getFieldInsertList(node, Integrador);
      NewId := Integrador.getNewId(Node);
      if NewId > 0 then
      begin
        vIdLocal := NewId;
        StrCheckInsert := TStringList.Create;
        try
          StrCheckInsert.Delimiter := ':';
          StrCheckInsert.DelimitedText := FieldsListInsert;
          if (StrCheckInsert.IndexOf(Integrador.nomePKLocal+',') < 0) and
            (StrCheckInsert.IndexOf(Integrador.nomePKLocal) < 0) then
            FieldsListInsert := ':'+ Integrador.nomePKLocal + ',' + FieldsListInsert;
        finally
          StrCheckInsert.Free;
        end;
      end;
      qry.CommandText := 'INSERT INTO ' + Integrador.nomeTabela + '(' + StringReplace(FieldsListInsert, ':', '', [rfReplaceAll]) + ') values (' + FieldsListInsert + ')';
      if qry.Params.ParamByName(Integrador.nomePkLocal) <> nil then
        qry.ParamByName(Integrador.nomePkLocal).AsInteger := NewId;
    end;

    Self.SetQueryParameters(qry, DMLOperation, node, ChildrenNodes, Integrador);
    _trans := dmPrincipal.startTransaction;
    try
      Self.ExecQuery(qry);
      _LastId := vIdLocal;

      //Quando o XML possui registos filhos, só deve fazer esse update quando estiver passando pela tabela principal
      if (pOperacao = opGET) and (self.nometabela = Integrador.nomeTabela) then
        Self.UpdateHibridoMetaDadosRemotos(Self.GetVersionIdAtual, _trans);

      Self.UpdateHibridoDadosRemotos(Self.GetVersionIdAtual, vIdLocal, id, Integrador.nomeTabela, pOperacao, _trans);
      dmPrincipal.commit(_trans);
       Result := True;
    except
      on E: Exception do
      begin
        dmPrincipal.rollback(_trans);
        if assigned(Self.FOnException) then
          Self.FOnException(haGet, Integrador, E.ClassName, E.Message, Id);//onde Id = RemoteId
        raise;
      end;
    end;

    for ChildNode in ChildrenNodes do
    begin
      Detail := Self.getTranslatedTable(ChildNode.Key);
      if Detail <> nil then
      begin
        list := ChildNode.Value.selectNodes(dasherize(Detail.fnomeSingular));
        if list <> nil then
        begin
          numRegistros := list.length;
          for i := 0 to numRegistros-1 do
          begin
            nodeItem := list.item[i];
            ChildId := 0;
            if nodeItem.selectSingleNode('./id') <> nil then
              ChildId := StrToIntDef(nodeItem.selectSingleNode('./id').text, 0);
            handled := False;
            Self.BeforeUpdateInsertRecord(Self, Detail, nodeItem, ChildId, handled);
            if not handled then
            begin
              Result := Self.ExecInsertRecord(nodeItem, ChildId, Detail, pOperacao, _LastIdFilho);
              if not Result then
                exit;
            end;
          end;
        end;
      end;
    end;

  finally
    FreeAndNil(qry);
    FreeAndNil(ChildrenNodes);
  end;
end;

function TDataIntegradorModuloWeb.GetVersionIdFromServer(pIdRemoto: Integer; pNomeTabela: String) : Int64;
var
  http: TidHTTP;
begin
  http := getHTTPInstance;
  http.OnWork := Self.OnWorkHandler;
  http.ConnectTimeout := Self.getTimeoutValue;
  http.ReadTimeout := Self.getTimeoutValue;
  try
    Result := StrToInt64Def(http.Get(self.getURL + 'get_my_last_post_version_ids' + '/' + IntToStr(pIdRemoto) + '?' + self.getDefaultParams + '&model_class='+pNomeTabela),0);
  finally
    FreeAndNil(http);
  end;
end;

function TDataIntegradorModuloWeb.updateInsertRecord(node: IXMLDomNode; const id: integer; pOperacao: String; var _LastId: Integer) : Boolean;
var
  handled : boolean;
begin
  handled := False;
  Result := True;
  Self.BeforeUpdateInsertRecord(nil, Self, node, id, handled);
  if not handled then
    Result := Self.ExecInsertRecord(node, id, Self, pOperacao, _LastId);
end;

procedure TDataIntegradorModuloWeb.updateSingletonRecord(node: IXMLDOMNode);
begin
  if dmPrincipal.getSQLIntegerResult('SELECT count(1) from ' + nomeTabela) < 1 then
    dmPrincipal.execSQL('Insert into ' + nomeTabela + ' DEFAULT VALUES');
  dmPrincipal.execSQL(getUpdateBaseSQL(node, Self));
end;

function TDataIntegradorModuloWeb.getUpdateBaseSQL(node: IXMLDOMNode; Integrador: TDataIntegradorModuloWeb): string;
begin
  result := 'UPDATE ' + Integrador.nomeTabela + getFieldUpdateList(node, Integrador);
end;

function TDataIntegradorModuloWeb.getFieldList(node: IXMLDomNode): string;
var
  i: integer;
  name: string;
begin
  result := '(';
  if duasVias and ((nomeGenerator <> '') or (usePKLocalMethod)) then
    result := result + nomePKLocal + ', ';
  if duasVias then
    result := result + 'salvouRetaguarda, ';
  for i := 0 to node.childNodes.length - 1 do
  begin
    name := translateFieldNameServerToPdv(node.childNodes.item[i], Self);
    if name <> '*' then
      if Self.getIncludeFieldNameOnList(dmInsert, name, Self) then
        result := result + name + ', ';
  end;
  result := copy(result, 0, length(result)-2);
  result := result + getFieldAdditionalList(node);
  result := result + ')';
end;

function TDataIntegradorModuloWeb.getFieldValues(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
var
  i: integer;
  name: string;
begin
  result := '(';
  if duasVias and ((nomeGenerator <> '') or (usePKLocalMethod)) then
  begin
    if nomeGenerator <> '' then
      result := result + 'gen_id(' + nomeGenerator + ',1), '
    else
      Result := Result + IntToStr(getNewId(Node)) + ', ';
  end;
  if duasVias then
    result := result + QuotedStr('S') + ', ';
  for i := 0 to node.childNodes.length - 1 do
  begin
    name := translateFieldNameServerToPdv(node.childNodes.item[i], Integrador);
    if name <> '*' then
      if Self.getIncludeFieldNameOnList(dmInsert, name, Integrador) then
        result := result + translateFieldValue(node.childNodes.item[i], Integrador) + ', ';
  end;
  result := copy(result, 0, length(result)-2);
  result := result + getFieldAdditionalValues(node);
  result := result + ')';
end;

function TDataIntegradorModuloWeb.getFieldUpdateList(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
var
  i: integer;
  name: string;
begin
  result := '';
  for i := 0 to node.childNodes.length - 1 do
  begin
    name := translateFieldNameServerToPdv(node.childNodes.item[i], Integrador);
    if (name <> '*') and (LowerCase(name) <> 'idremoto') and (LowerCase(name) <> 'version_id') then
      if Self.getIncludeFieldNameOnList(dmUpdate, name, Integrador) then
        result := result + ' ' + name + ' = :' + name + ',';
  end;
  result := result + ' ' + 'CONTROLEHIBRIDO = :CONTROLEHIBRIDO';
  //Remove a ultima virgula
//  result := copy(result, 1, Length(result)-1);
  result := result + getFieldAdditionalUpdateList(node);
end;

function TDataIntegradorModuloWeb.getFieldInsertList(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
var
  i: integer;
  name: string;
  StrInsert: TStringList;
begin
  Result := '';
  StrInsert := TStringList.Create;
  try
    for i := 0 to node.childNodes.length - 1 do
    begin
      name := LowerCase(translateFieldNameServerToPdv(node.childNodes.item[i], Integrador));
      if (name <> '*') and (LowerCase(name) <> 'idremoto') and (LowerCase(name) <> 'version_id') then
        if Self.getIncludeFieldNameOnList(dmInsert, name, Integrador) and (StrInsert.IndexOf(name) < 0) then
        begin
          StrInsert.Add(name);
          Result := Result + ' :' + name + ',';
        end;
    end;
    Result := Result + ' ' + ' :CONTROLEHIBRIDO';
  //  Result := copy(Result, 1, Length(Result)-1);
  finally
    StrInsert.Free;
  end;
end;

function TDataIntegradorModuloWeb.getFieldDictionaryList: TFieldDictionaryList;
begin
  Result := FFieldList;
end;

function TDataIntegradorModuloWeb.getIncludeFieldNameOnList(const aDMLOperation: TDMLOperation; const aFieldName: string; Integrador: TDataIntegradorModuloWeb): boolean;
begin
  Result := True;
end;

function TDataIntegradorModuloWeb.getRequestUrlForAction(toSave: boolean; versao: integer = -1): string;
var
  nomeRecurso: string;
begin
  if toSave then
  begin
    nomeRecurso := nomeActionSave;
    Result := buildRequestURL(nomeRecurso, '', haPost);
  end
  else
  begin
    nomeRecurso := nomeActionGet;
    Result := buildRequestURL(nomeRecurso);
  end;

  if versao > -1 then
    result := result + '&version=' + IntToStr(versao);
  if nomeRecurso = 'soft_deletes' then
    result := result + '&table_name='+FFilaSincronizacaoCDS.fieldbyname('TABELA').asstring;
end;

function TDataIntegradorModuloWeb.getVersionFieldName: string;
begin
  Result := 'versao';
end;

function TDataIntegradorModuloWeb.translateFieldValue(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
var
  typedTranslate: string;
begin
  if (node.attributes.getNamedItem('nil') <> nil) and (node.attributes.getNamedItem('nil').text = 'true') then
    result := 'NULL'
  else if (node.attributes.getNamedItem('type') <> nil) then
  begin
    typedTranslate := translateTypeValue(node.attributes.getNamedItem('type').text, node.text);
    result := translateValueFromServer(node.nodeName, typedTranslate, Integrador);
  end
  else
    result := translateValueFromServer(node.nodeName, node.text, Integrador);
end;

function TDataIntegradorModuloWeb.translateTypeValue(fieldType, fieldValue: string): string;
begin
  result := QuotedStr(fieldValue);
  if (fieldType = 'integer') or (fieldType = 'float') then
    result := fieldValue
  else if fieldType = 'boolean' then
  begin
    if fieldValue = 'true' then
      result := '1'
    else
      result := '0';
  end;
end;

function TDataIntegradorModuloWeb.translateFieldNameServerToPdv(node: IXMLDomNode; Integrador: TDataIntegradorModuloWeb): string;
begin
  result := Integrador.translations.translateServerToPDV(node.nodeName, duasVias);
  if result = '' then
    result := StringReplace(node.nodeName, '-', '', [rfReplaceAll]);
end;

function TDataIntegradorModuloWeb.translateFieldNamePdvToServer(
  node: IXMLDomNode): string;
begin
  result := translations.translatepdvToServer(node.nodeName);
  if result = '' then
    result := StringReplace(node.nodeName, '-', '', [rfReplaceAll]);
end;


function TDataIntegradorModuloWeb.addTranslatedParams(ds: TDataSet; params: TStringList;
  translations: TTranslationSet; nestedAttribute: string = ''): IXMLDomDocument2;
var
  i: integer;
  nestingText, nomeCampo, nome, valor: string;
begin
  nestingText := '';
  if nestedAttribute <> '' then
    nestingText := '[' + nestedAttribute + '][]';
  for i := 0 to translations.size-1 do
  begin
    nomeCampo := translations.get(i).pdv;
    if ds.FindField(nomeCampo) <> nil then
    begin
      nome := nomeSingularSave + nestingText + '[' + translations.get(i).server + ']';
      valor := translateValueToServer(translations.get(i), translations.get(i).pdv,
          ds.fieldByName(translations.get(i).pdv), nestedAttribute, translations.get(i).fkName);
      params.Add(nome + '=' + valor);
    end;
  end;
end;

procedure TDataIntegradorModuloWeb.afterDadosAtualizados;
begin
  //
end;

function TDataIntegradorModuloWeb.getTabelasDetalhe: TTabelaDetalheList;
begin
  Result := Self.tabelasDetalhe;
end;

function TDataIntegradorModuloWeb.getTimeoutValue: integer;
begin
  Result := 30000;
end;

procedure TDataIntegradorModuloWeb.OnWorkHandler(ASender: TObject; AWorkMode: TWorkMode;
  AWorkCount: Int64);
begin
  if (Self.FthreadControl <> nil) and (not Self.FthreadControl.getShouldContinue) then
    Abort;
end;

procedure TDataIntegradorModuloWeb.addDetailsToJsonList(aDetailList: TDetailList; aDs: TDataSet);
var
  Detalhe: TTabelaDetalhe;
begin
  for Detalhe in  Self.tabelasDetalhe do
    Self.SelectDetails(aDetailList, aDs.fieldByName(nomePKLocal).AsInteger, Detalhe);
end;

procedure TDataIntegradorModuloWeb.SelectDetailsIterate(aDetailList: TDetailList; aValorPK: integer);
var
  Detalhe: TTabelaDetalhe;
begin
  for  Detalhe in Self.tabelasDetalhe do
  begin
    SelectDetails(aDetailList, aValorPK, Detalhe);
  end;
end;

procedure TDataIntegradorModuloWeb.SelectDetails(aDetailList: TDetailList; aValorPK: integer; aTabelaDetalhe: TTabelaDetalhe);
var
  jsonArrayDetails: TJSONArrayContainer;
begin
  RunDataSet(aValorPk, aTabelaDetalhe,
             procedure (aDataSet: TDataSet)
             var
               nomeParametro: string;
               Dict: TStringDictionary;
             begin
               if (aDetailList <> nil) and (not aDetailList.ContainsKey(aTabelaDetalhe.nomeParametro)) then
               begin
                 jsonArrayDetails := TJSONArrayContainer.Create;
                 jsonArrayDetails.nomePluralDetalhe := aTabelaDetalhe.nomePlural;
                 jsonArrayDetails.nomeSingularDetalhe := aTabelaDetalhe.FnomeSingular;
                 jsonArrayDetails.nomeTabela := aTabelaDetalhe.nomeTabela;
                 jsonArrayDetails.nomePkLocal := aTabelaDetalhe.nomePKLocal;
                 nomeParametro := aTabelaDetalhe.nomeParametro;
                 aDetailList.Add(nomeParametro, jsonArrayDetails);
               end
               else
                 jsonArrayDetails := aDetailList.Items[aTabelaDetalhe.nomeParametro];
               Dict := Self.DataSetToArray(aDataSet);
               try
                 jsonArrayDetails.getJsonArray.AddElement(Self.getJsonObject(aDataSet, aTabelaDetalhe.translations, Dict, aTabelaDetalhe.nomeParametro));
                 aTabelaDetalhe.SelectDetailsIterate(aDetailList, aDataSet.fieldByName(aTabelaDetalhe.nomePKLocal).AsInteger);
               finally
                 Dict.Free;
               end;
            end);
end;


procedure TDataIntegradorModuloWeb.RunDataSet(const aValorPK: integer; aTabelaDetalhe: TTabelaDetalhe; aProc: TAnonymousMethod);
var
  qry: TSQLDataSet;
begin
  qry := dmPrincipal.getQuery;
  try
    try
      qry.commandText := 'SELECT ' + aTabelaDetalhe.nomeTabela + '.*,' + 'hdr.idremoto, hdr.version_id FROM ' + aTabelaDetalhe.nomeTabela +
      ' left join hibridodadosremotos hdr on hdr.tabela = ' + QuotedStr(UpperCase(aTabelaDetalhe.nomeTabela)) + ' and hdr.id = ' + aTabelaDetalhe.nomeTabela + '.' + aTabelaDetalhe.nomePKLocal +
      ' where ' + aTabelaDetalhe.nomeFK +
        ' = ' + IntToStr(aValorPK) + self.getAdditionalDetailFilter;
      qry.Open;
      while not qry.Eof do
      begin
        //Deve enviar o registro filho apenas se ele estiver na fila.
        if self.ValidaRegistroFila(aTabelaDetalhe.nomeTabela, qry.FieldByName(aTabelaDetalhe.nomePKLocal).AsInteger) then
          aProc(qry);
        qry.Next;
      end;
    except
       on E: Exception do
       begin
         Self.FDataLog.log('Erro no SQL:' + #13#10 + qry.CommandText);
         raise;
       end;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

function TDataIntegradorModuloWeb.ValidaRegistroFila(pTabela: String; pPkLocal: Integer) : Boolean;
var
  qry: TSQLDataSet;
begin
  //Verifica se o registro esta na fila, dessa forma pode ser feito o POST dos detalhes, caso não haja um registro filho na fila, apenas o pai deve ser sincronizado
  qry := dmPrincipal.getQuery;
  try
    qry.CommandText := 'select * from HIBRIDOFILASINCRONIZACAO WHERE TABELA = :TABELA AND ID = :ID';
    qry.ParamByName('TABELA').AsString := UpperCase(Trim(pTabela));
    qry.ParamByName('ID').AsInteger := pPkLocal;
    qry.Open;
    Result := not qry.IsEmpty;
  finally
    FreeAndNil(qry);
  end;
end;

function TDataIntegradorModuloWeb.JsonObjectHasPair(const aName: string; aJson: TJSONObject): boolean;
var
  jsonPair: TJSONPair;
begin
  Result := False;
  for jsonPair in aJson do
  begin
    if JsonPair.JsonString.Value = aName then
    begin
      Result := True;
      break;
    end;
  end;
end;

function TDataIntegradorModuloWeb.DataSetToArray(aDs: TDataSet) : TStringDictionary;
var
  i: Integer;
  nome: String;
  value: String;
  fieldValue: string;
  BlobStream: TStringStream;
  FieldStream: TStream;
  Input: TMemoryStream;
begin
  Result := TStringDictionary.Create;
  for I := 0 to aDs.FieldCount - 1 do
  begin
    nome := aDs.Fields[i].FieldName;
    try
      if VarIsNull(aDs.Fields[i].AsVariant) then
        fieldValue := ''
      else
        fieldValue := aDs.Fields[i].AsVariant;
    except
      fieldValue := aDs.Fields[i].AsString;
    end;

    if (aDs.Fields[i].IsNull) or (fieldValue = '') then
      value := ''
    else if aDS.Fields[i].DataType = ftDate then
      Value := aDS.Fields[i].AsString
    else if aDs.Fields[i].DataType = ftBlob then
    begin
      try
        FieldStream := aDs.CreateBlobStream(aDs.Fields[i], bmRead);
        Input := TBytesStream.Create;
        try
          Input.LoadFromStream(FieldStream);
          Input.Position := 0;
          Value := TIdEncoderMIME.EncodeStream(Input);
        finally
          FreeAndNil(Input);
        end;
      Finally
        FreeAndNil(FieldStream);
      end;
    end
    else
      value := fieldValue;
    Result.Add(nome, value)
  end;
end;

function TDataIntegradorModuloWeb.EscapeValueToServer(const aValue: string): string;
begin
  Result := aValue;
  Result := StringReplace(Result, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, '"', '\"', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

function TDataIntegradorModuloWeb.getJsonObject(aDs: TDataSet;
 aTranslations: TTranslationSet; aDict: TStringDictionary; aNestedAttribute: string = ''): TJsonObject;
var
  i: integer;
  nomeCampo, nome, valor, fieldValue: string;
  StringUTF8: UTF8String;
begin
  Result := TJsonObject.Create;
  Result.Owned := False; // Manter como False
  FIdRemotoEncontrado := True;
  for i := 0 to aTranslations.size-1 do
  begin
    nomeCampo := aTranslations.get(i).pdv;
    if aDict.ContainsKey(UpperCase(nomeCampo)) then
    begin
      nome := aTranslations.get(i).server;
      fieldValue := aDict.Items[UpperCase(aTranslations.get(i).pdv)];

      valor := translateValueToServer(aTranslations.get(i), aTranslations.get(i).pdv,
          aDs.fieldByName(aTranslations.get(i).pdv), aNestedAttribute, aTranslations.get(i).fkName, fieldValue);
      if not JsonObjectHasPair(nome, Result) then
      begin
        StringUTF8 := Self.EscapeValueToServer(valor);
        if Self.encodeJsonValues then
        begin
          if aDs.fieldByName(aTranslations.get(i).pdv).DataType = ftblob then
            Result.AddPair(nome, valor)
          else if StringUTF8 = '' then
            Result.AddPair(nome, TIdEncoderMIME.EncodeString(cNullToServer, IndyTextEncoding_UTF8))   //Força o envio de null para campos vazios
          else
            Result.AddPair(nome, TIdEncoderMIME.EncodeString(StringUTF8, IndyTextEncoding_UTF8))
        end
        else
          Result.AddPair(nome, valor);
      end;
    end;
    if UpperCase(NomeCampo) = UpperCase(GetNomePKLocal) then
    begin
      //Adiciona o Version_ID ao JSON
      setVersionIdToJSON(Result, getNomeTabela, valor);
    end;
  end;
end;

procedure TDataIntegradorModuloWeb.setVersionIdToJSON(pJSON: TJsonObject; pTabela, pId: String);
var
  qry: TSQLDataSet;
  salvou: boolean;
begin
  qry := dmPrincipal.getQuery;
  qry.CommandText := 'select version_id, IdRemoto from HibridoDadosRemotos where tabela = :tabela and ID = :ID';
  qry.ParamByName('tabela').AsString := pTabela;
  qry.ParamByName('ID').AsString := pId;
  qry.Open;

  if not qry.IsEmpty then
  begin
    pJSON.AddPair('version_id', TIdEncoderMIME.EncodeString(qry.FieldByName('version_id').AsString, IndyTextEncoding_UTF8));
    pJSON.AddPair('id', TIdEncoderMIME.EncodeString(qry.FieldByName('IdRemoto').AsString, IndyTextEncoding_UTF8));
  end;
end;

function TDataIntegradorModuloWeb.getLastStream: TStringStream;
begin
  Result := FLastStream;
end;

function TDataIntegradorModuloWeb.getNewId(node: IXMLDomNode): Integer;
begin
  Result := 0;
end;

function TDataIntegradorModuloWeb.GetNomeFK: string;
begin
  Result := FnomeFK;
end;

procedure TDataIntegradorModuloWeb.setNomeFK(const Value: string);
begin
  FnomeFK := Value;
end;

function TDataIntegradorModuloWeb.GetNomePKLocal: string;
begin
  Result := Self.FnomePKLocal
end;

function TDataIntegradorModuloWeb.GetIdAtual: Integer;
begin
  Result := Self.FIdAtual
end;

function TDataIntegradorModuloWeb.getIdLocalByIdRemoto(pTabela, pNomePK: String; pIdRemoto: Integer): Integer;
begin
  Result := 0;
end;

function TDataIntegradorModuloWeb.GetIdRemotoAtual: Integer;
begin
  Result := Self.FIdRemotoAtual
end;

function TDataIntegradorModuloWeb.GetVersionIdAtual: Int64;
begin
  Result := Self.FVersionIdAtual
end;

function TDataIntegradorModuloWeb.GetNomePlural: string;
begin
  Result := Self.FNomePlural
end;

function TDataIntegradorModuloWeb.getNomeSingular: string;
begin
  Result := Self.FnomeSingular
end;

function TDataIntegradorModuloWeb.getNomeTabela: string;
begin
  Result := Self.FNomeTabela
end;

procedure TDataIntegradorModuloWeb.addMasterTableToJson(aDetailList: TDetailList; aDs: TDataSet; apStream: TStringStream);
var
  JMaster, JResponse: TJsonObject;
  Item: TPair<string, TJSONArrayContainer>;
  Dict: TStringDictionary;
begin
  Dict := Self.DataSetToArray(aDs);
  try
    JMaster := Self.getJsonObject(aDs, Self.translations, Dict);
    JResponse := TJSONObject.Create;
    try
      jResponse.AddPair(Self.nomeSingularSave, JMaster);
      for Item in aDetailList do
      begin
        JMaster.Owned := True;
        JMaster.AddPair(item.Key, Item.Value.getJsonArray);
        Item.Value.FJSonArray.Free;
        Item.Value.Free;
      end;
      apStream.WriteString(JResponse.ToString);

    finally
      JResponse.Free;
      JMaster.Free;
    end;
  finally
    Dict.Clear;
    Dict.Free;
  end;
end;

function TDataIntegradorModuloWeb.PodeAtualizar(pTabela: String; pIdRemoto: Integer): Boolean;
begin
  Result := True;
end;

function TDataIntegradorModuloWeb.Post(ds: TDataSet; http: TidHTTP; url: string; pTrans: TDBXTransaction): string;
var
  params: TStringList;
  pStream: TStringStream;
  DetailList: TDetailList;
  Content: IXMLDomDocument2;
  ResponseContent: TStringStream;
  IdRemoto : integer;
begin
  result := '';
  pStream := TStringStream.Create('', TEncoding.UTF8);
  DetailList := TDetailList.Create;
  ResponseContent := TStringStream.Create('', TEncoding.UTF8);
  try
    Self.addDetailsToJsonList(DetailList, ds);
    Self.addMasterTableToJson(DetailList, ds, pStream);

    if ds.FieldByName('IDREMOTO').AsInteger > 0 then
    begin
      url := StringReplace(url, '?', '/' + ds.FieldByName('IDREMOTO').AsString + '?', []);
      http.Put(url, pStream, ResponseContent)
    end
    else
      http.Post(url, pStream, ResponseContent);

    result := ResponseContent.DataString;
    Self.FLastStream.LoadFromStream(pStream);
    Content := Self.getXMLContentAsXMLDom(result);
    if Content <> nil then
      IdRemoto := Self.GetIdRemoto(Content);
    self.UpdateHibridoDadosRemotos(self.GetVersionId(Content), ds.fieldByName(nomePKLocal).AsInteger, IdRemoto, self.nomeTabela, opPOST, pTrans);
  finally
    pStream.Free;
    DetailList.Free;
    FreeAndNil(ResponseContent);
  end;
end;

function TDataIntegradorModuloWeb.GetIdRemoto(aDoc: IXMLDomDocument2): integer;
begin
  Result := -1;
  try
    if aDoc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//id') <> nil then
      Result := strToInt(aDoc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//id').text)
    else if aDoc.selectSingleNode('//hash//id') <> nil then
      Result := strToInt(aDoc.selectSingleNode('//hash//id').text)
    else
      Result := StrToInt(aDoc.selectSingleNode('objects').selectSingleNode('object').selectSingleNode('id').text);
  except
    on e: Exception do
    begin
      Self.log('Erro ao ler Campo "ID" no XML de retorno, Tabela: ' + nomeTabela + ' - ' + e.Message, 'Sync');
    end;
  end;
end;

function TDataIntegradorModuloWeb.GetVersionId(aDoc: IXMLDomDocument2): Int64;
begin
  Result := -1;
  try
    if aDoc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//version_id') <> nil then
      Result := strToInt(aDoc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//version-id').text)
    else if aDoc.selectSingleNode('//hash//version-id') <> nil then
      Result := strToInt(aDoc.selectSingleNode('//hash//version-id').text)
    else
      Result := StrToInt(aDoc.selectSingleNode('objects').selectSingleNode('object').selectSingleNode('version-id').text);
  except
    on e: Exception do
    begin
      Self.log('Erro ao ler Campo "Version_ID" no XML de retorno, Tabela: ' + nomeTabela + ' - ' + e.Message, 'Sync');
    end;
  end;
end;

function TDataIntegradorModuloWeb.getXMLContentAsXMLDom(const aXMLContent: string): IXMLDomDocument2;
begin
  Result := nil;
  if aXMLContent <> EmptyStr then
  begin
    CoInitialize(nil);
    try
      Result := CoDOMDocument60.Create;
      Result.loadXML(aXmlContent);
    finally
      CoUninitialize;
    end;
  end;
end;

function TDataIntegradorModuloWeb.getXMLFromServerByIdRemotoList(const aIdRemotoList: string; aRetornoStream: TStringStream; var aException: string): boolean;
var
  _URL: string;
begin
  Result := False;
  aException := EmptyStr;
  try
    _URL := Self.getRequestUrlForAction(False);
    Self.getHTTP.Request.CustomHeaders.Clear;
    Self.getHTTP.Request.CustomHeaders.FoldLines := False;
    Self.getHTTP.Request.CustomHeaders.Add('Id-List:'+ aIdRemotoList);
    Self.getHTTP.Get(_URL, aRetornoStream);
    Result := not aRetornoStream.DataString.IsEmpty;
  except
    aException := UtilsUnit.HandleException(_URL);
  end;
end;

function TDataIntegradorModuloWeb.saveRecordToRemote(ds: TDataSet;
  var salvou: boolean; http: TidHTTP = nil): IXMLDomDocument2;
var
  multipartParams: TidMultipartFormDataStream;
  xmlContent: String;
  stream: TStringStream;
  url: string;
  criouHttp: boolean;
  log: string;
  _Trans: TDBXTransaction;
  _LastId: Integer;
  //version_id: Int64;
begin
  Self.log('Iniciando save record para remote. Classe: ' + ClassName, 'Sync');
  salvou := false;
  criouHTTP := false;
  if http = nil then
  begin
    criouHTTP := true;
    http := getHTTPInstance;
    http.OnWork := Self.OnWorkHandler;
    http.ConnectTimeout := Self.getTimeoutValue;
    http.ReadTimeout := Self.getTimeoutValue;
  end;

  try
    _Trans := self.dmPrincipal.startTransaction;
    try
      url := getRequestUrlForAction(true, -1);
      xmlContent := Self.Post(ds, http, url, _Trans);
      Self.dmPrincipal.commit(_Trans);

      Result := Self.getXMLContentAsXMLDom(xmlContent);
      if (Result <> nil) and (duasVias or clientToServer) then
      begin
        salvou := True;
        if self.nomeTabela <> 'softdelete' then
        begin
          //Atualiza o registro principal local logo após o POST
          self.updateInsertRecord(Result.selectNodes('//hash')[0],  Self.GetIdRemoto(Result), opPOST, _LastId);
        end;
      end;
    except
      on e: EIdHTTPProtocolException do
      begin
        Self.dmPrincipal.rollback(_Trans);
        if e.ErrorCode = 422 then
          log := Format('Erro ao tentar salvar registro. Classe: %s, Tabela: %s, Código de erro: %d, Erro: %s.',[ClassName, Self.nomeTabela, e.ErrorCode, Self.GetErrorMessage(e.ErrorMessage, 'xml')])
        else if e.ErrorCode = 500 then
          log := Format('Erro ao tentar salvar registro. Classe: %s, Tabela: %s, Código de erro: %d. Erro: Erro interno no servidor: %s. ',[ClassName, Self.nomeTabela, e.ErrorCode, e.ErrorMessage])
        else
          log :=  Format('Erro ao tentar salvar registro. Classe: %s, Tabela: %s, Código de erro: %d. Erro: %s.',[ClassName, Self.nomeTabela, e.ErrorCode, e.ErrorMessage]);

        Self.log(log, 'Sync');
        raise EIntegradorException.Create(log) ; //Logou, agora manda pra cima
      end;
      on E: Exception do
      begin
        Self.dmPrincipal.rollback(_Trans);
        log := Format('Erro ao tentar salvar registro. Classe: %s, Tabela: %s, Erro: %s', [ ClassName, Self.nomeTabela, e.Message]);
        Self.log(log, 'Sync');
        raise EIntegradorException.Create(log) ;
      end;
    end;
  finally
    if criouHttp then
      FreeAndNil(http);
  end;
end;

procedure TDataIntegradorModuloWeb.Log(const aLog: string; aClasse: string = '');
begin
  if (FDataLog <> nil) then
    FDataLog.log(aLog, aClasse);
end;

procedure TDataIntegradorModuloWeb.SetDataLog(const Value: ILog);
begin
  FDataLog := Value;
end;

function TDataIntegradorModuloWeb.GetErrorMessage(const aErro, aContentType: string): string;
var
  node: IXMLNode;
  list: IXMLNodeList;
  XML: IXMLDocument;
  htmlDoc: OleVariant;
  el: OleVariant;
  i: Integer;

begin
  Result := EmptyStr;
  if Trim(aErro) <> EmptyStr then
  begin
    if StrUtils.ContainsText(aContentType, 'xml') then
    begin
    CoInitialize(nil);
    XML := TXMLDocument.Create(Self);
    try
      XML.LoadFromXML(aErro);
      list := XML.ChildNodes;
      if list.FindNode('errors') <> nil then
      begin
        list := list.FindNode('errors').ChildNodes;
        if list <> nil  then
        begin
          node := list.FindNode('error');
          if node <> nil then
            Result := Trim(Result + UTF8ToString(HTTPDecode(node.Text)));
        end
        else if list.FindNode('errors').IsTextElement then
          Result := UTF8ToString(HTTPDecode(list.FindNode('errors').Text))
        else
          Result := aErro;
      end;
    finally
      CoUninitialize;
    end;
    end
    else if (StrUtils.ContainsText(aContentType, 'html')) then
    begin
      htmlDoc := coHTMLDocument.Create as IHTMLDocument2;
      htmlDoc.write(aErro);
      htmlDoc.close;
      for i := 0 to htmlDoc.body.all.length - 1 do
      begin
        el := htmlDoc.body.all.item(i);
        if (el.tagName = 'H1') then
        begin
          Result := el.innerText;
          break;
  end;
end;
    end;
  end;
end;

function TDataIntegradorModuloWeb.GetFallbackWhere(aNode: IXMLDOMNode; var IdLocal: Integer): string;
begin
  Result := EmptyStr;
end;

procedure TDataIntegradorModuloWeb.addDetails(ds: TDataSet; params: TStringList);
var
  Detalhe : TTabelaDetalhe;
begin
  for Detalhe in tabelasDetalhe do
    addTabelaDetalheParams(ds.fieldByName(nomePKLocal).AsInteger, params, Detalhe);
end;

procedure TDataIntegradorModuloWeb.addTabelaDetalheParamsIterate(valorPK: integer;
  params: TStringList);
var
  Detalhe: TTabelaDetalhe;
begin
  for Detalhe in Self.tabelasDetalhe do
    addTabelaDetalheParams(valorPK, params, Detalhe);
end;

procedure TDataIntegradorModuloWeb.addTabelaDetalheParams(valorPK: integer;
  params: TStringList;
  tabelaDetalhe: TTabelaDetalhe);
begin
  RunDataSet(valorPk,
             TabelaDetalhe,
             procedure (aDataSet: TDataSet)
             begin
               addTranslatedParams(aDataSet, params, tabelaDetalhe.translations, tabelaDetalhe.nomeParametro);
               tabelaDetalhe.addTabelaDetalheParamsIterate(aDataSet.fieldByName(tabelaDetalhe.nomePKLocal).AsInteger, params);

            end);
end;

function TDataIntegradorModuloWeb.getAdditionalDetailFilter: String;
begin
  Result := EmptyStr;
end;

procedure TDataIntegradorModuloWeb.migrateSingletonTableToRemote;
var
  qry: TSQLDataSet;
  salvou: boolean;
begin
  qry := dmPrincipal.getQuery;
  try
    qry.CommandText := 'SELECT * FROM ' + nomeTabela;
    qry.Open;
    saveRecordToRemote(qry, salvou);
  finally
    FreeAndNil(qry);
  end;
end;

function TDataIntegradorModuloWeb.getLastVersionIDLocal(pTabela: String) : Int64;
var
  qry: TSQLDataSet;
begin
  Result := 0;
  qry := dmPrincipal.getQuery;
  try
    qry.CommandText := 'select version_id from HIBRIDOMETADADOSREMOTOS where TABELA = ' + QuotedStr(UpperCase(pTabela));
    qry.Open;
    if not qry.IsEmpty then
      Result := qry.FieldByName('version_id').AsLargeInt;
  finally
    FreeAndNil(qry);
  end;
end;

function TDataIntegradorModuloWeb.getDefaultParams: string;
begin
  Result := EmptyStr;
  if Self.CustomParams <> nil then
    Result := Self.CustomParams.getCustomParams.getDefaultParams;
end;

function TDataIntegradorModuloWeb.getDefaultSQLStatementForPost(ID: Integer): string;
begin
  if Self.FStatementForPost <> EmptyStr then
  begin
    Result := Self.FStatementForPost;
    if Pos(':ID', UpperCase(Result)) > 0 then
      Result := StringReplace(UpperCase(Result), ':ID', IntToStr(ID), [rfReplaceAll]);
  end
  else
    Result := 'SELECT ' + Self.nomeTabela + '.*, hibridodadosremotos.VERSION_ID, hibridodadosremotos.IDREMOTO from ' + Self.nomeTabela +
    ' left join hibridodadosremotos on hibridodadosremotos.tabela = ' + QuotedStr(UpperCase(Self.nomeTabela)) + ' and hibridodadosremotos.id = ' + IntToStr(ID) +
    ' where ' + Self.nomePKLocal + ' = ' + IntToStr(ID) + getAdditionalSaveConditions;
end;

procedure TDataIntegradorModuloWeb.SetStatementForPost(const aStatement: string);
begin
  FStatementForPost:= aStatement;
end;

function TDataIntegradorModuloWeb.postRecordsToRemote(pDataSetFila: TClientDataSet; http: TidHTTP = nil) : Boolean;
var
  qry: TSQLDataSet;
  salvou: boolean;
  total: integer;
  criouHTTP: boolean;
  BookMark: TBookMark;
begin
  FFilaSincronizacaoCDS := pDataSetFila;
  criouHTTP := false;
  qry := dmPrincipal.getQuery;
  salvou := False;
  result := False;
  BookMark := pDataSetFila.BookMark;
  try
    try
      if pDataSetFila.FieldByName('OPERACAO').AsString = 'D' then //Delete
      begin
        UtilsUnitAgendadorUn.WritePurpleLog('Enviando Delete da ' + pDataSetFila.FieldByName('TABELA').AsString + ' ID: ' + pDataSetFila.FieldByName('ID').AsString);
        qry.commandText := 'select hf.TABELA, hf.ID, h.idremoto, ''S'' as DELETED, h.version_id from hibridofilasincronizacao hf ' +
        'join hibridodadosremotos h on h.tabela = hf.tabela and h.id = hf.id ' +
        'where hf.tabela = :tabela and hf.id = :id';
        qry.ParamByName('tabela').AsString := pDataSetFila.FieldByName('tabela').AsString;
        qry.ParamByName('id').AsInteger := pDataSetFila.FieldByName('id').AsInteger;
      end
      else
      begin
        Self.log('Selecionando registros para sincronização. Classe: ' + ClassName, 'Sync');
        qry.commandText := Self.getDefaultSQLStatementForPost(pDataSetFila.FieldByName('ID').AsInteger);

        {$IFDEF HibridoClientDLL}
        UtilsUnitAgendadorUn.WriteYellowLog(qry.CommandText);
        {$ENDIF}
      end;
      qry.Open;

      if http = nil then
      begin
        criouHTTP := true;
        http := TIdHTTP.Create(nil);
        http.ProtocolVersion := pv1_1;
        http.HTTPOptions := http.HTTPOptions + [hoKeepOrigProtocol];
        http.Request.Connection := 'keep-alive';
      end;

      total := 0;
      qry.First;
      while not qry.Eof do
      begin
        if (not self.shouldContinue) then
          break;

        if notifier <> nil then
        begin
          notifier.setCustomMessage('Salvando ' + getHumanReadableName);
        end;
        try
          saveRecordToRemote(qry, salvou, http);
          if salvou then
          begin
            Self.Log('Registro Salvo');
            inc(total);
          end;
        except
          on e: Exception do
          begin
            if assigned(Self.FOnException) then
              Self.FOnException(haPost, Self, E.ClassName, E.Message, qry.FieldByName(Self.nomePKLocal).AsInteger);

            Self.log('Erro no processamento do postRecordsToRemote. Classe: ' + ClassName +' | '+ e.Message, 'Sync');
            break;
            //if stopOnPostRecordError then
            //  raise
          end;
        end;
        qry.Next;
      end;

      if total = 0 then
      begin
        if pDataSetFila.FieldByName('OPERACAO').AsString = 'D' then //Sempre remove da fila quando registro for de DELETE
          Result := True
        else
        //verifica se o registro não existe mais na tabela, nesse caso remover da fila
        if not self.RegistroAindaExiste(pDataSetFila.FieldByName('tabela').AsString, pDataSetFila.FieldByName('id').AsString) then
          Result := True;
        exit;
      end;

      if notifier <> nil then
        notifier.unflagSalvandoDadosServidor;
      if Total > 0 then
        Self.log(Format('Post de records para remote comitados. Classe: %s. Total de registros: %d.', [ClassName, total]), 'Sync');

    except
      Self.log('Erro no processamento do postRecordsToRemote. Classe: ' + ClassName, 'Sync');
      if stopOnPostRecordError then
        raise;
    end;
  finally
    FreeAndNil(qry);
    if criouHTTP and (http<>nil) then
      FreeAndNil(http);

    if pDataSetFila.BookmarkValid(BookMark) then
      pDataSetFila.BookMark := BookMark;
  end;
  Result := salvou;
end;

function TDataIntegradorModuloWeb.RegistroAindaExiste(pTabela, pID: String) : Boolean;
var
  qry: TSQLDataSet;
begin
  qry := dmPrincipal.getQuery;
  try
    qry.CommandText := 'select * from ' + pTabela + ' where ' + Self.nomePKLocal + ' = ' + pID;
    qry.Open;

    result := not qry.IsEmpty;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TDataIntegradorModuloWeb.redirectRecord(idAntigo, idNovo: integer);
var
  Dependente: TTabelaDependente;
  nomeFK: string;
begin
  beforeRedirectRecord(idAntigo, idNovo);
  //Para cada tabela que referenciava esta devemos dar o update do id antigo para o novo
  for Dependente in tabelasDependentes do
  begin
    nomeFK := Dependente.nomeFK;
    if nomeFK = '' then
      nomeFK := nomePKLocal;
    dmPrincipal.execSQL('UPDATE ' + Dependente.nomeTabela +
    ' set ' + nomeFK + ' = ' + IntToStr(idNovo) +
    ' where ' + nomeFK + ' = ' + IntToStr(idAntigo));
    dmPrincipal.refreshData;    
  end;
  //E então apagar o registro original
  dmPrincipal.execSQL('DELETE FROM ' + nomeTabela + ' where ' +
    nomePKLocal + ' = ' + IntToStr(idAntigo));
end;

{ TTranslationSet }

procedure TTranslationSet.add(serverName, pdvName: string;
  lookupRemoteTable: string = ''; fkName: string = ''; aDataIntegradorClass: TDataIntegradorModuloWebClass = nil);
var
  Translation: TNameTranslation;
begin
  Translation := TNameTranslation.Create;
  Translation.server := serverName;
  Translation.pdv := pdvName;
  Translation.lookupRemoteTable := lookupRemoteTable;
  Translation.fkName := fkName;
  Translation.DataIntegradorClass := aDataIntegradorClass;
  Translations.Add(Translation);
end;

procedure TDataIntegradorModuloWeb.beforeRedirectRecord(idAntigo, idNovo: integer);
begin
  //
end;

constructor TTranslationSet.create(owner: TComponent);
begin
  Translations := TNameTranslationsList.Create(True);
end;

destructor TTranslationSet.Destroy;
var
  item: TObject;
begin
  for item in Translations do
    item.Free;
  Translations.Clear;
  Translations.Free;
  inherited;
end;

function TTranslationSet.get(index: integer): TNameTranslation;
begin
  result := translations[index];
end;

function TTranslationSet.size: integer;
begin
  Result := Translations.Count;
end;

function TTranslationSet.translatePDVToServer(pdvName: string): string;
var
  Translation: TNameTranslation;
begin
  Result := '';

  for Translation in Self.Translations do
    if translation.pdv = pdvName then
    begin
      Result := translation.server;
      Break;
    end;
end;

function TTranslationSet.translateServerToPDV(serverName: string; duasVias: boolean): string;
var
  Translation: TNameTranslation;
begin
  result := '';
  if duasVias and (upperCase(serverName) = 'ID') then
    result := 'idRemoto'
  else
    for Translation in Self.Translations do
      if translation.server = underscorize(serverName)  then
      begin
        Result := translation.pdv;
        Break;
      end;
end;

constructor TDataIntegradorModuloWeb.Create(AOwner: TComponent; aHTTP: TIdHTTP);
begin
  inherited Create(AOwner);
  verbose := false;
  duasVias := false;
  clientToServer := false;
  translations := TTranslationSet.create(self);
  nomePKLocal := 'id';
  nomePKRemoto := 'id';
  nomeGenerator := '';
  usePKLocalMethod := false;
  paramsType := ptParam;
  FstopOnPostRecordError := true;
  FStopOnGetRecordError := True;
  Self.encodeJsonValues := False;
//  translations.add('id', 'idremoto');
  tabelasDetalhe := TTabelaDetalheList.Create(True);
  tabelasDependentes := TTabelaDependenteList.Create(True);
  Self.FStatementForPost := EmptyStr;
  Self.FLastStream := TStringStream.Create('', TEncoding.UTF8);
  Self.FHTTP := aHTTP;
end;

destructor TDataIntegradorModuloWeb.Destroy;
var
  Dependente: TTabelaDependente;
  Detalhe: TTabelaDetalhe;
begin
  for Detalhe in Self.tabelasDetalhe do
     Detalhe.Free;

  for Dependente in Self.tabelasDependentes do
     Dependente.Free;
  if Self.FFieldList <> nil then
    FreeAndNil(Self.FFieldList);
  Self.FLastStream.Free;
  inherited;
end;

function TDataIntegradorModuloWeb.translateValueToServer(translation: TNameTranslation;
  fieldName: string; field: TField; nestedAttribute: string = ''; fkName: string = ''; fieldValue: String = ''): string;
var
  lookupIdRemoto: integer;
  fk: string;
  ValorCampo: string;
begin
  if fieldValue <> '' then
    ValorCampo := fieldValue
  else
    ValorCampo := field.AsString;

  if (length(ValorCampo) >= 1) and (pos(#0, ValorCampo) = length(ValorCampo)) then
    ValorCampo := copy(ValorCampo,1, length(ValorCampo)-1); //Remover um caracter inválido, isso foi encontrado na tabela XFilterDefDetail e foi necessario remove-lo

  Result := ValorCampo;
  if translation.lookupRemoteTable <> '' then
  begin
    result := '';
    if (field.asInteger >= 0) and not(field.IsNull) then
    begin
      if fkName = '' then
        fk := translation.pdv
      else
        fk := fkName;
      lookupIdRemoto := dmPrincipal.getSQLIntegerResult('SELECT idRemoto FROM HIBRIDODADOSREMOTOS Where TABELA = ' +
        QuotedStr(UpperCase(translation.lookupRemoteTable)) + ' AND ID = ' + ValorCampo);

      if lookupIdRemoto > 0 then
        result := IntToStr(lookupIdRemoto)
      else
      begin
        FIdRemotoEncontrado := False;
        self.Log(Format('O IdRemoto da tabela %s para o registro local %s não foi encontrado, verifique se a sincronização desta tabela está funcionando, ou as regras de POST',
                       [UpperCase(translation.lookupRemoteTable), ValorCampo]));
      end;
    end;
  end
  else
  begin
    if field.DataType in [ftFloat, ftBCD, ftFMTBCD, ftCurrency] then
    begin
      result := StringReplace(ValorCampo, ',','.', [rfReplaceAll]);
    end
    else if field.DataType in [ftDateTime, ftTimeStamp] then
    begin
      if field.IsNull then
        result := 'NULL'
      else
        //result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', field.AsDateTime);
        result := FormatDateTime(Self.getDateFormat , StrToDateTime(ValorCampo));
    end
    else if field.DataType in [ftDate] then
    begin
      if field.IsNull then
        result := 'NULL'
      else
        result := FormatDateTime('yyyy-mm-dd', StrToDate(ValorCampo));
    end
    else if field.DataType = ftBlob then
    begin
      result := ValorCampo;
    end;
  end;
end;

function TDataIntegradorModuloWeb.getDateFormat: String;
begin
  Result := 'dd"/"mm"/"yyyy"T"hh":"nn":"ss'
end;

function TDataIntegradorModuloWeb.translateValueFromServer(fieldName, value: string; Integrador: TDataIntegradorModuloWeb): string;
begin
  result := value;
end;

function TDataIntegradorModuloWeb.getFieldAdditionalList(
  node: IXMLDomNode): string;
begin
  result := '';
end;

function TDataIntegradorModuloWeb.getFieldAdditionalUpdateList(
  node: IXMLDomNode): string;
begin
  result := '';
end;

function TDataIntegradorModuloWeb.getFieldAdditionalValues(
  node: IXMLDomNode): string;
begin
  result := '';
end;

function TDataIntegradorModuloWeb.nomeActionGet: string;
begin
  result := nomePlural;
end;

function TDataIntegradorModuloWeb.nomeActionSave: string;
begin
  result := nomePlural;
end;

function TDataIntegradorModuloWeb.nomeSingularGet: string;
begin
  result := FnomeSingular;
end;

function TDataIntegradorModuloWeb.nomeSingularSave: string;
begin
  result := FnomeSingular;
end;

procedure TDataIntegradorModuloWeb.onDetailNamesMalformed(configName, tableName: string);
begin
  self.Log(Format('Tabela detalhe: %s da Classe: %s não possui configuração de %s',[tableName, Self.ClassName, configName]));
end;

function TDataIntegradorModuloWeb.getOrderBy: string;
begin
  result := nomePKLocal;
end;

procedure TDataIntegradorModuloWeb.addMoreParams(ds: TDataSet;
  params: TStringList);
begin
  //nothing to add here
end;

procedure TDataIntegradorModuloWeb.SetdmPrincipal(
  const Value: IDataPrincipal);
var
  Detalhe: TTabelaDetalhe;
begin
  FdmPrincipal := Value;
  if Value <> nil then
  begin
    if Self.FFieldList = nil then
      Self.FFieldList := TFieldDictionaryList.Create(Self.nomeTabela, Value);
    for Detalhe in Self.tabelasDetalhe do
      TTabelaDetalhe(Detalhe).DmPrincipal := Value;
  end;
end;

procedure TDataIntegradorModuloWeb.setIdAtual(const Value: Integer);
begin
  Self.FIdAtual := Value;
end;

procedure TDataIntegradorModuloWeb.setNomePKLocal(const Value: string);
begin
  Self.FnomePKLocal := Value;
end;

procedure TDataIntegradorModuloWeb.setNomePlural(const Value: string);
begin
  Self.FNomePlural := Value;
end;

procedure TDataIntegradorModuloWeb.SetNomeSingular(const Value: string);
begin
  Self.FNomeSingular := Value;
end;

procedure TDataIntegradorModuloWeb.setNomeTabela(const Value: string);
begin
  Self.FnomeTabela := Value;
end;

procedure TDataIntegradorModuloWeb.SetRecursividadeAtiva(const Value: Boolean);
begin
  Self.FRecursividadeAtiva := Value;
end;

procedure TDataIntegradorModuloWeb.SetthreadControl(const Value: IThreadControl);
begin
  FthreadControl := Value;
end;

procedure TDataIntegradorModuloWeb.SetTranslateTableNames(aTranslateTableNames: TJsonDictionary);
begin
  Self.FTranslateTableNames := aTranslateTableNames;
end;

function TDataIntegradorModuloWeb.getdmPrincipal: IDataPrincipal;
begin
  if FdmPrincipal = nil then
  begin
    FdmPrincipal := getNewDataPrincipal;
  end;
  result := FdmPrincipal;
end;

function TDataIntegradorModuloWeb.getAdditionalSaveConditions: string;
begin
  result := '';
end;

class procedure TDataIntegradorModuloWeb.updateDataSets;
begin
  //nada a atualizar
end;

function TDataIntegradorModuloWeb.gerenciaRedirecionamentos(idLocal,
  idRemoto: integer): boolean;
begin
  result := false;
end;

function TDataIntegradorModuloWeb.BinaryFromBase64(const base64: string): TBytesStream;
begin
  Result := UtilsUnit.BinaryFromBase64(base64);
end;

function TDataIntegradorModuloWeb.buildRequestURL(nomeRecurso, params: string;
  httpAction: THttpAction): string;
begin
  Result := Self.getURL + nomePlural;
  if httpAction = haPost then
    Result := Result + '.json' + '?'
  else
    Result := Result + '.xml' + '?';
  Result := Result + Self.getDefaultParams;
end;

{ TTabelaDetalhe }

constructor TTabelaDetalhe.Create(AOwner: TComponent; aHTTP: TIdHTTP);
begin
  inherited;
  translations := TTranslationSet.create(nil);
  Self.duasVias := True;
  Self.FGenId := TGeneratorId.Create;
end;

destructor TTabelaDetalhe.Destroy;
begin
  Self.FGenId.Free;
  inherited;
end;

function TTabelaDetalhe.getNewId(node: IXMLDomNode): Integer;
begin
  Self.FGenId.dmPrincipal := Self.dmPrincipal;
  Result := Self.FGenId.getNewId;
end;

function TTabelaDetalhe.GetNomeParametro: string;
begin
  Result := FnomeParametro;
end;

procedure TTabelaDetalhe.setNomeParametro(const Value: string);
begin
  FnomeParametro := Value;
end;

{ TJSONArrayContainer }

destructor TJSONArrayContainer.Destroy;
begin
  Self.FJSonArray.Free;
  inherited;
end;

function TJSONArrayContainer.getJsonArray: TJsonArray;
begin
  if Self.FJSonArray = nil then
    Self.FJSonArray := TJSONArray.Create;
  Result := Self.FJSonArray;
end;

{ TFieldList }

constructor TFieldDictionaryList.Create(const aTableName: string; aDm : IDataPrincipal);
begin
  inherited Create;
  FTableName := UpperCase(aTableName);
  FDm := aDm;
  Self.getTableFields;
end;

destructor TFieldDictionaryList.Destroy;
var
  _item: TPair<string, TFieldDictionary>;
begin
  for _item in Self do
    _item.Value.Free;
  inherited;
end;

procedure TFieldDictionaryList.getTableFields;
var
  lqry: TSQLDataSet;
  lfield: TFieldDictionary;
  lFieldType: TFieldType;
begin
  if (FDm <> nil) and (self.FTableName <> EmptyStr) then
  begin
    lqry := FDm.getQuery;
    try
      Self.FTableName := UpperCase(Self.FTableName);

      lqry.CommandText :=
        '  SELECT ' +
        '    A.RDB$FIELD_NAME FieldName,' +
        '    C.RDB$TYPE AS DataType,' +
        '    C.RDB$TYPE_NAME TIPO,' +
        '    B.RDB$FIELD_SUB_TYPE SUBTIPO,' +
        '    B.RDB$FIELD_LENGTH TAMANHO,' +
        '    B.RDB$SEGMENT_LENGTH SEGMENTO,' +
        '    B.RDB$FIELD_PRECISION PRECISAO,' +
        '    B.RDB$FIELD_SCALE CASAS_DECIMAIS,' +
        '    A.RDB$DEFAULT_SOURCE VALOR_PADRAO,' +
        '    A.RDB$NULL_FLAG OBRIGATORIO' +
        '  FROM' +
        '    RDB$RELATION_FIELDS A,' +
        '    RDB$FIELDS B,' +
        '    RDB$TYPES C' +
        '  WHERE' +
        '    (A.RDB$RELATION_NAME = '+ QuotedStr(Self.FTableName) + ') AND' +
        '    (B.RDB$FIELD_NAME = A.RDB$FIELD_SOURCE)AND' +
        '    (C.RDB$TYPE = B.RDB$FIELD_TYPE) AND' +
        '    (C.RDB$FIELD_NAME = ''RDB$FIELD_TYPE'')' +
        '  ORDER BY' +
        '    RDB$FIELD_POSITION';

      lqry.Open;
      lqry.First;
      while not lqry.Eof do
      begin
        if not self.ContainsKey(Lowercase(Trim(lqry.FieldByName('FieldName').AsString))) then
        begin
          lfield := TFieldDictionary.Create;
          lfield.FieldName := Lowercase(lqry.FieldByName('FieldName').AsString);
          case lqry.FieldByName('DataType').AsInteger of
            7: //Short
              lFieldType := ftSmallInt;
            8: //INTEGER
              begin
                if lqry.FieldByName('SUBTIPO').asInteger = 0 then
                  lFieldType := ftInteger
                else
                  lFieldType := ftFMTBcd;
              end;
            10: //Float
              begin
                if lqry.FieldByName('SUBTIPO').asInteger = 0 then
                  lFieldType := ftSingle
                else
                  lFieldType := ftFloat;
              end;
            12: //Date
              lFieldType := ftDate;
            13: //Time
              lFieldType := ftTime;
            16: //int64
              begin
                if lqry.FieldByName('SUBTIPO').asInteger = 0 then
                  lFieldType := ftLargeint
                else
                  lFieldType := ftCurrency;
              end;
            27: //double
              begin
                if lqry.FieldByName('SUBTIPO').asInteger = 0 then
                  lFieldType := ftFloat
                else
                  lFieldType := ftCurrency;
              end;
            35: //timestamp
              lFieldType := ftTimeStamp;
            14, 37: //varchar
              lFieldType := ftString;
            261: //blob
              if lqry.FieldByName('SUBTIPO').asInteger = 0 then
                lFieldType := ftBlob
              else
                lFieldType := ftMemo;
            else
              lFieldType := ftUnknown;
          end;
          lfield.DataType := lFieldType;
          Self.Add(LowerCase(Trim(lqry.FieldByName('FieldName').asString)), lfield);
        end;
        lqry.Next;
      end;
    finally
      lqry.Free;
    end;
  end;
end;

{ TFieldDictionary }

procedure TFieldDictionary.SetFieldName(const Value: string);
begin
  FFieldName := Trim(Value);
end;


{ TDetailList }

destructor TDetailList.Destroy;
var
  Pair: TPair<String, TJSONArrayContainer>;
  Json: TJsonValue;
begin
  for Pair in Self do
  begin
    for Json in Pair.Value.getJsonArray do
      Json.Free;
  end;
  Self.Clear;
  inherited;
end;

{ TJsonSetting }

procedure TJsonSetting.SetNomePlural(const Value: string);
begin
  FNomePlural := Value;
end;

procedure TJsonSetting.SetPostStatement(const Value: string);
begin
  FPostStatement := Value;
end;

procedure TJsonSetting.SetPostToServer(const Value: boolean);
begin
  FPostToServer := Value;
end;

procedure TJsonSetting.SetTableName(const Value: string);
begin
  FTableName := Value;
end;

{ TJsonDictionary }

destructor TJsonDictionary.Destroy;
var
  Pair: TPair<String, TJsonSetting>;
begin
  for Pair in Self do
    Pair.Value.Free;
  inherited;
end;

{ TGeneratorId }

function TGeneratorId.getdmPrincipal: IDataPrincipal;
begin
  Result := Self.FdmPrincipal
end;

function TGeneratorId.getNewId: integer;
var
  v: variant;
begin
  Result := 0;
  if Self.FdmPrincipal <> nil then
  begin
    FIDHighValue:= Self.FdmPrincipal.getSQLIntegerResult('SELECT gen_id(KGIDHIGH, 1) FROM RDB$DATABASE');
    if (FIDLowValue = 10) or (FIDHighValue = -1) then
    begin
        v := Self.dmPrincipal.getSQLIntegerResult('SELECT gen_id(KGIDHIGH, 1) FROM RDB$DATABASE');
        if v = NULL then
          raise Exception.Create('Não conseguiu obter o ID do server para inclusão');

        FIDHighValue := v;
        FIDLowValue := 0;
    end;
    Result := FIDHighValue * 10 + FIDLowValue;
    Inc(FIDLowValue);
  end;
end;

procedure TGeneratorId.SetdmPrincipal(const Value: IDataPrincipal);
begin
  Self.FdmPrincipal := Value;
end;

end.
