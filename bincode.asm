%define			debug 1

%include		"vocabulary.inc"
%include		"modplay_defines.inc"

; some type definitions from mkbootmsg.c
; struct file_header_t
fh_magic_id		equ 0
fh_version		equ 4
fh_res_1		equ 5
fh_res_2		equ 6
fh_file_entries		equ 7
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

; struct file_raw_t
fi_raw_data		equ 0
fi_raw_size		equ 4
sizeof_file_raw_t	equ 8

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
pserr_invalid_dict_entry	equ 200h
pserr_invalid_prim		equ 201h

keyBS			equ 08h
keyLeft			equ 4bh		; scan code
keyRight		equ 4dh		; scan code
keyHome			equ 47h		; scan code
keyEnd			equ 4fh		; scan code
keyDel			equ 53h		; scan code

max_text_rows		equ 128

			section .text

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

vbe_buffer		dd 0		; (seg:ofs) buffer for vbe calls
vbe_mode_list		dd 0		; (seg:ofs) list with vbe modes
infobox_buffer		dd 0		; (lin) temp buffer for InfoBox messages

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
dict_size		dw 0		; dict entries

boot_cs			dw 0		; seg
boot_sysconfig		dw 0		; ofs

pstack			dd 0		; (seg:ofs)
pstack_size		dw 0		; entries
pstack_ptr		dw 0
rstack			dd 0		; (seg:ofs)
rstack_size		dw 0		; entries
rstack_ptr		dw 0


image			dd 0		; (lin) current image
image_width		dw 0
image_height		dw 0
image_data		dd 0		; (seg:ofs)
image_pal		dd 0		; (seg:ofs)
image_type		db 0		; 0:no image, 1: pcx, 2:jpeg

pcx_line_starts		dd 0		; (lin) table of line starts

screen_width		dw 0
screen_height		dw 0
screen_line_len		dd 0

setpixel		dw setpixel_8		; function that sets one pixel
setpixel_a		dw setpixel_a_8		; function that sets one pixel
setpixel_t		dw setpixel_8		; function that sets one pixel
setpixel_ta		dw setpixel_a_8		; function that sets one pixel
getpixel		dw getpixel_8		; function that gets one pixel


transp			dd 0		; transparency

; 0..100h
brightness		dw 100h

			align 4, db 0
; current font description
font			dd 0		; (seg:ofs) to font header
font_entries		dw 0		; chars in font
font_height		dw 0
font_line_height	dw 0

; current char description
chr_bitmap		dw 0		; ofs rel. to [font]
chr_x_ofs		dw 0
chr_y_ofs		dw 0
chr_real_width		dw 0
chr_real_height		dw 0
chr_width		dw 0

utf8_buf		times 8 db 0

; pointer to currently active palette (3*100h bytes)
gfx_pal			dd 0		; (seg:ofs)
; pointer to tmp area (3*100h bytes)
gfx_pal_tmp		dd 0		; (seg:ofs)
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
; segment address of readable window
; if 0 -> gfx_window_seg_w is rw
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

			align 4, db 0
gfx_color		dd 0		; current color
gfx_color0		dd 0		; color #0 (normal color))
gfx_color1		dd 0		; color #1 (highlight color)
gfx_color2		dd 0		; color #2 (link color)
gfx_color3		dd 0		; color #3 (selected link color)
transparent_color	dw -1
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

			align 2, db 0
row_start_seg		dw 0
row_start_ofs		times max_text_rows dw 0

			; note: link_list relies on row_start_seg
link_list		times sizeof_link * link_entries db 0

; currently used tint color (call load_palette to make changes visible)
gfx_cs_tint_r		db 0
gfx_cs_tint_g		db 0
gfx_cs_tint_b		db 0
gfx_cs_r		db 0
gfx_cs_g		db 0
gfx_cs_b		db 0


			; max label size: 32
label_buf		times 35 db 0

; buffer for number conversions
num_buf			times 23h db 0
num_buf_end		db 0

; temp data for printf
tmp_write_data		times 10h dd 0
tmp_write_num		dw 0
tmp_write_sig		db 0
tmp_write_cnt		db 0
tmp_write_pad		db 0

pf_gfx			db 0
pf_gfx_err		dw 0
			align 4, db 0
pf_gfx_buf		dd 0
pf_gfx_max		dd 0
pf_gfx_cnt		dd 0

			align 4, db 0
input_timeout_start	dd 0
input_timeout		dd 0

progress_max		dd 0
progress_current	dd 0

edit_x			dw 0
edit_y			dw 0
edit_width		dw 0
edit_height		dw 0
edit_bg			dd 0		; (seg:ofs)
edit_buf		dd 0		; (seg:ofs)
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

; gdt for pm switch
pm_cs			equ 8
pm_ss			equ 10h
pm_ds			equ 18h
pm_es			equ 20h

			align 4
pm_gdt			dw pm_gdt_size-1	; gdt descriptor
			dd 0			; for lgdt instruction
			dw 0
pm_gdt_cs		dd 0000ffffh		; 64k code segment
			dd 00009b00h
pm_gdt_ss		dd 0000ffffh		; 64k data segment
			dd 00009300h
pm_gdt_ds		dd 0000ffffh		; 64k data segment
			dd 00009300h
pm_gdb_es		dd 0000ffffh		; 4GB data segment, start at 0
			dd 008f9300h
pm_gdt_size		equ $-pm_gdt


%if debug
; debug texts
dmsg_01			db 'Memory: %p - %p, img data at %p', 10, 0
dmsg_02			db 'Image: %u x %u (real: %u x %u)', 10, 0
dmsg_03			db 'addr 0x%05x, size 0x%05x+4, %s', 10, 0
dmsg_04			db 'oops: 0x%05x > 0x%05x', 10, 0
dmsg_05			db 'oops: 0 size block', 10, 0
dmsg_06			db 'addr 0x%05x', 10, 0
dmsg_07			db 'free', 0
dmsg_08			db 'used', 0
dmsg_09			db 'current dictionary', 10, 0
dmsg_10			db '  %2u: type %u, val 0x%x', 10, 0

%endif

single_step		db 0
show_debug_info		db 0

hello			db 10, 'Initializing gfx code...', 10, 0
msg_10			db '|ip %4x:  %8x.%x           |', 10, 0
msg_11			db '|%2x: %8x.%2x', 0
msg_12			db '|  :            ', 0
msg_13			db '/----pstk------------rstk-------\', 10, 0
msg_14			db '|-------------------------------|', 10, 0
msg_15			db '\-------------------------------/', 10, 0
msg_16			db '|', 10, 0
msg_17			db '|err %3x                        |', 10, 0 
msg_18			db '|err %3x: %8x              |', 10, 0
msg_19			db '|err %3x: %8x   %8x   |', 10, 0
msg_20			db '|ip %4x: %8x.%x %8x.%x |', 10, 0

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

		; init malloc memory chain

                ; align 4
		mov eax,[mem_free]
		add eax,3
		and eax,~3
		mov [mem_free],eax

		push eax
		call lin2so
		pop bx   
		pop es
		mov edx,[mem_max]
		sub edx,eax
		mov [es:bx],edx

%if debug
		mov si,hello
		call printf
%endif

		; get initial keyboard state
		push byte 0
		pop es
		push word [es:417h]
		pop word [kbd_status]

%if debug
		mov eax,[mem]
		pf_arg_uint 0,eax
		mov eax,[mem_max]
		pf_arg_uint 1,eax
		mov eax,[mem_free]
		pf_arg_uint 2,eax

		mov si,dmsg_01
		call printf
%endif

		call dict_init
		jc gfx_init_90

		call stack_init
		jc gfx_init_90

		mov eax,[mem]
		lin2segofs eax,es,si
		add eax,[es:si+fh_code]
		mov [pscode_start],eax
		mov eax,[es:si+fh_code_size]
		mov [pscode_size],eax

		; now the ps interpreter is ready to run

		; alloc memory for palette data
		call pal_init

		mov eax,100h
		call calloc
		cmp eax,byte 1
		jc gfx_init_90
		mov [infobox_buffer],eax

		mov eax,200h
		call calloc
		cmp eax,byte 1
		jc gfx_init_90
		push eax
		call lin2so
		pop dword [vbe_buffer]

		mov eax,200h
		call calloc
		cmp eax,byte 1
		jc gfx_init_90
		push eax
		call lin2so
		pop dword [vbe_mode_list]

		; ok, we've done it, now continue the setup

%if 0
		call dump_malloc
		call get_key
%endif

		; run global code
		xor eax,eax
		mov [pstack_ptr],ax
		mov [rstack_ptr],ax
		call run_pscode
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

		call sound_done

		mov ax,3
		int 10h

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

		push di
		push cx

		push cs
		pop ds
		cld

		movzx eax,ax
		mov [input_timeout],eax
		mov [input_timeout_start],eax

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
		call calloc
		mov [tmp_var_2],eax
		pop eax
		call calloc
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

		push ax

		mov cx,100h-1
		mov fs,[boot_cs]

		lin2segofs dword [infobox_buffer],es,bp
		or si,si
		jz gfx_infobox_init_40
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
		pop ds
		pop es
		pop fs
		retf



; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Internal functions.
;
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
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
;
; Initialize parameter & return stack.
;
; return:
;  CY		error
;
stack_init:
		mov ax,param_stack_size
		mov [pstack_size],ax
		and word [pstack_ptr],byte 0
		mov eax,param_stack_size * 5
		call calloc
		cmp eax,byte 1
		jc stack_init_90
		push eax
		call lin2so
		pop dword [pstack]

		mov ax,ret_stack_size
		mov [rstack_size],ax
		and word [rstack_ptr],byte 0
		mov eax,ret_stack_size * 5
		call calloc
		cmp eax,byte 1
		jc stack_init_90
		push eax
		call lin2so
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
;
; Setup initial dictionary.
;
; return:
;  CY		error
;
dict_init:
		push fs
		mov eax,[mem]
		lin2segofs eax,es,si
		mov ecx,[es:si+fh_dict]
		cmp ecx,byte 1
		jc dict_init_90
		add eax,ecx
		lin2segofs eax,es,si
		xor eax,eax
		es lodsw
		mov [dict_size],ax
		; the dictionary should fit in 64k
		cmp ax,0fff0h/5
		cmc
		jc dict_init_90

		; p_none is not part of the default dict
		cmp ax,cb_functions + prim_functions - 1
		jb dict_init_90

		imul eax,eax,5
		push es
		push si
		call calloc
		pop si
		pop es
		cmp eax,byte 1
		jc dict_init_90

		push eax
		call lin2so
		pop dword [dict]

		; add default functions

		lfs bx,[dict]
		add bx,cb_functions * 5
		xor cx,cx
		inc cx
