unit SyncDiffUn;

interface

uses Datasnap.DBClient, Classes, SysUtils, DB;

type
  ISQLDiff = interface
    function GetDataFromSQL(const aSQL: string): TClientDataSet;
  end;

  TOnCompare = procedure (const aTableName, aDiff: string) of object;

  TSyncDiff = class
  private
    FDiff1: ISQLDiff;
    FDiff2: ISQLDiff;
    FOnCompare: TOnCompare;
    procedure SetOnCompare(const Value: TOnCompare);
    procedure CompareCliente;
    procedure Log(const aTableName, aDiff: string);
    procedure CheckDiffs(aCds1, aCds2: TClientDataSet;  const aPkName, aTableName: string);
    function GetIdRemotoList(aCds: TClientDataSet): string;
  public
    constructor Create(aDiff1, aDiff2: ISQLDiff);
    procedure DoCompare;
    property OnCompare: TOnCompare read FOnCompare write SetOnCompare;
  end;

const
  SQLBasePaciente =
    'SELECT FIRST 50 * FROM paciente' +
    ' WHERE (1=1) %s ' +
    ' ORDER BY IdPaciente DESC;';
  SQLIdRemoto = 'AND IdRemoto IN (%s)';
  SQLSincronizados = 'AND version_id > 0 AND SalvouRetaguarda = ''S''';

implementation



{ TSyncDiff }

constructor TSyncDiff.Create(aDiff1, aDiff2: ISQLDiff);
begin
  FDiff1 := aDiff1;
  FDiff2 := aDiff2;
end;

procedure TSyncDiff.SetOnCompare(const Value: TOnCompare);
begin
  FOnCompare := Value;
end;

procedure TSyncDiff.DoCompare;
begin
  Self.CompareCliente;
end;

procedure TSyncDiff.Log(const aTableName, aDiff: string);
begin
  if assigned(Self.FOnCompare) then
    Self.FOnCompare(aTableName, aDiff);
end;

function TSyncDiff.GetIdRemotoList(aCds: TClientDataSet): string;
var
  _strIds: TStringList;
begin
  Result := '-1';
  _strIds := TStringList.Create;
  try
    aCds.First;
    while not aCds.Eof do
    begin
      _strIds.Add(aCds.FieldByName('IdRemoto').AsString);
      aCds.Next;
    end;
    if _strIds.Count > 0 then
      Result := _strIds.CommaText;
  finally
    _strIds.Free;
  end;
end;

procedure TSyncDiff.CompareCliente;
var
  _cds1, _cds2: TClientDataSet;
  _sql, _tableName: string;
begin
  _sql := Format(SQLBasePaciente, [SQLSincronizados]);
  _cds1 :=  FDiff1.GetDataFromSQL(_sql);
  _cds1.First;
  //primeiro coleta os ids
  _sql := Format(SQLIdRemoto, [Self.GetIdRemotoList(_cds1)]);
  _sql := Format(SQLBasePaciente, [_sql]);
  _cds2 := FDiff2.GetDataFromSQL(_sql);

  _tableName := 'Paciente';
  Self.CheckDiffs(_cds1, _cds2, 'IdPaciente', _tableName);

end;

procedure TSyncDiff.CheckDiffs(aCds1, aCds2: TClientDataSet; const aPkName, aTableName: string);
var
  _Field: TField;
  _WhiteListFields: TStringList;
begin
  if aCds1.RecordCount <> aCds2.RecordCount then
    Self.Log(aTablename, Format('Banco1 diferente na quantidade de registros do Banco2. (%d / %d)',[aCds1.RecordCount, aCds2.RecordCount]));
  _WhiteListFields := TStringList.Create;
  try
    _WhiteListFields.Add(aPkName.ToUpper);
    _WhiteListFields.Add('VERSION_ID');
    aCds1.First;
    while not aCds1.Eof do
    begin
      //Verificar se o registro existe no banco 2
      if not aCds2.Locate('IdRemoto', aCds1.FieldByName('IdRemoto').asInteger, []) then
        Self.Log(aTableName, Format('IdRemoto %s não encontrado', [aCds1.FieldByName('IdRemoto').AsString]))
      else
      begin
        //Verificar campo a campo
        for _Field in aCds1.Fields do
        begin
          if (_WhiteListFields.IndexOf(_Field.FieldName.ToUpper) = -1) and (_Field.AsString <> aCds2.FieldByName(_Field.FieldName).AsString) then
            Self.Log(aTableName, Format('IdRemoto: %d, Field "%s" com valor diferente. Banco1: "%s"; Banco2: "%s"',
                  [aCds1.FieldbyName('IdRemoto').asInteger,
                   _Field.FieldName,
                   _Field.AsString,
                   aCds2.FieldByName(_Field.FieldName).AsString]));
        end;
      end;
      aCds1.Next;
    end;
  finally
    _WhiteListFields.Free;
  end;
end;

end.
