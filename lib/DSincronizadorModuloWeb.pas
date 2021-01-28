unit DSincronizadorModuloWeb;

interface

uses
  ActiveX, SysUtils, Classes, ExtCtrls, DIntegradorModuloWeb, Dialogs, Windows, IDataPrincipalUnit,
  ISincronizacaoNotifierUnit, IdHTTP,  System.Generics.Collections, Data.DBXJSON, Data.DBXCommon,
  Data.SqlExpr, Data.FMTBcd, Datasnap.DBClient, osClientDataset, Datasnap.Provider, Data.DB, VersionInfoUn;

type
  TStepGettersEvent = procedure(name: string; step, total: integer) of object;

  TServerToClientBlock = class(TList<TDataIntegradorModuloWebClass>)
  end;

  TGetterBlocks = class(TList<TServerToClientBlock>)
  end;

  TPosterDataModules = class(TList<TDataIntegradorModuloWebClass>)
  end;

  TDataSincronizadorModuloWeb = class(TDataModule)
    sincronizaRetaguardaTimer: TTimer;
    FilaDataSet: TSQLDataSet;
    FilaProvider: TDataSetProvider;
    FilaClientDataSet: TosClientDataset;
    FilaDataSetIDHIBRIDOFILASINCRONIZACAO: TLargeintField;
    FilaDataSetTABELA: TStringField;
    FilaDataSetID: TIntegerField;
    FilaDataSetTENTATIVAS: TIntegerField;
    FilaDataSetULTIMATENTATIVA: TSQLTimeStampField;
    FilaDataSetOPERACAO: TStringField;
    FilaClientDataSetIDHIBRIDOFILASINCRONIZACAO: TLargeintField;
    FilaClientDataSetTABELA: TStringField;
    FilaClientDataSetID: TIntegerField;
    FilaClientDataSetTENTATIVAS: TIntegerField;
    FilaClientDataSetULTIMATENTATIVA: TSQLTimeStampField;
    FilaClientDataSetOPERACAO: TStringField;
    FilaClientDataSetSincronizado: TBooleanField;
    MetaDadosDataSet: TSQLDataSet;
    MetaDadosProvider: TDataSetProvider;
    MetaDadosClientDataSet: TosClientDataset;
    MetaDadosDataSetTABELA: TStringField;
    MetaDadosDataSetVERSION_ID: TLargeintField;
    MetaDadosClientDataSetTABELA: TStringField;
    MetaDadosClientDataSetVERSION_ID: TLargeintField;
    MetaDadosClientDataSetBaixar: TBooleanField;
    MetaDadosClientDataSetnome_plural: TStringField;
    MetaDadosClientDataSetVERSION_ID_SERVER: TLargeintField;
    BlackListFieldClientDataSet: TClientDataSet;
    BlackListFieldClientDataSetid: TIntegerField;
    BlackListFieldClientDataSetmatrix: TStringField;
    BlackListFieldClientDataSetcan_get: TStringField;
    BlackListFieldClientDataSetcan_post: TStringField;
    BlackListFieldClientDataSettable_client_name: TStringField;
    BlackListFieldClientDataSettable_server_name: TStringField;
    BlackListFieldClientDataSetfield_client_name: TStringField;
    BlackListFieldClientDataSetfield_server_name: TStringField;
    FilaDataSetIGNORADO: TSmallintField;
    FilaClientDataSetIGNORADO: TSmallintField;
    procedure DataModuleCreate(Sender: TObject);
    procedure sincronizaRetaguardaTimerTimer(Sender: TObject);
  private
    atualizando: boolean;
    FonStepGetters: TStepGettersEvent;
    FgetterBlocks: TGetterBlocks;
    FposterDataModules: TPosterDataModules;
    FOnException: TOnExceptionProcedure;
    procedure SetonStepGetters(const Value: TStepGettersEvent);
    function ShouldContinue: boolean;
    procedure setGetterBlocks(const Value: TGetterBlocks);
    procedure SetOnException(const Value: TOnExceptionProcedure);
    procedure VerificarTabelasGET(pDM: IDataPrincipal; pSB: TServerToClientBlock; http: TidHTTP);
  protected
    Fnotifier: ISincronizacaoNotifier;
    FThreadControl: IThreadControl;
    FCustomParams: ICustomParams;
    FDataLog: ILog;
    FIDataPrincipal: IDataPrincipal;
  public
    property posterDataModules: TPosterDataModules read FposterDataModules write FPosterDataModules;
    property getterBlocks: TGetterBlocks read FgetterBlocks write setGetterBlocks;
    function getNewDataPrincipal: IDataPrincipal; virtual;
    procedure SetNewDataPrincipal(aIDataPrincipal : IDataPrincipal);
    procedure addPosterDataModule(dm: TDataIntegradorModuloWebClass);
    procedure addGetterBlock(aGetterBlock: TServerToClientBlock);
    procedure ativar;
    procedure desativar;
    procedure getUpdatedData;
    procedure threadedGetUpdatedData;
    procedure saveAllToRemote(wait: boolean = false); virtual;
    property notifier: ISincronizacaoNotifier read FNotifier write FNotifier;
    property threadControl: IThreadControl read FthreadControl write FthreadControl;
    property CustomParams: ICustomParams read FCustomParams write FCustomParams;
    property Datalog: ILog read FDataLog write FDataLog;
    property OnException: TOnExceptionProcedure read FOnException write SetOnException;

    destructor Destroy; override;
  published
    property onStepGetters: TStepGettersEvent read FonStepGetters write SetonStepGetters;
  end;

  TCustomRunnerThread = class(TThread)

  private
    procedure Setnotifier(const Value: ISincronizacaoNotifier);
    procedure Setsincronizador(const Value: TDataSincronizadorModuloWeb);
  protected
    Fnotifier: ISincronizacaoNotifier;
    FthreadControl: IThreadControl;
    Fsincronizador: TDataSincronizadorModuloWeb;
    FCustomParams: ICustomParams;
    FDataLog: ILog;
    FOnException: TOnExceptionProcedure;
    function ShouldContinue: boolean;
    procedure Log(const aLog, aClasse: string);
  public
    property notifier: ISincronizacaoNotifier read Fnotifier write Setnotifier;
    property sincronizador: TDataSincronizadorModuloWeb read Fsincronizador write Setsincronizador;
    property threadControl: IThreadControl read FthreadControl write FthreadControl;
    property CustomParams: ICustomParams read FCustomParams write FCustomParams;
    property DataLog: ILog read FDataLog write FDataLog;
    procedure SetOnException(aOnException: TOnExceptionProcedure);
  end;

  TRunnerThreadGetters = class(TCustomRunnerThread)
  private
    procedure setMainFormGettingFalse;
    procedure finishGettingProcess;
  protected
    procedure setMainFormGettingTrue;
  public
    procedure Execute; override;
  end;

  TRunnerThreadPuters = class(TCustomRunnerThread)
  private
    FRestrictPosters: boolean;
    procedure PopulateTranslatedTableNames(aTranslatedTableName: TJsonDictionary);
    function getJsonFromServer: TJsonArray;
    function getJsonSetting(aJsonArray: TJsonArray; aDataIntegradorModuloWeb: TDataIntegradorModuloWeb): TJsonSetting;
    procedure LimpaFilaSincronizacao;
    procedure RestauraFilaSincronizacao(pRegistrosEncontrados: Integer);
    procedure ValidaPostRules(pTranslatedTables: TJsonDictionary);
    procedure EnviarFila(http: TIdHTTP; lTranslateTableNames: TJsonDictionary; dm: IDataPrincipal; Prioridade: Integer);
    procedure PopulateBlackListFieldClientDataSet;
    function getJsonBlackListFieldFromServer: TJsonArray;
  protected
    procedure setMainFormPuttingTrue;
    procedure finishPuttingProcess;
  public
    constructor Create(CreateSuspended: Boolean);
    procedure Execute; override;
  end;


