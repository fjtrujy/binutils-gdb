# Link scripts for PlayStation 2 IRXs.

# NOTE: Limit parameter expansions to a single line.  Cygwin's /bin/sh has
# been freaking out when it reaches the end of a line, even when the text is
# being quoted.

test -z "$ENTRY" && ENTRY=_start

test -z "$TEXT_START_ADDR" && TEXT_START_ADDR="0x0000"

if test "x$LD_FLAG" = "xn" -o "x$LD_FLAG" = "xN"; then
  DATA_ADDR=.
else
  test -z "$DATA_ADDR" && DATA_ADDR=0x10000000
fi

# These variables are used to put braces in parameter expansions so that
# they expand properly.
LBRACE="{"
RBRACE="}"

cat <<EOF
/* Link script for PlayStation 2 IRXs
 * Written by Douglas C. Knight <fsdck@uaf.edu>
 */

OUTPUT_FORMAT("${OUTPUT_FORMAT}")

${RELOCATING+${LIB_SEARCH_DIRS}}

ENTRY(${ENTRY})
SECTIONS
{
  ${RELOCATING+/* This is the .iopmod section for the IRX, it contains}
  ${RELOCATING+   information that the IOP uses when loading the IRX.}
  ${RELOCATING+   This section is placed in its own segment.  */}
  ${RELOCATING+.iopmod : ${LBRACE}}
  ${RELOCATING+  /* The linker will replace this first LONG with a pointer}
  ${RELOCATING+     to _irx_id if the symbol has been defined.  */}
  ${RELOCATING+  LONG (0xffffffff) ;}
 
  ${RELOCATING+  LONG (_start) ;}
  ${RELOCATING+  LONG (_gp) ;}
  ${RELOCATING+  LONG (_text_size) ;}
  ${RELOCATING+  LONG (_data_size) ;}
  ${RELOCATING+  LONG (_bss_size) ;}
  ${RELOCATING+  /* The linker will put a SHORT here with the version of}
  ${RELOCATING+     the IRX (or zero if there is no version).  */}
  ${RELOCATING+  /* The linker will put a null terminated string here}
  ${RELOCATING+     containing the name of the IRX (or an empty string if}
  ${RELOCATING+     the name is not known).  */}
  ${RELOCATING+${RBRACE}}

  ${RELOCATING+. = ${TEXT_START_ADDR} ;}
  ${RELOCATING+_ftext = . ;}
  .text : {
    CREATE_OBJECT_SYMBOLS
    * ( .text )
    * ( .text.* )
    * ( .init )
    * ( .fini )
  } = 0
  ${RELOCATING+_etext  =  . ;}

  ${RELOCATING+. = ${DATA_ADDR} ;}
  ${RELOCATING+_fdata = . ;}
  .rodata : {
    * ( .rdata )
    * ( .rodata )
    * ( .rodata1 )
    * ( .rodata.* )
  } = 0

  .data : {
    * ( .data )
    * ( .data1 )
    * ( .data.* )
    ${CONSTRUCTING+CONSTRUCTORS}
  }

  ${RELOCATING+. = ALIGN(16) ;}
  ${RELOCATING+_gp = . + 0x8000 ;}

  .sdata : {
    * ( .lit8 )
    * ( .lit4 )
    * ( .sdata )
    * ( .sdata.* )
  }
  ${RELOCATING+_edata = . ;}

  ${RELOCATING+. = ALIGN(4) ;}
  ${RELOCATING+_fbss = . ;}
  .sbss : {
    * ( .sbss )
    * ( .scommon )
  }

  ${RELOCATING+_bss_start = . ;}
  .bss : {
    * ( .bss )
    * ( COMMON )
    ${RELOCATING+. = ALIGN(4) ;}
  }
  ${RELOCATING+_end = . ;}

  ${RELOCATING+_text_size = _etext - _ftext ;}
  ${RELOCATING+_data_size = _edata - _fdata ;}
  ${RELOCATING+_bss_size = _end - _fbss ;}

  /* These are the stuff that we don't want to be put in an IRX.  */
  /DISCARD/ : {
	* ( .MIPS.abiflags )
	* ( .gnu.attributes )
	* ( .comment )
	* ( .reginfo )
	* ( .mdebug.* )
	/* This must go because it confuses the IOP kernel (treated as a reloc section). */
	* ( .pdr )
	/* Until I can figure out if there's a better way to rid ourselves of .rel.dyn
	   this will have to do.  - MRB  */
	* ( .rel.dyn )
  }
}

EOF
