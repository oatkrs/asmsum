; Reads two integers from user, prints:
;   var a is <a>
;   var b is <b>
;   a plus b is <a+b>

section .data
promptA  db "Enter a: ",0
promptB  db "Enter b: ",0

outA     db "var a is ",0
outB     db "var b is ",0
outSum   db "a plus b is ",0

bufA     times 32 db 0
bufB     times 32 db 0

errMsg   db "Invalid number!",0x0a,0
errLen   equ $ - errMsg

newline  db 0x0a

section .bss
; no bss needed here

section .text
global _start

; -------------- sys_write --------------
;  rdi=file, rsi=buf, rdx=len => rax=1 => syscall
; We'll define a small routine to print a null-terminated string:
printStr:
    push rbx
    ; find length
    xor rcx, rcx
    mov rbx, rsi
.findLen:
    cmp byte [rbx+rcx],0
    je .gotLen
    inc rcx
    jmp .findLen
.gotLen:
    ; rcx is length
    ; do write(1, rsi, rcx)
    mov rax, 1
    mov rdi, 1
    mov rdx, rcx
    syscall
    pop rbx
    ret

; -------------- readLine --------------
;  reads up to 31 chars from stdin, puts 0 at end
;  rsi => buffer
;  returns nothing special
readLine:
    mov rax, 0    ; syscall read
    mov rdi, 0    ; stdin
    mov rdx, 31   ; read up to 31 bytes
    syscall
    ; rax => number of bytes read
    ; if rax>0, we replace the last char (which might be \n) with 0
    cmp rax,0
    jle .doneRead
    dec rax
    mov byte [rsi+rax],0
.doneRead:
    ret

; -------------- asciiToInt --------------
;  rsi => buffer with ASCII number
;  returns integer in rax, or -1 if invalid
asciiToInt:
    push rbx
    push rdx
    xor rax,rax
    xor rbx,rbx     ; rbx => sign(0=plus) or partial
    ; we'll do no sign support for simplicity
.loopChar:
    mov dl, [rsi]
    cmp dl,0
    je .done
    cmp dl,'0'
    jb .invalid
    cmp dl,'9'
    ja .invalid
    sub dl,'0'
    imul rax, rax, 10
    add rax,rdx
    inc rsi
    jmp .loopChar
.invalid:
    mov rax,-1
    jmp .done2
.done:
    ; success
.done2:
    pop rdx
    pop rbx
    ret

; -------------- intToAscii --------------
;  rdi => buffer to store result
;  rax => number to convert
;  returns => nothing, writes 0-terminated string to [rdi]
intToAscii:
    push rbx
    push rcx
    push rdx

    cmp rax,0
    jne .convert
    ; zero => "0"
    mov byte [rdi], '0'
    mov byte [rdi+1],0
    jmp .done

.convert:
    xor rbx,rbx   ; store base=10
    mov rbx,10
    ; go to end of buffer
    add rdi,30    ; we'll fill from the end backward
    mov byte [rdi],0
.loopConv:
    xor rdx,rdx
    div rbx
    add rdx,'0'
    dec rdi
    mov [rdi],dl
    cmp rax,0
    jne .loopConv
.done:

    pop rdx
    pop rcx
    pop rbx
    ret

; -------------- _start --------------
_start:

    ; ask for a
    mov rsi, promptA
    call printStr

    mov rsi, bufA
    call readLine
    ; parse
    mov rsi, bufA
    call asciiToInt
    cmp rax,-1
    je .err
    mov rbx, rax   ; store a in rbx

    ; ask for b
    mov rsi, promptB
    call printStr

    mov rsi, bufB
    call readLine
    mov rsi, bufB
    call asciiToInt
    cmp rax,-1
    je .err
    mov rcx, rax   ; store b in rcx

    ; print "var a is <a>"
    mov rsi, outA
    call printStr

    mov rax, rbx
    mov rdi, bufA
    call intToAscii
    mov rsi, bufA
    call printStr
    ; newline
    mov rax,1
    mov rdi,1
    mov rsi, newline
    mov rdx,1
    syscall

    ; "var b is <b>"
    mov rsi, outB
    call printStr
    mov rax, rcx
    mov rdi, bufB
    call intToAscii
    mov rsi, bufB
    call printStr
    ; newline
    mov rax,1
    mov rdi,1
    mov rsi, newline
    mov rdx,1
    syscall

    ; "a plus b is <a+b>"
    mov rax, rbx
    add rax, rcx
    mov rdi, bufB
    call intToAscii

    mov rsi, outSum
    call printStr

    mov rsi, bufB
    call printStr
    ; newline
    mov rax,1
    mov rdi,1
    mov rsi, newline
    mov rdx,1
    syscall

    ; exit(0)
    mov rax,60
    xor rdi,rdi
    syscall

.err:
    ; print "Invalid number!"
    mov rsi, errMsg
    call printStr
    ; exit(1)
    mov rax,60
    mov rdi,1
    syscall
