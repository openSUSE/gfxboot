			bits 16

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
; struct font_header_t
foh_magic		equ 0
foh_entries		equ 4
foh_height		equ 6
foh_line_height		equ 7
sizeof_font_header_t	equ 8

; char data header definition
; struct char_header_t
ch_ofs			equ 0
ch_c			equ 2
ch_size			equ 4
sizeof_char_header_t	equ 8		; must be 8, otherwise change find_char

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
li_label		equ 0
li_text			equ 2
li_x			equ 4
li_row			equ 6
sizeof_link		equ 8		; search for 'sizeof_link'!
link_entries		equ 64

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
; the memory area we are working with
mem			dd 0		; (lin) data start address
mem_free		dd 0		; (lin) start of free area for malloc
mem_max			dd 0		; (lin) end address
mem_archive		dd 0		; (lin) archive start address (0 -> none), ends at mem_free

malloc.areas		equ 4
malloc.start		dd 0
malloc.end		dd 0
			; start, end pairs
malloc.area		times malloc.areas * 2 dd 0

vbe_buffer		dd 0		; (seg:ofs) buffer for vbe calls
vbe_buffer.ofs		equ vbe_buffer
vbe_buffer.seg		equ vbe_buffer+2
vbe_buffer.lin		dd 0		; (lin) dto
vbe_mode_list		dd 0		; (seg:ofs) list with (up to 100h) vbe modes
vbe_mode_list.ofs	equ vbe_mode_list
vbe_mode_list.seg	equ vbe_mode_list+2
vbe_mode_list.lin	dd 0		; (lin) dto
vbe_info_buffer		dd 0		; (lin) buffer for vbe gfx card info
infobox_buffer		dd 0		; (lin) temp buffer for InfoBox messages

local_stack		dd 0		; ofs local stack (8k)
local_stack.ofs		equ local_stack
local_stack.seg		dw 0		; dto, seg
old_stack		dd 0		; store old esp value
old_stack.ofs		equ old_stack
old_stack.seg		dw 0		; dto, ss
stack_size		dd 0		; in bytes
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
dict			dd 0		; seg:ofs
dict.lin		dd 0		; lin
dict_size		dd 0		; dict entries

boot_cs			dw 0		; seg
boot_sysconfig		dw 0		; ofs
boot_callback		dd 0 		; seg:ofs

pstack			dd 0		; (seg:ofs)
pstack.lin		dd 0		; (lin)
pstack_size		dd 0		; entries
pstack_ptr		dd 0
rstack			dd 0		; (seg:ofs)
rstack.lin		dd 0		; (lin)
rstack_size		dd 0		; entries
rstack_ptr		dd 0

image			dd 0		; (lin) current image
image_width		dw 0
image_height		dw 0
image_data		dd 0		; (seg:ofs)
image_pal		dd 0		; (seg:ofs)
image_type		db 0		; 0:no image, 1: pcx, 2:jpeg

pcx_line_starts		dd 0		; (lin) table of line starts
jpg_static_buf		dd 0		; (lin) tmp data for jpeg decoder

screen_width		dw 0
screen_height		dw 0
screen_vheight		dw 0
screen_mem		dw 0		; mem in 64k
screen_line_len		dd 0

setpixel		dw setpixel_8		; function that sets one pixel
setpixel_a		dw setpixel_a_8		; function that sets one pixel
setpixel_t		dw setpixel_8		; function that sets one pixel
setpixel_ta		dw setpixel_a_8		; function that sets one pixel
getpixel		dw getpixel_8		; function that gets one pixel

pm_setpixel		dd pm_setpixel_8		; function that sets one pixel
pm_setpixel_a		dd pm_setpixel_a_8		; function that sets one pixel
pm_setpixel_t		dd pm_setpixel_8		; function that sets one pixel
pm_setpixel_ta		dd pm_setpixel_a_8		; function that sets one pixel
pm_getpixel		dd pm_getpixel_8		; function that gets one pixel


transp			dd 0		; transparency

			align 4, db 0
; current font description
font			dd 0		; (lin)
font_entries		dw 0		; chars in font
font_height		dw 0
font_line_height	dw 0
font_properties		db 0		; bit 0: pw mode (show '*')
font_res1		db 0		; alignment

; console font
cfont			dd 0		; (seg:ofs) to bitmap
cfont.lin		dd 0		; console font bitmap
cfont_height		dw 0
con_x			dw 0		; cursor pos in pixel
con_y			dw 0		; cursor pos in pixel, *must* follow con_x


; current char description
chr_bitmap		dd 0		; ofs rel. to [font]
chr_x_ofs		dw 0
chr_y_ofs		dw 0
chr_real_width		dw 0
chr_real_height		dw 0
chr_width		dw 0

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
line_wrap		dw 0

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
last_label		dw 0		; ofs, seg = [row_start_seg]
page_title		dw 0		; ofs, seg = [row_start_seg]
max_rows		dw 0		; max. number of text rows
cur_row			dw 0		; current text row (0 based)
cur_row2		dw 0		; dto, only durig formatting
start_row		dw 0		; start row for text output
cur_link		dw 0		; link count
sel_link		dw 0		; selected link
txt_state		db 0		; bit 0: 1 = skip text
					; bit 1: 1 = text formatting only
run_idle		db 0

textmode_color		db 7		; fg color for text (debug) output
keep_mode		db 0		; keep video mode in gfx_done

			align 2, db 0
row_start_seg		dw 0
row_start_ofs		times max_text_rows dw 0

			; note: link_list relies on row_start_seg
link_list		times sizeof_link * link_entries db 0

			; max label size: 32
label_buf		times 35 db 0

; buffer for number conversions
; must be large enough for ps_status_info()
num_buf			times 23h db 0
num_buf_end		db 0

; temp data for printf
tmp_write_data		times 10h dd 0
tmp_write_num		dw 0
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
sound_start		dw 0		; rel. to sound_buf
sound_end		dw 0		; rel. to sound_buf
playlist		times playlist_entries * sizeof_playlist db 0
mod_buf			dd 0		; (seg:ofs)
int8_count		dd 0
cycles_per_tt		dd 0
cycles_per_int		dd 0
next_int		dd 0,0

			align 4, db 0
; temporary vars
tmp_var_0		dd 0
tmp_var_1		dd 0
tmp_var_2		dd 0
tmp_var_3		dd 0

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
pm_seg			equ 8
pm_seg.4gb_d32		equ 8			; covers all 4GB, default ss, es, fs, gs
pm_seg.4gb_c32		equ 10h			; dto, but executable (for e.g., idt)
pm_seg.prog_c32		equ 18h			; default cs, use32
pm_seg.prog_d16		equ 20h			; default ds
pm_seg.prog_c16		equ 28h			; default cs, use16
pm_seg.data_d16		equ 30h			; free to use
pm_seg.screen_r16	equ 38h			; graphics window, for reading
pm_seg.screen_w16	equ 40h			; graphics window, for writing

pm_large_seg		db 0			; active large segment mask
pm_seg_mask		db 0			; segment bit mask (1:es, 2:fs, 3:gs)

%if debug
; debug texts
dmsg_01			db 'static memory: %p - %p', 10, 0
dmsg_02			db '     malloc %d: %p - %p', 10, 0
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

%macro		lin2segofs 3
		push %1
		call lin2so
		pop %3
		pop %2
%endmacro

%macro		segofs2lin 3
		push %1
		push %2
		call so2lin
		pop %3
%endmacro

%macro		lin2seg 3
		push %1
		%ifidn %2,es
		  call _lin2es
		%elifidn %2,fs
		  call _lin2fs
		%elifidn %2,gs
		  call _lin2gs
		%else
		  %error "invalid segment argument"
		%endif
		pop %3
%endmacro


%macro		debug_print 2
		push %1
		pop dword [tmp_write_data]
		push es
		push fs
		pushad
		mov si,%%msg
		call printf
		popad
		pop fs
		pop es
		jmp %%cont
%%msg		db %2, ': %x', 10, 0
%%cont:
%endmacro


%macro		debug_printw 2
		push %1
		pop dword [tmp_write_data]
		push es
		push fs
		pushad
		mov si,%%msg
		call printf
		call get_key
		popad
		pop fs
		pop es
		jmp %%cont
%%msg		db %2, ': %x', 10, 0
%%cont:
%endmacro


%macro		switch_to_bits 1
		%ifidn %1,16
%%j_16_1:
		  jmp pm_seg.prog_c16:%%j_16_2
%%j_16_2:
		  %if %%j_16_2 - %%j_16_1 != 7
		    %error "switch_to_bits 16: not in 32 bit mode"
		  %endif

		  bits 16
		%elifidn %1,32
%%j_32_1:
		  jmp pm_seg.prog_c32:%%j_32_2
%%j_32_2:
		  %if %%j_32_2 - %%j_32_1 != 5
		    %error "switch_to_bits 32: not in 16 bit mode"
		  %endif

		  bits 32
		%else
		  %error "invalid bits"
		%endif
%endmacro


%macro		pm_leave 1
		%ifidn %1,16
%%j_16_1:
		  call switch_to_rm
%%j_16_2:
		  %if %%j_16_2 - %%j_16_1 != 3
		    %error "pm_leave %1: not in 16 bit mode"
		  %endif

		  bits 16
		%elifidn %1,32
%%j_32_1:
		  call switch_to_rm32
%%j_32_2:
		  %if %%j_32_2 - %%j_32_1 != 5
		    %error "pm_leave %1: not in 32 bit mode"
		  %endif

		  bits 16
		%else
		  %error "invalid argument"
		%endif
%endmacro


%macro		pm_enter 1
		%ifidn %1,16
%%j_16_1:
		  call switch_to_pm
%%j_16_2:
		  %if %%j_16_2 - %%j_16_1 != 3
		    %error "pm_enter %1: not in 16 bit mode"
		  %endif

		  bits 16
		%elifidn %1,32
%%j_32_1:
		  call switch_to_pm32
%%j_32_2:
		  %if %%j_32_2 - %%j_32_1 != 3
		    %error "pm_enter %1: not in 16 bit mode"
		  %endif

		  bits 32
		%else
		  %error "invalid argument"
		%endif
%endmacro


%macro		rm32_call 1
		pm_leave 32
		call %1
		pm_enter 32
%endmacro


%macro		pm32_call 1
		pm_enter 32
		call %1
		pm_leave 32
%endmacro


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Interface functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Initialize something.
;
; eax		memory start
; ebx		free memory start
; ecx		memory end
; dx		boot loader code segment
; si		gfx_sysconfig offset
; edi		file archive start, if any (ends at ebx)
;
; return:
;  CF		error
;
gfx_init:
		push fs
		push es
		push ds

		push cs
		pop ds

		cld

		mov [mem],eax
		mov [mem_free],ebx
		mov [mem_max],ecx
		mov [mem_archive],edi
		mov [boot_cs],dx
		mov [boot_sysconfig],si

		mov es,dx
		mov ax,[es:si+9]
		or ax,ax
		jz gfx_init_20
		mov [boot_callback+2],dx
		mov [boot_callback],ax
gfx_init_20:

		mov eax,cr0
		shr al,1		; in prot mode (maybe vm86)?
		jc gfx_init_90

		; setup gdt, to get pm-switching going
		call gdt_init

		; xen currently can't handle real mode 4GB selectors on
		; Intel VMX, so we do a quick check here whether it really
		; works

		xor eax,eax
		lin2seg eax,es,eax
		mov ax,es
		call lin_seg_off
		cmp ax,1		; xen will have returned 0 to match the base address
		jc gfx_init_90

		; init malloc memory chain

		push dword [mem_free]
		pop dword [malloc.area]
		push dword [mem_max]
		pop dword [malloc.area + 4]

		mov es,[boot_cs]
		mov bx,[boot_sysconfig]
		mov si,malloc.area + 8
		cmp byte [es:bx],1		; syslinux
		jnz gfx_init_30
		mov cx,2			; 2 extended mem areas
gfx_init_24:
		mov ax,[es:bx+24]		; extended mem area pointer
		or ax,ax
		jz gfx_init_26
		movzx edx,ax
		and dl,~0fh
		shl edx,16
		mov [si],edx
		and eax,0fh
		shl eax,20
		add eax,edx
		mov [si+4],eax
		add si,8
		add bx,2
		dec cx
		jnz gfx_init_24
gfx_init_26:
		jmp gfx_init_40

gfx_init_30:
		; 2MB - 3MB (to avoid A20 tricks)
		mov eax,200000h
		mov [si],eax
		add eax,100000h		; 1MB
		mov [si+4],eax
gfx_init_40:

		; we can run in protected mode but can't handle ints until
		; after pm_init
		cli

		pm_enter 32

		call malloc_init

		; setup full pm interface
		; can't do it earlier - we need malloc
		call pm_init

		pm_leave 32

		sti

		; now we really start...

		pm_enter 32

%if debug
		mov si,hello
		rm32_call printf
%endif

		; get initial keyboard state
		push word [es:417h]
		pop word [kbd_status]

%if debug
		mov eax,[mem]
		pf_arg_uint 0,eax
		mov eax,[mem_max]
		pf_arg_uint 1,eax

		mov si,dmsg_01
		rm32_call printf

		xor ebx,ebx

.malloc_deb:
		pf_arg_uchar 0,bl
		mov eax,[malloc.area + 8*ebx]
		pf_arg_uint 1,eax
		mov eax,[malloc.area + 8*ebx + 4]
		pf_arg_uint 2,eax

		push ebx
		mov si,dmsg_02
		rm32_call printf
		pop ebx

		inc ebx
		cmp ebx,malloc.areas
		jb .malloc_deb
%endif

		call dict_init
		jc pm_gfx_init_90

		call stack_init
		jc pm_gfx_init_90

		mov eax,[mem]
		mov esi,eax
		add eax,[es:esi+fh_code]
		mov [pscode_start],eax
		mov eax,[es:esi+fh_code_size]
		mov [pscode_size],eax

		; now the ps interpreter is ready to run

		; allocate 8k local stack
		mov eax,8 << 10
		mov [stack_size],eax
		add eax,3
		call calloc
		cmp eax,1
		jc pm_gfx_init_90
		; dword align
		add eax,3
		and eax,~3

		push eax
		xor eax,eax
		call pm_lin2so
		pop ax
		add eax,[stack_size]
		mov [local_stack.ofs],eax
		pop word [local_stack.seg]

		; jpg decoding buffer
		call jpg_setup

		; alloc memory for palette data
		call pal_init

		mov eax,100h
		call calloc
		cmp eax,1
		jc pm_gfx_init_90
		mov [infobox_buffer],eax

		mov eax,200h
		call calloc
		cmp eax,1
		jc pm_gfx_init_90
		mov [vbe_buffer.lin],eax
		push eax
		call pm_lin2so
		pop dword [vbe_buffer.ofs]

		mov eax,100h
		call calloc
		cmp eax,1
		jc pm_gfx_init_90
		mov [vbe_info_buffer],eax

		mov eax,200h
		call calloc
		cmp eax,1
		jc pm_gfx_init_90
		mov [vbe_mode_list.lin],eax
		push eax
		call pm_lin2so
		pop dword [vbe_mode_list.ofs]

		; fill list
		call get_vbe_modes

		; get console font
		call cfont_init

		; ok, we've done it, now continue the setup

%if 0
		rm32_call dump_malloc
		rm32_call get_key
%endif

		pm_leave 32

		; run global code
		xor eax,eax
		mov [pstack_ptr],ax
		mov [rstack_ptr],ax
		call use_local_stack
		call run_pscode
		call use_old_stack
		jc gfx_init_60

		; check for true/false on stack
		; (empty stack == true)

		xor cx,cx
		call get_pstack_tos
		jc gfx_init_80
		cmp dl,t_bool
		jnz gfx_init_70
		cmp eax,byte 1
		jz gfx_init_90
		jmp gfx_init_70

gfx_init_60:
		call ps_status_info
		call get_key
gfx_init_70:
		push cs
		call gfx_done
		stc
		jmp gfx_init_90

		bits 32

pm_gfx_init_90:
		pm_leave 32
		jmp gfx_init_90

gfx_init_80:
		clc

gfx_init_90:
		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Do something.
gfx_done:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		call sound_done

		cmp byte [keep_mode],0
		jnz gfx_done_50
		mov ax,3
		int 10h
gfx_done_50:

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; [boot_cs]:di	buffer	( 0 --> no buffer )
; cx		buffer size
; ax		timeout value (0 --> no timeout)
; return:
;  eax		action (1, 2: textmode, boot)
;  ebx		selected menu entry (-1: none)
;
gfx_input:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		push di
		push cx

		cmp byte [input_notimeout],0
		jnz gfx_input_10
		movzx eax,ax
		mov [input_timeout],eax
		mov [input_timeout_start],eax
gfx_input_10:

		call clear_kbd_queue

gfx_input_20:
		call get_key_to
		and dword [input_timeout],byte 0	; disable timeout

		push eax
		mov cx,cb_KeyEvent
		call get_dict_entry
		pop ecx
		jc gfx_input_90

		cmp dl,t_code
		stc
		jnz gfx_input_90

		push eax
		xchg eax,ecx
		mov word [pstack_ptr],1
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos
		mov word [rstack_ptr],1
		xor cx,cx
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
		mov cx,2
		call get_pstack_tos
		jc gfx_input_90
		cmp dl,t_string
		stc
		jnz gfx_input_90

		pop cx
		pop di
		push di
		push cx

		or di,di
		jz gfx_input_70
		or cx,cx
		jz gfx_input_70

		lin2segofs eax,fs,si
		mov es,[boot_cs]
gfx_input_60:
		fs lodsb
		stosb
		or al,al
		loopnz gfx_input_60
		mov byte [es:di-1],0

gfx_input_70:
		mov cx,1
		call get_pstack_tos
		jc gfx_input_90
		cmp dl,t_int
		stc
		jnz gfx_input_90

		xor cx,cx
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

		pop cx
		pop di

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; es:si	menu description
;
gfx_menu_init:
		push fs
		push es
		push ds

		push cs
		pop ds

		call use_local_stack

		push es
		pop fs

		cld

