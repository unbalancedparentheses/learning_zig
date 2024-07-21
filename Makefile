build:
	zig build

run: build
	./zig-out/bin/riscv program	
