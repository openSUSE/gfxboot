	.file	"jpeg.S"
	.text
	.code16gcc

	.globl jpeg_decode
	.globl jpeg_get_size

datap:
	.space	4,0

tmp_img:
	.space	512,0

info:
	.space	12,0

comps:
	.space	48,0

dscans:
	.space	112,0

quant:
	.space	256,0

dhuff:
	.space	5648,0

in:
	.space	24,0

aaidct:
	.long	724
	.long	1004
	.long	946
	.long	851
	.long	724
	.long	569
	.long	392
	.long	200

zig:
	.byte	0
	.byte	1
	.byte	5
	.byte	6
	.byte	14
	.byte	15
	.byte	27
	.byte	28
	.byte	2
	.byte	4
	.byte	7
	.byte	13
	.byte	16
	.byte	26
	.byte	29
	.byte	42
	.byte	3
	.byte	8
	.byte	12
	.byte	17
	.byte	25
	.byte	30
	.byte	41
	.byte	43
	.byte	9
	.byte	11
	.byte	18
	.byte	24
	.byte	31
	.byte	40
	.byte	44
	.byte	53
	.byte	10
	.byte	19
	.byte	23
	.byte	32
	.byte	39
	.byte	45
	.byte	52
	.byte	54
	.byte	20
	.byte	22
	.byte	33
	.byte	38
	.byte	46
	.byte	51
	.byte	55
	.byte	60
	.byte	21
	.byte	34
	.byte	37
	.byte	47
	.byte	50
	.byte	56
	.byte	59
	.byte	61
	.byte	35
	.byte	36
	.byte	48
	.byte	49
	.byte	57
	.byte	58
	.byte	62
	.byte	63

zig2:
	.byte	0
	.byte	2
	.byte	3
	.byte	9
	.byte	10
	.byte	20
	.byte	21
	.byte	35
	.byte	14
	.byte	16
	.byte	25
	.byte	31
	.byte	39
	.byte	46
	.byte	50
	.byte	57
	.byte	5
	.byte	7
	.byte	12
	.byte	18
	.byte	23
	.byte	33
	.byte	37
	.byte	48
	.byte	27
	.byte	29
	.byte	41
	.byte	44
	.byte	52
	.byte	55
	.byte	59
	.byte	62
	.byte	15
	.byte	26
	.byte	30
	.byte	40
	.byte	45
	.byte	51
	.byte	56
	.byte	58
	.byte	1
	.byte	4
	.byte	8
	.byte	11
	.byte	19
	.byte	22
	.byte	34
	.byte	36
	.byte	28
	.byte	42
	.byte	43
	.byte	53
	.byte	54
	.byte	60
	.byte	61
	.byte	63
	.byte	6
	.byte	13
	.byte	17
	.byte	24
	.byte	32
	.byte	38
	.byte	47
	.byte	49

getbyte:
	movl	datap, %edx
	movzbl	%es:(%edx), %eax
	incl	%edx
	movl	%edx, datap
	ret

getword:
	movl	datap, %edx
	movzwl	%es:(%edx), %eax
	addl	$2, %edx
	xchgb	%al,%ah
	movl	%edx, datap
	ret

fillbits:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	%eax, %edi
	movl	%edx, %ebx
	movl	%ecx, %esi
	cmpl	$0, 12(%eax)
	je	.L4
	cmpl	$16, %edx
	jg	.L3
	sall	$16, %esi
	addl	$16, %ebx
	movl	%esi, 4(%eax)
	jmp	.L3
.L4:
	cmpl	$24, %edx
	jg	.L7
.L13:
	movl	(%edi), %edx
	movzbl	(%edx), %ebp
	leal	1(%edx), %eax
	cmpl	$255, %ebp
	movl	%eax, (%edi)
	jne	.L9
	movzbl	1(%edx), %ecx
	leal	2(%edx), %eax
	testl	%ecx, %ecx
	movl	%eax, (%edi)
	je	.L9
	cmpl	$128, %ecx
	jne	.L10
	movl	16(%edi), %eax
	testl	%eax, %eax
	je	.L10
	pushl	20(%edi)
	call	*%eax
	movl	%eax, %ecx
	popl	%eax
	testl	%ecx, %ecx
	je	.L6
.L10:
	movl	%ecx, 12(%edi)
	cmpl	$16, %ebx
	jg	.L7
	sall	$16, %esi
	addl	$16, %ebx
	jmp	.L7
.L9:
	sall	$8, %esi
	addl	$8, %ebx
	orl	%ebp, %esi
.L6:
	cmpl	$24, %ebx
	jle	.L13
.L7:
	movl	%esi, 4(%edi)
.L3:
	movl	%ebx, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

dec_rec2:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$16, %esp
	movl	%eax, %ebp
	movl	8(%eax), %edi
	movl	4(%eax), %eax
	movl	40(%esp), %esi
	movl	%edx, 12(%esp)
	movl	%ecx, 8(%esp)
	movl	36(%esp), %ebx
	movl	%eax, 4(%esp)
	testl	%esi, %esi
	je	.L16
	movl	%esi, %eax
	sarl	$8, %esi
	andl	$127, %eax
	addl	%eax, %edi
	movl	%esi, %eax
	sarl	$8, %esi
	andl	$15, %eax
	jmp	.L31
.L16:
	movl	$8, %esi
	jmp	.L18
.L24:
	incl	%esi
.L18:
	addl	%ebx, %ebx
	testl	%edi, %edi
	movl	%ebx, (%esp)
	jg	.L23
	movl	%edi, %edx
	movl	4(%esp), %ecx
	movl	%ebp, %eax
	call	fillbits
	movl	4(%ebp), %edx
	movl	%eax, %edi
	movl	%edx, 4(%esp)
.L23:
	decl	%edi
	movl	4(%esp), %ebx
	movl	%edi, %ecx
	movl	12(%esp), %eax
	sarl	%cl, %ebx
	andl	$1, %ebx
	orl	(%esp), %ebx
	cmpl	(%eax,%esi,4), %ebx
	jge	.L24
	cmpl	$15, %esi
	jle	.L25
	movl	$-1, 12(%ebp)
	jmp	.L30
