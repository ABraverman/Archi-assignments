section .data
    format_counter: db '%X',10, 0
    format_hex_padded: db '%02X', 0
    format_hex: db '%X', 0
    newLine: db 10, 0
    dBug_flag: db 0

    stack_pointer: dd 0
    op_counter: dd 0

section .rodata
    calcMsg: db 'calc: ',0                                                                ; calc msg         
    calcMsg_len: equ $ - calcMsg                                                        ; size of calc msg

    err_msg_illegal_argument: db 'wrong Y value',10, 0                                     ; illegal argument error msg 
    errMsg_illegal_argument: equ $ - err_msg_illegal_argument                                 ;size of illegal argument errmsg

    err_msg_stack_overflow: db 'Error: Operand Stack Overflow',10, 0                        ; overflow msg
    errMsg_overflow_len: equ $ - err_msg_stack_overflow                                 ;size of overflow errmsg

    err_msg_insufficientArgs: db 'Error: Insufficient Number of Arguments on Stack',10, 0 
    errMsg_insufficientArgs_len: equ $ - err_msg_insufficientArgs                       ;size of insf errmsg

    



section .bss
    stack_size: equ 5                    ; size of stack - 5
    operand_stack: resd stack_size       ; define operand_stack with size of 5
    buffer_size: equ 82
    buffer: resb buffer_size            ;define the buffer for userInput with fixed size 82
    link_size: equ 5


section .text                           ; following - c code
    align 16                            
    global main                         
    extern fprintf
    extern printf 
    extern fflush
    extern malloc 
    extern calloc 
    extern free 
    extern fgets
    extern getchar
    extern stdin
    extern stderr


;%macro err_check
    

;%endmacro 



main:
push ebp
mov ebp, esp

mov ecx, [ebp+8]                ; argc
mov ebx, [ebp+12]               ; argv

cmp ecx, 2
jb .no_args
.args_check_loop:
    mov eax, [ebx]
    cmp word [eax], '-d'
    je .has_args
    add ebx, 4
loop .args_check_loop
jmp .no_args
.has_args:
mov byte [dBug_flag], 1

.no_args:
call myCalc                     ; call myCalc function
push eax                        ; insert value of eax to stack
push format_counter             ; push the format string
call printf                     ; call printf and print the return value of myCalc
add esp, 8

mov esp, ebp
pop ebp
mov eax, 1                      ; exit system call
mov ebx, 0
int 0x80

myCalc:                                   
    push ebp
    mov ebp, esp    
    pushad      

    calcLoop:

    push calcMsg                
    call printf
    add esp, 4

    push dword [stdin]
    push buffer_size
    push buffer
    call fgets
    add esp, 12

    cmp byte [buffer], 10
    je calcLoop

    cmp byte [buffer], 'q'
    je end_myCalc

    cmp byte [buffer], 'p'
    je pop_func_call

    cmp byte [buffer], '+'
    je add_func_call

    cmp byte [buffer], 'n'
    je count_bits_func_call

    cmp byte [buffer], 'd'
    je duplicate_func_call

    cmp byte [buffer], '^'
    je power_func_call

    cmp byte [buffer], 'v'
    je div_func_call


    jmp pushNumber_call


    ;mov eax,1 ;system call number (sys_exit)
    ;mov ebx, 0 ;exit status
    ;int 0x80

end_myCalc:
    .clean_stack_loop:
        sub dword [stack_pointer], 4
        mov eax, [stack_pointer]
        cmp eax, 0
        jl .end_clean_stack_loop
        push dword [operand_stack+eax]
        call free_list
        add esp, 4
    jmp .clean_stack_loop
    .end_clean_stack_loop:
    popad  
    mov eax, [op_counter]
    mov esp, ebp    
    pop ebp
    ret

pushNumber_call:
    call pushNumber
    cmp byte [dBug_flag], 1
    jne calcLoop 
    push dword [stderr]
    call print_list
    add esp, 4
    jmp calcLoop

pop_func_call:
    call pop_func
    jmp calcLoop

