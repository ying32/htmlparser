object Form23: TForm23
  Left = 0
  Top = 0
  Caption = 'Form23'
  ClientHeight = 454
  ClientWidth = 348
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Button1: TButton
    Left = 72
    Top = 105
    Width = 161
    Height = 25
    Caption = 'SimpleCSSSelector'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 72
    Top = 136
    Width = 161
    Height = 25
    Caption = 'XPath Test'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 72
    Top = 184
    Width = 161
    Height = 25
    Caption = 'Remov All <a>'
    TabOrder = 2
    OnClick = Button3Click
  end
end
