    .text
    .even
    .extern mp_colsets
    .extern mp_log2_lut
    .global mp_read_bits
    .extern mp_read_bits
    .global mp_unpack_sim_readmaps //mp_unpack_sim b1
    .global mp_tile_copy //mp_unpack_sim b2
    .global mp_unpack_sim_row //mp_unpack_sim b3
    .global mp_unpack_linerep_readmaps // mp_unpack_linerep b1
    .global mp_linerep_row0 // mp_unpack_linerep b2
    .global mp_linerep_rows1to7 // mp_unpack_linerep b3
    .global mp_parse_header //unpack b1
    .global mp_process_tiles //unpack b2
    .global mp_get_stream
    .global mp_unpack_linerep
    .global mp_unpack_sim

mp_read_bits:
    movem.l d2-d3,-(sp)

    move.l  12(sp),a0           // a0 = s
    move.l  16(sp),d2           // d2 = num_bits
    move.l  (a0),d1             // d1 = s->cmp
    move.l  4(a0),a1            // a1 = s->src

    tst.b   8(a0)
    bne.b   .Lrb_has_bits

    moveq   #0,d1
    move.w  (a1)+,d1            // WORD-ALIGNED REFILL
    swap    d1
    move.b  #16,8(a0)

.Lrb_has_bits:
    cmp.b   8(a0),d2
    bhi.b   .Lrb_two

    move.l  d1,d3
    lsl.l   d2,d1
    moveq   #32,d0
    sub.l   d2,d0
    lsr.l   d0,d3

    sub.b   d2,8(a0)
    move.l  d1,(a0)
    move.l  a1,4(a0)
    move.l  d3,d0

    movem.l (sp)+,d2-d3
    rts

.Lrb_two:
    moveq   #0,d0
    move.b  8(a0),d0

    moveq   #32,d3
    sub.l   d0,d3
    lsr.l   d3,d1

    sub.l   d0,d2
    lsl.l   d2,d1

    moveq   #0,d0
    move.w  (a1)+,d0            //  WORD-ALIGNED REFILL
    swap    d0

    move.l  d0,-(sp)
    moveq   #32,d3
    sub.l   d2,d3
    lsr.l   d3,d0
    or.l    d0,d1

    move.l  (sp)+,d0
    lsl.l   d2,d0

    moveq   #16,d3
    sub.l   d2,d3

    move.l  d0,(a0)
    move.b  d3,8(a0)
    move.l  a1,4(a0)
    move.l  d1,d0

    movem.l (sp)+,d2-d3
    rts

mp_pixstream:
    movem.l d2-d4,-(sp)

    move.l  16(sp),a0
    move.l  20(sp),d0

    moveq   #0,d2
    moveq   #0,d3
    move.b  d0,d2                 // d2 = lo
    lsr.w   #8,d0
    move.b  d0,d3                 // d3 = hi

    lea     mp_bitcount,a1        // sem (pc)
    moveq   #0,d4
    move.b  (a1,d2.w),d4          // d4 = loc
    move.b  (a1,d3.w),d0
    add.b   d4,d0                  // d0 = n

    move.l  d0,-(sp)
    move.l  a0,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp

    cmp.w   d4,d0
    bhs.b   .Lpix_hi

    lea     mp_nth_set_bit,a0     // sem (pc)
    lsl.w   #3,d2
    add.w   d0,d2
    move.b  (a0,d2.w),d0
    movem.l (sp)+,d2-d4
    rts

.Lpix_hi:
    lea     mp_nth_set_bit,a0     // sem (pc)
    sub.w   d4,d0
    lsl.w   #3,d3
    add.w   d0,d3
    move.b  (a0,d3.w),d0
    addq.b  #8,d0
    movem.l (sp)+,d2-d4
    rts



// ════════════════════════════════════════════════════════
//  mp_unpack_sim_readmaps — rb(1) INLINED (4×)
// ════════════════════════════════════════════════════════

mp_unpack_sim_readmaps:
    movem.l d2-d3/a2,-(sp)
    move.l  16(sp),a2

    moveq   #0,d2

    // rb(1) #1
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ls_rb1
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ls_rb1:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .Lv1

    move.l  #0x0F,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eor.b   #0x0F,d0
    lsl.b   #4,d0
    move.b  d0,d2
.Lv1:

    // rb(1) #2
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ls_rb2
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ls_rb2:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .Lv2

    or.b    #0x0F,d2
    move.l  #0x0F,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eor.b   d0,d2
.Lv2:

    moveq   #0,d3

    // rb(1) #3
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ls_rb3
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ls_rb3:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .Lh1

    move.l  #0x0F,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eori.b  #0x0F,d0
    lsl.b   #4,d0
    move.b  d0,d3
.Lh1:

    // rb(1) #4
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ls_rb4
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ls_rb4:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .Lh2

    or.b    #0x0F,d3
    move.l  #0x0F,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eor.b   d0,d3
