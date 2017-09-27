unit DIntegradorModuloWeb;

interface

uses
  SysUtils, ExtCtrls, DBClient, idHTTP, MSXML2_TLB, dialogs, acStrUtils, acNetUtils,
  DB, IdMultipartFormData, IdBaseComponent, IdComponent, IdTCPConnection,
  IdTCPClient, IdCoder, IdCoder3to4, IdCoderUUE, IdCoderXXE, Controls,
  IDataPrincipalUnit, idURI, System.Classes, Windows, UtilsUnit,
  ISincronizacaoNotifierUnit, Data.SqlExpr, System.ZLib, System.IOUtils, Xml.xmldom,
  Xml.XMLIntf, Xml.Win.msxmldom, Xml.XMLDoc,ActiveX, DLog, DLLInterfaceUn,
  {$IFDEF VER250}IBCustomDataSet, IBQuery{$ENDIF}{$IFDEF VER320}IBX.IBCustomDataSet, IBX.IBQuery {$ENDIF};

type
  EIntegradorException = class(Exception)
  end;

  TNameTranslation = record
    server: string;
    pdv: string;
    lookupRemoteTable: string;
    fkName: string;
  end;

  TTranslationSet = class
    protected
      translations: array of TNameTranslation;
    public
      constructor create(owner: TComponent);
      procedure add(serverName, pdvName: string; lookupRemoteTable: string = ''; fkName: string = '');
      function translateServerToPDV(serverName: string; duasVias: boolean): string;
      function translatePDVToServer(pdvName: string): string;
      function size: integer;
      function get(index: integer): TNameTranslation;
  end;

  TTabelaDependente = record
    nomeTabela: string;
    nomeFK: string;
  end;

  TTabelaDetalhe = class
  public
    nomeTabela: string;
    nomeFK: string;
    nomePK: string;
    nomeParametro: string;
    nomeSingularDetalhe : string;
    nomePluralDetalhe : string;
    tabelasDetalhe: array of TTabelaDetalhe;
    translations: TTranslationSet;
    constructor create;
  end;

  TDataIntegradorModuloWeb = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
  private
    FdmPrincipal: IDataPrincipal;
    Fnotifier: ISincronizacaoNotifier;
    FDataLog: TDataLog;
    procedure SetdmPrincipal(const Value: IDataPrincipal);
    function getdmPrincipal: IDataPrincipal;

    procedure addTabelaDetalheParams(valorPK: integer;
      params: TStringList;
      tabelaDetalhe: TTabelaDetalhe);
    procedure UpdateRecordDetalhe(pNode: IXMLDomNode; pTabelasDetalhe : array of TTabelaDetalhe);
    function GetErrorMessage(const aXML: string): string;
    procedure SetDataLog(const Value: TDataLog);
    procedure Log(const aLog, aClasse: string);
  protected
    nomeTabela: string;
    nomeSingular: string;
    nomePlural: string;
    nomePKLocal: string;
    nomePKRemoto: string;
    nomeGenerator: string;
    duasVias: boolean;
    useMultipartParams: boolean;
    clientToServer: boolean;
    tabelasDependentes: array of TTabelaDependente;
    tabelasDetalhe: array of TTabelaDetalhe;
    offset: integer;
    zippedPost: boolean;
    FEnderecoIntegrador: string;
    function extraGetUrlParams: String; virtual;
    procedure beforeRedirectRecord(idAntigo, idNovo: integer); virtual;
    function ultimaVersao: integer;
    function getRequestUrlForAction(toSave: boolean; versao: integer = -1): string;
    procedure importRecord(node: IXMLDomNode);
    procedure insertRecord(node: IXMLDomNode);
    procedure updateRecord(node: IXMLDomNode; id: integer);
    function jaExiste(id: integer): boolean;
    function getFieldList(node: IXMLDomNode): string;
    function getFieldUpdateList(node: IXMLDomNode): string;
    function getFieldValues(node: IXMLDomNode): string;
    function translateFieldValue(node: IXMLDomNode): string; virtual;
    function translateFieldNamePdvToServer(node: IXMLDomNode): string;
    function translateFieldNameServerToPdv(node: IXMLDomNode): string; virtual;
    function translateTypeValue(fieldType, fieldValue: string): string;
    function translateValueToServer(translation: TNameTranslation;
      fieldName: string; field: TField;
      nestedAttribute: string = '';
      fkName: string = ''): string; virtual;
    function translateValueFromServer(fieldName, value: string): string; virtual;
    procedure duplicarRegistroSemOffset(ds: TDataSet);
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
      params: TStringList;
      multipartParams: TIdMultiPartFormDataStream); virtual; abstract;
    function singleton: boolean;
    function getUpdateBaseSQL(node: IXMLDOMNode): string;
    procedure addDetails(ds: TDataSet; params: TStringList);
    function addTranslatedParams(ds: TDataSet;
      params: TStringList;
      translations: TTranslationSet; nestedAttribute: string = ''): IXMLDomDocument2;
    function getAdditionalSaveConditions: string; virtual;
    procedure beforeUpdateRecord(id: integer); virtual;
    function gerenciaRedirecionamentos(idLocal, idRemoto: integer): boolean; virtual;
    function getNewDataPrincipal: IDataPrincipal; virtual; abstract;
    function maxRecords: integer; virtual;
    function getHumanReadableName: string; virtual;
  public
    translations: TTranslationSet;
    verbose: boolean;
    property notifier: ISincronizacaoNotifier read Fnotifier write Fnotifier;
    property dmPrincipal: IDataPrincipal read getdmPrincipal write SetdmPrincipal;
    function buildRequestURL(nomeRecurso: string; params: string = ''): string; virtual; abstract;
    function getDadosAtualizados: TClientDataset;
    function saveRecordToRemote(ds: TDataSet; var salvou: boolean): IXMLDomDocument2;
    procedure migrateTableToRemote(where: string = '');
    procedure migrateSingletonTableToRemote;
    property DataLog: TDataLog read FDataLog write SetDataLog;
    procedure postRecordsToRemote(aDLL: IDLLInterface);
    class procedure updateDataSets; virtual;
    procedure SetEnderecoIntegrador(const aEnderecoIntegrador: string);
    destructor Destroy; override;
  end;

  TDataIntegradorModuloWebClass = class of TDataIntegradorModuloWeb;

