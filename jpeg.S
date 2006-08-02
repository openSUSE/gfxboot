	.file	"jpeg.S"
	.text

	.globl jpeg_decode
	.globl jpeg_get_size

	.equ	in, 0

	.equ	dhuff, 16

	.equ	quant, 5664

	.equ	dscans, 5920

	.equ	comps, 6032

	.equ	info, 6080

	.equ	decdata, 6092

	.equ	datap, 9996

	.equ	tmp_img, 10000

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

getword:
	# datap = %fs:datap
	movl	%fs:datap, %edx
	# (%edx) = %es:jpg+4
	movzwl	%es:(%edx), %eax
	addl	$2, %edx
	xchgb	%al, %ah
	# datap = %fs:datap
	movl	%edx, %fs:datap
	ret

idctqtab:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	pushl	%ecx
	movl	%edx, %ebp
	# (%esp) = %ss:stack+688
	movl	%eax, (%esp)
	xorl	%edi, %edi
.L4:
	leal	zig(%edi,%edi), %ebx
	movl	$aaidct, %esi
.L5:
	# (%ebx) = %cs:zig
	movzbl	%cs:(%ebx), %ecx
	# (%esp) = %ss:stack+688
	movl	(%esp), %eax
	incl	%ebx
	# (%eax,%ecx) = %fs:quant+?
	movzbl	%fs:(%eax,%ecx), %edx
	# (%esi) = %cs:aaidct
	movl	%cs:(%esi), %eax
	addl	$4, %esi
	# aaidct(%edi) = %cs:aaidct
	imull	%cs:aaidct(%edi), %eax
	sarl	$11, %eax
	imull	%eax, %edx
	cmpl	$aaidct+32, %esi
	# (%ebp,%ecx,4) = %fs:decdata+?
	movl	%edx, %fs:(%ebp,%ecx,4)
	jne	.L5
	addl	$4, %edi
	cmpl	$32, %edi
	jne	.L4
	popl	%eax
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
	subl	$388, %esp
	# 8(%esp) = %ss:stack+304
	movl	%edx, 8(%esp)
	# 12(%esp) = %ss:stack+308
	movl	%eax, 12(%esp)
	# 4(%esp) = %ss:stack+300
	movl	%ecx, 4(%esp)
	# 408(%esp) = %ss:stack+704
	movl	408(%esp), %edx
	# 412(%esp) = %ss:stack+708
	cmpl	$1, 412(%esp)
	jne	.L14
	# (%ecx) = %fs:decdata+3136
	movl	%fs:(%ecx), %eax
	# 12(%esp) = %ss:stack+308
	movl	12(%esp), %ecx
	# (%ecx) = %fs:decdata
	imull	%fs:(%ecx), %eax
	leal	(%edx,%eax), %ecx
	movl	$1, %edx
.L16:
	movl	%ecx, %eax
	# 8(%esp) = %ss:stack+304
	movl	8(%esp), %ebx
	sarl	$11, %eax
	# -4(%ebx,%edx,4) = %fs:decdata+1600
	movl	%eax, %fs:-4(%ebx,%edx,4)
	incl	%edx
	cmpl	$65, %edx
	je	.L21
	jmp	.L16
.L14:
	leal	136(%esp), %edi
	# 40(%esp) = %ss:stack+336
	movl	$zig2+8, 40(%esp)
	# 44(%esp) = %ss:stack+340
	movl	%edi, 44(%esp)
	movl	%edx, %ecx
.L18:
	# 40(%esp) = %ss:stack+336
	movl	40(%esp), %edx
	# 12(%esp) = %ss:stack+308
	movl	12(%esp), %ebx
	# 4(%esp) = %ss:stack+300
	movl	4(%esp), %edi
	# -8(%edx) = %cs:zig2
	movzbl	%cs:-8(%edx), %eax
	# (%ebx,%eax,4) = %fs:decdata+?
	movl	%fs:(%ebx,%eax,4), %edx
	# (%edi,%eax,4) = %fs:decdata+?
	imull	%fs:(%edi,%eax,4), %edx
	leal	(%ecx,%edx), %edx
	# 48(%esp) = %ss:stack+344
	movl	%edx, 48(%esp)
	# 40(%esp) = %ss:stack+336
	movl	40(%esp), %edx
	# -7(%edx) = %cs:zig2+1
	movzbl	%cs:-7(%edx), %eax
	# (%ebx,%eax,4) = %fs:decdata+?
	movl	%fs:(%ebx,%eax,4), %ecx
	# (%edi,%eax,4) = %fs:decdata+?
	imull	%fs:(%edi,%eax,4), %ecx
	# 80(%esp) = %ss:stack+376
	movl	%ecx, 80(%esp)
	# 4(%esp) = %ss:stack+300
	movl	4(%esp), %ecx
	# -6(%edx) = %cs:zig2+2
	movzbl	%cs:-6(%edx), %edx
	# (%ebx,%edx,4) = %fs:decdata+?
	movl	%fs:(%ebx,%edx,4), %eax
	# 40(%esp) = %ss:stack+336
	movl	40(%esp), %ebx
	# (%edi,%edx,4) = %fs:decdata+?
	imull	%fs:(%edi,%edx,4), %eax
	# -5(%ebx) = %cs:zig2+3
	movzbl	%cs:-5(%ebx), %edx
	# 12(%esp) = %ss:stack+308
	movl	12(%esp), %edi
	# (%edi,%edx,4) = %fs:decdata+?
	movl	%fs:(%edi,%edx,4), %edi
	# (%ecx,%edx,4) = %fs:decdata+?
	imull	%fs:(%ecx,%edx,4), %edi
	# 100(%esp) = %ss:stack+396
	movl	%edi, 100(%esp)
	# 40(%esp) = %ss:stack+336
	movl	40(%esp), %edi
	# -4(%ebx) = %cs:zig2+4
	movzbl	%cs:-4(%ebx), %edx
	# 12(%esp) = %ss:stack+308
	movl	12(%esp), %ebx
	# (%ebx,%edx,4) = %fs:decdata+?
	movl	%fs:(%ebx,%edx,4), %ebx
	# (%ecx,%edx,4) = %fs:decdata+?
	imull	%fs:(%ecx,%edx,4), %ebx
	# 124(%esp) = %ss:stack+420
	movl	%ebx, 124(%esp)
	# 12(%esp) = %ss:stack+308
	movl	12(%esp), %ecx
	# -3(%edi) = %cs:zig2+5
	movzbl	%cs:-3(%edi), %edx
	# 4(%esp) = %ss:stack+300
	movl	4(%esp), %ebx
	# (%ecx,%edx,4) = %fs:decdata+?
	movl	%fs:(%ecx,%edx,4), %ecx
	# (%ebx,%edx,4) = %fs:decdata+?
	imull	%fs:(%ebx,%edx,4), %ecx
	# 56(%esp) = %ss:stack+352
	movl	%ecx, 56(%esp)
	# -2(%edi) = %cs:zig2+6
	movzbl	%cs:-2(%edi), %edx
	# 12(%esp) = %ss:stack+308
	movl	12(%esp), %edi
	# (%edi,%edx,4) = %fs:decdata+?
	movl	%fs:(%edi,%edx,4), %ecx
	# (%ebx,%edx,4) = %fs:decdata+?
	imull	%fs:(%ebx,%edx,4), %ecx
	# 40(%esp) = %ss:stack+336
	movl	40(%esp), %ebx
	# -1(%ebx) = %cs:zig2+7
	movzbl	%cs:-1(%ebx), %edx
	# (%edi,%edx,4) = %fs:decdata+?
	movl	%fs:(%edi,%edx,4), %ebp
	# 4(%esp) = %ss:stack+300
	movl	4(%esp), %edi
	# (%edi,%edx,4) = %fs:decdata+?
	imull	%fs:(%edi,%edx,4), %ebp
	# 48(%esp) = %ss:stack+344
	movl	48(%esp), %edx
	# 48(%esp) = %ss:stack+344
	movl	48(%esp), %edi
	# 124(%esp) = %ss:stack+420
	subl	124(%esp), %edx
	# 124(%esp) = %ss:stack+420
	addl	124(%esp), %edi
	# 128(%esp) = %ss:stack+424
	movl	%edx, 128(%esp)
	leal	(%eax,%ecx), %edx
	subl	%ecx, %eax
	# 128(%esp) = %ss:stack+424
	movl	128(%esp), %ebx
	imull	$2896, %eax, %eax
	sarl	$11, %eax
	leal	(%edi,%edx), %ecx
	subl	%edx, %edi
	subl	%edx, %eax
	# 116(%esp) = %ss:stack+412
	movl	%edi, 116(%esp)
	# 128(%esp) = %ss:stack+424
	movl	128(%esp), %edi
	addl	%eax, %ebx
	subl	%eax, %edi
	# 72(%esp) = %ss:stack+368
	movl	%ecx, 72(%esp)
	# 56(%esp) = %ss:stack+352
	movl	56(%esp), %eax
	# 56(%esp) = %ss:stack+352
	movl	56(%esp), %ecx
	# 100(%esp) = %ss:stack+396
	addl	100(%esp), %eax
	# 100(%esp) = %ss:stack+396
	subl	100(%esp), %ecx
	# 76(%esp) = %ss:stack+372
	movl	%ebx, 76(%esp)
	# 80(%esp) = %ss:stack+376
	movl	80(%esp), %edx
	# 80(%esp) = %ss:stack+376
	movl	80(%esp), %ebx
	subl	%ebp, %ebx
	addl	%ebp, %edx
	# 112(%esp) = %ss:stack+408
	movl	%edi, 112(%esp)
	leal	(%edx,%eax), %ebp
	subl	%eax, %edx
	leal	(%ecx,%ebx), %eax
	imull	$5351, %ebx, %edi
	imull	$1567, %eax, %eax
	imull	$2217, %ecx, %ecx
	imull	$2896, %edx, %edx
	sarl	$11, %eax
	# 44(%esp) = %ss:stack+340
	movl	44(%esp), %ebx
	sarl	$11, %edi
	sarl	$11, %ecx
	subl	%eax, %edi
	subl	%ebp, %edi
	addl	%eax, %ecx
	sarl	$11, %edx
	# 72(%esp) = %ss:stack+368
	movl	72(%esp), %eax
	subl	%edi, %edx
	addl	%ebp, %eax
	# -4(%ebx) = %ss:stack+428
	movl	%eax, %ss:-4(%ebx)
	# 76(%esp) = %ss:stack+372
	movl	76(%esp), %eax
	addl	%edi, %eax
	subl	%edx, %ecx
	# 28(%ebx) = %ss:stack+460
	movl	%eax, %ss:28(%ebx)
	# 112(%esp) = %ss:stack+408
	movl	112(%esp), %eax
	addl	%edx, %eax
	# 88(%esp) = %ss:stack+384
	movl	%edi, 88(%esp)
	# 60(%ebx) = %ss:stack+492
	movl	%eax, %ss:60(%ebx)
	# 112(%esp) = %ss:stack+408
	subl	%edx, 112(%esp)
	# 116(%esp) = %ss:stack+412
	movl	116(%esp), %eax
	# 88(%esp) = %ss:stack+384
	movl	88(%esp), %edx
	# 116(%esp) = %ss:stack+412
	subl	%ecx, 116(%esp)
	addl	%ecx, %eax
	# 76(%esp) = %ss:stack+372
	subl	%edx, 76(%esp)
	# 116(%esp) = %ss:stack+412
	movl	116(%esp), %edi
	# 72(%esp) = %ss:stack+368
	subl	%ebp, 72(%esp)
	# 92(%ebx) = %ss:stack+524
	movl	%eax, %ss:92(%ebx)
	# 40(%esp) = %ss:stack+336
	addl	$8, 40(%esp)
	# 124(%ebx) = %ss:stack+556
	movl	%edi, %ss:124(%ebx)
	# 76(%esp) = %ss:stack+372
	movl	76(%esp), %ecx
	# 112(%esp) = %ss:stack+408
	movl	112(%esp), %eax
	# 72(%esp) = %ss:stack+368
	movl	72(%esp), %edi
	# 188(%ebx) = %ss:stack+620
	movl	%ecx, %ss:188(%ebx)
	# 156(%ebx) = %ss:stack+588
	movl	%eax, %ss:156(%ebx)
	# 220(%ebx) = %ss:stack+652
	movl	%edi, %ss:220(%ebx)
	addl	$4, %ebx
	xorl	%ecx, %ecx
	# 44(%esp) = %ss:stack+340
	movl	%ebx, 44(%esp)
	# 40(%esp) = %ss:stack+336
	cmpl	$zig2+72, 40(%esp)
	jne	.L18
	# 32(%esp) = %ss:stack+328
	movl	$0, 32(%esp)
