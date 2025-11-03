const std_lib = @import("std");

pub fn main() !void {
  var a: i64 = 0;
  var b: i64 = 0;

  var buffer: [128]u8 = undefined;
  var writer: std_lib.fs.File.Writer = .init( std_lib.fs.File.stdout(), &buffer );

  try writer.interface.print("\nbegin: |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();

  asm volatile(
      \\mov   $2,    %[a]
      \\mov   $3,    %[b]
      \\add   %[a],  %[b]
      : [a] "+r" (a),
        [b] "=r" (b)
  );
  
  try writer.interface.print("add:   |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();
  
  asm volatile(
      \\mov   $20,   %[a]
      \\mov   $10,   %[b]
      \\sub   %[b],  %[a]
      : [a] "+r" (a),
        [b] "=r"  (b),
      :
  );

  try writer.interface.print("sub:   |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();

  asm volatile(
      \\mov    $2,    %[a]
      \\mov    $4,    %[b]
      // \\mov    %[b],  %%rax
      // \\mov    %[a],  %%rbx
      \\imul   %[a],  %[b]
      : [a] "+r" (a),
        [b] "+r" (b)
  );

  try writer.interface.print("imul:  |a: {d}|b: {d}|\n", .{ a, b });
  try writer.interface.flush();
  
  return;
}