var
  DataIntegradorModuloWeb: TDataIntegradorModuloWeb;

implementation

uses ComObj;

{$R *.dfm}

function TDataIntegradorModuloWeb.extraGetUrlParams: String;
begin
  result := '';
end;

function TDataIntegradorModuloWeb.getDadosAtualizados: TClientDataset;
var
  url, xmlContent: string;
  doc: IXMLDomDocument2;
  list : IXMLDomNodeList;
  i, numRegistros: integer;
  node : IXMLDomNode;
  keepImporting: boolean;
begin
  keepImporting := true;
  while keepImporting do
  begin
    url := getRequestUrlForAction(false, ultimaVersao) + extraGetUrlParams;
    notifier.setCustomMessage('Buscando ' + getHumanReadableName + '...');
    numRegistros := 0;
    xmlContent := getRemoteXmlContent(url);

    if trim(xmlContent) <> '' then
    begin
      doc := CoDOMDocument60.Create;
      doc.loadXML(xmlContent);
      list := doc.selectNodes('/' + dasherize(nomePlural) + '//' + dasherize(nomeSingular));
      numRegistros := list.length;
      notifier.setCustomMessage(IntToStr(numRegistros) + ' novos');
      for i := 0 to numRegistros-1 do
      begin
        notifier.setCustomMessage('Importando ' + getHumanReadableName + ': ' + IntToStr(i+1) +
          '/' + IntToStr(numRegistros));
        node := list.item[i];
        if node<>nil then
          importRecord(node);
      end;
    end;
    keepImporting := (maxRecords > 0) and (numRegistros >= maxRecords);
  end;
end;

function TDataIntegradorModuloWeb.getHumanReadableName: string;
begin
  result := ClassName;
end;

function TDataIntegradorModuloWeb.maxRecords: integer;
begin
  result := 0;
end;

procedure TDataIntegradorModuloWeb.importRecord(node : IXMLDomNode);
var
  id: integer;
begin
  if not singleton then
  begin
    id := strToInt(node.selectSingleNode(dasherize(nomePKRemoto)).text);
    dmPrincipal.startTransaction;
    try
      if jaExiste(id) then
        updateRecord(node, id)
      else
        insertRecord(node);
      dmPrincipal.commit;
    except
      dmPrincipal.rollBack;
    end;
  end
  else
    updateSingletonRecord(node);
end;

function TDataIntegradorModuloWeb.singleton: boolean;
begin
  result := (nomePKLocal = '') and (nomePKRemoto = '');
end;

function TDataIntegradorModuloWeb.jaExiste(id: integer): boolean;
var
  qry: string;
begin
  if duasVias then
    qry := 'SELECT count(1) FROM ' + nomeTabela + ' where idRemoto = ' + IntToStr(id)
  else
    qry := 'SELECT count(1) FROM ' + nomeTabela + ' where ' + nomePKLocal + ' = ' + IntToStr(id);
  result := dmPrincipal.getSQLIntegerResult(qry) > 0;
end;

procedure TDataIntegradorModuloWeb.beforeUpdateRecord(id: integer);
begin

end;

procedure TDataIntegradorModuloWeb.updateRecord(node: IXMLDomNode; id: integer);
begin
  beforeUpdateRecord(id);
  if duasVias then
    dmPrincipal.execSQL(getUpdateBaseSQL(node) + ' WHERE idRemoto = ' + IntToStr(id), 3)
  else
    dmPrincipal.execSQL(getUpdateBaseSQL(node) + ' WHERE ' + nomePKLocal + ' = ' + IntToStr(id), 3);
