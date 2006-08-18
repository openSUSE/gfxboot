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
;   es:esi	start of player
;   es:edi	start of mod

pl_loadmod:
		push esi
		add esi,pl_state
		xor eax,eax
		mov ecx,pl_sizeof-pl_state
sm1:
		mov [es:esi],al
		inc esi
		loop sm1
		pop esi

		mov edx,esi
		mov ecx,4
		push esi
		add esi,pl_channs
sm10:
		mov [es:esi+ch_player],edx
		add esi,ch_sizeof
		loop sm10

		pop esi
		mov edx,32
		mov eax,[es:edi+0x438]
		cmp eax,'CHN4'
		jz sm2
		cmp eax,'M.K.'
		jz sm2
		cmp eax,'M&K!'
		jz sm2
		cmp eax,'FLT4'
		jz sm2
		mov dl,16
sm2:
		add edi,20+22
		mov [es:esi+pl_sampinfo],edi
		sub edi,22+30
		imul ecx,edx,30
		add edi,ecx
		mov al,[es:edi]
		mov [es:esi+pl_songlen],al
		inc edi
		inc edi
		mov [es:esi+pl_song],edi
		xor ebx,ebx
		mov ecx,128
sm5:
		mov al,[es:edi]
		inc edi
		cmp bl,al
		jge sm4
		mov bl,al
sm4:
		loop sm5
		inc bl
		cmp dl,32
		jnz sm6
		add edi,4
sm6:
		mov [es:esi+pl_patterns],edi
		mov ecx,ebx
sm7:
		add edi,64*16
		loop sm7

		mov byte [es:esi+pl_speed],6
		mov byte [es:esi+pl_effpos],6
		mov byte [es:esi+pl_loaded],1
		mov ecx,edx
		dec ecx
		mov ebx,edi
		mov edi,[es:esi+pl_sampinfo]
sm9:
		mov [es:esi+pl_sampd+4],ebx	; +4 -> skip first?
		movzx eax,word [es:edi]
		xchg al,ah
		add ebx,eax
		add ebx,eax
		add esi,4
		add edi,30
		loop sm9
		ret


; pl_play - play modfile
;   es:esi	start of player
;   es:edi	buffer to add samples

pl_play:
		pusha
		push edi

		call fixvol

		mov ax,[es:esi+pl_state]
		or ax,ax
		jz p3
		dec ax
		jnz p1

		; run effects
		push esi
		add esi,pl_channs
		mov ecx,4
p31:
		mov ax,[es:esi+ch_effect]
		or ax,ax
		jz p30
		call doeff
		call norm
p30:
		add esi,ch_sizeof
		loop p31
		pop esi

		inc word [es:esi+pl_effpos]
		mov ax,[es:esi+pl_effpos]
		cmp ax,[es:esi+pl_speed]
		jb p1

		; advance note
		xor eax,eax
		mov [es:esi+pl_effpos],ax
		mov bx,[es:esi+pl_nextsongnum]
		mov [es:esi+pl_songnum],bx
		mov cx,[es:esi+pl_songlen]
		cmp bx,cx
		jb p2
p3:
		mov [es:esi+pl_state],ax
		pop edi
		popa
		ret

p2:
		mov dx,[es:esi+pl_nextnotenum]
		mov [es:esi+pl_notenum],dx
		cmp dx,64
		jnb p3
		inc edx
		cmp dl,64
		jb p4
		xor dl,dl
		inc ebx
		cmp bx,cx
		jb p5
		xor ebx,ebx
p5:
		mov [es:esi+pl_nextsongnum],bx
p4:
		mov [es:esi+pl_nextnotenum],dx

		; interpret events for each channel
		movzx ebx,word [es:esi+pl_songnum]
		add ebx,[es:esi+pl_song]
		mov bl,[es:ebx]
		cmp bl,0x80
		jb p11
		xor bl,bl
