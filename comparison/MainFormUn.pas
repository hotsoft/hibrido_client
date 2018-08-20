unit MainFormUn;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.ExtCtrls, Vcl.FileCtrl;

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
    procedure Banco1ButtonClick(Sender: TObject);
    procedure Banco2ButtonClick(Sender: TObject);
    procedure OkButtonClick(Sender: TObject);
  private
    function SelectFile: string;
    procedure OnCompare(const aTableName, aDiff: string);
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

procedure TMainForm.OkButtonClick(Sender: TObject);
var
  DMBanco1, DMBanco2: ISQLDiff;
  _SyncDiff: TSyncDiff;
begin
  Memo.Clear;
  if Banco1Edit.Text <> EmptyStr then
    DMBanco1 := TDM.Create(Self, Banco1Edit.Text);
  if Banco2Edit.Text <> EmptyStr then
    DMBanco2 := TDM.Create(Self, Banco2Edit.Text);
  if (DMBanco1 <> nil) and (DMBanco2 <> nil) then
  begin
    _SyncDiff := TSyncDiff.Create(DMBanco1, DMBanco2);
    try
      _SyncDiff.OnCompare := Self.OnCompare;
      _SyncDiff.DoCompare;
    finally
      _SyncDiff.Free;
    end;
  end;
end;

procedure TMainForm.OnCompare(const aTableName, aDiff: string);
begin
  Memo.Lines.Add(Format('Tabela: %s | Diff: %s', [aTableName, aDiff]));
end;

end.