var
  DataSincronizadorModuloWeb: TDataSincronizadorModuloWeb;
  RodarGetters: Boolean;

implementation

uses ComObj, acNetUtils, IdCoderMIME, IdGlobal, StrUtils, Zip, Shellapi, UtilsUnitAgendadorUn, osSQLQuery;

{$R *.dfm}

procedure TDataSincronizadorModuloWeb.addPosterDataModule(
  dm: TDataIntegradorModuloWebClass);
begin
  Self.FposterDataModules.Add(dm);
end;

procedure TDataSincronizadorModuloWeb.threadedGetUpdatedData;
var
  t: TRunnerThreadGetters;
begin
  t := TRunnerThreadGetters.Create(true);
  t.sincronizador := self;
  t.threadControl := self.threadControl;
  t.CustomParams := self.CustomParams;
  t.DataLog := Self.Datalog;
  t.notifier := notifier;
  t.SetOnException(Self.FOnException);
  t.Start;
end;

function TDataSincronizadorModuloWeb.ShouldContinue: boolean;
begin
  Result := true;
  if Self.FThreadControl <> nil then
    result := Self.FThreadControl.getShouldContinue;
end;

function TDataSincronizadorModuloWeb.getNewDataPrincipal: IDataPrincipal;
begin
  Result := Self.FIDataPrincipal;
end;

procedure TDataSincronizadorModuloWeb.VerificarTabelasGET(pDM: IDataPrincipal; pSB: TServerToClientBlock; http: TidHTTP);
var
  dmw:  TDataIntegradorModuloWebClass;
  dimw: TDataIntegradorModuloWeb;
  JVersions, JsonObj: TJsonObject;
  Retorno: string;
  dmIntegrador: TDataIntegradorModuloWeb;
  pStream: TStringStream;
  I: Integer;
