unit SyncDiffUn;

interface

uses Datasnap.DBClient, Classes, SysUtils, DB, StrUtils, IdHTTP, OmniXML,
     DIntegradorModuloWebHS, System.Generics.Collections, DIntegradorModuloWeb;

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
    FHTTP: TIdHttp;
    FEnderecoHibrido: string;
    FAccessToken: string;
    FNumSerie: string;
    FVersaoExecutavel: string;
    procedure SetOnCompare(const Value: TOnCompare);
    procedure ComparePaciente;
    procedure Log(const aTableName, aDiff: string);
    function CheckDiffs(aCds1, aCds2: TClientDataSet;  const aPkName, aTableName: string): boolean;
    function GetIdRemotoList(aCds: TClientDataSet): string;
    procedure CompareRequisicao;
    procedure CompareMasterTableFromDB(const aTableName, aPkName, aSQLBase: string;
      out aIdRemotoList: string);
    procedure CompareDetailTableFromDB(const aDetailTableName, aPKName, aMasterIdRemotoList, aSQLBase: string; out aDetailIdRemotoList: string);
    procedure SetOnDiffRecord(const Value: TOnDiffRecord);
    function GetLogSeparator: string;
    function getXMLFromServer(const aURL: string;
      var aException: string): string;
    function getXMLDocument(const aURL: string): IXMLDocument;
    procedure SetFieldValue(aField: TField; var ValorCampo: string);
    procedure ConvertXMLToCds(aDataIntegrador: TDataIntegradorModuloWeb;
      aXMLDocument: IXMLDocument; aClientDataset: TClientDataSet);
    procedure GetSettings;
    procedure CompareDBWithCloud(
      aDataIntegradorClass: TDataIntegradorModuloWebHSClass);
    procedure TurnOffRequiredFields(aCds: TClientDataSet);
    procedure CompareCds1WithCds2(aDataIntegrador: TDataIntegradorModuloWeb; aClientDataSetBase: TClientDataSet; const aIdRemotoList: string);
  public
    constructor Create(aDiff1, aDiff2: ISQLDiff);
    destructor Destroy; override;
    procedure DoCompare;
    property OnCompare: TOnCompare read FOnCompare write SetOnCompare;
    property OnDiffRecord: TOnDiffRecord read FOnDiffRecord write SetOnDiffRecord;
  end;

const
  SQLParametros = 'SELECT p.EnderecoHibrido, p.AccessToken, l.NumSerie, p.VersaoExecutavel FROM PARAMETROSISTEMA p JOIN licenca l on 1=1';

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

  SQLBaseResultadoAtributo = 'SELECT FIRST %d * FROM ResultadoAtributo ';

  SQLBaseDB = 'SELECT FIRST %d * FROM %s ';

  Separator = 'SEPARATOR';

implementation

{ TSyncDiff }

uses UtilsUnit, SincronizaTabelasWebHCUn, acStrUtils;

constructor TSyncDiff.Create(aDiff1, aDiff2: ISQLDiff);
begin
  FDiff1 := aDiff1;
  FDiff2 := aDiff2;
  Self.FHTTP := UtilsUnit.GetIdHttp;
  Self.GetSettings;
end;

destructor TSyncDiff.Destroy;
begin
  Self.FHTTP.Free;
  inherited;
end;

procedure TSyncDiff.GetSettings;
var
  _cds: TClientDataSet;