p11:
		movzx ebx,bl
		shl ebx,6
		movzx ecx,word [es:esi+pl_notenum]
		add ebx,ecx
		shl ebx,4
		add ebx,[es:esi+pl_patterns]

		mov edi,[es:esi+pl_sampinfo]
		push esi
		add esi,pl_channs

		mov ecx,4
p18:
		mov ah,[es:ebx]
		and ah,0x10
		mov al,[es:ebx+2]
		shr al,4
		or al,ah
		jz p16
		call setsamp
p16:
		mov ah,[es:ebx]
		and ah,0x0f
		mov al,[es:ebx+1]
		or ax,ax
		jz p17
		mov [es:esi+ch_pitchgoal],ax
		mov dl,[es:ebx+2]
		inc dl
		or dl,0xf2
		cmp dl,0xf6
		jz p17
		mov [es:esi+ch_pitch],ax
		xor eax,eax
		mov [es:esi+ch_pointer],ax
		mov [es:esi+ch_pointer8],ax
		mov ax,[es:esi+ch_send]
		mov [es:esi+ch_end],ax
p17:
		xor eax,eax
		mov [es:esi+ch_effect],ax
		mov dl,[es:ebx+3]
		mov al,[es:ebx+2]
		and al,0x0f
		or dl,al
		jz p29

		push edi
		mov edi,[es:esi+ch_player]
		mov dl,[es:ebx+3]
		xor dh,dh
		call effects
		pop edi
p29:
		call norm
		add esi,ch_sizeof
		add ebx,4
		dec ecx
		jnz p18

		pop esi

		; prepare playing of each channel
p1:
		push esi
		add esi,pl_channs
		mov ecx,4
p10:
		mov ax,[es:esi+ch_end]
		or ax,ax
		jnz p6
p8:
		mov dword [es:esi+ch_start],0
		jmp p7
p6:
		mov ax,[es:esi+ch_pitch]
		or ax,ax
		jz p8
		movzx ebx,word [es:esi+ch_samp]
		or ebx,ebx
		jz p8
		mov edx,esi
		pop esi
		push esi
		shl ebx,2
		add esi,ebx
		mov ebx,[es:esi+pl_sampd]
		xchg esi,edx
		mov [es:esi+ch_start],ebx
		mov dx,[es:esi+ch_finetune]
		add dx,dx
		jz p9
		mov dx,[fttab]
		mul dx
		shl ax,1
		mov ax,dx
		adc ax,ax
p9:
		mov bx,ax
		mov ax,57213
		xor edx,edx
		div bx
		mov [es:esi+ch_step],ah
		mov [es:esi+ch_step8],al
p7:
		add esi,ch_sizeof
		loop p10

		pop esi

		; now generate 320 samples for each channel
		pop edi
		add esi,pl_channs
		mov eax,320
p21:
		push eax
		mov ecx,4
p20:
		mov ebx,[es:esi+ch_start]
		or ebx,ebx
		jz p22

		movzx eax,word [es:esi+ch_pointer]
		add ebx,eax
		movsx dx,[es:ebx]
		shl dx,2
		inc eax
		cmp ax,[es:esi+ch_end]
		jnb p23
		inc ebx
		movsx ax,[es:ebx]
		push ecx
		mov cx,[es:esi+ch_pointer8]
		or cx,cx
		jz p24
		sar dx,2
		imul ax,cx
		neg cl
		imul dx,cx
		add dx,ax
		sar dx,6
p24:
		pop ecx
p23:
		imul dx,[es:esi+ch_volume]
		sar dx,2
		push esi
		mov esi,[es:esi+ch_player]
		movzx eax,word [es:esi+pl_volume]
		pop esi
		movsx edx,dx
		imul edx
		sar eax,16
		add ax,word [es:edi]
		jno p40
		mov ax,32767
		js p40
		inc eax
