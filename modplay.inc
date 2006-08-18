; MOD player  (c) 2002 mls
;
; generates samples for 11000 HZ
; bpm always 125


%if 0
	init
	loadmod
	play
	playmod
	playsamp
	setvol
	getvol
	getstate
	stop
%endif

; pl_loadmod - configure a mod player
;   ds:si  start of player
;   es:di  start of mod
; si,di must be reasonable small ;)
pl_loadmod:
	pushad
	push	si
	add	si, pl_state
	xor	ax, ax
	mov	cx, pl_sizeof - pl_state
sm1:	mov	[si], al
	inc	si
	loop	sm1
	pop	si
	mov	[si + pl_seg], es
	mov	dx, si
	mov	cx, 4
	push	si
	add	si, pl_channs
sm10:	mov	[si + ch_player], dx
	add	si, ch_sizeof
	loop	sm10
	pop	si
	mov	dx, 32
	mov	eax, [es:di + 0x438]
	cmp	eax, 'CHN4'
	jz	sm2
	cmp	eax, 'M.K.'
	jz	sm2
	cmp	eax, 'M&K!'
	jz	sm2
	cmp	eax, 'FLT4'
	jz	sm2
	mov	dl, 16
sm2:	add	di, 20 + 22
	mov     [si + pl_sampinfo], di
	sub	di, 22 + 30
	mov	cx, dx
	imul	cx, 30
	add	di, cx
	mov	al, [es:di]
	mov	[si + pl_songlen], al
	inc	di
	inc	di
	mov	[si + pl_song], di
	xor	bx, bx
	mov	cx, 128
sm5:	mov	al, [es:di]
	inc	di
	cmp	bl, al
	jge	sm4
	mov	bl, al
sm4:	loop	sm5
	inc	bl
	cmp	dl, 32
	jnz	sm6
	add	di, 4
sm6:    mov     [si + pl_patterns], di
	mov	cx, bx
sm7:	add	di, 64 * 16	
	loop	sm7
	mov	[si + pl_speed], byte 6
	mov	[si + pl_effpos], byte 6
	mov	[si + pl_loaded], byte 1
	mov	cx, dx
	dec	cx
	mov	dx, es
	mov	bx, di
	mov	di, [si + pl_sampinfo]
	add	si, pl_sampd + 2
sm9:	push	bx
	shr	bx, 4
	add	dx, bx
	pop	bx
	and	bx, 0x000f
	mov	[si], bx
	mov	[si + 2 * 32], dx
	mov	ax, [es:di]
	xchg	al, ah
	add	bx, ax
	adc	dx, 0
	add	bx, ax
	adc	dx, 0
	add	si, 2
	add	di, 30
	loop	sm9
	popad
	ret

; pl_play - play modfile
;   ds:si  start of player
;   es:di  buffer to add samples
pl_play:
	pushad
	push	es
	push	di

	call	fixvol

	mov	ax, [si + pl_state]
	or	ax, ax
	jz	p3
	dec	ax
	jnz	p1

	; run effects
	push	si
	add	si, pl_channs
	mov	cx, 4
p31:	mov	ax, [si + ch_effect]
	or	ax, ax
	jz	p30
	call	doeff
	call	norm
p30:	add	si, ch_sizeof
	loop	p31
	pop	si

	inc	word [si + pl_effpos]
	mov	ax, [si + pl_effpos]
	cmp	ax, [si + pl_speed]
	jb	p1

	; advance note
	xor	ax, ax
	mov	[si + pl_effpos], ax
	mov	bx, [si + pl_nextsongnum]
	mov	[si + pl_songnum], bx
	mov	cx, [si + pl_songlen]
	cmp	bx, cx
	jb	p2
p3:	mov	[si + pl_state], ax
	pop	di
	pop	es
	popad
	ret
p2:	mov	dx, [si + pl_nextnotenum]
	mov	[si + pl_notenum], dx
	cmp	dx, 64
	jnb	p3
	inc	dx
	cmp	dl, 64
	jb	p4
	xor	dl, dl
	inc	bx
	cmp	bx, cx
	jb	p5
	xor	bx, bx
