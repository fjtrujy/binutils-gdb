/* V850 ELF support for BFD.
   Copyright (C) 1997 Free Software Foundation, Inc.
   Created by Michael Meissner, Cygnus Support <meissner@cygnus.com>

This file is part of BFD, the Binary File Descriptor library.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

/* This file holds definitions specific to the MIPS ELF ABI.  Note
   that most of this is not actually implemented by BFD.  */

#ifndef _ELF_V850_H
#define _ELF_V850_H

/* Processor specific flags for the ELF header e_flags field.  */

/* Four bit V850 architecture field.  */
#define EF_V850_ARCH		0xf0000000

/* v850 code.  */
#define E_V850_ARCH		0x00000000

/* start-sanitize-v850e */
/* v850e code.  */
#define E_V850E_ARCH		0x10000000
/* end-sanitize-v850e */

/* start-sanitize-v850eq */
/* v850eq code.  */
#define E_V850EQ_ARCH		0x20000000
/* end-sanitize-v850eq */


/* Flags for the st_other field */
#define V850_OTHER_SDA		0x01	/* symbol had SDA relocations */
#define V850_OTHER_ZDA		0x02	/* symbol had ZDA relocations */
#define V850_OTHER_TDA		0x04	/* symbol had TDA relocations */
#define V850_OTHER_TDA_BYTE	0x08	/* symbol had TDA byte relocations */
#define V850_OTHER_ERROR	0x80	/* symbol had an error reported */

/* V850 relocations */
enum reloc_type
{
  R_V850_NONE = 0,
  R_V850_9_PCREL,
  R_V850_16_PCREL,
  R_V850_22_PCREL,
  R_V850_HI16_S,
  R_V850_HI16,
  R_V850_LO16,
  R_V850_32,
  R_V850_16,
  R_V850_8,
  R_V850_SDA_16_16_OFFSET,		/* For ld.b, st.b, set1, clr1, not1, tst1, movea, movhi */
  R_V850_SDA_15_16_OFFSET,		/* For ld.w, ld.h, ld.hu, st.w, st.h */
  R_V850_ZDA_16_16_OFFSET,		/* For ld.b, st.b, set1, clr1, not1, tst1, movea, movhi */
  R_V850_ZDA_15_16_OFFSET,		/* For ld.w, ld.h, ld.hu, st.w, st.h */
  R_V850_TDA_6_8_OFFSET,		/* For sst.w, sld.w */
  R_V850_TDA_7_8_OFFSET,		/* For sst.h, sld.h */
  R_V850_TDA_7_7_OFFSET,		/* For sst.b, sld.b */
/* start-sanitize-v850e */
  R_V850_TDA_4_5_OFFSET,		/* For sld.hu */
  R_V850_TDA_4_4_OFFSET,		/* For sld.bu */
  R_V850_SDA_16_16_SPLIT_OFFSET,	/* For ld.bu */
  R_V850_ZDA_16_16_SPLIT_OFFSET,	/* For ld.bu */
/* end-sanitize-v850e */
  R_V850_max
};

#endif /* _ELF_V850_H */