dict_init_20:
		mov byte [fs:bx],t_prim
		mov [fs:bx+1],cx
		add bx,5
		inc cx
		cmp cx,prim_functions
		jb dict_init_20

		; add user defined things

		es lodsw
		or ax,ax
		jz dict_init_80
		cmp [dict_size],ax
		jb dict_init_90
		lfs bx,[dict]
		xchg ax,cx
dict_init_50:
		es lodsw
		cmp ax,[dict_size]
		cmc
		jc dict_init_90
		mov di,5
		mul di
		xchg ax,di
		es lodsb
		mov [fs:bx+di],al
		es lodsd
		mov [fs:bx+di+1],eax
		dec cx
		jnz dict_init_50

dict_init_80:
		clc
dict_init_90:
		pop fs
		ret

%if debug

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
;
; Get some memory.
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if the request failed)
;  memory is initialized with 0
;
calloc:
		push eax
		call malloc
		pop ecx
		or eax,eax
		jz calloc_90
		push eax
		lin2segofs eax,es,di
		xor eax,eax
		add ecx,byte 3
		shr ecx,2
		rep stosd
		pop eax
calloc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Get some memory.
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if the request failed)
;
malloc:
		xor ebp,ebp
		; only in 4-byte chunks
		add eax,3
		and eax,~3
		jz malloc_90
		add eax,4
		mov ebx,[mem_free]

malloc_20:
		lin2segofs ebx,es,si
		mov ecx,[es:si]
		test cl,1
		jnz malloc_60
		and cl,~3
		cmp ecx,eax
		jb malloc_70
		; mark as occupied
		or byte [es:si],1
		lea ebp,[ebx+4]
		mov edi,ecx
		sub edi,eax
		cmp edi,byte 8
		jb malloc_90
		
		add ebx,eax
		or al,1
		mov [es:si],eax
		lin2segofs ebx,es,si
		mov [es:si],edi
		
		jmp malloc_90
malloc_60:
		and cl,~3
malloc_70:
		add ebx,ecx
		cmp ebx,[mem_max]
		jb malloc_20
malloc_90:
		xchg ebp,eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Free memory.
;
;  eax          linear address
;
free:
		or eax,eax
		jz free_90
		test al,3
		jnz free_90

		; extended memory
		cmp eax,100000h
		jae xfree

		sub eax,4

		mov ebx,[mem_free]
		mov ecx,ebx
free_10:
		cmp eax,ebx
		jnz free_70

		lin2segofs ebx,es,si
		test byte [es:si],1
		jz free_90

		cmp ecx,ebx		; first block?
		jz free_30

		lin2segofs ecx,es,si
		mov edx,[es:si]
		test dl,1
		jnz free_30		; prev block is used

		and dl,~3		; prev block is free -> join them
		push es
		lin2segofs ebx,es,di
		add edx,[es:di]
		and dl,~3
		pop es
		mov [es:si],edx
		mov ebx,ecx

free_30:
		mov edx,ebx
		lin2segofs ebx,es,si
		and byte [es:si],~1	; mark block as free
		add edx,[es:si]
		and dl,~3
		cmp edx,[mem_max]	; last block?
		jae free_90

		lin2segofs edx,es,si
		mov edx,[es:si]
		test dl,1
		jnz free_90		; next block is used

		and dl,~3		; next block is free -> join them
		lin2segofs ebx,es,si
		add [es:si],edx
		jmp free_90

free_70:
		mov ecx,ebx
		lin2segofs ebx,es,si
		add ebx,[es:si]
		and bl,~3
		cmp ebx,[mem_max]
		jb free_10
free_90:
		ret


%if debug
; dump memory chain
dump_malloc:
		pushad
		mov ebx,[mem_free]

dump_malloc_30:
		lin2segofs ebx,es,si
		mov ecx,[es:si]

		pushad
		mov ax,dmsg_07
		test cl,1
		jz dump_malloc_40
		mov ax,dmsg_08
dump_malloc_40:
		pf_arg_ushort 2,ax
		and cl,~3
		sub ecx,4
		pf_arg_uint 0,ebx
		pf_arg_uint 1,ecx
		mov si,dmsg_03
		call printf
		popad

		and ecx,byte ~3
		mov si,dmsg_05
		jz dump_malloc_80

		add ebx,ecx
		cmp ebx,[mem_max]
		jz dump_malloc_90
		jb dump_malloc_30

		pf_arg_uint 0,ebx
		pf_arg_uint 1,edi
		mov si,dmsg_04
dump_malloc_80:
		call printf
dump_malloc_90:
		popad
		ret
%endif


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; return:
;  ebp		total free memory
;  edi		largest free block
;
memsize:
		xor ebp,ebp
		xor edi,edi
		mov ebx,[mem_free]
memsize_30:
		lin2segofs ebx,es,si
		mov ecx,[es:si]

		mov al,cl
		and ecx,byte ~3
		jz memsize_90
		test al,1
		jnz memsize_50

		lea eax,[ecx-4]
		add ebp,eax
		cmp eax,edi
		jb memsize_50
		mov edi,eax
memsize_50:
		add ebx,ecx
		cmp ebx,[mem_max]
		jb memsize_30