begin
  JVersions := TJSONObject.Create;
  JVersions.Owned := True;
  JsonObj := TJSONObject.Create;
  try
    MetaDadosDataSet.SQLConnection := pDM.getQuery.SQLConnection;
    MetaDadosClientDataSet.Open;
    MetaDadosClientDataSet.First;
    while not MetaDadosClientDataSet.Eof do
    begin
      MetaDadosClientDataSet.Edit;
      MetaDadosClientDataSetBaixar.AsBoolean := False;
      MetaDadosClientDataSet.Post;
      MetaDadosClientDataSet.Next;
    end;

    for dmw in pSB do
    begin
      dimw := dmw.CreateOwn(nil, http);
      try
        if MetaDadosClientDataSet.Locate('TABELA', dimw.nomeTabela, [loCaseInsensitive]) then
        begin
          JsonObj.AddPair(dimw.nomePlural, MetaDadosClientDataSetVERSION_ID.AsString);
          MetaDadosClientDataSet.Edit;
          MetaDadosClientDataSetnome_plural.AsString := dimw.nomePlural;
          MetaDadosClientDataSet.Post;
        end
        else
        begin
          MetaDadosClientDataSet.append;
          MetaDadosClientDataSetTABELA.AsString := UpperCase(dimw.nomeTabela);
          MetaDadosClientDataSetVERSION_ID.AsInteger := 0;
          MetaDadosClientDataSetBaixar.AsBoolean := False;
          MetaDadosClientDataSetnome_plural.AsString := dimw.nomePlural;
          MetaDadosClientDataSet.Post;
          MetaDadosClientDataSet.ApplyUpdates(0);
        end;
      finally
        dimw.Free;
      end;
    end;
    JVersions.AddPair('metadata', JsonObj);

    dmIntegrador := self.posterDataModules[0].CreateOwn(nil, http); //Apenas para pegar a URL
    pStream := TStringStream.Create(JVersions.ToString, TEncoding.UTF8);
    try
      dmIntegrador.CustomParams := Self.FCustomParams;
      http.Request.ContentType := 'application/json';
      http.Request.ContentEncoding := 'utf-8';
      Retorno := http.POST(dmIntegrador.getURL + 'metadata?' + dmIntegrador.getDefaultParams, pStream);
      http.Request.Clear;
    finally
      FreeAndNil(dmIntegrador);
      FreeAndNil(pStream);
    end;

    JsonObj := TJSONObject.ParseJSONValue(TEncoding.ASCII.GetBytes(Retorno),0) as TJSONObject;
    JsonObj := JsonObj.Get(0).JsonValue as TJsonObject;
    for I:= 0 to JsonObj.Size - 1 do
    begin
      MetaDadosClientDataSet.Locate('nome_plural', JsonObj.Get(I).JsonString.Value, [loCaseInsensitive]);
      MetaDadosClientDataSet.Edit;
      MetaDadosClientDataSetBaixar.AsBoolean := True;
      MetaDadosClientDataSetVERSION_ID_SERVER.AsLargeInt := StrToInt64(JsonObj.Get(I).JsonValue.Value);
      MetaDadosClientDataSet.Post
    end;
  finally
    JVersions.Free;
    JsonObj.Free;
  end;
end;

procedure TDataSincronizadorModuloWeb.getUpdatedData;
var
  i: integer;
  dm: IDataPrincipal;
  http: TidHTTP;
  dimw: TDataIntegradorModuloWeb;
  dimwName: string;
  sb: TServerToClientBlock;
  dmw:  TDataIntegradorModuloWebClass;
  _Trans: TDBXTransaction;
  vRegistrosEncontrados: Integer;