.L20:
	leal	132(%esp), %eax
	# 32(%esp) = %ss:stack+328
	movl	32(%esp), %ecx
	# 32(%esp) = %ss:stack+328
	movl	32(%esp), %edx
	# 16(%eax,%ecx) = %ss:stack+?
	movl	%ss:16(%eax,%ecx), %edi
	# 4(%eax,%ecx) = %ss:stack+?
	movl	%ss:4(%eax,%ecx), %ebx
	# 20(%esp) = %ss:stack+316
	movl	%edi, 20(%esp)
	movl	%ecx, %edi
	# (%edx,%eax) = %ss:stack+?
	movl	%ss:(%edx,%eax), %edx
	# 12(%eax,%ecx) = %ss:stack+?
	movl	%ss:12(%eax,%ecx), %esi
	# 24(%eax,%edi) = %ss:stack+?
	movl	%ss:24(%eax,%edi), %edi
	# 16(%esp) = %ss:stack+312
	movl	%edx, 16(%esp)
	# 24(%esp) = %ss:stack+320
	movl	%edi, 24(%esp)
	# 32(%esp) = %ss:stack+328
	movl	32(%esp), %edi
	# 8(%eax,%ecx) = %ss:stack+?
	movl	%ss:8(%eax,%ecx), %edx
	# 20(%eax,%ecx) = %ss:stack+?
	movl	%ss:20(%eax,%ecx), %ecx
	# 28(%eax,%edi) = %ss:stack+?
	movl	%ss:28(%eax,%edi), %eax
	# 16(%esp) = %ss:stack+312
	movl	16(%esp), %ebp
	# 28(%esp) = %ss:stack+324
	movl	%eax, 28(%esp)
	# 16(%esp) = %ss:stack+312
	movl	16(%esp), %eax
	subl	%ebx, %eax
	addl	%ebx, %ebp
	# 120(%esp) = %ss:stack+416
	movl	%eax, 120(%esp)
	leal	(%edx,%esi), %eax
	subl	%esi, %edx
	# 120(%esp) = %ss:stack+416
	movl	120(%esp), %edi
	imull	$2896, %edx, %edx
	sarl	$11, %edx
	leal	(%ebp,%eax), %ebx
	subl	%eax, %edx
	subl	%eax, %ebp
	# 120(%esp) = %ss:stack+416
	movl	120(%esp), %eax
	addl	%edx, %edi
	subl	%edx, %eax
	# 20(%esp) = %ss:stack+316
	movl	20(%esp), %edx
	# 28(%esp) = %ss:stack+324
	subl	28(%esp), %edx
	# 60(%esp) = %ss:stack+356
	movl	%ebx, 60(%esp)
	# 64(%esp) = %ss:stack+360
	movl	%edi, 64(%esp)
	# 20(%esp) = %ss:stack+316
	movl	20(%esp), %ebx
	# 24(%esp) = %ss:stack+320
	movl	24(%esp), %edi
	# 68(%esp) = %ss:stack+364
	movl	%edx, 68(%esp)
	# 28(%esp) = %ss:stack+324
	addl	28(%esp), %ebx
	# 108(%esp) = %ss:stack+404
	movl	%eax, 108(%esp)
	leal	(%ecx,%edi), %edx
	# 68(%esp) = %ss:stack+364
	movl	68(%esp), %eax
	subl	%edi, %ecx
	# 92(%esp) = %ss:stack+388
	movl	%ebx, 92(%esp)
	addl	%ecx, %eax
	addl	%edx, %ebx
	# 96(%esp) = %ss:stack+392
	movl	%ebx, 96(%esp)
	# 92(%esp) = %ss:stack+388
	subl	92(%esp), %edx
	# 68(%esp) = %ss:stack+364
	imull	$2217, 68(%esp), %ebx
	imull	$1567, %eax, %eax
	imull	$5351, %ecx, %ecx
	imull	$2896, %edx, %edx
	sarl	$11, %eax
	sarl	$11, %ebx
	sarl	$11, %ecx
	# (%esp) = %ss:stack+296
	movl	%ebx, (%esp)
	subl	%eax, %ecx
	addl	%eax, %ebx
	# 32(%esp) = %ss:stack+328
	movl	32(%esp), %edi
	# 60(%esp) = %ss:stack+356
	movl	60(%esp), %eax
	# 8(%esp) = %ss:stack+304
	addl	8(%esp), %edi
	# 96(%esp) = %ss:stack+392
	addl	96(%esp), %eax
	# 96(%esp) = %ss:stack+392
	subl	96(%esp), %ecx
	# 52(%esp) = %ss:stack+348
	movl	%ebx, 52(%esp)
	sarl	$11, %eax
	# 36(%esp) = %ss:stack+332
	movl	%edi, 36(%esp)
	sarl	$11, %edx
	# (%edi) = %fs:decdata+?
	movl	%eax, %fs:(%edi)
	# 64(%esp) = %ss:stack+360
	movl	64(%esp), %eax
	subl	%ecx, %edx
	addl	%ecx, %eax
	subl	%edx, %ebx
	sarl	$11, %eax
	# 4(%edi) = %fs:decdata+?
	movl	%eax, %fs:4(%edi)
	# 108(%esp) = %ss:stack+404
	movl	108(%esp), %eax
	addl	%edx, %eax
	# 64(%esp) = %ss:stack+360
	subl	%ecx, 64(%esp)
	# 96(%esp) = %ss:stack+392
	movl	96(%esp), %ecx
	# 108(%esp) = %ss:stack+404
	subl	%edx, 108(%esp)
	sarl	$11, %eax
	# 60(%esp) = %ss:stack+356
	subl	%ecx, 60(%esp)
	# 108(%esp) = %ss:stack+404
	sarl	$11, 108(%esp)
	# 64(%esp) = %ss:stack+360
	sarl	$11, 64(%esp)
	# 60(%esp) = %ss:stack+356
	sarl	$11, 60(%esp)
	# 8(%edi) = %fs:decdata+?
	movl	%eax, %fs:8(%edi)
	leal	(%ebp,%ebx), %eax
	sarl	$11, %eax
	subl	%ebx, %ebp
	# 12(%edi) = %fs:decdata+?
	movl	%eax, %fs:12(%edi)
	# 64(%esp) = %ss:stack+360
	movl	64(%esp), %edx
	sarl	$11, %ebp
	# 108(%esp) = %ss:stack+404
	movl	108(%esp), %eax
	# 60(%esp) = %ss:stack+356
	movl	60(%esp), %ebx
	# 16(%edi) = %fs:decdata+?
	movl	%ebp, %fs:16(%edi)
	# 20(%edi) = %fs:decdata+?
	movl	%eax, %fs:20(%edi)
	# 24(%edi) = %fs:decdata+?
	movl	%edx, %fs:24(%edi)
	# 28(%edi) = %fs:decdata+?
	movl	%ebx, %fs:28(%edi)
	# 32(%esp) = %ss:stack+328
	addl	$32, 32(%esp)
	# 32(%esp) = %ss:stack+328
	cmpl	$256, 32(%esp)
	jne	.L20
.L21:
	addl	$388, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

scaleidctqtab:
	pushl	%ebx
	leal	4(%eax), %ecx
	movl	%edx, %ebx
	leal	260(%eax), %edx
.L27:
	# -4(%ecx) = %fs:decdata+3392
	movl	%fs:-4(%ecx), %eax
	imull	%ebx, %eax
	sarl	$11, %eax
	# -4(%ecx) = %fs:decdata+3392
	movl	%eax, %fs:-4(%ecx)
	addl	$4, %ecx
	cmpl	%edx, %ecx
	jne	.L27
	popl	%ebx
	ret

store_16:
	imull	$31, %eax, %eax
	imull	$63, %edx, %edx
	imull	$31, %ecx, %ecx
	pushl	%ebx
	# 8(%esp) = %ss:stack+708
	movl	8(%esp), %ebx
	addl	%ebx, %eax
	addl	%ebx, %edx
	shrl	$8, %eax
	addl	%ebx, %ecx
	shrl	$8, %edx
	popl	%ebx
	sall	$11, %eax
	sall	$5, %edx
	shrl	$8, %ecx
	addl	%edx, %eax
	addl	%ecx, %eax
	ret

store_8:
	imull	$7, %edx, %edx
	imull	$7, %ecx, %ecx
	pushl	%ebx
	leal	(%eax,%eax,2), %eax
	# 8(%esp) = %ss:stack+708
	movl	8(%esp), %ebx
	addl	%ebx, %eax
	addl	%ebx, %edx
	shrl	$8, %eax
	addl	%ebx, %ecx
	sall	$6, %eax
	popl	%ebx
	shrl	$8, %edx
	shrl	$8, %ecx
	leal	(%eax,%edx,8), %edx
	leal	(%edx,%ecx), %eax
	ret

fillbits:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	pushl	%esi
	movl	%eax, %ebp
	movl	%edx, %ebx
	# 8(%eax) = %fs:in+8
	cmpl	$0, %fs:8(%eax)
	jne	.L37
	# datap = %fs:datap
	movl	%fs:datap, %edx
	jmp	.L39
.L37:
	cmpl	$16, %edx
	jg	.L40
	sall	$16, %ecx
	addl	$16, %ebx
	# (%eax) = %fs:in
	movl	%ecx, %fs:(%eax)
	jmp	.L40