memsize_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Get some memory (taken from extended memory).
;
;  eax          memory size
;
; return:
;  eax          linear address  (0 if the request failed)
;
; !!! Currently a fake; it's just called _once_ anyway. !!!
xmalloc:
		; 2 - 3 MB, to avoid A20 handling
		mov eax,200000h

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Free memory (extended memory area).
;
;  eax          linear address
;
xfree:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Switch to protected mode.
;
; return:
;  CF		error (can't switch)
;
real_to_pm:
		cli
		pushad

		segofs2lin ds,word pm_gdt,dword [pm_gdt+2]

		mov eax,9b00000h
		mov ax,cs
		; patch jmp instruction for later
		mov [pm_to_real_20-2],ax
		shl eax,4
		mov [pm_gdt_cs+2],eax
		
		mov eax,9300000h
		mov ax,ss
		shl eax,4
		mov [pm_gdt_ss+2],eax
		
		mov eax,9300000h
		mov ax,ds
		shl eax,4
		mov [pm_gdt_ds+2],eax

		mov eax,cr0
		test al,1		; in prot mode (maybe vm86)?
		stc
		jnz real_to_pm_90
		or al,1

		o32 lgdt [pm_gdt]

		mov cr0,eax

		jmp pm_cs:real_to_pm_20
real_to_pm_20:

		mov ax,pm_ss
		mov ss,ax

		mov ax,pm_ds
		mov ds,ax

		mov ax,pm_es
		mov es,ax
		mov fs,ax
		mov gs,ax

		clc
real_to_pm_90:
		popad
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Switch to real mode.
;
pm_to_real:
		pushad

		mov eax,cr0
		and al,~1
		mov cr0,eax

		jmp 0:pm_to_real_20
pm_to_real_20:

		mov ax,cs
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax

		mov eax,[pm_gdt_ss+2]
		shr eax,4
		mov ss,ax

		popad
		sti
		ret



; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Find out size of memory block.
;
;  eax		lin. address
;
; return:
;  eax		size
;
find_mem_size:
		mov edx,[pscode_start]
		cmp eax,edx
		jb find_mem_size_10
		add edx,[pscode_size]
		cmp eax,edx
		jae find_mem_size_10

		; string constant

		lin2segofs eax,es,di
		mov cx,0ffffh
		sub cx,di
		movzx edx,cx
		mov al,0
		repnz scasb
		xor eax,eax
		jnz find_mem_size_90
		sub dx,cx
		mov eax,edx
		jmp find_mem_size_90

find_mem_size_10:
		cmp eax,[mem_free]
		jb find_mem_size_40
		cmp eax,[mem_max]
		jae find_mem_size_40

		; malloc area

		mov ebx,[mem_free]

find_mem_size_20:
		lin2segofs ebx,es,si
		mov ecx,[es:si]
		and ecx,~3
		lea edx,[ebx+ecx]

		cmp eax,edx
		jae find_mem_size_30

		test byte [es:si],1
		jz find_mem_size_80

		sub eax,ebx
		cmp eax,4
		jb find_mem_size_80	; within header

		sub ecx,eax
		xchg eax,ecx
		jmp find_mem_size_90

find_mem_size_30:
		mov ebx,edx
		cmp ebx,[mem_max]
		jb find_mem_size_20
		jmp find_mem_size_80

find_mem_size_40:
		mov ebp,[mem_archive]
		or ebp,ebp
		jz find_mem_size_70
		cmp eax,ebp
		jb find_mem_size_70
		cmp eax,[mem_free]
		jae find_mem_size_70

		; cpio archive area

find_mem_size_50:
		mov ecx,[mem_free]
		sub ecx,26
		cmp ebp,ecx
		jae find_mem_size_80

		lin2segofs ebp,es,bx
		cmp word [es:bx],71c7h
		jnz find_mem_size_80

		movzx ecx,word [es:bx+20]	; file name size
		inc cx
		and cx,~1			; align

		lea ecx,[ecx+ebp+26]		; data start

		cmp eax,ecx
		jb find_mem_size_80		; within header area

		mov edx,[es:bx+22]		; data size
		rol edx,16			; strange word order

		mov ebp,edx
		inc ebp
		and ebp,byte ~1			; align
		add ebp,ecx			; next record

		add ecx,edx

		cmp eax,ebp
		jae find_mem_size_50

		sub ecx,eax
		jb find_mem_size_80		; within alignment area

		xchg eax,ecx
		jmp find_mem_size_90

find_mem_size_70:

		; some other area

find_mem_size_80:
		xor eax,eax

find_mem_size_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Find file.
;
;  eax		file name (lin)
;
; return:
;  eax		file start (lin)
;
; Note: use find_mem_size to find out the file size
;
find_file:
		lin2segofs eax,fs,si
		mov ebp,[mem_archive]
		or ebp,ebp
		jz find_file_80
find_file_20:
		lin2segofs ebp,es,bx
		cmp word [es:bx],71c7h
		jnz find_file_80
		mov cx,[es:bx+20]	; file name size (incl. final 0)
		movzx edx,cx
		inc dx
		and dx,~1		; align
		lea ebp,[ebp+edx+26]	; points to data start
		lea di,[bx+26]
		or cx,cx
		jz find_file_50
		push si
		fs rep cmpsb
		pop si
		jnz find_file_50
		xchg eax,ebp
		jmp find_file_90
find_file_50:
		mov ecx,[es:bx+22]	; data size
		rol ecx,16		; strange word order
		inc ecx
		and ecx,byte ~1		; align
		add ebp,ecx
		mov ecx,ebp
		add ecx,26
		cmp ecx,[mem_free]
		jb find_file_20
find_file_80:
		xor eax,eax
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
		mov word [screen_line_len],320
		mov byte [pixel_bits],8
		mov byte [pixel_bytes],1
		call mode_init
set_mode_102:
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

		mov al,[es:di+1bh]		; color mode (aka memory model)
		mov ah,[es:di+19h]		; color depth
		mov dh,ah
		cmp al,6			; direct color
		jnz set_mode_30
		sub dh,[es:di+25h]		; reserved color bits
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

		call mode_init

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


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Find graphics mode.
;
;  edx		width
;  ecx		height
;  eax		color bits
;  [vbe_buffer]	buffer for vbe info
;
; return:
;  eax		mode number
;  CF		1 = not found
;
find_mode:
		push es

		mov [tmp_write_data],dx
		mov [tmp_write_data+2],cx
		mov [tmp_write_data+4],ax

		lfs si,[vbe_mode_list]
		cmp word [fs:si],0
		jnz find_mode_40

		; ok, get list first

		les di,[vbe_buffer]
		mov ax,4f00h
		and dword [es:di],byte 0
		push di
		int 10h
		pop di
		cmp ax,4fh
		jnz find_mode_30
		lfs si,[es:di+0eh]
		les di,[vbe_mode_list]
		mov cx,0ffh
find_mode_10:
		fs lodsw
		stosw
		cmp ax,0ffffh
		jz find_mode_20
		dec cx
		jnz find_mode_10
		mov word [es:di],0ffffh
find_mode_20:
		lfs si,[vbe_mode_list]
		cmp word [fs:si],0
		jnz find_mode_40
		; make sure it's not 0; mode 1 is the same as mode 0
		mov byte [fs:si],1
		jmp find_mode_40
find_mode_30:
		lfs si,[vbe_mode_list]
		mov word [fs:si],0ffffh
find_mode_40:
		fs lodsw
		cmp ax,0ffffh
		jz find_mode_80
		xchg ax,cx
		les di,[vbe_buffer]
		mov ax,4f01h
		push fs
		push si
		push di
		push cx
		int 10h
		pop cx
		pop di
		pop si
		pop fs
		cmp ax,4fh
		jnz find_mode_40

		test byte [es:di],1		; mode supported?
		jz find_mode_40

		mov eax,[es:di+12h]		; size
		cmp eax,[tmp_write_data]
		jnz find_mode_40

		mov dl,[es:di+1bh]		; color mode (aka memory model)
		mov dh,[es:di+19h]		; color depth

		cmp dl,6			; direct color
		jnz find_mode_60
		cmp dh,32
		jz find_mode_70
		sub dh,[es:di+25h]		; reserved color bits
		jmp find_mode_70
find_mode_60:
		cmp dl,4			; PL8
		jnz find_mode_40
		mov dh,8
find_mode_70:
		cmp dh,[tmp_write_data+4]
		jnz find_mode_40

		movzx eax,cx
		jmp find_mode_90

find_mode_80:
		stc
find_mode_90:
		pop es
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Activate an image from file.
;
;  eax:		lin ptr to image
;
; return:
;  CY:		error
;
image_init:
		push eax
		lin2segofs eax,es,bx
		cmp dword [es:bx],0801050ah
		jnz image_init_90

		mov cx,[es:bx+8]
		inc cx
		jz image_init_80
		mov dx,[es:bx+10]
		inc dx
		jz image_init_80

		push eax
		push cx
		push dx
		push bx
		push es
		call find_mem_size
		pop es
		pop bx
		pop dx
		pop cx
		pop edi

		cmp eax,381h
		jb image_init_80

		lea esi,[eax+edi-301h]
		lin2segofs esi,fs,si

		cmp byte [fs:si],12
		jnz image_init_80

		mov byte [image_type],1		; pcx

		mov [image],edi
		mov [image_width],cx
		mov [image_height],dx

		lea ax,[bx+80h]
		mov [image_data],ax
		mov [image_data+2],es

		inc si
		mov [image_pal],si
		mov [image_pal+2],fs

		call parse_img

		lfs si,[image_pal]
		les di,[gfx_pal]

		mov cx,300h
		push cx
		fs rep movsb
		pop cx

		xor ax,ax
		mov dx,cx
		dec di
		std
		repz scasb
		cld
		setnz al
		sub dx,cx
		sub dx,ax
		xchg ax,dx
		xor dx,dx
		mov cx,3
		div cx
		sub ax,100h
		neg ax
		mov [pals],ax

		clc
		jmp image_init_90
		
image_init_80:
		stc
image_init_90:
		pop eax
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
lin2so:
		push eax
		mov eax,[esp + 6]
		shr eax,4
		mov [esp + 8],ax
		and word [esp + 6],byte 0fh
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
; Write text to console.
;
; si		text (ACSIIZ)
;
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

		cmp al,'s'
		jnz printf_30

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
write_str:
		xor cx,cx
write_str_10:
		call pf_next_char
		cmp byte [pf_gfx],0
		jz write_str_40
		call is_eot
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
		cmp al,0ah
		jnz write_char_60
		push ax
		mov al,0dh
		mov bx,7
		mov ah,0eh
		int 10h
		pop ax
write_char_60:
		mov bx,7
		mov ah,0eh
		int 10h

write_char_90:
		popad
		pop es
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
;  CY		not a number
;
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
ps_status_info:
		xor dx,dx
		call cons_xy

		mov si,msg_13
		call printf

		mov cx,4
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
; Set console cursor position.
;
;  dh		row
;  dl		column
;
; return:
;
cons_xy:
		mov bh,0
		mov ah,2
		int 10h
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
idle_data	dd 0
idle_data2	dd 0

%include	"kroete.inc"

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
;
;  dl		tos type
;  dh		tos + 1 type
; return:
;  eax		tos
;  ecx		tos + 1
;  dx		actual tos types (even if CF is set)
;  CF		error
;
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
;
; Our primary functions.
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
		call calloc
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


prim_length:
		mov dl,t_none
		call get_1arg
		jc prim_length_90
		call get_length
		jc prim_length_90
		xor cx,cx
		mov dl,t_int
		call set_pstack_tos
prim_length_90:
		ret


;  dl, eax	obj
; Return:
;  eax		length
;   CF		0/1 ok/not ok
;
get_length:
		cmp dl,t_ptr
		jz get_length_10
		lin2segofs eax,es,si
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
		movzx eax,word [es:si]
		jmp get_length_80
get_length_30:
		xor cx,cx
		xor eax,eax
get_length_40:
		es lodsb
		call is_eot
		loopnz get_length_40	; max 64k length
		not cx
		movzx eax,cx
get_length_80:
		clc
get_length_90:
		ret


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
		call calloc
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


prim_pop:
		cmp word [pstack_ptr],byte 1
		mov bp,pserr_pstack_underflow
		jc prim_pop_90
		dec word [pstack_ptr]
prim_pop_90:
		ret

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


prim_exec:
		mov dl,t_dict_idx
		call pr_setobj_or_none
		mov [pscode_eval],eax
		ret


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


prim_sub:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jnc prim_sub_50
		cmp dx,t_int + (t_string << 8)
		jz prim_sub_50
		cmp dx,t_int + (t_ptr << 8)
		stc
		jnz prim_sub_90
prim_sub_50:
		xchg eax,ecx
		sub eax,ecx
		dec word [pstack_ptr]
		xor cx,cx
		mov dl,dh
		call set_pstack_tos
prim_sub_90:
		ret

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

prim_neg:
		mov dl,t_int
		call get_1arg
		jc prim_neg_90
		neg eax
		xor cx,cx
		call set_pstack_tos
prim_neg_90:
		ret

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


prim_and:
		call plog_args
		and eax,ecx
prim_and_50:
		dec word [pstack_ptr]
		xor cx,cx
		call set_pstack_tos
		ret

prim_or:
		call plog_args
		or eax,ecx
		jmp prim_and_50

prim_xor:
		call plog_args
		xor eax,ecx
		jmp prim_and_50

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

prim_eq:
		mov bl,1
		call pcmp_args
		cmp ecx,eax
		jz pcmp_true
		jmp pcmp_false

prim_ne:
		mov bl,1
		call pcmp_args
		cmp ecx,eax
		jnz pcmp_true
		jmp pcmp_false

prim_gt:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jg pcmp_true
		jmp pcmp_false

prim_ge:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jge pcmp_true
		jmp pcmp_false

prim_lt:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jl pcmp_true
		jmp pcmp_false

prim_le:
		mov bl,0
		call pcmp_args
		cmp ecx,eax
		jle pcmp_true
		jmp pcmp_false


prim_exch:
		mov cx,2
		call rot_pstack_up
		mov bp,pserr_pstack_underflow
		ret


prim_rot:
		mov cx,3
		call rot_pstack_up
		mov bp,pserr_pstack_underflow
		ret


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

prim_dtrace:
		mov byte [single_step],1
		mov byte [show_debug_info],1
		ret

prim_trace:
		mov byte [single_step],1
		mov byte [show_debug_info],0
		ret

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
		call get_length
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


prim_imagecolors:
		movzx eax,word [pals]
		jmp pr_getint


prim_setcolor:
		call pr_setint
		mov [gfx_color0],eax
		call setcolor
		ret


prim_currentcolor:
		mov eax,[gfx_color0]
		jmp pr_getint


prim_moveto:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_moveto_90
		sub word [pstack_ptr],byte 2
		mov [gfx_cur_x],cx
		mov [gfx_cur_y],ax
prim_moveto_90:
		ret


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


prim_putpixel:
		call goto_xy
		call screen_segs
		call [setpixel_t]
		clc
		ret


prim_getpixel:
		call goto_xy
		call screen_seg_r
		mov si,di
		xor eax,eax
		call [getpixel]
		jmp pr_getint


prim_setfont:
		call pr_setptr_or_none
		call font_init
		ret


prim_currentfont:
		push dword [font]
		call so2lin
		pop eax
		jmp pr_getptr_or_none


prim_fontheight:
		movzx eax,word [font_height]
		jmp pr_getint


prim_setimage:
		call pr_setptr_or_none
		call image_init
		ret


prim_currentimage:
		mov eax,[image]
		jmp pr_getptr_or_none


prim_settransparency:
		call pr_setint
		mov [transp],eax
		ret


prim_currenttransparency:
		mov eax,[transp]
		jmp pr_getint


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


prim_strsize:
		mov dl,t_string
		call get_1arg
		jc prim_strsize_90
		dec word [pstack_ptr]
		lin2segofs eax,es,si
		call str_size

		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_strsize_90
		mov [pstack_ptr],ax
		push dx
		movzx eax,cx
		mov dl,t_int
		mov cx,1
		call set_pstack_tos
		pop ax
		mov dl,t_int
		movzx eax,ax
		xor cx,cx
		call set_pstack_tos
prim_strsize_90:
		ret


prim_image:
		mov bp,pserr_pstack_underflow
		cmp word [pstack_ptr],byte 4
		jc prim_image_90
		mov cx,3
		call get_pstack_tos
		cmp dl,t_int
		stc
		mov bp,pserr_wrong_arg_types
		jnz prim_image_90
		mov [line_x0],eax
		mov cx,2
		push bp
		call get_pstack_tos
		pop bp
		cmp dl,t_int
		stc
		jnz prim_image_90
		mov [line_y0],eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_image_90

		sub word [pstack_ptr],byte 4

		; clip image width
		; note: image height is handled in draw_image
		mov edx,[line_x0]
		add edx,ecx
		movzx ebx,word [image_width]
		sub edx,ebx
		jle prim_image_40
		sub ecx,edx
prim_image_40:

		cmp ecx,byte 0
		jle prim_image_90
		cmp eax,byte 0
		jz prim_image_90
		mov [line_x1],ecx
		mov [line_y1],eax
		push dword [gfx_cur]
		call draw_image
		pop dword [gfx_cur]

		clc
prim_image_90:
		ret


prim_loadpalette:
		mov cx,100h
		xor dx,dx
		call load_palette
		clc
		ret

prim_tint:
		mov bp,pserr_pstack_underflow
		cmp  word [pstack_ptr],byte 3
		jc prim_tint_90
		mov bp,pserr_wrong_arg_types
		mov cx,2
		call get_pstack_tos
		cmp dl,t_int
		stc
		jnz prim_tint_90
		push ax
		mov dx,t_int + (t_int << 8)
		call get_2args
		pop dx
		jc prim_tint_90

		sub word [pstack_ptr],byte 3

		xchg ax,bx

		push cx
		push bx
		call tint
		pop dx
		pop cx

		call load_palette
		clc
prim_tint_90:
		ret


prim_settintcolor:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_settintcolor_90

		sub word [pstack_ptr],byte 2

		mov [gfx_cs_tint_b],al
		mov [gfx_cs_tint_g],ah
		shr eax,16
		mov [gfx_cs_tint_r],al
		mov [gfx_cs_b],cl
		mov [gfx_cs_g],ch
		shr ecx,16
		mov [gfx_cs_r],cl

		clc

prim_settintcolor_90:
		ret


prim_setpalette:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_setpalette_90

		sub word [pstack_ptr],byte 2

		cmp ecx,100h
		jae prim_setpalette_90

		push cx
		les di,[gfx_pal]
		add di,cx
		add di,cx
		add di,cx
		mov [es:di+2],al
		mov [es:di+1],ah
		shr eax,16
		mov [es:di],al
		pop dx
		mov cx,1
		call load_palette

		clc

prim_setpalette_90:
		ret


prim_getpalette:
		mov dl,t_int
		call get_1arg
		jc prim_getpalette_90

		xchg eax,ecx
		xor eax,eax
		cmp ecx,100h
		jae prim_getpalette_50

		les di,[gfx_pal]
		add di,cx
		add di,cx
		add di,cx
		mov al,[es:di]
		shl eax,16
		mov ah,[es:di+1]
		mov al,[es:di+2]
prim_getpalette_50:
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos
prim_getpalette_90:
		ret


prim_settransparentcolor:
		call pr_setint
		mov [transparent_color],ax
		ret


prim_savescreen:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_savescreen_90
		push ax
		push cx
		mul ecx
		mul dword [pixel_bytes]
		pop dx
		pop cx
		mov bp,pserr_invalid_image_size
		add eax,4
		jc prim_savescreen_90
		cmp eax,1 << 20
		cmc
		jc prim_savescreen_90
		push cx
		push dx
		call malloc
		pop dx
		pop cx
		or eax,eax
		jz prim_savescreen_50
		lin2segofs eax,es,di
		mov [es:di],dx
		mov [es:di+2],cx
		add di,4
		push eax
		call save_bg
		pop eax
prim_savescreen_50:
		dec word [pstack_ptr]
		xor cx,cx
		mov dl,t_ptr
		or eax,eax
		jnz prim_savescreen_70
		mov dl,t_none
prim_savescreen_70:
		call set_pstack_tos
prim_savescreen_90:
		ret


prim_restorescreen:
		mov dl,t_ptr
		call get_1arg
		jnc prim_restorescreen_20
		cmp dl,t_none
		stc
		jnz prim_restorescreen_90

		jmp prim_restorescreen_80

prim_restorescreen_20:
		cmp eax,100000h
		jb prim_restorescreen_50

		call real_to_pm
		jc prim_restorescreen_80

		mov dx,[es:eax]
		mov cx,[es:eax+2]

		call pm_to_real

		mov bx,dx
		imul bx,[pixel_bytes]
		lea edi,[eax+4]

		call xrestore_bg

		jmp prim_restorescreen_80
prim_restorescreen_50:
		lin2segofs eax,es,di
		mov dx,[es:di]
		mov cx,[es:di+2]
		add di,4
		mov bx,dx
		imul bx,[pixel_bytes]
		call restore_bg
prim_restorescreen_80:
		dec word [pstack_ptr]
		clc
prim_restorescreen_90:
		ret


prim_malloc:
		mov dl,t_int
		call get_1arg
		jc prim_malloc_90
		call calloc
		or eax,eax
		stc
		mov bp,pserr_no_memory
		jz prim_malloc_90
		xor cx,cx
		mov dl,t_ptr
		call set_pstack_tos
prim_malloc_90:
		ret


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
		dec word [pstack_ptr]
		clc
prim_free_90:
		ret


prim_memsize:
		mov ax,[pstack_ptr]
		inc ax
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_memsize_90
		mov [pstack_ptr],ax
		call memsize
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


prim_fillrect:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_fillrect_90
		mov dx,cx
		mov cx,ax
		mov eax,[gfx_color]
		call fill_rect
		sub word [pstack_ptr],byte 2
prim_fillrect_90:
		ret


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


prim_editinit:
		mov dx,t_string + (t_array << 8)
		call get_2args
		jc prim_editinit_90

		lin2segofs ecx,es,si
		push es
		push si
		push eax
		call edit_get_params
		pop eax
		pop ecx
		mov bp,pserr_invalid_data
		jc prim_editinit_90

		push dword [gfx_cur]
		push ecx
		lin2segofs eax,es,si
		call edit_init
		pop si
		pop es
		pop dword [gfx_cur]

		call edit_put_params

		sub word [pstack_ptr],byte 2
prim_editinit_90:
		ret


prim_editdone:
		mov dx,t_array
		call get_1arg
		jc prim_editdone_90

		lin2segofs eax,es,si
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_editdone_90

		push word [edit_x]
		pop word [gfx_cur_x]
		push word [edit_y]
		pop word [gfx_cur_y]
		mov dx,[edit_width]
		mov cx,[edit_height]
		les di,[edit_bg]
		add di,4
		mov bx,dx
		imul bx,[pixel_bytes]
		call restore_bg

		sub word [pstack_ptr],byte 1
prim_editdone_90:
		ret


prim_editshowcursor:
		mov dx,t_array
		call get_1arg
		jc prim_editshowcursor_90

		lin2segofs eax,es,si
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_editshowcursor_90

		push dword [gfx_cur]
		call edit_show_cursor
		pop dword [gfx_cur]

		sub word [pstack_ptr],byte 1
prim_editshowcursor_90:
		ret


prim_edithidecursor:
		mov dx,t_array
		call get_1arg
		jc prim_edithidecursor_90

		lin2segofs eax,es,si
		call edit_get_params
		mov bp,pserr_invalid_data
		jc prim_edithidecursor_90

		push dword [gfx_cur]
		call edit_hide_cursor
		pop dword [gfx_cur]

		sub word [pstack_ptr],byte 1
prim_edithidecursor_90:
		ret


prim_editinput:
		mov dx,t_int + (t_array << 8)
		call get_2args
		jc prim_editinput_90

		lin2segofs ecx,es,si
		push es
		push si
		push eax
		call edit_get_params
		pop eax
		pop ecx
		mov bp,pserr_invalid_data
		jc prim_editinput_90

		push dword [gfx_cur]
		push ecx
		push eax
		call edit_hide_cursor
		pop eax
		call edit_input
		call edit_show_cursor
		pop si
		pop es
		pop dword [gfx_cur]

		call edit_put_params

		sub word [pstack_ptr],byte 2
prim_editinput_90:
		ret


prim_updatedisk:
		call pr_setint
		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		mov [es:si+1],al
		ret


prim_bootloader:
		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		movzx eax,byte [es:si]
		jmp pr_getint


prim_bootdrive:
		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		movzx eax,byte [es:si+5]
		jmp pr_getint


prim_reloadfs:
		call pr_setint
		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		mov [es:si+6],al
		ret


prim_usernote:
		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		movzx eax,byte [es:si+7]
		jmp pr_getint


prim_getinfo:
		mov dl,t_int
		call get_1arg
		jc prim_getinfo_90
		mov dl,t_int
		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		shl ax,2
		add si,ax
		mov eax,[es:si+12]
		xor cx,cx
		call set_pstack_tos
prim_getinfo_90:
		ret


prim_getbyte:
		mov dl,t_ptr
		call get_1arg
		jc prim_getbyte_90
		lin2segofs eax,es,bx
		movzx eax,byte [es:bx]
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos
prim_getbyte_90:
		ret


prim_putbyte:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jc prim_putbyte_90
		lin2segofs ecx,es,bx
		mov [es:bx],al
		sub word [pstack_ptr],byte 2
prim_putbyte_90:
		ret


prim_getdword:
		mov dl,t_ptr
		call get_1arg
		jc prim_getdword_90
		lin2segofs eax,es,bx
		mov eax,[es:bx]
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos
prim_getdword_90:
		ret


prim_putdword:
		mov dx,t_int + (t_ptr << 8)
		call get_2args
		jc prim_putdword_90
		lin2segofs ecx,es,bx
		mov [es:bx],eax
		sub word [pstack_ptr],byte 2
prim_putdword_90:
		ret


prim_findfile:
		mov dl,t_string
		call get_1arg
		jc prim_findfile_90
		call find_file
		mov dl,t_ptr
		or eax,eax
		jnz prim_findfile_20
		mov dl,t_none
prim_findfile_20:
		xor cx,cx
		call set_pstack_tos
prim_findfile_90:
		ret


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

		mov cx,[screen_height]
		mov [clip_b],cx

		xor cx,cx

		mov [clip_l],cx
		mov [clip_t],cx

prim_setmode_80:
		mov dl,t_bool
		call set_pstack_tos
prim_setmode_90:
		ret


prim_currentmode:
		movzx eax,word [gfx_mode]
		jmp pr_getint


prim_findmode:
		mov bp,pserr_pstack_underflow
		cmp word [pstack_ptr],byte 3
		jc prim_findmode_90

		mov bp,pserr_wrong_arg_types
		mov cx,2
		call get_pstack_tos
		cmp dl,t_int
		stc
		jnz prim_findmode_90
		push eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		pop edx
		jc prim_findmode_90

		; eax: color
		; ecx: height
		; edx: width

		call find_mode
		jnc prim_findmode_50

		mov dl,t_none
		xor eax,eax

		jmp prim_findmode_60

prim_findmode_50:
		mov dl,t_int

prim_findmode_60:
		sub word [pstack_ptr],byte 2

		xor cx,cx
		call set_pstack_tos

prim_findmode_90:
		ret


prim_colorbits:
		movzx eax,byte [color_bits]
		jmp pr_getint


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

prim_strstr_40
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


prim_soundplay:


		call sound_init
		jc prim_splay_80
prim_splay_80:
		clc
prim_splay_90:
		ret


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

prim_modload:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_modload_90
		sub word [pstack_ptr],byte 2
		xchg eax,ecx

		; ecx file
		; eax player

		push dword [mem]
		call lin2so
		pop bx
		pop es
		cmp cl,[es:bx+fh_file_entries]
		cmc
		jc prim_modload_80

		xor esi,esi

		imul dx,cx,sizeof_file_raw_t
		add si,dx

		add si,sizeof_file_header_t
		add esi,[mem]

		push esi
		call lin2so
		pop si
		pop es

		mov ebx,[es:si+fi_raw_data]
		add ebx,[mem]

		; ebx: mod file
		; eax: player

		push eax
		push ebx
		call sound_init
		pop ebx
		pop eax
		jc prim_modload_80

		push ebx
		call lin2so
		pop di
		pop es

		call mod_load

prim_modload_80:
		clc
prim_modload_90:
		ret


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


prim_settextwrap:
		call pr_setint
		mov [line_wrap],ax
		ret


prim_currenttextwrap:
		movzx eax,word [line_wrap]
		jmp pr_getint


prim_seteotchar:
		call pr_setint
		mov [char_eot],eax
		ret


prim_currenteotchar:
		mov eax,[char_eot]
		jmp pr_getint


prim_setmaxrows:
		call pr_setint
		mov [max_rows],ax
		ret


prim_currentmaxrows:
		movzx eax,word [max_rows]
		jmp pr_getint


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


prim_gettextrows:
		movzx eax,word [cur_row2]
		jmp pr_getint


prim_setstartrow:
		call pr_setint
		mov [start_row],ax
		ret


prim_getlinks:
		movzx eax,word [cur_link]
		jmp pr_getint


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
		mov [gfx_color0],eax
		mov [gfx_color],eax
		mov cx,2
		push bp
		call get_pstack_tos
		pop bp
		cmp dl,t_int
		stc
		jnz prim_settextcolors_90
		mov [gfx_color1],eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_settextcolors_90

		sub word [pstack_ptr],byte 4

		mov [gfx_color2],ecx
		mov [gfx_color3],eax

		clc
prim_settextcolors_90:
		ret


prim_currenttextcolors:
		mov ax,[pstack_ptr]
		add ax,4
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_currenttextcolors_90
		mov [pstack_ptr],ax
		mov dl,t_int
		mov eax,[gfx_color3]
		xor cx,cx
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color2]
		mov cx,1
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color1]
		mov cx,2
		call set_pstack_tos
		mov dl,t_int
		mov eax,[gfx_color0]
		mov cx,3
		call set_pstack_tos
