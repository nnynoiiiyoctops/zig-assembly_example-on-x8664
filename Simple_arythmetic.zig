const std_lib = @import("std");
const expect = std_lib.testing.expect;

  //Стоило бы обозначить, что в этом репозитории крайне мало смысла.
  //Ведь этот код мало того что прикован к x86_64
  //Так ещё и на вашем процессоре может быть совершенно иной набор команд
  //Этот репозиторий скорее ознакомительный, нежели полезный

  //volatile = указание компилятору не оптимизировать и не выкидывать эти куски кода
  //Общий синтаксис выглядит так
  //asm( строка : выходы : входы : clobbers );
  //Но чаще вы будите видеть
  //asm volatile(
  //\\asm code
  // : [ret] "constraint" ( -> type),  //zig:16:11: error: inline assembly allows up to one output value
                                       //issue215((((
                                       //Может быть только 1 выход
  // Хотя будут показаны примеры обратного  
  // : вход_1,                         //Синтаксис входных данных зависит от решения issue 215. Ознакомьтесь если интересно
  //   вход_2,                         //https://github.com/ziglang/zig/issues/215
  //   ...   ,
  //   вход_n
  // : .{ .rcx = true, .r11 = true } ); //Это лишь пример
                                        //Но тут показано, что эти регистры будут изменены после этой вставки кода
                                        //Например этот "clobbers" говорит что после нашего кода поменяются
                                        //регистры rcx и r11
                                        //Или  .{ .memory = true }, если будет изменена память во вне
test "Первая ассемблерная вставка" {
  var a: u64 = 0;
  var b: u64 = 0;
  asm volatile(
      \\mov   $2,      %[a] //a = 2
      \\mov   $3,      %[b] //b = 3
      : [a] "+r" (a),  //Указываем что возвращается значение в a
        [b] "+r" (b)   //Указываем что возвращается значение в b
      :                   //Мы сюда ничего не передаём. Поэтому секция ввода будет пуста
                          //Хотя и пишем в переданные переменные
                          //Но если мы запишем их здесь. То результат в них не запишется. В этом вы можете убедиться
                          //ознакомившись с файлом Change_constant.zig в этой же директории
      : .{}               //Тут перечисляются регистры которые будут изменены. Но изменены во вне
                          //Обращаю внимание на то, что тут не используется регистр RAX и из вне он не изменен.
                          //Хочу отметить что активно эта секция будет использоваться либо при вызове функции.
                          //Либо при системных выховах
                          // Хочу отметить что при системных вызовах может меняться память. Для этого есть поле
                          // .memory которому задается значение true
  );
  // "=r" - ввод в регистр/переменную
  // "+r" - ввод и вывод из регистра/переменной
  // "m"  - memory. И такое есть. Но это будет не в этом файле
  //Так же стоит уточнить что r - любой регистр. Тогда как для ограничения конкретного регистра, его следует обрамлять с помощью {}
  // "{rax}" | "={rax}" | "+{rax}" тоже валидно

  // Лучше всего будет ознакомиться с
  // https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html
  // https://releases.llvm.org/10.0.0/docs/LangRef.html#inline-asm-constraint-string

  // Синтаксис взят от GCC.
  // А ограничения, clobbers, Constraint взяты с llvm
  // Насколько я разобрался
  try expect( a == 2 );
  try expect( b == 3 );

}

test "Сложение" {

  const result = asm volatile(
      \\add    %%rax,    %%rdx  //Результат пишется во второй аргумет
      : [ret] "={rdx}" ( -> u64 )
      : [_]   "{rax}"  ( 2 ), //Разумеется можно ручками сделать mov. Разумеется. И всё показанный способ проще
                              //Так же хочу заметить что std написан в таком стиле
        [_]   "{rdx}"  ( 3 )
      : .{ .rdx = true } );

  try expect( result == 5 );
}

test "Вычитание" {
  const result: u64 = asm volatile(
      \\mov   $20,       %%rax
      \\mov   $10,       %%rdx
      \\sub   %%rdx,     %%rax //Почему-то в sub результат во второй аргумент пишется
      : [ret] "={rax}" ( -> u64)
      : [_] "{rax}"  (20),
        [_] "{rdx}"  (10),
      : .{ .rax = true }
  );

  try expect( result == 10 );
}


test "Знаковое умножение" {
  const result: u64 = asm volatile(
      \\imul   %%rdx,    %%rax  //b = a * b Тут тоже результат во второй аргумент
      : [ret] "={rax}" ( -> u64 )
      : [_] "{rax}" (2),
        [_] "{rdx}" (4),
      : .{ .rax = true, .rdx = true}
  );

  try expect( result == 8 );

}

test "mul instruction" {
  const a: u64 = asm volatile(
      \\mul    %%rdx  // Тут скрытое умножение с RAX
      : [ret]  "={rax}"  (-> u64)
      : [_]    "{rax}"  ( 2 ),
        [_]    "{rdx}"  ( 3 )
      : .{ .rax = true, .rdx = true }
  );

  try expect( a == 6 );
}

 test "Деление" {

  const dividend: u64 = 1000;
  const divisor: u64 = 3;
  var   quotient: u64 = undefined;
  var   remainder: u64 = undefined;

  asm volatile(
      \\xor    %%rdx,    %%rdx
      \\div    %%rsi
      : [_]        "={rax}"  (quotient),
        [_]        "={rdx}"  (remainder)
      : [_]        "{rax}"   (dividend),
        [_]        "{rsi}"       (divisor)
   : .{ .rax = true,  .rdx = true }
  );

   //  std_lib.debug.print("\n {d} {d} {d} {d}\n", .{ dividend, divisor, quotient, remainder } );
   try expect( quotient   ==  333 );
   try expect( remainder  ==  1 );

}

//Алгоритм возведения в степень
pub fn asmpower(a: i64, b: i64) i64 {
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

  result = asmpower(9, 3);
  try expect( result == 729 );
    
}

//Алгоритм быстрого возведения в степень
pub fn asmfastpower(a: i64, b: i64) i64 {
    return asm volatile (
        \\fastpow_loop:                                 // Начало цикла
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
    try expect(asmfastpower(2, 0) == 1);   // 2^0
    try expect(asmfastpower(2, 1) == 2);   // 2^1
    try expect(asmfastpower(2, 3) == 8);   // 2^3
    try expect(asmfastpower(3, 3) == 27);  // 3^3
    
    // Большие степени
    try expect(asmfastpower(2, 10) == 1024);    // 2^10
    try expect(asmfastpower(5, 4) == 625);      // 5^4
    
    // Проверка чётного/нечётного путей
    try expect(asmfastpower(2, 6) == 64);       // чётный путь
    try expect(asmfastpower(2, 7) == 128);      // нечётный путь
}