begin
  _cds := Self.FDiff1.GetDataFromSQL(SQLParametros);
  try
    if not _cds.IsEmpty then
    begin
      FEnderecoHibrido := acStrUtils.simpleDecrypt(_cds.FieldByName('EnderecoHibrido').AsString);
      FAccessToken := _cds.FieldByName('AccessToken').AsString;
      FNumSerie := _cds.FieldByName('NumSerie').AsString;
      FVersaoExecutavel := _cds.FieldByName('VersaoExecutavel').AsString;
    end;
  finally
    _cds.Free;
  end;
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
  Self.Log(SEPARATOR, Self.GetLogSeparator);
  Self.Log(SEPARATOR, Self.GetLogSeparator + ' Comparando dados com Firebird e MYSQL ' + Self.GetLogSeparator);
  Self.CompareDBWithCloud(TCargoWebData);
  Self.CompareDBWithCloud(TUsuarioWebData);
  Self.CompareDBWithCloud(TReagenteWebData);
  Self.CompareDBWithCloud(TXfilterDefWebData);
  Self.CompareDBWithCloud(TXfilterDefDetailWebData);
  Self.CompareDBWithCloud(TRBFolderWebData);
  Self.CompareDBWithCloud(TRBItemWebData);
  Self.CompareDBWithCloud(TTipoRelatorioWebData);
  Self.CompareDBWithCloud(TRelatorioWebData);
  Self.CompareDBWithCloud(TTipoRecursoWebData);
  Self.CompareDBWithCloud(TDominioWebData);
  Self.CompareDBWithCloud(TRecursoWebData);
  Self.CompareDBWithCloud(TAcaoWebData);
  Self.CompareDBWithCloud(TPermissaoSistemaWebData);
  Self.CompareDBWithCloud(TGrupoWebData);
  Self.CompareDBWithCloud(TPermissaoSistemaGrupoWebData);
  Self.CompareDBWithCloud(TDireitoUsoWebData);
  Self.CompareDBWithCloud(TUsuarioRelatorioWebData);
  Self.CompareDBWithCloud(TGrupoUsuarioWebData);
  Self.CompareDBWithCloud(TTipoOperacaoCaixaWebData);
  Self.CompareDBWithCloud(TMaterialBiologicoWebData);
  Self.CompareDBWithCloud(TMaterialBiologicoCompostoWebData);
  Self.CompareDBWithCloud(TConservanteWebData);
  Self.CompareDBWithCloud(TEmpresaWebData);
  Self.CompareDBWithCloud(TGrupoLocalWebData);
  Self.CompareDBWithCloud(TLocalAtendimentoWebData);
  Self.CompareDBWithCloud(TTipoDadoAdicionalWebData);
  Self.CompareDBWithCloud(TFornecedorWebData);
  Self.CompareDBWithCloud(TTipoMaterialConsumoWebData);
  Self.CompareDBWithCloud(TMaterialConsumoWebData);
  Self.CompareDBWithCloud(TMetodoExameWebData);
  Self.CompareDBWithCloud(TRecomendacaoTecnicaWebData);
  Self.CompareDBWithCloud(TBancadaWebData);
  Self.CompareDBWithCloud(TDriverWebData);
  Self.CompareDBWithCloud(TTipoInstrumentoWebData);
  Self.CompareDBWithCloud(TMaterialTipoInstrumentoWebData);
  Self.CompareDBWithCloud(TLaboratorioWebData);
  Self.CompareDBWithCloud(TMarcacaoWebData);
  Self.CompareDBWithCloud(TTipoExameWebData);
  Self.CompareDBWithCloud(TTipoExameMaterialBiologicoWebData);
  Self.CompareDBWithCloud(TVersaoExameWebData);
  Self.CompareDBWithCloud(TVersaoExameLocalAtendimentoWebData);
  Self.CompareDBWithCloud(TDadoAdicionalVersaoExameWebData);
  Self.CompareDBWithCloud(TMaterialConsumoExameWebData);
  Self.CompareDBWithCloud(TParametroVersaoExameWebData);
  Self.CompareDBWithCloud(TAtributoExameWebData);
  Self.CompareDBWithCloud(TValoresReferenciaWebData);
  Self.CompareDBWithCloud(TAgrupamentoAmostraWebData);
  Self.CompareDBWithCloud(TVersaoAgrupamentoWebData);
  Self.CompareDBWithCloud(TResultadoPadraoWebData);
  Self.CompareDBWithCloud(TPerfilWebData);
  Self.CompareDBWithCloud(TObservacaoResultadoWebData);
  Self.CompareDBWithCloud(TPrioridadeColetaWebData);
  Self.CompareDBWithCloud(TTipoInstrumentoFlagWebData);
  Self.CompareDBWithCloud(TAntibioticoWebData);
  Self.CompareDBWithCloud(TExameTipoInstrumentoWebData);
  Self.CompareDBWithCloud(TAtributoExameTipoInstrumentoWebData);
  Self.CompareDBWithCloud(TComposicaoExameWebData);
  Self.CompareDBWithCloud(TInstrumentoWebData);
  Self.CompareDBWithCloud(TExameTipoInstrumentoFlagWebData);
  Self.CompareDBWithCloud(TPeriodoIndicadorWebData);
  Self.CompareDBWithCloud(TIndicadorLocalAtendimentoWebData);
  Self.CompareDBWithCloud(TLocalIndicadorlocalWebData);
  Self.CompareDBWithCloud(TPeriodoIndicadorLocalWebData);
  Self.CompareDBWithCloud(TParametroLaboratorioWebData);
  Self.CompareDBWithCloud(TPorteProcedimentoWebData);
  Self.CompareDBWithCloud(THonorarioWebData);
  Self.CompareDBWithCloud(TTipoParasitaWebData);
  Self.CompareDBWithCloud(TProcedimentoMedicoWebData);
  Self.CompareDBWithCloud(THonorarioExameWebData);
  Self.CompareDBWithCloud(TParasitaWebData);
  Self.CompareDBWithCloud(TGermeWebData);
  Self.CompareDBWithCloud(TApoiadoWebData);
  Self.CompareDBWithCloud(TArquivoEnvioWebData);
  Self.CompareDBWithCloud(TArquivoRecebimentoWebData);
  Self.CompareDBWithCloud(TColetorWebData);
  //Self.CompareDBWithCloud(TResponsavelTecnicoWebData);
  Self.CompareDBWithCloud(TTipoLaudoWebData);
  Self.CompareDBWithCloud(TRelatorioTipoLaudoWebData);
  Self.CompareDBWithCloud(TEspecialidadeWebData);
  Self.CompareDBWithCloud(TOperadoraWebData);
  Self.CompareDBWithCloud(TConvenioWebData);
  //Self.CompareDBWithCloud(TConvenioIntegracaoWebData);
  Self.CompareDBWithCloud(TParametroConvenioWebData);
  Self.CompareDBWithCloud(TEstabelecimentoSaudeWebData);
  Self.CompareDBWithCloud(TConvenioEstabelecimentoSaudeWebData);
  Self.CompareDBWithCloud(TMedicoWebData);
  Self.CompareDBWithCloud(TCredencialWebData);
  Self.CompareDBWithCloud(TTipoLaudoMedicoWebData);
  Self.CompareDBWithCloud(TMedicoApoiadoWebData);
  Self.CompareDBWithCloud(TPacienteWebData);
  Self.CompareDBWithCloud(TPacienteApoiadoWebData);
  Self.CompareDBWithCloud(TDadoAdicionalPacienteWebData);
  Self.CompareDBWithCloud(TConfiguracaoGestaoLaudoWebData);
  Self.CompareDBWithCloud(TLaudosGestaoLaudoWebData);
  Self.CompareDBWithCloud(TContratoConvenioWebData);
  Self.CompareDBWithCloud(TContratoValorIndividualWebData);
  Self.CompareDBWithCloud(TParametroContratoConvenioWebData);
  Self.CompareDBWithCloud(TTaxaExtraWebData);
  Self.CompareDBWithCloud(TAntibioticoTipoInstrumentoWebData);
  Self.CompareDBWithCloud(TConfiguracaoIpeWebData);
  Self.CompareDBWithCloud(TGermeTipoInstrumentoWebData);
  Self.CompareDBWithCloud(TCompExameApoiadoWebData);
  Self.CompareDBWithCloud(TCompAtributoApoiadoWebData);
  Self.CompareDBWithCloud(TOperadoraTelefoniaWebData);
  Self.CompareDBWithCloud(TCompConvenioApoiadoWebData);
  Self.CompareDBWithCloud(TCompDadoAdicionalApoiadoWebData);
  Self.CompareDBWithCloud(TCompLocalApoiadoWebData);
  Self.CompareDBWithCloud(TCompMaterialApoiadoWebData);
  Self.CompareDBWithCloud(TUnidadeMedidaWebData);
  Self.CompareDBWithCloud(TIndicadorMarcacaoWebData);
  Self.CompareDBWithCloud(TMarcacaoIndicadorMarcacaoWebData);
  Self.CompareDBWithCloud(TExameRelacionadoWebData);
  Self.CompareDBWithCloud(TCaixaWebData);
  Self.CompareDBWithCloud(TRequisicaoApoiadoWebData);
  Self.CompareDBWithCloud(TLoteFaturaWebData);
  Self.CompareDBWithCloud(TFaturaWebData);
  Self.CompareDBWithCloud(TLoteAmostrasWebData);
  Self.CompareDBWithCloud(TRequisicaoWebData); //requisicao, exame, amostra, exameamostra, laudorequisicao, examelaudorequisicao
  Self.CompareDBWithCloud(TAmostraReplicadaWebData);
  Self.CompareDBWithCloud(TExameLaudoRequisicaoWebData);
  Self.CompareDBWithCloud(TExameAmostraWebData);
  Self.CompareDBWithCloud(TResultadoGermeWebData);
  Self.CompareDBWithCloud(TResultadoAtributoWebData);
  Self.CompareDBWithCloud(TResultadoMicrobiologiaWebData);
  Self.CompareDBWithCloud(TResultadoParasitologiaWebData);
  Self.CompareDBWithCloud(TDadoAdicionalMovimentoWebData);
  Self.CompareDBWithCloud(TDadoAdicionalMovimentoExameWebData);
  Self.CompareDBWithCloud(TMovimentoCaixaWebData);
  Self.CompareDBWithCloud(TRequisicaoTaxaExtraWebData);
  Self.CompareDBWithCloud(TCancelamentoApoiadoWebData);
  Self.CompareDBWithCloud(TReciboWebData);
  Self.CompareDBWithCloud(TLoteLaudoWebData);
  Self.CompareDBWithCloud(TExameFlagWebData);
  Self.CompareDBWithCloud(TBandejaWebData);  //bandeja, bandejaamostra
  Self.CompareDBWithCloud(THistoricoInstrumentoWebData);
  Self.CompareDBWithCloud(THistoricoImagemInstrumentoWebData);
  Self.CompareDBWithCloud(THistoricoResultadoWebData);
  Self.CompareDBWithCloud(TOrcamentoWebData);
  Self.CompareDBWithCloud(TDadoAdicionalMovimentoExameWebData);
  Self.CompareDBWithCloud(TExameLoteLaudoWebData);
  Self.CompareDBWithCloud(TDadoAdicionalApoiadoWebData);
  Self.CompareDBWithCloud(TParametroUsuarioWebData);
  Self.CompareDBWithCloud(TAtualizaLaudoPublicador);
  Self.CompareDBWithCloud(TAtualizaExamePublicador);
  Self.CompareDBWithCloud(TPendenciaExameLaudoWebData);
  Self.Log(SEPARATOR, Self.GetLogSeparator);
  Self.Log(SEPARATOR, 'Fim da verificação');
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

