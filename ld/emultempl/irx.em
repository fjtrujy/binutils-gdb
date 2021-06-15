fragment <<EOF
/* This file is is generated by a shell script.  DO NOT EDIT! */

/* IRX emulation code for ${EMULATION_NAME}
   Copyright (C) 1991, 1993 Free Software Foundation, Inc.
   Written by Steve Chamberlain steve@cygnus.com
   IRX support by Douglas C. Knight fsdck@uaf.edu

This file is part of GLD, the Gnu Linker.

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

EOF

source_em ${srcdir}/emultempl/mipself.em

cat >>e${EMULATION_NAME}.c <<EOF

static bfd_boolean building_irx;
static lang_output_section_statement_type *text_section_statement;
static lang_output_section_statement_type *iopmod_section_statement;

static lang_output_section_phdr_list default_phdr = {
  .name = " DEFAULT",
  .next = NULL,
  .used = FALSE
};
static lang_output_section_phdr_list irxhdr_phdr = {
  .name = " IRXHDR",
  .next = NULL,
  .used = FALSE
};
static lang_output_section_phdr_list none_phdr = {
  .name = "NONE",
  .next = NULL,
  .used = FALSE
};

/* This is called just before parsing the linker script.  It does some
   bfd configuration for irx filex, creates the irx program header,
   and adds an .iopmod output section to the statement list.  */

static void
irx_before_parse (void)
{
  gld${EMULATION_NAME}_before_parse();

  /* Only setup IRX headers for executable files.  */
  if (!bfd_link_relocatable (&link_info))
  {
    building_irx = TRUE;
    /* IRX files are dynamic.  They need their relocations.  */
    link_info.emitrelocations = TRUE;
    /* This isn't really needed, but I've never seen an IRX that's
      properly paged.  */
    config.magic_demand_paged = FALSE;
  
    /* The IRXHDR program header must be the first in the list of
      program headers.  By creating it here, before processing the
      linker script, it is always at the beginning of the list.  */
    lang_new_phdr (irxhdr_phdr.name, exp_intop (PT_MIPS_IRXHDR), FALSE,
        FALSE, NULL, exp_intop (PF_R));

    /* An .iopmod output section will be needed.  By creating the
      .iopmod section before parsing the linker script, the iopmod
      section statement will be placed at the top of the statement list
      after the *ABS* section, but before any other sections from the
      linker script.  The statements from the linker script can then be
      accessed through iopmod_section_statement->next.  */
      iopmod_section_statement = lang_output_section_statement_lookup (".iopmod", 0, TRUE);
  }else{
    building_irx = FALSE;
  }
}


/* irx_after_parse () is executed after the linker script has
   been parsed.  It puts the .iopmod output section into the IRXHDR
   segment.  If the linker script did not create any program headers
   of its own, this function also creates a PT_LOAD segment and puts
   all of the remaining sections in it.  */

static void
irx_after_parse (void)
{
  bfd_boolean linkscript_uses_phdrs;
  lang_output_section_statement_type *stat;

  after_parse_default ();

  /* Only setup IRX headers for executable files.  */
  if (building_irx)
  {
    /* Determine whether the link script assigned any sections to phdrs.  */

    /* FIXME: If none of the sections have been explicitly assigned to a
       segment, this function assumes that the linker script did not
       create any program headers.  This function should not put the
       sections in a new PT_LOAD segment if the linker script, for some
       odd reason, created program headers but did not assign any of the
       sections to any segments.  There is currently no way to tell
       whether the linker script created any program headers because the
       program header list is a static variable.  If there ever is any
       reason to create program headers, but have all of the sections
       remain segmentless, explicitly assign the first section in the
       linker script to the section "NONE". */

    linkscript_uses_phdrs = FALSE;
    for (stat = iopmod_section_statement->next; stat != NULL;
      stat = stat->next)
      if (stat->header.type == lang_output_section_statement_enum)
        if (stat->phdrs != NULL)
        {
          linkscript_uses_phdrs = TRUE;
          break;
        }

    if (! linkscript_uses_phdrs)
    {
      /* The linker script didn't use program headers, so build the
        default segment and put all of the sections in it.  */
      lang_new_phdr (default_phdr.name, exp_intop (PT_LOAD), FALSE,
        FALSE, NULL, exp_intop (PF_R | PF_W | PF_X));
      for (stat = iopmod_section_statement->next; stat != NULL;
        stat = stat->next)
      if (stat->header.type == lang_output_section_statement_enum)
        stat->phdrs = &default_phdr;
    }

    /* Add iopmod to the IRXHDR segment.  */
    irxhdr_phdr.next = iopmod_section_statement->phdrs;
    iopmod_section_statement->phdrs = &irxhdr_phdr;

    /* Keep IRXHDR from following through to following sections.  */
    for (stat = iopmod_section_statement->next; stat != NULL;
      stat = stat->next)
      if (stat->header.type == lang_output_section_statement_enum)
      {
        if (! stat->phdrs)
        {
          stat->phdrs = (irxhdr_phdr.next) ? irxhdr_phdr.next : &none_phdr;
        }
        break;
      }
  }
}

