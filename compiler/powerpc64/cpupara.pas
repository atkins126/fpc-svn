{
    Copyright (c) 2002 by Florian Klaempfl

    PowerPC64 specific calling conventions

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
unit cpupara;

{$I fpcdefs.inc}

interface

uses
  globtype,
  aasmtai,
  cpubase,
  symconst, symtype, symdef, symsym,
  paramgr, parabase, cgbase;

type
  tppcparamanager = class(tparamanager)
    function get_volatile_registers_int(calloption: tproccalloption):
      tcpuregisterset; override;
    function get_volatile_registers_fpu(calloption: tproccalloption):
      tcpuregisterset; override;
    function push_addr_param(varspez: tvarspez; def: tdef; calloption:
      tproccalloption): boolean; override;

    procedure getintparaloc(calloption: tproccalloption; nr: longint; var
      cgpara: TCGPara); override;
    function create_paraloc_info(p: tabstractprocdef; side: tcallercallee): longint; override;
    function create_varargs_paraloc_info(p: tabstractprocdef; varargspara:
      tvarargsparalist): longint; override;
    procedure create_funcretloc_info(p: tabstractprocdef; side: tcallercallee);

  private
    procedure init_values(var curintreg, curfloatreg, curmmreg: tsuperregister;
      var cur_stack_offset: aword);
    function create_paraloc_info_intern(p: tabstractprocdef; side:
      tcallercallee; paras: tparalist;
      var curintreg, curfloatreg, curmmreg: tsuperregister; var
        cur_stack_offset: aword; isVararg : boolean): longint;
    function parseparaloc(p: tparavarsym; const s: string): boolean; override;
  end;

implementation

uses
  verbose, systems,
  defutil,
  cgutils;

function tppcparamanager.get_volatile_registers_int(calloption:
  tproccalloption): tcpuregisterset;
begin
  result := [RS_R3..RS_R12];
end;

function tppcparamanager.get_volatile_registers_fpu(calloption:
  tproccalloption): tcpuregisterset;
begin
  result := [RS_F0..RS_F13];
end;

procedure tppcparamanager.getintparaloc(calloption: tproccalloption; nr:
  longint; var cgpara: TCGPara);
var
  paraloc: pcgparalocation;
begin
  cgpara.reset;
  cgpara.size := OS_INT;
  cgpara.intsize := tcgsize2size[OS_INT];
  cgpara.alignment := get_para_align(calloption);
  paraloc := cgpara.add_location;
  with paraloc^ do begin
    size := OS_INT;
    if (nr <= 8) then begin
      if nr = 0 then
        internalerror(200309271);
      loc := LOC_REGISTER;
      register := newreg(R_INTREGISTER, RS_R2 + nr, R_SUBWHOLE);
    end else begin
      loc := LOC_REFERENCE;
      paraloc^.reference.index := NR_STACK_POINTER_REG;
      reference.offset := sizeof(aint) * (nr - 8);
    end;
  end;
end;

function getparaloc(p: tdef): tcgloc;

begin
  { Later, the LOC_REFERENCE is in most cases changed into LOC_REGISTER
    if push_addr_param for the def is true
  }
  case p.deftype of
    orddef:
      result := LOC_REGISTER;
    floatdef:
      result := LOC_FPUREGISTER;
    enumdef:
      result := LOC_REGISTER;
    pointerdef:
      result := LOC_REGISTER;
    formaldef:
      result := LOC_REGISTER;
    classrefdef:
      result := LOC_REGISTER;
    recorddef:
      result := LOC_REGISTER;
    objectdef:
      if is_object(p) then
        result := LOC_REFERENCE
      else
        result := LOC_REGISTER;
    stringdef:
      if is_shortstring(p) or is_longstring(p) then
        result := LOC_REFERENCE
      else
        result := LOC_REGISTER;
    procvardef:
      if (po_methodpointer in tprocvardef(p).procoptions) then
        result := LOC_REFERENCE
      else
        result := LOC_REGISTER;
    filedef:
      result := LOC_REGISTER;
    arraydef:
      result := LOC_REFERENCE;
    setdef:
      if is_smallset(p) then
        result := LOC_REGISTER
      else
        result := LOC_REFERENCE;
    variantdef:
      result := LOC_REFERENCE;
    { avoid problems with errornous definitions }
    errordef:
      result := LOC_REGISTER;
  else
    internalerror(2002071001);
  end;
end;

function tppcparamanager.push_addr_param(varspez: tvarspez; def: tdef;
  calloption: tproccalloption): boolean;
begin
  result := false;
  { var,out always require address }
  if varspez in [vs_var, vs_out] then
  begin
    result := true;
    exit;
  end;
  case def.deftype of
    variantdef,
    formaldef:
      result := true;
    recorddef:
      result :=
        ((varspez = vs_const) and
        (
         (not (calloption in [pocall_cdecl, pocall_cppdecl]) and
         (def.size > 8))
        )
        );
    arraydef:
      result := (tarraydef(def).highrange >= tarraydef(def).lowrange) or
        is_open_array(def) or
        is_array_of_const(def) or
        is_array_constructor(def);
    objectdef:
      result := is_object(def);
    setdef:
      result := (tsetdef(def).settype <> smallset);
    stringdef:
      result := tstringdef(def).string_typ in [st_shortstring, st_longstring];
    procvardef:
      result := po_methodpointer in tprocvardef(def).procoptions;
  end;
end;

procedure tppcparamanager.init_values(var curintreg, curfloatreg, curmmreg:
  tsuperregister; var cur_stack_offset: aword);
begin
  { register parameter save area begins at 48(r2) }
  cur_stack_offset := 48;
  curintreg := RS_R3;
  curfloatreg := RS_F1;
  curmmreg := RS_M2;
end;

procedure tppcparamanager.create_funcretloc_info(p: tabstractprocdef; side:
  tcallercallee);
var
  retcgsize: tcgsize;
begin
  { Constructors return self instead of a boolean }
  if (p.proctypeoption = potype_constructor) then
    retcgsize := OS_ADDR
  else
    retcgsize := def_cgsize(p.rettype.def);

  location_reset(p.funcretloc[side], LOC_INVALID, OS_NO);
  p.funcretloc[side].size := retcgsize;
  { void has no location }
  if is_void(p.rettype.def) then begin
    p.funcretloc[side].loc := LOC_VOID;
    exit;
  end;

  { Return in FPU register? }
  if p.rettype.def.deftype = floatdef then begin
    p.funcretloc[side].loc := LOC_FPUREGISTER;
    p.funcretloc[side].register := NR_FPU_RESULT_REG;
    p.funcretloc[side].size := retcgsize;
  end else
    { Return in register? } 
    if not ret_in_param(p.rettype.def, p.proccalloption) then begin
      p.funcretloc[side].loc := LOC_REGISTER;
      p.funcretloc[side].size := retcgsize;
      if side = callerside then
        p.funcretloc[side].register := newreg(R_INTREGISTER,
          RS_FUNCTION_RESULT_REG, cgsize2subreg(retcgsize))
      else
        p.funcretloc[side].register := newreg(R_INTREGISTER,
          RS_FUNCTION_RETURN_REG, cgsize2subreg(retcgsize));
    end else begin
      p.funcretloc[side].loc := LOC_REFERENCE;
      p.funcretloc[side].size := retcgsize;
    end;
end;

function tppcparamanager.create_paraloc_info(p: tabstractprocdef; side:
  tcallercallee): longint;

var
  cur_stack_offset: aword;
  curintreg, curfloatreg, curmmreg: tsuperregister;
begin
  init_values(curintreg, curfloatreg, curmmreg, cur_stack_offset);

  result := create_paraloc_info_intern(p, side, p.paras, curintreg, curfloatreg,
    curmmreg, cur_stack_offset, false);

  create_funcretloc_info(p, side);
end;

function tppcparamanager.create_paraloc_info_intern(p: tabstractprocdef; side:
  tcallercallee; paras: tparalist;
  var curintreg, curfloatreg, curmmreg: tsuperregister; var cur_stack_offset:
  aword; isVararg : boolean): longint;
var
  stack_offset: longint;
  paralen: aint;
  nextintreg, nextfloatreg, nextmmreg : tsuperregister;
  paradef: tdef;
  paraloc: pcgparalocation;
  i: integer;
  hp: tparavarsym;
  loc: tcgloc;
  paracgsize: tcgsize;

begin
{$IFDEF extdebug}
  if po_explicitparaloc in p.procoptions then
    internalerror(200411141);
{$ENDIF extdebug}

  result := 0;
  nextintreg := curintreg;
  nextfloatreg := curfloatreg;
  nextmmreg := curmmreg;
  stack_offset := cur_stack_offset;

  for i := 0 to paras.count - 1 do begin
    hp := tparavarsym(paras[i]);
    paradef := hp.vartype.def;
    { Syscall for Morphos can have already a paraloc set }
    if (vo_has_explicit_paraloc in hp.varoptions) then begin
      if not (vo_is_syscall_lib in hp.varoptions) then
        internalerror(200412153);
      continue;
    end;
    hp.paraloc[side].reset;
    { currently only support C-style array of const }
    if (p.proccalloption in [pocall_cdecl, pocall_cppdecl]) and
      is_array_of_const(paradef) then begin
      paraloc := hp.paraloc[side].add_location;
      { hack: the paraloc must be valid, but is not actually used }
      paraloc^.loc := LOC_REGISTER;
      paraloc^.register := NR_R0;
      paraloc^.size := OS_ADDR;
      break;
    end;

    if (hp.varspez in [vs_var, vs_out]) or
      push_addr_param(hp.varspez, paradef, p.proccalloption) or
      is_open_array(paradef) or
      is_array_of_const(paradef) then begin
      paradef := voidpointertype.def;
      loc := LOC_REGISTER;
      paracgsize := OS_ADDR;
      paralen := tcgsize2size[OS_ADDR];
    end else begin
      if not is_special_array(paradef) then
        paralen := paradef.size
      else
        paralen := tcgsize2size[def_cgsize(paradef)];
      if (paradef.deftype = recorddef) and
        (hp.varspez in [vs_value, vs_const]) then begin
        { if a record has only one field and that field is }
        { non-composite (not array or record), it must be  }
        { passed according to the rules of that type.       }
        if (trecorddef(hp.vartype.def).symtable.symindex.count = 1) and
          (not trecorddef(hp.vartype.def).isunion) and
          (tabstractvarsym(trecorddef(hp.vartype.def).symtable.symindex.search(1)).vartype.def.deftype = floatdef) then begin
          paradef :=
            tabstractvarsym(trecorddef(hp.vartype.def).symtable.symindex.search(1)).vartype.def;
          loc := getparaloc(paradef);
          paracgsize := def_cgsize(paradef);
        end else begin
          loc := LOC_REGISTER;
          paracgsize := int_cgsize(paralen);
        end;
      end else begin
        loc := getparaloc(paradef);
        paracgsize := def_cgsize(paradef);
        { for things like formaldef }
        if (paracgsize = OS_NO) then begin
          paracgsize := OS_ADDR;
          paralen := tcgsize2size[OS_ADDR];
        end;
      end
    end;

    { patch FPU values into integer registers if we currently have
     to pass them as vararg parameters     
    }
    if (isVararg) and (paradef.deftype = floatdef) then begin
      loc := LOC_REGISTER;
      if paracgsize = OS_F64 then
        paracgsize := OS_64
      else
        paracgsize := OS_32;
    end;

    hp.paraloc[side].alignment := std_param_align;
    hp.paraloc[side].size := paracgsize;
    hp.paraloc[side].intsize := paralen;
    if (paralen = 0) then
      if (paradef.deftype = recorddef) then begin
        paraloc := hp.paraloc[side].add_location;
        paraloc^.loc := LOC_VOID;
      end else
        internalerror(2005011310);
    { can become < 0 for e.g. 3-byte records }
    while (paralen > 0) do begin
      paraloc := hp.paraloc[side].add_location;
      if (loc = LOC_REGISTER) and (nextintreg <= RS_R10) then begin
        paraloc^.loc := loc;
        { make sure we don't lose whether or not the type is signed }
        if (paradef.deftype <> orddef) then
          paracgsize := int_cgsize(paralen);
        if (paracgsize in [OS_NO]) then
          paraloc^.size := OS_INT
        else
          paraloc^.size := paracgsize;
        paraloc^.register := newreg(R_INTREGISTER, nextintreg, R_SUBNONE);
        inc(nextintreg);
        dec(paralen, tcgsize2size[paraloc^.size]);

        inc(stack_offset, tcgsize2size[OS_INT]);
      end else if (loc = LOC_FPUREGISTER) and
        (nextfloatreg <= RS_F13) then begin
        paraloc^.loc := loc;
        paraloc^.size := paracgsize;
        paraloc^.register := newreg(R_FPUREGISTER, nextfloatreg, R_SUBWHOLE);
        { the PPC64 ABI says that the GPR index is increased for every parameter, no matter
        which type it is stored in }
        inc(nextintreg);
        inc(nextfloatreg);
        dec(paralen, tcgsize2size[paraloc^.size]);
        
        inc(stack_offset, tcgsize2size[OS_FLOAT]);
      end else if (loc = LOC_MMREGISTER) then begin
        { Altivec not supported }
        internalerror(200510192);
      end else begin 
        { either LOC_REFERENCE, or one of the above which must be passed on the
        stack because of insufficient registers }
        paraloc^.loc := LOC_REFERENCE;
        paraloc^.size := int_cgsize(paralen);
        if (side = callerside) then
          paraloc^.reference.index := NR_STACK_POINTER_REG
        else
          { during procedure entry, NR_OLD_STACK_POINTER_REG contains the old stack pointer }
          paraloc^.reference.index := NR_OLD_STACK_POINTER_REG;
        paraloc^.reference.offset := stack_offset;

        { align temp contents to next register size }
        inc(stack_offset, align(paralen, 8));
        paralen := 0;
      end;
    end;
  end;

  curintreg := nextintreg;
  curfloatreg := nextfloatreg;
  curmmreg := nextmmreg;
  cur_stack_offset := stack_offset; 
  result := stack_offset;
end;

function tppcparamanager.create_varargs_paraloc_info(p: tabstractprocdef;
  varargspara: tvarargsparalist): longint;
var
  cur_stack_offset: aword;
  parasize, l: longint;
  curintreg, firstfloatreg, curfloatreg, curmmreg: tsuperregister;
  i: integer;
  hp: tparavarsym;
  paraloc: pcgparalocation;
begin
  init_values(curintreg, curfloatreg, curmmreg, cur_stack_offset);
  firstfloatreg := curfloatreg;

  result := create_paraloc_info_intern(p, callerside, p.paras, curintreg,
    curfloatreg, curmmreg, cur_stack_offset, false);
  if (p.proccalloption in [pocall_cdecl, pocall_cppdecl]) then begin
    { just continue loading the parameters in the registers }
    result := create_paraloc_info_intern(p, callerside, varargspara, curintreg,
      curfloatreg, curmmreg, cur_stack_offset, true);
    { varargs routines have to reserve at least 64 bytes for the PPC64 ABI }
    if (result < 64) then
      result := 64;
  end else begin
    parasize := cur_stack_offset;
    for i := 0 to varargspara.count - 1 do begin
      hp := tparavarsym(varargspara[i]);
      hp.paraloc[callerside].alignment := 8;
      paraloc := hp.paraloc[callerside].add_location;
      paraloc^.loc := LOC_REFERENCE;
      paraloc^.size := def_cgsize(hp.vartype.def);
      paraloc^.reference.index := NR_STACK_POINTER_REG;
      l := push_size(hp.varspez, hp.vartype.def, p.proccalloption);
      paraloc^.reference.offset := parasize;
      parasize := parasize + l;
    end;
    result := parasize;
  end;
  if curfloatreg <> firstfloatreg then
    include(varargspara.varargsinfo, va_uses_float_reg);
end;

function tppcparamanager.parseparaloc(p: tparavarsym; const s: string): boolean;
begin
  { not supported/required for PowerPC64-linux target }
  internalerror(200404182);
  result := true;
end;

begin
  paramanager := tppcparamanager.create;
end.

