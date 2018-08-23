program Comparison;

uses
  Vcl.Forms,
  MainFormUn in 'MainFormUn.pas' {MainForm},
  UtilsUnit in '..\..\FW\Lib\UtilsUnit.pas',
  UtilsUnitGUI in '..\..\FW\Lib\UtilsUnitGUI.pas',
  DMUn in 'DMUn.pas' {DM: TDataModule},
  SyncDiffUn in 'SyncDiffUn.pas',
  SincronizaTabelasWebHCUn in '..\..\Agendador\DLL\HibridoClient\SincronizaTabelasWebHCUn.pas',
  acStrUtils in '..\..\repositorio\acStrUtils.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
