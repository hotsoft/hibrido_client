unit MainFormUn;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.FileCtrl,
  Vcl.ComCtrls;

type
  TMainForm = class(TForm)
    Banco1Edit: TLabeledEdit;
    Banco2Edit: TLabeledEdit;
    Banco1Button: TBitBtn;
    Banco2Button: TBitBtn;
    Bevel1: TBevel;
    Memo: TMemo;
    OkButton: TBitBtn;
    OpenDialog: TOpenDialog;
    ProgressBar: TProgressBar;
    TableLabel: TLabel;
    procedure Banco1ButtonClick(Sender: TObject);
    procedure Banco2ButtonClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    function SelectFile: string;
    procedure OnCompare(const aTableName, aDiff: string);
    procedure OnDiffRecord(const aTableName: string; const aRecordCount,
      aRecno: integer);
    function FormatInClock(TickCount: Integer): string;
    { Private declarations }
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

uses DMUn, SyncDiffUn;

function TMainForm.SelectFile: string;
begin
  Result := EmptyStr;
  if OpenDialog.Execute then
    Result := OpenDialog.FileName;
end;

procedure TMainForm.Banco1ButtonClick(Sender: TObject);
begin
  Banco1Edit.Text := self.SelectFile;
end;

procedure TMainForm.Banco2ButtonClick(Sender: TObject);
begin
  Banco2Edit.Text := self.SelectFile;
end;

//esta função para ser usada em conjunto com o getTickCount
function  TMainForm.FormatInClock(TickCount: Integer): string;
var
  Days:   Integer;
  Hours:  Integer;
  Minutes:Integer;
  Seconds:Integer;
  MSecs:  Integer;
  S_DAY:  string;
  S_HUR:  string;
  S_MIN:  string;
  S_SEC:  string;
  S_MSC:  string;
begin
  Result := '00:00:00:00:000';
  if (TickCount>0) then
  try
    MSecs := TickCount mod 1000;
    S_MSC := IntToStr(MSecs);
    TickCount := TickCount div 1000;

    Seconds := TickCount mod 60;
    TickCount := TickCount div 60;
    S_SEC := IntToStr(Seconds);

    Minutes := TickCount mod 60;
    TickCount := TickCount div 60;
    S_MIN := IntToStr(Minutes);

    Hours := TickCount mod 60;
    TickCount := TickCount div 60;
    S_HUR := IntToStr(Hours);

    Days := TickCount;
    S_DAY := IntToStr(Days);
  finally
    Result := S_DAY
            + FormatSettings.TimeSeparator
            + S_HUR
            + FormatSettings.TimeSeparator
            + S_MIN
            + FormatSettings.TimeSeparator
            + S_SEC
            + FormatSettings.TimeSeparator
            + S_MSC;
  end;
end;

procedure TMainForm.OkButtonClick(Sender: TObject);
var
  DMBanco1, DMBanco2: ISQLDiff;
  _SyncDiff: TSyncDiff;
  _Start: cardinal;
begin
  Memo.Clear;
  DMBanco1 := nil;
  DMBanco2 := nil;
  _Start := GetTickCount;
  if Banco1Edit.Text <> EmptyStr then
    DMBanco1 := TDM.Create(Self, Banco1Edit.Text);
  if Banco2Edit.Text <> EmptyStr then
    DMBanco2 := TDM.Create(Self, Banco2Edit.Text);
  _SyncDiff := TSyncDiff.Create(DMBanco1, DMBanco2);
  try
    _SyncDiff.OnCompare := Self.OnCompare;
    _SyncDiff.OnDiffRecord := Self.OnDiffRecord;
    _SyncDiff.DoCompare;
    Memo.Lines.SaveToFile('./Compare.txt');
  finally
    _SyncDiff.Free;
  end;
  TableLabel.Caption := EmptyStr;
  ProgressBar.Position := 0;
  Memo.Lines.Add('Verificação executada em: ' + FormatInClock (GetTickCount - _Start));
end;

procedure TMainForm.OnCompare(const aTableName, aDiff: string);
begin
  if aTableName.Equals(URL) then
      Memo.Lines.Add('>>URL:' + aDiff)
  else if aTableName.Equals(Separator) then
  begin
    if Memo.Lines.Count > 0 then
      Memo.Lines.Add(aDiff)
  end
  else
    Memo.Lines.Add(Format('Tabela: %s | Diff: %s', [aTableName, aDiff]));
end;

procedure TMainForm.OnDiffRecord(const aTableName: string; const aRecordCount, aRecno: integer);
begin
  TableLabel.Caption := Format('%s - %d de %d', [aTableName, aRecno, aRecordCount]);
  ProgressBar.Max := aRecordCount;
  if aRecno = 1 then
    ProgressBar.Position := 1
  else
    ProgressBar.StepIt;
  Application.ProcessMessages;
  //StatusBar.Panels[0].Text := Format('%s, Registro %d/%d', [aTableName, aRecordCount, aRecno]);
end;

end.