end;

procedure TDataIntegradorModuloWeb.UpdateRecordDetalhe(pNode: IXMLDomNode; pTabelasDetalhe : array of TTabelaDetalhe);
var 
   i,j : integer;
   vNode : IXMLDomNode;
   vNodeList, List: IXMLDOMNodeList;
   vIdRemoto, vPkLocal : String;   
   vNomePlural, vNomeSingular, no : string;
begin                                                   
  try
    for i := low(pTabelasDetalhe) to high(pTabelasDetalhe) do
    begin
      vNomePlural := pTabelasDetalhe[i].nomePluralDetalhe;
      vNomeSingular := pTabelasDetalhe[i].nomeSingularDetalhe;

      if VNomePlural = EmptyStr then
        raise EIntegradorException.CreateFmt('Tabela detalhe da Classe %s não possui configuração de NomePluralDetalhe',[Self.ClassName]);

      if vNomeSingular = EmptyStr then
        raise EIntegradorException.CreateFmt('Tabela detalhe da Classe %s não possui configuração de NomeSingularDetalhe',[Self.ClassName]);

      vNode := pNode.selectSingleNode('./' + dasherize(vNomePlural));
      vNodeList := vNode.selectNodes('./' + dasherize(vNomeSingular));
         
      for j := 0 to vNodeList.length - 1 do
      begin
        vIdRemoto := vNodeList[j].selectSingleNode('./id').text;  
        vPkLocal := vNodeList[j].selectSingleNode('./original-id').text;  

        if duasVias then        
          dmPrincipal.execSQL('UPDATE ' + pTabelasDetalhe[i].nomeTabela + ' SET salvouRetaguarda = ' + 
                          QuotedStr('S') + ', idRemoto = ' + vIdRemoto + 
                          ' WHERE salvouRetaguarda = ''N'' and ' + pTabelasDetalhe[i].nomePK + ' = ' + vPkLocal) ;        
      end;     
      if Length(pTabelasDetalhe[i].tabelasDetalhe) > 0 then
         Self.UpdateRecordDetalhe(vNode, pTabelasDetalhe[i].tabelasDetalhe);
    end;
  except
    raise;
  end;
end;

procedure TDataIntegradorModuloWeb.updateSingletonRecord(node: IXMLDOMNode);
begin
  if dmPrincipal.getSQLIntegerResult('SELECT count(1) from ' + nomeTabela) < 1 then
    dmPrincipal.execSQL('Insert into ' + nomeTabela + ' DEFAULT VALUES');
  dmPrincipal.execSQL(getUpdateBaseSQL(node));
end;

function TDataIntegradorModuloWeb.getUpdateBaseSQL(node: IXMLDOMNode): string;
begin
  result := 'UPDATE ' + nomeTabela + getFieldUpdateList(node);
end;

procedure TDataIntegradorModuloWeb.insertRecord(node: IXMLDomNode);
begin
  dmPrincipal.execSQL('INSERT INTO ' + nomeTabela + getFieldList(node) + ' values ' + getFieldValues(node));
end;

function TDataIntegradorModuloWeb.getFieldList(node: IXMLDomNode): string;
var
  i: integer;
  name: string;
begin
  result := '(';
  if duasVias and (nomeGenerator <> '') then
    result := result + nomePKLocal + ', ';
  if duasVias then
    result := result + 'salvouRetaguarda, ';
  for i := 0 to node.childNodes.length - 1 do
  begin
    name := translateFieldNameServerToPdv(node.childNodes.item[i]);
    if name <> '*' then
      result := result + name + ', ';
  end;
  result := copy(result, 0, length(result)-2);
  result := result + getFieldAdditionalList(node);
  result := result + ')';
end;

function TDataIntegradorModuloWeb.getFieldValues(node: IXMLDomNode): string;
var
  i: integer;
  name: string;
begin
  result := '(';
  if duasVias and (nomeGenerator <> '') then
    result := result + 'gen_id(' + nomeGenerator + ',1), ';
  if duasVias then
    result := result + QuotedStr('S') + ', ';
  for i := 0 to node.childNodes.length - 1 do
  begin
    name := translateFieldNameServerToPdv(node.childNodes.item[i]);
    if name <> '*' then
      result := result + translateFieldValue(node.childNodes.item[i]) + ', ';
  end;
  result := copy(result, 0, length(result)-2);
  result := result + getFieldAdditionalValues(node);
  result := result + ')';
end;

function TDataIntegradorModuloWeb.getFieldUpdateList(node: IXMLDomNode): string;
var
  i: integer;
  name: string;
