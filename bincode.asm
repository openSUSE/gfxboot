			bits 32

			extern jpeg_get_size
			extern jpeg_decode

			global _start

%define			debug 1

%include		"vocabulary.inc"
%include		"modplay_defines.inc"
%include		"jpeg.inc"


; some type definitions from mkbootmsg.c
; struct file_header_t
fh_magic_id		equ 0
fh_version		equ 4
fh_res_1		equ 5
fh_res_2		equ 6
fh_res_3		equ 7
fh_bincode		equ 8
fh_bincode_size		equ 12
fh_bincode_crc		equ 16
fh_dict			equ 20
fh_code			equ 24
fh_code_size		equ 28
sizeof_file_header_t	equ 32


; font file header definition
foh.magic		equ 0
foh.entries		equ 4
foh.height		equ 8
foh.baseline		equ 9
foh.line_height		equ 10
foh.size		equ 11


; char bitmap definitions
; must match values in mkblfont.c
cbm_gray_bits		equ 4
cbm_gray_bit_count	equ 3

cbm_max_gray		equ (1 << cbm_gray_bits) - 3
cbm_rep_black		equ cbm_max_gray + 1
cbm_rep_white		equ cbm_max_gray + 2


; struct playlist
pl_file			equ 0		; actually file index + 1
pl_loop			equ 1
pl_res1			equ 2
pl_res2			equ 3
pl_start		equ 4
pl_current		equ 8
pl_end			equ 12
sizeof_playlist		equ 16
playlist_entries	equ 4


; struct link
li.label		equ 0
li.text			equ 4
li.x			equ 8
li.row			equ 10
li.size			equ 12		; search for 'li.size'!
link_entries		equ 64


; sysconfig data
sc.bootloader		equ 0
sc.sector_shift		equ 1
sc.media_type		equ 2
sc.failsafe		equ 3
sc.sysconfig_size	equ 4
sc.boot_drive		equ 5
sc.callback		equ 6
sc.bootloader_seg	equ 8
sc.reserved_1		equ 10
sc.user_info_0		equ 12
sc.user_info_1		equ 16
sc.bios_mem_size	equ 20
sc.xmem_0		equ 24
sc.xmem_1		equ 26
sc.xmem_2		equ 28
sc.xmem_3		equ 30
sc.file			equ 32
sc.archive_start	equ 36
sc.archive_end		equ 40
sc.mem0_start		equ 44
sc.mem0_end		equ 48


; enum_type_t
t_none			equ 0
t_int			equ 1
t_unsigned		equ 2
t_bool			equ 3
t_string		equ 4
t_code			equ 5
t_ret			equ 6
t_prim			equ 7
t_sec			equ 8
t_dict_idx		equ 9
t_array			equ 10
t_end			equ 11
t_ptr			equ 12

t_if			equ t_code + 10h
t_loop			equ t_code + 20h
t_repeat		equ t_code + 30h
t_for			equ t_code + 40h
t_forall		equ t_code + 50h
t_exit			equ t_code + 60h


param_stack_size	equ 1000
ret_stack_size		equ 1000


; various error codes
pserr_ok			equ 0
pserr_nocode			equ 1
pserr_invalid_opcode		equ 2
pserr_pstack_underflow		equ 3
pserr_pstack_overflow		equ 4
pserr_rstack_underflow		equ 5
pserr_rstack_overflow		equ 6
pserr_invalid_dict		equ 7
pserr_wrong_arg_types		equ 8
pserr_div_by_zero		equ 9
pserr_invalid_rstack_entry	equ 0ah
pserr_invalid_range		equ 0bh
pserr_invalid_exit		equ 0ch
pserr_invalid_image_size	equ 0dh
pserr_no_memory			equ 0eh
pserr_invalid_data		equ 0fh
pserr_nop			equ 10h
pserr_invalid_function		equ 11h
pserr_invalid_dict_entry	equ 200h
pserr_invalid_prim		equ 201h

keyBS			equ 08h
keyLeft			equ 4bh		; scan code
keyRight		equ 4dh		; scan code
keyHome			equ 47h		; scan code
keyEnd			equ 4fh		; scan code
keyDel			equ 53h		; scan code

max_text_rows		equ 128

mhead.memsize		equ 0
mhead.ip		equ 4
mhead.used		equ 8		; bit 7
mhead.rem		equ 8		; bit 0..6
mhead.size		equ 9

			section .text

_start:

; jmp table to interface functions
jt_init			dw gfx_init
jt_done			dw gfx_done
jt_input		dw gfx_input
jt_menu_init		dw gfx_menu_init
jt_infobox_init		dw gfx_infobox_init
jt_infobox_done		dw gfx_infobox_done
jt_progress_init	dw gfx_progress_init
jt_progress_done	dw gfx_progress_done
jt_progress_update	dw gfx_progress_update
jt_progress_limit	dw gfx_progress_limit
jt_password_init	dw gfx_password_init
jt_password_done	dw gfx_password_done

			align 4, db 0
file.start		dd 0		; the file we are in

archive.start		dd 0		; archive start address (0 -> none)
archive.end		dd 0		; archive end

mem0.start		dd 0		; free low memory area start
mem0.end		dd 0		; dto, end

malloc.areas		equ 5
malloc.start		dd 0
malloc.end		dd 0
			; start, end pairs
malloc.area		times malloc.areas * 2 dd 0

vbe_buffer		dd 0		; (lin) buffer for vbe calls
vbe_mode_list		dd 0		; (lin) list with (up to 100h) vbe modes
vbe_info_buffer		dd 0		; (lin) buffer for vbe gfx card info
infobox_buffer		dd 0		; (lin) temp buffer for InfoBox messages

local_stack		dd 0		; ofs local stack (8k)
local_stack.ofs		equ local_stack
local_stack.seg		dw 0		; dto, seg
old_stack		dd 0		; store old esp value
old_stack.ofs		equ old_stack
old_stack.seg		dw 0		; dto, ss
stack.size		dd 0		; in bytes
tmp_stack_val		dw 0		; needed for stack switching

pscode_start		dd 0		; (lin)
pscode_size		dd 0
pscode_instr		dd 0		; (lin) current instruction (rel. to pscode_start)
pscode_next_instr	dd 0		; (lin) next instruction
; for debugging only
pscode_next_break	dd 0		; (lin) break at this instruction
pscode_eval		dd 0		; opcode from exec instruction
pscode_error_arg_0	dd 0
pscode_error_arg_1	dd 0
pscode_arg		dd 0		; current arg
pscode_error		dw 0		; error code (if any)
pscode_type		db 0		; current instr type

			align 4, db 0
dict			dd 0		; lin
dict.size		dd 0		; dict entries

boot.base		dd 0		; bootloader segment
boot.sysconfig		dd 0		; bootloader parameter block
boot.callback		dd 0 		; seg:ofs

pstack			dd 0		; data stack
pstack.size		dd 0		; entries
pstack.ptr		dd 0		; index of current tos
rstack			dd 0		; code stack
rstack.size		dd 0		; entries
rstack.ptr		dd 0		; index of current tos

image			dd 0		; (lin) current image
image_width		dw 0
image_height		dw 0
image_type		db 0		; 0:no image, 1: pcx, 2:jpeg

pcx_line_starts		dd 0		; (lin) table of line starts
jpg_static_buf		dd 0		; (lin) tmp data for jpeg decoder

screen_width		dw 0
screen_height		dw 0
screen_vheight		dw 0
screen_mem		dw 0		; mem in 64k
screen_line_len		dd 0

setpixel		dd setpixel_8		; function that sets one pixel
setpixel_a		dd setpixel_a_8		; function that sets one pixel
setpixel_t		dd setpixel_8		; function that sets one pixel
setpixel_ta		dd setpixel_a_8		; function that sets one pixel
getpixel		dd getpixel_8		; function that gets one pixel


transp			dd 0		; transparency

			align 4, db 0
; current font description
font			dd 0		; (lin)
font.entries		dd 0		; chars in font
font.height		dw 0
font.baseline		dw 0
font.line_height	dw 0
font.properties		db 0		; bit 0: pw mode (show '*')
font.res1		db 0		; alignment

; console font
cfont.lin		dd 0		; console font bitmap
cfont_height		dd 0
con_x			dw 0		; cursor pos in pixel
con_y			dw 0		; cursor pos in pixel, *must* follow con_x


; current char description
chr.buf			dd 0		; buffer for antialiased fonts
chr.buf_len		dd 0
chr.pixel_buf		dd 0
chr.data		dd 0		; encoded char data
chr.bitmap		dd 0		; start of encoded bitmap; bit offset rel to chr.data
chr.bitmap_width	dw 0
chr.bitmap_height	dw 0
chr.x_ofs		dw 0
chr.y_ofs		dw 0		; rel. to baseline
chr.x_advance		dw 0
chr.type		db 0		; 0 = bitmap, 1: gray scale

chr.gray_values
%assign i 0
%rep cbm_max_gray + 1
			db (i * 255)/cbm_max_gray
%assign i i + 1
%endrep

utf8_buf		times 8 db 0

; pointer to currently active palette (3*100h bytes)
gfx_pal			dd 0		; (lin)
; pointer to tmp area (3*100h bytes)
gfx_pal_tmp		dd 0		; (lin)
; number of fixed pal values
pals			dw 0

; the current gfx mode
gfx_mode		dw 3
; != 0 if we're using a vbe mode (hi byte of gfx_mode)
vbe_active		equ gfx_mode + 1
pixel_bits		db 0		; pixel size (8 or 16)
color_bits		db 0		; color bits (8, 15 or 16)
pixel_bytes		dd 0		; pixel size in bytes

; segment address of writeable window
window_seg_w		dw 0
; segment address of readable window (= gfx_window_seg_w if 0)
window_seg_r		dw 0
; ganularity units per window
window_inc		db 0
; currently mapped window
mapped_window		db 0

; cursor position
gfx_cur			equ $		; both x & y
gfx_cur_x		dw 0
gfx_cur_y		dw 0		; must follow gfx_cur_x
gfx_width		dw 0
gfx_height		dw 0
line_wrap		dd 0

; clip region (incl)
clip_l			dw 0		; left, incl
clip_r			dw 0		; right, excl
clip_t			dw 0		; top, incl
clip_b			dw 0		; bottom, excl

line_x0			dd 0
line_y0			dd 0
line_x1			dd 0
line_y1			dd 0
line_tmp		dd 0
line_tmp2		dd 0

			align 4, db 0
gfx_color		dd 0		; current color
gfx_color0		dd 0		; color #0 (normal color))
gfx_color1		dd 0		; color #1 (highlight color)
gfx_color2		dd 0		; color #2 (link color)
gfx_color3		dd 0		; color #3 (selected link color)
gfx_color_rgb		dd 0		; current color (rgb)
transparent_color	dd -1
char_eot		dd 0		; 'end of text' char
last_label		dd 0		; lin
page_title		dd 0		; lin
max_rows		dd 0		; max. number of text rows
cur_row			dd 0		; current text row (0 based)
cur_row2		dd 0		; dto, only during formatting
start_row		dd 0		; start row for text output
cur_link		dd 0		; link count
sel_link		dd 0		; selected link
txt_state		db 0		; bit 0: 1 = skip text
					; bit 1: 1 = text formatting only
textmode_color		db 7		; fg color for text (debug) output
keep_mode		db 0		; keep video mode in gfx_done

			align 4, db 0

idle.draw_buffer	dd 0		; some drawing buffer
idle.data1		dd 0		; some data
idle.data2		dd 0		; some more data
idle.run		db 0		; run idle loop
idle.invalid		db 0		; idle loop has been left

			align 4, db 0
row_text		times max_text_rows dd 0

			; note: link_list relies on row_start
link_list		times li.size * link_entries db 0

			; max label size: 32
label_buf		times 35 db 0

; buffer for number conversions
; must be large enough for ps_status_info()
num_buf			times 23h db 0
num_buf_end		db 0

; temp data for printf
tmp_write_data		times 10h dd 0
tmp_write_num		dd 0
tmp_write_sig		db 0
tmp_write_cnt		db 0
tmp_write_pad		db 0

pf_gfx			db 0
pf_gfx_raw_char		db 0
pf_gfx_err		dw 0
			align 4, db 0
pf_gfx_buf		dd 0
pf_gfx_max		dd 0
pf_gfx_cnt		dd 0

input_notimeout		db 0
			align 4, db 0
input_timeout_start	dd 0
input_timeout		dd 0

progress_max		dd 0
progress_current	dd 0

edit_x			dw 0
edit_y			dw 0
edit_width		dw 0
edit_height		dw 0
edit_bg			dd 0		; (lin)
edit_buf		dd 0		; (lin)
edit_buf_len		dw 0
edit_buf_ptr		dw 0
edit_cursor		dw 0
edit_shift		dw 0
edit_y_ofs		dw 0

kbd_status		dw 0


sound_buf_size		equ 8*1024

			align 4, db 0
sound_x			dd 0
sound_old_int8		dd 0
sound_old_61		db 0
sound_61		db 0
sound_cnt0		dw 0
sound_timer0		dw 0
sound_timer1		dw 0
sound_vol		db 0
sound_ok		db 0
sound_int_active	db 0
sound_playing		db 0
sound_sample		dd 0
sound_buf		dd 0		; (seg:ofs)
sound_buf.lin		dd 0		; buffer for sound player
sound_start		dd 0		; rel. to sound_buf
sound_end		dd 0		; rel. to sound_buf
playlist		times playlist_entries * sizeof_playlist db 0
mod_buf			dd 0 		; buffer for mod player
int8_count		dd 0
cycles_per_tt		dd 0
cycles_per_int		dd 0
next_int		dd 0,0

			align 4, db 0

ddc_external		dd 0

; temporary vars
tmp_var_0		dd 0
tmp_var_1		dd 0
tmp_var_2		dd 0
tmp_var_3		dd 0

ddc_timings		dw 0		; standard ddc timing info
ddc_xtimings		dd 0		; converted standard timing/final timing value
ddc_xtimings1		dd 0, 0, 0, 0
ddc_mult		dd 0, 1		; needed for ddc timing calculation
			dd 3, 4
			dd 4, 5
			dd 9, 16

fsc_bits		dw 0, 0x0004, 0x4000, 0x0200, 0x0100, 0x0200, 0, 0x4000
			dw 0x0200, 0, 0, 0, 0, 0, 0, 0

			align 2
pm_idt			dw 7ffh			; idt for pm
.base			dd 0
rm_idt			dw 0ffffh		; idt for real mode
.base			dd 0
pm_gdt			dw gdt_size-1		; gdt for pm
.base			dd 0

; real mode segment values
rm_seg:
.ss			dw 0
.cs			dw 0
.ds			dw 0
.es			dw 0
.fs			dw 0
.gs			dw 0

			align 4

prog.base		dd 0			; our base address

gdt			dd 0, 0			; null descriptor
.4gb_d32		dd 0000ffffh, 00cf9300h	; 4GB segment, data, use32
.4gb_c32		dd 0000ffffh, 00cf9b00h	; 4GB segment, code, use32
			; see gdt_init
.prog_c32		dd 00000000h, 00409b00h	; our program as code, use32
.prog_d16		dd 00000000h, 00009300h	; dto, data, use16
.prog_c16		dd 00000000h, 00009b00h	; dto, code, use16
.data_d16		dd 00000000h, 00009300h	; 64k segment, data, use16

.screen_r16		dd 00000000h, 00009300h ; 64k screen, data, use16
.screen_w16		dd 00000000h, 00009300h ; 64k screen, data, use16
gdt_size		equ $-gdt

; gdt for pm switch
pm_seg.4gb_d32		equ 8			; covers all 4GB, default ss, es, fs, gs
pm_seg.4gb_c32		equ 10h			; dto, but executable (for e.g., idt)
pm_seg.prog_c32		equ 18h			; default cs, use32
pm_seg.prog_d16		equ 20h			; default ds
pm_seg.prog_c16		equ 28h			; default cs, use16
pm_seg.data_d16		equ 30h			; free to use
pm_seg.screen_r16	equ 38h			; graphics window, for reading
pm_seg.screen_w16	equ 40h			; graphics window, for writing

%if debug
; debug texts
dmsg_01			db 10, 'Press a key to continue...', 0
dmsg_02			db '     mem area %d: 0x%08x - 0x%08x', 10, 0
dmsg_03			db '%3u: addr 0x%06x, size 0x%06x+%u, ip 0x%04x, %s', 10, 0
dmsg_04			db 'oops: block at 0x%06x: size 0x%06x is too small', 10, 0
dmsg_04a		db 'oops: 0x%06x > 0x%06x', 10, 0
dmsg_06			db 'addr 0x%06x', 10, 0
dmsg_07			db 'free', 0
dmsg_08			db 'used', 0
dmsg_09			db 'current dictionary', 10, 0
dmsg_10			db '  %2u: type %u, val 0x%x', 10, 0

%endif

single_step		db 0
show_debug_info		db 0
dtrace_count		db 0

fms_cpio_swab		db 0

hello			db 10, 'Initializing gfx code...', 10, 0
msg_10			db 0b3h, 'ip %4x:  %8x.%x           ', 0b3h, 10, 0
msg_11			db 0b3h, '%2x: %8x.%2x', 0
msg_12			db 0b3h, '  :            ', 0
msg_13			db 0dah, 0c4h, 0c4h, 0c4h, 0c4h, 'data'
			times 7 db 0c4h
			db 0c2h, 0c4h, 0c4h, 0c4h, 0c4h, 'prog'
			times 7 db 0c4h
			db 0bfh, 10, 0
msg_14			db 0c3h
			times 15 db 0c4h
			db 0c1h
			times 15 db 0c4h
			db 0b4h, 10, 0
msg_15			db 0c0h
			times 31 db 0c4h
			db 0d9h, 10, 0
msg_16			db 0b3h, 10, 0
msg_17			db 0b3h, 'err %3x                        ', 0b3h, 10, 0 
msg_18			db 0b3h, 'err %3x: %8x              ', 0b3h, 10, 0
msg_19			db 0b3h, 'err %3x: %8x   %8x   ', 0b3h, 10, 0
msg_20			db 0b3h, 'ip %4x: %8x.%x %8x.%x ', 0b3h, 10, 0
msg_21			db 0b3h, '%S', 0b3h, 10, 0 

			align 2, db 0
			; prim_function entries
			prim_jump_table

; menu entry descriptor
menu_entries		equ 0
menu_default		equ 2		; seg:ofs
menu_ent_list		equ 6		; seg:ofs
menu_ent_size		equ 10
menu_arg_list		equ 12		; seg:ofs
menu_arg_size		equ 16
sizeof_menu_desc	equ 18

; framebuffer mode list
fb_mode			equ 0		; word
fb_width		equ 2		; word
fb_height		equ 4		; word, must follow fb_width
fb_bits			equ 6		; byte
fb_ok			equ 7		; monitor supports it
sizeof_fb_entry		equ 8

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Some macros.
;
%macro		pf_arg_uchar 2
		and dword [tmp_write_data + %1 * 4],byte 0
		mov [tmp_write_data + %1 * 4],%2
%endmacro


%macro		pf_arg_ushort 2
		and word [tmp_write_data + %1 * 4 + 2],byte 0
		mov [tmp_write_data + %1 * 4],%2
%endmacro


%macro		pf_arg_uint 2
		mov [tmp_write_data + %1 * 4],%2
%endmacro


%macro		pf_arg_char 2
		push eax
		movsx eax,%2
		mov [tmp_write_data + %1 * 4],eax
		pop eax
%endmacro


%macro		pf_arg_short 2
		push eax
		movsx eax,%2
		mov [tmp_write_data + %1 * 4],eax
		pop eax
%endmacro


%macro		pf_arg_int 2
		mov [tmp_write_data + %1 * 4],%2
%endmacro


%macro		pm_enter 0
%%j_pm_1:
		call switch_to_pm
%%j_pm_2:
		%if %%j_pm_2 - %%j_pm_1 != 3
		  %error "pm_enter: not in 16 bit mode"
		%endif

		bits 32
%endmacro


%macro		pm_leave 0
%%j_pm_1:
		call switch_to_rm
%%j_pm_2:
		%if %%j_pm_2 - %%j_pm_1 != 5
		  %error "pm_leave: not in 32 bit mode"
		%endif

		bits 16
%endmacro


%macro		gfx_enter 0
		call gfx_enter
		bits 32
%endmacro


%macro		gfx_leave 0
		call gfx_leave
		bits 16
%endmacro


%macro		rm32_call 1
		pm_leave
		call %1
		pm_enter
%endmacro


%macro		pm32_call 1
		pm_enter
		call %1
		pm_leave
%endmacro


%macro          wait32 0
		pushf
		push ecx
		push eax
                mov ecx,10000000
%%wait32_10:
                in al,80h
                loop %%wait32_10
                pop eax
                pop ecx
                popf
%endmacro

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Interface functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Setup internal data structures.
;
; esi		sysconfig data
;
; return:
;  CF		error
;

		bits 16

gfx_init:
		; don't change stack layout - see gfx_enter
		push fs
		push es
		push ds

		push cs
		pop ds

		cld

		mov [boot.sysconfig],esi

		; setup gdt, to get pm-switching going
		call gdt_init

		; we can run in protected mode but can't handle ints until
		; after pm_init
		cli

		pm_enter

		mov esi,[boot.sysconfig]
		movzx eax,word [es:esi+sc.bootloader_seg]
		shl eax,4
		mov [boot.base],eax

		push dword [es:esi+sc.file]
		pop dword [file.start]
		push dword [es:esi+sc.archive_start]
		pop dword [archive.start]
		push dword [es:esi+sc.archive_end]
		pop dword [archive.end]
		push dword [es:esi+sc.mem0_start]
		pop dword [mem0.start]
		push dword [es:esi+sc.mem0_end]
		pop dword [mem0.end]

		mov eax,[es:esi+sc.callback]
		or ax,ax				; check only offset
		jz gfx_init_20
		mov [boot.callback],eax
gfx_init_20:

		; init malloc memory chain

		push dword [mem0.start]
		pop dword [malloc.area]
		push dword [mem0.end]
		pop dword [malloc.area+4]

		mov ebx,[boot.sysconfig]
		mov esi,malloc.area+8
		mov ecx,malloc.areas-1			; extended mem areas
gfx_init_30:
		movzx eax,word [es:ebx+sc.xmem_0]	; extended mem area pointer
		or eax,eax
		jz gfx_init_40
		mov edx,eax
		and dl,~0fh
		shl edx,16

		and eax,0fh
		shl eax,20
		add eax,edx
		mov [esi+4],eax

		; magic: if archive was loaded in high memory, exclude it
		cmp edx,[archive.start]
		jnz gfx_init_35
		mov edx,[archive.end]
gfx_init_35:
		mov [esi],edx

		add esi,8
		add ebx,2
		dec ecx
		jnz gfx_init_30

gfx_init_40:
		call malloc_init

		; setup full pm interface
		; can't do it earlier - we need malloc
		call pm_init

		; allocate 8k local stack

		mov eax,8 << 10
		mov [stack.size],eax
		add eax,3
		call calloc
		; dword align
		add eax,3
		and eax,~3
		jnz gfx_init_50
		cmp eax,100000h		; must be low memory
		jb gfx_init_50
		; malloc failed - keep stack
		push word [rm_seg.ss]
		pop word [local_stack.seg]
		mov eax,esp
		mov [local_stack.ofs],eax
		jmp gfx_init_51
gfx_init_50:
		mov edx,eax
		and eax,0fh
		add eax,[stack.size]
		mov [local_stack.ofs],eax
		shr edx,4
		mov [local_stack.seg],dx

gfx_init_51:

		; now we really start...
		pm_leave

		sti
		call use_local_stack

		pm_enter

		mov esi,hello
		call printf

		; get initial keyboard state
		push word [es:417h]
		pop word [kbd_status]

		mov eax,[boot.sysconfig]
		mov al,[es:eax+sc.failsafe]
		test al,1
		jz gfx_init_58

		xor ebx,ebx

gfx_init_55:
		pf_arg_uchar 0,bl
		mov eax,[malloc.area+8*ebx]
		pf_arg_uint 1,eax
		mov eax,[malloc.area+8*ebx+4]
		pf_arg_uint 2,eax

		or eax,eax
		jz gfx_init_57

		push ebx
		mov esi,dmsg_02
		call printf
		pop ebx

		inc ebx
		cmp ebx,malloc.areas
		jb gfx_init_55

gfx_init_57:

		mov esi,dmsg_01
		call printf
		call get_key

gfx_init_58:

		; alloc memory for palette data
		call pal_init
		jc gfx_init_90

		mov eax,200h
		call calloc
		cmp eax,1
		jc gfx_init_90
		mov [vbe_buffer],eax

		mov eax,100h
		call calloc
		cmp eax,1
		jc gfx_init_90
		mov [vbe_info_buffer],eax

		; those must be low memory addresses:
		mov eax,[gfx_pal_tmp]
		or eax,[vbe_buffer]
		or eax,[vbe_info_buffer]
		cmp eax,100000h
		cmc
		jc gfx_init_90

		call dict_init
		jc gfx_init_90

		call stack_init
		jc gfx_init_90

		mov eax,[file.start]
		mov esi,eax
		add eax,[es:esi+fh_code]
		mov [pscode_start],eax
		mov eax,[es:esi+fh_code_size]
		mov [pscode_size],eax

		; now the ps interpreter is ready to run

		; jpg decoding buffer
		call jpg_setup
		jc gfx_init_90

		mov eax,100h
		call calloc
		cmp eax,1
		jc gfx_init_90
		mov [infobox_buffer],eax

		mov eax,200h
		call calloc
		cmp eax,1
		jc gfx_init_90
		mov [vbe_mode_list],eax

		; fill list
		call get_vbe_modes

		; get console font
		call cfont_init

		; ok, we've done it, now continue the setup

		mov eax,[boot.sysconfig]
		mov al,[es:eax+sc.failsafe]
		test al,1
		jz gfx_init_59

		call dump_malloc
		mov esi,dmsg_01
		call printf
		call get_key

gfx_init_59:

		; run global code
		xor eax,eax
		mov [pstack.ptr],eax
		mov [rstack.ptr],eax
		call run_pscode
		jc gfx_init_60

		; check for true/false on stack
		; (empty stack == true)

		xor ecx,ecx
		call get_pstack_tos
		cmc
		jnc gfx_init_90
		cmp dl,t_bool
		jnz gfx_init_70
		cmp eax,1
		jz gfx_init_90
		jmp gfx_init_70

gfx_init_60:
		call ps_status_info
		call get_key
gfx_init_70:
		call gfx_done_pm
		stc

gfx_init_90:
		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Finish gfx code.
;

		bits 16

gfx_done:
		gfx_enter

		call gfx_done_pm

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

gfx_done_pm:
		call sound_done

		cmp byte [keep_mode],0
		jnz gfx_done_pm_90
		mov ax,3
		int 10h
gfx_done_pm_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Input a text line.
;
; edi		buffer (0: no buffer)
; ecx		buffer size
; eax		timeout value (0: no timeout)
;
; return:
;  eax		action (1, 2: textmode, boot)
;  ebx		selected menu entry (-1: none)
;

		bits 16

gfx_input:
		gfx_enter

		push edi
		push ecx

		cmp byte [input_notimeout],0
		jnz gfx_input_10
		mov [input_timeout],eax
		mov [input_timeout_start],eax
gfx_input_10:

		call clear_kbd_queue

gfx_input_20:
		call get_key_to
		and dword [input_timeout],0		; disable timeout

		push eax
		mov ecx,cb_KeyEvent
		call get_dict_entry
		pop ecx
		jc gfx_input_90

		cmp dl,t_code
		stc
		jnz gfx_input_90

		push eax
		mov eax,ecx
		mov dword [pstack.ptr],1
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos
		pop eax

		call run_pscode
		jnc gfx_input_50

		call ps_status_info
		call get_key
		stc
		jmp gfx_input_90

gfx_input_50:
		mov ecx,2
		call get_pstack_tos
		jc gfx_input_90
		cmp dl,t_string
		stc
		jnz gfx_input_90

		pop ecx
		pop edi
		push edi
		push ecx

		or edi,edi
		jz gfx_input_70
		or ecx,ecx
		jz gfx_input_70

		mov esi,eax
gfx_input_60:
		es lodsb
		stosb
		or al,al
		loopnz gfx_input_60
		mov byte [es:edi-1],0

gfx_input_70:
		mov ecx,1
		call get_pstack_tos
		jc gfx_input_90
		cmp dl,t_int
		stc
		jnz gfx_input_90

		xor ecx,ecx
		push eax
		call get_pstack_tos
		pop ebx
		jc gfx_input_90
		cmp dl,t_int
		stc
		jnz gfx_input_90

		or eax,eax
		jz gfx_input_20

gfx_input_90:

		pop ecx
		pop edi

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Setup boot menu entries.
;
; esi		menu description
;

		bits 16

gfx_menu_init:
		gfx_enter

		push esi
		movzx eax,word [es:esi+menu_entries]
		push eax
		lea eax,[eax+4*eax+2]
		push eax
		call calloc
		mov [tmp_var_2],eax
		pop eax
		call calloc
		mov [tmp_var_1],eax
		pop ecx
		pop esi
		or eax,eax
		jz gfx_menu_init_90
		cmp dword [tmp_var_1],0
		jz gfx_menu_init_90

		push ecx

		mov ebx,[tmp_var_1]
		mov [es:ebx],cx
		add ebx,2
		movzx eax,word [es:esi+menu_ent_list]
		movzx edi,word [es:esi+menu_ent_list+2]
		shl edi,4
		add edi,eax
gfx_menu_init_40:
		mov byte [es:ebx],t_string
		mov [es:ebx+1],edi
		add ebx,5
		movzx eax,word [es:esi+menu_ent_size]
		add edi,eax
		loop gfx_menu_init_40

		pop ecx

		mov ebx,[tmp_var_2]
		mov [es:ebx],cx
		add ebx,2

		movzx eax,word [es:esi+menu_arg_list]
		movzx edi,word [es:esi+menu_arg_list+2]
		shl edi,4
		add edi,eax
gfx_menu_init_50:
		mov byte [es:ebx],t_string
		mov [es:ebx+1],edi
		add ebx,5
		movzx eax,word [es:esi+menu_arg_size]
		add edi,eax
		loop gfx_menu_init_50

		movzx eax,word [es:esi+menu_default]
		movzx edi,word [es:esi+menu_default+2]
		shl edi,4
		add eax,edi
		mov [tmp_var_3],eax

		mov ecx,cb_MenuInit
		call get_dict_entry
		jc gfx_menu_init_90

		cmp dl,t_code
		stc
		jnz gfx_menu_init_90

		push eax

		mov dword [pstack.ptr],3

		mov eax,[tmp_var_1]
		mov dl,t_array
		mov ecx,2
		call set_pstack_tos

		mov eax,[tmp_var_2]
		mov dl,t_array
		mov ecx,1
		call set_pstack_tos

		mov eax,[tmp_var_3]
		mov dl,t_string
		xor ecx,ecx
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax

		call run_pscode
		jnc gfx_menu_init_90

		call ps_status_info
		call get_key
		stc

gfx_menu_init_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Show info box.
;
; esi		info text 1
; edi		info text 2	(0: no text 2)
; al		0/1	info/error
;

		bits 16

gfx_infobox_init:
		gfx_enter

		push eax

		mov ecx,100h-1
		mov ebx,[infobox_buffer]

		or esi,esi
		jnz gfx_infobox_init_20
		inc ebx
		jmp gfx_infobox_init_40
gfx_infobox_init_20:
		es lodsb
		mov [es:ebx],al
		inc ebx
		or al,al
		loopnz gfx_infobox_init_20
		or ecx,ecx
		jz gfx_infobox_init_40

		mov esi,edi
		or esi,esi
		jz gfx_infobox_init_40
		inc ecx
		dec ebx
gfx_infobox_init_25:
		es lodsb
		mov [es:ebx],al
		inc ebx
		or al,al
		loopnz gfx_infobox_init_25
gfx_infobox_init_40:
		mov byte [es:ebx-1],0

		mov ecx,cb_InfoBoxInit
		call get_dict_entry

		pop ebx

		jc gfx_infobox_init_90

		cmp dl,t_code
		stc
		jnz gfx_infobox_init_90

		push eax

		mov dword [pstack.ptr],2

		movzx eax,bl
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos

		mov eax,[infobox_buffer]
		mov dl,t_string
		mov ecx,1
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc gfx_infobox_init_90

		call ps_status_info
		call get_key
		stc

gfx_infobox_init_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Close info box.
;

		bits 16

gfx_infobox_done:
		gfx_enter

		mov ecx,cb_InfoBoxDone
		call get_dict_entry
		jc gfx_infobox_done_90

		cmp dl,t_code
		stc
		jnz gfx_infobox_done_90

		push eax
		mov dword [pstack.ptr],0
		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc gfx_infobox_done_90

		call ps_status_info
		call get_key
		stc

gfx_infobox_done_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Setup progress bar window.
;
; eax		max
; esi		kernel name
;

		bits 16

gfx_progress_init:
		gfx_enter

		mov [progress_max],eax
		and dword [progress_current],0

		mov ecx,cb_ProgressInit
		push esi
		call get_dict_entry
		pop esi
		jc gfx_progress_init_90

		cmp dl,t_code
		stc
		jnz gfx_progress_init_90

		push eax
		mov dword [pstack.ptr],1

		mov eax,esi
		mov dl,t_string
		xor ecx,ecx
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc gfx_progress_init_90

		call ps_status_info
		call get_key
		stc

gfx_progress_init_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Close progress bar window.
;

		bits 16

gfx_progress_done:
		gfx_enter

		mov ecx,cb_ProgressDone
		call get_dict_entry
		jc gfx_progress_done_90

		cmp dl,t_code
		stc
		jnz gfx_progress_done_90

		push eax
		mov dword [pstack.ptr],0
		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc gfx_progress_done_90

		call ps_status_info
		call get_key
		stc

gfx_progress_done_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Advance progress bar.
;

		bits 16

gfx_progress_update:
		gfx_enter

		add [progress_current],eax

		mov ecx,cb_ProgressUpdate
		call get_dict_entry
		jc gfx_progress_update_90

		cmp dl,t_code
		stc
		jnz gfx_progress_update_90

		push eax
		mov dword [pstack.ptr],2

		mov eax,[progress_current]
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos

		mov eax,[progress_max]
		mov dl,t_int
		mov ecx,1
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc gfx_progress_update_90

		call ps_status_info
		call get_key
		stc

gfx_progress_update_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set progress bar values.
;

		bits 16

gfx_progress_limit:
		gfx_enter

		mov [progress_max],eax
		mov [progress_current],edx

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Setup password window.
;
; esi		password
; edi		image name
;

		bits 16

gfx_password_init:
		gfx_enter

		mov ecx,cb_PasswordInit
		push esi
		push edi
		call get_dict_entry
		pop edi
		pop esi
		jc gfx_password_init_90

		cmp dl,t_code
		stc
		jnz gfx_password_init_90

		push eax

		mov dword [pstack.ptr],2

		mov eax,esi
		mov dl,t_string
		xor ecx,ecx
		push edi
		call set_pstack_tos
		pop edi

		mov eax,edi
		mov dl,t_string
		mov ecx,1
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc gfx_password_init_90

gfx_password_init_80:
		call ps_status_info
		call get_key
		stc

gfx_password_init_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Close password window.
;
; esi		password
;

		bits 16

gfx_password_done:
		gfx_enter

		mov ecx,cb_PasswordDone
		push esi
		call get_dict_entry
		pop esi
		jc gfx_password_done_90

		cmp dl,t_code
		stc
		jnz gfx_password_done_90

		push eax

		mov dword [pstack.ptr],1

		mov eax,esi
		mov dl,t_string
		xor ecx,ecx
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jc gfx_password_done_80

		xor ecx,ecx
		call get_pstack_tos
		jc gfx_password_done_90
		cmp dl,t_bool
		stc
		jnz gfx_password_done_90

		cmp eax,1
		jmp gfx_password_done_90

gfx_password_done_80:
		call ps_status_info
		call get_key
		stc

gfx_password_done_90:

		gfx_leave		; does not return


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Save segment regs, use our own stack, and switch to pm.
;

		bits 16

