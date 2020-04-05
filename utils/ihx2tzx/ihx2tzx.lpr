{ IHX (Intel Hex format) to TZX (ZX Spectrum tape file format) convertor tool

  This is the main program of the tool.

  Copyright (C) 2020 Nikolay Nikolov <nickysn@users.sourceforg.net>

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
  Boston, MA 02110-1335, USA.
}

program ihx2tzx;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, CustApp, ihxreader, tzxwriter, zxbasic
  { you can add units after this };

const
  ShortOptions = 'h';
  LongOptions: array [0..0] of string = (
    'help'
  );

type

  { TIHX2TZX }

  TIHX2TZX = class(TCustomApplication)
  private
    FInputFileName: string;
    FOutputFileName: string;
    FInputImage: TIHXReader;
    FOutputFile: TStream;
    FTapeWriter: TTZXWriter;
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    procedure WriteHelp; virtual;
  end;

{ TIHX2TZX }

procedure TIHX2TZX.DoRun;
var
  ErrorMsg: String;
  NonOptions: TStringArray;
  BasicProgram: AnsiString;
begin
  // quick check parameters
  ErrorMsg:=CheckOptions(ShortOptions, LongOptions);
  if ErrorMsg<>'' then begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  NonOptions := GetNonOptions(ShortOptions, LongOptions);
  if Length(NonOptions) = 0 then
  begin
    ShowException(Exception.Create('Missing input file'));
    Terminate;
    Exit;
  end;
  if Length(NonOptions) > 2 then
  begin
    ShowException(Exception.Create('Too many files specified'));
    Terminate;
    Exit;
  end;
  FInputFileName := NonOptions[0];
  if Length(NonOptions) >= 2 then
    FOutputFileName := NonOptions[1]
  else
    FOutputFileName := ChangeFileExt(FInputFileName, '.tzx');

  { add your program here }
  FInputImage.ReadIHXFile(FInputFileName);

  FOutputFile := TFileStream.Create(FOutputFileName, fmCreate);
  FTapeWriter := TTZXWriter.Create(FOutputFile);

  BasicProgram := BAS_EncodeLine(10, ' '+BC_LOAD+'"" '+BC_CODE) +
                  BAS_EncodeLine(20, ' '+BC_PRINT+BC_USR+BAS_EncodeNumber(FInputImage.Origin));

  FTapeWriter.AppendProgramFile('basic', 10, Length(BasicProgram), BasicProgram[1], Length(BasicProgram));
  FTapeWriter.AppendCodeFile('test', FInputImage.Origin, FInputImage.Data[0], Length(FInputImage.Data));

  // stop program loop
  Terminate;
end;

constructor TIHX2TZX.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException:=True;
  FInputImage := TIHXReader.Create;
end;

destructor TIHX2TZX.Destroy;
begin
  FreeAndNil(FInputImage);
  FreeAndNil(FTapeWriter);
  FreeAndNil(FOutputFile);
  inherited Destroy;
end;

procedure TIHX2TZX.WriteHelp;
begin
  { add your help code here }
  writeln('Usage: ', ExeName, ' [options] ihx_file [tzx_file]');
end;

var
  Application: TIHX2TZX;
begin
  Application:=TIHX2TZX.Create(nil);
  Application.Title:='ihx2tzx';
  Application.Run;
  Application.Free;
end.

