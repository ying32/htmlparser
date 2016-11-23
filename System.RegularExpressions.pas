{*******************************************************}
{                                                       }
{           CodeGear Delphi Runtime Library             }
{                                                       }
{ Copyright(c) 1995-2014 Embarcadero Technologies, Inc. }
{                                                       }
{ Original Author: Vincent Parrett                      }
{                                                       }
{*******************************************************}

unit System.RegularExpressions;

interface

uses
  System.SysUtils, System.RegularExpressionsCore;

type
  TRegExOption = (roNone, roIgnoreCase, roMultiLine, roExplicitCapture,
    roCompiled, roSingleLine, roIgnorePatternSpace, roNotEmpty);
  TRegExOptions = set of TRegExOption;

  TGroup = record
  private
    FIndex: Integer;
    FLength: Integer;
    FSuccess: Boolean;
    FValue: TBytes;
    constructor Create(const AValue: string; AIndex, ALength: Integer; ASuccess: Boolean);
    function GetIndex: Integer;
    function GetLength: Integer;
    function GetValue: string;
  public
    property Index: Integer read GetIndex;
    property Length: Integer read GetLength;
    property Success: Boolean read FSuccess;
    property Value: string read GetValue;
  end;

  TGroupCollectionEnumerator = class;

  TGroupCollection = record
  private
    FList: TArray<TGroup>;
    FNotifier: IInterface;
    constructor Create(ANotifier: IInterface; const AValue: string;
      AIndex, ALength: Integer; ASuccess: Boolean);
    function GetCount: Integer;
    function GetItem(Index: Variant): TGroup;
  public
    function GetEnumerator: TGroupCollectionEnumerator;
    property Count: Integer read GetCount;
    property Item[Index: Variant]: TGroup read GetItem; default;
  end;

  TGroupCollectionEnumerator = class
  private
    FCollection: TGroupCollection;
    FIndex: Integer;
  public
    constructor Create(const ACollection: TGroupCollection);
    function GetCurrent: TGroup;
    function MoveNext: Boolean;
    property Current: TGroup read GetCurrent;
  end;

  TMatch = record
  private
    FGroup: TGroup;
    FGroups: TGroupCollection;
    FNotifier: IInterface;
    constructor Create(ANotifier: IInterface; const AValue: string;
      AIndex, ALength: Integer; ASuccess: Boolean);
    function GetIndex: Integer;
    function GetGroups: TGroupCollection;
    function GetLength: Integer;
    function GetSuccess: Boolean;
    function GetValue: string;
  public
    function NextMatch: TMatch;
    function Result(const Pattern: string): string;
    property Groups: TGroupCollection read GetGroups;
    property Index: Integer read GetIndex;
    property Length: Integer read GetLength;
    property Success: Boolean read GetSuccess;
    property Value: string read GetValue;
  end;

  TMatchCollectionEnumerator = class;

  TMatchCollection = record
  private
    FList: TArray<TMatch>;
    constructor Create(ANotifier: IInterface; const Input: string;
      AOptions: TRegExOptions; StartPos: Integer);
    function GetCount: Integer;
    function GetItem(Index: Integer): TMatch;
  public
    function GetEnumerator: TMatchCollectionEnumerator;
    property Count: Integer read GetCount;
    property Item[Index: Integer]: TMatch read GetItem; default;
  end;

  TMatchCollectionEnumerator = class
  private
    FCollection: TMatchCollection;
    FIndex: Integer;
  public
    constructor Create(const ACollection: TMatchCollection);
    function GetCurrent: TMatch;
    function MoveNext: Boolean;
    property Current: TMatch read GetCurrent;
  end;

  TMatchEvaluator = function(const Match: TMatch): string of object;

  TRegEx = record
  private
    FOptions: TRegExOptions;
    FMatchEvaluator: TMatchEvaluator;
    FNotifier: IInterface;
    FRegEx: TPerlRegEx;
    procedure InternalOnReplace(Sender: TObject; var ReplaceWith: string);
  public
    constructor Create(const Pattern: string; Options: TRegExOptions = [roNotEmpty]);

    function IsMatch(const Input: string): Boolean; overload;
    function IsMatch(const Input: string; StartPos: Integer): Boolean; overload;
    class function IsMatch(const Input, Pattern: string): Boolean;overload; static;
    class function IsMatch(const Input, Pattern: string; Options: TRegExOptions): Boolean; overload; static;

    class function Escape(const Str: string; UseWildCards: Boolean = False): string; static;

    function Match(const Input: string): TMatch; overload;
    function Match(const Input: string; StartPos: Integer): TMatch; overload;
    function Match(const Input: string; StartPos, Length: Integer): TMatch; overload;
    class function Match(const Input, Pattern: string): TMatch; overload; static;
    class function Match(const Input, Pattern: string; Options: TRegExOptions): TMatch; overload; static;

    function Matches(const Input: string): TMatchCollection; overload;
    function Matches(const Input: string; StartPos: Integer): TMatchCollection; overload;
    class function Matches(const Input, Pattern: string): TMatchCollection; overload; static;
    class function Matches(const Input, Pattern: string; Options: TRegExOptions): TMatchCollection; overload; static;

    function Replace(const Input, Replacement: string): string; overload;
    function Replace(const Input: string; Evaluator: TMatchEvaluator): string; overload;
    function Replace(const Input, Replacement: string; Count: Integer): string; overload;
    function Replace(const Input: string; Evaluator: TMatchEvaluator; Count: Integer): string; overload;
    class function Replace(const Input, Pattern, Replacement: string): string; overload; static;
    class function Replace(const Input, Pattern: string; Evaluator: TMatchEvaluator): string; overload; static;
    class function Replace(const Input, Pattern, Replacement: string; Options: TRegExOptions): string; overload; static;
    class function Replace(const Input, Pattern: string; Evaluator: TMatchEvaluator; Options: TRegExOptions): string; overload; static;

    function Split(const Input: string): TArray<string>; overload; inline;
    function Split(const Input: string; Count: Integer): TArray<string>; overload; inline;
    function Split(const Input: string; Count, StartPos: Integer): TArray<string>; overload;
    class function Split(const Input, Pattern: string): TArray<string>; overload; static;
    class function Split(const Input, Pattern: string; Options: TRegExOptions): TArray<string>; overload; static;
  end;