p5:	mov     [si + pl_nextsongnum], bx
p4:	mov	[si + pl_nextnotenum], dx

	; interpret events for each channel
	mov	bx, [si + pl_songnum]
	mov	es, [si + pl_seg]
	add	bx, [si + pl_song]
	mov	bl, [es:bx]
	cmp	bl, 0x80
	jb	p11
	xor	bl, bl
p11:	xor	bh, bh
	shl	bx, 6
	add	bx, [si + pl_notenum]
	shl	bx, 4
	add	bx, [si + pl_patterns]

	mov	di, [si + pl_sampinfo]
	push	si
	add	si, pl_channs

	mov	cx, 4
p18:	mov	ah, [es:bx]
	and	ah, 0x10
	mov	al, [es:bx + 2]
	shr	al, 4
	or	al, ah
	jz	p16
	call	setsamp
p16:	mov	ah, [es:bx]
	and	ah, 0x0f;
	mov	al, [es:bx + 1]
	or	ax, ax
	jz	p17
	mov	[si +  ch_pitchgoal], ax
	mov	dl, [es:bx + 2]
	inc	dl
	or	dl, 0xf2
	cmp	dl, 0xf6
	jz	p17
	mov     [si +  ch_pitch], ax
	xor	ax, ax
	mov     [si +  ch_pointer], ax
	mov     [si +  ch_pointer8], ax
	mov     ax, [si +  ch_send]
	mov     [si +  ch_end], ax
p17:	xor	ax, ax
	mov     [si +  ch_effect], ax
	mov	dl, [es:bx + 3]
	mov	al, [es:bx + 2]
	and	al, 0x0f
	or	dl, al
	jz	p29
	push	di
	mov	di, [si +  ch_player]
	mov     dl, [es:bx + 3]
	xor     dh, dh
	call	effects
	pop	di
p29:	call	norm
	add	si, ch_sizeof
	add	bx, 4
	dec	cx
	jnz	p18
	pop     si

	; prepare playing of each channel
p1:	push	si
	add	si, pl_channs
	mov	cx, 4
p10:	mov	ax, [si + ch_end]
	or	ax, ax
	jnz	p6
p8:	mov	[si + ch_start], ax
	mov     [si + ch_startseg], ax
	jmp	p7
p6:	mov	ax, [si + ch_pitch]
	or	ax, ax
	jz	p8
	mov	bx, [si + ch_samp]
	or	bx, bx
	jz	p8
	mov	dx, si
	pop	si
	push	si
	add	bx, bx
	add	si, bx
	mov	bx, [si + pl_sampd]
	mov	si, [si + pl_sampdseg]
	xchg	si, dx
	mov	[si + ch_start], bx
	mov	[si + ch_startseg], dx
	mov	dx, [si + ch_finetune]
	add	dx, dx
	jz	p9
	mov	dx, [cs: fttab]
	mul	dx
	shl	ax, 1
	mov	ax, dx
	adc	ax, ax
p9:	mov	bx, ax
	mov	ax, 57213
	xor	dx, dx
	div	bx
	mov	[si + ch_step], ah
	mov	[si + ch_step8], al
p7:	add	si, ch_sizeof
	loop	p10
	pop	si

	; now generate 320 samples for each channel
	pop	di
	pop	es
	add	si, pl_channs
	mov	ax, 320
p21:	push	ax
	mov	cx, 4
p20:	mov	bx, [si + ch_startseg]
	or	bx, bx
	jz	p22
	push	es
	mov     es, bx
	mov	bx, [si + ch_start]
	mov	ax, [si + ch_pointer]
	add	bx, ax
	movsx	dx, [es:bx]
	shl	dx, 2
	inc	ax
	cmp	ax, [si + ch_end]
	jnb	p23
	inc	bx
	movsx	ax, [es:bx]
	push	cx
	mov	cx, [si + ch_pointer8]
	or	cx, cx
	jz	p24
	sar	dx, 2
	imul	ax, cx
	neg	cl
	imul	dx, cx
	add	dx, ax
	sar	dx, 6
