const std_lib = @import("std");

pub fn main() !void {
    var a: u64 = 0;
    var b: u64 = 0;

    asm volatile (
      \\mov   $42 ,  %[a]
      \\mov   $18 ,  %[b]
      \\add   %[b],  %[a]        
      : [a] "+r" (a),
        [b] "=r" (b),
  );

    var buf: [128]u8 = undefined;
    var writer: std_lib.fs.File.Writer = .init(std_lib.fs.File.stdout(), &buf);
  
    try writer.interface.print("\n|b: {d} |a: {d}|", .{ b, a });
    try writer.interface.flush();

    return;
}