gfx_menu_init_20:
		push si
		movzx eax,word [fs:si+menu_entries]
		push ax
		imul ax,ax,5
		add ax,2
		push eax
		pm32_call calloc
		mov [tmp_var_2],eax
		pop eax
		pm32_call calloc
		mov [tmp_var_1],eax
		pop cx
		pop si
		or eax,[tmp_var_2]
		jz gfx_menu_init_90

		push cx

		lin2segofs dword [tmp_var_1],es,bx
		mov [es:bx],cx
		add bx,2
		push dword [fs:si+menu_ent_list]
		call so2lin
		pop edi
gfx_menu_init_40:
		mov byte [es:bx],t_string
		mov [es:bx+1],edi
		add bx,5
		movzx eax,word [fs:si+menu_ent_size]
		add edi,eax
		loop gfx_menu_init_40

		pop cx

		lin2segofs dword [tmp_var_2],es,bx
		mov [es:bx],cx
		add bx,2
		push dword [fs:si+menu_arg_list]
		call so2lin
		pop edi
gfx_menu_init_50:
		mov byte [es:bx],t_string
		mov [es:bx+1],edi
		add bx,5
		movzx eax,word [fs:si+menu_arg_size]
		add edi,eax
		loop gfx_menu_init_50

		push dword [fs:si+menu_default]
		call so2lin
		pop dword [tmp_var_3]

		mov cx,cb_MenuInit
		call get_dict_entry
		jc gfx_menu_init_90

		cmp dl,t_code
		stc
		jnz gfx_menu_init_90

		push eax

		mov word [pstack_ptr],3

		mov eax,[tmp_var_1]
		mov dl,t_array
		mov cx,2
		call set_pstack_tos

		mov eax,[tmp_var_2]
		mov dl,t_array
		mov cx,1
		call set_pstack_tos

		mov eax,[tmp_var_3]
		mov dl,t_string
		xor cx,cx
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; [boot_cs]:si	info text 1
; [boot_cs]:di	info text 2	(may be 0 --> no text 2)
; al		0/1	info/error
;
gfx_infobox_init:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		push ax

		mov cx,100h-1
		mov fs,[boot_cs]

		lin2segofs dword [infobox_buffer],es,bp
		or si,si
		jnz gfx_infobox_init_20
		inc bp
		jmp gfx_infobox_init_40
gfx_infobox_init_20:
		fs lodsb
		mov [es:bp],al
		inc bp
		or al,al
		loopnz gfx_infobox_init_20
		or cx,cx
		jz gfx_infobox_init_40
		mov si,di
		or si,si
		jz gfx_infobox_init_40
		inc cx
		dec bp
gfx_infobox_init_25:
		fs lodsb
		mov [es:bp],al
		inc bp
		or al,al
		loopnz gfx_infobox_init_25
gfx_infobox_init_40:
		mov byte [es:bp-1],0

		mov cx,cb_InfoBoxInit
		call get_dict_entry

		pop bx

		jc gfx_infobox_init_90

		cmp dl,t_code
		stc
		jnz gfx_infobox_init_90

		push eax

		mov word [pstack_ptr],2

		movzx eax,bl
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos

		mov eax,[infobox_buffer]
		mov dl,t_string
		mov cx,1
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
gfx_infobox_done:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		mov cx,cb_InfoBoxDone
		call get_dict_entry
		jc gfx_infobox_done_90

		cmp dl,t_code
		stc
		jnz gfx_infobox_done_90

		push eax
		mov word [pstack_ptr],0
		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; eax		max
; [boot_cs]:si	kernel name
;
gfx_progress_init:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		mov [progress_max],eax
		and dword [progress_current],byte 0

		mov cx,cb_ProgressInit
		push si
		call get_dict_entry
		pop si
		jc gfx_progress_init_90

		cmp dl,t_code
		stc
		jnz gfx_progress_init_90

		push eax
		mov word [pstack_ptr],1

		segofs2lin word [boot_cs],si,eax
		mov dl,t_string
		xor cx,cx
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
gfx_progress_done:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		mov cx,cb_ProgressDone
		call get_dict_entry
		jc gfx_progress_done_90

		cmp dl,t_code
		stc
		jnz gfx_progress_done_90

		push eax
		mov word [pstack_ptr],0
		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
gfx_progress_update:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		add [progress_current],eax

		mov cx,cb_ProgressUpdate
		call get_dict_entry
		jc gfx_progress_update_90

		cmp dl,t_code
		stc
		jnz gfx_progress_update_90

		push eax
		mov word [pstack_ptr],2

		mov eax,[progress_current]
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos

		mov eax,[progress_max]
		mov dl,t_int
		mov cx,1
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
gfx_progress_limit:
		push ds

		push cs
		pop ds

		mov [progress_max],eax
		mov [progress_current],edx

		pop ds
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  [boot_cs]:si	password
;  [boot_cs]:di	image name
;
gfx_password_init:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		mov cx,cb_PasswordInit
		push si
		push di
		call get_dict_entry
		pop di
		pop si
		jc gfx_password_init_90

		cmp dl,t_code
		stc
		jnz gfx_password_init_90

		push eax

		mov word [pstack_ptr],2

		segofs2lin word [boot_cs],si,eax
		mov dl,t_string
		xor cx,cx
		push di
		call set_pstack_tos
		pop di

		segofs2lin word [boot_cs],di,eax
		mov dl,t_string
		mov cx,1
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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

		call use_old_stack

		pop ds
		pop es
		pop fs
		retf


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  [boot_cs]:si	password
;
gfx_password_done:
		push fs
		push es
		push ds

		push cs
		pop ds
		cld

		call use_local_stack

		mov cx,cb_PasswordDone
		push si
		call get_dict_entry
		pop si
		jc gfx_password_done_90

		cmp dl,t_code
		stc
		jnz gfx_password_done_90

		push eax

		mov word [pstack_ptr],1

		segofs2lin word [boot_cs],si,eax
		mov dl,t_string
		xor cx,cx
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
		mov dl,t_code
		stc
		sbb eax,eax
		call set_rstack_tos

		pop eax
		call run_pscode
		jc gfx_password_done_80

		xor cx,cx
		call get_pstack_tos
		jc gfx_password_done_90
		cmp dl,t_bool
		stc
		jnz gfx_password_done_90

		cmp eax,byte 1
		jmp gfx_password_done_90

gfx_password_done_80:
		call ps_status_info
		call get_key
		stc

gfx_password_done_90:

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
		cmp dword [boot_callback],0
		jz gfx_cb_80
		pm_leave 32
		push ds
		call far [boot_callback]
		pop ds
		pm_enter 32
		jmp gfx_cb_90
gfx_cb_80:
		mov al,0ffh
gfx_cb_90:
		ret

		bits 16


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Internal functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 16

timeout:
		mov cx,cb_Timeout
		call get_dict_entry
		jc timeout_90

		cmp dl,t_code
		stc
		jnz timeout_90

		push eax
		mov word [pstack_ptr],2

		mov cx,1
		mov dl,t_int
		mov eax,[input_timeout_start]
		call set_pstack_tos

		xor cx,cx
		mov dl,t_int
		mov eax,[input_timeout]
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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
;
; eax		time
;

		bits 16

timer:
		mov cx,cb_Timer
		push eax
		call get_dict_entry
		pop ebx
		jc timer_90

		cmp dl,t_code
		stc
		jnz timer_90

		push eax
		mov word [pstack_ptr],1

		xor cx,cx
		mov dl,t_int
		xchg eax,ebx
		call set_pstack_tos

		mov word [rstack_ptr],1
		xor cx,cx
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
		mov dword [pstack_size],param_stack_size
		and dword [pstack_ptr],0
		mov eax,param_stack_size * 5
		call calloc
		cmp eax,1
		jc stack_init_90
		mov [pstack.lin],eax
		push eax
		call pm_lin2so
		pop dword [pstack]

		mov dword [rstack_size],ret_stack_size
		and dword [rstack_ptr],0
		mov eax,ret_stack_size * 5
		call calloc
		cmp eax,1
		jc stack_init_90
		mov [rstack.lin],eax
		push eax
		call pm_lin2so
		pop dword [rstack]
stack_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read a pstack entry.
;
;  cx		index
;
; return:
;  eax		value
;  dl		type
;  cx		index
;  CF		error
;

		bits 16

get_pstack_entry:
		les bx,[pstack]
		xor eax,eax
		mov dl,al
		cmp [pstack_size],cx
		jb get_pstack_entry_90
		mov ax,5
		mul cx
		add bx,ax
		mov dl,[es:bx]
		mov eax,[es:bx+1]
get_pstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write a pstack entry.
;
;  cx		index
;  eax		value
;  dl		type
;
; return:
;  cx		index
;  CF		error
;

		bits 16

set_pstack_entry:
		les bx,[pstack]
		cmp [pstack_size],cx
		jb set_pstack_entry_90
		push eax
		push dx
		mov ax,5
		mul cx
		add bx,ax
		pop dx
		mov [es:bx],dl
		pop dword [es:bx+1]
set_pstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read pstack tos (no pop).
;
;  cx           index (rel. to tos, 0 = tos)
;
; return:
;  eax		value
;  dl		type
;  cx		index (absolute)
;  CF		error
;

		bits 16

get_pstack_tos:
		mov ax,[pstack_ptr]
		sub ax,1
		jc get_pstack_tos_90
		sub ax,cx
		jc get_pstack_tos_90
		xchg ax,cx
		call get_pstack_entry
get_pstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write pstack tos (no push).
;
;  cx           index (rel. to tos, 0 = tos)
;  eax		value
;  dl		type
;
; return:
;  cx		index (absolute)
;  CF		error
;

		bits 16

set_pstack_tos:
		mov bx,[pstack_ptr]
		sub bx,1
		jc set_pstack_tos_90
		sub bx,cx
		jc set_pstack_tos_90
		xchg bx,cx
		call set_pstack_entry
set_pstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Rotate pstack up (cx-1'th element becomes tos).
;
;  cx		values to rotate (counted from tos)
;
; return:
;  CF		error
;

		bits 16

rot_pstack_up:
		or cx,cx
		jz rot_pstack_up_90
		les di,[pstack]
		mov ax,[pstack_ptr]
		sub ax,cx
		jb rot_pstack_up_90
		cmp cx,byte 1
		jz rot_pstack_up_90
		add di,ax
		shl ax,2
		add di,ax
		dec cx
		mov ax,cx
		shl ax,2
		add cx,ax
		mov ebx,[es:di]
		mov dl,[es:di+4]
		lea si,[di+5]
		es rep movsb
		mov [es:di],ebx
		mov [es:di+4],dl
		clc
rot_pstack_up_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Rotate pstack down (1st element becomes tos).
;
;  cx		values to rotate (counted from tos)
;
; return:
;  CF		error
;

		bits 16

rot_pstack_down:
		or cx,cx
		jz rot_pstack_down_90
		les di,[pstack]
		mov ax,[pstack_ptr]
		cmp ax,cx
		jb rot_pstack_down_90
		cmp cx,byte 1
		jz rot_pstack_down_90
		add di,ax
		shl ax,2
		add di,ax
		dec di
		lea si,[di-5]
		dec cx
		mov ax,cx
		shl ax,2
		add cx,ax
		mov ebx,[es:si+1]
		mov dl,[es:si+5]
		std
		es rep movsb
		cld
		mov [es:si+1],ebx
		mov [es:si+5],dl
		clc
rot_pstack_down_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read a rstack entry.
;
;  cx		index
;
; return:
;  eax		value
;  dl		type
;  cx		index
;  CF		error
;

		bits 16

get_rstack_entry:
		les bx,[rstack]
		xor eax,eax
		mov dl,al
		cmp [rstack_size],cx
		jb get_rstack_entry_90
		mov ax,5
		mul cx
		add bx,ax
		mov dl,[es:bx]
		mov eax,[es:bx+1]
get_rstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write a rstack entry.
;
;  cx		index
;  eax		value
;  dl		type
;
; return:
;  cx		index
;  CF		error
;

		bits 16

set_rstack_entry:
		les bx,[rstack]
		cmp [rstack_size],cx
		jb set_rstack_entry_90
		push eax
		push dx
		mov ax,5
		mul cx
		add bx,ax
		pop dx
		mov [es:bx],dl
		pop dword [es:bx+1]
set_rstack_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read rstack tos (no pop).
;
;  cx           index (rel. to tos, 0 = tos)
;
; return:
;  eax		value
;  dl		type
;  cx		index (absolute)
;  CF		error
;

		bits 16

get_rstack_tos:
		mov ax,[rstack_ptr]
		sub ax,1
		jc get_rstack_tos_90
		sub ax,cx
		jc get_rstack_tos_90
		xchg ax,cx
		call get_rstack_entry
get_rstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write rstack tos (no push).
;
;  cx           index (rel. to tos, 0 = tos)
;  eax		value
;  dl		type
;
; return:
;  cx		index (absolute)
;  CF		error
;

		bits 16

set_rstack_tos:
		mov bx,[rstack_ptr]
		sub bx,1
		jc set_rstack_tos_90
		sub bx,cx
		jc set_rstack_tos_90
		xchg bx,cx
		call set_rstack_entry
set_rstack_tos_90:
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

pm_get_pstack_entry:
		xor eax,eax
		mov dl,al
		cmp [pstack_size],ecx
		jb pm_get_pstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[pstack.lin]
		mov dl,[es:ebx]
		mov eax,[es:ebx+1]
		clc
pm_get_pstack_entry_90:
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

pm_set_pstack_entry:
		cmp [pstack_size],ecx
		jb pm_set_pstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[pstack.lin]
		mov [es:ebx],dl
		mov [es:ebx+1],eax
		clc
pm_set_pstack_entry_90:
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

pm_get_pstack_tos:
		mov eax,[pstack_ptr]
		sub eax,1
		jc pm_get_pstack_tos_90
		sub eax,ecx
		jc pm_get_pstack_tos_90
		xchg eax,ecx
		call pm_get_pstack_entry
pm_get_pstack_tos_90:
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

pm_set_pstack_tos:
		mov ebx,[pstack_ptr]
		sub ebx,1
		jc pm_set_pstack_tos_90
		sub ebx,ecx
		jc pm_set_pstack_tos_90
		xchg ebx,ecx
		call pm_set_pstack_entry
pm_set_pstack_tos_90:
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

pm_get_rstack_entry:
		xor eax,eax
		mov dl,al
		cmp [rstack_size],ecx
		jb pm_get_rstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[rstack.lin]
		mov dl,[es:ebx]
		mov eax,[es:ebx+1]
		clc
pm_get_rstack_entry_90:
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

pm_set_rstack_entry:
		cmp [rstack_size],ecx
		jb pm_set_rstack_entry_90
		lea ebx,[ecx+ecx*4]
		add ebx,[rstack.lin]
		mov [es:ebx],dl
		mov [es:ebx+1],eax
		clc
pm_set_rstack_entry_90:
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

pm_get_rstack_tos:
		mov eax,[rstack_ptr]
		sub eax,1
		jc pm_get_rstack_tos_90
		sub eax,ecx
		jc pm_get_rstack_tos_90
		xchg eax,ecx
		call pm_get_rstack_entry
pm_get_rstack_tos_90:
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

pm_set_rstack_tos:
		mov ebx,[rstack_ptr]
		sub ebx,1
		jc pm_set_rstack_tos_90
		sub ebx,ecx
		jc pm_set_rstack_tos_90
		xchg ebx,ecx
		call pm_set_rstack_entry
pm_set_rstack_tos_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Setup initial dictionary.
;
; return:
;  CF		error
;

		bits 32

dict_init:
		mov eax,[mem]

		mov ecx,[es:eax+fh_dict]
		cmp ecx,1
		jc dict_init_90
		add eax,ecx

		mov esi,eax

		xor eax,eax
		es lodsw
		mov [dict_size],ax

		; p_none is not part of the default dict
		cmp ax,cb_functions + prim_functions - 1
		jb dict_init_90

		lea eax,[eax+eax*4]

		push esi
		call calloc
		pop esi
		cmp eax,1
		jc dict_init_90

		mov [dict.lin],eax
		mov ebx,eax
		push eax
		call pm_lin2so
		pop dword [dict]

		; add default functions

		add ebx,cb_functions * 5
		xor ecx,ecx
		inc ecx
dict_init_20:
		mov byte [es:ebx],t_prim
		mov [es:ebx+1],ecx
		add ebx,5
		inc ecx
		cmp ecx,prim_functions
		jb dict_init_20

		; add user defined things

		xor eax,eax
		es lodsw
		or eax,eax
		jz dict_init_80
		cmp [dict_size],eax
		jb dict_init_90

		mov ebx,[dict.lin]

		xchg eax,ecx
dict_init_50:
		xor eax,eax
		es lodsw
		cmp eax,[dict_size]
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

%if debug

		bits 16

dump_dict:
		mov si,dmsg_09
		call printf

		xor cx,cx
dump_dict_20:
		call get_dict_entry
		jc dump_dict_90
		pf_arg_ushort 0,cx
		pf_arg_uchar 1,dl
		pf_arg_uint 2,eax
		mov si,dmsg_10
		pusha
		call printf
		popa

		inc cx
		cmp cx,[dict_size]
		jb dump_dict_20
dump_dict_90:
		ret

%endif


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read a dictionary entry.
;
;  cx		index
;
; return:
;  eax		value
;  dl		type
;  cx		index
;  CF		error
;

		bits 16

get_dict_entry:
		les bx,[dict]
		xor eax,eax
		mov dl,al
		cmp [dict_size],cx
		jb get_dict_entry_90
		mov ax,5
		mul cx
		add bx,ax
		mov dl,[es:bx]
		mov eax,[es:bx+1]
get_dict_entry_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write a dictionary entry.
;
;  cx		index
;  eax		value
;  dl		type
;
; return:
;  cx		index
;  CF		error
;

		bits 16

set_dict_entry:
		les bx,[dict]
		cmp [dict_size],cx
		jb set_dict_entry_90
		push eax
		push dx
		mov ax,5
		mul cx
		add bx,ax
		pop dx
		mov [es:bx],dl
		pop dword [es:bx+1]
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
;
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
;
; Get some memory (taken from extended memory, if possible).
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if the request failed)
;

		bits 32