gfx_enter:
		pop word [cs:tmp_var_0]

		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		pm_enter

		jmp word [tmp_var_0]


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Switch to rm, switch back to boot loader stack, restore segment regs and leave.
;
; Note: function does not return.
;

		bits 32

gfx_leave:
		pm_leave

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Run boot loader function.
;
; al		function number
;
; return:
;  al		error code (0 = ok)
;

		bits 32

gfx_cb:
		cmp dword [boot.callback],0
		jz gfx_cb_80
		pm_leave
		push ds
		call far [boot.callback]
		pop ds
		pm_enter
		jmp gfx_cb_90
gfx_cb_80:
		mov al,0ffh
gfx_cb_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Internal functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 32

timeout:
		mov ecx,cb_Timeout
		call get_dict_entry
		jc timeout_90

		cmp dl,t_code
		stc
		jnz timeout_90

		push eax
		mov dword [pstack.ptr],2

		mov ecx,1
		mov dl,t_int
		mov eax,[input_timeout_start]
		call set_pstack_tos

		xor ecx,ecx
		mov dl,t_int
		mov eax,[input_timeout]
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc timeout_90

		call ps_status_info
		call get_key
		stc

timeout_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Run 'Timer' callback function.
;
; eax		time
;

		bits 32

timer:
		mov ecx,cb_Timer
		push eax
		call get_dict_entry
		pop ebx
		jc timer_90

		cmp dl,t_code
		stc
		jnz timer_90

		push eax
		mov dword [pstack.ptr],1

		xor ecx,ecx
		mov dl,t_int
		mov eax,ebx
		call set_pstack_tos

		mov dword [rstack.ptr],1
		xor ecx,ecx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jnc timer_90

		call ps_status_info
		call get_key
		stc

timer_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Initialize parameter & return stack.
;
; return:
;  CF		error
;

		bits 32

stack_init:
		mov dword [pstack.size],param_stack_size
		and dword [pstack.ptr],0
		mov eax,param_stack_size * 5
		call calloc
		cmp eax,1
		jc stack_init_90
		mov [pstack],eax

		mov dword [rstack.size],ret_stack_size
		and dword [rstack.ptr],0
		mov eax,ret_stack_size * 5
		call calloc
		cmp eax,1
		jc stack_init_90
		mov [rstack],eax

stack_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Rotate pstack up (ecx-1'th element becomes tos).
;
;  ecx		values to rotate (counted from tos)
;
; return:
;  CF		error
;

		bits 32

rot_pstack_up:
		or ecx,ecx
		jz rot_pstack_up_90
		mov edi,[pstack]
		mov eax,[pstack.ptr]
		sub eax,ecx
		jb rot_pstack_up_90
		cmp ecx,1
		jz rot_pstack_up_90
		add edi,eax
		shl eax,2
		add edi,eax
		dec ecx
		mov eax,ecx
		shl eax,2
		add ecx,eax
		mov ebx,[es:edi]
		mov dl,[es:edi+4]
		lea esi,[edi+5]
		es rep movsb
		mov [es:edi],ebx
		mov [es:edi+4],dl
		clc
rot_pstack_up_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Rotate pstack down (1st element becomes tos).
;
;  ecx		values to rotate (counted from tos)
;
; return:
;  CF		error
;

		bits 32

rot_pstack_down:
		or ecx,ecx
		jz rot_pstack_down_90
		mov edi,[pstack]
		mov eax,[pstack.ptr]
		cmp eax,ecx
		jb rot_pstack_down_90
		cmp ecx,1
		jz rot_pstack_down_90
		add edi,eax
		shl eax,2
		add edi,eax
		dec edi
		lea esi,[edi-5]
		dec ecx
		mov eax,ecx
		shl eax,2
		add ecx,eax
		mov ebx,[es:esi+1]
		mov dl,[es:esi+5]
		std
		es rep movsb
		cld
		mov [es:esi+1],ebx
		mov [es:esi+5],dl
		clc
rot_pstack_down_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read pstack entry.
;
;  ecx		index
;
; return:
;  eax		value
;  dl		type
;  ecx		index
;  CF		error
;

		bits 32

get_pstack_entry:
		xor eax,eax
		mov dl,al
		cmp [pstack.size],ecx
		jb get_pstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[pstack]
		mov dl,[es:ebx]
		mov eax,[es:ebx+1]
		clc
get_pstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write pstack entry.
;
;  ecx		index
;  eax		value
;  dl		type
;
; return:
;  ecx		index
;  CF		error
;

		bits 32

set_pstack_entry:
		cmp [pstack.size],ecx
		jb set_pstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[pstack]
		mov [es:ebx],dl
		mov [es:ebx+1],eax
		clc
set_pstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read pstack tos (no pop).
;
;  ecx		index (rel. to tos, 0 = tos)
;
; return:
;  eax		value
;  dl		type
;  ecx		index (absolute)
;  CF		error
;

		bits 32

get_pstack_tos:
		mov eax,[pstack.ptr]
		sub eax,1
		jc get_pstack_tos_90
		sub eax,ecx
		jc get_pstack_tos_90
		xchg eax,ecx
		call get_pstack_entry
get_pstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write pstack tos (no push).
;
;  ecx		index (rel. to tos, 0 = tos)
;  eax		value
;  dl		type
;
; return:
;  ecx		index (absolute)
;  CF		error
;

		bits 32

set_pstack_tos:
		mov ebx,[pstack.ptr]
		sub ebx,1
		jc set_pstack_tos_90
		sub ebx,ecx
		jc set_pstack_tos_90
		xchg ebx,ecx
		call set_pstack_entry
set_pstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read rstack entry.
;
;  ecx		index
;
; return:
;  eax		value
;  dl		type
;  ecx		index
;  CF		error
;

		bits 32

get_rstack_entry:
		xor eax,eax
		mov dl,al
		cmp [rstack.size],ecx
		jb get_rstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[rstack]
		mov dl,[es:ebx]
		mov eax,[es:ebx+1]
		clc
get_rstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write rstack entry.
;
;  ecx		index
;  eax		value
;  dl		type
;
; return:
;  ecx		index
;  CF		error
;

		bits 32

set_rstack_entry:
		cmp [rstack.size],ecx
		jb set_rstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[rstack]
		mov [es:ebx],dl
		mov [es:ebx+1],eax
		clc
set_rstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read rstack tos (no pop).
;
;  ecx		index (rel. to tos, 0 = tos)
;
; return:
;  eax		value
;  dl		type
;  ecx		index (absolute)
;  CF		error
;

		bits 32

get_rstack_tos:
		mov eax,[rstack.ptr]
		sub eax,1
		jc get_rstack_tos_90
		sub eax,ecx
		jc get_rstack_tos_90
		xchg eax,ecx
		call get_rstack_entry
get_rstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write rstack tos (no push).
;
;  ecx		index (rel. to tos, 0 = tos)
;  eax		value
;  dl		type
;
; return:
;  ecx		index (absolute)
;  CF		error
;

		bits 32

set_rstack_tos:
		mov ebx,[rstack.ptr]
		sub ebx,1
		jc set_rstack_tos_90
		sub ebx,ecx
		jc set_rstack_tos_90
		xchg ebx,ecx
		call set_rstack_entry
set_rstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Setup initial dictionary.
;
; return:
;  CF		error
;

		bits 32

dict_init:
		mov eax,[file.start]

		mov ecx,[es:eax+fh_dict]
		cmp ecx,1
		jc dict_init_90
		add eax,ecx

		mov esi,eax

		xor eax,eax
		es lodsw
		mov [dict.size],ax

		; p_none is not part of the default dict
		cmp ax,cb_functions + prim_functions - 1
		jb dict_init_90

		lea eax,[eax+eax*4]

		push esi
		call calloc
		pop esi
		cmp eax,1
		jc dict_init_90
		mov [dict],eax

		; add default functions

		add eax,cb_functions * 5
		xor ecx,ecx
		inc ecx
dict_init_20:
		mov byte [es:eax],t_prim
		mov [es:eax+1],ecx
		add eax,5
		inc ecx
		cmp ecx,prim_functions
		jb dict_init_20

		; add user defined things

		xor eax,eax
		es lodsw
		or eax,eax
		jz dict_init_80
		cmp [dict.size],eax
		jb dict_init_90

		mov ebx,[dict]

		xchg eax,ecx
dict_init_50:
		xor eax,eax
		es lodsw
		cmp eax,[dict.size]
		cmc
		jc dict_init_90
		lea edi,[eax+eax*4]
		es lodsb
		mov [fs:ebx+edi],al
		es lodsd
		mov [fs:ebx+edi+1],eax
		dec ecx
		jnz dict_init_50

dict_init_80:
		clc
dict_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Dump dictionary to console.
;
; Currently unused.
;
%if 0

		bits 32

dump_dict:
		mov esi,dmsg_09
		call printf

		xor ecx,ecx
dump_dict_20:
		call get_dict_entry
		jc dump_dict_90
		pf_arg_uint 0,ecx
		pf_arg_uchar 1,dl
		pf_arg_uint 2,eax
		mov esi,dmsg_10
		pusha
		call printf
		popa

		inc ecx
		cmp ecx,[dict.size]
		jb dump_dict_20
dump_dict_90:
		ret

%endif


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read a dictionary entry.
;
;  ecx		index
;
; return:
;  eax		value
;  dl		type
;  ecx		index
;  CF		error
;

		bits 32

get_dict_entry:
		xor eax,eax
		mov dl,al
		cmp [dict.size],ecx
		jb get_dict_entry_90
		lea eax,[ecx+4*ecx]		; dict entry size = 5
		add eax,[dict]
		mov dl,[es:eax]
		mov eax,[es:eax+1]
get_dict_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write a dictionary entry.
;
;  ecx		index
;  eax		value
;  dl		type
;
; return:
;  ecx		index
;  CF		error
;

		bits 32

set_dict_entry:
		cmp [dict.size],ecx
		jb set_dict_entry_90
		lea ebx,[ecx+4*ecx]
		add ebx,[dict]
		mov [es:ebx],dl
		mov [es:ebx+1],eax
set_dict_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Init malloc areas.
;
; idt is not ready yet - hence the cli.
;

		bits 32

malloc_init:
		xor ebx,ebx
malloc_init_10:
		mov eax,[malloc.area + bx]
		mov edx,[malloc.area + bx + 4]
		cmp eax,edx
		jz malloc_init_70

		cmp edx,eax
		jnb malloc_init_30

malloc_init_20:
		; we can't access it
		xor eax,eax
		mov [malloc.area + bx],eax
		mov [malloc.area + bx + 4],eax
		jmp malloc_init_70

malloc_init_30:
		mov esi,eax

		sub edx,eax
		xor eax,eax
		mov [es:esi + mhead.memsize],edx
		mov [es:esi + mhead.ip],eax
		mov [es:esi + mhead.used],al

		; just check we can really write there
		cmp [es:esi + mhead.memsize],edx
		jnz malloc_init_20
malloc_init_70:
		add bx,8
		cmp bx,malloc.areas * 8
		jb malloc_init_10
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get some memory.
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if the request failed)
;  memory is initialized with 0
;

		bits 32

calloc:
		push eax
		call malloc
		pop ecx
calloc_10:
		or eax,eax
		jz calloc_90
		push eax
		mov edi,eax
		xor al,al
		rep stosb
		pop eax
calloc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get some memory (taken from extended memory, if possible).
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if the request failed)
;  memory is initialized with 0
;

		bits 32

xcalloc:
		mov bx,8		; start with mem area 1

		push eax
		call malloc_10
		pop ecx

		or eax,eax
		jnz calloc_10

		mov eax,ecx
		jmp calloc


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get some memory.
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if request failed)
;

		bits 32

malloc:
		xor bx,bx

malloc_10:
		mov ecx,[malloc.area + bx]
		mov edx,[malloc.area + 4 + bx]

		mov [malloc.start],ecx
		mov [malloc.end],edx

		cmp edx,ecx
		jz malloc_70

		push ebx
		push eax
		call _malloc
		pop edx
		pop ebx

		or eax,eax
		jnz malloc_90

		mov eax,edx

malloc_70:
		add bx,8
		cmp bx,malloc.areas * 8
		jb malloc_10

		xor eax,eax

malloc_90:
		ret

_malloc:
		xor ebp,ebp
		or eax,eax
		jz _malloc_90
		add eax,mhead.size
		mov ebx,[malloc.start]

_malloc_20:
		mov esi,ebx
		mov ecx,[es:esi + mhead.memsize]
		test byte [es:esi + mhead.used],80h
		jnz _malloc_70
		cmp ecx,eax
		jb _malloc_70
		; mark as occupied
		mov byte [es:esi + mhead.used],80h
		push dword [pscode_instr]
		pop dword [es:esi + mhead.ip]
		lea ebp,[ebx + mhead.size]
		mov edx,ecx
		sub edx,eax
		cmp edx,mhead.size
		ja _malloc_60

		add [es:esi + mhead.rem],dl

		jmp _malloc_90

_malloc_60:
		mov [es:esi + mhead.memsize],eax
		add ebx,eax
		mov esi,ebx
		mov [es:esi + mhead.memsize],edx
		xor edx,edx
		mov byte [es:esi + mhead.used],dl
		mov [es:esi + mhead.ip],edx
		
		jmp _malloc_90
_malloc_70:
		add ebx,ecx
		cmp ebx,[malloc.end]
		jb _malloc_20
_malloc_90:
		xchg ebp,eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Free memory.
;
;  eax          linear address
;

		bits 32

free:
		xor bx,bx

free_10:
		mov ecx,[malloc.area + bx]
		mov edx,[malloc.area + 4 + bx]

		cmp eax,ecx
		jb free_70
		cmp eax,edx
		jae free_70

		mov [malloc.start],ecx
		mov [malloc.end],edx

		jmp _free

free_70:
		add bx,8
		cmp bx,malloc.areas * 8
		jb free_10
free_90:
		ret


_free:
		or eax,eax
		jz _free_90

		sub eax,mhead.size

		mov ebx,[malloc.start]
		mov ecx,ebx
_free_10:
		cmp eax,ebx
		jnz _free_70

		test byte [es:ebx + mhead.used],80h
		jz _free_90

		cmp ecx,ebx				; first block?
		jz _free_30

		test byte [es:ecx + mhead.used],80h
		jnz _free_30				; prev block is used

		; prev block is free -> join them
		mov edx,[es:ecx + mhead.memsize]

		add edx,[es:ebx + mhead.memsize]

		mov [es:ecx],edx
		mov ebx,ecx

_free_30:
		mov edx,ebx
		mov byte [es:ebx + mhead.used],0	; mark block as free
		add edx,[es:ebx + mhead.memsize]
		cmp edx,[malloc.end]			; last block?
		jae _free_90

		test byte [es:edx + mhead.used],80h
		jnz _free_90				; next block is used

		; next block is free -> join them
		mov edx,[es:edx + mhead.memsize]

		add [es:ebx + mhead.memsize],edx
		jmp _free_90

_free_70:
		mov ecx,ebx
		add ebx,[es:ebx]
		cmp ebx,[malloc.end]
		jb _free_10
_free_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Dump memory chain.
;

		bits 32

dump_malloc:
		pushad

		xor edx,edx
		call con_xy

		xor ebx,ebx
		xor ebp,ebp

dump_malloc_10:
		mov ecx,[malloc.area + bx]
		mov edx,[malloc.area + 4 + bx]

		mov [malloc.start],ecx
		mov [malloc.end],edx

		cmp ecx,edx
		jz dump_malloc_70

		push ebx
		call _dump_malloc
		pop ebx

dump_malloc_70:
		add ebx,8
		cmp ebx,malloc.areas * 8
		jb dump_malloc_10
dump_malloc_90:

		popad
		ret

_dump_malloc:
		mov ebx,[malloc.start]

_dump_malloc_30:
		mov esi,ebx
		mov ecx,[es:esi + mhead.memsize]

		pushad
		mov ax,dmsg_07
		test byte [es:esi + mhead.used],80h
		jz _dump_malloc_40
		mov ax,dmsg_08
_dump_malloc_40:
		pf_arg_ushort 5,ax
		pf_arg_ushort 0,bp
		sub ecx,mhead.size
		movzx eax,byte [es:esi + mhead.rem]
		and al,7fh
		sub ecx,eax
		pf_arg_uint 1,ebx
		pf_arg_uint 2,ecx
		pf_arg_uchar 3,al
		mov eax,[es:esi + mhead.ip]
		pf_arg_uint 4,eax
		mov esi,dmsg_03

		call printf
		popad

		inc ebp
		test ebp,01fh
		jnz _dump_malloc_60
		pushad
		call get_key
		xor edx,edx
		call con_xy
		popad
_dump_malloc_60:		

		mov esi,dmsg_04
		cmp ecx,mhead.size
		jbe _dump_malloc_70

		add ebx,ecx
		cmp ebx,[malloc.end]
		jz _dump_malloc_90
		jb _dump_malloc_30

		mov ecx,[malloc.end]
		mov esi,dmsg_04a

_dump_malloc_70:
		pf_arg_uint 0,ebx
		pf_arg_uint 1,ecx
_dump_malloc_80:

		push ebp
		call printf
		pop ebp
_dump_malloc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get memory size.
;
;  eax		memory area (0 ... malloc.areas - 1)
;
; return:
;  ebp		total free memory
;  edi		largest free block
;

		bits 32

memsize:
		xor ebp,ebp
		xor edi,edi

		cmp eax,malloc.areas
		jae memsize_90

		imul bx,ax,8

		mov ecx,[malloc.area + bx]
		mov edx,[malloc.area + 4 + bx]

		mov [malloc.start],ecx
		mov [malloc.end],edx

		cmp ecx,edx
		jz memsize_90

		call _memsize

memsize_90:
		ret


_memsize:
		mov ebx,[malloc.start]
_memsize_30:
		mov ecx,[es:ebx + mhead.memsize]
		cmp ecx,mhead.size
		jb _memsize_90

		test byte [es:ebx + mhead.used],80h
		jnz _memsize_50

		mov eax,ecx
		sub eax,mhead.size
		add ebp,eax
		cmp eax,edi
		jb _memsize_50
		mov edi,eax
_memsize_50:
		add ebx,ecx
		cmp ebx,[malloc.end]
		jb _memsize_30
_memsize_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Calculate size of memory block.
;
; eax		address
;
; return:
;  eax		size
;

		bits 32

find_mem_size:
		call fms_code
		jnc find_mem_size_90

		call fms_malloc
		jnc find_mem_size_90

		call fms_file
		jnc find_mem_size_90

		; some other area

		xor eax,eax

find_mem_size_90:
		ret


; string constants in ps code
fms_code:
		mov edx,[pscode_start]
		cmp eax,edx
		jc fms_code_90
		add edx,[pscode_size]
		cmp eax,edx
		cmc
		jc fms_code_90

		mov edi,eax
		xor ecx,ecx
		dec ecx
		sub ecx,edi
		mov edx,ecx
		xor eax,eax
		repnz scasb
		jnz fms_code_80
		sub edx,ecx
		mov eax,edx
fms_code_80:
		clc
fms_code_90:
		ret


; check malloc areas
fms_malloc:
		xor ebx,ebx
fms_malloc_10:
		mov ecx,[malloc.area + bx]
		mov edx,[malloc.area + 4 + bx]

		cmp eax,ecx
		jb fms_malloc_20
		cmp eax,edx
		jae fms_malloc_20

		mov [malloc.start],ecx
		mov [malloc.end],edx

		jmp fms_malloc_30
fms_malloc_20:
		add ebx,8
		cmp ebx,malloc.areas * 8
		jb fms_malloc_10

		stc

		jmp fms_malloc_90

fms_malloc_30:

		cmp eax,[malloc.start]
		jc fms_malloc_90
		cmp eax,[malloc.end]
		cmc
		jc fms_malloc_90

		mov ebx,[malloc.start]

fms_malloc_40:
		mov ecx,[es:ebx + mhead.memsize]
		lea edx,[ebx+ecx]

		cmp eax,edx
		jae fms_malloc_50

		test byte [es:ebx + mhead.used],80h
		jz fms_malloc_70		; free

		sub eax,ebx
		cmp eax,mhead.size
		jb fms_malloc_70		; within header

		mov dl,[es:ebx + mhead.rem]
		and edx,7fh

		add eax,edx
		sub ecx,eax
		jb fms_malloc_70		; in reserved area
		xchg eax,ecx
		jmp fms_malloc_90

fms_malloc_50:
		mov ebx,edx
		cmp ebx,[malloc.end]
		jb fms_malloc_40

fms_malloc_70:
		xor eax,eax
fms_malloc_90:
		ret


; some file in cpio archive
fms_file:
		mov ebx,[archive.start]
		or ebx,ebx
		stc
		jz fms_file_90
		cmp eax,ebx
		jc fms_file_90
		cmp eax,[archive.end]
		cmc
		jc fms_file_90

fms_file_10:
		mov ecx,[archive.end]
		sub ecx,26
		cmp ebx,ecx
		jae fms_file_80

		mov byte [fms_cpio_swab],0
		cmp word [es:ebx],71c7h
		jz fms_file_20			; normal cpio record
		cmp word [es:ebx],0c771h	; maybe byte-swapped?
		jnz fms_file_80			; no cpio record
		mov byte [fms_cpio_swab],1

fms_file_20:
		push eax
		mov ax,[es:ebx+20]		; file name size
		call cpio_swab
		movzx ecx,ax
		pop eax
		inc ecx
		and ecx,~1			; align

		lea ecx,[ecx+ebx+26]		; data start

		cmp eax,ecx
		jb fms_file_80			; within header area

		push eax
		mov eax,[es:ebx+22]		; data size
		call cpio_swab
		rol eax,16			; strange word order
		call cpio_swab
		mov edx,eax
		pop eax

		mov ebx,edx
		inc ebx
		and ebx,~1			; align
		add ebx,ecx			; next record

		add ecx,edx

		cmp eax,ebx
		jae fms_file_10

		sub ecx,eax
		xchg eax,ecx

		jnc fms_file_90			; not within alignment area
fms_file_80:
		xor eax,eax
fms_file_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Byte-swap cpio data if appropriate.
;
;  ax:		word to swap
;
; return:
;  ax:		swapped if [fms_cpio_swab], otherwise same as input
;

		bits 32

cpio_swab:
		cmp byte [fms_cpio_swab],0
		jz cpio_swab_90
		xchg ah,al
cpio_swab_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Find (and load) file.
;
;  eax		file name
;
; return:
;  eax		file start
;   bl		0/1: file/symlink 
;
; Note: use find_mem_size to find out file size.
;

		bits 32

find_file:
		mov esi,eax
		mov al,0
		mov ebp,[archive.start]
		or ebp,ebp
		jz find_file_80
find_file_20:
		mov ebx,ebp

		mov byte [fms_cpio_swab],0
		cmp word [es:ebx],71c7h		; little-endian archive
		jz find_file_30
		cmp word [es:ebx],0c771h	; big-endian
		jnz find_file_80
		mov byte [fms_cpio_swab],1
find_file_30:
		mov al,[es:ebx+7]
		and al,0f0h
		cmp al,0a0h
		setz al
		push eax
		mov ax,[es:ebx+20]	; file name size (incl. final 0)
		call cpio_swab
		movzx ecx,ax
		pop eax
		mov edx,ecx
		inc edx
		and edx,~1		; align
		lea edi,[ebx+26]
		lea ebp,[ebx+edx+26]	; points to data start
		or ecx,ecx
		jz find_file_50
		push esi
		es rep cmpsb
		pop esi
		jnz find_file_50
		mov bl,al
		mov eax,ebp
		jmp find_file_90
find_file_50:
		push eax
		mov eax,[es:ebx+22]	; data size
		call cpio_swab
		rol eax,16		; strange word order
		call cpio_swab
		mov ecx,eax
		pop eax

		inc ecx
		and ecx,~1		; align
		add ebp,ecx
		mov ecx,ebp
		add ecx,26
		cmp ecx,[archive.end]
		jb find_file_20
find_file_80:
		xor eax,eax
		mov bl,al
find_file_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set graphics mode.
;
;  [gfx_mode]	graphics mode (either vbe or normal mode number)
;  [vbe_buffer]	buffer for vbe info
;
; return:
;  CF		error
;

		bits 32

set_mode:
		mov ax,[gfx_mode]
		test ah,ah
		jnz set_mode_20
		int 10h
		mov word [window_seg_w],0a000h
		and word [window_seg_r],0
		mov byte [mapped_window],0

		mov al,[gfx_mode]
		cmp al,13h
		jnz set_mode_10
		; 320x200, 8 bit
		mov word [screen_width],320
		mov word [screen_height],200
		mov word [screen_vheight],200
		mov dword [screen_line_len],320
		mov byte [pixel_bits],8
		mov byte [pixel_bytes],1
		call mode_init
set_mode_10:
		clc
		jmp set_mode_90
set_mode_20:
		mov ebx,[vbe_buffer]
		and dword [es:ebx],0

		mov eax,ebx
		shr eax,4
		mov [rm_seg.es],ax
		mov edi,ebx
		and edi,0fh

		mov ax,4f00h
		push ebx
		int 10h
		pop ebx
		cmp ax,4fh
		jnz set_mode_80
		mov ax,4f01h
		mov cx,[gfx_mode]
		push ebx
		int 10h
		pop edi
		cmp ax,4fh
		jnz set_mode_80

		movzx eax,word [es:edi+10h]
		mov [screen_line_len],eax

		push word [es:edi+12h]
		pop word [screen_width]
		push word [es:edi+14h]
		pop word [screen_height]

		movzx eax,byte [es:edi+1dh]
		inc eax
		movzx ecx,word [screen_height]
		mul ecx
		cmp eax,7fffh
		jbe set_mode_25
		mov eax,7fffh
set_mode_25:
		mov [screen_vheight],ax

		mov al,[es:edi+1bh]		; color mode (aka memory model)
		mov ah,[es:edi+19h]		; color depth
		mov dh,ah
		cmp al,6			; direct color
		jnz set_mode_30
		mov dh,[es:edi+1fh]		; red
		add dh,[es:edi+21h]		; green
		add dh,[es:edi+23h]		; blue
		jmp set_mode_40
set_mode_30:
		cmp al,4			; PL 8
		mov ah,8
		mov dh,ah
		jz set_mode_40
		mov ah,0
set_mode_40:
		cmp ah,8
		jz set_mode_45
		cmp ah,16
		jz set_mode_45
		cmp ah,32
		jnz set_mode_80
set_mode_45:

		mov [pixel_bits],ah
		shr ah,3
		mov [pixel_bytes],ah
		mov [color_bits],dh

		; we check if win A is readable _and_ writable; if not, we want
		; at least a writable win A and a readable win B
		; other, even more silly variations are not supported

		mov ax,[es:edi+8]		; win seg A
		mov bx,[es:edi+10]		; win seg B

		or ax,ax
		jz set_mode_80
		mov [window_seg_w],ax
		and word [window_seg_r],byte 0
		mov dx,[es:edi+2]		; win A/B attributes
		and dx,707h
		cmp dl,7
		jz set_mode_50		; win A is rw

		or bx,bx
		jz set_mode_80
		mov [window_seg_r],bx
		mov cx,dx
		and dx,305h
		cmp dx,305h
		jz set_mode_50		; win A is w, win B is r

		and cx,503h
		cmp cx,503h
		jnz set_mode_80
					; win A is r, win B is w
		mov [window_seg_r],ax
		mov [window_seg_w],bx
set_mode_50:
		mov ax,[es:edi+6]	; win size (in kb)
		cmp ax,64
		jb set_mode_80		; at least 64k
		xor edx,edx
		mov bx,[es:edi+4]	; granularity (in kb)
		or bx,bx
		jz set_mode_80
		div bx
		or dx,dx
		jnz set_mode_80
		or ax,ax
		jz set_mode_80
		mov [window_inc],al
		mov byte [mapped_window],0ffh
		mov ax,4f02h
		mov bx,[gfx_mode]
		int 10h
		cmp ax,4fh
		jnz set_mode_80
		mov al,0
		call set_win

		call mode_init

		clc

		jmp set_mode_90
set_mode_80:
		and word [gfx_mode],0
		stc
set_mode_90
		ret

mode_init:
		; graphics window selectors

		movzx eax,word [window_seg_w]
		shl eax,4
		mov si,pm_seg.screen_w16
		call set_gdt_base_pm

		movzx ecx,word [window_seg_r]
		shl ecx,4
		jz mode_init_05
		mov eax,ecx
mode_init_05:
		mov si,pm_seg.screen_r16
		call set_gdt_base_pm

		; pixel get/set functions

		mov dword [setpixel],setpixel_8
		mov dword [setpixel_a],setpixel_a_8
		mov dword [setpixel_t],setpixel_8
		mov dword [setpixel_ta],setpixel_a_8
		mov dword [getpixel],getpixel_8
		cmp byte [pixel_bits],8
		jz mode_init_90
		cmp  byte [pixel_bits],16
		jnz mode_init_50
		mov dword [setpixel],setpixel_16
		mov dword [setpixel_a],setpixel_a_16
		mov dword [setpixel_t],setpixel_t_16
		mov dword [setpixel_ta],setpixel_ta_16
		mov dword [getpixel],getpixel_16
		jmp mode_init_90
mode_init_50:
		cmp byte [pixel_bits],32
		jnz mode_init_90
		mov dword [setpixel],setpixel_32
		mov dword [setpixel_a],setpixel_a_32
		mov dword [setpixel_t],setpixel_t_32
		mov dword [setpixel_ta],setpixel_ta_32
		mov dword [getpixel],getpixel_32
mode_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get VBE mode list.
;
;  [vbe_buffer]	buffer for vbe info
;
; return:
;  [vbe_mode_list]	mode list, last entry is 0xffff
;  [screen_mem]		video memory size
;

		bits 32

get_vbe_modes:
		mov ebx,[vbe_mode_list]
		cmp word [es:ebx],0
		jnz get_vbe_modes_90

		mov edx,[vbe_buffer]
		and dword [es:edx],0

		mov eax,edx
		shr eax,4
		mov [rm_seg.es],ax
		mov edi,edx
		and edi,0fh

		mov ax,4f00h
		push ebx
		push edx
		int 10h
		pop edx
		pop ebx

		mov edi,ebx

		cmp ax,4fh
		jnz get_vbe_modes_20

		push word [es:edx+12h]
		pop word [screen_mem]

		movzx esi,word [es:edx+0eh]
		movzx eax,word [es:edx+0eh+2]
		shl eax,4
		add esi,eax

		mov ecx,0ffh
get_vbe_modes_10:
		es lodsw
		stosw
		cmp ax,0ffffh
		jz get_vbe_modes_30
		dec ecx
		jnz get_vbe_modes_10
get_vbe_modes_20:
		mov word [es:edi],0ffffh
get_vbe_modes_30:
		cmp word [es:ebx],0
		jnz get_vbe_modes_90
		; make sure it's not 0; mode 1 is the same as mode 0
		inc word [es:esi]

get_vbe_modes_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write text to console.
;
;  esi		format string
;  [pf_gfx]	use ds:esi (0) or es:esi (1) 
;

		bits 32

printf:
		mov byte [tmp_write_cnt],0
printf_10:
		call pf_next_char
		or eax,eax
		jz printf_90
		cmp al,'%'
		jnz printf_70
		mov byte [tmp_write_pad],' '
		call pf_next_char
		dec esi
		cmp al,'0'
		jnz printf_20
		mov [tmp_write_pad],al
printf_20:
		call get_number
		mov [tmp_write_num],ecx
		call pf_next_char
		or eax,eax
		jz printf_90
		cmp al,'%'
		jz printf_70

		cmp al,'S'
		jnz printf_23
		mov byte [pf_gfx_raw_char],1
		jmp printf_24
printf_23:
		cmp al,'s'
		jnz printf_30
printf_24:
		push esi

		call pf_next_arg
		mov esi,eax
		call write_str

		sub ecx,[tmp_write_num]
		neg ecx
		mov al,' '
		call write_chars

		pop esi

		mov byte [pf_gfx_raw_char],0
		jmp printf_10

printf_30:		
		cmp al,'u'
		jnz printf_35

		mov dx,10
printf_31:
		push esi

		call pf_next_arg
		or dh,dh
		jz printf_34
		test eax,eax
		jns printf_34
		neg eax
		push eax
		mov al,'-'
		call write_char
		pop eax
printf_34:
		mov cl,[tmp_write_num]
		mov ch,[tmp_write_pad]
		call number
		cmp byte [pf_gfx],0
		jz printf_345
		add esi,[prog.base]
printf_345:
		call write_str
printf_347:
		pop esi

		jmp printf_10

printf_35:
		cmp al,'x'
		jnz printf_36

printf_35a:
		mov dx,10h
		jmp printf_31

printf_36:
		cmp al,'d'
		jnz printf_37
printf_36a:
		mov dx,10ah
		jmp printf_31

printf_37:
		cmp al,'i'
		jz printf_36a

		cmp al,'p'
		jnz printf_40
		mov al,'0'
		call write_char
		mov al,'x'
		call write_char
		jmp printf_35a

printf_40:
		cmp al,'c'
		jnz printf_45

		push esi
		call pf_next_arg
		call write_char
		pop esi
		jmp printf_10
printf_45:

		; more ...
		

printf_70:
		call write_char
		jmp printf_10
printf_90:		
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get next char for printf.
;
; esi		string
;  [pf_gfx]	use ds:esi (0) or es:esi (1) 
;
; return:
;  eax		char
;  esi		points to next char
;

		bits 32

pf_next_char:
		xor eax,eax
		cmp byte [pf_gfx],0
		jz pf_next_char_50
		es		; ok, this _is_ evil code...
pf_next_char_50:
		lodsb
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get next printf arg.
;
;  [pf_gfx]	get arg from [tmp_write_data] (0) or pstack (1)
;
; return:
;  eax		arg
;
; changes no regs
;

		bits 32

pf_next_arg:
		cmp byte [pf_gfx],0
		jz pf_next_arg_50
		pusha
		xor ecx,ecx
		call get_pstack_tos
		mov [tmp_write_data],eax
		jnc pf_next_arg_20
		and dword [tmp_write_data],0
		cmp word [pf_gfx_err],0
		jnz pf_next_arg_20
		mov word [pf_gfx_err],pserr_pstack_underflow
		jmp pf_next_arg_30
pf_next_arg_20:
		dec dword [pstack.ptr]
pf_next_arg_30:
		popa
		mov eax,[tmp_write_data]
		jmp pf_next_arg_90
pf_next_arg_50:
		movzx eax,byte [tmp_write_cnt]
		inc byte [tmp_write_cnt]
		mov eax,[tmp_write_data+4*eax]
pf_next_arg_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write string.
;
;  esi		text
;  [pf_gfx]	use ds:esi (0) or es:esi (1) 
;
; return:
;  ecx		length
;

		bits 32

write_str:
		xor ecx,ecx
write_str_10:
		call pf_next_char
		cmp byte [pf_gfx],0
		jz write_str_40
		call is_eot
		jmp write_str_50
write_str_40:
		or eax,eax
write_str_50:
		jz write_str_90
		call write_char
		inc ecx
		jmp write_str_10
write_str_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write char multiple times.
;
;  al		char
;  ecx		count (does nothing if count <= 0)
;  [pf_gfx]	write to console (0) or [pf_gfx_buf] (1)
;

		bits 32

write_chars:
		cmp ecx,0
		jle write_chars_90
		call write_char
		dec ecx
		jmp write_chars
write_chars_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write single char.
;
;  al		char
;  [pf_gfx]	write to console (0) or [pf_gfx_buf] (1)
;
; Changes no regs.
;

		bits 32

write_char:
		pusha
		cmp byte [pf_gfx],0
		jz write_char_50
		mov ebx,[pf_gfx_cnt]
		inc ebx
		cmp ebx,[pf_gfx_max]
		jae write_char_90		; leave room for final 0!
		mov [pf_gfx_cnt],ebx
		add ebx,[pf_gfx_buf]
		dec ebx
		mov ah,0
		mov [es:ebx],ax
		jmp write_char_90
write_char_50:
		cmp byte [pf_gfx_raw_char],0
		jnz write_char_60
		cmp al,0ah
		jnz write_char_60
		push eax
		mov al,0dh
		call write_cons_char
		pop eax