implementation

uses
  System.Classes, System.Variants, System.RegularExpressionsAPI, System.RegularExpressionsConsts;

{ Helper classes and functions }

type
  TScopeExitNotifier = class(TInterfacedObject)
  private
    FRegEx: TPerlRegEx;
  public
    constructor Create(ARegEx: TPerlRegEx);
    destructor Destroy; override;
    property RegEx: TPerlRegEx read FRegEx;
  end;

function CopyBytes(const S: TBytes; Index, Count: Integer): TBytes;
var
  Len, I: Integer;
begin
  Len := Length(S);
  if Len = 0 then
    Result := TEncoding.UTF8.GetBytes('')
  else
  begin
    if Index < 0 then Index := 0
    else if Index > Len then Count := 0;
    Len := Len - Index;
    if Count <= 0 then
      Result := TEncoding.UTF8.GetBytes('')
    else
    begin
      if Count > Len then Count := Len;
      SetLength(Result, Count);
      for I := 0 to Count - 1 do
        Result[I] := S[Index + I];
    end;
  end;
end;

// Helper to extract RegEx object
function GetRegEx(Notifier: IInterface): TPerlRegEx; inline;
begin
  Result := TScopeExitNotifier(Notifier).RegEx;
end;

constructor TScopeExitNotifier.Create(ARegEx: TPerlRegEx);
begin
  FRegEx := ARegEx;
end;

destructor TScopeExitNotifier.Destroy;
begin
  if Assigned(FRegEx) then
    FreeAndNil(FRegEx);
  inherited;
end;

function MakeScopeExitNotifier(ARegEx: TPerlRegEx): IInterface;
begin
  Result := TScopeExitNotifier.Create(ARegEx);
end;

function RegExOptionsToPCREOptions(Value: TRegExOptions): TPerlRegExOptions;
begin
  Result := [];
  if (roIgnoreCase in Value) then
    Include(Result, preCaseLess);
  if (roMultiLine in Value) then
    Include(Result, preMultiLine);
  if (roExplicitCapture in Value) then
    Include(Result, preNoAutoCapture);
  if roSingleLine in Value then
    Include(Result, preSingleLine);
  if (roIgnorePatternSpace in Value) then
    Include(Result, preExtended);
end;

{ TGroup }

