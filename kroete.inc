;	es:si	pointer to data
;	bx	== 0 forward  != 0 backward
kroete:
	mov	fs,[window_seg_w]
	mov	ax,[window_seg_r]
	or	ax,ax
	jnz	sul1
	mov	ax,[window_seg_w]
sul1:	mov	gs,ax
	mov	di,[cs:screen_width]
	shr	di,1
	imul	di,[cs:pixel_bytes]
	mov	ax,[cs:screen_height]
	shr	ax,1
	mul	word [cs:screen_line_len]
	add	di,ax
	adc	dx,byte 0
	mov	ax,dx
	call	set_win
	call	kr_getpixel
	or	bx,bx
	jnz	sul3
	lea	bp,[si+16384]
sul:	mov	bl,[es:si]
	rol	bl,2
	call	doit
	rol	bl,2
	call	doit
	rol	bl,2
	call	doit
	rol	bl,2
	call	doit
	inc	si
	cmp	si,bp
	jnz	sul
	call	kr_putpixel
      	ret
sul3:	lea	bp,[si-1]
	add	si,16383
sul4:	mov	bl,[es:si]
	xor	bl,0xaa
	call	doit
	ror	bl,2
	call	doit
	ror	bl,2
	call	doit
	ror	bl,2
	call	doit
	dec	si
	cmp	si,bp
	jnz	sul4
	call	kr_putpixel
	ret
doit:
	push	ecx
	call	kr_getpixel
	mov	edx,ecx
	pop	ecx
	call	kr_putpixel
	mov	ecx,edx
	mov	dl,bl
	and	dl,3
	jnz	doit1
	sub	di,[cs:pixel_bytes]
	jnc	doit4
doit5:	sbb	al,0
	jmp	set_win
doit1:	dec	dl
	jnz	doit2
	sub	di,[cs:screen_line_len]
	jc	doit5
doit4:	ret
doit2:	dec	dl
	jnz	doit3
	add	di,[cs:pixel_bytes]
	jnc	doit4
doit6:	adc	al,0
	jmp	set_win
doit3:  add	di,[cs:screen_line_len]
	jc	doit6
	ret

kr_getpixel:
	cmp byte [cs:pixel_bytes],1
	ja kr_getpixel_10
	mov cl,[fs:di]
	ret
kr_getpixel_10:
	mov cx,[fs:di]
	ret

kr_putpixel:
	cmp byte [cs:pixel_bytes],1
	ja kr_putpixel_10
	mov [gs:di],cl
	ret
kr_putpixel_10:
	mov [gs:di],cx
	ret