write_char_60:
		call write_cons_char
write_char_90:
		popa
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write char on text console.
;
;  al		char
;

		bits 32

write_cons_char:
		; vesa mode?
		cmp byte [gfx_mode+1],0
		jnz write_cons_char_20
		mov bx,7
		cmp byte [pf_gfx_raw_char],0
		jz write_cons_char_10
		mov ah,0ah
		mov cx,1
		int 10h
		mov ah,3
		int 10h
		inc dl
		mov ah,2
		int 10h
		jmp write_cons_char_90
write_cons_char_10:
		mov ah,0eh
		int 10h
		jmp write_cons_char_90
write_cons_char_20:
		cmp byte [pf_gfx_raw_char],0
		jnz write_cons_char_40
		cmp al,0ah
		jnz write_cons_char_30
		mov cx,[cfont_height]
		add [con_y],cx
		jmp write_cons_char_90
write_cons_char_30:
		cmp al,0dh
		jnz write_cons_char_40
		and word [con_x],0
		jmp write_cons_char_90
write_cons_char_40:
		stc
		sbb ebx,ebx		; -1
		cmp byte [pixel_bits],8
		ja write_cons_char_50
		mov bl,[textmode_color]
write_cons_char_50:
		call con_char_xy
write_cons_char_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Convert string to number.
;
;  esi		string
;  [pf_gfx]	use ds:esi (0) or es:esi (1) 
;
; return:
;  ecx		number
;  esi		points past number
;  CF		not a number
;

		bits 32

get_number:

		xor ecx,ecx
		mov ah,1
get_number_10:
		call pf_next_char
		or al,al
		jz get_number_90
		sub al,'0'
		jb get_number_90
		cmp al,9
		ja get_number_90
		movzx eax,al
		imul ecx,ecx,10
		add ecx,eax
		jmp get_number_10
get_number_90:
		dec esi
		shr ah,1
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Convert a number to string.
;
;  eax		number
;  cl		field size
;  ch		padding char
;  dl		base
;
; return:
;  ds:esi	string
;
; Note: esi is relative to [prog.base], not 0!
;

		bits 32

number:
		mov edi,num_buf
		add edi,[prog.base]
		push eax
		push ecx
		mov al,ch
		mov ecx,num_buf_end - num_buf
		rep stosb
		pop ecx
		pop eax
		movzx ecx,cl
		movzx ebx,dl
		sub edi,[prog.base]
number_10:
		xor edx,edx
		div ebx
		cmp dl,9
		jbe number_20
		add dl,27h
number_20:
		add dl,'0'
		dec edi
		mov [edi],dl
		or eax,eax
		jz number_30
		cmp edi,num_buf
		ja number_10
number_30:
		mov esi,edi
		or ecx,ecx
		jz number_90
		cmp ecx,num_buf_end - num_buf
		jae number_90
		mov esi,num_buf_end
		sub esi,ecx
number_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Print status/debug info window on console.
;

		bits 32

ps_status_info:
		xor edx,edx
		call con_xy

		mov esi,msg_13
		call printf

		mov ecx,7
ps_status_info_10:
		push ecx

		call get_pstack_tos
		jc ps_status_info_20
		pf_arg_uint 0,ecx
		pf_arg_uchar 2,dl
		pf_arg_uint 1,eax
		mov esi,msg_11
		jmp ps_status_info_30
ps_status_info_20:
		mov esi,msg_12
ps_status_info_30:
		call printf

		pop ecx
		push ecx

		call get_rstack_tos
		jc ps_status_info_40
		pf_arg_uint 0,ecx
		pf_arg_uchar 2,dl
		pf_arg_uint 1,eax
		mov esi,msg_11
		jmp ps_status_info_50
ps_status_info_40:
		mov esi,msg_12
ps_status_info_50:
		call printf

		mov esi,msg_16
		call printf

		pop ecx
		dec ecx
		jge ps_status_info_10

		mov esi,msg_14
		call printf

		mov eax,[pscode_error_arg_0]
		pf_arg_uint 1,eax
		mov eax,[pscode_error_arg_1]
		pf_arg_uint 2,eax
		mov ax,[pscode_error]
		pf_arg_ushort 0,ax
		mov esi,msg_17
		cmp ax,100h
		jb ps_status_info_60
		mov esi,msg_18
		cmp ax,200h
		jb ps_status_info_60
		mov esi,msg_19
ps_status_info_60:
		call printf

		mov eax,[pscode_instr]
		pf_arg_uint 0,eax
		mov eax,[pscode_arg]
		pf_arg_uint 1,eax
		mov eax,[pscode_error_arg_0]
		pf_arg_uint 3,eax
		mov eax,[pscode_error_arg_1]
		pf_arg_uint 4,eax
		mov al,[pscode_type]
		pf_arg_uchar 2,al

		mov esi,msg_10
		cmp al,t_sec
		jnz ps_status_info_70
		mov esi,msg_20
ps_status_info_70:
		call printf

		xor ecx,ecx
		call get_pstack_tos
		jnc ps_status_info_71
		mov dl,t_none
		xor eax,eax
ps_status_info_71:
		mov ebp,[prog.base]
		push eax
		mov al,' '
		lea edi,[num_buf+ebp]
		mov ecx,1fh		; watch num_buf_end
		rep stosb
		mov [es:edi],cl
		pop eax

		cmp dl,t_string
		jnz ps_status_info_79

		mov esi,eax

		lea edi,[num_buf+ebp]
		mov al,0afh
		stosb
ps_status_info_72:
		es lodsb
		or al,al
		jz ps_status_info_73
		stosb
		cmp byte [es:edi+1],0
		jnz ps_status_info_72
		cmp byte [es:esi],0
		jnz ps_status_info_74
ps_status_info_73:		
		mov al,0aeh
		jmp ps_status_info_75
ps_status_info_74:
		mov al,0afh
ps_status_info_75:
		stosb

ps_status_info_79:
		mov esi,num_buf
		pf_arg_uint 0,esi
		mov esi,msg_21
		call printf

ps_status_info_80:
		mov esi,msg_15
		call printf

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read a key (blocking).
;
; return:
;  eax		key
;

		bits 32

get_key:
		mov ah,10h
		int 16h
		and eax,0ffffh
		mov ecx,[es:417h-2]
		xor cx,cx
		add eax,ecx
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read a key, return 0 if timed out
;
; return:
;  eax		key (or 0)
;

		bits 32

get_key_to:
		call get_time
		xchg eax,edx
get_key_to_20:
		mov ah,11h
		int 16h
		jnz get_key_to_60
		cmp byte [idle.run],0
		jz get_key_to_25
		call idle
get_key_to_25:
		mov ax,[es:417h]
		cmp ax,[kbd_status]
		mov [kbd_status],ax
		jz get_key_to_30
		xor ax,ax
		jmp get_key_to_60

get_key_to_30:
		call get_time
		cmp edx,eax
		jz get_key_to_20

		push eax
		call timer
		pop edx

		mov eax,[input_timeout]
		or eax,eax
		jz get_key_to_20

		dec dword [input_timeout]
		pushf
		push edx
		call timeout
		pop edx
		popf
		jnz get_key_to_20

		xor eax,eax
		jmp get_key_to_90

get_key_to_60:
		pushf
		cmp dword [input_timeout],0
		jz get_key_to_70
		and dword [input_timeout],0
		call timeout
get_key_to_70:
		popf
		jnz get_key_to_80
		mov ax,[kbd_status]
		shl eax,16
		mov ah,0ffh
		jmp get_key_to_90
get_key_to_80:
		call get_key
get_key_to_90:
		mov byte [idle.invalid],1
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Clear keyboard input buffer.
;

		bits 32

clear_kbd_queue:
		mov ah,11h
		int 16h
		jz clear_kbd_queue_90
		mov ah,10h
		int 16h
		jmp clear_kbd_queue
clear_kbd_queue_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get system time.
;
; return:
;  eax		clock ticks since midnight (18.2/s)
;

		bits 32

get_time:
		push ecx
		push edx
		xor eax,eax
		int 1ah
		push cx
		push dx
		pop eax
		pop edx
		pop ecx
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Convert 8 bit bcd to binary.
;
;  al		bcd
;
; return
;  ax		binary
;

		bits 32

bcd2bin:
		push edx
		mov dl,al
		shr al,4
		and dl,0fh
		mov ah,10
		mul ah
		add al,dl
		pop edx
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get date.
;
; return:
;  eax		date (year:16, month:8, day:8)
;

		bits 32

get_date:
		clc
		mov ah,4
		int 1ah
		jnc get_date_10
		xor edx,edx
		xor ecx,ecx
get_date_10:
		mov al,ch
		call bcd2bin
		imul bx,ax,100
		mov al,cl
		call bcd2bin
		add bx,ax
		shl ebx,16
		mov al,dh
		call bcd2bin
		mov bh,al
		mov al,dl
		call bcd2bin
		add bx,ax
		mov eax,ebx
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set console cursor position.
;
;  dh		row
;  dl		column
;
; return:
;

		bits 32

con_xy:
		mov bh,0
		mov ah,2
		int 10h
		and dword [con_x],0
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Idle task.
;
; Run when we are waiting for keyboard input.
;

		bits 32

idle:
		pusha

		mov edi,[idle.draw_buffer]
		or edi,edi
		jz idle_90

		push dword [gfx_cur]

		mov ax,[screen_width]
		sub ax,kroete.width
		shr ax,1
		mov [gfx_cur_x],ax

		mov ax,[screen_height]
		sub ax,kroete.height
		shr ax,1
		mov [gfx_cur_y],ax

		cmp byte [idle.invalid],0
		jz idle_10
		push edi
		mov dx,[es:edi]
		mov cx,[es:edi+2]
		add edi,4
		call save_bg
		pop edi
		mov byte [idle.invalid],0
idle_10:

		mov esi,[idle.data1]
		push edi
		call kroete
		pop edi

		mov dx,[es:edi]
		mov cx,[es:edi+2]
		add edi,4
		mov bx,dx
		imul bx,[pixel_bytes]
		call restore_bg

idle_90:
		pop dword [gfx_cur]

		popa
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Execute bytecode.
;
;  eax		start address, relative to [pscode_start]
;
; return:
;  CF		error
;

		bits 32

run_pscode:
		mov [pscode_instr],eax
		mov [pscode_next_instr],eax
		mov dword [pscode_next_break],-1
		and word [pscode_error],byte 0
		mov dword [pscode_eval],-1

		cmp [pscode_size],eax
		mov bp,pserr_nocode
		jb run_pscode_90
run_pscode_10:
		mov eax,[pscode_next_instr]
		mov [pscode_instr],eax
		cmp eax,-1		; -1 is special: stop there
		mov bp,pserr_ok
		jz run_pscode_90
		mov ecx,-1
		xchg ecx,[pscode_eval]
		cmp ecx,[pscode_eval]
		jz run_pscode_15
		; run opcode from exec instruction
		mov ebx,eax
		mov dl,t_sec
		mov eax,ecx
		jmp run_pscode_455
run_pscode_15:
		mov ebx,eax
		add eax,[pscode_start]
		mov esi,eax
		es lodsb
		xor ecx,ecx
		mov cl,al
		and al,0fh
		shr cl,4
		mov ah,cl

		and cl,7
		xor edx,edx

		cmp cl,0
		jz run_pscode_20

		mov dl,[es:esi]
		cmp cl,1
		jz run_pscode_20

		mov dx,[es:esi]
		cmp cl,2
		jz run_pscode_20

		mov edx,[es:esi]
		and edx,0ffffffh
		cmp cl,3
		jz run_pscode_20

		mov edx,[es:esi]
run_pscode_20:		
		stc
		adc ebx,ecx		; ebx+ecx+1
		mov edi,ebx
		add edi,[pscode_start]

		test ah,8
		jz run_pscode_30
		add ebx,edx
run_pscode_30:
		cmp [pscode_size],ebx
		mov bp,pserr_nocode
		jb run_pscode_90

		; fix up signed integer
		cmp al,t_int
		jnz run_pscode_40
		cmp ah,0
		jz run_pscode_40
		cmp ah,4
		jae run_pscode_40
		shl ah,3
		mov cl,20h
		sub cl,ah
		shl edx,cl
		sar edx,cl
run_pscode_40:

		cmp al,t_string
		jnz run_pscode_45
		mov edx,edi
run_pscode_45:
		xchg eax,edx

run_pscode_455:

		; dl:  opcode
		; eax: instr arg
		; ebx: next instruction

		; remember them
		mov [pscode_type],dl
		mov [pscode_arg],eax
		mov [pscode_next_instr],ebx

		cmp dl,t_sec
		jnz run_pscode_46

		; look it up in the dictionary, then continue
		mov ecx,eax
		call get_dict_entry
		mov bp,pserr_invalid_dict
		jc run_pscode_90

		movzx edx,dl
		mov [pscode_error_arg_0],eax
		mov [pscode_error_arg_1],edx

run_pscode_46:
		pusha
		cmp byte [show_debug_info],0
		jz run_pscode_47
		call ps_status_info
run_pscode_47:
		mov eax,[pscode_next_break]
		cmp eax,[pscode_instr]
		jz run_pscode_475
		cmp byte [single_step],0
		jz run_pscode_48
run_pscode_475:
		mov byte [single_step],1
		call get_key
		cmp ah,1		; ESC
		jnz run_pscode_477
		mov byte [single_step],0
		mov byte [show_debug_info],0
		jmp run_pscode_48
run_pscode_477:
		cmp ah,0fh		; Tab
		jnz run_pscode_48
		mov byte [single_step],0
		mov eax,[pscode_next_instr]
		mov [pscode_next_break],eax
run_pscode_48:
		popa

		; actually do something
		cmp dl,t_none
		jz run_pscode_50
		cmp dl,t_int
		jz run_pscode_50
		cmp dl,t_unsigned
		jz run_pscode_50
		cmp dl,t_bool
		jz run_pscode_50
		cmp dl,t_string
		jz run_pscode_50
		cmp dl,t_dict_idx
		jz run_pscode_50
		cmp dl,t_ptr
		jz run_pscode_50
		cmp dl,t_array
		jnz run_pscode_52
run_pscode_50:
		; t_none, t_int, t_bool, t_unsigned, t_string, t_code, t_dict_idx, t_array, t_ptr

		cmp dl,t_unsigned
		jnz run_pscode_51
		mov dl,t_int		; always use t_int
run_pscode_51:
		mov ecx,[pstack.ptr]
		cmp ecx,[pstack.size]
		mov bp,pserr_pstack_overflow
		jae run_pscode_80
		inc dword [pstack.ptr]

		xor ecx,ecx
		call set_pstack_tos
		jc run_pscode_90
		jmp run_pscode_10

run_pscode_52:
		cmp dl,t_prim
		jnz run_pscode_53

		cmp eax,prim_functions
		mov bp,pserr_invalid_prim
		jae run_pscode_80
		movzx eax,word [jt_p_none+2*eax]
		or eax,eax		; implemented?
		jz run_pscode_80
		call eax
		jc run_pscode_90
		jmp run_pscode_10

run_pscode_53:
		cmp dl,t_code
		jnz run_pscode_54

		; branch
		xchg eax,[pscode_next_instr]

		; Check if we should just leave a mark on the
		; pstack or actually execute the code.
		; Maybe 2 different types (say: t_code, t_mark) would be better?
		cmp byte [pscode_type],t_sec
		jnz run_pscode_50

		mov ecx,[rstack.ptr]
		cmp ecx,[rstack.size]
		mov bp,pserr_rstack_overflow
		jae run_pscode_80
		inc dword [rstack.ptr]

		xor ecx,ecx
		call set_rstack_tos
		jc run_pscode_90
		jmp run_pscode_10

run_pscode_54:
		cmp dl,t_ret
		jnz run_pscode_70

		xor ecx,ecx
		call get_rstack_tos
		jnc run_pscode_55
		mov bp,pserr_rstack_underflow
		jc run_pscode_90
; 		; treat this case as 'end'
;		mov bp,pserr_ok
;		clc
;		jmp run_pscode_90
run_pscode_55:
		mov bp,pserr_invalid_rstack_entry
		cmp dl,t_code
		jz run_pscode_68
		cmp dl,t_if			; if
		jz run_pscode_68
		cmp dl,t_loop			; loop
		jz run_pscode_69
		cmp dl,t_repeat			; repeat
		jz run_pscode_65
		cmp dl,t_for			; for
		jz run_pscode_62
		cmp dl,t_forall			; forall
		jnz run_pscode_80

		; forall
		cmp dword [rstack.ptr],5
		mov bp,pserr_rstack_underflow
		jc run_pscode_90

		mov ecx,1
		call get_rstack_tos		; count
		cmp dl,t_int
		jnz run_pscode_66

		mov ecx,2
		push eax
		call get_rstack_tos		; length
		pop esi
		cmp dl,t_int
		jnz run_pscode_66

		mov ecx,3
		push eax
		push esi
		call get_rstack_tos		; string/array
		pop esi
		pop ecx
		cmp dl,t_array
		jz run_pscode_57
		cmp dl,t_string
		jz run_pscode_57
		cmp dl,t_ptr
		jnz run_pscode_66

run_pscode_57:
		; dl,eax: string/array
		; esi: count
		; ecx: length

		inc esi
		cmp esi,ecx
		jae run_pscode_64

		push edx
		mov ecx,1
		mov dl,t_int
		push eax
		push esi
		mov eax,esi
		call set_rstack_tos
		pop eax
		pop ecx
		pop edx

		xchg dl,dh
		call p_get
		mov bp,pserr_invalid_range
		jc run_pscode_80

		mov ecx,[pstack.ptr]
		cmp ecx,[pstack.size]
		jae run_pscode_80
		inc dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
		jc run_pscode_90

		xor ecx,ecx
		call get_rstack_tos
		jmp run_pscode_69


run_pscode_62:
		; for
		cmp dword [rstack.ptr],5
		mov bp,pserr_rstack_underflow
		jc run_pscode_90

		mov ecx,2
		call get_rstack_tos		; step
		cmp dl,t_int
		jnz run_pscode_66
		mov ecx,1
		push eax
		call get_rstack_tos		; limit
		pop esi
		cmp dl,t_int
		jnz run_pscode_66
		push eax
		mov ecx,3
		push esi
		call get_rstack_tos		; counter
		pop esi
		cmp dl,t_int
		pop ecx
		jnz run_pscode_66
		add eax,esi
		or esi,esi
		push eax
		js run_pscode_63
		xchg eax,ecx
run_pscode_63:
		cmp eax,ecx
		pop eax
		jl run_pscode_64

		mov ecx,3
		push eax
		call set_rstack_tos
		pop eax
		mov ecx,[pstack.ptr]
		cmp ecx,[pstack.size]
		jae run_pscode_80
		inc dword [pstack.ptr]
		xor ecx,ecx
		mov dl,t_int
		call set_pstack_tos
		jc run_pscode_90
		xor ecx,ecx
		call get_rstack_tos
		jmp run_pscode_69
run_pscode_64:
		mov ecx,4
		call get_rstack_tos
		sub dword [rstack.ptr],5
		jmp run_pscode_69


run_pscode_65:
		; repeat
		cmp dword [rstack.ptr],3
		mov bp,pserr_rstack_underflow
		jc run_pscode_90
		push eax
		mov ecx,1
		call get_rstack_tos
		pop ebx
		cmp dl,t_int
run_pscode_66:
		mov bp,pserr_invalid_rstack_entry
		jnz run_pscode_80
		dec eax
		jz run_pscode_67
		mov ecx,1
		push ebx
		call set_rstack_tos
		pop eax
		jmp run_pscode_69
run_pscode_67:
		mov ecx,2
		call get_rstack_tos
		sub dword [rstack.ptr],2

run_pscode_68:
		dec dword [rstack.ptr]
run_pscode_69:
		mov [pscode_next_instr],eax

		jmp run_pscode_10

run_pscode_70:

%if 0
; Using undefined values has been legalized.
; See run_pscode_51 above...
;
		cmp dl,t_none
		mov bp,pserr_nop
		jz run_pscode_80
%endif

		cmp dl,t_sec
		mov bp,pserr_invalid_dict_entry
		jz run_pscode_80

		cmp dl,t_end
		mov bp,pserr_ok
		jz run_pscode_90

		; illegal opcode
		mov bp,pserr_invalid_opcode
run_pscode_80:
		stc
run_pscode_90:
		mov [pscode_error],bp
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get one argument from stack.
;
;  dl		tos type
;
; return:
;  eax		tos
;  dl		actual tos types (even if CF is set)
;  CF		error
;

		bits 32

get_1arg:
		xor eax,eax
		cmp dword [pstack.ptr],1
		mov bp,pserr_pstack_underflow
		jc get_1arg_90
		push edx
		xor ecx,ecx
		call get_pstack_tos
		pop ebx
		; ignore type check if t_none was requested
		cmp bl,t_none
		jz get_1arg_90
		cmp bl,dl
		jz get_1arg_90
		mov bp,pserr_wrong_arg_types
		stc
get_1arg_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get two arguments from stack.
;
;  dl		tos type
;  dh		tos + 1 type
; return:
;  eax		tos
;  ecx		tos + 1
;  dx		actual tos types (even if CF is set)
;  CF		error
;

		bits 32

get_2args:
		xor eax,eax
		xor ecx,ecx
		mov ebx,edx
		xor edx,edx
		cmp dword [pstack.ptr],2
		mov bp,pserr_pstack_underflow
		jc get_2args_90
		push ebx
		inc ecx
		call get_pstack_tos
		push edx
		push eax
		xor ecx,ecx
		call get_pstack_tos
		pop ecx
		pop ebx
		mov dh,bl
		pop ebx

		; ignore type check if t_none was requested
		cmp bh,t_none
		jnz get_2args_50
		mov bh,dh
get_2args_50:
		cmp bl,t_none
		jnz get_2args_60
		mov bl,dl
get_2args_60:
		cmp bx,dx
		jz get_2args_90
		mov bp,pserr_wrong_arg_types
get_2args_80:
		stc
get_2args_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get array/string/ptr element.
;
;  dh, ecx	obj
;  eax		index
;
; return:
;  dl, eax	element
;  CF		0/1 ok/not ok
;

		bits 32

p_get:
		cmp dh,t_array
		jz p_get_50
		cmp dh,t_string
		jz p_get_10
		cmp dh,t_ptr
		stc
		jnz p_get_90
p_get_10:
		mov dl,t_int
		movzx eax,byte [es:eax+ecx]
		jmp p_get_80
p_get_50:
		mov bp,pserr_invalid_range
		movzx ebx,word [es:ecx]
		cmp eax,ebx
		cmc
		jc p_get_90

		lea eax,[eax+4*eax]

		mov dl,[es:ecx+eax+2]
		mov eax,[es:ecx+eax+3]
p_get_80:
		clc
p_get_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Our primary functions.
;


;; { - start code definition
;
; group: code
;
; ( -- code1 )
;
; code1:	code start marker
;
; After @{, no code is executed until a matching @} is found.
;
; example 
;   /++ { 1 add } def	% define increment function '++'
;


;; } - complete code definition
;
; group: code
;
; ( -- )
;
; Note: @{ and @} are taken care of already during conversion into bytecode. This means that
; redefining them does not work as you would expect.
;
; example 
;   /dec { 1 sub } def	% define decrement function 'dec'
;


;; [ - start array
;
; group: arraydef
;
; ( -- mark1 )
;
; mark1:	array start marker
;
; example 
;   [ 1 2 3 ]	% array with 3 elements
;

		bits 32

prim_astart:
		mov eax,[pstack.ptr]
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_astart_90
		mov [pstack.ptr],eax
		mov dl,t_prim
		mov eax,(jt_p_astart - jt_p_none) / 2	; we need just some mark
		xor ecx,ecx
		call set_pstack_tos
prim_astart_90:
		ret


;; ] -  complete array definition
;
; group: arraydef, mem
;
; ( mark1 obj1 ... objN -- array1 )
;
; mark1:		array start marker
;
; obj1 ... objN:	some objects
; array1:		N-dimensional array with obj1 ... objN
;
; Note: The array uses dynamically allocated memory which must be released using @free.
;
; example 
;   /foo [ "some" "text" ] def	% array with 2 elements
;   foo free			% free memory
;

		bits 32

prim_aend:
		xor ecx,ecx
prim_aend_10:
		push ecx
		call get_pstack_tos
		pop ecx
		mov bp,pserr_pstack_underflow
		jc prim_aend_90
		inc ecx
		cmp dl,t_prim
		jnz prim_aend_10
		cmp eax,(jt_p_astart - jt_p_none) / 2
		jnz prim_aend_10

		dec ecx
		lea eax,[ecx+4*ecx+2]

		push ecx
		call calloc
		pop ecx

		or eax,eax
		mov bp,pserr_no_memory
		stc
		jz prim_aend_90

		push ecx
		push eax

		mov edi,eax
		mov [es:edi],cx
		inc edi
		inc edi

prim_aend_40:
		sub ecx,1
		jc prim_aend_60

		push edi
		push ecx
		call get_pstack_tos
		pop ecx
		pop edi

		mov [es:edi],dl
		mov [es:edi+1],eax
		add edi,5
		jmp prim_aend_40

prim_aend_60:

		pop eax
		pop ecx
		sub [pstack.ptr],ecx
		mov dl,t_array
		xor ecx,ecx
		call set_pstack_tos
prim_aend_90:
		ret


;; get - get array, string or memory element
;
; group: get/put
;
; ( array1 int1  -- obj1 )
; ( string1 int2  -- int3 )
; ( ptr1 int4  -- int5 )
;
; obj1: int1-th element of array1
; int3: int2-th byte of string1
; int5: int4-th byte of ptr1
;
; Note: Returns the n-th byte of string1, not the n-th utf8 char. Sizes of string1 or ptr1
; are not checked.
;
; example
;   "abc" 1 get			% 'b'
;
;   [ 10 20 30 ] 2 get		% 30
;

		bits 32

prim_get:
		mov dx,t_int + (t_array << 8)
		call get_2args
		jnc prim_get_10
		cmp dx,t_int + (t_string << 8)
		jz prim_get_10
		cmp dx,t_int + (t_ptr << 8)
		stc
		jnz prim_get_90
prim_get_10:
		call p_get
		jc prim_get_90

		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
prim_get_90:
		ret


;; put - set an array, string or memory element
;
; group: get/put
; 
; ( array1 int1 obj1 -- )
; ( string1 int2 int3 -- )
; ( ptr1 int4 int5 -- )
;
; int1-th element of array1 = obj1
;
; int2-th byte of string1 = int3
;
; int4-th byte of ptr1 = int5
;
; Note: Sets the n-th byte of string1, not the n-th utf8 char. Sizes of string1 or ptr1
; are not checked.
;
; example
;   /foo [ 10 20 30 ] def
;   foo 2 77 put		% foo = [ 10 20 77 ]
;
;   /foo 10 string def
;   foo 0 'a' put
;   foo 1 'b' put		% foo = "ab"
;
;   But don't do this:
;   "abc" 1 'X' put		% modifies string constant "abc" to "aXc"!
;

		bits 32

prim_put:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],3
		jc prim_put_90

		mov bp,pserr_wrong_arg_types
		mov ecx,2
		call get_pstack_tos
		mov dh,0
		push edx
		push eax
		mov dx,t_none + (t_int << 8)
		call get_2args
		pop ebx
		pop ebp
		shl edx,16
		mov dx,bp
		rol edx,8
		cmp dx,t_int + (t_array << 8)
		jz prim_put_50
		cmp edx,t_int + (t_string << 8) + (t_int << 24)
		jz prim_put_30
		cmp edx,t_int + (t_ptr << 8) + (t_int << 24)
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_put_90
prim_put_30:
		mov [es:ebx+ecx],al
		jmp prim_put_80
prim_put_50:
		shr edx,24

		movzx esi,word [es:ebx]
		cmp ecx,esi
		cmc
		mov bp,pserr_invalid_range
		jc prim_put_90
		
		lea ecx,[ecx+4*ecx]

		mov [es:ebx+ecx+2],dl
		mov [es:ebx+ecx+3],eax

prim_put_80:
		sub dword [pstack.ptr],3
prim_put_90:
		ret


;; length - array, string or memory size
;
; group: mem
;
; ( array1 -- int1 )
; ( string1 -- int1 )
; ( ptr1 -- int1 )
;
; int1: size of array1 or string1 or ptr1
;
; Returns the length of string1 in bytes, not the number of Unicode chars. If ptr1
; doesn't point at the start of a memory area, @length returns the number of remaining
; bytes.
;
; example
;   "abc" length	% 3
;
;   [ 0 1 ] length	% 2
;
;   /foo 10 malloc def
;   foo length		% 10
;   foo 3 add length	% 7
;

		bits 32

prim_length:
		mov dl,t_none
		call get_1arg
		jc prim_length_90
		call get_length
		jc prim_length_90
		xor ecx,ecx
		mov dl,t_int
		call set_pstack_tos
prim_length_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; array - create an empty array
;
; group: mem
;
; ( int1 -- array1 )
;
; int1:		array dimension
; array1:	new array
;
; Note: Use @free to free array1.
;
; example 
;   /foo 10 array def	% create array with 10 elements
;   foo 4 123 put	% foo[4] = 123
;   foo free		% free foo
;

		bits 32

prim_array:
		mov dl,t_int
		call get_1arg
		jc prim_array_90
		cmp eax,10000h
		cmc
		mov bp,pserr_invalid_range
		jc prim_array_90
		push eax
		lea eax,[eax+4*eax+2]
		call calloc
		pop ecx
		or eax,eax
		stc
		mov bp,pserr_no_memory
		jz prim_array_90
		mov [es:eax],cx
		xor ecx,ecx
		mov dl,t_array
		call set_pstack_tos
prim_array_90:
		ret


;; pop - remove TOS
;
; group: stackbasic
;
; ( obj1 -- )
;
; example
;   % status: true or false
;   "bad" status { pop "ok" } if	% "bad" or "ok"
;

		bits 32

prim_pop:
		cmp dword [pstack.ptr],1
		mov bp,pserr_pstack_underflow
		jc prim_pop_90
		dec dword [pstack.ptr]
prim_pop_90:
		ret


;; dup - duplicate TOS
;
; group: stackbasic
;
; ( obj1 -- obj1 obj1 )
;
; example
;   key		% key: some input value
;   dup 'a' eq { do_a } if	% if key = 'a'
;   dup 'b' eq { do_b } if	% if key = 'b'
;   dup 'c' eq { do_c } if	% if key = 'c'
;   pop
;

		bits 32

prim_dup:
		mov ecx,[pstack.ptr]
		cmp ecx,[pstack.size]
		cmc
		mov bp,pserr_pstack_overflow
		jb prim_dup_90
		xor ecx,ecx
		call get_pstack_tos
		mov bp,pserr_pstack_underflow
		jc prim_dup_90
		xor ecx,ecx
		inc dword [pstack.ptr]
		call set_pstack_tos
prim_dup_90:
		ret


;; over - copy TOS-1
;
; group: stackbasic
;
; ( obj1 obj2 -- obj1 obj2 obj1 )
;

		bits 32

prim_over:
		mov ecx,[pstack.ptr]
		cmp ecx,[pstack.size]
		cmc
		mov bp,pserr_pstack_overflow
		jb prim_over_90
		mov ecx,1
		call get_pstack_tos
		mov bp,pserr_pstack_underflow
		jc prim_over_90
		xor ecx,ecx
		inc dword [pstack.ptr]
		call set_pstack_tos
prim_over_90:
		ret


;; index - copy stack element
;
; group: stackbasic
;
; ( objN ... obj1 int1 -- objN ... obj1 objM )
;
; objM: M = int1 + 1
;
; example
;   /dup { 0 index } def
;   /over { 1 index } def
;

		bits 32

prim_index:
		mov dl,t_int
		call get_1arg
		jc prim_index_90

		mov edx,[pstack.ptr]
		sub edx,2
		jc prim_index_90
		cmp edx,eax
		mov bp,pserr_pstack_underflow
		jc prim_index_90

		lea ecx,[eax+1]
		call get_pstack_tos
		xor ecx,ecx
		call set_pstack_tos
prim_index_90:
		ret


;; exec - evaluate object
;
; group: control
;
; ( dict1 -- )
; ( obj1 -- obj1 )
;
; If obj1 is a dictionary entry, it is looked up and evaluated. If not, the stack is
; left unchanged.
;
; Note: Unlike Postscript, no cvx is necessary. And it works only with
; dictionary references.
;
; example
;
;   /foo [ /bar 100 "abc" ] def
;   foo 0 get				% /bar
;   exec				% run bar
;   foo 2 get				% "abc"
;   exec				% still "abc"
;

		bits 32

prim_exec:
		mov dl,t_none
		call pr_setobj_or_none
		cmp dl,t_dict_idx
		jz prim_exec_50
		jmp pr_getobj
prim_exec_50:
		mov [pscode_eval],eax
		ret


;; add - addition
;
; group: arith
;
; ( int1 int2 -- int3 )
; ( string1 int4 -- string2 )
; ( ptr1 int5 -- ptr2 )
;
; int3: int1 + int2
; string2: substring of string1 at offset int4
;
; Note: Strings are treated as byte sequences, not Unicode chars. Sizes of string1 and ptr1 are not
; checked.
;
; example
;   1 2 add		% 3
;
;   "abc" 1 add		% "bc"
;

		bits 32

prim_add:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jnc prim_add_50
		cmp dx,t_int + (t_string << 8)
		jz prim_add_50
		cmp dx,t_int + (t_ptr << 8)
		stc
		jnz prim_add_90
prim_add_50:
		add eax,ecx
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,dh
		call set_pstack_tos
prim_add_90:
		ret


;; sub - subtraction
;
; group: arith
;
; ( int1 int2 -- int3 )
; ( string1 int4 -- string2 )
; ( ptr1 int5 -- ptr2 )
; ( string3 string4 -- int6 )
; ( ptr2 ptr3 -- int7 )
;
; int3: int1 - int2
; string2: substring of string1 at offset -int4
; int6: string3 - string4
; int7: ptr2 - ptr3
;
; Note: Strings are treated as byte sequences, not Unicode chars. Boundaries of string1 and ptr1 are not
; checked.
;
; example
;   3 1 sub		% 2
;
;   "abcd" 3 add	% "d"
;   2 sub		% "bcd"
;

		bits 32

prim_sub:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jnc prim_sub_50
		cmp dx,t_int + (t_string << 8)
		jz prim_sub_50
		cmp dx,t_int + (t_ptr << 8)
		jz prim_sub_50
		cmp dx,t_ptr + (t_ptr << 8)
		jz prim_sub_40
		cmp dx,t_string + (t_string << 8)
		stc
		jnz prim_sub_90
prim_sub_40:
		mov dh,t_int
prim_sub_50:
		xchg eax,ecx
		sub eax,ecx
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,dh
		call set_pstack_tos
prim_sub_90:
		ret


;; mul - multiplication
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: int1 * int2
;
; example
;   2 3 mul	% 6
;

		bits 32

prim_mul:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_mul_90
		imul ecx
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,t_int
		call set_pstack_tos
prim_mul_90:
		ret


;; div - division
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: int1 / int2
;
; example
;   17 3 div	% 5
;

		bits 32

prim_div:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_div_90
		or eax,eax
		stc
		mov bp,pserr_div_by_zero
		jz prim_div_90
		xchg eax,ecx
		cdq
		idiv ecx
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,t_int
		call set_pstack_tos
prim_div_90:
		ret


;; mod - remainder
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: int1 % int2
;
; example
;   17 3 mod	% 2
;

		bits 32

prim_mod:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_mod_90
		or eax,eax
		stc
		mov bp,pserr_div_by_zero
		jz prim_div_90
		xchg eax,ecx
		cdq
		idiv ecx
		xchg eax,edx
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,t_int
		call set_pstack_tos
prim_mod_90:
		ret


;; neg - negation
;
; group: arith
;
; ( int1 -- int2 )
;
; int2: -int1
;
; example
;   5 neg	% -5
;

		bits 32

prim_neg:
		mov dl,t_int
		call get_1arg
		jc prim_neg_90
		neg eax
		xor ecx,ecx
		call set_pstack_tos
prim_neg_90:
		ret


