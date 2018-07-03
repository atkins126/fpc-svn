{
    This file is part of the Free Pascal run time library.
    and implements some stuff for protected mode programming
    Copyright (c) 1999-2000 by the Free Pascal development team.

    These files adds support for TP styled port accesses

    See the file COPYING.FPC, included in this distribution,
    for details about the copyright.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

 **********************************************************************}

unit ports;

{$inline on}

interface

type
   tport = object
      procedure writeport(p : word;data : byte);inline;
      function  readport(p : word) : byte;inline;
      property pp[w : word] : byte read readport write writeport;default;
   end;

   tportw = object
      procedure writeport(p : word;data : word);inline;
      function  readport(p : word) : word;inline;
      property pp[w : word] : word read readport write writeport;default;
   end;

   tportl = object
      procedure writeport(p : word;data : longint);
      function  readport(p : word) : longint;
      property pp[w : word] : longint read readport write writeport;default;
   end;

var
{ we don't need to initialize port, because neither member
  variables nor virtual methods are accessed }
   port,
   portb : tport;
   portw : tportw;
   portl : tportl;

  implementation

{ to give easy port access like tp with port[] }

procedure tport.writeport(p : word;data : byte);inline;
begin
  fpc_x86_outportb(p,data);
end;


function tport.readport(p : word) : byte;inline;
begin
  readport:=fpc_x86_inportb(p);
end;


procedure tportw.writeport(p : word;data : word);inline;
begin
  fpc_x86_outportw(p,data);
end;


function tportw.readport(p : word) : word;inline;
begin
  readport:=fpc_x86_inportw(p);
end;


{$asmcpu 80386}
procedure tportl.writeport(p : word;data : longint);assembler;
asm
  mov dx, p
  mov eax, data
  out dx, eax
end;


function tportl.readport(p : word) : longint;assembler;
asm
  mov dx, p
  in eax, dx
  mov edx, eax
  shr edx, 16
end;

end.
