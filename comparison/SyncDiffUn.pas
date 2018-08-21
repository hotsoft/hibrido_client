unit SyncDiffUn;

interface

uses Datasnap.DBClient, Classes, SysUtils, DB, StrUtils;

type
  ISQLDiff = interface
    function GetDataFromSQL(const aSQL: string): TClientDataSet;
  end;

  TOnCompare = procedure (const aTableName, aDiff: string) of object;

  TOnDiffRecord = procedure (const aTableName: string; const aRecordCount, aRecno: integer) of object;

  TSyncDiff = class
  private
    FDiff1: ISQLDiff;
    FDiff2: ISQLDiff;
    FOnCompare: TOnCompare;
    FOnDiffRecord: TOnDiffRecord;
    procedure SetOnCompare(const Value: TOnCompare);
    procedure ComparePaciente;
    procedure Log(const aTableName, aDiff: string);
    function CheckDiffs(aCds1, aCds2: TClientDataSet;  const aPkName, aTableName: string): boolean;
    function GetIdRemotoList(aCds: TClientDataSet): string;
    procedure CompareRequisicao;
    procedure CompareMasterTable(const aTableName, aPkName, aSQLBase: string;
      out aIdRemotoList: string);
    procedure CompareDetailTable(const aDetailTableName, aPKName, aMasterIdRemotoList, aSQLBase: string; out aDetailIdRemotoList: string);
    procedure SetOnDiffRecord(const Value: TOnDiffRecord);
    function GetLogSeparator: string;
  public
    constructor Create(aDiff1, aDiff2: ISQLDiff);
    procedure DoCompare;
    property OnCompare: TOnCompare read FOnCompare write SetOnCompare;
    property OnDiffRecord: TOnDiffRecord read FOnDiffRecord write SetOnDiffRecord;
  end;

const
  SQLIdRemoto = 'AND IdRemoto IN (%s)';
  SQLSincronizados = 'AND version_id > 0 AND SalvouRetaguarda = ''S''';

  SQLBasePaciente   = 'SELECT FIRST 50 * FROM paciente WHERE (1=1) %s ORDER BY IdPaciente DESC;';
  SQLBaseDadoAdicionalPaciente = 'SELECT bdp.* FROM dadoadicionalpaciente bdp JOIN paciente p ON bdp.idpaciente = p.idpaciente WHERE p.idremoto IN (%s) ';

  SQLBaseRequisicao = 'SELECT FIRST 50 * FROM requisicao WHERE (1=1) %s ORDER BY IdRequisicao DESC;';
  SQLBaseExame = 'SELECT e.* FROM exame e JOIN requisicao r ON e.idrequisicao = r.idrequisicao WHERE r.idremoto in (%s) ORDER BY r.idremoto';
  SQLBaseAmostra = 'SELECT a.* FROM amostra a JOIN requisicao r ON a.idrequisicao = r.idrequisicao WHERE r.idremoto in (%s) ORDER BY r.idremoto';
  SQLBaseExameAmostra = 'SELECT ea.* FROM exameamostra ea JOIN exame e ON ea.idexame = e.idexame WHERE e.idremoto in (%s) ORDER BY e.idremoto';

  SQLBaseLaudoRequisicao = 'SELECT lr.* FROM laudorequisicao lr JOIN requisicao r ON lr.idrequisicao = r.idrequisicao WHERE r.idremoto in (%s) ORDER BY r.idremoto';
  SQLBaseExameLaudoRequisicao = 'SELECT elr.* FROM examelaudorequisicao elr JOIN laudorequisicao lr ON elr.idlaudorequisicao = lr.idlaudorequisicao WHERE lr.idremoto in (%s) ORDER BY lr.idremoto';

  SQLBaseRequisicaoTaxaExtra = 'SELECT rte.* FROM requisicaotaxaextra rte JOIN requisicao r ON rte.idrequisicao = r.idrequisicao WHERE r.idremoto in (%s) ORDER BY r.idremoto';
  SQLBaseDadoAdicionalMovimento = 'SELECT dam.* FROM dadoadicionalmovimento dam JOIN requisicao r ON dam.idrequisicao = r.idrequisicao WHERE r.idremoto in (%s) ORDER BY r.idremoto';

  Separator = 'SEPARATOR';

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

procedure TSyncDiff.SetOnDiffRecord(const Value: TOnDiffRecord);
begin
  FOnDiffRecord := Value;
end;

procedure TSyncDiff.DoCompare;
begin
  Self.ComparePaciente;
  Self.CompareRequisicao;
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

function TSyncDiff.GetLogSeparator: string;
begin
  Result := StrUtils.DupeString('_', 50);
end;

procedure TSyncDiff.CompareMasterTable(const aTableName, aPkName, aSQLBase: string; out aIdRemotoList: string);
var
  _cds1, _cds2: TClientDataSet;
  _sql: string;
begin
  _sql := Format(aSQLBase, [SQLSincronizados]); //SQLBasePaciente
  _cds1 :=  FDiff1.GetDataFromSQL(_sql);
  _cds1.First;
  //primeiro coleta os ids
  aIdRemotoList := Self.GetIdRemotoList(_cds1);
  _sql := Format(SQLIdRemoto, [aIdRemotoList]);
  _sql := Format(aSQLBase, [_sql]);
  _cds2 := FDiff2.GetDataFromSQL(_sql);

  Self.Log(Separator, Self.GetLogSeparator);
  Self.Log(aTableName, 'Verificando...');
  if Self.CheckDiffs(_cds1, _cds2, aPkName, aTableName) then
    Self.Log(aTableName, 'Checagem efetuada sem erros');
end;