;; abs - absolute value
;
; group: arith
;
; ( int1 -- int2 )
;
; int2: |int1|
;
; example
;   -6 abs	% 6
;

		bits 32

prim_abs:
		mov dl,t_int
		call get_1arg
		jc prim_abs_90
		or eax,eax
		jns prim_abs_50
		neg eax
prim_abs_50:
		xor ecx,ecx
		call set_pstack_tos
prim_abs_90:
		ret


;; min - minimum
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: min(int1, int2)
;
; example
;   4 11 min	% 4
;

		bits 32

prim_min:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_min_90
		cmp eax,ecx
		jle prim_min_50
		xchg eax,ecx
prim_min_50:
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
prim_min_90:
		ret


;; max - maximum
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: max(int1, int2)
;
; example
;   4 11 max	% 11
;

		bits 32

prim_max:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_max_90
		cmp eax,ecx
		jge prim_max_50
		xchg eax,ecx
prim_max_50:
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
prim_max_90:
		ret


		bits 32

plog_args:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jnc plog_args_90
		cmp dx,t_int + (t_bool << 8)
		jz plog_args_20
		cmp dx,t_bool + (t_int << 8)
		jz plog_args_20
		cmp dx,t_bool + (t_bool << 8)
		jz plog_args_20
		stc
		pop eax			; don't return
		jmp plog_args_90
plog_args_20:
		mov dl,t_bool
		or eax,eax
		setnz al
		movzx eax,al
		or ecx,ecx
		setnz cl
		movzx ecx,cl
plog_args_90:
		ret


;; and - logical or arithmetical 'and'
;
; group: arith
;
; ( int1 int2 -- int3 )
; ( bool1 bool2 -- bool3 )
;
; int3: int1 &amp; int2
; bool3: bool1 &amp;&amp; bool2
;
; Note: Mixing boolean and integer argument types is possible, in this case integers are
; converted to boolean first.
;
; example
;   true false and	% false
;
;   3 6 and		% 2
;
;   10 true and		% gives true, but please avoid this
;

		bits 32

prim_and:
		call plog_args
		and eax,ecx
prim_and_50:
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
		ret


;; or - logical or arithmetical 'or'
;
; group: arith
;
; ( int1 int2 -- int3 )
; ( bool1 bool2 -- bool3 )
;
; int3: int1 | int2
; bool3: bool || bool2
;
; Note: Mixing boolean and integer argument types is possible, in this case integers are
; converted to boolean first.
;
; example
;   true false or	% true
;
;   3 6 or		% 7
;
;   10 true or		% gives true, but please avoid this
;

		bits 32

prim_or:
		call plog_args
		or eax,ecx
		jmp prim_and_50


;; xor - logical or arithmetical exclusive 'or'
;
; group: arith
;
; ( int1 int2 -- int3 )
; ( bool1 bool2 -- bool3 )
;
; int3: int1 ^ int2
; bool3: bool ^^ bool2
;
; Note: Mixing boolean and integer argument types is possible, in this case integers are
; converted to boolean first.
;
; example
;   true false xor	% true
;
;   3 6 xor		% 5
;
;   10 true xor		% gives false, but please avoid this
;

		bits 32

prim_xor:
		call plog_args
		xor eax,ecx
		jmp prim_and_50


;; not - logical or arithmetical 'not'
;
; group: arith
;
; ( int1 -- int2 )
; ( bool1 -- bool2 )
;
; int2: -int1 - 1
; bool2: !bool1
;
; example
;   true not		% false
;
;   0 not		% -1
;

		bits 32

prim_not:
		xor ecx,ecx
		call get_pstack_tos
		jc prim_not_90
		cmp dl,t_int
		jz prim_not_50
		cmp dl,t_bool
		mov bp,pserr_wrong_arg_types
		stc
		jnz prim_not_90
		xor al,1
		not eax
prim_not_50:
		not eax
		xor ecx,ecx
		call set_pstack_tos
prim_not_90:
		ret


;; shl - shift left
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: int1 &lt;&lt; int2
;
; example
;   5 2 shl	% 20
;

		bits 32

prim_shl:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_shl_90
		xchg eax,ecx
		shl eax,cl
		cmp ecx,byte 20h
		jb prim_shl_50
		xor eax,eax
prim_shl_50:
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
prim_shl_90:
		ret


;; shr - shift right
;
; group: arith
;
; ( int1 int2 -- int3 )
;
; int3: int1 >> int2
;
; example
;   15 2 shr	% 3
;

		bits 32

prim_shr:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_shr_90
		xchg eax,ecx
		cmp ecx,byte 20h
		jb prim_shr_50
		mov cl,1fh
prim_shr_50:
		sar eax,cl
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
prim_shr_90:
		ret


;; def - define new word
;
; group: code
;
; ( dict1 obj1  -- )
;
; dict1: is defined as obj1
;
; example
;   /x 100 def		% define constant x as 100
;
;   /neg { -1 mul } def	% define 'neg' function
;

		bits 32

prim_def:
		mov dx,t_none + (t_dict_idx << 8)
		call get_2args
		jc prim_def_90
		cmp dl,t_sec
		mov bp,pserr_wrong_arg_types
		stc
		jz prim_def_90
		; note: ecx is index
		call set_dict_entry
		mov bp,pserr_invalid_dict
		jc prim_def_90
		sub dword [pstack.ptr],2
prim_def_90:
		ret


;; if - typical 'if'
;
; group: control
;
; ( bool1 code1 -- )
; ( int1 code1 -- )
; ( undef1 code1 -- )
; ( obj1 code1 -- )
;
; bool1: contition
; code1: code start marker (see @{)
; int1: integer are automatically converted to boolean
; undef1: the undefined value is treated as 'false'
; obj1: strings, arrays, pointer are considered 'true'
;
; example
;   10 4 gt { "10 > 4" show } if
;
;   "" { "is always true" show } if	% strings are always 'true'
;

		bits 32

prim_if:
		mov dx,t_code + (t_bool << 8)
		call get_2args
		jnc prim_if_20
		cmp dh,t_int
		jz prim_if_20
		cmp dh,t_none
		jz prim_if_20
		mov cl,1			; all pointer, strings, arrays  are 'true'
		cmp dh,t_ptr
		jz prim_if_20
		cmp dh,t_string
		jz prim_if_20
		cmp dh,t_array
		jnz prim_if_80
prim_if_20:
		sub dword [pstack.ptr],2
		or ecx,ecx
		jz prim_if_90
		
		; branch
		xchg eax,[pscode_next_instr]

		mov ecx,[rstack.ptr]
		cmp ecx,[rstack.size]
		mov bp,pserr_rstack_overflow
		jae prim_if_80
		inc dword [rstack.ptr]

		xor ecx,ecx
		mov dl,t_if			; mark as 'if' block
		call set_rstack_tos
		jnc prim_if_90

prim_if_80:
		stc
prim_if_90:
		ret


;; ifelse - typical 'if' / 'else'
;
; group: control
;
; ( bool1 code1 code2 -- )
; ( int1 code1 code2 -- )
; ( undef1 code1 code2 -- )
; ( obj1 code1 code2 -- )
;
; bool1: contition
; code1: code start marker (see @{) for 'true' branch
; code2: code start marker (see @{) for 'false' branch
; int1: integer are automatically converted to boolean
; undef1: the undefined value is treated as 'false'
; obj1: strings, arrays, pointer are considered 'true'
;
; example
;   x1 x2 gt { "x1 > x2" } { "x1 &lt;= x2" } ifelse show
;

		bits 32

prim_ifelse:
		mov ecx,2
		call get_pstack_tos
		jc prim_ifelse_90
		mov bp,pserr_wrong_arg_types
		cmp dl,t_bool
		jz prim_ifelse_10
		cmp dl,t_int
		jz prim_ifelse_10
		cmp dl,t_none
		jz prim_ifelse_10
		mov al,1			; all pointer, strings, arrays  are 'true'
		cmp dl,t_ptr
		jz prim_ifelse_10
		cmp dl,t_string
		jz prim_ifelse_10
		cmp dl,t_array
		jnz prim_ifelse_80
prim_ifelse_10:
		push eax
		mov dx,t_code + (t_code << 8)
		call get_2args
		pop ebx
		jc prim_ifelse_90

		sub dword [pstack.ptr],3
		or ebx,ebx
		jz prim_ifelse_20
		xchg dl,dh
		xchg eax,ecx
prim_ifelse_20:
		; branch
		xchg eax,[pscode_next_instr]

		mov ecx,[rstack.ptr]
		cmp ecx,[rstack.size]
		mov bp,pserr_rstack_overflow
		jae prim_ifelse_80
		inc dword [rstack.ptr]

		xor ecx,ecx
		mov dl,t_if			; mark as 'if' block
		call set_rstack_tos
		jnc prim_ifelse_90

prim_ifelse_80:
		stc
prim_ifelse_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Compare 2 strings.
;
;  eax, ecx	strings
;
; return:
;  al, cl	last compared chars (if !=)
;  edx		length of identical parts
;

		bits 32

pcmp_str:
		mov esi,eax
		mov edi,ecx

		xor ecx,ecx
		xor eax,eax
		xor edx,edx
pcmp_str_20:
		mov ah,al
		mov ch,cl
		mov al,[es:esi]
		mov cl,[es:edi]
		cmp al,cl
		jnz pcmp_str_50
		or al,al
		jz pcmp_str_50
		or cl,cl
		jz pcmp_str_50
		inc esi
		inc edi
		inc edx
		jnz pcmp_str_20
pcmp_str_50:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Compare 2 objects.
;

		bits 32

pcmp_args:
		; integer
		mov dx,t_int + (t_int << 8)
		push ebx
		call get_2args
		pop ebx
		jnc pcmp_args_90

		; strings
		cmp dx,t_string + (t_string << 8)
		jz pcmp_args_60

		; two identical objects
		cmp dl,dh
		jz pcmp_args_90

		cmp bl,1
		jc pcmp_args_80

		cmp eax,ecx
		jnz pcmp_args_90
		mov al,dl
		mov cl,dh
		jmp pcmp_args_90

pcmp_args_60:
		call pcmp_str
		jmp pcmp_args_90
pcmp_args_80:
		pop eax			; skip last return
pcmp_args_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Return 'true'
;

		bits 32

pcmp_true:
		mov eax,1
		jmp pcmp_false_10


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Return 'false'
;

		bits 32

pcmp_false:
		xor eax,eax
pcmp_false_10:
		mov dl,t_bool
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
		ret


;; eq - equal
;
; group: cmp
;
; ( int1 int2 -- bool1 )
; ( str1 str2 -- bool2 )
; ( obj1 obj2 -- bool3 )
;
; bool1: true if int1 == int2
; bool2: true if str1 == str2
; bool3: true if obj1 and obj2 are identical
;
; example
;
;   1 3 eq		% false
;   "abc" "abc" eq	% true
;   /a [ 1 2 ] def
;   /b a def
;   a [ 1 2 ] eq	% false (not the same array)
;   a b eq		% true
;

		bits 32

prim_eq:
		mov bl,1
		call pcmp_args
		cmp ecx,eax
		jz pcmp_true
		jmp pcmp_false


;; ne - not equal
;
; group: cmp
;
; ( int1 int2 -- bool1 )
; ( str1 str2 -- bool2 )
; ( obj1 obj2 -- bool3 )
;
; bool1: false if int1 == int2
; bool2: false if str1 == str2
; bool3: false if obj1 and obj2 are identical
;
; example
;
;   1 3 ne		% true
;   "abc" "abc" ne	% false
;   /a [ 1 2 ] def
;   /b a def
;   a [ 1 2 ] ne        % true (not the same array)
;   a b ne              % false
;

		bits 32

prim_ne:
		mov bl,1
		call pcmp_args
		cmp ecx,eax
		jnz pcmp_true
		jmp pcmp_false


;; gt - greater than
;
; group: cmp
;
; ( int1 int2 -- bool1 )
; ( str1 str2 -- bool2 )
; ( ptr1 ptr2 -- bool3 )
;
; bool1: true if int1 > int2
; bool2: true if str1 > str2
; bool3: true if ptr1 > ptr2
;
; example
;   7 4 gt		% true
;   "abc" "abd" gt	% false
;   /a 10 malloc def
;   /b a + 2 def
;   b a gt		% true
;

		bits 32

prim_gt:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jg pcmp_true
		jmp pcmp_false


;; ge - greater or equal
;
; group: cmp
;
; ( int1 int2 -- bool1 )
; ( str1 str2 -- bool2 )
; ( ptr1 ptr2 -- bool3 )
;
; bool1: true if int1 >= int2
; bool2: true if str1 >= str2
; bool3: true if ptr1 >= ptr2
;
; example
;   7 4 ge		% true
;   "abc" "abc" ge	% true
;   /a 10 malloc def
;   /b a + 2 def
;   b a ge		% true
;

		bits 32

prim_ge:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jge pcmp_true
		jmp pcmp_false


;; lt - less than
;
; group: cmp
;
; ( int1 int2 -- bool1 )
; ( str1 str2 -- bool2 )
; ( ptr1 ptr2 -- bool3 )
;
; bool1: true if int1 &lt; int2
; bool2: true if str1 &lt; str2
; bool3: true if ptr1 &lt; ptr2
;
; example
;   7 4 lt		% false
;   "abc" "abd" lt	% true
;   /a 10 malloc def
;   /b a + 2 def
;   b a lt		% false
;

		bits 32

prim_lt:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jl pcmp_true
		jmp pcmp_false


;; le - less or equal
;
; group: cmp
;
; ( int1 int2 -- bool1 )
; ( str1 str2 -- bool2 )
; ( ptr1 ptr2 -- bool3 )
;
; bool1: true if int1 &lt;= int2
; bool2: true if str1 &lt;= str2
; bool3: true if ptr1 &lt;= ptr2
;
; example
;   7 7 le		% true
;   "abc" "abd" le	% true
;   /a 10 malloc def
;   /b a + 2 def
;   b a le		% false
;

		bits 32

prim_le:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jle pcmp_true
		jmp pcmp_false


;; exch - exchange TOS with TOS-1
;
; group: stackbasic
;
; ( obj1 obj2 -- obj2 obj1 )
;
; example
;   8
;   /a exch def		% a = 8
;

		bits 32

prim_exch:
		mov ecx,2
		call rot_pstack_up
		mov bp,pserr_pstack_underflow
		ret


;; rot - rotate TOS, TOS-1, TOS-2
;
; group: stackbasic
;
; ( obj1 obj2 obj3 -- obj2 obj3 obj1 )
;
; example
;   /a 4 array def
;   8
;   a 1 rot put		% a[1] = 8
;

		bits 32

prim_rot:
		mov ecx,3
		call rot_pstack_up
		mov bp,pserr_pstack_underflow
		ret


;; roll - rotate stack elements
;
; group: stackbasic
;
; ( obj1 ... objN int1 int2 -- objX ... objY )
;
; int1: number of elements to rotate
; int2: amount
; objX: X = (1 - int2) mod int1
; objY: Y = (N - int2) mod int1
;
; example
;   /rot { 3 -1 roll } def
;  1 2 3 4 5 5 2 roll		% leaves: 4 5 1 2 3
;

		bits 32

prim_roll:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_roll_90
		or ecx,ecx
		jz prim_roll_90
		mov edx,[pstack.ptr]
		sub edx,2
		cmp edx,ecx
		mov bp,pserr_pstack_underflow
		jc prim_roll_90
		cdq
		idiv ecx
		sub dword [pstack.ptr],2
		or edx,edx
		jz prim_roll_90
		js prim_roll_50
prim_roll_40:
		push edx
		push ecx
		call rot_pstack_down
		pop ecx
		pop edx
		dec edx
		jnz prim_roll_40
		jmp prim_roll_90
prim_roll_50:
		neg edx
prim_roll_60:
		push edx
		push ecx
		call rot_pstack_up
		pop ecx
		pop edx
		dec edx
		jnz prim_roll_60
		clc
prim_roll_90:
		ret


;; dtrace - single step with debug window
;
; group: debug
;
; ( -- )
;
; Turn on @trace mode and show debug info in upper left screen corner.
;

		bits 32

prim_dtrace:
		mov byte [single_step],1
		mov byte [show_debug_info],1
		inc byte [dtrace_count]
		ret


;; trace - single step
;
; group: debug
;
; ( -- )
;
; Enter single step mode. Waits for a keypress after every instruction. 
; Tab sets a temporary breakpoint after the current instruction and
; continues until it reaches it. Leave this mode by pressing Esc.
;

		bits 32

prim_trace:
		mov byte [single_step],1
		mov byte [show_debug_info],0
		ret


;; return - leave current function
;
; group: control
;
; ( -- )
;
; example
;   /x {		% expects key on TOS
;     dup 'a' eq { pop do_a return } if
;     dup 'b' eq { pop do_b return } if
;     dup 'c' eq { pop do_c return } if
;     pop
;   } def
; 

		bits 32

prim_return:
		xor ecx,ecx
prim_return_10:
		push ecx
		call get_rstack_tos
		pop ecx
		mov bp,pserr_rstack_underflow
		jc prim_return_90
		inc ecx
		cmp dl,t_code
		jnz prim_return_10		; skip if, loop, repeat, for, forall

		sub [rstack.ptr],ecx
		mov [pscode_next_instr],eax
prim_return_90:
		ret


;; exit - leave loop/repeat/for/forall loop.
;
; group: control
;
; ( -- )
;
; example
;
;  0 1 100 { 56 eq { exit } if } for	% leave if counter == 56
;

		bits 32

prim_exit:
		xor ecx,ecx
prim_exit_10:
		push ecx
		call get_rstack_tos
		pop ecx
		mov bp,pserr_rstack_underflow
		jc prim_exit_90
		inc ecx
		cmp dl,t_loop			; loop
		jz prim_exit_60
		cmp dl,t_repeat			; repeat
		jz prim_exit_40
		cmp dl,t_for			; for
		jz prim_exit_30
		cmp dl,t_forall			; forall
		jnz prim_exit_10
prim_exit_30:
		inc ecx
		inc ecx
prim_exit_40:
		inc ecx
prim_exit_60:
		push ecx
		call get_rstack_tos
		pop ecx
		cmp dl,t_code
		jz prim_exit_80
		cmp dl,t_exit
		mov bp,pserr_invalid_rstack_entry
		stc
		jnz prim_exit_90

prim_exit_80:
		inc ecx
		sub [rstack.ptr],ecx
		mov [pscode_next_instr],eax
prim_exit_90:
		ret

;; loop - endless loop
;
; group: control
;
; ( code1 -- )
;
; example
;
;     /x 0 def { /x x 1 add def x 56 eq { exit } if } loop	% loop until x == 56
;

		bits 32

prim_loop:
		xor ecx,ecx
		call get_pstack_tos
		cmp dl,t_code
		mov bp,pserr_wrong_arg_types
		stc
		jnz prim_loop_90

		dec dword [pstack.ptr]

		; branch
		xchg eax,[pscode_next_instr]

		mov ecx,[rstack.size]
		sub ecx,[rstack.ptr]
		cmp ecx,3
		mov bp,pserr_rstack_overflow
		jb prim_loop_90
		add dword [rstack.ptr],2

		mov dl,t_exit
		mov ecx,1
		call set_rstack_tos
		xor ecx,ecx
		mov dl,t_loop			; mark as 'loop' block
		mov eax,[pscode_next_instr]
		call set_rstack_tos
prim_loop_90:
		ret


;; repeat - repeat code
;
; group: control
;
; ( int1 code1 -- )
;
; Repeat code1 int1 times.
;
; example
;   3 { "X" show } repeat	% print "XXX"
;

		bits 32

prim_repeat:
		mov dx,t_code + (t_int << 8)
		call get_2args
		jc prim_repeat_90

		sub dword [pstack.ptr],2

		or ecx,ecx
		jz prim_repeat_90

		mov bp,pserr_invalid_range
		stc
		js prim_repeat_90

		; branch
		xchg eax,[pscode_next_instr]

		mov edx,[rstack.size]
		sub edx,[rstack.ptr]
		cmp edx,4
		mov bp,pserr_rstack_overflow
		jb prim_repeat_90
		add dword [rstack.ptr],3

		push eax
		xchg eax,ecx
		mov dl,t_int
		mov ecx,1
		call set_rstack_tos
		pop eax
		mov ecx,2
		mov dl,t_exit
		call set_rstack_tos
		xor ecx,ecx
		mov dl,t_repeat			; mark as 'repeat' block
		mov eax,[pscode_next_instr]
		call set_rstack_tos
prim_repeat_90:
		ret


;; for -- typical 'for' loop
;
; group: control
;
; ( int1 int2 int3 code1 -- )
;
; int1: start value
; int2: step size
; int3: final value (inclusive)
;
; Run code1 and put the current counter value onto the stack for every iteration.
;
; example
;  0 1 4 { } for 	% leave 0 1 2 3 4 on the stack
;

		bits 32

prim_for:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],4
		jc prim_for_90
		mov ecx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_for_90
		mov ecx,2
		push ebp
		push eax
		call get_pstack_tos
		pop edi
		pop ebp
		cmp dl,t_int
		stc
		jnz prim_for_90

		mov dx,t_code + (t_int << 8)
		push eax
		push edi
		call get_2args
		pop edi
		pop esi
		jc prim_for_90

		; don't remove start value!
		sub dword [pstack.ptr],3

		; branch
		xchg eax,[pscode_next_instr]

		mov edx,[rstack.size]
		sub edx,[rstack.ptr]
		cmp edx,6
		mov bp,pserr_rstack_overflow
		jb prim_for_90
		add dword [rstack.ptr],5

		push ecx
		push esi
		push edi

		mov dl,t_exit
		mov ecx,4
		call set_rstack_tos

		pop eax
		mov dl,t_int
		mov ecx,3
		call set_rstack_tos

		pop eax
		mov dl,t_int
		mov ecx,2
		call set_rstack_tos

		pop eax
		mov dl,t_int
		mov ecx,1
		call set_rstack_tos

		xor ecx,ecx
		mov dl,t_for			; mark as 'for' block
		mov eax,[pscode_next_instr]
		call set_rstack_tos
prim_for_90:
		ret


;; forall - loop over all array elements
;
; group: control
;
; ( array1 code 1 -- )
; ( str1 code 1 -- )
; ( ptr1 code 1 -- )
;
; Run code1 for every element of array1, str1 or ptr1 putting each element
; on the stack in turn.
;
; Note: str1 is treated as a sequence of bytes, not utf8 chars.
;
; example
;  [ 1 2 3 ] { } forall		% leave 1 2 3 on the stack
;

		bits 32

prim_forall:
		mov dx,t_code + (t_array << 8)
		call get_2args
		jnc prim_forall_30
		cmp dl,t_code
		stc
		jnz prim_forall_90
		cmp dh,t_string
		jz prim_forall_30
		cmp dh,t_ptr
		jz prim_forall_30
		cmp dh,t_none
		stc
		jnz prim_forall_90

		; nothing to do
prim_forall_20:
		sub dword [pstack.ptr],2
		clc
		jmp prim_forall_90

prim_forall_30:
		push eax			; code
		push ecx			; string/array
		xchg dl,dh
		push dx
		xchg eax,ecx
		call get_length
		pop dx
		pop ecx
		pop ebx

		mov bp,pserr_invalid_range
		jc prim_forall_90

		or eax,eax			; length == 0
		jz prim_forall_20

		sub dword [pstack.ptr],2

		; branch
		xchg ebx,[pscode_next_instr]

		mov esi,[rstack.size]
		sub esi,[rstack.ptr]
		cmp esi,6
		mov bp,pserr_rstack_overflow
		jb prim_forall_90
		add dword [rstack.ptr],5

		push ecx
		push edx
		push eax

		mov dl,t_exit
		xchg eax,ebx
		mov ecx,4
		call set_rstack_tos		; code

		pop eax
		mov dl,t_int
		mov ecx,2
		call set_rstack_tos		; length

		pop edx
		pop eax
		push eax
		push edx
		mov ecx,3
		call set_rstack_tos		; string/array

		xor eax,eax
		mov dl,t_int
		mov ecx,1
		call set_rstack_tos		; count

		xor ecx,ecx
		mov dl,t_forall			; mark as 'forall' block
		mov eax,[pscode_next_instr]
		call set_rstack_tos

		pop edx
		pop ecx
		xchg dl,dh
		xor eax,eax
		call p_get
		mov bp,pserr_invalid_range
		jc prim_forall_90

		jmp pr_getobj
prim_forall_90:
		ret


;; gettype - get object type
;
; group: arg
;
; ( obj1 -- int1 )
;
; Returns the object type.
;
; example
;   "abc" gettype	% 4 (= string)
;

		bits 32

prim_gettype:
		mov dl,t_none
		call get_1arg
		jc prim_gettype_90
		movzx eax,dl
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_gettype_90:
		ret


;; settype - set object type
;
; group: arg
;
; ( obj1 int1 -- obj2 )
;
; obj2: obj1 with type changed to int1.
; 
; example
;						% PS-like 'string' function
;   /string { 1 add malloc 4 settype } def	% 4 = string type
;   10 string					% new empty string of length 10
;

		bits 32

prim_settype:
		mov dx,t_int + (t_none << 8)
		call get_2args
		jc prim_settype_90
		mov dl,al
		and al,15
		xchg eax,ecx
		dec dword [pstack.ptr]
		xor ecx,ecx
		call set_pstack_tos
prim_settype_90:
		ret


;; screen.size - screen size in pixel
;
; group: gfx.screen
;
; ( -- int1 int2 )
;
; int1, int2: width, height
;
; example
;
; blue setcolor
; 0 0 moveto screen.size fillrect	% draw blue screen
;

		bits 32

prim_screensize:
		mov eax,[pstack.ptr]
		inc eax
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_screensize_90
		mov [pstack.ptr],eax
		mov dl,t_int
		movzx eax,word [screen_width]
		mov ecx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [screen_height]
		xor ecx,ecx
		call set_pstack_tos
prim_screensize_90:
		ret


;; vscreen.size - virtual screen size
;
; group: gfx.screen
;
; ( -- int1 int2 )
;
; int1, int2: virtual width and height
;
; You normally can expect the virtual height to be larger than the visible height returned by
; @screen.size. That area is available e.g. for hidden drawing. Some kind of
; scrolling is not implemented, however.
;

		bits 32

prim_vscreensize:
		mov eax,[pstack.ptr]
		inc eax
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_vscreensize_90
		mov [pstack.ptr],eax
		mov dl,t_int
		movzx eax,word [screen_width]
		mov ecx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [screen_vheight]
		xor ecx,ecx
		call set_pstack_tos
prim_vscreensize_90:
		ret


;; monitorsize - monitor size
;
; group: gfx.screen
;
; ( -- int1 int2 )
;
; int1, int2: width and height
;

		bits 32

prim_monitorsize:
		mov eax,[pstack.ptr]
		inc eax
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_monitorsize_90
		mov [pstack.ptr],eax

		cmp word [ddc_xtimings],0
		jnz prim_monitorsize_50

		call get_monitor_res

prim_monitorsize_50:

		mov dl,t_int
		movzx eax,word [ddc_xtimings]
		mov ecx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [ddc_xtimings + 2]
		xor ecx,ecx
		call set_pstack_tos
prim_monitorsize_90:
		ret


;; image.size - graphics image size
;
; group: image
;
; ( -- int1 int2 )
;
; int1, int2: image width and height. The image is specified with @setimage.
; 
; example
;
;  image.size screen.size
;  exch 4 -1 roll sub 2 div 3 1 roll exch sub 2 div	% center image
;  moveto 0 0 image.size image				% draw it
;

		bits 32

prim_imagesize:
		mov eax,[pstack.ptr]
		inc eax
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_imagesize_90
		mov [pstack.ptr],eax
		mov dl,t_int
		movzx eax,word [image_width]
		mov ecx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [image_height]
		xor ecx,ecx
		call set_pstack_tos
prim_imagesize_90:
		ret



;; image.colors - image palette entries
;
; group: image
;
; ( -- int1 )
;
; int1: number of colors in 8-bit PCX image.
;
; 8-bit modes use a color palette. An image uses the first @image.colors
; entries. If you want to define your own colors, use @image.colors to get
; the first free palette entry. For 16/32-bit modes, 0 is returned.
;

		bits 32

prim_imagecolors:
		xor eax,eax
		cmp byte [image_type],1
		jnz prim_imagecolors_90
		mov ax,[pals]
prim_imagecolors_90:
		jmp pr_getint


;; setcolor - set active drawing color
;
; group: draw
;
; ( int1 -- )
;
; int1: palette index (8-bit mode) or 24-bit RGB-value (16/32-bit modes).
;
; example
;  0xff0000 setcolor	% continue in red...
;  0xff00 setcolor	% or green...
;  0xff setcolor	% or blue
;

		bits 32

prim_setcolor:
		call pr_setint
		mov [gfx_color_rgb],eax
		call encode_color
		mov [gfx_color0],eax
		call setcolor
		ret


;; currentcolor - current drawing color
;
; group: draw
;
; ( -- int1 )
;
; int1: palette index (8-bit mode) or 24-bit RGB-value (16/32-bit modes).
;
; example
;   currentcolor not setcolor	% inverse color
;

		bits 32

prim_currentcolor:
		mov eax,[gfx_color0]
		call decode_color
		jmp pr_getint


;; settextmodecolor - set color to be used in text mode
;
; group: textmode
; 
; ( int1 -- )
;
; int1: text mode color
;
; Note: You only need this in case you're running in text mode (practically never).
;

		bits 32

prim_settextmodecolor:
		call pr_setint
		mov [textmode_color],al
		ret


;; moveto - set cursor position
;
; group: draw
;
; ( int1 int2 -- )
;
; int1, int2: x, y (upper left: 0, 0).
;
; example
;   200 100 moveto "Hello" show		% print "Hello" at (200, 100)
;

		bits 32

prim_moveto:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_moveto_90
		sub dword [pstack.ptr],2
		mov [gfx_cur_x],cx
		mov [gfx_cur_y],ax
prim_moveto_90:
		ret


;; rmoveto - set relative cursor position
;
; group: draw
;
; ( int1 int2 -- )
;
; int1, int2: x-ofs, y-ofs.
;
; example
;   200 100 moveto
;   "Hello" show
;   30 0 rmoveto "world!"	% "Hello    world!" (approx.)
;

		bits 32

prim_rmoveto:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_rmoveto_90
		sub dword [pstack.ptr],2
		add [gfx_cur_x],cx
		add [gfx_cur_y],ax
		clc
prim_rmoveto_90:
		ret


;; currentpoint - current cursor position
;
; group: draw
;
; ( -- int1 int2 )
;
; int1, int2: x, y (upper left: 0, 0)
;

		bits 32

prim_currentpoint:
		mov eax,[pstack.ptr]
		inc eax
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_currentpoint_90
		mov [pstack.ptr],eax
		mov dl,t_int
		movzx eax,word [gfx_cur_x]
		mov ecx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [gfx_cur_y]
		xor ecx,ecx
		call set_pstack_tos
prim_currentpoint_90:
		ret


;; lineto - draw line
;
; group: draw
;
; ( int1 int2 -- )
;
; int1, int2: line end
;
; example
;   0 0 moveto screen.size lineto	% draw diagonal
;

		bits 32

prim_lineto:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_lineto_90

		mov [line_x1],ecx
		mov [line_y1],eax
		push cx
		push ax
		movsx eax,word [gfx_cur_x]
		mov [line_x0],eax
		movsx eax,word [gfx_cur_y]
		mov [line_y0],eax
		call line
		pop word [gfx_cur_y]
		pop word [gfx_cur_x]

		sub dword [pstack.ptr],2
prim_lineto_90:
		ret



;; putpixel - draw single pixel
;
; group: draw
;
; ( -- )
;
; Draw pixel in current color at current cursor position.
;
; example
;   blue setcolor
;   0 0 moveto putpixel		% blue dot at upper left corner
;

		bits 32

prim_putpixel:
		push fs
		push gs

		call goto_xy
		call screen_segs
		call [setpixel_t]

		pop gs
		pop fs

		clc
		ret


;; getpixel - read pixel from graphics memory
;
; group: draw
;
; ( -- int1 )
;
; int1: color; either 8-bit palette index or 24-bit RGB-value, depending on
; graphics mode.
;
; example
;   getpixel not setcolor putpixel	% invert pixel color
;

		bits 32

prim_getpixel:
		push fs
		push gs

		call goto_xy
		call screen_segs
		call [getpixel]
		call decode_color

		pop gs
		pop fs

		jmp pr_getint


;; setfont - set font
;
; group: font
;
; ( ptr1 -- )
;
; ptr1: font data (e.g. font file).
;
; Note: If bit 31 in ptr1 is set, font is in 'password-mode' - it prints only '*'s.
;
; example
;   "16x16.fnt" findfile setfont	% set 16x16 font
;
;  /pwmode { 1 settype 0x80000000 or 12 settype } def
;  currentfont pwmode setfont		% now in password mode
;  "abc" show				% print "***"
;

		bits 32

prim_setfont:
		call pr_setptr_or_none
		call font_init
		ret


;; currentfont - get current font
;
; group: font
;
; ( -- ptr1 )
;
; ptr1: current font
;
; example
;   currentfont				% save font
;   "16x16_bold.fnt" findfile setfont	% set bold font
;   "bold text" show			% write something in bold font
;   setfont				% back to normal font
;

; FIXME: [font.properties] are lost
;

		bits 32

prim_currentfont:
		mov eax,[font]
		jmp pr_getptr_or_none


;; fontheight - font height
;
; group: font
;
; ( -- int1 )
;
; int1: font height
;
; example
;   currentpoint
;   "Hello" show			% print "Hello"
;   moveto 0 fontheight rmoveto
;   "world!"				% print "world!" below "Hello"
;

		bits 32

prim_fontheight:
		movzx eax,word [font.height]
		jmp pr_getint


;; setimage - set active image
;
; group: image
;
; ( ptr1 -- )
;
; ptr1: image data. Either JPG or PCX file.
;
; Note: JPG is only supported in 16/32-bit modes.
;
; example
;   "foo.jpg" findfile setimage		% load and use "foo.jpg"
;

		bits 32

prim_setimage:
		call pr_setptr_or_none
		call image_init
		ret


;; currentimage - currently used image
;
; group: image
;
; ( -- ptr1 )
;

		bits 32

prim_currentimage:
		mov eax,[image]
		jmp pr_getptr_or_none


;; settransparency - set transparency
;
; group: draw
;
; ( int1 -- )
;
; int1: transparency for @fillrect operations; valid values are 0 - 256.
;

		bits 32

prim_settransparency:
		call pr_setint
		mov [transp],eax
		ret


;; currenttransparency - current transparency
;
; group: draw
;
; ( -- int1 )
;

		bits 32

prim_currenttransparency:
		mov eax,[transp]
		jmp pr_getint


;; show - print text
;
; group: draw, text
;
; ( str1 -- )
;
; Print str1 in current color using current font.
;
; example
;   "Hello world!" show		% print "Hello world!"

		bits 32

prim_show:
		mov dl,t_string
		call get_1arg
		jc prim_show_90
		dec dword [pstack.ptr]
		mov esi,eax
		mov ebx,[start_row]
		or ebx,ebx
		jz prim_show_50
		cmp ebx,[cur_row2]
		jae prim_show_90
		mov esi,[row_text+4*ebx]
prim_show_50:
		call text_xy
		clc
prim_show_90:
		ret


;; strsize - text dimensions
;
; group: text
;
; ( str1 -- int1 int2 )
;
; int1, int2: width, height of str1.
;
; example
;
;   "Hi there!"
;   dup strsize pop neg 0 rmoveto show		% print "Hi there!" right aligned
;

		bits 32

prim_strsize:
		mov dl,t_string
		call get_1arg
		jc prim_strsize_90
		dec dword [pstack.ptr]

		mov esi,eax
		call str_size

		mov eax,[pstack.ptr]
		inc eax
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_strsize_90
		mov [pstack.ptr],eax
		push edx
		mov eax,ecx
		mov dl,t_int
		mov ecx,1
		call set_pstack_tos
		pop eax
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_strsize_90:
		ret


;; memcpy - copy memory
;
; group: mem
;
; ( ptr1 ptr2 int1 -- )
;
; ptr1: destination
; ptr2: source
; int1: size
;
; example
;   /a 10 malloc def
;   /b 10 malloc def
;   a 1 100 put		% a[1] = 100
;   b a 10 memcpy	% copy a to b
;

		bits 32

prim_memcpy:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],3
		jc prim_memcpy_90

		mov bp,pserr_wrong_arg_types
		mov ecx,2
		call get_pstack_tos
		cmp dl,t_ptr
		stc
		jnz prim_memcpy_90
		push eax
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		pop ebx			; dst
		jc prim_memcpy_90
		xchg eax,ecx

		; ecx: size
		; eax: src

		or ecx,ecx
		jz prim_memcpy_80

		mov esi,eax
		mov edi,ebx
		es rep movsb

prim_memcpy_80:
		sub dword [pstack.ptr],3
prim_memcpy_90:
		ret


;; image - show image region
;
; group: image
;
; ( int1 int2 int3 int4 -- )
;
; int1, int2: x, y position in image
;
; int3, int4: width, height of image region
;
; example
;   "xxx.jpg" findfile setimage		% load and activate "xxx.jpg"
;   0 0 image.size image		% draw whole image
;

		bits 32

prim_image:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],4
		jc prim_image_90
		mov ecx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_image_90
		mov [line_x0],eax
		mov ecx,2
		push ebp
		call get_pstack_tos
		pop ebp
		cmp dl,t_int
		stc
		jnz prim_image_90
		mov [line_y0],eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_image_90

		sub dword [pstack.ptr],4

		mov edx,[line_x0]
		add edx,ecx
		mov [line_x1],edx

		mov edx,[line_y0]
		add edx,eax
		mov [line_y1],edx

		call clip_image
		cmc
		jnc prim_image_90

		push dword [gfx_cur]
		call show_image
		pop dword [gfx_cur]

		clc
