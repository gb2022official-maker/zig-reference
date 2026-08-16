OUTPUT_ARCH(riscv)
ENTRY(_start)

PHDRS {
  text PT_LOAD FLAGS(5);
  rodata PT_LOAD FLAGS(4);
  data PT_LOAD FLAGS(6);
  reservation PT_LOAD FLAGS(6);
  caller_artifact PT_LOAD FLAGS(4);
}

SECTIONS {
  . = 0x80200000;
  __image_begin = .;
  __text_domain_begin = .;
  .text : {
    *(.text.entry)
    . = ALIGN(4);
    *(.text.usertrap)
    . = ALIGN(4);
    *(.text.user_service_trap)
    . = ALIGN(4);
    *(.text.enteruser)
    . = ALIGN(4);
    *(.text.trap)
    *(.text .text.*)
  } :text
  . = ALIGN(4096);
  __text_domain_end = .;
  __rodata_domain_begin = .;
  .rodata : { *(.rodata .rodata.* .srodata .srodata.*) } :rodata
  . = ALIGN(4096);
  __rodata_domain_end = .;
  __writable_domain_begin = .;
  .data : { *(.data .data.*) } :data
  .bss (NOLOAD) : {
    /* Keep small-data BSS in the ordinary identity-mapped kernel image.
       Otherwise the orphan .sbss section follows the distant prepared-image
       reservation and is not covered by the reservation's explicit mapping. */
    *(.bss .bss.* .sbss .sbss.* COMMON)
    . = ALIGN(16);
    __stack_bottom = .;
    . += 60K;
    __supervisor_stack_top = .;
    __user_trap_stack_begin = .;
    /* Real file/ELF syscall composition has deeper bounded call chains than
       the original register-only probe. Keep a distinct supervisor-only
       trap stack and make its bound explicit rather than overflowing it. */
    . += 64K;
    __user_trap_stack_end = .;
    __user_trap_stack_top = .;
    __stack_top = .;
  } :data
  .physical_page_pool (NOLOAD) : ALIGN(4096) {
    __physical_page_pool_begin = .;
    . += 8 * 4096;
    __physical_page_pool_end = .;
  } :data
  __writable_domain_end = .;
  __image_end = .;

  /* Replaceable machine-policy storage, deliberately outside the ordinary
     kernel image and the inherited 0x80400000 fixture window. */
  . = 0x80600000;
  .prepared_image_reservation (NOLOAD) : ALIGN(4096) {
    __prepared_image_reservation_begin = .;
    *(.prepared_image_reservation)
    __prepared_image_reservation_end = .;
  } :reservation

  /* Caller-provided ELF bytes are transport input, not part of the ordinary
     kernel image. The fixed reservation is bounded and mapped supervisor-RO. */
  . = 0x83000000;
  .caller_artifact : ALIGN(4096) {
    __caller_artifact_begin = .;
    KEEP(*(.caller_artifact))
    . = ALIGN(4096);
    __caller_artifact_end = .;
  } :caller_artifact
  ASSERT(SIZEOF(.caller_artifact) <= 8M, "caller artifact transport capacity exceeded")
  ASSERT(__caller_artifact_begin >= __prepared_image_reservation_end, "caller artifact overlaps prepared image reservation")
}