add_func_call:
    call add_func
    cmp byte [dBug_flag], 1
    jne calcLoop 
    push dword [stderr]
    call print_list
    add esp, 4
    jmp calcLoop

count_bits_func_call:
    call count_bits_func
    cmp byte [dBug_flag], 1
    jne calcLoop  
    push dword [stderr]
    call print_list
    add esp, 4
    jmp calcLoop

duplicate_func_call:
    call duplicate_func
    cmp byte [dBug_flag], 1
    jne calcLoop  
    push dword [stderr]
    call print_list
    add esp, 4
    jmp calcLoop

power_func_call:
    call power_func
    cmp byte [dBug_flag], 1
    jne calcLoop  
    push dword [stderr]
    call print_list
    add esp, 4
    jmp calcLoop

div_func_call:
    call div_func
    cmp byte [dBug_flag], 1
    jne calcLoop  
    push dword [stderr]
    call print_list
    add esp, 4
    jmp calcLoop


pushNumber:

    push ebp
    mov ebp, esp
    sub esp, 4   
    pushad

    
    cmp dword [stack_pointer], stack_size*4
    jae IllegalNum

    mov ebx, [stack_pointer]
    mov dword [operand_stack+ebx], 0
    ;mov dword [eax], 0    ; clear the current stack cell
    mov ecx, buffer                 ; save the head of the buffer to the ecx
    mov ebx, 0

    cmp byte [ecx], '0'
    jne .no_leading_zeroes
    .leading_zeros_loop:
        cmp byte [ecx+1], 10
        je .no_leading_zeroes
        inc ecx
        cmp byte [ecx], '0' 
    je .leading_zeros_loop
    .no_leading_zeroes:
    mov dword [ebp-4], ecx

    inputCountLoop:
        inc ebx
        inc ecx
        cmp byte [ecx], 10
        jnz inputCountLoop

    and ebx, 1
    mov ecx, [ebp-4]                 ; save the head of the buffer to the ecx
    cmp ebx, 0
    je insertionLoop

    ; case: odd input length
    pushad
    push link_size
    call malloc
    add esp, 4
    mov ebx, [stack_pointer]
    mov ebx, [operand_stack+ebx]
    mov dword [eax+1], ebx    ; enters the prev head of list as next of new head
    mov ebx, [stack_pointer]
    mov [operand_stack+ebx], eax              ; enters new head to stack
    popad
    cmp byte [ecx], '9'
    jbe digitodd

    ;case: letter                                             
    sub byte [ecx], 'A'                         ; substract the value of 'A' from ascii value
    add byte [ecx], 10                          ; add the value of the hexadecimal value of:  A - 10 B -20 etc.
    mov bl, byte [ecx]
    mov edx, [stack_pointer]
    mov edx, [operand_stack+edx]
    mov byte [edx], bl                ; move the value pointed by ecx to the link position
    inc ecx
    cmp byte [ecx], 10
    je end_pushNumer
    jmp insertionLoop                           

    ;case: digit  
    digitodd:
    sub byte [ecx], '0'                         ; substract the value of '0' from ascii value
    mov bl, byte [ecx]
    mov edx, [stack_pointer]
    mov edx, [operand_stack+edx]
    mov byte [edx], bl                ; move the value pointed by ecx to the link position
    inc ecx
    cmp byte [ecx], 10
    je end_pushNumer

    insertionLoop:

        pushad
        push link_size
        call malloc
        add esp, 4
        mov ebx, [stack_pointer]
        mov ebx, [operand_stack+ebx]
        mov dword [eax+1], ebx    ; enters the prev head of list as next of new head
        mov ebx, [stack_pointer]
        mov [operand_stack+ebx], eax              ; enters new head to stack
        popad
        cmp byte [ecx], '9'
        jbe digit_first

        ;case: letter                                               
        sub byte [ecx], 'A'                         ; substract the value of 'A' from ascii value
        add byte [ecx], 10                          ; add the value of the hexadecimal value of:  A - 10 B -20 etc.
        mov bl, byte [ecx]
        mov edx, [stack_pointer]
        mov edx, [operand_stack+edx]
        mov byte [edx], bl                ; move the value pointed by ecx to the link position
        jmp secondChar                           

        ;case: digit  ficient Number of Arguments on Stack: ',10, 0                      
        digit_first:
        sub byte [ecx], '0'                         ; substract the value of '0' from ascii value
        mov bl, byte [ecx]
        mov edx, [stack_pointer]
        mov edx, [operand_stack+edx]
        mov byte [edx], bl                ; move the value pointed by ecx to the link position
                

        secondChar:
        mov edx, [stack_pointer]
        mov edx, [operand_stack+edx]
        shl byte [edx], 4                           ; multiplies the first digit by 16
        inc ecx                                     ; moves the ecx pointer to the next char in the buffer
        cmp byte [ecx], '9'                         ; a test to see if the char is a number or a letter
        jbe digit_second

        ;case: letter                                             
        sub byte [ecx], 'A'                         ; substract the value of 'A' from ascii value
        add byte [ecx], 10                          ; add the value of the hexadecimal value of:  A - 10 B -20 etc.
        mov bl, byte [ecx]
        mov edx, [stack_pointer]
        mov edx, [operand_stack+edx]
        add byte [edx], bl                ; move the value pointed by ecx to the link position
        inc ecx                  
        cmp byte [ecx], 10
    jnz insertionLoop                           
    jmp end_pushNumer

        ;case: digit  
        digit_second:
        sub byte [ecx], '0'                         ; substract the value of '0' from ascii value
        mov bl, byte [ecx]
        mov edx, [stack_pointer]
        mov edx, [operand_stack+edx]
        add byte [edx], bl                ; move the value pointed by ecx to the link position
        inc ecx
        cmp byte [ecx], 10
    jnz insertionLoop   
    jmp end_pushNumer  
                
        IllegalNum:
        push err_msg_stack_overflow
        call printf
        add esp, 4
        sub dword [stack_pointer], 4

    end_pushNumer:
    add dword [stack_pointer], 4
    popad           
    mov esp, ebp    
    pop ebp
    ret

