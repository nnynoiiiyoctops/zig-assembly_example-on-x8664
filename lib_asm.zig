const std    = @import("std");
const expect = std.testing.expect;

pub fn asmfun(a: i64, b: i64) i64 {
  return   asm volatile(
      \\pushq    %%rdx
      \\imulq    %[b]
      \\subq     $4,      %%rax
      \\popq     %%rdx
      : [ret] "={rax}" ( -> i64)
      : [a] "{rax}" (a), //для imul помещаем в rax
        [b] "{rsi}" (b)
      : .{ .rdx = true }
  );
}

pub fn easier_asmfun(a: i64, b: i64) i64 {
  return   asm volatile(
      \\imulq    %[b]
      \\subq     $4,      %%rax
      : [ret] "={rax}" ( -> i64)
      : [a] "{rax}" (a), //для imul помещаем в rax
        [b] "{rsi}" (b)
      : .{ .rdx = true }
  );
}

test "testfunc" {
  var   result: i64 = 0;

  result = asmfun(2, 3); 
  try expect( result == 2 );  // 2 * 3 - 4 = 2;

  result = easier_asmfun( 3, 4 );
  try expect( result == 8 );
}

pub fn asmpower(a: i64, b: i64) i64 {
//a ^ b = result
return asm volatile(
      \\           pushq    %%rdx
      \\           mov       $1,         %%rax
      \\pow_loop:
      \\           cmpq $0,  %%rsi               //Сравнение
      \\           je        pow_end             //if (counter == 0) goto :pow_end
      \\           decq      %%rsi               //--counter
      \\           imulq     %%rdi               // rax *= rdi
      \\           jmp       pow_loop
      \\pow_end:
      \\           popq      %%rdx
      : [result]   "={rax}"   ( -> i64 )
      : [_]    "{rdi}"    (a),
        [_]    "{rsi}"    (b),
      : .{}
  ); }


pub fn easier_asmpower(a: i64, b: i64) i64 {
//a ^ b = result
return asm volatile(
      \\pow_loop:
      \\           cmpq $0,  %%rsi               //Сравнение
      \\           je        pow_end             //if (counter == 0) goto :pow_end
      \\           decq      %%rsi               //--counter
      \\           imulq     %%rdi               // rax *= rdi
      \\           jmp       pow_loop
      \\pow_end:
      : [result]   "={rax}"   ( -> i64 )
      : [_]    "{rdi}"    (a),
        [_]    "{rsi}"    (b),
        [_]    "{rax}"    (1)
      : .{}
  ); }

test "asmpower function test" {
  var   result: i64 = 1;

  result = asmpower(2,4);
  try expect( result == 16 );

  result = easier_asmpower(9, 3);
  try expect( result == 729 );
    
}

pub fn asmfastpower(a: i64, b: i64) i64 {
    return asm volatile (
        \\fastpow_loop:                                  // Начало цикла
        \\              cmpq    $0,      %[b]
        \\              je      end                      // if (b == 0) break
        \\              testq   $1,      %[b]            // проверяем младший бит (чётность)
        \\              jnz      fp_dec
        // Чётный случай: b = b/2, a = a*a
        \\              movq    %%rax,   %%r10           // сохраняем результат в r10
        \\              movq    %[a],    %%rax           // основание в rax для умножения
        \\              imulq   %%rax                    // rax = a * a
        \\              movq    %%rax,   %[a]            // обновляем основание
        \\              movq    %%r10,   %%rax           // восстанавливаем результат
        \\              shrq    $1,      %[b]            // b = b / 2
        \\              jmp     fastpow_loop
        // Нечётный случай
        \\fp_dec:                                        // fp_dec:
        \\              imulq   %[a]                     // результат *= основание
        \\              decq    %[b]                     // b--
        \\              jmp     fastpow_loop
        \\end:
        : [ret] "={rax}" (-> i64)
        : [a]   "{rdi}"  (a),
          [b]   "{rsi}"  (b),
          [_]   "{rax}"  (1)
        : .{ .cc = true }
    );
}

test "asmfastpower" {
    // Базовые случаи
    try std.testing.expect(asmfastpower(2, 0) == 1);   // 2^0
    try std.testing.expect(asmfastpower(2, 1) == 2);   // 2^1
    try std.testing.expect(asmfastpower(2, 3) == 8);   // 2^3
    try std.testing.expect(asmfastpower(3, 3) == 27);  // 3^3
    
    // Большие степени
    try std.testing.expect(asmfastpower(2, 10) == 1024);    // 2^10
    try std.testing.expect(asmfastpower(5, 4) == 625);      // 5^4
    
    // Проверка чётного/нечётного путей
    try std.testing.expect(asmfastpower(2, 6) == 64);       // чётный путь
    try std.testing.expect(asmfastpower(2, 7) == 128);      // нечётный путь
}