.Lh2:

    moveq   #0,d0
    move.b  d3,d0
    lsl.w   #8,d0
    or.b    d2,d0

    movem.l (sp)+,d2-d3/a2
    rts

mp_tile_copy:
    move.l  4(sp),a0              // a0 = tile_i
    move.l  8(sp),a1              // a1 = tile_ref

    movem.l (a1),d0-d7            // carrega 32 bytes (8 longwords)
    movem.l d0-d7,(a0)            // armazena 32 bytes
    rts

// ════════════════════════════════════════════════════════
//  mp_unpack_sim_row — rb(1) como CHAMADA EXTERNA
// ════════════════════════════════════════════════════════

mp_unpack_sim_row:
    movem.l d2-d7/a2-a4,-(sp)

    move.l  40(sp),a2
    move.l  44(sp),a3
    move.l  48(sp),a4
    moveq   #0,d3
    move.b  55(sp),d3
    move.l  d3,d2
    move.l  56(sp),d5
    move.l  60(sp),d4

    tst.l   d5
    bne.w   .Ldecode_pixels
    moveq   #7,d5

.Lrefine_loop:
    move.b  d2,d0
    not.b   d0
    beq.w   .Ldecode_pixels
    move.b  d0,d6
    subq.b  #1,d6
    and.b   d0,d6
    beq.w   .Ldecode_pixels
    btst    d5,d3
    bne.b   .Lrefine_next

    // * rb(1) INLINE
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Lsr_rb
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Lsr_rb:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .Lrefine_next
    bset    d5,d2

.Lrefine_next:
    subq.b  #1,d5
    bpl.b   .Lrefine_loop

.Ldecode_pixels:
    // Byte 0 (chamadas externas — sem alteração)
    move.b  (a4)+,d3
    move.b  d3,d5
    lsr.b   #4,d5
    andi.b  #0x0F,d3

    btst    #7,d2
    beq.b   .Lb0_pe
    move.b  d5,d6
    bra.b   .Lb0_pe_x
.Lb0_pe:
    move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b0pe_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b0pe_end
.Lpx_b0pe_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b0pe_end:
    move.b  d0,d6
.Lb0_pe_x:
    btst    #6,d2
    beq.b   .Lb0_po
    move.b  d3,d7
    bra.b   .Lb0_po_x
.Lb0_po:
    move.l  d4,d0
    bclr    d3,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b0po_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b0po_end
.Lpx_b0po_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b0po_end:
    move.b  d0,d7
.Lb0_po_x:
    lsl.b   #4,d6
    or.b    d7,d6
    move.b  d6,(a3)+

    // Byte 1
    move.b  (a4)+,d3
    move.b  d3,d5
    lsr.b   #4,d5
    andi.b  #0x0F,d3
   btst    #5,d2
    beq.b   .Lb1_pe
    move.b  d5,d6
    bra.b   .Lb1_pe_x
.Lb1_pe:
    move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b1pe_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b1pe_end
.Lpx_b1pe_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b1pe_end:
    move.b  d0,d6
.Lb1_pe_x:
    btst    #4,d2
    beq.b   .Lb1_po
    move.b  d3,d7
    bra.b   .Lb1_po_x
.Lb1_po:
    move.l  d4,d0
    bclr    d3,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b1po_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b1po_end
.Lpx_b1po_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b1po_end:
    move.b  d0,d7
.Lb1_po_x:
    lsl.b   #4,d6
    or.b    d7,d6
    move.b  d6,(a3)+

    // Byte 2
    move.b  (a4)+,d3
    move.b  d3,d5
    lsr.b   #4,d5
    andi.b  #0x0F,d3
    btst    #3,d2
    beq.b   .Lb2_pe
    move.b  d5,d6
    bra.b   .Lb2_pe_x
.Lb2_pe:
    move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b2pe_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b2pe_end
.Lpx_b2pe_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b2pe_end:
    move.b  d0,d6
.Lb2_pe_x:
    btst    #2,d2
    beq.b   .Lb2_po
    move.b  d3,d7
    bra.b   .Lb2_po_x
.Lb2_po:
    move.l  d4,d0
    bclr    d3,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b2po_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b2po_end
.Lpx_b2po_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b2po_end:
    move.b  d0,d7
.Lb2_po_x:
    lsl.b   #4,d6
    or.b    d7,d6
    move.b  d6,(a3)+

    // Byte 3
    move.b  (a4)+,d3
    move.b  d3,d5
    lsr.b   #4,d5
    andi.b  #0x0F,d3
    btst    #1,d2
    beq.b   .Lb3_pe
    move.b  d5,d6
    bra.b   .Lb3_pe_x
.Lb3_pe:
    move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b3pe_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b3pe_end
.Lpx_b3pe_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b3pe_end:
    move.b  d0,d6
.Lb3_pe_x:
    btst    #0,d2
    beq.b   .Lb3_po
    move.b  d3,d7
    bra.b   .Lb3_po_x
.Lb3_po:
    move.l  d4,d0
    bclr    d3,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_b3po_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_b3po_end