constructor TGroup.Create(const AValue: string; AIndex, ALength: Integer; ASuccess: Boolean);
begin
  FSuccess := ASuccess;
  FValue := TEncoding.UTF8.GetBytes(AValue);
  FIndex := UnicodeIndexToUTF8(AValue, AIndex);
  FLength := UnicodeIndexToUTF8(AValue, AIndex + ALength) - FIndex;
end;

function TGroup.GetIndex: Integer;
begin
  Result := UTF8IndexToUnicode(FValue, FIndex) + 1;
end;

function TGroup.GetLength: Integer;
begin
  if (FIndex + FLength) > System.Length(FValue) then
    Result := System.Length(FValue) - GetIndex +1
  else
    Result := UTF8IndexToUnicode(FValue, FIndex + FLength) - GetIndex + 1;
 end;

function TGroup.GetValue: string;
begin
  Result := TEncoding.UTF8.GetString(CopyBytes(FValue, FIndex, FLength));
end;

{ TGroupCollection }

constructor TGroupCollection.Create(ANotifier: IInterface;
  const AValue: string; AIndex, ALength: Integer; ASuccess: Boolean);
var
  I: Integer;
  LRegEx: TPerlRegEx;
begin
  FNotifier := ANotifier;
  // populate collection;
  if ASuccess then
  begin
    LRegEx := GetRegEx(FNotifier);
    SetLength(FList, LRegEx.GroupCount + 1);
    for I := 0 to Length(FList) - 1 do
      FList[I] := TGroup.Create(AValue, LRegEx.GroupOffsets[I], LRegEx.GroupLengths[I], ASuccess);
  end;
end;

function TGroupCollection.GetCount: Integer;
begin
  Result := Length(FList);
end;

function TGroupCollection.GetEnumerator: TGroupCollectionEnumerator;
begin
  Result := TGroupCollectionEnumerator.Create(Self);
end;

function TGroupCollection.GetItem(Index: Variant): TGroup;
var
  LIndex: Integer;
begin
  case VarType(Index) of
    varString, varUString, varOleStr:
      LIndex := GetRegEx(FNotifier).NamedGroup(string(Index));
    varByte, varSmallint, varInteger, varShortInt, varWord, varLongWord:
      LIndex := Index;
  else
    raise ERegularExpressionError.CreateRes(@SRegExInvalidIndexType);
  end;

  if (LIndex >= 0) and (LIndex < Length(FList)) then
    Result := FList[LIndex]
  else if (LIndex = PCRE_ERROR_NOSUBSTRING) and
          ((VarType(Index) = varUString) or (VarType(Index) = varString) or (VarType(Index) = varOleStr)) then
    raise ERegularExpressionError.CreateResFmt(@SRegExInvalidGroupName, [string(Index)])
  else
  begin
    // 没有找到这个命名组又非  PCRE_ERROR_NOSUBSTRING 之类的错误，不知道为什么要抛这样一个错误。
    // ying32
    Result.FIndex := -1;
    Result.FLength := 0;
    Result.FSuccess := False;
    Result.FValue := nil;
  end;
    //raise ERegularExpressionError.CreateResFmt(@SRegExIndexOutOfBounds, [LIndex]);
end;

{ TGroupCollectionEnumerator }

constructor TGroupCollectionEnumerator.Create(const ACollection: TGroupCollection);
begin
  FCollection := ACollection;
  FIndex := -1;
end;

function TGroupCollectionEnumerator.GetCurrent: TGroup;
begin
  Result := FCollection.Item[FIndex];
end;

function TGroupCollectionEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FCollection.Count - 1;
  if Result then
    Inc(FIndex);
end;

{ TMatch }

constructor TMatch.Create(ANotifier: IInterface; const AValue: string; AIndex,
  ALength: Integer; ASuccess: Boolean);
begin
  FGroup := TGroup.Create(AValue, AIndex, ALength, ASuccess);
  FGroups := TGroupCollection.Create(ANotifier, AValue, AIndex, ALength, ASuccess);
  FNotifier := ANotifier;
end;

function TMatch.GetGroups: TGroupCollection;
begin
  Result := FGroups;
end;

function TMatch.GetIndex: Integer;
begin
  Result := FGroup.Index;
end;

function TMatch.GetLength: Integer;
begin
  Result := FGroup.Length;
end;

function TMatch.GetSuccess: Boolean;
begin
  Result := FGroup.Success;