begin
  CoInitializeEx(nil, 0);
  try
    dm := getNewDataPrincipal;
    http := getHTTPInstance;
    try
      for sb in getterBlocks do
      begin
        if not Self.ShouldContinue then
          Break;

        //Carrega o Max Version_ID de cada tabela em um JSON que será enviado ao servidor, para que o servidor retorne quais tabelas devem ser atualizadas
        self.VerificarTabelasGET(dm, sb, http);

        for dmw in sb do
        begin
          if not Self.ShouldContinue then
            Break;

          _Trans := dm.startTransaction;
          dimw := dmw.CreateOwn(nil, http);

          if (MetaDadosClientDataSet.Locate('TABELA', dimw.nomeTabela, [loCaseInsensitive])) and
             (MetaDadosClientDataSetBaixar.AsBoolean) then
          begin
            try
              try
                i := 1;
                dimwName := dimw.getHumanReadableName;
                dimw.notifier := Self.Fnotifier;
                dimw.dmPrincipal := dm;
                dimw.threadcontrol := Self.FThreadControl;
                dimw.OnException := Self.OnException;
                dimw.CustomParams := Self.FCustomParams;
                dimw.DataLog := Self.FDataLog;
                dimw.setBlackListFieldCDS(BlackListFieldClientDataSet);
                dimw.getDadosAtualizados(vRegistrosEncontrados);
                if Assigned(onStepGetters) then
                  onStepGetters(dimw.getHumanReadableName, i, getterBlocks.Count);
                dm.commit(_Trans);

                if vRegistrosEncontrados = 0 then
                begin
                  MetaDadosClientDataSet.Edit;
                  MetaDadosClientDataSetVERSION_ID.AsLargeInt := MetaDadosClientDataSetVERSION_ID_SERVER.AsLargeInt;
                  MetaDadosClientDataSet.Post;
                  MetaDadosClientDataSet.ApplyUpdates(0);
                end;
              except
                on E: Exception do
                begin
                  dm.rollback(_Trans);
                  if assigned(Self.FOnException) then
                    Self.FOnException(haGet, dimw, E.ClassName, E.Message, 0);
                  if assigned (self.FDataLog) then
                  begin
                    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), FOREGROUND_RED or FOREGROUND_INTENSITY);
                    Self.FDataLog.log(Format('Erro em GetUpdateData para a classe "%s":'+#13#10+'%s', [dimwName,e.Message]));
                    SetConsoleTextAttribute(GetStdHandle(STD_OUTPUT_HANDLE), 7);
                  end;
                end;
              end;
            finally
              dimw.free;
            end;
          end;
        end;
      end;
    finally
      dm := nil;
      FreeAndNil(http);
    end;
  finally
    CoUninitialize;
  end;
end;

procedure TDataSincronizadorModuloWeb.DataModuleCreate(Sender: TObject);
begin
  sincronizaRetaguardaTimer.Enabled := false;
  atualizando := false;
  Self.FposterDataModules := TPosterDataModules.Create;
  Self.FgetterBlocks := TGetterBlocks.Create;
end;

destructor TDataSincronizadorModuloWeb.Destroy;
begin
  Self.FgetterBlocks.Free;
  Self.FposterDataModules.Free;
  inherited;
end;

procedure TDataSincronizadorModuloWeb.ativar;
begin
  sincronizaRetaguardaTimer.Enabled := true;
end;

procedure TDataSincronizadorModuloWeb.desativar;
begin
  sincronizaRetaguardaTimer.Enabled := false;
end;

procedure TDataSincronizadorModuloWeb.addGetterBlock(aGetterBlock: TServerToClientBlock);
begin
  SelF.FgetterBlocks.Add(aGetterBlock);
end;

procedure TDataSincronizadorModuloWeb.sincronizaRetaguardaTimerTimer(
  Sender: TObject);
begin
  SaveAllToRemote;
end;

procedure TDataSincronizadorModuloWeb.SaveAllToRemote(wait: boolean = false);
var
  t: TRunnerThreadPuters;
begin
  t := TRunnerThreadPuters.Create(true);
  t.sincronizador := self;
  t.notifier := notifier;
  t.threadControl := Self.FThreadControl;
  t.CustomParams := Self.FCustomParams;
  t.FreeOnTerminate := not wait;
  t.DataLog := Self.FDataLog;
  t.SetOnException(Self.FOnException);
  t.Start;
  if wait then
  begin
    t.WaitFor;
    FreeAndNil(t);
  end;
end;

procedure TDataSincronizadorModuloWeb.setGetterBlocks(const Value: TGetterBlocks);
begin
  FgetterBlocks := Value;
end;

procedure TDataSincronizadorModuloWeb.SetNewDataPrincipal(aIDataPrincipal: IDataPrincipal);
begin
  Self.FIDataPrincipal := aIDataPrincipal;
end;

procedure TDataSincronizadorModuloWeb.SetOnException(const Value: TOnExceptionProcedure);
begin
  FOnException := Value;
end;

procedure TDataSincronizadorModuloWeb.SetonStepGetters(
  const Value: TStepGettersEvent);
begin
  FonStepGetters := Value;
end;

{TRunnerThreadGetters}

procedure TRunnerThreadGetters.finishGettingProcess;
var
  i, j: integer;
  block: TServerToClientBlock;
begin
  //DataPrincipal.refreshData;
  for i := 0 to sincronizador.getterBlocks.Count - 1 do
  begin
    block := sincronizador.getterBlocks[i];
    for j := 0 to block.Count - 1 do
    begin
      block[j].updateDataSets;
    end;
  end;
  setMainFormGettingFalse;
end;

procedure TRunnerThreadGetters.setMainFormGettingFalse;
begin
  if notifier <> nil then
    notifier.unflagBuscandoDadosServidor;
end;

procedure TRunnerThreadGetters.setMainFormGettingTrue;
begin
  if notifier <> nil then
    notifier.flagBuscandoDadosServidor;
end;

procedure TRunnerThreadGetters.Execute;
begin
  inherited;
  FreeOnTerminate := True;
  if Self.Fnotifier <> nil then
    Synchronize(Self.setMainFormGettingTrue);
  CoInitializeEx(nil, 0);
  try
    if RodarGetters then
    begin
      sincronizador.notifier := Self.notifier;
      sincronizador.threadControl := Self.threadControl;
      sincronizador.Datalog := Self.DataLog;
      sincronizador.CustomParams := Self.CustomParams;
      sincronizador.OnException := Self.FOnException;
      sincronizador.getUpdatedData;
    end;
  finally
    CoUninitialize;
    if Self.Fnotifier <> nil then
      Synchronize(finishGettingProcess);
  end;
end;

{TRunnerThreadPuters}

procedure TRunnerThreadPuters.finishPuttingProcess;
begin
  if notifier <> nil then
    notifier.unflagSalvandoDadosServidor;
end;

procedure TRunnerThreadPuters.setMainFormPuttingTrue;
begin
  if FNotifier <> nil then
    FNotifier.flagSalvandoDadosServidor;
end;

function TRunnerThreadPuters.getJsonFromServer: TJsonArray;
var
  JsonFromServer: String;
begin
  JsonFromServer := EmptyStr;
  if (Self.FCustomParams <> nil) then
    JsonFromServer := Self.FCustomParams.getJsonFromServer(Self.FRestrictPosters);

  if JsonFromServer <> EmptyStr then
    Result :=  TJsonObject.ParseJSONValue(TEncoding.ASCII.getBytes(JsonFromServer),0) as TJsonArray
  else
    Result := TJsonArray.Create;
end;

function TRunnerThreadPuters.getJsonBlackListFieldFromServer: TJsonArray;
var
  JsonFromServer: String;
begin
  JsonFromServer := EmptyStr;
  if (Self.FCustomParams <> nil) then
    JsonFromServer := Self.FCustomParams.getJsonBlackListFieldFromServer;

  if JsonFromServer <> EmptyStr then
    Result :=  TJsonObject.ParseJSONValue(TEncoding.ASCII.getBytes(JsonFromServer),0) as TJsonArray
  else
    Result := TJsonArray.Create;
end;

function TRunnerThreadPuters.getJsonSetting(aJsonArray: TJsonArray; aDataIntegradorModuloWeb: TDataIntegradorModuloWeb): TJsonSetting;
var
  i: integer;
  JsonObject: TJsonValue;
  JsonPair: TJsonPair;

begin
  Result := TJsonSetting.Create;
  Result.TableName := LowerCase(Trim(aDataIntegradorModuloWeb.getNomeTabela));
  Result.NomePlural := LowerCase(Trim(aDataIntegradorModuloWeb.nomePlural));
  Result.PostToServer := (not Self.FRestrictPosters);
  for JsonObject in aJsonArray do
  begin
    if not Self.ShouldContinue then
      Break;

    if (JsonObject is TJsonObject) then
    begin
      if (TJsonObject(JsonObject).Get('client_name') <> nil) and
         (AnsiSameText(TJsonObject(JsonObject).Get('client_name').JsonValue.Value, Result.TableName)) then
      begin
        for i := 0 to TJsonObject(JsonObject).size - 1 do
        begin
          JsonPair := TJsonObject(JsonObject).Get(i);
          if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'statement') then
          begin
            Result.PostStatement := TIdDecoderMIME.DecodeString(JsonPair.JsonValue.Value, IndyTextEncoding_UTF8)
          end;
          if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'post') then
          begin
            Result.PostToServer := StrToBoolDef(UpperCase(JsonPair.JsonValue.ToString), True)
          end;
        end;
      end;
    end;
  end;