p40:
		mov [es:edi],ax
		mov bx,[es:esi+ch_pointer8]
		mov ax,[es:esi+ch_pointer]
		add bl,[es:esi+ch_step8]
		adc ax,[es:esi+ch_step]
		mov [es:esi+ch_pointer8],bl
		cmp ax,[es:esi+ch_end]
		jb p25
		mov ax,[es:esi+ch_roff]
		mov bx,[es:esi+ch_rend]
		mov [es:esi+ch_end],bx
		or bx,bx
		jnz p25
		mov dword [es:esi+ch_start],0
p25:
		mov [es:esi+ch_pointer],ax
p22:
		add esi,ch_sizeof
		dec ecx
		jnz p20
		add edi,2
		sub esi,ch_sizeof * 4
		pop eax
		dec eax
		jnz p21
		sub esi,pl_channs
		mov ax,[es:esi+pl_state]
		dec ax
		jz p50
		add esi,pl_channs
		mov ecx,4
p51:
		mov eax,[es:esi+ch_start]
		or eax,eax
		jnz p50
		add esi,ch_sizeof
		loop p51
		sub esi,ch_sizeof * 4 + pl_channs
		mov [es:esi+pl_state],ax
p50:
		popa
		ret


fttab		dw 32768, 32532, 32298, 32066
		dw 31835, 31606, 31378, 31153
		dw 34716, 34466, 34219, 33972
		dw 33728, 33485, 33244, 33005


; norm - normalize channel values
;   es:esi	start of chanel

norm:
		push eax
		mov ax,[es:esi+ch_volume]
		or ax,ax
		jns n1
		xor eax,eax
n1:
		cmp ax,64
		jb n2
		mov ax,64
n2:
		mov [es:esi+ch_volume],ax
		mov ax,[es:esi+ch_pitch]
		or ax,ax
		jnb n3
		xor eax,eax
		mov [es:esi+ch_pitch],ax
n3:
		pop eax
		ret


; effects - interpret effect
;   ax		effect
;   dx		arg
;   es:edi	start of player
;   es:esi	start of channel
;	
;   trashes ax, dx

effects:
		movzx edx,dx
		or al,al
		jnz e1
		mov [es:esi+ch_arpindex],ax
		mov ax,[es:esi+ch_pitch]
		mov [es:esi+ch_arp],ax
		push edx
		push eax
		shr dl,4
		jz e1b
		mov dx,[arptab+2*edx]
		mul dx
		mov ax,dx
e1b:
		mov [es:esi+ch_arp+2],ax
		pop eax
		pop edx
		and dl,0x0f
		jz e1a
		mov dx,[arptab+2*edx]
		mul dx
		mov ax,dx
e1a:
		mov [es:esi+ch_arp+4],ax
		mov byte [es:esi+ch_effect],EFF_ARP
		ret
e1:
		cmp al,1
		jnz e2
		neg dx
		jmp e3
e2:
		cmp al,2
		jnz e4
e3:
		or dl, dl
		jz e5
		mov [es:esi+ch_slide],dx
e5:
		mov byte [es:esi+ch_effect],EFF_SLIDE
		ret
e4:
		cmp al,3
		jnz e6
		or dl,dl
		jz e7
		mov [es:esi+ch_pitchrate],dx
e7:
		mov byte [es:esi+ch_effect],EFF_PORTA
		ret
e6:
		cmp al,4
		jnz e8
		mov ax,dx
		shr ax,4
		jz e9
		mov [es:esi+ch_vibrate],ax
e9:
		and dl,0x0f
		jz e10
		mov [es:esi+ch_vibdepth],dx
e10:
		mov byte [es:esi+ch_effect],EFF_VIBRA
		ret
e8:	
		cmp al,5
		jnz e11
		mov byte [es:esi+ch_effect],EFF_PORTASLIDE
		jmp e12
e11:
		cmp al,6
		jnz e13
		mov byte [es:esi+ch_effect],EFF_VIBRASLIDE
		jmp e12
e13:
		cmp al,9
		jnz e14
		mov ax,[es:esi+ch_samp]
		or al,al
		jz e15
		xor eax,eax
		mov [es:esi+ch_pointer8],ax
		mov ax,[es:esi+ch_send]
		mov [es:esi+ch_end],ax
		shl dx,8
		cmp dx,ax
		jb e16
		sub dx,ax
		mov ax,[es:esi+ch_rend]
		mov [es:esi+ch_end],ax
		sub ax,[es:esi+ch_roff]
		jz e17