end;

function TMatch.GetValue: string;
begin
  Result := FGroup.Value;
end;

function TMatch.NextMatch: TMatch;
var
  LSuccess: Boolean;
  LRegEx: TPerlRegEx;
begin
  LRegEx := GetRegEx(FNotifier);
  LSuccess := LRegEx.MatchAgain;
  if LSuccess then
    Result := TMatch.Create(FNotifier, LRegEx.Subject,
      LRegEx.MatchedOffset, LRegEx.MatchedLength, LSuccess)
  else
    Result := TMatch.Create(FNotifier, LRegEx.Subject, 0, 0, LSuccess)
end;

function TMatch.Result(const Pattern: string): string;
var
  LRegEx: TPerlRegEx;
begin
  LRegEx := GetRegEx(FNotifier);
  LRegEx.Replacement := Pattern;
  Result := LRegEx.ComputeReplacement;
end;

{ TMatchCollection }

constructor TMatchCollection.Create(ANotifier: IInterface; const Input: string;
  AOptions: TRegExOptions; StartPos: Integer);
var
  Count: Integer;
  LResult: Boolean;
  LRegEx: TPerlRegEx;
begin
  LRegEx := GetRegEx(ANotifier);
  LRegEx.Subject := Input;
  LRegEx.Options := RegExOptionsToPCREOptions(AOptions);
  LRegEx.Start := StartPos;
  Count := 0;
  SetLength(FList, 0);
  LResult := LRegEx.MatchAgain;
  while LResult do
  begin
    if Count mod 10 = 0 then
      SetLength(FList, Length(FList) + 10);
    FList[Count] := TMatch.Create(ANotifier, Input, LRegEx.MatchedOffset,
      LRegEx.MatchedLength, LResult);
    LResult := LRegEx.MatchAgain;
    Inc(Count);
  end;
  if Length(FList) > Count then
    SetLength(FList, Count);
end;

function TMatchCollection.GetCount: Integer;
begin
  Result := Length(FList);
end;

function TMatchCollection.GetEnumerator: TMatchCollectionEnumerator;
begin
  Result := TMatchCollectionEnumerator.Create(Self);
end;

function TMatchCollection.GetItem(Index: Integer): TMatch;
begin
  if (Index >= 0) and (Index < Length(FList)) then
    Result := FList[Index]
  else
    raise ERegularExpressionError.CreateResFmt(@SRegExIndexOutOfBounds, [Index]);
end;

{ TMatchCollectionEnumerator }

constructor TMatchCollectionEnumerator.Create(const ACollection: TMatchCollection);
begin
  FCollection := ACollection;
  FIndex := -1;
end;

function TMatchCollectionEnumerator.GetCurrent: TMatch;
begin
  Result := FCollection.Item[FIndex];
end;

function TMatchCollectionEnumerator.MoveNext: Boolean;
begin
  Result := FIndex < FCollection.Count - 1;
  if Result then
    Inc(FIndex);
end;

{ TRegEx }

constructor TRegEx.Create(const Pattern: string; Options: TRegExOptions);
begin
  FOptions := Options;
  FRegEx := TPerlRegEx.Create;
  FRegEx.Options := RegExOptionsToPCREOptions(FOptions);
  if (roNotEmpty in Options) then
    FRegEx.State := [preNotEmpty];
  FRegEx.RegEx := Pattern;
  FNotifier := MakeScopeExitNotifier(FRegEx);
  if (roCompiled in FOptions) then
    FRegEx.Compile;
end;

class function TRegEx.Escape(const Str: string; UseWildCards: Boolean): string;
const
  Special: array [1 .. 14] of string = ('\', '[', ']', '^', '$', '.', '|', '?',
    '*', '+', '(', ')', '{', '}'); // do not localize
var
  I: Integer;