p24:	pop	cx
p23:	pop	es
	imul	dx, [si + ch_volume]
	sar	dx, 2
	push	si
	mov	si, [si + ch_player]
	movzx	eax, word [si + pl_volume]
	pop	si
	movsx	edx, dx
	imul	edx
	sar	eax, 16
	add	ax, word [es:di]
	jno	p40
	mov	ax, 32767
	js	p40
	inc	ax
p40:	mov	[es:di], ax
	mov     bx, [si + ch_pointer8]
	mov     ax, [si + ch_pointer]
	add	bl, [si + ch_step8]
	adc	ax, [si + ch_step]
	mov	[si + ch_pointer8], bl
	cmp	ax, [si + ch_end]
	jb	p25
	mov	ax, [si + ch_roff]
	mov     bx, [si + ch_rend]
	mov	[si + ch_end], bx
	or	bx, bx
	jnz	p25
	mov	[si + ch_startseg], bx
p25:	mov     [si + ch_pointer], ax
p22:	add	si, ch_sizeof
	dec	cx
	jnz	p20
	add	di, 2
	sub	si, ch_sizeof * 4
	pop	ax
	dec	ax
	jnz	p21
	sub	si, pl_channs
	mov	ax, [si + pl_state]
	dec	ax
	jz	p50
	add	si, pl_channs
	mov	cx, 4
p51:	mov	ax, [si + ch_startseg]
	or	ax, ax
	jnz	p50
	add	si, ch_sizeof
	loop	p51
	sub	si, ch_sizeof * 4 + pl_channs
	mov	[si + pl_state], ax
p50:	popad
	ret

fttab:	dw	32768, 32532, 32298, 32066
	dw	31835, 31606, 31378, 31153
	dw	34716, 34466, 34219, 33972
	dw	33728, 33485, 33244, 33005

; norm - normalize channel values
;   ds:si  start of chanel
norm:	push	ax
	mov	ax, [si + ch_volume]
	or	ax, ax
	jns	n1
	xor	ax, ax
n1:	cmp	ax, 64
	jb	n2
	mov	ax, 64
n2:	mov	[si + ch_volume], ax
	mov     ax, [si + ch_pitch]
	or	ax, ax
	jnb	n3
	xor	ax, ax
	mov     [si + ch_pitch], ax
n3:	pop	ax
	ret

arptab: dw	    0, 61858, 58386, 55109
	dw	52016, 49097, 46341, 43740
	dw	41285, 38968, 36781, 34716
	dw	32768, 30929, 29193, 27554

; effects - interpret effect
;   ax     effect
;   dx     arg
;   ds:di  start of player
;   ds:si  start of chanel
;	
;   trashes ax, dx
effects:
	or	al, al
	jnz	e1
	mov	[si + ch_arpindex], ax
	mov	ax, [si + ch_pitch]
	mov	[si + ch_arp], ax
	push	dx
	push	ax
	shr	dl, 4
	jz	e1b
	push	bx
	mov	bx, dx
	add	bl, bl
	mov	dx, [cs: arptab + bx]
	pop	bx
	mul	dx
	mov	ax, dx
e1b:	mov	[si + ch_arp + 2], ax
	pop	ax
	pop	dx
	and	dl, 0x0f
	jz	e1a
	push	bx
	mov	bx, dx
	add	bl, bl
	mov	dx, [cs: arptab + bx]
	pop	bx
	mul	dx
	mov	ax, dx
e1a:	mov	[si + ch_arp + 4], ax
	mov	[si + ch_effect], byte EFF_ARP
	ret
e1:	cmp	al, 1
	jnz	e2
	neg	dx
	jmp	e3
e2:	cmp     al, 2
	jnz	e4
e3:	or	dl, dl
	jz	e5
	mov	[si + ch_slide], dx
e5:	mov	[si + ch_effect], byte EFF_SLIDE
	ret