prim_currenttextcolors_90:
		ret


prim_setlink:
		call pr_setint
		mov dx,[cur_link]
		cmp ax,dx
		jae prim_setlink_90
		mov [sel_link],ax
prim_setlink_90:
		ret


prim_currentlink:
		movzx eax,word [sel_link]
		jmp pr_getint


;
; label, text, x, row
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


prim_lineheight:
		movzx eax,word [font_line_height]
		jmp pr_getint


prim_currenttitle:
		segofs2lin word [row_start_seg],word [page_title],eax
		mov dl,t_string
		jmp pr_getobj


prim_xsavescreen:
		mov dx,t_int + (t_int << 8)
		call get_2args
		jc prim_xsavescreen_90
		push ax
		push cx
		mul ecx
		pop dx
		pop cx
		mov bp,pserr_invalid_image_size
		add eax,4
		jc prim_xsavescreen_90
		cmp eax,1 << 20
		cmc
		jc prim_xsavescreen_90
		push cx
		push dx
		call xmalloc
		pop dx
		pop cx
		or eax,eax
		stc
		mov bp,pserr_no_memory
		jz prim_xsavescreen_90

		call real_to_pm
		jc prim_xsavescreen_50

		mov [es:eax],dx
		mov [es:eax+2],cx

		call pm_to_real

		push eax
		lea edi,[eax+4]
		call xsave_bg
		pop eax