begin
  Result := Str;
  for I := Low(Special) to High(Special) do
  begin
    Result := StringReplace(Result, Special[I], '\' + Special[I], [rfReplaceAll]); // do not localize
  end;
  // CRLF becomes \r\n
  Result := StringReplace(Result, #13#10, '\r\n', [rfReplaceAll]); // do not localize

  // If we're matching wildcards, make them Regex Groups so we can read them back if necessary
  if UseWildCards then
  begin
    // Replace all \*s with (.*)
    Result := StringReplace(Result, '\*', '(.*)', [rfReplaceAll]); // do not localize
    // Replace any \?s with (.)
    Result := StringReplace(Result, '\?', '(.)', [rfReplaceAll]); // do not localize

    // Wildcards can be escaped as ** or ??
    // Change back any escaped wildcards
    Result := StringReplace(Result, '(.*)(.*)', '\*', [rfReplaceAll]); // do not localize
    Result := StringReplace(Result, '(.)(.)', '\?', [rfReplaceAll]); // do not localize
  end;
end;

function TRegEx.IsMatch(const Input: string): Boolean;
begin
  FRegEx.Subject := Input;
  Result := FRegEx.Match;
end;

function TRegEx.IsMatch(const Input: string; StartPos: Integer): Boolean;
begin
  FRegEx.Subject := Input;
  FRegEx.Start := UnicodeIndexToUTF8(Input, StartPos) + 1;
  Result := FRegEx.MatchAgain;
end;

class function TRegEx.IsMatch(const Input, Pattern: string): Boolean;
var
  LRegEx: TRegEx;
  Match: TMatch;
begin
  LRegEx := TRegEx.Create(Pattern);
  Match := LRegEx.Match(Input);
  Result := Match.Success;
end;

procedure TRegEx.InternalOnReplace(Sender: TObject; var ReplaceWith: string);
var
  Match: TMatch;
begin
  if Assigned(FMatchEvaluator) then
  begin
    Match := TMatch.Create(FNotifier, FRegEx.Subject,
      FRegEx.MatchedOffset, FRegEx.MatchedLength, True);
    ReplaceWith := FMatchEvaluator(Match);
  end;
end;

class function TRegEx.IsMatch(const Input, Pattern: string; Options: TRegExOptions): Boolean;
var
  LRegEx: TRegEx;
  Match: TMatch;
begin
  LRegEx := TRegEx.Create(Pattern, Options);
  Match := LRegEx.Match(Input);
  Result := Match.Success;
end;

class function TRegEx.Match(const Input, Pattern: string): TMatch;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern);
  Result := LRegEx.Match(Input);
end;

class function TRegEx.Match(const Input, Pattern: string; Options: TRegExOptions): TMatch;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern, Options);
  Result := LRegEx.Match(Input);
end;

function TRegEx.Matches(const Input: string): TMatchCollection;
begin
  Result := TMatchCollection.Create(FNotifier, Input, FOptions, 1);
end;

function TRegEx.Matches(const Input: string; StartPos: Integer): TMatchCollection;
begin
  Result := TMatchCollection.Create(FNotifier, Input, FOptions,
    UnicodeIndexToUTF8(Input, StartPos));
end;

function TRegEx.Match(const Input: string): TMatch;
var
  LSuccess: Boolean;
begin
  FRegEx.Subject := Input;
  LSuccess := FRegEx.Match;
  if LSuccess then
    Result := TMatch.Create(FNotifier, FRegEx.Subject,
      FRegEx.MatchedOffset, FRegEx.MatchedLength, LSuccess)
  else
    Result := TMatch.Create(FNotifier, FRegEx.Subject, 0, 0, LSuccess);
end;

function TRegEx.Match(const Input: string; StartPos: Integer): TMatch;
var
  LSuccess: Boolean;
begin
  FRegEx.Subject := Input;
  FRegEx.Start := UnicodeIndexToUTF8(Input, StartPos) + 1;
  LSuccess := FRegEx.MatchAgain;
  if LSuccess then
    Result := TMatch.Create(FNotifier, FRegEx.Subject,
      FRegEx.MatchedOffset, FRegEx.MatchedLength, LSuccess)
  else
    Result := TMatch.Create(FNotifier, FRegEx.Subject, 0, 0, LSuccess);
end;

function TRegEx.Match(const Input: string; StartPos, Length: Integer): TMatch;
var
  LSuccess: Boolean;
begin
  FRegEx.Subject := Input;
  FRegEx.Start := UnicodeIndexToUTF8(Input, StartPos) + 1;
  FRegEx.Stop := UnicodeIndexToUTF8(Input, StartPos + Length);
  LSuccess := FRegEx.MatchAgain;
  if LSuccess then
    Result := TMatch.Create(FNotifier, FRegEx.Subject,
      FRegEx.MatchedOffset, FRegEx.MatchedLength, LSuccess)
  else
    Result := TMatch.Create(FNotifier, FRegEx.Subject, 0, 0, LSuccess);