procedure TSyncDiff.CompareMasterTableFromDB(const aTableName, aPkName, aSQLBase: string; out aIdRemotoList: string);
var
  _cds1, _cds2: TClientDataSet;
  _sql: string;
begin
  _sql := Format(aSQLBase, [SQLSincronizados]);
  _cds1 :=  FDiff1.GetDataFromSQL(_sql);
  try
    _cds1.First;
    //primeiro coleta os ids
    aIdRemotoList := Self.GetIdRemotoList(_cds1);
    _sql := Format(SQLIdRemoto, [aIdRemotoList]);
    _sql := Format(aSQLBase, [_sql]);
    _cds2 := FDiff2.GetDataFromSQL(_sql);
    try
      Self.Log(Separator, Self.GetLogSeparator);
      Self.Log(aTableName, 'Verificando...');
      if Self.CheckDiffs(_cds1, _cds2, aPkName, aTableName) then
        Self.Log(aTableName, 'Checagem efetuada sem erros');
    finally
      _cds2.Free;
    end;
  finally
    _cds1.Free;
  end;
end;

procedure TSyncDiff.CompareDetailTableFromDB(const aDetailTableName, aPKName, aMasterIdRemotoList, aSQLBase: string; out aDetailIdRemotoList: string);
var
  _cds1, _cds2: TClientDataSet;
  _sql: string;
