{
    Copyright (c) 1998-2010 by Florian Klaempfl, Jonas Maebe

    Calling conventions for the JVM

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
 *****************************************************************************}
unit cpupara;

{$i fpcdefs.inc}

interface

    uses
      globtype,
      cclasses,
      aasmtai,aasmdata,
      cpubase,cpuinfo,
      symconst,symbase,symsym,symtype,symdef,paramgr,parabase,cgbase,cgutils;

    type

      { TJVMParaManager }

      TJVMParaManager=class(TParaManager)
        function  push_high_param(varspez:tvarspez;def : tdef;calloption : tproccalloption) : boolean;override;
        function  push_addr_param(varspez:tvarspez;def : tdef;calloption : tproccalloption) : boolean;override;
        function  push_size(varspez: tvarspez; def: tdef; calloption: tproccalloption): longint;override;
        {Returns a structure giving the information on the storage of the parameter
        (which must be an integer parameter)
        @param(nr Parameter number of routine, starting from 1)}
        procedure getintparaloc(calloption : tproccalloption; nr : longint;var cgpara : TCGPara);override;
        function  create_paraloc_info(p : TAbstractProcDef; side: tcallercallee):longint;override;
        function  get_funcretloc(p : tabstractprocdef; side: tcallercallee; def: tdef): tcgpara;override;
        function param_use_paraloc(const cgpara: tcgpara): boolean; override;
        function ret_in_param(def: tdef; calloption: tproccalloption): boolean; override;
        function is_stack_paraloc(paraloc: pcgparalocation): boolean;override;
      private
        procedure create_funcretloc_info(p : tabstractprocdef; side: tcallercallee);
        procedure create_paraloc_info_intern(p : tabstractprocdef; side: tcallercallee; paras: tparalist;
                                             var parasize:longint);
      end;

implementation

    uses
      cutils,verbose,systems,
      defutil,jvmdef,
      cgobj;


    procedure TJVMParaManager.GetIntParaLoc(calloption : tproccalloption; nr : longint;var cgpara : tcgpara);
      begin
        { don't know whether it's an actual integer or a pointer (necessary for cgpara.def) }
        internalerror(2010121001);
      end;

    function TJVMParaManager.push_high_param(varspez: tvarspez; def: tdef; calloption: tproccalloption): boolean;
      begin
        { we don't need a separate high parameter, since all arrays in Java
          have an implicit associated length }
        if not is_open_array(def) then
          result:=inherited
        else
          result:=false;
      end;


    { true if a parameter is too large to copy and only the address is pushed }
    function TJVMParaManager.push_addr_param(varspez:tvarspez;def : tdef;calloption : tproccalloption) : boolean;
      begin
        result:=jvmimplicitpointertype(def);
      end;


    function TJVMParaManager.push_size(varspez: tvarspez; def: tdef; calloption: tproccalloption): longint;
      begin
        { all aggregate types are emulated using indirect pointer types }
        if def.typ in [arraydef,recorddef,setdef,stringdef] then
          result:=4
        else
          result:=inherited;
      end;


    procedure TJVMParaManager.create_funcretloc_info(p : tabstractprocdef; side: tcallercallee);
      begin
        p.funcretloc[side]:=get_funcretloc(p,side,p.returndef);
      end;


    function TJVMParaManager.get_funcretloc(p : tabstractprocdef; side: tcallercallee; def: tdef): tcgpara;
      var
        paraloc : pcgparalocation;
        retcgsize  : tcgsize;
      begin
        result.init;
        result.alignment:=get_para_align(p.proccalloption);
        result.def:=def;
        { void has no location }
        if is_void(def) then
          begin
            paraloc:=result.add_location;
            result.size:=OS_NO;
            result.intsize:=0;
            paraloc^.size:=OS_NO;
            paraloc^.loc:=LOC_VOID;
            exit;
          end;
        { Constructors return self instead of a boolean }
        if (p.proctypeoption=potype_constructor) then
          begin
            retcgsize:=OS_INT;
            result.intsize:=sizeof(pint);
          end
        else
          begin
            retcgsize:=def_cgsize(def);
            result.intsize:=def.size;
          end;
        result.size:=retcgsize;

        paraloc:=result.add_location;
        { all values are returned on the evaluation stack }
        paraloc^.loc:=LOC_REFERENCE;
        paraloc^.reference.index:=NR_EVAL_STACK_BASE;
        paraloc^.reference.offset:=0;
      end;

    function TJVMParaManager.param_use_paraloc(const cgpara: tcgpara): boolean;
      begin
        { all parameters are copied by the VM to local variable locations }
        result:=true;
      end;

    function TJVMParaManager.ret_in_param(def: tdef; calloption: tproccalloption): boolean;
      begin
        Result:=false;
      end;

    function TJVMParaManager.is_stack_paraloc(paraloc: pcgparalocation): boolean;
      begin
        { all parameters are passed on the evaluation stack }
        result:=true;
      end;


    procedure TJVMParaManager.create_paraloc_info_intern(p : tabstractprocdef; side: tcallercallee;paras:tparalist;
                                                           var parasize:longint);
      var
        paraloc      : pcgparalocation;
        i            : integer;
        hp           : tparavarsym;
        paracgsize   : tcgsize;
        paraofs      : longint;
      begin
        paraofs:=0;
        for i:=0 to paras.count-1 do
          begin
            hp:=tparavarsym(paras[i]);
            paracgsize:=def_cgsize(hp.vardef);
            if paracgsize=OS_NO then
              paracgsize:=OS_ADDR;
            hp.paraloc[side].reset;
            hp.paraloc[side].size:=paracgsize;
            hp.paraloc[side].def:=hp.vardef;
            hp.paraloc[side].alignment:=std_param_align;
            hp.paraloc[side].intsize:=tcgsize2size[paracgsize];
            paraloc:=hp.paraloc[side].add_location;
            { All parameters are passed on the evaluation stack, pushed from
              left to right (including self, if applicable). At the callee side,
              they're available as local variables 0..n-1 (with 64 bit values
              taking up two slots) }
            paraloc^.loc:=LOC_REFERENCE;;
            paraloc^.reference.offset:=paraofs;
            case side of
              callerside:
                begin
                  paraloc^.loc:=LOC_REFERENCE;
                  { we use a fake loc_reference to indicate the stack location;
                    the offset (set above) will be used by ncal to order the
                    parameters so they will be pushed in the right order }
                  paraloc^.reference.index:=NR_EVAL_STACK_BASE;
                end;
              calleeside:
                begin
                  paraloc^.loc:=LOC_REFERENCE;
                  paraloc^.reference.index:=NR_STACK_POINTER_REG;
                end;
            end;
            { 2 slots for 64 bit integers and floats, 1 slot for the rest }
            if not(is_64bit(hp.vardef) or
                   ((hp.vardef.typ=floatdef) and
                    (tfloatdef(hp.vardef).floattype=s64real))) then
              inc(paraofs)
            else
              inc(paraofs,2);
          end;
        parasize:=paraofs;
      end;


    function TJVMParaManager.create_paraloc_info(p : tabstractprocdef; side: tcallercallee):longint;
      var
        parasize : longint;
      begin
        parasize:=0;
        create_paraloc_info_intern(p,side,p.paras,parasize);
        { Create Function result paraloc }
        create_funcretloc_info(p,side);
        { We need to return the size allocated on the stack }
        result:=parasize;
      end;


begin
   ParaManager:=TJVMParaManager.create;
end.
