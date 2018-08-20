object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'Comparison'
  ClientHeight = 431
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
    431)
  PixelsPerInch = 96
  TextHeight = 13
  object Bevel1: TBevel
    Left = 14
    Top = 47
    Width = 651
    Height = 47
    Shape = bsBottomLine
  end
  object Banco1Edit: TLabeledEdit
    Left = 14
    Top = 22
    Width = 523
    Height = 21
    EditLabel.Width = 38
    EditLabel.Height = 13
    EditLabel.Caption = 'Banco 1'
    TabOrder = 0
  end
  object Banco2Edit: TLabeledEdit
    Left = 14
    Top = 62
    Width = 523
    Height = 21
    EditLabel.Width = 38
    EditLabel.Height = 13
    EditLabel.Caption = 'Banco 2'
    TabOrder = 2
  end
  object Banco1Button: TBitBtn
    Left = 543
    Top = 18
    Width = 41
    Height = 25
    TabOrder = 1
    OnClick = Banco1ButtonClick
  end
  object Banco2Button: TBitBtn
    Left = 543
    Top = 58
    Width = 41
    Height = 25
    TabOrder = 3
    OnClick = Banco2ButtonClick
  end
  object Memo: TMemo
    Left = 18
    Top = 100
    Width = 651
    Height = 325
    Anchors = [akLeft, akTop, akRight, akBottom]
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
      DE010000424DDE01000000000000760000002800000024000000120000000100
      0400000000006801000000000000000000001000000000000000000000000000
      80000080000000808000800000008000800080800000C0C0C000808080000000
      FF0000FF000000FFFF00FF000000FF00FF00FFFF0000FFFFFF00333333333333
      3333333333333333333333330000333333333333333333333333F33333333333
      00003333344333333333333333388F3333333333000033334224333333333333
      338338F3333333330000333422224333333333333833338F3333333300003342
      222224333333333383333338F3333333000034222A22224333333338F338F333
      8F33333300003222A3A2224333333338F3838F338F33333300003A2A333A2224
      33333338F83338F338F33333000033A33333A222433333338333338F338F3333
      0000333333333A222433333333333338F338F33300003333333333A222433333
      333333338F338F33000033333333333A222433333333333338F338F300003333
      33333333A222433333333333338F338F00003333333333333A22433333333333
      3338F38F000033333333333333A223333333333333338F830000333333333333
      333A333333333333333338330000333333333333333333333333333333333333
      0000}
    NumGlyphs = 2
    TabOrder = 4
    OnClick = OkButtonClick
  end
  object OpenDialog: TOpenDialog
    DefaultExt = 'fdb'
    Filter = 'Arquivos fdb|*.fdb'
    Left = 616
    Top = 8
  end
end