begin
  _sql := Format(aSQLBase, [aMasterIdRemotoList]);
  _cds1 :=  FDiff1.GetDataFromSQL(_sql);
  try
    aDetailIdRemotoList := Self.GetIdRemotoList(_cds1);
    _cds2 :=  FDiff2.GetDataFromSQL(_sql);
    try
      Self.Log(Separator, Self.GetLogSeparator);
      Self.Log(aDetailTableName, 'Verificando...');
      if Self.CheckDiffs(_cds1, _cds2, aPKName, aDetailTableName) then
        Self.Log(aDetailTableName, 'Checagem efetuada sem erros');
    finally
      _cds2.Free;
    end;
  finally
    _cds1.Free;
  end;
end;

procedure TSyncDiff.ComparePaciente;
var
  _MasterIdRemoto, _DetailIdRemoto: string;
begin
  Self.CompareMasterTableFromDB('Paciente', 'IdPaciente', SQLBasePaciente, _MasterIdRemoto);
  Self.CompareDetailTableFromDB('DadoAdicionalPaciente', 'IdPaciente;IdDadoAdicionalPaciente', _MasterIdRemoto, SQLBaseDadoAdicionalPaciente, _DetailIdRemoto);
end;

procedure TSyncDiff.CompareRequisicao;
var
  _MasterIdRemoto, _DetailIdRemoto: string;
