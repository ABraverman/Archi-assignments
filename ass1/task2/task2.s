section	.rodata			; we define (global) read-only variables in .rodata section
	format_string: db "%s", 10, 0	; format string

section .bss			; we define (global) uninitialized variables in .bss section
	an: resb 12			; enough to store integer in [-2,147,483,648 (-2^31) : 2,147,483,647 (2^31-1)]
	strStart: resb 4	; save the start of the string

section .data
	isZero: db 0
	acc: dd 0
	digitCounter: dd 0

section .text
	global convertor
	extern printf

convertor:
	push ebp
	mov ebp, esp	
	pushad			

	; mov dword [an], 0
	mov ecx, dword [ebp+8]	; get function argument (pointer to string)
	mov dword [strStart], ecx
	cmp byte [ecx], 10
	jz EOS
	mov eax, 0
	mov al, byte [ecx]
	sub eax, '0'
	mov byte [isZero], 0
	mov dword [digitCounter], 0
	reachLSB:
		inc byte [isZero]
		inc ecx
		cmp byte [ecx], 10
		jnz reachLSB
	
	mul byte [isZero]
	mov ebx, 1
	mov dword [acc], 0
	cmp eax, 32
	jz negInit

	posInit:
		mov byte [isZero], 0
		jmp accLoop

	negInit:
		mov byte [isZero], 1

	accLoop:
		dec ecx
		sub byte [ecx], '0'
		mov eax, 0
		mov al, [ecx]
		mul ebx
		add dword [acc], eax
		shl ebx, 1
		cmp ecx, dword [strStart]
		jnz accLoop
	
	cmp byte [isZero], 1
	jnz posFinal
	neg dword [acc]
	posFinal:
	
	mov eax, dword [acc]
	mov ebx, 10
	digCount:
		inc dword [digitCounter]
		mov edx, 0
		idiv ebx
		cmp eax, 0
		jnz digCount

	mov eax, dword [acc]	
	mov ecx, an
	cmp byte [isZero], 1
	jnz posString
	mov byte [ecx], '-'
	inc ecx
	posString:
	add ecx, dword [digitCounter]
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
	
	add ecx, dword [digitCounter]
	; inc ecx
	; mov byte [ecx], 0

	EOS:

	

	push an			; call printf with 2 arguments -  
	push format_string	; pointer to str and pointer to format string
	call printf
	add esp, 8		; clean up stack after call

	popad			
	mov esp, ebp	
	pop ebp
	ret