e4:	cmp     al, 3
	jnz	e6
	or	dl, dl
	jz      e7
	mov     [si + ch_pitchrate], dx
e7:	mov	[si + ch_effect], byte EFF_PORTA
	ret
e6:	cmp     al, 4
	jnz     e8
	mov	ax, dx
	shr	ax, 4
	jz	e9
	mov     [si + ch_vibrate], ax
e9:	and	dl, 0x0f
	jz      e10
	mov     [si + ch_vibdepth], dx
e10:	mov     [si + ch_effect], byte EFF_VIBRA
	ret
e8:	cmp     al, 5
	jnz	e11
	mov	[si + ch_effect], byte EFF_PORTASLIDE
	jmp	e12
e11:	cmp     al, 6
	jnz	e13
	mov	[si + ch_effect], byte EFF_VIBRASLIDE
	jmp	e12
e13:	cmp     al, 9
	jnz	e14
	mov	ax, [si + ch_samp]
	or	al, al
	jz	e15
	xor	ax, ax
	mov	[si + ch_pointer8], ax
	mov	ax, [si + ch_send]
	mov	[si + ch_end], ax
	shl	dx, 8
	cmp	dx, ax
	jb	e16
	sub	dx, ax
	mov	ax, [si + ch_rend]
	mov	[si + ch_end], ax
	sub	ax, [si + ch_roff]
	jz	e17
e18:	cmp	dx, ax
	jb	e17
	sub	dx, ax
	jmp	e18
e17:	add	dx, [si + ch_roff]
e16:	mov	[si + ch_pointer], dx
e15:	ret
e14:	cmp	al, 10
	jnz	e19
	mov	[si + ch_effect], byte EFF_SLIDEVOL
e12:	mov	ax, dx
	and	dl, 0x0f
	jz	e20
	neg	dx
	jmp	e21
e20:	mov	dx, ax
	shr	dl, 4
e21:	mov     [si + ch_volumerate], dx
	ret
e19:	cmp     al, 11
	jnz	e22
	mov     [di + pl_nextsongnum], dx
	xor	dx, dx
	mov     [di + pl_nextnotenum], dx
	ret
e22:	cmp     al, 12
	jnz	e23
	mov     [si + ch_volume], dx
	ret
e23:	cmp	al, 13
	jnz	e24
	mov	ax, dx
	shr	al, 4
	imul	ax, 10
	and	dx, 0x0f
	add	dx, ax
	mov	[di + pl_nextnotenum], dx
	mov	dx, [di + pl_songnum]
	inc	dx
	mov	ax, [di + pl_songlen]
	cmp	dx, ax
	jb	e25
	xor	dx, dx
e25:	mov	[di + pl_nextsongnum], dx
	ret
e24:	cmp     al, 15
	jnz	e27
	cmp	dl, 32
	jnb	e26
	mov	[di + pl_speed], dx
e26:	ret
e27:	cmp	al, 14
	jnz	e26
	mov	al, dl
	shr	al, 4
	and	dl, 0x0f
	cmp	al, 1
	jnz	e28
e30:	add	[si + ch_pitch], dx
	ret
e28:	cmp     al, 2
	jnz	e29
	neg	dx
	jmp	e30
e29:	cmp	al, 5
	jnz	e31
	mov     [si + ch_finetune], dx
	ret
e31:	cmp     al, 6
	jnz	e32
	or	dl, dl
	jnz	e33
	mov	dx, [di + pl_notenum]
	mov	[di + pl_loop_notenum], dx
	ret
e33:	mov	ax, [di + pl_loop_counter]
	or	ax, ax
	jnz	e34
	mov	ax, dx
	inc	ax
e34:	dec	ax
	mov     [di + pl_loop_counter], ax
	jz	e35
	mov     dx, [di + pl_loop_notenum]
	mov	[di + pl_nextnotenum], dx
e35:	ret
e32:	cmp     al, 9
	jnz	e36
	mov	[si + ch_retrig], dx
	mov	[si + ch_current], dx
	mov	[si + ch_effect], byte EFF_RETRIG
	ret