.L25:
	movl	12(%esp), %edx
	movl	8(%esp), %ecx
	movl	-4(%edx,%esi,4), %eax
	addl	68(%edx,%esi,4), %ebx
	addl	%eax, %eax
	subl	%eax, %ebx
	movzbl	132(%edx,%ebx), %esi
	movl	%esi, %eax
	andl	$15, %esi
	sarl	$4, %eax
.L31:
	movl	%eax, (%ecx)
	testl	%esi, %esi
	jne	.L26
	movl	4(%esp), %eax
	movl	%edi, 8(%ebp)
	movl	%eax, 4(%ebp)
.L30:
	xorl	%eax, %eax
	jmp	.L15
.L26:
	cmpl	%esi, %edi
	jge	.L28
	movl	%edi, %edx
	movl	4(%esp), %ecx
	movl	%ebp, %eax
	call	fillbits
	movl	4(%ebp), %edx
	movl	%eax, %edi
	movl	%edx, 4(%esp)
.L28:
	subl	%esi, %edi
	movl	$1, %eax
	movl	%edi, %ecx
	movl	4(%esp), %ebx
	sarl	%cl, %ebx
	movl	%eax, %edx
	movl	%esi, %ecx
	sall	%cl, %edx
	decl	%edx
	leal	-1(%esi), %ecx
	andl	%edx, %ebx
	sall	%cl, %eax
	cmpl	%eax, %ebx
	jge	.L29
	orl	$-1, %eax
	movl	%esi, %ecx
	sall	%cl, %eax
	leal	1(%eax,%ebx), %ebx
.L29:
	movl	4(%esp), %eax
	movl	%edi, 8(%ebp)
	movl	%eax, 4(%ebp)
	movl	%ebx, %eax
.L15:
	addl	$16, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

readtables:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$360, %esp
	movl	%eax, 36(%esp)
.L127:
	call	getbyte
	orl	$-1, %edx
	cmpl	$255, %eax
	jne	.L32
	call	getbyte
	xorl	%edx, %edx
	cmpl	36(%esp), %eax
	je	.L32
	cmpl	$196, %eax
	je	.L52
	jg	.L105
	cmpl	$194, %eax
	je	.L32
	jmp	.L99
.L105:
	cmpl	$219, %eax
	je	.L40
	cmpl	$221, %eax
	je	.L98
	jmp	.L99
.L40:
	call	getword
	movl	%eax, %edi
	cmpl	$2, %eax
	jle	.L127
.L51:
	call	getbyte
	orl	$-1, %edx
	movl	%eax, %ebp
	andl	$15, %ebp
	cmpl	$3, %ebp
	jg	.L32
	sarl	$4, %eax
	testl	%eax, %eax
	jne	.L32
	xorl	%esi, %esi
.L50:
	call	getbyte
	movl	%ebp, %ebx
	sall	$6, %ebx
	addl	$quant, %ebx
	movb	%al, (%esi,%ebx)
	incl	%esi
	cmpl	$63, %esi
	jle	.L50
	subl	$65, %edi
	cmpl	$2, %edi
	jg	.L51
	jmp	.L127
.L52:
	call	getword
	cmpl	$2, %eax
	movl	%eax, 32(%esp)
	jle	.L127
.L97:
	call	getbyte
	movl	%eax, %ecx
	sarl	$4, %eax
	andl	$15, %ecx
	leal	(%ecx,%eax,2), %edx
	decl	%eax
	movl	%edx, 28(%esp)
	setg	%dl
	decl	%ecx
	setg	%al
	orl	%edx, %eax
	orl	$-1, %edx
	testb	$1, %al
	jne	.L32
	xorl	%esi, %esi
.L61:
	call	getbyte
	movl	%eax, 296(%esp,%esi,4)
	incl	%esi
	cmpl	$15, %esi
	jle	.L61
	subl	$17, 32(%esp)
	xorl	%ebp, %ebp
	xorl	%esi, %esi
.L71:
	xorl	%edi, %edi
	cmpl	296(%esp,%esi,4), %edi
	jge	.L117
.L70:
	leal	360(%esp), %ecx
	incl	%edi
	leal	(%ecx,%ebp), %ebx
	call	getbyte
	incl	%ebp
	cmpl	296(%esp,%esi,4), %edi
	movb	%al, -320(%ebx)
	jl	.L70
.L117:
	movl	296(%esp,%esi,4), %eax
	incl	%esi
	subl	%eax, 32(%esp)
	cmpl	$15, %esi
	jle	.L71
	imull	$1412, 28(%esp), %eax
	leal	40(%esp), %edx
	addl	$dhuff, %eax
	movl	%eax, 24(%esp)
	movl	%edx, 20(%esp)
	xorl	%edi, %edi
.L76:
	movl	24(%esp), %ecx
	movl	$0, 388(%ecx,%edi,4)
	incl	%edi
	cmpl	$255, %edi
	jle	.L76
	movl	$0, 16(%esp)
	movl	$0, 12(%esp)
	xorl	%edi, %edi
	movl	$7, (%esp)
.L95:
	movl	24(%esp), %edx
	movl	12(%esp), %eax
	movl	%eax, 68(%edx,%edi,4)
	movl	296(%esp,%edi,4), %eax
	testl	%eax, %eax
	jle	.L123
	movl	%eax, 8(%esp)
.L94:
	movl	20(%esp), %ecx
	movl	12(%esp), %edx
	movb	(%ecx), %al
	incl	%ecx
	movl	%ecx, 20(%esp)
	movl	24(%esp), %ecx
	cmpl	$7, %edi
	movb	%al, 132(%ecx,%edx)
	jg	.L85
	movb	(%esp), %cl
	movl	$1, %ebp
	movl	16(%esp), %edx
	movl	$15, %esi
	sall	%cl, %ebp
	sall	%cl, %edx
	andl	%eax, %esi
	decl	%ebp
	movl	%edx, 4(%esp)
	js	.L85
.L93:
	leal	(%edi,%esi), %eax
	cmpl	$7, %eax
	jg	.L90
	movl	%esi, %ecx
	movl	%ebp, %ebx
	negl	%ecx
	subl	%edi, %ecx
	addl	$7, %ecx
	sarl	%cl, %ebx
	testl	%esi, %esi
	je	.L91
	leal	-1(%esi), %ecx
	movl	$1, %eax
	sall	%cl, %eax
	cmpl	%eax, %ebx
	jge	.L91
	orl	$-1, %eax
	movl	%esi, %ecx
	sall	%cl, %eax
	leal	1(%eax,%ebx), %ebx
