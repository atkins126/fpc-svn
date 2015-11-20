{ %cpu=i386 }
program tw29010a;

{$ifdef fpc}
  {$asmmode intel}
{$else fpc}
  {$apptype console}
{$endif fpc}

var
  Error: Boolean;

  esp_initial: longint;
  esp_after_push: longint;
  esp_final: longint;

  global_proc: procedure;
  global_word: word;
  global_longint: longint;

procedure check_esps(bytes: longint);
begin
  if (esp_initial - esp_after_push) <> bytes then
  begin
    Writeln('Wrong push size, expected ', bytes, ', got ', esp_initial - esp_after_push);
    Error := True;
  end;
  if (esp_final - esp_after_push) <> bytes then
  begin
    Writeln('Wrong pop size, expected ', bytes, ', got ', esp_final - esp_after_push);
    Error := True;
  end;
end;

procedure check_word;
begin
  check_esps(2);
end;

procedure check_dword;
begin
  check_esps(4);
end;

procedure testproc;
var
  local_proc: procedure;
  local_word: word;
  local_longint: longint;
begin
  Writeln('testing push/pop global_proc');
  asm
    mov esp_initial, esp
    push global_proc
    mov esp_after_push, esp
    pop global_proc
    mov esp_final, esp
    mov esp, esp_initial
    call check_dword
  end;

  Writeln('testing push/pop word [global_proc]');
  asm
    mov esp_initial, esp
    push word [global_proc]
    mov esp_after_push, esp
    pop word [global_proc]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;
  
  Writeln('testing push/pop word ptr global_proc');
  asm
    mov esp_initial, esp
    push word ptr global_proc
    mov esp_after_push, esp
    pop word ptr global_proc
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr [global_proc]');
  asm
    mov esp_initial, esp
    push word ptr [global_proc]
    mov esp_after_push, esp
    pop word ptr [global_proc]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop global_word');
  asm
    mov esp_initial, esp
    push global_word
    mov esp_after_push, esp
    pop global_word
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop global_longint');
  asm
    mov esp_initial, esp
    push global_longint
    mov esp_after_push, esp
    pop global_longint
    mov esp_final, esp
    mov esp, esp_initial
    call check_dword
  end;

  Writeln('testing push/pop word [global_longint]');
  asm
    mov esp_initial, esp
    push word [global_longint]
    mov esp_after_push, esp
    pop word [global_longint]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr global_longint');
  asm
    mov esp_initial, esp
    push word ptr global_longint
    mov esp_after_push, esp
    pop word ptr global_longint
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr [global_longint]');
  asm
    mov esp_initial, esp
    push word ptr [global_longint]
    mov esp_after_push, esp
    pop word ptr [global_longint]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop local_proc');
  asm
    mov esp_initial, esp
    push local_proc
    mov esp_after_push, esp
    pop local_proc
    mov esp_final, esp
    mov esp, esp_initial
    call check_dword
  end;

  Writeln('testing push/pop word [local_proc]');
  asm
    mov esp_initial, esp
    push word [local_proc]
    mov esp_after_push, esp
    pop word [local_proc]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr local_proc');
  asm
    mov esp_initial, esp
    push word ptr local_proc
    mov esp_after_push, esp
    pop word ptr local_proc
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr [local_proc]');
  asm
    mov esp_initial, esp
    push word ptr [local_proc]
    mov esp_after_push, esp
    pop word ptr [local_proc]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop local_word');
  asm
    mov esp_initial, esp
    push local_word
    mov esp_after_push, esp
    pop local_word
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop local_longint');
  asm
    mov esp_initial, esp
    push local_longint
    mov esp_after_push, esp
    pop local_longint
    mov esp_final, esp
    mov esp, esp_initial
    call check_dword
  end;

  Writeln('testing push/pop word [local_longint]');
  asm
    mov esp_initial, esp
    push word [local_longint]
    mov esp_after_push, esp
    pop word [local_longint]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr local_longint');
  asm
    mov esp_initial, esp
    push word ptr local_longint
    mov esp_after_push, esp
    pop word ptr local_longint
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;

  Writeln('testing push/pop word ptr [local_longint]');
  asm
    mov esp_initial, esp
    push word ptr [local_longint]
    mov esp_after_push, esp
    pop word ptr [local_longint]
    mov esp_final, esp
    mov esp, esp_initial
    call check_word
  end;
end;

begin
  Error := False;
  testproc;
  if Error then
  begin
    Writeln('Errors found!');
    Halt(1);
  end
  else
    Writeln('Ok!');
end.
