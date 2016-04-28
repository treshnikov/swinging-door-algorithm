object Form1: TForm1
  Left = 0
  Top = 0
  Caption = #1044#1077#1084#1086#1085#1089#1090#1088#1072#1094#1080#1103' '#1072#1083#1075#1086#1088#1080#1090#1084#1072' SwingDoor '
  ClientHeight = 376
  ClientWidth = 526
  Color = clWhite
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    526
    376)
  PixelsPerInch = 96
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 0
    Width = 808
    Height = 265
    OnClick = Image1Click
  end
  object mLog: TMemo
    Left = 120
    Top = 279
    Width = 398
    Height = 90
    Anchors = [akLeft, akTop, akRight]
    ScrollBars = ssVertical
    TabOrder = 1
    ExplicitWidth = 688
  end
  object btnStep: TButton
    Left = 8
    Top = 279
    Width = 106
    Height = 25
    Caption = #1053#1086#1074#1072#1103' '#1090#1086#1095#1082#1072
    TabOrder = 0
    OnClick = btnStepClick
  end
  object btnClear: TButton
    Left = 8
    Top = 310
    Width = 106
    Height = 25
    Caption = #1054#1095#1080#1089#1090#1080#1090#1100
    TabOrder = 2
    OnClick = btnClearClick
  end
end