.Lpx_b3po_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_b3po_end:
    move.b  d0,d7
.Lb3_po_x:
    lsl.b   #4,d6
    or.b    d7,d6
    move.b  d6,(a3)+

    movem.l (sp)+,d2-d7/a2-a4
    rts

// ════════════════════════════════════════════════════════
//  mp_unpack_linerep_readmaps — rb(1) INLINED (4×)
//  ORDEM: hmap PRIMEIRO, vmap SEGUNDO
// ════════════════════════════════════════════════════════

mp_unpack_linerep_readmaps:
    movem.l d2-d3/a2,-(sp)
    move.l  16(sp),a2

    // ══ hmap (d3) — PRIMEIRO ══
    moveq   #0,d3

    // rb(1) #1
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ll_rb1
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ll_rb1:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .LLh1

    move.l  #0x0F,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eori.b  #0x0F,d0
    lsl.b   #3,d0
    move.b  d0,d3
.LLh1:

    // rb(1) #2
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ll_rb2
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ll_rb2:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .LLh2

    or.b    #7,d3
    move.l  #7,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eor.b   d0,d3
.LLh2:

    btst    #3,d3
    beq.b   .LLh_post
    eor.b   #7,d3
.LLh_post:

    // ══ vmap (d2) — SEGUNDO ══
    moveq   #0,d2

    // rb(1) #3
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ll_rb3
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ll_rb3:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .LLv1

    move.l  #0x0F,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eori.b  #0x0F,d0
    lsl.b   #3,d0
    move.b  d0,d2
.LLv1:

    // rb(1) #4
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Ll_rb4
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Ll_rb4:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .LLv2

    or.b    #7,d2
    move.l  #7,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    eor.b   d0,d2
.LLv2:

    btst    #3,d2
    beq.b   .LLv_post
    eor.b   #7,d2
.LLv_post:

    moveq   #0,d0
    move.b  d3,d0
    lsl.w   #8,d0
    or.b    d2,d0

    movem.l (sp)+,d2-d3/a2
    rts

// ════════════════════════════════════════════════════════
//  mp_linerep_row0 — rb(1) como CHAMADA EXTERNA
// ════════════════════════════════════════════════════════

 mp_linerep_row0:
    movem.l d2-d7/a2-a3,-(sp)

    move.l  36(sp),a2
    move.l  40(sp),a3
    move.b  47(sp),d2
    move.l  48(sp),d3

        // Col 0: pixstream inline
    moveq   #0,d1
    move.b  d3,d1                   // d1 = lo byte de pixels
    move.w  d3,d0
    lsr.w   #8,d0                   // d0 = hi byte de pixels
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1            // d1 = loc = bitcount(lo)
    move.b  (a0,d0.w),d0            // d0 = bitcount(hi)
    add.b   d1,d0                   // d0 = n = loc + bitcount(hi)
    move.w  d1,-(sp)                // salva loc

    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp                   // d0 = index

    move.w  (sp)+,d1                // d1 = loc
    cmp.w   d1,d0
    bhs.b   .Lpx_lr0_hi

    lea     mp_nth_set_bit,a0
    move.w  d3,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_lr0_end

.Lpx_lr0_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  d3,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0

.Lpx_lr0_end:
    move.b  d0,d4
    move.b  d0,d6
    lsl.b   #4,d6

    moveq   #1,d7

.ALcol_loop:
    moveq   #7,d5
    sub.b   d7,d5
    btst    d5,d2
    beq.b   .ALcol_rb
    move.b  d4,d5
    bra   .ALcol_store

.ALcol_rb:
    // * rb(1) INLINE (mantém como está)
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Alr_rb
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Alr_rb:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .ALcol_copy

    // * mp_mpixstream INLINE (era chamada externa)
    move.l  d3,d0
    bclr    d4,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_alrb_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_alrb_end
.Lpx_alrb_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_alrb_end:
    move.b  d0,d5
    bra.b   .ALcol_store

.ALcol_copy:
    move.b  d4,d5

.ALcol_store:
    move.b  d5,d4

    btst    #0,d7
    beq.b   .ALstore_hi
    or.b    d5,d6
    move.b  d6,(a3)+
    bra.b   .ALcol_next
.ALstore_hi:
    move.b  d5,d6
    lsl.b   #4,d6

.ALcol_next:
    addq.b  #1,d7
    cmp.b   #8,d7
    bcs   .ALcol_loop

    movem.l (sp)+,d2-d7/a2-a3
    rts

// ════════════════════════════════════════════════════════
//  mp_linerep_rows1to7 — rb(1) como CHAMADAS EXTERNAS
//  * Labels .LR prefixados para evitar colisão
// ════════════════════════════════════════════════════════

mp_linerep_rows1to7:
    movem.l d2-d7/a2-a4,-(sp)
    subq.l  #4,sp

    move.l  44(sp),a2
    move.l  48(sp),a3
    moveq   #0,d2
    move.b  55(sp),d2
    moveq   #0,d3
    move.b  59(sp),d3
    moveq   #0,d4
    move.w  62(sp),d4

    moveq   #1,d6
    move.l  #6,(sp)