.L91:
	movl	12(%esp), %edx
	movl	24(%esp), %ecx
	sall	$16, %ebx
	movzbl	132(%ecx,%edx), %eax
	andl	$240, %eax
	leal	(%esi,%edi), %edx
	sall	$4, %eax
	orl	%eax, %ebx
	movl	$7, %eax
	subl	%edx, %eax
	orl	%eax, %ebx
	orb	$-128, %bl
	jmp	.L92
.L90:
	movl	12(%esp), %edx
	movl	24(%esp), %ecx
	movl	%esi, %ebx
	movzbl	132(%ecx,%edx), %eax
	sall	$16, %ebx
	andl	$240, %eax
	sall	$4, %eax
	orl	%eax, %ebx
	orl	(%esp), %ebx
.L92:
	movl	4(%esp), %eax
	movl	24(%esp), %edx
	orl	%ebp, %eax
	decl	%ebp
	movl	%ebx, 388(%edx,%eax,4)
	jns	.L93
.L85:
	incl	16(%esp)
	incl	12(%esp)
	decl	8(%esp)
	jne	.L94
.L123:
	movl	24(%esp), %ecx
	movl	16(%esp), %eax
	decl	(%esp)
	movl	%eax, (%ecx,%edi,4)
	addl	%eax, %eax
	incl	%edi
	movl	%eax, 16(%esp)
	cmpl	$15, %edi
	jle	.L95
	movl	$131072, 64(%ecx)
	cmpl	$2, 32(%esp)
	jg	.L97
	jmp	.L127
.L98:
	call	getword
	call	getword
	movl	%eax, info+8
	jmp	.L127
.L99:
	call	getword
	movl	%eax, 32(%esp)
	decl	32(%esp)
	cmpl	$2, %eax
	jle	.L127
.L103:
	call	getbyte
	movl	32(%esp), %eax
	decl	32(%esp)
	cmpl	$2, %eax
	jg	.L103
	jmp	.L127
.L32:
	addl	$360, %esp
	movl	%edx, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

idct:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$296, %esp
	movl	%eax, 36(%esp)
	movl	316(%esp), %eax
	movl	%edx, 32(%esp)
	movl	%ecx, 28(%esp)
	movl	%eax, 24(%esp)
	cmpl	$1, 320(%esp)
	jne	.L129
	movl	36(%esp), %edx
	movl	(%ecx), %eax
	movl	$0, 4(%esp)
	imull	(%edx), %eax
	addl	%eax, 24(%esp)
.L134:
	movl	4(%esp), %ecx
	movl	24(%esp), %eax
	sarl	$11, %eax
	movl	32(%esp), %ebp
	movl	%eax, (%ebp,%ecx,4)
	incl	%ecx
	movl	%ecx, 4(%esp)
	cmpl	$63, %ecx
	jle	.L134
	jmp	.L128
.L129:
	leal	40(%esp), %eax
	movl	$zig2, (%esp)
	movl	%eax, 8(%esp)
	movl	$7, 4(%esp)
.L139:
	movl	(%esp), %ecx
	movl	28(%esp), %ebp
	movzbl	(%ecx), %edx
	incl	%ecx
	movl	%ecx, (%esp)
	movl	36(%esp), %ecx
	movl	(%ebp,%edx,4), %eax
	movl	(%esp), %ebp
	imull	(%ecx,%edx,4), %eax
	addl	%eax, 24(%esp)
	movl	28(%esp), %ecx
	movzbl	(%ebp), %edx
	incl	%ebp
	movl	%ebp, (%esp)
	movl	36(%esp), %ebp
	movl	(%ecx,%edx,4), %eax
	movl	(%ebp,%edx,4), %edi
	imull	%eax, %edi
	movl	(%esp), %eax
	movzbl	(%eax), %edx
	incl	%eax
	movl	%eax, (%esp)
	movl	(%ecx,%edx,4), %eax
	movl	(%esp), %ecx
	movl	(%ebp,%edx,4), %esi
	movl	28(%esp), %ebp
	movzbl	(%ecx), %edx
	incl	%ecx
	movl	%ecx, (%esp)
	movl	36(%esp), %ecx
	imull	%eax, %esi
	movl	(%ebp,%edx,4), %eax
	movl	(%esp), %ebp
	imull	(%ecx,%edx,4), %eax
	movl	%eax, 12(%esp)
	movl	28(%esp), %ecx
	movzbl	(%ebp), %edx
	incl	%ebp
	movl	%ebp, (%esp)
	movl	36(%esp), %ebp
	movl	(%ecx,%edx,4), %eax
	imull	(%ebp,%edx,4), %eax
	movl	%eax, 20(%esp)
	movl	(%esp), %eax
	movzbl	(%eax), %edx
	incl	%eax
	movl	%eax, (%esp)
	movl	(%ebp,%edx,4), %ebp
	movl	(%ecx,%edx,4), %eax
	movl	28(%esp), %ecx
	imull	%eax, %ebp
	movl	(%esp), %eax
	movzbl	(%eax), %edx
	incl	%eax
	movl	%eax, (%esp)
	movl	(%ecx,%edx,4), %eax
	movl	36(%esp), %ecx
	imull	(%ecx,%edx,4), %eax
	movl	%eax, 16(%esp)
	movl	(%esp), %eax
	movl	28(%esp), %ecx
	movzbl	(%eax), %edx
	incl	%eax
	movl	%eax, (%esp)
	movl	(%ecx,%edx,4), %eax
	movl	36(%esp), %ecx
	movl	(%ecx,%edx,4), %ebx
	movl	24(%esp), %ecx
	addl	20(%esp), %ecx
	imull	%eax, %ebx
	movl	24(%esp), %eax
	movl	%ecx, 24(%esp)
	movl	%esi, %ecx
	movl	24(%esp), %edx
	subl	16(%esp), %ecx
	addl	%esi, 16(%esp)
	imull	$2896, %ecx, %esi
	movl	24(%esp), %ecx
	subl	20(%esp), %eax
	addl	16(%esp), %ecx
	subl	16(%esp), %edx
	sarl	$11, %esi
	subl	16(%esp), %esi
	movl	%edx, 16(%esp)
	movl	%ecx, 24(%esp)
	movl	%eax, %ecx
	addl	%esi, %ecx
	subl	%esi, %eax
	movl	%ecx, 20(%esp)
	movl	%ebp, %ecx
	subl	12(%esp), %ecx
	addl	%ebp, 12(%esp)
	movl	%ecx, %ebp
	leal	(%ebx,%edi), %ecx
	subl	%ebx, %edi
	movl	%eax, %esi
	movl	%edi, %ebx
	movl	%ecx, %edi
	subl	12(%esp), %ecx
	addl	%edi, 12(%esp)
	leal	(%ebx,%ebp), %eax
	movl	20(%esp), %edx
	imull	$2896, %ecx, %edi
	imull	$1567, %eax, %ecx
	imull	$2217, %ebp, %eax
	imull	$5351, %ebx, %ebx
	sarl	$11, %ecx
	sarl	$11, %eax
	sarl	$11, %ebx
	leal	(%ecx,%eax), %ebp
	subl	%ecx, %ebx
	movl	24(%esp), %ecx
	subl	12(%esp), %ebx
	addl	12(%esp), %ecx
	movl	24(%esp), %eax
	sarl	$11, %edi
	movl	%ecx, 24(%esp)
	subl	%ebx, %edi
	movl	20(%esp), %ecx
	addl	%ebx, %ecx
	subl	%edi, %ebp
	movl	%ecx, 20(%esp)
	leal	(%edi,%esi), %ecx
	subl	%edi, %esi
	subl	12(%esp), %eax
	movl	%esi, %edi
	movl	%ecx, %esi
	movl	16(%esp), %ecx
	subl	%ebp, 16(%esp)
	addl	%ebp, %ecx
	movl	8(%esp), %ebp
	movl	%eax, 12(%esp)
	subl	%ebx, %edx
	movl	24(%esp), %eax
	movl	%ecx, 96(%ebp)
	movl	%eax, (%ebp)
	movl	%edx, %ebx
	movl	16(%esp), %ecx
	movl	20(%esp), %edx
	movl	12(%esp), %eax
	movl	%edx, 32(%ebp)
	movl	%esi, 64(%ebp)
	movl	%ecx, 128(%ebp)
	movl	%edi, 160(%ebp)
	movl	%ebx, 192(%ebp)
	movl	%eax, 224(%ebp)
	addl	$4, %ebp
	decl	4(%esp)
	movl	%ebp, 8(%esp)
	movl	$0, 24(%esp)
	jns	.L139
	movl	$0, 4(%esp)