.L42:
	# (%edx) = %es:jpg+14
	movb	%es:(%edx), %al
	movzbl	%al, %esi
	# (%esp) = %ss:stack+688
	movl	%esi, (%esp)
	incb	%al
	leal	1(%edx), %esi
	jne	.L43
	# 1(%edx) = %es:jpg+15
	movb	%es:1(%edx), %al
	leal	2(%edx), %esi
	movzbl	%al, %edi
	testb	%al, %al
	je	.L43
	# datap = %fs:datap
	movl	%esi, %fs:datap
	# 8(%ebp) = %fs:in+8
	movl	%edi, %fs:8(%ebp)
	cmpl	$16, %ebx
	jg	.L46
	sall	$16, %ecx
	addl	$16, %ebx
	jmp	.L46
.L43:
	sall	$8, %ecx
	addl	$8, %ebx
	# (%esp) = %ss:stack+688
	orl	(%esp), %ecx
	movl	%esi, %edx
.L39:
	cmpl	$24, %ebx
	jle	.L42
	# datap = %fs:datap
	movl	%edx, %fs:datap
.L46:
	# (%ebp) = %fs:in
	movl	%ecx, %fs:(%ebp)
.L40:
	movl	%ebx, %eax
	popl	%ebx
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
	subl	$20, %esp
	movl	%eax, %edi
	# 4(%eax) = %fs:in+4
	movl	%fs:4(%eax), %esi
	# (%eax) = %fs:in
	movl	%fs:(%eax), %ebp
	# 4(%esp) = %ss:stack+668
	movl	%edx, 4(%esp)
	# 44(%esp) = %ss:stack+708
	movl	44(%esp), %edx
	# (%esp) = %ss:stack+664
	movl	%ecx, (%esp)
	# 40(%esp) = %ss:stack+704
	movl	40(%esp), %ebx
	testl	%edx, %edx
	jne	.L51
	# 4(%esp) = %ss:stack+668
	movl	4(%esp), %eax
	# 12(%esp) = %ss:stack+676
	movl	$8, 12(%esp)
	# 8(%esp) = %ss:stack+672
	movl	%eax, 8(%esp)
	jmp	.L53
.L51:
	movl	%edx, %eax
	# (%esp) = %ss:stack+664
	movl	(%esp), %ecx
	sarl	$8, %edx
	andl	$127, %eax
	addl	%eax, %esi
	movl	%edx, %ebx
	sarl	$8, %ebx
	movl	%edx, %eax
	andl	$15, %eax
	# (%ecx) = %ss:stack+948
	movl	%eax, %ss:(%ecx)
	jmp	.L54
.L55:
	# 12(%esp) = %ss:stack+676
	incl	12(%esp)
.L53:
	testl	%esi, %esi
	jg	.L56
	movl	%ebp, %ecx
	movl	%esi, %edx
	movl	%edi, %eax
	call	fillbits
	# (%edi) = %fs:in
	movl	%fs:(%edi), %ebp
	movl	%eax, %esi
.L56:
	decl	%esi
	movl	%ebp, %eax
	movl	%esi, %ecx
	# 8(%esp) = %ss:stack+672
	movl	8(%esp), %edx
	sarl	%cl, %eax
	andl	$1, %eax
	addl	%ebx, %ebx
	orl	%eax, %ebx
	# 32(%edx) = %fs:dhuff+?
	movl	%fs:32(%edx), %eax
	addl	$4, %edx
	cmpl	%eax, %ebx
	# 8(%esp) = %ss:stack+672
	movl	%edx, 8(%esp)
	jge	.L55
	# 12(%esp) = %ss:stack+676
	cmpl	$15, 12(%esp)
	jle	.L59
	# 8(%edi) = %fs:in+8
	movl	$-1, %fs:8(%edi)
	jmp	.L69
.L59:
	# 12(%esp) = %ss:stack+676
	movl	12(%esp), %ecx
	# 4(%esp) = %ss:stack+668
	movl	4(%esp), %edx
	# -4(%edx,%ecx,4) = %fs:dhuff+?
	movl	%fs:-4(%edx,%ecx,4), %eax
	# 68(%edx,%ecx,4) = %fs:dhuff+?
	addl	%fs:68(%edx,%ecx,4), %ebx
	addl	%eax, %eax
	# (%esp) = %ss:stack+664
	movl	(%esp), %ecx
	subl	%eax, %ebx
	# 132(%ebx,%edx) = %fs:dhuff+?
	movzbl	%fs:132(%ebx,%edx), %edx
	movl	%edx, %eax
	movl	%edx, %ebx
	sarl	$4, %eax
	andl	$15, %ebx
	# (%ecx) = %ss:stack+948
	movl	%eax, %ss:(%ecx)
.L54:
	testl	%ebx, %ebx
	jne	.L62
	# 4(%edi) = %fs:in+4
	movl	%esi, %fs:4(%edi)
	# (%edi) = %fs:in
	movl	%ebp, %fs:(%edi)
.L69:
	xorl	%esi, %esi
	jmp	.L61
.L62:
	cmpl	%ebx, %esi
	jge	.L64
	movl	%ebp, %ecx
	movl	%esi, %edx
	movl	%edi, %eax
	call	fillbits
	# (%edi) = %fs:in
	movl	%fs:(%edi), %ebp
	movl	%eax, %esi
.L64:
	subl	%ebx, %esi
	movl	$1, %eax
	# 16(%esp) = %ss:stack+680
	movl	%esi, 16(%esp)
	movl	%ebp, %esi
	# 16(%esp) = %ss:stack+680
	movb	16(%esp), %cl
	movl	%eax, %edx
	sarl	%cl, %esi
	movb	%bl, %cl
	sall	%cl, %edx
	decl	%edx
	leal	-1(%ebx), %ecx
	andl	%edx, %esi
	sall	%cl, %eax
	cmpl	%eax, %esi
	jge	.L66
	orl	$-1, %eax
	movb	%bl, %cl
	sall	%cl, %eax
	leal	1(%esi,%eax), %esi
.L66:
	# 16(%esp) = %ss:stack+680
	movl	16(%esp), %eax
	# (%edi) = %fs:in
	movl	%ebp, %fs:(%edi)
	# 4(%edi) = %fs:in+4
	movl	%eax, %fs:4(%edi)
.L61:
	addl	$20, %esp
	movl	%esi, %eax
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
	subl	$380, %esp
	# 4(%esp) = %ss:stack+316
	movl	%eax, 4(%esp)
	jmp	.L145
.L138:
	# datap = %fs:datap
	movl	%esi, %fs:datap
.L145:
	# datap = %fs:datap
	movl	%fs:datap, %ecx
	# (%ecx) = %es:jpg+4
	movb	%es:(%ecx), %dl
	leal	1(%ecx), %eax
	# datap = %fs:datap
	movl	%eax, %fs:datap
	incb	%dl
	jne	.L144
	# 1(%ecx) = %es:jpg+5
	movb	%es:1(%ecx), %dl
	leal	2(%ecx), %eax
	# datap = %fs:datap
	movl	%eax, %fs:datap
	movzbl	%dl, %eax
	# 4(%esp) = %ss:stack+316
	cmpl	4(%esp), %eax
	je	.L76
	cmpb	$-60, %dl
	je	.L79
	ja	.L82
	cmpb	$-62, %dl
	jne	.L78
	jmp	.L76
.L82:
	cmpb	$-37, %dl
	je	.L80
	cmpb	$-35, %dl
	jne	.L78
	jmp	.L81
.L80:
	call	getword
	# datap = %fs:datap
	movl	%fs:datap, %esi
	movl	%eax, %edi
	jmp	.L83
.L84:
	# (%esi) = %es:jpg+4
	movzbl	%es:(%esi), %eax
	movl	%eax, %edx
	leal	1(%esi), %ecx
	andl	$15, %edx
	cmpl	$3, %edx
	jg	.L126
	sarl	$4, %eax
	testl	%eax, %eax
	jne	.L126
	sall	$6, %edx
	movl	$64, %ebx
	addl	$quant, %edx
.L90:
	# (%ecx) = %es:jpg+5
	movzbl	%es:(%ecx), %eax
	incl	%ecx
	# (%edx) = %fs:quant+?
	movb	%al, %fs:(%edx)
	incl	%edx
	decl	%ebx
	jne	.L90
	subl	$65, %edi
	addl	$65, %esi
.L83:
	cmpl	$2, %edi
	jg	.L84
	jmp	.L138
.L79:
	call	getword
	# datap = %fs:datap
	movl	%fs:datap, %edi
	# 52(%esp) = %ss:stack+364
	movl	%eax, 52(%esp)
	jmp	.L92
.L93:
	# (%edi) = %es:jpg+6
	movzbl	%es:(%edi), %eax
	movl	%eax, %ecx
	incl	%edi
	sarl	$4, %eax
	andl	$15, %ecx
	leal	(%ecx,%eax,2), %edx
	decl	%eax
	# 8(%esp) = %ss:stack+320
	movl	%edx, 8(%esp)
	setg	%dl
	decl	%ecx
	setg	%al
	orb	%al, %dl
	jne	.L128
	movl	$1, %ecx
	movl	$4, %edx
.L96:
	# (%edi) = %es:jpg+7
	movzbl	%es:(%edi), %eax
	incl	%ecx
	incl	%edi
	# 312(%esp,%edx) = %ss:stack+628
	movl	%eax, 312(%esp,%edx)
	addl	$4, %edx
	cmpl	$17, %ecx
	jne	.L96
	# 52(%esp) = %ss:stack+364
	subl	$17, 52(%esp)
	# 12(%esp) = %ss:stack+324
	movl	$0, 12(%esp)
	movl	$1, %ebp
	movl	$4, %esi
.L98:
	# 12(%esp) = %ss:stack+324
	movl	12(%esp), %eax
	# 312(%esp,%esi) = %ss:stack+628
	movl	312(%esp,%esi), %ebx
	xorl	%ecx, %ecx
	leal	60(%esp,%eax), %edx
	jmp	.L99
.L100:
	# (%edi) = %es:jpg+8
	movzbl	%es:(%edi), %eax
	incl	%ecx
	# (%edx) = %ss:stack+?
	movb	%al, %ss:(%edx)
	incl	%edi
	incl	%edx
.L99:
	cmpl	%ebx, %ecx
	jl	.L100
	incl	%ebp
	# 12(%esp) = %ss:stack+324
	addl	%ecx, 12(%esp)
	# 52(%esp) = %ss:stack+364
	subl	%ebx, 52(%esp)
	addl	$4, %esi
	cmpl	$17, %ebp
	jne	.L98
	# 8(%esp) = %ss:stack+320
	imull	$1412, 8(%esp), %eax
	addl	$dhuff, %eax
	movl	$256, %edx
	# 56(%esp) = %ss:stack+368
	movl	%eax, 56(%esp)