prim_image_90:
		ret


;; loadpalette - load current palette
;
; group: image
;
; ( -- )
;
; Activates current palette in 8-bit modes.
;

		bits 32

prim_loadpalette:
		mov ecx,100h
		xor edx,edx
		call load_palette
		clc
		ret


;; unpackimage -  unpack image region into buffer
;
; group: image
;
; ( int1 int2 int3 int4 -- ptr1 )
;
; int1, int2: x, y position in image
;
; int3, int4: width, height of image region
; ptr1: buffer with image data; use @free to free the buffer
;
; example
;
;   "xxx.jpg" findfile setimage		% load and activate "xxx.jpg"
;   0 0 10 10 unpackimage		% unpack upper left 10x10 region
;   /img exch def			% img = buffer
;
;  0 10 100 {
;    0 exch moveto
;    img restorescreen
;  } for				% repeat image section horizontally 10 times
;
;  img free				% free it
;

		bits 32

prim_unpackimage:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],4
		jc prim_unpackimage_90
		mov ecx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_unpackimage_90
		mov [line_x0],eax
		mov ecx,2
		push ebp
		call get_pstack_tos
		pop ebp
		cmp dl,t_int
		stc
		jnz prim_unpackimage_90
		mov [line_y0],eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_unpackimage_90

		sub dword [pstack.ptr],3

		mov edx,[line_x0]
		add edx,ecx
		mov [line_x1],edx
		mov edx,[line_y0]
		add edx,eax
		mov [line_y1],edx

		call clip_image

		jc prim_unpackimage_70

		mov eax,[line_y1]
		mov ecx,[line_x1]

		sub eax,[line_y0]
		sub ecx,[line_x0]

		call alloc_fb
		or eax,eax
		jz prim_unpackimage_70

		push eax
		call unpack_image
		pop eax

prim_unpackimage_60:
		mov dl,t_ptr
		or eax,eax
		jnz prim_unpackimage_80
prim_unpackimage_70:
		mov dl,t_none
		xor eax,eax
prim_unpackimage_80:

		xor ecx,ecx
		call set_pstack_tos
prim_unpackimage_90:
		ret


;; setpalette - set palette entry
;
; group: draw
;
; ( int1 int2 -- )
;
; int1: palette index
; int2: RGB value
;
; example
;   /red 11 0xff0000 def	% color 11 = red
;   /yellow 12 0xffff00 def	% color 12 = yellow
;

		bits 32

prim_setpalette:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_setpalette_90

		sub dword [pstack.ptr],2

		cmp ecx,100h
		jae prim_setpalette_90

		mov edx,ecx

		lea edi,[ecx+2*ecx]
		add edi,[gfx_pal]
		
		mov [es:edi+2],al
		mov [es:edi+1],ah
		shr eax,16
		mov [es:edi],al

		mov ecx,1
		call load_palette

		clc

prim_setpalette_90:
		ret


;; getpalette - get palette entry
;
; group: draw
;
; ( int1 -- int2 )
;
; int1: palette index
; int2: RGB value
;
; example
;   11 dup getpalette not setpalette	% invert color 11
;

		bits 32

prim_getpalette:
		mov dl,t_int
		call get_1arg
		jc prim_getpalette_90

		xchg eax,ecx
		xor eax,eax
		cmp ecx,100h
		jae prim_getpalette_50

		lea ecx,[ecx+2*ecx]
		add ecx,[gfx_pal]

		mov al,[es:ecx]
		shl eax,16
		mov ah,[es:ecx+1]
		mov al,[es:ecx+2]
prim_getpalette_50:
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_getpalette_90:
		ret


;; settransparentcolor - set color used for transparency
;
; group: image
;
; ( int1 -- )
;
; When doing an @image operation, pixels with this color are not copied.
; Something like an alpha channel, actually. Works only with PCX images.
; Not at all related to @settransparency.
;

		bits 32

prim_settransparentcolor:
		call pr_setint
		mov [transparent_color],eax
		ret


;; savescreen - save screen area
;
; group: image
;
; ( int1 int2 -- ptr1 )
;
; int1, int2: width, height of screen area
; ptr1: buffer with image data; use @free to free the buffer
;
; Note: width and height are stored in buffer.
;
; example
;   0 0 moveto screen.size savescreen	% save entire screen
;

		bits 32

prim_savescreen:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_savescreen_90
		call alloc_fb
		or eax,eax
		jz prim_savescreen_50
		push eax
		lea edi,[eax+4]
		call save_bg
		pop eax
prim_savescreen_50:
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,t_ptr
		or eax,eax
		jnz prim_savescreen_70
		mov dl,t_none
prim_savescreen_70:
		call set_pstack_tos
prim_savescreen_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Allocate drawing buffer.
;
; eax		height
; ecx		width
;
; return:
;  eax		buffer (0: failed)
;  dx, cx       width, height
;

		bits 32

alloc_fb:
		push eax
		push ecx
		mul ecx
		mul dword [pixel_bytes]
		pop edx
		pop ecx
		mov bp,pserr_invalid_image_size
		add eax,4
		jc alloc_fb_80
		push ecx
		push edx
		call calloc
		pop edx
		pop ecx
		or eax,eax
		jz alloc_fb_90
		mov [es:eax],dx
		mov [es:eax+2],cx
		jmp alloc_fb_90
alloc_fb_80:
		xor eax,eax
alloc_fb_90:
		ret


;; restorescreen - restore screen area
;
; group: image
;
; ( ptr1 -- )
;
; ptr1: buffer with image data; use @free to free the buffer
;
; Note: width and height are taken from buffer. Does not actually
; free ptr1 - use @free explicitly.
;
; example
;   0 0 moveto 100 100 savescreen	% save upper left 100x100 section...
;   300 200 moveto dup restorescreen	% and copy it to 300x200
;   free				% free memory
;

		bits 32

prim_restorescreen:
		mov dl,t_ptr
		call get_1arg
		jnc prim_restorescreen_20
		cmp dl,t_none
		stc
		jnz prim_restorescreen_90
		jmp prim_restorescreen_80

prim_restorescreen_20:

		mov dx,[es:eax]
		mov cx,[es:eax+2]
		lea edi,[eax+4]
		mov bx,dx
		imul bx,[pixel_bytes]
		call restore_bg

prim_restorescreen_80:
		dec dword [pstack.ptr]
		clc
prim_restorescreen_90:
		ret


;; malloc - allocate memory
;
; group: mem
;
; ( int1 -- ptr1 )
;
; int1:		memory size
; ptr1:		pointer to memory area
;
; Note: Use @free to free ptr1.
;
; example 
;   /foo 256 malloc def	% allocate 256 bytes...
;   foo free		% and free it
;

		bits 32

prim_malloc:
		mov dl,t_int
		call get_1arg
		jc prim_malloc_90
		call calloc
		or eax,eax
		stc
		mov bp,pserr_no_memory
		jz prim_malloc_90
		xor ecx,ecx
		mov dl,t_ptr
		call set_pstack_tos
prim_malloc_90:
		ret


;; free - free memory
;
; group: mem
;
; ( obj1 -- )
;
; obj1:		object to free, either array, string or pointer
;
; Note: There is no garbage collector implemented. You have to keep track of
; memory usage yourself. If obj1 does not refer to some dynamically
; allocated object, @free does nothing.
;
; example
; 2 array		% create array with 2 elements...
; free			% and free it
;
; 100 malloc		% allocate 100 bytes...
; free			% and free it
;
; "Some Text" free	% free nothing
;

		bits 32

prim_free:
		mov dl,t_string
		call get_1arg
		jnc prim_free_10
		cmp dl,t_ptr
		jz prim_free_10
		cmp dl,t_none
		jz prim_free_50
		cmp dl,t_array
		stc
		jnz prim_free_90
prim_free_10:
		call free
prim_free_50:
		dec dword [pstack.ptr]
		clc
prim_free_90:
		ret


;; memsize - report available memory size
;
; group: mem
;
; ( int1 -- int2 int3 )
;
; int1: memory region (0 ... 3)
; int2: total free memory
; int3: size of largest free block
;
; Region 0 is memory in the low 640kB range. Region >= 1 are typically 1 MB extended memory
; per region.
;
; Note: available memory depends on the boot loader.
;
; example
;   0 memsize pop 1024 lt { "less than 1kB left" show } if
;

		bits 32

prim_memsize:
		mov dl,t_int
		call get_1arg
		jc prim_memsize_90
		mov ecx,[pstack.ptr]
		inc ecx
		cmp [pstack.size],ecx
		mov bp,pserr_pstack_overflow
		jb prim_memsize_90
		mov [pstack.ptr],ecx

		call memsize

		mov dl,t_int
		xchg eax,ebp
		push edi
		mov ecx,1
		call set_pstack_tos
		pop eax
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_memsize_90:
		ret


;; dumpmem - dump memory usage to console
;
; group: mem
;
; ( -- )
;
; Note: useful only for debugging.
;

		bits 32

prim_dumpmem:
		call dump_malloc
		ret


;; fillrect - fill rectangular area
;
; group: draw
;
; ( int1 int2 -- )
;
; int1, int2: width, height
;
; example
;   0 0 moveto
;   blue setcolor
;   300 200 fillrect		% 300x200 blue rectangle
;

		bits 32

prim_fillrect:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_fillrect_90
		mov edx,ecx
		mov ecx,eax
		mov eax,[gfx_color]
		call fill_rect
		sub dword [pstack.ptr],2
prim_fillrect_90:
		ret


;; snprintf - C-style snprintf
;
; group: mem
;
; ( obj1 ... objN str1 int1 ptr1 -- )
;
; ptr1: buffer
; int1: buffer size
; str1: format string
;
; obj1 ... objN: printf arguments
;
; Note: reversed argument order!
;
; example
;
; /sprintf {
;   dup 12 settype length exch snprintf	% 12 = pointer type
; } def
;
; /buf 100 string def
; "bar" "foo" 3 "&#37;d &#37;s &#37;s" buf sprintf
; buf show				% print "3 foo bar"
; 

		bits 32

prim_snprintf:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],3
		jc prim_snprintf_90
		mov bp,pserr_wrong_arg_types
		mov ecx,2
		call get_pstack_tos
		cmp dl,t_string
		stc
		jnz prim_snprintf_90
		push eax
		mov dx,t_string + (t_int << 8)
		call get_2args
		pop esi
		jc prim_snprintf_90

		sub dword [pstack.ptr],3

		mov [pf_gfx_buf],eax
		mov [pf_gfx_max],ecx
		and dword [pf_gfx_cnt],0
		and word [pf_gfx_err],0

		or ecx,ecx
		jz prim_snprintf_40
		; clear buffer in case we have to print _nothing_
		mov byte [es:eax],0
prim_snprintf_40:
		mov byte [pf_gfx],1
		call printf
		mov byte [pf_gfx],0

		mov bp,[pf_gfx_err]
		cmp bp,0
prim_snprintf_90:
		ret


;; edit.init -- setup and show an editable input field
;
; group: edit
;
; ( array1 str1 -- )
;
; str1: initial input string value
; array1: (at least) 6-dimensional array: [ x y bg buf buf_size .undef ]. x, y: input field
; position; bg: background pixmap (created with @savescreen) - this determines the
; input field dimensions, too; buf: string buffer, large enough
; for a string of length buf_size. The last element is used internally.
;
; example
;   50 100 moveto 200 20 savescreen /bg exch def
;   /buf 100 string def
;   /ed [ 50 100 bg buf 100 .undef ] def
;   ed "foo" edit.init
;

		bits 32

prim_editinit:
		mov dx,t_string + (t_array << 8)
		call get_2args
		jc prim_editinit_90

		mov esi,ecx

		push eax
		call edit_init_params
		call edit_get_params
		pop eax

		mov bp,pserr_invalid_data
		jc prim_editinit_90

		push dword [gfx_cur]

		push esi
		mov esi,eax
		call edit_init
		pop esi

		pop dword [gfx_cur]

		call edit_put_params

		sub dword [pstack.ptr],2
prim_editinit_90:
		ret


;; edit.done - restore input field background
;
; group: edit
;
; ( array1 -- )
;
; array1: see @edit.init
;
; Note: does not free any data associated with array1.
;
; example
;   ed edit.done		% delete input field
;

		bits 32

prim_editdone:
		mov dl,t_array
		call get_1arg
		jc prim_editdone_90

		mov esi,eax
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_editdone_90

		push word [edit_x]
		pop word [gfx_cur_x]
		push word [edit_y]
		pop word [gfx_cur_y]
		mov dx,[edit_width]
		mov cx,[edit_height]
		mov edi,[edit_bg]
		add edi,4

		mov bx,dx
		imul bx,[pixel_bytes]
		push esi
		call restore_bg
		pop esi

		call edit_done_params

		sub word [pstack.ptr],byte 1
prim_editdone_90:
		ret


;; edit.showcursor - show input field cursor
;
; group: edit
;
; ( array1 -- )
;
; array1: see @edit.init
;

		bits 32

prim_editshowcursor:
		mov dl,t_array
		call get_1arg
		jc prim_editshowcursor_90

		mov esi,eax
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_editshowcursor_90

		or edi,edi
		jz prim_editshowcursor_50

		push dword [gfx_cur]
		call edit_show_cursor
		pop dword [gfx_cur]

prim_editshowcursor_50:

		sub dword [pstack.ptr],1
prim_editshowcursor_90:
		ret


;; edit.hidecursor - hide input field cursor
;
; group: edit
;
; ( array1 -- )
;
; array1: see @edit.init
;

		bits 32

prim_edithidecursor:
		mov dl,t_array
		call get_1arg
		jc prim_edithidecursor_90

		mov esi,eax
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_edithidecursor_90

		or edi,edi
		jz prim_edithidecursor_50

		push dword [gfx_cur]
		call edit_hide_cursor
		pop dword [gfx_cur]

prim_edithidecursor_50:

		sub dword [pstack.ptr],1
prim_edithidecursor_90:
		ret


;; edit.input - edit field input processing
;
; group: edit
;
; ( array1 int1 -- )
;
; array1: see @edit.init
; int1: key (bits 0-23 Unicode char, bits 24-31 scan code)
;
; example
;   /keyLeft 0x4b000000 def	% move cursor left
;   ed 'a' edit.input
;   ed keyLeft edit.input
;

		bits 32

prim_editinput:
		mov dx,t_int + (t_array << 8)
		call get_2args
		jc prim_editinput_90

		mov esi,ecx

		push eax
		call edit_get_params
		pop eax

		mov bp,pserr_invalid_data
		jc prim_editinput_90

		or edi,edi
		jz prim_editinput_50

		push esi

		push dword [gfx_cur]

		push eax
		call edit_hide_cursor
		pop eax

		call edit_input

		call edit_show_cursor

		pop dword [gfx_cur]

		pop esi

		call edit_put_params

prim_editinput_50:

		sub dword [pstack.ptr],2
prim_editinput_90:
		ret


;; sysconfig - get pointer to boot loader config data
;
; group: system
;
; ( -- ptr1 )
;
; ptr1: boot loader config data (32 bytes)
;

		bits 32

prim_sysconfig:
		mov eax,[boot.sysconfig]
		jmp pr_getptr_or_none


;; 64bit - test if we run on a 64-bit machine
;
; group: system
;
; ( -- int1 )
;
; int1 = 1: 64-bit architecture
;

		bits 32

prim_64bit:
		call chk_64bit
		sbb eax,eax
		inc eax
		jmp pr_getint


;; inbyte - get byte from i/o port
;
; group: system
;
; ( int1 -- int2 )
;
; int2: byte from port int1
;

		bits 32

prim_inbyte:
		mov dl,t_int
		call get_1arg
		jc prim_inbyte_90
		mov edx,eax
		xor eax,eax
		in al,dx
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_inbyte_90:
		ret


;; outbyte - write byte to i/o port 
;
; group: system
;
; ( int1 int2 -- )
;
; Write byte int2 to port int1.
;

		bits 32

prim_outbyte:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_outbyte_90
		mov edx,ecx
		out dx,al
		sub dword [pstack.ptr],2
prim_outbyte_90:
		ret


;; getbyte - get byte from memory
;
; group: system
;
; ( ptr1 -- int1 )
;
; int1: byte at ptr1
;

		bits 32

prim_getbyte:
		mov dl,t_ptr
		call get_1arg
		jc prim_getbyte_90
		movzx eax,byte [es:eax]
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_getbyte_90:
		ret


;; putbyte - write byte to memory 
;
; group: system
;
; ( ptr1 int1 -- )
;
; Write byte int1 at ptr1.
;

		bits 32

prim_putbyte:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jc prim_putbyte_90
		mov [es:ecx],al
		sub dword [pstack.ptr],2
prim_putbyte_90:
		ret


;; getdword - get dword from memory
;
; group: system
;
; ( ptr1 -- int1 )
;
; int1: dword at ptr1
;

		bits 32

prim_getdword:
		mov dl,t_ptr
		call get_1arg
		jc prim_getdword_90
		mov eax,[es:eax]
		mov dl,t_int
		xor ecx,ecx
		call set_pstack_tos
prim_getdword_90:
		ret


;; putdword - write dword to memory 
;
; group: system
;
; ( ptr1 int1 -- )
;
; Write dword int1 at ptr1.
;

		bits 32

prim_putdword:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jc prim_putdword_90
		mov [es:ecx],eax
		sub dword [pstack.ptr],2
prim_putdword_90:
		ret


;; findfile - load file
;
; group: mem
;
; ( str1 -- ptr1 )
;
; str1: file name
; ptr1: buffer with file data
;
; Note: ptr1 may or may not have to be free'd using @free, depending on whether it is
; actually loaded from file system or is part of the bootlogo archive. To be on the safe
; side, always free it.
;
; To get the file length, use @length on ptr1.
;
; example
;   "xxx.jpg" findfile length		% file size of "xxx.jpg"
;

		bits 32

prim_findfile:
		mov dl,t_string
		call get_1arg
		jc prim_findfile_90
prim_findfile_10:
		push eax
		call find_file
		pop ecx
		cmp bl,1
		jz prim_findfile_10		; symlink
		mov dl,t_ptr
		or eax,eax
		jnz prim_findfile_20
		xchg eax,ecx
		call find_file_ext
		mov dl,t_ptr
		or eax,eax
		jnz prim_findfile_20
		mov dl,t_none
prim_findfile_20:
		xor ecx,ecx
		call set_pstack_tos
prim_findfile_90:
		ret


;; filesize - get file size
;
; group: mem
;
; ( str1 -- int1 )
;
; str1: file name
; int1: file length (or .undef if not found)
;
; Note: Unlike @findfile, it doesn't load the file.
;
; example
;   "xxx.jpg" filesize		% file size of "xxx.jpg"
;

		bits 32

prim_filesize:
		mov dl,t_string
		call get_1arg
		jc prim_filesize_90
prim_filesize_10:
		push eax
		call find_file
		pop ecx
		cmp bl,1
		jz prim_filesize_10		; symlink
		or eax,eax
		jz prim_filesize_50
		call find_mem_size
prim_filesize_40:
		mov dl,t_int
		jmp prim_filesize_70
prim_filesize_50:
		xchg eax,ecx
		call file_size_ext
		cmp eax,-1
		jnz prim_filesize_40
		inc eax
		mov dl,t_none
prim_filesize_70:
		xor ecx,ecx
		call set_pstack_tos
prim_filesize_90:
		ret


;; getcwd - get current working directory
;
; group: mem
;
; ( -- str1 )
;
; str1: file name
;
; example
;   getcwd show		% print working directory
;

		bits 32

prim_getcwd:
		mov al,3
		call gfx_cb			; cwd (lin)
		or al,al
		jnz prim_getcwd_70
		mov eax,edx
		mov dl,t_string
		jmp prim_getcwd_90
prim_getcwd_70:
		mov dl,t_none
		xor eax,eax
prim_getcwd_90:
		jmp pr_getobj


;; chdir - set current working directory
;
; group: mem
;
; ( str1 -- )
;
; str1: file name
;
; example
;   "/foo/bar" chdir		% set working directory
;

		bits 32

prim_chdir:
		mov dl,t_string
		call get_1arg
		jc prim_chdir_90
		push eax
		call get_length
		xchg eax,ecx
		pop eax
		jc prim_chdir_60

		or ecx,ecx
		jz prim_chdir_60
		cmp ecx,64
		jae prim_chdir_60

		push ecx

		push eax
		mov al,0
		call gfx_cb			; get file name buffer address (edx)
		pop esi

		pop ecx

		or al,al
		jnz prim_chdir_60

		mov edi,edx

		es rep movsb
		mov al,0
		stosb

		mov al,4
		call gfx_cb
		or al,al

		mov bp,pserr_invalid_function
		jnz prim_chdir_70

		dec dword [pstack.ptr]
		jmp prim_chdir_90

prim_chdir_60:
		mov bp,pserr_invalid_data
prim_chdir_70:
		stc
prim_chdir_90:
		ret


;; _readsector - read sector
;
; group: system
;
; ( int1 -- ptr1 )
;
; int1: sector number
; ptr1: sector data
;
; Note: internal function. Returns pointer to static buffer. Does not return
; on error. Returns .undef if function is not implemented.
;

		bits 32

prim__readsector:
		mov dl,t_int
		call get_1arg
		jc prim__readsector_90

		mov edx,eax
		mov al,5
		call gfx_cb			; read sector (nr = edx)
		or al,al
		jz prim__readsector_50
		mov dl,t_none
		xor eax,eax
		jmp prim__readsector_80
prim__readsector_50:
		mov eax,edx
		mov dl,t_ptr
prim__readsector_80:
		xor ecx,ecx
		call set_pstack_tos
prim__readsector_90:
		ret


;; setmode - set video mode
;
; group: gfx.screen
;
; ( int1 -- bool1 )
;
; int1: VESA or VGA mode number
; bool1: true = mode is set, false = failed
;
; Note: if video mode setting fails, the old mode is restored, but the
; screen contents is undefined.
;

		bits 32

prim_setmode:
		mov dl,t_int
		call get_1arg
		jz prim_setmode_30
		cmp dl,t_none
		stc
		jnz prim_setmode_90
		xor eax,eax
		mov ecx,eax
		jmp prim_setmode_80
prim_setmode_30:
		xchg [gfx_mode],ax
		push eax
		call set_mode
		pop eax
		jnc prim_setmode_60
		xchg [gfx_mode],ax
		call set_mode
		stc
prim_setmode_60:
		sbb eax,eax
		inc eax

		mov cx,[screen_width]
		mov [clip_r],cx

		mov cx,[screen_vheight]
		mov [clip_b],cx

		xor ecx,ecx

		mov [clip_l],cx
		mov [clip_t],cx

prim_setmode_80:
		mov dl,t_bool
		call set_pstack_tos
prim_setmode_90:
		ret


;; currentmode - current video mode
;
; group: gfx.screen
;
; ( -- int1 )
;
; int1: current video mode number
;

		bits 32

prim_currentmode:
		movzx eax,word [gfx_mode]
		jmp pr_getint


;; videomodes - video mode list length
;
; group: gfx.screen
;
; ( -- int1 )
;
; int1: video mode list length (always >= 1)
;

		bits 32

prim_videomodes:
		mov esi,[vbe_mode_list]
		xor eax,eax

prim_videomodes_20:
		add esi,2
		inc eax
		cmp eax,1000h		; don't overdo
		jae prim_videomodes_30
		cmp word [es:esi-2],0xffff
		jnz prim_videomodes_20
		jmp prim_videomodes_40
prim_videomodes_30:
		xor eax,eax
prim_videomodes_40:
		jmp pr_getint


;; videomodeinfo - return video mode info
;
; group: gfx.screen
;
; ( int1 -- int2 int3 int4 int5 )
;
; int1: mode index
; int2, int3: width, height
; int4: color bits
; int5: mode number (bit 14: framebuffer mode) or .undef
;
; example
;   2 videomodeinfo
;

		bits 32

prim_videomodeinfo:
		mov dl,t_int
		call get_1arg
		jc prim_vmi_90

		mov ecx,[pstack.ptr]
		add ecx,3
		cmp [pstack.size],ecx
		mov bp,pserr_pstack_overflow
		jb prim_vmi_90
		mov [pstack.ptr],ecx

		cmp eax,100h
		jb prim_vmi_10
		mov ax,0ffh
prim_vmi_10:
		add eax,eax
		add eax,[vbe_mode_list]
		movzx ecx,word [es:eax]
		or ecx,ecx
		jz prim_vmi_60
		cmp ecx,-1
		jz prim_vmi_60

		mov eax,[vbe_buffer]
		mov edi,eax
		shr eax,4
		mov [rm_seg.es],ax
		and edi,0fh

		mov ax,4f01h
		push ecx
		int 10h
		pop ecx

		cmp ax,4fh
		jnz prim_vmi_60

		mov edi,[vbe_buffer]

		test byte [es:edi],1		; mode supported?
		jz prim_vmi_60

		mov eax,ecx
		and ax,~(1 << 14)
		cmp dword [es:edi+28h],0	; framebuffer start
		jz prim_vmi_20
		or ax,1 << 14
prim_vmi_20:
		mov dl,t_int
		xor ecx,ecx
		push edi
		call set_pstack_tos
		pop edi

		movzx eax,word [es:edi+12h]	; width
		mov dl,t_int
		mov ecx,3
		push edi
		call set_pstack_tos
		pop edi

		movzx eax,word [es:edi+14h]	; height
		mov dl,t_int
		mov ecx,2
		push edi
		call set_pstack_tos
		pop edi

		mov dl,[es:edi+1bh]		; color mode (aka memory model)
		mov dh,[es:edi+19h]		; color depth

		cmp dl,6			; direct color
		jnz prim_vmi_30
		cmp dh,32
		jz prim_vmi_40
		mov dh,[es:edi+1fh]		; red
		add dh,[es:edi+21h]		; green
		add dh,[es:edi+23h]		; blue
		jmp prim_vmi_40
prim_vmi_30:
		cmp dl,4			; PL8
		jnz prim_vmi_60
		mov dh,8
prim_vmi_40:
		movzx eax,dh

		mov dl,t_int
		mov ecx,1
		call set_pstack_tos
		jmp prim_vmi_90

prim_vmi_60:
		; no mode
		xor eax,eax
		mov dl,t_int
		mov ecx,3
		call set_pstack_tos
		xor eax,eax
		mov dl,t_int
		mov ecx,2
		call set_pstack_tos
		xor eax,eax
		mov dl,t_int
		mov ecx,1
		call set_pstack_tos
		xor eax,eax
		mov dl,t_none
		xor ecx,ecx
		call set_pstack_tos

prim_vmi_90:
		ret


;; sysinfo - return system info
;
; group: gfx.screen
;
; ( int1 -- obj1 )
;
; int1: info type
; obj1: info (or .undef)
;
; example
;   0 sysinfo		% video mem size in kb
;   1 sysinfo		% gfx card oem string
;   2 sysinfo		% gfx card vendor string
;   3 sysinfo		% gfx card product string
;   4 sysinfo		% gfx card revision string
;

		bits 32

prim_sysinfo:
		mov dl,t_int
		call get_1arg
		jc prim_si_90

		cmp eax,100h
		jae prim_si_20
		call videoinfo
		jmp prim_si_80
prim_si_20:



prim_si_70:
		mov dl,t_none
		xor eax,eax
prim_si_80:
		xor ecx,ecx
		call set_pstack_tos
prim_si_90:
		ret


;; colorbits - current pixel size
;
; group: gfx.screen
;
; ( -- int1 )
;
; int1: pixel size in bits
;

		bits 32

prim_colorbits:
		movzx eax,byte [color_bits]
		jmp pr_getint


;; eject  - eject CD-ROM
;
; group: system
;
; ( int1 -- int2 )
;
; int1: BIOS drive id
; int2: BIOS error code
;
; Note: does not work with all BIOSes. (With very few, actually.)
;

		bits 32

prim_eject:
		mov dl,t_int
		call get_1arg
		jc prim_eject_90
		mov dl,al
		mov ax,4600h
		int 13h
		xor ecx,ecx
		mov dl,t_int
		movzx eax,ah
		call set_pstack_tos
prim_eject_90:
		ret


;; poweroff  - switch computer off
;
; group: system
;
; ( -- )
;
; Note: uses APM, not ACPI.
;

		bits 32

prim_poweroff:
		mov ax,5300h
		xor ebx,ebx
		int 15h
		jc prim_poweroff_90
		mov ax,5304h
		xor ebx,ebx
		int 15h
		mov ax,5301h
		xor ebx,ebx
		int 15h
		jc prim_poweroff_90
		mov ax,530eh
		xor ebx,ebx
		mov cx,102h
		int 15h
		jc prim_poweroff_90
		mov ax,5307h
		mov cx,3
		mov bx,1
		int 15h
prim_poweroff_90:
		clc
		ret


;; reboot  - reboot computer
;
; group: system
;
; ( -- )
;

		bits 32

prim_reboot:
		mov word [es:472h],1234h
		pm_leave
		jmp 0ffffh:0
		pm_enter
		clc
		ret


;; strstr - find string in string
;
; group: string
;
; ( str1 str2 -- int1 )
;
; Search for str2 in str1.
; int1: offset of str2 in str1 + 1 if found; otherwise 0.
;
; Note: a bit strange, I know.
;
; example
;   "abcd" "c" strstr		% 3 (not 2)
;

		bits 32

prim_strstr:
		mov dx,t_string + (t_string << 8)
		call get_2args
		jc prim_strstr_90

		xor ebx,ebx

prim_strstr_20:
		push eax
		push ecx

		push ebx
		call pcmp_str
		pop ebx

		jz prim_strstr_50

		or al,al
		jnz prim_strstr_30

		or edx,edx
		jnz prim_strstr_50

prim_strstr_30:

		or cl,cl
		jz prim_strstr_40
		
		pop ecx
		pop eax

		inc ecx
		inc ebx
		jmp prim_strstr_20

prim_strstr_40:
		xor ebx,ebx
		jmp prim_strstr_60
prim_strstr_50:
		inc ebx
prim_strstr_60:
		add esp,2*4
		mov eax,ebx
		dec dword [pstack.ptr]
		xor ecx,ecx
		mov dl,t_int
		call set_pstack_tos

prim_strstr_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; sound primitives

;; sound.getvolume - current sound volume
;
; group: sound
;
; ( -- int1 )
;
; int1: volume (0 .. 100)
;

		bits 32

prim_soundgetvolume:
		mov eax,[pstack.ptr]
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_sgv_90
		mov [pstack.ptr],eax
		mov dl,t_int
		movzx eax,byte [sound_vol]
		xor ecx,ecx
		call set_pstack_tos
prim_sgv_90:
		ret


;; sound.setvolume - set sound volume
;
; group: sound
;
; ( int1 -- )
;
; int1: volume (0 .. 100)
;

		bits 32

prim_soundsetvolume:
		mov dl,t_int
		call get_1arg
		jc prim_ssv_90
		dec dword [pstack.ptr]
		or eax,eax
		jns prim_ssv_30
		xor eax,eax
prim_ssv_30:
		cmp eax,100
		jl prim_ssv_50
		mov eax,100
prim_ssv_50:
		or eax,eax
		jns prim_ssv_60
		xor eax,eax
prim_ssv_60:
		mov [sound_vol],al
		call mod_setvolume
		clc
prim_ssv_90:
		ret


;; sound.getsamplerate - current sample rate
;
; group: sound
;
; ( -- int1 )
;
; int1: sample rate
;

		bits 32

prim_soundgetsamplerate:
		mov eax,[pstack.ptr]
		inc eax
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_sgsr_90
		mov [pstack.ptr],eax
		mov dl,t_int
		movzx eax,byte [sound_sample]
		xor ecx,ecx
		call set_pstack_tos
prim_sgsr_90:
		ret


;; sound.setsamplerate - set sample rate
;
; group: sound
;
; ( -- int1 )
;
; int1: sample rate
;

		bits 32

prim_soundsetsamplerate:
		mov dl,t_int
		call get_1arg
		jc prim_sssr_90
		dec dword [pstack.ptr]
		push eax
		call sound_init
		pop eax
		call sound_setsample
		clc
prim_sssr_90:
		ret


;; sound.play - play sound
;
; group: sound
;
; ( -- )
;
; Note: obsolete. Sounds are played using the PC speaker.
;

		bits 32

prim_soundplay:
		call sound_init
		jc prim_splay_80
prim_splay_80:
		clc
prim_splay_90:
		ret


;; sound.done - turn off sound subsystem
;
; group: sound
;
; ( -- )
;

		bits 32

prim_sounddone:
		call sound_done
		clc
		ret


%if 0

		bits 32

prim_soundtest:
		mov dl,t_int
		call get_1arg
		jc prim_stest_90
		dec dword [pstack.ptr]

		mov [sound_x],eax
		call sound_test
		clc
prim_stest_90:
		ret
%endif


;; mod.load - assign mod file to player
;
; group: sound
;
; ( int1 ptr1 -- )
;
; int1: player
; ptr1: mod file
;

		bits 32

prim_modload:
		mov dx,t_ptr + (t_int << 8)
		call get_2args
		jc prim_modload_90
		sub dword [pstack.ptr],2
		xchg eax,ecx

		; ecx mod file
		; eax player

		push eax
		push ecx
		call sound_init
		pop edi
		pop eax
		jc prim_modload_80

		call mod_load
prim_modload_80:
		clc
prim_modload_90:
		ret


;; mod.play - play mod file
;
; group: sound
;
; ( int1 int2 -- )
;
; int1: player
; int2: song start
;
; Note: sounds are played using the PC speaker.
;

		bits 32

prim_modplay:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_modplay_90
		sub dword [pstack.ptr],2
		xchg eax,ecx

		; ecx start
		; eax player

		cmp byte [sound_ok],0
		jz prim_modplay_90

		mov ebx,ecx
		call mod_play

		clc
prim_modplay_90:
		ret


;; mod.playsample - play mod sample
;
; group: sound
;
; ( int1 int2 int3 int4 -- )
;
; int1: player
; int2: channel
; int3: sample number
; int4: pitch
;

		bits 32

prim_modplaysample:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],4
		jc prim_modps_90
		mov bp,pserr_wrong_arg_types

		mov ecx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		jnz prim_modps_90

		mov ecx,2
		push eax
		call get_pstack_tos
		pop ebx
		cmp dl,t_int
		stc
		jnz prim_modps_90

		mov dx,t_int + (t_int << 8)
		push ebx
		push eax
		call get_2args
		pop ebx
		pop edx
		jc prim_modps_90

		sub dword [pstack.ptr],4

		xchg eax,edx

		; 1: eax
		; 2: ebx
		; 3: ecx
		; 4: edx

		cmp byte [sound_ok],0
		jz prim_modps_90

		call mod_playsample

		clc