e18:
		cmp dx,ax
		jb e17
		sub dx,ax
		jmp e18
e17:
		add dx,[es:esi+ch_roff]
e16:
		mov [es:esi+ch_pointer],dx
e15:
		ret
e14:
		cmp al,10
		jnz e19
		mov byte [es:esi+ch_effect],EFF_SLIDEVOL
e12:
		mov ax,dx
		and dl,0x0f
		jz e20
		neg dx
		jmp e21
e20:
		mov dx,ax
		shr dl,4
e21:
		mov [es:esi+ch_volumerate],dx
		ret
e19:
		cmp al,11
		jnz e22
		mov [es:edi+pl_nextsongnum],dx
		xor edx,edx
		mov [es:edi+pl_nextnotenum],dx
		ret
e22:
		cmp al,12
		jnz e23
		mov [es:esi+ch_volume],dx
		ret
e23:
		cmp al,13
		jnz e24
		mov ax,dx
		shr al,4
		imul ax,10
		and dx,0x0f
		add dx,ax
		mov [es:edi+pl_nextnotenum],dx
		mov dx,[es:edi+pl_songnum]
		inc dx
		mov ax,[es:edi+pl_songlen]
		cmp dx,ax
		jb e25
		xor edx,edx
e25:
		mov [es:edi+pl_nextsongnum],dx
		ret
e24:
		cmp al,15
		jnz e27
		cmp dl,32
		jnb e26
		mov [es:edi+pl_speed],dx
e26:
		ret
e27:
		cmp al,14
		jnz e26
		mov al,dl
		shr al,4
		and dl,0x0f
		cmp al,1
		jnz e28
e30:
		add [es:esi+ch_pitch],dx
		ret
e28:
		cmp al,2
		jnz e29
		neg dx
		jmp e30
e29:
		cmp al,5
		jnz e31
		mov [es:esi+ch_finetune],dx
		ret
e31:
		cmp al,6
		jnz e32
		or dl,dl
		jnz e33
		mov dx,[es:edi+pl_notenum]
		mov [es:edi+pl_loop_notenum],dx
		ret
e33:
		mov ax,[es:edi+pl_loop_counter]
		or ax,ax
		jnz e34
		mov ax,dx
		inc ax
e34:
		dec ax
		mov [es:edi+pl_loop_counter],ax
		jz e35
		mov dx,[es:edi+pl_loop_notenum]
		mov [es:edi+pl_nextnotenum],dx
e35:
		ret
e32:
		cmp al,9
		jnz e36
		mov [es:esi+ch_retrig],dx
		mov [es:esi+ch_current],dx
		mov byte [es:esi+ch_effect],EFF_RETRIG
		ret
e36:	
		cmp al,10
		jnz e37
e39:
		add [es:esi+ch_volume],dx
		ret
e37:	
		cmp  al,11
		jnz e38
		neg dx
		jmp e39
e38:
		cmp al,12
		jnz e40
		mov [es:esi+ch_retrig],dx
		mov byte [es:esi+ch_effect],EFF_CUT
		ret
e40:	
		cmp al,13
		jnz e41
		mov [es:esi+ch_current],dx
		mov dx,[es:esi+ch_samp]
		mov [es:esi+ch_latesamp],dx
		xor edx,edx
		mov [es:esi+ch_samp],dx
		mov byte [es:esi+ch_effect],EFF_LATESTART
		ret
e41:	
		cmp al,14
		jnz e42
		inc dx
		imul dx,[es:edi+pl_speed]
		sub [es:edi+pl_effpos],dx
e42:
		ret


arptab		dw     0, 61858, 58386, 55109
		dw 52016, 49097, 46341, 43740
		dw 41285, 38968, 36781, 34716
		dw 32768, 30929, 29193, 27554


