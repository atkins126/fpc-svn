{
    Copyright (c) 1998-2008 by Carl Eric Codere and Peter Vreman

    Does the parsing for the Z80 styled inline assembler.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

 ****************************************************************************
}
Unit raz80asm;

{$i fpcdefs.inc}

  Interface

    uses
      rasm,
      raz80,
      cpubase;

    type
      tasmtoken = (
        AS_NONE,AS_LABEL,AS_LLABEL,AS_STRING,AS_INTNUM,
        AS_COMMA,AS_LPAREN,
        AS_RPAREN,AS_COLON,AS_DOT,AS_PLUS,AS_MINUS,AS_STAR,
        AS_SEPARATOR,AS_ID,AS_REGISTER,AS_OPCODE,AS_SLASH,AS_DOLLAR,
        AS_HASH,AS_LSBRACKET,AS_RSBRACKET,AS_LBRACKET,AS_RBRACKET,
        AS_EQUAL,
        {------------------ Assembler directives --------------------}
        AS_DEFB,AS_DEFW
        );
      tasmkeyword = string[10];

    const
      { These tokens should be modified accordingly to the modifications }
      { in the different enumerations.                                   }
      firstdirective = AS_DEFB;
      lastdirective  = AS_DEFW;
      token2str : array[tasmtoken] of tasmkeyword=(
        '','Label','LLabel','string','integer',
        ',','(',
        ')',':','.','+','-','*',
        ';','identifier','register','opcode','/','$',
        '#','{','}','[',']',
        '=',
        'defb','defw');

    type

      { tz80reader }

      tz80reader = class(tasmreader)
        actasmtoken    : tasmtoken;
        function is_asmopcode(const s: string):boolean;
        function is_register(const s:string):boolean;
        //procedure handleopcode;override;
        //procedure BuildReference(oper : tz80operand);
        //procedure BuildOperand(oper : tz80operand);
        //procedure BuildOpCode(instr : tz80instruction);
        //procedure ReadSym(oper : tz80operand);
        procedure ConvertCalljmp(instr : tz80instruction);
      end;


  Implementation

    uses
      { helpers }
      cutils,
      { global }
      globtype,globals,verbose,
      systems,
      { aasm }
      cpuinfo,aasmbase,aasmtai,aasmdata,aasmcpu,
      { symtable }
      symconst,symbase,symtype,symsym,symtable,
      { parser }
      scanner,
      procinfo,
      rabase,rautils,
      cgbase,cgutils,cgobj
      ;


