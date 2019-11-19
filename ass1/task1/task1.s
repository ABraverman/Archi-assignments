section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12		; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]

section .data
	isZero: db 0

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp	
	pushad			

	mov ecx, dword [ebp+8]	; get function argument (pointer to string)
	cmp byte [ecx], 10
	jz EOS
	mov eax, byte [ecx]
	sub eax, '0'
	reachLSB:
		inc byte [isZero]
		inc ecx
		cmp byte [ecx], 10
		jnz reachLSB
	
	mul byte [isZero]
	cmp eax, 32
	jz negInit

	posInit:
		mov ebx, 1
		mov edx, 0
		mov byte [isZero], 0
		jmp acc

	negInit:
		mov ebx, 1
		mov edx, 0
		mov byte [isZero], 1

	acc:
		dec ecx
		sub byte [ecx], '0'
		cmp byte [isZero], 1
		jnz pos
		not byte [ecx] ;; might need to move to al
	posAcc:
		mov eax, [ecx]
		mul ebx
		add edx, eax
		shl ebx, 1
		cmp ecx, ebp+8
		jnz acc
	
	cmp byte [isZero], 1
	jnz posFinal
	inc edx
	posFinal:
	
	mov eax, edx
	mov ecx, an
	cmp byte [isZero], 1
	jnz stringExt
	mov byte [ecx], '-'
	inc ecx
	stringExt:
		mov edx, 0
		div 10
		add edx, '0'
		mov byte [ecx], edx
		inc ecx
		cmp eax, 0
		jnz stringExt

	EOS:

	

	push an			; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