; doeff - apply channel effect
;   ax		effect
;   es:esi	start of chanel
;
;   trashes ax, bx

doeff:
		bt ax,3
		jnc d1
		mov bx,[es:esi+ch_volumerate]
		add [es:esi+ch_volume],bx
		sub al,8
d1:
		cmp al,EFF_ARP
		jnz d2
		movzx ebx,word [es:esi+ch_arpindex]
		inc bl
		cmp bl,3
		jb d3
		xor bl,bl
d3:
		mov [es:esi+ch_arpindex],bl
		add bl,bl
		mov ax,[es:esi+ebx+ch_arp]
		mov [es:esi+ch_pitch],ax
		ret
d2:
		cmp al,EFF_SLIDE
		jnz d4
		mov ax,[es:esi+ch_slide]
		add [es:esi+ch_pitch],ax
		ret
d4:
		cmp al,EFF_PORTA
		jnz d5
		mov ax,[es:esi+ch_pitch]
		mov bx,[es:esi+ch_pitchgoal]
		cmp ax,bx
		jnb d6
		add ax,[es:esi+ch_pitchrate]
		cmp ax,bx
		jb d7
d8:
		mov ax,bx
d7:
		mov [es:esi+ch_pitch],ax
		ret
d6:
		sub ax,[es:esi+ch_pitchrate]
		cmp ax,bx
		jb d8
		jmp d7
d5:
		cmp al,EFF_VIBRA
		jnz d9
		mov bx,[es:esi+ch_viboffset]
		add bx,[es:esi+ch_vibrate]
		and ebx,0x3f
		mov [es:esi+ch_viboffset],bx
		mov ax,[vibtab+2*ebx]
		imul ax,[es:esi+ch_vibdepth]
		sar ax, 8
		add ax,[es:esi+ch_pitchgoal]
		mov [es:esi+ch_pitch],ax
d12:
		ret
d9:
		cmp al,EFF_RETRIG
		jnz d10
		dec word [es:esi+ch_current]
		jz d11
		jns d12
d11:
		mov ax,[es:esi+ch_retrig]
		mov [es:esi+ch_current],ax
		mov ax,[es:esi+ch_send]
		mov [es:esi+ch_end],ax
		xor eax,eax
		mov [es:esi+ch_pointer],ax
		mov [es:esi+ch_pointer8],ax
		ret
d10:
		cmp al,EFF_CUT
		jnz d13
		mov ax,[es:esi+ch_retrig]
		jz d14
		dec word [es:esi+ch_retrig]
		jnz d14
		xor eax,eax
		mov [es:esi+ch_volume],ax
d14:
		ret
d13:
		cmp al,EFF_LATESTART
		jnz d14
		dec word [es:esi+ch_current]
		jz d15
		jns d14
d15:
		call d11
		mov [es:esi+ch_current],ax
		mov [es:esi+ch_effect],ax
		mov ax,[es:esi+ch_latesamp]
		mov [es:esi+ch_samp],ax
		ret


vibtab		dw    0,  50, 100, 149, 196, 241, 284, 325
		dw  362, 396, 426, 452, 473, 490, 502, 510
		dw  512, 510, 502, 490, 473, 452, 426, 396
		dw  362, 325, 284, 241, 196, 149, 100,  50
		dw    0, -49, -99,-148,-195,-240,-283,-324
		dw -361,-395,-425,-451,-472,-489,-501,-509
		dw -511,-509,-501,-489,-472,-451,-425,-395
		dw -361,-324,-283,-240, -195,-148,-99, -49


; fixvol - fixup volume
;   es:esi	start of volblock

fixvol:
		push eax
		push ebx
		mov ax,[es:esi+vo_volume]
		mov bx,[es:esi+vo_volumegoal]
		cmp ax,bx
		jz vo3
		jnb vo1
		add ax,[es:esi+vo_volumerate]
		jc vohit
		cmp ax,bx
		jb vo2
vohit:
		mov ax,bx
