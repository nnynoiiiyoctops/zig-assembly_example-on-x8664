
.globl asmfun

# Функция вычисляет rdi * rsi - 4
asmfun:
    pushq %rdx     # Прячем rdx, чтобы его не повредить
    movq %rdi, %rax # Готовим первый операнд к умножению
    imulq %rsi # Умножаем
    subq $4, %rax # Вычитаем из результата 4. О переполнении не заботимся.
    popq %rdx # Возвращаем rdx.
    ret

.globl asmpower

# Функция вычисляет rdi ^ rsi
asmpower:
    pushq %rdx
    movq $1, %rax # Кладём начальное значение в rax
pow_loop:
    cmpq $0, %rsi
    je pow_end
    decq %rsi
    imulq %rdi
    jmp pow_loop
pow_end:
    popq %rdx
    retq



.globl asmfastpower

# Функция вычисляет rdi ^ rsi по быстрому алгоритму.
# Если показатель чётный, он делится надвое, а основание умножается само на себя
# Если показатель нечётный, он декрементируется, а результат умножается на основание
asmfastpower:
    pushq %rdx
    pushq %r10
    movq $1, %rax
fastpow_loop:
    cmpq $0, %rsi
    je fastpow_end
    testq $1, %rsi
    jnz fp_dec

    movq %rax, %r10 # Для умножения основания самого на себя, временно убираем результат.
    mov %rdi, %rax # Кладём основание в rax для умножения.
    imulq %rax # Умножаем основание само на себя
    movq %rax, %rdi
    movq %r10, %rax
    shrq %rsi
    jmp fastpow_loop

fp_dec:
    imulq %rdi
    decq %rsi
    jmp fastpow_loop


fastpow_end:
    popq %r10
    popq %rdx
    retq
