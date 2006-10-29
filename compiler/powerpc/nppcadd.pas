{
    Copyright (c) 2000-2002 by Florian Klaempfl and Jonas Maebe

    Code generation for add nodes on the PowerPC

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
unit nppcadd;

{$i fpcdefs.inc}

interface

    uses
       node,nadd,ncgadd,ngppcadd,cpubase;

    type
       tppcaddnode = class(tgenppcaddnode)
          procedure pass_generate_code;override;
         protected
          function use_generic_mul32to64: boolean; override;
         private
          procedure emit_compare(unsigned : boolean); override;
{$ifdef SUPPORT_MMX}
          procedure second_addmmx;override;
{$endif SUPPORT_MMX}
          procedure second_add64bit;override;
       end;

  implementation

    uses
      globtype,systems,
      cutils,verbose,globals,
      symconst,symdef,paramgr,
      aasmbase,aasmtai,aasmdata,aasmcpu,defutil,htypechk,
      cgbase,cpuinfo,pass_1,pass_2,regvars,
      cpupara,cgcpu,cgutils,procinfo,
      ncon,nset,
      ncgutil,tgobj,rgobj,rgcpu,cgobj,cg64f32;


{*****************************************************************************
                                  Pass 1
*****************************************************************************}

   function tppcaddnode.use_generic_mul32to64: boolean;
     begin
       result := false;
     end;

{*****************************************************************************
                                  Helpers
*****************************************************************************}

    procedure tppcaddnode.emit_compare(unsigned: boolean);
      var
        op : tasmop;
        tmpreg : tregister;
        useconst : boolean;
      begin
        // get the constant on the right if there is one
        if (left.location.loc = LOC_CONSTANT) then
          swapleftright;
        // can we use an immediate, or do we have to load the
        // constant in a register first?
        if (right.location.loc = LOC_CONSTANT) then
          begin
{$ifdef dummy}
            if (right.location.size in [OS_64,OS_S64]) and (hi(right.location.value64)<>0) and ((hi(right.location.value64)<>$ffffffff) or unsigned) then
              internalerror(2002080301);
{$endif extdebug}
            if (nodetype in [equaln,unequaln]) then
              if (unsigned and
                  (aword(right.location.value) > high(word))) or
                 (not unsigned and
                  (aint(right.location.value) < low(smallint)) or
                   (aint(right.location.value) > high(smallint))) then
                { we can then maybe use a constant in the 'othersigned' case
                 (the sign doesn't matter for // equal/unequal)}
                unsigned := not unsigned;

            if (unsigned and
                (aword(right.location.value) <= high(word))) or
               (not(unsigned) and
                (aint(right.location.value) >= low(smallint)) and
                (aint(right.location.value) <= high(smallint))) then
               useconst := true
            else
              begin
                useconst := false;
                tmpreg := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                cg.a_load_const_reg(current_asmdata.CurrAsmList,OS_INT,
                    right.location.value,tmpreg);
               end
          end
        else
          useconst := false;
        location.loc := LOC_FLAGS;
        location.resflags := getresflags;
        if not unsigned then
          if useconst then
            op := A_CMPWI
          else
            op := A_CMPW
        else
          if useconst then
            op := A_CMPLWI
          else
            op := A_CMPLW;

        if (right.location.loc = LOC_CONSTANT) then
          begin
            if useconst then
              current_asmdata.CurrAsmList.concat(taicpu.op_reg_const(op,left.location.register,longint(right.location.value)))
            else
              current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(op,left.location.register,tmpreg));
          end
        else
          current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(op,
            left.location.register,right.location.register));
      end;


{*****************************************************************************
                                Add64bit
*****************************************************************************}

    procedure tppcaddnode.second_add64bit;
      var
        op         : TOpCG;
        op1,op2    : TAsmOp;
        cmpop,
        unsigned   : boolean;


      procedure emit_cmp64_hi;

        var
          oldleft, oldright: tlocation;
        begin
          // put the high part of the location in the low part
          location_copy(oldleft,left.location);
          location_copy(oldright,right.location);
          if left.location.loc = LOC_CONSTANT then
            left.location.value64 := left.location.value64 shr 32
          else
            left.location.register64.reglo := left.location.register64.reghi;
          if right.location.loc = LOC_CONSTANT then
            right.location.value64 := right.location.value64 shr 32
          else
            right.location.register64.reglo := right.location.register64.reghi;

          // and call the normal emit_compare
          emit_compare(unsigned);
          location_copy(left.location,oldleft);
          location_copy(right.location,oldright);
        end;


      procedure emit_cmp64_lo;

        begin
          emit_compare(true);
        end;


      procedure firstjmp64bitcmp;

        var
          oldnodetype: tnodetype;
        begin
{$ifdef OLDREGVARS}
           load_all_regvars(current_asmdata.CurrAsmList);
{$endif OLDREGVARS}
           { the jump the sequence is a little bit hairy }
           case nodetype of
              ltn,gtn:
                begin
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrTrueLabel);
                   { cheat a little bit for the negative test }
                   toggleflag(nf_swaped);
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrFalseLabel);
                   toggleflag(nf_swaped);
                end;
              lten,gten:
                begin
                   oldnodetype:=nodetype;
                   if nodetype=lten then
                     nodetype:=ltn
                   else
                     nodetype:=gtn;
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrTrueLabel);
                   { cheat for the negative test }
                   if nodetype=ltn then
                     nodetype:=gtn
                   else
                     nodetype:=ltn;
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrFalseLabel);
                   nodetype:=oldnodetype;
                end;
              equaln:
                begin
                  nodetype := unequaln;
                  cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrFalseLabel);
                  nodetype := equaln;
                end;
              unequaln:
                begin
                  cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrTrueLabel);
                end;
           end;
        end;


      procedure secondjmp64bitcmp;

        begin
           { the jump the sequence is a little bit hairy }
           case nodetype of
              ltn,gtn,lten,gten:
                begin
                   { the comparison of the low dword always has }
                   { to be always unsigned!                     }
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrTrueLabel);
                   cg.a_jmp_always(current_asmdata.CurrAsmList,current_procinfo.CurrFalseLabel);
                end;
              equaln:
                begin
                   nodetype := unequaln;
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrFalseLabel);
                   cg.a_jmp_always(current_asmdata.CurrAsmList,current_procinfo.CurrTrueLabel);
                   nodetype := equaln;
                end;
              unequaln:
                begin
                   cg.a_jmp_flags(current_asmdata.CurrAsmList,getresflags,current_procinfo.CurrTrueLabel);
                   cg.a_jmp_always(current_asmdata.CurrAsmList,current_procinfo.CurrFalseLabel);
                end;
           end;
        end;


    var
      tempreg64: tregister64;

      begin
        firstcomplex(self);

        pass_left_and_right;

        cmpop:=false;
        unsigned:=((left.resultdef.deftype=orddef) and
                   (torddef(left.resultdef).typ=u64bit)) or
                  ((right.resultdef.deftype=orddef) and
                   (torddef(right.resultdef).typ=u64bit));
        case nodetype of
          addn :
            begin
              op:=OP_ADD;
            end;
          subn :
            begin
              op:=OP_SUB;
              if (nf_swaped in flags) then
                swapleftright;
            end;
          ltn,lten,
          gtn,gten,
          equaln,unequaln:
            begin
              op:=OP_NONE;
              cmpop:=true;
            end;
          xorn:
            op:=OP_XOR;
          orn:
            op:=OP_OR;
          andn:
            op:=OP_AND;
          muln:
            begin
              { should be handled in pass_1 (JM) }
              if not(torddef(left.resultdef).typ in [U32bit,s32bit]) or
                 (torddef(left.resultdef).typ <> torddef(right.resultdef).typ) then
                internalerror(200109051);
              { handled separately }
              op := OP_NONE;
            end;
          else
            internalerror(2002072705);
        end;

        if not cmpop then
          location_reset(location,LOC_REGISTER,def_cgsize(resultdef));

        load_left_right(cmpop,((cs_check_overflow in aktlocalswitches) and
            (nodetype in [addn,subn])) or (nodetype = muln));

        if (nodetype <> muln) and
           (not(cs_check_overflow in aktlocalswitches) or
            not(nodetype in [addn,subn])) then
          begin
            case nodetype of
              ltn,lten,
              gtn,gten:
                begin
                  emit_cmp64_hi;
                  firstjmp64bitcmp;
                  emit_cmp64_lo;
                  secondjmp64bitcmp;
                end;
              equaln,unequaln:
                begin
                  // instead of doing a complicated compare, do
                  // (left.hi xor right.hi) or (left.lo xor right.lo)
                  // (somewhate optimized so that no superfluous 'mr's are
                  //  generated)
                  if (left.location.loc = LOC_CONSTANT) then
                    swapleftright;
                  if (right.location.loc = LOC_CONSTANT) then
                    begin
                      if left.location.loc = LOC_REGISTER then
                        begin
                          tempreg64.reglo := left.location.register64.reglo;
                          tempreg64.reghi := left.location.register64.reghi;
                        end
                      else
                        begin
                          if (aint(right.location.value64) <> 0) then
                            tempreg64.reglo := cg.getintregister(current_asmdata.CurrAsmList,OS_32)
                          else
                            tempreg64.reglo := left.location.register64.reglo;
                          if ((right.location.value64 shr 32) <> 0) then
                            tempreg64.reghi := cg.getintregister(current_asmdata.CurrAsmList,OS_32)
                          else
                            tempreg64.reghi := left.location.register64.reghi;
                        end;

                      if (aint(right.location.value64) <> 0) then
                        { negative values can be handled using SUB, }
                        { positive values < 65535 using XOR.        }
                        if (longint(right.location.value64) >= -32767) and
                           (longint(right.location.value64) < 0) then
                          cg.a_op_const_reg_reg(current_asmdata.CurrAsmList,OP_SUB,OS_INT,
                            aint(right.location.value64),
                            left.location.register64.reglo,tempreg64.reglo)
                        else
                          cg.a_op_const_reg_reg(current_asmdata.CurrAsmList,OP_XOR,OS_INT,
                            aint(right.location.value64),
                            left.location.register64.reglo,tempreg64.reglo);

                      if ((right.location.value64 shr 32) <> 0) then
                        if (longint(right.location.value64 shr 32) >= -32767) and
                           (longint(right.location.value64 shr 32) < 0) then
                          cg.a_op_const_reg_reg(current_asmdata.CurrAsmList,OP_SUB,OS_INT,
                            aint(right.location.value64 shr 32),
                            left.location.register64.reghi,tempreg64.reghi)
                        else
                          cg.a_op_const_reg_reg(current_asmdata.CurrAsmList,OP_XOR,OS_INT,
                            aint(right.location.value64 shr 32),
                            left.location.register64.reghi,tempreg64.reghi);
                    end
                  else
                    begin
                       tempreg64.reglo := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                       tempreg64.reghi := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                       cg64.a_op64_reg_reg_reg(current_asmdata.CurrAsmList,OP_XOR,location.size,
                         left.location.register64,right.location.register64,
                         tempreg64);
                    end;

                  cg.a_reg_alloc(current_asmdata.CurrAsmList,NR_R0);
                  current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_OR_,NR_R0,
                    tempreg64.reglo,tempreg64.reghi));
                  cg.a_reg_dealloc(current_asmdata.CurrAsmList,NR_R0);

                  location_reset(location,LOC_FLAGS,OS_NO);
                  location.resflags := getresflags;
                end;
              xorn,orn,andn,addn:
                begin
                  location.register64.reglo := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                  location.register64.reghi := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);

                  if (left.location.loc = LOC_CONSTANT) then
                    swapleftright;
                  if (right.location.loc = LOC_CONSTANT) then
                    cg64.a_op64_const_reg_reg(current_asmdata.CurrAsmList,op,location.size,right.location.value64,
                      left.location.register64,location.register64)
                  else
                    cg64.a_op64_reg_reg_reg(current_asmdata.CurrAsmList,op,location.size,right.location.register64,
                      left.location.register64,location.register64);
                end;
              subn:
                begin
                  location.register64.reglo := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                  location.register64.reghi := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                  if left.location.loc <> LOC_CONSTANT then
                    begin
                      if right.location.loc <> LOC_CONSTANT then
                        // reg64 - reg64
                        cg64.a_op64_reg_reg_reg(current_asmdata.CurrAsmList,OP_SUB,location.size,
                          right.location.register64,left.location.register64,
                          location.register64)
                      else
                        // reg64 - const64
                        cg64.a_op64_const_reg_reg(current_asmdata.CurrAsmList,OP_SUB,location.size,
                          right.location.value64,left.location.register64,
                          location.register64)
                    end
                  else if ((left.location.value64 shr 32) = 0) then
                    begin
                      if (int64(left.location.value64) >= low(smallint)) and
                         (int64(left.location.value64) <= high(smallint)) then
                        begin
                          // consts16 - reg64
                          current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_const(A_SUBFIC,
                            location.register64.reglo,right.location.register64.reglo,
                            left.location.value));
                        end
                      else
                        begin
                          // const32 - reg64
                          location_force_reg(current_asmdata.CurrAsmList,left.location,
                            OS_32,true);
                          current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_SUBC,
                            location.register64.reglo,left.location.register64.reglo,
                            right.location.register64.reglo));
                        end;
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(A_SUBFZE,
                        location.register64.reghi,right.location.register64.reghi));
                    end
                  else if (aint(left.location.value64) = 0) then
                    begin
                      // (const32 shl 32) - reg64
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_const(A_SUBFIC,
                        location.register64.reglo,right.location.register64.reglo,0));
                      left.location.value64 := left.location.value64 shr 32;
                      location_force_reg(current_asmdata.CurrAsmList,left.location,OS_32,true);
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_SUBFE,
                        location.register64.reghi,right.location.register64.reghi,
                        left.location.register));
                    end
                  else
                    begin
                      // const64 - reg64
                      location_force_reg(current_asmdata.CurrAsmList,left.location,
                        def_cgsize(left.resultdef),false);
                      cg64.a_op64_reg_reg_reg(current_asmdata.CurrAsmList,OP_SUB,location.size,
                        right.location.register64,left.location.register64,
                        location.register64);
                     end;
                end;
              else
                internalerror(2002072803);
            end;
          end
        else
          begin
            if is_signed(resultdef) then
              begin
                case nodetype of
                  addn:
                    begin
                      op1 := A_ADDC;
                      op2 := A_ADDEO;
                    end;
                  subn:
                    begin
                      op1 := A_SUBC;
                      op2 := A_SUBFEO;
                    end;
                  muln:
                    begin
                      op1 := A_MULLW;
                      op2 := A_MULHW
                    end;
                  else
                    internalerror(2002072806);
                end
              end
            else
              begin
                case nodetype of
                  addn:
                    begin
                      op1 := A_ADDC;
                      op2 := A_ADDE;
                    end;
                  subn:
                    begin
                      op1 := A_SUBC;
                      op2 := A_SUBFE;
                    end;
                  muln:
                    begin
                      op1 := A_MULLW;
                      op2 := A_MULHWU
                    end;
                end;
              end;
            current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(op1,location.register64.reglo,
              left.location.register64.reglo,right.location.register64.reglo));

            if (nodetype <> muln) then
              begin
                current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(op2,location.register64.reghi,
                   right.location.register64.reghi,left.location.register64.reghi));
                if not(is_signed(resultdef)) then
                  if nodetype = addn then
                    current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(A_CMPLW,location.register64.reghi,left.location.register64.reghi))
                  else
                    current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(A_CMPLW,left.location.register64.reghi,location.register64.reghi));
                cg.g_overflowcheck(current_asmdata.CurrAsmList,location,resultdef);
              end
            else
              begin
               { 32 * 32 -> 64 cannot overflow }
                current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(op2,location.register64.reghi,
                   left.location.register64.reglo,right.location.register64.reglo));
              end
          end;

        { set result location }
        { (emit_compare sets it to LOC_FLAGS for compares, so set the }
        {  real location only now) (JM)                               }
        if cmpop and
           not(nodetype in [equaln,unequaln]) then
          location_reset(location,LOC_JUMP,OS_NO);
      end;