end;

procedure TRunnerThreadPuters.PopulateBlackListFieldClientDataSet;
var
  i: integer;
  JsonServer: TJsonArray;
  JsonObject: TJsonValue;
  JsonPair: TJsonPair;
begin
  //Carrega o Black List Field
  JsonServer := Self.getJsonBlackListFieldFromServer;
  sincronizador.BlackListFieldClientDataSet.CreateDataSet;

  if not sincronizador.BlackListFieldClientDataSet.Active then
    sincronizador.BlackListFieldClientDataSet.Open;

  for JsonObject in JsonServer do
  begin
    sincronizador.BlackListFieldClientDataSet.Append;
    if (JsonObject is TJsonObject) then
    begin
      for i := 0 to TJsonObject(JsonObject).size - 1 do
      begin
        JsonPair := TJsonObject(JsonObject).Get(i);
        if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'id') then
        begin
          sincronizador.BlackListFieldClientDataSetid.AsInteger := StrToInt(Trim(JsonPair.JsonValue.ToString));
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'matrix') then
        begin
          if UpperCase(Trim(JsonPair.JsonValue.ToString)) = 'TRUE' then
            sincronizador.BlackListFieldClientDataSetmatrix.AsString := 'S'
          else
            sincronizador.BlackListFieldClientDataSetmatrix.AsString := 'N';
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'can_get') then
        begin
          if UpperCase(Trim(JsonPair.JsonValue.ToString)) = 'TRUE' then
            sincronizador.BlackListFieldClientDataSetcan_get.AsString := 'S'
          else
            sincronizador.BlackListFieldClientDataSetcan_get.AsString := 'N';
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'can_post') then
        begin
          if UpperCase(Trim(JsonPair.JsonValue.ToString)) = 'TRUE' then
            sincronizador.BlackListFieldClientDataSetcan_post.AsString := 'S'
          else
            sincronizador.BlackListFieldClientDataSetcan_post.AsString := 'N';
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'table_client_name') then
        begin
          sincronizador.BlackListFieldClientDataSettable_client_name.AsString := Trim(JsonPair.JsonValue.Value);
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'table_server_name') then
        begin
          sincronizador.BlackListFieldClientDataSettable_server_name.AsString := Trim(JsonPair.JsonValue.Value);
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'field_client_name') then
        begin
          sincronizador.BlackListFieldClientDataSetfield_client_name.AsString := Trim(JsonPair.JsonValue.Value);
        end
        else if (lowerCase(Trim(JsonPair.JsonString.Value)) = 'field_server_name') then
        begin
          sincronizador.BlackListFieldClientDataSetfield_server_name.AsString := Trim(JsonPair.JsonValue.Value);
        end;
      end;
    end;
    sincronizador.BlackListFieldClientDataSet.Post;
  end;
end;

procedure TRunnerThreadPuters.PopulateTranslatedTableNames(aTranslatedTableName: TJsonDictionary);
var
  i, j: integer;
  dmIntegrador: TDataIntegradorModuloWeb;
  JsonServer: TJsonArray;
begin
  //Carrega o Post Rules
  JsonServer := Self.getJsonFromServer;
  try
    for i := 0 to sincronizador.posterDataModules.Count - 1 do
    begin
      if not Self.ShouldContinue then
        Break;
      dmIntegrador := sincronizador.posterDataModules[i].CreateOwn(nil, nil);
      try
        if (dmIntegrador.getNomeTabela <> EmptyStr) and (dmIntegrador.NomeSingular <> EmptyStr) then
          if not aTranslatedTableName.ContainsKey(dmIntegrador.getNomeTabela) then
            aTranslatedTableName.Add(LowerCase(Trim(dmIntegrador.getNomeTabela)), Self.getJsonSetting(JsonServer, dmIntegrador));
        for j := 0 to dmIntegrador.getTabelasDetalhe.Count -1 do
          if not aTranslatedTableName.ContainsKey(dmIntegrador.getTabelasDetalhe[j].getNomeTabela) then
            aTranslatedTableName.Add(LowerCase(Trim(dmIntegrador.getTabelasDetalhe[j].getNomeTabela)), Self.getJsonSetting(JsonServer, dmIntegrador.getTabelasDetalhe[j]));
      finally
        FreeAndNil(dmIntegrador);
      end;
    end;
  finally
    JsonServer.Free;
  end;
