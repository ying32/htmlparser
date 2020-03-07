program demo;

uses
  Vcl.Forms,
  Unit23 in 'Unit23.pas' {Form23},
  HtmlParserEx in '..\HtmlParserEx.pas';

{$R *.res}

{$APPTYPE CONSOLE}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TForm23, Form23);
  Application.Run;
end.