.L144:
	movl	4(%esp), %edx
	sall	$5, %edx
	movl	40(%esp,%edx), %ecx
	movl	44(%esp,%edx), %ebp
	movl	%ecx, 24(%esp)
	movl	68(%esp,%edx), %ecx
	movl	%ebp, 20(%esp)
	movl	%ecx, 12(%esp)
	movl	24(%esp), %ecx
	movl	48(%esp,%edx), %esi
	addl	20(%esp), %ecx
	movl	52(%esp,%edx), %eax
	movl	%eax, 16(%esp)
	movl	24(%esp), %eax
	movl	%ecx, 24(%esp)
	movl	%esi, %ecx
	subl	16(%esp), %ecx
	addl	%esi, 16(%esp)
	imull	$2896, %ecx, %esi
	subl	20(%esp), %eax
	movl	24(%esp), %ecx
	addl	16(%esp), %ecx
	movl	%eax, 20(%esp)
	sarl	$11, %esi
	movl	24(%esp), %eax
	subl	16(%esp), %esi
	subl	16(%esp), %eax
	movl	%ecx, 24(%esp)
	movl	20(%esp), %ecx
	movl	56(%esp,%edx), %ebp
	addl	%esi, %ecx
	movl	%eax, 16(%esp)
	movl	20(%esp), %eax
	movl	%ecx, 20(%esp)
	movl	%ebp, %ecx
	movl	64(%esp,%edx), %ebx
	movl	60(%esp,%edx), %edi
	subl	12(%esp), %ecx
	addl	%ebp, 12(%esp)
	movl	%ecx, %ebp
	leal	(%ebx,%edi), %ecx
	subl	%ebx, %edi
	subl	%esi, %eax
	movl	%edi, %ebx
	movl	%ecx, %edi
	subl	12(%esp), %ecx
	movl	%eax, %esi
	leal	(%ebx,%ebp), %eax
	addl	%edi, 12(%esp)
	imull	$2896, %ecx, %edi
	imull	$1567, %eax, %ecx
	imull	$2217, %ebp, %eax
	imull	$5351, %ebx, %ebx
	sarl	$11, %ecx
	sarl	$11, %eax
	sarl	$11, %ebx
	leal	(%ecx,%eax), %ebp
	subl	%ecx, %ebx
	movl	24(%esp), %ecx
	subl	12(%esp), %ebx
	addl	12(%esp), %ecx
	movl	24(%esp), %eax
	subl	12(%esp), %eax
	movl	%ecx, 24(%esp)
	sarl	$11, %edi
	movl	20(%esp), %ecx
	subl	%ebx, %edi
	addl	%ebx, %ecx
	movl	%eax, 12(%esp)
	movl	20(%esp), %eax
	subl	%edi, %ebp
	movl	%ecx, 20(%esp)
	subl	%ebx, %eax
	leal	(%edi,%esi), %ecx
	subl	%edi, %esi
	movl	%eax, %ebx
	movl	%esi, %edi
	movl	%ecx, %esi
	movl	16(%esp), %ecx
	subl	%ebp, 16(%esp)
	sarl	$11, 24(%esp)
	addl	%ebp, %ecx
	movl	32(%esp), %ebp
	sarl	$11, 20(%esp)
	sarl	$11, 16(%esp)
	sarl	$11, %ecx
	movl	24(%esp), %eax
	sarl	$11, %esi
	movl	%eax, (%ebp,%edx)
	addl	%ebp, %edx
	movl	16(%esp), %eax
	sarl	$11, %edi
	movl	20(%esp), %ebp
	sarl	$11, %ebx
	movl	%ecx, 12(%edx)
	movl	%ebp, 4(%edx)
	movl	%esi, 8(%edx)
	movl	%eax, 16(%edx)
	movl	%edi, 20(%edx)
	movl	%ebx, 24(%edx)
	incl	4(%esp)
	sarl	$11, 12(%esp)
	movl	12(%esp), %ecx
	movl	%ecx, 28(%edx)
	cmpl	$7, 4(%esp)
	jle	.L144
