{
    Copyright (c) 1998-2002 by Florian Klaempfl

    Does object types for Free Pascal

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
unit pdecobj;

{$i fpcdefs.inc}

interface

    uses
      cclasses,
      globtype,symconst,symtype,symdef;

    { parses a object declaration }
    function object_dec(objecttype:tobjecttyp;const n:tidstring;objsym:tsym;genericdef:tstoreddef;genericlist:TFPObjectList;fd : tobjectdef;helpertype:thelpertype) : tobjectdef;

    { parses a (class) method declaration }
    function method_dec(astruct: tabstractrecorddef; is_classdef: boolean): tprocdef;

    function class_constructor_head(astruct: tabstractrecorddef):tprocdef;
    function class_destructor_head(astruct: tabstractrecorddef):tprocdef;
    function constructor_head:tprocdef;
    function destructor_head:tprocdef;
    procedure struct_property_dec(is_classproperty:boolean);

implementation

    uses
      sysutils,cutils,
      globals,verbose,systems,tokens,
      symbase,symsym,symtable,symcreat,defcmp,
      node,nld,nmem,ncon,ncnv,ncal,
      fmodule,scanner,
      pbase,pexpr,pdecsub,pdecvar,ptype,pdecl,pgenutil,ppu,
{$ifdef jvm}
      pjvm,
{$endif}
      parabase
      ;

    const
      { Please leave this here, this module should NOT use
        these variables.
        Declaring it as string here results in an error when compiling (PFV) }
      current_procinfo = 'error';

    var
      current_objectdef : tobjectdef absolute current_structdef;


    procedure constr_destr_finish_head(pd: tprocdef; const astruct: tabstractrecorddef);
      begin
        case astruct.typ of
          recorddef:
            begin
              parse_record_proc_directives(pd);
              // we can't add hidden params here because record is not yet defined
              // and therefore record size which has influence on paramter passing rules may change too
              // look at record_dec to see where calling conventions are applied (issue #0021044)
              handle_calling_convention(pd,[hcc_check]);
            end;
          objectdef:
            begin
              parse_object_proc_directives(pd);
              handle_calling_convention(pd);
            end
          else
            internalerror(2011040502);
        end;

        { add definition to procsym }
        proc_add_definition(pd);

        { add procdef options to objectdef options }
        if (po_virtualmethod in pd.procoptions) then
          include(astruct.objectoptions,oo_has_virtual);

        maybe_parse_hint_directives(pd);
      end;


    function class_constructor_head(astruct: tabstractrecorddef):tprocdef;
      var
        pd : tprocdef;
      begin
        result:=nil;
        consume(_CONSTRUCTOR);
        { must be at same level as in implementation }
        parse_proc_head(current_structdef,potype_class_constructor,pd);
        if not assigned(pd) then
          begin
            consume(_SEMICOLON);
            exit;
          end;
        pd.calcparas;
        if (pd.maxparacount>0) then
          Message(parser_e_no_paras_for_class_constructor);
        consume(_SEMICOLON);
        include(astruct.objectoptions,oo_has_class_constructor);
        current_module.flags:=current_module.flags or uf_classinits;
        { no return value }
        pd.returndef:=voidtype;
        constr_destr_finish_head(pd,astruct);
        result:=pd;
      end;

    function constructor_head:tprocdef;
      var
        pd : tprocdef;
      begin
        result:=nil;
        consume(_CONSTRUCTOR);
        { must be at same level as in implementation }
        parse_proc_head(current_structdef,potype_constructor,pd);
        if not assigned(pd) then
          begin
            consume(_SEMICOLON);
            exit;
          end;
        if (cs_constructor_name in current_settings.globalswitches) and
           (pd.procsym.name<>'INIT') then
          Message(parser_e_constructorname_must_be_init);
        consume(_SEMICOLON);
        include(current_structdef.objectoptions,oo_has_constructor);
        { Set return type, class and record constructors return the
          created instance, helper types return the extended type,
          object constructors return boolean }
        if is_class(pd.struct) or
           is_record(pd.struct) or
           is_javaclass(pd.struct) then
          pd.returndef:=pd.struct
        else
          if is_objectpascal_helper(pd.struct) then
            pd.returndef:=tobjectdef(pd.struct).extendeddef
          else
{$ifdef CPU64bitaddr}
            pd.returndef:=bool64type;
{$else CPU64bitaddr}
            pd.returndef:=bool32type;
{$endif CPU64bitaddr}
        constr_destr_finish_head(pd,pd.struct);
        result:=pd;
      end;


    procedure struct_property_dec(is_classproperty:boolean);
      var
        p : tpropertysym;
      begin
        { check for a class, record or helper }
        if not((is_class_or_interface_or_dispinterface(current_structdef) or is_record(current_structdef) or
                is_objectpascal_helper(current_structdef) or is_java_class_or_interface(current_structdef)) or
               (not(m_tp7 in current_settings.modeswitches) and (is_object(current_structdef)))) then
          Message(parser_e_syntax_error);
        consume(_PROPERTY);
        p:=read_property_dec(is_classproperty,current_structdef);
        consume(_SEMICOLON);
        if try_to_consume(_DEFAULT) then
          begin
            if oo_has_default_property in current_structdef.objectoptions then
              message(parser_e_only_one_default_property);
            include(current_structdef.objectoptions,oo_has_default_property);
            include(p.propoptions,ppo_defaultproperty);
            if not(ppo_hasparameters in p.propoptions) then
              message(parser_e_property_need_paras);
            if (token=_COLON) then
              begin
                Message(parser_e_field_not_allowed_here);
                consume_all_until(_SEMICOLON);
              end;
            consume(_SEMICOLON);
          end;
        { parse possible enumerator modifier }
        if try_to_consume(_ENUMERATOR) then
          begin
            if (token = _ID) then
            begin
              if pattern='CURRENT' then
              begin
                if oo_has_enumerator_current in current_structdef.objectoptions then
                  message(parser_e_only_one_enumerator_current);
                if not p.propaccesslist[palt_read].empty then
                begin
                  include(current_structdef.objectoptions,oo_has_enumerator_current);
                  include(p.propoptions,ppo_enumerator_current);
                end
                else
                  Message(parser_e_enumerator_current_is_not_valid) // property has no reader
              end
              else
                Message1(parser_e_invalid_enumerator_identifier, pattern);
              consume(token);
            end
            else
              Message(parser_e_enumerator_identifier_required);
            consume(_SEMICOLON);
          end;
        { hint directives, these can be separated by semicolons here,
          that needs to be handled here with a loop (PFV) }
        while try_consume_hintdirective(p.symoptions,p.deprecatedmsg) do
          Consume(_SEMICOLON);
      end;


    function class_destructor_head(astruct: tabstractrecorddef):tprocdef;
      var
        pd : tprocdef;
      begin
        result:=nil;
        consume(_DESTRUCTOR);
        parse_proc_head(current_structdef,potype_class_destructor,pd);
        if not assigned(pd) then
          begin
            consume(_SEMICOLON);
            exit;
          end;
        pd.calcparas;
        if (pd.maxparacount>0) then
          Message(parser_e_no_paras_for_class_destructor);
        consume(_SEMICOLON);
        include(astruct.objectoptions,oo_has_class_destructor);
        current_module.flags:=current_module.flags or uf_classinits;
        { no return value }
        pd.returndef:=voidtype;
        constr_destr_finish_head(pd,astruct);
        result:=pd;
      end;

    function destructor_head:tprocdef;
      var
        pd : tprocdef;
      begin
        result:=nil;
        consume(_DESTRUCTOR);
        parse_proc_head(current_structdef,potype_destructor,pd);
        if not assigned(pd) then
          begin
            consume(_SEMICOLON);
            exit;
          end;
        if (cs_constructor_name in current_settings.globalswitches) and
           (pd.procsym.name<>'DONE') then
          Message(parser_e_destructorname_must_be_done);
        pd.calcparas;
        if not(pd.maxparacount=0) and
           (m_fpc in current_settings.modeswitches) then
          Message(parser_e_no_paras_for_destructor);
        consume(_SEMICOLON);
        include(current_structdef.objectoptions,oo_has_destructor);
        include(current_structdef.objectoptions,oo_has_new_destructor);
        { no return value }
        pd.returndef:=voidtype;
        constr_destr_finish_head(pd,pd.struct);
        result:=pd;
      end;


    procedure setinterfacemethodoptions;
      var
        i   : longint;
        def : tdef;
      begin
        include(current_structdef.objectoptions,oo_has_virtual);
        for i:=0 to current_structdef.symtable.DefList.count-1 do
          begin
            def:=tdef(current_structdef.symtable.DefList[i]);
            if assigned(def) and
               (def.typ=procdef) then
              begin
                include(tprocdef(def).procoptions,po_virtualmethod);
                tprocdef(def).forwarddef:=false;
              end;
          end;
      end;


    procedure setobjcclassmethodoptions;
      var
        i   : longint;
        def : tdef;
      begin
        for i:=0 to current_structdef.symtable.DefList.count-1 do
          begin
            def:=tdef(current_structdef.symtable.DefList[i]);
            if assigned(def) and
               (def.typ=procdef) then
              begin
                include(tprocdef(def).procoptions,po_virtualmethod);
              end;
          end;
      end;


    procedure handleImplementedInterface(intfdef : tobjectdef);
      begin
        if not is_interface(intfdef) then
          begin
             Message1(type_e_interface_type_expected,intfdef.typename);
             exit;
          end;
        if ([oo_is_forward,oo_is_formal] * intfdef.objectoptions <> []) then
          begin
             Message1(parser_e_forward_intf_declaration_must_be_resolved,intfdef.objrealname^);
             exit;
          end;
        if find_implemented_interface(current_objectdef,intfdef)<>nil then
          Message1(sym_e_duplicate_id,intfdef.objname^)
        else
          begin
            { allocate and prepare the GUID only if the class
              implements some interfaces. }
            if current_objectdef.ImplementedInterfaces.count = 0 then
              current_objectdef.prepareguid;
            current_objectdef.ImplementedInterfaces.Add(TImplementedInterface.Create(intfdef));
          end;
      end;


    procedure handleImplementedProtocolOrJavaIntf(intfdef : tobjectdef);
      begin
        intfdef:=find_real_class_definition(intfdef,false);
        case current_objectdef.objecttype of
          odt_objcclass,
          odt_objccategory,
          odt_objcprotocol:
            if not is_objcprotocol(intfdef) then
              begin
                 Message1(type_e_protocol_type_expected,intfdef.typename);
                 exit;
              end;
          odt_javaclass,
          odt_interfacejava:
            if not is_javainterface(intfdef) then
              begin
                Message1(type_e_interface_type_expected,intfdef.typename);
                exit
              end;
          else
            internalerror(2011010807);
        end;
        if ([oo_is_forward,oo_is_formal] * intfdef.objectoptions <> []) then
          begin
             Message1(parser_e_forward_intf_declaration_must_be_resolved,intfdef.objrealname^);
             exit;
          end;
        if find_implemented_interface(current_objectdef,intfdef)<>nil then
          Message1(sym_e_duplicate_id,intfdef.objname^)
        else
          begin
            current_objectdef.ImplementedInterfaces.Add(TImplementedInterface.Create(intfdef));
          end;
      end;


    procedure readImplementedInterfacesAndProtocols(intf: boolean);
      var
        hdef : tdef;
      begin
        while try_to_consume(_COMMA) do
          begin
             { use single_type instead of id_type for specialize support }
             single_type(hdef,[stoAllowSpecialization,stoParseClassParent]);
             if (hdef.typ<>objectdef) then
               begin
                  if intf then
                    Message1(type_e_interface_type_expected,hdef.typename)
                  else
                    Message1(type_e_protocol_type_expected,hdef.typename);
                  continue;
               end;
             if intf then
               handleImplementedInterface(tobjectdef(hdef))
             else
               handleImplementedProtocolOrJavaIntf(tobjectdef(hdef));
          end;
      end;


    procedure readinterfaceiid;
      var
        p : tnode;
        valid : boolean;
      begin
        p:=comp_expr(true,false);
        if p.nodetype=stringconstn then
          begin
            stringdispose(current_objectdef.iidstr);
            current_objectdef.iidstr:=stringdup(strpas(tstringconstnode(p).value_str));
            valid:=string2guid(current_objectdef.iidstr^,current_objectdef.iidguid^);
            if (current_objectdef.objecttype in [odt_interfacecom,odt_dispinterface]) and
               not valid then
              Message(parser_e_improper_guid_syntax);
            include(current_structdef.objectoptions,oo_has_valid_guid);
          end
        else
          Message(parser_e_illegal_expression);
        p.free;
      end;

    procedure get_cpp_or_java_class_external_status(od: tobjectdef);
      var
        hs: string;
      begin
        { C++ classes can be external -> all methods inside are external
         (defined at the class level instead of per method, so that you cannot
         define some methods as external and some not)
        }
        if try_to_consume(_EXTERNAL) then
          begin
            hs:='';
            if token in [_CSTRING,_CWSTRING,_CCHAR,_CWCHAR] then
              begin
                { Always add library prefix and suffix to create an uniform name }
                hs:=get_stringconst;
                if ExtractFileExt(hs)='' then
                  hs:=ChangeFileExt(hs,target_info.sharedlibext);
                if Copy(hs,1,length(target_info.sharedlibprefix))<>target_info.sharedlibprefix then
                  hs:=target_info.sharedlibprefix+hs;
              end;
            if hs<>'' then
              begin
                { the JVM expects java/lang/Object rather than java.lang.Object }
                if target_info.system in systems_jvm then
                  Replace(hs,'.','/');
                stringdispose(od.import_lib);
                od.import_lib:=stringdup(hs);
              end;
            { check if we shall use another name for the class }
            if try_to_consume(_NAME) then
              od.objextname:=stringdup(get_stringconst)
            else
              od.objextname:=stringdup(od.objrealname^);
            include(od.objectoptions,oo_is_external);
          end
        else
          begin
            od.objextname:=stringdup(od.objrealname^);
          end;
      end;


    procedure get_objc_class_or_protocol_external_status(od: tobjectdef);
      begin
        { Objective-C classes can be external -> all messages inside are
          external (defined at the class level instead of per method, so
          that you cannot define some methods as external and some not)
        }
        if try_to_consume(_EXTERNAL) then
          begin
            if try_to_consume(_NAME) then
              od.objextname:=stringdup(get_stringconst)
            else
              { the external name doesn't matter for formally declared
                classes, and allowing to specify one would mean that we would
                have to check it for consistency with the actual definition
                later on }
              od.objextname:=stringdup(od.objrealname^);
            include(od.objectoptions,oo_is_external);
          end
        else
          od.objextname:=stringdup(od.objrealname^);
      end;


    procedure parse_object_options;
      var
        gotexternal: boolean;
      begin
        case current_objectdef.objecttype of
          odt_object,odt_class,
          odt_javaclass:
            begin
              gotexternal:=false;
              while true do
                begin
                  if try_to_consume(_ABSTRACT) then
                    include(current_structdef.objectoptions,oo_is_abstract)
                  else
                  if try_to_consume(_SEALED) then
                    include(current_structdef.objectoptions,oo_is_sealed)
                  else if (current_objectdef.objecttype=odt_javaclass) and
                          (token=_ID) and
                          (idtoken=_EXTERNAL) then
                    begin
                      get_cpp_or_java_class_external_status(current_objectdef);
                      gotexternal:=true;
                    end
                  else
                    break;
                end;
              { don't use <=, because there's a bug in the 2.6.0 SPARC code
                generator regarding handling this expression }
              if ([oo_is_abstract, oo_is_sealed] * current_structdef.objectoptions) = [oo_is_abstract, oo_is_sealed] then
                Message(parser_e_abstract_and_sealed_conflict);
              { set default external name in case of no external directive }
              if (current_objectdef.objecttype=odt_javaclass) and
                 not gotexternal then
               get_cpp_or_java_class_external_status(current_objectdef)
            end;
          odt_cppclass,
          odt_interfacejava:
            get_cpp_or_java_class_external_status(current_objectdef);
          odt_objcclass,odt_objcprotocol,odt_objccategory:
            get_objc_class_or_protocol_external_status(current_objectdef);
          odt_helper: ; // nothing
        end;
      end;

    procedure parse_parent_classes;
      var
        intfchildof,
        childof : tobjectdef;
        hdef : tdef;
        hasparentdefined : boolean;
      begin
        childof:=nil;
        intfchildof:=nil;
        hasparentdefined:=false;

        { reads the parent class }
        if (token=_LKLAMMER) or
           is_objccategory(current_structdef) then
          begin
            consume(_LKLAMMER);
            { use single_type instead of id_type for specialize support }
            single_type(hdef,[stoAllowSpecialization, stoParseClassParent]);
            if (not assigned(hdef)) or
               (hdef.typ<>objectdef) then
              begin
                if assigned(hdef) then
                  Message1(type_e_class_type_expected,hdef.typename)
                else if is_objccategory(current_structdef) then
                  { a category must specify the class to extend }
                  Message(type_e_objcclass_type_expected);
              end
            else
              begin
                childof:=tobjectdef(hdef);
                { a mix of class, interfaces, objects and cppclasses
                  isn't allowed }
                case current_objectdef.objecttype of
                   odt_class,
                   odt_javaclass:
                     if (childof.objecttype<>current_objectdef.objecttype) then
                       begin
                          if (is_interface(childof) and
                              is_class(current_objectdef)) or
                             (is_javainterface(childof) and
                              is_javaclass(current_objectdef)) then
                            begin
                               { we insert the interface after the child
                                 is set, see below
                               }
                               intfchildof:=childof;
                               childof:=class_tobject;
                            end
                          else
                            Message(parser_e_mix_of_classes_and_objects);
                       end
                     else
                       if oo_is_sealed in childof.objectoptions then
                         Message1(parser_e_sealed_descendant,childof.typename)
                       else
                         childof:=find_real_class_definition(childof,true);
                   odt_interfacecorba,
                   odt_interfacecom:
                     begin
                       if not(is_interface(childof)) then
                         Message(parser_e_mix_of_classes_and_objects);
                       current_objectdef.objecttype:=childof.objecttype;
                     end;
                   odt_cppclass:
                     if not(is_cppclass(childof)) then
                       Message(parser_e_mix_of_classes_and_objects);
                   odt_objcclass:
                     if not(is_objcclass(childof) or
                        is_objccategory(childof)) then
                       begin
                         if is_objcprotocol(childof) then
                           begin
                             if not(oo_is_classhelper in current_structdef.objectoptions) then
                               begin
                                 intfchildof:=childof;
                                 childof:=nil;
                                 CGMessage(parser_h_no_objc_parent);
                               end
                             else
                               { a category must specify the class to extend }
                               CGMessage(type_e_objcclass_type_expected);
                           end
                         else
                           Message(parser_e_mix_of_classes_and_objects);
                       end
                     else
                       childof:=find_real_class_definition(childof,true);
                   odt_objcprotocol:
                     begin
                       if not(is_objcprotocol(childof)) then
                         Message(parser_e_mix_of_classes_and_objects);
                       intfchildof:=childof;
                       childof:=nil;
                     end;
                   odt_interfacejava:
                     begin
                       if not(is_javainterface(childof)) then
                         Message(parser_e_mix_of_classes_and_objects);
                       intfchildof:=find_real_class_definition(childof,true);
                       childof:=nil;
                     end;
                   odt_object:
                     if not(is_object(childof)) then
                       Message(parser_e_mix_of_classes_and_objects)
                     else
                       if oo_is_sealed in childof.objectoptions then
                         Message1(parser_e_sealed_descendant,childof.typename);
                   odt_dispinterface:
                     Message(parser_e_dispinterface_cant_have_parent);
                   odt_helper:
                     if not is_objectpascal_helper(childof) then
                       begin
                         Message(type_e_helper_type_expected);
                         childof:=nil;
                       end;
                end;
              end;
            hasparentdefined:=true;
          end;

        { if no parent class, then a class get tobject as parent }
        if not assigned(childof) then
          begin
            case current_objectdef.objecttype of
              odt_class:
                if current_objectdef<>class_tobject then
                  childof:=class_tobject;
              odt_interfacecom:
                if current_objectdef<>interface_iunknown then
                  childof:=interface_iunknown;
              odt_dispinterface:
                childof:=interface_idispatch;
              odt_objcclass:
                CGMessage(parser_h_no_objc_parent);
              odt_javaclass:
                { inherit from TObject by default for compatibility }
                if current_objectdef<>java_jlobject then
                  childof:=class_tobject;
            end;
          end;

        if assigned(childof) then
          begin
            { Forbid not completly defined objects to be used as parents. This will
              also prevent circular loops of classes, because we set the forward flag
              at the start of the new definition and will reset it below after the
              parent has been set }
            if (oo_is_forward in childof.objectoptions) then
              Message1(parser_e_forward_declaration_must_be_resolved,childof.objrealname^)
            else if not(oo_is_formal in childof.objectoptions) then
              current_objectdef.set_parent(childof)
            else
              Message1(sym_e_formal_class_not_resolved,childof.objrealname^);
          end;

        { remove forward flag, is resolved }
        exclude(current_structdef.objectoptions,oo_is_forward);

        if hasparentdefined then
          begin
            if current_objectdef.objecttype in [odt_class,odt_objcclass,odt_objcprotocol,odt_javaclass,odt_interfacejava] then
              begin
                if assigned(intfchildof) then
                  if current_objectdef.objecttype=odt_class then
                    handleImplementedInterface(intfchildof)
                  else
                    handleImplementedProtocolOrJavaIntf(intfchildof);
                readImplementedInterfacesAndProtocols(current_objectdef.objecttype=odt_class);
              end;
            consume(_RKLAMMER);
          end;
      end;

    procedure parse_extended_type(helpertype:thelpertype);

      procedure validate_extendeddef_typehelper(var def:tdef);
        begin
          if def.typ in [undefineddef,procvardef,procdef,objectdef,recorddef,
              filedef,classrefdef,abstractdef,forwarddef,formaldef] then
            begin
              Message1(type_e_type_not_allowed_for_type_helper,def.typename);
              def:=generrordef;
            end;
        end;

      procedure check_inheritance_record_type_helper(var def:tdef);
        begin
          if (def.typ<>errordef) and assigned(current_objectdef.childof) then
            begin
              if def<>current_objectdef.childof.extendeddef then
                begin
                  Message1(type_e_record_helper_must_extend_same_record,current_objectdef.childof.extendeddef.typename);
                  def:=generrordef;
                end;
            end;
        end;

      var
        hdef: tdef;
      begin
        if not is_objectpascal_helper(current_structdef) then
          Internalerror(2011021103);
        if helpertype=ht_none then
          Internalerror(2011021001);

        consume(_FOR);
        single_type(hdef,[stoParseClassParent]);
        if not assigned(hdef) or (hdef.typ=errordef) then
          begin
            case helpertype of
              ht_class:
                Message1(type_e_class_type_expected,hdef.typename);
              ht_record:
                Message(type_e_record_type_expected);
              ht_type:
                Message1(type_e_type_id_expected,hdef.typename);
            end;
          end
        else
          begin
            case helpertype of
              ht_class:
                if (hdef.typ<>objectdef) or
                    not is_class(hdef) then
                  Message1(type_e_class_type_expected,hdef.typename)
                else
                  begin
                    { a class helper must extend the same class or a subclass
                      of the class extended by the parent class helper }
                    if assigned(current_objectdef.childof) then
                      begin
                        if not is_class(current_objectdef.childof.extendeddef) then
                          Internalerror(2011021101);
                        if not def_is_related(hdef,current_objectdef.childof.extendeddef) then
                          Message1(type_e_class_helper_must_extend_subclass,current_objectdef.childof.extendeddef.typename);
                      end;
                  end;
              ht_record:
                if (hdef.typ=objectdef) or
                    (
                      { primitive types are allowed for record helpers in mode
                        delphi }
                      (hdef.typ<>recorddef) and
                      not (m_delphi in current_settings.modeswitches)
                    ) then
                  Message1(type_e_record_type_expected,hdef.typename)
                else
                  begin
                    if hdef.typ<>recorddef then
                      { this is a primitive type in mode delphi, so validate
                        the def }
                      validate_extendeddef_typehelper(hdef);
                    { a record helper must extend the same record as the
                      parent helper }
                    check_inheritance_record_type_helper(hdef);
                  end;
              ht_type:
                begin
                  validate_extendeddef_typehelper(hdef);
                  { a type helper must extend the same type as the
                    parent helper }
                  check_inheritance_record_type_helper(hdef);
                end;
            end;
          end;

        if assigned(hdef) then
          current_objectdef.extendeddef:=hdef
        else
          current_objectdef.extendeddef:=generrordef;
      end;

    procedure parse_guid;
      begin
        { read GUID }
        if (current_objectdef.objecttype in [odt_interfacecom,odt_interfacecorba,odt_dispinterface]) and
           try_to_consume(_LECKKLAMMER) then
          begin
            readinterfaceiid;
            consume(_RECKKLAMMER);
          end
        else if (current_objectdef.objecttype=odt_dispinterface) then
          message(parser_e_dispinterface_needs_a_guid);
      end;


    function method_dec(astruct: tabstractrecorddef; is_classdef: boolean): tprocdef;

      procedure chkobjc(pd: tprocdef);
        begin
          if is_objc_class_or_protocol(pd.struct) then
            begin
              include(pd.procoptions,po_objc);
            end;
        end;


      procedure chkjava(pd: tprocdef);
        begin
{$ifdef jvm}
          if is_java_class_or_interface(pd.struct) then
            begin
              { mark all non-virtual instance methods as "virtual; final;",
                because
                 a) that's the only way to guarantee "non-virtual" behaviour
                    (other than making them class methods with an explicit self
                     pointer, but that causes problems with interface mappings
                     and procvars)
                 b) if we don't mark them virtual, they don't get added to the
                    vmt and we can't check whether child classes try to override
                    them
              }
              if is_javaclass(pd.struct) then
                begin
                  if not(po_virtualmethod in pd.procoptions) and
                     not(po_classmethod in pd.procoptions) then
                    begin
                      include(pd.procoptions,po_virtualmethod);
                      include(pd.procoptions,po_finalmethod);
                      include(pd.procoptions,po_java_nonvirtual);
                    end
                  else if [po_virtualmethod,po_classmethod]<=pd.procoptions then
                    begin
                      if po_staticmethod in pd.procoptions then
                        Message(type_e_java_class_method_not_static_virtual);
                    end;
                end;
            end;
{$endif}
        end;


        procedure chkcpp(pd:tprocdef);
          begin
            { nothing currently }
          end;

      var
        oldparse_only: boolean;
      begin
        case token of
          _PROCEDURE,
          _FUNCTION:
            begin
              if (astruct.symtable.currentvisibility=vis_published) and
                 not(oo_can_have_published in astruct.objectoptions) then
                Message(parser_e_cant_have_published);

              oldparse_only:=parse_only;
              parse_only:=true;
              result:=parse_proc_dec(is_classdef,astruct);

              { this is for error recovery as well as forward }
              { interface mappings, i.e. mapping to a method  }
              { which isn't declared yet                      }
              if assigned(result) then
                begin
                  parse_object_proc_directives(result);

                  { check if dispid is set }
                  if is_dispinterface(result.struct) and not (po_dispid in result.procoptions) then
                    begin
                      result.dispid:=tobjectdef(result.struct).get_next_dispid;
                      include(result.procoptions, po_dispid);
                    end;

                  { all Macintosh Object Pascal methods are virtual.  }
                  { this can't be a class method, because macpas mode }
                  { has no m_class                                    }
                  if (m_mac in current_settings.modeswitches) then
                    include(result.procoptions,po_virtualmethod);

                  { for record and type helpers only static class methods are
                    allowed }
                  if is_objectpascal_helper(astruct) and
                     (tobjectdef(astruct).extendeddef.typ<>objectdef) and
                     is_classdef and not (po_staticmethod in result.procoptions) then
                    MessagePos(result.fileinfo,parser_e_class_methods_only_static_in_records);

                  handle_calling_convention(result);

                  { add definition to procsym }
                  proc_add_definition(result);

                  { add procdef options to objectdef options }
                  if (po_msgint in result.procoptions) then
                    include(astruct.objectoptions,oo_has_msgint);
                  if (po_msgstr in result.procoptions) then
                    include(astruct.objectoptions,oo_has_msgstr);
                  if (po_virtualmethod in result.procoptions) then
                    include(astruct.objectoptions,oo_has_virtual);

                  chkcpp(result);
                  chkobjc(result);
                  chkjava(result);
                end;

              maybe_parse_hint_directives(result);

              parse_only:=oldparse_only;
            end;
          _CONSTRUCTOR :
            begin
              if (astruct.symtable.currentvisibility=vis_published) and
                not(oo_can_have_published in astruct.objectoptions) then
                Message(parser_e_cant_have_published);

              if not is_classdef and not(astruct.symtable.currentvisibility in [vis_public,vis_published]) then
                Message(parser_w_constructor_should_be_public);

              if is_interface(astruct) then
                Message(parser_e_no_con_des_in_interfaces);

              { Objective-C does not know the concept of a constructor }
              if is_objc_class_or_protocol(astruct) then
                Message(parser_e_objc_no_constructor_destructor);

              if is_objectpascal_helper(astruct) then
                if is_classdef then
                  { class constructors are not allowed in class helpers }
                  Message(parser_e_no_class_constructor_in_helpers);

              { only 1 class constructor is allowed }
              if is_classdef and (oo_has_class_constructor in astruct.objectoptions) then
                Message1(parser_e_only_one_class_constructor_allowed, astruct.objrealname^);

              oldparse_only:=parse_only;
              parse_only:=true;
              if is_classdef then
                result:=class_constructor_head(current_structdef)
              else
                begin
                  result:=constructor_head;
                  if is_objectpascal_helper(astruct) and
                     (tobjectdef(astruct).extendeddef.typ<>objectdef) and
                     (result.minparacount=0) then
                      { as long as parameterless constructors aren't allowed in records they
                       aren't allowed in record/type helpers either }
                    MessagePos(result.procsym.fileinfo,parser_e_no_parameterless_constructor_in_records);
                end;

              chkcpp(result);

              parse_only:=oldparse_only;
            end;
          _DESTRUCTOR :
            begin
              if (astruct.symtable.currentvisibility=vis_published) and
                 not(oo_can_have_published in astruct.objectoptions) then
                Message(parser_e_cant_have_published);

              if not is_classdef then
                if (oo_has_new_destructor in astruct.objectoptions) then
                  Message(parser_n_only_one_destructor);

              if is_interface(astruct) then
                Message(parser_e_no_con_des_in_interfaces);

              { (class) destructors are not allowed in class helpers }
              if is_objectpascal_helper(astruct) then
                Message(parser_e_no_destructor_in_records);

              if not is_classdef and (astruct.symtable.currentvisibility<>vis_public) then
                Message(parser_w_destructor_should_be_public);

              { Objective-C does not know the concept of a destructor }
              if is_objc_class_or_protocol(astruct) then
                Message(parser_e_objc_no_constructor_destructor);

              { only 1 class destructor is allowed }
              if is_classdef and (oo_has_class_destructor in astruct.objectoptions) then
                Message1(parser_e_only_one_class_destructor_allowed, astruct.objrealname^);

              oldparse_only:=parse_only;
              parse_only:=true;
              if is_classdef then
                result:=class_destructor_head(current_structdef)
              else
                result:=destructor_head;

              chkcpp(result);

              parse_only:=oldparse_only;
            end;
          else
            internalerror(2011032102);
        end;
      end;


    procedure parse_object_members;

      var
        typedconstswritable: boolean;
        object_member_blocktype : tblock_type;
        fields_allowed, is_classdef, class_fields, is_final, final_fields: boolean;
        vdoptions: tvar_dec_options;
        fieldlist: tfpobjectlist;


      procedure parse_const;
        begin
          if not(current_objectdef.objecttype in [odt_class,odt_object,odt_helper,odt_javaclass,odt_interfacejava]) then
            Message(parser_e_type_var_const_only_in_records_and_classes);
          consume(_CONST);
          object_member_blocktype:=bt_const;
          final_fields:=is_final;
          is_final:=false;
        end;


      procedure parse_var;
        begin
          if not(current_objectdef.objecttype in [odt_class,odt_object,odt_helper,odt_javaclass]) and
             { Java interfaces can contain static final class vars }
             not((current_objectdef.objecttype=odt_interfacejava) and
                 is_final and is_classdef) then
            Message(parser_e_type_var_const_only_in_records_and_classes);
          consume(_VAR);
          fields_allowed:=true;
          object_member_blocktype:=bt_general;
          class_fields:=is_classdef;
          final_fields:=is_final;
          is_classdef:=false;
          is_final:=false;
        end;


      procedure parse_class;
        begin
          is_classdef:=false;
          { read class method/field/property }
          consume(_CLASS);
          { class modifier is only allowed for procedures, functions, }
          { constructors, destructors, fields and properties          }
          if not(token in [_FUNCTION,_PROCEDURE,_PROPERTY,_VAR,_CONSTRUCTOR,_DESTRUCTOR]) then
            Message(parser_e_procedure_or_function_expected);

          { Java interfaces can contain final class vars }
          if is_interface(current_structdef) or
             (is_javainterface(current_structdef) and
              (not(is_final) or
               (token<>_VAR))) then
            Message(parser_e_no_static_method_in_interfaces)
          else
            { class methods are also allowed for Objective-C protocols }
            is_classdef:=true;
        end;


      procedure parse_visibility(vis: tvisibility; oo: tobjectoption);
        begin
          { Objective-C and Java classes do not support "published",
            as basically everything is published.  }
          if (vis=vis_published) and
             (is_objc_class_or_protocol(current_structdef) or
              is_java_class_or_interface(current_structdef)) then
             Message(parser_e_no_objc_published)
          else if is_interface(current_structdef) or
             is_objc_protocol_or_category(current_structdef) or
             is_javainterface(current_structdef) then
            Message(parser_e_no_access_specifier_in_interfaces);
          current_structdef.symtable.currentvisibility:=vis;
          consume(token);
          if (oo<>oo_none) then
            include(current_structdef.objectoptions,oo);
          fields_allowed:=true;
          is_classdef:=false;
          class_fields:=false;
          is_final:=false;
          object_member_blocktype:=bt_general;
        end;


      begin
        { empty class declaration ? }
        if (current_objectdef.objecttype in [odt_class,odt_objcclass,odt_javaclass]) and
           (token=_SEMICOLON) then
          exit;

        { in "publishable" classes the default access type is published }
        if (oo_can_have_published in current_structdef.objectoptions) then
          current_structdef.symtable.currentvisibility:=vis_published
        else
          current_structdef.symtable.currentvisibility:=vis_public;
        fields_allowed:=true;
        is_classdef:=false;
        class_fields:=false;
        is_final:=false;
        final_fields:=false;
        object_member_blocktype:=bt_general;
        fieldlist:=tfpobjectlist.create(false);
        repeat
          case token of
            _TYPE :
              begin
                if not(current_objectdef.objecttype in [odt_class,odt_object,odt_helper,odt_javaclass,odt_interfacejava]) then
                  Message(parser_e_type_var_const_only_in_records_and_classes);
                consume(_TYPE);
                object_member_blocktype:=bt_type;
              end;
            _VAR :
              begin
                parse_var;
              end;
            _CONST:
              begin
                parse_const
              end;
            _ID :
              begin
                if is_objcprotocol(current_structdef) and
                   ((idtoken=_REQUIRED) or
                    (idtoken=_OPTIONAL)) then
                  begin
                    current_structdef.symtable.currentlyoptional:=(idtoken=_OPTIONAL);
                    consume(idtoken)
                  end
                else case idtoken of
                  _PRIVATE :
                    begin
                      parse_visibility(vis_private,oo_has_private);
                     end;
                   _PROTECTED :
                     begin
                       parse_visibility(vis_protected,oo_has_protected);
                     end;
                   _PUBLIC :
                     begin
                       parse_visibility(vis_public,oo_none);
                     end;
                   _PUBLISHED :
                     begin
                       parse_visibility(vis_published,oo_none);
                     end;
                   _STRICT :
                     begin
                       if is_interface(current_structdef) or
                          is_objc_protocol_or_category(current_structdef) or
                          is_javainterface(current_structdef) then
                         Message(parser_e_no_access_specifier_in_interfaces);
                         consume(_STRICT);
                        if token=_ID then
                          begin
                            case idtoken of
                              _PRIVATE:
                                begin
                                  consume(_PRIVATE);
                                  current_structdef.symtable.currentvisibility:=vis_strictprivate;
                                  include(current_structdef.objectoptions,oo_has_strictprivate);
                                end;
                              _PROTECTED:
                                begin
                                  consume(_PROTECTED);
                                  current_structdef.symtable.currentvisibility:=vis_strictprotected;
                                  include(current_structdef.objectoptions,oo_has_strictprotected);
                                end;
                              else
                                message(parser_e_protected_or_private_expected);
                            end;
                          end
                        else
                          message(parser_e_protected_or_private_expected);
                        fields_allowed:=true;
                        is_classdef:=false;
                        class_fields:=false;
                        is_final:=false;
                        final_fields:=false;
                        object_member_blocktype:=bt_general;
                     end
                    else if (m_final_fields in current_settings.modeswitches) and
                            (token=_ID) and
                            (idtoken=_FINAL) then
                      begin
                        { currently only supported for external classes, because
                          requires fully working DFA otherwise }
                        if (current_structdef.typ<>objectdef) or
                           not(oo_is_external in tobjectdef(current_structdef).objectoptions) then
                          Message(parser_e_final_only_external);
                        consume(_final);
                        is_final:=true;
                        if token=_CLASS then
                          parse_class;
                        if not(token in [_CONST,_VAR]) then
                          message(parser_e_final_only_const_var);
                      end
                    else
                      begin
                        if object_member_blocktype=bt_general then
                          begin
                            if is_interface(current_structdef) or
                               is_objc_protocol_or_category(current_structdef) or
                               is_objectpascal_helper(current_structdef) or
                               (is_javainterface(current_structdef) and
                                not(class_fields and final_fields)) then
                              Message(parser_e_no_vars_in_interfaces);

                            if (current_structdef.symtable.currentvisibility=vis_published) and
                               not(oo_can_have_published in current_structdef.objectoptions) then
                              Message(parser_e_cant_have_published);
                            if (not fields_allowed) then
                              Message(parser_e_field_not_allowed_here);

                            vdoptions:=[vd_object];
                            if class_fields then
                              include(vdoptions,vd_class);
                            if is_class(current_structdef) then
                              include(vdoptions,vd_canreorder);
                            if final_fields then
                              include(vdoptions,vd_final);
                            read_record_fields(vdoptions,fieldlist,nil);
                          end
                        else if object_member_blocktype=bt_type then
                          types_dec(true)
                        else if object_member_blocktype=bt_const then
                          begin
                            if final_fields then
                              begin
                                { the value of final fields cannot be changed
                                  once they've been assigned a value }
                                typedconstswritable:=cs_typed_const_writable in current_settings.localswitches;
                                exclude(current_settings.localswitches,cs_typed_const_writable);
                              end;
                            consts_dec(true,not is_javainterface(current_structdef));
                            if final_fields and
                               typedconstswritable then
                              include(current_settings.localswitches,cs_typed_const_writable);
                          end
                        else
                          internalerror(201001110);
                      end;
                end;
              end;
            _PROPERTY :
              begin
                struct_property_dec(is_classdef);
                fields_allowed:=false;
                is_classdef:=false;
              end;
            _CLASS:
              begin
                parse_class;
              end;
            _PROCEDURE,
            _FUNCTION,
            _CONSTRUCTOR,
            _DESTRUCTOR :
              begin
                method_dec(current_structdef,is_classdef);
                fields_allowed:=false;
                is_classdef:=false;
              end;
            _END :
              begin
                consume(_END);
                break;
              end;
            else
              consume(_ID); { Give a ident expected message, like tp7 }
          end;
        until false;

        if is_class(current_structdef) then
          tabstractrecordsymtable(current_structdef.symtable).addfieldlist(fieldlist,true);
        fieldlist.free;
      end;


    function object_dec(objecttype:tobjecttyp;const n:tidstring;objsym:tsym;genericdef:tstoreddef;genericlist:TFPObjectList;fd : tobjectdef;helpertype:thelpertype) : tobjectdef;
      var
        old_current_structdef: tabstractrecorddef;
        old_current_genericdef,
        old_current_specializedef: tstoreddef;
        hrecst: trecordsymtable;
        fsym: tfieldvarsym;
        old_parse_generic: boolean;
        list: TFPObjectList;
        s: String;
        st: TSymtable;
        olddef: tdef;
      begin
        old_current_structdef:=current_structdef;
        old_current_genericdef:=current_genericdef;
        old_current_specializedef:=current_specializedef;
        old_parse_generic:=parse_generic;

        current_structdef:=nil;
        current_genericdef:=nil;
        current_specializedef:=nil;

        { objects and class types can't be declared local }
        if not(symtablestack.top.symtabletype in [globalsymtable,staticsymtable,objectsymtable,recordsymtable]) and
           not assigned(genericlist) then
          Message(parser_e_no_local_objects);

        { reuse forward objectdef? }
        if assigned(fd) then
          begin
            if fd.objecttype<>objecttype then
              begin
                Message(parser_e_forward_mismatch);
                { recover }
                current_structdef:=tobjectdef.create(current_objectdef.objecttype,n,nil);
                include(current_structdef.objectoptions,oo_is_forward);
              end
            else
              current_structdef:=fd
          end
        else
          begin
            { anonym objects aren't allow (o : object a : longint; end;) }
            if n='' then
              Message(parser_f_no_anonym_objects);

            { create new class }
            current_structdef:=tobjectdef.create(objecttype,n,nil);

            { include always the forward flag, it'll be removed after the parent class have been
              added. This is to prevent circular childof loops }
            include(current_structdef.objectoptions,oo_is_forward);

            if (cs_compilesystem in current_settings.moduleswitches) then
              begin
                case current_objectdef.objecttype of
                  odt_interfacecom :
                    if (current_structdef.objname^='IUNKNOWN') then
                      interface_iunknown:=current_objectdef
                    else
                    if (current_structdef.objname^='IDISPATCH') then
                      interface_idispatch:=current_objectdef;
                  odt_class :
                    if (current_structdef.objname^='TOBJECT') then
                      class_tobject:=current_objectdef;
                  odt_javaclass:
                    begin
                      if (current_structdef.objname^='TOBJECT') then
                        class_tobject:=current_objectdef
                      else if (current_objectdef.objname^='JLOBJECT') then
                        begin
                          java_jlobject:=current_objectdef;
                          { the methodpointer type is normally created in
                            psystem, but java_jlobject is not yet available
                            there... }
                          hrecst:=trecordsymtable.create('',1);
                          fsym:=tfieldvarsym.create('$proc',vs_value,java_jlobject,[]);
                          hrecst.insert(fsym);
                          hrecst.addfield(fsym,vis_hidden);
                          fsym:=tfieldvarsym.create('$data',vs_value,java_jlobject,[]);
                          hrecst.insert(fsym);
                          hrecst.addfield(fsym,vis_hidden);
                          methodpointertype:=trecorddef.create('',hrecst);
                          systemunit.insert(ttypesym.create('$methodpointer',methodpointertype));
                        end
                      else if (current_objectdef.objname^='JLTHROWABLE') then
                        java_jlthrowable:=current_objectdef
                      else if (current_objectdef.objname^='FPCBASERECORDTYPE') then
                        java_fpcbaserecordtype:=current_objectdef
                      else if (current_objectdef.objname^='JLSTRING') then
                        java_jlstring:=current_objectdef
                      else if (current_objectdef.objname^='ANSISTRINGCLASS') then
                        java_ansistring:=current_objectdef
                      else if (current_objectdef.objname^='SHORTSTRINGCLASS') then
                        java_shortstring:=current_objectdef
                      else if (current_objectdef.objname^='JLENUM') then
                        java_jlenum:=current_objectdef
                      else if (current_objectdef.objname^='JUENUMSET') then
                        java_juenumset:=current_objectdef
                      else if (current_objectdef.objname^='FPCBITSET') then
                        java_jubitset:=current_objectdef
                      else if (current_objectdef.objname^='FPCBASEPROCVARTYPE') then
                        java_procvarbase:=current_objectdef;
                    end;
                end;
              end;
            if (current_module.modulename^='OBJCBASE') then
              begin
                case current_objectdef.objecttype of
                  odt_objcclass:
                    if (current_objectdef.objname^='Protocol') then
                      objc_protocoltype:=current_objectdef;
                end;
              end;
          end;

        { usage of specialized type inside its generic template }
        if assigned(genericdef) then
          current_specializedef:=current_structdef
        { reject declaration of generic class inside generic class }
        else if assigned(genericlist) then
          current_genericdef:=current_structdef;

        { nested types of specializations are specializations as well }
        if assigned(old_current_structdef) and
            (df_specialization in old_current_structdef.defoptions) then
          include(current_structdef.defoptions,df_specialization);
        if assigned(old_current_structdef) and
            (df_generic in old_current_structdef.defoptions) then
          begin
            include(current_structdef.defoptions,df_generic);
            current_genericdef:=current_structdef;
          end;

        { set published flag in $M+ mode, it can also be inherited and will
          be added when the parent class set with tobjectdef.set_parent (PFV) }
        if (cs_generate_rtti in current_settings.localswitches) and
           (current_objectdef.objecttype in [odt_interfacecom,odt_class,odt_helper]) then
          include(current_structdef.objectoptions,oo_can_have_published);

        { Objective-C/Java objectdefs can be "formal definitions", in which case
          the syntax is "type tc = objcclass external;" -> we have to parse
          its object options (external) already here, to make sure that such
          definitions are recognised as formal defs }
        if objecttype in [odt_objcclass,odt_objcprotocol,odt_objccategory,odt_javaclass,odt_interfacejava] then
          parse_object_options;

        { forward def? }
        if not assigned(fd) and
           (token=_SEMICOLON) then
          begin
            { add to the list of definitions to check that the forward
              is resolved. this is required for delphi mode }
            current_module.checkforwarddefs.add(current_structdef);
          end
        else
          begin
            { change objccategories into objcclass helpers }
            if (objecttype=odt_objccategory) then
              begin
                current_objectdef.objecttype:=odt_objcclass;
                include(current_structdef.objectoptions,oo_is_classhelper);
              end;

            { include the class helper flag for Object Pascal helpers }
            if (objecttype=odt_helper) then
              include(current_objectdef.objectoptions,oo_is_classhelper);

            { parse list of options (abstract / sealed) }
            if not(objecttype in [odt_objcclass,odt_objcprotocol,odt_objccategory,odt_javaclass,odt_interfacejava]) then
              parse_object_options;

            symtablestack.push(current_structdef.symtable);
            insert_generic_parameter_types(current_structdef,genericdef,genericlist);
            { when we are parsing a generic already then this is a generic as
              well }
            if old_parse_generic then
              include(current_structdef.defoptions, df_generic);
            parse_generic:=(df_generic in current_structdef.defoptions);

            { in non-Delphi modes we need a strict private symbol without type
              count and type parameters in the name to simply resolving }
            maybe_insert_generic_rename_symbol(n,genericlist);

            { parse list of parent classes }
            { for record helpers in mode Delphi this is not allowed }
            if not (is_objectpascal_helper(current_objectdef) and
                (m_delphi in current_settings.modeswitches) and
                (helpertype=ht_record)) then
              parse_parent_classes
            else
              { remove forward flag, is resolved (this is normally done inside
                parse_parent_classes) }
              exclude(current_structdef.objectoptions,oo_is_forward);

            { parse extended type for helpers }
            if is_objectpascal_helper(current_structdef) then
              parse_extended_type(helpertype);

            { parse optional GUID for interfaces }
            parse_guid;

            { classes can handle links to themself not only inside type blocks
              but in const blocks too. to make this possible we need to set
              their symbols to real defs instead of errordef }

            if assigned(objsym) and (objecttype in [odt_class,odt_javaclass,odt_interfacejava]) then
              begin
                olddef:=ttypesym(objsym).typedef;
                ttypesym(objsym).typedef:=current_structdef;
                current_structdef.typesym:=objsym;
              end
            else
              olddef:=nil;

            { parse and insert object members }
            parse_object_members;

            if assigned(olddef) then
              begin
                ttypesym(objsym).typedef:=olddef;
                current_structdef.typesym:=nil;
              end;

          if not(oo_is_external in current_structdef.objectoptions) then
            begin
              { In Java, constructors are not automatically inherited (so you can
                hide them). Emulate the Pascal behaviour for classes implemented
                in Pascal (we cannot do it for classes implemented in Java, since
                we obviously cannot add constructors to those) }
              if is_javaclass(current_structdef) then
                begin
                  add_missing_parent_constructors_intf(tobjectdef(current_structdef),true,vis_none);
{$ifdef jvm}
                  maybe_add_public_default_java_constructor(tobjectdef(current_structdef));
                  jvm_wrap_virtual_class_methods(tobjectdef(current_structdef));
{$endif}
                end;
              { need method to hold the initialization code for typed constants? }
              if (target_info.system in systems_typed_constants_node_init) and
                 not is_any_interface_kind(current_structdef) then
                add_typedconst_init_routine(current_structdef);
            end;

            symtablestack.pop(current_structdef.symtable);
          end;

        { generate vmt space if needed }
        if not(oo_has_vmt in current_structdef.objectoptions) and
           not(oo_is_forward in current_structdef.objectoptions) and
           { no vmt for helpers ever }
           not is_objectpascal_helper(current_structdef) and
           (
            ([oo_has_virtual,oo_has_constructor,oo_has_destructor]*current_structdef.objectoptions<>[]) or
            (current_objectdef.objecttype in [odt_class])
           ) then
          current_objectdef.insertvmt;

        { for implemented classes with a vmt check if there is a constructor }
        if (oo_has_vmt in current_structdef.objectoptions) and
           not(oo_is_forward in current_structdef.objectoptions) and
           not(oo_has_constructor in current_structdef.objectoptions) and
           not is_objc_class_or_protocol(current_structdef) and
           not is_java_class_or_interface(current_structdef) then
          Message1(parser_w_virtual_without_constructor,current_structdef.objrealname^);

        if is_interface(current_structdef) or
           is_objcprotocol(current_structdef) or
           is_javainterface(current_structdef) then
          setinterfacemethodoptions
        else if is_objcclass(current_structdef) then
          setobjcclassmethodoptions;

        { we need to add this helper to the extendeddefs of the current module,
          as the global and static symtable are not pushed onto the symtable
          stack again (it will be removed when poping the symtable) }
        if is_objectpascal_helper(current_structdef) and
            (current_objectdef.extendeddef.typ<>errordef) then
          begin
            { the topmost symtable must be a static symtable }
            st:=current_structdef.owner;
            while st.symtabletype in [objectsymtable,recordsymtable] do
              st:=st.defowner.owner;
            if st.symtabletype in [staticsymtable,globalsymtable] then
              begin
                if current_objectdef.extendeddef.typ in [recorddef,objectdef] then
                  s:=make_mangledname('',tabstractrecorddef(current_objectdef.extendeddef).symtable,'')
                else
                  s:=make_mangledname('',current_objectdef.extendeddef.owner,current_objectdef.extendeddef.typesym.name);
                Message1(sym_d_adding_helper_for,s);
                list:=TFPObjectList(current_module.extendeddefs.Find(s));
                if not assigned(list) then
                  begin
                    list:=TFPObjectList.Create(false);
                    current_module.extendeddefs.Add(s, list);
                  end;
                list.add(current_structdef);
              end;
          end;
        tabstractrecordsymtable(current_objectdef.symtable).addalignmentpadding;

        { return defined objectdef }
        result:=current_objectdef;

        { restore old state }
        current_structdef:=old_current_structdef;
        current_genericdef:=old_current_genericdef;
        current_specializedef:=old_current_specializedef;
        parse_generic:=old_parse_generic;
      end;

end.