vo2:
		mov [es:esi+vo_volume],ax
vo3:
		pop ebx
		pop eax
		ret
vo1:
		sub ax,[es:esi+vo_volumerate]
		jc vohit
		cmp ax,bx
		jb vohit
		jmp vo2


; vo_setvol - set volume
;
;   es:esi	start of volblock
;   ax		goal
;   bx		rate 0=immediate 50=one sec

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

vo_getvol:
		mov ax,[es:esi+vo_volume]
		ret
	

; pl_playmod - play a modfile
;   es:esi	start of player
;   ax		start of song

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
		mov [es:esi+ch_start],eax
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

pl_getstate:
		mov ax,[es:esi+pl_state]
		ret


; pl_stop - stop something?
;   es:esi  start of player

pl_stop:
		mov byte [es:esi+pl_state],0
		ret


; clearchans - stop all channels
;   es:esi	start of player

clearchans:
		push esi
		push ecx
		push eax
		xor eax,eax
		add esi,pl_channs
		mov ecx,4
cc1:
		mov [es:esi+ch_start],eax
		mov [es:esi+ch_effect],ax
		add esi,ch_sizeof
		loop cc1
		pop eax
		pop ecx
		pop esi
		ret


; setsamp - start a sample
;   es:esi	start of channel
;   es:edi	start of sampinfo
;   ax		sample number
;
;   trashes ax, dx

setsamp:
		movzx eax,al
		mov [es:esi+ch_samp],ax
		dec ax
		imul ax,30
		push ebx
		mov ebx,eax
		mov ax,[es:edi+ebx]
		xchg ah,al
		add ax,ax
		mov [es:esi+ch_send],ax
		mov ax,[es:edi+ebx+4]
		xchg ah,al
		add ax,ax
		mov [es:esi+ch_roff],ax
		mov dx,[es:edi+ebx+6]
		xchg dh,dl
		add dx,dx
		mov [es:esi+ch_rend],dx
		add ax,dx
		mov dx,[es:esi+ch_send]
		dec ax
		dec ax
		cmp ax,dx
		jna ss13
		shr word [es:esi+ch_roff],1
ss13:
		mov ax,[es:esi+ch_roff]
		add ax,[es:esi+ch_rend]
		cmp dx,[es:esi+ch_roff]
		jnb ss14
ss16:
		xor eax,eax
		mov [es:esi+ch_roff],ax
ss14:
		cmp dx,ax
		jnb ss15
		mov ax,dx
ss15:
		mov [es:esi+ch_rend],ax
		dec ax
		dec ax
		jz ss16
		mov al,[es:edi+ebx+2]
		mov [es:esi+ch_finetune],al
		mov al,[es:edi+ebx+3]
		mov [es:esi+ch_volume],al
		pop ebx
		ret


; the big picture: four mod players
;
; init - initialize everything
;
;   es:esi	start of area

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
;   eax		player no.
;
; return:
;   esi		player offset

setpl:
		add esi,ar_players
		imul eax,pl_sizeof
		add esi,eax
		ret


; loadmod - load a mod into one of the players
;   es:esi	start of area
;   es:edi	start of mod
;   eax		player no.

loadmod:
		call setpl
		call pl_loadmod
		ret


; playmod - play a modfile
;   es:esi	start of area
;   eax		player no.
;   bx		start of song

playmod:
		call setpl
		mov eax,ebx
		call pl_playmod
		ret


; playsamp - play a sample
;   es:esi	start of area
;   eax		player no.
;   bx		channel number
;   cx		sample number
;   dx		pitch

playsamp:
		call setpl
		mov eax,ebx
		mov ebx,ecx
		mov ecx,edx
		call pl_playsamp
		ret


; getstate - get state of player
;   es:esi	start of area
;   eax		player no.

getstate:
		call setpl
		call pl_getstate
		ret


; stop - stop a player
;   es:esi	start of area
;   eax		player no.

stop:
		call setpl
		call pl_stop
		ret


; play - generate samples
;   es:esi	start of area