end;

constructor TRunnerThreadPuters.Create(CreateSuspended: Boolean);
begin
  inherited Create(CreateSuspended);
  Self.FRestrictPosters := False;
end;

procedure TRunnerThreadPuters.Execute;
var
  dm: IDataPrincipal;
  http: TIdHTTP;
  lTranslateTableNames: TJsonDictionary;
  qry: TosSQLQuery;
begin
  inherited;
  if Self.Fnotifier <> nil then
    Synchronize(setMainFormPuttingTrue);

  try
    CoInitializeEx(nil, 0);
    try
      http := nil;
      dm := sincronizador.getNewDataPrincipal;
      try
        try
          http := getHTTPInstance;
          lTranslateTableNames := TJsonDictionary.Create;
          Self.PopulateTranslatedTableNames(lTranslateTableNames);
          Self.PopulateBlackListFieldClientDataSet;

          /// ******** FILA 1 *******
          //Fila com mais prioridade, todos os registros que nunca foram tentados ser sincronizados antes
          sincronizador.FilaDataSet.SQLConnection := dm.getQuery.SQLConnection;
          sincronizador.FilaClientDataSet.Close;
          sincronizador.FilaClientDataSet.CommandText := 'select first 500 * from hibridofilasincronizacao where coalesce(tentativas,0) = 0 and coalesce(ignorado,0) = 0 order by idhibridofilasincronizacao';
          sincronizador.FilaClientDataSet.Open;

          //FRestrictPosters - é TRUE quando a sincronização é iniciada pelo LM/LP para as tabelas do stockfin, quando o usuário acessa o recurso financeiro.
          if (sincronizador.FilaClientDataSet.RecordCount > 0) and (not Self.FRestrictPosters) then
            self.ValidaPostRules(lTranslateTableNames);

          Self.log('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila', 'Sync');
          UtilsUnitAgendadorUn.WriteGreenLog('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila');
          self.EnviarFila(http, lTranslateTableNames, dm, 0);

          /// ******** FILA 2 *******
          //Fila com registros que foram ignorados anteriormente por não corresponderem a uma regra de where do select,
          //exemplo: requisições retidas
          sincronizador.FilaClientDataSet.Close;
          sincronizador.FilaClientDataSet.CommandText := 'select first 500 * from hibridofilasincronizacao where ignorado between 1 and 20 and coalesce(tentativas,0) = 0 order by ignorado';
          sincronizador.FilaClientDataSet.Open;

          //FRestrictPosters - é TRUE quando a sincronização é iniciada pelo LM/LP para as tabelas do stockfin, quando o usuário acessa o recurso financeiro.
          if (sincronizador.FilaClientDataSet.RecordCount > 0) and (not Self.FRestrictPosters) then
            self.ValidaPostRules(lTranslateTableNames);

          Self.log('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila de ignorados', 'Sync');
          UtilsUnitAgendadorUn.WriteGreenLog('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila de ignorados');
          self.EnviarFila(http, lTranslateTableNames, dm, 0);

          // ******** FILA 3 ******
          //Fila com prioridade menor, sincroniza os registros que deram problemas ao menos 1 vez
          //Se tentou sincronizar o registro por 10 vezes e deu problema, ele é deixado de lado, para ser avaliado o porque do erro.
          sincronizador.FilaClientDataSet.Close;
          sincronizador.FilaClientDataSet.CommandText := 'select first 100 * from hibridofilasincronizacao where tentativas between 1 and 10 order by idhibridofilasincronizacao, Tentativas';
          sincronizador.FilaClientDataSet.Open;

          if (sincronizador.FilaClientDataSet.RecordCount > 0) and (not Self.FRestrictPosters) then
            self.ValidaPostRules(lTranslateTableNames);

          Self.log('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila de tentativas', 'Sync');
          UtilsUnitAgendadorUn.WriteGreenLog('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila de tentativas');
          self.EnviarFila(http, lTranslateTableNames, dm, 1);

          //Apagar da fila registros não sincronizados
         { try
            qry := TosSQLQuery.Create(nil);
            qry.SQLConnection := dm.getQuery.SQLConnection;
            qry.SQL.Text := 'delete from hibridofilasincronizacao where tentativas > 10 or ignorado > 30 ';
            qry.ExecSQL;
          finally
            qry.Close;
            FreeAndNil(qry);
          end;}

          //Se o RestrictPosters for TRUE significa que a sincronização foi iniciar pelo LM via stock ou financeiro, dessa forma não devem ser feitos os GETS
          RodarGetters := not Self.FRestrictPosters;
        except
          on e: Exception do
          begin
            self.RestauraFilaSincronizacao(1);
            sincronizador.FilaClientDataSet.Next;
            Self.log('Erros ao dar saveAllToRemote. Erro: ' + e.Message, 'Sync');
          end;
        end;
      finally
        dm := nil;
        if http <> nil then
          FreeAndNil(http);
        FreeAndNil(lTranslateTableNames);
      end;
    finally
      CoUninitialize;
    end;
  finally
    if Self.Fnotifier <> nil then
      Synchronize(finishPuttingProcess);
  end;
