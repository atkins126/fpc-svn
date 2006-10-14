{
    This file is part of the Free Pascal packages.
    Copyright (c) 1999-2000 by the Free Pascal development team

    Tests the MD5 program.

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

program md5test;

{$h+}

uses md5, ntlm;

var
  I: byte;

const
  Suite: array[1..7] of string = (
    '',
    'a',
    'abc',
    'message digest',
    'abcdefghijklmnopqrstuvwxyz',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789',
    '12345678901234567890123456789012345678901234567890123456789012345678901234567890'
    );

begin
  Writeln('Executing RFC 1320 test suite ...');
  for I := 1 to 7 do
    Writeln('MD4 ("',Suite[i],'") = ',MDPrint(MDString(Suite[I], 4)));
  Writeln();
  Writeln('md4file (50)  : ',MDPrint(MDFile('md5test.pp',4,50)));
  Writeln('md4file (def) : ',MDPrint(MDFile('md5test.pp',4)));
  Writeln;

  Writeln('Executing RFC 1321 test suite ...');
  for I := 1 to 7 do
    Writeln('MD5 ("',Suite[i],'") = ',MDPrint(MDString(Suite[I], 5)));
  Writeln();
  Writeln('md5file (50)  : ',MDPrint(MDFile('md5test.pp',5,50)));
  Writeln('md5file (def) : ',MDPrint(MDFile('md5test.pp',5)));
  Writeln;

  Writeln('nt-password   : ',MDPrint(NTGenerate('foobar')));
  Writeln('lm-password   : ',MDPrint(LMGenerate('foobar')));
end.