begin
  result := ' set ';
  for i := 0 to node.childNodes.length - 1 do
  begin
    name := translateFieldNameServerToPdv(node.childNodes.item[i]);
    if name <> '*' then
      result := result + ' ' + translateFieldNameServerToPdv(node.childNodes.item[i]) + ' = ' +
        translateFieldValue(node.childNodes.item[i]) + ', ';
  end;
  result := copy(result, 0, length(result)-2);
  result := result + getFieldAdditionalUpdateList(node);
end;

function TDataIntegradorModuloWeb.getRequestUrlForAction(toSave: boolean; versao: integer = -1): string;
var
  nomeRecurso: string;
begin
  if toSave then
    nomeRecurso := nomeActionSave
  else
    nomeRecurso := nomeActionGet;
  result := buildRequestURL(nomeRecurso);
  if versao > -1 then
    result := result + '&version=' + IntToStr(versao);
end;

function TDataIntegradorModuloWeb.ultimaVersao: integer;
begin
  result := dmPrincipal.getSQLIntegerResult('Select max(versao) from ' + nomeTabela);
end;

function TDataIntegradorModuloWeb.translateFieldValue(
  node: IXMLDomNode): string;
var
  typedTranslate: string;
begin
  if (node.attributes.getNamedItem('nil') <> nil) and (node.attributes.getNamedItem('nil').text = 'true') then
    result := 'NULL'
  else if (node.attributes.getNamedItem('type') <> nil) then
  begin
    typedTranslate := translateTypeValue(node.attributes.getNamedItem('type').text, node.text);
    result := translateValueFromServer(node.nodeName, typedTranslate);
  end
  else
    result := QuotedStr(translateValueFromServer(node.nodeName, node.text));
end;

function TDataIntegradorModuloWeb.translateTypeValue(fieldType, fieldValue: string): string;
begin
  result := QuotedStr(fieldValue);
  if fieldType = 'integer' then
    result := fieldValue
  else if fieldType = 'boolean' then
  begin
    if fieldValue = 'true' then
      result := '1'
    else
      result := '0';
  end;
end;

function TDataIntegradorModuloWeb.translateFieldNameServerToPdv(
  node: IXMLDomNode): string;
begin
  result := translations.translateServerToPDV(node.nodeName, duasVias);
  if result = '' then
    {$IFDEF VER150}
    result := FastReplace(node.nodeName, '-', '');
    {$ELSE}
    result := StringReplace(node.nodeName, '-', '', [rfReplaceAll]);
    {$ENDIF}
end;

function TDataIntegradorModuloWeb.translateFieldNamePdvToServer(
  node: IXMLDomNode): string;
begin
  result := translations.translatepdvToServer(node.nodeName);
  if result = '' then
    {$IFDEF VER150}
    result := FastReplace(node.nodeName, '-', '');
    {$ELSE}
    result := StringReplace(node.nodeName, '-', '', [rfReplaceAll]);
    {$ENDIF}
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
      valor :=
        translateValueToServer(translations.get(i), translations.get(i).pdv,
          ds.fieldByName(translations.get(i).pdv), nestedAttribute, translations.get(i).fkName);
      //params.Add(nome + '=' + TIdURI.ParamsEncode(valor));
      params.Add(nome + '=' + valor);
    end;
  end;
end;

function TDataIntegradorModuloWeb.GetErrorMessage(const aXML: string): string;
var
  _node: IXMLNode;
  _list: IXMLNodeList;
  _XML: TXMLDocument;
begin
  Result := EmptyStr;
  CoInitialize(nil);
  _XML := TXMLDocument.Create(Self);
  try
    _XML.LoadFromXML(aXML);
    _list := _XML.ChildNodes;
    if _list.FindNode('errors') <> nil then
    begin
      _list := _list.FindNode('errors').ChildNodes;
      if _list <> nil  then
      begin
        _node := _list.FindNode('error');
        if _node <> nil then
          Result := _node.Text;
      end;
    end;
  finally
    FreeAndNil(_XML);
    CoUninitialize;
  end;
end;

function TDataIntegradorModuloWeb.saveRecordToRemote(ds: TDataSet; var salvou: boolean): IXMLDomDocument2;
var
  http: TIdHTTP;
  params: TStringList;
  multipartParams: TidMultipartFormDataStream;
  xmlContent: string;
  doc: IXMLDomDocument2;
  idRemoto: integer;
  txtUpdate: string;
  _Retry: integer;
  _stream: TStringStream;
  zippedParams: TMemoryStream;
  zipper: TZCompressionStream;
  url, s: string;
  _Log: string;
  _Response: TStringStream;
