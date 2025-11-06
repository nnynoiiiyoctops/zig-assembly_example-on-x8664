//Тут будет пример работы с метками и условияя
const  std_lib  =  @import("std");
const  expect  =  std_lib.testing.expect;

test "Метки и переходы" {

  var a: i64 = 1;

  asm volatile(
      \\movq    $0,    %%rax
      \\jmp end
      \\movq    $10,    %%rax
      \\end:
      : [result]  "={rax}"  (a)
      :
      : .{}
  );    

  try expect( a == 0 );
  
}

// Все if и вообще любые сравнения строятся на прыжках по коду
// jmp - абсалютный прыжок. Без условий
// je  - jump if equal            (==)
// jne - jump if not equal        (!=)
// jl  - jump if less             (<,  знаковое)
// jg  - jump if greater          (>,  знаковое)
// jle - jump if less or equal    (<=, знаковое)
// jge - jump if greater or equal (>=, знаковое)
// jb  - jump if below            (<,  беззнаковое)
// ja  - jump if above            (>,  беззнаковое)
//Примеров каждого не будет
//(Если будет - то мне вообще заняться нечем)

test "if then else" {
    const a: i64 = 10;
    const b: i64 = 20;
    var   result: i64 = 0;

    asm volatile (
        \\cmpl   %[b], %[a]       // Сравниваем a и b
        \\jle    less            // Если a <= b, прыгаем вперёд к метке 1
        \\movl   $100, %[result]  // a > b - устанавливаем результат 100
        \\jmp    end               // Прыгаем в конец
        \\less:                   // Метка 1 (else branch)
        \\movl   $200, %[result]  // a <= b - устанавливаем результат 200
        \\end:                       // Метка 2 (конец)
        : [result] "=r" (result)
        : [a] "r" (a),
          [b] "r" (b)
        : .{}
    );

    // При a=10, b=20: result должен быть 200
    try expect(result == 200);
}
