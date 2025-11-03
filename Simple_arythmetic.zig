const std_lib = @import("std");

pub fn main() !void {
  var a: i64 = 0;
  var b: i64 = 0;

  var buffer: [128]u8 = undefined;
  var writer: std_lib.fs.File.Writer = .init( std_lib.fs.File.stdout(), &buffer );

  try writer.interface.print("\nbegin: |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();

  //volatile = указание компилятору не оптимизировать и не выкидывать эти куски кода
  //Общий синтаксис выглядит так
  //asm( строка : ограничения : clobbers );
  asm volatile(
      \\mov   $2,    %[a] //a = 2
      \\mov   $3,    %[b] //b = 2
      \\add   %[a],  %[b] //a = a + b
      : [a] "+r" (a),     //а - доступен для чтения и записи
        [b] "=r" (b)      //b - доступен для записи
  );
  // "=r" - ввод
  // "+r"  - ввод и вывод
  //Так же стоит уточнить что r - любой регистр. Тогда как для ограничения конкретного регистра его следует обрамлять с помощью {}
  // "{rax}" | "={rax}" | "+{rax} тоже валидно
  
  try writer.interface.print("add:   |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();
  
  asm volatile(
      \\mov   $20,   %[val_a] //a = 20
      \\mov   $10,   %[val_b] //b = 10
      \\sub   %[val_b],  %[val_a] //a = a - b
      : [val_a] "+r"  (a),  // Имена в ассемблерных вставках могут отличаться от переменных, с которыми вы их "свяжите"
        [val_b] "=r"  (b),  //Вот наглядный пример
      ://Тут должны были быть clobbers. Но их можно опустить. Как математики опускают скобки у "sin 2x"
       //Только тут это может повлиять на результат
  );

  try writer.interface.print("sub:   |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();

  asm volatile(
      \\mov    $2,    %[a]  //a = 2
      \\mov    $4,    %[b]  //b = 4
      \\imul   %[a],  %[b]  //b = a * b
      : [a] "+r" (a),
        [b] "+r" (b)
  );

  try writer.interface.print("imul:  |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();

  asm volatile(
      \\mov    $8,    %[a]  //a = 2
      \\mov    $0,    %[b]  //b = 0
      \\mul   %[a]          //a = a * a
      : [a] "+r" (a),
        [b] "=r" (b)
  );
  //Тут я должен сказать что большинство этих инструкций я тыкаю наугад)
  //Так что вы выбрали крайне сомнительный источник для обучения
  
  try writer.interface.print("mul:   |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();

  asm volatile(
    \\
      :
      :
  );

  try writer.interface.print("mul:   |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();
  
  return;
}