pop_func:
    push ebp
    mov ebp, esp    
    sub esp, 4
    pushad

    
    cmp dword [stack_pointer], 0
    je pop_insufficient_args

    
    mov dword [ebp-4], 0
    sub dword [stack_pointer], 4
    
    mov eax , dword [stack_pointer]
    mov eax, dword [operand_stack+eax]
    
    link_iterator:
        mov ebx, 0
        mov bl, byte [eax]
        push ebx
        inc dword [ebp-4]
        mov eax, [eax+1]
        cmp eax, 0
    jne link_iterator

    mov eax, 1
    print_loop:
        cmp eax, 1
        jne .not_first
        push format_hex
        call printf
        jmp .first
        .not_first:
        push format_hex_padded
        call printf
        .first:
        add esp, 8
        dec dword [ebp-4]
        cmp dword [ebp-4], 0
        mov eax, 0
    jne print_loop

    push newLine
    call printf

    add esp, 4
    mov edx, [stack_pointer]
    mov edx, [operand_stack+edx]
    push edx
    call free_list
    add esp, 4
    jmp pop_end

    ; not enough arguments for pop
    pop_insufficient_args:
        push err_msg_insufficientArgs
        call printf
        add esp, 4

    pop_end:
    inc dword [op_counter] ; check if needs to count in error as well move to pop_end
    popad           
    mov esp, ebp    
    pop ebp
    ret





