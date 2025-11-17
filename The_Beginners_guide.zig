const std_lib = @import("std");
const expect  = std_lib.testing.expect;
const allocator = std_lib.testing.allocator;

// Биты 63-0     Биты 31-0     Биты 15-0     Биты 15-8     Биты 7-0
//       RAX           EAX            AX            AH           AL
//       RBX           EBX            BX            BH           BL
//       RCX           ECX            CX            CH           CL
//       RDX           EDX            DX            DH           DL
//       RSI           ESI            SI                        SIL
//       RDI           EDI            DI                        DIL
//       RBP           EBP            BP                        BPL
//       RSP           ESP            SP                        SPL
//        R8           R8D           R8W                        R8B
//        R9           R9D           R9W                        R9B
//       R10          R10D          R10W                       R10B
//       R11          R11D          R11W                       R11B
//       R12          R12D          R12W                       R12B
//       R13          R13D          R13W                       R13B
//       R14          R14D          R14W                       R14B
//       R15          R15D          R15W                       R15B

   //Немножко отрывков из
  
  // Inline assembly это выражение которое возвращает значение,
  // ключевое слово  `asm`  начинает его
  fn syscall1(number: usize, arg1: usize) usize {
    return asm
    // `volatile` это опциональный можификатор, указывающий Zig не
    // наличие побочных эффектов. Без него
    // (`volatile`), Zig может удалить эту вставку,
    // если её результат не используется 
    volatile (
    // Далее следует известная во время компиляции строка, с непосредственно asm кодом
    // !!!До конца коментария следует отсебятина
    // Стоит учесть что Zig пользуется тем же синтаксисом AT&T. Он же используется в
    // Ассемблерных вставках на C под GCC.
    // Поэтому в https://ziglang.org/documentation/0.15.2/ есть вот такая ссылка
    // https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html
    // Так же в README
    \\syscall
    // Далее идут выводы. Сейчас поддерживается вывод лишь одного значения.
    // Возможно в будущем Zig будет поддерживать вывод нескольких значений. Зависит от того, как
    // https://github.com/ziglang/zig/issues/215 будет решён
    // Допускается и отсутствие входных данных.
    :
    // Это имя, что будет использоваться в  `%[ret]` синтаксисе in
    // в ассемблерной строке выше. Этот пример не использует его,
    // Но данный синтаксис обязателен.                                                            ПРИМЕЧАНИЕ!. Можно использовать известный вам `_` и тут. [_] - валидное значение. Но решил оставить как в доке.
    [ret]
    // Далее следует строка-ограничение. Эта функция считается нестабильной
    // Поэтому для неё следует использовать документацию:
    // http://releases.llvm.org/10.0.0/docs/LangRef.html#inline-asm-constraint-string
    // https://gcc.gnu.org/onlinedocs/gcc/Extended-Asm.html
    // В этом примере, строка ограничитель означает "Результирующие значение этой вставки будет находиться в регистре rax"
    "={rax}"
    // Далее следует, ибо привязка к значению, либо '->' а затем
    // тип, которым будет обладать возвращаемое значение. 
    // Если это значение связанно с именем, то синтаксис `%[имя]` будет использовано
    // для ссылки на регистр, привязанный к значению.
    (-> usize),
    // Далее следует список инпутов. 
    // Ограничение для этих входных значений значит: "Когда ассемблерный код будет исполнен
    // `rax` будет содержать значение `number` и  `rdi` будет содержать значение `arg1`.  Тут доступно любое кол-во входных параметров.
    : [number] "{rax}" (number),
      [arg1] "{rdi}" (arg1),
    // Далее идёт список изменённых после исполнения регистров, значения которых
    // не будут сохранены при выполнении этого ассемблерного кода.
    // Они не включают регистры вывода или ввода. Специальный блокировщик
    // значение "memory" означает, что сборка выполняет запись в произвольные необъявленные ячейки
    // памяти, а не только в память, на которую указывает объявленный косвенный
    // вывод. В этом примере мы перечисляем `rcx` и `r11`, поскольку известно, что
    // системный вызов не сохраняет эти регистры.
      : .{ .rcx = true, .r11 = true } ) ;
}

