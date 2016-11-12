section .data
	msg1 db "Enter text: "		; first prompt
	msg1_size equ $-msg1		; first prompt length

section .bss
	buffer resb 1

section .text
	global _start

_start:

	; sys_write
	mov	edx, msg1_size
	mov	ecx, msg1
	mov	ebx, 1			; stdout
	mov	eax, 4			; sys_write
	int	80h			; syscall

	call	readwrite
	jmp	exit

readwrite:
	.1:
		; sys_read
		mov	edx, 1
		mov	ecx, buffer
		mov	ebx, 0			; stdin
		mov	eax, 3			; sys_read
		int	80h			; syscall

		; print what we got from sys_read
		; sys_write
		mov	edx, 1
		mov	ecx, buffer
		mov	ebx, 1			; stdout
		mov	eax, 4			; sys_write
		int	80h			; syscall

		cmp	byte[ecx], 33		; if buffer character is a "!"
		je	exit

		; this is so if we overflow the buffer then it'll read more
		; if the last byte we printed is a linefeed, we're done
		; if not, there must be more to read
		cmp	byte[ecx], 10
		jne	.1

		ret

exit:
	; syscall exit(0)
	mov	eax, 1			; syscall_exit
	mov	ebx, 0 			; status 0
	int	80h			; call