e36:	cmp     al, 10
	jnz	e37
e39:	add	[si + ch_volume], dx
	ret
e37:	cmp     al, 11
	jnz	e38
	neg	dx
	jmp	e39
e38:	cmp	al, 12
	jnz	e40
	mov	[si + ch_retrig], dx
	mov	[si + ch_effect], byte EFF_CUT
	ret
e40:	cmp     al, 13
	jnz	e41
	mov     [si + ch_current], dx
	mov     dx, [si + ch_samp]
	mov     [si + ch_latesamp], dx
	xor	dx, dx
	mov     [si + ch_samp], dx
	mov	[si + ch_effect], byte EFF_LATESTART
	ret
e41:	cmp	al, 14
	jnz	e42
	inc	dx
	imul	dx, [di + pl_speed]
	sub	[di + pl_effpos], dx
e42:	ret

vibtab:	dw	   0,  50, 100, 149, 196, 241, 284, 325
	dw	 362, 396, 426, 452, 473, 490, 502, 510
	dw	 512, 510, 502, 490, 473, 452, 426, 396
	dw	 362, 325, 284, 241, 196, 149, 100,  50
	dw	   0, -49, -99,-148,-195,-240,-283,-324
	dw	-361,-395,-425,-451,-472,-489,-501,-509
	dw	-511,-509,-501,-489,-472,-451,-425,-395
	dw	-361,-324,-283,-240, -195,-148,-99, -49

; doeff - apply channel effect
;   ax     effect
;   ds:si  start of chanel
;
;   trashes ax, bx
doeff:
	bt	ax, 3
	jnc	d1
	mov	bx, [si + ch_volumerate]
	add	[si + ch_volume], bx
	sub	al, 8
d1:	cmp	al, EFF_ARP
	jnz	d2
	mov	bx, [si + ch_arpindex]
	inc	bl
	cmp	bl, 3
	jb	d3
	xor	bl, bl
d3:	mov	[si + ch_arpindex], bl
	add	bl, bl
	mov	ax, [si + ch_arp + bx]
	mov	[si + ch_pitch], ax
	ret
d2:	cmp	al, EFF_SLIDE
	jnz	d4
	mov	ax, [si + ch_slide]
	add	[si + ch_pitch], ax
	ret
d4:	cmp	al, EFF_PORTA
	jnz	d5
	mov	ax, [si + ch_pitch]
	mov	bx, [si + ch_pitchgoal]
	cmp	ax, bx
	jnb	d6
	add	ax, [si + ch_pitchrate]
	cmp     ax, bx
	jb	d7
d8:	mov	ax, bx
d7:	mov	[si + ch_pitch], ax
	ret
d6:	sub	ax, [si + ch_pitchrate]
	cmp     ax, bx
	jb	d8
	jmp	d7
d5:	cmp	al, EFF_VIBRA
	jnz	d9
	mov	bx, [si + ch_viboffset]
	add	bx, [si + ch_vibrate]
	and	bx, 0x3f
	mov	[si + ch_viboffset], bx
	add	bx, bx
	mov	ax, [cs: vibtab + bx]
	imul	ax, [si + ch_vibdepth]
	sar	ax, 8
	add	ax, [si + ch_pitchgoal]
	mov	[si + ch_pitch], ax
d12:	ret
d9:	cmp     al, EFF_RETRIG
	jnz	d10
	dec	word [si + ch_current]
	jz	d11
	jns	d12
d11:	mov	ax, [si + ch_retrig]
	mov	[si + ch_current], ax
	mov	ax, [si + ch_send]
	mov	[si + ch_end], ax
	xor	ax, ax
	mov	[si + ch_pointer], ax
	mov	[si + ch_pointer8], ax
	ret
d10:	cmp	al, EFF_CUT
	jnz	d13
	mov	ax, [si + ch_retrig]
	jz	d14
	dec	word [si + ch_retrig]
	jnz	d14
	xor	ax, ax
	mov	[si + ch_volume], ax