prim_xsavescreen_50:
		dec word [pstack_ptr]
		xor cx,cx
		mov dl,t_ptr
		call set_pstack_tos
prim_xsavescreen_90:
		ret


prim_videomodes:
		mov ax,[pstack_ptr]
		inc ax
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_videomodes_90
		mov [pstack_ptr],ax

		mov es,[boot_cs]
		mov si,[boot_sysconfig]
		movzx cx,byte [es:si+4]
		mov si,[es:si+2]
		xor eax,eax
		or cx,cx
		jz prim_videomodes_40
prim_videomodes_20:
		cmp byte [es:si+fb_bits],0
		jz prim_videomodes_40
		add si,sizeof_fb_entry
		inc eax
		loop prim_videomodes_20
prim_videomodes_40:
		mov dl,t_int
		xor cx,cx
		call set_pstack_tos
prim_videomodes_90:
		ret


;
; mode, width, height, ok
prim_getvideomode:
		mov dl,t_int
		call get_1arg
		jc prim_getvm_90
		mov bp,pserr_invalid_range
		mov fs,[boot_cs]
		mov si,[boot_sysconfig]
		movzx ecx,byte [fs:si+4]
		cmp eax,ecx
		cmc
		jc prim_getvm_90
		imul di,ax,sizeof_fb_entry
		add di,[fs:si+2]

		mov ax,[pstack_ptr]
		add ax,3
		cmp [pstack_size],ax
		mov bp,pserr_pstack_overflow
		jb prim_getvm_90
		mov [pstack_ptr],ax

		mov dl,t_int
		movzx eax,word [fs:di+fb_mode]
		mov cx,3
		call set_pstack_tos

		mov dl,t_int
		movzx eax,word [fs:di+fb_width]
		mov cx,2
		call set_pstack_tos

		mov dl,t_int
		movzx eax,word [fs:di+fb_height]
		mov cx,1
		call set_pstack_tos

		mov dl,t_int
		movzx eax,byte [fs:di+fb_ok]
		xor cx,cx
		call set_pstack_tos
prim_getvm_90:
		ret


prim_usleep:
		call pr_setint

		mov ecx,54944/2
		add eax,ecx
		add ecx,ecx
		xor edx,edx
		div ecx
		or eax,eax
		jz prim_usleep_90
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


prim_time:
		call get_time
		jmp pr_getint


prim_setbrightness:
		call pr_setint
		mov [brightness],ax
		ret

prim_currentbrightness:
		movzx eax,word [brightness]
		jmp pr_getint


prim_fadein:
		mov dx,t_int + (t_string << 8)
		call get_2args
		jc prim_get_90

		sub word [pstack_ptr],byte 2

		lin2segofs ecx,es,bx
		call fade_in

		clc
prim_fadein_90:
		ret


prim_fade:
		mov bp,pserr_pstack_underflow
		cmp word [pstack_ptr],byte 3
		jc prim_fade_90
		mov bp,pserr_wrong_arg_types
		mov cx,2
		call get_pstack_tos
		cmp dl,t_string
		stc
		jnz prim_fade_90
		push eax
		mov dx,t_int + (t_int << 8)
		call get_2args
		pop edx
		jc prim_fade_90

		sub word [pstack_ptr],byte 3

		mov bp,ax
		mov ax,cx
		lin2segofs edx,es,bx
		call fade_one

		clc
prim_fade_90:
		ret


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

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Helper function that covers common cases.

; return eax as ptr on stack, returns undef if eax = 0
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
;
; ensure the cursor is always within the visible area
;
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
		and word [edit_shift],byte 0
		jmp edit_align_90
edit_align_50:
		sub cx,ax
		sub cx,byte 5		; still 5 pixel away?
		jge edit_align_90
		sub [edit_shift],cx
edit_align_90:
		ret





; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  es:bx	string
;  si		ptr to char (rel. to es:bx)
;
; return:
;  si		points to prev char
;
;  Changes no other regs.
;
utf8_prev:
		push ax
		or si,si
		jz utf8_prev_90
utf8_prev_50:
		dec si
		jz utf8_prev_90
		mov al,[es:bx+si]
		shr al,6
		cmp al,2
		jz utf8_prev_50
utf8_prev_90:
		pop ax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  es:bx	string
;  si		ptr to char (rel. to es:bx)
;
; return:
;  si		points to next char
;
;  Changes no other regs.
;
utf8_next:
		push ax
		cmp byte [es:bx+si],0
		jz utf8_next_90
utf8_next_50:
		inc si
		mov al,[es:bx+si]
		shr al,6
		cmp al,2
		jz utf8_next_50
utf8_next_90:
		pop ax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; eax		key (bits 0-23: key, 24-31: scan code)
;
edit_input:
		mov edx,eax
		shr edx,24
		and eax,1fffffh
		les si,[edit_buf]
		mov bx,si

		dec si
edit_input_10:
		inc si
		cmp byte [es:si],0
		jnz edit_input_10
		mov cx,si
		sub cx,bx
		; cx: string length

		mov si,[edit_buf_ptr]

		cmp dl,keyLeft
		jnz edit_input_20
		mov di,si
		call utf8_prev
		cmp di,si
		jz edit_input_90
		mov [edit_buf_ptr],si
		jmp edit_input_80
