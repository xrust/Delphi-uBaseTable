object Form1: TForm1
  Left = 2259
  Top = 167
  Width = 958
  Height = 541
  Caption = 'Form1'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnActivate = FormActivate
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 13
  object Log: TMemo
    Left = 0
    Top = 384
    Width = 950
    Height = 126
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object StringGrid1: TStringGrid
    Left = 0
    Top = 0
    Width = 950
    Height = 384
    Align = alClient
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSelect]
    TabOrder = 1
  end
end