d14:	ret
d13:	cmp     al, EFF_LATESTART
	jnz	d14
	dec	word [si + ch_current]
	jz	d15
	jns	d14
d15:	call	d11
	mov	[si + ch_current], ax
	mov	[si + ch_effect], ax
	mov	ax, [si + ch_latesamp]
	mov	[si + ch_samp], ax
	ret

; fixvol - fixup volume
;   ds:si  start of volblock
fixvol:
	push	ax
	push	bx
	mov	ax, [si + vo_volume]
	mov	bx, [si + vo_volumegoal]
	cmp	ax, bx
	jz	vo3
	jnb	vo1
	add	ax, [si + vo_volumerate]
	jc	vohit
	cmp	ax, bx
	jb	vo2
vohit:	mov	ax, bx
vo2:	mov	[si + vo_volume], ax
vo3:	pop	bx
	pop	ax
	ret
vo1:	sub	ax, [si + vo_volumerate]
	jc	vohit
	cmp	ax, bx
	jb	vohit
	jmp	vo2


; vo_setvol - set volume
;
;   es:esi	start of volblock
;   ax		goal
;   bx		rate 0=immediate 50=one sec

		bits 32

vo_setvol:
		mov [es:esi+vo_volumegoal],ax
		or bx,bx
		jnz sv1
		mov [es:esi+vo_volume],ax
		mov [es:esi+vo_volumerate],bx
		ret
sv1:
		push eax
		stc
		sbb eax,eax
		push edx
		div bx
		pop edx
		mov [es:esi+vo_volumerate],ax
		pop eax
		ret


; getvol - get volume
;   es:esi	start of volblock

		bits 32

vo_getvol:
		mov ax,[es:esi+vo_volume]
		ret
	

; pl_playmod - play a modfile
;   es:esi	start of player
;   ax		start of song

		bits 32

pl_playmod:
		cmp byte [es:esi+pl_loaded],1
		jz pm0
		ret
pm0:
		xor ebx,ebx
		mov [es:esi+pl_state],bx
		mov byte [es:esi+pl_speed],6
		mov byte [es:esi+pl_effpos],6
		mov [es:esi+pl_nextsongnum],ax
		mov [es:esi+pl_nextnotenum],bx
		call clearchans
		inc ebx
		mov [es:esi+pl_state],bx
		ret


; pl_playsamp - play a sample
;   es:esi	start of player
;   ax		channel number
;   bx		sample number
;   cx		pitch

		bits 32

pl_playsamp:
		cmp byte [es:esi+pl_loaded],1
		jz ps0
		ret
ps0:	
		push eax
		mov ax,[es:esi+pl_state]
		dec ax
		dec ax
		jz ps1
		call clearchans
ps1:
		pop eax
		push esi
		mov edi,[es:esi+pl_sampinfo]
		add esi,pl_channs
		imul eax,ch_sizeof
		add esi,eax
		xor eax,eax
		mov [es:esi+ch_startseg],ax
		mov [es:esi+ch_effect],ax
		mov [es:esi+ch_pointer],ax
		mov [es:esi+ch_pointer8],ax
		mov [es:esi+ch_pitch],cx
		mov eax,ebx
		or ax,ax
		jz ps2
		call setsamp
ps2:
		mov ax,[es:esi+ ch_send]
		mov [es:esi+ch_end],ax
		pop esi
		mov byte [es:esi + pl_state],2
		ret


; pl_getstate - get state of player
;   es:esi	start of player

		bits 32

pl_getstate:
		mov ax,[es:esi+pl_state]
		ret


; pl_stop - stop something?
;   ds:si  start of player

		bits 32

pl_stop:
		mov byte [es:esi+pl_state],0
		ret


; clearchans - stop all channels
;   es:esi	start of player

		bits 32

clearchans:
		push esi
		push ecx
		push eax
		xor eax,eax
		add esi,pl_channs
		mov ecx,4
cc1:
		mov [es:esi+ch_startseg],ax
		mov [es:esi+ch_effect],ax
		add si,ch_sizeof
		loop cc1
		pop eax
		pop ecx
		pop esi
		ret