edit_input_20:
		cmp dl,keyRight
		jnz edit_input_21
		mov di,si
		call utf8_next
		cmp di,si
		jz edit_input_90
		mov [edit_buf_ptr],si
		jmp edit_input_80
edit_input_21:
		cmp dl,keyEnd
		jnz edit_input_22
		cmp byte [es:bx+si],0
		jz edit_input_90
		mov [edit_buf_ptr],cx
		jmp edit_input_80
edit_input_22:
		cmp dl,keyHome
		jnz edit_input_23
		or si,si
		jz edit_input_90
		and word [edit_buf_ptr],byte 0
		jmp edit_input_80
edit_input_23:
		cmp dl,keyDel
		jnz edit_input_30
edit_input_24:
		mov di,si
		call utf8_next
		cmp di,si
		jz edit_input_90
edit_input_25:
		mov al,[es:bx+si]
		mov [es:bx+di],al
		inc si
		inc di
		or al,al
		jnz edit_input_25
		jmp edit_input_80
edit_input_30:
		cmp eax,keyBS
		jnz edit_input_35
		mov di,si
		call utf8_prev
		cmp di,si
		jz edit_input_90
		mov [edit_buf_ptr],si
		jmp edit_input_24
edit_input_35:

		cmp eax,20h
		jb edit_input_90

		; reject chars we can't display
		pusha
		push es
		call char_width
		or cx,cx
		pop es
		popa
		jz edit_input_90

		push cx
		push bx
		push si
		call utf8_enc
		pop si
		pop bx
		pop ax

		mov dx,[edit_buf_len]
		sub dx,ax
		sub dx,cx
		jb edit_input_90
		cmp dx,1
		jb edit_input_90
		sub ax,[edit_buf_ptr]
		add [edit_buf_ptr],cx

		; ax: bytes to copy (excl. final 0)
		; cx: utf8 size

		push si
		add si,ax
		mov di,si
		add di,cx
		inc ax
edit_input_70:
		mov dl,[es:bx+si]
		mov [es:bx+di],dl
		dec si
		dec di
		dec ax
		jnz edit_input_70
		pop si

		mov di,utf8_buf
edit_input_75:
		mov al,[di]
		mov [es:bx+si],al
		inc di
		inc si
		dec cx
		jnz edit_input_75

edit_input_80:
		mov si,[edit_buf_ptr]
		mov al,0
		xchg al,[es:bx+si]
		push ax
		push si
		push bx
		push es
		mov si,bx
		call str_size
		pop es
		pop bx
		pop si
		pop ax
		xchg al,[es:bx+si]
		mov [edit_cursor],cx

		call edit_align
		
		call edit_redraw
edit_input_90:
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
edit_redraw:
		mov ax,[edit_x]
		sub ax,[edit_shift]
		mov [gfx_cur_x],ax
		mov ax,[edit_y]
		add ax,[edit_y_ofs]
		mov [gfx_cur_y],ax

		les si,[edit_buf]
edit_redraw_20:
		call utf8_dec
		or eax,eax
		jz edit_redraw_50
		push si
		push es
		call edit_char
		pop es
		pop si
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
		les di,[edit_bg]
		add di,4
		add di,bx
		sub di,ax
		call restore_bg
edit_redraw_90:
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write char at current cursor position.
;
;  eax		char
;  [edit_bg]	background pixmap
;
; return:
;  cursor position gets advanced
;
edit_char:
		push fs

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

		les di,[edit_bg]
		mov bx,[edit_width]
		imul bx,[pixel_bytes]
		add di,4
		mov ax,[edit_y_ofs]
		imul bx
		add di,ax
		mov cx,[gfx_cur_x]
		sub cx,[edit_x]
		imul cx,[pixel_bytes]
		add di,cx

		mov dx,[chr_width]
		mov cx,[font_height]

		call restore_bg

edit_char_80:
		pop eax

		call char_xy

		pop word [clip_l]
		pop word [clip_r]

edit_char_90:
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
edit_hide_cursor:
		les di,[edit_bg]
		add di,4
		mov ax,[edit_cursor]
		sub ax,[edit_shift]
		mov cx,ax
		imul cx,[pixel_bytes]
		add di,cx
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
edit_show_cursor:
		call screen_segs

		mov ax,[edit_cursor]
		sub ax,[edit_shift]
		add ax,[edit_x]
		mov [gfx_cur_x],ax
		push word [edit_y]
		pop word [gfx_cur_y]
		mov cx,[edit_height]
edit_show_cursor_10:
		push cx
		call goto_xy
		call [setpixel_t]
		pop cx
		inc word [gfx_cur_y]
		loop edit_show_cursor_10
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; es:si		initial text
;
edit_init:
		push fs
		push es
		pop fs
		xor cx,cx
		mov [edit_shift],cx
		les di,[edit_buf]
edit_init_10:
		fs lodsb
		or al,al
		jz edit_init_20
		stosb
		inc cx
		cmp cx,[edit_buf_len]
		jb edit_init_10
		dec cx
		dec di
edit_init_20:
		mov byte [es:di],0
		mov [edit_buf_ptr],cx

		mov si,[edit_buf]
		call str_size
		mov [edit_cursor],cx

		call edit_align

		call edit_redraw
		call edit_show_cursor
edit_init_90:
		pop fs
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; es:si		parameter array
;
; note: no consistency checks done, es:si _must_ point to
; a valid array
;
edit_put_params:
		push word [edit_buf_ptr]
		pop word [es:si+2+5*5+1]
		
		push word [edit_cursor]
		pop word [es:si+2+5*6+1]
		
		push word [edit_shift]
		pop word [es:si+2+5*7+1]

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
;  es:si	parameter array
;
; return:
;  CF		invalid data
;
edit_get_params:
		es lodsw
		cmp ax,8
		jc edit_get_params_90

		cmp byte [es:si+5*0],t_int
		jnz edit_get_params_80
		push word [es:si+5*0+1]
		pop word [edit_x]

		cmp byte [es:si+5*1],t_int
		jnz edit_get_params_80
		push word [es:si+5*1+1]
		pop word [edit_y]
		
		cmp byte [es:si+5*2],t_ptr
		jnz edit_get_params_80
		push dword [es:si+5*2+1]
		call lin2so
		pop dword [edit_bg]
		
		cmp byte [es:si+5*3],t_string
		jnz edit_get_params_80
		push dword [es:si+5*3+1]
		call lin2so
		pop dword [edit_buf]
		
		cmp byte [es:si+5*4],t_int
		jnz edit_get_params_80
		push word [es:si+5*4+1]
		pop word [edit_buf_len]
		
		cmp byte [es:si+5*5],t_int
		jnz edit_get_params_80
		push word [es:si+5*5+1]
		pop word [edit_buf_ptr]
		
		cmp byte [es:si+5*6],t_int
		jnz edit_get_params_80
		push word [es:si+5*6+1]
		pop word [edit_cursor]
		
		cmp byte [es:si+5*7],t_int
		jnz edit_get_params_80
		push word [es:si+5*7+1]
		pop word [edit_shift]
		
		les si,[edit_bg]
		es lodsw
		mov [edit_width],ax
		es lodsw
		mov [edit_height],ax

		mov cx,[font_height]
		sub ax,cx
		sar ax,1
		mov [edit_y_ofs],ax

		cmp word [edit_buf_len],byte 2		; at least 1 char
		jc edit_get_params_90

		movzx eax,word [edit_width]
		movzx ecx,word [edit_height]
		mul ecx
		cmp eax,10000h-20
		jae edit_get_params_80			; to large: max 64k

		clc
		jmp edit_get_params_90

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
inc_winseg:
		push ax
		mov al,[cs:mapped_window]
		inc al
		call set_win
		pop ax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; map window segment
;
; 	al	= window segment
;
set_win:
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
		ret



; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Go to current cursor position.
;
; return:
;  di		offset
;  correct gfx segment is mapped
;
; Notes:
;  - changes no regs other than di
;  - does not require ds == cs
;
goto_xy:
		push ax
		push dx
		mov ax,[cs:gfx_cur_y]
		mov di,[cs:gfx_cur_x]
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
setcolor:
		call encode_color
		mov [gfx_color],eax
		ret


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


;  ax		palette index
;
; return:
;  eax		color
;
pal_to_color:
		push fs
		push si
		lfs si,[gfx_pal]
		add si,ax
		add si,ax
		add si,ax
		mov eax,[fs:si]
		bswap eax
		shr eax,8
		pop si
		pop fs
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; draw a line
;
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
		jmp [setpixel_t]


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Set pixel at es:di.
;
setpixel_8:
		mov al,[gfx_color]

setpixel_a_8:
		mov [es:di],al
		ret

setpixel_16:
		mov ax,[gfx_color]

setpixel_a_16:
		mov [es:di],ax
		ret

setpixel_32:
		mov eax,[gfx_color]

setpixel_a_32:
		mov [es:di],eax
		ret


; with transparency
setpixel_t_16:
		mov ax,[gfx_color]

setpixel_ta_16:
		mov [es:di],ax
		ret

setpixel_t_32:
		mov eax,[gfx_color]

setpixel_ta_32:
		cmp word [transp],0
		jz setpixel_a_32
		push ecx
		mov ecx,[fs:di]
		ror ecx,16
		ror eax,16
		call add_transp
		rol ecx,8
		rol eax,8
		call add_transp
		rol ecx,8
		rol eax,8
		call add_transp
		mov [es:di],ecx
		pop ecx
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
;
; Get pixel from fs:si.
;
getpixel_8:
		mov al,[fs:si]
		ret

getpixel_16:
		mov ax,[fs:si]
		ret

getpixel_32:
		mov eax,[fs:si]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Initialize font.
;
; eax		linear ptr to font header
;
font_init:
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
		push es
		push bx
		pop dword [font]
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
		call is_eot
		jz text_xy_05
		inc word [cur_row2]
text_xy_05:
		push word [gfx_cur_x]
text_xy_10:
		mov di,si
		call utf8_dec

		call is_eot
		jz text_xy_90

		cmp word [line_wrap],byte 0
		jz text_xy_60

		call is_space
		jnz text_xy_60

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

		call is_eot
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
		call char_xy
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

word_width_10:
		call utf8_dec

word_width_20:
		call is_eot
		jz word_width_90

		cmp eax,0ah
		jz word_width_90

		cmp eax,12h
		jnz word_width_30
		mov bl,1
word_width_30:
		cmp eax,10h
		jz word_width_40
		cmp eax,13h
		jnz word_width_50
word_width_40:
		mov bl,0
