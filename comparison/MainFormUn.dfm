object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Comparison'
  ClientHeight = 464
  ClientWidth = 677
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    677
    464)
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 14
    Top = 47
    Width = 651
    Height = 47
    Anchors = [akLeft, akTop, akRight]
    Shape = bsBottomLine
  end
  object TableLabel: TLabel
    Left = 20
    Top = 446
    Width = 3
    Height = 13
    Anchors = [akLeft, akRight, akBottom]
  end
  object Banco1Edit: TLabeledEdit
    Left = 14
    Top = 22
    Width = 523
    Height = 21
    EditLabel.Width = 27
    EditLabel.Height = 13
    EditLabel.Caption = 'Posto'
    TabOrder = 0
  end
  object Banco2Edit: TLabeledEdit
    Left = 14
    Top = 62
    Width = 523
    Height = 21
    EditLabel.Width = 29
    EditLabel.Height = 13
    EditLabel.Caption = 'Matriz'
    TabOrder = 2
  end
  object Banco1Button: TBitBtn
    Left = 543
    Top = 18
    Width = 41
    Height = 25
    Glyph.Data = {
      06030000424D06030000000000003600000028000000100000000F0000000100
      180000000000D0020000C40E0000C40E0000000000000000000085D5FD66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF88D6FD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF67CAFD61C4F466CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF62C1F252A3CCDCEDF5
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFDAEBF452A2CD52A3CC52A3CC55A4CD55A4CD55A4CD55A4CD55A4CD55
      A4CD55A4CD55A4CD55A4CD55A4CD55A4CD55A4CD52A3CC79B8D777B6D752A3CC
      52A3CC52A3CC52A3CC78B6D6FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF}
    TabOrder = 1
    OnClick = Banco1ButtonClick
  end
  object Banco2Button: TBitBtn
    Left = 543
    Top = 58
    Width = 41
    Height = 25
    Glyph.Data = {
      06030000424D06030000000000003600000028000000100000000F0000000100
      180000000000D0020000C40E0000C40E0000000000000000000085D5FD66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF88D6FD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF68CDFD66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF68CDFD66CCFF66CCFF
      66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CC
      FF66CCFF66CCFF67CAFD61C4F466CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66
      CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF66CCFF62C1F252A3CCDCEDF5
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFDAEBF452A2CD52A3CC52A3CC55A4CD55A4CD55A4CD55A4CD55A4CD55
      A4CD55A4CD55A4CD55A4CD55A4CD55A4CD55A4CD52A3CC79B8D777B6D752A3CC
      52A3CC52A3CC52A3CC78B6D6FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF}
    TabOrder = 3
    OnClick = Banco2ButtonClick
  end
  object Memo: TMemo
    Left = 18
    Top = 100
    Width = 651
    Height = 341
    Anchors = [akLeft, akTop, akRight, akBottom]
    ScrollBars = ssVertical
    TabOrder = 5
  end
  object OkButton: TBitBtn
    Left = 590
    Top = 58
    Width = 75
    Height = 25
    Caption = 'OK'
    Default = True
    Glyph.Data = {
      76020000424D76020000000000003600000028000000100000000C0000000100
      18000000000040020000C40E0000C40E00000000000000000000FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFB1D1B1519D51F7F7F7FFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB0D1B019891900800048
      8948F8F8F8FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFB3D3B32492240087000087000087004C8F4CFAFAFAFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB2D2B255AE5548AC482C9F2C0C910C04
      8D04048D04529352FBFBFBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFB3D3B3
      5FB15F56B25654B15452B15250B0503CA63C249C241494145F975FFCFCFCFFFF
      FFFFFFFFFFFFFFFFFFFFB5D3B567B76761B76160B7605EB65E67B36785BB855B
      B35B58B35853B15346AB4679A579FDFDFDFFFFFFFFFFFFFFFFFFD6E7D671B971
      6BBC6B6ABB6A6DB66DDCEADCFFFFFF95C29565B56561B76160B6605EB65E87AC
      87FEFEFEFFFFFFFFFFFFFFFFFFD6E7D676B97677B877DCEADCFFFFFFFFFFFFFF
      FFFF97C3976DBA6D6BBC6B69BB6968BA688CAD8CFEFEFEFFFFFFFFFFFFFFFFFF
      D6E7D6DCEADCFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF98C39874BE7474C07473BF
      7371BE7194AF94FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFF99C5997DC47D7DC47D7CC37C7DC07DA9CDA9FFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF9AC59A87C8
      8786C68684BB84FDFEFDFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFF9DC59D89BE89FDFEFDFFFFFF}
    TabOrder = 4
    OnClick = OkButtonClick
  end
  object ProgressBar: TProgressBar
    Left = 208
    Top = 444
    Width = 461
    Height = 17
    Anchors = [akLeft, akRight, akBottom]
    Smooth = True
    TabOrder = 6
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'fdb'
    Filter = 'Arquivos fdb|*.fdb'
    Left = 616
    Top = 8
  end
end