xmalloc:
		mov bx,8		; start with mem area 1

		push eax
		call malloc_10
		pop edx

		or eax,eax
		jnz xmalloc_90

		mov eax,edx
		jmp malloc
xmalloc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
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
;
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

		bits 16

%if debug
; dump memory chain
dump_malloc:
		pushad

		xor dx,dx
		call con_xy

		xor bx,bx
		xor bp,bp

dump_malloc_10:
		mov ecx,[malloc.area + bx]
		mov edx,[malloc.area + 4 + bx]

		mov [malloc.start],ecx
		mov [malloc.end],edx

		cmp ecx,edx
		jz dump_malloc_70

		push bx
		call _dump_malloc
		pop bx

dump_malloc_70:
		add bx,8
		cmp bx,malloc.areas * 8
		jb dump_malloc_10
dump_malloc_90:

		call lin_seg_off

		popad
		ret

_dump_malloc:
		mov ebx,[malloc.start]

_dump_malloc_30:
		lin2seg ebx,es,esi
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
		mov si,dmsg_03

		call lin_seg_off

		call printf
		popad

		inc bp
		test bp,01fh
		jnz _dump_malloc_60
		pushad
		call get_key
		xor dx,dx
		call con_xy
		popad
_dump_malloc_60:		

		mov si,dmsg_04
		cmp ecx,mhead.size
		jbe _dump_malloc_70

		add ebx,ecx
		cmp ebx,[malloc.end]
		jz _dump_malloc_90
		jb _dump_malloc_30

		mov ecx,[malloc.end]
		mov si,dmsg_04a

_dump_malloc_70:
		pf_arg_uint 0,ebx
		pf_arg_uint 1,ecx
_dump_malloc_80:

		call lin_seg_off

		push bp
		call printf
		pop bp
_dump_malloc_90:
		ret
%endif


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
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
		mov ebx,[mem_archive]
		or ebx,ebx
		stc
		jz fms_file_90
		cmp eax,ebx
		jc fms_file_90
		cmp eax,[mem_free]
		cmc
		jc fms_file_90

fms_file_10:
		mov ecx,[mem_free]
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
;
; Load segment with 4GB selector.
;
;  byte [pm_seg_mask]	segment bit mask (bit 1-3: es, fs, gs)
;
; return:
;  seg			4GB segment selector
;  IF			0 (interrupts off)
;
; Note: MUST NOT be run in protected mode!!!
;

		bits 16

lin_seg:
		cli

		push eax

		mov al,[pm_seg_mask]
		test [pm_large_seg],al
		jnz lin_seg_80

		mov eax,cr0
		or al,1
		o32 lgdt [pm_gdt]
		mov cr0,eax

		test byte [pm_seg_mask],(1 << 1)
		jz lin_seg_30
		push word pm_seg
		pop es
		jmp lin_seg_50
lin_seg_30:
		test byte [pm_seg_mask],(1 << 2)
		jz lin_seg_40
		push word pm_seg
		pop fs
		jmp lin_seg_50
lin_seg_40:
		test byte [pm_seg_mask],(1 << 3)
		jz lin_seg_50
		push word pm_seg
		pop gs
lin_seg_50:

		and al,~1
		mov cr0,eax

		mov al,[pm_seg_mask]
		or byte [pm_large_seg],al

lin_seg_80:
		pop eax

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;

		bits 16

lin_seg_off:
		mov byte [pm_large_seg],0
		sti
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
		mov ebp,[mem_archive]
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
		cmp ecx,[mem_free]
		jb find_file_20
find_file_80:
		xor eax,eax
		mov bl,al
find_file_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Set graphics mode.
;
;  [gfx_mode]	graphics mode (either vbe or normal mode number)
;  [vbe_buffer]	buffer for vbe info
;
; return:
;  CF		error
;

		bits 16

set_mode:
		push es
		mov ax,[gfx_mode]
		test ah,ah
		jnz set_mode_20
		int 10h
		mov word [window_seg_w],0a000h
		and word [window_seg_r],byte 0
		mov byte [mapped_window],0

		mov al,[gfx_mode]
		cmp al,13h
		jnz set_mode_102
		; 320x200, 8 bit
		mov word [screen_width],320
		mov word [screen_height],200
		mov word [screen_vheight],200
		mov word [screen_line_len],320
		mov byte [pixel_bits],8
		mov byte [pixel_bytes],1
		call mode_init
		call pm_mode_init
set_mode_102:
		clc
		jmp set_mode_90
set_mode_20:
		les di,[vbe_buffer]
		mov ax,4f00h
		and dword [es:di],byte 0
		push di			; you never know...
		int 10h
		pop di
		cmp ax,4fh
		jnz set_mode_80
		mov ax,4f01h
		mov cx,[gfx_mode]
		push di
		int 10h
		pop di
		cmp ax,4fh
		jnz set_mode_80

		push word [es:di+10h]
		pop word [screen_line_len]

		push word [es:di+12h]
		pop word [screen_width]
		push word [es:di+14h]
		pop word [screen_height]

		movzx eax,byte [es:di+1dh]
		inc ax
		movzx ecx,word [screen_height]
		mul ecx
		cmp eax,7fffh
		jbe set_mode_25
		mov ax,7fffh
set_mode_25:
		mov [screen_vheight],ax

		mov al,[es:di+1bh]		; color mode (aka memory model)
		mov ah,[es:di+19h]		; color depth
		mov dh,ah
		cmp al,6			; direct color
		jnz set_mode_30
		mov dh,[es:di+1fh]		; red
		add dh,[es:di+21h]		; green
		add dh,[es:di+23h]		; blue
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

		mov ax,[es:di+8]		; win seg A
		mov bx,[es:di+10]		; win seg B

		or ax,ax
		jz set_mode_80
		mov [window_seg_w],ax
		and word [window_seg_r],byte 0
		mov dx,[es:di+2]		; win A/B attributes
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
		mov ax,[es:di+6]	; win size (in kb)
		cmp ax,64
		jb set_mode_80		; at least 64k
		xor dx,dx
		mov bx,[es:di+4]	; granularity (in kb)
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
		call pm_mode_init

		clc

		jmp set_mode_90
set_mode_80:
		and word [gfx_mode],byte 0
		stc
set_mode_90
		pop es
		ret


mode_init:
		mov word [setpixel],setpixel_8
		mov word [setpixel_a],setpixel_a_8
		mov word [setpixel_t],setpixel_8
		mov word [setpixel_ta],setpixel_a_8
		mov word [getpixel],getpixel_8
		cmp byte [pixel_bits],8
		jz mode_init_90
		cmp  byte [pixel_bits],16
		jnz mode_init_10
		mov word [setpixel],setpixel_16
		mov word [setpixel_a],setpixel_a_16
		mov word [setpixel_t],setpixel_t_16
		mov word [setpixel_ta],setpixel_ta_16
		mov word [getpixel],getpixel_16
		jmp mode_init_90
mode_init_10:
		cmp byte [pixel_bits],32
		jnz mode_init_90
		mov word [setpixel],setpixel_32
		mov word [setpixel_a],setpixel_a_32
		mov word [setpixel_t],setpixel_t_32
		mov word [setpixel_ta],setpixel_ta_32
		mov word [getpixel],getpixel_32
mode_init_90:
		ret


pm_mode_init:
		; graphics window selectors

		movzx eax,word [window_seg_w]
		shl eax,4
		mov si,pm_seg.screen_w16
		call set_gdt_base

		movzx ecx,word [window_seg_r]
		shl ecx,4
		jz pm_mode_init_05
		mov eax,ecx
pm_mode_init_05:
		mov si,pm_seg.screen_r16
		call set_gdt_base

		; pixel get/set functions

		mov dword [pm_setpixel],pm_setpixel_8
		mov dword [pm_setpixel_a],pm_setpixel_a_8
		mov dword [pm_setpixel_t],pm_setpixel_8
		mov dword [pm_setpixel_ta],pm_setpixel_a_8
		mov dword [pm_getpixel],pm_getpixel_8
		cmp byte [pixel_bits],8
		jz pm_mode_init_90
		cmp  byte [pixel_bits],16
		jnz pm_mode_init_50
		mov dword [pm_setpixel],pm_setpixel_16
		mov dword [pm_setpixel_a],pm_setpixel_a_16
		mov dword [pm_setpixel_t],pm_setpixel_t_16
		mov dword [pm_setpixel_ta],pm_setpixel_ta_16
		mov dword [pm_getpixel],pm_getpixel_16
		jmp mode_init_90
pm_mode_init_50:
		cmp byte [pixel_bits],32
		jnz pm_mode_init_90
		mov dword [pm_setpixel],pm_setpixel_32
		mov dword [pm_setpixel_a],pm_setpixel_a_32
		mov dword [pm_setpixel_t],pm_setpixel_t_32
		mov dword [pm_setpixel_ta],pm_setpixel_ta_32
		mov dword [pm_getpixel],pm_getpixel_32
pm_mode_init_90:
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
		mov ebx,[vbe_mode_list.lin]
		cmp word [es:ebx],0
		jnz get_vbe_modes_90

		mov edx,[vbe_buffer.lin]
		and dword [es:edx],0
		
		mov di,[vbe_buffer.ofs]
		push word [vbe_buffer.seg]
		pop word [rm_seg.es]
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
;
; Convert 32bit linear address to seg:ofs.
;
;  dword [esp + 2]:	linear address
;
; return:
;  dword [esp + 2]:	seg:ofs
;
; Notes:
;  - changes no regs
;

		bits 16

lin2so:
		push eax
		mov eax,[esp + 6]
		shr eax,4
		mov [esp + 8],ax
		and word [esp + 6],byte 0fh
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Convert 32bit linear address to seg:ofs.
;
;  dword [esp + 2]:	linear address
;
; return:
;  dword [esp + 2]:	seg:ofs
;
; Notes:
;  - changes no regs
;

		bits 32

pm_lin2so:
		push eax
		mov eax,[esp + 8]
		shr eax,4
		mov [esp + 10],ax
		and word [esp + 8],byte 0fh
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Convert seg:ofs to 32bit linear address.
;
;  dword [esp + 2]:	seg:ofs
;
; return:
;  dword [esp + 2]:	linear address
;
; Notes:
;  - changes no regs
;

		bits 16

so2lin:
		push eax
		movzx eax,word [esp + 8]
		and word [esp + 8],byte 0
		shl eax,4
		add [esp + 6],eax
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Convert 32bit linear address to seg:32_bit_ofs.
;
;  dword [esp + 2]:	linear address
;  byte [pm_seg_mask]:	segment bit mask (bit 1-3: es, fs, gs)
;
; return:
;  seg:			segment (as determined by [pm_seg_mask])
;  dword [esp + 2]:	ofs
;
; Notes:
;  - changes no regs
;  - clears IF
;

		bits 16

_lin2seg:
		push eax
		mov eax,[esp + 6]
		call lin_seg
		pop eax
		ret


_lin2es:
		mov byte [pm_seg_mask],(1 << 1)
		jmp _lin2seg

_lin2fs:
		mov byte [pm_seg_mask],(1 << 2)
		jmp _lin2seg

_lin2gs:
		mov byte [pm_seg_mask],(1 << 3)
		jmp _lin2seg

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write text to console.
;
; si		text (ACSIIZ)
;

		bits 16

printf:
		mov byte [tmp_write_cnt],0
printf_10:
		call pf_next_char
		or al,al
		jz printf_90
		cmp al,'%'
		jnz printf_70
		mov byte [tmp_write_pad],' '
		call pf_next_char
		dec si
		cmp al,'0'
		jnz printf_20
		mov [tmp_write_pad],al
printf_20:
		call get_number
		mov [tmp_write_num],cx
		call pf_next_char
		or al,al
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
		push si

		call pf_next_arg
		cmp byte [pf_gfx],0
		jz printf_25
		push es
		lin2segofs eax,es,si
		call write_str
		pop es
		jmp printf_27
printf_25:
		xchg ax,si
		call write_str
printf_27:
		sub cx,[tmp_write_num]
		neg cx
		mov al,' '
		call write_chars
		pop si
		mov byte [pf_gfx_raw_char],0
		jmp printf_10

printf_30:		
		cmp al,'u'
		jnz printf_35

		mov dx,10
printf_31:
		push si
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
		push es
		push ds
		pop es
		call write_str
		pop es
		jmp printf_347
printf_345:
		call write_str
printf_347:
		pop si
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

		push si
		call pf_next_arg
		call write_char
		pop si
		jmp printf_10
printf_45:

		; more ...
		

printf_70:
		call write_char
		jmp printf_10
printf_90:		
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; get next char for printf
;
; either from ds:si or es:si
;

		bits 16

pf_next_char:
		xor eax,eax
		cmp byte [pf_gfx],0
		jz pf_next_char_50
		es		; ok, this _is_ evil code...
pf_next_char_50:
		lodsb
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; return next printf arg
;
; return:
;  eax		arg
;
; changes no regs
;

		bits 16

pf_next_arg:
		cmp byte [pf_gfx],0
		jz pf_next_arg_50
		push es
		pushad
		xor cx,cx
		call get_pstack_tos
		mov [tmp_write_data],eax
		jnc pf_next_arg_20
		and dword [tmp_write_data],byte 0
		cmp word [pf_gfx_err],byte 0
		jnz pf_next_arg_20
		mov word [pf_gfx_err],pserr_pstack_underflow
		jmp pf_next_arg_30
pf_next_arg_20:
		dec word [pstack_ptr]
pf_next_arg_30:
		popad
		pop es
		mov eax,[tmp_write_data]
		jmp pf_next_arg_90
pf_next_arg_50:
		push si
		mov al,[tmp_write_cnt]
		cbw
		inc byte [tmp_write_cnt]
		shl ax,2
		mov si,ax
		mov eax,[si+tmp_write_data]
		pop si
pf_next_arg_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  si		text
;
; return:
;  cx		length
;

		bits 16

write_str:
		xor cx,cx
write_str_10:
		call pf_next_char
		cmp byte [pf_gfx],0
		jz write_str_40
		call rm_is_eot
		jmp write_str_50
write_str_40:
		or al,al
write_str_50:
		jz write_str_90
		call write_char
		inc cx
		jmp write_str_10
write_str_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; al		char
; cx		count (must be > 0)
;

		bits 16

write_chars:
		cmp cx,0
		jle write_chars_90
		call write_char
		dec cx
		jmp write_chars
write_chars_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; al		char
;

		bits 16

write_char:
		push es
		pushad
		cmp byte [pf_gfx],0
		jz write_char_50
		mov ebx,[pf_gfx_cnt]
		inc ebx
		cmp ebx,[pf_gfx_max]
		jae write_char_90		; leave room for final 0!
		mov [pf_gfx_cnt],ebx
		add ebx,[pf_gfx_buf]
		dec ebx
		lin2segofs ebx,es,di
		mov ah,0
		mov [es:di],ax
		jmp write_char_90
write_char_50:
		cmp byte [pf_gfx_raw_char],0
		jnz write_char_60
		cmp al,0ah
		jnz write_char_60
		push ax
		mov al,0dh
		call write_cons_char
		pop ax
write_char_60:
		call write_cons_char
write_char_90:
		popad
		pop es
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; al		char
;

		bits 16

write_cons_char:
		push gs
		push fs

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

		pop fs
		pop gs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Convert string to number.
;
;  si		string
;
; return:
;  cx		number
;  si		points past number
;  CF		not a number
;

		bits 16

get_number:

		xor cx,cx
		mov ah,1
get_number_10:
		call pf_next_char
		or al,al
		jz get_number_90
		sub al,'0'
		jb get_number_90
		cmp al,9
		ja get_number_90
		cbw
		imul cx,cx,10
		add cx,ax
		jmp get_number_10
get_number_90:
		dec si
		shr ah,1
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Convert a number to string.
;
;  eax		number
;  cl		field size
;  ch		padding char
;  dl		base
;
; return:
;  si		string
;

		bits 16

number:
		push es

		push ds
		pop es
		mov di,num_buf
		push ax
		push cx
		mov al,ch
		mov cx,num_buf_end - num_buf
		rep stosb
		pop cx
		pop ax
		mov ch,0
		movzx ebx,dl
number_10:
		xor edx,edx
		div ebx
		cmp dl,9
		jbe number_20
		add dl,27h
number_20:
		add dl,'0'
		dec di
		mov [di],dl
		or eax,eax
		jz number_30
		cmp di,num_buf
		ja number_10
number_30:
		mov si,di
		or cx,cx
		jz number_90
		cmp cl,num_buf_end - num_buf
		jae number_90
		mov si,num_buf_end
		sub si,cx
number_90:
		pop es
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		bits 16

ps_status_info:
		xor dx,dx
		call con_xy

		mov si,msg_13
		call printf

		mov cx,7
ps_status_info_10:
		push cx

		call get_pstack_tos
		jc ps_status_info_20
		pf_arg_ushort 0,cx
		pf_arg_uchar 2,dl
		pf_arg_uint 1,eax
		mov si,msg_11
		jmp ps_status_info_30
ps_status_info_20:
		mov si,msg_12
ps_status_info_30:
		call printf

		pop cx
		push cx

		call get_rstack_tos
		jc ps_status_info_40
		pf_arg_ushort 0,cx
		pf_arg_uchar 2,dl
		pf_arg_uint 1,eax
		mov si,msg_11
		jmp ps_status_info_50
ps_status_info_40:
		mov si,msg_12
ps_status_info_50:
		call printf

		mov si,msg_16
		call printf

		pop cx
		dec cx
		jge ps_status_info_10

		mov si,msg_14
		call printf

		mov eax,[pscode_error_arg_0]
		pf_arg_uint 1,eax
		mov eax,[pscode_error_arg_1]
		pf_arg_uint 2,eax
		mov ax,[pscode_error]
		pf_arg_ushort 0,ax
		mov si,msg_17
		cmp ax,100h
		jb ps_status_info_60
		mov si,msg_18
		cmp ax,200h
		jb ps_status_info_60
		mov si,msg_19
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

		mov si,msg_10
		cmp al,t_sec
		jnz ps_status_info_70
		mov si,msg_20