.L128:
	addl	$296, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

idctqtab:
	pushl	%ebp
	movl	%eax, %ebp
	pushl	%edi
	movl	%edx, %edi
	pushl	%esi
	xorl	%esi, %esi
	pushl	%ebx
.L160:
	xorl	%ebx, %ebx
.L159:
	movl	aaidct(,%ebx,4), %eax
	imull	aaidct(,%esi,4), %eax
	movzbl	zig(%ebx,%esi,8), %ecx
	sarl	$11, %eax
	incl	%ebx
	movzbl	(%ecx,%ebp), %edx
	imull	%eax, %edx
	cmpl	$7, %ebx
	movl	%edx, (%edi,%ecx,4)
	jle	.L159
	incl	%esi
	cmpl	$7, %esi
	jle	.L160
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

scaleidctqtab:
	pushl	%ebx
	xorl	%ecx, %ecx
	movl	%eax, %ebx
.L170:
	movl	(%ebx,%ecx,4), %eax
	imull	%edx, %eax
	sarl	$11, %eax
	movl	%eax, (%ebx,%ecx,4)
	incl	%ecx
	cmpl	$63, %ecx
	jle	.L170
	popl	%ebx
	ret

jpeg_decode:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$132, %esp
	orl	$-1, %edx
	cmpl	$0, 160(%esp)
	je	.L173
	movl	152(%esp), %eax
	movl	%eax, datap
	call	getbyte
	movl	$1, %edx
	cmpl	$255, %eax
	jne	.L173
	call	getbyte
	movl	$1, %edx
	cmpl	$216, %eax
	jne	.L173
	movl	$192, %eax
	call	readtables
	movl	$14, %edx
	testl	%eax, %eax
	jne	.L173
	movl	$12, %edx
	cmpl	$0, info+8
	jne	.L173
	call	getword
	call	getbyte
	movl	$2, %edx
	cmpl	$8, %eax
	jne	.L173
	call	getword
	movl	%eax, 68(%esp)
	call	getword
	movl	%eax, 72(%esp)
	call	getbyte
	movl	$6, %edx
	movl	%eax, info
	cmpl	$4, %eax
	jg	.L173
	xorl	%esi, %esi
	cmpl	%eax, %esi
	jge	.L328
	xorl	%ebp, %ebp
.L187:
	call	getbyte
	movl	%eax, comps(%ebp)
	call	getbyte
	movl	%eax, %ebx
	movl	%eax, %edi
	movl	%eax, comps+4(%ebp)
	call	getbyte
	andl	$15, %ebx
	movl	%eax, %ecx
	sarl	$4, %edi
	movl	%eax, comps+8(%ebp)
	cmpl	$3, %edi
	setg	%dl
	cmpl	$3, %ebx
	setg	%al
	orl	%edx, %eax
	movl	$7, %edx
	testb	$1, %al
	jne	.L173
	movl	$8, %edx
	cmpl	$3, %ecx
	jg	.L173
	incl	%esi
	addl	$12, %ebp
	cmpl	info, %esi
	jl	.L187
.L328:
	movl	$218, %eax
	call	readtables
	movl	$14, %edx
	testl	%eax, %eax
	jne	.L173
	call	getword
	call	getbyte
	movl	$9, %edx
	movl	%eax, info+4
	cmpl	$3, %eax
	jne	.L173
	xorl	%esi, %esi
	xorl	%ebp, %ebp
.L202:
	call	getbyte
	movl	%eax, dscans+16(%ebp)
	call	getbyte
	movl	%eax, %edi
	andl	$15, %eax
	sarl	$4, %edi
	movl	%eax, 92(%esp)
	cmpl	$1, %edi
	setg	%dl
	decl	%eax
	setg	%al
	orl	%edx, %eax
	movl	$8, %edx
	testb	$1, %al
	jne	.L173
	xorl	%ebx, %ebx
	movl	info, %ecx
	cmpl	%ecx, %ebx
	jge	.L196
	movl	$comps, %edx
.L200:
	movl	dscans+16(%ebp), %eax
	cmpl	%eax, (%edx)
	je	.L196
	incl	%ebx
	addl	$12, %edx
	cmpl	%ecx, %ebx
	jl	.L200
.L196:
	movl	$10, %edx
	cmpl	%ecx, %ebx
	je	.L173
	imull	$12, %ebx, %edx
	incl	%esi
	movl	comps+4(%edx), %eax
	movl	%eax, dscans+20(%ebp)
	movl	comps+8(%edx), %eax
	movl	%eax, dscans+24(%ebp)
	imull	$1412, %edi, %eax
	addl	$dhuff, %eax
	movl	%eax, dscans+4(%ebp)
	imull	$1412, 92(%esp), %eax
	addl	$dhuff+2824, %eax
	movl	%eax, dscans+8(%ebp)
	addl	$28, %ebp
	cmpl	$2, %esi
	jle	.L202
	call	getbyte
	movl	%eax, %esi
	call	getbyte
	movl	%eax, %ebx
	call	getbyte
	testl	%esi, %esi
	movl	%eax, %ecx
	setne	%dl
	cmpl	$63, %ebx
	setne	%al
	orl	%edx, %eax
	testb	$1, %al
	jne	.L204
	testl	%ecx, %ecx
	je	.L203
.L204:
	movl	$11, %edx
	jmp	.L173
.L203:
	cmpl	$1, dscans+16
	jne	.L208
	cmpl	$2, dscans+44
	jne	.L208
	cmpl	$3, dscans+72
	jne	.L208
	cmpl	$34, dscans+20
	jne	.L208
	cmpl	$17, dscans+48
	jne	.L208
	cmpl	$17, dscans+76
	je	.L207
.L208:
	movl	$9, %edx
	jmp	.L173
