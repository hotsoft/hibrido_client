unit DSincronizadorModuloWeb;

interface

uses
  ActiveX, SysUtils, Classes, ExtCtrls, DIntegradorModuloWeb, Dialogs, Windows, IDataPrincipalUnit,
  ISincronizacaoNotifierUnit, DLog, DLLInterfaceUn;

type
  TStepGettersEvent = procedure(name: string; step, total: integer) of object;
  TServerToClientBlock = array of TDataIntegradorModuloWebClass;
  TGetterBlocks = array of TServerToClientBlock;
  TDataSincronizadorModuloWeb = class(TDataModule)
    sincronizaRetaguardaTimer: TTimer;
    procedure DataModuleCreate(Sender: TObject);
    procedure sincronizaRetaguardaTimerTimer(Sender: TObject);
  private
    atualizando: boolean;
    FonStepGetters: TStepGettersEvent;
    FEnderecoIntegrador : string;
    FDataLog: TDataLog;
    procedure SetonStepGetters(const Value: TStepGettersEvent);
    function GetDLLModuleName: string;
  protected
    posterDataModules: array of TDataIntegradorModuloWebClass;
    Fnotifier: ISincronizacaoNotifier;
    function getNewDataPrincipal: IDataPrincipal; virtual; abstract;
  public
    getterBlocks: TGetterBlocks;
    procedure saveAllToRemote(aDLL: IDLLInterface);
    procedure addPosterDataModule(dm: TDataIntegradorModuloWebClass);
    procedure addGetterBlock(getterBlock: TServerToClientBlock);
    procedure ativar;
    procedure desativar;
    procedure getUpdatedData;
    procedure threadedGetUpdatedData;
    procedure threadedSaveAllToRemote;
    property notifier: ISincronizacaoNotifier read FNotifier write FNotifier;
    procedure setEnderecoIntegrador(const Value: string);
  published
    property onStepGetters: TStepGettersEvent read FonStepGetters write SetonStepGetters;
  end;

  TRunnerThreadGetters = class(TThread)
  private
    Fnotifier: ISincronizacaoNotifier;
    Fsincronizador: TDataSincronizadorModuloWeb;
    procedure Setnotifier(const Value: ISincronizacaoNotifier);
    procedure Setsincronizador(const Value: TDataSincronizadorModuloWeb);
  public
    property notifier: ISincronizacaoNotifier read Fnotifier write Setnotifier;
    property sincronizador: TDataSincronizadorModuloWeb read Fsincronizador write Setsincronizador;
  protected
    procedure setMainFormGettingTrue;
    procedure finishGettingProcess;
    procedure Execute; override;
  end;

  TRunnerThreadPuters = class(TThread)
  private
    Fnotifier: ISincronizacaoNotifier;
    Fsincronizador: TDataSincronizadorModuloWeb;
    procedure Setnotifier(const Value: ISincronizacaoNotifier);
    procedure Setsincronizador(const Value: TDataSincronizadorModuloWeb);
  public
    property notifier: ISincronizacaoNotifier read Fnotifier write Setnotifier;
    property sincronizador: TDataSincronizadorModuloWeb read Fsincronizador write Setsincronizador;
  protected
    procedure setMainFormPuttingTrue;
    procedure finishPuttingProcess;
    procedure Execute; override;
  end;
  


var
  DataSincronizadorModuloWeb: TDataSincronizadorModuloWeb;
  salvandoRetaguarda, gravandoVenda: boolean;

implementation

uses ComObj, Forms;

{$R *.dfm}

procedure TDataSincronizadorModuloWeb.addPosterDataModule(
  dm: TDataIntegradorModuloWebClass);
var
  size: integer;
begin
  size := length(posterDataModules);
  SetLength(posterDataModules, size + 1);
  posterDataModules[size] := dm;
end;

function TDataSincronizadorModuloWeb.GetDLLModuleName: string;
var
  szFileName: array[0..MAX_PATH] of Char;