prim_modps_90:
		ret


;; settextwrap - set text wrap column
;
; group: text
;
; ( int1 -- )
;
; int1: text wrap column; set to 0 to turn text wrapping off.
;

		bits 32

prim_settextwrap:
		call pr_setint
		mov [line_wrap],eax
		ret


;; currenttextwrap - current text wrap column
;
; group: text
;
; ( -- int1 )
;
; int1: text wrap column
;

		bits 32

prim_currenttextwrap:
		mov eax,[line_wrap]
		jmp pr_getint


;; seteotchar - set alternative end-of-text char
;
; group: text
;
; ( int1 -- )
;
; int1: eot char
;
; Normally strings are 0 terminated. @seteotchar lets you define an
; additional char text functions recognize.
;

		bits 32

prim_seteotchar:
		call pr_setint
		mov [char_eot],eax
		ret


;; currenteotchar - current alternative end-of-text char
;
; group: text
;
; ( -- int1 )
;
; int1: eot char
;

		bits 32

prim_currenteotchar:
		mov eax,[char_eot]
		jmp pr_getint


;; setmaxrows - maximum number of text rows to display
;
; group: text
;
; ( int1 -- )
;
; int1: maximum number of text rows to display in a single @show command.
;

		bits 32

prim_setmaxrows:
		call pr_setint
		mov [max_rows],eax
		ret


;; currentmaxrows -- current maxium number of text rows to display
;
; group: text
;
; ( -- int1 )
;
; int1: maxium number of text rows to display in a single @show command.
;

		bits 32

prim_currentmaxrows:
		mov eax,[max_rows]
		jmp pr_getint


;; formattext -- format text
;
; group: text
;
; ( str1 -- )
;
; str1: text
;
; Preprocess text to find (and remember) line breaks, links and stuff.
;

		bits 32

prim_formattext:
		mov dl,t_string
		call get_1arg
		jc prim_formattext_90
		dec dword [pstack.ptr]
		push eax

		push es
		push ds
		pop es

		xor eax,eax
		mov ecx,max_text_rows
		mov edi,row_text
		rep stosd
		mov ecx,link_entries * li.size
		mov edi,link_list
		rep stosb

		pop es

		pop esi
		or byte [txt_state],2
		call text_xy
		and byte [txt_state],~2
		clc
prim_formattext_90:
		ret


;; gettextrows - number of text rows
;
; group: text
;
; ( -- int1 )
;
; int1: total number of text rows.
;
; Note: available after running @formattext.
;

		bits 32

prim_gettextrows:
		mov eax,[cur_row2]
		jmp pr_getint


;; setstartrow - set start row
;
; group: text
;
; ( int1 -- )
;
; int1: start row for next @show command.
;
; Note: if a start row > 0 is set, the argument to @show is irrelevant.
; Instead the internal data built during the last @formattext is used.
;

		bits 32

prim_setstartrow:
		call pr_setint
		mov [start_row],eax
		ret


;; getlinks -- number of links in text
;
; group: text
;
; ( -- int1 )
;
; int1: number of links in text.
;
; Note: available after running @formattext.
;

		bits 32

prim_getlinks:
		mov eax,[cur_link]
		jmp pr_getint


;; settextcolors -- set text markup colors
;
; group: text
;
; ( int1 int2 int3 int4 -- )
;
; int1: normal color
; int2: highlight color
; int3: link color
; int4: selected link color
; 
; Note: int1 can be changed using @setcolor, too.
;

		bits 32

prim_settextcolors:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],4
		jc prim_settextcolors_90
		mov ecx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_settextcolors_90
		call encode_color
		mov [gfx_color0],eax
		mov [gfx_color],eax
		mov ecx,2
		push ebp
		call get_pstack_tos
		pop ebp
		cmp dl,t_int
		stc
		jnz prim_settextcolors_90
		call encode_color
		mov [gfx_color1],eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_settextcolors_90

		sub dword [pstack.ptr],4

		call encode_color
		mov [gfx_color3],eax
		mov eax,ecx
		call encode_color
		mov [gfx_color2],eax

		clc
prim_settextcolors_90:
		ret


;; currenttextcolors - current text markup colors
;
; group: text
;
; ( -- int1 int2 int3 int4 )
;
; int1: normal color
; int2: highlight color
; int3: link color
; int4: selected link color
; 

		bits 32

prim_currenttextcolors:
		mov eax,[pstack.ptr]
		add eax,4
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_currenttextcolors_90
		mov [pstack.ptr],eax
		mov dl,t_int
		mov eax,[gfx_color3]
		call decode_color
		xor ecx,ecx
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color2]
		call decode_color
		mov ecx,1
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color1]
		call decode_color
		mov ecx,2
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color0]
		call decode_color
		mov ecx,3
		call set_pstack_tos
prim_currenttextcolors_90:
		ret


;; setlink - select link
;
; group: text
;
; ( int1 -- )
;
; int1: link number
;

		bits 32

prim_setlink:
		call pr_setint
		cmp eax,[cur_link]
		jae prim_setlink_90
		mov [sel_link],eax
prim_setlink_90:
		ret


;; currentlink - currently selected link
;
; group: text
;
; ( -- int1 )
;
; int1: selected link
;

		bits 32

prim_currentlink:
		mov eax,[sel_link]
		jmp pr_getint


;; getlink -- get link information
;
; group: text
;
; ( int1 -- str1 str2 int2 int3 )
;
; int1: link number
; str1: link label
; str2: link text
; int1: link text x-offset
; int2: link text row
;

		bits 32

prim_getlink:
		mov dl,t_int
		call get_1arg
		jc prim_getlink_90
		mov bp,pserr_invalid_range
		cmp eax,[cur_link]
		cmc
		jc prim_getlink_90
		shl eax,2
		lea edi,[link_list+2*eax+eax]		; li.size = 12 (3*4)
		mov eax,[pstack.ptr]
		add eax,3
		cmp [pstack.size],eax
		mov bp,pserr_pstack_overflow
		jb prim_getlink_90
		mov [pstack.ptr],eax

		mov dl,t_string
		mov eax,label_buf
		add eax,[prog.base]
		mov ecx,3
		call set_pstack_tos

		mov dl,t_string
		mov eax,[edi+li.text]
		mov ecx,2
		call set_pstack_tos

		mov dl,t_int
		movzx eax,word [edi+li.x]
		mov ecx,1
		call set_pstack_tos

		mov dl,t_int
		movzx eax,word [edi+li.row]
		xor ecx,ecx
		call set_pstack_tos

		mov esi,[edi+li.label]
		mov edi,label_buf
		mov ecx,32			; sizeof label_buf
prim_getlink_50:
		es lodsb
		cmp al,13h
		jz prim_getlink_60
		or al,al
		jz prim_getlink_60
		mov [edi],al
		inc edi
		loop prim_getlink_50
prim_getlink_60:
		mov byte [edi],0
		clc
prim_getlink_90:
		ret


;; lineheight - current line height
;
; group: font
;
; ( -- int1 )
;
; int1: line height
;

		bits 32

prim_lineheight:
		movzx eax,word [font.line_height]
		jmp pr_getint


;; currenttitle - current page title
;
; group: text
;
; ( -- str1 )
;
; str1: page title
;
; Note: available after running @formattext.
;

		bits 32

prim_currenttitle:
		mov eax,[page_title]
		mov dl,t_string
		jmp pr_getobj


;; usleep - sleep micro seconds
;
; group: system
;
; ( int1 -- )
;
; int1: micro seconds to sleep.
;
; Note: the actual granularity is 18Hz, so don't make up too sophisticated
; timings.
;

		bits 32

prim_usleep:
		call pr_setint
		mov ecx,54944/2
		add eax,ecx
		add ecx,ecx
		xor edx,edx
		div ecx
		; or eax,eax
		; jz prim_usleep_90
		mov ecx,eax
		push ecx
		call get_time
		pop ecx
		add ecx,eax
prim_usleep_20:
		push ecx
		call get_time
		pop ecx
		cmp eax,ecx
		jbe prim_usleep_20
prim_usleep_90:
		ret


;; notimeout - turn off initial boot loader timeout
;
; group: system
;
; ( -- )
;
; Turns off any automatic booting.
;

		bits 32

prim_notimeout:
		mov byte [input_notimeout],1
		clc
		ret


;; time - get current time
;
; group: system
;
; ( -- int1 )
;
; int1: time in seconds since midnight.
;

		bits 32

prim_time:
		call get_time
		jmp pr_getint


;; date - get current date
;
; group: system
;
; ( -- int1 )
;
; int1: date (bit 0-7: day, bit 8-15: month, bit 16-31: year)
;

		bits 32

prim_date:
		call get_date
		jmp pr_getint


;; idle - run stuff when idle
;
; group: system
;
; ( ptr1 int1 -- )
;
; ptr1: 'kroete' data
; int1: direction (0 or 1)
;
; Run 'kroete' animation while we're waiting for keyboard input.
;

		bits 32

prim_idle:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jnc prim_idle_10
		cmp dx,t_int + (t_none << 8)
		stc
		jnz prim_idle_90
prim_idle_10:
		sub dword [pstack.ptr],2
		cmp dh,t_none			; undef
		jnz prim_idle_50
		mov byte [idle.run],0
		mov eax,[idle.draw_buffer]
		or eax,eax
		jz prim_idle_80
		call free
		and dword [idle.draw_buffer],0
		jmp prim_idle_80
prim_idle_50:
		mov [idle.data1],ecx
		mov [idle.data2],eax

		mov byte [idle.invalid],1

		cmp dword [idle.draw_buffer],0
		jnz prim_idle_70

		mov ecx,kroete.width
		mov eax,kroete.height
		call alloc_fb
		mov [idle.draw_buffer],eax
		or eax,eax
		jz prim_idle_80

prim_idle_70:
		mov byte [idle.run],1
prim_idle_80:
		clc
prim_idle_90:
		ret


;; keepmode - keep video mode
;
; group: system
;
; ( int1 -- )
;
; int1 = 1: keep video mode when starting kernel.
;

		bits 32

prim_keepmode:
		call pr_setint
		mov [keep_mode],al
		ret


;; blend -- blend image with alpha channel
;
; group: image
;
; ( obj1 obj2 ptr3 -- )
;
; obj1: pointer to source image or color value
; obj2: pointer to alpha channel or transparency value
; ptr3: destination
;
; An image section of obj1 is copied to ptr3 using obj2 as alpha channel.
; obj1 may be a color value or an unpacked image (@unpackimage, @savescreen).
; obj2 may be a transparency value (0..255) or an unpacked image used as alpha channel.
; The current cursor position is used as offset into obj1 and obj2 if they are images.
; If both obj1 and obj2 are images, they must have the same dimensions.
;
; Note: 16/32-bit modes only.
;

		bits 32

prim_blend:
		mov bp,pserr_pstack_underflow
		cmp dword [pstack.ptr],3
		jc prim_blend_90

		and dword [tmp_var_0],0

		mov ecx,2
		call get_pstack_tos
		cmp dl,t_none
		jnz prim_blend_21
		xor eax,eax
		mov dl,t_int
prim_blend_21:
		cmp dl,t_ptr
		jz prim_blend_23
		or byte [tmp_var_0],1
		cmp dl,t_int
		jz prim_blend_23
prim_blend_22:
		stc
		mov bp,pserr_wrong_arg_types
		jmp prim_blend_90
prim_blend_23:
		mov [tmp_var_1],eax

		mov ecx,1
		call get_pstack_tos
		cmp dl,t_none
		jnz prim_blend_31
		xor eax,eax
		mov dl,t_int
prim_blend_31:
		cmp dl,t_ptr
		jz prim_blend_33
		or byte [tmp_var_0],2
		cmp dl,t_int
		jnz prim_blend_22
prim_blend_33:
		mov [tmp_var_2],eax

		xor ecx,ecx
		call get_pstack_tos
		cmp dl,t_none
		jnz prim_blend_35
		sub dword [pstack.ptr],3
		; CF = 0
		jmp prim_blend_90
prim_blend_35:
		cmp dl,t_ptr
		jnz prim_blend_22

		mov [tmp_var_3],eax

		sub dword [pstack.ptr],3

		; tmp_var_0: bit 0, 1: src type, alpha type (0 = ptr, 1 = int)
		; tmp_var_1: src
		; tmp_var_2: alpha
		; tmp_var_3: dst

		mov esi,[tmp_var_1]
		mov ebx,[tmp_var_2]

		mov al,[tmp_var_0]
		or al,al
		jnz prim_blend_60

		; check image domensions
		mov ecx,[es:esi]
		cmp ecx,[es:ebx]

		jnz prim_blend_22
prim_blend_60:
		mov edi,[tmp_var_3]

		; invalidates tmp_var_*
		call blend

		clc
prim_blend_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Helper function that covers common cases.

; return eax as ptr on stack, returns undef if eax = 0

		bits 32

pr_getptr_or_none:
		mov dl,t_ptr
		or eax,eax
		jnz pr_getobj
		mov dl,t_none
		jmp pr_getobj

; return eax as integer on stack
pr_getint:
		mov dl,t_int

; return eax as dl on stack
pr_getobj:
		mov ecx,[pstack.ptr]
		inc ecx
		cmp [pstack.size],ecx
		mov bp,pserr_pstack_overflow
		jc pr_getobj_90
		mov [pstack.ptr],ecx
		xor ecx,ecx
		call set_pstack_tos
pr_getobj_90:
		ret


; get ptr from stack as eax; if it is undef, don't return to function
pr_setptr_or_none:
		mov dl,t_ptr

; get obj from stack as eax; if it is undef, don't return to function
pr_setobj_or_none:
		call get_1arg
		jnc pr_setobj_20
		cmp dl,t_none
		stc
		jnz pr_setobj_10
		dec dword [pstack.ptr]
		clc
		jmp pr_setobj_10

; get integer from stack as eax
pr_setint:
		mov dl,t_int

; get object with type dl from stack as eax
pm_pr_setobj:
		call get_1arg
		jnc pr_setobj_20
pr_setobj_10:
		pop eax			; don't return to function that called us
		ret
pr_setobj_20:
		dec dword [pstack.ptr]
		pop ecx			; put link to clc on stack
		push dword pr_setobj_30
		jmp ecx
pr_setobj_30:
		clc
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get object size.
;
; eax, dl	obj, obj tyoe
;
; return:
;
;  eax		length
;   CF		0/1 ok/not ok
;

		bits 32

get_length:
		cmp dl,t_ptr
		jz get_length_10
		cmp dl,t_array
		jz get_length_20
		cmp dl,t_string
		jz get_length_30
		stc
		jmp get_length_90
get_length_10:
		call find_mem_size
		jmp get_length_80
get_length_20:
		movzx eax,word [es:eax]
		jmp get_length_80
get_length_30:
		xchg eax,esi
		xor ecx,ecx
		xor eax,eax
get_length_40:
		es lodsb
		call is_eot
		loopnz get_length_40
		not ecx
		xchg eax,ecx
get_length_80:
		clc
get_length_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Blend src & dst using alpha channel.
;
;  al		arg type; bit 0, 1: src, alpha (0 = ptr, 1 = int)
;  esi		src
;  ebx		alpha
;  edi		dst
;  word [gfx_cur_x]	offset into src
;  word [gfx_cur_y]	dto
;

		bits 32

blend:
		push dword [transp]

		cmp byte [pixel_bytes],2
		jz blend_10
		cmp byte [pixel_bytes],4
		jnz blend_90

blend_10:
		mov ebp,[es:edi]
		test al,2
		jnz blend_12
		mov ebp,[es:ebx]
blend_12:
		test al,1
		jnz blend_14
		mov ebp,[es:esi]
blend_14:

		mov [tmp_var_0],al
		mov [tmp_var_1],ebp		; width, height (src)

		push dword [es:edi]
		pop dword [tmp_var_2]		; width, height (dst)

		mov [tmp_var_3],esi		; color

		movzx eax,bl
		mov [transp],eax		; alpha transp

		movzx ebp,bp			; src width

		movzx eax,word [gfx_cur_y]
		mul ebp
		movzx ecx,word [gfx_cur_x]
		add eax,ecx
		imul eax,[pixel_bytes]
		add eax,4

		test byte [tmp_var_0],1
		jnz blend_16
		add esi,eax
blend_16:
		test byte [tmp_var_0],2
		jnz blend_17
		add ebx,eax
blend_17:

		add edi,4

		mov edx,blend_pixel_16
		cmp byte [pixel_bytes],2
		jz blend_18
		mov edx,blend_pixel_32
blend_18:
		movzx ecx,byte [tmp_var_0]
		and cl,3
		push dword [edx+ecx*4]
		pop dword [blend_pixel]

		mov cx,[tmp_var_2 + 2]		; dst height

blend_20:
		push cx

		mov dx,[tmp_var_2]		; dst width

blend_40:
		call [blend_pixel]

		add esi,[pixel_bytes]
		add ebx,[pixel_bytes]
		add edi,[pixel_bytes]

		dec dx
		jnz blend_40

		pop cx

		movzx eax,word [tmp_var_2]	; dst width
		sub eax,ebp			; src width
		imul eax,[pixel_bytes]

		sub esi,eax
		sub ebx,eax

		dec cx
		jnz blend_20

blend_90:
		pop dword [transp]

		ret


		align 4, db 0
blend_pixel	dd 0

blend_pixel_16	dd blend_pixel_00_16
		dd blend_pixel_01_16
		dd blend_pixel_10_16
		dd blend_pixel_11_16

blend_pixel_32	dd blend_pixel_00_32
		dd blend_pixel_01_32
		dd blend_pixel_10_32
		dd blend_pixel_11_32


; src: image, alpha: image
blend_pixel_00_16:
		mov ax,[es:ebx]
		call decode_color

		movzx eax,ah
		mov [transp],eax

		mov ax,[es:esi]
		call decode_color
		xchg ecx,eax

		mov ax,[es:edi]
		call decode_color
		call enc_transp
		call encode_color

		mov [es:edi],ax
		ret

; src: color, alpha: image
blend_pixel_01_16:
		mov ax,[es:ebx]
		call decode_color

		movzx eax,ah
		mov [transp],eax

		mov ecx,[tmp_var_3]

		mov ax,[es:edi]
		call decode_color
		call enc_transp
		call encode_color

		mov [es:edi],ax
		ret

; src: image, alpha: fixed
blend_pixel_10_16:
		mov ax,[es:esi]
		call decode_color
		xchg eax,ecx

		mov ax,[es:edi]
		call decode_color
		call enc_transp
		call encode_color

		mov [es:edi],ax
		ret

; src: color, alpha: fixed
blend_pixel_11_16:
		mov ecx,[tmp_var_3]

		mov ax,[es:edi]
		call decode_color
		call enc_transp
		call encode_color

		mov [es:edi],ax
		ret

; src: image, alpha: image
blend_pixel_00_32:
		mov eax,[es:ebx]
		movzx eax,ah
		mov [transp],eax

		mov ecx,[es:esi]

		mov eax,[es:edi]
		call enc_transp

		mov [es:edi],eax
		ret

; src: color, alpha: image
blend_pixel_01_32:
		mov eax,[es:ebx]
		movzx eax,ah
		mov [transp],eax

		mov ecx,[tmp_var_3]

		mov eax,[es:edi]
		call enc_transp

		mov [es:edi],eax
		ret

; src: image, alpha: fixed
blend_pixel_10_32:
		mov ecx,[es:esi]

		mov eax,[es:edi]
		call enc_transp

		mov [es:edi],eax
		ret

; src: color, alpha: fixed
blend_pixel_11_32:
		mov ecx,[tmp_var_3]

		mov eax,[es:edi]
		call enc_transp

		mov [es:edi],eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Ensure the cursor is always within the visible area.
;

		bits 32

edit_align:
		mov cx,[edit_width]
		mov dx,cx
		shr dx,1
		mov ax,[edit_cursor]
		sub ax,[edit_shift]
		cmp ax,dx
		jg edit_align_50

		sub ax,1		; still 1 pixel away?
		jge edit_align_90
		add [edit_shift],ax
		jge edit_align_90
		and word [edit_shift],0
		jmp edit_align_90
edit_align_50:
		sub cx,ax
		sub cx,1		; still 1 pixel away?
		jge edit_align_90
		sub [edit_shift],cx
edit_align_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;  ebx		string
;  esi		ptr to char (rel. to ebx)
;
; return:
;  esi		points to prev char
;
;  Changes no other regs.
;

		bits 32

utf8_prev:
		push eax
		or esi,esi
		jz utf8_prev_90
utf8_prev_50:
		dec esi
		jz utf8_prev_90
		mov al,[es:ebx+esi]
		shr al,6
		cmp al,2
		jz utf8_prev_50
utf8_prev_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  ebx		string
;  esi		ptr to char (rel. to ebx)
;
; return:
;  esi		points to next char
;
;  Changes no other regs.
;

		bits 32

utf8_next:
		push eax
		cmp byte [es:ebx+esi],0
		jz utf8_next_90
utf8_next_50:
		inc esi
		mov al,[es:ebx+esi]
		shr al,6
		cmp al,2
		jz utf8_next_50
utf8_next_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; eax		key (bits 0-23: key, 24-31: scan code)
;

		bits 32

edit_input:
		mov edx,eax
		shr edx,24
		and eax,1fffffh
		mov esi,[edit_buf]

		mov ebx,esi
		dec esi

edit_input_10:
		inc esi
		cmp byte [es:esi],0
		jnz edit_input_10
		mov ecx,esi
		sub ecx,ebx

		; ecx: string length

		movzx esi,word [edit_buf_ptr]

		cmp dl,keyLeft
		jnz edit_input_20
		mov edi,esi
		call utf8_prev
		cmp edi,esi
		jz edit_input_90
		mov [edit_buf_ptr],si
		jmp edit_input_80
edit_input_20:
		cmp dl,keyRight
		jnz edit_input_21
		mov edi,esi
		call utf8_next
		cmp edi,esi
		jz edit_input_90
		mov [edit_buf_ptr],si
		jmp edit_input_80
edit_input_21:
		cmp dl,keyEnd
		jnz edit_input_22
		cmp byte [es:ebx+esi],0
		jz edit_input_90
		mov [edit_buf_ptr],cx
		jmp edit_input_80
edit_input_22:
		cmp dl,keyHome
		jnz edit_input_23
		or esi,esi
		jz edit_input_90
		and word [edit_buf_ptr],0
		jmp edit_input_80
edit_input_23:
		cmp dl,keyDel
		jnz edit_input_30
edit_input_24:
		mov edi,esi
		call utf8_next
		cmp edi,esi
		jz edit_input_90
edit_input_25:
		mov al,[es:ebx+esi]
		mov [es:ebx+edi],al
		inc esi
		inc edi
		or al,al
		jnz edit_input_25
		jmp edit_input_80
edit_input_30:
		cmp eax,keyBS
		jnz edit_input_35
		mov edi,esi
		call utf8_prev
		cmp edi,esi
		jz edit_input_90
		mov [edit_buf_ptr],si
		jmp edit_input_24
edit_input_35:

		cmp eax,20h
		jb edit_input_90

		; reject chars we can't display
		pusha
		call char_width
		or ecx,ecx
		popa
		jz edit_input_90

		push ecx
		push ebx
		push esi
		call utf8_enc
		pop esi
		pop ebx
		pop eax

		movzx edx,word [edit_buf_len]
		sub edx,eax
		sub edx,ecx
		jb edit_input_90
		cmp edx,1
		jb edit_input_90
		sub ax,[edit_buf_ptr]
		add [edit_buf_ptr],cx

		; eax: bytes to copy (excl. final 0)
		; ecx: utf8 size

		push esi

		add esi,eax
		mov edi,esi
		add edi,ecx
		inc eax
edit_input_70:
		mov dl,[es:ebx+esi]
		mov [es:ebx+edi],dl
		dec esi
		dec edi
		dec eax
		jnz edit_input_70

		pop esi

		mov edi,utf8_buf
edit_input_75:
		mov al,[edi]
		mov [es:ebx+esi],al
		inc edi
		inc esi
		dec ecx
		jnz edit_input_75

edit_input_80:
		movzx esi,word [edit_buf_ptr]
		mov al,0
		xchg al,[es:ebx+esi]
		push eax
		push esi
		push ebx

		mov esi,ebx
		call str_size

		pop ebx
		pop esi
		pop eax
		xchg al,[es:ebx+esi]
		mov [edit_cursor],cx

		; wait32

		call edit_align
		call edit_redraw
edit_input_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
		bits 32

edit_redraw:
		mov ax,[edit_x]
		sub ax,[edit_shift]
		mov [gfx_cur_x],ax
		mov ax,[edit_y]
		add ax,[edit_y_ofs]
		mov [gfx_cur_y],ax

		mov esi,[edit_buf]
edit_redraw_20:
		call utf8_dec
		or eax,eax
		jz edit_redraw_50
		push esi
		call edit_char
		pop esi
		jmp edit_redraw_20
edit_redraw_50:
		mov ax,[edit_x]
		add ax,[edit_width]
		sub ax,[gfx_cur_x]
		jle edit_redraw_90

		push word [edit_y]
		pop word [gfx_cur_y]
		mov dx,ax
		imul ax,[pixel_bytes]
		mov cx,[edit_height]
		mov bx,[edit_width]
		imul bx,[pixel_bytes]
		mov edi,[edit_bg]
		add edi,4
		movzx ebx,bx
		movzx eax,ax
		add edi,ebx
		sub edi,eax

		call restore_bg
edit_redraw_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write char at current cursor position.
;
;  eax		char
;  [edit_bg]	background pixmap
;
; return:
;  cursor position gets advanced
;

		bits 32

edit_char:
		push word [clip_r]
		push word [clip_l]

		push eax

		mov cx,[edit_x]
		mov [clip_l],cx
		add cx,[edit_width]
		mov [clip_r],cx

		call find_char

		cmp word [chr.x_advance],0
		jle edit_char_80

		mov edi,[edit_bg]
		add edi,4
		mov bx,[edit_width]
		imul bx,[pixel_bytes]
		mov ax,[edit_y_ofs]
		imul bx
		movzx eax,ax
		add edi,eax
		mov cx,[gfx_cur_x]
		sub cx,[edit_x]
		imul cx,[pixel_bytes]
		movsx ecx,cx
		add edi,ecx

		mov dx,[chr.x_advance]
		mov cx,[font.height]

		call restore_bg

edit_char_80:
		pop eax

		call char_xy

		pop word [clip_l]
		pop word [clip_r]

edit_char_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 32

edit_hide_cursor:
		mov edi,[edit_bg]
		add edi,4
		mov ax,[edit_cursor]
		sub ax,[edit_shift]
		mov cx,ax
		imul cx,[pixel_bytes]
		movzx ecx,cx
		add edi,ecx
		add ax,[edit_x]
		mov [gfx_cur_x],ax
		push word [edit_y]
		pop word [gfx_cur_y]
		mov cx,[edit_height]
		mov dx,1
		mov bx,[edit_width]
		imul bx,[pixel_bytes]
		call restore_bg
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

edit_show_cursor:
		push fs
		push gs

		call screen_segs

		mov ax,[edit_cursor]
		sub ax,[edit_shift]
		add ax,[edit_x]
		mov [gfx_cur_x],ax
		push word [edit_y]
		pop word [gfx_cur_y]
		movzx ecx,word [edit_height]
edit_show_cursor_10:
		push ecx
		call goto_xy
		call [setpixel_t]
		pop ecx
		inc word [gfx_cur_y]
		loop edit_show_cursor_10

		pop gs
		pop fs
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; esi		initial text
;

		bits 32

edit_init:
		xor ecx,ecx
		mov [edit_shift],cx
		mov edi,[edit_buf]
edit_init_10:
		es lodsb
		or al,al
		jz edit_init_20
		stosb
		inc ecx
		cmp cx,[edit_buf_len]
		jb edit_init_10
		dec ecx
		dec edi
edit_init_20:
		mov byte [es:edi],0
		mov [edit_buf_ptr],cx

		mov esi,[edit_buf]
		call str_size

		mov [edit_cursor],cx

		call edit_align
		call edit_redraw
		call edit_show_cursor
edit_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Initialize internal edit data.
;
;  esi		parameter array
;
; return:
;  CF		invalid array/out of memory
;
; Note:
;  esi unchanged
;

		bits 32

edit_init_params:
		cmp word [es:esi],6
		jc edit_init_params_90

		push esi
		mov eax,2+3*5
		call calloc
		pop esi
		or eax,eax
		jz edit_init_params_80

		mov byte [es:esi+2+5*5],t_array
		mov [es:esi+2+5*5+1],eax

		mov word [es:eax],3

		mov byte [es:eax+2+5*0],t_int
		mov byte [es:eax+2+5*1],t_int
		mov byte [es:eax+2+5*2],t_int

		clc
		jmp edit_init_params_90

edit_init_params_80:
		stc

edit_init_params_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Free internal edit data.
;
;  esi		parameter array
;
; Note:
;  esi unchanged
;

		bits 32

edit_done_params:
		cmp word [es:esi],6
		jc edit_done_params_90

		cmp byte [es:esi+2+5*5],t_array
		jnz edit_done_params_90

		mov edi,[es:esi+2+5*5+1]
		cmp word [es:edi],3
		jc edit_done_params_90

		; mov byte [es:eax+2+5*0],t_int
		; mov byte [es:eax+2+5*1],t_int
		; mov byte [es:eax+2+5*2],t_int

		mov eax,edi
		push esi
		call free
		pop esi

		xor eax,eax
		mov byte [es:esi+2+5*5],t_none
		mov [es:esi+2+5*5+1],eax

edit_done_params_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Store internal input field state.
;
;  esi		parameter array
;
; Notes:
;  - no consistency checks done, esi _must_ point to a valid array
;  - esi unchanged
;

		bits 32

edit_put_params:
		cmp byte [es:esi+2+5*5],t_array
		jnz edit_put_params_90

		mov edi,[es:esi+2+5*5+1]

		push word [edit_buf_ptr]
		pop word [es:edi+2+5*0+1]
		
		push word [edit_cursor]
		pop word [es:edi+2+5*1+1]
		
		push word [edit_shift]
		pop word [es:edi+2+5*2+1]

edit_put_params_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Copy input field parameters into internal structures.
;
;  esi		parameter array
;
; return:
;  edi:		internal data array
;  CF		invalid data
;

		bits 32

edit_get_params:
		cmp word [es:esi],6
		jc edit_get_params_90

		cmp byte [es:esi+2+5*0],t_int
		jnz edit_get_params_80
		push word [es:esi+2+5*0+1]
		pop word [edit_x]

		cmp byte [es:esi+2+5*1],t_int
		jnz edit_get_params_80
		push word [es:esi+2+5*1+1]
		pop word [edit_y]
		
		cmp byte [es:esi+2+5*2],t_ptr
		jnz edit_get_params_80
		push dword [es:esi+2+5*2+1]
		pop dword [edit_bg]
		
		cmp byte [es:esi+2+5*3],t_string
		jnz edit_get_params_80
		mov eax,[es:esi+2+5*3+1]
		mov [edit_buf],eax
		
		cmp byte [es:esi+2+5*4],t_int
		jnz edit_get_params_80
		push word [es:esi+2+5*4+1]
		pop word [edit_buf_len]
		
		cmp byte [es:esi+2+5*5],t_none
		jnz edit_get_params_40
		xor edi,edi
		jmp edit_get_params_90
edit_get_params_40:
		cmp byte [es:esi+2+5*5],t_array
		jnz edit_get_params_80
		mov edi,[es:esi+2+5*5+1]
		cmp word [es:edi],3		; array length
		jb edit_get_params_80

		cmp byte [es:edi+2+5*0],t_int
		jnz edit_get_params_80
		push word [es:edi+2+5*0+1]
		pop word [edit_buf_ptr]
		
		cmp byte [es:edi+2+5*1],t_int
		jnz edit_get_params_80
		push word [es:edi+2+5*1+1]
		pop word [edit_cursor]
		
		cmp byte [es:edi+2+5*2],t_int
		jnz edit_get_params_80
		push word [es:edi+2+5*2+1]
		pop word [edit_shift]
		
		mov eax,[edit_bg]
		mov dx,[es:eax]
		mov [edit_width],dx
		mov dx,[es:eax+2]
		mov [edit_height],dx

		mov cx,[font.height]
		sub dx,cx
		sar dx,1
		mov [edit_y_ofs],dx

		cmp word [edit_buf_len],2		; at least 1 char
		jnc edit_get_params_90

edit_get_params_80:

		stc
edit_get_params_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; basic graphics functions
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Map next window segment.
;

		bits 32

inc_winseg:
		push eax
		mov al,[mapped_window]
		inc al
		call set_win
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Map window segment.
;
;  al		window segment
;

		bits 32

set_win:
		push edi
		cmp byte [vbe_active],0
		jz set_win_90
		cmp [mapped_window],al
		jz set_win_90
		pusha
		mov [mapped_window],al
		mov ah,[window_inc]
		mul ah
		xchg eax,edx
		mov ax,4f05h
		xor ebx,ebx
		cmp word [window_seg_r],0
		jz set_win_50
		pusha
		inc ebx
		int 10h
		popa
set_win_50:
		int 10h
		popa
set_win_90:
		pop edi
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Go to current cursor position.
;
; return:
;  edi		offset
;  correct gfx segment is mapped
;
; Notes:
;  - changes no regs other than edi
;

		bits 32

goto_xy:
		push eax
		push edx
		mov ax,[gfx_cur_y]
		movzx edi,word [gfx_cur_x]
		imul edi,[pixel_bytes]
		mul word [screen_line_len]
		add ax,di
		adc dx,0
		push ax
		xchg ax,dx
		call set_win
		pop di
		pop edx
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set active color.
;
; eax		color
;
; return:
;  [gfx_color]	color
;

		bits 32

setcolor:
		mov [gfx_color],eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Encode rgb value to color.
;
;  eax		rgb value
;
; return:
;  eax		color
;

		bits 32

encode_color:
		cmp byte [pixel_bits],16
		jnz encode_color_90
		push edx
		xor edx,edx
		shl eax,8
		shld edx,eax,5
		shl eax,8
		shld edx,eax,6
		shl eax,8
		shld edx,eax,5
		mov eax,edx
		pop edx
encode_color_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Decode color to rgb.
;
;  eax		color
;
; return:
;  eax		rgb value
;

		bits 32

decode_color:
		cmp byte [pixel_bits],16
		jnz decode_color_90
		push edx
		xor edx,edx
		shl eax,16
		shld edx,eax,5
		shld edx,eax,3
		shl eax,5
		shld edx,eax,6
		shld edx,eax,2
		shl eax,6
		shld edx,eax,5
		shld edx,eax,3
		mov eax,edx
		pop edx
decode_color_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Look up rgb value for palette entry.
;
;  eax		palette index
;
; return:
;  eax		color
;

		bits 32

pal_to_color:
		lea eax,[eax+2*eax]
		add eax,[gfx_pal]
		mov eax,[es:eax]
		bswap eax
		shr eax,8
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Draw a line.
;
; [line_x0], [line_y0]	start
; [line_x1], [line_y1]	end
;

		bits 32

line:
		push fs
		push gs

		xor eax,eax
		xor ebx,ebx
		inc ax
		inc bx
		mov esi,[line_x1]
		sub esi,[line_x0]
		jns line_10
		neg esi
		neg eax
line_10:
		mov ebp,[line_y1]
		sub ebp,[line_y0]
		jns line_20
		neg ebp
		neg ebx
line_20:
		call screen_segs

		xchg eax,ecx
		mov eax,[screen_line_len]
		imul ebx
		xchg eax,edx
		
		mov eax,[line_y0]
		push edx
		imul dword [screen_line_len]
		pop edx
		xchg eax,edi

		mov eax,[line_x0]
		imul eax,[pixel_bytes]

		add edi,eax

		cmp byte [pixel_bytes],1
		jbe line_25
		cmp byte [pixel_bytes],2
		jz line_23
		shl dword [line_x0],2
		shl dword [line_x1],2
		shl ecx,2
		jmp line_25
line_23:
		shl dword [line_x0],1
		shl dword [line_x1],1
		shl ecx,1
