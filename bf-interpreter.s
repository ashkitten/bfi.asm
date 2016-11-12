section .data
	msg1 db "Enter text: "		; first prompt
	msg1_size equ $-msg1		; first prompt length

section .bss
	buffer resb 256
	buffer_size equ $-buffer	; buffer size
	count resb 1

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
		mov	edx, buffer_size
		mov	ecx, buffer
		mov	ebx, 0			; stdin
		mov	eax, 3			; sys_read
		int	80h			; syscall

		mov	[count], eax		; save count for later

		; print what we got from sys_read
		; sys_write
		mov	edx, [count]
		mov	ecx, buffer
		mov	ebx, 1			; stdout
		mov	eax, 4			; sys_write
		int	80h			; syscall

		; if the last byte we printed is a linefeed, we're done
		; if not, there must be more to read
		cmp	byte [ecx + edx - 1], 10
		jne	.1

		ret

exit:
	; syscall exit(0)
	mov	eax, 1			; syscall_exit
	mov	ebx, 0 			; status 0
	int	80h			; call
