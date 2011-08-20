{
    Copyright (c) 2010 by Jonas Maebe

    This unit implements some JVM type helper routines (minimal
    unit dependencies, usable in symdef).

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

{$i fpcdefs.inc}

unit jvmdef;

interface

    uses
      node,
      symbase,symtype;

    { Encode a type into the internal format used by the JVM (descriptor).
      Returns false if a type is not representable by the JVM,
      and in that case also the failing definition.  }
    function jvmtryencodetype(def: tdef; out encodedtype: string; out founderror: tdef): boolean;

    { same as above, but throws an internal error on failure }
    function jvmencodetype(def: tdef): string;

    { Check whether a type can be used in a JVM methom signature or field
      declaration.  }
    function jvmchecktype(def: tdef; out founderror: tdef): boolean;

    { incremental version of jvmtryencodetype() }
    function jvmaddencodedtype(def: tdef; bpacked: boolean; var encodedstr: string; out founderror: tdef): boolean;

    { add type prefix (package name) to a type }
    procedure jvmaddtypeownerprefix(owner: tsymtable; var name: string);

    { returns type string for a single-dimensional array (different from normal
      typestring in case of a primitive type) }
    function jvmarrtype(def: tdef; out primitivetype: boolean): string;
    function jvmarrtype_setlength(def: tdef): char;

    { returns whether a def is emulated using an implicit pointer type on the
      JVM target (e.g., records, regular arrays, ...) }
    function jvmimplicitpointertype(def: tdef): boolean;

    { returns the mangled base name for a tsym (type + symbol name, no
      visibility etc) }
    function jvmmangledbasename(sym: tsym): string;
    function jvmmangledbasename(sym: tsym; const usesymname: string): string;

implementation

  uses
    globtype,
    cutils,cclasses,
    verbose,systems,
    fmodule,
    symtable,symconst,symsym,symdef,symcreat,
    defutil,paramgr;

{******************************************************************
                          Type encoding
*******************************************************************}

    function jvmaddencodedtype(def: tdef; bpacked: boolean; var encodedstr: string; out founderror: tdef): boolean;
      var
        c: char;
      begin
        result:=true;
        case def.typ of
          stringdef :
            begin
              case tstringdef(def).stringtype of
                { translated into java.lang.String }
                st_widestring,
                st_unicodestring:
                  encodedstr:=encodedstr+'Ljava/lang/String;';
                else
                  { May be handled via wrapping later  }
                  result:=false;
              end;
            end;
          enumdef,
          orddef :
            begin
              { for procedure "results" }
              if is_void(def) then
                c:='V'
              { only Pascal-style booleans conform to Java's definition of
                Boolean }
              else if is_pasbool(def) and
                      (def.size=1) then
                c:='Z'
              else if is_widechar(def) then
                c:='C'
              else
                begin
                  case def.size of
                    1:
                      c:='B';
                    2:
                      c:='S';
                    4:
                      c:='I';
                    8:
                      c:='J';
                    else
                      internalerror(2010121905);
                  end;
                end;
              encodedstr:=encodedstr+c;
            end;
          pointerdef :
            begin
              { some may be handled via wrapping later }
              result:=false;
            end;
          floatdef :
            begin
              case tfloatdef(def).floattype of
                s32real:
                  c:='F';
                s64real:
                  c:='D';
                else
                  result:=false;
              end;
              encodedstr:=encodedstr+c;
            end;
          filedef :
            result:=false;
          recorddef :
            begin
              encodedstr:=encodedstr+'L'+trecorddef(def).jvm_full_typename(true)+';'
            end;
          variantdef :
            begin
              { will be hanlded via wrapping later, although wrapping may
                happen at higher level }
              result:=false;
            end;
          classrefdef :
            begin
              { may be handled via wrapping later }
              result:=false;
            end;
          setdef :
            begin
              if is_smallset(def) then
                encodedstr:=encodedstr+'I'
              else
              { will be hanlded via wrapping later, although wrapping may
                happen at higher level }
              result:=false;
            end;
          formaldef :
            begin
              { not supported (may be changed into "java.lang.Object" later) }
              result:=false;
            end;
          arraydef :
            begin
              if is_array_of_const(def) or
                 is_packed_array(def) then
                result:=false
              else
                begin
                  encodedstr:=encodedstr+'[';
                  if not jvmaddencodedtype(tarraydef(def).elementdef,false,encodedstr,founderror) then
                    begin
                      result:=false;
                      { report the exact (nested) error defintion }
                      exit;
                    end;
                end;
            end;
          procvardef :
            begin
              { will be hanlded via wrapping later, although wrapping may
                happen at higher level }
              result:=false;
            end;
          objectdef :
            case tobjectdef(def).objecttype of
              odt_javaclass,
              odt_interfacejava:
                encodedstr:=encodedstr+'L'+tobjectdef(def).jvm_full_typename(true)+';'
              else
                result:=false;
            end;
          undefineddef,
          errordef :
            result:=false;
          procdef :
            { must be done via jvmencodemethod() }
            internalerror(2010121903);
        else
          internalerror(2010121904);
        end;
        if not result then
          founderror:=def;
      end;


    function jvmtryencodetype(def: tdef; out encodedtype: string; out founderror: tdef): boolean;
      begin
        encodedtype:='';
        result:=jvmaddencodedtype(def,false,encodedtype,founderror);
      end;


    procedure jvmaddtypeownerprefix(owner: tsymtable; var name: string);
      var
        owningcontainer: tsymtable;
        tmpresult: string;
        module: tmodule;
      begin
        { see tprocdef.jvmmangledbasename for description of the format }
        owningcontainer:=owner;
        while (owningcontainer.symtabletype=localsymtable) do
          owningcontainer:=owningcontainer.defowner.owner;
        case owningcontainer.symtabletype of
          globalsymtable,
          staticsymtable:
            begin
              module:=find_module_from_symtable(owningcontainer);
              tmpresult:='';
              if assigned(module.namespace) then
                tmpresult:=module.namespace^+'/';
              tmpresult:=tmpresult+module.realmodulename^+'/';
            end;
          objectsymtable:
            case tobjectdef(owningcontainer.defowner).objecttype of
              odt_javaclass,
              odt_interfacejava:
                begin
                  tmpresult:=tobjectdef(owningcontainer.defowner).jvm_full_typename(true)+'/'
                end
              else
                internalerror(2010122606);
            end;
          recordsymtable:
            tmpresult:=trecorddef(owningcontainer.defowner).jvm_full_typename(true)+'/'
          else
            internalerror(2010122605);
        end;
        name:=tmpresult+name;
      end;


    function jvmarrtype(def: tdef; out primitivetype: boolean): string;
      var
        errdef: tdef;
      begin
        if not jvmtryencodetype(def,result,errdef) then
          internalerror(2011012205);
        primitivetype:=false;
        if length(result)=1 then
          begin
            case result[1] of
              'Z': result:='boolean';
              'C': result:='char';
              'B': result:='byte';
              'S': result:='short';
              'I': result:='int';
              'J': result:='long';
              'F': result:='float';
              'D': result:='double';
              else
                internalerror(2011012206);
              end;
            primitivetype:=true;
          end
        else if (result[1]='L') then
          begin
            { in case of a class reference, strip the leading 'L' and the
              trailing ';' }
            setlength(result,length(result)-1);
            delete(result,1,1);
          end;
        { for arrays, use the actual reference type }
      end;


    function jvmarrtype_setlength(def: tdef): char;
      var
        errdef: tdef;
        res: string;
      begin
        if is_record(def) then
          result:='R'
        else
          begin
            if not jvmtryencodetype(def,res,errdef) then
              internalerror(2011012209);
            if length(res)=1 then
              result:=res[1]
            else
              result:='A';
          end;
      end;


    function jvmimplicitpointertype(def: tdef): boolean;
      begin
        case def.typ of
          arraydef:
            result:=(tarraydef(def).highrange>=tarraydef(def).lowrange) or
                is_open_array(def) or
                is_array_of_const(def) or
                is_array_constructor(def);
          recorddef:
            result:=true;
          objectdef:
            result:=is_object(def);
          setdef:
            result:=not is_smallset(def);
          stringdef :
            result:=tstringdef(def).stringtype in [st_shortstring,st_longstring];
          else
            result:=false;
        end;
      end;


    function jvmmangledbasename(sym: tsym; const usesymname: string): string;
      var
        container: tsymtable;
        vsym: tabstractvarsym;
        csym: tconstsym;
        founderror: tdef;
      begin
        case sym.typ of
          staticvarsym,
          paravarsym,
          localvarsym,
          fieldvarsym:
            begin
              vsym:=tabstractvarsym(sym);
              result:=jvmencodetype(vsym.vardef);
              if (vsym.typ=paravarsym) and
                 (vo_is_self in tparavarsym(vsym).varoptions) then
                result:='this ' +result
              else if (vsym.typ in [paravarsym,localvarsym]) and
                      ([vo_is_funcret,vo_is_result] * tabstractnormalvarsym(vsym).varoptions <> []) then
                result:='result '+result
              else
                begin
                  { we have to mangle staticvarsyms in localsymtables to
                    prevent name clashes... }
                  container:=sym.Owner;
                  result:=usesymname+' '+result;
                  while (container.symtabletype=localsymtable) do
                    begin
                      if tdef(container.defowner).typ<>procdef then
                        internalerror(2011040303);
                      { not safe yet in case of overloaded routines, need to
                        encode parameters too or find another way for conflict
                        resolution }
                      result:=tprocdef(container.defowner).procsym.realname+'$'+result;
                      container:=container.defowner.owner;
                    end;
                end;
            end;
          constsym:
            begin
              csym:=tconstsym(sym);
              { some constants can be untyped }
              if assigned (csym.constdef) then
                result:=jvmencodetype(csym.constdef)
              else
                begin
                  case csym.consttyp of
                    constord:
                      result:=jvmencodetype(s32inttype);
                    constreal:
                      result:=jvmencodetype(s64floattype);
                    constset:
                      internalerror(2011040701);
                    constpointer,
                    constnil:
                      result:=jvmencodetype(java_jlobject);
                    constwstring,
                    conststring:
                      result:=jvmencodetype(java_jlstring);
                    constguid:
                      internalerror(2011040702);
                    else
                      internalerror(2011040703);
                  end;
                end;
              result:=usesymname+' '+result;
            end;
          else
            internalerror(2011021703);
        end;
      end;


    function jvmmangledbasename(sym: tsym): string;
      begin
        if (sym.typ=fieldvarsym) and
           assigned(tfieldvarsym(sym).externalname) then
          result:=jvmmangledbasename(sym,tfieldvarsym(sym).externalname^)
        else
          result:=jvmmangledbasename(sym,sym.RealName);
      end;

{******************************************************************
                    jvm type validity checking
*******************************************************************}

   function jvmencodetype(def: tdef): string;
     var
       errordef: tdef;
     begin
       if not jvmtryencodetype(def,result,errordef) then
         internalerror(2011012305);
     end;


   function jvmchecktype(def: tdef; out founderror: tdef): boolean;
      var
        encodedtype: string;
      begin
        { don't duplicate the code like in objcdef, since the resulting strings
          are much shorter here so it's not worth it }
        result:=jvmtryencodetype(def,encodedtype,founderror);
      end;


end.