word_width_50:

		or bl,bl
		jnz word_width_70

		push eax
		push bx
		push dx
		push si
		push es
		call char_width
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
;
; Test for end of text.
;
;  eax		char
;
; return:
;  ZF		0 = no, 1 = yes
;
is_eot:
		or eax,eax
		jz is_eot_90
		cmp eax,[char_eot]
is_eot_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Get string dimensions (in pixel).
;
;  es:si	ASCIIZ string
;
; return:
;  cx		width
;  dx		height
;
str_size:
		xor cx,cx
		xor dx,dx
str_size_20:
		push cx
		push dx
		call str_len
		xchg ax,cx
		pop dx
		pop cx
		cmp ax,cx
		jb str_size_40
		mov cx,ax
str_size_40:
		inc dx

		; suppress final line break
		call utf8_dec
		cmp eax,0ah
		jnz str_size_60
		cmp byte [es:si],0
		jz str_size_80
str_size_60:
		or eax,eax
		jz str_size_80
		cmp eax,[char_eot]
		jz str_size_80
		jmp str_size_20
str_size_80:
		dec dx
		mov ax,[font_line_height]
		mul dx
		mov dx,[font_height]
		add dx,ax
str_size_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Get string length (in pixel).
; *** Use str_size instead. ***
;
;  es:si	ASCIIZ string
;
; return:
;  cx		width
;  es:si	points to string end or line break
;
; notes:
;  - stops at linebreak ('\n')
;
str_len:
		xor cx,cx
str_len_10:
		mov di,si
		call utf8_dec
		or eax,eax
		jz str_len_70
		cmp eax,[char_eot]
		jz str_len_70
		cmp eax,0ah
		jz str_len_70
		push cx
		push si
		push es
		call char_width
		pop es
		pop si
		pop ax
		add cx,ax
		jmp str_len_10
str_len_70:
		mov si,di
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
;
; Encode utf8 char.
;
;  eax		char
;
; return:
;  cx		length
;  utf8_buf	char
;
utf8_enc:
		mov si,utf8_buf
		xor cx,cx
		xor dx,dx

		cmp eax,80h
		jae utf8_enc_10
		mov [si],al
		inc si
		jmp utf8_enc_80
utf8_enc_10:
		inc cx
		cmp eax,800h
		jae utf8_enc_20
		shl eax,21
		mov dl,6
		shld edx,eax,5
		shl eax,5
		jmp utf8_enc_60
utf8_enc_20:
		inc cx
		cmp eax,10000h
		jae utf8_enc_30
		shl eax,16
		mov dl,0eh
		shld edx,eax,4
		shl eax,4
		jmp utf8_enc_60
utf8_enc_30:
		inc cx
		cmp eax,200000h
		jae utf8_enc_40
		shl eax,11
		mov dl,1eh
		shld edx,eax,3
		shl eax,3
		jmp utf8_enc_60
utf8_enc_40
		inc cx
		cmp eax,4000000h
		jae utf8_enc_50
		shl eax,6
		mov dl,3eh
		shld edx,eax,2
		shl eax,2
		jmp utf8_enc_60
utf8_enc_50:
		inc cx
		shl eax,1
		mov dl,7eh
		shld edx,eax,1
		add eax,eax
utf8_enc_60:
		mov bx,cx
		mov [si],dl
		inc si
utf8_enc_70:
		mov dl,2
		shld edx,eax,6
		shl eax,6
		mov [si],dl
		inc si
		dec bx
		jnz utf8_enc_70
utf8_enc_80:
		mov byte [si],0
		inc cx
utf8_enc_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Write a char at the current cursor position.
;
;  eax		char
;
; return:
;  cursor position gets advanced
;
char_xy:
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

		call goto_xy

		call screen_segs

		lgs si,[font]
		add si,[chr_bitmap]

		cmp byte [chr_real_width],0
		jz char_xy_70
		cmp byte [chr_real_height],0
		jz char_xy_70

		xor dx,dx
		xor bp,bp

char_xy_20:
		xor cx,cx
char_xy_30:
		bt [gs:si],bp
		jnc char_xy_40
		mov ax,[gfx_cur_x]
		add ax,cx
		cmp ax,[clip_r]
		jge char_xy_40
		cmp ax,[clip_l]
		jl char_xy_40
		call [setpixel_t]
char_xy_40:
		inc bp
		add di,[pixel_bytes]
		jnc char_xy_50
		call inc_winseg
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
		call inc_winseg
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
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Look for char in font.
;
;  eax		char
;
; return:
;  CF		0 = found, 1 = not found
;  [chr_*]	updated
;
find_char:
		and eax,1fffffh
		cmp dword [font],byte 0
		stc
		jz find_char_90

		les bx,[font]
		add bx,sizeof_font_header_t
		mov cx,[font_entries]

find_char_20:
		mov si,cx
		shr si,1

		shl si,3
		mov edx,[es:bx+si+ch_c]
		and edx,1fffffh		; 21 bits
		cmp eax,edx

		jz find_char_80

		jl find_char_50

		add bx,si
		test cl,1
		jz find_char_50
		add bx,sizeof_char_header_t
find_char_50:
		shr cx,1
		jnz find_char_20

		stc
		jmp find_char_90

find_char_80:
		mov dx,[es:bx+si+ch_ofs]
		mov [chr_bitmap],dx
		mov edx,[es:bx+si+ch_size]

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
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; 
; Get char width.
;
;  eax		char
;
; return:
;  eax		char
;  cx		char width
;
char_width:
		push eax
		cmp eax,1fh		; \x1f looks like a space, but isn't
		jnz char_width_10
		mov al,' '
char_width_10:
		call find_char
		mov cx,0
		jc char_width_90
		mov cx,[chr_width]
char_width_90:
		pop eax
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Draw part of an image.
;
draw_image:
		push gs
		push fs

		mov es,[window_seg_w]

		lin2segofs dword [pcx_line_starts],gs,bp

		mov ax,[line_y0]
		cmp ax,[image_height]
		jae draw_image_90

		mov bx,ax
		add ax,[line_y1]	; length!
		sub ax,[image_height]
		jbe draw_image_10
		sub [line_y1],ax
draw_image_10:
		shl bx,2
		add bp,bx

draw_image_20:
		call goto_xy

		lfs si,[gs:bp]

		mov cx,[line_x0]
		neg cx

		; draw one line
draw_image_30:
		fs lodsb

		mov ah,0
		cmp al,0c0h
		jb draw_image_70

		; repeat count

		and ax,3fh
		mov dx,ax
		fs lodsb

		add cx,dx
		js draw_image_80
		jnc draw_image_40
		mov dx,cx

draw_image_40:
		mov bx,cx
		sub bx,[line_x1]
		jle draw_image_50
		sub dx,bx
draw_image_50:
		or dx,dx
		jz draw_image_80
		dec dx
		cmp ax,[transparent_color]
		jz draw_image_55
		cmp byte [pixel_bytes],1
		jbe draw_image_54
		push ax
		call pal_to_color
		call encode_color
		call [setpixel_a]
		pop ax
		jmp draw_image_55
draw_image_54:
		mov [es:di],al
draw_image_55:
		add di,[pixel_bytes]
		jnc draw_image_50
		call inc_winseg
		jmp draw_image_50

draw_image_70:
		inc cx
		cmp cx,byte 0
		jle draw_image_80
		cmp ax,[transparent_color]
		jz draw_image_75
		cmp byte [pixel_bytes],1
		jbe draw_image_74
		call pal_to_color
		call encode_color
		call [setpixel_a]
		jmp draw_image_75
draw_image_74:
		mov [es:di],al
draw_image_75:
		add di,[pixel_bytes]
		jnc draw_image_80
		call inc_winseg
draw_image_80:
		cmp cx,[line_x1]
		jl draw_image_30

		inc word [gfx_cur_y]

		add bp,4
		dec word [line_y1]
		jnz draw_image_20

draw_image_90:
		pop fs
		pop gs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Get some memory for palette data
;
pal_init:
		mov eax,300h
		call calloc
		push eax
		call lin2so
		pop dword [gfx_pal]
		or eax,eax
		stc
		jz pal_init_90
		mov eax,300h
		call calloc
		push eax
		call lin2so
		pop dword [gfx_pal_tmp]
		or eax,eax
		stc
		jz pal_init_90
		clc
pal_init_90:		
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Load palette data.
;
; cx		number of palettes
; dx		start
;
load_palette:
		push fs

		cmp byte [pixel_bytes],1
		ja load_palette_90

		cmp dx,100h
		jae load_palette_90

		mov ax,dx
		add ax,cx
		sub ax,100h
		jbe load_palette_10
		sub cx,ax
load_palette_10:
		or cx,cx
		jz load_palette_90

		mov ax,dx
		add ax,dx
		add ax,dx

		push dx
		push cx

		; vga function wants 6 bit values

		lfs si,[gfx_pal]
		les di,[gfx_pal_tmp]
		add si,ax
		add di,ax

		imul cx,cx,3
		mov dx,di
		push dx
load_palette_50:
		fs lodsb
		mov ah,0
		mul word [brightness]
		shr ax,10
		stosb
		loop load_palette_50

		pop dx
		pop cx
		pop bx


%if 0
		mov si,dx
		mov dx,3dah
		cli
load_palette_60:
		in al,dx
		test al,8
		jnz load_palette_60
load_palette_70:
		in al,dx
		test al,8
		jz load_palette_70
		cli
		imul cx,cx,3
		mov dx,3c8h
		xchg ax,bx
		out dx,al
		inc dx
		es rep outsb
		sti
%else
		mov ax,1012h
		int 10h
%endif

load_palette_90:
		pop fs
		ret


; es:bx		colors
; ax		ref color
;
fade_in:
		xor bp,bp

fade_in_20:
		push bx
		push ax

		mov dx,3dah
fade_in_30:
		in al,dx
		test al,8
		jnz fade_in_30
fade_in_40:
		in al,dx
		test al,8
		jz fade_in_40

		pop ax
		pop bx

		push bx
		push ax
		call fade_one
		pop ax
		pop bx

		add bp,4

		cmp bp,100h
		jbe fade_in_20

		ret


; es:bx		colors
; ax		ref color
; bp		step (0 - 100h)
;
fade_one:
		push fs

		lfs si,[gfx_pal]
		mov di,si
		imul ax,ax,3
		add di,ax

		mov dx,3c8h
		xor cx,cx