begin
  FillChar(szFileName, SizeOf(szFileName), #0);
  GetModuleFileName(hInstance, szFileName, MAX_PATH);
  Result := szFileName;
end;

procedure TDataSincronizadorModuloWeb.saveAllToRemote(aDLL: IDLLInterface);
var
  i: integer;
  dm: IDataPrincipal;
  dmIntegrador: TDataIntegradorModuloWeb;
begin
  if gravandoVenda then exit;
  dm := getNewDataPrincipal;
  if dm.sincronizar then
  begin
    FDataLog := TDataLog.Create(Self);
    try
      FDataLog.logPrefix := StringReplace(ExtractFileName(Self.GetDLLModuleName),'.dll','',[rfReplaceAll]) + '_';
      FDataLog.baseDir := ExtractFileDir(Application.ExeName) + '\Log\HibridoClient\';
      FDataLog.paused := False;
      try
        for i := 0 to length(posterDataModules)-1 do
        begin
          if (aDLL <> nil) and (aDLL.GetTerminated) then
            Break;

          dmIntegrador := posterDataModules[i].Create(nil);
          try
            dmIntegrador.SetEnderecoIntegrador(Self.FEnderecoIntegrador);
            dmIntegrador.notifier := FNotifier;
            dmIntegrador.dmPrincipal := dm;
            dmIntegrador.DataLog := FDataLog;
            try
              dmIntegrador.postRecordsToRemote(aDLL);
            except
              on E:Exception do
              begin
                FDataLog.log(Format('Erro ao postar registros da classe: %s.  Erro: %s.', [posterDataModules[i].ClassName, e.Message]))
              end;
            end;
          finally
            FreeAndNil(dmIntegrador);
          end;
        end;
      except
        on e: Exception do
        begin
          FDataLog.log('Erros ao dar saveAllToRemote. Erro: ' + e.Message, 'Sync')
        end;
      end;
    finally
      dm := nil;
      FDataLog.Free;
    end;
  end;
end;

procedure TDataSincronizadorModuloWeb.setEnderecoIntegrador(const Value: string);
begin
  Self.FEnderecoIntegrador := Value;
end;

procedure TDataSincronizadorModuloWeb.threadedGetUpdatedData;
var
  t: TRunnerThreadGetters;
begin
  t := TRunnerThreadGetters.Create(true);
  t.sincronizador := self;
  t.notifier := notifier;
  t.Resume;
end;

procedure TDataSincronizadorModuloWeb.getUpdatedData;
var
  i, j: integer;
  block: TServerToClientBlock;
  dm: IDataPrincipal;
begin
  dm := getNewDataPrincipal;
  try
    for i := 0 to length(getterBlocks) - 1 do
    begin
      block := getterBlocks[i];
      dm.startTransaction;
      try
        for j := 0 to length(block) - 1 do
        begin
          with block[j].Create(nil) do
          begin
            notifier := self.notifier;
            dmPrincipal := dm;
            getDadosAtualizados;
            if Assigned(onStepGetters) then onStepGetters(block[j].className, i+1, length(getterBlocks));
            free;
          end;
        end;
        dm.commit;
      except
        dm.rollback;
      end;
    end;
  finally
    dm := nil;
  end;
end;

procedure TDataSincronizadorModuloWeb.DataModuleCreate(Sender: TObject);
begin
  SetLength(posterDataModules, 0);
  SetLength(getterBlocks, 0);
  sincronizaRetaguardaTimer.Enabled := false;
  atualizando := false;
  salvandoRetaguarda := false;
  gravandoVenda := false;
end;

procedure TDataSincronizadorModuloWeb.ativar;
begin
  sincronizaRetaguardaTimer.Enabled := true;
end;

procedure TDataSincronizadorModuloWeb.desativar;
begin
  sincronizaRetaguardaTimer.Enabled := false;
end;

procedure TDataSincronizadorModuloWeb.addGetterBlock(
  getterBlock: TServerToClientBlock);
var
  size: integer;
begin
  size := length(getterBlocks);
  SetLength(getterBlocks, size + 1);
  getterBlocks[size] := getterBlock;
end;

{ TRunnerThread }

procedure TRunnerThreadGetters.Execute;
begin
  inherited;
  FreeOnTerminate := True;
  Synchronize(setMainFormGettingTrue);
  CoInitializeEx(nil, 0);
  try
    sincronizador.getUpdatedData;
  finally
    CoUninitialize;
    Synchronize(finishGettingProcess);
  end;
end;

{ TRunnerThreadPuters }

procedure TRunnerThreadPuters.Execute;
begin
  inherited;
  FreeOnTerminate := True;
  if salvandoRetaguarda or gravandoVenda then exit;
  Synchronize(setMainFormPuttingTrue);
  salvandoRetaguarda := true;
  try
    CoInitializeEx(nil, 0);
    try
      sincronizador.saveAllToRemote(nil);
    finally
      CoUninitialize;
    end;
  finally
    salvandoRetaguarda := false;
    if notifier <> nil then
      notifier.unflagSalvandoDadosServidor;
    Synchronize(finishPuttingProcess);
  end;
end;

procedure TDataSincronizadorModuloWeb.sincronizaRetaguardaTimerTimer(
  Sender: TObject);
begin
  threadedSaveAllToRemote;
end;

procedure TDataSincronizadorModuloWeb.threadedSaveAllToRemote;
var
  t: TRunnerThreadPuters;
begin
  t := TRunnerThreadPuters.Create(true);
  t.sincronizador := self;
  t.notifier := notifier;
  t.Resume;
end;

procedure TDataSincronizadorModuloWeb.SetonStepGetters(
  const Value: TStepGettersEvent);
begin
  FonStepGetters := Value;
end;

procedure TRunnerThreadGetters.finishGettingProcess;
var
  i, j: integer;
  block: TServerToClientBlock;
begin
  //DataPrincipal.refreshData;
  for i := 0 to length(sincronizador.getterBlocks) - 1 do
  begin
    block := sincronizador.getterBlocks[i];
    for j := 0 to length(block) - 1 do
    begin
      block[j].updateDataSets;
    end;
  end;
  notifier.unflagBuscandoDadosServidor;
end;

procedure TRunnerThreadGetters.setMainFormGettingTrue;
begin
  if notifier <> nil then
    notifier.flagBuscandoDadosServidor;
end;

procedure TRunnerThreadPuters.finishPuttingProcess;
begin
  notifier.unflagSalvandoDadosServidor;
end;

procedure TRunnerThreadPuters.setMainFormPuttingTrue;
begin
  notifier.flagSalvandoDadosServidor;
end;

procedure TRunnerThreadPuters.Setnotifier(
  const Value: ISincronizacaoNotifier);
begin
  Fnotifier := Value;
end;

procedure TRunnerThreadGetters.Setnotifier(
  const Value: ISincronizacaoNotifier);
begin
  Fnotifier := Value;
end;

procedure TRunnerThreadPuters.Setsincronizador(
  const Value: TDataSincronizadorModuloWeb);
begin
  Fsincronizador := Value;
end;

procedure TRunnerThreadGetters.Setsincronizador(
  const Value: TDataSincronizadorModuloWeb);
begin
  Fsincronizador := Value;
end;

end.