{*****************************************************************************
                                AddMMX
*****************************************************************************}

{$ifdef SUPPORT_MMX}
    procedure ti386addnode.second_addmmx;
      var
        op         : TAsmOp;
        cmpop      : boolean;
        mmxbase    : tmmxtype;
        hregister  : tregister;
      begin
        pass_left_and_right;

        cmpop:=false;
        mmxbase:=mmx_type(left.resultdef);
        case nodetype of
          addn :
            begin
              if (cs_mmx_saturation in aktlocalswitches) then
                begin
                   case mmxbase of
                      mmxs8bit:
                        op:=A_PADDSB;
                      mmxu8bit:
                        op:=A_PADDUSB;
                      mmxs16bit,mmxfixed16:
                        op:=A_PADDSB;
                      mmxu16bit:
                        op:=A_PADDUSW;
                   end;
                end
              else
                begin
                   case mmxbase of
                      mmxs8bit,mmxu8bit:
                        op:=A_PADDB;
                      mmxs16bit,mmxu16bit,mmxfixed16:
                        op:=A_PADDW;
                      mmxs32bit,mmxu32bit:
                        op:=A_PADDD;
                   end;
                end;
            end;
          muln :
            begin
               case mmxbase of
                  mmxs16bit,mmxu16bit:
                    op:=A_PMULLW;
                  mmxfixed16:
                    op:=A_PMULHW;
               end;
            end;
          subn :
            begin
              if (cs_mmx_saturation in aktlocalswitches) then
                begin
                   case mmxbase of
                      mmxs8bit:
                        op:=A_PSUBSB;
                      mmxu8bit:
                        op:=A_PSUBUSB;
                      mmxs16bit,mmxfixed16:
                        op:=A_PSUBSB;
                      mmxu16bit:
                        op:=A_PSUBUSW;
                   end;
                end
              else
                begin
                   case mmxbase of
                      mmxs8bit,mmxu8bit:
                        op:=A_PSUBB;
                      mmxs16bit,mmxu16bit,mmxfixed16:
                        op:=A_PSUBW;
                      mmxs32bit,mmxu32bit:
                        op:=A_PSUBD;
                   end;
                end;
            end;
          xorn:
            op:=A_PXOR;
          orn:
            op:=A_POR;
          andn:
            op:=A_PAND;
          else
            internalerror(200403183);
        end;

        { left and right no register?  }
        { then one must be demanded    }
        if (left.location.loc<>LOC_MMXREGISTER) then
         begin
           if (right.location.loc=LOC_MMXREGISTER) then
            begin
              location_swap(left.location,right.location);
              toggleflag(nf_swaped);
            end
           else
            begin
              { register variable ? }
              if (left.location.loc=LOC_CMMXREGISTER) then
               begin
                 hregister:=rg.getregistermm(current_asmdata.CurrAsmList);
                 emit_reg_reg(A_MOVQ,S_NO,left.location.register,hregister);
               end
              else
               begin
                 if not(left.location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
                  internalerror(200203245);

                 location_release(current_asmdata.CurrAsmList,left.location);

                 hregister:=rg.getregistermm(current_asmdata.CurrAsmList);
                 emit_ref_reg(A_MOVQ,S_NO,left.location.reference,hregister);
               end;

              location_reset(left.location,LOC_MMXREGISTER,OS_NO);
              left.location.register:=hregister;
            end;
         end;

        { at this point, left.location.loc should be LOC_MMXREGISTER }
        if right.location.loc<>LOC_MMXREGISTER then
         begin
           if (nodetype=subn) and (nf_swaped in flags) then
            begin
              if right.location.loc=LOC_CMMXREGISTER then
               begin
                 emit_reg_reg(A_MOVQ,S_NO,right.location.register,R_MM7);
                 emit_reg_reg(op,S_NO,left.location.register,R_MM7);
                 emit_reg_reg(A_MOVQ,S_NO,R_MM7,left.location.register);
               end
              else
               begin
                 if not(left.location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
                  internalerror(200203247);
                 emit_ref_reg(A_MOVQ,S_NO,right.location.reference,R_MM7);
                 emit_reg_reg(op,S_NO,left.location.register,R_MM7);
                 emit_reg_reg(A_MOVQ,S_NO,R_MM7,left.location.register);
                 location_release(current_asmdata.CurrAsmList,right.location);
               end;
            end
           else
            begin
              if (right.location.loc=LOC_CMMXREGISTER) then
               begin
                 emit_reg_reg(op,S_NO,right.location.register,left.location.register);
               end
              else
               begin
                 if not(right.location.loc in [LOC_REFERENCE,LOC_CREFERENCE]) then
                  internalerror(200203246);
                 emit_ref_reg(op,S_NO,right.location.reference,left.location.register);
                 location_release(current_asmdata.CurrAsmList,right.location);
               end;
            end;
          end
        else
          begin
            { right.location=LOC_MMXREGISTER }
            if (nodetype=subn) and (nf_swaped in flags) then
             begin
               emit_reg_reg(op,S_NO,left.location.register,right.location.register);
               location_swap(left.location,right.location);
               toggleflag(nf_swaped);
             end
            else
             begin
               emit_reg_reg(op,S_NO,right.location.register,left.location.register);
             end;
          end;

        location_freetemp(current_asmdata.CurrAsmList,right.location);
        location_release(current_asmdata.CurrAsmList,right.location);
        if cmpop then
         begin
           location_freetemp(current_asmdata.CurrAsmList,left.location);
           location_release(current_asmdata.CurrAsmList,left.location);
         end;
        set_result_location(cmpop,true);
      end;
{$endif SUPPORT_MMX}


{*****************************************************************************
                                pass_2
*****************************************************************************}

    procedure tppcaddnode.pass_generate_code;
    { is also being used for xor, and "mul", "sub, or and comparative }
    { operators                                                }
      var
         cgop       : topcg;
         op         : tasmop;
         tmpreg     : tregister;
         hl         : tasmlabel;
         cmpop      : boolean;

         { true, if unsigned types are compared }
         unsigned : boolean;

      begin
         { to make it more readable, string and set (not smallset!) have their
           own procedures }
         case left.resultdef.deftype of
           orddef :
             begin
               { handling boolean expressions }
               if is_boolean(left.resultdef) and
                  is_boolean(right.resultdef) then
                 begin
                   second_addboolean;
                   exit;
                 end
               { 64bit operations }
               else if is_64bit(resultdef) or
                       is_64bit(left.resultdef) then
                 begin
                   second_add64bit;
                   exit;
                 end;
             end;
           stringdef :
             begin
               internalerror(2002072402);
               exit;
             end;
           setdef :
             begin
               { normalsets are already handled in pass1 }
               if (tsetdef(left.resultdef).settype<>smallset) then
                internalerror(200109041);
               second_addsmallset;
               exit;
             end;
           arraydef :
             begin
{$ifdef SUPPORT_MMX}
               if is_mmx_able_array(left.resultdef) then
                begin
                  second_addmmx;
                  exit;
                end;
{$endif SUPPORT_MMX}
             end;
           floatdef :
             begin
               second_addfloat;
               exit;
             end;
         end;

         { defaults }
         cmpop:=nodetype in [ltn,lten,gtn,gten,equaln,unequaln];
         unsigned:=not(is_signed(left.resultdef)) or
                   not(is_signed(right.resultdef));

         pass_left_and_right;

         { Convert flags to register first }
         { can any of these things be in the flags actually?? (JM) }

         if (left.location.loc = LOC_FLAGS) or
            (right.location.loc = LOC_FLAGS) then
           internalerror(2002072602);

         { set result location }
         if not cmpop then
           location_reset(location,LOC_REGISTER,def_cgsize(resultdef))
          else
           location_reset(location,LOC_FLAGS,OS_NO);

         load_left_right(cmpop, (cs_check_overflow in aktlocalswitches) and
            (nodetype in [addn,subn,muln]));

         if not(cmpop) then
           location.register := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);

         if not(cs_check_overflow in aktlocalswitches) or
            (cmpop) or
            (nodetype in [orn,andn,xorn]) then
           begin
             case nodetype of
               addn, muln, xorn, orn, andn:
                 begin
                   case nodetype of
                     addn:
                       cgop := OP_ADD;
                     muln:
                       if unsigned then
                         cgop := OP_MUL
                       else
                         cgop := OP_IMUL;
                     xorn:
                       cgop := OP_XOR;
                     orn:
                       cgop := OP_OR;
                     andn:
                       cgop := OP_AND;
                   end;
                   if (left.location.loc = LOC_CONSTANT) then
                     swapleftright;
                   if (right.location.loc <> LOC_CONSTANT) then
                     cg.a_op_reg_reg_reg(current_asmdata.CurrAsmList,cgop,OS_INT,
                       left.location.register,right.location.register,
                       location.register)
                   else
                     cg.a_op_const_reg_reg(current_asmdata.CurrAsmList,cgop,OS_INT,
                       right.location.value,left.location.register,
                     location.register);
                 end;
               subn:
                 begin
                   if (nf_swaped in flags) then
                     swapleftright;
                   if left.location.loc <> LOC_CONSTANT then
                     if right.location.loc <> LOC_CONSTANT then
                       cg.a_op_reg_reg_reg(current_asmdata.CurrAsmList,OP_SUB,OS_INT,
                         right.location.register,left.location.register,
                         location.register)
                     else
                       cg.a_op_const_reg_reg(current_asmdata.CurrAsmList,OP_SUB,OS_INT,
                         right.location.value,left.location.register,
                         location.register)
                   else
                     if (longint(left.location.value) >= low(smallint)) and
                        (longint(left.location.value) <= high(smallint)) then
                       begin
                         current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_const(A_SUBFIC,
                           location.register,right.location.register,
                           longint(left.location.value)));
                       end
                     else
                       begin
                         tmpreg := cg.getintregister(current_asmdata.CurrAsmList,OS_INT);
                         cg.a_load_const_reg(current_asmdata.CurrAsmList,OS_INT,
                           left.location.value,tmpreg);
                         cg.a_op_reg_reg_reg(current_asmdata.CurrAsmList,OP_SUB,OS_INT,
                           right.location.register,tmpreg,location.register);
                       end;
                 end;
               ltn,lten,gtn,gten,equaln,unequaln :
                 begin
                   emit_compare(unsigned);
                 end;
             end;
           end
         else
           // overflow checking is on and we have an addn, subn or muln
           begin
             if is_signed(resultdef) then
               begin
                 case nodetype of
                   addn:
                     op := A_ADDO;
                   subn:
                     begin
                       op := A_SUBO;
                       if (nf_swaped in flags) then
                         swapleftright;
                     end;
                   muln:
                     op := A_MULLWO;
                   else
                     internalerror(2002072601);
                 end;
                 current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(op,location.register,
                   left.location.register,right.location.register));
                 cg.g_overflowcheck(current_asmdata.CurrAsmList,location,resultdef);
              end
             else
              begin
                case nodetype of
                  addn:
                    begin
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_ADD,location.register,
                        left.location.register,right.location.register));
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(A_CMPLW,location.register,left.location.register));
                      cg.g_overflowcheck(current_asmdata.CurrAsmList,location,resultdef);
                    end;
                  subn:
                    begin
                      if nf_swaped in flags then
                        swapleftright;
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_SUB,location.register,
                        left.location.register,right.location.register));
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg(A_CMPLW,left.location.register,location.register));
                      cg.g_overflowcheck(current_asmdata.CurrAsmList,location,resultdef);
                    end;
                  muln:
                    begin
                      { calculate the upper 32 bits of the product, = 0 if no overflow }
                      cg.a_reg_alloc(current_asmdata.CurrAsmList,NR_R0);
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_MULHWU_,NR_R0,
                        left.location.register,right.location.register));
                      cg.a_reg_dealloc(current_asmdata.CurrAsmList,NR_R0);
                      { calculate the real result }
                      current_asmdata.CurrAsmList.concat(taicpu.op_reg_reg_reg(A_MULLW,location.register,
                        left.location.register,right.location.register));
                      { g_overflowcheck generates a OC_AE instead of OC_EQ :/ }
                      current_asmdata.getjumplabel(hl);
                      tcgppc(cg).a_jmp_cond(current_asmdata.CurrAsmList,OC_EQ,hl);
                      cg.a_call_name(current_asmdata.CurrAsmList,'FPC_OVERFLOW');
                      cg.a_label(current_asmdata.CurrAsmList,hl);
                    end;
                end;
              end;
           end;
      end;

begin
   caddnode:=tppcaddnode;
end.
