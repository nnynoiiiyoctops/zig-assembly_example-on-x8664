const std = @import("std");

// Создаём кастомную секцию через Global Assembly
comptime {
    asm (
        // Создаём секцию с атрибутами: writable, allocatable
        \\.section .my_custom_section, "aw", @progbits
        // Выравнивание для 64-битных данных
        \\.align 8
        // Метка начала секции (опционально)
        \\.global my_section_start
        \\my_section_start:
    );
}

// Переменные, которые мы разместим в кастомной секции
var my_counter: u64 linksection(".my_custom_section") = 0;
var my_buffer: [100]u8 linksection(".my_custom_section") = undefined;
const my_message: []const u8 linksection(".my_custom_section") = "Hello from custom section!";

pub fn main() !void {
  var buf: [4096]u8 = undefined;
  var writer: std.fs.File.Writer = .init( std.fs.File.stdout(), &buf );

  my_counter += 1;

  // Инициализируем буфер данными из my_message
  @memcpy(my_buffer[0..my_message.len], my_message); // Копируем строку
  
  try writer.interface.print("Counter: {}\n", .{my_counter});
  try writer.interface.print("Message: {s}\n", .{my_buffer[0..my_buffer.len]});
  try writer.interface.print("Buffer size: {}\n", .{my_buffer.len});
  try writer.interface.print("Message(as_string): {s}\n", .{my_message[0..my_message.len]});
  try writer.interface.print("Counter address: 0x{x}\n", .{@intFromPtr(&my_counter)});
  try writer.interface.print("Buffer address: 0x{x}\n", .{@intFromPtr(&my_buffer)});
  try writer.interface.flush();
  
}
