unit DSincronizadorModuloWeb;

interface

uses
  ActiveX, SysUtils, Classes, ExtCtrls, DIntegradorModuloWeb, Dialogs, Windows, IDataPrincipalUnit,
  ISincronizacaoNotifierUnit, IdHTTP,  System.Generics.Collections, Data.DBXJSON, Data.DBXCommon,
  Data.SqlExpr, Data.FMTBcd, Datasnap.DBClient, osClientDataset, Datasnap.Provider, Data.DB;

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
    procedure RestauraFilaSincronizacao;
  protected
    procedure setMainFormPuttingTrue;
    procedure finishPuttingProcess;
  public
    constructor Create(CreateSuspended: Boolean);
    procedure Execute; override;
  end;


var
  DataSincronizadorModuloWeb: TDataSincronizadorModuloWeb;

implementation

uses ComObj, acNetUtils, IdCoderMIME, IdGlobal, StrUtils;

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

procedure TDataSincronizadorModuloWeb.getUpdatedData;
var
  i: integer;
  block: TServerToClientBlock;
  dm: IDataPrincipal;
  http: TidHTTP;
  dimw: TDataIntegradorModuloWeb;
  dimwName: string;
  sb: TServerToClientBlock;
  dmw:  TDataIntegradorModuloWebClass;
  _Trans: TDBXTransaction;
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
        for dmw in sb do
        begin
          if not Self.ShouldContinue then
            Break;

          _Trans := dm.startTransaction;
          dimw := dmw.Create(nil, http);
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
              dimw.getDadosAtualizados;
              if Assigned(onStepGetters) then onStepGetters(dimw.getHumanReadableName, i, getterBlocks.Count);
              inc(i);
              dm.commit(_Trans);
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
    sincronizador.notifier := Self.notifier;
    sincronizador.threadControl := Self.threadControl;
    sincronizador.Datalog := Self.DataLog;
    sincronizador.CustomParams := Self.CustomParams;
    sincronizador.OnException := Self.FOnException;
    sincronizador.getUpdatedData;
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
            Result.PostToServer := StrToBoolDef(JsonPair.JsonString.Value, True)
        end;
      end;
    end;
  end;
end;

procedure TRunnerThreadPuters.PopulateTranslatedTableNames(aTranslatedTableName: TJsonDictionary);
var
  i, j: integer;
  dmIntegrador: TDataIntegradorModuloWeb;
  JsonServer: TJsonArray;
begin
  JsonServer := Self.getJsonFromServer;
  try
    for i := 0 to sincronizador.posterDataModules.Count - 1 do
    begin
      if not Self.ShouldContinue then
        Break;
      dmIntegrador := sincronizador.posterDataModules[i].Create(nil, nil);
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
  i: integer;
  dm: IDataPrincipal;
  dmIntegrador: TDataIntegradorModuloWeb;
  http: TIdHTTP;
  lTranslateTableNames: TJsonDictionary;
  JsonSetting: TJsonSetting;
  Salvou: Boolean;
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
          sincronizador.FilaDataSet.SQLConnection := dm.getQuery.SQLConnection;
          sincronizador.FilaClientDataSet.Open;
          Self.log('Encontrados ' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' registros na fila', 'Sync');
          sincronizador.FilaClientDataSet.First;
          while not sincronizador.FilaClientDataSet.Eof do
          begin
            if sincronizador.FilaClientDataSetOPERACAO.AsString = 'D' then //Delete
            begin
              Self.log('Enviando delete da ' + sincronizador.FilaClientDataSetTABELA.AsString + ' ID: ' + sincronizador.FilaClientDataSetID.AsString, 'Sync');
              dmIntegrador := sincronizador.posterDataModules[0].Create(nil, http); //Aciona o SoftDelete
            end
            else
            begin
              //Come�a no 1 pois a posi��o 0 � para o softdelete
              for I := 1 to sincronizador.posterDataModules.Count -1 do
              begin
                dmIntegrador := sincronizador.posterDataModules[i].Create(nil, http);
                if UpperCase(dmIntegrador.nomeTabela) = UpperCase(sincronizador.FilaClientDataSetTABELA.AsString) then
                  break
                else
                  FreeAndNil(dmIntegrador);
              end;
            end;

            if dmIntegrador <> nil then
            begin
              dmIntegrador.IdAtual := sincronizador.FilaClientDataSetID.AsInteger;
              Self.log('Sincronizando ' + IntToStr(sincronizador.FilaClientDataSet.RecNo) + '/' + IntToStr(sincronizador.FilaClientDataSet.RecordCount) + ' - tabela ' + sincronizador.FilaClientDataSetTABELA.AsString, 'Sync');
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
                  Salvou := dmIntegrador.postRecordsToRemote(sincronizador.FilaClientDataSet, http);
                end;
              finally
                FreeAndNil(dmIntegrador);
              end;
            end
            else
              Self.log('N�o foi encontrado dataModule registrado para a tabela ' + sincronizador.FilaClientDataSetTABELA.AsString, 'Sync');

            if Salvou then
              self.LimpaFilaSincronizacao
            else
            begin
              self.RestauraFilaSincronizacao;
              sincronizador.FilaClientDataSet.Next;
            end;
          end
        except
          on e: Exception do
          begin
            self.RestauraFilaSincronizacao;
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

procedure TRunnerThreadPuters.RestauraFilaSincronizacao;
var
  BookMark: TBookMark;
begin
  BookMark := sincronizador.FilaClientDataSet.Bookmark;
  try
    sincronizador.FilaClientDataSet.First;
    while not sincronizador.FilaClientDataSet.Eof do
    begin
      sincronizador.FilaClientDataSet.Edit;
      sincronizador.FilaClientDataSetSincronizado.Clear;
      sincronizador.FilaClientDataSet.Post;
      sincronizador.FilaClientDataSet.Next;
    end;
  finally
    sincronizador.FilaClientDataSet.Bookmark := BookMark;
  end;
end;

procedure TRunnerThreadPuters.LimpaFilaSincronizacao;
begin
  sincronizador.FilaClientDataSet.Delete;
  sincronizador.FilaClientDataSet.Filter := 'Sincronizado = TRUE ';
  sincronizador.FilaClientDataSet.Filtered := True;
  try
    sincronizador.FilaClientDataSet.First;
    while not sincronizador.FilaClientDataSet.Eof do
      sincronizador.FilaClientDataSet.Delete;
  finally
    sincronizador.FilaClientDataSet.Filtered := False;
    sincronizador.FilaClientDataSet.Filter := '';
  end;
  sincronizador.FilaClientDataSet.ApplyUpdates(0);
  sincronizador.FilaClientDataSet.First;
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