end;

class function TRegEx.Matches(const Input, Pattern: string): TMatchCollection;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern);
  Result := LRegEx.Matches(Input);
end;

class function TRegEx.Matches(const Input, Pattern: string; Options: TRegExOptions): TMatchCollection;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern, Options);
  Result := LRegEx.Matches(Input);
end;

class function TRegEx.Replace(const Input, Pattern, Replacement: string): string;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern);
  Result := LRegEx.Replace(Input, Replacement);
end;

class function TRegEx.Replace(const Input, Pattern: string; Evaluator: TMatchEvaluator): string;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern);
  Result := LRegEx.Replace(Input, Evaluator);
end;

class function TRegEx.Replace(const Input, Pattern: string;
  Evaluator: TMatchEvaluator; Options: TRegExOptions): string;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern, Options);
  Result := LRegEx.Replace(Input, Evaluator);
end;

function TRegEx.Replace(const Input, Replacement: string): string;
begin
  FRegEx.Subject := Input;
  FRegEx.Replacement := Replacement;
  FRegEx.ReplaceAll;
  Result := FRegEx.Subject;
end;

function TRegEx.Replace(const Input, Replacement: string; Count: Integer): string;
var
  I: Integer;
begin
  if Count = -1 then
  begin
    Result := Replace(Input, Replacement);
    Exit;
  end;
  FRegEx.Subject := Input;
  FRegEx.Replacement := Replacement;

  I := 0;
  if FRegEx.Match then
  begin
    repeat
      FRegEx.Replace;
      Inc(I)
    until (I = Count) or (not FRegEx.MatchAgain);
  end;
  Result := FRegEx.Subject;
end;

function TRegEx.Replace(const Input: string; Evaluator: TMatchEvaluator): string;
begin
  FRegEx.Subject := Input;
  FMatchEvaluator := Evaluator;
  FRegEx.OnReplace := Self.InternalOnReplace;
  try
    FRegEx.ReplaceAll;
    Result := FRegEx.Subject;
  finally
    FRegEx.OnReplace := nil;
    FMatchEvaluator := nil;
  end;
end;

function TRegEx.Replace(const Input: string; Evaluator: TMatchEvaluator; Count: Integer): string;
var
  I: Integer;
begin
  if Count = -1 then
  begin
    Result := Replace(Input, Evaluator);
    Exit;
  end;
  FRegEx.Subject := Input;
  FRegEx.OnReplace := Self.InternalOnReplace;
  FMatchEvaluator := Evaluator;

  try
    I := 0;
    if FRegEx.Match then
    begin
      repeat
        FRegEx.Replace;
        Inc(I)
      until (I = Count) or (not FRegEx.MatchAgain);
    end;
    Result := FRegEx.Subject;
  finally
    FRegEx.OnReplace := nil;
    FMatchEvaluator := nil;
  end;
end;

class function TRegEx.Replace(const Input, Pattern, Replacement: string;
  Options: TRegExOptions): string;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern, Options);
  Result := LRegEx.Replace(Input, Replacement);
end;

function TRegEx.Split(const Input: string): TArray<string>;
begin
  Result := Split(Input, 0, 1);
end;

function TRegEx.Split(const Input: string; Count: Integer): TArray<string>;
begin
  Result := Split(Input, Count, 1);
end;

function TRegEx.Split(const Input: string; Count, StartPos: Integer): TArray<string>;
var
  List: TStringList;
begin
  if Input <> '' then
  begin
    List := TStringList.Create;
    try
      FRegEx.Subject := Input;
      FRegEx.SplitCapture(List, Count, UnicodeIndexToUTF8(Input, StartPos) + 1);
      Result := List.ToStringArray;
    finally
      List.Free;
    end;
  end
  else
    SetLength(Result, 0);
end;

class function TRegEx.Split(const Input, Pattern: string): TArray<string>;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern);
  Result := LRegEx.Split(Input);
end;

class function TRegEx.Split(const Input, Pattern: string; Options: TRegExOptions): TArray<string>;
var
  LRegEx: TRegEx;
begin
  LRegEx := TRegEx.Create(Pattern, Options);
  Result := LRegEx.Split(Input);
end;

end.
