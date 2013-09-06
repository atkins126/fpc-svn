{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Load the system unit, create required defs for systemunit

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
unit psystem;

{$i fpcdefs.inc}

interface

    uses
      symbase;

    procedure create_intern_symbols;
    procedure create_intern_types;

    procedure load_intern_types;

    procedure registernodes;
    procedure registertais;


implementation

    uses
      globals,globtype,verbose,constexp,cpuinfo,
      systems,
      symconst,symtype,symsym,symdef,symtable,
      aasmtai,aasmdata,aasmcpu,
      ncgutil,ncgrtti,fmodule,
      node,nbas,nflw,nset,ncon,ncnv,nld,nmem,ncal,nmat,nadd,ninl,nopt
      ;


    procedure create_intern_symbols;
      {
        all intern procedures for the system unit
      }
      begin
        systemunit.insert(tsyssym.create('Concat',in_concat_x));
        systemunit.insert(tsyssym.create('Write',in_write_x));
        systemunit.insert(tsyssym.create('WriteLn',in_writeln_x));
        systemunit.insert(tsyssym.create('WriteStr',in_writestr_x));
        systemunit.insert(tsyssym.create('Assigned',in_assigned_x));
        systemunit.insert(tsyssym.create('Read',in_read_x));
        systemunit.insert(tsyssym.create('ReadLn',in_readln_x));
        systemunit.insert(tsyssym.create('ReadStr',in_readstr_x));
        systemunit.insert(tsyssym.create('Ofs',in_ofs_x));
        systemunit.insert(tsyssym.create('SizeOf',in_sizeof_x));
        systemunit.insert(tsyssym.create('BitSizeOf',in_bitsizeof_x));
        systemunit.insert(tsyssym.create('TypeOf',in_typeof_x));
        systemunit.insert(tsyssym.create('Low',in_low_x));
        systemunit.insert(tsyssym.create('High',in_high_x));
        systemunit.insert(tsyssym.create('Slice',in_slice_x));
        systemunit.insert(tsyssym.create('Seg',in_seg_x));
        systemunit.insert(tsyssym.create('Ord',in_ord_x));
        systemunit.insert(tsyssym.create('Pred',in_pred_x));
        systemunit.insert(tsyssym.create('Succ',in_succ_x));
        systemunit.insert(tsyssym.create('Exclude',in_exclude_x_y));
        systemunit.insert(tsyssym.create('Include',in_include_x_y));
        systemunit.insert(tsyssym.create('Pack',in_pack_x_y_z));
        systemunit.insert(tsyssym.create('Unpack',in_unpack_x_y_z));
        systemunit.insert(tsyssym.create('Break',in_break));
        systemunit.insert(tsyssym.create('Exit',in_exit));
        systemunit.insert(tsyssym.create('Continue',in_continue));
        systemunit.insert(tsyssym.create('Leave',in_leave)); {macpas only}
        systemunit.insert(tsyssym.create('Cycle',in_cycle)); {macpas only}
        systemunit.insert(tsyssym.create('Dec',in_dec_x));
        systemunit.insert(tsyssym.create('Inc',in_inc_x));
        systemunit.insert(tsyssym.create('Str',in_str_x_string));
        systemunit.insert(tsyssym.create('Assert',in_assert_x_y));
        systemunit.insert(tsyssym.create('Val',in_val_x));
        systemunit.insert(tsyssym.create('Addr',in_addr_x));
        systemunit.insert(tsyssym.create('TypeInfo',in_typeinfo_x));
        systemunit.insert(tsyssym.create('SetLength',in_setlength_x));
        systemunit.insert(tsyssym.create('Copy',in_copy_x));
        systemunit.insert(tsyssym.create('Initialize',in_initialize_x));
        systemunit.insert(tsyssym.create('Finalize',in_finalize_x));
        systemunit.insert(tsyssym.create('Length',in_length_x));
        systemunit.insert(tsyssym.create('New',in_new_x));
        systemunit.insert(tsyssym.create('Dispose',in_dispose_x));
{$ifdef SUPPORT_GET_FRAME}
        systemunit.insert(tsyssym.create('Get_Frame',in_get_frame));
{$endif SUPPORT_GET_FRAME}
        systemunit.insert(tsyssym.create('Unaligned',in_unaligned_x));
        systemunit.insert(tsyssym.create('Aligned',in_aligned_x));
        systemunit.insert(tsyssym.create('ObjCSelector',in_objc_selector_x)); { objc only }
        systemunit.insert(tsyssym.create('ObjCEncode',in_objc_encode_x)); { objc only }
        systemunit.insert(tsyssym.create('Default',in_default_x));
      end;


    procedure set_default_int_types;
      begin
{$ifdef cpu64bitaddr}
        uinttype:=u64inttype;
        sinttype:=s64inttype;
        ptruinttype:=u64inttype;
        ptrsinttype:=s64inttype;
{$endif cpu64bitaddr}
{$ifdef cpu32bitaddr}
        uinttype:=u32inttype;
        sinttype:=s32inttype;
        ptruinttype:=u32inttype;
        ptrsinttype:=s32inttype;
{$endif cpu32bitaddr}
{$ifdef cpu32bitalu}
        uinttype:=u32inttype;
        sinttype:=s32inttype;
{$endif cpu32bitalu}
{$ifdef cpu16bitaddr}
        ptruinttype:=u16inttype;
        ptrsinttype:=s16inttype;
{$endif cpu16bitaddr}
{$ifdef cpu16bitalu}
        uinttype:=u16inttype;
        sinttype:=s16inttype;
{$endif cpu16bitalu}
{$ifdef cpu8bitalu}
        uinttype:=u8inttype;
        sinttype:=s8inttype;
{$endif cpu8bitalu}

{$ifndef avr}
        osuinttype:=uinttype;
        ossinttype:=sinttype;
{$else avr}
        osuinttype:=u16inttype;
        ossinttype:=s16inttype;
{$endif avr}
      end;

    procedure create_intern_types;
      {
        all the types inserted into the system unit
      }

        function addtype(const s:string;def:tdef):ttypesym;
        begin
          result:=ttypesym.create(s,def);
          systemunit.insert(result);
        end;

        procedure addfield(recst:tabstractrecordsymtable;sym:tfieldvarsym);
        begin
          recst.insert(sym);
          recst.addfield(sym,vis_hidden);
        end;

        procedure create_fpu_types;
        begin
          if init_settings.fputype<>fpu_none then
            begin
              s32floattype:=tfloatdef.create(s32real);
              s64floattype:=tfloatdef.create(s64real);
              s80floattype:=tfloatdef.create(s80real);
              sc80floattype:=tfloatdef.create(sc80real);
            end else begin
              s32floattype:=nil;
              s64floattype:=nil;
              s80floattype:=nil;
              sc80floattype:=nil;
            end;
        end;

      var
        hrecst : trecordsymtable;
      begin
        symtablestack.push(systemunit);
        cundefinedtype:=tundefineddef.create;
        cformaltype:=tformaldef.create(false);
        ctypedformaltype:=tformaldef.create(true);
        voidtype:=torddef.create(uvoid,0,0);
        u8inttype:=torddef.create(u8bit,0,255);
        s8inttype:=torddef.create(s8bit,int64(-128),127);
        u16inttype:=torddef.create(u16bit,0,65535);
        s16inttype:=torddef.create(s16bit,int64(-32768),32767);
        u32inttype:=torddef.create(u32bit,0,high(longword));
        s32inttype:=torddef.create(s32bit,int64(low(longint)),int64(high(longint)));
        u64inttype:=torddef.create(u64bit,low(qword),high(qword));
        s64inttype:=torddef.create(s64bit,low(int64),high(int64));
        pasbool8type:=torddef.create(pasbool8,0,1);
        pasbool16type:=torddef.create(pasbool16,0,1);
        pasbool32type:=torddef.create(pasbool32,0,1);
        pasbool64type:=torddef.create(pasbool64,0,1);
        bool8type:=torddef.create(bool8bit,low(int64),high(int64));
        bool16type:=torddef.create(bool16bit,low(int64),high(int64));
        bool32type:=torddef.create(bool32bit,low(int64),high(int64));
        bool64type:=torddef.create(bool64bit,low(int64),high(int64));
        cansichartype:=torddef.create(uchar,0,255);
        cwidechartype:=torddef.create(uwidechar,0,65535);
        cshortstringtype:=tstringdef.createshort(255);
        { should we give a length to the default long and ansi string definition ?? }
        clongstringtype:=tstringdef.createlong(-1);
        cansistringtype:=tstringdef.createansi(0);
        if target_info.system in systems_windows then
          cwidestringtype:=tstringdef.createwide
        else
          cwidestringtype:=tstringdef.createunicode;
        cunicodestringtype:=tstringdef.createunicode;
        { length=0 for shortstring is open string (needed for readln(string) }
        openshortstringtype:=tstringdef.createshort(0);
        openchararraytype:=tarraydef.create(0,-1,s32inttype);
        tarraydef(openchararraytype).elementdef:=cansichartype;
{$ifdef x86}
        create_fpu_types;
{$ifndef FPC_SUPPORT_X87_TYPES_ON_WIN64}
        if target_info.system=system_x86_64_win64 then
          begin
            s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
            pbestrealtype:=@s64floattype;
          end
        else
{$endif FPC_SUPPORT_X87_TYPES_ON_WIN64}
          s64currencytype:=tfloatdef.create(s64currency);
{$endif x86}
{$ifdef powerpc}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif powerpc}
{$ifdef POWERPC64}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif POWERPC64}
{$ifdef sparc}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif sparc}
{$ifdef m68k}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif}
{$ifdef arm}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif arm}
{$ifdef avr}
        s32floattype:=tfloatdef.create(s32real);
        s64floattype:=tfloatdef.create(s64real);
        s80floattype:=tfloatdef.create(s80real);
        sc80floattype:=tfloatdef.create(sc80real);
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif avr}
{$ifdef mips}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif mips}
{$ifdef jvm}
        create_fpu_types;
        s64currencytype:=torddef.create(scurrency,low(int64),high(int64));
{$endif jvm}
        set_default_int_types;
        { some other definitions }
        voidpointertype:=tpointerdef.create(voidtype);
        charpointertype:=tpointerdef.create(cansichartype);
        widecharpointertype:=tpointerdef.create(cwidechartype);
{$ifdef x86}
        voidnearpointertype:=tpointerdef.createx86(voidtype,x86pt_near);
        voidnearcspointertype:=tpointerdef.createx86(voidtype,x86pt_near_cs);
        voidneardspointertype:=tpointerdef.createx86(voidtype,x86pt_near_ds);
        voidnearsspointertype:=tpointerdef.createx86(voidtype,x86pt_near_ss);
        voidnearespointertype:=tpointerdef.createx86(voidtype,x86pt_near_es);
        voidnearfspointertype:=tpointerdef.createx86(voidtype,x86pt_near_fs);
        voidneargspointertype:=tpointerdef.createx86(voidtype,x86pt_near_gs);
  {$ifdef i8086}
        voidfarpointertype:=tpointerdef.createx86(voidtype,x86pt_far);
        voidhugepointertype:=tpointerdef.createx86(voidtype,x86pt_huge);
        bytefarpointertype:=tpointerdef.createx86(u8inttype,x86pt_far);
        wordfarpointertype:=tpointerdef.createx86(u16inttype,x86pt_far);
        longintfarpointertype:=tpointerdef.createx86(s32inttype,x86pt_far);
  {$endif i8086}
{$endif x86}
        cfiletype:=tfiledef.createuntyped;
        cvarianttype:=tvariantdef.create(vt_normalvariant);
        colevarianttype:=tvariantdef.create(vt_olevariant);