/* This is a macro to add a data statement of data type T and the data
   expression E to the end of the statement list LP.  */

#define new_data_stat(t,e,lp) {                         \
  lang_statement_union_type *d;                         \
  d = stat_alloc (sizeof (lang_data_statement_type));   \
  d->header.type = lang_data_statement_enum;            \
  d->header.next = NULL;                                \
  ((lang_data_statement_type *) d)->exp = e;            \
  ((lang_data_statement_type *) d)->type = t;           \
  *(lp->tail) = d;                                      \
  lp->tail = &d->header.next;                           \
}

/* Called after input files have been opened, and their symbols
   parsed.  If the .iopmod section is empty, construct a valid .iopmod
   structure.  If _irx_id is defined, it is used as the id structure to
   for this irx.  */

static void
irx_after_open (void)
{
  lang_statement_list_type *seg_stat_ptr;
  union lang_statement_union *stat_list_remainder;
  union lang_statement_union **stat_list_old_tail;
  struct bfd_link_hash_entry *h;
  bfd_vma irxname_pos;
  asection *irxname_sec;
  bfd_vma irxid_pos;
  asection *irxid_sec;
  int irx_version;
  char buf[64];
  bfd_boolean result;
  unsigned uit;
  asymbol **syms;
  arelent **rels;
  long size;
  long count;

  gld${EMULATION_NAME}_after_open();

  /* Only setup IRX headers for executable files.  */
  if (building_irx == FALSE)
    return;
  
  /* If the linker script didn't already start the .iopmod section,
     build the basics now.  */
  seg_stat_ptr = &iopmod_section_statement->children;
  if (seg_stat_ptr->head == NULL)
  {
    new_data_stat (LONG, exp_intop (0xffffffff), seg_stat_ptr);
    new_data_stat (LONG, exp_unop (ABSOLUTE, exp_nameop (NAME, "_start")),
      seg_stat_ptr);
    new_data_stat (LONG, exp_nameop (NAME, "_gp"), seg_stat_ptr);
    new_data_stat (LONG, exp_nameop (NAME, "_text_size"), seg_stat_ptr);
    new_data_stat (LONG, exp_nameop (NAME, "_data_size"), seg_stat_ptr);
    new_data_stat (LONG, exp_nameop (NAME, "_bss_size"), seg_stat_ptr);
    stat_list_old_tail = NULL;
  }
  else
  {
    /* If the linker script built an .iopmod section, make sure the
       first six data statments are LONGS, and that the first LONG
       is set to the int 0xffffffff.  If not, assume the linker
       script knows what it's doing, and leave everything alone.  */
    union lang_statement_union *stat_iter;
    stat_iter = seg_stat_ptr->head;
    /* Make sure the first satement is a LONG data statement with
       the value 0xffffffff.  */
    if (stat_iter->header.type != lang_data_statement_enum
      || stat_iter->data_statement.type != LONG
      || stat_iter->data_statement.exp->type.node_class != etree_value
      || stat_iter->data_statement.exp->type.node_code != INT
      || stat_iter->data_statement.exp->value.value != 0xffffffff)
        return;

    /* Make sure the next five statements are LONG data statements.  */
    stat_iter = stat_iter->header.next;
    if (stat_iter->header.type != lang_data_statement_enum
      || stat_iter->data_statement.type != LONG)
        return;
    stat_iter = stat_iter->header.next;
    if (stat_iter->header.type != lang_data_statement_enum
      || stat_iter->data_statement.type != LONG)
      return;
    stat_iter = stat_iter->header.next;
    if (stat_iter->header.type != lang_data_statement_enum
      || stat_iter->data_statement.type != LONG)
      return;
    stat_iter = stat_iter->header.next;
    if (stat_iter->header.type != lang_data_statement_enum
      || stat_iter->data_statement.type != LONG)
      return;
    stat_iter = stat_iter->header.next;
    if (stat_iter->header.type != lang_data_statement_enum
      || stat_iter->data_statement.type != LONG)
      return;
      
    /* Cut the statement list off after the six LONGs, so that new
       data can be inserted.  */
    stat_list_old_tail = seg_stat_ptr->tail;
    seg_stat_ptr->tail = &stat_iter->header.next;
    stat_list_remainder = stat_iter->header.next;
  }

  /* Look for an _irx_id symbol.  */
  h = bfd_link_hash_lookup (link_info.hash, "_irx_id", FALSE, FALSE, TRUE);
  if (h != NULL)
    if (h->type != bfd_link_hash_defined && h->type != bfd_link_hash_defweak)
      h = NULL;

  /* If _irx_id is undefined.  Set the IRX version to 0.0 and name to
     an empty string.  */
  if (h == NULL)
  {
    new_data_stat (SHORT, exp_intop (0x0), seg_stat_ptr);
    new_data_stat (BYTE, exp_intop (0x0), seg_stat_ptr);
    goto eout;
  }

  /* Retrieve the contents of _irx_id.  */
  irxid_pos = h->u.def.value;
  irxid_sec = h->u.def.section;
  result = bfd_get_section_contents (irxid_sec->owner,
             irxid_sec, buf,
             irxid_pos, 8);
  if (! result)
  {
    einfo ("%F%P: could not read the contents of _irx_id from %E\n",
     irxid_sec->owner);
    goto eout;
  }

  /* Extract the version number, and a pointer to the irx name.  */
  irxname_pos = bfd_get_32 (irxid_sec->owner, &buf[0]);
  irx_version = bfd_get_16 (irxid_sec->owner, &buf[4]);

  /* Things get really ugly here.  The contents of the symbol table
     and relocations are already in memory in the bfd's elf backend,
     after calling the canonicalize functions there are two copies in
     memory, one in the backends own format, and one in bfd's standard
     format.  This could be a waste of memory, but we need to follow
     the relocations, and digging through the backend's data would be
     even uglier.  */

  /* Canonicalize the symbol table for the bfd contaning _irx_id.  */
  size = bfd_get_symtab_upper_bound (irxid_sec->owner);
  if (size < 0)
  {
    einfo ("%F%P: could not read symbols from %E\n", irxid_sec->owner);
    goto eout;
  }
  syms = xmalloc (size);
  count = bfd_canonicalize_symtab (irxid_sec->owner, syms);
  if (count < 0)
  {
    einfo ("%F%P: could not read symbols from %E\n",
     irxid_sec->owner);
    goto eout;
  }
  
  /* Canonicalize the relocations for the section containing _irx_id.  */
  size = bfd_get_reloc_upper_bound (irxid_sec->owner, irxid_sec);
  if (size < 0)
  {
    einfo ("%F%P: could not read relocations from %E\n", irxid_sec->owner);
    free (syms);
    goto eout;
  }
  rels = xmalloc (size);
  count = bfd_canonicalize_reloc (irxid_sec->owner, irxid_sec, rels, syms);
  if (count < 0)
  {
    einfo ("%F%P: could not read relocations from %E\n", irxid_sec->owner);
    free (syms);
    goto eout;
  }

  /* Find the relocation for the irx name pointer in _irx_id, and
     extract the section that the irx name is stored in from it.  */
  irxname_sec = NULL;
  for (uit = 0; uit < count; ++uit)
  {
    arelent *r;
    r = rels[uit];
    if (r->address == irxid_pos)
    {
      if ((*r->sym_ptr_ptr)->flags & (BSF_OBJECT | BSF_FUNCTION
            | BSF_SECTION_SYM))
        irxname_sec = (*r->sym_ptr_ptr)->section;
      else
      {
        /* The irx name is not in the same bfd, but we know what
         the symbol is called now, so we can look for it in
         the other bfds.  */
        h = bfd_link_hash_lookup (link_info.hash,
          (*r->sym_ptr_ptr)->name, FALSE,
          FALSE, TRUE);
        if (h != NULL)
        {
          irxname_pos = h->u.def.value;
          irxname_sec = h->u.def.section;
        }
      }
    }
  }

  /* Release what little memory we can.  */
  free (rels);
  free (syms);
  
  if (irxname_sec == NULL)
  {
    einfo ("%F%P: failed to resolve the irx name\n");
    goto eout;
  }

  /* Retrieve up to 63 bytes of the the contents of the irx name.  */
  count = irxname_sec->size;
  count -= irxname_pos;
  if (count > 63)
    count = 63;
  buf[count] = 0;
  result = bfd_get_section_contents (irxname_sec->owner,
             irxname_sec, buf,
             irxname_pos, count);
  if (! result)
  {
    einfo ("%F%P: failed to resolve the irx name\n");
    goto eout;
  }

  /* Set the first LONG in the .iopmod section to the address of the
     _irx_id structure.  */
  seg_stat_ptr->head->data_statement.exp =
    exp_unop (ABSOLUTE, exp_nameop (NAME, "_irx_id"));
  /* Add the version number to the header.  */
  new_data_stat (SHORT, exp_intop (irx_version), seg_stat_ptr);
  /* Add each byte of the IRX name to the header.  FIXME: If the name
     is long and the linker script already has a lot of statements in
     it, the linker could run out of space in the parse tree.  This
     data could be added to the linker script as LONGs, and a SHORT,
     and/or a BYTE to save tree nodes.  */
  for (uit = 0; (uit < 64) && (buf[uit] != 0); ++uit)
    new_data_stat (BYTE, exp_intop ((unsigned int) buf[uit]), seg_stat_ptr);
  /* Tack a null on to the end of the string.  */
  new_data_stat (BYTE, exp_intop (0x0), seg_stat_ptr);

eout:
  /* Put anything that was cut off the end of the .iopmod section back
     on.  */
  if (stat_list_old_tail != NULL)
  {
    *seg_stat_ptr->tail = stat_list_remainder;
    seg_stat_ptr->tail = stat_list_old_tail;
  }
}