line_25:

		; edi -> address
		; ecx -> d_x
		; edx -> d_y

		cmp esi,ebp
		jl hline_40

		or esi,esi
		jz line_60

		mov [line_tmp],esi
		shr esi,1
		neg esi

		mov eax,[line_x1]
		sub [line_x0],eax

line_30:
		call line_pp

		add edi,ecx
		add [line_x0],ecx
		jz line_60
		add esi,ebp
		jnc line_30
		sub esi,[line_tmp]
		add edi,edx
		jmp line_30

hline_40:
		or ebp,ebp
		jz line_60

		mov [line_tmp],ebp
		shr ebp,1
		neg ebp

		mov eax,[line_y1]
		sub [line_y0],eax

line_50:
		call line_pp

		add edi,edx
		add [line_y0],ebx
		jz line_60
		add ebp,esi
		jnc line_50
		sub ebp,[line_tmp]
		add edi,ecx
		jmp line_50
line_60:
		; now draw final point

		mov eax,[line_y1]
		imul dword [screen_line_len]
		add eax,[line_x1]
		xchg eax,edi

		call line_pp

		pop gs
		pop fs
		ret

line_pp:
		mov eax,edi
		shr eax,16
		call set_win
		push edi
		and edi,0xffff
		call [setpixel_t]
		pop edi
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set pixel at gs:edi.
;
; setpixel_* read from [fs:edi] and write to [gs:edi]
;

		bits 32

setpixel_8:
		mov al,[gfx_color]

setpixel_a_8:
		mov [gs:edi],al
		ret

setpixel_16:
		mov ax,[gfx_color]

setpixel_a_16:
		mov [gs:edi],ax
		ret

setpixel_32:
		mov eax,[gfx_color]

setpixel_a_32:
		mov [gs:edi],eax
		ret


; set pixel with transparency
setpixel_t_16:
		mov ax,[gfx_color]

setpixel_ta_16:
		cmp dword [transp],0
		jz setpixel_a_16
		call decode_color
		push ecx
		xchg eax,ecx
		mov ax,[fs:edi]
		call decode_color
		xchg eax,ecx
		call enc_transp
		pop ecx
		call encode_color
		mov [gs:edi],ax
		ret

setpixel_t_32:
		mov eax,[gfx_color]

setpixel_ta_32:
		cmp dword [transp],0
		jz setpixel_a_32
		push ecx
		mov ecx,[fs:edi]
		call enc_transp
		pop ecx
		mov [gs:edi],eax
		ret

; (1 - t) eax + t * ecx -> eax
enc_transp:
		ror ecx,16
		ror eax,16
		call add_transp
		rol ecx,8
		rol eax,8
		call add_transp
		rol ecx,8
		rol eax,8
		call add_transp
		mov eax,ecx
		ret

; cl, al -> cl
add_transp:
		push eax
		push ecx
		movzx eax,al
		movzx ecx,cl
		sub ecx,eax
		imul ecx,[transp]
		sar ecx,8
		add ecx,eax
		cmp ecx,0
		jge add_transp_10
		mov cl,0
		jmp add_transp_20
add_transp_10:
		cmp ecx,100h
		jb add_transp_20
		mov cl,0ffh
add_transp_20:
		mov [esp],cl
		pop ecx
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get pixel from fs:edi.
;
; getpixel_* read from [fs:edi]
;

		bits 32

getpixel_8:
		mov al,[fs:edi]
		ret

getpixel_16:
		mov ax,[fs:edi]
		ret

getpixel_32:
		mov eax,[fs:edi]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Initialize console font (used for debug output).
;

		bits 32

cfont_init:
		; 3: 8x8, 2: 8x14, 6: 8x16
		mov bh,6
		mov ax,1130h
		int 10h
		movzx ebp,bp
		movzx eax,word [rm_seg.es]
		shl eax,4
		add eax,ebp
		mov [cfont.lin],eax

		mov dword [cfont_height],16
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Initialize font.
;
; eax		ptr to font header
;

		bits 32

font_init:
		mov ebx,eax
		shr eax,31
		mov [font.properties],al
		and ebx,~(1 << 31)
		cmp dword [es:ebx+foh.magic],0d2828e06h		; magic
		jnz font_init_90
		mov eax,[es:ebx+foh.entries]
		mov dl,[es:ebx+foh.height]
		mov dh,[es:ebx+foh.line_height]
		movsx cx,byte [es:ebx+foh.baseline]
		or eax,eax
		jz font_init_90
		or dx,dx
		jz font_init_90
		mov [font.entries],eax
		mov [font.height],dl
		mov [font.line_height],dh
		mov [font.baseline],cx
		mov [font],ebx
font_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write a string. '\n' is a line break.
;
;  esi		string
;
; return:
;  cursor position gets advanced
;
; special chars:
;   char_eot	same as \x00
;   \x10	back to normal
;   \x11	set alternative text color (gfx_color1)
;   \x12	label start, no text output
;   \x13	set link text color (gfx_color2); typically label end
;   \x14	start page description
;

		bits 32

text_xy:
		xor eax,eax
		mov [last_label],eax
		mov [cur_row],eax
		and byte [txt_state],~1

		test byte [txt_state],2
		jz text_xy_05

		mov [row_text],esi
		mov [cur_row2],eax
		mov [cur_link],eax
		mov [sel_link],eax
		mov [page_title],eax
		push esi
		call utf8_dec
		pop esi
		call is_eot
		jz text_xy_05
		inc dword [cur_row2]
text_xy_05:
		push word [gfx_cur_x]
text_xy_10:
		mov edi,esi
		call utf8_dec

		call is_eot
		jz text_xy_90

		cmp dword [line_wrap],0
		jz text_xy_60

		cmp eax,3000h
		jae text_xy_20

		call is_space
		jnz text_xy_60
text_xy_20:

		push esi
		mov esi,edi
		push edi
		call word_width
		pop edi
		pop esi
		movzx edx,word [gfx_cur_x]
		add ecx,edx
		cmp ecx,[line_wrap]
		jbe text_xy_60
text_xy_30:
		call is_space
		jnz text_xy_50

		mov edi,esi
		call utf8_dec

		call is_eot
		jz text_xy_90
		jmp text_xy_30
text_xy_50:
		mov esi,edi
		jmp text_xy_65
text_xy_60:
		cmp eax,0ah
		jnz text_xy_70
text_xy_65:
		mov ax,[font.line_height]
		add [gfx_cur_y],ax
		pop ax
		push ax
		mov [gfx_cur_x],ax
		inc dword [cur_row]
		mov edx,[max_rows]
		mov eax,[cur_row]
		or edx,edx
		jz text_xy_67
		cmp eax,edx
		jae text_xy_90
text_xy_67:
		test byte [txt_state],2
		jz text_xy_10
		cmp eax,max_text_rows
		jae text_xy_10
		mov [cur_row2],eax
		inc dword [cur_row2]
		mov [row_text+4*eax],esi
		jmp text_xy_10
text_xy_70:
		push esi
		cmp eax,1fh
		jae text_xy_80
		call text_special
		jmp text_xy_89
text_xy_80:
		test byte [txt_state],1
		jnz text_xy_89

;;
		pop esi
		push esi
		mov edx,eax
		call utf8_dec
		xchg eax,edx
		cmp edx,0a3fh		; Sihari (Gurmukhi 'i')
		jz text_xy_85
		cmp edx,093fh		; (Devanagari 'i')
		jnz text_xy_88
text_xy_85:
		pop edi
		push esi
		push eax
		mov eax,edx
		call char_xy
		pop eax
text_xy_88:
;;

		call char_xy
text_xy_89:
		pop esi
		jmp text_xy_10
text_xy_90:
		pop ax
		push dword [gfx_color0]
		pop dword [gfx_color]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Handle special chars.
;
;  eax		char
;  esi		ptr to next char
;

		bits 32

text_special:
		cmp eax,10h
		jnz text_special_20

		and byte [txt_state],~1
		push eax
		mov eax,[gfx_color0]
		call setcolor
		pop eax
		jmp text_special_90
text_special_20:
		cmp eax,11h
		jnz text_special_30

		and byte [txt_state],~1
		push eax
		mov eax,[gfx_color1]
		call setcolor
		pop eax
		jmp text_special_90
text_special_30:
		cmp eax,12h
		jnz text_special_40

		or byte [txt_state],1
		mov [last_label],esi

		jmp text_special_90
text_special_40:
		cmp eax,13h
		jnz text_special_50

		and byte [txt_state],~1

		; check for selected link
		mov ebx,[sel_link]
		shl ebx,2
		mov edx,[link_list+li.text+2*ebx+ebx]		; li.size = 12 (4*3)
		cmp esi,edx

		push eax
		mov eax,[gfx_color3]
		jz text_special_45
		mov eax,[gfx_color2]
text_special_45:
		call setcolor
		pop eax

		test byte [txt_state],2
		jz text_special_90

		mov ebx,[cur_link]
		cmp ebx,link_entries
		jae text_special_90
		inc dword [cur_link]
		shl ebx,2
		lea ebx,[link_list+2*ebx+ebx]			; li.size = 12 (4*3)
		push dword [last_label]
		pop dword [ebx+li.label]
		mov [ebx+li.text],esi
		push word [gfx_cur_x]
		pop word [ebx+li.x]
		mov edx,[cur_row2]
		sub edx,1		; 0-- -> 0
		adc edx,0
		mov [ebx+li.row],dx

		jmp text_special_90
text_special_50:
		cmp eax,14h
		jnz text_special_60

		mov [page_title],esi

		jmp text_special_90
text_special_60:


text_special_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; String width until end of next word.
;
;  esi		string
;
; return:
;  ecx		width
;

		bits 32

word_width:
		push esi
		push eax

		xor edx,edx
		xor ebx,ebx

word_width_10:
		call utf8_dec

word_width_20:
		call is_eot
		jz word_width_90

		cmp eax,0ah
		jz word_width_90

		cmp eax,10h
		jnz word_width_30
		xor ebx,ebx
word_width_30:
		cmp eax,11h
		jnz word_width_31
		mov bh,1
word_width_31:
		cmp eax,12h
		jnz word_width_32
		mov bl,1
word_width_32:
		cmp eax,13h
		jnz word_width_33
		mov bh,1
		mov bl,0
word_width_33:
		cmp eax,14h
		jnz word_width_34
		mov bh,1
word_width_34:

		or bl,bl
		jnz word_width_70

		push eax
		push ebx
		push edx
		push esi
		call char_width
		pop esi
		pop edx
		pop ebx
		pop eax

		add edx,ecx

word_width_70:
		call is_space
		jz word_width_10

		call utf8_dec

		or ebx,ebx
		jnz word_width_80
		cmp eax,3000h
		jae word_width_90
word_width_80:

		call is_space
		jnz word_width_20

word_width_90:
		mov ecx,edx

		pop eax
		pop esi
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Test for white space (space or tab).
;
;  eax		char
;
; return:
;  ZF		0 = no, 1 = yes
;

		bits 32

is_space:
		cmp eax,20h
		jz is_space_90
		cmp eax,9
is_space_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Test for end of text.
;
; eax		char
;
; return:
;  ZF		0 = no, 1 = yes
;

		bits 32

is_eot:
		or eax,eax
		jz is_eot_90
		cmp eax,[char_eot]
is_eot_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get string dimensions (in pixel).
;
;  esi		string
;
; return:
;  ecx		width
;  edx		height
;

		bits 32

str_size:
		xor ecx,ecx
		xor edx,edx
str_size_20:
		push ecx
		push edx
		call str_len
		xchg eax,ecx
		pop edx
		pop ecx
		cmp eax,ecx
		jb str_size_40
		mov ecx,eax
str_size_40:
		inc edx

		; suppress final line break
		call utf8_dec
		cmp eax,0ah
		jnz str_size_60
		cmp byte [es:esi],0
		jz str_size_80
str_size_60:
		or eax,eax
		jz str_size_80
		cmp eax,[char_eot]
		jz str_size_80
		jmp str_size_20
str_size_80:
		dec edx
		movzx eax,word [font.line_height]
		mul edx
		movzx edx,word [font.height]
		add edx,eax
str_size_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get string length (in pixel).
; *** Use str_size instead. ***
;
;  esi		string
;
; return:
;  ecx		width
;  esi		points to string end or line break
;
; notes:
;  - stops at linebreak ('\n')
;

		bits 32

str_len:
		xor ecx,ecx
str_len_10:
		mov edi,esi
		call utf8_dec
		or eax,eax
		jz str_len_70
		cmp eax,[char_eot]
		jz str_len_70
		cmp eax,0ah
		jz str_len_70
		push ecx
		push esi
		call char_width
		pop esi
		pop eax
		add ecx,eax
		jmp str_len_10
str_len_70:
		mov esi,edi
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Decode next utf8 char.
;
;  esi		string
;
; return:
;  eax		char (invalid char: 0)
;  esi		points past char
;
; Note: changes only eax, esi
;

		bits 32

utf8_dec:
		xor eax,eax
		es lodsb
		cmp al,80h
		jb utf8_dec_90

		push ecx
		push edx

		xor edx,edx
		xor ecx,ecx
		mov dl,al

		cmp al,0c0h		; invalid
		jb utf8_dec_70

		inc ecx			; 2 bytes
		and dl,1fh
		cmp al,0e0h
		jb utf8_dec_10

		inc ecx			; 3 bytes
		and dl,0fh
		cmp al,0f0h
		jb utf8_dec_10

		inc ecx			; 4 bytes
		and dl,7
		cmp al,0f8h
		jb utf8_dec_10

		inc ecx			; 5 bytes
		and dl,3
		cmp al,0fch
		jb utf8_dec_10

		inc ecx			; 6 bytes
		and dl,1
		cmp al,0feh
		jae utf8_dec_70
utf8_dec_10:
		es lodsb
		cmp al,80h
		jb utf8_dec_70
		cmp al,0c0h
		jae utf8_dec_70
		and al,3fh
		shl edx,6
		or dl,al
		dec ecx
		jnz utf8_dec_10
		xchg eax,edx
		jmp utf8_dec_80
		
utf8_dec_70:
		xor eax,eax
utf8_dec_80:
		pop edx
		pop ecx

utf8_dec_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Encode utf8 char.
;
;  eax		char
;
; return:
;  ecx		length
;  utf8_buf	char
;

		bits 32

utf8_enc:
		mov esi,utf8_buf
		xor ecx,ecx
		xor edx,edx

		cmp eax,80h
		jae utf8_enc_10
		mov [esi],al
		inc esi
		jmp utf8_enc_80
utf8_enc_10:
		inc ecx
		cmp eax,800h
		jae utf8_enc_20
		shl eax,21
		mov dl,6
		shld edx,eax,5
		shl eax,5
		jmp utf8_enc_60
utf8_enc_20:
		inc ecx
		cmp eax,10000h
		jae utf8_enc_30
		shl eax,16
		mov dl,0eh
		shld edx,eax,4
		shl eax,4
		jmp utf8_enc_60
utf8_enc_30:
		inc ecx
		cmp eax,200000h
		jae utf8_enc_40
		shl eax,11
		mov dl,1eh
		shld edx,eax,3
		shl eax,3
		jmp utf8_enc_60
utf8_enc_40
		inc ecx
		cmp eax,4000000h
		jae utf8_enc_50
		shl eax,6
		mov dl,3eh
		shld edx,eax,2
		shl eax,2
		jmp utf8_enc_60
utf8_enc_50:
		inc ecx
		shl eax,1
		mov dl,7eh
		shld edx,eax,1
		add eax,eax
utf8_enc_60:
		mov ebx,ecx
		mov [esi],dl
		inc esi
utf8_enc_70:
		mov dl,2
		shld edx,eax,6
		shl eax,6
		mov [esi],dl
		inc esi
		dec ebx
		jnz utf8_enc_70
utf8_enc_80:
		mov byte [esi],0
		inc ecx
utf8_enc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write a char at the current cursor position.
;
;  eax		char
;
; return:
;  cursor position gets advanced
;

		bits 32

char_xy:
		push fs
		push gs

		cmp eax,1fh			; \x1f looks like a space, but isn't
		jnz char_xy_10
		mov al,' '
char_xy_10:
		call find_char
		jc char_xy_90

		test byte [txt_state],2		; don't actually write
		jnz char_xy_80

		cmp word [chr.bitmap_width],0
		jz char_xy_80
		cmp word [chr.bitmap_height],0
		jz char_xy_80

		mov dl,[chr.type]
		or dl,dl
		jnz char_xy_30
		call char0_xy
		jmp char_xy_80
char_xy_30:
		cmp dl,1
		jnz char_xy_80
		call char1_xy

char_xy_80:
		mov cx,[chr.x_advance]
		add [gfx_cur_x],cx
char_xy_90:
		pop gs
		pop fs
		ret


char0_xy:
		push word [gfx_cur_x]
		push word [gfx_cur_y]

		mov ax,[chr.x_ofs]
		add [gfx_cur_x],ax

		mov ax,[font.height]
		sub ax,[font.baseline]
		sub ax,[chr.y_ofs]
		sub ax,[chr.bitmap_height]
		add [gfx_cur_y],ax

		call goto_xy
		call screen_segs

		mov ebx,[chr.data]
		mov esi,[chr.bitmap]

		xor edx,edx
char0_xy_20:
		xor ecx,ecx
char0_xy_30:
		bt [es:ebx],esi
		jnc char0_xy_40
		mov ax,[gfx_cur_x]
		add ax,cx
		cmp ax,[clip_r]
		jge char0_xy_40
		cmp ax,[clip_l]
		jl char0_xy_40
		call [setpixel_t]
char0_xy_40:
		inc esi
		add di,[pixel_bytes]
		jnc char0_xy_50
		call inc_winseg
char0_xy_50:
		inc ecx
		cmp cx,[chr.bitmap_width]
		jnz char0_xy_30

		mov ax,[screen_line_len]
		mov bp,[chr.bitmap_width]
		imul bp,[pixel_bytes]
		sub ax,bp
		add di,ax
		jnc char0_xy_60
		call inc_winseg
char0_xy_60:
		inc edx
		cmp dx,[chr.bitmap_height]
		jnz char0_xy_20

		pop word [gfx_cur_y]
		pop word [gfx_cur_x]

		ret


char1_xy:
		push word [gfx_cur_x]
		push word [gfx_cur_y]

		call char1_unpack
		jc char1_xy_90

		mov ax,[chr.x_ofs]
		add [gfx_cur_x],ax

		mov ax,[font.height]
		sub ax,[font.baseline]
		sub ax,[chr.y_ofs]
		sub ax,[chr.bitmap_height]
		add [gfx_cur_y],ax

		; save_bg does not clip, do it here (sort of)
		mov ax,[gfx_cur_x]
		cmp ax,[clip_r]
		jge char1_xy_20
		add ax,[chr.bitmap_width]
		cmp ax,[clip_l]
		jl char1_xy_20

		mov edi,[chr.pixel_buf]
		mov dx,[es:edi]
		mov cx,[es:edi+2]
		add edi,4
		call save_bg

char1_xy_20:

		push dword [transp]

		mov edi,[chr.pixel_buf]
		mov esi,[chr.buf]
		mov ax,[es:edi]
		mul word [es:edi+2]
		movzx ecx,ax
		add edi,4
		add esi,4

		mov eax,[gfx_color]
		call decode_color
		mov [tmp_var_0],eax

char1_xy_30:
		push ecx

		movzx eax,byte [es:esi]
		inc esi
		mov [transp],eax
		mov ecx,[tmp_var_0]

		cmp dword [pixel_bytes],2
		jnz char1_xy_40

		mov ax,[es:edi]
		call decode_color
		call enc_transp
		call encode_color
		mov [es:edi],ax

		jmp char1_xy_60
char1_xy_40:

		mov eax,[es:edi]
		call enc_transp
		mov [es:edi],eax

char1_xy_60:
		pop ecx
		add edi,[pixel_bytes]
		dec ecx
		jnz char1_xy_30

		pop dword [transp]

		mov edi,[chr.pixel_buf]
		mov dx,[es:edi]
		mov cx,[es:edi+2]
		add edi,4
		mov bx,dx
		imul bx,[pixel_bytes]
		call restore_bg

char1_xy_90:
		pop word [gfx_cur_y]
		pop word [gfx_cur_x]

		ret


char1_unpack:
		mov ax,[chr.bitmap_width]
		mul word [chr.bitmap_height]
		movzx eax,ax
		mov ebp,eax
		mov ebx,eax
		imul ebx,[pixel_bytes]
		add eax,4
		add ebx,4
		cmp eax,[chr.buf_len]
		jb char1_unpack_10
		push ebp
		push ebx
		push eax
		mov eax,[chr.buf]
		call free
		mov eax,[chr.pixel_buf]
		call free
		xor eax,eax
		mov [chr.buf],eax
		mov [chr.pixel_buf],eax
		mov [chr.buf_len],eax
		pop eax
		push eax
		call calloc
		pop ecx
		pop ebx
		pop ebp
		or eax,eax
		stc
		jz char1_unpack_90
		mov [chr.buf_len],ecx
		mov [chr.buf],eax
		mov eax,ebx
		push ebp
		call calloc
		pop ebp
		or eax,eax
		stc
		jz char1_unpack_90
		mov [chr.pixel_buf],eax
char1_unpack_10:
		mov edi,[chr.buf]
		mov esi,[chr.pixel_buf]

		mov cx,[chr.bitmap_width]
		mov [es:edi],cx
		mov [es:esi],cx
		mov cx,[chr.bitmap_height]
		mov [es:edi+2],cx
		mov [es:esi+2],cx

		add edi,4

		; ebp: pixel

		mov ebx,[chr.data]
		mov esi,[chr.bitmap]

char1_unpack_20:
		push ebp
		push edi
		mov cl,cbm_gray_bits
		call get_u_bits
		pop edi
		pop ebp

		cmp al,cbm_max_gray
		ja char1_unpack_30
		mov al,[chr.gray_values + eax]
		stosb
		dec ebp
		jnz char1_unpack_20
		jmp char1_unpack_80
char1_unpack_30:
		mov dl,[chr.gray_values + 0]
		cmp al,cbm_rep_white
		jnz char1_unpack_40
		mov dl,[chr.gray_values + cbm_max_gray]
char1_unpack_40:
		push edx
		push ebp
		push edi
		mov cl,cbm_gray_bit_count
		call get_u_bits
		pop edi
		pop ebp
		pop edx
		add al,3
		xchg dl,al
char1_unpack_50:
		stosb
		dec ebp
		jz char1_unpack_80
		dec dl
		jnz char1_unpack_50
		jmp char1_unpack_20
char1_unpack_80:
		clc

char1_unpack_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read bits and convert to unsigned int.
;
; ebx		buffer
; esi		bit offset
; cl		bits
;
; return:
;  eax		(unsigned) number
;  ebx		buffer
;  esi		updated bit offset
;  ecx		bits
;
get_u_bits:
		movzx ecx,cl
		mov edi,esi
		mov ebp,esi
		add esi,ecx
		shr edi,3
		and ebp,7
		mov eax,[es:ebx+edi]
		xchg ecx,ebp
		mov edx,[es:ebx+edi+4]
		shrd eax,edx,cl
		xchg ecx,ebp
		cmp ecx,32
		jae get_u_bits_90
		mov ebp,1
		shl ebp,cl
		dec ebp
		and eax,ebp
get_u_bits_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read bits and convert to signed int.
;
; ebx		buffer
; esi		bit offset
; cl		bits
;
; return:
;  eax		(signed) number
;  ebx		buffer
;  esi		updated bit offset
;  ecx		bits
;
get_s_bits:
		call get_u_bits
		or ecx,ecx
		jz get_s_bits_90
		dec ecx
		mov ebp,1
		shl ebp,cl
		inc ecx
		test eax,ebp
		jz get_s_bits_90
		xor ebp,ebp
		dec ebp
		shl ebp,cl
		add eax,ebp
get_s_bits_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Look for char in font.
;
;  eax		char
;
; return:
;  CF		0 = found, 1 = not found
;  [chr.*]	updated
;

		bits 32

find_char:
		and eax,1fffffh
		push eax
		cmp dword [font],0
		stc
		jz find_char_90

		test byte [font.properties],1
		jz find_char_10
		mov eax,'*'
find_char_10:

		mov ebx,[font]
		add ebx,foh.size
		mov ecx,[font.entries]

		; do a binary search for char

find_char_20:
		mov esi,ecx
		shr esi,1

		lea esi,[esi+4*esi]			; offset table has 5-byte entries
		mov edx,[es:ebx+esi]
		and edx,1fffffh				; 21 bits
		cmp eax,edx

		jz find_char_80

		jl find_char_50

		add ebx,esi
		test cl,1
		jz find_char_50
		add ebx,5				; offset table has 5-byte entries
find_char_50:
		shr ecx,1
		jnz find_char_20

		stc
		jmp find_char_90

find_char_80:
		mov edx,[es:ebx+esi+1]
		shr edx,13				; 19 bit offset
		add edx,[font]
		mov [chr.data],edx

		mov ebx,edx
		xor esi,esi
		mov cl,2
		call get_u_bits
		mov [chr.type],al
		mov cl,3
		call get_u_bits
		mov cl,al
		inc cl

		call get_u_bits
		mov [chr.bitmap_width],ax
		call get_u_bits
		mov [chr.bitmap_height],ax
		call get_s_bits
		mov [chr.x_ofs],ax
		call get_s_bits
		mov [chr.y_ofs],ax
		call get_s_bits
		mov [chr.x_advance],ax

		mov [chr.bitmap],esi

		clc
find_char_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get char width.
;
;  eax		char
;
; return:
;  eax		char
;  ecx		char width
;

		bits 32

char_width:
		push eax
		cmp eax,1fh		; \x1f looks like a space, but isn't
		jnz char_width_10
		mov al,' '
char_width_10:
		call find_char
		mov ecx,0
		jc char_width_90
		movsx ecx,word [chr.x_advance]
char_width_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Write char at the current console cursor position.
;
;  al		char
;  ebx		color
;
; return:
;  console cursor position gets advanced
;

		bits 32

con_char_xy:
		push fs
		push gs

		push dword [gfx_color]

		push word [gfx_cur_x]
		push word [gfx_cur_y]

		mov [gfx_color],ebx

		push word [con_x]
		pop word [gfx_cur_x]

		push word [con_y]
		pop word [gfx_cur_y]

		call goto_xy
		call screen_segs

		mov esi,[cfont.lin]

		movzx eax,al

		mul byte [cfont_height]
		add esi,eax

		xor edx,edx

con_char_xy_20:
		mov ecx,7
con_char_xy_30:
		bt [es:esi],ecx
		mov eax,[gfx_color]
		jc con_char_xy_40
		xor eax,eax
con_char_xy_40:
		call [setpixel_a]
		add di,[pixel_bytes]
		jnc con_char_xy_50
		call inc_winseg
con_char_xy_50:
		dec ecx
		jns con_char_xy_30

		inc esi

		mov eax,[screen_line_len]
		mov ebx,[pixel_bytes]
		shl ebx,3
		sub eax,ebx
		add di,ax
		jnc con_char_xy_60
		call inc_winseg
con_char_xy_60:
		inc edx
		cmp edx,[cfont_height]
		jnz con_char_xy_20

		add word [con_x],8

		pop word [gfx_cur_y]
		pop word [gfx_cur_x]

		pop dword [gfx_color]

		pop gs
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get some memory for palette data
;

		bits 32

pal_init:
		mov eax,300h
		call calloc
		mov [gfx_pal],eax
		or eax,eax
		stc
		jz pal_init_90
		mov eax,300h
		call calloc
		mov [gfx_pal_tmp],eax
		or eax,eax
		stc
		jz pal_init_90
		clc
pal_init_90:		
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Load palette data.
;
; ecx		number of palette entries
; edx		start entry
;

		bits 32

load_palette:
		cmp byte [pixel_bytes],1
		ja load_palette_90

		cmp edx,100h
		jae load_palette_90

		mov eax,edx
		add eax,ecx
		sub eax,100h
		jbe load_palette_10
		sub ecx,eax
load_palette_10:
		or ecx,ecx
		jz load_palette_90

		lea ebp,[edx+2*edx]

		mov ebx,edx
		push ecx

		; vga function wants 6 bit values

		mov esi,[gfx_pal]
		mov edi,[gfx_pal_tmp]

		add esi,ebp
		add edi,ebp

		lea ecx,[ecx+2*ecx]

load_palette_50:
		es lodsb
		shr al,2
		stosb
		loop load_palette_50

		pop ecx

		mov edx,[gfx_pal_tmp]
		add edx,ebp

		mov eax,edx
		and edx,0fh
		shr eax,4

		; check seg value
		cmp eax,10000h
		jae load_palette_90

		mov [rm_seg.es],ax

		mov ax,1012h
		int 10h

load_palette_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Clip drawing area.
;
;  [gfx_cur_x]		left border
;  [gfx_cur_y]		top border
;  [gfx_width]		width
;  [gfx_height]		height
;
; return:
;  CF			1 = empty area
;  If CF = 0		Area adjusted to fit within [clip_*].
;  If CF = 1		Undefined values in [gfx_*].
;
;  Changed registers: -
;

		bits 32

clip_it:
		pusha

		mov ax,[gfx_cur_x]
		mov dx,[gfx_width]
		mov cx,[clip_l]
		add dx,ax

		sub ax,cx
		jge clip_it_10
		add [gfx_width],ax
		mov [gfx_cur_x],cx
clip_it_10:
		sub dx,[clip_r]
		jl clip_it_20
		sub [gfx_width],dx
clip_it_20:
		cmp word [gfx_width],0
		jg clip_it_30
		mov word [gfx_width],0
		stc
		jmp clip_it_90
clip_it_30:

		mov ax,[gfx_cur_y]
		mov dx,[gfx_height]
		mov cx,[clip_t]
		add dx,ax

		sub ax,cx
		jge clip_it_40
		add [gfx_height],ax
		mov [gfx_cur_y],cx
clip_it_40:
		sub dx,[clip_b]
		jl clip_it_50
		sub [gfx_height],dx
clip_it_50:
		cmp word [gfx_height],0
		jg clip_it_90
		mov word [gfx_height],0
		stc

clip_it_90:
		popa
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Save screen region.
;
;  dx, cx	width, height
;  edi		buffer
;
; Note: ensure we only make aligned dword reads from video memory. Else some
; ATI 7000 boards will make problems (computer hangs).
; As an added bonus, it really speeds things up.
;

		bits 32

save_bg:
		push fs
		push gs

		push edi

		call goto_xy
		mov esi,edi

		pop edi

		call screen_segs

		movzx ecx,cx
		movzx edx,dx

		or ecx,ecx
		jz save_bg_90
		or edx,edx
		jz save_bg_90

		imul dx,[pixel_bytes]

save_bg_10:
		push ecx
		push edx

		mov ebp,esi
		mov ecx,esi
		and ebp,~3
		and ecx,3

		jz save_bg_30

		shl ecx,3
		mov eax,[fs:ebp]
		shr eax,cl

save_bg_20:
		stosb
		inc si
		shr eax,8
		dec edx
		; ensure ch = 0
		jz save_bg_70
		add cl,8
		cmp cl,20h
		jnz save_bg_20

		or si,si
		jnz save_bg_30
		call inc_winseg
save_bg_30:
		mov eax,[fs:esi]
		add si,4
		jnz save_bg_35
		call inc_winseg
save_bg_35:
		cmp edx,4
		jb save_bg_50
		stosd
		sub edx,4
		; ch = 0
		jz save_bg_70
		jmp save_bg_30
save_bg_50:
		mov ecx,4
		sub ecx,edx
		sub si,cx
		; don't switch bank later: we've already done it
		setc ch
save_bg_60:
		stosb
		shr eax,8
		dec edx
		jnz save_bg_60

save_bg_70:
		pop edx

		mov eax,[screen_line_len]
		sub eax,edx
		add si,ax
		jnc save_bg_80
		or ch,ch
		jnz save_bg_80
		call inc_winseg
save_bg_80:
		pop ecx

		dec ecx
		jnz save_bg_10

save_bg_90:
		pop gs
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Restore screen region.
;
;  dx, cx	width, height
;  bx		bytes per line
;  edi		buffer
;
; Does not change cursor positon.
;

		bits 32

restore_bg:
		push fs
		push gs

		push dword [gfx_cur]

		mov [gfx_width],dx
		mov [gfx_height],cx

		mov ax,[gfx_cur_x]
		mov cx,[gfx_cur_y]

		call clip_it
		jc restore_bg_90

		sub ax,[gfx_cur_x]
		neg ax
		mul word [pixel_bytes]
		movzx ebp,ax

		sub cx,[gfx_cur_y]
		neg cx
		movzx ecx,cx
		movzx ebx,bx
		imul ecx,ebx
		add ecx,ebp

		lea esi,[edi+ecx]

		movzx edx,word [gfx_width]
		movzx ecx,word [gfx_height]

		call goto_xy
		call screen_segs

		imul edx,[pixel_bytes]

restore_bg_20:
		push edx

restore_bg_30:
		es lodsb
		mov [gs:edi],al
		inc di
		jnz restore_bg_50
		call inc_winseg
restore_bg_50:
		dec edx
		jnz restore_bg_30

		pop edx

		mov eax,[screen_line_len]
		sub eax,edx
		add di,ax
		jnc restore_bg_60
		call inc_winseg
restore_bg_60:
		mov eax,ebx
		sub eax,edx
		add esi,eax

		dec ecx
		jnz restore_bg_20

restore_bg_90:
		pop dword [gfx_cur]

		pop gs
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Load screen segments.
;
; return:
;  fs		read segment
;  gs		write segment
;
; Modified registers: -
;

		bits 32

screen_segs:
		push eax
		mov ax,pm_seg.screen_r16
		mov fs,ax
		mov ax,pm_seg.screen_w16
		mov gs,ax
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Draw filled rectangle.
;
;  dx, cx	width, height
;  eax		color
;

		bits 32

fill_rect:
		push fs
		push gs

		mov [gfx_width],dx
		mov [gfx_height],cx

		call clip_it
		jc fill_rect_90

		movzx edx,word [gfx_width]
		movzx ecx,word [gfx_height]

		call goto_xy
		call screen_segs

		mov ebp,[screen_line_len]
		mov eax,edx
		imul eax,[pixel_bytes]
		sub ebp,eax

fill_rect_20:
		mov ebx,edx
fill_rect_30:
		call [setpixel_t]
		add di,[pixel_bytes]
		jnc fill_rect_60
		call inc_winseg
fill_rect_60:
		dec ebx
		jnz fill_rect_30

		add di,bp
		jnc fill_rect_80
		call inc_winseg
fill_rect_80:
		dec ecx
		jnz fill_rect_20

fill_rect_90:

		pop gs
		pop fs
		ret	


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Our timer interrut handler.
;
; Needed to play sound via pc-speaker.
;

		bits 16

new_int8:
		pushad
		push ds
		push es
		push fs
		push gs

		push cs
		pop ds

		mov al,20h
		out 20h,al

		inc dword [int8_count]

		cmp byte [sound_playing],0
		jnz new_int8_10

		mov ax,[sound_timer1]
		out 40h,al
		mov al,ah
		out 40h,al

		jmp new_int8_90

new_int8_10:

%if 0
		rdtsc
		mov esi,[next_int]
		mov edi,[next_int + 4]
		sub esi,eax
		sbb edi,edx
		jnc new_int8_20

		xor eax,eax
		xor edx,edx
		sub eax,esi
		sbb edx,edi

		mov [tmp_var_0],eax
		mov [tmp_var_1],edx
%endif

new_int8_20:
		rdtsc
		mov edi,edx
		mov esi,eax

		sub eax,[next_int]
		sbb edx,[next_int + 4]
		jb new_int8_20

		add esi,[cycles_per_int]
		adc edi,0
		mov [next_int],esi
		mov [next_int + 4],edi

		mov si,[sound_start]
		cmp si,[sound_end]
		jz new_int8_25

		les bx,[sound_buf]
		mov dl,[es:bx+si]

		cmp dl,0ffh
		jz new_int8_22

		mov al,[sound_61]
		out 61h,al
		and al,0xfe
		out 61h,al

		mov al,dl
		out 42h,al

