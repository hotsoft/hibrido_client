object DataSincronizadorModuloWeb: TDataSincronizadorModuloWeb
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 255
  Width = 443
  object sincronizaRetaguardaTimer: TTimer
    Interval = 60000
    OnTimer = sincronizaRetaguardaTimerTimer
    Left = 352
    Top = 112
  end
  object FilaDataSet: TSQLDataSet
    CommandText = 
      'select first 500 * from hibridofilasincronizacao order by idhibr' +
      'idofilasincronizacao'
    MaxBlobSize = -1
    Params = <>
    SQLConnection = MainData.SQLConnection
    Left = 32
    Top = 16
    object FilaDataSetIDHIBRIDOFILASINCRONIZACAO: TLargeintField
      FieldName = 'IDHIBRIDOFILASINCRONIZACAO'
      Required = True
    end
    object FilaDataSetTABELA: TStringField
      FieldName = 'TABELA'
      Size = 50
    end
    object FilaDataSetID: TIntegerField
      FieldName = 'ID'
    end
    object FilaDataSetTENTATIVAS: TIntegerField
      FieldName = 'TENTATIVAS'
    end
    object FilaDataSetULTIMATENTATIVA: TSQLTimeStampField
      FieldName = 'ULTIMATENTATIVA'
    end
    object FilaDataSetOPERACAO: TStringField
      FieldName = 'OPERACAO'
      FixedChar = True
      Size = 1
    end
    object FilaDataSetIGNORADO: TSmallintField
      FieldName = 'IGNORADO'
    end
  end
  object FilaProvider: TDataSetProvider
    DataSet = FilaDataSet
    Options = [poAllowCommandText, poUseQuoteChar]
    Left = 120
    Top = 16
  end
  object FilaClientDataSet: TosClientDataset
    Aggregates = <>
    FetchOnDemand = False
    Params = <>
    DataProvider = FilaProvider
    Left = 216
    Top = 16
    object FilaClientDataSetIDHIBRIDOFILASINCRONIZACAO: TLargeintField
      FieldName = 'IDHIBRIDOFILASINCRONIZACAO'
      Required = True
    end
    object FilaClientDataSetTABELA: TStringField
      FieldName = 'TABELA'
      Size = 50
    end
    object FilaClientDataSetID: TIntegerField
      FieldName = 'ID'
    end
    object FilaClientDataSetTENTATIVAS: TIntegerField
      FieldName = 'TENTATIVAS'
    end
    object FilaClientDataSetULTIMATENTATIVA: TSQLTimeStampField
      FieldName = 'ULTIMATENTATIVA'
    end
    object FilaClientDataSetOPERACAO: TStringField
      FieldName = 'OPERACAO'
      FixedChar = True
      Size = 1
    end
    object FilaClientDataSetSincronizado: TBooleanField
      FieldKind = fkInternalCalc
      FieldName = 'Sincronizado'
    end
    object FilaClientDataSetIGNORADO: TSmallintField
      FieldName = 'IGNORADO'
    end
  end
  object MetaDadosDataSet: TSQLDataSet
    CommandText = 'select h.tabela, h.version_id from hibridometadadosremotos h'
    MaxBlobSize = -1
    Params = <>
    SQLConnection = MainData.SQLConnection
    Left = 32
    Top = 72
    object MetaDadosDataSetTABELA: TStringField
      FieldName = 'TABELA'
      Required = True
      Size = 50
    end
    object MetaDadosDataSetVERSION_ID: TLargeintField
      FieldName = 'VERSION_ID'
    end
  end
  object MetaDadosProvider: TDataSetProvider
    DataSet = MetaDadosDataSet
    Left = 120
    Top = 72
  end
  object MetaDadosClientDataSet: TosClientDataset
    Aggregates = <>
    FetchOnDemand = False
    Params = <>
    DataProvider = MetaDadosProvider
    Left = 216
    Top = 72
    object MetaDadosClientDataSetTABELA: TStringField
      DisplayWidth = 50
      FieldName = 'TABELA'
      Size = 50
    end
    object MetaDadosClientDataSetVERSION_ID: TLargeintField
      FieldName = 'VERSION_ID'
    end
    object MetaDadosClientDataSetBaixar: TBooleanField
      FieldKind = fkInternalCalc
      FieldName = 'Baixar'
    end
    object MetaDadosClientDataSetnome_plural: TStringField
      FieldKind = fkInternalCalc
      FieldName = 'nome_plural'
      Size = 50
    end
    object MetaDadosClientDataSetVERSION_ID_SERVER: TLargeintField
      FieldKind = fkInternalCalc
      FieldName = 'VERSION_ID_SERVER'
    end
  end
  object BlackListFieldClientDataSet: TClientDataSet
    Aggregates = <>
    FieldDefs = <>
    IndexDefs = <>
    Params = <>
    StoreDefs = True
    Left = 220
    Top = 136
    object BlackListFieldClientDataSetid: TIntegerField
      FieldName = 'id'
    end
    object BlackListFieldClientDataSetmatrix: TStringField
      FieldName = 'matrix'
      Size = 1
    end
    object BlackListFieldClientDataSetcan_get: TStringField
      FieldName = 'can_get'
      Size = 1
    end
    object BlackListFieldClientDataSetcan_post: TStringField
      FieldName = 'can_post'
      Size = 1
    end
    object BlackListFieldClientDataSettable_client_name: TStringField
      FieldName = 'table_client_name'
      Size = 100
    end
    object BlackListFieldClientDataSettable_server_name: TStringField
      FieldName = 'table_server_name'
      Size = 100
    end
    object BlackListFieldClientDataSetfield_client_name: TStringField
      FieldName = 'field_client_name'
      Size = 100
    end
    object BlackListFieldClientDataSetfield_server_name: TStringField
      FieldName = 'field_server_name'
      Size = 100
    end
  end
end