end;

procedure TRunnerThreadPuters.EnviarFila(http: TIdHTTP; lTranslateTableNames: TJsonDictionary; dm: IDataPrincipal; Prioridade: Integer);
var
  dmIntegrador: TDataIntegradorModuloWeb;
  i: Integer;
  JsonSetting: TJsonSetting;
  Aux: Integer;
  RegistrosEncontrados: Integer;
begin
  Aux := sincronizador.FilaClientDataSet.RecordCount;
  sincronizador.FilaClientDataSet.First;
  while not sincronizador.FilaClientDataSet.Eof do
  begin
    Aux := Aux-1;
    if (Prioridade = 0) and (sincronizador.FilaClientDataSetTENTATIVAS.AsInteger > 0)  then
    begin
      sincronizador.FilaClientDataSet.Next;
      continue;
    end;

    if sincronizador.FilaClientDataSetOPERACAO.AsString = 'D' then //Delete
    begin
      Self.log('Enviando delete da ' + sincronizador.FilaClientDataSetTABELA.AsString + ' ID: ' + sincronizador.FilaClientDataSetID.AsString, 'Sync');
      dmIntegrador := sincronizador.posterDataModules[0].CreateOwn(nil, http); //Aciona o SoftDelete
    end
    else
    begin
      //Começa no 1 pois a posição 0 é para o softdelete
      for I := 1 to sincronizador.posterDataModules.Count -1 do
      begin
        dmIntegrador := sincronizador.posterDataModules[i].CreateOwn(nil, http);
        if UpperCase(dmIntegrador.nomeTabela) = UpperCase(sincronizador.FilaClientDataSetTABELA.AsString) then
          break
        else
          FreeAndNil(dmIntegrador);
      end;
    end;

    if dmIntegrador <> nil then
    begin
      dmIntegrador.IdAtual := sincronizador.FilaClientDataSetID.AsInteger;
      if Aux mod 10 = 0 then
        UtilsUnitAgendadorUn.WriteGreenLog('Restam ' + IntToStr(Aux) + ' registros');
      if not Self.ShouldContinue then
        Break;

      try
        JsonSetting := lTranslateTableNames.Items[dmIntegrador.getNomeTabela];
        if ((JsonSetting <> nil) and (JsonSetting.PostToServer)) or
          ((JsonSetting = nil) and (not Self.FRestrictPosters)) then
        begin
          if (JsonSetting <> nil) then
            dmIntegrador.SetStatementForPost(JsonSetting.PostStatement);
          dmIntegrador.SetTranslateTableNames(lTranslateTableNames);
          dmIntegrador.notifier := FNotifier;
          dmIntegrador.threadControl := Self.FthreadControl;
          dmIntegrador.CustomParams := Self.FCustomParams;
          dmIntegrador.dmPrincipal := dm;
          dmIntegrador.DataLog := Self.FDataLog;
          dmIntegrador.SetOnException(Self.FOnException);
          dmIntegrador.setBlackListFieldCDS(sincronizador.BlackListFieldClientDataSet);
          dmIntegrador.setRestrictPosters(FRestrictPosters);

          if dmIntegrador.postRecordsToRemote(sincronizador.FilaClientDataSet, RegistrosEncontrados, http) then
          begin
            self.LimpaFilaSincronizacao;
          end
          else
          begin
            self.RestauraFilaSincronizacao(RegistrosEncontrados);
            sincronizador.FilaClientDataSet.Next;
          end;
        end
        else
          sincronizador.FilaClientDataSet.Next;
      finally
        FreeAndNil(dmIntegrador);
      end;
    end
    else
    begin
      Self.log('Não foi encontrado dataModule registrado para a tabela ' + sincronizador.FilaClientDataSetTABELA.AsString, 'Sync');
      sincronizador.FilaClientDataSet.Next;
    end;
  end
end;

procedure TRunnerThreadPuters.ValidaPostRules(pTranslatedTables: TJsonDictionary);
var
  JsonSetting: TJsonSetting;
  dmIntegrador: TDataIntegradorModuloWeb;
  I: Integer;
begin
  //Remove da fila todos os registros que não deve ser feito POST, isso é definido no Laboratory_Post_Rules
  try
    //Começa no 1 pois a posição 0 é para o softdelete
    for I := 1 to sincronizador.posterDataModules.Count -1 do
    begin
      dmIntegrador := sincronizador.posterDataModules[i].CreateOwn(nil, nil);
      if dmIntegrador <> nil then
      begin
        try
          JsonSetting := pTranslatedTables.Items[dmIntegrador.getNomeTabela];
          if ((JsonSetting <> nil) and (not JsonSetting.PostToServer)) then
          begin
            sincronizador.FilaClientDataSet.Filter := 'TABELA = ' + QuotedStr(UpperCase(dmIntegrador.getNomeTabela));
            sincronizador.FilaClientDataSet.Filtered := True;
            try
              if sincronizador.FilaClientDataSet.RecordCount > 0 then
              begin
                Self.FDataLog.log(Format('Removendo da fila os registros da tabela %s, Quantidade: %s', [sincronizador.FilaClientDataSetTABELA.AsString, IntToStr(sincronizador.FilaClientDataSet.RecordCount)]));
                while not sincronizador.FilaClientDataSet.Eof do
                  sincronizador.FilaClientDataSet.Delete;

                sincronizador.FilaClientDataSet.ApplyUpdates(0);
              end;
            finally
              sincronizador.FilaClientDataSet.Filtered := False;
              sincronizador.FilaClientDataSet.Filter := '';
            end;
          end;
        finally
          FreeAndNil(dmIntegrador);
        end;
      end;
    end;
  finally
    sincronizador.FilaClientDataSet.Filter := '';
    sincronizador.FilaClientDataSet.Filtered := False;
  end;