.L207:
	movl	168(%esp), %eax
	movl	72(%esp), %edx
	addl	$15, %eax
	movl	68(%esp), %ecx
	sarl	$4, %eax
	movl	164(%esp), %ebx
	decl	%eax
	movl	172(%esp), %edi
	sarl	$4, %edx
	movl	%eax, 60(%esp)
	movl	176(%esp), %eax
	movl	%edx, 88(%esp)
	sarl	$4, %ecx
	addl	$15, %eax
	sarl	$4, %eax
	movl	%ecx, 84(%esp)
	sarl	$4, %ebx
	sarl	$4, %edi
	leal	-1(%eax), %edx
	movl	%ebx, 64(%esp)
	movl	%edi, 56(%esp)
	movl	%edx, 52(%esp)
	cmpl	%ecx, %edx
	jge	.L209
	movl	%eax, 84(%esp)
.L209:
	movl	dscans+24, %eax
	movl	160(%esp), %edx
	sall	$6, %eax
	addl	$3136, %edx
	addl	$quant, %eax
	call	idctqtab
	movl	160(%esp), %esi
	movl	dscans+52, %eax
	addl	$3392, %esi
	sall	$6, %eax
	movl	%esi, %edx
	addl	$quant, %eax
	call	idctqtab
	movl	160(%esp), %ebx
	movl	dscans+80, %eax
	addl	$3648, %ebx
	sall	$6, %eax
	movl	%ebx, %edx
	addl	$quant, %eax
	call	idctqtab
	movl	$3629, %edx
	movl	%esi, %eax
	call	scaleidctqtab
	movl	%ebx, %eax
	movl	$2871, %edx
	call	scaleidctqtab
	movl	datap, %eax
	movl	%eax, in
	movl	info+4, %eax
	movl	$0, in+8
	movl	$0, in+4
	movl	$0, in+12
	testl	%eax, %eax
	jle	.L333
	movl	$dscans, %edx
.L216:
	movl	$0, (%edx)
	addl	$28, %edx
	decl	%eax
	jne	.L216
.L333:
	movl	$0, 76(%esp)
	movl	84(%esp), %ecx
	movl	$2, dscans+12
	movl	$1, dscans+40
	movl	$0, dscans+68
	cmpl	%ecx, 76(%esp)
	jge	.L335
.L326:
	movl	$0, 80(%esp)
	movl	88(%esp), %ebx
	cmpl	%ebx, 80(%esp)
	jge	.L337
.L325:
	movl	160(%esp), %esi
	leal	100(%esp), %edi
	movl	$dscans, 44(%esp)
	movl	%edi, 40(%esp)
	movl	%esi, %eax
	movl	$1535, %edx
.L229:
	decl	%edx
	movb	$0, (%eax)
	incl	%eax
	cmpl	$-1, %edx
	jne	.L229
	movl	in+4, %eax
	movl	in+8, %ebx
	movl	%eax, (%esp)
	movl	$5, 48(%esp)
.L248:
	movl	44(%esp), %edx
	movl	%esi, %ebp
	addl	$4, %esi
	cmpl	$7, %ebx
	movl	4(%edx), %edi
	jg	.L235
	movl	(%esp), %ecx
	movl	%ebx, %edx
	movl	$in, %eax
	call	fillbits
	movl	in+4, %ecx
	movl	%eax, %ebx
	movl	%ecx, (%esp)