.LRouter:
    move.l  (sp),d0
    bmi.w   .LRdone

    btst    d0,d2
    beq.b   .LRdecode_row

    moveq   #6,d1
    sub.l   d0,d1
    lsl.l   #2,d1
    move.l  a3,a0
    add.l   d1,a0
    move.l  (a0),d0
    move.l  d0,4(a0)
    bra.w   .LRnext_row

.LRdecode_row:
    moveq   #6,d1
    sub.l   d0,d1
    lsl.l   #2,d1
    move.l  a3,a4
    add.l   d1,a4

    move.b  (a4),d5
    lsr.b   #4,d5

    // * rb(1) INLINE — col 0
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Lrr_rb_c0
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Lrr_rb_c0:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .LRc0_copy

    move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_lrc0_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_lrc0_end
.Lpx_lrc0_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_lrc0_end:
    move.b  d0,d5

.LRc0_copy:
    move.b  d5,d0
    lsl.b   #4,d0
    move.b  4(a4),d1
    andi.b  #0x0F,d1
    or.b    d0,d1
    move.b  d1,4(a4)

    moveq   #6,d7

.LRinner:
    btst    d7,d3
    beq.b   .LRnvm
    move.b  d5,d0
    bra.w   .LRstore

.LRnvm:
    tst.b   d6
    beq.w   .LRnpref

    // ══ VPREF = 1 ══

    // * rb(1) INLINE — vpref bit0
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Lrr_rb_vp1
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Lrr_rb_vp1:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq   .LRvp_copy

    bsr     .LRcalc_above
    cmp.b   d5,d0
    bne.b   .LRvp_neq

 move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_lrvp_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra     .LRstore
.Lpx_lrvp_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
    bra     .LRstore

.LRvp_neq:
    move.l  d0,-(sp)              // push above

    // * rb(1) INLINE — vpref bit1
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Lrr_rb_vp2
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Lrr_rb_vp2:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1                    // d1 = bit (0 ou 1)

    // * CORREÇÃO: pop above em d0, testa d1 explicitamente
    move.l  (sp)+,d0              // d0 = above
    tst.b   d1                    // * testa bit explicitamente
    beq.b   .LRvp_b1_0

    // bit1=1: pixstream(s, base & ~(1<<above) & ~(1<<left))
    move.l  d4,d1                 // d1 = base_pixels
    bclr    d0,d1                 // d1 &= ~(1 << above)
    bclr    d5,d1                 // d1 &= ~(1 << left)
    move.w  d1,-(sp)
    moveq   #0,d0
    move.b  d1,d0
    lsr.w   #8,d1
    lea     mp_bitcount,a0
    move.b  (a0,d0.w),d0
    move.b  (a0,d1.w),d1
    add.b   d0,d1
    move.w  d0,-(sp)
    move.l  d1,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_lr7vp_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra.b   .Lpx_lr7vp_end
.Lpx_lr7vp_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
.Lpx_lr7vp_end:
    bra     .LRstore

.LRvp_b1_0:
    // bit1=0: vpref=0, pix=above
    moveq   #0,d6                 // vpref = 0
    // d0 já contém above (do move.l (sp)+,d0)
    bra   .LRstore

.LRvp_copy:
    move.b  d5,d0
    bra   .LRstore

    // ══ VPREF = 0 ══
.LRnpref:

    // * rb(1) INLINE — npref bit0
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Lrr_rb_np1
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Lrr_rb_np1:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    bne.b   .LRnp_rb1

    bsr     .LRcalc_above
    bra   .LRstore

.LRnp_rb1:
    bsr     .LRcalc_above
    cmp.b   d5,d0
    bne     .LRnp_neq

    move.l  d4,d0
    bclr    d5,d0
    move.w  d0,-(sp)
    moveq   #0,d1
    move.b  d0,d1
    lsr.w   #8,d0
    lea     mp_bitcount,a0
    move.b  (a0,d1.w),d1
    move.b  (a0,d0.w),d0
    add.b   d1,d0
    move.w  d1,-(sp)
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_lrnp_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra     .LRstore
.Lpx_lrnp_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
    bra     .LRstore

.LRnp_neq:
    move.l  d0,-(sp)              // push above

    // * rb(1) INLINE — npref bit1
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Lrr_rb_np2
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Lrr_rb_np2:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1                    // d1 = bit (0 ou 1)

    // * CORREÇÃO: pop above em d0, testa d1 explicitamente
    move.l  (sp)+,d0              // d0 = above
    tst.b   d1                    // * testa bit explicitamente
    beq.b   .LRnp_b1_0

    // bit1=1: pixstream(s, base & ~(1<<above) & ~(1<<left))
    move.l  d4,d1
    bclr    d0,d1
    bclr    d5,d1
    move.w  d1,-(sp)
    moveq   #0,d0
    move.b  d1,d0
    lsr.w   #8,d1
    lea     mp_bitcount,a0
    move.b  (a0,d0.w),d0
    move.b  (a0,d1.w),d1
    add.b   d0,d1
    move.w  d0,-(sp)
    move.l  d1,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.w  (sp)+,d1
    cmp.w   d1,d0
    bhs.b   .Lpx_lrnp2_hi
    lea     mp_nth_set_bit,a0
    move.w  (sp)+,d1
    andi.w  #0xFF,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    bra     .LRstore