; setsamp - start a sample
;   si  start of channel
;   es:di  start of sampinfo
;   ax     sample number
;
;   trashes ax, dx

		bits 16

setsamp:
	xor     ah, ah
	mov     [si +  ch_samp], ax
	dec     ax
	imul    ax, 30
	push    bx
	mov     bx, ax
	mov     ax, [es:di + bx]
	xchg    ah, al
	add     ax, ax
	mov     [si +  ch_send], ax
	mov     ax, [es:di + bx + 4]
	xchg    ah, al
	add     ax, ax
	mov     [si +  ch_roff], ax
	mov     dx, [es:di + bx + 6]
	xchg    dh, dl
	add     dx, dx
	mov     [si +  ch_rend], dx
	add     ax, dx
	mov     dx, [si +  ch_send]
	dec     ax
	dec     ax
	cmp     ax, dx
	jna     ss13
	shr     word [si +  ch_roff], 1
ss13:	mov     ax, [si +  ch_roff]
	add     ax, [si +  ch_rend]
	cmp     dx, [si +  ch_roff]
	jnb     ss14
ss16:	xor     ax, ax
	mov     [si +  ch_roff], ax
ss14:	cmp     dx, ax
	jnb     ss15
	mov     ax, dx
ss15:	mov	[si +  ch_rend], ax
	dec	ax
	dec	ax
	jz	ss16
	mov     al, [es:di + bx + 2]
	mov     [si +  ch_finetune], al
	mov     al, [es:di + bx + 3]
	mov     [si +  ch_volume], al
	pop     bx
	ret


; the big picture: four mod players
;
; init - initialize everything
;
;   es:esi	start of area

		bits 32

init:
		mov edi,esi
		xor eax,eax
		mov ecx,ar_sizeof
		rep stosb
		not eax
		xor ebx,ebx
		push esi
		add esi,ar_players
		mov ecx,4
ii2:
		call vo_setvol
		add esi,pl_sizeof
		loop ii2
		pop esi
		add esi,ar_volume
		mov ax,32767
		call vo_setvol
		ret


; setpl - get player offset
;   ax     player no.

		bits 16

setpl:
	add	si, ar_players
	imul	ax, pl_sizeof
	add	si, ax
	ret


; setpl - get player offset
;   eax		player no.
;
; return:
;   esi		player offset

		bits 32

pm_setpl:
		add esi,ar_players
		imul eax,pl_sizeof
		add esi,eax
		ret


; loadmod - load a mod into one of the players
;   ds:si  start of area
;   es:di  start of mod
;   ax     player no.

		bits 16

loadmod:
	push	si
	call	setpl
	call	pl_loadmod
	pop	si
	ret


; playmod - play a modfile
;   es:esi	start of area
;   eax		player no.
;   bx		start of song

		bits 32

playmod:
		call pm_setpl
		mov eax,ebx
		call pl_playmod
		ret


; playsamp - play a sample
;   es:esi	start of area
;   eax		player no.
;   bx		channel number
;   cx		sample number
;   dx		pitch

		bits 32

playsamp:
		call pm_setpl
		mov eax,ebx
		mov ebx,ecx
		mov ecx,edx
		call pl_playsamp
		ret


; getstate - get state of player
;   es:esi	start of area
;   eax		player no.

		bits 32

getstate:
		call pm_setpl
		call pl_getstate
		ret


; stop - stop a player
;   es:esi	start of area
;   eax		player no.

		bits 32

stop:
		call pm_setpl
		call pl_stop
		ret


		bits 16

