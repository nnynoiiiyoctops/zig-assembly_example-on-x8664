const std_lib = @import("std");

pub fn main() !void {
    var buf: [128]u8 = undefined;
    var writer: std_lib.fs.File.Writer = .init(std_lib.fs.File.stdout(), &buf);
  
    var a: u64 = 0;
    var b: u64 = 0;

    try writer.interface.print("\nBEFORE: |b: {d}  |a: {d} |", .{ b, a });
    try writer.interface.flush();
  
    asm volatile (
      \\mov   $42 ,  %[a]
      \\mov   $18 ,  %[b]
      \\add   %[b],  %[a]        
      : [a] "+r" (a),
        [b] "=r" (b),
  );
  
    try writer.interface.print("\nAFTER:  |b: {d} |a: {d}|", .{ b, a });
    try writer.interface.flush();

    return;
}