ps_status_info_70:
		call printf

		xor cx,cx
		call get_pstack_tos
		jnc ps_status_info_71
		mov dl,t_none
		xor eax,eax
ps_status_info_71:
		push eax
		push ds
		pop es
		mov al,' '
		mov di,num_buf
		mov cx,1fh		; watch num_buf_end
		rep stosb
		mov [di],cl
		pop eax

		cmp dl,t_string
		jnz ps_status_info_79

		pm_enter 32

		push ds
		pop es

		xchg eax,esi

		mov edi,num_buf
		mov al,0afh
		stosb
ps_status_info_72:
		fs lodsb
		or al,al
		jz ps_status_info_73
		stosb
		cmp byte [es:edi+1],0
		jnz ps_status_info_72
		cmp byte [fs:esi],0
		jnz ps_status_info_74
ps_status_info_73:		
		mov al,0aeh
		jmp ps_status_info_75
ps_status_info_74:
		mov al,0afh
ps_status_info_75:
		stosb

		pm_leave 32

ps_status_info_79:
		mov si,num_buf
		pf_arg_uint 0,esi
		mov si,msg_21
		call printf

ps_status_info_80:
		mov si,msg_15
		call printf

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read a key (blocking).
;
; return:
;  eax		key
;

		bits 16

get_key:
		mov ah,10h
		int 16h
		and eax,0ffffh
		push es
		push word 0
		pop es
		mov ecx,[es:417h-2]
		xor cx,cx
		add eax,ecx
		pop es
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read a key, return 0 if timed out
;
; return:
;  eax		key (or 0)

		bits 16

get_key_to:
		call get_time
		xchg eax,edx
get_key_to_20:
		mov ah,11h
		int 16h
		jnz get_key_to_60
		cmp byte [run_idle],0
		jz get_key_to_25
		call idle
get_key_to_25:
		push es
		push byte 0
		pop es
		mov ax,[es:417h]
		pop es
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
		cmp dword [input_timeout],byte 0
		jz get_key_to_70
		and dword [input_timeout],byte 0
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
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 16

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
;

		bits 16

get_time:
		push cx
		push dx
		xor ax,ax
		int 1ah
		push cx
		push dx
		pop eax
		pop dx
		pop cx
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Convert 8 bit bcd to binary.
;
;  al		bcd
;
; return
;  ax		binary
;

		bits 16

bcd2bin:
		push dx
		mov dl,al
		shr al,4
		and dl,0fh
		mov ah,10
		mul ah
		add al,dl
		pop dx
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 16

get_date:
		clc
		mov ah,4
		int 1ah
		jnc get_date_10
		xor dx,dx
		xor cx,cx
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
;
; Set console cursor position.
;
;  dh		row
;  dl		column
;
; return:
;

		bits 16

con_xy:
		mov bh,0
		mov ah,2
		int 10h
		and dword [con_x],0
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
idle_data	dd 0
idle_data2	dd 0

%include	"kroete.inc"

		bits 16

idle:
		push es
		push fs
		push gs
		pushad

		les si,[idle_data]
		mov bx,[idle_data2]
		call kroete

		popad
		pop gs
		pop fs
		pop es
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Execute ps code.
;
;  eax		start address, relative to 
;
; return:
;  CF		error
;

		bits 16

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
		lin2segofs eax,es,si
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

		mov dl,[es:si]
		cmp cl,1
		jz run_pscode_20

		mov dx,[es:si]
		cmp cl,2
		jz run_pscode_20

		mov edx,[es:si]
		and edx,0ffffffh
		cmp cl,3
		jz run_pscode_20

		mov edx,[es:si]
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
		xchg ax,cx
		call get_dict_entry
		mov bp,pserr_invalid_dict
		jc run_pscode_90

		movzx edx,dl
		mov [pscode_error_arg_0],eax
		mov [pscode_error_arg_1],edx

run_pscode_46:
		pushad
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
		popad

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
		mov cx,[pstack_ptr]
		cmp cx,[pstack_size]
		mov bp,pserr_pstack_overflow
		jae run_pscode_80
		inc word [pstack_ptr]

		xor cx,cx
		call set_pstack_tos
		jc run_pscode_90
		jmp run_pscode_10

run_pscode_52:
		cmp dl,t_prim
		jnz run_pscode_53

		cmp eax,prim_functions
		mov bp,pserr_invalid_prim
		jae run_pscode_80
		xchg ax,si
		add si,si
		mov ax,[si+jt_p_none]
		or ax,ax		; implemented?
		jz run_pscode_80

		call ax
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

		mov cx,[rstack_ptr]
		cmp cx,[rstack_size]
		mov bp,pserr_rstack_overflow
		jae run_pscode_80
		inc word [rstack_ptr]

		xor cx,cx
		call set_rstack_tos
		jc run_pscode_90
		jmp run_pscode_10

run_pscode_54:
		cmp dl,t_ret
		jnz run_pscode_70

		xor cx,cx
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
		cmp word [rstack_ptr],byte 5
		mov bp,pserr_rstack_underflow
		jc run_pscode_90

		mov cx,1
		call get_rstack_tos		; count
		cmp dl,t_int
		jnz run_pscode_66

		mov cx,2
		push eax
		call get_rstack_tos		; length
		pop esi
		cmp dl,t_int
		jnz run_pscode_66

		mov cx,3
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

		push dx
		mov cx,1
		mov dl,t_int
		push eax
		push esi
		mov eax,esi
		call set_rstack_tos
		pop eax
		pop ecx
		pop dx

		xchg dl,dh
		call p_get
		mov bp,pserr_invalid_range
		jc run_pscode_80

		mov cx,[pstack_ptr]
		cmp cx,[pstack_size]
		jae run_pscode_80
		inc word [pstack_ptr]
		xor cx,cx
		call set_pstack_tos
		jc run_pscode_90

		xor cx,cx
		call get_rstack_tos
		jmp run_pscode_69


run_pscode_62:
		; for
		cmp word [rstack_ptr],byte 5
		mov bp,pserr_rstack_underflow
		jc run_pscode_90

		mov cx,2
		call get_rstack_tos		; step
		cmp dl,t_int
		jnz run_pscode_66
		mov cx,1
		push eax
		call get_rstack_tos		; limit
		pop esi
		cmp dl,t_int
		jnz run_pscode_66
		push eax
		mov cx,3
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

		mov cx,3
		push eax
		call set_rstack_tos
		pop eax
		mov cx,[pstack_ptr]
		cmp cx,[pstack_size]
		jae run_pscode_80
		inc word [pstack_ptr]
		xor cx,cx
		mov dl,t_int
		call set_pstack_tos
		jc run_pscode_90
		xor cx,cx
		call get_rstack_tos
		jmp run_pscode_69
run_pscode_64:
		mov cx,4
		call get_rstack_tos
		sub word [rstack_ptr],byte 5
		jmp run_pscode_69


run_pscode_65:
		; repeat
		cmp word [rstack_ptr],byte 3
		mov bp,pserr_rstack_underflow
		jc run_pscode_90
		push eax
		mov cx,1
		call get_rstack_tos
		pop ebx
		cmp dl,t_int
run_pscode_66:
		mov bp,pserr_invalid_rstack_entry
		jnz run_pscode_80
		dec eax
		jz run_pscode_67
		mov cx,1
		push ebx
		call set_rstack_tos
		pop eax
		jmp run_pscode_69
run_pscode_67:
		mov cx,2
		call get_rstack_tos
		sub word [rstack_ptr],byte 2

run_pscode_68:
		dec word [rstack_ptr]
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
;
;  dl		tos type
; return:
;  eax		tos
;  dl		actual tos types (even if CF is set)
;  CF		error
;

		bits 16

get_1arg:
		xor eax,eax
		cmp word [pstack_ptr],byte 1
		mov bp,pserr_pstack_underflow
		jc get_1arg_90
		push dx
		xor cx,cx
		call get_pstack_tos
		pop bx
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

pm_get_1arg:
		xor eax,eax
		cmp dword [pstack_ptr],1
		mov bp,pserr_pstack_underflow
		jc pm_get_1arg_90
		push edx
		xor ecx,ecx
		call pm_get_pstack_tos
		pop ebx
		; ignore type check if t_none was requested
		cmp bl,t_none
		jz pm_get_1arg_90
		cmp bl,dl
		jz pm_get_1arg_90
		mov bp,pserr_wrong_arg_types
		stc
pm_get_1arg_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  dl		tos type
;  dh		tos + 1 type
; return:
;  eax		tos
;  ecx		tos + 1
;  dx		actual tos types (even if CF is set)
;  CF		error
;

		bits 16

get_2args:
		xor eax,eax
		xor ecx,ecx
		mov bx,dx
		xor dx,dx
		cmp word [pstack_ptr],byte 2
		mov bp,pserr_pstack_underflow
		jc get_2args_90
		push bx
		inc cx
		call get_pstack_tos
		push dx
		push eax
		xor cx,cx
		call get_pstack_tos
		pop ecx
		pop bx
		mov dh,bl
		pop bx

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

pm_get_2args:
		xor eax,eax
		xor ecx,ecx
		mov ebx,edx
		xor edx,edx
		cmp dword [pstack_ptr],2
		mov bp,pserr_pstack_underflow
		jc pm_get_2args_90
		push ebx
		inc ecx
		call pm_get_pstack_tos
		push edx
		push eax
		xor ecx,ecx
		call pm_get_pstack_tos
		pop ecx
		pop ebx
		mov dh,bl
		pop ebx

		; ignore type check if t_none was requested
		cmp bh,t_none
		jnz pm_get_2args_50
		mov bh,dh
pm_get_2args_50:
		cmp bl,t_none
		jnz pm_get_2args_60
		mov bl,dl
pm_get_2args_60:
		cmp bx,dx
		jz pm_get_2args_90
		mov bp,pserr_wrong_arg_types
pm_get_2args_80:
		stc
pm_get_2args_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Our primary functions.
;

		bits 16

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
prim_astart:
		mov ax,[pstack_ptr]
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_astart_90
		mov [pstack_ptr],ax
		mov dl,t_prim
		mov eax,(jt_p_astart - jt_p_none) / 2	; we need just some mark
		xor cx,cx
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
prim_aend:
		xor cx,cx
prim_aend_10:
		push cx
		call get_pstack_tos
		pop cx
		mov bp,pserr_pstack_underflow
		jc prim_aend_90
		inc cx
		cmp dl,t_prim
		jnz prim_aend_10
		cmp eax,(jt_p_astart - jt_p_none) / 2
		jnz prim_aend_10

		dec cx
		push cx
		mov ax,5
		mul cx
		inc ax
		inc ax
		movzx eax,ax
		pm32_call calloc
		pop cx
		or eax,eax
		mov bp,pserr_no_memory
		stc
		jz prim_aend_90

		push cx
		push eax

		lin2segofs eax,es,di
		mov [es:di],cx
		inc di
		inc di

prim_aend_40:
		sub cx,1
		jc prim_aend_60

		push es
		push di
		push cx
		call get_pstack_tos
		pop cx
		pop di
		pop es

		mov [es:di],dl
		mov [es:di+1],eax
		add di,5
		jmp prim_aend_40

prim_aend_60:

		pop eax
		pop cx
		sub [pstack_ptr],cx
		mov dl,t_array
		xor cx,cx
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

		dec word [pstack_ptr]
		xor cx,cx
		call set_pstack_tos
prim_get_90:
		ret


;  dh, ecx	obj
;  eax		index
; Return:
;  dl, eax	element
;  CF		0/1 ok/not ok
;
p_get:
		cmp dh,t_array
		jz p_get_50
		cmp dh,t_string
		jz p_get_10
		cmp dh,t_ptr
		stc
		jnz p_get_90
p_get_10:
		add ecx,eax
		lin2segofs ecx,es,di
		mov dl,t_int
		movzx eax,byte [es:di]
		jmp p_get_80
p_get_50:
		lin2segofs ecx,es,di
		mov bp,pserr_invalid_range
		cmp ax,[es:di]
		cmc
		jc p_get_90

		add di,ax
		add ax,ax
		add ax,ax
		add di,ax

		mov dl,[es:di+2]
		mov eax,[es:di+3]
p_get_80:
		clc
p_get_90:
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
prim_put:
		mov bp,pserr_pstack_underflow
		cmp word [pstack_ptr],byte 3
		jc prim_put_90

		mov bp,pserr_wrong_arg_types
		mov cx,2
		call get_pstack_tos
		mov dh,0
		push dx
		push eax
		mov dx,t_none + (t_int << 8)
		call get_2args
		pop ebx
		pop bp
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
		add ebx,ecx
		lin2segofs ebx,es,di
		mov [es:di],al
		jmp prim_put_80
prim_put_50:
		shr edx,24
		lin2segofs ebx,es,di

		cmp cx,[es:di]
		cmc
		mov bp,pserr_invalid_range
		jc prim_put_90
		
		add di,cx
		add cx,cx
		add cx,cx
		add di,cx

		mov [es:di+2],dl
		mov [es:di+3],eax

prim_put_80:
		sub word [pstack_ptr],byte 3
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
prim_length:
		pm_enter 32

		mov dl,t_none
		call pm_get_1arg
		jc prim_length_90
		call get_length
		jc prim_length_90
		xor ecx,ecx
		mov dl,t_int
		call pm_set_pstack_tos
prim_length_90:

		pm_leave 32
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
prim_array:
		mov dl,t_int
		call get_1arg
		jc prim_array_90
		cmp eax,(0fff0h-2)/5
		cmc
		mov bp,pserr_invalid_range
		jc prim_array_90
		push ax
		mov cx,5
		mul cx
		inc ax
		inc ax
		pm32_call calloc
		pop cx
		or eax,eax
		stc
		mov bp,pserr_no_memory
		jz prim_array_90

		lin2segofs eax,es,di
		mov [es:di],cx

		xor cx,cx
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
prim_pop:
		cmp word [pstack_ptr],byte 1
		mov bp,pserr_pstack_underflow
		jc prim_pop_90
		dec word [pstack_ptr]
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
prim_dup:
		mov cx,[pstack_ptr]
		cmp cx,[pstack_size]
		cmc
		mov bp,pserr_pstack_overflow
		jb prim_dup_90
		xor cx,cx
		call get_pstack_tos
		mov bp,pserr_pstack_underflow
		jc prim_dup_90
		mov cx,0
		inc word [pstack_ptr]
		call set_pstack_tos
prim_dup_90:
		ret


;; over - copy TOS-1
;
; group: stackbasic
;
; ( obj1 obj2 -- obj1 obj2 obj1 )
;
prim_over:
		mov cx,[pstack_ptr]
		cmp cx,[pstack_size]
		cmc
		mov bp,pserr_pstack_overflow
		jb prim_over_90
		mov cx,1
		call get_pstack_tos
		mov bp,pserr_pstack_underflow
		jc prim_over_90
		mov cx,0
		inc word [pstack_ptr]
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
prim_index:
		mov dl,t_int
		call get_1arg
		jc prim_index_90

		movzx edx,word [pstack_ptr]
		sub edx,2
		jc prim_index_90
		cmp edx,eax
		mov bp,pserr_pstack_underflow
		jc prim_index_90

		inc ax
		xchg ax,cx
		call get_pstack_tos
		xor cx,cx
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
		dec word [pstack_ptr]
		xor cx,cx
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
		dec word [pstack_ptr]
		xor cx,cx
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
prim_mul:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_mul_90
		imul ecx
		dec word [pstack_ptr]
		xor cx,cx
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
		dec word [pstack_ptr]
		xor cx,cx
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
		dec word [pstack_ptr]
		xor cx,cx
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
prim_neg:
		mov dl,t_int
		call get_1arg
		jc prim_neg_90
		neg eax
		xor cx,cx
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
prim_abs:
		mov dl,t_int
		call get_1arg
		jc prim_abs_90
		or eax,eax
		jns prim_abs_50
		neg eax
prim_abs_50:
		xor cx,cx
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
prim_min:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_min_90
		cmp eax,ecx
		jle prim_min_50
		xchg eax,ecx
prim_min_50:
		dec word [pstack_ptr]
		xor cx,cx
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
prim_max:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_max_90
		cmp eax,ecx
		jge prim_max_50
		xchg eax,ecx
prim_max_50:
		dec word [pstack_ptr]
		xor cx,cx
		call set_pstack_tos
prim_max_90:
		ret

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
		pop ax
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
prim_and:
		call plog_args
		and eax,ecx
prim_and_50:
		dec word [pstack_ptr]
		xor cx,cx
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
prim_not:
		xor cx,cx
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
		xor cx,cx
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
		dec word [pstack_ptr]
		xor cx,cx
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
		dec word [pstack_ptr]
		xor cx,cx
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
prim_def:
		mov dx,t_none + (t_dict_idx << 8)
		call get_2args
		jc prim_def_90
		cmp dl,t_sec
		mov bp,pserr_wrong_arg_types
		stc
		jz prim_def_90
		; note: cx is index
		call set_dict_entry
		mov bp,pserr_invalid_dict
		jc prim_def_90
		sub word [pstack_ptr],byte 2
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
		sub word [pstack_ptr],byte 2
		or ecx,ecx
		jz prim_if_90
		
		; branch
		xchg eax,[pscode_next_instr]

		mov cx,[rstack_ptr]
		cmp cx,[rstack_size]
		mov bp,pserr_rstack_overflow
		jae prim_if_80
		inc word [rstack_ptr]

		xor cx,cx
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
prim_ifelse:
		mov cx,2
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

		sub word [pstack_ptr],byte 3
		or ebx,ebx
		jz prim_ifelse_20
		xchg dl,dh
		xchg eax,ecx