.L235:
	subl	$8, %ebx
	movl	(%esp), %eax
	movb	%bl, %cl
	sarl	%cl, %eax
	andl	$255, %eax
	movl	%eax, 96(%esp)
	movl	388(%edi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L236
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %ebx
	movl	%edx, %eax
	andl	$15, %eax
	movl	%eax, 96(%esp)
	movl	%edx, %eax
	sarl	$8, %eax
	jmp	.L237
.L356:
	leal	(%esi,%ebp,4), %esi
	jmp	.L239
.L236:
	movl	%ebx, in+8
	movl	(%esp), %ebx
	pushl	%edx
	pushl	%eax
	leal	104(%esp), %ecx
	movl	%edi, %edx
	movl	$in, %eax
	movl	%ebx, in+4
	call	dec_rec2
	popl	%ebx
	popl	%edi
	movl	in+4, %edi
	movl	in+8, %ebx
	movl	%edi, (%esp)
.L237:
	movl	44(%esp), %edx
	addl	(%edx), %eax
	movl	%eax, (%edx)
	movl	%eax, (%ebp)
	movl	8(%edx), %edi
	movl	$63, %ebp
.L246:
	cmpl	$7, %ebx
	jg	.L242
	movl	(%esp), %ecx
	movl	%ebx, %edx
	movl	$in, %eax
	call	fillbits
	movl	in+4, %ecx
	movl	%eax, %ebx
	movl	%ecx, (%esp)
.L242:
	subl	$8, %ebx
	movl	(%esp), %eax
	movb	%bl, %cl
	sarl	%cl, %eax
	andl	$255, %eax
	movl	%eax, 96(%esp)
	movl	388(%edi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L243
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %ebx
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$15, %eax
	movl	%eax, 96(%esp)
	jmp	.L244
.L243:
	movl	%ebx, in+8
	movl	(%esp), %ebx
	pushl	%edx
	pushl	%eax
	leal	104(%esp), %ecx
	movl	%edi, %edx
	movl	$in, %eax
	movl	%ebx, in+4
	call	dec_rec2
	popl	%edx
	popl	%ecx
	movl	%eax, %edx
	movl	in+4, %eax
	movl	in+8, %ebx
	movl	%eax, (%esp)
.L244:
	testl	%edx, %edx
	jne	.L245
	cmpl	$0, 96(%esp)
	je	.L356
.L245:
	movl	96(%esp), %eax
	subl	%eax, %ebp
	leal	(%esi,%eax,4), %esi
	leal	-1(%ebp), %ebp
	movl	%edx, (%esi)
	addl	$4, %esi
	testl	%ebp, %ebp
	jg	.L246
.L239:
	movl	40(%esp), %edx
	movl	$64, %eax
	subl	%ebp, %eax
	movl	44(%esp), %ecx
	movl	%eax, (%edx)
	movl	48(%esp), %edi
	addl	$4, %edx
	cmpl	12(%ecx), %edi
	movl	%edx, 40(%esp)
	jne	.L231
	addl	$28, %ecx
	movl	%ecx, 44(%esp)
.L231:
	movl	48(%esp), %eax
	decl	48(%esp)
	testl	%eax, %eax
	jg	.L248
	movl	(%esp), %eax
	movl	56(%esp), %edx
	movl	52(%esp), %ecx
	cmpl	%edx, 76(%esp)
	movl	%eax, in+4
	movl	%ebx, in+8
	setge	%dl
	cmpl	%ecx, 76(%esp)
	setle	%al
	andl	%edx, %eax
	testb	$1, %al
	je	.L224
	movl	64(%esp), %ebx
	movl	60(%esp), %edi
	cmpl	%ebx, 80(%esp)
	setge	%dl
	cmpl	%edi, 80(%esp)
	setle	%al
	andl	%edx, %eax
	testb	$1, %al
	je	.L224
	movl	160(%esp), %ebx
	movl	160(%esp), %esi
	pushl	100(%esp)
	addl	$3136, %ebx
	pushl	$263168
	addl	$1600, %esi
	movl	168(%esp), %eax
	movl	%ebx, %ecx
	movl	%esi, %edx
	call	idct
	movl	%ebx, %ecx
	pushl	112(%esp)
	pushl	$263168
	movl	176(%esp), %eax
	leal	1856(%eax), %edx
	addl	$256, %eax
	call	idct
	movl	%ebx, %ecx
	pushl	124(%esp)
	pushl	$263168
	movl	184(%esp), %edi
	leal	2112(%edi), %edx
	leal	512(%edi), %eax
	call	idct
	movl	%ebx, %ecx
	pushl	136(%esp)
	leal	2368(%edi), %edx
	pushl	$263168
	leal	768(%edi), %eax
	movl	%edi, %ebx
	call	idct
	addl	$32, %esp
	pushl	116(%esp)
	addl	$2624, %ebx
	pushl	$1024
	leal	3392(%edi), %ecx
	movl	%ebx, %edx
	leal	1024(%edi), %eax
	call	idct
	leal	3648(%edi), %ecx
	pushl	128(%esp)
	leal	2880(%edi), %edx
	pushl	$1024
	leal	1280(%edi), %eax
	call	idct
	addl	$16, %esp
	movl	$tmp_img, 20(%esp)
	movl	$tmp_img+32, 16(%esp)
	movl	%ebx, 12(%esp)
	movl	$2, 28(%esp)
.L305:
	movl	$4, 24(%esp)
.L304:
	xorl	%edi, %edi
.L303:
	movl	12(%esp), %edx
	movl	12(%esp), %eax
	movl	256(%edx,%edi,4), %edx
	movl	(%eax,%edi,4), %eax
	movl	%edx, 8(%esp)
	movl	%eax, 4(%esp)
	imull	$50, %eax, %edx
	imull	$130, 8(%esp), %eax
	leal	128(%eax,%edx), %ebp
	movl	$4, %edx
	movl	%edi, %eax
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%edi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	sarl	$8, %ebp
	leal	(%edx,%ecx), %eax
	movl	8(%esp), %edx
	movl	(%esi,%eax,8), %ebx
	leal	7(%edx,%ebx), %eax
	cmpl	$255, %eax
	ja	.L263
	movl	%eax, %ecx
	andl	$248, %ecx
	sall	$8, %ecx
	jmp	.L264
.L263:
	movl	%eax, %ecx
	sarl	$31, %ecx
	notl	%ecx
	andl	$63488, %ecx
.L264:
	movl	%ebx, %eax
	subl	%ebp, %eax
	leal	3(%eax), %edx
	cmpl	$255, %edx
	ja	.L267
	andl	$252, %edx
	leal	0(,%edx,8), %eax
	orl	%ecx, %eax
	jmp	.L268
.L267:
	movl	%ecx, %eax
	testl	%edx, %edx
	js	.L268
	orl	$2016, %eax
.L268:
	movl	4(%esp), %edx
	leal	7(%edx,%ebx), %ecx
	cmpl	$255, %ecx
	ja	.L270
	movl	%ecx, %edx
	sarl	$3, %edx
	orl	%eax, %edx
	jmp	.L271
.L270:
	movl	%eax, %edx
	testl	%ecx, %ecx
	js	.L271
	orl	$31, %edx
.L271:
	movl	20(%esp), %ecx
	movl	%edx, %eax
	sarl	$8, %eax
	movb	%al, (%ecx,%edi,4)
	movb	%dl, 1(%ecx,%edi,4)
	movl	%edi, %eax
	movl	$4, %edx
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%edi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	8(%esp), %edx
	movl	4(%esi,%eax,8), %ebx
	leal	1(%edx,%ebx), %eax
	cmpl	$255, %eax
	ja	.L273
	andl	$248, %eax
	sall	$8, %eax
	jmp	.L274
.L273:
	sarl	$31, %eax
	notl	%eax
	andl	$63488, %eax
.L274:
	movl	%ebx, %edx
	subl	%ebp, %edx
	cmpl	$255, %edx
	ja	.L277
	andl	$252, %edx
	leal	0(,%edx,8), %ecx
	orl	%eax, %ecx
	jmp	.L278
.L277:
	movl	%eax, %ecx
	testl	%edx, %edx
	js	.L278
	orl	$2016, %ecx
.L278:
	movl	4(%esp), %eax
	leal	1(%eax,%ebx), %edx
	cmpl	$255, %edx
	ja	.L280
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ecx, %eax
	jmp	.L281
.L280:
	movl	%ecx, %eax
	testl	%edx, %edx
	js	.L281
	orl	$31, %eax
.L281:
	movl	20(%esp), %edx
	movl	%eax, %ebx
	sarl	$8, %eax
	movb	%al, 2(%edx,%edi,4)
	movb	%bl, 3(%edx,%edi,4)
	movl	%edi, %eax
	movl	$4, %edx
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%edi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	8(%esp), %edx
	movl	32(%esi,%eax,8), %ebx
	leal	3(%edx,%ebx), %eax
	cmpl	$255, %eax
	ja	.L283
	movl	%eax, %ecx
	andl	$248, %ecx
	sall	$8, %ecx
	jmp	.L284
.L283:
	movl	%eax, %ecx
	sarl	$31, %ecx
	notl	%ecx
	andl	$63488, %ecx
.L284:
	movl	%ebx, %eax
	subl	%ebp, %eax
	leal	1(%eax), %edx
	cmpl	$255, %edx
	ja	.L287
	andl	$252, %edx
	leal	0(,%edx,8), %eax
	orl	%ecx, %eax
	jmp	.L288
.L287:
	movl	%ecx, %eax
	testl	%edx, %edx
	js	.L288
	orl	$2016, %eax
.L288:
	movl	4(%esp), %edx
	leal	3(%edx,%ebx), %ecx
	cmpl	$255, %ecx
	ja	.L290
	movl	%ecx, %edx
	sarl	$3, %edx
	orl	%eax, %edx
	jmp	.L291
.L290:
	movl	%eax, %edx
	testl	%ecx, %ecx
	js	.L291
	orl	$31, %edx
.L291:
	movl	16(%esp), %ecx
	movl	%edx, %eax
	sarl	$8, %eax
	movb	%al, (%ecx,%edi,4)
	movb	%dl, 1(%ecx,%edi,4)
	movl	%edi, %eax
	movl	$4, %edx
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%edi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	8(%esp), %edx
	movl	36(%esi,%eax,8), %ebx
	leal	5(%edx,%ebx), %eax
	cmpl	$255, %eax
	ja	.L293
	movl	%eax, %ecx
	andl	$248, %ecx
	sall	$8, %ecx
	jmp	.L294
.L293:
	movl	%eax, %ecx
	sarl	$31, %ecx
	notl	%ecx
	andl	$63488, %ecx
.L294:
	movl	%ebx, %eax
	subl	%ebp, %eax
	leal	2(%eax), %edx
	cmpl	$255, %edx
	ja	.L297
	andl	$252, %edx
	leal	0(,%edx,8), %eax
	orl	%ecx, %eax
	jmp	.L298
.L297:
	movl	%ecx, %eax
	testl	%edx, %edx
	js	.L298
	orl	$2016, %eax
.L298:
	movl	4(%esp), %ecx
	leal	5(%ecx,%ebx), %edx
	cmpl	$255, %edx
	ja	.L300
	movl	%edx, %ecx
	sarl	$3, %ecx
	orl	%eax, %ecx
	jmp	.L301
.L300:
	movl	%eax, %ecx
	testl	%edx, %edx
	js	.L301
	orl	$31, %ecx
.L301:
	movl	16(%esp), %ebx
	movl	%ecx, %eax
	sarl	$8, %eax
	movb	%al, 2(%ebx,%edi,4)
	movb	%cl, 3(%ebx,%edi,4)
	incl	%edi
	cmpl	$7, %edi
	jle	.L303
	decl	24(%esp)
	addl	$64, %ebx
	addl	$32, 12(%esp)
	addl	$64, %esi
	movl	%ebx, 16(%esp)
	addl	$64, 20(%esp)
	cmpl	$0, 24(%esp)
	jg	.L304
	decl	28(%esp)
	addl	$256, %esi
	cmpl	$0, 28(%esp)
	jg	.L305
	movl	56(%esp), %edi
	xorl	%edx, %edx
	cmpl	%edi, 76(%esp)
	jne	.L308
	movl	76(%esp), %eax
	movl	172(%esp), %edx
	sall	$4, %eax
	subl	%eax, %edx
.L308:
	movl	52(%esp), %eax
	movl	$16, 32(%esp)
	cmpl	%eax, 76(%esp)
	jne	.L310
	movl	76(%esp), %eax
	movl	176(%esp), %ecx
	sall	$4, %eax
	subl	%eax, %ecx
	movl	%ecx, 32(%esp)
.L310:
	movl	%edx, %ebx
	cmpl	32(%esp), %edx
	jge	.L224
	movl	%edx, %ebp
	sall	$4, %ebp
.L324:
	movl	76(%esp), %eax
	xorl	%edx, %edx
	sall	$4, %eax
	subl	172(%esp), %eax
	leal	(%ebx,%eax), %edi
	movl	168(%esp), %eax
	subl	164(%esp), %eax
	imull	%eax, %edi
	movl	64(%esp), %eax
	cmpl	%eax, 80(%esp)
	jne	.L316
	movl	80(%esp), %eax
	movl	164(%esp), %edx
	sall	$4, %eax
	subl	%eax, %edx
.L316:
	movl	60(%esp), %ecx
	movl	$16, 36(%esp)
	cmpl	%ecx, 80(%esp)
	jne	.L318
	movl	80(%esp), %eax
	movl	168(%esp), %ecx
	sall	$4, %eax
	subl	%eax, %ecx
	movl	%ecx, 36(%esp)
.L318:
	movl	%edx, %esi
	cmpl	36(%esp), %edx
	jge	.L351
.L323:
	movl	80(%esp), %eax
	movl	164(%esp), %edx
	sall	$5, %eax
	addl	%edx, %edx
	addl	156(%esp), %eax
	leal	(%edi,%esi), %ecx
	subl	%edx, %eax
	leal	(%esi,%ebp), %edx
	incl	%esi
	movw	tmp_img(%edx,%edx), %dx
	cmpl	36(%esp), %esi
	movw	%dx, %fs:(%eax,%ecx,2)
	jl	.L323
.L351:
	incl	%ebx
	addl	$16, %ebp
	cmpl	32(%esp), %ebx
	jl	.L324
.L224:
	incl	80(%esp)
	movl	88(%esp), %ebx
	cmpl	%ebx, 80(%esp)
	jl	.L325
.L337:
	incl	76(%esp)
	movl	84(%esp), %edi
	cmpl	%edi, 76(%esp)
	jl	.L326
.L335:
	xorl	%edx, %edx
.L173:
	addl	$132, %esp
	movl	%edx, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

jpeg_get_size:
	pushl	%esi
	pushl	%ebx
	movl	12(%esp), %eax
	movl	20(%esp), %ebx
	movl	16(%esp), %esi
	movl	%eax, datap
	call	getbyte
	call	getbyte
	movl	$192, %eax
	call	readtables
	call	getword
	call	getbyte
	call	getword
	testl	%ebx, %ebx
	je	.L358
	movl	%eax, (%ebx)
.L358:
	call	getword
	testl	%esi, %esi
	je	.L357
	movl	%eax, (%esi)
.L357:
	popl	%ebx
	popl	%esi
	ret
