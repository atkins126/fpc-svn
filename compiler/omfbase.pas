{
    Copyright (c) 2015 by Nikolay Nikolov

    Contains Relocatable Object Module Format (OMF) definitions
    This is the object format used on the i8086-msdos platform.

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
unit omfbase;

{$i fpcdefs.inc}

interface
{$H+}
  uses
    cclasses,
    aasmbase,
    owbase;

  const
    { OMF segment names for the object sections, produced by the FPC code generator }
    omf_secnames : array[TAsmSectiontype] of string[length('__DATA, __datacoal_nt,coalesced')] = ('','',
      '_TEXT',
      'data',
      'data',
      'rodata',
      'bss',
      'tbss',
      'pdata',
      '_TEXT','data','data','data','data',
      'stab',
      'stabstr',
      'idata2','idata4','idata5','idata6','idata7','edata',
      'eh_frame',
      '.debug_frame','.debug_info','.debug_line','.debug_abbrev','.debug_aranges','.debug_ranges',
      'fpc',
      '',
      'init',
      'fini',
      'objc_class',
      'objc_meta_class',
      'objc_cat_cls_meth',
      'objc_cat_inst_meth',
      'objc_protocol',
      'objc_string_object',
      'objc_cls_meth',
      'objc_inst_meth',
      'objc_cls_refs',
      'objc_message_refs',
      'objc_symbols',
      'objc_category',
      'objc_class_vars',
      'objc_instance_vars',
      'objc_module_info',
      'objc_class_names',
      'objc_meth_var_types',
      'objc_meth_var_names',
      'objc_selector_strs',
      'objc_protocol_ext',
      'objc_class_ext',
      'objc_property',
      'objc_image_info',
      'objc_cstring_object',
      'objc_sel_fixup',
      '__DATA,__objc_data',
      '__DATA,__objc_const',
      'objc_superrefs',
      '__DATA, __datacoal_nt,coalesced',
      'objc_classlist',
      'objc_nlclasslist',
      'objc_catlist',
      'obcj_nlcatlist',
      'objc_protolist',
      'stack',
      'heap'
    );

    { OMF record types }
    RT_THEADR    = $80;  { Translator Header Record }
    RT_LHEADR    = $82;  { Library Module Header Record }
    RT_COMENT    = $88;  { Comment Record }
    RT_MODEND    = $8A;  { Module End Record }
    RT_MODEND32  = $8B;
    RT_EXTDEF    = $8C;  { External Names Definition Record }
    RT_PUBDEF    = $90;  { Public Names Definition Record }
    RT_PUBDEF32  = $91;
    RT_LINNUM    = $94;  { Line Numbers Record }
    RT_LINNUM32  = $95;
    RT_LNAMES    = $96;  { List of Names Record }
    RT_SEGDEF    = $98;  { Segment Definition Record }
    RT_SEGDEF32  = $99;
    RT_GRPDEF    = $9A;  { Group Definition Record }
    RT_FIXUPP    = $9C;  { Fixup Record }
    RT_FIXUPP32  = $9D;
    RT_LEDATA    = $A0;  { Logical Enumerated Data Record }
    RT_LEDATA32  = $A1;
    RT_LIDATA    = $A2;  { Logical Iterated Data Record }
    RT_LIDATA32  = $A3;
    RT_COMDEF    = $B0;  { Communal Names Definition Record }
    RT_BAKPAT    = $B2;  { Backpatch Record }
    RT_BAKPAT32  = $B3;
    RT_LEXTDEF   = $B4;  { Local External Names Definition Record }
    RT_LEXTDEF32 = $B5;
    RT_LPUBDEF   = $B6;  { Local Public Names Definition Record }
    RT_LPUBDEF32 = $B7;
    RT_LCOMDEF   = $B8;  { Local Communal Names Definition Record }
    RT_CEXTDEF   = $BC;  { COMDAT External Names Definition Record }
    RT_COMDAT    = $C2;  { Initialized Communal Data Record }
    RT_COMDAT32  = $C3;
    RT_LINSYM    = $C4;  { Symbol Line Numbers Record }
    RT_LINSYM32  = $C5;
    RT_ALIAS     = $C6;  { Alias Definition Record }
    RT_NBKPAT    = $C8;  { Named Backpatch Record }
    RT_NBKPAT32  = $C9;
    RT_LLNAMES   = $CA;  { Local Logical Names Definition Record }
    RT_VERNUM    = $CC;  { OMF Version Number Record }
    RT_VENDEXT   = $CE;  { Vendor-specific OMF Extension Record }
    RT_LIBHEAD   = $F0;  { Library Header Record }
    RT_LIBEND    = $F1;  { Library End Record (marks end of objects and beginning of dictionary) }

    { OMF comment class }
    CC_Translator               = $00; { language translator (compiler or assembler) name }
    CC_IntelCopyright           = $01;
    CC_IntelReservedRangeStart  = $02;
    CC_IntelReservedRangeEnd    = $9B;
    CC_LibrarySpecifierObsolete = $81;
    CC_MsDosVersionObsolete     = $9C;
    CC_MemoryModel              = $9D;
    CC_DOSSEG                   = $9E;
    CC_DefaultLibrarySearchName = $9F;
    CC_OmfExtension             = $A0;
    CC_NewOmfExtension          = $A1;
    CC_LinkPassSeparator        = $A2;
    CC_LIBMOD                   = $A3;
    CC_EXESTR                   = $A4;
    CC_INCERR                   = $A6;
    CC_NOPAD                    = $A7;
    CC_WKEXT                    = $A8;
    CC_LZEXT                    = $A9;
    CC_Comment                  = $DA;
    CC_Compiler                 = $DB;
    CC_Date                     = $DC;
    CC_Timestamp                = $DD;
    CC_User                     = $DF;
    CC_DependencyFileBorland    = $E9;
    CC_CommandLineMicrosoft     = $FF;

  type
    TOmfSegmentAlignment = (
      saAbsolute                = 0,
      saRelocatableByteAligned  = 1,
      saRelocatableWordAligned  = 2,
      saRelocatableParaAligned  = 3,
      saRelocatablePageAligned  = 4,  { 32-bit linkers extension }
      saRelocatableDWordAligned = 5,  { 32-bit linkers extension }
      saNotSupported            = 6,  { PharLap: 4096-byte page alignment }
      saNotDefined              = 7);
    TOmfSegmentCombination = (
      scPrivate   = 0,
      scReserved1 = 1,
      scPublic    = 2,
      scReserved3 = 3,
      scPublic4   = 4,  { same as scPublic }
      scStack     = 5,
      scCommon    = 6,
      scPublic7   = 7); { same as scPublic }
    TOmfSegmentUse = (suUse16, suUse32);

    TOmfFixupThread = (ftThread0, ftThread1, ftThread2, ftThread3);

    TOmfFixupMode = (fmSelfRelative, fmSegmentRelative);
    TOmfFixupLocationType = (
      fltLoByte                 = 0,  { low 8 bits of 16-bit offset }
      fltOffset                 = 1,  { 16-bit offset }
      fltBase                   = 2,  { 16-bit base (segment) }
      fltFarPointer             = 3,  { 16-bit base:16-bit offset }
      fltHiByte                 = 4,  { high 8 bits of 16-bit offset }
      fltLoaderResolvedOffset   = 5,  { PharLap: Offset32 }
      fltUndefined6             = 6,  { PharLap: Pointer48 }
      fltUndefined7             = 7,
      fltUndefined8             = 8,
      fltOffset32               = 9,  { 32-bit offset }
      fltUndefined10            = 10,
      fltFarPointer48           = 11, { 16-bit base:32-bit offset }
      fltUndefined12            = 12,
      fltLoaderResolvedOffset32 = 13,
      fltUndefined14            = 14,
      fltUndefined15            = 15);
    TOmfFixupFrameMethod = (
      ffmSegmentIndex  = 0,  { SI(<segment name>) - The frame is the canonic frame of the logical
                                                    segment segment defined by the index }
      ffmGroupIndex    = 1,  { GI(<group name>)   - The frame is the canonic frame of the group
                                                    (= the canonic frame of the logical segment from the group,
                                                    located at the lowest memory address) }
      ffmExternalIndex = 2,  { EI(<symbol name>)  - The frame is determined depending on the external's public definition:
                                                     * if the symbol is defined relative to a logical segment and no defined group,
                                                       the frame of the logical segment is used
                                                     * if the symbol is defined absolutely, without reference to a logical segment and
                                                       no defined group, the FRAME NUMBER from the symbol's PUBDEF record is used
                                                     * regardless of how the symbol is specified, if there's an associated group,
                                                       that group's canonic frame is used }
      ffmFrameNumber   = 3,  { <FRAME NUMBER> - The frame is a directly specified constant. }
      ffmLocation      = 4,  { LOCATION - The frame is determined by the location (i.e. the canonic frame of the logical
                                          segment where the fixup location is) }
      ffmTarget        = 5,  { TARGET - The frame is determined by the target. }
      ffmNone          = 6,  { NONE - There is no frame. Used for 8089 self-relative references. }
      ffmUndefined     = 7);
    TOmfFixupTargetMethod = (
      ftmSegmentIndex        = 0,  { SI(<segment name>),<displacement> }
      ftmGroupIndex          = 1,  { GI(<group name>),<displacement> }
      ftmExternalIndex       = 2,  { EI(<symbol name>),<displacement> }
      ftmFrameNumber         = 3,  { <FRAME NUMBER>,<displacement> }
      ftmSegmentIndexNoDisp  = 4,  { SI(<segment name>) }
      ftmGroupIndexNoDisp    = 5,  { GI(<group name>) }
      ftmExternalIndexNoDisp = 6,  { EI(<symbol name>) }
      ftmFrameNumberNoDisp   = 7); { <FRAME NUMBER> }

    { TOmfOrderedNameCollection }

    TOmfOrderedNameCollection = class
    private
      FAllowDuplicates: Boolean;
      FStringList: array of string;
      function GetCount: Integer;
      function GetString(Index: Integer): string;
      procedure SetString(Index: Integer; AValue: string);
    public
      constructor Create(AAllowDuplicates: Boolean);
      function Add(const S: string): Integer;
      procedure Clear;
      property Strings [Index: Integer]: string read GetString write SetString; default;
      property Count: Integer read GetCount;
      property AllowDuplicates: Boolean read FAllowDuplicates;
    end;

    { TOmfRawRecord }

    TOmfRawRecord = class
    private
      function GetChecksumByte: Byte;
      function GetRecordLength: Word;
      function GetRecordType: Byte;
      procedure SetChecksumByte(AValue: Byte);
      procedure SetRecordLength(AValue: Word);
      procedure SetRecordType(AValue: Byte);
    public
      RawData: array [-3..65535] of Byte;
      property RecordType: Byte read GetRecordType write SetRecordType;
      property RecordLength: Word read GetRecordLength write SetRecordLength;

      function ReadStringAt(Offset: Integer; out s: string): Integer;
      function WriteStringAt(Offset: Integer; s: string): Integer;

      function ReadIndexedRef(Offset: Integer; out IndexedRef: Integer): Integer;
      function WriteIndexedRef(Offset: Integer; IndexedRef: Integer): Integer;

      procedure CalculateChecksumByte;
      function VerifyChecksumByte: boolean;
      property ChecksumByte: Byte read GetChecksumByte write SetChecksumByte;

      procedure ReadFrom(aReader: TObjectReader);
      procedure ReadFrom(aReader: TDynamicArray);
      procedure WriteTo(aWriter: TObjectWriter);
      procedure WriteTo(aWriter: TDynamicArray);
    end;

    { TOmfParsedRecord }

    TOmfParsedRecord = class
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);virtual;abstract;
      procedure EncodeTo(RawRecord: TOmfRawRecord);virtual;abstract;
    end;

    { TOmfRecord_THEADR }

    TOmfRecord_THEADR = class(TOmfParsedRecord)
    private
      FModuleName: string;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property ModuleName: string read FModuleName write FModuleName;
    end;

    { TOmfRecord_COMENT }

    TOmfRecord_COMENT = class(TOmfParsedRecord)
    private
      FCommentType: Byte;
      FCommentClass: Byte;
      FCommentString: string;
      function GetNoList: Boolean;
      function GetNoPurge: Boolean;
      procedure SetNoList(AValue: Boolean);
      procedure SetNoPurge(AValue: Boolean);
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property CommentType: Byte read FCommentType write FCommentType;
      property CommentClass: Byte read FCommentClass write FCommentClass;
      property CommentString: string read FCommentString write FCommentString;
      property NoPurge: Boolean read GetNoPurge write SetNoPurge;
      property NoList: Boolean read GetNoList write SetNoList;
    end;

    { TOmfRecord_LNAMES }

    TOmfRecord_LNAMES = class(TOmfParsedRecord)
    private
      FNames: TOmfOrderedNameCollection;
      FNextIndex: Integer;
    public
      constructor Create;

      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property Names: TOmfOrderedNameCollection read FNames write FNames;
      property NextIndex: Integer read FNextIndex write FNextIndex;
    end;

    { TOmfRecord_SEGDEF }

    TOmfRecord_SEGDEF = class(TOmfParsedRecord)
    private
      FAlignment: TOmfSegmentAlignment;
      FCombination: TOmfSegmentCombination;
      FUse: TOmfSegmentUse;
      FFrameNumber: Word;
      FOffset: Byte;
      FIs32Bit: Boolean;
      FSegmentLength: Int64;  { int64, because it can be 2**32 }
      FSegmentNameIndex: Integer;
      FClassNameIndex: Integer;
      FOverlayNameIndex: Integer;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      procedure MaybeGo32;

      property Alignment: TOmfSegmentAlignment read FAlignment write FAlignment;
      property Combination: TOmfSegmentCombination read FCombination write FCombination;
      property Use: TOmfSegmentUse read FUse write FUse;
      property FrameNumber: Word read FFrameNumber write FFrameNumber;
      property Offset: Byte read FOffset write FOffset;
      property Is32Bit: Boolean read FIs32Bit write FIs32Bit;
      property SegmentLength: Int64 read FSegmentLength write FSegmentLength;
      property SegmentNameIndex: Integer read FSegmentNameIndex write FSegmentNameIndex;
      property ClassNameIndex: Integer read FClassNameIndex write FClassNameIndex;
      property OverlayNameIndex: Integer read FOverlayNameIndex write FOverlayNameIndex;
    end;

    TSegmentList = array of Integer;

    { TOmfRecord_GRPDEF }

    TOmfRecord_GRPDEF = class(TOmfParsedRecord)
    private
      FGroupNameIndex: Integer;
      FSegmentList: TSegmentList;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property GroupNameIndex: Integer read FGroupNameIndex write FGroupNameIndex;
      property SegmentList: TSegmentList read FSegmentList write FSegmentList;
    end;

    { TOmfPublicNameElement }

    TOmfPublicNameElement = class(TFPHashObject)
    private
      FPublicOffset: DWord;
      FTypeIndex: Integer;
    public
      function GetLengthInFile(Is32Bit: Boolean): Integer;

      property PublicOffset: DWord read FPublicOffset write FPublicOffset;
      property TypeIndex: Integer read FTypeIndex write FTypeIndex;
    end;

    { TOmfRecord_PUBDEF }

    TOmfRecord_PUBDEF = class(TOmfParsedRecord)
    private
      FIs32Bit: Boolean;
      FBaseGroupIndex: Integer;
      FBaseSegmentIndex: Integer;
      FBaseFrame: Word;

      FPublicNames: TFPHashObjectList;
      FNextIndex: Integer;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      procedure MaybeGo32;

      property Is32Bit: Boolean read FIs32Bit write FIs32Bit;
      property BaseGroupIndex: Integer read FBaseGroupIndex write FBaseGroupIndex;
      property BaseSegmentIndex: Integer read FBaseSegmentIndex write FBaseSegmentIndex;
      property BaseFrame: Word read FBaseFrame write FBaseFrame;

      property PublicNames: TFPHashObjectList read FPublicNames write FPublicNames;
      property NextIndex: Integer read FNextIndex write FNextIndex;
    end;

    { TOmfExternalNameElement }

    TOmfExternalNameElement = class(TFPHashObject)
    private
      FTypeIndex: Integer;
    public
      function GetLengthInFile: Integer;

      property TypeIndex: Integer read FTypeIndex write FTypeIndex;
    end;

    { TOmfRecord_EXTDEF }

    TOmfRecord_EXTDEF = class(TOmfParsedRecord)
    private
      FExternalNames: TFPHashObjectList;
      FNextIndex: Integer;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property ExternalNames: TFPHashObjectList read FExternalNames write FExternalNames;
      property NextIndex: Integer read FNextIndex write FNextIndex;
    end;

    { TOmfRecord_MODEND }

    TOmfRecord_MODEND = class(TOmfParsedRecord)
    private
      FIs32Bit: Boolean;
      FIsMainModule: Boolean;
      FHasStartAddress: Boolean;
      FSegmentBit: Boolean;
      FLogicalStartAddress: Boolean;

      FFrameMethod: TOmfFixupFrameMethod;
      FFrameDatum: Integer;
      FTargetMethod: TOmfFixupTargetMethod;
      FTargetDatum: Integer;
      FTargetDisplacement: DWord;

      FPhysFrameNumber: Word;
      FPhysOffset: DWord;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property Is32Bit: Boolean read FIs32Bit write FIs32Bit;
      property IsMainModule: Boolean read FIsMainModule write FIsMainModule;
      property HasStartAddress: Boolean read FHasStartAddress write FHasStartAddress;
      property SegmentBit: Boolean read FSegmentBit write FSegmentBit;
      property LogicalStartAddress: Boolean read FLogicalStartAddress write FLogicalStartAddress;

      { properties, specifying a logical start address (used when LogicalStartAddress=true) }
      property FrameMethod: TOmfFixupFrameMethod read FFrameMethod write FFrameMethod;
      property FrameDatum: Integer read FFrameDatum write FFrameDatum;
      property TargetMethod: TOmfFixupTargetMethod read FTargetMethod write FTargetMethod;
      property TargetDatum: Integer read FTargetDatum write FTargetDatum;
      property TargetDisplacement: DWord read FTargetDisplacement write FTargetDisplacement;

      { properties, specifying a physical start address (used when LogicalStartAddress=false) }
      property PhysFrameNumber: Word read FPhysFrameNumber write FPhysFrameNumber;
      property PhysOffset: DWord read FPhysOffset write FPhysOffset;
    end;

    { TOmfRecord_LINNUM }

    TOmfRecord_LINNUM = class(TOmfParsedRecord)
    private
      FIs32Bit: Boolean;
      FBaseGroup: Integer;
      FBaseSegment: Integer;
      FNextIndex: Integer;
    protected
      procedure DebugFormatSpecific_DecodeFrom(RawRecord:TOmfRawRecord;NextOfs:Integer);virtual;abstract;
      procedure DebugFormatSpecific_EncodeTo(RawRecord:TOmfRawRecord;var NextOfs:Integer);virtual;abstract;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property Is32Bit: Boolean read FIs32Bit write FIs32Bit;
      property BaseGroup: Integer read FBaseGroup write FBaseGroup;
      property BaseSegment: Integer read FBaseSegment write FBaseSegment;
      property NextIndex: Integer read FNextIndex write FNextIndex;
    end;

    TOmfSubRecord_LINNUM_MsLink_LineNumber = 0..$7fff;

    { TOmfSubRecord_LINNUM_MsLink_Entry }

    TOmfSubRecord_LINNUM_MsLink_Entry = class
    private
      FLineNumber: TOmfSubRecord_LINNUM_MsLink_LineNumber;
      FOffset: DWord;
    public
      constructor Create(ALineNumber: TOmfSubRecord_LINNUM_MsLink_LineNumber; AOffset: DWord);
      property LineNumber: TOmfSubRecord_LINNUM_MsLink_LineNumber read FLineNumber write FLineNumber;
      property Offset: DWord read FOffset write FOffset;
    end;

    { TOmfSubRecord_LINNUM_MsLink_LineNumberList }

    TOmfSubRecord_LINNUM_MsLink_LineNumberList = class
    private
      FLineNumbers: TFPObjectList;
      function GetCount: Integer;
      function GetItem(Index: Integer): TOmfSubRecord_LINNUM_MsLink_Entry;
      procedure SetCount(AValue: Integer);
      procedure SetItem(Index: Integer; AValue: TOmfSubRecord_LINNUM_MsLink_Entry);
    public
      constructor Create;
      destructor Destroy;override;

      procedure Clear;
      function Add(AObject: TOmfSubRecord_LINNUM_MsLink_Entry): Integer;
      property Count: Integer read GetCount write SetCount;
      property Items[Index: Integer]: TOmfSubRecord_LINNUM_MsLink_Entry read GetItem write SetItem; default;
    end;

    { TOmfRecord_LINNUM_MsLink }

    TOmfRecord_LINNUM_MsLink = class(TOmfRecord_LINNUM)
    private
      FLineNumberList: TOmfSubRecord_LINNUM_MsLink_LineNumberList;
    protected
      procedure DebugFormatSpecific_DecodeFrom(RawRecord:TOmfRawRecord;NextOfs:Integer);override;
      procedure DebugFormatSpecific_EncodeTo(RawRecord:TOmfRawRecord;var NextOfs:Integer);override;
    public
      property LineNumberList: TOmfSubRecord_LINNUM_MsLink_LineNumberList read FLineNumberList write FLineNumberList;
    end;

    { TOmfSubRecord_FIXUP }

    TOmfSubRecord_FIXUP = class
    private
      FIs32Bit: Boolean;
      FMode: TOmfFixupMode;
      FLocationType: TOmfFixupLocationType;
      FLocationOffset: DWord;
      FDataRecordStartOffset: DWord;
      FTargetDeterminedByThread: Boolean;
      FTargetThread: TOmfFixupThread;
      FTargetThreadDisplacementPresent: Boolean;
      FTargetMethod: TOmfFixupTargetMethod;
      FTargetDatum: Integer;
      FTargetDisplacement: DWord;
      FFrameDeterminedByThread: Boolean;
      FFrameThread: TOmfFixupThread;
      FFrameMethod: TOmfFixupFrameMethod;
      FFrameDatum: Integer;
      function GetDataRecordOffset: Integer;
      function GetLocationSize: Integer;
      procedure SetDataRecordOffset(AValue: Integer);
    public
      function ReadAt(RawRecord: TOmfRawRecord; Offset: Integer): Integer;
      function WriteAt(RawRecord: TOmfRawRecord; Offset: Integer): Integer;

      property Is32Bit: Boolean read FIs32Bit write FIs32Bit;
      property Mode: TOmfFixupMode read FMode write FMode;
      property LocationType: TOmfFixupLocationType read FLocationType write FLocationType;
      property LocationOffset: DWord read FLocationOffset write FLocationOffset;
      property LocationSize: Integer read GetLocationSize;
      property DataRecordStartOffset: DWord read FDataRecordStartOffset write FDataRecordStartOffset;
      property DataRecordOffset: Integer read GetDataRecordOffset write SetDataRecordOffset;
      property TargetDeterminedByThread: Boolean read FTargetDeterminedByThread write FTargetDeterminedByThread;
      property TargetThread: TOmfFixupThread read FTargetThread write FTargetThread;
      property TargetThreadDisplacementPresent: Boolean read FTargetThreadDisplacementPresent write FTargetThreadDisplacementPresent;
      property TargetMethod: TOmfFixupTargetMethod read FTargetMethod write FTargetMethod;
      property TargetDatum: Integer read FTargetDatum write FTargetDatum;
      property TargetDisplacement: DWord read FTargetDisplacement write FTargetDisplacement;
      property FrameDeterminedByThread: Boolean read FFrameDeterminedByThread write FFrameDeterminedByThread;
      property FrameThread: TOmfFixupThread read FFrameThread write FFrameThread;
      property FrameMethod: TOmfFixupFrameMethod read FFrameMethod write FFrameMethod;
      property FrameDatum: Integer read FFrameDatum write FFrameDatum;
    end;

    { TOmfRecord_LIBHEAD }

    TOmfRecord_LIBHEAD = class(TOmfParsedRecord)
    private
      FPageSize: Integer;
      FDictionaryOffset: DWord;
      FDictionarySizeInBlocks: Word;
      FFlags: Byte;
      function IsCaseSensitive: Boolean;
      procedure SetCaseSensitive(AValue: Boolean);
      procedure SetPageSize(AValue: Integer);
    public
      constructor Create;
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      property PageSize: Integer read FPageSize write SetPageSize;
      property DictionaryOffset: DWord read FDictionaryOffset write FDictionaryOffset;
      property DictionarySizeInBlocks: Word read FDictionarySizeInBlocks write FDictionarySizeInBlocks;
      property Flags: Byte read FFlags write FFlags;
      property CaseSensitive: Boolean read IsCaseSensitive write SetCaseSensitive;
    end;

    { TOmfRecord_LIBEND }

    TOmfRecord_LIBEND = class(TOmfParsedRecord)
    private
      FPaddingBytes: Word;
    public
      procedure DecodeFrom(RawRecord: TOmfRawRecord);override;
      procedure EncodeTo(RawRecord: TOmfRawRecord);override;

      procedure CalculatePaddingBytes(RecordStartOffset: DWord);
      property PaddingBytes: Word read FPaddingBytes write FPaddingBytes;
    end;

  const
    { list of all the possible omf library dictionary block counts - contains
      all the prime numbers less than 65536 }
    OmfLibDictionaryBlockCounts: array [0..6541] of Word =
      (2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,
       101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,
       193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,
       293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,
       409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509,
       521,523,541,547,557,563,569,571,577,587,593,599,601,607,613,617,619,631,
       641,643,647,653,659,661,673,677,683,691,701,709,719,727,733,739,743,751,
       757,761,769,773,787,797,809,811,821,823,827,829,839,853,857,859,863,877,
       881,883,887,907,911,919,929,937,941,947,953,967,971,977,983,991,997,1009,
       1013,1019,1021,1031,1033,1039,1049,1051,1061,1063,1069,1087,1091,1093,
       1097,1103,1109,1117,1123,1129,1151,1153,1163,1171,1181,1187,1193,1201,
       1213,1217,1223,1229,1231,1237,1249,1259,1277,1279,1283,1289,1291,1297,
       1301,1303,1307,1319,1321,1327,1361,1367,1373,1381,1399,1409,1423,1427,
       1429,1433,1439,1447,1451,1453,1459,1471,1481,1483,1487,1489,1493,1499,
       1511,1523,1531,1543,1549,1553,1559,1567,1571,1579,1583,1597,1601,1607,
       1609,1613,1619,1621,1627,1637,1657,1663,1667,1669,1693,1697,1699,1709,
       1721,1723,1733,1741,1747,1753,1759,1777,1783,1787,1789,1801,1811,1823,
       1831,1847,1861,1867,1871,1873,1877,1879,1889,1901,1907,1913,1931,1933,
       1949,1951,1973,1979,1987,1993,1997,1999,2003,2011,2017,2027,2029,2039,
       2053,2063,2069,2081,2083,2087,2089,2099,2111,2113,2129,2131,2137,2141,
       2143,2153,2161,2179,2203,2207,2213,2221,2237,2239,2243,2251,2267,2269,
       2273,2281,2287,2293,2297,2309,2311,2333,2339,2341,2347,2351,2357,2371,
       2377,2381,2383,2389,2393,2399,2411,2417,2423,2437,2441,2447,2459,2467,
       2473,2477,2503,2521,2531,2539,2543,2549,2551,2557,2579,2591,2593,2609,
       2617,2621,2633,2647,2657,2659,2663,2671,2677,2683,2687,2689,2693,2699,
       2707,2711,2713,2719,2729,2731,2741,2749,2753,2767,2777,2789,2791,2797,
       2801,2803,2819,2833,2837,2843,2851,2857,2861,2879,2887,2897,2903,2909,
       2917,2927,2939,2953,2957,2963,2969,2971,2999,3001,3011,3019,3023,3037,
       3041,3049,3061,3067,3079,3083,3089,3109,3119,3121,3137,3163,3167,3169,
       3181,3187,3191,3203,3209,3217,3221,3229,3251,3253,3257,3259,3271,3299,
       3301,3307,3313,3319,3323,3329,3331,3343,3347,3359,3361,3371,3373,3389,
       3391,3407,3413,3433,3449,3457,3461,3463,3467,3469,3491,3499,3511,3517,
       3527,3529,3533,3539,3541,3547,3557,3559,3571,3581,3583,3593,3607,3613,
       3617,3623,3631,3637,3643,3659,3671,3673,3677,3691,3697,3701,3709,3719,
       3727,3733,3739,3761,3767,3769,3779,3793,3797,3803,3821,3823,3833,3847,
       3851,3853,3863,3877,3881,3889,3907,3911,3917,3919,3923,3929,3931,3943,
       3947,3967,3989,4001,4003,4007,4013,4019,4021,4027,4049,4051,4057,4073,
       4079,4091,4093,4099,4111,4127,4129,4133,4139,4153,4157,4159,4177,4201,
       4211,4217,4219,4229,4231,4241,4243,4253,4259,4261,4271,4273,4283,4289,
       4297,4327,4337,4339,4349,4357,4363,4373,4391,4397,4409,4421,4423,4441,
       4447,4451,4457,4463,4481,4483,4493,4507,4513,4517,4519,4523,4547,4549,
       4561,4567,4583,4591,4597,4603,4621,4637,4639,4643,4649,4651,4657,4663,
       4673,4679,4691,4703,4721,4723,4729,4733,4751,4759,4783,4787,4789,4793,
       4799,4801,4813,4817,4831,4861,4871,4877,4889,4903,4909,4919,4931,4933,
       4937,4943,4951,4957,4967,4969,4973,4987,4993,4999,5003,5009,5011,5021,
       5023,5039,5051,5059,5077,5081,5087,5099,5101,5107,5113,5119,5147,5153,
       5167,5171,5179,5189,5197,5209,5227,5231,5233,5237,5261,5273,5279,5281,
       5297,5303,5309,5323,5333,5347,5351,5381,5387,5393,5399,5407,5413,5417,
       5419,5431,5437,5441,5443,5449,5471,5477,5479,5483,5501,5503,5507,5519,
       5521,5527,5531,5557,5563,5569,5573,5581,5591,5623,5639,5641,5647,5651,
       5653,5657,5659,5669,5683,5689,5693,5701,5711,5717,5737,5741,5743,5749,
       5779,5783,5791,5801,5807,5813,5821,5827,5839,5843,5849,5851,5857,5861,
       5867,5869,5879,5881,5897,5903,5923,5927,5939,5953,5981,5987,6007,6011,
       6029,6037,6043,6047,6053,6067,6073,6079,6089,6091,6101,6113,6121,6131,
       6133,6143,6151,6163,6173,6197,6199,6203,6211,6217,6221,6229,6247,6257,
       6263,6269,6271,6277,6287,6299,6301,6311,6317,6323,6329,6337,6343,6353,
       6359,6361,6367,6373,6379,6389,6397,6421,6427,6449,6451,6469,6473,6481,
       6491,6521,6529,6547,6551,6553,6563,6569,6571,6577,6581,6599,6607,6619,
       6637,6653,6659,6661,6673,6679,6689,6691,6701,6703,6709,6719,6733,6737,
       6761,6763,6779,6781,6791,6793,6803,6823,6827,6829,6833,6841,6857,6863,
       6869,6871,6883,6899,6907,6911,6917,6947,6949,6959,6961,6967,6971,6977,
       6983,6991,6997,7001,7013,7019,7027,7039,7043,7057,7069,7079,7103,7109,
       7121,7127,7129,7151,7159,7177,7187,7193,7207,7211,7213,7219,7229,7237,
       7243,7247,7253,7283,7297,7307,7309,7321,7331,7333,7349,7351,7369,7393,
       7411,7417,7433,7451,7457,7459,7477,7481,7487,7489,7499,7507,7517,7523,
       7529,7537,7541,7547,7549,7559,7561,7573,7577,7583,7589,7591,7603,7607,
       7621,7639,7643,7649,7669,7673,7681,7687,7691,7699,7703,7717,7723,7727,
       7741,7753,7757,7759,7789,7793,7817,7823,7829,7841,7853,7867,7873,7877,
       7879,7883,7901,7907,7919,7927,7933,7937,7949,7951,7963,7993,8009,8011,
       8017,8039,8053,8059,8069,8081,8087,8089,8093,8101,8111,8117,8123,8147,
       8161,8167,8171,8179,8191,8209,8219,8221,8231,8233,8237,8243,8263,8269,
       8273,8287,8291,8293,8297,8311,8317,8329,8353,8363,8369,8377,8387,8389,
       8419,8423,8429,8431,8443,8447,8461,8467,8501,8513,8521,8527,8537,8539,
       8543,8563,8573,8581,8597,8599,8609,8623,8627,8629,8641,8647,8663,8669,
       8677,8681,8689,8693,8699,8707,8713,8719,8731,8737,8741,8747,8753,8761,
       8779,8783,8803,8807,8819,8821,8831,8837,8839,8849,8861,8863,8867,8887,
       8893,8923,8929,8933,8941,8951,8963,8969,8971,8999,9001,9007,9011,9013,
       9029,9041,9043,9049,9059,9067,9091,9103,9109,9127,9133,9137,9151,9157,
       9161,9173,9181,9187,9199,9203,9209,9221,9227,9239,9241,9257,9277,9281,
       9283,9293,9311,9319,9323,9337,9341,9343,9349,9371,9377,9391,9397,9403,
       9413,9419,9421,9431,9433,9437,9439,9461,9463,9467,9473,9479,9491,9497,
       9511,9521,9533,9539,9547,9551,9587,9601,9613,9619,9623,9629,9631,9643,
       9649,9661,9677,9679,9689,9697,9719,9721,9733,9739,9743,9749,9767,9769,
       9781,9787,9791,9803,9811,9817,9829,9833,9839,9851,9857,9859,9871,9883,
       9887,9901,9907,9923,9929,9931,9941,9949,9967,9973,10007,10009,10037,
       10039,10061,10067,10069,10079,10091,10093,10099,10103,10111,10133,10139,
       10141,10151,10159,10163,10169,10177,10181,10193,10211,10223,10243,10247,
       10253,10259,10267,10271,10273,10289,10301,10303,10313,10321,10331,10333,
       10337,10343,10357,10369,10391,10399,10427,10429,10433,10453,10457,10459,
       10463,10477,10487,10499,10501,10513,10529,10531,10559,10567,10589,10597,
       10601,10607,10613,10627,10631,10639,10651,10657,10663,10667,10687,10691,
       10709,10711,10723,10729,10733,10739,10753,10771,10781,10789,10799,10831,
       10837,10847,10853,10859,10861,10867,10883,10889,10891,10903,10909,10937,
       10939,10949,10957,10973,10979,10987,10993,11003,11027,11047,11057,11059,
       11069,11071,11083,11087,11093,11113,11117,11119,11131,11149,11159,11161,
       11171,11173,11177,11197,11213,11239,11243,11251,11257,11261,11273,11279,
       11287,11299,11311,11317,11321,11329,11351,11353,11369,11383,11393,11399,
       11411,11423,11437,11443,11447,11467,11471,11483,11489,11491,11497,11503,
       11519,11527,11549,11551,11579,11587,11593,11597,11617,11621,11633,11657,
       11677,11681,11689,11699,11701,11717,11719,11731,11743,11777,11779,11783,
       11789,11801,11807,11813,11821,11827,11831,11833,11839,11863,11867,11887,
       11897,11903,11909,11923,11927,11933,11939,11941,11953,11959,11969,11971,
       11981,11987,12007,12011,12037,12041,12043,12049,12071,12073,12097,12101,
       12107,12109,12113,12119,12143,12149,12157,12161,12163,12197,12203,12211,
       12227,12239,12241,12251,12253,12263,12269,12277,12281,12289,12301,12323,
       12329,12343,12347,12373,12377,12379,12391,12401,12409,12413,12421,12433,
       12437,12451,12457,12473,12479,12487,12491,12497,12503,12511,12517,12527,
       12539,12541,12547,12553,12569,12577,12583,12589,12601,12611,12613,12619,
       12637,12641,12647,12653,12659,12671,12689,12697,12703,12713,12721,12739,
       12743,12757,12763,12781,12791,12799,12809,12821,12823,12829,12841,12853,
       12889,12893,12899,12907,12911,12917,12919,12923,12941,12953,12959,12967,
       12973,12979,12983,13001,13003,13007,13009,13033,13037,13043,13049,13063,
       13093,13099,13103,13109,13121,13127,13147,13151,13159,13163,13171,13177,
       13183,13187,13217,13219,13229,13241,13249,13259,13267,13291,13297,13309,
       13313,13327,13331,13337,13339,13367,13381,13397,13399,13411,13417,13421,
       13441,13451,13457,13463,13469,13477,13487,13499,13513,13523,13537,13553,
       13567,13577,13591,13597,13613,13619,13627,13633,13649,13669,13679,13681,
       13687,13691,13693,13697,13709,13711,13721,13723,13729,13751,13757,13759,
       13763,13781,13789,13799,13807,13829,13831,13841,13859,13873,13877,13879,
       13883,13901,13903,13907,13913,13921,13931,13933,13963,13967,13997,13999,
       14009,14011,14029,14033,14051,14057,14071,14081,14083,14087,14107,14143,
       14149,14153,14159,14173,14177,14197,14207,14221,14243,14249,14251,14281,
       14293,14303,14321,14323,14327,14341,14347,14369,14387,14389,14401,14407,
       14411,14419,14423,14431,14437,14447,14449,14461,14479,14489,14503,14519,
       14533,14537,14543,14549,14551,14557,14561,14563,14591,14593,14621,14627,
       14629,14633,14639,14653,14657,14669,14683,14699,14713,14717,14723,14731,
       14737,14741,14747,14753,14759,14767,14771,14779,14783,14797,14813,14821,
       14827,14831,14843,14851,14867,14869,14879,14887,14891,14897,14923,14929,
       14939,14947,14951,14957,14969,14983,15013,15017,15031,15053,15061,15073,
       15077,15083,15091,15101,15107,15121,15131,15137,15139,15149,15161,15173,
       15187,15193,15199,15217,15227,15233,15241,15259,15263,15269,15271,15277,
       15287,15289,15299,15307,15313,15319,15329,15331,15349,15359,15361,15373,
       15377,15383,15391,15401,15413,15427,15439,15443,15451,15461,15467,15473,
       15493,15497,15511,15527,15541,15551,15559,15569,15581,15583,15601,15607,
       15619,15629,15641,15643,15647,15649,15661,15667,15671,15679,15683,15727,
       15731,15733,15737,15739,15749,15761,15767,15773,15787,15791,15797,15803,
       15809,15817,15823,15859,15877,15881,15887,15889,15901,15907,15913,15919,
       15923,15937,15959,15971,15973,15991,16001,16007,16033,16057,16061,16063,
       16067,16069,16073,16087,16091,16097,16103,16111,16127,16139,16141,16183,
       16187,16189,16193,16217,16223,16229,16231,16249,16253,16267,16273,16301,
       16319,16333,16339,16349,16361,16363,16369,16381,16411,16417,16421,16427,
       16433,16447,16451,16453,16477,16481,16487,16493,16519,16529,16547,16553,
       16561,16567,16573,16603,16607,16619,16631,16633,16649,16651,16657,16661,
       16673,16691,16693,16699,16703,16729,16741,16747,16759,16763,16787,16811,
       16823,16829,16831,16843,16871,16879,16883,16889,16901,16903,16921,16927,
       16931,16937,16943,16963,16979,16981,16987,16993,17011,17021,17027,17029,
       17033,17041,17047,17053,17077,17093,17099,17107,17117,17123,17137,17159,
       17167,17183,17189,17191,17203,17207,17209,17231,17239,17257,17291,17293,
       17299,17317,17321,17327,17333,17341,17351,17359,17377,17383,17387,17389,
       17393,17401,17417,17419,17431,17443,17449,17467,17471,17477,17483,17489,
       17491,17497,17509,17519,17539,17551,17569,17573,17579,17581,17597,17599,
       17609,17623,17627,17657,17659,17669,17681,17683,17707,17713,17729,17737,
       17747,17749,17761,17783,17789,17791,17807,17827,17837,17839,17851,17863,
       17881,17891,17903,17909,17911,17921,17923,17929,17939,17957,17959,17971,
       17977,17981,17987,17989,18013,18041,18043,18047,18049,18059,18061,18077,
       18089,18097,18119,18121,18127,18131,18133,18143,18149,18169,18181,18191,
       18199,18211,18217,18223,18229,18233,18251,18253,18257,18269,18287,18289,
       18301,18307,18311,18313,18329,18341,18353,18367,18371,18379,18397,18401,
       18413,18427,18433,18439,18443,18451,18457,18461,18481,18493,18503,18517,
       18521,18523,18539,18541,18553,18583,18587,18593,18617,18637,18661,18671,
       18679,18691,18701,18713,18719,18731,18743,18749,18757,18773,18787,18793,
       18797,18803,18839,18859,18869,18899,18911,18913,18917,18919,18947,18959,
       18973,18979,19001,19009,19013,19031,19037,19051,19069,19073,19079,19081,
       19087,19121,19139,19141,19157,19163,19181,19183,19207,19211,19213,19219,
       19231,19237,19249,19259,19267,19273,19289,19301,19309,19319,19333,19373,
       19379,19381,19387,19391,19403,19417,19421,19423,19427,19429,19433,19441,
       19447,19457,19463,19469,19471,19477,19483,19489,19501,19507,19531,19541,
       19543,19553,19559,19571,19577,19583,19597,19603,19609,19661,19681,19687,
       19697,19699,19709,19717,19727,19739,19751,19753,19759,19763,19777,19793,
       19801,19813,19819,19841,19843,19853,19861,19867,19889,19891,19913,19919,
       19927,19937,19949,19961,19963,19973,19979,19991,19993,19997,20011,20021,
       20023,20029,20047,20051,20063,20071,20089,20101,20107,20113,20117,20123,
       20129,20143,20147,20149,20161,20173,20177,20183,20201,20219,20231,20233,
       20249,20261,20269,20287,20297,20323,20327,20333,20341,20347,20353,20357,
       20359,20369,20389,20393,20399,20407,20411,20431,20441,20443,20477,20479,
       20483,20507,20509,20521,20533,20543,20549,20551,20563,20593,20599,20611,
       20627,20639,20641,20663,20681,20693,20707,20717,20719,20731,20743,20747,
       20749,20753,20759,20771,20773,20789,20807,20809,20849,20857,20873,20879,
       20887,20897,20899,20903,20921,20929,20939,20947,20959,20963,20981,20983,
       21001,21011,21013,21017,21019,21023,21031,21059,21061,21067,21089,21101,
       21107,21121,21139,21143,21149,21157,21163,21169,21179,21187,21191,21193,
       21211,21221,21227,21247,21269,21277,21283,21313,21317,21319,21323,21341,
       21347,21377,21379,21383,21391,21397,21401,21407,21419,21433,21467,21481,
       21487,21491,21493,21499,21503,21517,21521,21523,21529,21557,21559,21563,
       21569,21577,21587,21589,21599,21601,21611,21613,21617,21647,21649,21661,
       21673,21683,21701,21713,21727,21737,21739,21751,21757,21767,21773,21787,
       21799,21803,21817,21821,21839,21841,21851,21859,21863,21871,21881,21893,
       21911,21929,21937,21943,21961,21977,21991,21997,22003,22013,22027,22031,
       22037,22039,22051,22063,22067,22073,22079,22091,22093,22109,22111,22123,
       22129,22133,22147,22153,22157,22159,22171,22189,22193,22229,22247,22259,
       22271,22273,22277,22279,22283,22291,22303,22307,22343,22349,22367,22369,
       22381,22391,22397,22409,22433,22441,22447,22453,22469,22481,22483,22501,
       22511,22531,22541,22543,22549,22567,22571,22573,22613,22619,22621,22637,
       22639,22643,22651,22669,22679,22691,22697,22699,22709,22717,22721,22727,
       22739,22741,22751,22769,22777,22783,22787,22807,22811,22817,22853,22859,
       22861,22871,22877,22901,22907,22921,22937,22943,22961,22963,22973,22993,
       23003,23011,23017,23021,23027,23029,23039,23041,23053,23057,23059,23063,
       23071,23081,23087,23099,23117,23131,23143,23159,23167,23173,23189,23197,
       23201,23203,23209,23227,23251,23269,23279,23291,23293,23297,23311,23321,
       23327,23333,23339,23357,23369,23371,23399,23417,23431,23447,23459,23473,
       23497,23509,23531,23537,23539,23549,23557,23561,23563,23567,23581,23593,
       23599,23603,23609,23623,23627,23629,23633,23663,23669,23671,23677,23687,
       23689,23719,23741,23743,23747,23753,23761,23767,23773,23789,23801,23813,
       23819,23827,23831,23833,23857,23869,23873,23879,23887,23893,23899,23909,
       23911,23917,23929,23957,23971,23977,23981,23993,24001,24007,24019,24023,
       24029,24043,24049,24061,24071,24077,24083,24091,24097,24103,24107,24109,
       24113,24121,24133,24137,24151,24169,24179,24181,24197,24203,24223,24229,
       24239,24247,24251,24281,24317,24329,24337,24359,24371,24373,24379,24391,
       24407,24413,24419,24421,24439,24443,24469,24473,24481,24499,24509,24517,
       24527,24533,24547,24551,24571,24593,24611,24623,24631,24659,24671,24677,
       24683,24691,24697,24709,24733,24749,24763,24767,24781,24793,24799,24809,
       24821,24841,24847,24851,24859,24877,24889,24907,24917,24919,24923,24943,
       24953,24967,24971,24977,24979,24989,25013,25031,25033,25037,25057,25073,
       25087,25097,25111,25117,25121,25127,25147,25153,25163,25169,25171,25183,
       25189,25219,25229,25237,25243,25247,25253,25261,25301,25303,25307,25309,
       25321,25339,25343,25349,25357,25367,25373,25391,25409,25411,25423,25439,
       25447,25453,25457,25463,25469,25471,25523,25537,25541,25561,25577,25579,
       25583,25589,25601,25603,25609,25621,25633,25639,25643,25657,25667,25673,
       25679,25693,25703,25717,25733,25741,25747,25759,25763,25771,25793,25799,
       25801,25819,25841,25847,25849,25867,25873,25889,25903,25913,25919,25931,
       25933,25939,25943,25951,25969,25981,25997,25999,26003,26017,26021,26029,
       26041,26053,26083,26099,26107,26111,26113,26119,26141,26153,26161,26171,
       26177,26183,26189,26203,26209,26227,26237,26249,26251,26261,26263,26267,
       26293,26297,26309,26317,26321,26339,26347,26357,26371,26387,26393,26399,
       26407,26417,26423,26431,26437,26449,26459,26479,26489,26497,26501,26513,
       26539,26557,26561,26573,26591,26597,26627,26633,26641,26647,26669,26681,
       26683,26687,26693,26699,26701,26711,26713,26717,26723,26729,26731,26737,
       26759,26777,26783,26801,26813,26821,26833,26839,26849,26861,26863,26879,
       26881,26891,26893,26903,26921,26927,26947,26951,26953,26959,26981,26987,
       26993,27011,27017,27031,27043,27059,27061,27067,27073,27077,27091,27103,
       27107,27109,27127,27143,27179,27191,27197,27211,27239,27241,27253,27259,
       27271,27277,27281,27283,27299,27329,27337,27361,27367,27397,27407,27409,
       27427,27431,27437,27449,27457,27479,27481,27487,27509,27527,27529,27539,
       27541,27551,27581,27583,27611,27617,27631,27647,27653,27673,27689,27691,
       27697,27701,27733,27737,27739,27743,27749,27751,27763,27767,27773,27779,
       27791,27793,27799,27803,27809,27817,27823,27827,27847,27851,27883,27893,
       27901,27917,27919,27941,27943,27947,27953,27961,27967,27983,27997,28001,
       28019,28027,28031,28051,28057,28069,28081,28087,28097,28099,28109,28111,
       28123,28151,28163,28181,28183,28201,28211,28219,28229,28277,28279,28283,
       28289,28297,28307,28309,28319,28349,28351,28387,28393,28403,28409,28411,
       28429,28433,28439,28447,28463,28477,28493,28499,28513,28517,28537,28541,
       28547,28549,28559,28571,28573,28579,28591,28597,28603,28607,28619,28621,
       28627,28631,28643,28649,28657,28661,28663,28669,28687,28697,28703,28711,
       28723,28729,28751,28753,28759,28771,28789,28793,28807,28813,28817,28837,
       28843,28859,28867,28871,28879,28901,28909,28921,28927,28933,28949,28961,
       28979,29009,29017,29021,29023,29027,29033,29059,29063,29077,29101,29123,
       29129,29131,29137,29147,29153,29167,29173,29179,29191,29201,29207,29209,
       29221,29231,29243,29251,29269,29287,29297,29303,29311,29327,29333,29339,
       29347,29363,29383,29387,29389,29399,29401,29411,29423,29429,29437,29443,
       29453,29473,29483,29501,29527,29531,29537,29567,29569,29573,29581,29587,
       29599,29611,29629,29633,29641,29663,29669,29671,29683,29717,29723,29741,
       29753,29759,29761,29789,29803,29819,29833,29837,29851,29863,29867,29873,
       29879,29881,29917,29921,29927,29947,29959,29983,29989,30011,30013,30029,
       30047,30059,30071,30089,30091,30097,30103,30109,30113,30119,30133,30137,
       30139,30161,30169,30181,30187,30197,30203,30211,30223,30241,30253,30259,
       30269,30271,30293,30307,30313,30319,30323,30341,30347,30367,30389,30391,
       30403,30427,30431,30449,30467,30469,30491,30493,30497,30509,30517,30529,
       30539,30553,30557,30559,30577,30593,30631,30637,30643,30649,30661,30671,
       30677,30689,30697,30703,30707,30713,30727,30757,30763,30773,30781,30803,
       30809,30817,30829,30839,30841,30851,30853,30859,30869,30871,30881,30893,
       30911,30931,30937,30941,30949,30971,30977,30983,31013,31019,31033,31039,
       31051,31063,31069,31079,31081,31091,31121,31123,31139,31147,31151,31153,
       31159,31177,31181,31183,31189,31193,31219,31223,31231,31237,31247,31249,
       31253,31259,31267,31271,31277,31307,31319,31321,31327,31333,31337,31357,
       31379,31387,31391,31393,31397,31469,31477,31481,31489,31511,31513,31517,
       31531,31541,31543,31547,31567,31573,31583,31601,31607,31627,31643,31649,
       31657,31663,31667,31687,31699,31721,31723,31727,31729,31741,31751,31769,
       31771,31793,31799,31817,31847,31849,31859,31873,31883,31891,31907,31957,
       31963,31973,31981,31991,32003,32009,32027,32029,32051,32057,32059,32063,
       32069,32077,32083,32089,32099,32117,32119,32141,32143,32159,32173,32183,
       32189,32191,32203,32213,32233,32237,32251,32257,32261,32297,32299,32303,
       32309,32321,32323,32327,32341,32353,32359,32363,32369,32371,32377,32381,
       32401,32411,32413,32423,32429,32441,32443,32467,32479,32491,32497,32503,
       32507,32531,32533,32537,32561,32563,32569,32573,32579,32587,32603,32609,
       32611,32621,32633,32647,32653,32687,32693,32707,32713,32717,32719,32749,
       32771,32779,32783,32789,32797,32801,32803,32831,32833,32839,32843,32869,
       32887,32909,32911,32917,32933,32939,32941,32957,32969,32971,32983,32987,
       32993,32999,33013,33023,33029,33037,33049,33053,33071,33073,33083,33091,
       33107,33113,33119,33149,33151,33161,33179,33181,33191,33199,33203,33211,
       33223,33247,33287,33289,33301,33311,33317,33329,33331,33343,33347,33349,
       33353,33359,33377,33391,33403,33409,33413,33427,33457,33461,33469,33479,
       33487,33493,33503,33521,33529,33533,33547,33563,33569,33577,33581,33587,
       33589,33599,33601,33613,33617,33619,33623,33629,33637,33641,33647,33679,
       33703,33713,33721,33739,33749,33751,33757,33767,33769,33773,33791,33797,
       33809,33811,33827,33829,33851,33857,33863,33871,33889,33893,33911,33923,
       33931,33937,33941,33961,33967,33997,34019,34031,34033,34039,34057,34061,
       34123,34127,34129,34141,34147,34157,34159,34171,34183,34211,34213,34217,
       34231,34253,34259,34261,34267,34273,34283,34297,34301,34303,34313,34319,
       34327,34337,34351,34361,34367,34369,34381,34403,34421,34429,34439,34457,
       34469,34471,34483,34487,34499,34501,34511,34513,34519,34537,34543,34549,
       34583,34589,34591,34603,34607,34613,34631,34649,34651,34667,34673,34679,
       34687,34693,34703,34721,34729,34739,34747,34757,34759,34763,34781,34807,
       34819,34841,34843,34847,34849,34871,34877,34883,34897,34913,34919,34939,
       34949,34961,34963,34981,35023,35027,35051,35053,35059,35069,35081,35083,
       35089,35099,35107,35111,35117,35129,35141,35149,35153,35159,35171,35201,
       35221,35227,35251,35257,35267,35279,35281,35291,35311,35317,35323,35327,
       35339,35353,35363,35381,35393,35401,35407,35419,35423,35437,35447,35449,
       35461,35491,35507,35509,35521,35527,35531,35533,35537,35543,35569,35573,
       35591,35593,35597,35603,35617,35671,35677,35729,35731,35747,35753,35759,
       35771,35797,35801,35803,35809,35831,35837,35839,35851,35863,35869,35879,
       35897,35899,35911,35923,35933,35951,35963,35969,35977,35983,35993,35999,
       36007,36011,36013,36017,36037,36061,36067,36073,36083,36097,36107,36109,
       36131,36137,36151,36161,36187,36191,36209,36217,36229,36241,36251,36263,
       36269,36277,36293,36299,36307,36313,36319,36341,36343,36353,36373,36383,
       36389,36433,36451,36457,36467,36469,36473,36479,36493,36497,36523,36527,
       36529,36541,36551,36559,36563,36571,36583,36587,36599,36607,36629,36637,
       36643,36653,36671,36677,36683,36691,36697,36709,36713,36721,36739,36749,
       36761,36767,36779,36781,36787,36791,36793,36809,36821,36833,36847,36857,
       36871,36877,36887,36899,36901,36913,36919,36923,36929,36931,36943,36947,
       36973,36979,36997,37003,37013,37019,37021,37039,37049,37057,37061,37087,
       37097,37117,37123,37139,37159,37171,37181,37189,37199,37201,37217,37223,
       37243,37253,37273,37277,37307,37309,37313,37321,37337,37339,37357,37361,
       37363,37369,37379,37397,37409,37423,37441,37447,37463,37483,37489,37493,
       37501,37507,37511,37517,37529,37537,37547,37549,37561,37567,37571,37573,
       37579,37589,37591,37607,37619,37633,37643,37649,37657,37663,37691,37693,
       37699,37717,37747,37781,37783,37799,37811,37813,37831,37847,37853,37861,
       37871,37879,37889,37897,37907,37951,37957,37963,37967,37987,37991,37993,
       37997,38011,38039,38047,38053,38069,38083,38113,38119,38149,38153,38167,
       38177,38183,38189,38197,38201,38219,38231,38237,38239,38261,38273,38281,
       38287,38299,38303,38317,38321,38327,38329,38333,38351,38371,38377,38393,
       38431,38447,38449,38453,38459,38461,38501,38543,38557,38561,38567,38569,
       38593,38603,38609,38611,38629,38639,38651,38653,38669,38671,38677,38693,
       38699,38707,38711,38713,38723,38729,38737,38747,38749,38767,38783,38791,
       38803,38821,38833,38839,38851,38861,38867,38873,38891,38903,38917,38921,
       38923,38933,38953,38959,38971,38977,38993,39019,39023,39041,39043,39047,
       39079,39089,39097,39103,39107,39113,39119,39133,39139,39157,39161,39163,
       39181,39191,39199,39209,39217,39227,39229,39233,39239,39241,39251,39293,
       39301,39313,39317,39323,39341,39343,39359,39367,39371,39373,39383,39397,
       39409,39419,39439,39443,39451,39461,39499,39503,39509,39511,39521,39541,
       39551,39563,39569,39581,39607,39619,39623,39631,39659,39667,39671,39679,
       39703,39709,39719,39727,39733,39749,39761,39769,39779,39791,39799,39821,
       39827,39829,39839,39841,39847,39857,39863,39869,39877,39883,39887,39901,
       39929,39937,39953,39971,39979,39983,39989,40009,40013,40031,40037,40039,
       40063,40087,40093,40099,40111,40123,40127,40129,40151,40153,40163,40169,
       40177,40189,40193,40213,40231,40237,40241,40253,40277,40283,40289,40343,
       40351,40357,40361,40387,40423,40427,40429,40433,40459,40471,40483,40487,
       40493,40499,40507,40519,40529,40531,40543,40559,40577,40583,40591,40597,
       40609,40627,40637,40639,40693,40697,40699,40709,40739,40751,40759,40763,
       40771,40787,40801,40813,40819,40823,40829,40841,40847,40849,40853,40867,
       40879,40883,40897,40903,40927,40933,40939,40949,40961,40973,40993,41011,
       41017,41023,41039,41047,41051,41057,41077,41081,41113,41117,41131,41141,
       41143,41149,41161,41177,41179,41183,41189,41201,41203,41213,41221,41227,
       41231,41233,41243,41257,41263,41269,41281,41299,41333,41341,41351,41357,
       41381,41387,41389,41399,41411,41413,41443,41453,41467,41479,41491,41507,
       41513,41519,41521,41539,41543,41549,41579,41593,41597,41603,41609,41611,
       41617,41621,41627,41641,41647,41651,41659,41669,41681,41687,41719,41729,
       41737,41759,41761,41771,41777,41801,41809,41813,41843,41849,41851,41863,
       41879,41887,41893,41897,41903,41911,41927,41941,41947,41953,41957,41959,
       41969,41981,41983,41999,42013,42017,42019,42023,42043,42061,42071,42073,
       42083,42089,42101,42131,42139,42157,42169,42179,42181,42187,42193,42197,
       42209,42221,42223,42227,42239,42257,42281,42283,42293,42299,42307,42323,
       42331,42337,42349,42359,42373,42379,42391,42397,42403,42407,42409,42433,
       42437,42443,42451,42457,42461,42463,42467,42473,42487,42491,42499,42509,
       42533,42557,42569,42571,42577,42589,42611,42641,42643,42649,42667,42677,
       42683,42689,42697,42701,42703,42709,42719,42727,42737,42743,42751,42767,
       42773,42787,42793,42797,42821,42829,42839,42841,42853,42859,42863,42899,
       42901,42923,42929,42937,42943,42953,42961,42967,42979,42989,43003,43013,
       43019,43037,43049,43051,43063,43067,43093,43103,43117,43133,43151,43159,
       43177,43189,43201,43207,43223,43237,43261,43271,43283,43291,43313,43319,
       43321,43331,43391,43397,43399,43403,43411,43427,43441,43451,43457,43481,
       43487,43499,43517,43541,43543,43573,43577,43579,43591,43597,43607,43609,
       43613,43627,43633,43649,43651,43661,43669,43691,43711,43717,43721,43753,
       43759,43777,43781,43783,43787,43789,43793,43801,43853,43867,43889,43891,
       43913,43933,43943,43951,43961,43963,43969,43973,43987,43991,43997,44017,
       44021,44027,44029,44041,44053,44059,44071,44087,44089,44101,44111,44119,
       44123,44129,44131,44159,44171,44179,44189,44201,44203,44207,44221,44249,
       44257,44263,44267,44269,44273,44279,44281,44293,44351,44357,44371,44381,
       44383,44389,44417,44449,44453,44483,44491,44497,44501,44507,44519,44531,
       44533,44537,44543,44549,44563,44579,44587,44617,44621,44623,44633,44641,
       44647,44651,44657,44683,44687,44699,44701,44711,44729,44741,44753,44771,
       44773,44777,44789,44797,44809,44819,44839,44843,44851,44867,44879,44887,
       44893,44909,44917,44927,44939,44953,44959,44963,44971,44983,44987,45007,
       45013,45053,45061,45077,45083,45119,45121,45127,45131,45137,45139,45161,
       45179,45181,45191,45197,45233,45247,45259,45263,45281,45289,45293,45307,
       45317,45319,45329,45337,45341,45343,45361,45377,45389,45403,45413,45427,
       45433,45439,45481,45491,45497,45503,45523,45533,45541,45553,45557,45569,
       45587,45589,45599,45613,45631,45641,45659,45667,45673,45677,45691,45697,
       45707,45737,45751,45757,45763,45767,45779,45817,45821,45823,45827,45833,
       45841,45853,45863,45869,45887,45893,45943,45949,45953,45959,45971,45979,
       45989,46021,46027,46049,46051,46061,46073,46091,46093,46099,46103,46133,
       46141,46147,46153,46171,46181,46183,46187,46199,46219,46229,46237,46261,
       46271,46273,46279,46301,46307,46309,46327,46337,46349,46351,46381,46399,
       46411,46439,46441,46447,46451,46457,46471,46477,46489,46499,46507,46511,
       46523,46549,46559,46567,46573,46589,46591,46601,46619,46633,46639,46643,
       46649,46663,46679,46681,46687,46691,46703,46723,46727,46747,46751,46757,
       46769,46771,46807,46811,46817,46819,46829,46831,46853,46861,46867,46877,
       46889,46901,46919,46933,46957,46993,46997,47017,47041,47051,47057,47059,
       47087,47093,47111,47119,47123,47129,47137,47143,47147,47149,47161,47189,
       47207,47221,47237,47251,47269,47279,47287,47293,47297,47303,47309,47317,
       47339,47351,47353,47363,47381,47387,47389,47407,47417,47419,47431,47441,
       47459,47491,47497,47501,47507,47513,47521,47527,47533,47543,47563,47569,
       47581,47591,47599,47609,47623,47629,47639,47653,47657,47659,47681,47699,
       47701,47711,47713,47717,47737,47741,47743,47777,47779,47791,47797,47807,
       47809,47819,47837,47843,47857,47869,47881,47903,47911,47917,47933,47939,
       47947,47951,47963,47969,47977,47981,48017,48023,48029,48049,48073,48079,
       48091,48109,48119,48121,48131,48157,48163,48179,48187,48193,48197,48221,
       48239,48247,48259,48271,48281,48299,48311,48313,48337,48341,48353,48371,
       48383,48397,48407,48409,48413,48437,48449,48463,48473,48479,48481,48487,
       48491,48497,48523,48527,48533,48539,48541,48563,48571,48589,48593,48611,
       48619,48623,48647,48649,48661,48673,48677,48679,48731,48733,48751,48757,
       48761,48767,48779,48781,48787,48799,48809,48817,48821,48823,48847,48857,
       48859,48869,48871,48883,48889,48907,48947,48953,48973,48989,48991,49003,
       49009,49019,49031,49033,49037,49043,49057,49069,49081,49103,49109,49117,
       49121,49123,49139,49157,49169,49171,49177,49193,49199,49201,49207,49211,
       49223,49253,49261,49277,49279,49297,49307,49331,49333,49339,49363,49367,
       49369,49391,49393,49409,49411,49417,49429,49433,49451,49459,49463,49477,
       49481,49499,49523,49529,49531,49537,49547,49549,49559,49597,49603,49613,
       49627,49633,49639,49663,49667,49669,49681,49697,49711,49727,49739,49741,
       49747,49757,49783,49787,49789,49801,49807,49811,49823,49831,49843,49853,
       49871,49877,49891,49919,49921,49927,49937,49939,49943,49957,49991,49993,
       49999,50021,50023,50033,50047,50051,50053,50069,50077,50087,50093,50101,
       50111,50119,50123,50129,50131,50147,50153,50159,50177,50207,50221,50227,
       50231,50261,50263,50273,50287,50291,50311,50321,50329,50333,50341,50359,
       50363,50377,50383,50387,50411,50417,50423,50441,50459,50461,50497,50503,
       50513,50527,50539,50543,50549,50551,50581,50587,50591,50593,50599,50627,
       50647,50651,50671,50683,50707,50723,50741,50753,50767,50773,50777,50789,
       50821,50833,50839,50849,50857,50867,50873,50891,50893,50909,50923,50929,
       50951,50957,50969,50971,50989,50993,51001,51031,51043,51047,51059,51061,
       51071,51109,51131,51133,51137,51151,51157,51169,51193,51197,51199,51203,
       51217,51229,51239,51241,51257,51263,51283,51287,51307,51329,51341,51343,
       51347,51349,51361,51383,51407,51413,51419,51421,51427,51431,51437,51439,
       51449,51461,51473,51479,51481,51487,51503,51511,51517,51521,51539,51551,
       51563,51577,51581,51593,51599,51607,51613,51631,51637,51647,51659,51673,
       51679,51683,51691,51713,51719,51721,51749,51767,51769,51787,51797,51803,
       51817,51827,51829,51839,51853,51859,51869,51871,51893,51899,51907,51913,
       51929,51941,51949,51971,51973,51977,51991,52009,52021,52027,52051,52057,
       52067,52069,52081,52103,52121,52127,52147,52153,52163,52177,52181,52183,
       52189,52201,52223,52237,52249,52253,52259,52267,52289,52291,52301,52313,
       52321,52361,52363,52369,52379,52387,52391,52433,52453,52457,52489,52501,
       52511,52517,52529,52541,52543,52553,52561,52567,52571,52579,52583,52609,
       52627,52631,52639,52667,52673,52691,52697,52709,52711,52721,52727,52733,
       52747,52757,52769,52783,52807,52813,52817,52837,52859,52861,52879,52883,
       52889,52901,52903,52919,52937,52951,52957,52963,52967,52973,52981,52999,
       53003,53017,53047,53051,53069,53077,53087,53089,53093,53101,53113,53117,
       53129,53147,53149,53161,53171,53173,53189,53197,53201,53231,53233,53239,
       53267,53269,53279,53281,53299,53309,53323,53327,53353,53359,53377,53381,
       53401,53407,53411,53419,53437,53441,53453,53479,53503,53507,53527,53549,
       53551,53569,53591,53593,53597,53609,53611,53617,53623,53629,53633,53639,
       53653,53657,53681,53693,53699,53717,53719,53731,53759,53773,53777,53783,
       53791,53813,53819,53831,53849,53857,53861,53881,53887,53891,53897,53899,
       53917,53923,53927,53939,53951,53959,53987,53993,54001,54011,54013,54037,
       54049,54059,54083,54091,54101,54121,54133,54139,54151,54163,54167,54181,
       54193,54217,54251,54269,54277,54287,54293,54311,54319,54323,54331,54347,
       54361,54367,54371,54377,54401,54403,54409,54413,54419,54421,54437,54443,
       54449,54469,54493,54497,54499,54503,54517,54521,54539,54541,54547,54559,
       54563,54577,54581,54583,54601,54617,54623,54629,54631,54647,54667,54673,
       54679,54709,54713,54721,54727,54751,54767,54773,54779,54787,54799,54829,
       54833,54851,54869,54877,54881,54907,54917,54919,54941,54949,54959,54973,
       54979,54983,55001,55009,55021,55049,55051,55057,55061,55073,55079,55103,
       55109,55117,55127,55147,55163,55171,55201,55207,55213,55217,55219,55229,
       55243,55249,55259,55291,55313,55331,55333,55337,55339,55343,55351,55373,
       55381,55399,55411,55439,55441,55457,55469,55487,55501,55511,55529,55541,
       55547,55579,55589,55603,55609,55619,55621,55631,55633,55639,55661,55663,
       55667,55673,55681,55691,55697,55711,55717,55721,55733,55763,55787,55793,
       55799,55807,55813,55817,55819,55823,55829,55837,55843,55849,55871,55889,
       55897,55901,55903,55921,55927,55931,55933,55949,55967,55987,55997,56003,
       56009,56039,56041,56053,56081,56087,56093,56099,56101,56113,56123,56131,
       56149,56167,56171,56179,56197,56207,56209,56237,56239,56249,56263,56267,
       56269,56299,56311,56333,56359,56369,56377,56383,56393,56401,56417,56431,
       56437,56443,56453,56467,56473,56477,56479,56489,56501,56503,56509,56519,
       56527,56531,56533,56543,56569,56591,56597,56599,56611,56629,56633,56659,
       56663,56671,56681,56687,56701,56711,56713,56731,56737,56747,56767,56773,
       56779,56783,56807,56809,56813,56821,56827,56843,56857,56873,56891,56893,
       56897,56909,56911,56921,56923,56929,56941,56951,56957,56963,56983,56989,
       56993,56999,57037,57041,57047,57059,57073,57077,57089,57097,57107,57119,
       57131,57139,57143,57149,57163,57173,57179,57191,57193,57203,57221,57223,
       57241,57251,57259,57269,57271,57283,57287,57301,57329,57331,57347,57349,
       57367,57373,57383,57389,57397,57413,57427,57457,57467,57487,57493,57503,
       57527,57529,57557,57559,57571,57587,57593,57601,57637,57641,57649,57653,
       57667,57679,57689,57697,57709,57713,57719,57727,57731,57737,57751,57773,
       57781,57787,57791,57793,57803,57809,57829,57839,57847,57853,57859,57881,
       57899,57901,57917,57923,57943,57947,57973,57977,57991,58013,58027,58031,
       58043,58049,58057,58061,58067,58073,58099,58109,58111,58129,58147,58151,
       58153,58169,58171,58189,58193,58199,58207,58211,58217,58229,58231,58237,
       58243,58271,58309,58313,58321,58337,58363,58367,58369,58379,58391,58393,
       58403,58411,58417,58427,58439,58441,58451,58453,58477,58481,58511,58537,
       58543,58549,58567,58573,58579,58601,58603,58613,58631,58657,58661,58679,
       58687,58693,58699,58711,58727,58733,58741,58757,58763,58771,58787,58789,
       58831,58889,58897,58901,58907,58909,58913,58921,58937,58943,58963,58967,
       58979,58991,58997,59009,59011,59021,59023,59029,59051,59053,59063,59069,
       59077,59083,59093,59107,59113,59119,59123,59141,59149,59159,59167,59183,
       59197,59207,59209,59219,59221,59233,59239,59243,59263,59273,59281,59333,
       59341,59351,59357,59359,59369,59377,59387,59393,59399,59407,59417,59419,
       59441,59443,59447,59453,59467,59471,59473,59497,59509,59513,59539,59557,
       59561,59567,59581,59611,59617,59621,59627,59629,59651,59659,59663,59669,
       59671,59693,59699,59707,59723,59729,59743,59747,59753,59771,59779,59791,
       59797,59809,59833,59863,59879,59887,59921,59929,59951,59957,59971,59981,
       59999,60013,60017,60029,60037,60041,60077,60083,60089,60091,60101,60103,
       60107,60127,60133,60139,60149,60161,60167,60169,60209,60217,60223,60251,
       60257,60259,60271,60289,60293,60317,60331,60337,60343,60353,60373,60383,
       60397,60413,60427,60443,60449,60457,60493,60497,60509,60521,60527,60539,
       60589,60601,60607,60611,60617,60623,60631,60637,60647,60649,60659,60661,
       60679,60689,60703,60719,60727,60733,60737,60757,60761,60763,60773,60779,
       60793,60811,60821,60859,60869,60887,60889,60899,60901,60913,60917,60919,
       60923,60937,60943,60953,60961,61001,61007,61027,61031,61043,61051,61057,
       61091,61099,61121,61129,61141,61151,61153,61169,61211,61223,61231,61253,
       61261,61283,61291,61297,61331,61333,61339,61343,61357,61363,61379,61381,
       61403,61409,61417,61441,61463,61469,61471,61483,61487,61493,61507,61511,
       61519,61543,61547,61553,61559,61561,61583,61603,61609,61613,61627,61631,
       61637,61643,61651,61657,61667,61673,61681,61687,61703,61717,61723,61729,
       61751,61757,61781,61813,61819,61837,61843,61861,61871,61879,61909,61927,
       61933,61949,61961,61967,61979,61981,61987,61991,62003,62011,62017,62039,
       62047,62053,62057,62071,62081,62099,62119,62129,62131,62137,62141,62143,
       62171,62189,62191,62201,62207,62213,62219,62233,62273,62297,62299,62303,
       62311,62323,62327,62347,62351,62383,62401,62417,62423,62459,62467,62473,
       62477,62483,62497,62501,62507,62533,62539,62549,62563,62581,62591,62597,
       62603,62617,62627,62633,62639,62653,62659,62683,62687,62701,62723,62731,
       62743,62753,62761,62773,62791,62801,62819,62827,62851,62861,62869,62873,
       62897,62903,62921,62927,62929,62939,62969,62971,62981,62983,62987,62989,
       63029,63031,63059,63067,63073,63079,63097,63103,63113,63127,63131,63149,
       63179,63197,63199,63211,63241,63247,63277,63281,63299,63311,63313,63317,
       63331,63337,63347,63353,63361,63367,63377,63389,63391,63397,63409,63419,
       63421,63439,63443,63463,63467,63473,63487,63493,63499,63521,63527,63533,
       63541,63559,63577,63587,63589,63599,63601,63607,63611,63617,63629,63647,
       63649,63659,63667,63671,63689,63691,63697,63703,63709,63719,63727,63737,
       63743,63761,63773,63781,63793,63799,63803,63809,63823,63839,63841,63853,
       63857,63863,63901,63907,63913,63929,63949,63977,63997,64007,64013,64019,
       64033,64037,64063,64067,64081,64091,64109,64123,64151,64153,64157,64171,
       64187,64189,64217,64223,64231,64237,64271,64279,64283,64301,64303,64319,
       64327,64333,64373,64381,64399,64403,64433,64439,64451,64453,64483,64489,
       64499,64513,64553,64567,64577,64579,64591,64601,64609,64613,64621,64627,
       64633,64661,64663,64667,64679,64693,64709,64717,64747,64763,64781,64783,
       64793,64811,64817,64849,64853,64871,64877,64879,64891,64901,64919,64921,
       64927,64937,64951,64969,64997,65003,65011,65027,65029,65033,65053,65063,
       65071,65089,65099,65101,65111,65119,65123,65129,65141,65147,65167,65171,
       65173,65179,65183,65203,65213,65239,65257,65267,65269,65287,65293,65309,
       65323,65327,65353,65357,65371,65381,65393,65407,65413,65419,65423,65437,
       65447,65449,65479,65497,65519,65521);

  type
    TOmfLibHash = record
      block_x: Integer;
      block_d: Integer;
      bucket_x: Integer;
      bucket_d: Integer;
    end;

  function compute_omf_lib_hash(const name: string; blocks: Integer): TOmfLibHash;

  { OMF segment class names for the object sections, produced by the FPC code generator }
  function omf_segclass(atype:TAsmSectiontype):string;
  function omf_sectiontype2align(atype:TAsmSectiontype):longint;
  { returns whether the specified section type belongs to the group DGROUP in
    the current memory model. DGROUP is the segment group pointed by DS }
  function section_belongs_to_dgroup(atype:TAsmSectiontype): Boolean;

implementation

  uses
    cutils,globtype,globals,
    cpuinfo,
    verbose;

  { TOmfOrderedNameCollection }

  function TOmfOrderedNameCollection.GetString(Index: Integer): string;
    begin
      Result:=FStringList[Index-1];
    end;

  function TOmfOrderedNameCollection.GetCount: Integer;
    begin
      Result:=Length(FStringList);
    end;

  procedure TOmfOrderedNameCollection.SetString(Index: Integer; AValue: string);
    begin
      FStringList[Index-1]:=AValue;
    end;

  constructor TOmfOrderedNameCollection.Create(AAllowDuplicates: Boolean);
    begin
      FAllowDuplicates:=AAllowDuplicates;
    end;

  function TOmfOrderedNameCollection.Add(const S: string): Integer;
    var
      I: Integer;
    begin
      if not AllowDuplicates then
        begin
          for I:=Low(FStringList) to High(FStringList) do
            if FStringList[I]=S then
              exit(I+1);
        end;
      Result:=Length(FStringList)+1;
      SetLength(FStringList,Result);
      FStringList[Result-1]:=S;
    end;

  procedure TOmfOrderedNameCollection.Clear;
    begin
      SetLength(FStringList,0);
    end;

  { TOmfRawRecord }

  function TOmfRawRecord.GetRecordType: Byte;
    begin
      Result:=RawData[-3];
    end;

  procedure TOmfRawRecord.SetRecordType(AValue: Byte);
    begin
      RawData[-3]:=AValue;
    end;

  function TOmfRawRecord.GetRecordLength: Word;
    begin
      Result:=RawData[-2] or (RawData[-1] shl 8);
    end;

  procedure TOmfRawRecord.SetRecordLength(AValue: Word);
    begin
      RawData[-2]:=Byte(AValue);
      RawData[-1]:=Byte(AValue shr 8);
    end;

  function TOmfRawRecord.ReadStringAt(Offset: Integer; out s: string): Integer;
    var
      len: Byte;
    begin
      len:=RawData[Offset];
      Result:=Offset+len+1;
      if result>RecordLength then
        internalerror(2015033103);
      SetLength(s, len);
      UniqueString(s);
      Move(RawData[Offset+1],s[1],len);
    end;

  function TOmfRawRecord.WriteStringAt(Offset: Integer; s: string): Integer;
    begin
      if Length(s)>255 then
        internalerror(2015033101);
      result:=Offset+Length(s)+1;
      if result>High(RawData) then
        internalerror(2015033102);
      RawData[Offset]:=Length(s);
      Move(s[1], RawData[Offset+1], Length(s));
    end;

  function TOmfRawRecord.ReadIndexedRef(Offset: Integer; out IndexedRef: Integer): Integer;
    begin
      Result:=Offset+1;
      if result>RecordLength then
        internalerror(2015033103);
      IndexedRef:=RawData[Offset];
      if IndexedRef<=$7f then
        exit;
      Result:=Offset+2;
      if result>RecordLength then
        internalerror(2015033103);
      IndexedRef:=((IndexedRef and $7f) shl 8)+RawData[Offset+1];
    end;

  function TOmfRawRecord.WriteIndexedRef(Offset: Integer; IndexedRef: Integer): Integer;
    begin
      if (IndexedRef<0) or (IndexedRef>$7FFF) then
        internalerror(2015040303);
      if IndexedRef<=$7f then
        begin
          Result:=Offset+1;
          if Result>High(RawData) then
            internalerror(2015033102);
          RawData[Offset]:=IndexedRef;
        end
      else
        begin
          Result:=Offset+2;
          if Result>High(RawData) then
            internalerror(2015033102);
          RawData[Offset]:=$80+(IndexedRef shr 8);
          RawData[Offset+1]:=Byte(IndexedRef);
        end;
    end;

  function TOmfRawRecord.GetChecksumByte: Byte;
    begin
      if RecordLength>0 then
        Result:=RawData[RecordLength-1]
      else
        Result:=0;
    end;

  procedure TOmfRawRecord.SetChecksumByte(AValue: Byte);
    begin
      if RecordLength>0 then
        RawData[RecordLength-1]:=AValue;
    end;

  procedure TOmfRawRecord.CalculateChecksumByte;
    var
      I: Integer;
      b: Byte;
    begin
      b:=0;
      for I:=-3 to RecordLength-2 do
        b:=byte(b+RawData[I]);
      SetChecksumByte($100-b);
    end;

  function TOmfRawRecord.VerifyChecksumByte: boolean;
    var
      I: Integer;
      b: Byte;
    begin
      { according to the OMF spec, some tools always write a 0 rather than
        computing the checksum, so it should also be accepted as correct }
      if ChecksumByte=0 then
        exit(true);
      b:=0;
      for I:=-3 to RecordLength-1 do
        b:=byte(b+RawData[I]);
      Result:=(b=0);
    end;

  procedure TOmfRawRecord.ReadFrom(aReader: TObjectReader);
    begin
      aReader.read(RawData, 3);
      aReader.read(RawData[0], RecordLength);
    end;

  procedure TOmfRawRecord.ReadFrom(aReader: TDynamicArray);
    begin
      aReader.read(RawData, 3);
      aReader.read(RawData[0], RecordLength);
    end;

  procedure TOmfRawRecord.WriteTo(aWriter: TObjectWriter);
    begin
      aWriter.write(RawData, RecordLength+3);
    end;

  procedure TOmfRawRecord.WriteTo(aWriter: TDynamicArray);
    begin
      aWriter.write(RawData, RecordLength+3);
    end;

  { TOmfRecord_THEADR }

  procedure TOmfRecord_THEADR.DecodeFrom(RawRecord: TOmfRawRecord);
    begin
      if RawRecord.RecordType<>RT_THEADR then
        internalerror(2015040301);
      RawRecord.ReadStringAt(0,FModuleName);
    end;

  procedure TOmfRecord_THEADR.EncodeTo(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
    begin
      RawRecord.RecordType:=RT_THEADR;
      NextOfs:=RawRecord.WriteStringAt(0,ModuleName);
      RawRecord.RecordLength:=NextOfs+1;
      RawRecord.CalculateChecksumByte;
    end;

  { TOmfRecord_COMENT }

  function TOmfRecord_COMENT.GetNoList: Boolean;
    begin
      Result:=(CommentType and $40)<>0;
    end;

  function TOmfRecord_COMENT.GetNoPurge: Boolean;
    begin
      Result:=(CommentType and $80)<>0;
    end;

  procedure TOmfRecord_COMENT.SetNoList(AValue: Boolean);
    begin
      if AValue then
        CommentType:=CommentType or $40
      else
        CommentType:=CommentType and $BF;
    end;

  procedure TOmfRecord_COMENT.SetNoPurge(AValue: Boolean);
    begin
      if AValue then
        CommentType:=CommentType or $80
      else
        CommentType:=CommentType and $7F;
    end;

  procedure TOmfRecord_COMENT.DecodeFrom(RawRecord: TOmfRawRecord);
    begin
      if RawRecord.RecordType<>RT_COMENT then
        internalerror(2015040301);
      if RawRecord.RecordLength<3 then
        internalerror(2015033104);
      CommentType:=RawRecord.RawData[0];
      CommentClass:=RawRecord.RawData[1];
      SetLength(FCommentString,RawRecord.RecordLength-3);
      UniqueString(FCommentString);
      Move(RawRecord.RawData[2],FCommentString[1],Length(FCommentString));
    end;

  procedure TOmfRecord_COMENT.EncodeTo(RawRecord: TOmfRawRecord);
    begin
      RawRecord.RecordType:=RT_COMENT;
      if (Length(FCommentString)+3)>High(RawRecord.RawData) then
        internalerror(2015033105);
      RawRecord.RecordLength:=Length(FCommentString)+3;
      RawRecord.RawData[0]:=CommentType;
      RawRecord.RawData[1]:=CommentClass;
      Move(FCommentString[1],RawRecord.RawData[2],Length(FCommentString));
      RawRecord.CalculateChecksumByte;
    end;

  { TOmfRecord_LNAMES }

  constructor TOmfRecord_LNAMES.Create;
    begin
      FNextIndex:=1;
    end;

  procedure TOmfRecord_LNAMES.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
      Name: string;
    begin
      if RawRecord.RecordType<>RT_LNAMES then
        internalerror(2015040301);
      NextOfs:=0;
      while NextOfs<(RawRecord.RecordLength-1) do
        begin
          NextOfs:=RawRecord.ReadStringAt(NextOfs,Name);
          Names.Add(Name);
        end;
    end;

  procedure TOmfRecord_LNAMES.EncodeTo(RawRecord: TOmfRawRecord);
    const
      RecordLengthLimit = 1024;
    var
      Len,LastIncludedIndex,NextOfs,I: Integer;
    begin
      RawRecord.RecordType:=RT_LNAMES;

      { find out how many strings can we include until we reach the length limit }
      Len:=1;
      LastIncludedIndex:=NextIndex-1;
      repeat
        Inc(LastIncludedIndex);
        Inc(Len,Length(Names[LastIncludedIndex])+1);
      until (LastIncludedIndex>=Names.Count) or ((Len+Length(Names[LastIncludedIndex+1])+1)>=RecordLengthLimit);

      { write the strings... }
      NextOfs:=0;
      for I:=NextIndex to LastIncludedIndex do
        NextOfs:=RawRecord.WriteStringAt(NextOfs,Names[I]);
      RawRecord.RecordLength:=Len;
      RawRecord.CalculateChecksumByte;

      { update NextIndex }
      NextIndex:=LastIncludedIndex+1;
    end;

  { TOmfRecord_SEGDEF }

  procedure TOmfRecord_SEGDEF.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      B: Byte;
      Big: Boolean;
      NextOfs: Integer;
      MinLen: Integer;
    begin
      if not (RawRecord.RecordType in [RT_SEGDEF,RT_SEGDEF32]) then
        internalerror(2015040301);
      Is32Bit:=RawRecord.RecordType=RT_SEGDEF32;

      MinLen:=7; { b(1)+seglength(2..4)+segnameindex(1..2)+classnameindex(1..2)+overlaynameindex(1..2)+checksum }
      if Is32Bit then
        inc(MinLen,2);
      if RawRecord.RecordLength<MinLen then
        internalerror(2015040305);
      B:=RawRecord.RawData[0];
      Alignment:=TOmfSegmentAlignment(B shr 5);
      Combination:=TOmfSegmentCombination((B shr 2) and 7);
      Big:=(B and 2)<>0;
      Use:=TOmfSegmentUse(B and 1);
      NextOfs:=1;
      if Alignment=saAbsolute then
        begin
          inc(MinLen,3);
          if RawRecord.RecordLength<MinLen then
            internalerror(2015040305);
          FrameNumber:=RawRecord.RawData[1]+(RawRecord.RawData[2] shl 8);
          Offset:=RawRecord.RawData[3];
          NextOfs:=4;
        end
      else
        begin
          FrameNumber:=0;
          Offset:=0;
        end;
      if Is32Bit then
        begin
          SegmentLength:=RawRecord.RawData[NextOfs]+
            (RawRecord.RawData[NextOfs+1] shl 8)+
            (RawRecord.RawData[NextOfs+2] shl 16)+
            (RawRecord.RawData[NextOfs+3] shl 24);
          if Big then
            if SegmentLength=0 then
              SegmentLength:=4294967296
            else
              internalerror(2015040306);
          Inc(NextOfs,4);
        end
      else
        begin
          SegmentLength:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8);
          if Big then
            if SegmentLength=0 then
              SegmentLength:=65536
            else
              internalerror(2015040306);
          Inc(NextOfs,2);
        end;
      NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FSegmentNameIndex);
      NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FClassNameIndex);
      NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FOverlayNameIndex);
    end;

  procedure TOmfRecord_SEGDEF.EncodeTo(RawRecord: TOmfRawRecord);
    var
      Big: Boolean;
      NextOfs: Integer;
    begin
      MaybeGo32;
      if Is32Bit then
        begin
          RawRecord.RecordType:=RT_SEGDEF32;
          if SegmentLength>4294967296 then
            internalerror(2015040307);
          Big:=SegmentLength=4294967296;
        end
      else
        begin
          RawRecord.RecordType:=RT_SEGDEF;
          if SegmentLength>65536 then
            internalerror(2015040302);
          Big:=SegmentLength=65536;
        end;
      RawRecord.RawData[0]:=(Ord(Alignment) shl 5) or (Ord(Combination) shl 2) or (Ord(Big) shl 1) or Ord(Use);
      NextOfs:=1;
      if Alignment=saAbsolute then
        begin
          RawRecord.RawData[1]:=Byte(FrameNumber);
          RawRecord.RawData[2]:=Byte(FrameNumber shr 8);
          RawRecord.RawData[3]:=Offset;
          NextOfs:=4;
        end;
      if Is32Bit then
        begin
          RawRecord.RawData[NextOfs]:=Byte(SegmentLength);
          RawRecord.RawData[NextOfs+1]:=Byte(SegmentLength shr 8);
          RawRecord.RawData[NextOfs+2]:=Byte(SegmentLength shr 16);
          RawRecord.RawData[NextOfs+3]:=Byte(SegmentLength shr 24);
          Inc(NextOfs,4);
        end
      else
        begin
          RawRecord.RawData[NextOfs]:=Byte(SegmentLength);
          RawRecord.RawData[NextOfs+1]:=Byte(SegmentLength shr 8);
          Inc(NextOfs,2);
        end;
      NextOfs:=RawRecord.WriteIndexedRef(NextOfs,SegmentNameIndex);
      NextOfs:=RawRecord.WriteIndexedRef(NextOfs,ClassNameIndex);
      NextOfs:=RawRecord.WriteIndexedRef(NextOfs,OverlayNameIndex);
      RawRecord.RecordLength:=NextOfs+1;
      RawRecord.CalculateChecksumByte;
    end;

  procedure TOmfRecord_SEGDEF.MaybeGo32;
    begin
      if SegmentLength>65536 then
        Is32Bit:=true;
    end;

  { TOmfRecord_GRPDEF }

  procedure TOmfRecord_GRPDEF.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
      Segment: Integer;
    begin
      if RawRecord.RecordType<>RT_GRPDEF then
        internalerror(2015040301);
      NextOfs:=RawRecord.ReadIndexedRef(0,FGroupNameIndex);
      SetLength(FSegmentList,0);
      while NextOfs<RawRecord.RecordLength-1 do
        begin
          if RawRecord.RawData[NextOfs]<>$ff then
            internalerror(2015040901);
          NextOfs:=RawRecord.ReadIndexedRef(NextOfs+1,Segment);
          SetLength(FSegmentList,Length(FSegmentList)+1);
          FSegmentList[High(FSegmentList)]:=Segment;
        end;
    end;

  procedure TOmfRecord_GRPDEF.EncodeTo(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
      Segment: Integer;
    begin
      RawRecord.RecordType:=RT_GRPDEF;
      NextOfs:=RawRecord.WriteIndexedRef(0,GroupNameIndex);
      for Segment in SegmentList do
        begin
          if NextOfs>High(RawRecord.RawData) then
            internalerror(2015040401);
          RawRecord.RawData[NextOfs]:=$ff;
          NextOfs:=RawRecord.WriteIndexedRef(NextOfs+1,Segment);
        end;
      RawRecord.RecordLength:=NextOfs+1;
      RawRecord.CalculateChecksumByte;
    end;

  { TOmfPublicNameElement }

    function TOmfPublicNameElement.GetLengthInFile(Is32Bit: Boolean): Integer;
    begin
      Result:=1+Length(Name)+2+1;
      if Is32Bit then
        Inc(Result,2);
      if TypeIndex>=$80 then
        Inc(Result);
    end;

  { TOmfRecord_PUBDEF }

  procedure TOmfRecord_PUBDEF.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
      Name: string;
      TypeIndex: Integer;
      PublicOffset: DWord;
      PubName: TOmfPublicNameElement;
    begin
      if not (RawRecord.RecordType in [RT_PUBDEF,RT_PUBDEF32]) then
        internalerror(2015040301);
      Is32Bit:=RawRecord.RecordType=RT_PUBDEF32;

      NextOfs:=RawRecord.ReadIndexedRef(0,FBaseGroupIndex);
      NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FBaseSegmentIndex);
      if BaseSegmentIndex=0 then
        begin
          if (NextOfs+1)>=RawRecord.RecordLength then
            internalerror(2015041401);
          BaseFrame:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8);
          Inc(NextOfs,2);
        end
      else
        BaseFrame:=0;

      while NextOfs<(RawRecord.RecordLength-1) do
        begin
          NextOfs:=RawRecord.ReadStringAt(NextOfs,Name);
          if Is32Bit then
            begin
              if (NextOfs+3)>=RawRecord.RecordLength then
                internalerror(2015041401);
              PublicOffset:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8)+
                (RawRecord.RawData[NextOfs+2] shl 16)+(RawRecord.RawData[NextOfs+3] shl 24);
              Inc(NextOfs,4);
            end
          else
            begin
              if (NextOfs+1)>=RawRecord.RecordLength then
                internalerror(2015041401);
              PublicOffset:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8);
              Inc(NextOfs,2);
            end;
          NextOfs:=RawRecord.ReadIndexedRef(NextOfs,TypeIndex);
          PubName:=TOmfPublicNameElement.Create(PublicNames,Name);
          PubName.PublicOffset:=PublicOffset;
          PubName.TypeIndex:=TypeIndex;
        end;
    end;

  procedure TOmfRecord_PUBDEF.EncodeTo(RawRecord: TOmfRawRecord);
    const
      RecordLengthLimit = 1024;
    var
      Len,LastIncludedIndex,NextOfs,I: Integer;
      PubName: TOmfPublicNameElement;
    begin
      MaybeGo32;
      if Is32Bit then
        RawRecord.RecordType:=RT_PUBDEF32
      else
        RawRecord.RecordType:=RT_PUBDEF;

      NextOfs:=RawRecord.WriteIndexedRef(0,BaseGroupIndex);
      NextOfs:=RawRecord.WriteIndexedRef(NextOfs,BaseSegmentIndex);
      if BaseSegmentIndex=0 then
        begin
          RawRecord.RawData[NextOfs]:=Byte(BaseFrame);
          RawRecord.RawData[NextOfs+1]:=Byte(BaseFrame shr 8);
          Inc(NextOfs,2);
        end;

      { find out how many public names can we include until we reach the length limit }
      Len:=NextOfs;
      LastIncludedIndex:=NextIndex-1;
      repeat
        Inc(LastIncludedIndex);
        Inc(Len,TOmfPublicNameElement(PublicNames[LastIncludedIndex]).GetLengthInFile(Is32Bit));
      until (LastIncludedIndex>=(PublicNames.Count-1)) or ((Len+TOmfPublicNameElement(PublicNames[LastIncludedIndex+1]).GetLengthInFile(Is32Bit))>=RecordLengthLimit);

      { write the public names... }
      for I:=NextIndex to LastIncludedIndex do
        begin
          PubName:=TOmfPublicNameElement(PublicNames[I]);
          NextOfs:=RawRecord.WriteStringAt(NextOfs,PubName.Name);
          if Is32Bit then
            begin
              RawRecord.RawData[NextOfs]:=Byte(PubName.PublicOffset);
              RawRecord.RawData[NextOfs+1]:=Byte(PubName.PublicOffset shr 8);
              RawRecord.RawData[NextOfs+2]:=Byte(PubName.PublicOffset shr 16);
              RawRecord.RawData[NextOfs+3]:=Byte(PubName.PublicOffset shr 24);
              Inc(NextOfs,4);
            end
          else
            begin
              if PubName.PublicOffset>$ffff then
                internalerror(2015041403);
              RawRecord.RawData[NextOfs]:=Byte(PubName.PublicOffset);
              RawRecord.RawData[NextOfs+1]:=Byte(PubName.PublicOffset shr 8);
              Inc(NextOfs,2);
            end;
          NextOfs:=RawRecord.WriteIndexedRef(NextOfs,PubName.TypeIndex);
        end;
      RawRecord.RecordLength:=Len+1;
      RawRecord.CalculateChecksumByte;

      { update NextIndex }
      NextIndex:=LastIncludedIndex+1;
    end;

  procedure TOmfRecord_PUBDEF.MaybeGo32;
    var
      I: Integer;
      PubName: TOmfPublicNameElement;
    begin
      for I:=0 to PublicNames.Count-1 do
        begin
          PubName:=TOmfPublicNameElement(PublicNames[I]);
          if PubName.PublicOffset>$ffff then
            begin
              Is32Bit:=true;
              exit;
            end;
        end;
    end;

  { TOmfExternalNameElement }

  function TOmfExternalNameElement.GetLengthInFile: Integer;
    begin
      Result:=1+Length(Name)+1;
      if TypeIndex>=$80 then
        Inc(Result);
    end;

  { TOmfRecord_EXTDEF }

  procedure TOmfRecord_EXTDEF.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
      Name: string;
      TypeIndex: Integer;
      ExtName: TOmfExternalNameElement;
    begin
      if RawRecord.RecordType<>RT_EXTDEF then
        internalerror(2015040301);
      NextOfs:=0;
      while NextOfs<(RawRecord.RecordLength-1) do
        begin
          NextOfs:=RawRecord.ReadStringAt(NextOfs,Name);
          NextOfs:=RawRecord.ReadIndexedRef(NextOfs,TypeIndex);
          ExtName:=TOmfExternalNameElement.Create(ExternalNames,Name);
          ExtName.TypeIndex:=TypeIndex;
        end;
    end;

  procedure TOmfRecord_EXTDEF.EncodeTo(RawRecord: TOmfRawRecord);
    const
      RecordLengthLimit = 1024;
    var
      Len,LastIncludedIndex,NextOfs,I: Integer;
      ExtName: TOmfExternalNameElement;
    begin
      RawRecord.RecordType:=RT_EXTDEF;
      NextOfs:=0;

      { find out how many external names can we include until we reach the length limit }
      Len:=NextOfs;
      LastIncludedIndex:=NextIndex-1;
      repeat
        Inc(LastIncludedIndex);
        Inc(Len,TOmfExternalNameElement(ExternalNames[LastIncludedIndex]).GetLengthInFile);
      until (LastIncludedIndex>=(ExternalNames.Count-1)) or ((Len+TOmfExternalNameElement(ExternalNames[LastIncludedIndex+1]).GetLengthInFile)>=RecordLengthLimit);

      { write the external names... }
      for I:=NextIndex to LastIncludedIndex do
        begin
          ExtName:=TOmfExternalNameElement(ExternalNames[I]);
          NextOfs:=RawRecord.WriteStringAt(NextOfs,ExtName.Name);
          NextOfs:=RawRecord.WriteIndexedRef(NextOfs,ExtName.TypeIndex);
        end;
      RawRecord.RecordLength:=Len+1;
      RawRecord.CalculateChecksumByte;

      { update NextIndex }
      NextIndex:=LastIncludedIndex+1;
    end;

  { TOmfRecord_MODEND }

  procedure TOmfRecord_MODEND.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      ModTyp: Byte;
      NextOfs: Integer;
      EndData: Byte;
    begin
      if not (RawRecord.RecordType in [RT_MODEND,RT_MODEND32]) then
        internalerror(2015040301);
      Is32Bit:=RawRecord.RecordType=RT_MODEND32;

      if RawRecord.RecordLength<2 then
        internalerror(2015040305);
      ModTyp:=RawRecord.RawData[0];
      IsMainModule:=(ModTyp and $80)<>0;
      HasStartAddress:=(ModTyp and $40)<>0;
      SegmentBit:=(ModTyp and $20)<>0;
      LogicalStartAddress:=(ModTyp and $01)<>0;
      if (ModTyp and $1E)<>0 then
        internalerror(2015041404);
      NextOfs:=1;

      { clear all the start address properties first }
      FrameMethod:=Low(FrameMethod);
      FrameDatum:=0;
      TargetMethod:=Low(TargetMethod);
      TargetDatum:=0;
      TargetDisplacement:=0;
      PhysFrameNumber:=0;
      PhysOffset:=0;

      if HasStartAddress then
        begin
          if LogicalStartAddress then
            begin
              if NextOfs>=RawRecord.RecordLength then
                internalerror(2015040305);
              EndData:=RawRecord.RawData[NextOfs];
              Inc(NextOfs);
              { frame and target method determined by thread is not allowed in MODEND records }
              if (EndData and $88)<>0 then
                internalerror(2015041406);
              FrameMethod:=TOmfFixupFrameMethod((EndData shr 4) and 7);
              TargetMethod:=TOmfFixupTargetMethod(EndData and 7);
              { frame method ffmLocation is not allowed in an MODEND record }
              if FrameMethod=ffmLocation then
                internalerror(2015041402);
              { read Frame Datum? }
              if FrameMethod in [ffmSegmentIndex,ffmGroupIndex,ffmExternalIndex,ffmFrameNumber] then
                NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FFrameDatum);
              { read Target Datum? }
              NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FTargetDatum);
              { read Target Displacement? }
              if TargetMethod in [ftmSegmentIndex,ftmGroupIndex,ftmExternalIndex,ftmFrameNumber] then
                begin
                  if Is32Bit then
                    begin
                      if (NextOfs+3)>=RawRecord.RecordLength then
                        internalerror(2015040504);
                      TargetDisplacement := RawRecord.RawData[NextOfs]+
                                           (RawRecord.RawData[NextOfs+1] shl 8)+
                                           (RawRecord.RawData[NextOfs+2] shl 16)+
                                           (RawRecord.RawData[NextOfs+3] shl 24);
                      Inc(NextOfs,4);
                    end
                  else
                    begin
                      if (NextOfs+1)>=RawRecord.RecordLength then
                        internalerror(2015040504);
                      TargetDisplacement := RawRecord.RawData[NextOfs]+
                                           (RawRecord.RawData[NextOfs+1] shl 8);
                      Inc(NextOfs,2);
                    end;
                end;
            end
          else
            begin
              { physical start address }
              if (NextOfs+1)>=RawRecord.RecordLength then
                internalerror(2015040305);
              PhysFrameNumber:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8);
              Inc(NextOfs,2);
              if Is32Bit then
                begin
                  if (NextOfs+3)>=RawRecord.RecordLength then
                    internalerror(2015040305);
                  PhysOffset:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8)+
                    (RawRecord.RawData[NextOfs+2] shl 16)+(RawRecord.RawData[NextOfs+3] shl 24);
                  Inc(NextOfs,4);
                end
              else
                begin
                  if (NextOfs+1)>=RawRecord.RecordLength then
                    internalerror(2015040305);
                  PhysOffset:=RawRecord.RawData[NextOfs]+(RawRecord.RawData[NextOfs+1] shl 8);
                  Inc(NextOfs,2);
                end;
            end;
        end;
    end;

  procedure TOmfRecord_MODEND.EncodeTo(RawRecord: TOmfRawRecord);
    var
      ModTyp: Byte;
      NextOfs: Integer;
      EndData: Byte;
    begin
      if Is32Bit then
        RawRecord.RecordType:=RT_MODEND32
      else
        RawRecord.RecordType:=RT_MODEND;
      ModTyp:=(Ord(IsMainModule) shl 7)+(Ord(HasStartAddress) shl 6)+(Ord(SegmentBit) shl 5)+Ord(LogicalStartAddress);
      RawRecord.RawData[0]:=ModTyp;
      NextOfs:=1;
      if HasStartAddress then
        begin
          if LogicalStartAddress then
            begin
              { frame method ffmLocation is not allowed in an MODEND record }
              if FrameMethod=ffmLocation then
                internalerror(2015041402);
              EndData:=(Ord(FrameMethod) shl 4)+Ord(TargetMethod);
              RawRecord.RawData[NextOfs]:=EndData;
              Inc(NextOfs);
              { save Frame Datum? }
              if FrameMethod in [ffmSegmentIndex,ffmGroupIndex,ffmExternalIndex,ffmFrameNumber] then
                NextOfs:=RawRecord.WriteIndexedRef(NextOfs,FrameDatum);
              { save Target Datum? }
              NextOfs:=RawRecord.WriteIndexedRef(NextOfs,TargetDatum);
              { save Target Displacement? }
              if TargetMethod in [ftmSegmentIndex,ftmGroupIndex,ftmExternalIndex,ftmFrameNumber] then
                begin
                  if Is32Bit then
                    begin
                      RawRecord.RawData[NextOfs]:=Byte(TargetDisplacement);
                      RawRecord.RawData[NextOfs+1]:=Byte(TargetDisplacement shr 8);
                      RawRecord.RawData[NextOfs+2]:=Byte(TargetDisplacement shr 16);
                      RawRecord.RawData[NextOfs+3]:=Byte(TargetDisplacement shr 24);
                      Inc(NextOfs,4);
                    end
                  else
                    begin
                      if TargetDisplacement>$ffff then
                        internalerror(2015040502);
                      RawRecord.RawData[NextOfs]:=Byte(TargetDisplacement);
                      RawRecord.RawData[NextOfs+1]:=Byte(TargetDisplacement shr 8);
                      Inc(NextOfs,2);
                    end;
                end;
            end
          else
            begin
              { physical start address }
              RawRecord.RawData[NextOfs]:=Byte(PhysFrameNumber);
              RawRecord.RawData[NextOfs+1]:=Byte(PhysFrameNumber shr 8);
              Inc(NextOfs,2);
              if Is32Bit then
                begin
                  RawRecord.RawData[NextOfs]:=Byte(PhysOffset);
                  RawRecord.RawData[NextOfs+1]:=Byte(PhysOffset shr 8);
                  RawRecord.RawData[NextOfs+2]:=Byte(PhysOffset shr 16);
                  RawRecord.RawData[NextOfs+3]:=Byte(PhysOffset shr 24);
                  Inc(NextOfs,4);
                end
              else
                begin
                  if PhysOffset>$ffff then
                    internalerror(2015040502);
                  RawRecord.RawData[NextOfs]:=Byte(PhysOffset);
                  RawRecord.RawData[NextOfs+1]:=Byte(PhysOffset shr 8);
                  Inc(NextOfs,2);
                end;
            end;
        end;
      RawRecord.RecordLength:=NextOfs+1;
      RawRecord.CalculateChecksumByte;
    end;

  { TOmfRecord_LINNUM }

  procedure TOmfRecord_LINNUM.DecodeFrom(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
    begin
      if not (RawRecord.RecordType in [RT_LINNUM,RT_LINNUM32]) then
        internalerror(2018050801);
      Is32Bit:=RawRecord.RecordType=RT_LINNUM32;

      NextOfs:=RawRecord.ReadIndexedRef(0,FBaseGroup);
      NextOfs:=RawRecord.ReadIndexedRef(NextOfs,FBaseSegment);

      DebugFormatSpecific_DecodeFrom(RawRecord,NextOfs);
    end;

  procedure TOmfRecord_LINNUM.EncodeTo(RawRecord: TOmfRawRecord);
    var
      NextOfs: Integer;
    begin
      if Is32Bit then
        RawRecord.RecordType:=RT_LINNUM32
      else
        RawRecord.RecordType:=RT_LINNUM;

      NextOfs:=RawRecord.WriteIndexedRef(0,BaseGroup);
      NextOfs:=RawRecord.WriteIndexedRef(NextOfs,BaseSegment);

      DebugFormatSpecific_EncodeTo(RawRecord,NextOfs);

      RawRecord.RecordLength:=NextOfs+1;
      RawRecord.CalculateChecksumByte;
    end;

  { TOmfSubRecord_LINNUM_MsLink_Entry }

  constructor TOmfSubRecord_LINNUM_MsLink_Entry.Create(ALineNumber: TOmfSubRecord_LINNUM_MsLink_LineNumber; AOffset: DWord);
    begin
      LineNumber:=ALineNumber;
      Offset:=AOffset;
    end;

  { TOmfSubRecord_LINNUM_MsLink_LineNumberList }

  function TOmfSubRecord_LINNUM_MsLink_LineNumberList.GetCount: Integer;
    begin
      result:=FLineNumbers.Count;
    end;

  function TOmfSubRecord_LINNUM_MsLink_LineNumberList.GetItem(Index: Integer
    ): TOmfSubRecord_LINNUM_MsLink_Entry;
    begin
      result:=TOmfSubRecord_LINNUM_MsLink_Entry(FLineNumbers[Index]);
    end;

  procedure TOmfSubRecord_LINNUM_MsLink_LineNumberList.SetCount(AValue: Integer
    );
    begin
      FLineNumbers.Count:=AValue;
    end;

  procedure TOmfSubRecord_LINNUM_MsLink_LineNumberList.SetItem(Index: Integer;
    AValue: TOmfSubRecord_LINNUM_MsLink_Entry);
    begin
      FLineNumbers[Index]:=AValue;
    end;

  constructor TOmfSubRecord_LINNUM_MsLink_LineNumberList.Create;
    begin
      FLineNumbers:=TFPObjectList.Create(true);
    end;

  destructor TOmfSubRecord_LINNUM_MsLink_LineNumberList.Destroy;
    begin
      FLineNumbers.Free;
      inherited Destroy;
    end;

  procedure TOmfSubRecord_LINNUM_MsLink_LineNumberList.Clear;
    begin
      FLineNumbers.Clear;
    end;

  function TOmfSubRecord_LINNUM_MsLink_LineNumberList.Add(
    AObject: TOmfSubRecord_LINNUM_MsLink_Entry): Integer;
    begin
      Result:=FLineNumbers.Add(AObject);
    end;

  { TOmfRecord_LINNUM_MsLink }

  procedure TOmfRecord_LINNUM_MsLink.DebugFormatSpecific_DecodeFrom(
    RawRecord: TOmfRawRecord; NextOfs: Integer);
    var
      RecordSize: Integer;
      LineNumber: Word;
      Offset: DWord;
    begin
      if Is32Bit then
        RecordSize:=6
      else
        RecordSize:=4;
      while (NextOfs+RecordSize)<RawRecord.RecordLength do
        begin
          LineNumber:=RawRecord.RawData[NextOfs]+
                     (RawRecord.RawData[NextOfs+1] shl 8);
          if Is32Bit then
            Offset:=RawRecord.RawData[NextOfs+2]+
                   (RawRecord.RawData[NextOfs+3] shl 8)+
                   (RawRecord.RawData[NextOfs+4] shl 16)+
                   (RawRecord.RawData[NextOfs+5] shl 24)
          else
            Offset:=RawRecord.RawData[NextOfs+2]+
                   (RawRecord.RawData[NextOfs+3] shl 8);
          LineNumberList.Add(TOmfSubRecord_LINNUM_MsLink_Entry.Create(LineNumber,Offset));
          Inc(NextOfs,RecordSize);
        end;
    end;

  procedure TOmfRecord_LINNUM_MsLink.DebugFormatSpecific_EncodeTo(
    RawRecord: TOmfRawRecord; var NextOfs: Integer);
    const
      RecordLengthLimit = 1024;
    var
      I, Len, LastIncludedIndex, RecordSize: Integer;
    begin
      { find out how many line number records can we include until we reach the length limit }
      if Is32Bit then
        RecordSize:=6
      else
        RecordSize:=4;
      Len:=NextOfs;
      LastIncludedIndex:=NextIndex-1;
      repeat
        Inc(LastIncludedIndex);
        Inc(Len,RecordSize);
      until (LastIncludedIndex>=(LineNumberList.Count-1)) or ((Len+RecordSize)>=RecordLengthLimit);

      { write the line number info... }
      for I:=NextIndex to LastIncludedIndex do
        with LineNumberList.Items[I] do
          begin
            RawRecord.RawData[NextOfs]:=byte(LineNumber);
            RawRecord.RawData[NextOfs+1]:=byte(LineNumber shr 8);
            Inc(NextOfs,2);
            if Is32Bit then
              begin
                RawRecord.RawData[NextOfs]:=byte(Offset);
                RawRecord.RawData[NextOfs+1]:=byte(Offset shr 8);
                RawRecord.RawData[NextOfs+2]:=byte(Offset shr 16);
                RawRecord.RawData[NextOfs+3]:=byte(Offset shr 24);
                Inc(NextOfs,4);
              end
            else
              begin
                if Offset>High(Word) then
                  internalerror(2018050901);
                RawRecord.RawData[NextOfs]:=byte(Offset);
                RawRecord.RawData[NextOfs+1]:=byte(Offset shr 8);
                Inc(NextOfs,2);
              end;
          end;

      { update NextIndex }
      NextIndex:=LastIncludedIndex+1;
    end;

  { TOmfSubRecord_FIXUP }

  function TOmfSubRecord_FIXUP.GetDataRecordOffset: Integer;
    begin
      Result:=FLocationOffset-FDataRecordStartOffset;
    end;

  function TOmfSubRecord_FIXUP.GetLocationSize: Integer;
    const
      OmfLocationType2Size: array [TOmfFixupLocationType] of Integer=
        (1,  // fltLoByte
         2,  // fltOffset
         2,  // fltBase
         4,  // fltFarPointer
         1,  // fltHiByte
         2,  // fltLoaderResolvedOffset  (PharLap: Offset32)
         0,  // fltUndefined6            (PharLap: Pointer48)
         0,  // fltUndefined7
         0,  // fltUndefined8
         4,  // fltOffset32
         0,  // fltUndefined10
         6,  // fltFarPointer48
         0,  // fltUndefined12
         4,  // fltLoaderResolvedOffset32
         0,  // fltUndefined14
         0); // fltUndefined15
    begin
      Result:=OmfLocationType2Size[LocationType];
    end;

  procedure TOmfSubRecord_FIXUP.SetDataRecordOffset(AValue: Integer);
    begin
      FLocationOffset:=AValue+FDataRecordStartOffset;
    end;

  function TOmfSubRecord_FIXUP.ReadAt(RawRecord: TOmfRawRecord; Offset: Integer): Integer;
    var
      Locat: Word;
      FixData: Byte;
    begin
      if (Offset+2)>=RawRecord.RecordLength then
        internalerror(2015040504);
      { unlike other fields in the OMF format, this one is big endian }
      Locat:=(RawRecord.RawData[Offset] shl 8) or RawRecord.RawData[Offset+1];
      FixData:=RawRecord.RawData[Offset+2];
      Inc(Offset,3);
      if (Locat and $8000)=0 then
        internalerror(2015040503);
      DataRecordOffset:=Locat and $3FF;
      LocationType:=TOmfFixupLocationType((Locat shr 10) and 15);
      Mode:=TOmfFixupMode((Locat shr 14) and 1);
      FrameDeterminedByThread:=(FixData and $80)<>0;
      TargetDeterminedByThread:=(FixData and $08)<>0;
      if FrameDeterminedByThread then
        FrameThread:=TOmfFixupThread((FixData shr 4) and 3)
      else
        FrameMethod:=TOmfFixupFrameMethod((FixData shr 4) and 7);
      if TargetDeterminedByThread then
        begin
          TargetThread:=TOmfFixupThread(FixData and 3);
          TargetThreadDisplacementPresent:=(FixData and $40)=0;
        end
      else
        TargetMethod:=TOmfFixupTargetMethod(FixData and 7);
      { read Frame Datum? }
      if not FrameDeterminedByThread and (FrameMethod in [ffmSegmentIndex,ffmGroupIndex,ffmExternalIndex,ffmFrameNumber]) then
        Offset:=RawRecord.ReadIndexedRef(Offset,FFrameDatum)
      else
        FrameDatum:=0;
      { read Target Datum? }
      if not TargetDeterminedByThread then
        Offset:=RawRecord.ReadIndexedRef(Offset,FTargetDatum)
      else
        TargetDatum:=0;
      { read Target Displacement? }
      if (TargetDeterminedByThread and TargetThreadDisplacementPresent) or
         (TargetMethod in [ftmSegmentIndex,ftmGroupIndex,ftmExternalIndex,ftmFrameNumber]) then
        begin
          if Is32Bit then
            begin
              if (Offset+3)>=RawRecord.RecordLength then
                internalerror(2015040504);
              TargetDisplacement := RawRecord.RawData[Offset]+
                                   (RawRecord.RawData[Offset+1] shl 8)+
                                   (RawRecord.RawData[Offset+2] shl 16)+
                                   (RawRecord.RawData[Offset+3] shl 24);
              Inc(Offset,4);
            end
          else
            begin
              if (Offset+1)>=RawRecord.RecordLength then
                internalerror(2015040504);
              TargetDisplacement := RawRecord.RawData[Offset]+
                                   (RawRecord.RawData[Offset+1] shl 8);
              Inc(Offset,2);
            end;
        end;
      Result:=Offset;
    end;

  function TOmfSubRecord_FIXUP.WriteAt(RawRecord: TOmfRawRecord; Offset: Integer): Integer;
    var
      Locat: Word;
      FixData: Byte;
    begin
      if (DataRecordOffset<0) or (DataRecordOffset>1023) then
        internalerror(2015040505);
      Locat:=$8000+(Ord(Mode) shl 14)+(Ord(LocationType) shl 10)+DataRecordOffset;
      { unlike other fields in the OMF format, this one is big endian }
      RawRecord.RawData[Offset]:=Byte(Locat shr 8);
      RawRecord.RawData[Offset+1]:=Byte(Locat);
      Inc(Offset, 2);
      FixData:=(Ord(FrameDeterminedByThread) shl 7)+(Ord(TargetDeterminedByThread) shl 3);
      if FrameDeterminedByThread then
        FixData:=FixData+(Ord(FrameThread) shl 4)
      else
        FixData:=FixData+(Ord(FrameMethod) shl 4);
      if TargetDeterminedByThread then
        FixData:=FixData+Ord(TargetThread)+(Ord(not TargetThreadDisplacementPresent) shl 2)
      else
        FixData:=FixData+Ord(TargetMethod);
      RawRecord.RawData[Offset]:=FixData;
      Inc(Offset);
      { save Frame Datum? }
      if not FrameDeterminedByThread and (FrameMethod in [ffmSegmentIndex,ffmGroupIndex,ffmExternalIndex,ffmFrameNumber]) then
        Offset:=RawRecord.WriteIndexedRef(Offset,FrameDatum);
      { save Target Datum? }
      if not TargetDeterminedByThread then
        Offset:=RawRecord.WriteIndexedRef(Offset,TargetDatum);
      { save Target Displacement? }
      if (TargetDeterminedByThread and TargetThreadDisplacementPresent) or
         (TargetMethod in [ftmSegmentIndex,ftmGroupIndex,ftmExternalIndex,ftmFrameNumber]) then
        begin
          if Is32Bit then
            begin
              RawRecord.RawData[Offset]:=Byte(TargetDisplacement);
              RawRecord.RawData[Offset+1]:=Byte(TargetDisplacement shr 8);
              RawRecord.RawData[Offset+2]:=Byte(TargetDisplacement shr 16);
              RawRecord.RawData[Offset+3]:=Byte(TargetDisplacement shr 24);
              Inc(Offset,4);
            end
          else
            begin
              if TargetDisplacement>$ffff then
                internalerror(2015040502);
              RawRecord.RawData[Offset]:=Byte(TargetDisplacement);
              RawRecord.RawData[Offset+1]:=Byte(TargetDisplacement shr 8);
              Inc(Offset,2);
            end;
        end;
      Result:=Offset;
    end;


  { TOmfRecord_LIBHEAD }

  constructor TOmfRecord_LIBHEAD.Create;
    begin
      PageSize:=512;
      DictionarySizeInBlocks:=2;
      CaseSensitive:=true;
    end;

  procedure TOmfRecord_LIBHEAD.SetPageSize(AValue: Integer);
    var
      p: longint;
    begin
      { valid library page sizes are powers of two, between 2**4 and 2**15 }
      if not ispowerof2(AValue,p) then
        internalerror(2015041802);
      if (p<4) or (p>15) then
        internalerror(2015041802);
      FPageSize:=AValue;
    end;

  procedure TOmfRecord_LIBHEAD.DecodeFrom(RawRecord: TOmfRawRecord);
    begin
      if RawRecord.RecordType<>RT_LIBHEAD then
        internalerror(2015040301);
      { this will also range check PageSize and will ensure that RecordLength>=13 }
      PageSize:=RawRecord.RecordLength+3;
      DictionaryOffset:=RawRecord.RawData[0]+
                       (RawRecord.RawData[1] shl 8)+
                       (RawRecord.RawData[2] shl 16)+
                       (RawRecord.RawData[3] shl 24);
      DictionarySizeInBlocks:=RawRecord.RawData[4]+
                             (RawRecord.RawData[5] shl 8);
      Flags:=RawRecord.RawData[6];
    end;

  procedure TOmfRecord_LIBHEAD.EncodeTo(RawRecord: TOmfRawRecord);
    begin
      { make sure the LIBHEAD record is padded with zeros at the end }
      FillChar(RawRecord.RawData,SizeOf(RawRecord.RawData),0);
      RawRecord.RecordType:=RT_LIBHEAD;
      RawRecord.RecordLength:=PageSize-3;
      RawRecord.RawData[0]:=Byte(DictionaryOffset);
      RawRecord.RawData[1]:=Byte(DictionaryOffset shr 8);
      RawRecord.RawData[2]:=Byte(DictionaryOffset shr 16);
      RawRecord.RawData[3]:=Byte(DictionaryOffset shr 24);
      RawRecord.RawData[4]:=Byte(DictionarySizeInBlocks);
      RawRecord.RawData[5]:=Byte(DictionarySizeInBlocks shr 8);
      RawRecord.RawData[6]:=Flags;
      { the LIBHEAD record contains no checksum byte, so no need to call
        RawRecord.CalculateChecksumByte }
    end;

  function TOmfRecord_LIBHEAD.IsCaseSensitive: Boolean;
    begin
      Result:=(FFlags and 1)<>0;
    end;

  procedure TOmfRecord_LIBHEAD.SetCaseSensitive(AValue: Boolean);
    begin
      FFlags:=(FFlags and $FE) or Ord(AValue);
    end;

  { TOmfRecord_LIBEND }

  procedure TOmfRecord_LIBEND.DecodeFrom(RawRecord: TOmfRawRecord);
    begin
      if RawRecord.RecordType<>RT_LIBEND then
        internalerror(2015040301);
      FPaddingBytes:=RawRecord.RecordLength;
    end;

  procedure TOmfRecord_LIBEND.EncodeTo(RawRecord: TOmfRawRecord);
    begin
      { make sure the LIBEND record is padded with zeros at the end }
      FillChar(RawRecord.RawData,SizeOf(RawRecord.RawData),0);
      RawRecord.RecordType:=RT_LIBEND;
      RawRecord.RecordLength:=FPaddingBytes;
      { the LIBEND record contains no checksum byte, so no need to call
        RawRecord.CalculateChecksumByte }
    end;

  procedure TOmfRecord_LIBEND.CalculatePaddingBytes(RecordStartOffset: DWord);
    var
      DictionaryStartOffset: Integer;
    begin
      { padding must be calculated, so that the dictionary begins on a 512-byte boundary }
      Inc(RecordStartOffset,3);  // padding begins _after_ the record header (3 bytes)
      DictionaryStartOffset:=(RecordStartOffset+511) and $fffffe00;
      PaddingBytes:=DictionaryStartOffset-RecordStartOffset;
    end;

  function compute_omf_lib_hash(const name: string; blocks: Integer): TOmfLibHash;
    const
      blank=$20;  // ASCII blank
      nbuckets=37;
    var
      block_x: Integer;
      block_d: Integer;
      bucket_x: Integer;
      bucket_d: Integer;
      len: Integer;
      pbidx,peidx: Integer;
      cback,cfront: Byte;
    begin
      len:=Length(name);
      if len=0 then
        internalerror(2015041801);
      pbidx:=1;
      peidx:=len+1;
      { left to right scan }
      block_x:=len or blank;
      bucket_d:=block_x;
      { right to left scan }
      block_d:=0;
      bucket_x:=0;
      while true do
        begin
          { blank -> convert to LC }
          Dec(peidx);
          cback:=Byte(name[peidx]) or blank;
          bucket_x:=RorWord(bucket_x,2) xor cback;
          block_d:=RolWord(block_d,2) xor cback;
          Dec(len);
          if len=0 then
            break;
          cfront:=Byte(name[pbidx]) or blank;
          Inc(pbidx);
          block_x:=RolWord(block_x,2) xor cfront;
          bucket_d:=RorWord(bucket_d,2) xor cfront;
        end;
      Result.block_x:=block_x mod blocks;
      Result.block_d:=max(block_d mod blocks,1);
      Result.bucket_x:=bucket_x mod nbuckets;
      Result.bucket_d:=max(bucket_d mod nbuckets,1);
    end;

  function omf_segclass(atype: TAsmSectiontype): string;
    const
      segclass : array[TAsmSectiontype] of string[length('DWARF')] = ('',
        {user} 'DATA',
        {code} 'CODE',
        {data} 'DATA',
        {rodata} 'DATA',
        {rodata_norel} 'DATA',
        {bss} 'BSS',
        {threadvar} 'DATA',
        {pdata} 'DATA',
        {stub} 'CODE',
        {data_nonlazy} 'DATA',
        {data_lazy} 'DATA',
        {init_func} 'DATA',
        {term_func} 'DATA',
        {stab} 'DATA',
        {stabstr} 'DATA',
        {idata2} 'DATA',
        {idata4} 'DATA',
        {idata5} 'DATA',
        {idata6} 'DATA',
        {idata7} 'DATA',
        {edata} 'DATA',
        {eh_frame} 'DATA',
        {debug_frame} 'DWARF',
        {debug_info} 'DWARF',
        {debug_line} 'DWARF',
        {debug_abbrev} 'DWARF',
        {debug_aranges} 'DWARF',
        {debug_ranges} 'DWARF',
        {fpc} 'DATA',
        {toc} 'DATA',
        {init} 'CODE',
        {fini} 'CODE',
        {objc_class} 'DATA',
        {objc_meta_class} 'DATA',
        {objc_cat_cls_meth} 'DATA',
        {objc_cat_inst_meth} 'DATA',
        {objc_protocol} 'DATA',
        {objc_string_object} 'DATA',
        {objc_cls_meth} 'DATA',
        {objc_inst_meth} 'DATA',
        {objc_cls_refs} 'DATA',
        {objc_message_refs} 'DATA',
        {objc_symbols} 'DATA',
        {objc_category} 'DATA',
        {objc_class_vars} 'DATA',
        {objc_instance_vars} 'DATA',
        {objc_module_info} 'DATA',
        {objc_class_names} 'DATA',
        {objc_meth_var_types} 'DATA',
        {objc_meth_var_names} 'DATA',
        {objc_selector_strs} 'DATA',
        {objc_protocol_ext} 'DATA',
        {objc_class_ext} 'DATA',
        {objc_property} 'DATA',
        {objc_image_info} 'DATA',
        {objc_cstring_object} 'DATA',
        {objc_sel_fixup} 'DATA',
        {objc_data} 'DATA',
        {objc_const} 'DATA',
        {objc_sup_refs} 'DATA',
        {data_coalesced} 'DATA',
        {objc_classlist} 'DATA',
        {objc_nlclasslist} 'DATA',
        {objc_catlist} 'DATA',
        {objc_nlcatlist} 'DATA',
        {objc_protolist} 'DATA',
        {stack} 'STACK',
        {heap} 'HEAP'
      );
    begin
      result:=segclass[atype];
{$ifdef i8086}
      if (current_settings.x86memorymodel=mm_huge) and
        ((result='DATA') or (result='BSS')) then
        result:='FAR_DATA';
{$endif i8086}
    end;

  function omf_sectiontype2align(atype: TAsmSectiontype): longint;
    begin
      case atype of
        sec_stabstr:
          result:=1;
        sec_code:
          result:=1;
        sec_data,
        sec_rodata,
        sec_rodata_norel,
        sec_bss:
          result:=2;
        { For idata (at least idata2) it must be 4 bytes, because
          an entry is always (also in win64) 20 bytes and aligning
          on 8 bytes will insert 4 bytes between the entries resulting
          in a corrupt idata section.
          Same story with .pdata, it has 4-byte elements which should
          be packed without gaps. }
        sec_idata2,sec_idata4,sec_idata5,sec_idata6,sec_idata7,sec_pdata:
          result:=4;
        sec_debug_frame,sec_debug_info,sec_debug_line,sec_debug_abbrev,sec_debug_aranges,sec_debug_ranges:
          result:=1;
        sec_stack,
        sec_heap:
          result:=16;
        else
          result:=1;
      end;
    end;

  function section_belongs_to_dgroup(atype: TAsmSectiontype): Boolean;
    begin
{$ifdef i8086}
      case omf_segclass(atype) of
        'CODE':
          result:=current_settings.x86memorymodel=mm_tiny;
        'FAR_DATA':
          result:=false;
        'DATA',
        'BSS':
          result:=true;
        'STACK':
          result:=current_settings.x86memorymodel in (x86_near_data_models-[mm_tiny]);
        'HEAP':
          result:=current_settings.x86memorymodel in x86_near_data_models;
        else
          result:=false;
      end;
{$else i8086}
      result:=false;
{$endif i8086}
    end;

end.