prim_ifelse_20:
		; branch
		xchg eax,[pscode_next_instr]

		mov cx,[rstack_ptr]
		cmp cx,[rstack_size]
		mov bp,pserr_rstack_overflow
		jae prim_ifelse_80
		inc word [rstack_ptr]

		xor cx,cx
		mov dl,t_if			; mark as 'if' block
		call set_rstack_tos
		jnc prim_ifelse_90

prim_ifelse_80:
		stc
prim_ifelse_90:
		ret



; compare 2 strings
; return:
;  cl, al	last compared chars (if !=)
;  edx		length of identical parts
pcmp_str:
		push fs
		lin2segofs eax,fs,si
		lin2segofs ecx,es,di

		xor ecx,ecx
		xor eax,eax
		xor edx,edx
pcmp_str_20:
		mov ah,al
		mov ch,cl
		mov al,[fs:si]
		mov cl,[es:di]
		cmp al,cl
		jnz pcmp_str_50
		or al,al
		jz pcmp_str_50
		or cl,cl
		jz pcmp_str_50
		inc si
		jnz pcmp_str_30
		mov bx,fs
		add bx,1000h
		mov fs,bx
pcmp_str_30:
		inc di
		jnz pcmp_str_40
		mov bx,es
		add bx,1000h
		mov es,bx
pcmp_str_40:
		inc edx
		cmp edx,1 << 20		; avoid infinite loop
		jb pcmp_str_20
pcmp_str_50:
		pop fs
		ret


pcmp_args:
		; integer
		mov dx,t_int + (t_int << 8)
		push bx
		call get_2args
		pop bx
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
		pop ax			; skip last return
pcmp_args_90:
		ret

pcmp_true:
		mov dl,t_bool
		mov eax,1
		dec word [pstack_ptr]
		xor cx,cx
		call set_pstack_tos
		ret

pcmp_false:
		mov dl,t_bool
		mov eax,0
		dec word [pstack_ptr]
		xor cx,cx
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
prim_exch:
		mov cx,2
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
prim_rot:
		mov cx,3
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
prim_roll:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_roll_90
		or ecx,ecx
		jz prim_roll_90
		movzx edx,word [pstack_ptr]
		sub edx,2
		cmp edx,ecx
		mov bp,pserr_pstack_underflow
		jc prim_roll_90
		cdq
		idiv ecx
		sub word [pstack_ptr],byte 2
		; ecx is max. 14 bit
		or dx,dx
		jz prim_roll_90
		js prim_roll_50
prim_roll_40:
		push dx
		push cx
		call rot_pstack_down
		pop cx
		pop dx
		dec dx
		jnz prim_roll_40
		jmp prim_roll_90
prim_roll_50:
		neg dx
prim_roll_60:
		push dx
		push cx
		call rot_pstack_up
		pop cx
		pop dx
		dec dx
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
prim_return:
		xor cx,cx
prim_return_10:
		push cx
		call get_rstack_tos
		pop cx
		mov bp,pserr_rstack_underflow
		jc prim_return_90
		inc cx
		cmp dl,t_code
		jnz prim_return_10		; skip if, loop, repeat, for, forall

		sub [rstack_ptr],cx
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
prim_exit:
		xor cx,cx
prim_exit_10:
		push cx
		call get_rstack_tos
		pop cx
		mov bp,pserr_rstack_underflow
		jc prim_exit_90
		inc cx
		cmp dl,t_loop			; loop
		jz prim_exit_60
		cmp dl,t_repeat			; repeat
		jz prim_exit_40
		cmp dl,t_for			; for
		jz prim_exit_30
		cmp dl,t_forall			; forall
		jnz prim_exit_10
prim_exit_30:
		inc cx
		inc cx
prim_exit_40:
		inc cx
prim_exit_60:
		push cx
		call get_rstack_tos
		pop cx
		cmp dl,t_code
		jz prim_exit_80
		cmp dl,t_exit
		mov bp,pserr_invalid_rstack_entry
		stc
		jnz prim_exit_90

prim_exit_80:
		inc cx
		sub [rstack_ptr],cx
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
prim_loop:
		xor cx,cx
		call get_pstack_tos
		cmp dl,t_code
		mov bp,pserr_wrong_arg_types
		stc
		jnz prim_loop_90

		dec word [pstack_ptr]

		; branch
		xchg eax,[pscode_next_instr]

		mov cx,[rstack_size]
		sub cx,[rstack_ptr]
		cmp cx,3
		mov bp,pserr_rstack_overflow
		jb prim_loop_90
		add word [rstack_ptr],byte 2

		mov dl,t_exit
		mov cx,1
		call set_rstack_tos
		xor cx,cx
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
prim_repeat:
		mov dx,t_code + (t_int << 8)
		call get_2args
		jc prim_repeat_90

		sub word [pstack_ptr],byte 2

		or ecx,ecx
		jz prim_repeat_90

		mov bp,pserr_invalid_range
		stc
		js prim_repeat_90

		; branch
		xchg eax,[pscode_next_instr]

		mov dx,[rstack_size]
		sub dx,[rstack_ptr]
		cmp dx,4
		mov bp,pserr_rstack_overflow
		jb prim_repeat_90
		add word [rstack_ptr],byte 3

		push eax
		xchg eax,ecx
		mov dl,t_int
		mov  cx,1
		call set_rstack_tos
		pop eax
		mov cx,2
		mov dl,t_exit
		call set_rstack_tos
		xor cx,cx
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
prim_for:
		mov bp,pserr_pstack_underflow
		cmp  word [pstack_ptr],byte 4
		jc prim_for_90
		mov cx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_for_90
		mov cx,2
		push bp
		push eax
		call get_pstack_tos
		pop edi
		pop bp
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
		sub word [pstack_ptr],byte 3

		; branch
		xchg eax,[pscode_next_instr]

		mov dx,[rstack_size]
		sub dx,[rstack_ptr]
		cmp dx,6
		mov bp,pserr_rstack_overflow
		jb prim_for_90
		add word [rstack_ptr],byte 5

		push ecx
		push esi
		push edi

		mov dl,t_exit
		mov cx,4
		call set_rstack_tos

		pop eax
		mov dl,t_int
		mov cx,3
		call set_rstack_tos

		pop eax
		mov dl,t_int
		mov cx,2
		call set_rstack_tos

		pop eax
		mov dl,t_int
		mov cx,1
		call set_rstack_tos

		xor cx,cx
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
		sub word [pstack_ptr],2
		clc
		jmp prim_forall_90

prim_forall_30:
		push eax			; code
		push ecx			; string/array
		xchg dl,dh
		push dx
		xchg eax,ecx
		pm32_call get_length
		pop dx
		pop ecx
		pop ebx

		mov bp,pserr_invalid_range
		jc prim_forall_90

		or eax,eax			; length == 0
		jz prim_forall_20

		sub word [pstack_ptr],2

		; branch
		xchg ebx,[pscode_next_instr]

		mov si,[rstack_size]
		sub si,[rstack_ptr]
		cmp si,6
		mov bp,pserr_rstack_overflow
		jb prim_forall_90
		add word [rstack_ptr],5

		push ecx
		push dx
		push eax

		mov dl,t_exit
		xchg eax,ebx
		mov cx,4
		call set_rstack_tos		; code

		pop eax
		mov dl,t_int
		mov cx,2
		call set_rstack_tos		; length

		pop dx
		pop eax
		push eax
		push dx
		mov cx,3
		call set_rstack_tos		; string/array

		xor eax,eax
		mov dl,t_int
		mov cx,1
		call set_rstack_tos		; count

		xor cx,cx
		mov dl,t_forall			; mark as 'forall' block
		mov eax,[pscode_next_instr]
		call set_rstack_tos

		pop dx
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
prim_gettype:
		mov dl,t_none
		call get_1arg
		jc prim_gettype_90
		movzx eax,dl
		mov dl,t_int
		xor cx,cx
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
prim_settype:
		mov dx,t_int + (t_none << 8)
		call get_2args
		jc prim_settype_90
		mov dl,al
		and al,15
		xchg eax,ecx
		dec word [pstack_ptr]
		xor cx,cx
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
prim_screensize:
		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_screensize_90
		mov [pstack_ptr],ax
		mov dl,t_int
		movzx eax,word [screen_width]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [screen_height]
		xor cx,cx
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
prim_vscreensize:
		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_screensize_90
		mov [pstack_ptr],ax
		mov dl,t_int
		movzx eax,word [screen_width]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [screen_vheight]
		xor cx,cx
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
prim_monitorsize:
		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_monitorsize_90
		mov [pstack_ptr],ax

		cmp word [ddc_xtimings],0
		jnz prim_monitorsize_50

		call get_monitor_res

prim_monitorsize_50:

		mov dl,t_int
		movzx eax,word [ddc_xtimings]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [ddc_xtimings + 2]
		xor cx,cx
		call set_pstack_tos
prim_monitorsize_90:
		ret


;; image.size - graphics image size
;
; group: image
;
; ( -- int1 int2 )
;
; int1, int2: image width and heigth. The image is specified with @setimage.
; 
; example
;
;  image.size screen.size
;  exch 4 -1 roll sub 2 div 3 1 roll exch sub 2 div	% center image
;  moveto 0 0 image.size image				% draw it
;
prim_imagesize:
		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_imagesize_90
		mov [pstack_ptr],ax
		mov dl,t_int
		movzx eax,word [image_width]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [image_height]
		xor cx,cx
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
prim_moveto:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_moveto_90
		sub word [pstack_ptr],byte 2
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
prim_rmoveto:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_rmoveto_90
		sub word [pstack_ptr],byte 2
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
prim_currentpoint:
		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_currentpoint_90
		mov [pstack_ptr],ax
		mov dl,t_int
		movzx eax,word [gfx_cur_x]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [gfx_cur_y]
		xor cx,cx
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

		sub word [pstack_ptr],byte 2
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
prim_putpixel:
		pm_enter 32

		push fs
		push gs

		call pm_goto_xy
		call pm_screen_segs
		call [pm_setpixel_t]
		clc

		pop gs
		pop fs

		pm_leave 32
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
prim_getpixel:
		pm_enter 32

		push fs
		push gs

		call pm_goto_xy
		call pm_screen_segs
		mov esi,edi
		xor eax,eax
		call [pm_getpixel]
		call pm_decode_color

		pop gs
		pop fs

		pm_leave 32
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

; FIXME: [font_properties] are lost
;
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
prim_fontheight:
		movzx eax,word [font_height]
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
prim_setimage:
		call pr_setptr_or_none
		pm32_call image_init
		ret


;; currentimage - currently used image
;
; group: image
;
; ( -- ptr1 )
;
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
prim_show:
		mov dl,t_string
		call get_1arg
		jc prim_show_90
		dec word [pstack_ptr]
		lin2segofs eax,es,si
		mov bx,[start_row]
		or bx,bx
		jz prim_show_50
		cmp bx,[cur_row2]
		jae prim_show_90
		add bx,bx
		mov si,[bx + row_start_ofs]
		mov es,[row_start_seg]
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
prim_strsize:
		pm_enter 32

		mov dl,t_string
		call pm_get_1arg
		jc prim_strsize_90
		dec dword [pstack_ptr]

		mov esi,eax
		call str_size

		mov eax,[pstack_ptr]
		inc eax
		inc eax
		cmp [pstack_size],eax
		mov bp,pserr_pstack_overflow
		jb prim_strsize_90
		mov [pstack_ptr],eax
		push edx
		mov eax,ecx
		mov dl,t_int
		mov ecx,1
		call pm_set_pstack_tos
		pop eax
		mov dl,t_int
		xor ecx,ecx
		call pm_set_pstack_tos
prim_strsize_90:

		pm_leave 32
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
prim_memcpy:
		mov bp,pserr_pstack_underflow
		cmp word [pstack_ptr],byte 3
		jc prim_memcpy_90

		mov bp,pserr_wrong_arg_types
		mov cx,2
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

		pm_enter 32

		mov esi,eax
		mov edi,ebx

		es rep movsb

		pm_leave 32

prim_memcpy_80:
		sub word [pstack_ptr],byte 3
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
prim_image:
		pm_enter 32

		mov bp,pserr_pstack_underflow
		cmp dword [pstack_ptr],4
		jc prim_image_90
		mov ecx,3
		call pm_get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_image_90
		mov [line_x0],eax
		mov ecx,2
		push ebp
		call pm_get_pstack_tos
		pop ebp
		cmp dl,t_int
		stc
		jnz prim_image_90
		mov [line_y0],eax
		mov dx,t_int + (t_int << 8)
		call pm_get_2args
		jc prim_image_90

		sub dword [pstack_ptr],4

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

		pm_leave 32
		ret


;; loadpalette - load current palette
;
; group: image
;
; ( -- )
;
; Activates current palette in 8-bit modes.
;
prim_loadpalette:
		pm_enter 32

		mov ecx,100h
		xor edx,edx
		call load_palette
		clc

		pm_leave 32
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
prim_unpackimage:
		pm_enter 32

		mov bp,pserr_pstack_underflow
		cmp dword [pstack_ptr],4
		jc prim_unpackimage_90
		mov ecx,3
		call pm_get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_unpackimage_90
		mov [line_x0],eax
		mov ecx,2
		push ebp
		call pm_get_pstack_tos
		pop ebp
		cmp dl,t_int
		stc
		jnz prim_unpackimage_90
		mov [line_y0],eax
		mov dx,t_int + (t_int << 8)
		call pm_get_2args
		jc prim_unpackimage_90

		sub dword [pstack_ptr],3

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
		call pm_set_pstack_tos
prim_unpackimage_90:

		pm_leave 32
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
prim_setpalette:
		pm_enter 32

		mov dx,t_int + (t_int << 8)
		call pm_get_2args
		jc prim_setpalette_90

		sub dword [pstack_ptr],2

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

		pm_leave 32
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
prim_getpalette:
		pm_enter 32

		mov dl,t_int
		call pm_get_1arg
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
		call pm_set_pstack_tos
prim_getpalette_90:

		pm_leave 32
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
prim_savescreen:
		pm_enter 32

		mov dx,t_int + (t_int << 8)
		call pm_get_2args
		jc prim_savescreen_90
		call alloc_fb
		or eax,eax
		jz prim_savescreen_50
		push eax
		lea edi,[eax+4]
		call save_bg
		pop eax
prim_savescreen_50:
		dec dword [pstack_ptr]
		xor ecx,ecx
		mov dl,t_ptr
		or eax,eax
		jnz prim_savescreen_70
		mov dl,t_none
prim_savescreen_70:
		call pm_set_pstack_tos
prim_savescreen_90:

		pm_leave 32
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Allocate drawing buffer.
;
; eax		height
; ecx		width
;
; return:
;  eax		buffer (0: failed)
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
		call xmalloc
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

		bits 16

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
prim_restorescreen:
		pm_enter 32

		mov dl,t_ptr
		call pm_get_1arg
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
		dec dword [pstack_ptr]
		clc
prim_restorescreen_90:

		pm_leave 32
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
prim_malloc:
		mov dl,t_int
		call get_1arg
		jc prim_malloc_90
		pm32_call calloc
		or eax,eax
		stc
		mov bp,pserr_no_memory
		jz prim_malloc_90
		xor cx,cx
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
		pm32_call free
prim_free_50:
		dec word [pstack_ptr]
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
prim_memsize:
		mov dl,t_int
		call get_1arg
		jc prim_memsize_90
		mov cx,[pstack_ptr]
		inc cx
		cmp [pstack_size],cx
		mov bp,pserr_pstack_overflow
		jb prim_memsize_90
		mov [pstack_ptr],cx

		pm32_call memsize

		mov dl,t_int
		xchg eax,ebp
		push edi
		mov cx,1
		call set_pstack_tos
		pop eax
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos
prim_memsize_90:
		ret

prim_dumpmem:
%if debug
		call dump_malloc
%endif
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
prim_fillrect:
		pm_enter 32

		mov dx,t_int + (t_int << 8)
		call pm_get_2args
		jc prim_fillrect_90
		mov edx,ecx
		mov ecx,eax
		mov eax,[gfx_color]
		call fill_rect
		sub dword [pstack_ptr],2
prim_fillrect_90:

		pm_leave 32
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
prim_snprintf:
		mov bp,pserr_pstack_underflow
		cmp  word [pstack_ptr],byte 3
		jc prim_snprintf_90
		mov bp,pserr_wrong_arg_types
		mov cx,2
		call get_pstack_tos
		cmp dl,t_string
		stc
		jnz prim_snprintf_90
		push eax
		mov dx,t_string + (t_int << 8)
		call get_2args
		pop ebx
		jc prim_snprintf_90

		sub word [pstack_ptr],byte 3

		mov [pf_gfx_buf],eax
		mov [pf_gfx_max],ecx
		and dword [pf_gfx_cnt],byte 0
		and word [pf_gfx_err],byte 0

		or ecx,ecx
		jz prim_snprintf_40
		; clear buffer in case we have to print _nothing_
		lin2segofs eax,es,di
		mov byte [es:di],0
prim_snprintf_40:

		lin2segofs ebx,es,si

		mov byte [pf_gfx],1
		call printf
		mov byte [pf_gfx],0

		mov bp,[pf_gfx_err]
		cmp bp,byte 0
prim_snprintf_90:
		ret


;; edit.init -- setup and show an editable input field
;
; group: edit
;
; ( array1 str1 -- )
;
; str1: initial input string value
; array1: 8-dimensional array: [ x y bg buf buf_size 0 0 0 ]. x, y: input field
; position; bg: background pixmap (created with @savescreen) - this determines the
; input field dimensions, too; buf: string buffer, large enough
; for a string of length buf_size. The last 3 elements are used internally and must be 0.
;
; example
;   50 100 moveto 200 20 savescreen /bg exch def
;   /buf 100 string def
;   /ed [ 50 100 bg buf 100 0 0 0 ] def
;   ed "foo" edit.init
;
prim_editinit:
		pm_enter 32

		mov dx,t_string + (t_array << 8)
		call pm_get_2args
		jc prim_editinit_90

		mov esi,ecx

		push esi
		push eax
		call edit_get_params
		pop eax
		pop esi

		mov bp,pserr_invalid_data
		jc prim_editinit_90

		push dword [gfx_cur]

		push esi
		mov esi,eax
		call edit_init
		pop esi

		pop dword [gfx_cur]

		call edit_put_params

		sub dword [pstack_ptr],2
