const std = @import("std");
const fs = std.fs;

const Cpu = struct {
    var regs: [32]u64 = undefined;
    var pc: u64 = 0;
    var dram: []u8 = undefined;
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const file = try fs.cwd().openFile("program", .{});
    defer file.close();
    const file_size = try file.getEndPos();

    // Create an array to hold the file contents
    const buffer = try allocator.alloc(u8, file_size);
    defer allocator.free(buffer);

    // Read the file into the buffer
    const bytes_read = try file.readAll(buffer);

    // Verify that we read the entire file
    if (bytes_read != file_size) {
        return error.IncompleteRead;
    }

    Cpu.dram = buffer;
    std.debug.print("File content: {any}\n", .{Cpu.dram});

    Cpu.regs[2] = 1024 * 1024 * 128;
    Cpu.regs[0] = 0;

    while (Cpu.pc < Cpu.dram.len) {
        const inst = fetch();
        Cpu.pc = Cpu.pc + 4;
        execute(inst);
    }
}

pub fn fetch() u64 {
    const pc = Cpu.pc;
    const dram = Cpu.dram;
    const first_byte: u32 = dram[pc];
    const second_byte: u32 = dram[pc + 1];
    const third_byte: u32 = dram[pc + 2];
    const fourth_byte: u32 = dram[pc + 3];

    return first_byte | (second_byte << 8) | (third_byte << 16) | (fourth_byte << 24);
}

pub fn execute(inst: u64) void {
    const opcode = inst & 0x7f;
    const rd: u32 = @intCast((inst >> 7) & 0x1f);
    const rs1: u64 = @intCast((inst >> 15) & 0x1f);
    const rs2: u64 = @intCast((inst >> 20) & 0x1f);
    Cpu.regs[0] = 0;
    std.debug.print("{}, {}, {}\n", .{ Cpu.regs[rd], Cpu.regs[rs1], Cpu.regs[rs2] });

    switch (opcode) {
        0x13 => {
            // addi
            Cpu.regs[rd] = Cpu.regs[rs1] +% Cpu.regs[rs2];
            std.debug.print("addi, {}, {}, {}\n", .{ Cpu.regs[rd], Cpu.regs[rs1], Cpu.regs[rs2] });
        },
        0x33 => {
            // add
            Cpu.regs[rd] = Cpu.regs[rs1] +% Cpu.regs[rs2];
            std.debug.print("add\n", .{});
        },
        else => {
            std.debug.print("not implemented yet: opcode {x}\n", .{opcode});
        },
    }
}