begin
  Self.CompareMasterTableFromDB('Requisicao', 'IdRequisicao', SQLBaseRequisicao, _MasteridRemoto);

  //Verificar exames
  Self.CompareDetailTableFromDB('Exame', 'IdRequisicao;IdExame', _MasterIdRemoto, SQLBaseExame, _DetailIdRemoto);

  //Verificar exameamostra a partir do exame
  Self.CompareDetailTableFromDB('ExameAmostra', 'IdExame;IdExameAmostra', _DetailIdRemoto, SQLBaseExameAmostra,  _DetailIdRemoto);

  //Verificar amostras
  Self.CompareDetailTableFromDB('Amostra', 'IdRequisicao;IdAmostra', _MasterIdRemoto, SQLBaseAmostra, _DetailIdRemoto);

  //Verificar exameamostra a partir da amostra
  Self.CompareDetailTableFromDB('ExameAmostra', 'IdExame;IdExameAmostra', _DetailIdRemoto, SQLBaseExameAmostra,  _DetailIdRemoto);

  //Verificar Laudo Requisicao
  Self.CompareDetailTableFromDB('LaudoRequisicao', 'IdRequisicao;IdLaudoRequisicao', _MasterIdRemoto, SQLBaseLaudoRequisicao, _DetailIdRemoto);

  //Verificar ExameLaudoRequisicao
  Self.CompareDetailTableFromDB('ExameLaudoRequisicao', 'IdLaudoRequisicao;IdExameLaudoRequisicao', _DetailIdRemoto, SQLBaseExameLaudoRequisicao,  _DetailIdRemoto);

  //Verificar Requisicao Taxa Extra
  Self.CompareDetailTableFromDB('RequisicaoTaxaExtra', 'IdRequisicao;IdRequisicaoTaxaExtra', _MasterIdRemoto, SQLBaseRequisicaoTaxaExtra, _DetailIdRemoto);

  //Verificar Dado adicional movimento
  Self.CompareDetailTableFromDB('DadoAdicionalMovimento', 'IdRequisicao;IdDadoAdicionalMovimento', _MasterIdRemoto, SQLBaseDadoAdicionalMovimento, _DetailIdRemoto);
end;

procedure TSyncDiff.SetFieldValue(aField:TField; var ValorCampo: string);
var
  lFormatSettings: TFormatSettings;