add_func:
    push ebp
    mov ebp, esp    
    sub esp, 12                                     ; make room for 3 local variables: first list, second list, and counter
    pushad 

    cmp dword [stack_pointer], 8
    jl add_insufficient_args

    
    mov ebx, [stack_pointer]
    add ebx, operand_stack-8
    mov ebx, [ebx]
    mov dword [ebp-12], ebx        ; first loacl variable holds the value of the entry to first list [ebp-12]
    mov ebx, [stack_pointer]
    add ebx, operand_stack-4
    mov ebx, [ebx]
    mov dword [ebp-8], ebx          ; second local variable holds the value of the entry to second list [ebp-8]
    mov dword [ebp-4], 0                            ; counter - [ebp-4]

      
    
    clc
    pushfd
    
    add_loop:
        
        mov edx, dword [ebp-12]
        mov ecx, 0
        mov cl, byte [edx]
        mov edx, dword [ebp-8]
        popfd
        adc cl, byte [edx]
        push ecx

        mov eax, [ebp-12]
        mov eax, [eax+1]
        mov dword [ebp-12], eax

        mov eax, [ebp-8]
        mov eax, [eax+1]
        mov dword [ebp-8], eax

        inc dword [ebp-4]

        pushfd
        mov eax, [ebp-12]
        and eax, [ebp-8]
        cmp eax, 0

    jnz add_loop

    mov eax, [ebp-12]
    or eax, [ebp-8]
    cmp eax, 0
    je got_sum

    cmp dword [ebp-8], 0
    mov esi, 12
    je pre_rest_loop

    cmp dword [ebp-12], 0
    mov esi, 8
    
    pre_rest_loop:
    mov eax, ebp
    sub eax, esi
    mov eax, [eax]
    popfd
    pushfd
    rest_loop:                         
        popfd
        mov ebx, 0
        mov bl, byte [eax]                 ; get the value in the link
        adc bl, 0                           ; adc with 0 (keeps same values)
        push ebx
        inc dword [ebp-4]
        mov eax, [eax+1]                    ; get next link

        pushfd
        cmp eax, 0
    jnz rest_loop
    
    
    got_sum:
    popfd
    jnc sum
    push 1
    inc dword [ebp-4]
    sum:
    

    mov ebx, [stack_pointer]
    add ebx, operand_stack-8
    mov ebx, [ebx]
    ; mov ebx, operand_stack+8
    ; mov ebx, [stack_pointer+ebx]
    mov dword [ebp-12], ebx        ; first loacl variable holds the value of the entry to first list [ebp-12]
    mov ebx, [stack_pointer]
    add ebx, operand_stack-4
    mov ebx, [ebx]
    ; mov ebx, operand_stack+8
    ; mov ebx, [stack_pointer+ebx]
    mov dword [ebp-8], ebx          ; second local variable holds the value of the entry to second list [ebp-8]
    
    sub dword [stack_pointer], 8
    
    push dword [ebp-12]
    call free_list
    add esp, 4
    push dword [ebp-8]
    call free_list
    add esp, 4

    mov ebx, 0         ; first loacl variable holds the value of the entry to first list [ebp-12]
    
    list_create_loop:
        call make_link
        add esp, 4
        mov dword [eax+1], ebx
        mov ebx, eax
        dec dword [ebp-4]

        cmp dword [ebp-4], 0
    jne list_create_loop
    mov ecx, [stack_pointer]
    mov dword [operand_stack+ecx], ebx
    add dword [stack_pointer], 4

    
    jmp add_end

    add_insufficient_args:
    push err_msg_insufficientArgs
    call printf
    add esp, 4

    add_end:
    inc dword [op_counter] ; check if needs to count in error as well move to pop_end
    mov esp, ebp    
    pop ebp
    ret

count_bits_func:
    push ebp
    mov ebp, esp
    sub esp, 4
    pushad

    cmp dword [stack_pointer], 0
    je .insufficient_args

    sub dword [stack_pointer], 4
    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax]

    mov dword [ebp-4], 0
    .outer_loop:
        mov ebx, 0
        mov bl, [eax]
        mov ecx, 8
        .inner_loop:
            shl bl, 1
            adc dword [ebp-4], 0
        loop .inner_loop
        mov eax, [eax+1]
        cmp eax, 0
    jne .outer_loop

    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax]
    push eax
    call free_list
    add esp, 4
    
    mov edx, [ebp-4]
    mov esi, 0

    .number_push_loop:
        inc esi

        push edx
        shr edx, 8

        cmp edx, 0
    jne .number_push_loop

    mov ebx, 0
    mov ecx, esi
    .list_create_loop:
        call make_link
        add esp, 4

        mov dword [eax+1], ebx
        mov ebx, eax
    loop .list_create_loop

    mov eax, [stack_pointer]
    mov [operand_stack+eax], ebx
    add dword [stack_pointer], 4

    jmp .end


    ; not enough arguments for pop
    .insufficient_args:
        push err_msg_insufficientArgs
        call printf
        add esp, 4

    .end:
    inc dword [op_counter] ; check if needs to count in error as well move to pop_end
    popad           
    mov esp, ebp    
    pop ebp
    ret