.Lpx_lrnp2_hi:
    lea     mp_nth_set_bit,a0
    sub.w   d1,d0
    move.w  (sp)+,d1
    lsr.w   #8,d1
    lsl.w   #3,d1
    add.w   d0,d1
    move.b  (a0,d1.w),d0
    addq.b  #8,d0
    bra     .LRstore

.LRnp_b1_0:
    // bit1=0: vpref=1, pix=left
    moveq   #1,d6                 // vpref = 1
    move.b  d5,d0                 // d0 = left_pixel
    // fall through

.LRstore:
    move.b  d0,d5                 // left_pixel = pix

    moveq   #7,d1
    sub.b   d7,d1
    move.b  d1,d0
    lsr.b   #1,d0
    lea     4(a4),a0
    adda.w  d0,a0

    btst    #0,d1
    beq.b   .LRstore_even
    move.b  (a0),d0
    andi.b  #0xF0,d0
    or.b    d5,d0
    move.b  d0,(a0)
    bra.b   .LRstore_done
.LRstore_even:
    move.b  d5,d0
    lsl.b   #4,d0
    move.b  (a0),d1
    andi.b  #0x0F,d1
    or.b    d0,d1
    move.b  d1,(a0)
.LRstore_done:
    subq.b  #1,d7
    bpl.w   .LRinner

.LRnext_row:
    subq.l  #1,(sp)
    bra.w   .LRouter

.LRdone:
    addq.l  #4,sp
    movem.l (sp)+,d2-d7/a2-a4
    rts

.LRcalc_above:
    moveq   #7,d0
    sub.b   d7,d0
    move.b  d0,d1
    lsr.b   #1,d0
    move.b  (a4,d0.w),d0
    btst    #0,d1
    beq.b   .LRca_hi
    andi.b  #0x0F,d0
    rts
.LRca_hi:
    lsr.b   #4,d0
    rts
// ════════════════════════════════════════════════════════
//  mp_parse_header — rb(1) como CHAMADA EXTERNA
// ════════════════════════════════════════════════════════

mp_parse_header:
    movem.l d2-d6/a2,-(sp)
    move.l  28(sp),a2

    // rb(8) — chamada externa (justificado: num_bits != 1)
    move.l  #8,-(sp)
    move.l  a2,-(sp)
    jsr     mp_read_bits
    addq.l  #8,sp
    move.l  d0,d2

    // rb(2) — chamada externa
    move.l  #2,-(sp)
    move.l  a2,-(sp)
    jsr     mp_read_bits
    addq.l  #8,sp
    lsl.l   #8,d0
    or.l    d0,d2

    // set_nums
    move.l  d2,d0
    cmp.l   #512,d0
    bls.b   .KBLsr_ok
    move.l  #512,d0
.KBLsr_ok:
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.l  d0,d4

    // rb(16) — chamada externa
    move.l  #16,-(sp)
    move.l  a2,-(sp)
    jsr     mp_read_bits
    addq.l  #8,sp
    lea     mp_colsets,a0
    move.w  d0,(a0)

    moveq   #1,d3
    moveq   #0,d5
    tst.l   d4
    beq.w   .KBLcs_done

.KBLcs_loop:
    // * rb(1) INLINE — decide caminho
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Kph_rb1
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Kph_rb1:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    beq.b   .KBLcs_else

    // rb(16) — chamada externa
    move.l  #16,-(sp)
    move.l  a2,-(sp)
    jsr     mp_read_bits
    addq.l  #8,sp
    lea     mp_colsets,a0
    move.l  d3,d1
    lsl.l   #1,d1
    move.w  d0,0(a0,d1.l)
    addq.l  #1,d3
    bra.b   .KBLcs_next

.KBLcs_else:
    move.l  d3,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp

    move.l  d3,d1
    sub.l   d0,d1
    subq.l  #1,d1

    lea     mp_colsets,a0
    lsl.l   #1,d1
    move.w  0(a0,d1.l),d6

    // rb(4) — chamada externa
    move.l  #4,-(sp)
    move.l  a2,-(sp)
    jsr     mp_read_bits
    addq.l  #8,sp
    moveq   #1,d1
    lsl.l   d0,d1
    eor.w   d1,d6

    lea     mp_colsets,a0
    move.l  d3,d1
    lsl.l   #1,d1
    move.w  d6,0(a0,d1.l)
    addq.l  #1,d3