begin
  if aField <> nil then
  begin
    case aField.DataType of
      ftString, ftMemo: aField.AsString := ValorCampo;
      ftInteger: aField.AsInteger := StrToInt(ValorCampo);
      ftLargeint: aField.AsLargeInt := StrToInt(ValorCampo);
      ftDate, ftDateTime, ftTimeStamp:
        begin
          lFormatSettings.DateSeparator := '-';
          lFormatSettings.TimeSeparator := ':';
          lFormatSettings.ShortDateFormat := 'yyyy-MM-ddThh:mm:ssZ'; //'dd/MM/yyyy hh:mm:ss';
          aField.AsDateTime := StrToDateTime(ValorCampo, lFormatSettings);
        end;
      ftCurrency, ftTime:
        begin
          ValorCampo := StringReplace(ValorCampo, '''','', [rfReplaceAll]);
          aField.AsCurrency := StrToCurr(ValorCampo);
        end;
      ftSingle, ftFloat, ftFMTBcd:
      begin
        ValorCampo := StringReplace(ValorCampo, '.', ',',[rfReplaceAll]);
        ValorCampo := StringReplace(ValorCampo, '''','', [rfReplaceAll]);
        aField.AsFloat := StrToFloat(ValorCampo);
      end;
      ftBlob:
      begin
        TBlobField(aField).LoadFromStream(UtilsUnit.BinaryFromBase64(ValorCampo));
      end
    else
      aField.AsString := ValorCampo;
    end;
  end;
end;

procedure TSyncDiff.ConvertXMLToCds(aDataIntegrador: TDataIntegradorModuloWeb; aXMLDocument: IXMLDocument; aClientDataset: TClientDataSet);
var
  _list: IXMLNodeList;
  _i, _j: integer;
  _node: IXMLNode;
  _FieldName : string;
  _count: integer;
  _field: TField;
  _fieldValue: string;
begin
  _list := aXMLDocument.selectNodes('/objects/*');
  _count := _list.length;
  for _i := 0 to _count -1 do
  begin
    aClientDataset.Append;
    _node := _list.item[_i];
    for _j := 0 to _node.ChildNodes.Length - 1  do
    begin
      _FieldName := aDataIntegrador.translations.translateServerToPDV(_node.ChildNodes.Item[_j].NodeName, False);
      _field := aClientDataset.FindField(_FieldName);
      if (not _FieldName.IsEmpty) and (_field <> nil) and (_node.ChildNodes.Item[_j].Text <> EmptyStr) then
      begin
        _fieldValue := _node.ChildNodes.Item[_j].Text;
        Self.SetFieldValue(_Field, _fieldValue);
      end;
    end;
    try
      aClientDataset.Post;
    except
      on E: Exception do
      begin
        aClientDataset.Cancel;
        Self.Log(aDataIntegrador.nomeTabela, E.Message);
      end;
    end;
  end;
end;

procedure TSyncDiff.TurnOffRequiredFields(aCds: TClientDataSet);
var
  _i: integer;
begin
  for _i := 0 to aCds.Fields.Count - 1 do
  begin
    aCds.Fields[_i].Required := False;
    aCds.Fields[_i].ProviderFlags := [];
  end;
end;


procedure TSyncDiff.CompareCds1WithCds2(aDataIntegrador: TDataIntegradorModuloWeb; aClientDataSetBase: TClientDataSet; const aIdRemotoList: string);
var
  _sql, _url: string;
  _cds2: TClientDataSet;
  _xml: IXMLDocument;
begin
  //pega somente a estrutura
  _sql := Format(SQLBaseDB, [0, aDataIntegrador.nomeTabela]);
  _cds2 := Self.FDiff2.GetDataFromSQL(_sql);
  try
    Self.TurnOffRequiredFields(_cds2);

    _url := Self.FEnderecoHibrido + aDataIntegrador.nomePlural + '.xml?serie='+ FNumSerie + '&access_token=' + Self.FAccessToken + '&idlist=' + aIdRemotoList;
    _xml := Self.getXMLDocument(_url);
    if _xml <> nil then
      Self.ConvertXMLToCds(aDataIntegrador, _xml, _cds2);
    if Self.CheckDiffs(aClientDataSetBase, _cds2, aDataIntegrador.nomePKLocal + ';SalvouRetaguarda', aDataIntegrador.nomeTabela) then
      Self.Log(aDataIntegrador.nomeTabela, 'Checagem efetuada sem erros');
  finally
    _cds2.Free;
  end;
end;


procedure TSyncDiff.CompareDBWithCloud(aDataIntegradorClass: TDataIntegradorModuloWebHSClass);
var
  _DataWeb: TDataIntegradorModuloWeb;
  _cds1, _cdsDetailLocal: TClientDataSet;
  _sql, _IdRemotoMasterList, _IdRemotoDetailsList: string;
  _detail: TTabelaDetalhe;
begin
  Self.Log(Separator, Self.GetLogSeparator);
  _DataWeb := aDataIntegradorClass.Create(nil);
  try
    Self.Log(_DataWeb.nomeTabela , 'Verificando...');

    _sql := Format(SQLBaseDB, [50, _DataWeb.nomeTabela]);
    _sql := _sql + 'WHERE (1=1) ' + SQLSincronizados;
    _cds1 := FDiff2.GetDataFromSQL(_sql);
    try
      _IdRemotoMasterList := Self.GetIdRemotoList(_cds1);
      Self.CompareCds1WithCds2(_DataWeb, _cds1, _IdRemotoMasterList);
    finally
      _cds1.Free;
    end;

    for _detail in _DataWeb.tabelasDetalhe do
    begin
      _sql := Format('SELECT detail.* FROM %s detail JOIN %s master ON detail.%s = master.%s WHERE master.idremoto IN (%s)',
                                    [_detail.nomeTabela, _DataWeb.nomeTabela, _DataWeb.nomePKLocal, _DataWeb.nomePKLocal, _IdRemotoMasterList]);
      _cdsDetailLocal := FDiff2.GetDataFromSQL(_sql);
      try
        _IdRemotoDetailsList := Self.GetIdRemotoList(_cdsDetailLocal);
        Self.Log(Separator, '>>>> Verificando detalhe: ' + _detail.nomeTabela);
        Self.CompareCds1WithCds2(_detail, _cdsDetailLocal, _IdRemotoMasterList);
      finally
        _cdsDetailLocal.Free;
      end;
    end;

  finally
    _DataWeb.Free;
  end;
end;

function TSyncDiff.getXMLFromServer(const aURL: string; var aException: string): string;
var
  _Response: TStringStream;
begin
  aException := EmptyStr;
  _Response := TStringStream.Create(EmptyStr, TEncoding.UTF8);
  try
    try
      Self.FHTTP.Get(aURL, _Response);
      if FHTTP.ResponseCode = 204 then
        Result := EmptyStr
      else
        Result := _Response.DataString;
      _Response.SaveToFile(ExtractFilePath(ParamStr(0)) + '/response.xml');
      FHTTP.Disconnect;
    except
      aException := UtilsUnit.HandleException(aURL);
    end;
  finally
    FreeAndNil(_Response);
  end;
end;

function TSyncDiff.getXMLDocument(const aURL: string): IXMLDocument;
var
  _xmlContent, _Exception: string;
begin
  Result := nil;
  _xmlContent := Self.getXMLFromServer(aURL, _Exception);
  if not _xmlContent.IsEmpty then
  begin
    Result := OmniXML.CreateXMLDoc;
    Result.PreserveWhiteSpace := False;
    Result.load(ExtractFilePath(ParamStr(0)) + '/response.xml');
    Result.Save(ExtractFilePath(ParamStr(0)) + '/response.xml', ofIndent);
  end
  else
    Self.Log('', _Exception);
end;

function TSyncDiff.CheckDiffs(aCds1, aCds2: TClientDataSet; const aPkName, aTableName: string): boolean;
var
  _Field: TField;
  _WhiteListFields: TStringList;
  _LogList: TStringList;
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
        _LogList := TStringList.Create;
        try
          //Verificar campo a campo
          for _Field in aCds1.Fields do
          begin
            if (_WhiteListFields.IndexOf(_Field.FieldName.ToUpper) = -1) and
              (_Field.AsString <> aCds2.FieldByName(_Field.FieldName).AsString) then
              begin
                Result := False;
                _LogList.Add(Format('Field "%s" com valor diferente. Banco1: "%s"; Banco2: "%s"',
                  [_Field.FieldName,
                   _Field.AsString,
                   aCds2.FieldByName(_Field.FieldName).AsString]));
              end;
          end;

          if (not Result) and (_LogList.Count > 0) then
            Self.Log(aTableName,Format('IdRemoto: %d, %s', [aCds1.FieldbyName('IdRemoto').asInteger,
              StringReplace(_LogList.Text, #13#10, EmptyStr, [rfReplaceAll])]));
        finally
          _LogList.Free;
        end;
      end;
      aCds1.Next;
    end;
  finally
    _WhiteListFields.Free;
  end;
end;

end.