duplicate_func:
    push ebp
    mov ebp, esp
    pushad

    cmp dword [stack_pointer], 0
    jle .insufficient_args
    cmp dword [stack_pointer], 20
    jge .stack_overflow

    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax-4]
    
    mov ecx, 0

    .num_extract_loop:
        inc ecx
        mov ebx, 0
        mov bl, [eax]
        push ebx
        mov eax, [eax+1]
        cmp eax, 0
    jne .num_extract_loop

    mov ebx, 0
    .list_create_loop:
        call make_link
        add esp, 4
        
        mov dword [eax+1], ebx
        mov ebx, eax

        cmp edx, 0
    loop .list_create_loop

    mov eax, [stack_pointer]
    mov [operand_stack+eax], ebx
    add dword [stack_pointer], 4

    jmp .end

    ; not enough arguments for pop
    .insufficient_args:
        push err_msg_insufficientArgs
        call printf
        add esp, 4
        jmp .end
    
    .stack_overflow:
        push err_msg_stack_overflow
        call printf
        add esp, 4

    .end:
    inc dword [op_counter] ; check if needs to count in error as well move to pop_end
    popad           
    mov esp, ebp    
    pop ebp
    ret

power_func:
    push ebp
    mov ebp, esp    
    pushad 

    cmp dword [stack_pointer], 8
    jl .insufficient_args

    sub dword [stack_pointer], 8

    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax]

    cmp dword [eax+1], 0
    jne .illegal_argument
    cmp byte [eax], 200
    ja .illegal_argument

    
        
    mov ecx, 0
    mov cl, [eax]
    cmp ecx, 0
    je .skip_loop 
    

    .outer_loop:
        mov eax, [stack_pointer]
        mov eax, [operand_stack+eax+4]
        clc
        pushfd
        .inner_loop:
            popfd
            mov edx, 0
            adc edx, 0
            shl byte [eax], 1
            pushfd
            add byte [eax], dl
            popfd
            mov ebx, eax
            mov eax, [eax+1]
            pushfd
            cmp eax, 0
        jne .inner_loop
        popfd

        jnc .outer_loop_end
        push 1
        call make_link
        add esp, 4
        mov [ebx+1], eax


    .outer_loop_end:
    loop .outer_loop
    .skip_loop:

    mov eax, [stack_pointer]
    push dword [operand_stack+eax]
    call free_list
    add esp, 4

    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax+4]

    mov ebx, [stack_pointer]
    mov [operand_stack+ebx], eax

    add dword [stack_pointer], 4

    jmp .end

    .illegal_argument:
        add dword [stack_pointer], 8
        push err_msg_illegal_argument
        call printf
        add esp, 4
        jmp .end

    .insufficient_args:
        push err_msg_insufficientArgs
        call printf
        add esp, 4

    .end:
    inc dword [op_counter] ; check if needs to count in error as well move to pop_ends
    popad
    mov esp, ebp    
    pop ebp
    ret         

