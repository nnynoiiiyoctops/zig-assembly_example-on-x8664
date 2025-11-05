//Тут будет набор тестов, которые я не смог отнести к определенной тематике
const std_lib = @import("std");
const expect  = std_lib.testing.expect;

test "write in pointer" {

  var   a:   u64  = 0;

  asm volatile(
      \\movq    %[ptr],   %%rax
      \\movq    $42,      (%%rax)
      : 
      : [ptr] "r" (&a)
      : .{ .memory = true }
  );

  try expect( a == 42 );
  
}

test "return struct from asm" {

  const structure = asm volatile (
      \\mov    $20,    %%eax
      \\shl    $32,    %%rax
      \\mov    $10,    %%ebx
      \\or     %%rbx,  %%rax
      :  [ret] "={rax}" ( -> struct{a:u32, b:u32} ),
      :
      : .{.rax = true,
          .rbx = true } );

  try expect( structure.a == 10 );
  try expect( structure.b == 20 );
  
}


test "write struct in memory" {

  var struct2: struct{ a: u64, b: u64 } align(8) = undefined;
//std_lib.debug.print("{any}", .{struct2} );  
  
  asm volatile (
      \\movq   %[field_a],     %%rax
      \\movq   $10,            (%%rax)
      \\movq   %[field_b],     %%rax
      \\movq   $20,            (%%rax)
      :
      : [field_a] "m" (&struct2.a),
        [field_b] "m" (&struct2.b)
      : .{ .memory = true, .rax = true }
  );


//std_lib.debug.print("{any}", .{struct2} );
  try expect( struct2.a == 10 );
  try expect( struct2.b == 20 );
  
}

test "get address" {

  var a: u64 = 0;

  asm volatile(
      \\leaq     %[val],   %%rax  //Берем аддрес переменной val и помещаем в rax
      \\movq    $42,      (%%rax)
      : [val]  "=m"  (a)          //Без "=m" работать не будет. "=r" тоже работать не будет
      :                           //Я настоятельно рекомендую запустить с constraint "=r" 
      : .{} );                    //Так как эта ошибка показывает весьма интересные аргументы 
                                  //А именно non lea rax rax none none
  try expect( a == 42 );
  
}

// test "linux exit syscall"{  //Закомментированно по 1 простой причине - этот тест никогда не завершается
//   asm volatile(             //Он работает. Вместе с этим не так как хотелось бы
//       \\syscall
//       : 
//       : [_] "{rax}" (60),
//         [_] "{rdi}" (1)
//       : .{ .rax = true,
//           .rdi = true } );
//   unreachable;

// }

test "write syscall. Write to stdout" {
  const string = "\nПривет из сисколла в stdout!)\n";

  //Сперва в stdout
  asm volatile(
      \\syscall
      : 
      : [_] "{rax}" (1), //номер системного вызова
        [_] "{rdi}" (1), //stdout
        [_] "{rsi}" (&string[0]),
        [_] "{rdx}" (string.len)
      : .{ .rax = true,
           .rdi = true,
           .rsi = true,
           .rdx = true } );
    
}

//Теперь в stderr
test "write syscall. Write to stderr" {
  const string = "\nПривет из сисколла в stderr!)\n";

  asm volatile(
      \\syscall
      : 
      : [_] "{rax}" (1), //номер системного вызова
        [_] "{rdi}" (2), //stderr
        [_] "{rsi}" (&string[0]),
        [_] "{rdx}" (string.len)
      : .{ .rax = true,
           .rdi = true,
           .rsi = true,
           .rdx = true } );

  //Теперь в stderr   
}