play:
		push esi
		xor eax,eax
		mov ecx,ar_volume
ap1:
		mov [es:esi],al
		inc esi
		loop ap1
		call fixvol
		pop esi
		push esi
		add esi,ar_ssamps
		mov edi,esi
		mov ecx,ar_sizeof-ar_ssamps
ap2:
		mov [es:esi],al
		inc esi
		loop ap2
		pop esi
		push esi
		mov ecx,4
		xor ebx,ebx
		add esi,ar_players
ap4:
		mov ax,[es:esi+pl_state]
		or ax,ax
		jz ap3
		call pl_play
		mov ax,[es:esi+pl_volume]
		or ax,ax
		jz ap3
		mov bl,1
ap3:
		add esi,pl_sizeof
		loop ap4
		pop esi
		movzx eax,word [es:esi+ar_volume]
		or ax,ax
		jz ap5
		mov [es:esi+ar_hassamp],bl
		mov ecx,320
		xor ebx,ebx
ap6:
		movsx edx,word [es:esi+ebx+ar_ssamps]

		imul edx,eax

		sar edx,16-2

		cmp edx,32767
		jl ap7
		mov edx,32767
ap7:
		cmp edx,-32768
		jg ap8
		mov edx,-32768

ap8:
		add dh,128
		push ebx
		xor ebx,ebx
		mov bl,dh
		mov dl,[pctab+ebx]
		pop ebx
		mov [es:esi+ar_samps],dl
		inc esi
		inc ebx
		loop ap6
ap5:
		ret


pctab		db 64,  64,  64,  64,  64,  64,  64,  64
		db 64,  64,  63,  63,  63,  63,  63,  63
		db 63,  63,  63,  63,  63,  63,  62,  62
		db 62,  62,  62,  62,  62,  62,  62,  62
		db 61,  61,  61,  61,  61,  61,  61,  61
		db 61,  60,  60,  60,  60,  60,  60,  60
		db 60,  60,  60,  59,  59,  59,  59,  59
		db 59,  59,  59,  59,  59,  58,  58,  58
		db 58,  58,  58,  58,  58,  58,  58,  57
		db 57,  57,  57,  57,  57,  57,  57,  57
		db 57,  56,  56,  56,  56,  56,  56,  56
		db 56,  55,  55,  55,  55,  55,  54,  54
		db 54,  54,  53,  53,  53,  53,  52,  52
		db 52,  51,  51,  50,  50,  49,  49,  48
		db 48,  47,  46,  45,  44,  43,  42,  41
		db 40,  39,  38,  37,  36,  35,  34,  33
		db 32,  31,  30,  29,  28,  27,  26,  25
		db 24,  23,  22,  21,  20,  19,  18,  17
		db 17,  16,  16,  15,  15,  14,  14,  13
		db 13,  13,  12,  12,  12,  12,  11,  11
		db 11,  11,  10,  10,  10,  10,  10,   9
		db  9,   9,   9,   9,   9,   9,   9,   9
		db  8,   8,   8,   8,   8,   8,   8,   8
		db  8,   8,   8,   8,   7,   7,   7,   7
		db  7,   7,   7,   6,   6,   6,   6,   6
		db  6,   6,   6,   6,   6,   6,   5,   5
		db  5,   5,   5,   5,   5,   5,   5,   5
		db  4,   4,   4,   4,   4,   4,   4,   4
		db  4,   4,   3,   3,   3,   3,   3,   3
		db  3,   3,   3,   3,   2,   2,   2,   2
		db  2,   2,   2,   2,   2,   1,   1,   1
		db  1,   1,   1,   1,   1,   1,   1,   1
	

; setvol - set volume
;   es:esi	start of area
;   eax		player no.
;   bx		goal
;   cx		rate 0=immediate 50=one sec

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

getvol:
		call setplvl
		call vo_getvol	
		ret


; setplvl - get volume offset
;   eax		player no.

setplvl:
		or eax,eax
		jns setpl
		add esi,ar_volume
		ret