end;

procedure TRunnerThreadPuters.RestauraFilaSincronizacao(pRegistrosEncontrados: Integer);
var
  BookMark: TBookMark;
begin
  //pRegistrosEncontrados:
  //Quando um registro não foi enviado ao servidor, pois não atendeu as condições do POST RULES
  //ele deve ficar na fila até atender a condição, sem contar como tentativas erradas de envio
  BookMark := sincronizador.FilaClientDataSet.GetBookmark;
  if pRegistrosEncontrados > 0 then
  begin
    sincronizador.FilaClientDataSet.Edit;
    sincronizador.FilaClientDataSetTENTATIVAS.AsInteger := sincronizador.FilaClientDataSetTENTATIVAS.AsInteger + 1;
    sincronizador.FilaClientDataSetULTIMATENTATIVA.AsDateTime := now;
    sincronizador.FilaClientDataSet.Post;
    sincronizador.FilaClientDataSet.ApplyUpdates(0);
  end
  else  //O registro não foi encontrado mas ainda existe na base, então alguma condição do where não permitiu que fosse selecionado, exemplo: Requisição retida
  begin
    sincronizador.FilaClientDataSet.Edit;
    sincronizador.FilaClientDataSetIGNORADO.AsInteger := sincronizador.FilaClientDataSetIGNORADO.AsInteger + 1;
    sincronizador.FilaClientDataSetULTIMATENTATIVA.AsDateTime := now;
    sincronizador.FilaClientDataSet.Post;
    sincronizador.FilaClientDataSet.ApplyUpdates(0);
  end;

  try
    sincronizador.FilaClientDataSet.Filter := 'Sincronizado = TRUE';
    sincronizador.FilaClientDataSet.Filtered := True;
    sincronizador.FilaClientDataSet.First;
    while not sincronizador.FilaClientDataSet.Eof do
    begin
      sincronizador.FilaClientDataSet.Edit;
      sincronizador.FilaClientDataSetSincronizado.Clear;
      sincronizador.FilaClientDataSet.Post;
    end;
  finally
    sincronizador.FilaClientDataSet.Filter := '';
    sincronizador.FilaClientDataSet.Filtered := False;
    if sincronizador.FilaClientDataSet.BookmarkValid(BookMark) then
      sincronizador.FilaClientDataSet.GotoBookmark(BookMark);
    sincronizador.FilaClientDataSet.FreeBookmark(BookMark);
  end;
end;

procedure TRunnerThreadPuters.LimpaFilaSincronizacao;
var
  BookMark: TBookMark;
begin
  sincronizador.FilaClientDataSet.Delete;
  sincronizador.FilaClientDataSet.ApplyUpdates(0);

  //////  Foi comentado para deixar remover da fila apenas o registro corrente que foi sincronizado, estava acontecendo de alguns registros de tabelas filhas
  ///  não serem sincronizados e não foram encontrados na tabela de fila
  ///  removi essa parte para testar se o problema continuar
  ///
  {BookMark := sincronizador.FilaClientDataSet.GetBookmark;
  sincronizador.FilaClientDataSet.Filter := 'Sincronizado = TRUE ';
  sincronizador.FilaClientDataSet.Filtered := True;
  try
    sincronizador.FilaClientDataSet.First;
    while not sincronizador.FilaClientDataSet.Eof do
      sincronizador.FilaClientDataSet.Delete;
  finally
    sincronizador.FilaClientDataSet.Filtered := False;
    sincronizador.FilaClientDataSet.Filter := '';

    if (sincronizador.FilaClientDataSet.RecordCount > 0) and (sincronizador.FilaClientDataSet.BookmarkValid(BookMark)) then
      sincronizador.FilaClientDataSet.GotoBookmark(BookMark);

    sincronizador.FilaClientDataSet.FreeBookmark(BookMark);
  end;
  sincronizador.FilaClientDataSet.ApplyUpdates(0);   }
end;

{ TCustomRunnerThread }

procedure TCustomRunnerThread.Log(const aLog, aClasse: string);
begin
  if Self.FDataLog <> nil then
   Self.FDataLog.log(aLog, aClasse);
end;

procedure TCustomRunnerThread.Setnotifier(const Value: ISincronizacaoNotifier);
begin
  Fnotifier := Value;
end;

procedure TCustomRunnerThread.SetOnException(aOnException: TOnExceptionProcedure);
begin
  Self.FOnException := aOnException;
end;

procedure TCustomRunnerThread.Setsincronizador(const Value: TDataSincronizadorModuloWeb);
begin
  Fsincronizador := Value;
end;

function TCustomRunnerThread.ShouldContinue: boolean;
begin
  result := true;
  if Self.FThreadControl <> nil then
    result := Self.FThreadControl.getShouldContinue;
end;

end.