.L103:
	# 388(%eax) = %fs:dhuff+?
	movl	$0, %fs:388(%eax)
	addl	$4, %eax
	decl	%edx
	jne	.L103
	# 56(%esp) = %ss:stack+368
	movl	56(%esp), %edx
	leal	60(%esp), %ecx
	movl	%edx, %eax
	# 48(%esp) = %ss:stack+360
	movl	%edx, 48(%esp)
	subl	$-128, %eax
	# 16(%esp) = %ss:stack+328
	movl	%ecx, 16(%esp)
	# 36(%esp) = %ss:stack+348
	movl	$0, 36(%esp)
	# 28(%esp) = %ss:stack+340
	movl	$0, 28(%esp)
	# 32(%esp) = %ss:stack+344
	movl	$0, 32(%esp)
	# (%esp) = %ss:stack+312
	movl	%eax, (%esp)
.L105:
	# 48(%esp) = %ss:stack+360
	movl	48(%esp), %edx
	# (%esp) = %ss:stack+312
	movl	(%esp), %ebp
	# 32(%esp) = %ss:stack+344
	movl	32(%esp), %ecx
	addl	$4, %ebp
	# 68(%edx) = %fs:dhuff+?
	movl	%ecx, %fs:68(%edx)
	# 40(%esp) = %ss:stack+352
	movl	$0, 40(%esp)
	jmp	.L106
.L107:
	# 16(%esp) = %ss:stack+328
	movl	16(%esp), %edx
	# (%edx) = %ss:stack+372
	movb	%ss:(%edx), %al
	incl	%edx
	# (%ebp) = %fs:dhuff+?
	movb	%al, %fs:(%ebp)
	# 16(%esp) = %ss:stack+328
	movl	%edx, 16(%esp)
	# 36(%esp) = %ss:stack+348
	cmpl	$7, 36(%esp)
	jg	.L108
	# 20(%esp) = %ss:stack+332
	movl	$7, 20(%esp)
	# 36(%esp) = %ss:stack+348
	movl	36(%esp), %ecx
	# 20(%esp) = %ss:stack+332
	subl	%ecx, 20(%esp)
	# 28(%esp) = %ss:stack+340
	movl	28(%esp), %edx
	# 20(%esp) = %ss:stack+332
	movb	20(%esp), %cl
	movl	%eax, %ebx
	movl	$1, %esi
	andl	$15, %ebx
	sall	%cl, %edx
	sall	%cl, %esi
	# 44(%esp) = %ss:stack+356
	movl	%edx, 44(%esp)
	jmp	.L110
.L111:
	# 36(%esp) = %ss:stack+348
	movl	36(%esp), %eax
	addl	%ebx, %eax
	# 24(%esp) = %ss:stack+336
	movl	%eax, 24(%esp)
	cmpl	$7, %eax
	jg	.L112
	movl	%ebx, %ecx
	movl	%esi, %edx
	negl	%ecx
	# 36(%esp) = %ss:stack+348
	subl	36(%esp), %ecx
	addl	$7, %ecx
	sarl	%cl, %edx
	testl	%ebx, %ebx
	je	.L114
	leal	-1(%ebx), %ecx
	movl	$1, %eax
	sall	%cl, %eax
	cmpl	%eax, %edx
	jge	.L114
	orl	$-1, %eax
	movb	%bl, %cl
	sall	%cl, %eax
	leal	1(%edx,%eax), %edx
.L114:
	# (%ebp) = %fs:dhuff+?
	movzbl	%fs:(%ebp), %eax
	sall	$16, %edx
	andl	$240, %eax
	sall	$4, %eax
	orl	%eax, %edx
	movl	$7, %eax
	# 24(%esp) = %ss:stack+336
	subl	24(%esp), %eax
	orl	%eax, %edx
	orb	$-128, %dl
	jmp	.L117
.L112:
	# (%ebp) = %fs:dhuff+?
	movzbl	%fs:(%ebp), %eax
	movl	%ebx, %edx
	andl	$240, %eax
	sall	$16, %edx
	sall	$4, %eax
	orl	%eax, %edx
	# 20(%esp) = %ss:stack+332
	orl	20(%esp), %edx
.L117:
	# 44(%esp) = %ss:stack+356
	movl	44(%esp), %eax
	# 56(%esp) = %ss:stack+368
	movl	56(%esp), %ecx
	orl	%esi, %eax
	# 388(%ecx,%eax,4) = %fs:dhuff+?
	movl	%edx, %fs:388(%ecx,%eax,4)
.L110:
	decl	%esi
	jns	.L111
.L108:
	# 28(%esp) = %ss:stack+340
	incl	28(%esp)
	incl	%ebp
	# 32(%esp) = %ss:stack+344
	incl	32(%esp)
	# (%esp) = %ss:stack+312
	incl	(%esp)
	# 40(%esp) = %ss:stack+352
	incl	40(%esp)
.L106:
	# 36(%esp) = %ss:stack+348
	movl	36(%esp), %eax
	# 40(%esp) = %ss:stack+352
	movl	40(%esp), %edx
	# 316(%esp,%eax,4) = %ss:stack+?
	cmpl	316(%esp,%eax,4), %edx
	jl	.L107
	# 48(%esp) = %ss:stack+360
	movl	48(%esp), %ecx
	# 36(%esp) = %ss:stack+348
	incl	36(%esp)
	# 28(%esp) = %ss:stack+340
	movl	28(%esp), %eax
	# (%ecx) = %fs:dhuff+?
	movl	%eax, %fs:(%ecx)
	addl	%eax, %eax
	addl	$4, %ecx
	# 28(%esp) = %ss:stack+340
	movl	%eax, 28(%esp)
	# 48(%esp) = %ss:stack+360
	movl	%ecx, 48(%esp)
	# 36(%esp) = %ss:stack+348
	cmpl	$16, 36(%esp)
	jne	.L105
	# 56(%esp) = %ss:stack+368
	movl	56(%esp), %edx
	# 64(%edx) = %fs:dhuff+?
	movl	$131072, %fs:64(%edx)
.L92:
	# 52(%esp) = %ss:stack+364
	cmpl	$2, 52(%esp)
	jg	.L93
	# datap = %fs:datap
	movl	%edi, %fs:datap
	jmp	.L145
.L81:
	call	getword
	call	getword
	# info+8 = %fs:info+8
	movl	%eax, %fs:info+8
	jmp	.L145
.L78:
	call	getword
	# datap = %fs:datap
	movl	%fs:datap, %edx
	jmp	.L121
.L122:
	incl	%edx
	decl	%eax
.L121:
	cmpl	$2, %eax
	jg	.L122
	# datap = %fs:datap
	movl	%edx, %fs:datap
	jmp	.L145
.L126:
	# datap = %fs:datap
	movl	%ecx, %fs:datap
.L144:
	orl	$-1, %eax
	jmp	.L87
.L128:
	# datap = %fs:datap
	movl	%edi, %fs:datap
	jmp	.L144
.L76:
	xorl	%eax, %eax
.L87:
	addl	$380, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

jpeg_decode:
	pushl	%ebp
	pushl	%edi
	pushl	%esi
	pushl	%ebx
	subl	$240, %esp
	# 260(%esp) = %ss:stack+972
	movl	260(%esp), %ecx
	# datap = %fs:datap
	movl	%ecx, %fs:datap
	# (%ecx) = %es:jpg
	movb	%es:(%ecx), %dl
	leal	1(%ecx), %eax
	# datap = %fs:datap
	movl	%eax, %fs:datap
	incb	%dl
	jne	.L147
	# 1(%ecx) = %es:jpg+1
	movb	%es:1(%ecx), %dl
	leal	2(%ecx), %eax
	# datap = %fs:datap
	movl	%eax, %fs:datap
	cmpb	$-40, %dl
	jne	.L147
	movl	$192, %eax
	call	readtables
	testl	%eax, %eax
	jne	.L150
	movb	$12, %al
	# info+8 = %fs:info+8
	cmpl	$0, %fs:info+8
	jne	.L154
	call	getword
	# datap = %fs:datap
	movl	%fs:datap, %eax
	# (%eax) = %es:jpg+4
	movb	%es:(%eax), %dl
	incl	%eax
	# datap = %fs:datap
	movl	%eax, %fs:datap
	cmpb	$8, %dl
	movl	$2, %eax
	jne	.L154
	call	getword
	# 60(%esp) = %ss:stack+772
	movl	%eax, 60(%esp)
	call	getword
	# 56(%esp) = %ss:stack+768
	movl	%eax, 56(%esp)
	# datap = %fs:datap
	movl	%fs:datap, %eax
	# (%eax) = %es:jpg+5
	movzbl	%es:(%eax), %esi
	leal	1(%eax), %ebx
	# info = %fs:info
	movl	%esi, %fs:info
	# datap = %fs:datap
	movl	%ebx, %fs:datap
	movl	$6, %eax
	cmpl	$4, %esi
	jg	.L154
	movl	$comps, %edi
	# 32(%esp) = %ss:stack+744
	movl	$0, 32(%esp)
	jmp	.L159
.L160:
	# (%ebx) = %es:jpg+8
	movzbl	%es:(%ebx), %eax
	# (%edi) = %fs:comps
	movl	%eax, %fs:(%edi)
	# 1(%ebx) = %es:jpg+9
	movzbl	%es:1(%ebx), %edx
	movl	%edx, %eax
	# 4(%edi) = %fs:comps+4
	movl	%edx, %fs:4(%edi)
	sarl	$4, %eax
	# 2(%ebx) = %es:jpg+10
	movzbl	%es:2(%ebx), %ebp
	addl	$3, %ebx
	cmpl	$3, %eax
	setg	%cl
	andl	$15, %edx
	# 8(%edi) = %fs:comps+8
	movl	%ebp, %fs:8(%edi)
	cmpl	$3, %edx
	setg	%al
	orb	%al, %cl
	jne	.L415
	addl	$12, %edi
	cmpl	$3, %ebp
	jg	.L416
	# 32(%esp) = %ss:stack+744
	incl	32(%esp)
.L159:
	# 32(%esp) = %ss:stack+744
	cmpl	%esi, 32(%esp)
	jl	.L160
	movl	$218, %eax
	# datap = %fs:datap
	movl	%ebx, %fs:datap
	call	readtables
	testl	%eax, %eax
	jne	.L150
	call	getword
	# datap = %fs:datap
	movl	%fs:datap, %ecx
	# (%ecx) = %es:jpg+11
	movb	%es:(%ecx), %al
	leal	1(%ecx), %edx
	# datap = %fs:datap
	movl	%edx, %fs:datap
	cmpb	$3, %al
	movzbl	%al, %edx
	# info+4 = %fs:info+4
	movl	%edx, %fs:info+4
	jne	.L167
	# info = %fs:info
	movl	%fs:info, %eax
	addl	$3, %ecx
	# 24(%esp) = %ss:stack+736
	movl	%eax, 24(%esp)
	movl	$dscans, %edi