prim_editinit_90:

		pm_leave 32
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
prim_editdone:
		pm_enter 32

		mov dx,t_array
		call pm_get_1arg
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
		call restore_bg

		sub word [pstack_ptr],byte 1
prim_editdone_90:

		pm_leave 32
		ret


;; edit.showcursor - show input field cursor
;
; group: edit
;
; ( array1 -- )
;
; array1: see @edit.init
;
prim_editshowcursor:
		pm_enter 32

		mov dx,t_array
		call pm_get_1arg
		jc prim_editshowcursor_90

		mov esi,eax
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_editshowcursor_90

		push dword [gfx_cur]
		call edit_show_cursor
		pop dword [gfx_cur]

		sub dword [pstack_ptr],1
prim_editshowcursor_90:

		pm_leave 32
		ret


;; edit.hidecursor - hide input field cursor
;
; group: edit
;
; ( array1 -- )
;
; array1: see @edit.init
;
prim_edithidecursor:
		pm_enter 32

		mov dx,t_array
		call pm_get_1arg
		jc prim_edithidecursor_90

		mov esi,eax
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_edithidecursor_90

		push dword [gfx_cur]
		call edit_hide_cursor
		pop dword [gfx_cur]

		sub dword [pstack_ptr],1
prim_edithidecursor_90:

		pm_leave 32
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
prim_editinput:
		pm_enter 32

		mov dx,t_int + (t_array << 8)
		call pm_get_2args
		jc prim_editinput_90

		mov esi,ecx

		push esi
		push eax
		call edit_get_params
		pop eax
		pop esi

		mov bp,pserr_invalid_data
		jc prim_editinput_90

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

		sub dword [pstack_ptr],2
prim_editinput_90:

		pm_leave 32
		ret


;; sysconfig - get pointer to boot loader config data
;
; group: system
;
; ( -- ptr1 )
;
; ptr1: boot loader config data (32 bytes)
;
prim_sysconfig:
		segofs2lin word [boot_cs],word [boot_sysconfig],eax
		jmp pr_getptr_or_none


;; 64bit - test if we run on a 64-bit machine
;
; group: system
;
; ( -- int1 )
;
; int1 = 1: 64-bit architecture
;
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
prim_inbyte:
		mov dl,t_int
		call get_1arg
		jc prim_inbyte_90
		xchg ax,dx
		xor eax,eax
		in al,dx
		mov dl,t_int
		xor cx,cx
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
prim_outbyte:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_outbyte_90
		mov dx,cx
		out dx,al
		sub word [pstack_ptr],byte 2
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
prim_getbyte:
		mov dl,t_ptr
		call get_1arg
		jc prim_getbyte_90
		pm_enter 32
		movzx eax,byte [es:eax]
		pm_leave 32
		mov dl,t_int
		xor cx,cx
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
prim_putbyte:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jc prim_putbyte_90
		pm_enter 32
		mov [es:ecx],al
		pm_leave 32
		sub word [pstack_ptr],byte 2
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
prim_getdword:
		mov dl,t_ptr
		call get_1arg
		jc prim_getdword_90
		pm_enter 32
		mov eax,[es:eax]
		pm_leave 32
		mov dl,t_int
		xor cx,cx
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
prim_putdword:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jc prim_putdword_90
		pm_enter 32
		mov [es:ecx],eax
		pm_leave 32
		sub word [pstack_ptr],byte 2
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
prim_findfile:
		pm_enter 32

		mov dl,t_string
		call pm_get_1arg
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
		call pm_set_pstack_tos
prim_findfile_90:

		pm_leave 32
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
prim_filesize:
		pm_enter 32

		mov dl,t_string
		call pm_get_1arg
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
		call pm_set_pstack_tos
prim_filesize_90:

		pm_leave 32
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
prim_getcwd:
		pm_enter 32

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

		pm_leave 32
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
prim_chdir:
		mov dl,t_string
		call get_1arg
		jc prim_chdir_90
		push eax
		pm32_call get_length
		xchg eax,ecx
		pop eax
		jc prim_chdir_60

		or ecx,ecx
		jz prim_chdir_60
		cmp ecx,64
		jae prim_chdir_60

		push cx

		push eax
		mov al,0
		pm32_call gfx_cb			; get file name buffer address (edx)
		call lin2so
		pop si
		pop fs

		pop cx

		or al,al
		jnz prim_chdir_60

		lin2segofs edx,es,di

		fs rep movsb
		mov al,0
		stosb

		mov al,4
		pm32_call gfx_cb
		or al,al

		mov bp,pserr_invalid_function
		jnz prim_chdir_70

		dec word [pstack_ptr]
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
prim__readsector:
		mov dl,t_int
		call get_1arg
		jc prim__readsector_90

		mov edx,eax
		mov al,5
		pm32_call gfx_cb			; read sector (nr = edx)
		or al,al
		jz prim__readsector_50
		mov dl,t_none
		xor eax,eax
		jmp prim__readsector_80
prim__readsector_50:
		mov eax,edx
		mov dl,t_ptr
prim__readsector_80:
		xor cx,cx
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
prim_setmode:
		mov dl,t_int
		call get_1arg
		jz prim_setmode_30
		cmp dl,t_none
		stc
		jnz prim_setmode_90
		xor eax,eax
		mov cx,ax
		jmp prim_setmode_80
prim_setmode_30:
		xchg [gfx_mode],ax
		push ax
		call set_mode
		pop ax
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

		xor cx,cx

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
prim_videomodes:
		lfs si,[vbe_mode_list]
		xor eax,eax

prim_videomodes_20:
		add si,2
		inc ax
		cmp word [fs:si-2],0xffff
		jnz prim_videomodes_20

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
prim_videomodeinfo:
		mov dl,t_int
		call get_1arg
		jc prim_vmi_90

		mov cx,[pstack_ptr]
		add cx,3
		cmp [pstack_size],cx
		mov bp,pserr_pstack_overflow
		jb prim_vmi_90
		mov [pstack_ptr],cx

		cmp eax,100h
		jb prim_vmi_10
		mov ax,0ffh
prim_vmi_10:
		add ax,ax
		lfs si,[vbe_mode_list]
		add si,ax
		mov cx,[fs:si]
		or cx,cx
		jz prim_vmi_60
		cmp cx,-1
		jz prim_vmi_60

		push es

		les di,[vbe_buffer]
		mov ax,4f01h
		push di
		push cx
		int 10h
		pop cx
		pop di

		pop es
		mov fs,[vbe_buffer+2]

		cmp ax,4fh
		jnz prim_vmi_60

		test byte [fs:di],1		; mode supported?
		jz prim_vmi_60

		movzx eax,cx
		and ax,~(1 << 14)
		cmp dword [fs:di+28h],byte 0	; framebuffer start
		jz prim_vmi_20
		or ax,1 << 14
prim_vmi_20:
		mov dl,t_int
		xor cx,cx
		push di
		call set_pstack_tos
		pop di

		movzx eax,word [fs:di+12h]	; width
		mov dl,t_int
		mov cx,3
		push di
		call set_pstack_tos
		pop di

		movzx eax,word [fs:di+14h]	; heigth
		mov dl,t_int
		mov cx,2
		push di
		call set_pstack_tos
		pop di

		mov dl,[fs:di+1bh]		; color mode (aka memory model)
		mov dh,[fs:di+19h]		; color depth

		cmp dl,6			; direct color
		jnz prim_vmi_30
		cmp dh,32
		jz prim_vmi_40
		mov dh,[fs:di+1fh]		; red
		add dh,[fs:di+21h]		; green
		add dh,[fs:di+23h]		; blue
		jmp prim_vmi_40
prim_vmi_30:
		cmp dl,4			; PL8
		jnz prim_vmi_60
		mov dh,8
prim_vmi_40:
		movzx eax,dh

		mov dl,t_int
		mov cx,1
		call set_pstack_tos

		jmp prim_vmi_90

prim_vmi_60:
		; no mode
		xor eax,eax
		mov dl,t_int
		mov cx,3
		call set_pstack_tos
		xor eax,eax
		mov dl,t_int
		mov cx,2
		call set_pstack_tos
		xor eax,eax
		mov dl,t_int
		mov cx,1
		call set_pstack_tos
		xor eax,eax
		mov dl,t_none
		xor cx,cx
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
prim_sysinfo:
		mov dl,t_int
		call get_1arg
		jc prim_si_90

		cmp eax,100h
		jae prim_si_20
		pm32_call videoinfo
		jmp prim_si_80
prim_si_20:



prim_si_70:
		mov dl,t_none
		xor eax,eax
prim_si_80:
		xor cx,cx
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
prim_eject:
		mov dl,t_int
		call get_1arg
		jc prim_eject_90
		mov dl,al
		mov ax,4600h
		int 13h
		xor cx,cx
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
prim_poweroff:
		mov ax,5300h
		xor bx,bx
		int 15h
		jc prim_poweroff_90
		mov ax,5304h
		xor bx,bx
		int 15h
		mov ax,5301h
		xor bx,bx
		int 15h
		jc prim_poweroff_90
		mov ax,530eh
		xor bx,bx
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
prim_reboot:
		mov word [472h],1234h
		push word 0ffffh
		push word 0
		retf
		int 19h
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
		xchg eax,ebx
		dec word [pstack_ptr]
		xor cx,cx
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
prim_soundgetvolume:
		mov ax,[pstack_ptr]
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_sgv_90
		mov [pstack_ptr],ax
		mov dl,t_int
		movzx eax,byte [sound_vol]
		xor cx,cx
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
prim_soundsetvolume:
		mov dl,t_int
		call get_1arg
		jc prim_ssv_90
		dec word [pstack_ptr]
		or eax,eax
		jns prim_ssv_30
		xor eax,eax
prim_ssv_30:
		cmp eax,100
		jl prim_ssv_50
		mov ax,100
prim_ssv_50:
		or eax,eax
		jns prim_ssv_60
		xor ax,ax
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
prim_soundgetsamplerate:
		mov ax,[pstack_ptr]
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_sgsr_90
		mov [pstack_ptr],ax
		mov dl,t_int
		movzx eax,byte [sound_sample]
		xor cx,cx
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
prim_soundsetsamplerate:
		mov dl,t_int
		call get_1arg
		jc prim_sssr_90
		dec word [pstack_ptr]
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
prim_sounddone:
		call sound_done
		clc
		ret


%if 0
prim_soundtest:
		mov dl,t_int
		call get_1arg
		jc prim_stest_90
		dec word [pstack_ptr]

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
prim_modload:
		mov dx,t_ptr + (t_int << 8)
		call get_2args
		jc prim_modload_90
		sub word [pstack_ptr],byte 2
		xchg eax,ecx

		; ecx mod file
		; eax player

		push eax
		push ecx
		call sound_init
		pop ecx
		pop eax
		jc prim_modload_80

		push ecx
		call lin2so
		pop di
		pop es

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
prim_modplay:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_modplay_90
		sub word [pstack_ptr],byte 2
		xchg eax,ecx

		; ecx start
		; eax player

		cmp byte [sound_ok],0
		jz prim_modplay_90

		mov bx,cx
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
prim_modplaysample:
		mov bp,pserr_pstack_underflow
		cmp  word [pstack_ptr],byte 4
		jc prim_modps_90
		mov bp,pserr_wrong_arg_types

		mov cx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		jnz prim_modps_90

		mov cx,2
		push ax
		call get_pstack_tos
		pop bx
		cmp dl,t_int
		stc
		jnz prim_modps_90

		mov dx,t_int + (t_int << 8)
		push bx
		push ax
		call get_2args
		pop bx
		pop dx
		jc prim_modps_90

		sub word [pstack_ptr],byte 4

		xchg ax,dx

		; 1: ax
		; 2: bx
		; 3: cx
		; 4: dx

		cmp byte [sound_ok],0
		jz prim_modps_90

		call mod_playsample

		clc
prim_modps_90:
		ret


%if 0
prim_numtest:
		mov dl,t_int
		call get_1arg
		jc prim_numtest_90

		mov eax,[tmp_var_0 + 4*eax]

		mov dl,t_int
		xor cx,cx
		call set_pstack_tos

		clc
prim_numtest_90:
		ret
%endif


;; settextwrap - set text wrap column
;
; group: text
;
; ( int1 -- )
;
; int1: text wrap column; set to 0 to turn text wrapping off.
;
prim_settextwrap:
		call pr_setint
		mov [line_wrap],ax
		ret


;; currenttextwrap - current text wrap column
;
; group: text
;
; ( -- int1 )
;
; int1: text wrap column
;
prim_currenttextwrap:
		movzx eax,word [line_wrap]
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
prim_setmaxrows:
		call pr_setint
		mov [max_rows],ax
		ret


;; currentmaxrows -- current maxium number of text rows to display
;
; group: text
;
; ( -- int1 )
;
; int1: maxium number of text rows to display in a single @show command.
;
prim_currentmaxrows:
		movzx eax,word [max_rows]
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
prim_formattext:
		mov dl,t_string
		call get_1arg
		jc prim_formattext_90
		dec word [pstack_ptr]
		push eax
		xor ax,ax
		mov cx,max_text_rows
		mov di,row_start_ofs
		push ds
		pop es
		rep stosw
		mov cx,link_entries * sizeof_link
		mov di,link_list
		rep stosb
		pop eax
		lin2segofs eax,es,si
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
prim_gettextrows:
		movzx eax,word [cur_row2]
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
prim_setstartrow:
		call pr_setint
		mov [start_row],ax
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
prim_getlinks:
		movzx eax,word [cur_link]
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
prim_settextcolors:
		mov bp,pserr_pstack_underflow
		cmp word [pstack_ptr],byte 4
		jc prim_settextcolors_90
		mov cx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_settextcolors_90
		call encode_color
		mov [gfx_color0],eax
		mov [gfx_color],eax
		mov cx,2
		push bp
		call get_pstack_tos
		pop bp
		cmp dl,t_int
		stc
		jnz prim_settextcolors_90
		call encode_color
		mov [gfx_color1],eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_settextcolors_90

		sub word [pstack_ptr],byte 4

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
prim_currenttextcolors:
		mov ax,[pstack_ptr]
		add ax,4
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_currenttextcolors_90
		mov [pstack_ptr],ax
		mov dl,t_int
		mov eax,[gfx_color3]
		call decode_color
		xor cx,cx
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color2]
		call decode_color
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color1]
		call decode_color
		mov cx,2
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color0]
		call decode_color
		mov cx,3
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
prim_setlink:
		call pr_setint
		mov dx,[cur_link]
		cmp ax,dx
		jae prim_setlink_90
		mov [sel_link],ax
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
prim_currentlink:
		movzx eax,word [sel_link]
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
prim_getlink:
		mov dl,t_int
		call get_1arg
		jc prim_getlink_90
		mov bp,pserr_invalid_range
		cmp ax,[cur_link]
		cmc
		jc prim_getlink_90
		xchg ax,di
		shl di,3		; sizeof_link = 8
		add di,link_list
		mov ax,[pstack_ptr]
		add ax,3
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_getlink_90
		mov [pstack_ptr],ax
		mov dl,t_string
		segofs2lin ds, word label_buf,eax
		mov cx,3
		call set_pstack_tos
		mov dl,t_string
		segofs2lin word [row_start_seg],word [di+li_text],eax
		mov cx,2
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [di+li_x]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		movzx eax,word [di+li_row]
		xor cx,cx
		call set_pstack_tos

		mov es,[row_start_seg]
		mov si,[di+li_label]
		mov di,label_buf
		mov cx,32		; sizeof buf
prim_getlink_50:
		es lodsb
		cmp al,13h
		jz prim_getlink_60
		or al,al
		jz prim_getlink_60
		mov [di],al
		inc di
		loop prim_getlink_50
prim_getlink_60:
		mov byte [di],0
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
prim_lineheight:
		movzx eax,word [font_line_height]
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
prim_currenttitle:
		segofs2lin word [row_start_seg],word [page_title],eax
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
prim_idle:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jnc prim_idle_10
		cmp dx,t_int + (t_none << 8)
		stc
		jnz prim_idle_90
prim_idle_10:
		sub word [pstack_ptr],byte 2
		mov byte [run_idle],0
		cmp dh,t_none			; undef
		jz prim_idle_90
		push ecx
		call lin2so
		pop dword [idle_data]
		mov [idle_data2],eax
		mov byte [run_idle],1
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
prim_blend:
		pm_enter 32

		mov bp,pserr_pstack_underflow
		cmp dword [pstack_ptr],3
		jc prim_blend_90

		and dword [tmp_var_0],0

		mov ecx,2
		call pm_get_pstack_tos
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
		call pm_get_pstack_tos
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
		call pm_get_pstack_tos
		cmp dl,t_none
		jnz prim_blend_35
		sub dword [pstack_ptr],3
		; CF = 0
		jmp prim_blend_90
prim_blend_35:
		cmp dl,t_ptr
		jnz prim_blend_22

		mov [tmp_var_3],eax

		sub dword [pstack_ptr],3

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

		pm_leave 32
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Helper function that covers common cases.

; return eax as ptr on stack, returns undef if eax = 0

		bits 16

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
		mov cx,[pstack_ptr]
		inc cx
		cmp [pstack_size],cx
		mov bp,pserr_pstack_overflow
		jc pr_getobj_90
		mov [pstack_ptr],cx
		xor cx,cx
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
		dec word [pstack_ptr]
		clc
		jmp pr_setobj_10

; get integer from stack as eax
pr_setint:
		mov dl,t_int

; get object with type dl from stack as eax
pr_setobj:
		call get_1arg
		jnc pr_setobj_20
pr_setobj_10:
		pop ax			; don't return to function that called us
		ret