procedure TSyncDiff.CompareDetailTable(const aDetailTableName, aPKName, aMasterIdRemotoList, aSQLBase: string; out aDetailIdRemotoList: string);
var
  _cds1, _cds2: TClientDataSet;
  _sql: string;
begin
  _sql := Format(aSQLBase, [aMasterIdRemotoList]);
  _cds1 :=  FDiff1.GetDataFromSQL(_sql);
  aDetailIdRemotoList := Self.GetIdRemotoList(_cds1);
  _cds2 :=  FDiff2.GetDataFromSQL(_sql);
  Self.Log(Separator, Self.GetLogSeparator);
  Self.Log(aDetailTableName, 'Verificando...');
  if Self.CheckDiffs(_cds1, _cds2, aPKName, aDetailTableName) then
    Self.Log(aDetailTableName, 'Checagem efetuada sem erros');
end;

procedure TSyncDiff.ComparePaciente;
var
  _MasterIdRemoto, _DetailIdRemoto: string;
begin
  Self.CompareMasterTable('Paciente', 'IdPaciente', SQLBasePaciente, _MasterIdRemoto);
  Self.CompareDetailTable('DadoAdicionalPaciente', 'IdPaciente;IdDadoAdicionalPaciente', _MasterIdRemoto, SQLBaseDadoAdicionalPaciente, _DetailIdRemoto);
end;

procedure TSyncDiff.CompareRequisicao;
var
  _MasterIdRemoto, _DetailIdRemoto: string;
begin
  Self.CompareMasterTable('Requisicao', 'IdRequisicao', SQLBaseRequisicao, _MasteridRemoto);

  //Verificar exames
  Self.CompareDetailTable('Exame', 'IdRequisicao;IdExame', _MasterIdRemoto, SQLBaseExame, _DetailIdRemoto);

  //Verificar exameamostra a partir do exame
  Self.CompareDetailTable('ExameAmostra', 'IdExame;IdExameAmostra', _DetailIdRemoto, SQLBaseExameAmostra,  _DetailIdRemoto);

  //Verificar amostras
  Self.CompareDetailTable('Amostra', 'IdRequisicao;IdAmostra', _MasterIdRemoto, SQLBaseAmostra, _DetailIdRemoto);

  //Verificar exameamostra a partir da amostra
  Self.CompareDetailTable('ExameAmostra', 'IdExame;IdExameAmostra', _DetailIdRemoto, SQLBaseExameAmostra,  _DetailIdRemoto);

  //Verificar Laudo Requisicao
  Self.CompareDetailTable('LaudoRequisicao', 'IdRequisicao;IdLaudoRequisicao', _MasterIdRemoto, SQLBaseLaudoRequisicao, _DetailIdRemoto);

  //Verificar ExameLaudoRequisicao
  Self.CompareDetailTable('ExameLaudoRequisicao', 'IdLaudoRequisicao;IdExameLaudoRequisicao', _DetailIdRemoto, SQLBaseExameLaudoRequisicao,  _DetailIdRemoto);

  //Verificar Requisicao Taxa Extra
  Self.CompareDetailTable('RequisicaoTaxaExtra', 'IdRequisicao;IdRequisicaoTaxaExtra', _MasterIdRemoto, SQLBaseRequisicaoTaxaExtra, _DetailIdRemoto);

  //Verificar Dado adicional movimento
  Self.CompareDetailTable('DadoAdicionalMovimento', 'IdRequisicao;IdDadoAdicionalMovimento', _MasterIdRemoto, SQLBaseDadoAdicionalMovimento, _DetailIdRemoto);

end;

function TSyncDiff.CheckDiffs(aCds1, aCds2: TClientDataSet; const aPkName, aTableName: string): boolean;
var
  _Field: TField;
  _WhiteListFields: TStringList;
begin
  Result := True;
  if aCds1.RecordCount <> aCds2.RecordCount then
  begin
    Result := False;
    Self.Log(aTablename, Format('Banco1 diferente na quantidade de registros do Banco2. (%d / %d)',[aCds1.RecordCount, aCds2.RecordCount]));
  end;
  _WhiteListFields := TStringList.Create;
  try
    _WhiteListFields.Delimiter := ';';
    _WhiteListFields.DelimitedText := aPkName.ToUpper;
    _WhiteListFields.Add('VERSION_ID');
    aCds1.First;
    while not aCds1.Eof do
    begin
      if assigned(Self.FOnDiffRecord) then
        Self.FOnDiffRecord(aTableName, aCds1.RecordCount, aCds1.RecNo);
      //Verificar se o registro existe no banco 2
      if not aCds2.Locate('IdRemoto', aCds1.FieldByName('IdRemoto').asInteger, []) then
      begin
        Result := False;
        Self.Log(aTableName, Format('IdRemoto %s não encontrado', [aCds1.FieldByName('IdRemoto').AsString]))
      end
      else
      begin
        //Verificar campo a campo
        for _Field in aCds1.Fields do
        begin
          if (_WhiteListFields.IndexOf(_Field.FieldName.ToUpper) = -1) and
            (_Field.AsString <> aCds2.FieldByName(_Field.FieldName).AsString) then
            begin
              Result := False;
              Self.Log(aTableName, Format('IdRemoto: %d, Field "%s" com valor diferente. Banco1: "%s"; Banco2: "%s"',
                    [aCds1.FieldbyName('IdRemoto').asInteger,
                     _Field.FieldName,
                     _Field.AsString,
                     aCds2.FieldByName(_Field.FieldName).AsString]));
            end;
        end;
      end;
      aCds1.Next;
    end;
  finally
    _WhiteListFields.Free;
  end;
end;

end.