new_int8_22:
		inc si
		cmp si,sound_buf_size
		jb new_int8_23
		xor si,si
new_int8_23:

		mov [sound_start],si

new_int8_25:
		mov ax,[sound_timer1]
		out 40h,al
		mov al,ah
		out 40h,al

		mov ax,[sound_timer0]
		or ax,ax
		jz new_int8_30
		add [sound_cnt0],ax
		jnc new_int8_40
new_int8_30:
		push word 40h
		pop es
		inc dword [es:6ch]
new_int8_40:

		cmp byte [sound_int_active],0
		jnz new_int8_90

		mov byte [sound_int_active],1

		sti

		mov ax,[sound_end]
		sub ax,[sound_start]
		jnc new_int8_60
		add ax,sound_buf_size
new_int8_60:
		cmp ax,160
		jae new_int8_80
		pm32_call mod_get_samples

new_int8_80:

		mov byte [sound_int_active],0
new_int8_90:

		pop gs
		pop fs
		pop es
		pop ds
		popad

		iret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Prepare sound subsystem.
;
; Installs a new timer interrupt handler and increases timer frequency.
;

		bits 32

sound_init:
		cmp byte [sound_ok],0
		jnz sound_init_90

		call chk_tsc
		jc sound_init_90

		mov eax,ar_sizeof
		call calloc
		cmp eax,1
		jc sound_init_90
		mov [mod_buf],eax

		call mod_init

		mov eax,sound_buf_size
		call calloc
		cmp eax,1
		jc sound_init_90
		mov [sound_buf.lin],eax
		mov edx,eax
		and eax,~0fh
		shl eax,12
		and edx,0fh
		mov ax,dx
		mov [sound_buf],eax

		xor eax,eax
		mov [int8_count],eax
		mov [sound_start],eax
		mov [sound_end],eax
		mov [sound_playing],al
		mov [sound_int_active],al

		mov edi,playlist
		add edi,[prog.base]
		mov ecx,playlist_entries * sizeof_playlist
		rep stosb

		pushf
		cli

		in al,61h
		mov [sound_old_61],al
		or al,3
		mov [sound_61],al

		mov al,92h
		out 43h,al

		mov al,30h
		out 43h,al

		xor ax,ax
		out 40h,al
		out 40h,al

		push dword [es:8*4]
		pop dword [sound_old_int8]

		push word [rm_prog_cs]
		push word new_int8
		pop dword [es:8*4]

		popf

		mov eax,[int8_count]
sound_init_40:
		cmp eax,[int8_count]
		jz sound_init_40

		rdtsc

		mov edi,edx
		mov esi,eax

		mov eax,[int8_count]
		add eax,4
sound_init_50:
		cmp eax,[int8_count]
		jnz sound_init_50

		rdtsc

		sub eax,esi
		sbb edx,edi

		shrd eax,edx,18
		adc eax,0
		mov [cycles_per_tt],eax

		mov [tmp_var_0],eax
		mov [tmp_var_1],edx

		mov eax,16000
		call sound_setsample

		xor eax,eax
		mov [next_int],eax
		mov [next_int+4],eax

		mov byte [sound_ok],1
sound_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Shut down sound subsystem.
;
; Activates old timer interrupt handler and sets timer frequency back to
; normal.
;
		bits 32

sound_done:
		cmp byte [sound_ok],0
		jz sound_done_90

		pushf
		cli

		mov al,[sound_old_61]
		out 61h,al

		mov al,36h
		out 43h,al

		xor ax,ax
		out 40h,al
		out 40h,al

		mov [sound_timer0],ax
		mov [sound_timer1],ax
		mov [sound_cnt0],ax
		mov [sound_playing],al

		push dword [sound_old_int8]
		pop dword [es:8*4]

		mov byte [sound_ok],0

		popf

		mov eax,[mod_buf]
		call free

		mov eax,[sound_buf.lin]
		call free

sound_done_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set sample rate for sound playback.
;
; eax		sample rate
;

		bits 32

sound_setsample:
		cmp eax,20
		jae sound_setsample_20
		mov eax,20
sound_setsample_20:
		cmp eax,18000
		jbe sound_setsample_50
		mov eax,18000
sound_setsample_50:
		mov [sound_sample],eax
		xchg eax,ecx
		mov eax,1193180
		xor edx,edx
		div ecx
		mov [sound_timer0],ax
		push eax
		mul dword [cycles_per_tt]
		mov [cycles_per_int],eax

		mov [tmp_var_2],eax

		pop eax

		; 5/4 faster
		imul eax,eax,4
		mov ecx,5
		div ecx

		mov [sound_timer1],ax
		mov [tmp_var_3],eax
		
		pushf
		cli
		out 40h,al
		mov al,ah
		out 40h,al
		popf
sound_setsample_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Test sound subsystem.
;

%if 0

		bits 32

sound_test:
		cmp dword [sound_x],0
		jz sound_test_80

		call sound_init
		jc sound_test_90

		mov eax,16000
		call sound_setsample

		mov byte [sound_playing],1

		jmp sound_test_90

sound_test_80:
		call sound_done
sound_test_90:
		ret
%endif


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Init mod player.
;
		bits 32

mod_init:
		mov esi,[mod_buf]
		call init
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

mod_load:
		mov esi,[mod_buf]
		call loadmod
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

mod_play:
		mov esi,[mod_buf]
		call playmod
		mov byte [sound_playing],1
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

mod_playsample:
		mov esi,[mod_buf]
		call playsamp
		mov byte [sound_playing],1
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

mod_get_samples:
		mov esi,[mod_buf]
		push esi
		call play
		pop esi

		mov dl,[es:esi]
		add esi,ar_samps

		; dl: 0/1 --> play nothing/play
		sub dl,1

		mov ecx,num_samples
		mov ebx,[sound_buf.lin]
		mov edi,[sound_end]
		cld

mod_get_samples_20:

		es lodsb
		or al,dl		; 0ffh if we play nothing
		mov [es:ebx+edi],al
		inc edi
		cmp edi,sound_buf_size
		jb mod_get_samples_50
		xor edi,edi

mod_get_samples_50:

		dec ecx
		jnz mod_get_samples_20
		mov [sound_end],edi

mod_get_samples_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set mod player volume.
;
; al		volume (0 .. 100)
;

		bits 32

mod_setvolume:
		cmp byte [sound_ok],0
		jz mod_setvolume_90

		mov esi,[mod_buf]

		movzx edx,al
		xor eax,eax
		or edx,edx
		jz mod_setvolume_50
		sub ax,1
		sbb dx,0
		mov bx,100
		div bx
mod_setvolume_50:
		mov ebx,eax
		xor ecx,ecx
		lea eax,[ecx-1]
		call setvol
mod_setvolume_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Check for cpuid instruction.
;
; return:
;  CF		0/1	yes/no
;

		bits 32

chk_cpuid:
		mov ecx,1 << 21
		pushf
		pushf
		pop eax
		xor eax,ecx
		push eax
		popf
		pushf
		pop edx
		popf
		xor eax,edx
		cmp eax,ecx
		stc
		jz chk_cpuid_90
		clc
chk_cpuid_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Check for time stamp counter.
;
; return:
;  CF		0/1	yes/no
;

		bits 32

chk_tsc:
		call chk_cpuid
		jc chk_tsc_90
		mov eax,1
		cpuid
		test dl,1 << 4
		jnz chk_tsc_90
		stc
chk_tsc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Check for 64 bit extension.
;
; return:
;  CF		0/1	yes/no
;

		bits 32

chk_64bit:
		call chk_cpuid
		jc chk_64bit_90
		mov eax,80000001h
		cpuid
		test edx,1 << 29
		jnz chk_64bit_90
		stc
chk_64bit_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;; test1 - for internal testing
;
; group: system
;
; ( ptr1 -- )
;
; ptr1: some value with obscure meaning
;
; example
;  0x123 test1
;

		bits 32

prim_test1:
		call pr_setptr_or_none
		mov [ddc_external],eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

prim_xxx:
;		call pr_setptr_or_none
		; eax
		rm32_call mouse_init
		or ah,ah
		mov eax,0
		jnz prim_xxx_90
		mov eax,mouse_x
		add eax,[prog.base]
prim_xxx_90:
		jmp pr_getptr_or_none


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Find (and read) file from file system.
;
;  eax		file name (lin)
;
; return:
;  eax		file start (lin)
;
; Note: use find_mem_size to find out the file size

		bits 32

find_file_ext:
		mov dl,t_string
		push eax
		call get_length
		xchg eax,ecx
		pop eax
		or ecx,ecx
		jz find_file_ext_80
		cmp ecx,64
		jae find_file_ext_80

		push ecx

		push eax
		mov al,0
		call gfx_cb			; get file name buffer address (edx)
		pop esi

		pop ecx

		or al,al
		jnz find_file_ext_80

		mov edi,edx
		es rep movsb
		mov al,0
		stosb

		mov al,1
		call gfx_cb			; open file (ecx size)
		or al,al
		jnz find_file_ext_80

		mov eax,ecx
		push ecx
		call calloc
		pop ecx
		or eax,eax
		jz find_file_ext_80

		push ecx
		push eax

		; eax: buffer, ecx: buffer size

		mov edi,eax

find_file_ext_20:
		push edi
		mov al,2
		call gfx_cb			; read next chunk (edx buffer, ecx len)
		pop edi
		or al,al
		jnz find_file_ext_50
		or ecx,ecx
		jz find_file_ext_50

		mov esi,edx
		es rep movsb

		jmp find_file_ext_20

find_file_ext_50:		

		pop eax
		pop ecx

		; did we get everything...?
		sub edi,ecx
		cmp eax,edi
		jz find_file_ext_90

		; ... no -> read error
		call free

find_file_ext_80:
		xor eax,eax
find_file_ext_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Find file from file system, returns size.
;
;  eax		file name (lin)
;
; return:
;  eax		file size (-1: not found)
;

		bits 32

file_size_ext:
		mov dl,t_string
		push eax
		call get_length
		xchg eax,ecx
		pop eax
		or ecx,ecx
		jz file_size_ext_80
		cmp ecx,64
		jae file_size_ext_80

		push ecx
		push eax

		mov al,0
		call gfx_cb			; get file name buffer address (edx)
		mov edi,edx

		pop esi
		pop ecx

		or al,al
		jnz file_size_ext_80

		es rep movsb
		mov al,0
		stosb

		mov al,1
		call gfx_cb			; open file (ecx size)
		or al,al
		jnz file_size_ext_80

		mov eax,ecx
		jmp file_size_ext_90

file_size_ext_80:
		stc
		sbb eax,eax
file_size_ext_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Clip image area.
;
; [line_x0]		left, incl
; [line_x1]		right, excl
; [line_y0]		top, incl
; [line_y1]		bottom, excl
;
; return:
;  CF			1 = empty area
;  If CF = 0		Area adjusted to fit within [line_*].
;  If CF = 1		Undefined values in [line_*].
;

		bits 32

clip_image:
		movzx edx,word [image_width]
		mov eax,[line_x0]
		mov ecx,[line_x1]

		call clip_image_10
		jc clip_image_90

		mov [line_x0],eax
		mov [line_x1],ecx

		movzx edx,word [image_height]
		mov eax,[line_y0]
		mov ecx,[line_y1]

		call clip_image_10

		mov [line_y0],eax
		mov [line_y1],ecx

		jmp clip_image_90

clip_image_10:
		cmp eax,0
		jge clip_image_20
		xor eax,eax
clip_image_20:
		cmp ecx,edx
		jle clip_image_30
		mov ecx,edx
clip_image_30:
		cmp ecx,eax
		jle clip_image_80
		cmp eax,edx
		jge clip_image_80
		clc
		jmp clip_image_90
clip_image_80:
		stc
clip_image_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Draw image into buffer.
;
; eax			drawing buffer
; [image]		image
; dword [line_x0]	x0	; upper left
; dword [line_y0]	y0
; dword [line_x1]	x1	; lower right
; dword [line_y1]	y1
;

		bits 32

unpack_image:
		cmp byte [image_type],1
		jnz unpack_image_20
		call pcx_unpack
		jmp unpack_image_90
unpack_image_20:
		cmp byte [image_type],2
		jnz unpack_image_90
		call jpg_unpack
unpack_image_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Activate image from file.
;
;  eax		lin ptr to image
;
; return:
;  CF		error
;

		bits 32

image_init:
		call pcx_init
		jnc image_init_90
		call jpg_init
image_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Draw image region on screen.
;
; [image]		jpg image
; dword [line_x0]	x0	; uppper left
; dword [line_y0]	y0
; dword [line_x1]	x1	; lower right
; dword [line_y1]	y1
;

		bits 32

show_image:
		xor esi,esi
		xor eax,eax
show_image_10:
		push esi
		push eax
		call memsize
		pop eax
		pop esi
		cmp edi,esi
		jb show_image_20
		mov esi,edi
show_image_20:
		inc eax
		cmp eax,malloc.areas
		jb show_image_10

		; esi: largest free mem block

		sub esi,4		; fb header size
		jc show_image_90

		mov ebx,[line_y1]
		sub ebx,[line_y0]

		mov ecx,[line_x1]
		sub ecx,[line_x0]

		mov eax,[pixel_bytes]
		mul ecx
		xchg eax,esi
		div esi

		; fb height

		cmp eax,ebx
		jbe show_image_30
		mov eax,ebx
show_image_30:
		mov [line_tmp],eax

		or eax,eax
		jz show_image_90

		; eax, ecx, height, width
		call alloc_fb

		or eax,eax
		jz show_image_90

		mov [line_tmp2],eax

show_image_40:
		mov eax,[line_y1]
		sub eax,[line_y0]
		jle show_image_70
		mov ebp,[line_tmp]
		cmp eax,ebp
		jle show_image_50
		mov eax,ebp
show_image_50:
		mov bp,ax
		add eax,[line_y0]
		xchg eax,[line_y1]

		push eax
		mov eax,[line_tmp2]

		push ebp

		cmp byte [image_type],1
		jnz show_image_54
		call pcx_unpack
		jmp show_image_56
show_image_54:
		cmp byte [image_type],2
		jnz show_image_56
		call jpg_unpack
show_image_56:

		pop ebp

		mov edi,[line_tmp2]
		mov dx,[es:edi]
		mov cx,[es:edi+2]

		cmp cx,bp
		jbe show_image_60
		mov cx,bp
show_image_60:

		mov edi,[line_tmp2]
		add edi,4
		mov bx,dx
		imul bx,[pixel_bytes]
		call restore_bg

		mov eax,[line_y1]
		mov ecx,eax
		sub ecx,[line_y0]
		mov [line_y0],eax

		add [gfx_cur_y],cx

		pop eax

		mov [line_y1],eax
		jmp show_image_40

show_image_70:
		mov eax,[line_tmp2]
		call free
show_image_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Activate pcx image from file.
;
;  eax		pcx image
;
; return:
;  eax		pcx image
;  CF		error
;

		bits 32

pcx_init:
		push eax
		cmp dword [es:eax],0801050ah
		jnz pcx_init_80

		mov cx,[es:eax+8]
		inc cx
		jz pcx_init_80
		mov dx,[es:eax+10]
		inc dx
		jz pcx_init_80

		push eax
		push ecx
		push edx
		push ebx
		call find_mem_size
		pop ebx
		pop edx
		pop ecx
		pop edi

		; edi: image, eax: size, cx: width, dx: height

		cmp eax,381h
		jb pcx_init_80

		lea esi,[eax+edi-301h]

		cmp byte [es:esi],12
		jnz pcx_init_80

		inc esi

		mov byte [image_type],1		; pcx

		mov [image],edi
		mov [image_width],cx
		mov [image_height],dx

		push esi
		call parse_pcx_img
		pop esi

		mov edi,[gfx_pal]

		mov ecx,300h
		push ecx
		es rep movsb
		pop ecx

		xor eax,eax
		mov edx,ecx
		dec edi
		std
		repz scasb
		cld
		setnz al
		sub edx,ecx
		sub edx,eax
		xchg eax,edx
		xor edx,edx
		mov ecx,3
		div ecx
		sub eax,100h
		neg eax
		mov [pals],ax

		clc
		jmp pcx_init_90
		
pcx_init_80:
		stc
pcx_init_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 32

parse_pcx_img:
		mov eax,[pcx_line_starts]
		or eax,eax
		jz parse_pcx_img_10
		call free
parse_pcx_img_10:
		movzx eax,word [image_height]
		shl eax,2
		call calloc
		or eax,eax
		stc
		mov [pcx_line_starts],eax
		jz parse_pcx_img_90

		mov edi,eax
		mov esi,[image]
		add esi,80h		; skip pcx header

		xor edx,edx		; y count

parse_pcx_img_20:
		xor ecx,ecx		; x count
		mov [es:edi],esi
		add edi,4
parse_pcx_img_30:
		es lodsb
		cmp al,0c0h
		jb parse_pcx_img_40
		and eax,3fh
		inc esi
		add ecx,eax
		dec ecx
parse_pcx_img_40:
		inc ecx
		cmp cx,[image_width]
		jb parse_pcx_img_30
		stc
		jnz parse_pcx_img_90		; no decoding break at line end?

		inc edx
		cmp dx,[image_height]
		jb parse_pcx_img_20

parse_pcx_img_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Draw pcx image region into buffer.
;
; eax			drawing buffer
; [image]		pcx image
; dword [line_x0]	x0	; uppper left
; dword [line_y0]	y0
; dword [line_x1]	x1	; lower right
; dword [line_y1]	y1
;
; note:
;  [line_*] are unchanged
;

		bits 32

pcx_unpack:
		push dword [line_x1]
		push dword [line_y1]

		mov ebp,[pcx_line_starts]

		lea edi,[eax+4]

		mov eax,[line_x0]
		sub [line_x1],eax

		mov eax,[line_y0]
		sub [line_y1],eax

		shl eax,2
		add ebp,eax

pcx_unpack_20:
		mov esi,[es:ebp]

		mov ecx,[line_x0]
		neg ecx

		; draw one line
pcx_unpack_30:
		xor eax,eax
		es lodsb

		cmp al,0c0h
		jb pcx_unpack_70

		; repeat count

		and eax,3fh
		mov edx,eax
		es lodsb

		add ecx,edx
		js pcx_unpack_80
		jnc pcx_unpack_40
		mov edx,ecx

pcx_unpack_40:
		mov ebx,ecx
		sub ebx,[line_x1]
		jle pcx_unpack_50
		sub edx,ebx
pcx_unpack_50:
		or edx,edx
		jz pcx_unpack_80
		dec edx
		cmp byte [pixel_bytes],1
		jbe pcx_unpack_54
		push eax
		call pal_to_color
		call encode_color
		call [setpixel_a]
		pop eax
		jmp pcx_unpack_55
pcx_unpack_54:
		mov [gs:edi],al
pcx_unpack_55:
		add edi,[pixel_bytes]
		jmp pcx_unpack_50

pcx_unpack_70:
		inc ecx
		cmp ecx,0
		jle pcx_unpack_80
		cmp byte [pixel_bytes],1
		jbe pcx_unpack_74
		call pal_to_color
		call encode_color
pcx_unpack_74:
		call [setpixel_a]
		add edi,[pixel_bytes]
pcx_unpack_80:
		cmp ecx,[line_x1]
		jl pcx_unpack_30

		add ebp,4
		dec dword [line_y1]
		jnz pcx_unpack_20

pcx_unpack_90:
		pop dword [line_y1]
		pop dword [line_x1]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Allocate static buffer for jpeg decoder.
;
; return:
;  [jpg_static_buf]	buffer
;
		bits 32

jpg_setup:
		cmp dword [jpg_static_buf], 0
		jnz jpg_setup_90

		mov eax,jpg_data_size + 15
		call calloc
		or eax,eax
		stc
		jz jpg_setup_90

		; align a bit
		add eax,15
		and eax,~15

		mov [jpg_static_buf],eax
jpg_setup_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Activate jpeg image from file.
;
;  eax		jpeg image
;
; return:
;  eax		jpeg image
;  CF		error
;

		bits 32

jpg_init:
		push eax

		push eax
		call jpg_setup
		pop eax

		cmp dword [jpg_static_buf],0
		jz jpg_init_80

		push eax
		call find_mem_size
		mov ecx,eax
		pop eax

		or ecx,ecx
		jz jpg_init_80

		cmp dword [es:eax],0e0ffd8ffh
		jnz jpg_init_80

		call jpg_size
		jc jpg_init_90

		mov [image_width],ax
		shr eax,16
		mov [image_height],ax

		mov byte [image_type],2		; jpg

		pop eax
		push eax
		mov [image],eax

		clc
		jmp jpg_init_90
		
jpg_init_80:
		stc
jpg_init_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read jpeg image size.
;
; eax		jpeg image
;
; return:
;  eax		size (low word: width, high word: height)
;  CF		error
;

		bits 32

jpg_size:
		push fs
		push eax

		mov si,pm_seg.data_d16
		mov eax,[jpg_static_buf]
		call set_gdt_base_pm
		mov fs,si

		call dword jpeg_get_size

		pop ecx

		or eax,eax
		jnz jpg_size_90
		stc
jpg_size_90:
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Unpack image region from jpeg.
;
; eax			drawing buffer
; [image]		jpeg image
; dword [line_x0]	x0
; dword [line_y0]	y0
; dword [line_x1]	x1
; dword [line_y1]	y1
;
; note:
;  [line_*] are unchanged
;

		bits 32

jpg_unpack:
		push fs

		movzx edx,byte [pixel_bits]
		cmp dl,16
		jz jpg_unpack_10
		cmp dl,32
		jnz jpg_unpack_90

jpg_unpack_10:

		push dword edx
		push dword [line_y1]
		push dword [line_y0]
		push dword [line_x1]
		push dword [line_x0]
		add eax,4
		push eax
		push dword [image]

		mov si,pm_seg.data_d16
		mov eax,[jpg_static_buf]
		call set_gdt_base_pm
		mov fs,si

		call dword jpeg_decode

		add sp,28

jpg_unpack_90:
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Install mouse handler.
;
; Note: experimental.
;

		bits 16

mouse_init:
		push cs
		pop es
		mov bx,mouse_handler
		mov ax,0c207h
		int 15h
		jc mouse_init_90
		mov ax,0c200h
		mov bh,1
		int 15h
		jc mouse_init_90
		mov al,ah
mouse_init_90:
		ret


mouse_x		dw 0
mouse_y		dw 0
mouse_button	dw 0

mouse_handler:
		movsx ax,byte [esp+6]
		add [cs:mouse_y],ax
		movsx ax,byte [esp+8]
		add [cs:mouse_x],ax
		mov ax,[esp+10]
		mov [cs:mouse_button],ax

		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get monitor capabilities.
;
;

		bits 32

get_monitor_res:
		call read_ddc
		call read_fsc

		; convert timing bitmask to resolution
		; if the card has enough memory assume larger resolutions

		mov ax,[ddc_timings]
		mov dword [ddc_xtimings],640 + (480 << 16)
		test ax,0ef03h
		jnz get_mon_res_20
		cmp word [screen_mem],0x3e		; at least 4MB-128k
		jb get_mon_res_21
get_mon_res_20:
		mov dword [ddc_xtimings],800 + (600 << 16)
get_mon_res_21:
		test ax,0f00h
		jnz get_mon_res_22
		cmp word [screen_mem],0x200		; at least 32MB
		jb get_mon_res_23
get_mon_res_22:
		mov dword [ddc_xtimings],1024 + (768 << 16)
get_mon_res_23:
		test ax,0100h
		jz get_mon_res_24
		mov dword [ddc_xtimings],1280 + (1024 << 16)
get_mon_res_24:

		; find max. resolution

		mov ecx,5
		mov esi,ddc_xtimings

get_mon_res_30:
		mov ax,[esi]
		mov dx,[esi+2]

		cmp ax,[ddc_xtimings]
		jb get_mon_res_60

		cmp dx,[ddc_xtimings+2]
		jb get_mon_res_60

		mov [ddc_xtimings],ax
		mov [ddc_xtimings+2],dx

get_mon_res_60:
		add esi,4
		loop get_mon_res_30

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read EDID record via DDC
;

		bits 32

read_ddc:
		; vbe support check
		cmp word [screen_mem],0
		jz read_ddc_90

		xor ebp,ebp

read_ddc_20:
		mov edi,[vbe_buffer]

		mov ecx,80h
		xor eax,eax
		push edi
		rep stosb
		pop edi

		mov esi,[ddc_external]
		or esi,esi
		jz read_ddc_25
		mov ecx,80h
		rep movsb
		jmp read_ddc_30

read_ddc_25:

		mov eax,edi
		shr eax,4
		mov [rm_seg.es],ax
		and edi,0fh

                mov ax,4f15h
		mov bl,1
		mov cx,bp
		xor dx,dx
		push ebp
		int 10h
		pop ebp
		cmp ax,4fh
		jz read_ddc_30

		inc ebp
		cmp ebp,2		; some BIOSes don't like more (seen on a Packard Bell EasyNote)
		jb read_ddc_20

		jmp read_ddc_90

read_ddc_30:

		mov edi,[vbe_buffer]

		mov ax,[es:edi+23h]
		mov [ddc_timings],ax

		mov ecx,4
		lea esi,[edi+26h]
		mov edi,ddc_xtimings1
read_ddc_40:
		es lodsb
		cmp al,1
		jbe read_ddc_70
		
		movzx ebp,al
		add ebp,31
		shl ebp,3

		mov al,[es:esi]
		shr al,6
		jz read_ddc_70
		movzx ebx,al
		shl ebx,3

		mov eax,ebp
		mul dword [ebx+ddc_mult]
		div dword [ebx+ddc_mult+4]
		
		jz read_ddc_70

		shl eax,16
		add eax,ebp
		mov [edi],eax

read_ddc_70:
		inc esi
		add edi,4
		loop read_ddc_40

read_ddc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Look for a fsc notebook lcd panel and set ddc_timings.
;

		bits 32

read_fsc:
		cmp word [ddc_timings],0
		jnz read_fsc_90

		mov edi,0f0000h
read_fsc_10:
		cmp dword [es:edi],0x696a7546
		jnz read_fsc_30
		cmp dword [es:edi+4],0x20757374
		jnz read_fsc_30
		mov ecx,0x20
		xor ebx,ebx
		mov esi,edi
read_fsc_20:
		es lodsb
		add bl,al
		dec ecx
		jnz read_fsc_20
		or bl,bl
		jnz read_fsc_30
		mov al,[es:edi+23]
		and al,0xf0
		jnz read_fsc_90
		mov bl,[es:edi+21]
		and bl,0xf0
		shr bl,3
		mov ax,[fsc_bits+ebx]
		mov [ddc_timings],ax
		jmp read_fsc_90
read_fsc_30:
		add edi,0x10
		cmp edi,100000h
		jbe read_fsc_10
read_fsc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Read vbe card info.
;
; al		info type
;		  0: video mem size in kb
;		  1: oem string
;		  2: vendor string
;		  3: product string
;		  4: revision string
;
; return:
;  eax		info
;   dl		info type (enum_type_t)
;

		bits 32

videoinfo:
		mov edi,[vbe_buffer]

		push eax
		push edi

		mov ecx,200h/4
		xor eax,eax
		push edi
		rep stosd
		pop edi
		mov dword [es:edi],32454256h	; 'VBE2'

		mov eax,edi
		shr eax,4
		mov [rm_seg.es],ax
		and edi,0fh

		mov ax,4f00h
		int 10h

		pop edi
		xor ecx,ecx
		cmp ax,4fh
		pop eax
		jnz videoinfo_80

		cmp word [screen_mem],0
		jnz videoinfo_20
		push word [es:edi+12h]
		pop word [screen_mem]
videoinfo_20:
		cmp al,0
		jnz videoinfo_30
		movzx eax,word [screen_mem]
		shl eax,6
		mov dl,t_int
		jmp videoinfo_90
videoinfo_30:
		cmp al,1
		jnz videoinfo_31
		add edi,6
		jmp videoinfo_50
videoinfo_31:
		cmp al,2
		jnz videoinfo_32
		add edi,16h
		jmp videoinfo_50
videoinfo_32:
		cmp al,3
		jnz videoinfo_33
		add edi,1ah
		jmp videoinfo_50
videoinfo_33:
		cmp al,4
		jnz videoinfo_34
		add edi,1eh
		jmp videoinfo_50
videoinfo_34:
		; add more here...

		jmp videoinfo_80

videoinfo_50:
		cmp dword [es:edi],0
		jz videoinfo_90
		movzx esi,word [es:edi]
		movzx ecx,word [es:edi+2]
		shl ecx,4
		add esi,ecx
		mov ecx,100h-1
		mov edi,[vbe_info_buffer]
videoinfo_55:
		es lodsb
		stosb
		or al,al
		jz videoinfo_57
		dec ecx
		jnz videoinfo_55
		mov byte [es:edi],0
videoinfo_57:
		mov eax,[vbe_info_buffer]
		mov dl,t_string
		jmp videoinfo_90

videoinfo_80:
		mov dl,t_none
		xor eax,eax
videoinfo_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Switch to local stack.
;
; no regs or flags changed
;

		bits 16

use_local_stack:
		; cmp dword [old_stack.ofs],0
		; jnz $
		pop word [tmp_stack_val]
		mov [old_stack.ofs],esp
		mov [old_stack.seg],ss
		lss esp,[local_stack]
		jmp [tmp_stack_val]


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Switch back to system wide stack.
;
; no regs or flags changed
;

		bits 16

use_old_stack:
		; cmp dword [old_stack.ofs],0
		; jz $
		pop word [tmp_stack_val]
		lss esp,[old_stack]
		mov dword [old_stack.ofs],0
		jmp [tmp_stack_val]


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set segment descriptor base in gdt (32 bit code).
;
; si		descriptor
; eax		base
;
; changes no regs
;

		bits 32

set_gdt_base_pm:
		push eax
		mov [gdt+si+2],ax
		shr eax,16
		mov [gdt+si+4],al
		mov [gdt+si+7],ah
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set segment descriptor base in gdt.
;
; si		descriptor
; eax		base
;
; changes no regs
;

		bits 16

set_gdt_base:
		push eax
		mov [gdt+si+2],ax
		shr eax,16
		mov [gdt+si+4],al
		mov [gdt+si+7],ah
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set segment descriptor limit in gdt.
;
; si		descriptor
; eax		limit (largest address)
;
; changes no regs
;

		bits 16

set_gdt_limit:
		push eax
		push dx
		mov dl,0
		cmp eax,0fffffh
		jbe set_gdt_limit_40
		shr eax,12
		mov dl,80h	; big segment
set_gdt_limit_40:
		mov [gdt+si],ax
		shr eax,16
		mov ah,[gdt+si+6]
		and ah,70h
		or ah,al
		or ah,dl
		mov [gdt+si+6],ah
		pop dx
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Preliminary protected mode interface init.
;
; Setup gdt so we can at least switch modes with interrupts disabled.
;

		bits 16

gdt_init:
		mov eax,cs
		mov [rm_prog_cs],ax

		shl eax,4
		mov [prog.base],eax

		lea edx,[eax+gdt]
		mov [pm_gdt.base],edx

		mov si,pm_seg.prog_c32
		call set_gdt_base

		mov si,pm_seg.prog_d16
		call set_gdt_base

		mov si,pm_seg.prog_c16
		call set_gdt_base

		mov eax,0ffffh

		mov si,pm_seg.prog_c32
		call set_gdt_limit

		mov si,pm_seg.prog_d16
		call set_gdt_limit

		mov si,pm_seg.prog_c16
		call set_gdt_limit

		mov si,pm_seg.data_d16
		call set_gdt_limit

		mov si,pm_seg.screen_r16
		call set_gdt_limit

		mov si,pm_seg.screen_w16
		call set_gdt_limit

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Complete protected mode setup.
;
; Initialize idt and setup interrupt handlers.
;

		bits 32

pm_init:
		mov eax,(8+8)*100h
		call xcalloc
		cmp eax,1
		jc pm_init_90
		mov [pm_idt.base],eax

		; setup idt

		mov esi,[pm_idt.base]
		lea ebx,[esi+8*100h]
		mov edi,ebx
		mov eax,8e000000h + pm_seg.4gb_c32

		mov ecx,100h
pm_init_20:
		mov [es:esi],ebx
		mov [es:esi+4],ebx
		mov [es:esi+2],eax
		add esi,8
		add ebx,8
		loop pm_init_20		

		; push eax, call far pm_seg.prog_c32:pm_int
		mov eax,9a50h + (((pm_int - _start) & 0xffff) << 16)
		mov edx,(((pm_int - _start) >> 16) & 0xffff) + (pm_seg.prog_c32 << 16)

		mov ch,1
pm_init_40:
		mov [es:edi],eax
		mov [es:edi+4],edx
		add edi,8
		loop pm_init_40

pm_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Protected mode interrupt handler.
;
; switches to real mode and runs the real mode interrupt handler
;
; Note: processor generated ints with error code are not properly handled.
;

		bits 32

pm_int:
		pop eax

		push ds
		push es
		push fs
		push gs

		push ebx
		mov bx,pm_seg.prog_d16
		mov ds,bx
		mov bx,pm_seg.4gb_d32
		mov es,bx
		pop ebx

		pushfw
		push word [rm_prog_cs]
		push word pm_int_50

		sub eax,[pm_idt.base]
		shr eax,1
		sub eax,101h*4

		; eax = int_nr*4

		push dword [es:eax]

		; get original eax
		mov eax,[esp+4+3*2+4*4+4]	; seg from far call

		pm_leave

		; jmp to int handler & continue at pm_int_50
		retf
pm_int_50:

		pm_enter

		pop gs
		pop fs
		pop es
		pop ds

		; update arithmetic flags
		push eax
		lahf
		mov [esp+4*5],ah
		pop eax

		add esp,4*2		; skip eax & seg from far call

		iret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Switch from real mode to 32 bit protected mode.
;
; Assumes cs = .text.
;
; No normal regs or flags changed.
; Segment regs != cs are stored in rm_seg.
; ds = .text; ss, es, fs, gs = 4GB selector
;

		bits 16

switch_to_pm:
		pushf
		push eax

		mov eax,cr0

		test al,1
		jnz $			; FIXME - for testing

		cli

		mov word [cs:rm_seg.ss],ss

		mov word [cs:rm_seg.ds],ds
		mov word [cs:rm_seg.es],es
		mov word [cs:rm_seg.fs],fs
		mov word [cs:rm_seg.gs],gs

		or al,1
		o32 lgdt [cs:pm_gdt]
		o32 lidt [cs:pm_idt]
		mov cr0,eax
		jmp pm_seg.prog_c32:switch_to_pm_20
switch_to_pm_20:

		bits 32

		mov ax,pm_seg.prog_d16
		mov ds,ax

		mov eax,ss
		and esp,0ffffh
		shl eax,4
		add esp,eax
		mov ax,pm_seg.4gb_d32
		mov ss,ax

		mov es,ax
		mov fs,ax
		mov gs,ax

		pop eax
		popfw
		o16 ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Switch from 32 bit protected mode to real mode.
;
; Assumes cs = .text
;
; No normal regs or flags changed.
; Segment regs != cs are taken from rm_seg.
;

		bits 32

switch_to_rm:
		pushfw
		push eax
		push edx

		mov eax,cr0

		test al,1
		jz $				; FIXME - for testing

		cli

		o32 lidt [cs:rm_idt]

		mov dx,pm_seg.prog_d16
		mov ss,dx
		mov ds,dx
		mov es,dx
		mov fs,dx
		mov gs,dx

		; first down to 16 bit...
		jmp pm_seg.prog_c16:switch_to_rm_10
switch_to_rm_10:

		bits 16

		and al,~1
		mov cr0,eax

		; ... then reload cs
		jmp 0:switch_to_rm_20
rm_prog_cs	equ $-2				; our real mode cs value (patched here)
switch_to_rm_20:

		movzx eax,word [cs:rm_seg.ss]
		mov ss,ax
		shl eax,4
		sub esp,eax

		mov ds,[cs:rm_seg.ds]
		mov es,[cs:rm_seg.es]
		mov fs,[cs:rm_seg.fs]
		mov gs,[cs:rm_seg.gs]

		pop edx
		pop eax
		popf
		o32 ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 32

%include	"kroete.inc"
%include	"modplay.inc"

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; code end

_end:

