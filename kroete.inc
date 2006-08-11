		bits 32

; must be large enough, else we will get evil memory corruptions
kroete.width    equ 520
kroete.height   equ 236

;  esi			kroete data
;  edi			drawing buffer
;  [idle.data2]		direction (0 forward, != 0 backward)

kroete:
		movzx eax,word [es:edi]		; width

		mov edx,[pixel_bytes]
		imul edx,eax
		mov [tmp_var_0],edx

		movzx edx,word [es:edi+2]	; height
		inc edx
		mul edx
		shr eax,1
		mul dword [pixel_bytes]
		add edi,4
		add edi,eax

		; edi: start offset into buffer

		call [getpixel]

		cmp byte [idle.data2],0
		jnz sul3
		lea ebp,[esi+16384]
sul:
		mov bl,[es:esi]
		rol bl,2
		call doit
		rol bl,2
		call doit
		rol bl,2
		call doit
		rol bl,2
		call doit
		inc esi
		cmp esi,ebp
		jnz sul
		jmp sul5

sul3:
		lea ebp,[esi-1]
		add esi,16383
sul4:
		mov bl,[es:esi]
		xor bl,0xaa
		call doit
		ror bl,2
		call doit
		ror bl,2
		call doit
		ror bl,2
		call doit
		dec esi
		cmp esi,ebp
		jnz sul4
sul5:
		call [setpixel_a]
		ret

doit:
		xchg eax,edx
		call [getpixel]
		xchg eax,edx
		call [setpixel_a]
		xchg eax,edx

		mov edx,ebx
		and edx,3
		jmp [doit_tab+4*edx]

doit0:
		sub edi,[pixel_bytes]
		ret

doit1:
		sub edi,[tmp_var_0]
		ret

doit2:
		add edi,[pixel_bytes]
		ret

doit3:
		add edi,[tmp_var_0]
		ret

		align 4, db 0
doit_tab	dd doit0, doit1, doit2, doit3

