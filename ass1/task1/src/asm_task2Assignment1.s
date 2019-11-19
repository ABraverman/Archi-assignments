section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	
	
	

section .data 
	an: db 'illegal input', 0

section .text
	global assFunc
	extern printf
	extern c_checkValidity

assFunc:
	push ebp
	mov ebp, esp	
	pushad			

	mov ebx, dword [ebp+8]	; get function argument (pointer to string)
	mov ecx, dword [ebp+12]	; get function argument (pointer to string)
	sub esp, 4

	push ecx
	push ebx
	call c_checkValidity
	add esp, 8				; clean up stack after call

	cmp eax, 0
	jz illegal	
	
	add ebx, ecx
	mov dword [ebp - 4], ebx
	sub esp, 4



	mov eax, dword [ebp - 4]
	mov ebx, 10
	mov ecx, 0
	digCount:
		inc ecx
		mov edx, 0
		idiv ebx
		cmp eax, 0
	jnz digCount

	mov [ebp - 8], ecx
	mov eax, dword [ebp - 4]	
	mov ecx, an
	add ecx, dword [ebp - 8]
	mov byte [ecx], 0
	dec ecx
	
	stringExt:
		mov edx, 0
		idiv ebx
		add edx, '0'
		mov byte [ecx], dl
		dec ecx
		cmp eax, 0
		jnz stringExt	
	
	illegal:
	

	print:
	push an					; call printf with 2 arguments -  
	push format_string		; pointer to str and pointer to format string
	call printf
	add esp, 16				; clean up stack after call

	

	popad			
	mov esp, ebp	
	pop ebp
	ret