begin
  Self.log('Iniciando save record para remote. Classe: ' + ClassName, 'Sync');
  salvou := false;
  http := TIdHTTP.Create(nil);
  params := TStringList.Create;
  try
    addTranslatedParams(ds, params, translations);
    addDetails(ds, params);
    addMoreParams(ds, params);
    _Retry := 1;
    while (_Retry<=3) do
    begin
      try
        if useMultipartParams then
        begin
          multiPartParams := TIdMultiPartFormDataStream.Create;
          try
            _stream := TStringStream.Create('');
            prepareMultipartParams(ds, params, multipartParams);
            http.Post(getRequestUrlForAction(true), multipartParams, _stream);
            xmlContent := _stream.ToString;
          finally
            MultiPartParams.Free;
          end;
        end
        else
        begin
          url := getRequestUrlForAction(true);
          {
            A implementação do zippedPost ainda não está pronta. Ela deve ser mais bem testada em vários casos
            e precisa ser garantido que o post está de fato indo zipado.
          }
          if zippedPost then
          begin
            params.Delimiter := '&';
            params.QuoteChar := '&';
            s := params.DelimitedText;
            //_stream é o input com a string "s" a ser comprimida
            _stream := TStringStream.Create(utf8Encode(s));
            try
              //este será o stream de output, comprimido
              zippedParams := TMemoryStream.Create;
              zipper := TZCompressionStream.Create(zippedParams);
              _stream.Position := 0;
              //zippedParams é o stream de destino, no qual receberá o stream "_stream"
              zipper.CopyFrom(_stream, _stream.Size);

              http.Request.contentEncoding := 'gzip';
              xmlContent := http.Post(url, zippedParams);
            finally
              FreeAndNil(zippedParams);
              FreeAndNil(zipper);
            end;
          end
          else
          begin
            _Response := TStringStream.Create;
            try
              http.ConnectTimeout := 30000;
              http.ReadTimeout := 30000;
              //Primeiro, tenta dar um "Get" no endereço, para saber se pode enviar dados para o servidor. (como medida de proteção)
              http.Get(StringReplace(Self.FEnderecoIntegrador, '/Api/', '/stockfin', [rfReplaceAll]), _Response);
              xmlContent := http.Post(url, Params);
            finally
              _Response.Free;
            end;
          end;
        end;
        CoInitialize(nil);
        try
          {$IFDEF VER150}
          doc := CoDOMDocument.Create;
          {$ELSE}
          doc := CoDOMDocument60.Create;
          {$ENDIF}
          doc.loadXML(xmlContent);
          result := doc;
        finally
          CoUninitialize;
        end;
        if duasVias or clientToServer then
        begin
          txtUpdate := 'UPDATE ' + nomeTabela + ' SET salvouRetaguarda = ' + QuotedStr('S');

          if duasVias then
          begin
            idRemoto := strToInt(doc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//id').text);
            txtUpdate := txtUpdate + ', idRemoto = ' + IntToStr(idRemoto);
          end;

          txtUpdate := txtUpdate + ' WHERE ' + nomePKLocal + ' = ' + ds.fieldByName(nomePKLocal).AsString;

          //da a chance da classe gerenciar redirecionamentos, por exemplo ao descobrir que este registro já
          //existia no remoto e era outro registro neste banco de dados.
          if not gerenciaRedirecionamentos(ds.fieldByName(nomePKLocal).AsInteger, idRemoto) then
            dmPrincipal.execSQL(txtUpdate);

          dmPrincipal.refreshData;

          if Length(TabelasDetalhe) > 0 then
             Self.UpdateRecordDetalhe(doc.selectSingleNode(dasherize(nomeSingularSave)), TabelasDetalhe);
        end;
        _Retry := 4;
      except
        on e: EIdHTTPProtocolException do
        begin
          inc(_Retry);
          if e.ErrorCode = 422 then
            _Log := Format('Erro ao tentar salvar registro. Classe: %s, Código de erro: %d, Erro: %s.',[ClassName, e.ErrorCode, Self.GetErrorMessage(e.ErrorMessage)])
          else if e.ErrorCode = 500 then
            _Log := Format('Erro ao tentar salvar registro. Classe: %s, Código de erro: %d. Erro: Erro interno no servidor. ',[ClassName, e.ErrorCode])
          else
           _Log :=  Format('Erro ao tentar salvar registro. Classe: %s, Código de erro: %d. Erro: %s.',[ClassName, e.ErrorCode, e.ErrorMessage]);

          Self.log(_Log, 'Sync');
          raise EIntegradorException.Create(_Log) ; //Logou, agora manda pra cima
        end;
      end;
    end;
    salvou := _Retry > 3;
  finally
    FreeAndNil(http);
    FreeAndNil(params);
  end;
end;

procedure TDataIntegradorModuloWeb.addDetails(ds: TDataSet; params: TStringList);
var
  i : integer;
begin
  for i := low(tabelasDetalhe) to high(tabelasDetalhe) do
    addTabelaDetalheParams(ds.fieldByName(nomePKLocal).AsInteger, params, tabelasDetalhe[i]);
end;

procedure TDataIntegradorModuloWeb.addTabelaDetalheParams(valorPK: integer;
  params: TStringList;
  tabelaDetalhe: TTabelaDetalhe);
var
  qry: TDataSet;
  i: integer;
begin
  qry := dmPrincipal.getQuery;
  try
    TIBQuery(qry).SQL.Text := 'SELECT * FROM ' + tabelaDetalhe.nomeTabela + ' where ' + tabelaDetalhe.nomeFK +
      ' = ' + IntToStr(valorPK) + ' and ((salvouRetaguarda = ''N'') or (salvouRetaguarda is null)' +
                                                                 ' or (salvouRetaguarda = ''''))';
    qry.Open;
    while not qry.Eof do
    begin
      addTranslatedParams(qry, params, tabelaDetalhe.translations, tabelaDetalhe.nomeParametro);
      for i := low(tabelaDetalhe.tabelasDetalhe) to high(tabelaDetalhe.tabelasDetalhe) do
        addTabelaDetalheParams(qry.fieldByName(tabelaDetalhe.nomePK).AsInteger, params, tabelaDetalhe.tabelasDetalhe[i]);
      qry.Next;
    end;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TDataIntegradorModuloWeb.migrateSingletonTableToRemote;
var
  qry: TDataSet;
  salvou: boolean;
begin
  qry := dmPrincipal.getQuery;
  try
    TIBQuery(qry).SQL.Text := Trim('SELECT * FROM ' + nomeTabela);
    qry.Open;
    saveRecordToRemote(qry, salvou);
    qry.Close;
  finally
    FreeAndNil(qry);
  end;
end;

procedure TDataIntegradorModuloWeb.Log(const aLog, aClasse: string);
begin
  if (FDataLog <> nil) then
    FDataLog.log(aLog, aClasse);
end;

procedure TDataIntegradorModuloWeb.postRecordsToRemote(aDLL: IDLLInterface);
var
  qry: TIBQuery;
  salvou: boolean;
  i, j: Integer;
begin
  qry := (dmPrincipal.getQuery as TIBQuery);
  try
    try
      Self.log('Selecionando registros para sincronização. Classe: ' + ClassName, 'Sync');
      qry.SQL.Text := Trim( Format('SELECT * from %s where COALESCE(salvouRetaguarda, %s) = %s', [nomeTabela, QuotedStr('N'),QuotedStr('N')])
                         + getAdditionalSaveConditions);

      qry.Open;
      qry.FetchAll;
      qry.Last;
      i := qry.RecordCount;
      Self.log(IntToStr(i) +' Selecionados: ' + ClassName, 'Sync');
      j := 0;
      qry.First;
      while (not qry.Eof) do
      begin
        if (aDLL <> nil) and (aDLL.GetTerminated)  then
          Break;

        try
          dmPrincipal.startTransaction;
          saveRecordToRemote(qry, salvou);
          dmPrincipal.commit;
          if ((j mod 10) = 0) then
            Self.log('Enviando ' + IntToStr(j) +' de ' + IntToStr(i) , 'Sync');
          SleepEx(1000,True); //"dorme" 1 segundo para o servidor "respirar"
        except
          on e: Exception do
          begin
            dmPrincipal.rollback;
            Self.log('Erro no processamento do postRecordsToRemote. Classe: ' + ClassName +' | '+ e.Message, 'Sync');
          end;
        end;
        qry.Next;
        inc(j);
      end;
      Self.log(IntToStr(j) +' Enviados: ' + ClassName, 'Sync');
    except
      on e: Exception do
      begin
        Self.log('Erro no processamento do postRecordsToRemote. Classe: ' + ClassName +' | '+ e.Message, 'Sync');
        raise;
      end;
    end;
  finally
    FreeAndNil(qry);
    TrimAppMemorySize;
  end;
end;

procedure TDataIntegradorModuloWeb.migrateTableToRemote(where: string = '');
var
  qry: TDataSet;
  doc: IXMLDomDocument2;
  idRemoto: integer;
  salvou: boolean;
  log: TextFile;
begin
  offset := dmPrincipal.getSQLIntegerResult('SELECT max(' + nomePKLocal + ' + 1) from ' +
    nomeTabela + ' ');
  qry := dmPrincipal.getQuery;
  TIBQuery(qry).SQL.Text := Trim('SELECT * from ' + nomeTabela + ' where ' + nomePKLocal + ' = :' + nomePKLocal);
  dmPrincipal.startTransaction;
  try
    qry.Close;
    TIBQuery(qry).SQL.Text := Trim('SELECT * from ' + nomeTabela + ' ' + where + ' order by ' + getOrderBy);
    qry.Open;
    qry.First;
    ReWrite(log);

    while not qry.Eof do
    begin
      qry.Refresh;
      try
        doc := saveRecordToRemote(qry, salvou);
        if salvou and not(duasVias) then
        begin
          //no resp virá o id e os dados, devemos salvar porém com o id somado
          idRemoto := strToInt(doc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//id').text);
          doc.selectSingleNode('//' + dasherize(nomeSingularSave) + '//id').text :=
            IntToStr(idRemoto + offset);
          importRecord(doc.selectSingleNode('//' + dasherize(nomeSingularSave)));
          redirectRecord(qry.FieldByName(nomePKLocal).AsInteger, idRemoto + offset);
          Writeln(log, 'Redirecionando. De ' + qry.FieldByName(nomePKLocal).asString + ' -> ' + intToStr(idRemoto + offset));
        end;
      except
        //se der erro ao salvar um registro eu vou redirecionar para outro id, por exemplo
        //  em um produto eu posso redirecionar para um produto padrão, genérico, que será
        //  usado para este fim.
        write(log, 'Erro no item ' + qry.fieldByName(nomePKLocal).asString);

      end;

      qry.Next;
    end;
    dmPrincipal.commit;
    if not(duasVias) then
    begin
      //Segunda passada. Agora com o espaço liberado e os registros já semi-integrados
      //ao remoto, faltando apenas o ajuste do id
      qry.close;
      TIBQuery(qry).SQL.Text := Trim('SELECT * from ' + nomeTabela + ' ' + where + ' order by ' + nomePKLocal);
      qry.Open;
      qry.First;
      Writeln(log, '--Iniciando duplicação de volta, sem offset. Offset: ' + inttostr(offset));
      while not qry.Eof do
      begin
        qry.Refresh;
        //tira o offset e insere
        try
          Write(log, 'id: ' + qry.fieldByName(nomePKLocal).asString);
          duplicarRegistroSemOffset(qry);
          WriteLn(log, '... ok');
        except
          WriteLn(log, '... erro');
        end;
        Flush(log);
        qry.Next;
      end;
    end;
  finally
    dmPrincipal.commit;
    FreeAndNil(qry);
    CloseFile(log);
  end;
end;

procedure TDataIntegradorModuloWeb.redirectRecord(idAntigo, idNovo: integer);
var
  i: integer;
  nomeFK: string;
begin
  beforeRedirectRecord(idAntigo, idNovo);
  //Para cada tabela que referenciava esta devemos dar o update do id antigo para o novo
  for i:= low(tabelasDependentes) to high(tabelasDependentes) do
  begin
    nomeFK := tabelasDependentes[i].nomeFK;
    if nomeFK = '' then
      nomeFK := nomePKLocal;
    dmPrincipal.execSQL('UPDATE ' + tabelasDependentes[i].nomeTabela +
    ' set ' + nomeFK + ' = ' + IntToStr(idNovo) +
    ' where ' + nomeFK + ' = ' + IntToStr(idAntigo));
    dmPrincipal.refreshData;    
  end;
  //E então apagar o registro original
  dmPrincipal.execSQL('DELETE FROM ' + nomeTabela + ' where ' +
    nomePKLocal + ' = ' + IntToStr(idAntigo));
end;

procedure TDataIntegradorModuloWeb.duplicarRegistroSemOffset(ds: TDataSet);
var
  qry: TDataSet;
  i: integer;
begin
  qry := dmPrincipal.getQuery;
  try
    TIBQuery(qry).SQL.Text := 'INSERT INTO ' + nomeTabela + '(';
    for i := 0 to ds.fieldCount -1 do
    begin
      TIBQuery(qry).SQL.Add( ds.Fields[i].FieldName);
      if i < ds.fieldCount -1 then
        TIBQuery(qry).SQL.Add( ', ');
    end;
    TIBQuery(qry).SQL.Add( ') values (');
    for i := 0 to ds.fieldCount -1 do
    begin
      TIBQuery(qry).SQL.Add( ':' + ds.Fields[i].FieldName);
      if i < ds.fieldCount -1 then
        TIBQuery(qry).SQL.Add( ', ');
    end;
    TIBQuery(qry).SQL.Add( ')');
    for i := 0 to ds.fieldCount -1 do
    begin
      if uppercase(ds.Fields[i].FieldName) = uppercase(nomePKLocal) then
        TIBQuery(qry).ParamByName(nomePKLocal).Value := ds.Fields[i].AsInteger - offset
      else
        TIBQuery(qry).ParamByName(ds.Fields[i].FieldName).Value := ds.Fields[i].Value;
    end;
    TIBQuery(qry).ExecSQL;
    redirectRecord(ds.FieldByName(nomePKLocal).AsInteger, ds.FieldByName(nomePKLocal).AsInteger - offset);
    dmPrincipal.commit;
  finally
    FreeAndNil(qry);
  end;
end;

{ TTranslationSet }

procedure TTranslationSet.add(serverName, pdvName: string; lookupRemoteTable: string = ''; fkName: string = '');
var
  tam: integer;
begin
  tam := length(translations);
  SetLength(translations, tam + 1);
  translations[tam].server := serverName;
  translations[tam].pdv := pdvName;
  translations[tam].lookupRemoteTable := lookupRemoteTable;
  translations[tam].fkName := fkName;
end;

procedure TDataIntegradorModuloWeb.beforeRedirectRecord(idAntigo, idNovo: integer);
begin
  //
end;

constructor TTranslationSet.create(owner: TComponent);
begin
  SetLength(translations, 0);
  //add('version', 'versao');
  //add('active', 'ativo');
end;

function TTranslationSet.get(index: integer): TNameTranslation;
begin
  result := translations[index];
end;

function TTranslationSet.size: integer;
begin
  result := length(translations);
end;

function TTranslationSet.translatePDVToServer(pdvName: string): string;
var
  i: integer;
begin
  result := '';
  for i := low(translations) to high(translations) do
    if translations[i].pdv = pdvName then
      result := translations[i].server;
end;

function TTranslationSet.translateServerToPDV(serverName: string; duasVias: boolean): string;
var
  i: integer;
begin
  result := '';
  if duasVias and (upperCase(serverName) = 'ID') then
    result := 'idRemoto'
  else
    for i := low(translations) to high(translations) do
      if translations[i].server = underscorize(serverName) then
        result := translations[i].pdv;
end;

procedure TDataIntegradorModuloWeb.DataModuleCreate(Sender: TObject);
begin
  verbose := false;
  duasVias := false;
  clientToServer := false;
  translations := TTranslationSet.create(self);
  nomePKLocal := 'id';
  nomePKRemoto := 'id';
  SetLength(tabelasDependentes, 0);
  nomeGenerator := '';
  useMultipartParams := false;
  zippedPost := false;
end;


destructor TDataIntegradorModuloWeb.Destroy;
var
  _i: integer;
begin
  for _i := Low(Self.tabelasDetalhe) to High(Self.tabelasDetalhe) do
    Self.tabelasDetalhe[_i].Free;

  inherited;
end;

function TDataIntegradorModuloWeb.translateValueToServer(translation: TNameTranslation;
  fieldName: string; field: TField; nestedAttribute: string = ''; fkName: string = ''): string;
var
  lookupIdRemoto: integer;
  fk: string;
begin
  if translation.lookupRemoteTable <> '' then
  begin
    if fkName = '' then
      fk := translation.pdv
    else
      fk := fkName;
    if trim(field.AsString) <> '' then
    begin
      lookupIdRemoto := dmPrincipal.getSQLIntegerResult('SELECT idRemoto FROM ' +
        translation.lookupRemoteTable +
        ' WHERE ' + fk + ' = ' + field.AsString);
      if lookupIdRemoto > 0 then
        result := IntToStr(lookupIdRemoto)
      else
        result := '';
    end
    else
      result := '';
  end
  else
  begin
    if field.DataType in [ftFloat, ftBCD, ftFMTBCD, ftCurrency] then
    begin
      try
        {$IFDEF VER150}
        DecimalSeparator := '.';
        ThousandSeparator := #0;
        {$ELSE}
        FormatSettings.DecimalSeparator := '.';
        FormatSettings.ThousandSeparator := #0;
        {$ENDIF}
        result := field.AsString;
      finally

        {$IFDEF VER150}
        DecimalSeparator := ',';
        ThousandSeparator := '.';
        {$ELSE}
        FormatSettings.DecimalSeparator := ',';
        FormatSettings.ThousandSeparator := '.';
        {$ENDIF}
      end;
    end
    else if field.DataType in [ftDateTime, ftTimeStamp] then
    begin
      if field.IsNull then
        result := 'NULL'
      else
        result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', field.AsDateTime);
        //result := FormatDateTime('dd"/"mm"/"yyyy"T"hh":"nn":"ss', field.AsDateTime);
    end
    else if field.DataType in [ftDate] then
    begin
      if field.IsNull then
        result := 'NULL'
      else
        result := FormatDateTime('yyyy-mm-dd', field.AsDateTime);
    end
    else
      result := field.asString;
  end;
end;

function TDataIntegradorModuloWeb.translateValueFromServer(fieldName,
  value: string): string;
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
  result := nomeSingular;
end;

function TDataIntegradorModuloWeb.nomeSingularSave: string;
begin
  result := nomeSingular;
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

{ TTabelaDetalhe }

constructor TTabelaDetalhe.create;
begin
  translations := TTranslationSet.create(nil);
end;

procedure TDataIntegradorModuloWeb.SetDataLog(const Value: TDataLog);
begin
  FDataLog := Value;
end;

procedure TDataIntegradorModuloWeb.SetdmPrincipal(
  const Value: IDataPrincipal);
begin
  FdmPrincipal := Value;
end;

procedure TDataIntegradorModuloWeb.SetEnderecoIntegrador(const aEnderecoIntegrador: string);
begin
  Self.FEnderecoIntegrador := aEnderecoIntegrador;
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

end.
