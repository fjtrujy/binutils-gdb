source_sh ${srcdir}/emulparams/elf32bmip.sh

OUTPUT_FORMAT="elf32-littlemips"
BIG_OUTPUT_FORMAT="elf32-bigmips"
LITTLE_OUTPUT_FORMAT="elf32-littlemips"

TEXT_START_ADDR=0x0100000
ARCH=mips:5900
MACHINE=
MAXPAGESIZE=128
EMBEDDED=yes
DYNAMIC_LINK=FALSE

unset DATA_ADDR
SHLIB_TEXT_START_ADDR=0
unset GENERATE_SHLIB_SCRIPT

OTHER_SYMBOLS='
  PROVIDE(_heap_size = -1);
  PROVIDE(_stack = -1);
  PROVIDE(_stack_size = 128 * 1024);
'