div_func:
    push ebp
    mov ebp, esp    
    pushad 

    cmp dword [stack_pointer], 8
    jl .insufficient_args

    sub dword [stack_pointer], 8

    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax]

    cmp dword [eax+1], 0
    jne .illegal_argument
    cmp byte [eax], 200
    ja .illegal_argument

    mov ecx, 0
    mov cl, [eax]
    cmp ecx, 0
    je .skip_loop
    
    .outer_loop:
        mov eax, [stack_pointer]
        mov eax, [operand_stack+eax+4]
        mov esi, 1
        mov ebx, 0
        clc
        pushfd
        .inner_loop:
            popfd
            shr byte [eax], 1
            mov edx, 0
            adc edx, 0
            cmp esi, 1
            je .first
            shl edx, 7
            add byte [ebx], dl
            .first:
            mov esi, 0
            mov edi, ebx
            mov ebx, eax
            mov eax, [eax+1]
            pushfd
            cmp eax, 0
        jne .inner_loop
        popfd

        cmp byte [ebx], 0
        jne .outer_loop_end
        cmp edi, 0
        je .outer_loop_end
            mov dword [edi+1], 0
            push ebx
            call free_list
            add esp, 4


    .outer_loop_end:
    loop .outer_loop
    .skip_loop:

    mov eax, [stack_pointer]
    push dword [operand_stack+eax]
    call free_list
    add esp, 4

    mov eax, [stack_pointer]
    mov eax, [operand_stack+eax+4]

    mov ebx, [stack_pointer]
    mov [operand_stack+ebx], eax

    add dword [stack_pointer], 4

    jmp .end



    .illegal_argument:
        add dword [stack_pointer], 8
        push err_msg_illegal_argument
        call printf
        add esp, 4
        jmp .end

    .insufficient_args:
        push err_msg_insufficientArgs
        call printf
        add esp, 4

    .end:
    inc dword [op_counter] ; check if needs to count in error as well move to pop_ends
    popad
    mov esp, ebp    
    pop ebp
    ret         


make_link:
    push ebp
    mov ebp, esp    
    sub esp, 4
    pushad 
    
    mov ebx, dword [ebp+8]                  ; the data value to insert to link
    push link_size                          ; size of 5
    call malloc                             ; allocate 5 bytes
    add esp, 4                              ; clear the stack
    mov byte [eax], bl                      ; insert the data to the section of data in the link
    mov dword [eax+1], 0                    ; insert null to "next" pointer

    mov dword [ebp-4], eax
    popad
    mov eax, [ebp-4]  
    mov esp, ebp    
    pop ebp
    ret                                     ;should return value of eax which is the 5 allocated bytes with data and pointer to null

;frees the link list allocated by malloc
free_list:
    push ebp
    mov ebp, esp    
    pushad

    mov eax, dword [ebp+8]                  ; move function parameter (start of the link) to eax
    
    free_list_iterator:
        mov ebx, dword [eax +1]              ; save the next link position in ebx
        push eax                            ; push current link to use in free
        call free                           ; free the current link
        add esp, 4                          ; free stack   
        mov eax, ebx                        ; curr = next
        cmp eax, 0                          ; check if curr = "null"
    jne free_list_iterator                  ; continue iteration if curr is not the end of the list
    
    popad           
    mov esp, ebp    
    pop ebp
    ret

print_list:
    push ebp
    mov ebp, esp    
    sub esp, 4
    pushad

    

    mov dword [ebp-4], 0
    sub dword [stack_pointer], 4

    cmp dword [stack_pointer], 0
    jle .end
    
    mov eax , dword [stack_pointer]
    mov eax, dword [operand_stack+eax]
    
    .link_iterator:
        mov ebx, 0
        mov bl, byte [eax]
        push ebx
        inc dword [ebp-4]
        mov eax, [eax+1]
        cmp eax, 0
    jne .link_iterator

    mov eax, 1
    .print_loop:
        cmp eax, 1
        jne .not_first
        push format_hex
        push dword [ebp+8]
        call fprintf
        jmp .first
        .not_first:
        push format_hex_padded
        push dword [ebp+8]
        call fprintf
        .first:
        add esp, 12
        dec dword [ebp-4]
        cmp dword [ebp-4], 0
        mov eax, 0
    jne .print_loop

    push newLine
    push dword [ebp+8]
    call fprintf

    add esp, 8
    
    .end:
    add dword [stack_pointer], 4
    popad           
    mov esp, ebp    
    pop ebp
    ret

