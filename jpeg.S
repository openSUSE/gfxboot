	.file	"jpg.c"
	.text
	.code16
	.align 32
	.type	aaidct, @object
	.size	aaidct, 32
aaidct:
	.long	724
	.long	1004
	.long	946
	.long	851
	.long	724
	.long	569
	.long	392
	.long	200
	.align 32
	.type	zig, @object
	.size	zig, 64
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
	.align 32
	.type	zig2, @object
	.size	zig2, 64
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

	.type	getbyte, @function
getbyte:
	movl	datap, %edx
	movzbl	(%edx), %eax
	incl	%edx
	movl	%edx, datap
	ret
	.size	getbyte, .-getbyte
	.type	getword, @function
getword:
	movl	datap, %edx
	leal	1(%edx), %ecx
	movzbl	(%edx), %eax
	sall	$8, %eax
	movl	%ecx, datap
	movzbl	1(%edx), %ecx
	addl	$2, %edx
	orl	%ecx, %eax
	movl	%edx, datap
	ret
	.size	getword, .-getword
	.type	fillbits, @function
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
	.size	fillbits, .-fillbits
	.type	dec_readmarker, @function
dec_readmarker:
	pushl	%ebx
	movl	%eax, %ebx
	movl	8(%eax), %edx
	movl	4(%eax), %ecx
	call	fillbits
	xorl	%edx, %edx
	movl	%eax, 8(%ebx)
	movl	12(%ebx), %eax
	testl	%eax, %eax
	je	.L15
	movl	$0, 8(%ebx)
	movl	$0, 12(%ebx)
	movl	%eax, %edx
.L15:
	movl	%edx, %eax
	popl	%ebx
	ret
	.size	dec_readmarker, .-dec_readmarker
	.type	dec_rec2, @function
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
	je	.L18
	movl	%esi, %eax
	sarl	$8, %esi
	andl	$127, %eax
	addl	%eax, %edi
	movl	%esi, %eax
	sarl	$8, %esi
	andl	$15, %eax
	jmp	.L33
.L18:
	movl	$10, %esi
	jmp	.L20
.L26:
	incl	%esi
.L20:
	addl	%ebx, %ebx
	testl	%edi, %edi
	movl	%ebx, (%esp)
	jg	.L25
	movl	%edi, %edx
	movl	4(%esp), %ecx
	movl	%ebp, %eax
	call	fillbits
	movl	4(%ebp), %edx
	movl	%eax, %edi
	movl	%edx, 4(%esp)
.L25:
	decl	%edi
	movl	4(%esp), %ebx
	movl	%edi, %ecx
	movl	12(%esp), %eax
	sarl	%cl, %ebx
	andl	$1, %ebx
	orl	(%esp), %ebx
	cmpl	(%eax,%esi,4), %ebx
	jge	.L26
	cmpl	$15, %esi
	jle	.L27
	movl	$-1, 12(%ebp)
	jmp	.L32
.L27:
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
.L33:
	movl	%eax, (%ecx)
	testl	%esi, %esi
	jne	.L28
	movl	4(%esp), %eax
	movl	%edi, 8(%ebp)
	movl	%eax, 4(%ebp)
.L32:
	xorl	%eax, %eax
	jmp	.L17
.L28:
	cmpl	%esi, %edi
	jge	.L30
	movl	%edi, %edx
	movl	4(%esp), %ecx
	movl	%ebp, %eax
	call	fillbits
	movl	4(%ebp), %edx
	movl	%eax, %edi
	movl	%edx, 4(%esp)
.L30:
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
	jge	.L31
	orl	$-1, %eax
	movl	%esi, %ecx
	sall	%cl, %eax
	leal	1(%eax,%ebx), %ebx
.L31:
	movl	4(%esp), %eax
	movl	%edi, 8(%ebp)
	movl	%eax, 4(%ebp)
	movl	%ebx, %eax
.L17:
	addl	$16, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.size	dec_rec2, .-dec_rec2
	.type	readtables, @function
readtables:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$360, %esp
	movl	%eax, 36(%esp)
.L129:
	call	getbyte
	orl	$-1, %edx
	cmpl	$255, %eax
	jne	.L34
	call	getbyte
	xorl	%edx, %edx
	cmpl	36(%esp), %eax
	je	.L34
	cmpl	$196, %eax
	je	.L54
	jg	.L107
	cmpl	$194, %eax
	je	.L34
	jmp	.L101
.L107:
	cmpl	$219, %eax
	je	.L42
	cmpl	$221, %eax
	je	.L100
	jmp	.L101
.L42:
	call	getword
	movl	%eax, %edi
	cmpl	$2, %eax
	jle	.L129
.L53:
	call	getbyte
	orl	$-1, %edx
	movl	%eax, %ebp
	andl	$15, %ebp
	cmpl	$3, %ebp
	jg	.L34
	sarl	$4, %eax
	testl	%eax, %eax
	jne	.L34
	xorl	%esi, %esi
.L52:
	call	getbyte
	movl	%ebp, %ebx
	sall	$6, %ebx
	addl	$quant, %ebx
	movb	%al, (%esi,%ebx)
	incl	%esi
	cmpl	$63, %esi
	jle	.L52
	subl	$65, %edi
	cmpl	$2, %edi
	jg	.L53
	jmp	.L129
.L54:
	call	getword
	cmpl	$2, %eax
	movl	%eax, 32(%esp)
	jle	.L129
.L99:
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
	jne	.L34
	xorl	%esi, %esi
.L63:
	call	getbyte
	movl	%eax, 296(%esp,%esi,4)
	incl	%esi
	cmpl	$15, %esi
	jle	.L63
	subl	$17, 32(%esp)
	xorl	%ebp, %ebp
	xorl	%esi, %esi
.L73:
	xorl	%edi, %edi
	cmpl	296(%esp,%esi,4), %edi
	jge	.L119
.L72:
	leal	360(%esp), %ecx
	incl	%edi
	leal	(%ecx,%ebp), %ebx
	call	getbyte
	incl	%ebp
	cmpl	296(%esp,%esi,4), %edi
	movb	%al, -320(%ebx)
	jl	.L72
.L119:
	movl	296(%esp,%esi,4), %eax
	incl	%esi
	subl	%eax, 32(%esp)
	cmpl	$15, %esi
	jle	.L73
	imull	$4484, 28(%esp), %eax
	leal	40(%esp), %edx
	addl	$dhuff, %eax
	movl	%eax, 24(%esp)
	movl	%edx, 20(%esp)
	xorl	%edi, %edi
.L78:
	movl	24(%esp), %ecx
	movl	$0, 388(%ecx,%edi,4)
	incl	%edi
	cmpl	$1023, %edi
	jle	.L78
	movl	$0, 16(%esp)
	movl	$0, 12(%esp)
	xorl	%edi, %edi
	movl	$9, (%esp)
.L97:
	movl	24(%esp), %edx
	movl	12(%esp), %eax
	movl	%eax, 68(%edx,%edi,4)
	movl	296(%esp,%edi,4), %eax
	testl	%eax, %eax
	jle	.L125
	movl	%eax, 8(%esp)
.L96:
	movl	20(%esp), %ecx
	movl	12(%esp), %edx
	movb	(%ecx), %al
	incl	%ecx
	movl	%ecx, 20(%esp)
	movl	24(%esp), %ecx
	cmpl	$9, %edi
	movb	%al, 132(%ecx,%edx)
	jg	.L87
	movb	(%esp), %cl
	movl	$1, %ebp
	movl	16(%esp), %edx
	movl	$15, %esi
	sall	%cl, %ebp
	sall	%cl, %edx
	andl	%eax, %esi
	decl	%ebp
	movl	%edx, 4(%esp)
	js	.L87
.L95:
	leal	(%edi,%esi), %eax
	cmpl	$9, %eax
	jg	.L92
	movl	%esi, %ecx
	movl	%ebp, %ebx
	negl	%ecx
	subl	%edi, %ecx
	addl	$9, %ecx
	sarl	%cl, %ebx
	testl	%esi, %esi
	je	.L93
	leal	-1(%esi), %ecx
	movl	$1, %eax
	sall	%cl, %eax
	cmpl	%eax, %ebx
	jge	.L93
	orl	$-1, %eax
	movl	%esi, %ecx
	sall	%cl, %eax
	leal	1(%eax,%ebx), %ebx
.L93:
	movl	12(%esp), %edx
	movl	24(%esp), %ecx
	sall	$16, %ebx
	movzbl	132(%ecx,%edx), %eax
	andl	$240, %eax
	leal	(%esi,%edi), %edx
	sall	$4, %eax
	orl	%eax, %ebx
	movl	$9, %eax
	subl	%edx, %eax
	orl	%eax, %ebx
	orb	$-128, %bl
	jmp	.L94
.L92:
	movl	12(%esp), %edx
	movl	24(%esp), %ecx
	movl	%esi, %ebx
	movzbl	132(%ecx,%edx), %eax
	sall	$16, %ebx
	andl	$240, %eax
	sall	$4, %eax
	orl	%eax, %ebx
	orl	(%esp), %ebx
.L94:
	movl	4(%esp), %eax
	movl	24(%esp), %edx
	orl	%ebp, %eax
	decl	%ebp
	movl	%ebx, 388(%edx,%eax,4)
	jns	.L95
.L87:
	incl	16(%esp)
	incl	12(%esp)
	decl	8(%esp)
	jne	.L96
.L125:
	movl	24(%esp), %ecx
	movl	16(%esp), %eax
	decl	(%esp)
	movl	%eax, (%ecx,%edi,4)
	addl	%eax, %eax
	incl	%edi
	movl	%eax, 16(%esp)
	cmpl	$15, %edi
	jle	.L97
	movl	$131072, 64(%ecx)
	cmpl	$2, 32(%esp)
	jg	.L99
	jmp	.L129
.L100:
	call	getword
	call	getword
	movl	%eax, info+8
	jmp	.L129
.L101:
	call	getword
	movl	%eax, 32(%esp)
	decl	32(%esp)
	cmpl	$2, %eax
	jle	.L129
.L105:
	call	getbyte
	movl	32(%esp), %eax
	decl	32(%esp)
	cmpl	$2, %eax
	jg	.L105
	jmp	.L129
.L34:
	addl	$360, %esp
	movl	%edx, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.size	readtables, .-readtables
	.type	idct, @function
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
	jne	.L131
	movl	36(%esp), %edx
	movl	(%ecx), %eax
	movl	$0, 4(%esp)
	imull	(%edx), %eax
	addl	%eax, 24(%esp)
.L136:
	movl	4(%esp), %ecx
	movl	24(%esp), %eax
	sarl	$11, %eax
	movl	32(%esp), %ebp
	movl	%eax, (%ebp,%ecx,4)
	incl	%ecx
	movl	%ecx, 4(%esp)
	cmpl	$63, %ecx
	jle	.L136
	jmp	.L130
.L131:
	leal	40(%esp), %eax
	movl	$zig2, (%esp)
	movl	%eax, 8(%esp)
	movl	$7, 4(%esp)
.L141:
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
	jns	.L141
	movl	$0, 4(%esp)
.L146:
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
	jle	.L146
.L130:
	addl	$296, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.size	idct, .-idct
	.type	idctqtab, @function
idctqtab:
	pushl	%ebp
	movl	%eax, %ebp
	pushl	%edi
	movl	%edx, %edi
	pushl	%esi
	xorl	%esi, %esi
	pushl	%ebx
.L162:
	xorl	%ebx, %ebx
.L161:
	movl	aaidct(,%ebx,4), %eax
	imull	aaidct(,%esi,4), %eax
	movzbl	zig(%ebx,%esi,8), %ecx
	sarl	$11, %eax
	incl	%ebx
	movzbl	(%ecx,%ebp), %edx
	imull	%eax, %edx
	cmpl	$7, %ebx
	movl	%edx, (%edi,%ecx,4)
	jle	.L161
	incl	%esi
	cmpl	$7, %esi
	jle	.L162
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.size	idctqtab, .-idctqtab
	.type	scaleidctqtab, @function
scaleidctqtab:
	pushl	%ebx
	xorl	%ecx, %ecx
	movl	%eax, %ebx
.L172:
	movl	(%ebx,%ecx,4), %eax
	imull	%edx, %eax
	sarl	$11, %eax
	movl	%eax, (%ebx,%ecx,4)
	incl	%ecx
	cmpl	$63, %ecx
	jle	.L172
	popl	%ebx
	ret
	.size	scaleidctqtab, .-scaleidctqtab
.globl jpeg_decode
	.type	jpeg_decode, @function
jpeg_decode:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$152, %esp
	orl	$-1, %edx
	cmpl	$0, 192(%esp)
	je	.L175
	movl	172(%esp), %eax
	movl	%eax, datap
	call	getbyte
	movl	$1, %edx
	cmpl	$255, %eax
	jne	.L175
	call	getbyte
	movl	$1, %edx
	cmpl	$216, %eax
	jne	.L175
	movl	$192, %eax
	call	readtables
	movl	$14, %edx
	testl	%eax, %eax
	jne	.L175
	call	getword
	call	getbyte
	movl	$2, %edx
	cmpl	$8, %eax
	jne	.L175
	call	getword
	movl	$3, %edx
	addl	$15, %eax
	andl	$-16, %eax
	cmpl	184(%esp), %eax
	jne	.L175
	call	getword
	movl	$4, %edx
	addl	$15, %eax
	andl	$-16, %eax
	cmpl	180(%esp), %eax
	jne	.L175
	call	getbyte
	movl	$6, %edx
	movl	%eax, info
	cmpl	$4, %eax
	jg	.L175
	xorl	%esi, %esi
	cmpl	%eax, %esi
	jge	.L392
	xorl	%ebp, %ebp
.L192:
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
	jne	.L175
	movl	$8, %edx
	cmpl	$3, %ecx
	jg	.L175
	incl	%esi
	addl	$12, %ebp
	cmpl	info, %esi
	jl	.L192
.L392:
	movl	$218, %eax
	call	readtables
	movl	$14, %edx
	testl	%eax, %eax
	jne	.L175
	call	getword
	call	getbyte
	movl	$9, %edx
	movl	%eax, info+4
	cmpl	$3, %eax
	jne	.L175
	xorl	%esi, %esi
	xorl	%ebp, %ebp
.L207:
	call	getbyte
	movl	%eax, dscans+16(%ebp)
	call	getbyte
	movl	%eax, %edi
	andl	$15, %eax
	sarl	$4, %edi
	movl	%eax, 112(%esp)
	cmpl	$1, %edi
	setg	%dl
	decl	%eax
	setg	%al
	orl	%edx, %eax
	movl	$8, %edx
	testb	$1, %al
	jne	.L175
	xorl	%ebx, %ebx
	movl	info, %ecx
	cmpl	%ecx, %ebx
	jge	.L201
	movl	$comps, %edx
.L205:
	movl	dscans+16(%ebp), %eax
	cmpl	%eax, (%edx)
	je	.L201
	incl	%ebx
	addl	$12, %edx
	cmpl	%ecx, %ebx
	jl	.L205
.L201:
	movl	$10, %edx
	cmpl	%ecx, %ebx
	je	.L175
	imull	$12, %ebx, %edx
	incl	%esi
	movl	comps+4(%edx), %eax
	movl	%eax, dscans+20(%ebp)
	movl	comps+8(%edx), %eax
	movl	%eax, dscans+24(%ebp)
	imull	$4484, %edi, %eax
	addl	$dhuff, %eax
	movl	%eax, dscans+4(%ebp)
	imull	$4484, 112(%esp), %eax
	addl	$dhuff+8968, %eax
	movl	%eax, dscans+8(%ebp)
	addl	$28, %ebp
	cmpl	$2, %esi
	jle	.L207
	call	getbyte
	movl	%eax, %esi
	call	getbyte
	movl	%eax, %ebx
	call	getbyte
	testl	%esi, %esi
	movl	%eax, %edi
	setne	%dl
	cmpl	$63, %ebx
	setne	%al
	orl	%edx, %eax
	testb	$1, %al
	jne	.L209
	testl	%edi, %edi
	je	.L208
.L209:
	movl	$11, %edx
	jmp	.L175
.L208:
	cmpl	$1, dscans+16
	jne	.L213
	cmpl	$2, dscans+44
	jne	.L213
	cmpl	$3, dscans+72
	jne	.L213
	cmpl	$34, dscans+20
	jne	.L213
	cmpl	$17, dscans+48
	jne	.L213
	cmpl	$17, dscans+76
	je	.L212
.L213:
	movl	$9, %edx
	jmp	.L175
.L212:
	movl	180(%esp), %edx
	movl	dscans+24, %eax
	sarl	$4, %edx
	movl	184(%esp), %ecx
	sall	$6, %eax
	movl	%edx, 108(%esp)
	movl	192(%esp), %edx
	addl	$quant, %eax
	sarl	$4, %ecx
	addl	$3136, %edx
	movl	%ecx, 104(%esp)
	call	idctqtab
	movl	192(%esp), %esi
	movl	dscans+52, %eax
	sall	$6, %eax
	addl	$3392, %esi
	addl	$quant, %eax
	movl	%esi, %edx
	call	idctqtab
	movl	192(%esp), %ebx
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
	movl	info+8, %eax
	incl	%eax
	movl	$0, in+8
	movl	%eax, info+12
	movl	info+4, %eax
	movl	$0, in+4
	movl	$0, in+12
	movl	$208, info+16
	cmpl	%eax, %edi
	jge	.L397
	movl	$dscans, %edx
.L220:
	movl	$0, (%edx)
	addl	$28, %edx
	decl	%eax
	jne	.L220
.L397:
	movl	$0, 96(%esp)
	movl	104(%esp), %ebx
	movl	$2, dscans+12
	movl	$1, dscans+40
	movl	$0, dscans+68
	cmpl	%ebx, 96(%esp)
	jge	.L399
.L389:
	movl	$0, 100(%esp)
	movl	108(%esp), %edi
	cmpl	%edi, 100(%esp)
	jge	.L401
.L388:
	cmpl	$0, info+8
	je	.L230
	movl	info+12, %eax
	decl	%eax
	movl	%eax, info+12
	testl	%eax, %eax
	jne	.L230
	movl	$in, %eax
	call	dec_readmarker
	movl	$12, %edx
	movl	%eax, %ecx
	cmpl	info+16, %eax
	jne	.L175
	movl	info+8, %eax
	movl	%eax, info+12
	leal	1(%ecx), %eax
	andl	$-9, %eax
	movl	%eax, info+16
	movl	info+4, %eax
	testl	%eax, %eax
	jle	.L230
	movl	$dscans, %edx
.L238:
	movl	$0, (%edx)
	addl	$28, %edx
	decl	%eax
	jne	.L238
.L230:
	leal	120(%esp), %eax
	movl	192(%esp), %esi
	movl	%eax, 84(%esp)
	movl	$dscans, 88(%esp)
	movl	%esi, %eax
	movl	$1535, %edx
.L242:
	decl	%edx
	movb	$0, (%eax)
	incl	%eax
	cmpl	$-1, %edx
	jne	.L242
	movl	in+4, %edx
	movl	in+8, %ebx
	movl	%edx, 8(%esp)
	movl	$5, 92(%esp)
.L261:
	movl	88(%esp), %ecx
	movl	%esi, %ebp
	addl	$4, %esi
	cmpl	$9, %ebx
	movl	4(%ecx), %edi
	jg	.L248
	movl	%ebx, %edx
	movl	8(%esp), %ecx
	movl	$in, %eax
	call	fillbits
	movl	%eax, %ebx
	movl	in+4, %eax
	movl	%eax, 8(%esp)
.L248:
	subl	$10, %ebx
	movl	8(%esp), %eax
	movb	%bl, %cl
	sarl	%cl, %eax
	andl	$1023, %eax
	movl	%eax, 116(%esp)
	movl	388(%edi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L249
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %ebx
	movl	%edx, %eax
	andl	$15, %eax
	movl	%eax, 116(%esp)
	movl	%edx, %eax
	sarl	$8, %eax
	jmp	.L250
.L427:
	leal	(%esi,%ebp,4), %esi
	jmp	.L252
.L249:
	movl	%ebx, in+8
	movl	8(%esp), %ebx
	pushl	%edx
	pushl	%eax
	leal	124(%esp), %ecx
	movl	%edi, %edx
	movl	$in, %eax
	movl	%ebx, in+4
	call	dec_rec2
	popl	%ebx
	popl	%edi
	movl	in+4, %edi
	movl	in+8, %ebx
	movl	%edi, 8(%esp)
.L250:
	movl	88(%esp), %edx
	addl	(%edx), %eax
	movl	%eax, (%edx)
	movl	%eax, (%ebp)
	movl	8(%edx), %edi
	movl	$63, %ebp
.L259:
	cmpl	$9, %ebx
	jg	.L255
	movl	8(%esp), %ecx
	movl	%ebx, %edx
	movl	$in, %eax
	call	fillbits
	movl	in+4, %ecx
	movl	%eax, %ebx
	movl	%ecx, 8(%esp)
.L255:
	subl	$10, %ebx
	movl	8(%esp), %eax
	movb	%bl, %cl
	sarl	%cl, %eax
	andl	$1023, %eax
	movl	%eax, 116(%esp)
	movl	388(%edi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L256
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %ebx
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$15, %eax
	movl	%eax, 116(%esp)
	jmp	.L257
.L256:
	movl	%ebx, in+8
	movl	8(%esp), %ebx
	pushl	%edx
	pushl	%eax
	leal	124(%esp), %ecx
	movl	%edi, %edx
	movl	$in, %eax
	movl	%ebx, in+4
	call	dec_rec2
	popl	%edx
	popl	%ecx
	movl	%eax, %edx
	movl	in+4, %eax
	movl	in+8, %ebx
	movl	%eax, 8(%esp)
.L257:
	testl	%edx, %edx
	jne	.L258
	cmpl	$0, 116(%esp)
	je	.L427
.L258:
	movl	116(%esp), %eax
	subl	%eax, %ebp
	leal	(%esi,%eax,4), %esi
	leal	-1(%ebp), %ebp
	movl	%edx, (%esi)
	addl	$4, %esi
	testl	%ebp, %ebp
	jg	.L259
.L252:
	movl	84(%esp), %edx
	movl	$64, %eax
	subl	%ebp, %eax
	movl	88(%esp), %ecx
	movl	%eax, (%edx)
	movl	92(%esp), %edi
	addl	$4, %edx
	cmpl	12(%ecx), %edi
	movl	%edx, 84(%esp)
	jne	.L244
	addl	$28, %ecx
	movl	%ecx, 88(%esp)
.L244:
	movl	92(%esp), %eax
	decl	92(%esp)
	testl	%eax, %eax
	jg	.L261
	movl	8(%esp), %eax
	movl	192(%esp), %esi
	movl	%ebx, in+8
	movl	192(%esp), %ebx
	pushl	120(%esp)
	addl	$3136, %ebx
	pushl	$263168
	addl	$1600, %esi
	movl	%ebx, %ecx
	movl	%eax, in+4
	movl	%esi, %edx
	movl	200(%esp), %eax
	call	idct
	movl	%ebx, %ecx
	pushl	132(%esp)
	pushl	$263168
	movl	208(%esp), %edi
	leal	1856(%edi), %edx
	leal	256(%edi), %eax
	call	idct
	movl	%ebx, %ecx
	pushl	144(%esp)
	leal	2112(%edi), %edx
	pushl	$263168
	leal	512(%edi), %eax
	call	idct
	movl	%ebx, %ecx
	pushl	156(%esp)
	leal	2368(%edi), %edx
	pushl	$263168
	leal	768(%edi), %eax
	movl	%edi, %ebx
	call	idct
	addl	$32, %esp
	pushl	136(%esp)
	addl	$2624, %ebx
	pushl	$1024
	leal	3392(%edi), %ecx
	movl	%ebx, %edx
	leal	1024(%edi), %eax
	call	idct
	leal	3648(%edi), %ecx
	pushl	148(%esp)
	leal	2880(%edi), %edx
	pushl	$1024
	leal	1280(%edi), %eax
	call	idct
	addl	$16, %esp
	cmpl	$16, 188(%esp)
	je	.L329
	movl	$15, %edx
	cmpl	$24, 188(%esp)
	jne	.L175
	movl	96(%esp), %eax
	movl	176(%esp), %ecx
	imull	108(%esp), %eax
	sall	$4, %eax
	movl	%esi, 60(%esp)
	addl	100(%esp), %eax
	movl	%ebx, 56(%esp)
	imull	$48, %eax, %eax
	imull	$48, 108(%esp), %edx
	leal	(%eax,%ecx), %ebp
	movl	%edx, 80(%esp)
	addl	%ebp, %edx
	movl	$2, 76(%esp)
	movl	%edx, 64(%esp)
.L327:
	movl	$4, 72(%esp)
.L326:
	movl	64(%esp), %ebx
	movl	$0, 68(%esp)
	movl	%ebx, 16(%esp)
	xorl	%esi, %esi
	movl	%ebp, 12(%esp)
.L325:
	movl	68(%esp), %eax
	movl	56(%esp), %edx
	movl	256(%edx,%eax,4), %ecx
	movl	(%edx,%eax,4), %edi
	imull	$50, %edi, %edx
	imull	$130, %ecx, %eax
	movl	%ecx, 4(%esp)
	leal	128(%eax,%edx), %ecx
	movl	68(%esp), %eax
	sarl	$8, %ecx
	movl	$4, %edx
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	68(%esp), %edx
	movl	%eax, (%esp)
	andl	$3, %edx
	movl	60(%esp), %ebx
	sall	$5, %eax
	addl	%eax, %edx
	movl	%edx, 52(%esp)
	movl	(%ebx,%edx,8), %edx
	movb	4(%esp), %bl
	leal	(%ebx,%edx), %eax
	movb	%al, (%ebp,%esi)
	movl	4(%esp), %ebx
	leal	(%ebx,%edx), %eax
	cmpl	$255, %eax
	jbe	.L278
	sarl	$31, %eax
	notl	%eax
	movb	%al, (%ebp,%esi)
.L278:
	movb	%dl, %al
	subb	%cl, %al
	movb	%al, 1(%ebp,%esi)
	movl	%edx, %eax
	subl	%ecx, %eax
	cmpl	$255, %eax
	jbe	.L282
	sarl	$31, %eax
	movl	12(%esp), %ebx
	notl	%eax
	movb	%al, 1(%ebx)
.L282:
	leal	(%edi,%edx), %eax
	movb	%al, 2(%ebp,%esi)
	leal	(%edi,%edx), %eax
	cmpl	$255, %eax
	jbe	.L286
	sarl	$31, %eax
	movl	12(%esp), %edx
	notl	%eax
	movb	%al, 2(%edx)
.L286:
	movl	52(%esp), %ebx
	movl	60(%esp), %eax
	movl	4(%eax,%ebx,8), %edx
	movb	4(%esp), %bl
	leal	(%ebx,%edx), %eax
	movb	%al, 3(%ebp,%esi)
	movl	4(%esp), %ebx
	leal	(%ebx,%edx), %eax
	cmpl	$255, %eax
	jbe	.L290
	sarl	$31, %eax
	movl	12(%esp), %ebx
	notl	%eax
	movb	%al, 3(%ebx)
.L290:
	movb	%dl, %al
	subb	%cl, %al
	movb	%al, 4(%ebp,%esi)
	movl	%edx, %eax
	subl	%ecx, %eax
	cmpl	$255, %eax
	jbe	.L294
	sarl	$31, %eax
	movl	12(%esp), %ebx
	notl	%eax
	movb	%al, 4(%ebx)
.L294:
	leal	(%edi,%edx), %eax
	movb	%al, 5(%ebp,%esi)
	leal	(%edi,%edx), %eax
	cmpl	$255, %eax
	jbe	.L298
	sarl	$31, %eax
	movl	12(%esp), %edx
	notl	%eax
	movb	%al, 5(%edx)
.L298:
	movl	52(%esp), %ebx
	movl	60(%esp), %eax
	movl	32(%eax,%ebx,8), %edx
	movb	4(%esp), %bl
	leal	(%ebx,%edx), %eax
	movl	64(%esp), %ebx
	movb	%al, (%ebx,%esi)
	movl	4(%esp), %ebx
	leal	(%ebx,%edx), %eax
	cmpl	$255, %eax
	jbe	.L302
	sarl	$31, %eax
	movl	64(%esp), %ebx
	notl	%eax
	movb	%al, (%ebx,%esi)
.L302:
	movb	%dl, %al
	movl	64(%esp), %ebx
	subb	%cl, %al
	movb	%al, 1(%ebx,%esi)
	movl	%edx, %eax
	subl	%ecx, %eax
	cmpl	$255, %eax
	jbe	.L306
	sarl	$31, %eax
	movl	16(%esp), %ebx
	notl	%eax
	movb	%al, 1(%ebx)
.L306:
	movl	64(%esp), %ebx
	leal	(%edi,%edx), %eax
	movb	%al, 2(%ebx,%esi)
	leal	(%edi,%edx), %eax
	cmpl	$255, %eax
	jbe	.L310
	sarl	$31, %eax
	movl	16(%esp), %edx
	notl	%eax
	movb	%al, 2(%edx)
.L310:
	movl	52(%esp), %ebx
	movl	60(%esp), %eax
	movl	36(%eax,%ebx,8), %edx
	movb	4(%esp), %bl
	leal	(%ebx,%edx), %eax
	movl	64(%esp), %ebx
	movb	%al, 3(%ebx,%esi)
	movl	4(%esp), %ebx
	leal	(%ebx,%edx), %eax
	cmpl	$255, %eax
	jbe	.L314
	sarl	$31, %eax
	movl	16(%esp), %ebx
	notl	%eax
	movb	%al, 3(%ebx)
.L314:
	movb	%dl, %al
	movl	64(%esp), %ebx
	subb	%cl, %al
	movb	%al, 4(%ebx,%esi)
	movl	%edx, %eax
	subl	%ecx, %eax
	cmpl	$255, %eax
	jbe	.L318
	sarl	$31, %eax
	movl	16(%esp), %ecx
	notl	%eax
	movb	%al, 4(%ecx)
.L318:
	movl	64(%esp), %ebx
	leal	(%edi,%edx), %eax
	movb	%al, 5(%ebx,%esi)
	leal	(%edi,%edx), %eax
	cmpl	$255, %eax
	jbe	.L275
	sarl	$31, %eax
	movl	16(%esp), %edi
	notl	%eax
	movb	%al, 5(%edi)
.L275:
	incl	68(%esp)
	addl	$6, %esi
	addl	$6, 12(%esp)
	addl	$6, 16(%esp)
	cmpl	$7, 68(%esp)
	jle	.L325
	decl	72(%esp)
	movl	80(%esp), %eax
	addl	%eax, %eax
	addl	$32, 56(%esp)
	addl	$64, 60(%esp)
	addl	%eax, %ebp
	addl	%eax, 64(%esp)
	cmpl	$0, 72(%esp)
	jg	.L326
	decl	76(%esp)
	addl	$256, 60(%esp)
	cmpl	$0, 76(%esp)
	jg	.L327
	jmp	.L228
.L329:
	movl	96(%esp), %eax
	movl	176(%esp), %ecx
	imull	108(%esp), %eax
	sall	$4, %eax
	movl	108(%esp), %edx
	addl	100(%esp), %eax
	movl	%esi, %edi
	sall	$5, %eax
	movl	%ebx, 32(%esp)
	sall	$5, %edx
	movl	$2, 44(%esp)
	leal	(%eax,%ecx), %ebp
	movl	%edx, 48(%esp)
	addl	%ebp, %edx
	movl	%edx, 36(%esp)
.L384:
	movl	$4, 40(%esp)
.L383:
	xorl	%esi, %esi
.L382:
	movl	32(%esp), %ebx
	movl	32(%esp), %eax
	movl	(%ebx,%esi,4), %ebx
	movl	256(%eax,%esi,4), %eax
	imull	$50, %ebx, %edx
	movl	%eax, 28(%esp)
	movl	%ebx, 20(%esp)
	imull	$130, %eax, %eax
	leal	128(%eax,%edx), %eax
	movl	$4, %edx
	sarl	$8, %eax
	movl	%edx, %ebx
	movl	%eax, 24(%esp)
	movl	%esi, %eax
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%esi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	28(%esp), %ecx
	movl	(%edi,%eax,8), %edx
	leal	7(%ecx,%edx), %eax
	cmpl	$255, %eax
	ja	.L342
	movl	%eax, %ecx
	andl	$248, %ecx
	sall	$8, %ecx
	jmp	.L343
.L342:
	movl	%eax, %ecx
	sarl	$31, %ecx
	notl	%ecx
	andl	$63488, %ecx
.L343:
	movl	%edx, %eax
	subl	24(%esp), %eax
	addl	$3, %eax
	cmpl	$255, %eax
	ja	.L346
	andl	$252, %eax
	leal	0(,%eax,8), %ebx
	orl	%ecx, %ebx
	jmp	.L347
.L346:
	movl	%ecx, %ebx
	testl	%eax, %eax
	js	.L347
	orl	$2016, %ebx
.L347:
	movl	20(%esp), %eax
	leal	7(%eax,%edx), %edx
	cmpl	$255, %edx
	ja	.L349
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ebx, %eax
	jmp	.L350
.L349:
	movl	%ebx, %eax
	testl	%edx, %edx
	js	.L350
	orl	$31, %eax
.L350:
	movl	%eax, %edx
	sarl	$8, %eax
	movb	%dl, 1(%ebp,%esi,4)
	movb	%al, (%ebp,%esi,4)
	movl	$4, %edx
	movl	%esi, %eax
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%esi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	28(%esp), %ecx
	movl	4(%edi,%eax,8), %edx
	leal	1(%ecx,%edx), %eax
	cmpl	$255, %eax
	ja	.L352
	andl	$248, %eax
	sall	$8, %eax
	jmp	.L353
.L352:
	sarl	$31, %eax
	notl	%eax
	andl	$63488, %eax
.L353:
	movl	%edx, %ebx
	subl	24(%esp), %ebx
	cmpl	$255, %ebx
	ja	.L356
	andl	$252, %ebx
	leal	0(,%ebx,8), %ecx
	orl	%eax, %ecx
	jmp	.L357
.L356:
	movl	%eax, %ecx
	testl	%ebx, %ebx
	js	.L357
	orl	$2016, %ecx
.L357:
	movl	20(%esp), %ebx
	leal	1(%ebx,%edx), %edx
	cmpl	$255, %edx
	ja	.L359
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ecx, %eax
	jmp	.L360
.L359:
	movl	%ecx, %eax
	testl	%edx, %edx
	js	.L360
	orl	$31, %eax
.L360:
	movl	%eax, %edx
	sarl	$8, %eax
	movb	%dl, 3(%ebp,%esi,4)
	movb	%al, 2(%ebp,%esi,4)
	movl	$4, %edx
	movl	%esi, %eax
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%esi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	28(%esp), %ecx
	movl	32(%edi,%eax,8), %edx
	leal	3(%ecx,%edx), %eax
	cmpl	$255, %eax
	ja	.L362
	movl	%eax, %ecx
	andl	$248, %ecx
	sall	$8, %ecx
	jmp	.L363
.L362:
	movl	%eax, %ecx
	sarl	$31, %ecx
	notl	%ecx
	andl	$63488, %ecx
.L363:
	movl	%edx, %eax
	subl	24(%esp), %eax
	incl	%eax
	cmpl	$255, %eax
	ja	.L366
	andl	$252, %eax
	leal	0(,%eax,8), %ebx
	orl	%ecx, %ebx
	jmp	.L367
.L366:
	movl	%ecx, %ebx
	testl	%eax, %eax
	js	.L367
	orl	$2016, %ebx
.L367:
	movl	20(%esp), %eax
	leal	3(%eax,%edx), %edx
	cmpl	$255, %edx
	ja	.L369
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ebx, %eax
	jmp	.L370
.L369:
	movl	%ebx, %eax
	testl	%edx, %edx
	js	.L370
	orl	$31, %eax
.L370:
	movl	36(%esp), %ecx
	movl	%eax, %edx
	sarl	$8, %eax
	movb	%al, (%ecx,%esi,4)
	movb	%dl, 1(%ecx,%esi,4)
	movl	%esi, %eax
	movl	$4, %edx
	movl	%edx, %ebx
	cltd
	idivl	%ebx
	movl	%eax, %ecx
	movl	%esi, %edx
	sall	$5, %ecx
	andl	$3, %edx
	leal	(%edx,%ecx), %eax
	movl	28(%esp), %ecx
	movl	36(%edi,%eax,8), %edx
	leal	5(%ecx,%edx), %eax
	cmpl	$255, %eax
	ja	.L372
	movl	%eax, %ecx
	andl	$248, %ecx
	sall	$8, %ecx
	jmp	.L373
.L372:
	movl	%eax, %ecx
	sarl	$31, %ecx
	notl	%ecx
	andl	$63488, %ecx
.L373:
	movl	%edx, %eax
	subl	24(%esp), %eax
	addl	$2, %eax
	cmpl	$255, %eax
	ja	.L376
	andl	$252, %eax
	leal	0(,%eax,8), %ebx
	orl	%ecx, %ebx
	jmp	.L377
.L376:
	movl	%ecx, %ebx
	testl	%eax, %eax
	js	.L377
	orl	$2016, %ebx
.L377:
	movl	20(%esp), %ecx
	leal	5(%ecx,%edx), %eax
	cmpl	$255, %eax
	ja	.L379
	movl	%eax, %ecx
	sarl	$3, %ecx
	orl	%ebx, %ecx
	jmp	.L380
.L379:
	movl	%ebx, %ecx
	testl	%eax, %eax
	js	.L380
	orl	$31, %ecx
.L380:
	movl	36(%esp), %ebx
	movl	%ecx, %eax
	sarl	$8, %eax
	movb	%al, 2(%ebx,%esi,4)
	movb	%cl, 3(%ebx,%esi,4)
	incl	%esi
	cmpl	$7, %esi
	jle	.L382
	movl	48(%esp), %eax
	decl	40(%esp)
	addl	%eax, %eax
	addl	$64, %edi
	addl	%eax, %ebx
	addl	%eax, %ebp
	addl	$32, 32(%esp)
	movl	%ebx, 36(%esp)
	cmpl	$0, 40(%esp)
	jg	.L383
	decl	44(%esp)
	addl	$256, %edi
	cmpl	$0, 44(%esp)
	jg	.L384
.L228:
	incl	100(%esp)
	movl	108(%esp), %edi
	cmpl	%edi, 100(%esp)
	jl	.L388
.L401:
	incl	96(%esp)
	movl	104(%esp), %eax
	cmpl	%eax, 96(%esp)
	jl	.L389
.L399:
	movl	$in, %eax
	call	dec_readmarker
	xorl	%edx, %edx
	cmpl	$217, %eax
	sete	%dl
	decl	%edx
	andl	$13, %edx
.L175:
	addl	$152, %esp
	movl	%edx, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret
	.size	jpeg_decode, .-jpeg_decode
.globl jpeg_get_size
	.type	jpeg_get_size, @function
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
	je	.L429
	movl	%eax, (%ebx)
.L429:
	call	getword
	testl	%esi, %esi
	je	.L428
	movl	%eax, (%esi)
.L428:
	popl	%ebx
	popl	%esi
	ret
	.size	jpeg_get_size, .-jpeg_get_size
	.local	datap
	.comm	datap,4,4
	.local	info
	.comm	info,20,4
	.local	comps
	.comm	comps,48,32
	.local	dscans
	.comm	dscans,112,32
	.local	quant
	.comm	quant,256,32
	.local	dhuff
	.comm	dhuff,17936,32
	.local	in
	.comm	in,24,4
	.section	.note.GNU-stack,"",@progbits
	.ident	"GCC: (GNU) 3.3.4 (pre 3.3.5 20040809)"
