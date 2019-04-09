object DataSincronizadorModuloWeb: TDataSincronizadorModuloWeb
  OldCreateOrder = False
  OnCreate = DataModuleCreate
  Height = 255
  Width = 443
  object sincronizaRetaguardaTimer: TTimer
    Interval = 60000
    OnTimer = sincronizaRetaguardaTimerTimer
    Left = 160
    Top = 96
  end
  object FilaDataSet: TSQLDataSet
    CommandText = 
      'select * from HIBRIDOFILASINCRONIZACAO order by IDHIBRIDOFILASIN' +
      'CRONIZACAO'
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
  end
  object FilaProvider: TDataSetProvider
    DataSet = FilaDataSet
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
  end
end