.L169:
	# -2(%ecx) = %es:jpg+12
	movzbl	%es:-2(%ecx), %ebp
	# 16(%edi) = %fs:dscans+16
	movl	%ebp, %fs:16(%edi)
	movl	%ecx, %ebx
	# -1(%ecx) = %es:jpg+13
	movzbl	%es:-1(%ecx), %eax
	movl	%eax, %edx
	sarl	$4, %eax
	andl	$15, %edx
	# 36(%esp) = %ss:stack+748
	movl	%edx, 36(%esp)
	# 180(%esp) = %ss:stack+892
	movl	%eax, 180(%esp)
	decl	%eax
	setg	%dl
	# 36(%esp) = %ss:stack+748
	cmpl	$1, 36(%esp)
	setg	%al
	orb	%al, %dl
	jne	.L170
	xorl	%edx, %edx
	movl	$comps, %esi
	jmp	.L172
.L170:
	# datap = %fs:datap
	movl	%ecx, %fs:datap
	jmp	.L428
.L173:
	# (%esi) = %fs:comps
	movl	%fs:(%esi), %eax
	addl	$12, %esi
	cmpl	%ebp, %eax
	je	.L174
	incl	%edx
.L172:
	# 24(%esp) = %ss:stack+736
	cmpl	24(%esp), %edx
	jl	.L173
.L174:
	# 24(%esp) = %ss:stack+736
	cmpl	24(%esp), %edx
	je	.L417
	imull	$12, %edx, %edx
	addl	$2, %ecx
	# comps+4(%edx) = %fs:comps+16
	movl	%fs:comps+4(%edx), %eax
	# 20(%edi) = %fs:dscans+20
	movl	%eax, %fs:20(%edi)
	# comps+8(%edx) = %fs:comps+20
	movl	%fs:comps+8(%edx), %eax
	# 24(%edi) = %fs:dscans+24
	movl	%eax, %fs:24(%edi)
	# 180(%esp) = %ss:stack+892
	imull	$1412, 180(%esp), %eax
	addl	$dhuff, %eax
	# 4(%edi) = %fs:dscans+4
	movl	%eax, %fs:4(%edi)
	# 36(%esp) = %ss:stack+748
	imull	$1412, 36(%esp), %eax
	addl	$dhuff+2824, %eax
	# 8(%edi) = %fs:dscans+8
	movl	%eax, %fs:8(%edi)
	addl	$28, %edi
	cmpl	$dscans+84, %edi
	jne	.L169
	# datap = %fs:datap
	movl	%ebx, %fs:datap
	leal	1(%ebx), %eax
	# (%ebx) = %es:jpg+11
	movzbl	%es:(%ebx), %edx
	# datap = %fs:datap
	movl	%eax, %fs:datap
	leal	2(%ebx), %eax
	# 1(%ebx) = %es:jpg+12
	movzbl	%es:1(%ebx), %ecx
	# datap = %fs:datap
	movl	%eax, %fs:datap
	testl	%edx, %edx
	# 2(%ebx) = %es:jpg+13
	movb	%es:2(%ebx), %al
	# 83(%esp) = %ss:stack+795
	movb	%al, 83(%esp)
	leal	3(%ebx), %eax
	setne	%dl
	# datap = %fs:datap
	movl	%eax, %fs:datap
	cmpl	$63, %ecx
	setne	%al
	orb	%al, %dl
	jne	.L179
	# 83(%esp) = %ss:stack+795
	cmpb	$0, 83(%esp)
	jne	.L179
	# dscans+16 = %fs:dscans+16
	cmpl	$1, %fs:dscans+16
	jne	.L167
	# dscans+44 = %fs:dscans+44
	cmpl	$2, %fs:dscans+44
	jne	.L167
	# dscans+72 = %fs:dscans+72
	cmpl	$3, %fs:dscans+72
	jne	.L167
	# dscans+20 = %fs:dscans+20
	cmpl	$34, %fs:dscans+20
	jne	.L167
	# dscans+48 = %fs:dscans+48
	cmpl	$17, %fs:dscans+48
	jne	.L167
	# dscans+76 = %fs:dscans+76
	cmpl	$17, %fs:dscans+76
	jne	.L167
	# 272(%esp) = %ss:stack+984
	movl	272(%esp), %eax
	# 56(%esp) = %ss:stack+768
	movl	56(%esp), %edx
	addl	$15, %eax
	# 60(%esp) = %ss:stack+772
	movl	60(%esp), %ecx
	sarl	$4, %eax
	addl	$15, %edx
	decl	%eax
	addl	$15, %ecx
	# 68(%esp) = %ss:stack+780
	movl	%eax, 68(%esp)
	# 280(%esp) = %ss:stack+992
	movl	280(%esp), %eax
	addl	$15, %eax
	# 268(%esp) = %ss:stack+980
	movl	268(%esp), %ebx
	sarl	$4, %eax
	# 276(%esp) = %ss:stack+988
	movl	276(%esp), %esi
	sarl	$4, %edx
	sarl	$4, %ecx
	leal	-1(%eax), %edi
	sarl	$4, %ebx
	# 40(%esp) = %ss:stack+752
	movl	%edx, 40(%esp)
	sarl	$4, %esi
	# 44(%esp) = %ss:stack+756
	movl	%ecx, 44(%esp)
	# 64(%esp) = %ss:stack+776
	movl	%ebx, 64(%esp)
	# 72(%esp) = %ss:stack+784
	movl	%esi, 72(%esp)
	# 76(%esp) = %ss:stack+788
	movl	%edi, 76(%esp)
	cmpl	%ecx, %edi
	jge	.L188
	# 44(%esp) = %ss:stack+756
	movl	%eax, 44(%esp)
.L188:
	# dscans+24 = %fs:dscans+24
	movl	%fs:dscans+24, %eax
	movl	$decdata+3136, %edx
	sall	$6, %eax
	addl	$quant, %eax
	call	idctqtab
	# dscans+52 = %fs:dscans+52
	movl	%fs:dscans+52, %eax
	sall	$6, %eax
	movl	$decdata+3392, %edx
	addl	$quant, %eax
	call	idctqtab
	# dscans+80 = %fs:dscans+80
	movl	%fs:dscans+80, %eax
	sall	$6, %eax
	movl	$decdata+3648, %edx
	addl	$quant, %eax
	call	idctqtab
	movl	$3629, %edx
	movl	$decdata+3392, %eax
	call	scaleidctqtab
	movl	$2871, %edx
	movl	$decdata+3648, %eax
	call	scaleidctqtab
	# info+4 = %fs:info+4
	movl	%fs:info+4, %ecx
	xorl	%edx, %edx
	movl	$dscans, %eax
	# in+4 = %fs:in+4
	movl	$0, %fs:in+4
	# in = %fs:in
	movl	$0, %fs:in
	# in+8 = %fs:in+8
	movl	$0, %fs:in+8
	jmp	.L190
.L191:
	# -28(%eax) = %fs:dscans
	movl	$0, %fs:-28(%eax)
	incl	%edx
.L190:
	addl	$28, %eax
	cmpl	%ecx, %edx
	jl	.L191
	# 284(%esp) = %ss:stack+996
	movl	284(%esp), %eax
	# 272(%esp) = %ss:stack+984
	movl	272(%esp), %ecx
	# 268(%esp) = %ss:stack+980
	movl	268(%esp), %ebx
	# 280(%esp) = %ss:stack+992
	movl	280(%esp), %esi
	leal	tmp_img(%eax,%eax), %eax
	# 276(%esp) = %ss:stack+988
	movl	276(%esp), %edi
	# 116(%esp) = %ss:stack+828
	movl	%eax, 116(%esp)
	# 68(%esp) = %ss:stack+780
	movl	68(%esp), %eax
	sall	$4, %eax
	# 284(%esp) = %ss:stack+996
	movl	284(%esp), %edx
	subl	%eax, %ecx
	# 64(%esp) = %ss:stack+776
	movl	64(%esp), %eax
	sall	$4, %eax
	# dscans+12 = %fs:dscans+12
	movl	$2, %fs:dscans+12
	subl	%eax, %ebx
	# 76(%esp) = %ss:stack+788
	movl	76(%esp), %eax
	sall	$4, %eax
	# dscans+40 = %fs:dscans+40
	movl	$1, %fs:dscans+40
	subl	%eax, %esi
	# 72(%esp) = %ss:stack+784
	movl	72(%esp), %eax
	sall	$4, %eax
	# dscans+68 = %fs:dscans+68
	movl	$0, %fs:dscans+68
	subl	%eax, %edi
	# 276(%esp) = %ss:stack+988
	movl	276(%esp), %eax
	sall	$2, %edx
	# 204(%esp) = %ss:stack+916
	movl	%ecx, 204(%esp)
	negl	%eax
	# 104(%esp) = %ss:stack+816
	movl	%edx, 104(%esp)
	# 200(%esp) = %ss:stack+912
	movl	%ebx, 200(%esp)
	# 196(%esp) = %ss:stack+908
	movl	%esi, 196(%esp)
	# 192(%esp) = %ss:stack+904
	movl	%edi, 192(%esp)
	# 176(%esp) = %ss:stack+888
	movl	%eax, 176(%esp)
	# 52(%esp) = %ss:stack+764
	movl	$0, 52(%esp)
	jmp	.L193
.L194:
	movl	$decdata, %edx
	movl	$1536, %eax
	jmp	.L195
.L196:
	# -1(%edx) = %fs:decdata
	movb	$0, %fs:-1(%edx)
.L195:
	decl	%eax
	incl	%edx
	cmpl	$-1, %eax
	jne	.L196
	# in+4 = %fs:in+4
	movl	%fs:in+4, %esi
	# in = %fs:in
	movl	%fs:in, %edi
	# 92(%esp) = %ss:stack+804
	movl	$decdata, 92(%esp)
	# 84(%esp) = %ss:stack+796
	movl	$dscans, 84(%esp)
	# 168(%esp) = %ss:stack+880
	movl	$0, 168(%esp)
	jmp	.L198
.L199:
	# 84(%esp) = %ss:stack+796
	movl	84(%esp), %edx
	cmpl	$7, %esi
	# 4(%edx) = %fs:dscans+4
	movl	%fs:4(%edx), %ebx
	jg	.L200
	movl	%edi, %ecx
	movl	%esi, %edx
	movl	$in, %eax
	call	fillbits
	# in = %fs:in
	movl	%fs:in, %edi
	movl	%eax, %esi
.L200:
	leal	-8(%esi), %ecx
	movl	%edi, %eax
	sarl	%cl, %eax
	andl	$255, %eax
	# 84(%esp) = %ss:stack+796
	movl	84(%esp), %esi
	# 236(%esp) = %ss:stack+948
	movl	%eax, 236(%esp)
	# 388(%ebx,%eax,4) = %fs:dhuff+?
	movl	%fs:388(%ebx,%eax,4), %edx
	# (%esi) = %fs:dscans
	movl	%fs:(%esi), %ebp
	testb	%dl, %dl
	jns	.L202
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	leal	(%ecx,%eax), %esi
	movl	%edx, %eax
	andl	$15, %eax
	# 236(%esp) = %ss:stack+948
	movl	%eax, 236(%esp)
	movl	%edx, %eax
	sarl	$8, %eax
	jmp	.L204
.L418:
	# 92(%esp) = %ss:stack+804
	movl	92(%esp), %eax
	leal	(%eax,%ebp,4), %eax
	# 92(%esp) = %ss:stack+804
	movl	%eax, 92(%esp)
	jmp	.L214