/* Called before creating the output sections in the output bfd.
   Since the .iopmod section's data is completely generated, it
   doesn't have any alignment attributes associated with it.  Force
   the iopmod section to be word aligned.  */

static void
irx_before_allocation (void)
{
  /* Only setup IRX headers for executable files.  */
  if (building_irx)
  {
    if (iopmod_section_statement->bfd_section->alignment_power < 2)
      iopmod_section_statement->bfd_section->alignment_power = 2;
  }

  mips_before_allocation();
}

/* Called after the output sections have been created.  Makes the
   .iopmod section exist in the file image, but not in the memory
   image by marking it as a loaded section, but not allocated.  */

static void
irx_after_allocation (void)
{
  /* Only setup IRX headers for executable files.  */
  if (building_irx)
  {
    iopmod_section_statement->bfd_section->flags |= SEC_LOAD;
    iopmod_section_statement->bfd_section->flags &= ~SEC_ALLOC;
  }

  gld${EMULATION_NAME}_after_allocation();
}

EOF

LDEMUL_BEFORE_PARSE=irx_before_parse
LDEMUL_AFTER_PARSE=irx_after_parse
LDEMUL_AFTER_OPEN=irx_after_open
LDEMUL_AFTER_ALLOCATION=irx_after_allocation
LDEMUL_BEFORE_ALLOCATION=irx_before_allocation