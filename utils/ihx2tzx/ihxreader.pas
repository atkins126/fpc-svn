{ <description>

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

unit ihxreader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type

  { TIHXReader }

  TIHXReader = class
  private
    FOrigin: Word;
  public
    Data: array of Byte;

    procedure ReadIHXFile(const FileName: string);

    property Origin: Word read FOrigin;
  end;

implementation

{ TIHXReader }

procedure TIHXReader.ReadIHXFile(const FileName: string);
var
  InF: TextFile;
  S: string;
  I: Integer;
  LineByteCount: Byte;
  LineAddress: Word;
  PrevLineAddress: LongInt = -1;
  RecordType: Byte;
  Checksum, ExpectedChecksum: Byte;
  B: Byte;
  OriginSet: Boolean = False;
begin
  FOrigin := 0;
  SetLength(Data, 0);
  AssignFile(InF, FileName);
  Reset(InF);
  try
    while not EoF(InF) do
    begin
      ReadLn(InF, S);
      S:=UpperCase(Trim(S));
      if S='' then
        continue;
      if Length(S)<11 then
        raise Exception.Create('Line too short');
      if S[1]<>':' then
        raise Exception.Create('Line must start with '':''');
      for I:=2 to Length(S) do
        if not (S[I] in ['0'..'9','A'..'F']) then
          raise Exception.Create('Line contains an invalid character');
      LineByteCount:=StrToInt('$'+Copy(S,2,2));
      if (LineByteCount*2+11)<>Length(S) then
        raise Exception.Create('Invalid line length');
      LineAddress:=StrToInt('$'+Copy(S,4,4));
      if (PrevLineAddress <> -1) and (PrevLineAddress < LineAddress) then
        SetLength(Data, Length(Data) + (LineAddress - PrevLineAddress));
      RecordType:=StrToInt('$'+Copy(S,8,2));
      Checksum:=StrToInt('$'+Copy(S,Length(S)-1,2));
      ExpectedChecksum := Byte(LineByteCount + RecordType + Byte(LineAddress) + Byte(LineAddress shr 8));
      if not OriginSet then
      begin
        OriginSet := True;
        FOrigin := LineAddress;
      end;
      for I:=0 to LineByteCount-1 do
      begin
        B := StrToInt('$' + Copy(S, 10 + 2*I, 2));
        ExpectedChecksum := Byte(ExpectedChecksum + B);
      end;
      ExpectedChecksum := Byte(-ExpectedChecksum);
      if ExpectedChecksum <> Checksum then
        raise Exception.Create('Invalid checksum');
      case RecordType of
        0:
          begin
            SetLength(Data, Length(Data) + LineByteCount);
            for I:=0 to LineByteCount-1 do
            begin
              B := StrToInt('$' + Copy(S, 10 + 2*I, 2));
              Data[High(Data) - (LineByteCount-1) + I] := B;
            end;
          end;
        1:
          begin
            { end of file }
            break;
          end;
      end;
      PrevLineAddress := LineAddress + LineByteCount;
    end;
  finally
    CloseFile(InF);
  end;
end;

end.