.L202:
	pushl	%edx
	pushl	%eax
	# in+4 = %fs:in+4
	movl	%ecx, %fs:in+4
	movl	%ebx, %edx
	leal	244(%esp), %ecx
	movl	$in, %eax
	# in = %fs:in
	movl	%edi, %fs:in
	call	dec_rec2
	popl	%edx
	# in+4 = %fs:in+4
	movl	%fs:in+4, %esi
	# in = %fs:in
	movl	%fs:in, %edi
	popl	%ecx
.L204:
	# 92(%esp) = %ss:stack+804
	movl	92(%esp), %ecx
	# 84(%esp) = %ss:stack+796
	movl	84(%esp), %edx
	leal	(%ebp,%eax), %eax
	movl	$63, %ebp
	# (%edx) = %fs:dscans
	movl	%eax, %fs:(%edx)
	# (%ecx) = %fs:decdata
	movl	%eax, %fs:(%ecx)
	addl	$4, %ecx
	# 92(%esp) = %ss:stack+804
	movl	%ecx, 92(%esp)
	# 8(%edx) = %fs:dscans+8
	movl	%fs:8(%edx), %ebx
	# 184(%esp) = %ss:stack+896
	movl	%ebx, 184(%esp)
.L205:
	cmpl	$7, %esi
	jg	.L206
	movl	%edi, %ecx
	movl	%esi, %edx
	movl	$in, %eax
	call	fillbits
	# in = %fs:in
	movl	%fs:in, %edi
	movl	%eax, %esi
.L206:
	leal	-8(%esi), %ecx
	movl	%edi, %eax
	sarl	%cl, %eax
	andl	$255, %eax
	# 184(%esp) = %ss:stack+896
	movl	184(%esp), %esi
	# 236(%esp) = %ss:stack+948
	movl	%eax, 236(%esp)
	# 388(%esi,%eax,4) = %fs:dhuff+?
	movl	%fs:388(%esi,%eax,4), %edx
	testb	%dl, %dl
	jns	.L208
	movl	%edx, %eax
	sarl	$8, %edx
	andl	$127, %eax
	movl	%edx, %ebx
	sarl	$8, %ebx
	leal	(%ecx,%eax), %esi
	movl	%edx, %eax
	andl	$15, %eax
	# 236(%esp) = %ss:stack+948
	movl	%eax, 236(%esp)
	jmp	.L210
.L208:
	pushl	%edx
	pushl	%eax
	# in+4 = %fs:in+4
	movl	%ecx, %fs:in+4
	# 192(%esp) = %ss:stack+896
	movl	192(%esp), %edx
	leal	244(%esp), %ecx
	movl	$in, %eax
	# in = %fs:in
	movl	%edi, %fs:in
	call	dec_rec2
	popl	%ecx
	movl	%eax, %ebx
	# in+4 = %fs:in+4
	movl	%fs:in+4, %esi
	# in = %fs:in
	movl	%fs:in, %edi
	popl	%eax
.L210:
	testl	%ebx, %ebx
	jne	.L211
	# 236(%esp) = %ss:stack+948
	cmpl	$0, 236(%esp)
	je	.L418
.L211:
	# 236(%esp) = %ss:stack+948
	movl	236(%esp), %eax
	# 92(%esp) = %ss:stack+804
	movl	92(%esp), %edx
	leal	(%edx,%eax,4), %eax
	# (%eax) = %fs:decdata+?
	movl	%ebx, %fs:(%eax)
	addl	$4, %eax
	# 92(%esp) = %ss:stack+804
	movl	%eax, 92(%esp)
	movl	%ebp, %eax
	# 236(%esp) = %ss:stack+948
	subl	236(%esp), %eax
	leal	-1(%eax), %ebp
	testl	%ebp, %ebp
	jg	.L205
.L214:
	movl	$64, %eax
	# 168(%esp) = %ss:stack+880
	movl	168(%esp), %ecx
	subl	%ebp, %eax
	# 84(%esp) = %ss:stack+796
	movl	84(%esp), %ebx
	# 212(%esp,%ecx,4) = %ss:stack+?
	movl	%eax, 212(%esp,%ecx,4)
	# 88(%esp) = %ss:stack+800
	movl	88(%esp), %eax
	# 12(%ebx) = %fs:dscans+12
	cmpl	%fs:12(%ebx), %eax
	jne	.L215
	addl	$28, %ebx
	# 84(%esp) = %ss:stack+796
	movl	%ebx, 84(%esp)
.L215:
	# 168(%esp) = %ss:stack+880
	incl	168(%esp)
.L198:
	# 168(%esp) = %ss:stack+880
	movl	168(%esp), %edx
	# 88(%esp) = %ss:stack+800
	movl	$5, 88(%esp)
	# 88(%esp) = %ss:stack+800
	subl	%edx, 88(%esp)
	cmpl	$6, %edx
	jne	.L199
	# 72(%esp) = %ss:stack+784
	movl	72(%esp), %ecx
	# 76(%esp) = %ss:stack+788
	movl	76(%esp), %ebx
	# 52(%esp) = %ss:stack+764
	cmpl	%ecx, 52(%esp)
	# in+4 = %fs:in+4
	movl	%esi, %fs:in+4
	setge	%dl
	# 52(%esp) = %ss:stack+764
	cmpl	%ebx, 52(%esp)
	# in = %fs:in
	movl	%edi, %fs:in
	setle	%al
	testb	%al, %dl
	je	.L218
	# 64(%esp) = %ss:stack+776
	movl	64(%esp), %esi
	# 68(%esp) = %ss:stack+780
	movl	68(%esp), %edi
	# 48(%esp) = %ss:stack+760
	cmpl	%esi, 48(%esp)
	setge	%dl
	# 48(%esp) = %ss:stack+760
	cmpl	%edi, 48(%esp)
	setle	%al
	testb	%al, %dl
	je	.L218
	# 212(%esp) = %ss:stack+924
	pushl	212(%esp)
	movl	$decdata+3136, %ecx
	pushl	$263168
	movl	$decdata+1600, %edx
	movl	$decdata, %eax
	call	idct
	movl	$decdata+3136, %ecx
	# 224(%esp) = %ss:stack+928
	pushl	224(%esp)
	movl	$decdata+1856, %edx
	pushl	$263168
	movl	$decdata+256, %eax
	call	idct
	movl	$decdata+3136, %ecx
	# 236(%esp) = %ss:stack+932
	pushl	236(%esp)
	movl	$decdata+2112, %edx
	pushl	$263168
	movl	$decdata+512, %eax
	call	idct
	movl	$decdata+3136, %ecx
	# 248(%esp) = %ss:stack+936
	pushl	248(%esp)
	movl	$decdata+2368, %edx
	pushl	$263168
	movl	$decdata+768, %eax
	call	idct
	addl	$32, %esp
	# 228(%esp) = %ss:stack+940
	pushl	228(%esp)
	movl	$decdata+3392, %ecx
	pushl	$1024
	movl	$decdata+2624, %edx
	movl	$decdata+1024, %eax
	call	idct
	movl	$decdata+1280, %eax
	# 240(%esp) = %ss:stack+944
	pushl	240(%esp)
	movl	$decdata+3648, %ecx
	pushl	$1024
	movl	$decdata+2880, %edx
	call	idct
	# 132(%esp) = %ss:stack+828
	movl	132(%esp), %eax
	# 204(%esp) = %ss:stack+900
	movl	%eax, 204(%esp)
	# 128(%esp) = %ss:stack+824
	movl	$tmp_img, 128(%esp)
	# 136(%esp) = %ss:stack+832
	movl	$decdata+1600, 136(%esp)
	# 180(%esp) = %ss:stack+876
	movl	$decdata+2624, 180(%esp)
	addl	$16, %esp
.L221:
	# 164(%esp) = %ss:stack+876
	movl	164(%esp), %edx
	# 120(%esp) = %ss:stack+832
	movl	120(%esp), %ecx
	# 124(%esp) = %ss:stack+836
	movl	%edx, 124(%esp)
	# 208(%esp) = %ss:stack+920
	movl	%ecx, 208(%esp)
	# 132(%esp) = %ss:stack+844
	movl	$4, 132(%esp)
.L222:
	# 124(%esp) = %ss:stack+836
	movl	124(%esp), %ebx
	# 108(%esp) = %ss:stack+820
	movl	$0, 108(%esp)
	# 20(%esp) = %ss:stack+732
	movl	$0, 20(%esp)
	# 16(%esp) = %ss:stack+728
	movl	%ebx, 16(%esp)
	# 12(%esp) = %ss:stack+724
	movl	$0, 12(%esp)
.L223:
	# 108(%esp) = %ss:stack+820
	movl	108(%esp), %eax
	# 108(%esp) = %ss:stack+820
	movl	108(%esp), %ecx
	sarl	$2, %ecx
	andl	$3, %eax
	# 284(%esp) = %ss:stack+996
	cmpl	$16, 284(%esp)
	leal	(%eax,%eax), %ebx
	je	.L226
	# 284(%esp) = %ss:stack+996
	cmpl	$32, 284(%esp)
	je	.L227
	# 284(%esp) = %ss:stack+996
	cmpl	$8, 284(%esp)
	jne	.L224
	sall	$6, %ecx
	# 16(%esp) = %ss:stack+728
	movl	16(%esp), %esi
	# (%esi) = %fs:decdata+2624
	movl	%fs:(%esi), %edi
	# 256(%esi) = %fs:decdata+2880
	movl	%fs:256(%esi), %ebp
	imull	$50, %edi, %eax
	imull	$130, %ebp, %edx
	leal	128(%eax,%edx), %esi
	leal	(%ecx,%ebx), %eax
	sall	$2, %eax
	# 208(%esp) = %ss:stack+920
	movl	208(%esp), %edx
	sarl	$8, %esi
	# 8(%esp) = %ss:stack+720
	movl	%eax, 8(%esp)
	# (%edx,%eax) = %fs:decdata+?
	movl	%fs:(%edx,%eax), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L228
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L228:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L232
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L232:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L236
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L236:
	# 108(%esp) = %ss:stack+820
	movl	108(%esp), %ebx
	addl	%ebx, %ebx
	# 160(%esp) = %ss:stack+872
	movl	%ebx, 160(%esp)
	# 112(%esp) = %ss:stack+824
	movl	112(%esp), %ebx
	# 160(%esp) = %ss:stack+872
	addl	160(%esp), %ebx
	# 156(%esp) = %ss:stack+868
	movl	%ebx, 156(%esp)
	pushl	$255
	call	store_8
	popl	%edx
	# (%ebx) = %fs:tmp_img+?
	movb	%al, %fs:(%ebx)
	# 8(%esp) = %ss:stack+720
	movl	8(%esp), %eax
	# 208(%esp) = %ss:stack+920
	addl	208(%esp), %eax
	# 8(%esp) = %ss:stack+720
	movl	%eax, 8(%esp)
	# 4(%eax) = %fs:decdata+?
	movl	%fs:4(%eax), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L240
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L240:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L244
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L244:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L248
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L248:
	pushl	$0
	call	store_8
	popl	%ecx
	# 156(%esp) = %ss:stack+868
	movl	156(%esp), %ecx
	# 1(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:1(%ecx)
	# 8(%esp) = %ss:stack+720
	movl	8(%esp), %ebx
	# 32(%ebx) = %fs:decdata+?
	movl	%fs:32(%ebx), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L252
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L252:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L256
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L256:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L260
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L260:
	# 188(%esp) = %ss:stack+900
	movl	188(%esp), %ebx
	# 160(%esp) = %ss:stack+872
	addl	160(%esp), %ebx
	# 152(%esp) = %ss:stack+864
	movl	%ebx, 152(%esp)
	pushl	$85
	call	store_8
	popl	%edx
	# (%ebx) = %fs:tmp_img+?
	movb	%al, %fs:(%ebx)
	# 8(%esp) = %ss:stack+720
	movl	8(%esp), %edx
	# 36(%edx) = %fs:decdata+?
	movl	%fs:36(%edx), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L264
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L264:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L268
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L268:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L272
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L272:
	pushl	$170
	call	store_8
	popl	%ecx
	# 152(%esp) = %ss:stack+864
	movl	152(%esp), %ecx
	# 1(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:1(%ecx)
	jmp	.L224
