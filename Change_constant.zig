const std_lib = @import("std");

pub fn main() !void {
  const a: u64 = 0;

  var out_buf: [64]u8 = undefined;
  var writer: std_lib.fs.File.Writer = .init( std_lib.fs.File.stdout(), &out_buf );
  try writer.interface.print( "\n| BEFORE: {d} |", .{a});

  asm volatile(
      \\mov $24, %%rax
      \\mov %%rax, %[a]
      :
      : [a] "r" (a)
  );

  try writer.interface.print( "\n| AFTER: {d} |", .{a});
  try writer.interface.flush();

  return;
}
  