pctab:
	db	64,  64,  64,  64,  64,  64,  64,  64
	db	64,  64,  63,  63,  63,  63,  63,  63
	db	63,  63,  63,  63,  63,  63,  62,  62
	db	62,  62,  62,  62,  62,  62,  62,  62
	db	61,  61,  61,  61,  61,  61,  61,  61
	db	61,  60,  60,  60,  60,  60,  60,  60
	db	60,  60,  60,  59,  59,  59,  59,  59
	db	59,  59,  59,  59,  59,  58,  58,  58
	db	58,  58,  58,  58,  58,  58,  58,  57
	db	57,  57,  57,  57,  57,  57,  57,  57
	db	57,  56,  56,  56,  56,  56,  56,  56
	db	56,  55,  55,  55,  55,  55,  54,  54
	db	54,  54,  53,  53,  53,  53,  52,  52
	db	52,  51,  51,  50,  50,  49,  49,  48
	db	48,  47,  46,  45,  44,  43,  42,  41
	db	40,  39,  38,  37,  36,  35,  34,  33
	db	32,  31,  30,  29,  28,  27,  26,  25
	db	24,  23,  22,  21,  20,  19,  18,  17
	db	17,  16,  16,  15,  15,  14,  14,  13
	db	13,  13,  12,  12,  12,  12,  11,  11
	db	11,  11,  10,  10,  10,  10,  10,   9
	db	 9,   9,   9,   9,   9,   9,   9,   9
	db	 8,   8,   8,   8,   8,   8,   8,   8
	db	 8,   8,   8,   8,   7,   7,   7,   7
	db	 7,   7,   7,   6,   6,   6,   6,   6
	db	 6,   6,   6,   6,   6,   6,   5,   5
	db	 5,   5,   5,   5,   5,   5,   5,   5
	db	 4,   4,   4,   4,   4,   4,   4,   4
	db	 4,   4,   3,   3,   3,   3,   3,   3
	db	 3,   3,   3,   3,   2,   2,   2,   2
	db	 2,   2,   2,   2,   2,   1,   1,   1
	db	 1,   1,   1,   1,   1,   1,   1,   1
	
; play - generate samples
;   ds:si  start of area
play:
	pushad
	push	es
	push	si
	xor	ax, ax
	mov	cx, ar_volume
ap1:	mov	[si], al
	inc	si
	loop	ap1
	call	fixvol
	pop	si
	push	si
	add	si, ar_ssamps
	mov	di, si
	push	ds
	pop	es
	mov	cx, ar_sizeof - ar_ssamps
ap2:	mov	[si], al
	inc	si
	loop	ap2
	pop	si
	push	si
	mov	cx, 4
	xor	bx, bx
	add	si, ar_players
ap4:	mov	ax, [si + pl_state]
	or	ax, ax
	jz	ap3
	call	pl_play
	mov	ax, [si + pl_volume]
	or	ax, ax
	jz	ap3
	mov	bl, 1
ap3:	add	si, pl_sizeof
	loop	ap4
	pop	si
	movzx	eax, word [si + ar_volume]
	or	ax, ax
	jz	ap5
	mov	[si + ar_hassamp], bl
	mov	cx, 320
	xor	bx, bx
ap6:	movsx	edx, word [si + bx + ar_ssamps]
	imul	edx, eax

	sar	edx, 16-2

	cmp	edx,32767
	jl	ap7
	mov	edx,32767
ap7:
	cmp	edx,-32768
	jg	ap8
	mov	edx,-32768

ap8:
	add	dh, 128
	push	bx
	xor	bx, bx
	mov	bl, dh
	mov	dl, [cs: pctab + bx]
	pop	bx
	mov	[si + ar_samps], dl
	inc	si
	inc	bx
	loop	ap6
ap5:	pop	es
	popad
	ret


; setvol - set volume
;   es:esi	start of area
;   eax		player no.
;   bx		goal
;   cx		rate 0=immediate 50=one sec

		bits 32

setvol:
		call setplvl
		mov eax,ebx
		mov ebx,ecx
		call vo_setvol	
		ret


; getvol - get volume
;   es:esi	start of area
;   eax		player no.
;
; return:
;   ax		volume

		bits 32

getvol:
		call setplvl
		call vo_getvol	
		ret


; setplvl - get volume offset
;   eax		player no.

		bits 32

setplvl:
		or eax,eax
		jns pm_setpl
		add esi,ar_volume
		ret