.L226:
	sall	$6, %ecx
	# 16(%esp) = %ss:stack+728
	movl	16(%esp), %esi
	# (%esi) = %fs:decdata+2624
	movl	%fs:(%esi), %edi
	# 256(%esi) = %fs:decdata+2880
	movl	%fs:256(%esi), %ebp
	imull	$50, %edi, %eax
	imull	$130, %ebp, %edx
	leal	128(%eax,%edx), %esi
	leal	(%ecx,%ebx), %eax
	sall	$2, %eax
	# 208(%esp) = %ss:stack+920
	movl	208(%esp), %edx
	sarl	$8, %esi
	# 8(%esp) = %ss:stack+720
	movl	%eax, 8(%esp)
	# (%edx,%eax) = %fs:decdata+?
	movl	%fs:(%edx,%eax), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L276
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L276:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L280
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L280:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L284
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L284:
	# 112(%esp) = %ss:stack+824
	movl	112(%esp), %ebx
	# 12(%esp) = %ss:stack+724
	addl	12(%esp), %ebx
	# 148(%esp) = %ss:stack+860
	movl	%ebx, 148(%esp)
	pushl	$255
	call	store_16
	popl	%edx
	# (%ebx) = %fs:tmp_img+?
	movw	%ax, %fs:(%ebx)
	# 8(%esp) = %ss:stack+720
	movl	8(%esp), %eax
	# 208(%esp) = %ss:stack+920
	addl	208(%esp), %eax
	# 8(%esp) = %ss:stack+720
	movl	%eax, 8(%esp)
	# 4(%eax) = %fs:decdata+?
	movl	%fs:4(%eax), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L288
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L288:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L292
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L292:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L296
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L296:
	pushl	$0
	call	store_16
	popl	%ecx
	# 148(%esp) = %ss:stack+860
	movl	148(%esp), %ecx
	# 8(%esp) = %ss:stack+720
	movl	8(%esp), %ebx
	# 2(%ecx) = %fs:tmp_img+?
	movw	%ax, %fs:2(%ecx)
	# 32(%ebx) = %fs:decdata+?
	movl	%fs:32(%ebx), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L300
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L300:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L304
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L304:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L308
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L308:
	# 188(%esp) = %ss:stack+900
	movl	188(%esp), %ebx
	# 12(%esp) = %ss:stack+724
	addl	12(%esp), %ebx
	# 144(%esp) = %ss:stack+856
	movl	%ebx, 144(%esp)
	pushl	$85
	call	store_16
	popl	%edx
	# 8(%esp) = %ss:stack+720
	movl	8(%esp), %edx
	# (%ebx) = %fs:tmp_img+?
	movw	%ax, %fs:(%ebx)
	# 36(%edx) = %fs:decdata+?
	movl	%fs:36(%edx), %eax
	leal	(%eax,%edi), %ecx
	cmpl	$255, %ecx
	jbe	.L312
	sarl	$31, %ecx
	notl	%ecx
	andl	$255, %ecx
.L312:
	movl	%eax, %edx
	subl	%esi, %edx
	cmpl	$255, %edx
	jbe	.L316
	sarl	$31, %edx
	notl	%edx
	andl	$255, %edx
.L316:
	addl	%ebp, %eax
	cmpl	$255, %eax
	jbe	.L320
	sarl	$31, %eax
	notl	%eax
	andl	$255, %eax
.L320:
	pushl	$170
	call	store_16
	popl	%edi
	# 144(%esp) = %ss:stack+856
	movl	144(%esp), %ecx
	# 2(%ecx) = %fs:tmp_img+?
	movw	%ax, %fs:2(%ecx)
	jmp	.L224
.L227:
	sall	$6, %ecx
	# 16(%esp) = %ss:stack+728
	movl	16(%esp), %esi
	# (%esi) = %fs:decdata+2624
	movl	%fs:(%esi), %ebp
	# 256(%esi) = %fs:decdata+2880
	movl	%fs:256(%esi), %edi
	imull	$130, %edi, %eax
	imull	$50, %ebp, %edx
	# 128(%esp) = %ss:stack+840
	movl	%edi, 128(%esp)
	# 112(%esp) = %ss:stack+824
	movl	112(%esp), %edi
	leal	128(%edx,%eax), %esi
	leal	(%ecx,%ebx), %eax
	sall	$2, %eax
	# 208(%esp) = %ss:stack+920
	movl	208(%esp), %edx
	movl	%ebp, %ebx
	# 4(%esp) = %ss:stack+716
	movl	%eax, 4(%esp)
	# (%edx,%eax) = %fs:decdata+?
	movl	%fs:(%edx,%eax), %ecx
	# 101(%esp) = %ss:stack+813
	movb	%bl, 101(%esp)
	movl	%ebp, %eax
	# 12(%esp) = %ss:stack+724
	movl	12(%esp), %ebx
	addl	%ecx, %eax
	# 112(%esp) = %ss:stack+824
	movl	112(%esp), %edx
	# 20(%esp) = %ss:stack+732
	addl	20(%esp), %edx
	# 8(%esp) = %ss:stack+720
	movb	%cl, 8(%esp)
	sarl	$8, %esi
	# (%edi,%ebx,2) = %fs:tmp_img+?
	movb	%al, %fs:(%edi,%ebx,2)
	leal	(%ecx,%ebp), %eax
	cmpl	$255, %eax
	jbe	.L324
	sarl	$31, %eax
	notl	%eax
	# (%edx) = %fs:tmp_img+?
	movb	%al, %fs:(%edx)
.L324:
	movl	%esi, %eax
	# 102(%esp) = %ss:stack+814
	movb	%al, 102(%esp)
	# 8(%esp) = %ss:stack+720
	movb	8(%esp), %al
	# 102(%esp) = %ss:stack+814
	subb	102(%esp), %al
	# 1(%edx) = %fs:tmp_img+?
	movb	%al, %fs:1(%edx)
	movl	%ecx, %eax
	subl	%esi, %eax
	cmpl	$255, %eax
	jbe	.L329
	sarl	$31, %eax
	notl	%eax
	# 1(%edx) = %fs:tmp_img+?
	movb	%al, %fs:1(%edx)
.L329:
	# 128(%esp) = %ss:stack+840
	movb	128(%esp), %bl
	# 103(%esp) = %ss:stack+815
	movb	%bl, 103(%esp)
	# 8(%esp) = %ss:stack+720
	movb	8(%esp), %bl
	# 103(%esp) = %ss:stack+815
	addb	103(%esp), %bl
	# 2(%edx) = %fs:tmp_img+?
	movb	%bl, %fs:2(%edx)
	# 128(%esp) = %ss:stack+840
	movl	128(%esp), %edi
	leal	(%ecx,%edi), %eax
	cmpl	$255, %eax
	jbe	.L334
	sarl	$31, %eax
	notl	%eax
	# 2(%edx) = %fs:tmp_img+?
	movb	%al, %fs:2(%edx)
.L334:
	# 4(%esp) = %ss:stack+716
	movl	4(%esp), %edi
	# 101(%esp) = %ss:stack+813
	movb	101(%esp), %al
	# 208(%esp) = %ss:stack+920
	addl	208(%esp), %edi
	# 4(%edi) = %fs:decdata+?
	movl	%fs:4(%edi), %ecx
	addl	%ecx, %eax
	movb	%cl, %bl
	# 4(%edx) = %fs:tmp_img+?
	movb	%al, %fs:4(%edx)
	leal	(%ecx,%ebp), %eax
	cmpl	$255, %eax
	jbe	.L339
	sarl	$31, %eax
	notl	%eax
	# 4(%edx) = %fs:tmp_img+?
	movb	%al, %fs:4(%edx)
.L339:
	movb	%bl, %al
	# 102(%esp) = %ss:stack+814
	subb	102(%esp), %al
	# 5(%edx) = %fs:tmp_img+?
	movb	%al, %fs:5(%edx)
	movl	%ecx, %eax
	subl	%esi, %eax
	cmpl	$255, %eax
	jbe	.L344
	sarl	$31, %eax
	notl	%eax
	# 5(%edx) = %fs:tmp_img+?
	movb	%al, %fs:5(%edx)
.L344:
	# 103(%esp) = %ss:stack+815
	addb	103(%esp), %bl
	# 6(%edx) = %fs:tmp_img+?
	movb	%bl, %fs:6(%edx)
	# 128(%esp) = %ss:stack+840
	movl	128(%esp), %ebx
	leal	(%ecx,%ebx), %eax
	cmpl	$255, %eax
	jbe	.L349
	sarl	$31, %eax
	notl	%eax
	# 6(%edx) = %fs:tmp_img+?
	movb	%al, %fs:6(%edx)
.L349:
	# 188(%esp) = %ss:stack+900
	movl	188(%esp), %ecx
	# 32(%edi) = %fs:decdata+?
	movl	%fs:32(%edi), %edx
	# 20(%esp) = %ss:stack+732
	addl	20(%esp), %ecx
	# 101(%esp) = %ss:stack+813
	movb	101(%esp), %al
	addl	%edx, %eax
	movb	%dl, %bl
	# (%ecx) = %fs:tmp_img+?
	movb	%al, %fs:(%ecx)
	leal	(%edx,%ebp), %eax
	cmpl	$255, %eax
	jbe	.L354
	sarl	$31, %eax
	notl	%eax
	# (%ecx) = %fs:tmp_img+?
	movb	%al, %fs:(%ecx)
.L354:
	movb	%bl, %al
	# 102(%esp) = %ss:stack+814
	subb	102(%esp), %al
	# 1(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:1(%ecx)
	movl	%edx, %eax
	subl	%esi, %eax
	cmpl	$255, %eax
	jbe	.L359
	sarl	$31, %eax
	notl	%eax
	# 1(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:1(%ecx)