{*****************************************************************************
                                tz80reader
*****************************************************************************}


    function tz80reader.is_asmopcode(const s: string):boolean;
      begin
        actcondition:=C_None;
        actopcode:=tasmop(PtrUInt(iasmops.Find(s)));
        if actopcode<>A_NONE then
          begin
            actasmtoken:=AS_OPCODE;
            is_asmopcode:=true;
          end
        else
          is_asmopcode:=false;
      end;


    function tz80reader.is_register(const s:string):boolean;
      begin
        is_register:=false;
        actasmregister:=std_regnum_search(lower(s));
        if actasmregister<>NR_NO then
          begin
            is_register:=true;
            actasmtoken:=AS_REGISTER;
          end;
      end;


    //procedure tz80reader.ReadSym(oper : tz80operand);
    //  var
    //    tempstr, mangledname : string;
    //    typesize,l,k : aint;
    //  begin
    //    tempstr:=actasmpattern;
    //    Consume(AS_ID);
    //    { typecasting? }
    //    if (actasmtoken=AS_LPAREN) and
    //       SearchType(tempstr,typesize) then
    //     begin
    //       oper.hastype:=true;
    //       Consume(AS_LPAREN);
    //       BuildOperand(oper);
    //       Consume(AS_RPAREN);
    //       if oper.opr.typ in [OPR_REFERENCE,OPR_LOCAL] then
    //         oper.SetSize(typesize,true);
    //     end
    //    else
    //     if not oper.SetupVar(tempstr,false) then
    //      Message1(sym_e_unknown_id,tempstr);
    //    { record.field ? }
    //    if actasmtoken=AS_DOT then
    //     begin
    //       BuildRecordOffsetSize(tempstr,l,k,mangledname,false);
    //       if (mangledname<>'') then
    //         Message(asmr_e_invalid_reference_syntax);
    //       inc(oper.opr.ref.offset,l);
    //     end;
    //  end;


    //Procedure tz80attreader.BuildReference(oper : tz80operand);
    //
    //  procedure Consume_RParen;
    //    begin
    //      if actasmtoken<>AS_RPAREN then
    //       Begin
    //         Message(asmr_e_invalid_reference_syntax);
    //         RecoverConsume(true);
    //       end
    //      else
    //       begin
    //         Consume(AS_RPAREN);
    //         if not (actasmtoken in [AS_COMMA,AS_SEPARATOR,AS_END]) then
    //          Begin
    //            Message(asmr_e_invalid_reference_syntax);
    //            RecoverConsume(true);
    //          end;
    //       end;
    //    end;


      //procedure read_index;
      //  begin
      //    Consume(AS_COMMA);
      //    if actasmtoken=AS_REGISTER then
      //      Begin
      //        oper.opr.ref.index:=actasmregister;
      //        Consume(AS_REGISTER);
      //      end
      //    else if actasmtoken=AS_HASH then
      //      begin
      //        Consume(AS_HASH);
      //        inc(oper.opr.ref.offset,BuildConstExpression(false,true));
      //      end;
      //  end;


      //begin
      //  Consume(AS_LPAREN);
      //  if actasmtoken=AS_REGISTER then
      //    begin
      //      oper.opr.ref.base:=actasmregister;
      //      Consume(AS_REGISTER);
      //      { can either be a register or a right parenthesis }
      //      { (reg)        }
      //      if actasmtoken=AS_LPAREN then
      //       Begin
      //         Consume_RParen;
      //         exit;
      //       end;
      //      if actasmtoken=AS_PLUS then
      //        begin
      //          consume(AS_PLUS);
      //          oper.opr.ref.addressmode:=AM_POSTINCREMENT;
      //        end;
      //    end {end case }
      //  else
      //    Begin
      //      Message(asmr_e_invalid_reference_syntax);
      //      RecoverConsume(false);
      //    end;
      //end;


    //Procedure tz80reader.BuildOperand(oper : tz80operand);
    //  var
    //    expr : string;
    //    typesize,l : aint;
    //
    //
    //    procedure AddLabelOperand(hl:tasmlabel);
    //      begin
    //        if not(actasmtoken in [AS_PLUS,AS_MINUS,AS_LPAREN]) { and
    //           is_calljmp(actopcode) } then
    //         begin
    //           oper.opr.typ:=OPR_SYMBOL;
    //           oper.opr.symbol:=hl;
    //         end
    //        else
    //         begin
    //           oper.InitRef;
    //           oper.opr.ref.symbol:=hl;
    //         end;
    //      end;
    //
    //
    //    procedure MaybeRecordOffset;
    //      var
    //        mangledname: string;
    //        hasdot  : boolean;
    //        l,
    //        toffset,
    //        tsize   : aint;
    //      begin
    //        if not(actasmtoken in [AS_DOT,AS_PLUS,AS_MINUS]) then
    //         exit;
    //        l:=0;
    //        mangledname:='';
    //        hasdot:=(actasmtoken=AS_DOT);
    //        if hasdot then
    //          begin
    //            if expr<>'' then
    //              begin
    //                BuildRecordOffsetSize(expr,toffset,tsize,mangledname,false);
    //                if (oper.opr.typ<>OPR_CONSTANT) and
    //                   (mangledname<>'') then
    //                  Message(asmr_e_wrong_sym_type);
    //                inc(l,toffset);
    //                oper.SetSize(tsize,true);
    //              end;
    //          end;
    //        if actasmtoken in [AS_PLUS,AS_MINUS] then
    //          inc(l,BuildConstExpression(true,false));
    //        case oper.opr.typ of
    //          OPR_LOCAL :
    //            begin
    //              { don't allow direct access to fields of parameters, because that
    //                will generate buggy code. Allow it only for explicit typecasting }
    //              if hasdot and
    //                 (not oper.hastype) and
    //                 (tabstractnormalvarsym(oper.opr.localsym).owner.symtabletype=parasymtable) and
    //                 (current_procinfo.procdef.proccalloption<>pocall_register) then
    //                Message(asmr_e_cannot_access_field_directly_for_parameters);
    //              inc(oper.opr.localsymofs,l)
    //            end;
    //          OPR_CONSTANT :
    //            inc(oper.opr.val,l);
    //          OPR_REFERENCE :
    //            if (mangledname<>'') then
    //              begin
    //                if (oper.opr.val<>0) then
    //                  Message(asmr_e_wrong_sym_type);
    //                oper.opr.typ:=OPR_SYMBOL;
    //                oper.opr.symbol:=current_asmdata.RefAsmSymbol(mangledname,AT_FUNCTION);
    //              end
    //            else
    //              inc(oper.opr.val,l);
    //          OPR_SYMBOL:
    //            Message(asmr_e_invalid_symbol_ref);
    //          else
    //            internalerror(200309221);
    //        end;
    //      end;
    //
    //
    //    function MaybeBuildReference:boolean;
    //      { Try to create a reference, if not a reference is found then false
    //        is returned }
    //      begin
    //        MaybeBuildReference:=true;
    //        case actasmtoken of
    //          AS_INTNUM,
    //          AS_MINUS,
    //          AS_PLUS:
    //            Begin
    //              oper.opr.ref.offset:=BuildConstExpression(True,False);
    //              if actasmtoken<>AS_LPAREN then
    //                Message(asmr_e_invalid_reference_syntax)
    //              else
    //                BuildReference(oper);
    //            end;
    //          AS_LPAREN:
    //            BuildReference(oper);
    //          AS_ID: { only a variable is allowed ... }
    //            Begin
    //              ReadSym(oper);
    //              case actasmtoken of
    //                AS_END,
    //                AS_SEPARATOR,
    //                AS_COMMA: ;
    //                AS_LPAREN:
    //                  BuildReference(oper);
    //              else
    //                Begin
    //                  Message(asmr_e_invalid_reference_syntax);
    //                  Consume(actasmtoken);
    //                end;
    //              end; {end case }
    //            end;
    //          else
    //           MaybeBuildReference:=false;
    //        end; { end case }
    //      end;
    //
    //
    //  var
    //    tempreg : tregister;
    //    ireg : tsuperregister;
    //    hl : tasmlabel;
    //    ofs : longint;
    //    registerset : tcpuregisterset;
    //    tempstr : string;
    //    tempsymtyp : tasmsymtype;
    //  Begin
    //    expr:='';
    //    case actasmtoken of
    //      AS_LBRACKET: { Memory reference or constant expression }
    //        Begin
    //          oper.InitRef;
    //          BuildReference(oper);
    //        end;
    //
    //      AS_INTNUM,
    //      AS_MINUS,
    //      AS_PLUS:
    //        Begin
    //          if (actasmtoken=AS_MINUS) and
    //             (actopcode in [A_LD,A_ST]) then
    //            begin
    //              { Special handling of predecrement addressing }
    //              oper.InitRef;
    //              oper.opr.ref.addressmode:=AM_PREDRECEMENT;
    //
    //              consume(AS_MINUS);
    //
    //              if actasmtoken=AS_REGISTER then
    //                begin
    //                  oper.opr.ref.base:=actasmregister;
    //                  consume(AS_REGISTER);
    //                end
    //              else
    //                begin
    //                  Message(asmr_e_invalid_reference_syntax);
    //                  RecoverConsume(false);
    //                end;
    //            end
    //          else
    //            begin
    //              { Constant memory offset }
    //              { This must absolutely be followed by (  }
    //              oper.InitRef;
    //              oper.opr.ref.offset:=BuildConstExpression(True,False);
    //
    //              { absolute memory addresss? }
    //              if actopcode in [A_LDS,A_STS] then
    //                BuildReference(oper)
    //              else
    //                begin
    //                  ofs:=oper.opr.ref.offset;
    //                  BuildConstantOperand(oper);
    //                  inc(oper.opr.val,ofs);
    //                end;
    //            end;
    //        end;
    //
    //      AS_ID: { A constant expression, or a Variable ref.  }
    //        Begin
    //          if (actasmpattern='LO8') or (actasmpattern='HI8') then
    //            begin
    //              { Low or High part of a constant (or constant
    //                memory location) }
    //              oper.InitRef;
    //              if actasmpattern='LO8' then
    //                oper.opr.ref.refaddr:=addr_lo8
    //              else
    //                oper.opr.ref.refaddr:=addr_hi8;
    //              Consume(actasmtoken);
    //              Consume(AS_LPAREN);
    //              BuildConstSymbolExpression(false, true,false,l,tempstr,tempsymtyp);
    //              if not assigned(oper.opr.ref.symbol) then
    //                oper.opr.ref.symbol:=current_asmdata.RefAsmSymbol(tempstr,tempsymtyp)
    //              else
    //                Message(asmr_e_cant_have_multiple_relocatable_symbols);
    //              case oper.opr.typ of
    //                OPR_CONSTANT :
    //                  inc(oper.opr.val,l);
    //                OPR_LOCAL :
    //                  inc(oper.opr.localsymofs,l);
    //                OPR_REFERENCE :
    //                  inc(oper.opr.ref.offset,l);
    //                else
    //                  internalerror(200309202);
    //              end;
    //              Consume(AS_RPAREN);
    //            end
    //          { Local Label ? }
    //          else if is_locallabel(actasmpattern) then
    //           begin
    //             CreateLocalLabel(actasmpattern,hl,false);
    //             Consume(AS_ID);
    //             AddLabelOperand(hl);
    //           end
    //          { Check for label }
    //          else if SearchLabel(actasmpattern,hl,false) then
    //            begin
    //              Consume(AS_ID);
    //              AddLabelOperand(hl);
    //            end
    //          else
    //           { probably a variable or normal expression }
    //           { or a procedure (such as in CALL ID)      }
    //           Begin
    //             { is it a constant ? }
    //             if SearchIConstant(actasmpattern,l) then
    //              Begin
    //                if not (oper.opr.typ in [OPR_NONE,OPR_CONSTANT]) then
    //                 Message(asmr_e_invalid_operand_type);
    //                BuildConstantOperand(oper);
    //              end
    //             else
    //              begin
    //                expr:=actasmpattern;
    //                Consume(AS_ID);
    //                { typecasting? }
    //                if (actasmtoken=AS_LPAREN) and
    //                   SearchType(expr,typesize) then
    //                 begin
    //                   oper.hastype:=true;
    //                   Consume(AS_LPAREN);
    //                   BuildOperand(oper);
    //                   Consume(AS_RPAREN);
    //                   if oper.opr.typ in [OPR_REFERENCE,OPR_LOCAL] then
    //                     oper.SetSize(typesize,true);
    //                 end
    //                else
    //                 begin
    //                   if not(oper.SetupVar(expr,false)) then
    //                    Begin
    //                      { look for special symbols ... }
    //                      if expr= '__HIGH' then
    //                        begin
    //                          consume(AS_LPAREN);
    //                          if not oper.setupvar('high'+actasmpattern,false) then
    //                            Message1(sym_e_unknown_id,'high'+actasmpattern);
    //                          consume(AS_ID);
    //                          consume(AS_RPAREN);
    //                        end
    //                      else
    //                       if expr = '__RESULT' then
    //                        oper.SetUpResult
    //                      else
    //                       if expr = '__SELF' then
    //                        oper.SetupSelf
    //                      else
    //                       if expr = '__OLDEBP' then
    //                        oper.SetupOldEBP
    //                      else
    //                        Message1(sym_e_unknown_id,expr);
    //                    end;
    //                 end;
    //              end;
    //              if actasmtoken=AS_DOT then
    //                MaybeRecordOffset;
    //              { add a constant expression? }
    //              if (actasmtoken=AS_PLUS) then
    //               begin
    //                 l:=BuildConstExpression(true,false);
    //                 case oper.opr.typ of
    //                   OPR_CONSTANT :
    //                     inc(oper.opr.val,l);
    //                   OPR_LOCAL :
    //                     inc(oper.opr.localsymofs,l);
    //                   OPR_REFERENCE :
    //                     inc(oper.opr.ref.offset,l);
    //                   else
    //                     internalerror(200309202);
    //                 end;
    //               end
    //           end;
    //          { Do we have a indexing reference, then parse it also }
    //          if actasmtoken=AS_LPAREN then
    //            BuildReference(oper);
    //        end;
    //
    //      { Register, a variable reference or a constant reference  }
    //      AS_REGISTER:
    //        Begin
    //          { save the type of register used. }
    //          tempreg:=actasmregister;
    //          Consume(AS_REGISTER);
    //          if (actasmtoken=AS_PLUS) then
    //            begin
    //              oper.opr.typ:=OPR_REFERENCE;
    //
    //              reference_reset_base(oper.opr.ref,tempreg,0,1,[]);
    //              oper.opr.ref.addressmode:=AM_POSTINCREMENT;
    //
    //              consume(AS_PLUS);
    //            end
    //          else if (actasmtoken in [AS_END,AS_SEPARATOR,AS_COMMA]) then
    //            Begin
    //              if not (oper.opr.typ in [OPR_NONE,OPR_REGISTER]) then
    //                Message(asmr_e_invalid_operand_type);
    //              oper.opr.typ:=OPR_REGISTER;
    //              oper.opr.reg:=tempreg;
    //            end
    //          else
    //            Message(asmr_e_syn_operand);
    //        end;
    //
    //      AS_END,
    //      AS_SEPARATOR,
    //      AS_COMMA: ;
    //    else
    //      Begin
    //        Message(asmr_e_syn_operand);
    //        Consume(actasmtoken);
    //      end;
    //    end; { end case }
    //  end;


    //procedure tz80reader.BuildOpCode(instr : tz80instruction);
    //  var
    //    operandnum : longint;
    //  Begin
    //    { opcode }
    //    if (actasmtoken<>AS_OPCODE) then
    //     Begin
    //       Message(asmr_e_invalid_or_missing_opcode);
    //       RecoverConsume(true);
    //       exit;
    //     end;
    //    { Fill the instr object with the current state }
    //    with instr do
    //      begin
    //        Opcode:=ActOpcode;
    //        condition:=ActCondition;
    //      end;
    //
    //    { We are reading operands, so opcode will be an AS_ID }
    //    operandnum:=1;
    //    Consume(AS_OPCODE);
    //    { Zero operand opcode ?  }
    //    if actasmtoken in [AS_SEPARATOR,AS_END] then
    //     begin
    //       operandnum:=0;
    //       exit;
    //     end;
    //    { Read the operands }
    //    repeat
    //      case actasmtoken of
    //        AS_COMMA: { Operand delimiter }
    //          Begin
    //            if operandnum>Max_Operands then
    //              Message(asmr_e_too_many_operands)
    //            else
    //              Inc(operandnum);
    //            Consume(AS_COMMA);
    //          end;
    //        AS_SEPARATOR,
    //        AS_END : { End of asm operands for this opcode  }
    //          begin
    //            break;
    //          end;
    //      else
    //        BuildOperand(instr.Operands[operandnum] as tz80operand);
    //      end; { end case }
    //    until false;
    //    instr.Ops:=operandnum;
    //  end;


    procedure tz80reader.ConvertCalljmp(instr : tz80instruction);
      var
        newopr : toprrec;
      begin
        if instr.Operands[1].opr.typ=OPR_REFERENCE then
          begin
            newopr.typ:=OPR_SYMBOL;
            newopr.symbol:=instr.Operands[1].opr.ref.symbol;
            newopr.symofs:=instr.Operands[1].opr.ref.offset;
            if (instr.Operands[1].opr.ref.base<>NR_NO) or
              (instr.Operands[1].opr.ref.index<>NR_NO) then
              Message(asmr_e_syn_operand);
            instr.Operands[1].opr:=newopr;
          end;
      end;


    //procedure tz80reader.handleopcode;
    //  var
    //    instr : tz80instruction;
    //  begin
    //    instr:=tz80instruction.Create(tz80operand);
    //    BuildOpcode(instr);
{   //     if is_calljmp(instr.opcode) then
    //      ConvertCalljmp(instr); }
    //    {
    //    instr.AddReferenceSizes;
    //    instr.SetInstructionOpsize;
    //    instr.CheckOperandSizes;
    //    }
    //    instr.ConcatInstruction(curlist);
    //    instr.Free;
    //  end;


{*****************************************************************************
                                     Initialize
*****************************************************************************}

const
{  asmmode_z80_att_info : tasmmodeinfo =
          (
            id    : asmmode_z80_gas;
            idtxt : 'GAS';
            casmreader : tz80attreader;
          );}

  asmmode_z80_standard_info : tasmmodeinfo =
          (
            id    : asmmode_standard;
            idtxt : 'STANDARD';
            casmreader : tz80reader;
          );

initialization
//  RegisterAsmMode(asmmode_z80_att_info);
  RegisterAsmMode(asmmode_z80_standard_info);
end.
