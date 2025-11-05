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