pr_setobj_20:
		dec word [pstack_ptr]
		pop cx			; put link to clc on stack
		push word pr_setobj_30
		jmp cx
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
		call pm_decode_color

		movzx eax,ah
		mov [transp],eax

		mov ax,[es:esi]
		call pm_decode_color
		xchg ecx,eax

		mov ax,[es:edi]
		call pm_decode_color
		call pm_enc_transp
		call pm_encode_color

		mov [es:edi],ax
		ret

; src: color, alpha: image
blend_pixel_01_16:
		mov ax,[es:ebx]
		call pm_decode_color

		movzx eax,ah
		mov [transp],eax

		mov ecx,[tmp_var_3]

		mov ax,[es:edi]
		call pm_decode_color
		call pm_enc_transp
		call pm_encode_color

		mov [es:edi],ax
		ret

; src: image, alpha: fixed
blend_pixel_10_16:
		mov ax,[es:esi]
		call pm_decode_color
		xchg eax,ecx

		mov ax,[es:edi]
		call pm_decode_color
		call pm_enc_transp
		call pm_encode_color

		mov [es:edi],ax
		ret

; src: color, alpha: fixed
blend_pixel_11_16:
		mov ecx,[tmp_var_3]

		mov ax,[es:edi]
		call pm_decode_color
		call pm_enc_transp
		call pm_encode_color

		mov [es:edi],ax
		ret

; src: image, alpha: image
blend_pixel_00_32:
		mov eax,[es:ebx]
		movzx eax,ah
		mov [transp],eax

		mov ecx,[es:esi]

		mov eax,[es:edi]
		call pm_enc_transp

		mov [es:edi],eax
		ret

; src: color, alpha: image
blend_pixel_01_32:
		mov eax,[es:ebx]
		movzx eax,ah
		mov [transp],eax

		mov ecx,[tmp_var_3]

		mov eax,[es:edi]
		call pm_enc_transp

		mov [es:edi],eax
		ret

; src: image, alpha: fixed
blend_pixel_10_32:
		mov ecx,[es:esi]

		mov eax,[es:edi]
		call pm_enc_transp

		mov [es:edi],eax
		ret

; src: color, alpha: fixed
blend_pixel_11_32:
		mov ecx,[tmp_var_3]

		mov eax,[es:edi]
		call pm_enc_transp

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

		sub ax,5		; still 5 pixel away?
		jge edit_align_90
		add [edit_shift],ax
		jge edit_align_90
		and word [edit_shift],0
		jmp edit_align_90
edit_align_50:
		sub cx,ax
		sub cx,5		; still 5 pixel away?
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
		call pm_utf8_dec
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

		cmp byte [chr_width],0
		jz edit_char_80

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

		mov dx,[chr_width]
		mov cx,[font_height]

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

		call pm_screen_segs

		mov ax,[edit_cursor]
		sub ax,[edit_shift]
		add ax,[edit_x]
		mov [gfx_cur_x],ax
		push word [edit_y]
		pop word [gfx_cur_y]
		movzx ecx,word [edit_height]
edit_show_cursor_10:
		push ecx
		call pm_goto_xy
		call [pm_setpixel_t]
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
; Store internal input field state.
;
;  esi		parameter array
;
; Note: no consistency checks done, esi _must_ point to a valid array.
;

		bits 32

edit_put_params:
		push word [edit_buf_ptr]
		pop word [es:esi+2+5*5+1]
		
		push word [edit_cursor]
		pop word [es:esi+2+5*6+1]
		
		push word [edit_shift]
		pop word [es:esi+2+5*7+1]

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Copy input field parameters into internal structures.
;
;  esi		parameter array
;
; return:
;  CF		invalid data
;

		bits 32

edit_get_params:
		es lodsw
		cmp ax,8
		jc edit_get_params_90

		cmp byte [es:esi+5*0],t_int
		jnz edit_get_params_80
		push word [es:esi+5*0+1]
		pop word [edit_x]

		cmp byte [es:esi+5*1],t_int
		jnz edit_get_params_80
		push word [es:esi+5*1+1]
		pop word [edit_y]
		
		cmp byte [es:esi+5*2],t_ptr
		jnz edit_get_params_80
		push dword [es:esi+5*2+1]
		pop dword [edit_bg]
		
		cmp byte [es:esi+5*3],t_string
		jnz edit_get_params_80
		mov eax,[es:esi+5*3+1]
		mov [edit_buf],eax
		
		cmp byte [es:esi+5*4],t_int
		jnz edit_get_params_80
		push word [es:esi+5*4+1]
		pop word [edit_buf_len]
		
		cmp byte [es:esi+5*5],t_int
		jnz edit_get_params_80
		push word [es:esi+5*5+1]
		pop word [edit_buf_ptr]
		
		cmp byte [es:esi+5*6],t_int
		jnz edit_get_params_80
		push word [es:esi+5*6+1]
		pop word [edit_cursor]
		
		cmp byte [es:esi+5*7],t_int
		jnz edit_get_params_80
		push word [es:esi+5*7+1]
		pop word [edit_shift]
		
		mov esi,[edit_bg]
		es lodsw
		mov [edit_width],ax
		es lodsw
		mov [edit_height],ax

		mov cx,[font_height]
		sub ax,cx
		sar ax,1
		mov [edit_y_ofs],ax

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
; map next window segment
;

		bits 16

inc_winseg:
		push ax
		mov al,[cs:mapped_window]
		inc al
		call set_win
		pop ax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Map next window segment.
;

		bits 32

pm_inc_winseg:
		push eax
		mov al,[mapped_window]
		inc al
		call pm_set_win
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; map window segment
;
; 	al	= window segment
;

		bits 16

set_win:
		push edi
		cmp byte [cs:vbe_active],0
		jz set_win_90
		cmp [cs:mapped_window],al
		jz set_win_90
		pusha
		mov [cs:mapped_window],al
		mov ah,[cs:window_inc]
		mul ah
		xchg ax,dx
		mov ax,4f05h
		xor bx,bx
		cmp word [cs:window_seg_r],0
		jz set_win_50
		pusha
		inc bx
		int 10h
		popa
set_win_50:
		int 10h
		popa
set_win_90:
		pop edi
		ret



; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Map window segment.
;
;  al		window segment
;

		bits 32

pm_set_win:
		push edi
		cmp byte [vbe_active],0
		jz pm_set_win_90
		cmp [mapped_window],al
		jz pm_set_win_90
		pusha
		mov [mapped_window],al
		mov ah,[window_inc]
		mul ah
		xchg eax,edx
		mov ax,4f05h
		xor ebx,ebx
		cmp word [window_seg_r],0
		jz pm_set_win_50
		pusha
		inc ebx
		int 10h
		popa
pm_set_win_50:
		int 10h
		popa
pm_set_win_90:
		pop edi
		ret



; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Go to current cursor position.
;
; return:
;  edi		offset
;  correct gfx segment is mapped
;
; Notes:
;  - changes no regs other than edi
;  - does not require ds == cs
;

		bits 16

goto_xy:
		push ax
		push dx
		mov ax,[cs:gfx_cur_y]
		movzx edi,word [cs:gfx_cur_x]
		imul di,[pixel_bytes]
		mul word [cs:screen_line_len]
		add ax,di
		adc dx,0
		push ax
		xchg ax,dx
		call set_win
		pop di
		pop dx
		pop ax
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

pm_goto_xy:
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
		call pm_set_win
		pop di
		pop edx
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Set active color.
;
; eax		color
;
; return:
;  [gfx_color]	color
;
;  Changed registers: eax
;

		bits 16

setcolor:
		mov [gfx_color],eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;

		bits 16

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
;

		bits 32

pm_encode_color:
		cmp byte [pixel_bits],16
		jnz pm_encode_color_90
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
pm_encode_color_90:
		ret


pm_decode_color:
		cmp byte [pixel_bits],16
		jnz pm_decode_color_90
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
pm_decode_color_90:
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
; draw a line
;

		bits 16

line:
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

		; es  -> window
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
; Set pixel at es:di.
;

		bits 16

setpixel_8:
		mov al,[gfx_color]

setpixel_a_8:
		mov [es:edi],al
		ret

setpixel_16:
		mov ax,[gfx_color]

setpixel_a_16:
		mov [es:edi],ax
		ret

setpixel_32:
		mov eax,[gfx_color]

setpixel_a_32:
		mov [es:edi],eax
		ret


; with transparency
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
		mov [es:edi],ax
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
		mov [es:edi],eax
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
; Get pixel from fs:si.
;

		bits 16

getpixel_8:
		mov al,[fs:esi]
		ret

getpixel_16:
		mov ax,[fs:esi]
		ret

getpixel_32:
		mov eax,[fs:esi]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Set pixel at es:edi.
;
; pm_setpixel_* read from [fs:edi] and write to [gs:edi]
;

		bits 32

pm_setpixel_8:
		mov al,[gfx_color]

pm_setpixel_a_8:
		mov [gs:edi],al
		ret

pm_setpixel_16:
		mov ax,[gfx_color]

pm_setpixel_a_16:
		mov [gs:edi],ax
		ret

pm_setpixel_32:
		mov eax,[gfx_color]

pm_setpixel_a_32:
		mov [gs:edi],eax
		ret


; with transparency
pm_setpixel_t_16:
		mov ax,[gfx_color]

pm_setpixel_ta_16:
		cmp dword [transp],0
		jz pm_setpixel_a_16
		call pm_decode_color
		push ecx
		xchg eax,ecx
		mov ax,[fs:edi]
		call pm_decode_color
		xchg eax,ecx
		call pm_enc_transp
		pop ecx
		call pm_encode_color
		mov [gs:edi],ax
		ret

pm_setpixel_t_32:
		mov eax,[gfx_color]

pm_setpixel_ta_32:
		cmp dword [transp],0
		jz pm_setpixel_a_32
		push ecx
		mov ecx,[fs:edi]
		call pm_enc_transp
		pop ecx
		mov [gs:edi],eax
		ret


; (1 - t) eax + t * ecx -> eax
pm_enc_transp:
		ror ecx,16
		ror eax,16
		call pm_add_transp
		rol ecx,8
		rol eax,8
		call pm_add_transp
		rol ecx,8
		rol eax,8
		call pm_add_transp
		mov eax,ecx
		ret


; cl, al -> cl
pm_add_transp:
		push eax
		push ecx
		movzx eax,al
		movzx ecx,cl
		sub ecx,eax
		imul ecx,[transp]
		sar ecx,8
		add ecx,eax
		cmp ecx,0
		jge pm_add_transp_10
		mov cl,0
		jmp pm_add_transp_20
pm_add_transp_10:
		cmp ecx,100h
		jb pm_add_transp_20
		mov cl,0ffh
pm_add_transp_20:
		mov [esp],cl
		pop ecx
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Get pixel from fs:esi.
;
; pm_getpixel_* read from [fs:esi]
;

		bits 32

pm_getpixel_8:
		mov al,[fs:esi]
		ret

pm_getpixel_16:
		mov ax,[fs:esi]
		ret

pm_getpixel_32:
		mov eax,[fs:esi]
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
		mov [cfont],bp
		mov [cfont+2],ax

		shl eax,4
		add eax,ebp
		mov [cfont.lin],eax

		mov word [cfont_height],16
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Initialize font.
;
; eax		linear ptr to font header
;

		bits 16

font_init:
		mov edx,eax
		shr edx,31
		mov [font_properties],dl
		and eax,~(1 << 31)
		mov ebp,eax
		lin2segofs eax,es,bx
		cmp dword [es:bx+foh_magic],0d2828e07h	; magic
		jnz font_init_90
		mov ax,[es:bx+foh_entries]
		mov dl,[es:bx+foh_height]
		mov dh,[es:bx+foh_line_height]
		or ax,ax
		jz font_init_90
		or dx,dx
		jz font_init_90
		mov [font_entries],ax
		mov [font_height],dl
		mov [font_line_height],dh
		mov [font],ebp
font_init_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write a string. '\n' is a line break.
;
;  es:si	ASCIIZ string
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
text_xy:
		xor eax,eax
		mov [last_label],ax
		mov [cur_row],ax
		and [txt_state],byte ~1

		test byte [txt_state],2
		jz text_xy_05
		mov [row_start_seg],es
		mov [row_start_ofs],si
		mov [cur_row2],ax
		mov [cur_link],ax
		mov [sel_link],ax
		mov [page_title],ax
		push si
		call utf8_dec
		pop si
		call rm_is_eot
		jz text_xy_05
		inc word [cur_row2]
text_xy_05:
		push word [gfx_cur_x]
text_xy_10:
		mov di,si
		call utf8_dec

		call rm_is_eot
		jz text_xy_90

		cmp word [line_wrap],byte 0
		jz text_xy_60

		cmp eax,3000h
		jae text_xy_20

		call is_space
		jnz text_xy_60
text_xy_20:

		push si
		mov si,di
		call word_width
		pop si
		add cx,[gfx_cur_x]
		cmp cx,[line_wrap]
		jbe text_xy_60
text_xy_30:
		call is_space
		jnz text_xy_50

		mov di,si
		call utf8_dec

		call rm_is_eot
		jz text_xy_90
		jmp text_xy_30
text_xy_50:
		mov si,di
		jmp text_xy_65
text_xy_60:
		cmp eax,0ah
		jnz text_xy_70
text_xy_65:
		mov ax,[font_line_height]
		add [gfx_cur_y],ax
		pop ax
		push ax
		mov [gfx_cur_x],ax
		inc word [cur_row]
		mov dx,[max_rows]
		mov ax,[cur_row]
		or dx,dx
		jz text_xy_67
		cmp ax,dx
		jae text_xy_90
text_xy_67:
		test byte [txt_state],2
		jz text_xy_10
		cmp ax,max_text_rows
		jae text_xy_10
		mov [cur_row2],ax
		inc word [cur_row2]
		add ax,ax
		xchg ax,bx
		mov [row_start_ofs + bx],si
		jmp text_xy_10
text_xy_70:
		push si
		push es
		cmp eax,1fh
		jae text_xy_80
		call text_special
		jmp text_xy_81
text_xy_80:
		test byte [txt_state],1
		jnz text_xy_81
		pm32_call char_xy
text_xy_81:
		pop es
		pop si
		jmp text_xy_10
text_xy_90:
		pop ax
		push dword [gfx_color0]
		pop dword [gfx_color]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Handle special chars.
;
;  eax		char
;  es:si	ptr to next char
;
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
		mov [last_label],si

		jmp text_special_90
text_special_40:
		cmp eax,13h
		jnz text_special_50

		and byte [txt_state],~1

		; check for selected link
		mov bx,[sel_link]
		shl bx,3		; sizeof_link = 8
		mov dx,[bx+link_list+li_text]
		cmp si,dx

		push eax
		mov eax,[gfx_color3]
		jz text_special_45
		mov eax,[gfx_color2]
text_special_45:
		call setcolor
		pop eax

		test byte [txt_state],2
		jz text_special_90

		mov bx,[cur_link]
		cmp bx,link_entries
		jae text_special_90
		inc word [cur_link]
		shl bx,3		; sizeof_link = 8
		add bx,link_list
		push word [last_label]
		pop word [bx+li_label]
		mov [bx+li_text],si
		push word [gfx_cur_x]
		pop word [bx+li_x]
		mov dx,[cur_row2]
		sub dx,1		; 0-- -> 0
		adc dx,0
		mov [bx+li_row],dx

		jmp text_special_90
text_special_50:
		cmp eax,14h
		jnz text_special_60

		mov [page_title],si

		jmp text_special_90
text_special_60:


text_special_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; string width until end of next word
;
;  es:si	ASCIIZ string
;
; return:
;  cx		width
;
word_width:
		push es
		push si
		push ax

		xor dx,dx
		mov bl,0
		mov bh,0

word_width_10:
		call utf8_dec

word_width_20:
		call rm_is_eot
		jz word_width_90

		cmp eax,0ah
		jz word_width_90

		cmp eax,10h
		jnz word_width_30
		mov bh,0
		mov bl,0
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
		push bx
		push dx
		push si
		push es
		pm32_call char_width
		pop es
		pop si
		pop dx
		pop bx
		pop eax

		add dx,cx

word_width_70:
		call is_space
		jz word_width_10

		call utf8_dec

		or bx,bx
		jnz word_width_80
		cmp eax,3000h
		jae word_width_90
word_width_80:

		call is_space
		jnz word_width_20

word_width_90:
		mov cx,dx

		pop ax
		pop si
		pop es
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Test for white space (space or tab).
;
;  eax		char
;
; return:
;  ZF		0 = no, 1 = yes
;
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

		bits 16

rm_is_eot:
		or eax,eax
		jz rm_is_eot_90
		cmp eax,[char_eot]
rm_is_eot_90:
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
		call pm_utf8_dec
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
		movzx eax,word [font_line_height]
		mul edx
		movzx edx,word [font_height]
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
		call pm_utf8_dec
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
;
; Decode next utf8 char.
;
;  es:si	string
;
; return:
;  eax		char	(invalid char: 0)
;
;  Note: changes only: eax, si
;

		bits 16

utf8_dec:
		xor eax,eax
		es lodsb
		cmp al,80h
		jb utf8_dec_90

		push cx
		push edx

		xor edx,edx
		xor cx,cx
		mov dl,al

		cmp al,0c0h		; invalid
		jb utf8_dec_70

		inc cx			; 2 bytes
		and dl,1fh
		cmp al,0e0h
		jb utf8_dec_10

		inc cx			; 3 bytes
		and dl,0fh
		cmp al,0f0h
		jb utf8_dec_10

		inc cx			; 4 bytes
		and dl,7
		cmp al,0f8h
		jb utf8_dec_10

		inc cx			; 5 bytes
		and dl,3
		cmp al,0fch
		jb utf8_dec_10

		inc cx			; 6 bytes
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
		dec cx
		jnz utf8_dec_10
		xchg eax,edx
		jmp utf8_dec_80
		
utf8_dec_70:
		xor eax,eax
utf8_dec_80:
		pop edx
		pop cx

utf8_dec_90:
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

