/*
 * Linker script for Caravel RISC-V firmware
 * Memory layout for management SoC
 */

MEMORY
{
    /* Management SoC Memory */
    rom (rx)  : ORIGIN = 0x00000000, LENGTH = 0x4000  /* 16KB ROM/Flash */
    ram (rwx) : ORIGIN = 0x00000800, LENGTH = 0x0800  /* 2KB SRAM */
    
    /* User SRAM (if using external SRAM) */
    user_sram (rwx) : ORIGIN = 0x30050000, LENGTH = 0x1000  /* 4KB User SRAM */
}

SECTIONS
{
    /* Code section */
    .text : {
        *(.text.start)
        *(.text*)
        . = ALIGN(4);
    } > rom
    
    /* Read-only data */
    .rodata : {
        *(.rodata*)
        . = ALIGN(4);
    } > rom
    
    /* Data section (initialized data) */
    .data : {
        __data_start = .;
        *(.data*)
        . = ALIGN(4);
        __data_end = .;
    } > ram AT > rom
    
    /* BSS section (uninitialized data) */
    .bss : {
        __bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        __bss_end = .;
    } > ram
    
    /* Stack */
    .stack : {
        . = ALIGN(8);
        __stack_bottom = .;
        . = . + 0x400;  /* 1KB stack */
        __stack_top = .;
    } > ram
    
    /* Heap (optional, for dynamic allocation) */
    .heap : {
        __heap_start = .;
        . = ORIGIN(ram) + LENGTH(ram) - SIZEOF(.data) - SIZEOF(.bss) - SIZEOF(.stack);
        __heap_end = .;
    } > ram
}

/* Entry point */
ENTRY(main)