{$ifdef cpufpemu}
        { Normal types }
        (* we use the same types as without emulator, the only
          difference is that direct calls to the emulator are generated
        if (cs_fp_emulation in current_settings.moduleswitches) then
          begin
            addtype('Single',s32floattype);
            { extended size is the best real type for the target }
            addtype('Real',s32floattype);
            pbestrealtype:=@s32floattype;
            { extended size is the best real type for the target }
            addtype('Extended',pbestrealtype^);
          end
        else
        *)
{$endif cpufpemu}
        if init_settings.fputype <> fpu_none then
          begin
            addtype('Single',s32floattype);
            addtype('Double',s64floattype);
            { extended size is the best real type for the target }
            addtype('Extended',pbestrealtype^);
            { CExtended corresponds to the C version of the Extended type
              (either "long double" or "double") }
            if target_info.system in systems_android then
              { Android has "long double"="double" even for x86 }
              addtype('CExtended',s64floattype)
            else
              if tfloatdef(pbestrealtype^).floattype=s80real then
                addtype('CExtended',sc80floattype)
              else
                addtype('CExtended',pbestrealtype^);
          end;
{$ifdef x86}
{$ifndef FPC_SUPPORT_X87_TYPES_ON_WIN64}
        if target_info.system<>system_x86_64_win64 then
{$endif FPC_SUPPORT_X87_TYPES_ON_WIN64}
          addtype('Comp',tfloatdef.create(s64comp));
{$endif x86}
        addtype('Currency',s64currencytype);
        addtype('Pointer',voidpointertype);
{$ifdef x86}
        addtype('NearPointer',voidnearpointertype);
        addtype('NearCsPointer',voidnearcspointertype);
        addtype('NearDsPointer',voidneardspointertype);
        addtype('NearSsPointer',voidnearsspointertype);
        addtype('NearEsPointer',voidnearespointertype);
        addtype('NearFsPointer',voidnearfspointertype);
        addtype('NearGsPointer',voidneargspointertype);
  {$ifdef i8086}
        addtype('FarPointer',voidfarpointertype);
        addtype('HugePointer',voidhugepointertype);
  {$endif i8086}
{$endif x86}
        addtype('ShortString',cshortstringtype);
{$ifdef support_longstring}
        addtype('LongString',clongstringtype);
{$endif support_longstring}
        addtype('AnsiString',cansistringtype);
        addtype('WideString',cwidestringtype);
        addtype('UnicodeString',cunicodestringtype);

        addtype('OpenString',openshortstringtype);
        addtype('Boolean',pasbool8type);
        addtype('Boolean16',pasbool16type);
        addtype('Boolean32',pasbool32type);
        addtype('Boolean64',pasbool64type);
        addtype('ByteBool',bool8type);
        addtype('WordBool',bool16type);
        addtype('LongBool',bool32type);
        addtype('QWordBool',bool64type);
        addtype('Byte',u8inttype);
        addtype('ShortInt',s8inttype);
        addtype('Word',u16inttype);
        addtype('SmallInt',s16inttype);
        addtype('LongWord',u32inttype);
        addtype('LongInt',s32inttype);
        addtype('QWord',u64inttype);
        addtype('Int64',s64inttype);
        addtype('Char',cansichartype);
        addtype('WideChar',cwidechartype);
        addtype('Text',tfiledef.createtext);
        addtype('TypedFile',tfiledef.createtyped(voidtype));
        addtype('Variant',cvarianttype);
        addtype('OleVariant',colevarianttype);
        { Internal types }
        addtype('$undefined',cundefinedtype);
        addtype('$formal',cformaltype);
        addtype('$typedformal',ctypedformaltype);
        addtype('$void',voidtype);
        addtype('$byte',u8inttype);
        addtype('$shortint',s8inttype);
        addtype('$word',u16inttype);
        addtype('$smallint',s16inttype);
        addtype('$ulong',u32inttype);
        addtype('$longint',s32inttype);
        addtype('$qword',u64inttype);
        addtype('$int64',s64inttype);
        addtype('$char',cansichartype);
        addtype('$widechar',cwidechartype);
        addtype('$shortstring',cshortstringtype);
        addtype('$longstring',clongstringtype);
        addtype('$ansistring',cansistringtype);
        addtype('$widestring',cwidestringtype);
        addtype('$unicodestring',cunicodestringtype);
        addtype('$openshortstring',openshortstringtype);
        addtype('$boolean',pasbool8type);
        addtype('$boolean16',pasbool16type);
        addtype('$boolean32',pasbool32type);
        addtype('$boolean64',pasbool64type);
        addtype('$bytebool',bool8type);
        addtype('$wordbool',bool16type);
        addtype('$longbool',bool32type);
        addtype('$qwordbool',bool64type);
        addtype('$void_pointer',voidpointertype);
        addtype('$char_pointer',charpointertype);
        addtype('$widechar_pointer',widecharpointertype);
{$ifdef x86}
        addtype('$void_nearpointer',voidnearpointertype);
        addtype('$void_nearcspointer',voidnearcspointertype);
        addtype('$void_neardspointer',voidneardspointertype);
        addtype('$void_nearsspointer',voidnearsspointertype);
        addtype('$void_nearespointer',voidnearespointertype);
        addtype('$void_nearfspointer',voidnearfspointertype);
        addtype('$void_neargspointer',voidneargspointertype);
  {$ifdef i8086}
        addtype('$void_farpointer',voidfarpointertype);
        addtype('$void_hugepointer',voidhugepointertype);
        addtype('$byte_farpointer',bytefarpointertype);
        addtype('$word_farpointer',wordfarpointertype);
        addtype('$longint_farpointer',longintfarpointertype);
  {$endif i8086}
{$endif x86}
        addtype('$openchararray',openchararraytype);
        addtype('$file',cfiletype);
        addtype('$variant',cvarianttype);
        addtype('$olevariant',colevarianttype);
        if init_settings.fputype<>fpu_none then
          begin
            addtype('$s32real',s32floattype);
            addtype('$s64real',s64floattype);
            addtype('$s80real',s80floattype);
            addtype('$sc80real',sc80floattype);
          end;
        addtype('$s64currency',s64currencytype);
        if not(target_info.system in systems_managed_vm) then
          begin
            { Add a type for virtual method tables }
            hrecst:=trecordsymtable.create('',current_settings.packrecords);
            vmttype:=trecorddef.create('',hrecst);
            pvmttype:=tpointerdef.create(vmttype);
            { can't use addtype for pvmt because the rtti of the pointed
              type is not available. The rtti for pvmt will be written implicitly
              by thev tblarray below }
            systemunit.insert(ttypesym.create('$pvmt',pvmttype));
            addfield(hrecst,tfieldvarsym.create('$length',vs_value,ptrsinttype,[]));
            addfield(hrecst,tfieldvarsym.create('$mlength',vs_value,ptrsinttype,[]));
            addfield(hrecst,tfieldvarsym.create('$parent',vs_value,pvmttype,[]));
            { it seems vmttype is used both for TP objects and Delphi classes,
              so the next entry could either be the first virtual method (vm1)
              (object) or the class name (class). We can't easily create separate
              vtable formats for both, as gdb is hard coded to search for
              __vtbl_ptr_type in all cases (JM) }
            addfield(hrecst,tfieldvarsym.create('$vm1_or_classname',vs_value,tpointerdef.create(cshortstringtype),[]));
            vmtarraytype:=tarraydef.create(0,0,s32inttype);
            tarraydef(vmtarraytype).elementdef:=voidpointertype;
            addfield(hrecst,tfieldvarsym.create('$__pfn',vs_value,vmtarraytype,[]));
            addtype('$__vtbl_ptr_type',vmttype);
            vmtarraytype:=tarraydef.create(0,1,s32inttype);
            tarraydef(vmtarraytype).elementdef:=pvmttype;
            addtype('$vtblarray',vmtarraytype);
            { Add a type for methodpointers }
            hrecst:=trecordsymtable.create('',1);
{$ifdef i8086}
            if current_settings.x86memorymodel in x86_far_code_models then
              addfield(hrecst,tfieldvarsym.create('$proc',vs_value,voidfarpointertype,[]))
            else
              addfield(hrecst,tfieldvarsym.create('$proc',vs_value,voidnearpointertype,[]));
{$else i8086}
            addfield(hrecst,tfieldvarsym.create('$proc',vs_value,voidpointertype,[]));
{$endif i8086}
            addfield(hrecst,tfieldvarsym.create('$self',vs_value,voidpointertype,[]));
            methodpointertype:=trecorddef.create('',hrecst);
            addtype('$methodpointer',methodpointertype);
          end;
        symtablestack.pop(systemunit);
      end;


    procedure load_intern_types;
      {
        Load all default definitions for consts from the system unit
      }

        procedure loadtype(const s:string;var def:tdef);
        var
          srsym : ttypesym;
        begin
          srsym:=search_system_type(s);
          def:=srsym.typedef;
        end;

      var
        oldcurrentmodule : tmodule;
      begin
{$ifndef FPC_SUPPORT_X87_TYPES_ON_WIN64}
        if target_info.system=system_x86_64_win64 then
          pbestrealtype:=@s64floattype;
{$endif FPC_SUPPORT_X87_TYPES_ON_WIN64}

        oldcurrentmodule:=current_module;
        set_current_module(nil);
        loadtype('byte',u8inttype);
        loadtype('shortint',s8inttype);
        loadtype('word',u16inttype);
        loadtype('smallint',s16inttype);
        loadtype('ulong',u32inttype);
        loadtype('longint',s32inttype);
        loadtype('qword',u64inttype);
        loadtype('int64',s64inttype);
        loadtype('undefined',cundefinedtype);
        loadtype('formal',cformaltype);
        loadtype('typedformal',ctypedformaltype);
        loadtype('void',voidtype);
        loadtype('char',cansichartype);
        loadtype('widechar',cwidechartype);
        loadtype('shortstring',cshortstringtype);
        loadtype('longstring',clongstringtype);
        loadtype('ansistring',cansistringtype);
        loadtype('widestring',cwidestringtype);
        loadtype('unicodestring',cunicodestringtype);
        loadtype('openshortstring',openshortstringtype);
        loadtype('openchararray',openchararraytype);
        if init_settings.fputype <> fpu_none then
          begin
            loadtype('s32real',s32floattype);
            loadtype('s64real',s64floattype);
            loadtype('s80real',s80floattype);
            loadtype('sc80real',sc80floattype);
          end;
        loadtype('s64currency',s64currencytype);
        loadtype('boolean',pasbool8type);
        loadtype('boolean16',pasbool16type);
        loadtype('boolean32',pasbool32type);
        loadtype('boolean64',pasbool64type);
        loadtype('bytebool',bool8type);
        loadtype('wordbool',bool16type);
        loadtype('longbool',bool32type);
        loadtype('qwordbool',bool64type);
        loadtype('void_pointer',voidpointertype);
        loadtype('char_pointer',charpointertype);
        loadtype('widechar_pointer',widecharpointertype);
{$ifdef x86}
        loadtype('void_nearpointer',voidnearpointertype);
        loadtype('void_nearcspointer',voidnearcspointertype);
        loadtype('void_neardspointer',voidneardspointertype);
        loadtype('void_nearsspointer',voidnearsspointertype);
        loadtype('void_nearespointer',voidnearespointertype);
        loadtype('void_nearfspointer',voidnearfspointertype);
        loadtype('void_neargspointer',voidneargspointertype);
  {$ifdef i8086}
        loadtype('void_farpointer',voidfarpointertype);
        loadtype('void_hugepointer',voidhugepointertype);
        loadtype('byte_farpointer',bytefarpointertype);
        loadtype('word_farpointer',wordfarpointertype);
        loadtype('longint_farpointer',longintfarpointertype);
  {$endif i8086}
{$endif x86}
        loadtype('file',cfiletype);
        if not(target_info.system in systems_managed_vm) then
          begin
            loadtype('pvmt',pvmttype);
            loadtype('vtblarray',vmtarraytype);
            loadtype('__vtbl_ptr_type',vmttype);
          end;
        loadtype('variant',cvarianttype);
        loadtype('olevariant',colevarianttype);
        if not(target_info.system in systems_managed_vm) then
          loadtype('methodpointer',methodpointertype);
        loadtype('HRESULT',hresultdef);
        set_default_int_types;
        set_current_module(oldcurrentmodule);
      end;


    procedure registernodes;
      {
        Register all possible nodes in the nodeclass array that
        will be used for loading the nodes from a ppu
      }
      begin
        nodeclass[addn]:=caddnode;
        nodeclass[muln]:=caddnode;
        nodeclass[subn]:=caddnode;
        nodeclass[divn]:=cmoddivnode;
        nodeclass[symdifn]:=caddnode;
        nodeclass[modn]:=cmoddivnode;
        nodeclass[assignn]:=cassignmentnode;
        nodeclass[loadn]:=cloadnode;
        nodeclass[rangen]:=crangenode;
        nodeclass[ltn]:=caddnode;
        nodeclass[lten]:=caddnode;
        nodeclass[gtn]:=caddnode;
        nodeclass[gten]:=caddnode;
        nodeclass[equaln]:=caddnode;
        nodeclass[unequaln]:=caddnode;
        nodeclass[inn]:=cinnode;
        nodeclass[orn]:=caddnode;
        nodeclass[xorn]:=caddnode;
        nodeclass[shrn]:=cshlshrnode;
        nodeclass[shln]:=cshlshrnode;
        nodeclass[slashn]:=caddnode;
        nodeclass[andn]:=caddnode;
        nodeclass[subscriptn]:=csubscriptnode;
        nodeclass[derefn]:=cderefnode;
        nodeclass[addrn]:=caddrnode;
        nodeclass[ordconstn]:=cordconstnode;
        nodeclass[typeconvn]:=ctypeconvnode;
        nodeclass[calln]:=ccallnode;
        nodeclass[callparan]:=ccallparanode;
        nodeclass[realconstn]:=crealconstnode;
        nodeclass[unaryminusn]:=cunaryminusnode;
        nodeclass[unaryplusn]:=cunaryplusnode;
        nodeclass[asmn]:=casmnode;
        nodeclass[vecn]:=cvecnode;
        nodeclass[pointerconstn]:=cpointerconstnode;
        nodeclass[stringconstn]:=cstringconstnode;
        nodeclass[notn]:=cnotnode;
        nodeclass[inlinen]:=cinlinenode;
        nodeclass[niln]:=cnilnode;
        nodeclass[errorn]:=cerrornode;
        nodeclass[typen]:=ctypenode;
        nodeclass[setelementn]:=csetelementnode;
        nodeclass[setconstn]:=csetconstnode;
        nodeclass[blockn]:=cblocknode;
        nodeclass[statementn]:=cstatementnode;
        nodeclass[ifn]:=cifnode;
        nodeclass[breakn]:=cbreaknode;
        nodeclass[continuen]:=ccontinuenode;
        nodeclass[whilerepeatn]:=cwhilerepeatnode;
        nodeclass[forn]:=cfornode;
        nodeclass[exitn]:=cexitnode;
        nodeclass[withn]:=cwithnode;
        nodeclass[casen]:=ccasenode;
        nodeclass[labeln]:=clabelnode;
        nodeclass[goton]:=cgotonode;
        nodeclass[tryexceptn]:=ctryexceptnode;
        nodeclass[raisen]:=craisenode;
        nodeclass[tryfinallyn]:=ctryfinallynode;
        nodeclass[onn]:=connode;
        nodeclass[isn]:=cisnode;
        nodeclass[asn]:=casnode;
        nodeclass[starstarn]:=caddnode;
        nodeclass[arrayconstructorn]:=carrayconstructornode;
        nodeclass[arrayconstructorrangen]:=carrayconstructorrangenode;
        nodeclass[tempcreaten]:=ctempcreatenode;
        nodeclass[temprefn]:=ctemprefnode;
        nodeclass[tempdeleten]:=ctempdeletenode;
        nodeclass[addoptn]:=caddnode;
        nodeclass[nothingn]:=cnothingnode;
        nodeclass[loadvmtaddrn]:=cloadvmtaddrnode;
        nodeclass[guidconstn]:=cguidconstnode;
        nodeclass[rttin]:=crttinode;
        nodeclass[loadparentfpn]:=cloadparentfpnode;
      end;


    procedure registertais;
      {
        Register all possible tais in the taiclass array that
        will be used for loading the tais from a ppu
      }
      begin
        aiclass[ait_none]:=nil;
        aiclass[ait_align]:=tai_align;
        aiclass[ait_section]:=tai_section;
        aiclass[ait_comment]:=tai_comment;
        aiclass[ait_string]:=tai_string;
        aiclass[ait_instruction]:=taicpu;
        aiclass[ait_datablock]:=tai_datablock;
        aiclass[ait_symbol]:=tai_symbol;
        aiclass[ait_symbol_end]:=tai_symbol_end;
        aiclass[ait_directive]:=tai_directive;
        aiclass[ait_label]:=tai_label;
        aiclass[ait_const]:=tai_const;
        aiclass[ait_real_32bit]:=tai_real_32bit;
        aiclass[ait_real_64bit]:=tai_real_64bit;
        aiclass[ait_real_80bit]:=tai_real_80bit;
        aiclass[ait_comp_64bit]:=tai_comp_64bit;
        aiclass[ait_stab]:=tai_stab;
        aiclass[ait_force_line]:=tai_force_line;
        aiclass[ait_function_name]:=tai_function_name;
{$ifdef alpha}
          { the follow is for the DEC Alpha }
        aiclass[ait_frame]:=tai_frame;
{$endif alpha}
{$ifdef m68k}
{ TODO: FIXME: tai_labeled_instruction doesn't exists}
//        aiclass[ait_labeled_instruction]:=tai_labeled_instruction;
{$endif m68k}
{$ifdef ia64}
        aiclass[ait_bundle]:=tai_bundle;
        aiclass[ait_stop]:=tai_stop;
{$endif ia64}
{$ifdef SPARC}
//        aiclass[ait_labeled_instruction]:=tai_labeled_instruction;
{$endif SPARC}
{$ifdef arm}
        aiclass[ait_thumb_func]:=tai_thumb_func;
        aiclass[ait_thumb_set]:=tai_thumb_set;
{$endif arm}
        aiclass[ait_set]:=tai_set;
        aiclass[ait_weak]:=tai_weak;
        aiclass[ait_cutobject]:=tai_cutobject;
        aiclass[ait_regalloc]:=tai_regalloc;
        aiclass[ait_tempalloc]:=tai_tempalloc;
        aiclass[ait_marker]:=tai_marker;
        aiclass[ait_seh_directive]:=tai_seh_directive;
{$ifdef JVM}
        aiclass[ait_jvar]:=tai_jvar;
        aiclass[ait_jcatch]:=tai_jcatch;
{$endif JVM}
      end;

end.