.KBLcs_next:
    addq.l  #1,d5
    cmp.l   d4,d5
    bcs.w   .KBLcs_loop

.KBLcs_done:
    move.l  d2,d0
    movem.l (sp)+,d2-d6/a2
    rts

// ════════════════════════════════════════════════════════
//  mp_process_tiles — rb(1) como CHAMADA EXTERNA
// ════════════════════════════════════════════════════════

mp_process_tiles:
    movem.l d2-d6/a2-a3,-(sp)

    move.l  32(sp),a2
    move.l  36(sp),a3
    move.l  40(sp),d2
    moveq   #0,d3
    moveq   #0,d4

    tst.l   d2
    beq.w   .KBLpt_done

.KBLpt_loop:
    move.l  d4,d0
    addq.l  #1,d0
    move.l  d0,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp

    tst.l   d0
    bne.b   .KBLpt_idx_nz
    move.l  d4,d6
    addq.l  #1,d4
    bra.b   .KBLpt_have_idx
.KBLpt_idx_nz:
    move.l  d4,d6
    sub.l   d0,d6
.KBLpt_have_idx:

    lea     mp_colsets,a0
    move.l  d6,d0
    lsl.l   #1,d0
    move.w  0(a0,d0.l),d5

    // * rb(1) INLINE — decide sim/linerep
    move.l  (a2),d0
    tst.b   8(a2)
    bne.b   .Kpt_rb1
    move.l  4(a2),a0
    moveq   #0,d0
    move.w  (a0)+,d0
    swap    d0
    move.l  a0,4(a2)
    move.b  #16,8(a2)
.Kpt_rb1:
    lsl.l   #1,d0
    scs     d1
    move.l  d0,(a2)
    subq.b  #1,8(a2)
    neg.b   d1
    bne.b   .KBLpt_linerep

    // mp_unpack_sim (chamada externa)
    move.l  d3,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    not.l   d0
    add.l   d3,d0
    move.l  d0,-(sp)
    move.l  d5,-(sp)
    move.l  d3,-(sp)
    move.l  a3,-(sp)
    move.l  a2,-(sp)
    jsr     mp_unpack_sim
    lea     20(sp),sp
    bra.b   .KBLpt_next

.KBLpt_linerep:
    // mp_unpack_linerep (chamada externa)
    move.l  d6,-(sp)
    move.l  d5,-(sp)
    move.l  d3,-(sp)
    move.l  a3,-(sp)
    move.l  a2,-(sp)
    jsr     mp_unpack_linerep
    lea     20(sp),sp

.KBLpt_next:
    addq.l  #1,d3
    cmp.l   d2,d3
    bcs.w   .KBLpt_loop

.KBLpt_done:
    movem.l (sp)+,d2-d6/a2-a3
    rts

// ================================================================
// mp_get_stream.s — CORRIGIDO
// ================================================================

mp_get_stream:
    //  Input: 4(sp) = s, 8(sp) = range (interface ANTIGA)
    //  Output: d0 = result (interface ANTIGA)
    //  FASE 1: Adapter carrega/salva D0/D1/A1
    //  FASE 4: Remove adapter

    move.l  4(sp),a2               // A2 = s
    //  Carrega bitstream state nos registradores permanentes
    move.l  (a2),d0                // D0 = s->cmp
    move.b  8(a2),d1               // D1 = s->used
    move.l  4(a2),a1               // A1 = s->src

    movem.l d2-d4,-(sp)
    move.l  20(sp),d2              // D2 = range (offset: 3 regs × 4 + ret_addr)

.GSLtop:
    cmp.l   #0x100,d2
    bls.w   .GSLcommon

    // ── range > 0x100 ──
    subq.l  #1,d2
    moveq   #0,d3
    move.b  d2,d3
    addq.l  #1,d3                  // D3 = low
    move.l  d2,d4
    lsr.l   #8,d4
    addq.l  #1,d4                  // D4 = hi

    // Recursive call (interface antiga — mantém compatibilidade)
    move.l  d3,-(sp)
    move.l  d4,-(sp)
    move.l  a2,-(sp)
    jsr     mp_get_stream
    addq.l  #8,sp
    move.l  (sp)+,d3               // D3 = low

    //  Recarrega bitstream state (recursive call atualizou via adapter)
    move.l  d0,d2                  // D2 = xhi (resultado)
    move.l  (a2),d0                // D0 = cmp atualizado
    move.b  8(a2),d1               // D1 = used atualizado
    move.l  4(a2),a1               // A1 = src atualizado

    tst.l   d2                     //  testa xhi (em D2, não D0)
    beq.b   .GSLxhi_zero

    subq.l  #1,d2
    lsl.l   #8,d2
    add.l   d3,d2                  // D2 = (xhi-1)*256 + low

    move.l  d2,-(sp)
    moveq   #8,d2
    bsr     .GS_readBits
    add.l   (sp)+,d2               // D2 = rb(8) + intermediate
    bra.b   .GSLdone

.GSLxhi_zero:
    move.l  d3,d2
    bra.w   .GSLtop

