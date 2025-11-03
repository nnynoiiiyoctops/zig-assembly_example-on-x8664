const std_lib = @import("std");

pub fn main() !void {

  var a: u64 = 0;
  var b: u64 = 0;
  var c: u64 = 0;

  asm volatile(
    \\mov $1, %[a]
    \\mov $2, %[b]
    \\mov $3, %[c]
    : [a] "=r" (a),
      [b] "=r" (b),
      [c] "=r" (c)
  );
  
  var buf: [128]u8 = undefined;
  var writer: std_lib.fs.File.Writer = .init(std_lib.fs.File.stdout(), &buf);
  
  try writer.interface.print("\n|b: {d} |a: {d}|c: {d}|", .{ b, a, c });
  try writer.interface.flush();

  return;
}