test "Возвращаемое значение" {
  //У этих тестов нет побочных эффкутов. Поэтому volatile тут не нужен.

  const a: u64 = asm(
    \\
      : [_] "={rax}" ( -> u64 ),
      : [_] "{rax}" ( 10 ),
      : .{}
  );
  try expect( a == 10 );

  const b: u64 = asm(
    \\movq    %[a],   %%rax
      : [ret]  "={rax}"  ( -> u64 )
      : [a]    "r"   ( a )
      : .{} );
  try expect( b == a );
  
  const b_ptr: *u64 = asm(
    \\leaq    %[b],   %%rax
      : [ret]  "={rax}"  ( -> *u64 )
      : [b]    "m"       ( b )
      : .{} );
  try expect( @intFromPtr( &b ) + 16 == @intFromPtr( b_ptr ) );
  //Так как b на стеке - то местоположение может меняться. Например тут видно,
  //что для вставки была создана копия с небольшим сдвигом.
  
  const array: [10]u64 align(8) = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9 };
  var change_me: u64 = 10;
  _ = &change_me;
  
  asm volatile(
    \\leaq    %[val],   %%rax   //rax = &change_me
    \\movq    $20,      (%%rax) //rax.* = 20
      : [val]   "+m"  ( change_me )
      :
      : .{ .memory = true }
  );
  try expect( change_me == 20 );
  
  const arr_ptr: [*]u64 = asm(
    \\leaq    %[arr],   %%rax
      : [ret]  "={rax}"  ( -> [*]u64 )
      : [arr]  "m"       ( array )
      : .{}
  );
  //std_lib.debug.print("\n&arr     {*}\narr_ptr  {*}\n", .{&array, arr_ptr} );
  try expect( &array == arr_ptr );

  const first_elem: u64 = asm(
    \\leaq    %[arr],    %%rax  //rax = &array[0]
    \\movq    (%%rax),   %%r11  //r11 = rax.*
      : [ret]  "={r11}"  ( -> u64 ),
        [arr]  "=m"       ( array )
      :
      : .{ .memory = true }
  );
  try expect( first_elem == 0 );

  const last_elem: u64 = asm volatile(
    \\leaq    %[arr],   %%rax  //rax = %array[0]
    \\add     $72,      %%rax  //rax += 72 //72 = 8 * 9 (выравнивание * номер элемента)
    \\movq    (%%rax),  %%r9   //r9 = rax.*
    : [ret]  "={r9}"  ( -> u64 )
    : [arr]  "m"   ( array )
    : .{}
  );
  try expect( last_elem == 9 );

//Усложняем задачку  
// jmp - абсалютный прыжок. Без условий
// je  - jump if equal            (==)
// jne - jump if not equal        (!=)
// jl  - jump if less             (<,  знаковое)
// jg  - jump if greater          (>,  знаковое)
// jle - jump if less or equal    (<=, знаковое)
// jge - jump if greater or equal (>=, знаковое)
// jb  - jump if below            (<,  беззнаковое)
// ja  - jump if above            (>,  беззнаковое)
  
  const summ_of_arr: u64 = asm(
    \\leaq    %[arr],     %%rax  //rax = %array[0]
    \\begin:                     //метка
    //r9|r10  - результат
    //r11     - счётчик
    //rax     - указатель на элемент
    //8       - выравнивание
    \\movq    (%%rax),   %%r9    //r9   =  rax.*
    \\add     %%r9,      %%r10   //summ += r9
    //:( counter += 1 )
    \\inc     %%r11              //cpunter += 1
    \\add     $8,        %%rax   //rax += 8
   //while( r11 < len )
    \\cmpq    %[len],    %%r11
      \\        jl         begin
    : [ret]  "={r10}" ( -> u64 )
    : [arr]  "m"      ( array ),
      [_]    "{r10}"  ( 0 ), //На случай, если до вставки в r10 было значение
      [_]    "{r11}"  ( 0 ), //счётчик = 0
      [len]  "{r12}"  ( array.len )
      : .{.memory = true, //Для любой работы с указателями - ОБЯЗАТЕЛЬНО
          .cc = true,     //Обязательно для любых сравнений
          .r9 = true,     //Используется, но не указано в inputs/outputs
          }
  );
  try expect( summ_of_arr == 45 );
  
}

test "Simple arythmetic" {

  const add_result = asm volatile(
      \\add    %%rax,    %%rdx  //Результат пишется во второй аргумет
      : [ret] "={rdx}" ( -> u64 )
      : [_]   "{rax}"  ( 2 ), //Разумеется можно ручками сделать mov. Разумеется. И всё показанный способ проще
                              //Так же хочу заметить что std написан в таком стиле
        [_]   "{rdx}"  ( 3 )
      : .{ .rdx = true } );
  try expect( add_result == 5 );

  const sub_result: u64 = asm volatile(
      \\mov   $20,       %%rax
      \\mov   $10,       %%rdx
      \\sub   %%rdx,     %%rax //Почему-то в sub результат во второй аргумент пишется
      : [ret] "={rax}" ( -> u64)
      : [_] "{rax}"  (20),
        [_] "{rdx}"  (10),
      : .{ .rax = true }
  );
  try expect( sub_result == 10 );

  const imul_result: u64 = asm volatile(
      \\imul   %%rdx,    %%rax  //b = a * b Тут тоже результат во второй аргумент
      : [ret] "={rax}" ( -> u64 )
      : [_] "{rax}" (2),
        [_] "{rdx}" (4),
      : .{ .rax = true, .rdx = true}
  );
  try expect( imul_result == 8 );

  const mul_result: u64 = asm volatile(
      \\mul    %%rdx  // Тут скрытое умножение с RAX
      : [ret]  "={rax}"  (-> u64)
      : [_]    "{rax}"  ( 2 ),
        [_]    "{rdx}"  ( 3 )
      : .{ .rax = true, .rdx = true }
  );
  try expect( mul_result == 6 );

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
  );
}