.GSLcommon:
    lea     mp_log2_lut,a0
    move.b  0(a0,d2.l),d3          // D3 = bc

    // unused = (1 << (bc+1)) - range
    moveq   #1,d4
    addq.b  #1,d3                  // D3 = bc+1 (temp)
    lsl.l   d3,d4                  // D4 = 1<<(bc+1)
    subq.b  #1,d3                  // D3 = bc
    sub.l   d2,d4                  // D4 = unused

    // x = rb(bc)
    move.l  d4,-(sp)
    tst.b   d3
    beq.b   .GSLbc_zero
    move.l  d3,d2
    bsr     .GS_readBits
    move.l  (sp)+,d4
    bra.b   .GSLcmp

.GSLbc_zero:
    moveq   #0,d2
    move.l  (sp)+,d4

.GSLcmp:
    cmp.l   d4,d2
    bhs.b   .GSLx_ge
    bra.b   .GSLdone

.GSLx_ge:
    lsl.l   #1,d2
    move.l  d2,-(sp)
    moveq   #1,d2
    bsr     .GS_readBits
    or.l    (sp)+,d2
    sub.l   d4,d2

.GSLdone:
    //  D2 = resultado, D0 = cmp atualizado
    //  Salva bitstream state ANTES de sobrescrever D0
    move.l  d0,(a2)                // s->cmp = D0
    move.b  d1,8(a2)               // s->used = D1
    move.l  a1,4(a2)               // s->src = A1

    move.l  d2,d0                  // D0 = resultado (para callers)
    movem.l (sp)+,d2-d4
    rts

// ════════════════════════════════════════════════════════
//  .GS_readBits — subroutine interna
//   USA D0/D1/A1 DIRETAMENTE (sem load/store memória)
//  Input:  D2 = numBits, D0=cmp, D1=used, A1=src
//  Output: D2 = resultado, D0/D1/A1 atualizados
//  Preserva: D3-D7, A0, A2-A6
// ════════════════════════════════════════════════════════
.GS_readBits:
    tst.b   d2
    beq.b   .Lgs_zero
    tst.b   d1
    bne.b   .Lgs_have
    //  Refill — lê direto de A1 (src pointer em registrador!)
    moveq   #0,d0
    move.w  (a1)+,d0
    swap    d0
    move.b  #16,d1
.Lgs_have:
    cmp.b   d1,d2
    bhi.b   .Lgs_fallback

    //  Caminho rápido: N ≤ used (90% dos casos)
    //  Sem load/store de memória! Tudo em registradores.
    move.l  d3,-(sp)               //  salva D3 (único reg precisamos)

    // Salva numBits e cmp na stack
    move.l  d2,-(sp)               // [sp] = numBits
    move.l  d0,-(sp)               // [sp] = cmp, [sp+4] = numBits

    // result = cmp >> (32-numBits)
    moveq   #32,d3
    sub.l   d2,d3                  // D3 = 32-numBits
    lsr.l   d3,d0                  // D0 = resultado
    move.l  d0,d2                  // D2 = resultado

    // Update cmp: original <<= numBits
    move.l  (sp),d0                // D0 = cmp original
    move.l  4(sp),d3               // D3 = numBits
    lsl.l   d3,d0                  // D0 = cmp <<= numBits

    // Update used
    sub.b   d3,d1                  // D3 = numBits (low byte correto)

    // Restaura
    addq.l  #8,sp                  // pop cmp e numBits
    move.l  (sp)+,d3               //  restaura D3
    rts

.Lgs_fallback:
    //  Caminho lento (10%): N > used
    //  Sincroniza D0/D1/A1 com struct, chama mp_read_bits antigo
    move.l  d0,(a2)
    move.b  d1,8(a2)
    move.l  a1,4(a2)

    move.l  d2,-(sp)
    move.l  a2,-(sp)
    jsr     mp_read_bits
    addq.l  #8,sp
    move.l  d0,d2                  // D2 = resultado

    //  Re-carrega bitstream state
    move.l  (a2),d0
    move.b  8(a2),d1
    move.l  4(a2),a1
    rts

.Lgs_zero:
    moveq   #0,d2
    rts

mp_unpack_linerep:
    movem.l d2-d7/a2-a4,-(sp)

    move.l  40(sp),a2               // s
    move.l  44(sp),d0               // dst
    move.l  48(sp),d1               // i
    move.l  52(sp),d5               // pixels
    move.l  56(sp),d6               // col_idx

    // tile = dst + i*32
    lsl.l   #5,d1
    add.l   d0,d1
    move.l  d1,a3                   // a3 = tile

    // * base_pixels = mp_colsets[col_idx]
    lea     mp_colsets,a0
    lsl.l   #1,d6
    move.w  0(a0,d6.l),d4           // d4 = base_pixels

    // readmaps(s)
    move.l  a2,-(sp)
    jsr     mp_unpack_linerep_readmaps
    addq.l  #4,sp
    move.b  d0,d3                   // d3 = vmap
    lsr.w   #8,d0
    move.b  d0,d2                   // d2 = hmap

    // mp_linerep_row0(s, tile, VMAP, pixels)  * vmap=d3, não hmap=d2
    move.l  d5,-(sp)
    moveq   #0,d0
    move.b  d3,d0                   //vmap
    move.l  d0,-(sp)
    move.l  a3,-(sp)
    move.l  a2,-(sp)
    jsr     mp_linerep_row0
    lea     16(sp),sp

    // mp_linerep_rows1to7(s, tile, hmap, vmap, BASE_PIXELS)  * d4
    move.l  d4,-(sp)                // base_pixels
    moveq   #0,d0
    move.b  d3,d0
    move.l  d0,-(sp)
    moveq   #0,d0
    move.b  d2,d0
    move.l  d0,-(sp)
    move.l  a3,-(sp)
    move.l  a2,-(sp)
    jsr     mp_linerep_rows1to7
    lea     20(sp),sp

    movem.l (sp)+,d2-d7/a2-a4
    rts

mp_unpack_sim:
    movem.l d2-d7/a2-a4,-(sp)

    move.l  40(sp),a2               // s
    move.l  44(sp),d0               // dst
    move.l  48(sp),d1               // i
    move.l  52(sp),d5               // pixels
    move.l  56(sp),d2               // offset

    // tile_i = dst + i*32
    move.l  d1,d6
    lsl.l   #5,d6
    add.l   d0,d6
    move.l  d6,a3                   // a3 = tile_i

    // tile_ref = dst + offset*32
    lsl.l   #5,d2
    add.l   d0,d2
    move.l  d2,a4                   // a4 = tile_ref

    // readmaps(s)
    move.l  a2,-(sp)
    jsr     mp_unpack_sim_readmaps
    addq.l  #4,sp
    move.b  d0,d3                   // d3 = vmap
    lsr.w   #8,d0
    move.b  d0,d2                   // d2 = hmap

    // Fast path: hmap==0xFF && vmap==0xFF → tile_copy
    cmp.b   #0xFF,d2
    bne     .Ksim_rows
    cmp.b   #0xFF,d3
    bne     .Ksim_rows
    movem.l (a4),d0-d7
    movem.l d0-d7,(a3)
    bra     .Ksim_done

.Ksim_rows:
    // Row loop: row=0..7, y=7-row
    moveq   #0,d6                   // d6 = row

.Ksim_yloop:
    cmp.b   #8,d6
    bge     .Ksim_done

    moveq   #7,d0
    sub.b   d6,d0                   // d0 = y = 7-row
    move.b  d0,d7                   // d7 = y

    // Test hmap bit y
    btst    d0,d2
    beq     .Ksim_check_vmap

    // hmap bit set: copy row
    move.l  d6,d0
    lsl.l   #2,d0
    move.l  a4,a0
    add.l   d0,a0
    move.l  a3,a1
    add.l   d0,a1
    move.l  (a0),(a1)
    bra     .Ksim_next

.Ksim_check_vmap:
    // * vmap == 0xFF -> copy row
    cmp.b   #0xFF,d3
    bne     .Ksim_decode
    move.l  d6,d0
    lsl.l   #2,d0
    move.l  a4,a0
    add.l   d0,a0
    move.l  a3,a1
    add.l   d0,a1
    move.l  (a0),(a1)
    bra     .Ksim_next

.Ksim_decode:
    // Compute row pointers
    move.l  d6,d0
    lsl.l   #2,d0
    move.l  a4,a0
    add.l   d0,a0                   // a0 = ref_row
    move.l  a3,a1
    add.l   d0,a1                   // a1 = dst_row

    // * skip = ((hmap // (1 << y)) == 0xFF) ? 1 : 0 (ESTAVA FALTANDO)
    moveq   #0,d1
    bset    d7,d1                   // d1 = (1 << y)
    move.b  d2,d0                   // d0 = hmap
    or.b    d1,d0                   // d0 = hmap // (1<<y)
    cmp.b   #0xFF,d0
    bne.b   .Ksim_no_skip
    moveq   #1,d1
    bra.b   .Ksim_call
.Ksim_no_skip:
    moveq   #0,d1
.Ksim_call:

    // mp_unpack_sim_row(s, dst_row, ref_row, vmap, skip, pixels)
    move.l  d5,-(sp)                // pixels
    moveq   #0,d0
    move.b  d1,d0
    move.l  d0,-(sp)                // skip
    moveq   #0,d0
    move.b  d3,d0
    move.l  d0,-(sp)                // vmap
    move.l  a0,-(sp)                // ref_row
    move.l  a1,-(sp)                // dst_row
    move.l  a2,-(sp)                // s
    jsr     mp_unpack_sim_row
    lea     24(sp),sp

.Ksim_next:
    addq.b  #1,d6
    bra     .Ksim_yloop

.Ksim_done:
    movem.l (sp)+,d2-d7/a2-a4
    rts
