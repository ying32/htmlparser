unit Unit23;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, HtmlParserEx;

type
  TForm23 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    FHtmlData: string;
  public
    { Public declarations }
  end;

var
  Form23: TForm23;

implementation

{$R *.dfm}


procedure TForm23.Button1Click(Sender: TObject);
var
  LHtml: IHtmlElement;
  LList: IHtmlElementList;
begin
  LHtml := ParserHTML(FHtmlData);
  if LHtml <> nil then
  begin
    LList := LHtml.Find('a');
    for LHtml in LList do
      Writeln('url:', lhtml.Attributes['href']);
  end;
end;

procedure TForm23.Button2Click(Sender: TObject);
var
  LHtml: IHtmlElement;
  LList: IHtmlElementList;
begin
  LHtml := ParserHTML(FHtmlData);
  if LHtml <> nil then
  begin
    // 只是将xpath转为css操作。-----猥琐的操作
    LList := LHtml.FindX('//a/@href');
    for LHtml in LList do
      Writeln('url:', lhtml.Attributes['href']);
  end;
end;

procedure TForm23.Button3Click(Sender: TObject);
var
  LHtml: IHtmlElement;
  LList: IHtmlElementList;
begin
  LHtml := ParserHTML(FHtmlData);
  if LHtml <> nil then
  begin
    LList := LHtml.Find('a');
    LList.RemoveAll;
    Writeln(LHtml.InnerHtml);
  end;
end;

procedure TForm23.FormCreate(Sender: TObject);
var
  LStrStream: TStringStream;
begin
  LStrStream := TStringStream.Create('', TEncoding.UTF8);
  try
    LStrStream.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'github.com_ying32_htmlparser.html');
    FHtmlData := LStrStream.DataString;
  finally
    LStrStream.Free;
  end;
  // github.com_ying32_htmlparser.html
end;

end.