pm_utf8_dec:
		xor eax,eax
		es lodsb
		cmp al,80h
		jb pm_utf8_dec_90

		push ecx
		push edx

		xor edx,edx
		xor ecx,ecx
		mov dl,al

		cmp al,0c0h		; invalid
		jb pm_utf8_dec_70

		inc ecx			; 2 bytes
		and dl,1fh
		cmp al,0e0h
		jb pm_utf8_dec_10

		inc ecx			; 3 bytes
		and dl,0fh
		cmp al,0f0h
		jb pm_utf8_dec_10

		inc ecx			; 4 bytes
		and dl,7
		cmp al,0f8h
		jb pm_utf8_dec_10

		inc ecx			; 5 bytes
		and dl,3
		cmp al,0fch
		jb pm_utf8_dec_10

		inc ecx			; 6 bytes
		and dl,1
		cmp al,0feh
		jae pm_utf8_dec_70
pm_utf8_dec_10:
		es lodsb
		cmp al,80h
		jb pm_utf8_dec_70
		cmp al,0c0h
		jae pm_utf8_dec_70
		and al,3fh
		shl edx,6
		or dl,al
		dec ecx
		jnz pm_utf8_dec_10
		xchg eax,edx
		jmp pm_utf8_dec_80
		
pm_utf8_dec_70:
		xor eax,eax
pm_utf8_dec_80:
		pop edx
		pop ecx

pm_utf8_dec_90:
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

		push word [gfx_cur_x]
		push word [gfx_cur_y]

		mov cx,[chr_x_ofs]
		add [gfx_cur_x],cx

		mov dx,[chr_y_ofs]
		add [gfx_cur_y],dx

		call pm_goto_xy
		call pm_screen_segs

		mov esi,[font]
		add esi,[chr_bitmap]

		cmp byte [chr_real_width],0
		jz char_xy_70
		cmp byte [chr_real_height],0
		jz char_xy_70

		xor dx,dx
		xor bp,bp

char_xy_20:
		xor cx,cx
char_xy_30:
		bt [es:esi],bp
		jnc char_xy_40
		mov ax,[gfx_cur_x]
		add ax,cx
		cmp ax,[clip_r]
		jge char_xy_40
		cmp ax,[clip_l]
		jl char_xy_40
		call [pm_setpixel_t]
char_xy_40:
		inc bp
		add di,[pixel_bytes]
		jnc char_xy_50
		call pm_inc_winseg
char_xy_50:
		inc cx
		cmp cx,[chr_real_width]
		jnz char_xy_30

		mov ax,[screen_line_len]
		mov bx,[chr_real_width]
		imul bx,[pixel_bytes]
		sub ax,bx
		add di,ax
		jnc char_xy_60
		call pm_inc_winseg
char_xy_60:
		inc dx
		cmp dx,[chr_real_height]
		jnz char_xy_20

char_xy_70:

		pop word [gfx_cur_y]
		pop word [gfx_cur_x]

char_xy_80:
		mov cx,[chr_width]
		add [gfx_cur_x],cx

char_xy_90:

		pop gs
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Look for char in font.
;
;  eax		char
;
; return:
;  CF		0 = found, 1 = not found
;  [chr_*]	updated
;

		bits 32

find_char:
		and eax,1fffffh
		push eax
		cmp dword [font],0
		stc
		jz find_char_90

		test byte [font_properties],1
		jz find_char_10
		mov eax,'*'
find_char_10:

		mov ebx,[font]
		add ebx,sizeof_font_header_t
		movzx ecx,word [font_entries]

find_char_20:
		mov esi,ecx
		shr esi,1

		shl esi,3
		mov edx,[es:ebx+esi+ch_c]
		and edx,1fffffh		; 21 bits
		cmp eax,edx

		jz find_char_80

		jl find_char_50

		add ebx,esi
		test cl,1
		jz find_char_50
		add ebx,sizeof_char_header_t
find_char_50:
		shr ecx,1
		jnz find_char_20

		stc
		jmp find_char_90

find_char_80:
		movzx edx,word [es:ebx+esi+ch_ofs]
		mov [chr_bitmap],edx
		mov edx,[es:ebx+esi+ch_size]

		shr edx,5
		mov cl,dl
		and cl,01fh
		mov [chr_x_ofs],cl

		shr edx,5
		mov cl,dl
		and cl,01fh
		mov [chr_y_ofs],cl

		shr edx,5
		mov cl,dl
		and cl,01fh
		mov [chr_real_width],cl

		shr edx,5
		mov cl,dl
		and cl,01fh
		mov [chr_real_height],cl

		shr edx,5
		mov cl,dl
		and cl,01fh
		mov [chr_width],cl

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
		movzx ecx,word [chr_width]
char_width_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write a char at the current console cursor position.
;
;  al		char
;  ebx		color
;
; return:
;  console cursor position gets advanced
;

		bits 16

con_char_xy:
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

		lgs si,[cfont]

		mul byte [cfont_height]
		add si,ax

		xor dx,dx

con_char_xy_20:
		mov cx,7
con_char_xy_30:
		bt [gs:si],cx
		mov eax,[gfx_color]
		jc con_char_xy_40
		xor  eax,eax
con_char_xy_40:
		call [setpixel_a]
		add di,[pixel_bytes]
		jnc con_char_xy_50
		call inc_winseg
con_char_xy_50:
		dec cx
		jns con_char_xy_30

		inc si

		mov ax,[screen_line_len]
		mov bx,8
		imul bx,[pixel_bytes]
		sub ax,bx
		add di,ax
		jnc con_char_xy_60
		call inc_winseg
con_char_xy_60:
		inc dx
		cmp dx,[cfont_height]
		jnz con_char_xy_20

		add word [con_x],8

		pop word [gfx_cur_y]
		pop word [gfx_cur_x]

		pop dword [gfx_color]

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
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
;
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

		bits 16

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

		call pm_goto_xy
		mov esi,edi

		pop edi

		call pm_screen_segs

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
		call pm_inc_winseg
save_bg_30:
		mov eax,[fs:esi]
		add si,4
		jnz save_bg_35
		call pm_inc_winseg
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
		call pm_inc_winseg
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

		rm32_call clip_it
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

		call pm_goto_xy
		call pm_screen_segs

		imul edx,[pixel_bytes]

restore_bg_20:
		push edx

restore_bg_30:
		es lodsb
		mov [gs:edi],al
		inc di
		jnz restore_bg_50
		call pm_inc_winseg
restore_bg_50:
		dec edx
		jnz restore_bg_30

		pop edx

		mov eax,[screen_line_len]
		sub eax,edx
		add di,ax
		jnc restore_bg_60
		call pm_inc_winseg
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
;
; Load screen segments. Write segment to es, read segment to fs.
;
; Modified registers: -
;

		bits 16

screen_segs:
		call screen_seg_w
		jmp screen_seg_r


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

pm_screen_segs:
		push eax
		mov ax,pm_seg.screen_r16
		mov fs,ax
		mov ax,pm_seg.screen_w16
		mov gs,ax
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Load write segment to es.
;
; Modified registers: -
;

		bits 16

screen_seg_w:
		mov es,[window_seg_w]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Load read segment to fs.
;
; Modified registers: -
;

		bits 16

screen_seg_r:
		cmp word [window_seg_r],0
		jz screen_seg_r_10
		mov fs,[window_seg_r]
		ret
screen_seg_r_10:
		mov fs,[window_seg_w]
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

		rm32_call clip_it
		jc fill_rect_90

		movzx edx,word [gfx_width]
		movzx ecx,word [gfx_height]

		call pm_goto_xy
		call pm_screen_segs

		mov ebp,[screen_line_len]
		mov eax,edx
		imul eax,[pixel_bytes]
		sub ebp,eax

fill_rect_20:
		mov ebx,edx
fill_rect_30:
		call [pm_setpixel_t]
		add di,[pixel_bytes]
		jnc fill_rect_60
		call pm_inc_winseg
fill_rect_60:
		dec ebx
		jnz fill_rect_30

		add di,bp
		jnc fill_rect_80
		call pm_inc_winseg
fill_rect_80:
		dec ecx
		jnz fill_rect_20

fill_rect_90:

		pop gs
		pop fs
		ret	


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

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
		call mod_get_samples

new_int8_80:

		mov byte [sound_int_active],0
new_int8_90:

		pop gs
		pop fs
		pop es
		pop ds
		popad

		iret


		bits 16

sound_init:
		cmp byte [sound_ok],0
		jnz sound_init_90

		call chk_tsc
		jc sound_init_90

		mov eax,ar_sizeof
		pm32_call calloc
		cmp eax,byte 1
		jc sound_init_90
		push eax
		call lin2so
		pop dword [mod_buf]

		call mod_init

		mov eax,sound_buf_size
		pm32_call calloc
		cmp eax,byte 1
		jc sound_init_90
		push eax
		call lin2so
		pop dword [sound_buf]

		xor eax,eax
		mov [int8_count],eax
		mov [sound_start],ax
		mov [sound_end],ax
		mov [sound_playing],al
		mov [sound_int_active],al

		push ds
		pop es
		mov di,playlist
		mov cx,playlist_entries * sizeof_playlist
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

		push word 0
		pop es

		push dword [es:8*4]
		pop dword [sound_old_int8]

		push cs
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
		mov [next_int + 4],eax

		mov byte [sound_ok],1
sound_init_90:
		ret


		bits 16

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

		push word 0
		pop es

		push dword [sound_old_int8]
		pop dword [es:8*4]

		mov byte [sound_ok],0

		popf

		push dword [mod_buf]
		call so2lin
		pop eax
		pm32_call free

		push dword [sound_buf]
		call so2lin
		pop eax
		pm32_call free

sound_done_90:
		ret


; eax: new sample rate

		bits 16

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

%if 0

		bits 16

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


; mod player
%include	"modplay.inc"


mod_init:
		push ds
		push dword [mod_buf]
		pop si
		pop ds
		call init
		clc
		pop ds
		ret

mod_load:
		push ds
		push dword [mod_buf]
		pop si
		pop ds
		call loadmod
		pop ds
		ret

mod_play:
		push ds
		push dword [mod_buf]
		pop si
		pop ds
		call playmod
		pop ds
		mov byte [sound_playing],1
		ret

mod_playsample:
		push ds
		push dword [mod_buf]
		pop si
		pop ds
		call playsamp
		pop ds
		mov byte [sound_playing],1
		ret

mod_get_samples:
		push ds
		push dword [mod_buf]
		pop si
		pop ds
		call play
		mov dl,[si]
		add si,ar_samps
		push ds
		pop fs
		pop ds

		; dl: 0/1 --> play nothing/play
		sub dl,1

		mov cx,num_samples
		les bx,[sound_buf]
		mov di,[sound_end]
		cld

mod_get_samples_20:

		fs lodsb
		or al,dl		; 0ffh if we play nothing
		mov [es:bx+di],al
		inc di
		cmp di,sound_buf_size
		jb mod_get_samples_50
		xor di,di

mod_get_samples_50:

		dec cx
		jnz mod_get_samples_20
		mov [sound_end],di

mod_get_samples_90:
		ret

mod_setvolume:
		cmp byte [sound_ok],0
		jz mod_setvolume_90
		push ds
		push dword [mod_buf]
		pop si
		pop ds

		mov dx,ax
		xor ax,ax
		or dx,dx
		jz mod_setvolume_50
		sub ax,1
		sbb dx,0
		mov bx,100
		div bx
mod_setvolume_50:
		mov bx,ax
		xor ax,ax
		mov cx,ax
		dec ax
		call setvol

		pop ds
mod_setvolume_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Check for cpuid instruction.
;
; return:
;  CF		0/1	yes/no
;
chk_cpuid:
		mov ecx,1 << 21
		pushfd
		pushfd
		pop eax
		xor eax,ecx
		push eax
		popfd
		pushfd
		pop edx
		popfd
		xor eax,edx
		cmp eax,ecx
		stc
		jz chk_cpuid_90
		clc
chk_cpuid_90:
		ret


; Check for time stamp counter.
;
; return:
;  CF		0/1	yes/no
;
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


; Check for 64 bit extension.
;
; return:
;  CF		0/1	yes/no
;
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
prim_xxx:
;		call pr_setptr_or_none
		; eax
		call mouse_init
		or ah,ah
		mov eax,0
		jnz prim_xxx_90
		segofs2lin cs,word mouse_x,eax
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

		mov byte [image_type],1		; pcx

		mov [image],edi
		mov [image_width],cx
		mov [image_height],dx

		lea ebx,[edi+80h]
		mov [image_data],ebx

		inc esi
		mov [image_pal],esi

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
		mov esi,[image_data]

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
		call pm_encode_color
		call [pm_setpixel_a]
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
		call pm_encode_color
pcx_unpack_74:
		call [pm_setpixel_a]
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

		bits 16

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

		mov cx,5
		mov si,ddc_xtimings

get_mon_res_30:
		mov ax,[si]
		mov dx,[si+2]

		cmp ax,[ddc_xtimings]
		jb get_mon_res_60

		cmp dx,[ddc_xtimings+2]
		jb get_mon_res_60

		mov [ddc_xtimings],ax
		mov [ddc_xtimings+2],dx

get_mon_res_60:
		add si,4
		loop get_mon_res_30

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Read EDID record via DDC
;

		bits 16

read_ddc:
		push es

		; vbe support check
		cmp word [screen_mem],0
		jz read_ddc_90

%if 0
		xor cx,cx
		xor dx,dx
		mov ax,4f15h
		mov bl,0
		int 10h
		cmp ax,4fh
		jnz read_ddc_90
%endif

		xor bp,bp

read_ddc_20:
		push bp
		les di,[vbe_buffer]
		push di
		mov cx,40h
		xor ax,ax
		rep stosw
		pop di
		mov ax,4f15h
		mov bl,1
		mov cx,bp
		xor dx,dx
		push di
		int 10h
		pop di
		pop bp
		cmp ax,4fh
		jz read_ddc_30

		inc bp
		cmp bp,2		; some BIOSes don't like more (seen on a Packard Bell EasyNote)
		jb read_ddc_20

		jmp read_ddc_90

read_ddc_30:

		mov ax,[es:di+23h]
		mov [ddc_timings],ax

		mov cx,4
		lea si,[di+26h]
		mov di,ddc_xtimings1
read_ddc_40:
		es lodsb
		cmp al,1
		jbe read_ddc_70
		
		movzx ebp,al
		add bp,byte 31
		shl bp,3

		mov al,[es:si]
		shr al,6
		jz read_ddc_70
		movzx bx,al
		shl bx,3

		mov eax,ebp
		mul dword [bx+ddc_mult]
		div dword [bx+ddc_mult+4]
		
		jz read_ddc_70

		shl eax,16
		add eax,ebp
		mov [di],eax

read_ddc_70:
		inc si
		add di,4
		loop read_ddc_40

read_ddc_90:
		pop es
		ret

ddc_timings	dw 0		; standard ddc timing info
ddc_xtimings	dd 0		; converted standard timing/final timing value
ddc_xtimings1	dd 0, 0, 0, 0
ddc_mult	dd 0, 1		; needed for ddc timing calculation
		dd 3, 4
		dd 4, 5
		dd 9, 16


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Look for a fsc notebook lcd panel and set ddc_timings.
;

		bits 16

read_fsc:
		push es
		push ds
		cmp word [ddc_timings],byte 0
		jnz read_fsc_90

		push word 0xf000
		pop ds
		xor di,di
read_fsc_10:
		cmp dword [di],0x696a7546
		jnz read_fsc_30
		cmp dword [di+4],0x20757374
		jnz read_fsc_30
		mov cx,0x20
		xor bx,bx
		mov si,di
read_fsc_20:
		lodsb
		add bl,al
		dec cx
		jnz read_fsc_20
		or bl,bl
		jnz read_fsc_30
		mov al,[di+23]
		and al,0xf0
		jnz read_fsc_90
		mov bl,[di+21]
		and bx,0xf0
		shr bx,3
		mov ax,[cs:bx+fsc_bits]
		mov [cs:ddc_timings],ax
		jmp read_fsc_90
read_fsc_30:
		add di,0x10
		jnz read_fsc_10
read_fsc_90:
		pop ds
		pop es
		ret

fsc_bits	dw 0, 0x0004, 0x4000, 0x0200, 0x0100, 0x0200, 0, 0x4000
		dw 0x0200, 0, 0, 0, 0, 0, 0, 0


%if 0
xxx_setscreen:
		push es
		pushad
		call encode_color
		push word 0a000h
		pop es
		xor di,di
		mov cx,4000h
		rep stosd
		call get_key
		popad
		pop es
		ret

%endif


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
		mov edi,[vbe_buffer.lin]

		push eax
		push edi

		mov ecx,200h/4
		xor eax,eax
		rep stosd
		mov dword [es:edi-200h],32454256h	; 'VBE2'

		mov di,[vbe_buffer.ofs]
		push word [vbe_buffer.seg]
		pop word [rm_seg.es]

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
; Prelimiray protected mode interface init.
;
; Setup gdt so we can at least switch modes with interrupts disabled.
;

		bits 16

gdt_init:
		mov eax,cs

		segofs2lin ax,word gdt,dword [pm_gdt.base]

		mov [rm_prog_cs],ax
		shl eax,4

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
		call calloc
		cmp eax,byte 1
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

		switch_to_bits 16

		call switch_to_rm

		; jmp to int handler & continue at pm_int_50
		retf
pm_int_50:

		call switch_to_pm

		switch_to_bits 32

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
; Switch from real mode to 16 bit protected mode.
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
		jmp pm_seg.prog_c16:switch_to_pm_20
switch_to_pm_20:
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
		popf
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; Switch from 16 bit protected mode to real mode.
;
; Assumes cs = .text
;
; No normal regs or flags changed.
; Segment regs != cs are taken from rm_seg.
;

		bits 16

switch_to_rm:
		pushf
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

		and al,~1
		mov cr0,eax

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
		ret


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

switch_to_pm32:
		call switch_to_pm
		switch_to_bits 32
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

switch_to_rm32:
		switch_to_bits 16
		call switch_to_rm
		o32 ret

		bits 16


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; code end

_end:

