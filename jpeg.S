	.file	"jpeg.S"
	.text
	.code16gcc

	.globl jpeg_decode
	.globl jpeg_get_size

	.equ	tmp_img, 0

	.equ	datap, 1024

	.equ	decdata, 1028

	.equ	info, 4932

	.equ	comps, 4944

	.equ	dscans, 4992

	.equ	quant, 5104

	.equ	dhuff, 5360

	.equ	in, 11008

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
	# datap = %ds:datap
	movl	datap, %edx
	# (%edx) = %es:jpg
	movzbl	%es:(%edx), %eax
	incl	%edx
	# datap = %ds:datap
	movl	%edx, datap
	ret

getword:
	# datap = %ds:datap
	movl	datap, %edx
	# (%edx) = %es:jpg+1
	movzwl	%es:(%edx), %eax
	addl	$2, %edx
	xchgb	%al, %ah
	# datap = %ds:datap
	movl	%edx, datap
	ret

fillbits:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	movl	%eax, %ebp
	movl	%edx, %ebx
	movl	%ecx, %esi
	# 8(%eax) = %ds:in+8
	cmpl	$0, 8(%eax)
	je	.L4
	cmpl	$16, %edx
	jg	.L3
	sall	$16, %esi
	addl	$16, %ebx
	# (%eax) = %ds:in
	movl	%esi, (%eax)
	jmp	.L3
.L4:
	cmpl	$24, %edx
	jg	.L7
.L11:
	call	getbyte
	movl	%eax, %edi
	cmpl	$255, %eax
	jne	.L9
	call	getbyte
	testl	%eax, %eax
	je	.L9
	# 8(%ebp) = %ds:in+8
	movl	%eax, %ds:8(%ebp)
	cmpl	$16, %ebx
	jg	.L7
	sall	$16, %esi
	addl	$16, %ebx
	jmp	.L7
.L9:
	sall	$8, %esi
	addl	$8, %ebx
	orl	%edi, %esi
	cmpl	$24, %ebx
	jle	.L11
.L7:
	# (%ebp) = %ds:in
	movl	%esi, %ds:(%ebp)
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
	# 4(%eax) = %ds:in+4
	movl	4(%eax), %edi
	# (%eax) = %ds:in
	movl	(%eax), %eax
	# 40(%esp) = %ss:stack+792
	movl	40(%esp), %esi
	# 12(%esp) = %ss:stack+764
	movl	%edx, 12(%esp)
	# 8(%esp) = %ss:stack+760
	movl	%ecx, 8(%esp)
	# 36(%esp) = %ss:stack+788
	movl	36(%esp), %ebx
	# 4(%esp) = %ss:stack+756
	movl	%eax, 4(%esp)
	testl	%esi, %esi
	je	.L14
	movl	%esi, %eax
	sarl	$8, %esi
	andl	$127, %eax
	addl	%eax, %edi
	movl	%esi, %eax
	sarl	$8, %esi
	andl	$15, %eax
	jmp	.L29
.L14:
	movl	$8, %esi
	jmp	.L16
.L22:
	incl	%esi
.L16:
	addl	%ebx, %ebx
	testl	%edi, %edi
	# (%esp) = %ss:stack+752
	movl	%ebx, (%esp)
	jg	.L21
	movl	%edi, %edx
	# 4(%esp) = %ss:stack+756
	movl	4(%esp), %ecx
	movl	%ebp, %eax
	call	fillbits
	# (%ebp) = %ds:in
	movl	%ds:(%ebp), %edx
	movl	%eax, %edi
	# 4(%esp) = %ss:stack+756
	movl	%edx, 4(%esp)
.L21:
	decl	%edi
	# 4(%esp) = %ss:stack+756
	movl	4(%esp), %ebx
	movl	%edi, %ecx
	# 12(%esp) = %ss:stack+764
	movl	12(%esp), %eax
	sarl	%cl, %ebx
	andl	$1, %ebx
	# (%esp) = %ss:stack+752
	orl	(%esp), %ebx
	# (%eax,%esi,4) = %ds:dhuff+4268
	cmpl	(%eax,%esi,4), %ebx
	jge	.L22
	cmpl	$15, %esi
	jle	.L23
	# 8(%ebp) = %ds:in+8
	movl	$-1, %ds:8(%ebp)
	jmp	.L28
.L23:
	# 12(%esp) = %ss:stack+764
	movl	12(%esp), %edx
	# 8(%esp) = %ss:stack+760
	movl	8(%esp), %ecx
	# -4(%edx,%esi,4) = %ds:dhuff+4264
	movl	-4(%edx,%esi,4), %eax
	# 68(%edx,%esi,4) = %ds:dhuff+4336
	addl	68(%edx,%esi,4), %ebx
	addl	%eax, %eax
	subl	%eax, %ebx
	# 132(%edx,%ebx) = %ds:dhuff+?
	movzbl	132(%edx,%ebx), %esi
	movl	%esi, %eax
	andl	$15, %esi
	sarl	$4, %eax
.L29:
	# (%ecx) = %ss:stack+916
	movl	%eax, %ss:(%ecx)
	testl	%esi, %esi
	jne	.L24
	# 4(%esp) = %ss:stack+756
	movl	4(%esp), %eax
	# 4(%ebp) = %ds:in+4
	movl	%edi, %ds:4(%ebp)
	# (%ebp) = %ds:in
	movl	%eax, %ds:(%ebp)
.L28:
	xorl	%eax, %eax
	jmp	.L13
.L24:
	cmpl	%esi, %edi
	jge	.L26
	movl	%edi, %edx
	# 4(%esp) = %ss:stack+756
	movl	4(%esp), %ecx
	movl	%ebp, %eax
	call	fillbits
	# (%ebp) = %ds:in
	movl	%ds:(%ebp), %edx
	movl	%eax, %edi
	# 4(%esp) = %ss:stack+756
	movl	%edx, 4(%esp)
.L26:
	subl	%esi, %edi
	movl	$1, %eax
	movl	%edi, %ecx
	# 4(%esp) = %ss:stack+756
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
	jge	.L27
	orl	$-1, %eax
	movl	%esi, %ecx
	sall	%cl, %eax
	leal	1(%eax,%ebx), %ebx
.L27:
	# 4(%esp) = %ss:stack+756
	movl	4(%esp), %eax
	# 4(%ebp) = %ds:in+4
	movl	%edi, %ds:4(%ebp)
	# (%ebp) = %ds:in
	movl	%eax, %ds:(%ebp)
	movl	%ebx, %eax
.L13:
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
	# 36(%esp) = %ss:stack+452
	movl	%eax, 36(%esp)
.L125:
	call	getbyte
	orl	$-1, %edx
	cmpl	$255, %eax
	jne	.L30
	call	getbyte
	xorl	%edx, %edx
	# 36(%esp) = %ss:stack+452
	cmpl	36(%esp), %eax
	je	.L30
	cmpl	$196, %eax
	je	.L50
	jg	.L103
	cmpl	$194, %eax
	je	.L30
	jmp	.L97
.L103:
	cmpl	$219, %eax
	je	.L38
	cmpl	$221, %eax
	je	.L96
	jmp	.L97
.L38:
	call	getword
	movl	%eax, %edi
	cmpl	$2, %eax
	jle	.L125
.L49:
	call	getbyte
	orl	$-1, %edx
	movl	%eax, %ebp
	andl	$15, %ebp
	cmpl	$3, %ebp
	jg	.L30
	sarl	$4, %eax
	testl	%eax, %eax
	jne	.L30
	xorl	%esi, %esi
.L48:
	call	getbyte
	movl	%ebp, %ebx
	sall	$6, %ebx
	addl	$quant, %ebx
	# (%esi,%ebx) = %ds:quant+704
	movb	%al, (%esi,%ebx)
	incl	%esi
	cmpl	$63, %esi
	jle	.L48
	subl	$65, %edi
	cmpl	$2, %edi
	jg	.L49
	jmp	.L125
.L50:
	call	getword
	cmpl	$2, %eax
	# 32(%esp) = %ss:stack+448
	movl	%eax, 32(%esp)
	jle	.L125
.L95:
	call	getbyte
	movl	%eax, %ecx
	sarl	$4, %eax
	andl	$15, %ecx
	leal	(%ecx,%eax,2), %edx
	decl	%eax
	# 28(%esp) = %ss:stack+444
	movl	%edx, 28(%esp)
	setg	%dl
	decl	%ecx
	setg	%al
	orl	%edx, %eax
	orl	$-1, %edx
	testb	$1, %al
	jne	.L30
	xorl	%esi, %esi
.L59:
	call	getbyte
	# 296(%esp,%esi,4) = %ss:stack+712
	movl	%eax, 296(%esp,%esi,4)
	incl	%esi
	cmpl	$15, %esi
	jle	.L59
	# 32(%esp) = %ss:stack+448
	subl	$17, 32(%esp)
	xorl	%ebp, %ebp
	xorl	%esi, %esi
.L69:
	xorl	%edi, %edi
	# 296(%esp,%esi,4) = %ss:stack+712
	cmpl	296(%esp,%esi,4), %edi
	jge	.L115
.L68:
	leal	360(%esp), %ecx
	incl	%edi
	leal	(%ecx,%ebp), %ebx
	call	getbyte
	incl	%ebp
	# 296(%esp,%esi,4) = %ss:stack+712
	cmpl	296(%esp,%esi,4), %edi
	# -320(%ebx) = %ss:stack+456
	movb	%al, %ss:-320(%ebx)
	jl	.L68
.L115:
	# 296(%esp,%esi,4) = %ss:stack+712
	movl	296(%esp,%esi,4), %eax
	incl	%esi
	# 32(%esp) = %ss:stack+448
	subl	%eax, 32(%esp)
	cmpl	$15, %esi
	jle	.L69
	# 28(%esp) = %ss:stack+444
	imull	$1412, 28(%esp), %eax
	leal	40(%esp), %edx
	addl	$dhuff, %eax
	# 24(%esp) = %ss:stack+440
	movl	%eax, 24(%esp)
	# 20(%esp) = %ss:stack+436
	movl	%edx, 20(%esp)
	xorl	%edi, %edi
.L74:
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %ecx
	# 388(%ecx,%edi,4) = %ds:dhuff+49808
	movl	$0, 388(%ecx,%edi,4)
	incl	%edi
	cmpl	$255, %edi
	jle	.L74
	# 16(%esp) = %ss:stack+432
	movl	$0, 16(%esp)
	# 12(%esp) = %ss:stack+428
	movl	$0, 12(%esp)
	xorl	%edi, %edi
	# (%esp) = %ss:stack+416
	movl	$7, (%esp)
.L93:
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %edx
	# 12(%esp) = %ss:stack+428
	movl	12(%esp), %eax
	# 68(%edx,%edi,4) = %ds:dhuff+49488
	movl	%eax, 68(%edx,%edi,4)
	# 296(%esp,%edi,4) = %ss:stack+712
	movl	296(%esp,%edi,4), %eax
	testl	%eax, %eax
	jle	.L121
	# 8(%esp) = %ss:stack+424
	movl	%eax, 8(%esp)
.L92:
	# 20(%esp) = %ss:stack+436
	movl	20(%esp), %ecx
	# 12(%esp) = %ss:stack+428
	movl	12(%esp), %edx
	# (%ecx) = %ss:stack+456
	movb	%ss:(%ecx), %al
	incl	%ecx
	# 20(%esp) = %ss:stack+436
	movl	%ecx, 20(%esp)
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %ecx
	cmpl	$7, %edi
	# 132(%ecx,%edx) = %ds:dhuff+?
	movb	%al, 132(%ecx,%edx)
	jg	.L83
	# (%esp) = %ss:stack+416
	movb	(%esp), %cl
	movl	$1, %ebp
	# 16(%esp) = %ss:stack+432
	movl	16(%esp), %edx
	movl	$15, %esi
	sall	%cl, %ebp
	sall	%cl, %edx
	andl	%eax, %esi
	decl	%ebp
	# 4(%esp) = %ss:stack+420
	movl	%edx, 4(%esp)
	js	.L83
.L91:
	leal	(%edi,%esi), %eax
	cmpl	$7, %eax
	jg	.L88
	movl	%esi, %ecx
	movl	%ebp, %ebx
	negl	%ecx
	subl	%edi, %ecx
	addl	$7, %ecx
	sarl	%cl, %ebx
	testl	%esi, %esi
	je	.L89
	leal	-1(%esi), %ecx
	movl	$1, %eax
	sall	%cl, %eax
	cmpl	%eax, %ebx
	jge	.L89
	orl	$-1, %eax
	movl	%esi, %ecx
	sall	%cl, %eax
	leal	1(%eax,%ebx), %ebx
.L89:
	# 12(%esp) = %ss:stack+428
	movl	12(%esp), %edx
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %ecx
	sall	$16, %ebx
	# 132(%ecx,%edx) = %ds:dhuff+?
	movzbl	132(%ecx,%edx), %eax
	andl	$240, %eax
	leal	(%esi,%edi), %edx
	sall	$4, %eax
	orl	%eax, %ebx
	movl	$7, %eax
	subl	%edx, %eax
	orl	%eax, %ebx
	orb	$-128, %bl
	jmp	.L90
.L88:
	# 12(%esp) = %ss:stack+428
	movl	12(%esp), %edx
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %ecx
	movl	%esi, %ebx
	# 132(%ecx,%edx) = %ds:dhuff+?
	movzbl	132(%ecx,%edx), %eax
	sall	$16, %ebx
	andl	$240, %eax
	sall	$4, %eax
	orl	%eax, %ebx
	# (%esp) = %ss:stack+416
	orl	(%esp), %ebx
.L90:
	# 4(%esp) = %ss:stack+420
	movl	4(%esp), %eax
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %edx
	orl	%ebp, %eax
	decl	%ebp
	# 388(%edx,%eax,4) = %ds:dhuff+?
	movl	%ebx, 388(%edx,%eax,4)
	jns	.L91
.L83:
	# 16(%esp) = %ss:stack+432
	incl	16(%esp)
	# 12(%esp) = %ss:stack+428
	incl	12(%esp)
	# 8(%esp) = %ss:stack+424
	decl	8(%esp)
	jne	.L92
.L121:
	# 24(%esp) = %ss:stack+440
	movl	24(%esp), %ecx
	# 16(%esp) = %ss:stack+432
	movl	16(%esp), %eax
	# (%esp) = %ss:stack+416
	decl	(%esp)
	# (%ecx,%edi,4) = %ds:dhuff+49420
	movl	%eax, (%ecx,%edi,4)
	addl	%eax, %eax
	incl	%edi
	# 16(%esp) = %ss:stack+432
	movl	%eax, 16(%esp)
	cmpl	$15, %edi
	jle	.L93
	# 64(%ecx) = %ds:dhuff+49484
	movl	$131072, 64(%ecx)
	# 32(%esp) = %ss:stack+448
	cmpl	$2, 32(%esp)
	jg	.L95
	jmp	.L125
.L96:
	call	getword
	call	getword
	# info+8 = %ds:info+8
	movl	%eax, info+8
	jmp	.L125
.L97:
	call	getword
	# 32(%esp) = %ss:stack+448
	movl	%eax, 32(%esp)
	# 32(%esp) = %ss:stack+448
	decl	32(%esp)
	cmpl	$2, %eax
	jle	.L125
.L101:
	call	getbyte
	# 32(%esp) = %ss:stack+448
	movl	32(%esp), %eax
	# 32(%esp) = %ss:stack+448
	decl	32(%esp)
	cmpl	$2, %eax
	jg	.L101
	jmp	.L125
.L30:
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
	# 36(%esp) = %ss:stack+508
	movl	%eax, 36(%esp)
	# 316(%esp) = %ss:stack+788
	movl	316(%esp), %eax
	# 32(%esp) = %ss:stack+504
	movl	%edx, 32(%esp)
	# 28(%esp) = %ss:stack+500
	movl	%ecx, 28(%esp)
	# 24(%esp) = %ss:stack+496
	movl	%eax, 24(%esp)
	# 320(%esp) = %ss:stack+792
	cmpl	$1, 320(%esp)
	jne	.L127
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %edx
	# (%ecx) = %ds:decdata+3136
	movl	(%ecx), %eax
	# 4(%esp) = %ss:stack+476
	movl	$0, 4(%esp)
	# (%edx) = %ds:decdata
	imull	(%edx), %eax
	# 24(%esp) = %ss:stack+496
	addl	%eax, 24(%esp)
.L132:
	# 4(%esp) = %ss:stack+476
	movl	4(%esp), %ecx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	sarl	$11, %eax
	# 32(%esp) = %ss:stack+504
	movl	32(%esp), %ebp
	# (%ebp,%ecx,4) = %ds:decdata+?
	movl	%eax, %ds:(%ebp,%ecx,4)
	incl	%ecx
	# 4(%esp) = %ss:stack+476
	movl	%ecx, 4(%esp)
	cmpl	$63, %ecx
	jle	.L132
	jmp	.L126
.L127:
	leal	40(%esp), %eax
	# (%esp) = %ss:stack+472
	movl	$zig2, (%esp)
	# 8(%esp) = %ss:stack+480
	movl	%eax, 8(%esp)
	# 4(%esp) = %ss:stack+476
	movl	$7, 4(%esp)
.L137:
	# (%esp) = %ss:stack+472
	movl	(%esp), %ecx
	# 28(%esp) = %ss:stack+500
	movl	28(%esp), %ebp
	# (%ecx) = %cs:zig2
	movzbl	%cs:(%ecx), %edx
	incl	%ecx
	# (%esp) = %ss:stack+472
	movl	%ecx, (%esp)
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %ecx
	# (%ebp,%edx,4) = %ds:decdata+?
	movl	%ds:(%ebp,%edx,4), %eax
	# (%esp) = %ss:stack+472
	movl	(%esp), %ebp
	# (%ecx,%edx,4) = %ds:decdata+?
	imull	(%ecx,%edx,4), %eax
	# 24(%esp) = %ss:stack+496
	addl	%eax, 24(%esp)
	# 28(%esp) = %ss:stack+500
	movl	28(%esp), %ecx
	# (%ebp) = %cs:zig2+1
	movzbl	%cs:(%ebp), %edx
	incl	%ebp
	# (%esp) = %ss:stack+472
	movl	%ebp, (%esp)
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %ebp
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %eax
	# (%ebp,%edx,4) = %ds:decdata+?
	movl	%ds:(%ebp,%edx,4), %edi
	imull	%eax, %edi
	# (%esp) = %ss:stack+472
	movl	(%esp), %eax
	# (%eax) = %cs:zig2+2
	movzbl	%cs:(%eax), %edx
	incl	%eax
	# (%esp) = %ss:stack+472
	movl	%eax, (%esp)
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %eax
	# (%esp) = %ss:stack+472
	movl	(%esp), %ecx
	# (%ebp,%edx,4) = %ds:decdata+?
	movl	%ds:(%ebp,%edx,4), %esi
	# 28(%esp) = %ss:stack+500
	movl	28(%esp), %ebp
	# (%ecx) = %cs:zig2+3
	movzbl	%cs:(%ecx), %edx
	incl	%ecx
	# (%esp) = %ss:stack+472
	movl	%ecx, (%esp)
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %ecx
	imull	%eax, %esi
	# (%ebp,%edx,4) = %ds:decdata+?
	movl	%ds:(%ebp,%edx,4), %eax
	# (%esp) = %ss:stack+472
	movl	(%esp), %ebp
	# (%ecx,%edx,4) = %ds:decdata+?
	imull	(%ecx,%edx,4), %eax
	# 12(%esp) = %ss:stack+484
	movl	%eax, 12(%esp)
	# 28(%esp) = %ss:stack+500
	movl	28(%esp), %ecx
	# (%ebp) = %cs:zig2+4
	movzbl	%cs:(%ebp), %edx
	incl	%ebp
	# (%esp) = %ss:stack+472
	movl	%ebp, (%esp)
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %ebp
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %eax
	# (%ebp,%edx,4) = %ds:decdata+?
	imull	%ds:(%ebp,%edx,4), %eax
	# 20(%esp) = %ss:stack+492
	movl	%eax, 20(%esp)
	# (%esp) = %ss:stack+472
	movl	(%esp), %eax
	# (%eax) = %cs:zig2+5
	movzbl	%cs:(%eax), %edx
	incl	%eax
	# (%esp) = %ss:stack+472
	movl	%eax, (%esp)
	# (%ebp,%edx,4) = %ds:decdata+?
	movl	%ds:(%ebp,%edx,4), %ebp
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %eax
	# 28(%esp) = %ss:stack+500
	movl	28(%esp), %ecx
	imull	%eax, %ebp
	# (%esp) = %ss:stack+472
	movl	(%esp), %eax
	# (%eax) = %cs:zig2+6
	movzbl	%cs:(%eax), %edx
	incl	%eax
	# (%esp) = %ss:stack+472
	movl	%eax, (%esp)
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %eax
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %ecx
	# (%ecx,%edx,4) = %ds:decdata+?
	imull	(%ecx,%edx,4), %eax
	# 16(%esp) = %ss:stack+488
	movl	%eax, 16(%esp)
	# (%esp) = %ss:stack+472
	movl	(%esp), %eax
	# 28(%esp) = %ss:stack+500
	movl	28(%esp), %ecx
	# (%eax) = %cs:zig2+7
	movzbl	%cs:(%eax), %edx
	incl	%eax
	# (%esp) = %ss:stack+472
	movl	%eax, (%esp)
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %eax
	# 36(%esp) = %ss:stack+508
	movl	36(%esp), %ecx
	# (%ecx,%edx,4) = %ds:decdata+?
	movl	(%ecx,%edx,4), %ebx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %ecx
	# 20(%esp) = %ss:stack+492
	addl	20(%esp), %ecx
	imull	%eax, %ebx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	movl	%esi, %ecx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %edx
	# 16(%esp) = %ss:stack+488
	subl	16(%esp), %ecx
	# 16(%esp) = %ss:stack+488
	addl	%esi, 16(%esp)
	imull	$2896, %ecx, %esi
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %ecx
	# 20(%esp) = %ss:stack+492
	subl	20(%esp), %eax
	# 16(%esp) = %ss:stack+488
	addl	16(%esp), %ecx
	# 16(%esp) = %ss:stack+488
	subl	16(%esp), %edx
	sarl	$11, %esi
	# 16(%esp) = %ss:stack+488
	subl	16(%esp), %esi
	# 16(%esp) = %ss:stack+488
	movl	%edx, 16(%esp)
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	movl	%eax, %ecx
	addl	%esi, %ecx
	subl	%esi, %eax
	# 20(%esp) = %ss:stack+492
	movl	%ecx, 20(%esp)
	movl	%ebp, %ecx
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %ecx
	# 12(%esp) = %ss:stack+484
	addl	%ebp, 12(%esp)
	movl	%ecx, %ebp
	leal	(%ebx,%edi), %ecx
	subl	%ebx, %edi
	movl	%eax, %esi
	movl	%edi, %ebx
	movl	%ecx, %edi
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %ecx
	# 12(%esp) = %ss:stack+484
	addl	%edi, 12(%esp)
	leal	(%ebx,%ebp), %eax
	# 20(%esp) = %ss:stack+492
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
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %ecx
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %ebx
	# 12(%esp) = %ss:stack+484
	addl	12(%esp), %ecx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	sarl	$11, %edi
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	subl	%ebx, %edi
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %ecx
	addl	%ebx, %ecx
	subl	%edi, %ebp
	# 20(%esp) = %ss:stack+492
	movl	%ecx, 20(%esp)
	leal	(%edi,%esi), %ecx
	subl	%edi, %esi
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %eax
	movl	%esi, %edi
	movl	%ecx, %esi
	# 16(%esp) = %ss:stack+488
	movl	16(%esp), %ecx
	# 16(%esp) = %ss:stack+488
	subl	%ebp, 16(%esp)
	addl	%ebp, %ecx
	# 8(%esp) = %ss:stack+480
	movl	8(%esp), %ebp
	# 12(%esp) = %ss:stack+484
	movl	%eax, 12(%esp)
	subl	%ebx, %edx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	# 96(%ebp) = %ss:stack+608
	movl	%ecx, 96(%ebp)
	# (%ebp) = %ss:stack+512
	movl	%eax, (%ebp)
	movl	%edx, %ebx
	# 16(%esp) = %ss:stack+488
	movl	16(%esp), %ecx
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %edx
	# 12(%esp) = %ss:stack+484
	movl	12(%esp), %eax
	# 32(%ebp) = %ss:stack+544
	movl	%edx, 32(%ebp)
	# 64(%ebp) = %ss:stack+576
	movl	%esi, 64(%ebp)
	# 128(%ebp) = %ss:stack+640
	movl	%ecx, 128(%ebp)
	# 160(%ebp) = %ss:stack+672
	movl	%edi, 160(%ebp)
	# 192(%ebp) = %ss:stack+704
	movl	%ebx, 192(%ebp)
	# 224(%ebp) = %ss:stack+736
	movl	%eax, 224(%ebp)
	addl	$4, %ebp
	# 4(%esp) = %ss:stack+476
	decl	4(%esp)
	# 8(%esp) = %ss:stack+480
	movl	%ebp, 8(%esp)
	# 24(%esp) = %ss:stack+496
	movl	$0, 24(%esp)
	jns	.L137
	# 4(%esp) = %ss:stack+476
	movl	$0, 4(%esp)
.L142:
	# 4(%esp) = %ss:stack+476
	movl	4(%esp), %edx
	sall	$5, %edx
	# 40(%esp,%edx) = %ss:stack+?
	movl	40(%esp,%edx), %ecx
	# 44(%esp,%edx) = %ss:stack+?
	movl	44(%esp,%edx), %ebp
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	# 68(%esp,%edx) = %ss:stack+?
	movl	68(%esp,%edx), %ecx
	# 20(%esp) = %ss:stack+492
	movl	%ebp, 20(%esp)
	# 12(%esp) = %ss:stack+484
	movl	%ecx, 12(%esp)
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %ecx
	# 48(%esp,%edx) = %ss:stack+?
	movl	48(%esp,%edx), %esi
	# 20(%esp) = %ss:stack+492
	addl	20(%esp), %ecx
	# 52(%esp,%edx) = %ss:stack+?
	movl	52(%esp,%edx), %eax
	# 16(%esp) = %ss:stack+488
	movl	%eax, 16(%esp)
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	movl	%esi, %ecx
	# 16(%esp) = %ss:stack+488
	subl	16(%esp), %ecx
	# 16(%esp) = %ss:stack+488
	addl	%esi, 16(%esp)
	imull	$2896, %ecx, %esi
	# 20(%esp) = %ss:stack+492
	subl	20(%esp), %eax
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %ecx
	# 16(%esp) = %ss:stack+488
	addl	16(%esp), %ecx
	# 20(%esp) = %ss:stack+492
	movl	%eax, 20(%esp)
	sarl	$11, %esi
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	# 16(%esp) = %ss:stack+488
	subl	16(%esp), %esi
	# 16(%esp) = %ss:stack+488
	subl	16(%esp), %eax
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %ecx
	# 56(%esp,%edx) = %ss:stack+?
	movl	56(%esp,%edx), %ebp
	addl	%esi, %ecx
	# 16(%esp) = %ss:stack+488
	movl	%eax, 16(%esp)
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %eax
	# 20(%esp) = %ss:stack+492
	movl	%ecx, 20(%esp)
	movl	%ebp, %ecx
	# 64(%esp,%edx) = %ss:stack+?
	movl	64(%esp,%edx), %ebx
	# 60(%esp,%edx) = %ss:stack+?
	movl	60(%esp,%edx), %edi
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %ecx
	# 12(%esp) = %ss:stack+484
	addl	%ebp, 12(%esp)
	movl	%ecx, %ebp
	leal	(%ebx,%edi), %ecx
	subl	%ebx, %edi
	subl	%esi, %eax
	movl	%edi, %ebx
	movl	%ecx, %edi
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %ecx
	movl	%eax, %esi
	leal	(%ebx,%ebp), %eax
	# 12(%esp) = %ss:stack+484
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
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %ecx
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %ebx
	# 12(%esp) = %ss:stack+484
	addl	12(%esp), %ecx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	# 12(%esp) = %ss:stack+484
	subl	12(%esp), %eax
	# 24(%esp) = %ss:stack+496
	movl	%ecx, 24(%esp)
	sarl	$11, %edi
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %ecx
	subl	%ebx, %edi
	addl	%ebx, %ecx
	# 12(%esp) = %ss:stack+484
	movl	%eax, 12(%esp)
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %eax
	subl	%edi, %ebp
	# 20(%esp) = %ss:stack+492
	movl	%ecx, 20(%esp)
	subl	%ebx, %eax
	leal	(%edi,%esi), %ecx
	subl	%edi, %esi
	movl	%eax, %ebx
	movl	%esi, %edi
	movl	%ecx, %esi
	# 16(%esp) = %ss:stack+488
	movl	16(%esp), %ecx
	# 16(%esp) = %ss:stack+488
	subl	%ebp, 16(%esp)
	# 24(%esp) = %ss:stack+496
	sarl	$11, 24(%esp)
	addl	%ebp, %ecx
	# 32(%esp) = %ss:stack+504
	movl	32(%esp), %ebp
	# 20(%esp) = %ss:stack+492
	sarl	$11, 20(%esp)
	# 16(%esp) = %ss:stack+488
	sarl	$11, 16(%esp)
	sarl	$11, %ecx
	# 24(%esp) = %ss:stack+496
	movl	24(%esp), %eax
	sarl	$11, %esi
	# (%ebp,%edx) = %ds:decdata+?
	movl	%eax, %ds:(%ebp,%edx)
	addl	%ebp, %edx
	# 16(%esp) = %ss:stack+488
	movl	16(%esp), %eax
	sarl	$11, %edi
	# 20(%esp) = %ss:stack+492
	movl	20(%esp), %ebp
	sarl	$11, %ebx
	# 12(%edx) = %ds:decdata+?
	movl	%ecx, 12(%edx)
	# 4(%edx) = %ds:decdata+?
	movl	%ebp, 4(%edx)
	# 8(%edx) = %ds:decdata+?
	movl	%esi, 8(%edx)
	# 16(%edx) = %ds:decdata+?
	movl	%eax, 16(%edx)
	# 20(%edx) = %ds:decdata+?
	movl	%edi, 20(%edx)
	# 24(%edx) = %ds:decdata+?
	movl	%ebx, 24(%edx)
	# 4(%esp) = %ss:stack+476
	incl	4(%esp)
	# 12(%esp) = %ss:stack+484
	sarl	$11, 12(%esp)
	# 12(%esp) = %ss:stack+484
	movl	12(%esp), %ecx
	# 28(%edx) = %ds:decdata+?
	movl	%ecx, 28(%edx)
	# 4(%esp) = %ss:stack+476
	cmpl	$7, 4(%esp)
	jle	.L142
.L126:
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
.L158:
	xorl	%ebx, %ebx
.L157:
	# aaidct(,%ebx,4) = %cs:aaidct
	movl	%cs:aaidct(,%ebx,4), %eax
	# aaidct(,%esi,4) = %cs:aaidct
	imull	%cs:aaidct(,%esi,4), %eax
	# zig(%ebx,%esi,8) = %cs:zig
	movzbl	%cs:zig(%ebx,%esi,8), %ecx
	sarl	$11, %eax
	incl	%ebx
	# (%ecx,%ebp) = %ds:quant+?
	movzbl	(%ecx,%ebp), %edx
	imull	%eax, %edx
	cmpl	$7, %ebx
	# (%edi,%ecx,4) = %ds:decdata+?
	movl	%edx, (%edi,%ecx,4)
	jle	.L157
	incl	%esi
	cmpl	$7, %esi
	jle	.L158
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

scaleidctqtab:
	pushl	%ebx
	xorl	%ecx, %ecx
	movl	%eax, %ebx
.L168:
	# (%ebx,%ecx,4) = %ds:decdata+3392
	movl	(%ebx,%ecx,4), %eax
	imull	%edx, %eax
	sarl	$11, %eax
	# (%ebx,%ecx,4) = %ds:decdata+3392
	movl	%eax, (%ebx,%ecx,4)
	incl	%ecx
	cmpl	$63, %ecx
	jle	.L168
	popl	%ebx
	ret

jpeg_decode:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$156, %esp
	# 176(%esp) = %ss:stack+972
	movl	176(%esp), %eax
	# datap = %ds:datap
	movl	%eax, datap
	call	getbyte
	movl	$1, %ecx
	cmpl	$255, %eax
	jne	.L171
	call	getbyte
	movl	$1, %ecx
	cmpl	$216, %eax
	jne	.L171
	movl	$192, %eax
	call	readtables
	movl	$14, %ecx
	testl	%eax, %eax
	jne	.L171
	movl	$12, %ecx
	# info+8 = %ds:info+8
	cmpl	$0, info+8
	jne	.L171
	call	getword
	call	getbyte
	movl	$2, %ecx
	cmpl	$8, %eax
	jne	.L171
	call	getword
	# 92(%esp) = %ss:stack+888
	movl	%eax, 92(%esp)
	call	getword
	# 96(%esp) = %ss:stack+892
	movl	%eax, 96(%esp)
	call	getbyte
	movl	$6, %ecx
	# info = %ds:info
	movl	%eax, info
	cmpl	$4, %eax
	jg	.L171
	xorl	%esi, %esi
	cmpl	%eax, %esi
	jge	.L382
	# 4(%esp) = %ss:stack+800
	movl	$0, 4(%esp)
.L184:
	call	getbyte
	# 4(%esp) = %ss:stack+800
	movl	4(%esp), %edx
	# comps(%edx) = %ds:comps+?
	movl	%eax, comps(%edx)
	call	getbyte
	# 4(%esp) = %ss:stack+800
	movl	4(%esp), %ecx
	movl	%eax, %ebx
	movl	%eax, %edi
	andl	$15, %ebx
	sarl	$4, %edi
	# comps+4(%ecx) = %ds:comps+?
	movl	%eax, comps+4(%ecx)
	call	getbyte
	cmpl	$3, %edi
	movl	%eax, %ebp
	# 4(%esp) = %ss:stack+800
	movl	4(%esp), %eax
	setg	%dl
	# comps+8(%eax) = %ds:comps+?
	movl	%ebp, comps+8(%eax)
	cmpl	$3, %ebx
	setg	%al
	orl	%edx, %eax
	movl	$7, %ecx
	testb	$1, %al
	jne	.L171
	movl	$8, %ecx
	cmpl	$3, %ebp
	jg	.L171
	incl	%esi
	# 4(%esp) = %ss:stack+800
	addl	$12, 4(%esp)
	# info = %ds:info
	cmpl	info, %esi
	jl	.L184
.L382:
	movl	$218, %eax
	call	readtables
	movl	$14, %ecx
	testl	%eax, %eax
	jne	.L171
	call	getword
	call	getbyte
	movl	$9, %ecx
	# info+4 = %ds:info+4
	movl	%eax, info+4
	cmpl	$3, %eax
	jne	.L171
	xorl	%esi, %esi
	xorl	%ebp, %ebp
.L199:
	call	getbyte
	# dscans+16(%ebp) = %ds:dscans+16
	movl	%eax, %ds:dscans+16(%ebp)
	call	getbyte
	movl	%eax, %edx
	movl	%eax, %edi
	andl	$15, %edx
	movl	$8, %ecx
	sarl	$4, %edi
	# 116(%esp) = %ss:stack+912
	movl	%edx, 116(%esp)
	cmpl	$1, %edi
	setg	%dl
	# 116(%esp) = %ss:stack+912
	cmpl	$1, 116(%esp)
	setg	%al
	orl	%edx, %eax
	testb	$1, %al
	jne	.L171
	xorl	%ebx, %ebx
	# info = %ds:info
	movl	info, %edx
	cmpl	%edx, %ebx
	jge	.L193
	movl	$comps, %ecx
.L197:
	# dscans+16(%ebp) = %ds:dscans+16
	movl	%ds:dscans+16(%ebp), %eax
	# (%ecx) = %ds:comps
	cmpl	%eax, (%ecx)
	je	.L193
	incl	%ebx
	addl	$12, %ecx
	cmpl	%edx, %ebx
	jl	.L197
.L193:
	movl	$10, %ecx
	cmpl	%edx, %ebx
	je	.L171
	imull	$12, %ebx, %edx
	incl	%esi
	# comps+4(%edx) = %ds:comps+16
	movl	comps+4(%edx), %eax
	# dscans+20(%ebp) = %ds:dscans+20
	movl	%eax, %ds:dscans+20(%ebp)
	# comps+8(%edx) = %ds:comps+20
	movl	comps+8(%edx), %eax
	# dscans+24(%ebp) = %ds:dscans+24
	movl	%eax, %ds:dscans+24(%ebp)
	imull	$1412, %edi, %eax
	addl	$dhuff, %eax
	# dscans+4(%ebp) = %ds:dscans+4
	movl	%eax, %ds:dscans+4(%ebp)
	# 116(%esp) = %ss:stack+912
	imull	$1412, 116(%esp), %eax
	addl	$dhuff+2824, %eax
	# dscans+8(%ebp) = %ds:dscans+8
	movl	%eax, %ds:dscans+8(%ebp)
	addl	$28, %ebp
	cmpl	$2, %esi
	jle	.L199
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
	jne	.L201
	testl	%ecx, %ecx
	je	.L200
.L201:
	movl	$11, %ecx
	jmp	.L171
.L200:
	# dscans+16 = %ds:dscans+16
	cmpl	$1, dscans+16
	jne	.L205
	# dscans+44 = %ds:dscans+44
	cmpl	$2, dscans+44
	jne	.L205
	# dscans+72 = %ds:dscans+72
	cmpl	$3, dscans+72
	jne	.L205
	# dscans+20 = %ds:dscans+20
	cmpl	$34, dscans+20
	jne	.L205
	# dscans+48 = %ds:dscans+48
	cmpl	$17, dscans+48
	jne	.L205
	# dscans+76 = %ds:dscans+76
	cmpl	$17, dscans+76
	je	.L204
.L205:
	movl	$9, %ecx
	jmp	.L171
.L204:
	# 184(%esp) = %ss:stack+980
	movl	184(%esp), %eax
	# 96(%esp) = %ss:stack+892
	movl	96(%esp), %ecx
	sarl	$4, %eax
	addl	$15, %ecx
	# 88(%esp) = %ss:stack+884
	movl	%eax, 88(%esp)
	# 188(%esp) = %ss:stack+984
	movl	188(%esp), %eax
	addl	$15, %eax
	# 92(%esp) = %ss:stack+888
	movl	92(%esp), %ebx
	sarl	$4, %eax
	addl	$15, %ebx
	decl	%eax
	# 192(%esp) = %ss:stack+988
	movl	192(%esp), %edx
	sarl	$4, %ecx
	# 84(%esp) = %ss:stack+880
	movl	%eax, 84(%esp)
	# 196(%esp) = %ss:stack+992
	movl	196(%esp), %eax
	# 112(%esp) = %ss:stack+908
	movl	%ecx, 112(%esp)
	sarl	$4, %ebx
	addl	$15, %eax
	sarl	$4, %eax
	# 108(%esp) = %ss:stack+904
	movl	%ebx, 108(%esp)
	sarl	$4, %edx
	leal	-1(%eax), %ecx
	# 80(%esp) = %ss:stack+876
	movl	%edx, 80(%esp)
	# 76(%esp) = %ss:stack+872
	movl	%ecx, 76(%esp)
	cmpl	%ebx, %ecx
	jge	.L206
	# 108(%esp) = %ss:stack+904
	movl	%eax, 108(%esp)
.L206:
	# dscans+24 = %ds:dscans+24
	movl	dscans+24, %eax
	movl	$decdata+3136, %edx
	sall	$6, %eax
	addl	$quant, %eax
	call	idctqtab
	# dscans+52 = %ds:dscans+52
	movl	dscans+52, %eax
	sall	$6, %eax
	movl	$decdata+3392, %edx
	addl	$quant, %eax
	call	idctqtab
	# dscans+80 = %ds:dscans+80
	movl	dscans+80, %eax
	sall	$6, %eax
	movl	$decdata+3648, %edx
	addl	$quant, %eax
	call	idctqtab
	movl	$3629, %edx
	movl	$decdata+3392, %eax
	call	scaleidctqtab
	movl	$decdata+3648, %eax
	movl	$2871, %edx
	call	scaleidctqtab
	# info+4 = %ds:info+4
	movl	info+4, %eax
	# in+4 = %ds:in+4
	movl	$0, in+4
	# in = %ds:in
	movl	$0, in
	# in+8 = %ds:in+8
	movl	$0, in+8
	testl	%eax, %eax
	jle	.L387
	movl	$dscans, %edx
.L213:
	# (%edx) = %ds:dscans
	movl	$0, (%edx)
	addl	$28, %edx
	decl	%eax
	jne	.L213
.L387:
	# 100(%esp) = %ss:stack+896
	movl	$0, 100(%esp)
	# 108(%esp) = %ss:stack+904
	movl	108(%esp), %ebx
	# dscans+12 = %ds:dscans+12
	movl	$2, dscans+12
	# dscans+40 = %ds:dscans+40
	movl	$1, dscans+40
	# dscans+68 = %ds:dscans+68
	movl	$0, dscans+68
	# 100(%esp) = %ss:stack+896
	cmpl	%ebx, 100(%esp)
	jge	.L389
.L380:
	# 104(%esp) = %ss:stack+900
	movl	$0, 104(%esp)
	# 112(%esp) = %ss:stack+908
	movl	112(%esp), %eax
	# 104(%esp) = %ss:stack+900
	cmpl	%eax, 104(%esp)
	jge	.L391
.L379:
	leal	124(%esp), %edx
	movl	$decdata, %edi
	# 64(%esp) = %ss:stack+860
	movl	%edx, 64(%esp)
	# 68(%esp) = %ss:stack+864
	movl	$dscans, 68(%esp)
	movl	%edi, %edx
	movl	$1535, %eax
.L226:
	decl	%eax
	# (%edx) = %ds:decdata
	movb	$0, (%edx)
	incl	%edx
	cmpl	$-1, %eax
	jne	.L226
	# in = %ds:in
	movl	in, %ecx
	# in+4 = %ds:in+4
	movl	in+4, %ebx
	# (%esp) = %ss:stack+796
	movl	%ecx, (%esp)
	# 72(%esp) = %ss:stack+868
	movl	$5, 72(%esp)
.L245:
	# 68(%esp) = %ss:stack+864
	movl	68(%esp), %eax
	movl	%edi, %ebp
	addl	$4, %edi
	cmpl	$7, %ebx
	# 4(%eax) = %ds:dscans+4
	movl	4(%eax), %esi
	jg	.L232
	movl	%ebx, %edx
	# (%esp) = %ss:stack+796
	movl	(%esp), %ecx
	movl	$in, %eax
	call	fillbits
	# in = %ds:in
	movl	in, %edx
	movl	%eax, %ebx
	# (%esp) = %ss:stack+796
	movl	%edx, (%esp)
.L232:
	subl	$8, %ebx
	# (%esp) = %ss:stack+796
	movl	(%esp), %eax
	movb	%bl, %cl
	sarl	%cl, %eax
	andl	$255, %eax
	# 120(%esp) = %ss:stack+916
	movl	%eax, 120(%esp)
	# 388(%esi,%eax,4) = %ds:dhuff+?
	movl	388(%esi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L233
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %ebx
	movl	%edx, %eax
	andl	$15, %eax
	# 120(%esp) = %ss:stack+916
	movl	%eax, 120(%esp)
	movl	%edx, %eax
	sarl	$8, %eax
	jmp	.L234
.L411:
	leal	(%edi,%ebp,4), %edi
	jmp	.L236
.L233:
	# in+4 = %ds:in+4
	movl	%ebx, in+4
	# (%esp) = %ss:stack+796
	movl	(%esp), %ebx
	pushl	%edx
	pushl	%eax
	movl	%esi, %edx
	leal	128(%esp), %ecx
	movl	$in, %eax
	# in = %ds:in
	movl	%ebx, in
	call	dec_rec2
	popl	%ebx
	popl	%esi
	movl	%eax, %edx
	# in = %ds:in
	movl	in, %eax
	# in+4 = %ds:in+4
	movl	in+4, %ebx
	# (%esp) = %ss:stack+796
	movl	%eax, (%esp)
	movl	%edx, %eax
.L234:
	# 68(%esp) = %ss:stack+864
	movl	68(%esp), %edx
	# (%edx) = %ds:dscans
	addl	(%edx), %eax
	# (%edx) = %ds:dscans
	movl	%eax, (%edx)
	# (%ebp) = %ds:decdata
	movl	%eax, %ds:(%ebp)
	# 8(%edx) = %ds:dscans+8
	movl	8(%edx), %esi
	movl	$63, %ebp
.L243:
	cmpl	$7, %ebx
	jg	.L239
	# (%esp) = %ss:stack+796
	movl	(%esp), %ecx
	movl	%ebx, %edx
	movl	$in, %eax
	call	fillbits
	# in = %ds:in
	movl	in, %ecx
	movl	%eax, %ebx
	# (%esp) = %ss:stack+796
	movl	%ecx, (%esp)
.L239:
	subl	$8, %ebx
	# (%esp) = %ss:stack+796
	movl	(%esp), %eax
	movb	%bl, %cl
	sarl	%cl, %eax
	andl	$255, %eax
	# 120(%esp) = %ss:stack+916
	movl	%eax, 120(%esp)
	# 388(%esi,%eax,4) = %ds:dhuff+?
	movl	388(%esi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L240
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %ebx
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$15, %eax
	# 120(%esp) = %ss:stack+916
	movl	%eax, 120(%esp)
	jmp	.L241
.L240:
	# in+4 = %ds:in+4
	movl	%ebx, in+4
	# (%esp) = %ss:stack+796
	movl	(%esp), %ebx
	pushl	%edx
	pushl	%eax
	leal	128(%esp), %ecx
	movl	%esi, %edx
	movl	$in, %eax
	# in = %ds:in
	movl	%ebx, in
	call	dec_rec2
	popl	%edx
	popl	%ecx
	movl	%eax, %edx
	# in = %ds:in
	movl	in, %eax
	# in+4 = %ds:in+4
	movl	in+4, %ebx
	# (%esp) = %ss:stack+796
	movl	%eax, (%esp)
.L241:
	testl	%edx, %edx
	jne	.L242
	# 120(%esp) = %ss:stack+916
	cmpl	$0, 120(%esp)
	je	.L411
.L242:
	# 120(%esp) = %ss:stack+916
	movl	120(%esp), %eax
	subl	%eax, %ebp
	leal	(%edi,%eax,4), %edi
	leal	-1(%ebp), %ebp
	# (%edi) = %ds:decdata+?
	movl	%edx, (%edi)
	addl	$4, %edi
	testl	%ebp, %ebp
	jg	.L243
.L236:
	# 64(%esp) = %ss:stack+860
	movl	64(%esp), %edx
	movl	$64, %eax
	subl	%ebp, %eax
	# 68(%esp) = %ss:stack+864
	movl	68(%esp), %ecx
	# (%edx) = %ss:stack+920
	movl	%eax, %ss:(%edx)
	addl	$4, %edx
	# 72(%esp) = %ss:stack+868
	movl	72(%esp), %eax
	# 64(%esp) = %ss:stack+860
	movl	%edx, 64(%esp)
	# 12(%ecx) = %ds:dscans+12
	cmpl	12(%ecx), %eax
	jne	.L228
	addl	$28, %ecx
	# 68(%esp) = %ss:stack+864
	movl	%ecx, 68(%esp)
.L228:
	# 72(%esp) = %ss:stack+868
	movl	72(%esp), %eax
	# 72(%esp) = %ss:stack+868
	decl	72(%esp)
	testl	%eax, %eax
	jg	.L245
	# (%esp) = %ss:stack+796
	movl	(%esp), %edx
	# in+4 = %ds:in+4
	movl	%ebx, in+4
	# 80(%esp) = %ss:stack+876
	movl	80(%esp), %ecx
	# 76(%esp) = %ss:stack+872
	movl	76(%esp), %ebx
	# 100(%esp) = %ss:stack+896
	cmpl	%ecx, 100(%esp)
	# in = %ds:in
	movl	%edx, in
	setge	%dl
	# 100(%esp) = %ss:stack+896
	cmpl	%ebx, 100(%esp)
	setle	%al
	andl	%edx, %eax
	testb	$1, %al
	je	.L221
	# 88(%esp) = %ss:stack+884
	movl	88(%esp), %eax
	# 84(%esp) = %ss:stack+880
	movl	84(%esp), %ecx
	# 104(%esp) = %ss:stack+900
	cmpl	%eax, 104(%esp)
	setge	%dl
	# 104(%esp) = %ss:stack+900
	cmpl	%ecx, 104(%esp)
	setle	%al
	andl	%edx, %eax
	testb	$1, %al
	je	.L221
	# 124(%esp) = %ss:stack+920
	pushl	124(%esp)
	movl	$decdata+3136, %ecx
	pushl	$263168
	movl	$decdata+1600, %edx
	movl	$decdata, %eax
	call	idct
	movl	$decdata+3136, %ecx
	# 136(%esp) = %ss:stack+924
	pushl	136(%esp)
	movl	$decdata+1856, %edx
	pushl	$263168
	movl	$decdata+256, %eax
	call	idct
	movl	$decdata+3136, %ecx
	# 148(%esp) = %ss:stack+928
	pushl	148(%esp)
	movl	$decdata+2112, %edx
	pushl	$263168
	movl	$decdata+512, %eax
	call	idct
	movl	$decdata+3136, %ecx
	# 160(%esp) = %ss:stack+932
	pushl	160(%esp)
	movl	$decdata+2368, %edx
	pushl	$263168
	movl	$decdata+768, %eax
	call	idct
	addl	$32, %esp
	# 140(%esp) = %ss:stack+936
	pushl	140(%esp)
	movl	$decdata+3392, %ecx
	pushl	$1024
	movl	$decdata+2624, %edx
	movl	$decdata+1024, %eax
	call	idct
	movl	$decdata+3648, %ecx
	# 152(%esp) = %ss:stack+940
	pushl	152(%esp)
	movl	$decdata+2880, %edx
	pushl	$1024
	movl	$decdata+1280, %eax
	call	idct
	addl	$16, %esp
	# 200(%esp) = %ss:stack+996
	movl	200(%esp), %ebx
	# 36(%esp) = %ss:stack+832
	movl	$tmp_img, 36(%esp)
	addl	%ebx, %ebx
	# 32(%esp) = %ss:stack+828
	movl	$decdata+1600, 32(%esp)
	movl	%ebx, %ebp
	# 56(%esp) = %ss:stack+852
	movl	%ebx, 56(%esp)
	addl	$tmp_img, %ebp
	# 28(%esp) = %ss:stack+824
	movl	$decdata+2624, 28(%esp)
	# 52(%esp) = %ss:stack+848
	movl	$2, 52(%esp)
.L352:
	# 48(%esp) = %ss:stack+844
	movl	$4, 48(%esp)
.L351:
	xorl	%esi, %esi
.L350:
	movl	%esi, %ecx
	# 28(%esp) = %ss:stack+824
	movl	28(%esp), %edx
	sarl	$2, %ecx
	# 28(%esp) = %ss:stack+824
	movl	28(%esp), %ebx
	# (%edx,%esi,4) = %ds:decdata+2624
	movl	(%edx,%esi,4), %edx
	leal	0(,%ecx,8), %eax
	# 256(%ebx,%esi,4) = %ds:decdata+2880
	movl	256(%ebx,%esi,4), %ebx
	# 44(%esp) = %ss:stack+840
	movl	%eax, 44(%esp)
	movl	%esi, %eax
	andl	$3, %eax
	# 24(%esp) = %ss:stack+820
	movl	%edx, 24(%esp)
	addl	%eax, %eax
	# 20(%esp) = %ss:stack+816
	movl	%ebx, 20(%esp)
	# 40(%esp) = %ss:stack+836
	movl	%eax, 40(%esp)
	leal	1(%esi), %eax
	# 200(%esp) = %ss:stack+996
	cmpl	$16, 200(%esp)
	# 16(%esp) = %ss:stack+812
	movl	%eax, 16(%esp)
	jne	.L260
	imull	$50, %edx, %eax
	imull	$130, %ebx, %edx
	sall	$6, %ecx
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %ebx
	leal	128(%edx,%eax), %edi
	# 40(%esp) = %ss:stack+836
	movl	40(%esp), %edx
	sarl	$8, %edi
	leal	(%edx,%ecx), %eax
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %edx
	# (%ebx,%eax,4) = %ds:decdata+?
	movl	(%ebx,%eax,4), %ecx
	leal	7(%edx,%ecx), %eax
	cmpl	$255, %eax
	ja	.L261
	movl	%eax, %edx
	andl	$248, %edx
	sall	$8, %edx
	jmp	.L262
.L261:
	cltd
	notl	%edx
	andl	$63488, %edx
.L262:
	movl	%ecx, %eax
	subl	%edi, %eax
	addl	$3, %eax
	cmpl	$255, %eax
	ja	.L265
	andl	$252, %eax
	leal	0(,%eax,8), %ebx
	orl	%edx, %ebx
	jmp	.L266
.L265:
	movl	%edx, %ebx
	testl	%eax, %eax
	js	.L266
	orl	$2016, %ebx
.L266:
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %eax
	leal	7(%eax,%ecx), %edx
	cmpl	$255, %edx
	ja	.L268
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ebx, %eax
	jmp	.L269
.L268:
	movl	%ebx, %eax
	testl	%edx, %edx
	js	.L269
	orl	$31, %eax
.L269:
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %edx
	movl	%eax, %ecx
	sarl	$8, %ecx
	# (%edx,%esi,4) = %ds:tmp_img
	movb	%al, (%edx,%esi,4)
	# 1(%edx,%esi,4) = %ds:tmp_img+1
	movb	%cl, 1(%edx,%esi,4)
	# 44(%esp) = %ss:stack+840
	movl	44(%esp), %ecx
	# 40(%esp) = %ss:stack+836
	movl	40(%esp), %ebx
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %edx
	leal	(%ebx,%ecx,8), %eax
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %ebx
	# 4(%edx,%eax,4) = %ds:decdata+?
	movl	4(%edx,%eax,4), %ecx
	leal	1(%ebx,%ecx), %eax
	cmpl	$255, %eax
	ja	.L271
	andl	$248, %eax
	sall	$8, %eax
	jmp	.L272
.L271:
	sarl	$31, %eax
	notl	%eax
	andl	$63488, %eax
.L272:
	movl	%ecx, %ebx
	subl	%edi, %ebx
	cmpl	$255, %ebx
	ja	.L275
	andl	$252, %ebx
	leal	0(,%ebx,8), %edx
	orl	%eax, %edx
	jmp	.L276
.L275:
	movl	%eax, %edx
	testl	%ebx, %ebx
	js	.L276
	orl	$2016, %edx
.L276:
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %eax
	leal	1(%eax,%ecx), %ecx
	cmpl	$255, %ecx
	ja	.L278
	movl	%ecx, %eax
	sarl	$3, %eax
	orl	%edx, %eax
	jmp	.L279
.L278:
	movl	%edx, %eax
	testl	%ecx, %ecx
	js	.L279
	orl	$31, %eax
.L279:
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %edx
	movl	%eax, %ecx
	sarl	$8, %ecx
	# 2(%edx,%esi,4) = %ds:tmp_img+2
	movb	%al, 2(%edx,%esi,4)
	# 3(%edx,%esi,4) = %ds:tmp_img+3
	movb	%cl, 3(%edx,%esi,4)
	# 44(%esp) = %ss:stack+840
	movl	44(%esp), %ecx
	# 40(%esp) = %ss:stack+836
	movl	40(%esp), %ebx
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %edx
	leal	(%ebx,%ecx,8), %eax
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %ebx
	# 32(%edx,%eax,4) = %ds:decdata+?
	movl	32(%edx,%eax,4), %ecx
	leal	3(%ebx,%ecx), %eax
	cmpl	$255, %eax
	ja	.L281
	movl	%eax, %edx
	andl	$248, %edx
	sall	$8, %edx
	jmp	.L282
.L281:
	cltd
	notl	%edx
	andl	$63488, %edx
.L282:
	movl	%ecx, %eax
	subl	%edi, %eax
	incl	%eax
	cmpl	$255, %eax
	ja	.L285
	andl	$252, %eax
	leal	0(,%eax,8), %ebx
	orl	%edx, %ebx
	jmp	.L286
.L285:
	movl	%edx, %ebx
	testl	%eax, %eax
	js	.L286
	orl	$2016, %ebx
.L286:
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %eax
	leal	3(%eax,%ecx), %edx
	cmpl	$255, %edx
	ja	.L288
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ebx, %eax
	jmp	.L289
.L288:
	movl	%ebx, %eax
	testl	%edx, %edx
	js	.L289
	orl	$31, %eax
.L289:
	movl	%eax, %ecx
	# (%ebp,%esi,4) = %ds:tmp_img+64
	movb	%al, %ds:(%ebp,%esi,4)
	sarl	$8, %ecx
	# 1(%ebp,%esi,4) = %ds:tmp_img+65
	movb	%cl, %ds:1(%ebp,%esi,4)
	# 44(%esp) = %ss:stack+840
	movl	44(%esp), %edx
	# 40(%esp) = %ss:stack+836
	movl	40(%esp), %ecx
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %ebx
	leal	(%ecx,%edx,8), %eax
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %edx
	# 36(%ebx,%eax,4) = %ds:decdata+?
	movl	36(%ebx,%eax,4), %ecx
	leal	5(%edx,%ecx), %eax
	cmpl	$255, %eax
	ja	.L291
	movl	%eax, %edx
	andl	$248, %edx
	sall	$8, %edx
	jmp	.L292
.L291:
	cltd
	notl	%edx
	andl	$63488, %edx
.L292:
	movl	%ecx, %eax
	subl	%edi, %eax
	addl	$2, %eax
	cmpl	$255, %eax
	ja	.L295
	andl	$252, %eax
	leal	0(,%eax,8), %ebx
	orl	%edx, %ebx
	jmp	.L296
.L295:
	movl	%edx, %ebx
	testl	%eax, %eax
	js	.L296
	orl	$2016, %ebx
.L296:
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %eax
	leal	5(%eax,%ecx), %edx
	cmpl	$255, %edx
	ja	.L298
	movl	%edx, %eax
	sarl	$3, %eax
	orl	%ebx, %eax
	jmp	.L299
.L298:
	movl	%ebx, %eax
	testl	%edx, %edx
	js	.L299
	orl	$31, %eax
.L299:
	movl	%eax, %ecx
	# 2(%ebp,%esi,4) = %ds:tmp_img+66
	movb	%al, %ds:2(%ebp,%esi,4)
	sarl	$8, %ecx
	# 3(%ebp,%esi,4) = %ds:tmp_img+67
	movb	%cl, %ds:3(%ebp,%esi,4)
	jmp	.L258
.L260:
	# 24(%esp) = %ss:stack+820
	imull	$50, 24(%esp), %eax
	# 20(%esp) = %ss:stack+816
	imull	$130, 20(%esp), %edx
	sall	$6, %ecx
	# 40(%esp) = %ss:stack+836
	movl	40(%esp), %ebx
	leal	128(%edx,%eax), %edi
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %eax
	sarl	$8, %edi
	leal	(%ebx,%ecx), %edx
	# 24(%esp) = %ss:stack+820
	movb	24(%esp), %bl
	# (%eax,%edx,4) = %ds:decdata+?
	movl	(%eax,%edx,4), %ecx
	leal	(%ebx,%ecx), %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	# (%ebx,%esi,8) = %ds:tmp_img
	movb	%al, (%ebx,%esi,8)
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %ebx
	leal	(%ebx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L303
	sarl	$31, %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	notl	%eax
	# (%ebx,%esi,8) = %ds:tmp_img
	movb	%al, (%ebx,%esi,8)
.L303:
	movl	%edi, %ebx
	movb	%cl, %al
	subb	%bl, %al
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	# 1(%ebx,%esi,8) = %ds:tmp_img+1
	movb	%al, 1(%ebx,%esi,8)
	movl	%ecx, %eax
	subl	%edi, %eax
	cmpl	$255, %eax
	jbe	.L307
	sarl	$31, %eax
	notl	%eax
	# 1(%ebx,%esi,8) = %ds:tmp_img+1
	movb	%al, 1(%ebx,%esi,8)
.L307:
	# 20(%esp) = %ss:stack+816
	movb	20(%esp), %bl
	leal	(%ebx,%ecx), %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	# 2(%ebx,%esi,8) = %ds:tmp_img+2
	movb	%al, 2(%ebx,%esi,8)
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %ebx
	leal	(%ebx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L311
	sarl	$31, %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ecx
	notl	%eax
	# 2(%ecx,%esi,8) = %ds:tmp_img+2
	movb	%al, 2(%ecx,%esi,8)
.L311:
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %ebx
	# 4(%ebx,%edx,4) = %ds:decdata+?
	movl	4(%ebx,%edx,4), %ecx
	# 24(%esp) = %ss:stack+820
	movb	24(%esp), %bl
	leal	(%ebx,%ecx), %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	# 4(%ebx,%esi,8) = %ds:tmp_img+4
	movb	%al, 4(%ebx,%esi,8)
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %ebx
	leal	(%ebx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L315
	sarl	$31, %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	notl	%eax
	# 4(%ebx,%esi,8) = %ds:tmp_img+4
	movb	%al, 4(%ebx,%esi,8)
.L315:
	movl	%edi, %ebx
	movb	%cl, %al
	subb	%bl, %al
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	# 5(%ebx,%esi,8) = %ds:tmp_img+5
	movb	%al, 5(%ebx,%esi,8)
	movl	%ecx, %eax
	subl	%edi, %eax
	cmpl	$255, %eax
	jbe	.L319
	sarl	$31, %eax
	notl	%eax
	# 5(%ebx,%esi,8) = %ds:tmp_img+5
	movb	%al, 5(%ebx,%esi,8)
.L319:
	# 20(%esp) = %ss:stack+816
	movb	20(%esp), %bl
	leal	(%ebx,%ecx), %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ebx
	# 6(%ebx,%esi,8) = %ds:tmp_img+6
	movb	%al, 6(%ebx,%esi,8)
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %ebx
	leal	(%ebx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L323
	sarl	$31, %eax
	# 36(%esp) = %ss:stack+832
	movl	36(%esp), %ecx
	notl	%eax
	# 6(%ecx,%esi,8) = %ds:tmp_img+6
	movb	%al, 6(%ecx,%esi,8)
.L323:
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %ebx
	# 32(%ebx,%edx,4) = %ds:decdata+?
	movl	32(%ebx,%edx,4), %ecx
	# 24(%esp) = %ss:stack+820
	movb	24(%esp), %dl
	leal	(%edx,%ecx), %eax
	# (%ebp,%esi,8) = %ds:tmp_img+64
	movb	%al, %ds:(%ebp,%esi,8)
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %ebx
	leal	(%ebx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L327
	sarl	$31, %eax
	notl	%eax
	# (%ebp,%esi,8) = %ds:tmp_img+64
	movb	%al, %ds:(%ebp,%esi,8)
.L327:
	movb	%cl, %al
	movl	%edi, %edx
	subb	%dl, %al
	# 1(%ebp,%esi,8) = %ds:tmp_img+65
	movb	%al, %ds:1(%ebp,%esi,8)
	movl	%ecx, %eax
	subl	%edi, %eax
	cmpl	$255, %eax
	jbe	.L331
	sarl	$31, %eax
	notl	%eax
	# 1(%ebp,%esi,8) = %ds:tmp_img+65
	movb	%al, %ds:1(%ebp,%esi,8)
.L331:
	# 20(%esp) = %ss:stack+816
	movb	20(%esp), %bl
	leal	(%ebx,%ecx), %eax
	# 2(%ebp,%esi,8) = %ds:tmp_img+66
	movb	%al, %ds:2(%ebp,%esi,8)
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %edx
	leal	(%edx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L335
	sarl	$31, %eax
	notl	%eax
	# 2(%ebp,%esi,8) = %ds:tmp_img+66
	movb	%al, %ds:2(%ebp,%esi,8)
.L335:
	# 44(%esp) = %ss:stack+840
	movl	44(%esp), %ecx
	# 40(%esp) = %ss:stack+836
	movl	40(%esp), %ebx
	# 32(%esp) = %ss:stack+828
	movl	32(%esp), %edx
	leal	(%ebx,%ecx,8), %eax
	# 24(%esp) = %ss:stack+820
	movb	24(%esp), %bl
	# 36(%edx,%eax,4) = %ds:decdata+?
	movl	36(%edx,%eax,4), %ecx
	leal	(%ebx,%ecx), %eax
	# 4(%ebp,%esi,8) = %ds:tmp_img+68
	movb	%al, %ds:4(%ebp,%esi,8)
	# 24(%esp) = %ss:stack+820
	movl	24(%esp), %edx
	leal	(%edx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L339
	sarl	$31, %eax
	notl	%eax
	# 4(%ebp,%esi,8) = %ds:tmp_img+68
	movb	%al, %ds:4(%ebp,%esi,8)
.L339:
	movb	%cl, %al
	movl	%edi, %ebx
	subb	%bl, %al
	# 5(%ebp,%esi,8) = %ds:tmp_img+69
	movb	%al, %ds:5(%ebp,%esi,8)
	movl	%ecx, %eax
	subl	%edi, %eax
	cmpl	$255, %eax
	jbe	.L343
	sarl	$31, %eax
	notl	%eax
	# 5(%ebp,%esi,8) = %ds:tmp_img+69
	movb	%al, %ds:5(%ebp,%esi,8)
.L343:
	# 20(%esp) = %ss:stack+816
	movb	20(%esp), %dl
	leal	(%edx,%ecx), %eax
	# 6(%ebp,%esi,8) = %ds:tmp_img+70
	movb	%al, %ds:6(%ebp,%esi,8)
	# 20(%esp) = %ss:stack+816
	movl	20(%esp), %ebx
	leal	(%ebx,%ecx), %eax
	cmpl	$255, %eax
	jbe	.L258
	sarl	$31, %eax
	notl	%eax
	# 6(%ebp,%esi,8) = %ds:tmp_img+70
	movb	%al, %ds:6(%ebp,%esi,8)
.L258:
	# 16(%esp) = %ss:stack+812
	movl	16(%esp), %esi
	cmpl	$7, %esi
	jle	.L350
	# 48(%esp) = %ss:stack+844
	decl	48(%esp)
	# 56(%esp) = %ss:stack+852
	movl	56(%esp), %eax
	addl	%eax, %eax
	# 28(%esp) = %ss:stack+824
	addl	$32, 28(%esp)
	# 32(%esp) = %ss:stack+828
	addl	$64, 32(%esp)
	# 36(%esp) = %ss:stack+832
	addl	%eax, 36(%esp)
	addl	%eax, %ebp
	# 48(%esp) = %ss:stack+844
	cmpl	$0, 48(%esp)
	jg	.L351
	# 52(%esp) = %ss:stack+848
	decl	52(%esp)
	# 32(%esp) = %ss:stack+828
	addl	$256, 32(%esp)
	# 52(%esp) = %ss:stack+848
	cmpl	$0, 52(%esp)
	jg	.L352
	# 80(%esp) = %ss:stack+876
	movl	80(%esp), %eax
	xorl	%edx, %edx
	# 100(%esp) = %ss:stack+896
	cmpl	%eax, 100(%esp)
	jne	.L355
	# 100(%esp) = %ss:stack+896
	movl	100(%esp), %eax
	# 192(%esp) = %ss:stack+988
	movl	192(%esp), %edx
	sall	$4, %eax
	subl	%eax, %edx
.L355:
	# 76(%esp) = %ss:stack+872
	movl	76(%esp), %ecx
	# 60(%esp) = %ss:stack+856
	movl	$16, 60(%esp)
	# 100(%esp) = %ss:stack+896
	cmpl	%ecx, 100(%esp)
	jne	.L357
	# 100(%esp) = %ss:stack+896
	movl	100(%esp), %eax
	# 196(%esp) = %ss:stack+992
	movl	196(%esp), %ebx
	sall	$4, %eax
	subl	%eax, %ebx
	# 60(%esp) = %ss:stack+856
	movl	%ebx, 60(%esp)
.L357:
	movl	%edx, %ebx
	# 60(%esp) = %ss:stack+856
	cmpl	60(%esp), %edx
	jge	.L221
	movl	%edx, %eax
	sall	$4, %eax
	# 12(%esp) = %ss:stack+808
	movl	%eax, 12(%esp)
	# 8(%esp) = %ss:stack+804
	movl	%eax, 8(%esp)
.L378:
	# 100(%esp) = %ss:stack+896
	movl	100(%esp), %eax
	# 88(%esp) = %ss:stack+884
	movl	88(%esp), %ecx
	sall	$4, %eax
	xorl	%edx, %edx
	# 192(%esp) = %ss:stack+988
	subl	192(%esp), %eax
	leal	(%ebx,%eax), %edi
	# 188(%esp) = %ss:stack+984
	movl	188(%esp), %eax
	# 184(%esp) = %ss:stack+980
	subl	184(%esp), %eax
	imull	%eax, %edi
	# 104(%esp) = %ss:stack+900
	cmpl	%ecx, 104(%esp)
	jne	.L363
	# 104(%esp) = %ss:stack+900
	movl	104(%esp), %eax
	# 184(%esp) = %ss:stack+980
	movl	184(%esp), %edx
	sall	$4, %eax
	subl	%eax, %edx
.L363:
	# 84(%esp) = %ss:stack+880
	movl	84(%esp), %eax
	movl	$16, %ebp
	# 104(%esp) = %ss:stack+900
	cmpl	%eax, 104(%esp)
	jne	.L365
	# 104(%esp) = %ss:stack+900
	movl	104(%esp), %eax
	# 188(%esp) = %ss:stack+984
	movl	188(%esp), %ebp
	sall	$4, %eax
	subl	%eax, %ebp
.L365:
	# 200(%esp) = %ss:stack+996
	cmpl	$16, 200(%esp)
	jne	.L366
	movl	%edx, %esi
	cmpl	%ebp, %edx
	jge	.L360
.L371:
	# 104(%esp) = %ss:stack+900
	movl	104(%esp), %eax
	# 184(%esp) = %ss:stack+980
	movl	184(%esp), %edx
	sall	$5, %eax
	addl	%edx, %edx
	# 180(%esp) = %ss:stack+976
	addl	180(%esp), %eax
	leal	(%edi,%esi), %ecx
	subl	%edx, %eax
	# 8(%esp) = %ss:stack+804
	movl	8(%esp), %edx
	addl	%esi, %edx
	incl	%esi
	cmpl	%ebp, %esi
	# tmp_img(%edx,%edx) = %ds:tmp_img+?
	movw	tmp_img(%edx,%edx), %dx
	# (%eax,%ecx,2) = %fs:pic+?
	movw	%dx, %fs:(%eax,%ecx,2)
	jl	.L371
	jmp	.L360
.L366:
	movl	%edx, %esi
	cmpl	%ebp, %edx
	jge	.L360
.L377:
	# 104(%esp) = %ss:stack+900
	movl	104(%esp), %eax
	# 184(%esp) = %ss:stack+980
	movl	184(%esp), %edx
	sall	$6, %eax
	leal	(%edi,%esi), %ecx
	sall	$2, %edx
	# 180(%esp) = %ss:stack+976
	addl	180(%esp), %eax
	subl	%edx, %eax
	# 12(%esp) = %ss:stack+808
	movl	12(%esp), %edx
	addl	%esi, %edx
	incl	%esi
	cmpl	%ebp, %esi
	# tmp_img(,%edx,4) = %ds:tmp_img+?
	movl	tmp_img(,%edx,4), %edx
	# (%eax,%ecx,4) = %fs:pic+?
	movl	%edx, %fs:(%eax,%ecx,4)
	jl	.L377
.L360:
	incl	%ebx
	# 8(%esp) = %ss:stack+804
	addl	$16, 8(%esp)
	# 12(%esp) = %ss:stack+808
	addl	$16, 12(%esp)
	# 60(%esp) = %ss:stack+856
	cmpl	60(%esp), %ebx
	jl	.L378
.L221:
	# 104(%esp) = %ss:stack+900
	incl	104(%esp)
	# 112(%esp) = %ss:stack+908
	movl	112(%esp), %edx
	# 104(%esp) = %ss:stack+900
	cmpl	%edx, 104(%esp)
	jl	.L379
.L391:
	# 100(%esp) = %ss:stack+896
	incl	100(%esp)
	# 108(%esp) = %ss:stack+904
	movl	108(%esp), %ecx
	# 100(%esp) = %ss:stack+896
	cmpl	%ecx, 100(%esp)
	jl	.L380
.L389:
	xorl	%ecx, %ecx
.L171:
	addl	$156, %esp
	movl	%ecx, %eax
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

jpeg_get_size:
	pushl	%ebx
	# 8(%esp) = %ss:stack+996
	movl	8(%esp), %eax
	# datap = %ds:datap
	movl	%eax, datap
	call	getbyte
	call	getbyte
	movl	$192, %eax
	call	readtables
	xorl	%edx, %edx
	testl	%eax, %eax
	jne	.L412
	call	getword
	call	getbyte
	call	getword
	movl	%eax, %ebx
	call	getword
	sall	$16, %ebx
	leal	(%eax,%ebx), %edx
.L412:
	movl	%edx, %eax
	popl	%ebx
	ret
