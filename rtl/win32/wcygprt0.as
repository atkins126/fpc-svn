//Startup code for WIN32 port of Free Pascal
//Written by P.Ozerski 1998
// modified by Pierre Muller
     .text
     .globl _mainCRTStartup
_mainCRTStartup:
     movb   $1,U_SYSTEM_ISCONSOLE
     jmp    _start

     .globl _WinMainCRTStartup
_WinMainCRTStartup:
     movb   $0,U_SYSTEM_ISCONSOLE
_start:
     subl   $0x8,%esp
     andl   $0xfffffff0,%esp
     push   $_cmain
     call   _cygwin_crt0

     .globl _cmain
_cmain:
     subl   $0x8,%esp
     andl   $0xfffffff0,%esp
     call   ___main
     call   _FPC_EXE_Entry
     ret

     .globl asm_exit
asm_exit:
    pushl   %eax
    call    exitprocess

.text
.globl	exitprocess
exitprocess:
	jmp	*.L10
	.balign 4,144

.text
	.balign 4,144

.section .idata$2
	.rva	.L7
	.long	0,0
	.rva	.L6
	.rva	.L8

.section .idata$4
.L7:
	.rva	.L9
	.long	0

.section .idata$5
.L8:


.section .idata$5
.L10:
	.rva	.L9
	.long	0

.section .idata$6
.L9:
	.short	0
	.ascii	"ExitProcess\000"
	.balign 2,0

.section .idata$7
.L6:
	.ascii	"kernel32.dll\000"




// Revision 1.1  2004/11/04 17:15:01  peter
//  * wcygprt is now used for cygwin (libc) linking, initc contains only cerrno
//
// Revision 1.4  2002/11/30 18:17:35  carl
//   + profiling support
//
// Revision 1.3  2002/07/28 20:43:51  florian
//   * several fixes for linux/powerpc
//   * several fixes to MT
//
//