.L359:
	# 103(%esp) = %ss:stack+815
	addb	103(%esp), %bl
	# 2(%ecx) = %fs:tmp_img+?
	movb	%bl, %fs:2(%ecx)
	# 128(%esp) = %ss:stack+840
	movl	128(%esp), %ebx
	leal	(%edx,%ebx), %eax
	cmpl	$255, %eax
	jbe	.L364
	sarl	$31, %eax
	notl	%eax
	# 2(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:2(%ecx)
.L364:
	# 36(%edi) = %fs:decdata+?
	movl	%fs:36(%edi), %edx
	# 101(%esp) = %ss:stack+813
	movb	101(%esp), %al
	movb	%dl, %bl
	leal	(%edx,%eax), %edi
	movl	%edi, %eax
	# 4(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:4(%ecx)
	leal	(%edx,%ebp), %eax
	cmpl	$255, %eax
	jbe	.L369
	sarl	$31, %eax
	notl	%eax
	# 4(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:4(%ecx)
.L369:
	movb	%bl, %al
	# 102(%esp) = %ss:stack+814
	subb	102(%esp), %al
	# 5(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:5(%ecx)
	movl	%edx, %eax
	subl	%esi, %eax
	cmpl	$255, %eax
	jbe	.L374
	sarl	$31, %eax
	notl	%eax
	# 5(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:5(%ecx)
.L374:
	# 103(%esp) = %ss:stack+815
	addb	103(%esp), %bl
	# 6(%ecx) = %fs:tmp_img+?
	movb	%bl, %fs:6(%ecx)
	# 128(%esp) = %ss:stack+840
	movl	128(%esp), %ebx
	leal	(%edx,%ebx), %eax
	cmpl	$255, %eax
	jbe	.L224
	sarl	$31, %eax
	notl	%eax
	# 6(%ecx) = %fs:tmp_img+?
	movb	%al, %fs:6(%ecx)
.L224:
	# 108(%esp) = %ss:stack+820
	incl	108(%esp)
	# 12(%esp) = %ss:stack+724
	addl	$4, 12(%esp)
	# 16(%esp) = %ss:stack+728
	addl	$4, 16(%esp)
	# 20(%esp) = %ss:stack+732
	addl	$8, 20(%esp)
	# 108(%esp) = %ss:stack+820
	cmpl	$8, 108(%esp)
	jne	.L223
	# 104(%esp) = %ss:stack+816
	movl	104(%esp), %esi
	# 124(%esp) = %ss:stack+836
	addl	$32, 124(%esp)
	# 208(%esp) = %ss:stack+920
	addl	$64, 208(%esp)
	# 112(%esp) = %ss:stack+824
	addl	%esi, 112(%esp)
	# 188(%esp) = %ss:stack+900
	addl	%esi, 188(%esp)
	# 132(%esp) = %ss:stack+844
	decl	132(%esp)
	jne	.L222
	# 120(%esp) = %ss:stack+832
	addl	$512, 120(%esp)
	# 164(%esp) = %ss:stack+876
	subl	$-128, 164(%esp)
	# 120(%esp) = %ss:stack+832
	cmpl	$decdata+2624, 120(%esp)
	jne	.L221
	# 72(%esp) = %ss:stack+784
	movl	72(%esp), %edi
	# 192(%esp) = %ss:stack+904
	movl	192(%esp), %edx
	# 52(%esp) = %ss:stack+764
	cmpl	%edi, 52(%esp)
	je	.L388
	xorl	%edx, %edx
.L388:
	# 196(%esp) = %ss:stack+908
	movl	196(%esp), %eax
	# 76(%esp) = %ss:stack+788
	movl	76(%esp), %ecx
	# 96(%esp) = %ss:stack+808
	movl	%eax, 96(%esp)
	# 52(%esp) = %ss:stack+764
	cmpl	%ecx, 52(%esp)
	je	.L391
	# 96(%esp) = %ss:stack+808
	movl	$16, 96(%esp)
.L391:
	# 264(%esp) = %ss:stack+976
	movl	264(%esp), %eax
	movl	%edx, %edi
	# 268(%esp) = %ss:stack+980
	subl	268(%esp), %eax
	# 176(%esp) = %ss:stack+888
	movl	176(%esp), %ebx
	# 172(%esp) = %ss:stack+884
	addl	172(%esp), %eax
	addl	%edx, %ebx
	sall	$4, %edi
	movl	%edx, %ebp
	# 28(%esp) = %ss:stack+740
	movl	%eax, 28(%esp)
	# 136(%esp) = %ss:stack+848
	movl	%ebx, 136(%esp)
	# 140(%esp) = %ss:stack+852
	movl	%edi, 140(%esp)
	jmp	.L392
.L393:
	# 272(%esp) = %ss:stack+984
	movl	272(%esp), %eax
	# 136(%esp) = %ss:stack+848
	movl	136(%esp), %ecx
	# 268(%esp) = %ss:stack+980
	subl	268(%esp), %eax
	# 64(%esp) = %ss:stack+776
	movl	64(%esp), %esi
	imull	%eax, %ecx
	# 200(%esp) = %ss:stack+912
	movl	200(%esp), %edx
	# 48(%esp) = %ss:stack+760
	cmpl	%esi, 48(%esp)
	je	.L396
	xorl	%edx, %edx
.L396:
	# 68(%esp) = %ss:stack+780
	movl	68(%esp), %eax
	# 204(%esp) = %ss:stack+916
	movl	204(%esp), %esi
	# 48(%esp) = %ss:stack+760
	cmpl	%eax, 48(%esp)
	je	.L399
	movl	$16, %esi
.L399:
	# 284(%esp) = %ss:stack+996
	cmpl	$16, 284(%esp)
	je	.L402
	# 284(%esp) = %ss:stack+996
	cmpl	$32, 284(%esp)
	je	.L403
	# 284(%esp) = %ss:stack+996
	cmpl	$8, 284(%esp)
	jne	.L400
	jmp	.L401
.L403:
	leal	(%edi,%edx), %eax
	leal	tmp_img(,%eax,4), %ebx
	movl	%edx, %eax
	# 268(%esp) = %ss:stack+980
	subl	268(%esp), %eax
	# 172(%esp) = %ss:stack+884
	addl	172(%esp), %eax
	addl	%eax, %ecx
	# 264(%esp) = %ss:stack+976
	movl	264(%esp), %eax
	leal	(%eax,%ecx,4), %ecx
	jmp	.L404
.L402:
	leal	(%edi,%edx), %eax
	leal	tmp_img(%eax,%eax), %ebx
	movl	%edx, %eax
	# 268(%esp) = %ss:stack+980
	subl	268(%esp), %eax
	# 172(%esp) = %ss:stack+884
	addl	172(%esp), %eax
	addl	%eax, %ecx
	# 264(%esp) = %ss:stack+976
	movl	264(%esp), %eax
	leal	(%eax,%ecx,2), %ecx
	jmp	.L405
.L401:
	# 140(%esp) = %ss:stack+852
	movl	140(%esp), %eax
	leal	tmp_img(%eax,%edx), %ebx
	# 28(%esp) = %ss:stack+740
	movl	28(%esp), %eax
	addl	%edx, %eax
	leal	(%eax,%ecx), %ecx
	jmp	.L406
.L407:
	# -1(%ebx) = %fs:tmp_img+?
	movb	%fs:-1(%ebx), %al
	incl	%edx
	# -1(%ecx) = %es:pic+?
	movb	%al, %es:-1(%ecx)
.L406:
	incl	%ebx
	incl	%ecx
	cmpl	%esi, %edx
	jl	.L407
	jmp	.L400
.L408:
	# -2(%ebx) = %fs:tmp_img
	movw	%fs:-2(%ebx), %ax
	incl	%edx
	# -2(%ecx) = %es:pic+?
	movw	%ax, %es:-2(%ecx)
.L405:
	addl	$2, %ebx
	addl	$2, %ecx
	cmpl	%esi, %edx
	jl	.L408
	jmp	.L400
.L409:
	# -4(%ebx) = %fs:tmp_img
	movl	%fs:-4(%ebx), %eax
	incl	%edx
	# -4(%ecx) = %es:pic+?
	movl	%eax, %es:-4(%ecx)
.L404:
	addl	$4, %ebx
	addl	$4, %ecx
	cmpl	%esi, %edx
	jl	.L409
.L400:
	# 136(%esp) = %ss:stack+848
	incl	136(%esp)
	incl	%ebp
	# 140(%esp) = %ss:stack+852
	addl	$16, 140(%esp)
	addl	$16, %edi
.L392:
	# 96(%esp) = %ss:stack+808
	cmpl	96(%esp), %ebp
	jl	.L393
.L218:
	# 48(%esp) = %ss:stack+760
	incl	48(%esp)
	# 172(%esp) = %ss:stack+884
	addl	$16, 172(%esp)
.L410:
	# 40(%esp) = %ss:stack+752
	movl	40(%esp), %edx
	# 48(%esp) = %ss:stack+760
	cmpl	%edx, 48(%esp)
	jl	.L194
	# 52(%esp) = %ss:stack+764
	incl	52(%esp)
	# 176(%esp) = %ss:stack+888
	addl	$16, 176(%esp)
.L193:
	# 44(%esp) = %ss:stack+756
	movl	44(%esp), %ecx
	# 52(%esp) = %ss:stack+764
	cmpl	%ecx, 52(%esp)
	jl	.L412
	xorl	%eax, %eax
	jmp	.L154
.L412:
	# 48(%esp) = %ss:stack+760
	movl	$0, 48(%esp)
	# 172(%esp) = %ss:stack+884
	movl	$0, 172(%esp)
	jmp	.L410
.L147:
	movl	$1, %eax
	jmp	.L154
.L150:
	movl	$14, %eax
	jmp	.L154
.L167:
	movl	$9, %eax
	jmp	.L154
.L415:
	movl	$7, %eax
	# datap = %fs:datap
	movl	%ebx, %fs:datap
	jmp	.L154
.L416:
	# datap = %fs:datap
	movl	%ebx, %fs:datap
.L428:
	movl	$8, %eax
	jmp	.L154
.L417:
	movl	$10, %eax
	# datap = %fs:datap
	movl	%ecx, %fs:datap
	jmp	.L154
.L179:
	movl	$11, %eax
.L154:
	addl	$240, %esp
	popl	%ebx
	popl	%esi
	popl	%edi
	popl	%ebp
	ret

jpeg_get_size:
	pushl	%ebx
	# 8(%esp) = %ss:stack+996
	movl	8(%esp), %eax
	addl	$2, %eax
	# datap = %fs:datap
	movl	%eax, %fs:datap
	movl	$192, %eax
	call	readtables
	xorl	%edx, %edx
	testl	%eax, %eax
	jne	.L432
	call	getword
	# datap = %fs:datap
	incl	%fs:datap
	call	getword
	movl	%eax, %ebx
	call	getword
	sall	$16, %ebx
	leal	(%ebx,%eax), %edx
.L432:
	movl	%edx, %eax
	popl	%ebx
	ret