fade_one_30:
		cmp byte [es:bx],0
		jz fade_one_70

		mov al,cl
		out dx,al

		inc dx

		mov al,[fs:di]
		mov ah,[fs:si]
		call fade_it
		shr al,2
		out dx,al

		mov al,[fs:di+1]
		mov ah,[fs:si+1]
		call fade_it
		shr al,2
		out dx,al

		mov al,[fs:di+2]
		mov ah,[fs:si+2]
		call fade_it
		shr al,2
		out dx,al

		dec dx
fade_one_70:
		inc bx
		add si,3
		inc cx
		cmp cx,100h
		jb fade_one_30

fade_one_90:
		pop fs
		ret


; al		old color
; ah		new color
; bp		step (0 - 100h)
;
; return:
;  al		color
fade_it:
		push cx
		push dx
		push bp

		push ax
		movzx ax,ah
		mul bp
		mov cx,ax
		sub bp,100h
		neg bp
		pop ax
		mov ah,0
		mul bp
		add ax,cx
		mov al,ah

		pop bp
		pop dx
		pop cx
		ret

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
parse_img:
		push fs
		mov eax,[pcx_line_starts]
		or eax,eax
		jz parse_img_10
		call free
parse_img_10:
		movzx eax,word [image_height]
		shl eax,2
		call calloc
		or eax,eax
		stc
		mov [pcx_line_starts],eax
		jz parse_img_90
		lin2segofs eax,es,di
		lfs si,[image_data]

		xor dx,dx		; y count

parse_img_20:
		xor cx,cx		; x count
		mov [es:di],si
		mov [es:di+2],fs
		add di,4
parse_img_30:
		fs lodsb
		cmp al,0c0h
		jb parse_img_40
		and ax,3fh
		inc si
		add cx,ax
		dec cx
parse_img_40:
		inc cx
		cmp cx,[image_width]
		jb parse_img_30
		stc
		jnz parse_img_90		; no decoding break at line end?

		; normalize fs:si
		mov bp,si
		and si,0fh
		shr bp,4
		mov ax,fs
		add ax,bp
		mov fs,ax

		inc dx
		cmp dx,[image_height]
		jb parse_img_20

parse_img_90:
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; cx		colors
; dx		src
; bx		dst
;
tint:
		push fs

		; ensure we don't exceed bounds
		cmp dx,100h
		jae tint_90
		cmp bx,100h
		jae tint_90

		mov ax,dx
		cmp dx,bx
		jae tint_10
		mov ax,bx
tint_10:
		add ax,cx
		sub ax,100h
		jb tint_20
		sub cx,ax
tint_20:
		or cx,cx
		jz tint_90

		lfs si,[gfx_pal]
		les di,[gfx_pal_tmp]

		imul ax,dx,3
		add si,dx
		imul ax,bx,3
		add di,ax
		imul cx,cx,3
		push ax
		push cx

		xor bx,bx

tint_40:
		movzx ax,byte [gfx_cs_r + bx]
		fs movzx bp,byte [si]
		inc si
		sub ax,bp
		push bp
		movzx dx,byte [gfx_cs_tint_r + bx]
		imul dx
		mov bp,0ffh		; 100
		idiv bp
		pop bp
		add ax,bp
		jns tint_50
		xor ax,ax
tint_50:
		or ah,ah
		jz tint_60
		mov ax,0ffh
tint_60:
		stosb
		inc bx
		cmp bx,3
		jb tint_70
		xor bx,bx
tint_70:
		loop tint_40

		pop cx
		pop ax

		lfs si,[gfx_pal_tmp]
		les di,[gfx_pal]

		add di,ax
		add si,ax
		fs rep movsb
tint_90:
		pop fs
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
; save a screen region
;
;		dx,cx	= width, height
;		es:di	= buffer
;
save_bg:
		push fs

		push es
		push di

		call goto_xy

		call screen_seg_r

		mov si,di
		pop di
		pop es

		or cx,cx
		jz save_bg_90
		or dx,dx
		jz save_bg_90

		imul dx,[pixel_bytes]

save_bg_20:
		push dx
save_bg_30:
		mov al,[fs:si]
		inc si
		jnz save_bg_40
		call inc_winseg
save_bg_40:
		mov [es:di],al
		inc di
		jnz save_bg_50
		mov bp,es
		add bp,1000h
		mov es,bp
save_bg_50:
		dec dx
		jnz save_bg_30
		pop dx
		mov ax,[screen_line_len]
		sub ax,dx
		add si,ax
		jnc save_bg_60
		call inc_winseg
save_bg_60:
		dec cx
		jnz save_bg_20

save_bg_90:
		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Restore a screen region.
;
;  dx,cx	width, height
;  bx		bytes per line
;  es:di	buffer
;
; Does not change cursor positon.
;
restore_bg:
		push fs

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

		push es
		push di
		call so2lin
		add [esp],ecx
		call lin2so
		pop di
		pop es

		mov dx,[gfx_width]
		mov cx,[gfx_height]

		push es
		push di

		call goto_xy

		call screen_seg_w
		
		pop si
		pop fs

		imul dx,[pixel_bytes]

restore_bg_20:
		push dx
restore_bg_30:
		mov al,[fs:si]
		inc si
		jnz restore_bg_40
		mov bp,fs
		add bp,1000h
		mov fs,bp
restore_bg_40:
		mov [es:di],al
		inc di
		jnz restore_bg_50
		call inc_winseg
restore_bg_50:
		dec dx
		jnz restore_bg_30
		pop dx
		mov ax,[screen_line_len]
		sub ax,dx
		add di,ax
		jnc restore_bg_60
		call inc_winseg
restore_bg_60:
		mov ax,bx
		sub ax,dx
		add si,ax
		jnc restore_bg_70
		mov bp,fs
		add bp,1000h
		mov fs,bp
restore_bg_70:
		dec cx
		jnz restore_bg_20

restore_bg_90:
		pop dword [gfx_cur]

		pop fs
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Save a screen region to extended memory.
;
;  dx,cx	width, height
;  edi		buffer (linear address)
;
xsave_bg:
		push edi

		call goto_xy
		mov ax,[window_seg_w]
		cmp word [window_seg_r],byte 0
		jz xsave_bg_10
		mov ax,[window_seg_r]
xsave_bg_10:
		segofs2lin ax,di,esi

		pop edi

		or cx,cx
		jz xsave_bg_90
		or dx,dx
		jz xsave_bg_90

		call real_to_pm

xsave_bg_20:
		push dx
xsave_bg_30:
		mov al,[es:esi]
		inc si
		jnz xsave_bg_40
		call pm_to_real
		call inc_winseg
		call real_to_pm
xsave_bg_40:
		mov [es:edi],al
		inc edi
		dec dx
		jnz xsave_bg_30
		pop dx
		mov ax,[screen_line_len]
		sub ax,dx
		add si,ax
		jnc xsave_bg_60
		call pm_to_real
		call inc_winseg
		call real_to_pm
xsave_bg_60:
		dec cx
		jnz xsave_bg_20

		call pm_to_real

xsave_bg_90:
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Restore a screen region from extended memory.
;
;  dx,cx	width, height
;  bx		bytes per line
;  edi		buffer (linear address)
;
;  note:
;    bx must be >= dx
;
; Does not change cursor positon.
;
xrestore_bg:
		push dword [gfx_cur]

		mov [gfx_width],dx
		mov [gfx_height],cx

		call clip_it
		jc restore_bg_90

		mov dx,[gfx_width]
		mov cx,[gfx_height]

		push edi

		call goto_xy
		segofs2lin word [window_seg_w],di,edi
		
		pop esi

		or cx,cx
		jz xrestore_bg_90
		or dx,dx
		jz xrestore_bg_90

		call real_to_pm

xrestore_bg_20:
		push dx
xrestore_bg_30:
		mov al,[es:esi]
		inc esi
		mov [es:edi],al
		inc di
		jnz xrestore_bg_50
		call pm_to_real
		call inc_winseg
		call real_to_pm
xrestore_bg_50:
		dec dx
		jnz xrestore_bg_30
		pop dx
		mov ax,[screen_line_len]
		sub ax,dx
		add di,ax
		jnc xrestore_bg_60
		call pm_to_real
		call inc_winseg
		call real_to_pm
xrestore_bg_60:
		movzx eax,bx
		sub ax,dx
		add esi,eax
		dec cx
		jnz xrestore_bg_20

		call pm_to_real

xrestore_bg_90:
		pop dword [gfx_cur]

		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Load screen segments. Write segment to es, read segment to fs.
;
; Modified registers: -
;
screen_segs:
		call screen_seg_w
		jmp screen_seg_r


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Load write segment to es.
;
; Modified registers: -
;
screen_seg_w:
		mov es,[window_seg_w]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
;
; Load read segment to fs.
;
; Modified registers: -
;
screen_seg_r:
		cmp word [window_seg_r],0
		jz screen_seg_r_10
		mov fs,[window_seg_r]
		ret
screen_seg_r_10:
		mov fs,[window_seg_w]
		ret


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; draw a filled rectangle
;
;		dx, cx	= width, height
;  eax		color
;		bh,bl	= bh -> bl
;		bp	= drawing mode
;			  0: move, 1: add, 2,3: dto, except for bh (bh->bl)
;
fill_rect:
		mov [gfx_width],dx
		mov [gfx_height],cx

		call clip_it
		jc fill_rect_90

		mov dx,[gfx_width]
		mov cx,[gfx_height]

		call goto_xy

		call screen_segs

		mov bp,[screen_line_len]
		push dx
		mov ax,dx
		xor dx,dx
		mul word [pixel_bytes]
		sub bp,ax
		pop dx

fill_rect_20:
		mov bx,dx
fill_rect_30:
		call [setpixel_t]
		add di,[pixel_bytes]
		jnc fill_rect_60
		call inc_winseg
fill_rect_60:
		dec bx
		jnz fill_rect_30

		add di,bp
		jnc fill_rect_80
		call inc_winseg
fill_rect_80:
		dec cx
		jnz fill_rect_20

fill_rect_90:
		ret	


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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

sound_init:
		cmp byte [sound_ok],0
		jnz sound_init_90

		call chk_tsc
		jc sound_init_90

		mov eax,ar_sizeof
		call calloc
		cmp eax,byte 1
		jc sound_init_90
		push eax
		call lin2so
		pop dword [mod_buf]

		call mod_init

		mov eax,sound_buf_size
		call calloc
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
		call free

		push dword [sound_buf]
		call so2lin
		pop eax
		call free

sound_done_90:
		ret


; eax: new sample rate
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


; see if we have a time stamp counter
chk_tsc:
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
		jz chk_tsc_90
		mov eax,1
		cpuid
		test dl,1 << 4
		jnz chk_tsc_90
		stc
chk_tsc_90:
		ret


