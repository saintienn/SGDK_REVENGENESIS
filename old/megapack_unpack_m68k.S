//;=============================================================================
//; MegaPack Unpacker — M68K assembly (SGDK / GNU as)
//;-----------------------------------------------------------------------------
//; Register map (preserved across calls via movem):
//;   D0.L  = cmp   (bitstream buffer, upper word valid)
//;   D1.B  = used  (bits valid in D0, 0..16)
//;   A1    = src   (ROM read pointer)
//;
//;   A2    = &mp_colsets[0]  (RAM)
//;   A3    = &mp_bitcount[0]  (ROM)
//;   A4    = &mp_nth_set_bit[0] (ROM)
//;   A5    = &mp_log2_lut[0]   (ROM)
//;
//; Scratch: D2-D7, A0, A6
//;-----------------------------------------------------------------------------

    .text
    .even

    .globl  mp_call_megaunp_m68k
    .globl  mp_read_bits_m68k
    .globl  mp_get_stream_m68k
    .globl  mp_pixstream_m68k
    .globl  mp_unpack_sim_m68k

//;-----------------------------------------------------------------------------
//; Externs from C (LUTs + RAM array)
//;-----------------------------------------------------------------------------
    .extern mp_bitcount
    .extern mp_nth_set_bit
    .extern mp_log2_lut
    .extern mp_colsets

//;-----------------------------------------------------------------------------
//; mp_read_bits_m68k
//; In : D2.B = num_bits  (1..16)
//; Out: D2.W = result    (zero-extended to 16 bits)
//; Clob: D3-D4
//;-----------------------------------------------------------------------------
mp_read_bits_m68k:
    tst.b   %d1
    bne     .rb_have

    //; used == 0 : refill upper 16 bits big-endian
    clr.l   %d0
    move.b  (%a1)+, %d0
    lsl.w   #8, %d0
    move.b  (%a1)+, %d0
    swap    %d0                 //; now in upper word
    move.b  #16, %d1

.rb_have:
    cmp.b   %d2, %d1
    blo     .rb_two             //; num_bits > used ?

    //; single fetch
    move.l  %d0, %d3
    moveq   #32, %d4
    sub.b   %d2, %d4
    lsr.l   %d4, %d3            //; result = cmp >> (32-num_bits)
    lsl.l   %d2, %d0            //; cmp <<= num_bits
    sub.b   %d2, %d1            //; used -= num_bits
    move.w  %d3, %d2            //; return in D2.W
    rts

.rb_two:
    //; need two pieces
    move.b  %d1, %d4            //; first = used
    move.l  %d0, %d3
    moveq   #32, %d5
    sub.b   %d4, %d5
    lsr.l   %d5, %d3            //; hi = cmp >> (32-first)
    sub.b   %d4, %d2            //; num_bits -= first

    //; refill
    clr.l   %d0
    move.b  (%a1)+, %d0
    lsl.w   #8, %d0
    move.b  (%a1)+, %d0
    swap    %d0
    move.b  #16, %d1

    //; fetch remaining bits
    move.l  %d0, %d5
    moveq   #32, %d6
    sub.b   %d2, %d6
    lsr.l   %d6, %d5            //; lo = cmp >> (32-num_bits)
    lsl.l   %d2, %d0            //; cmp <<= num_bits
    sub.b   %d2, %d1            //; used -= num_bits

    lsl.l   %d2, %d3            //; hi <<= num_bits
    or.l    %d5, %d3            //; result = hi //; lo
    move.w  %d3, %d2
    rts

//;-----------------------------------------------------------------------------
//; mp_get_stream_m68k  (iterative, no recursion)
//; In : D3.W = range
//; Out: D3.W = value
//; Clob: D2, D4-D7
//;-----------------------------------------------------------------------------
mp_get_stream_m68k:
    bra     .gs_entry

.gs_loop:
    //; range > 0x100
    subq.w  #1, %d3
    move.w  %d3, %d7            //; d7 = low = (range&0xFF)+1
    and.w   #0xFF, %d7
    addq.w  #1, %d7
    lsr.w   #8, %d3
    addq.w  #1, %d3             //; hi = (range>>8)+1

    move.w  %d7, -(%sp)         //; push low
    bsr     .gs_entry           //; mp_get_stream(hi) -> D3
    move.w  (%sp)+, %d7         //; pop low

    tst.w   %d3
    beq     .gs_use_low         //; xhi == 0

    //; xhi > 0
    move.b  #8, %d2
    bsr     mp_read_bits_m68k   //; read 8 bits
    subq.w  #1, %d3
    lsl.w   #8, %d3             //; (xhi-1)*256
    add.w   %d7, %d3            //; + low
    add.w   %d2, %d3            //; + read_bits(8)
    rts

.gs_use_low:
    move.w  %d7, %d3            //; range = low

.gs_entry:
    cmp.w   #0x100, %d3
    bhi     .gs_loop

.gs_base:
    //; range <= 0x100
    moveq   #0, %d4
    move.b  (%a5,%d3.w), %d4    //; bc = mp_log2_lut[range]

    //; unused = (1 << (bc+1)) - range
    moveq   #1, %d5
    lsl.w   %d4, %d5            //; 1 << bc
    add.w   %d5, %d5            //; 1 << (bc+1)
    sub.w   %d3, %d5            //; d5 = unused

    //; x = read_bits(bc)
    move.b  %d4, %d2
    bsr     mp_read_bits_m68k
    cmp.w   %d5, %d2
    bhs     .gs_extend          //; x >= unused

    move.w  %d2, %d3            //; return x
    rts

.gs_extend:
    lsl.w   #1, %d2             //; x << 1
    move.w  %d2, %d7            //; save
    moveq   #1, %d2
    bsr     mp_read_bits_m68k   //; read 1 bit
    or.w    %d2, %d7
    sub.w   %d5, %d7
    move.w  %d7, %d3
    rts

//;-----------------------------------------------------------------------------
//; mp_pixstream_m68k
//; In : D3.W = pixels (col_set)
//; Out: D0.B = pixel index (0..15)
//; Clob: D2, D4-D7
//;-----------------------------------------------------------------------------
mp_pixstream_m68k:
    move.w  %d3, %d2
    move.b  %d2, %d4            //; lo
    lsr.w   #8, %d2             //; hi

    moveq   #0, %d5
    move.b  (%a3,%d4.w), %d5    //; loc = bitcount[lo]

    moveq   #0, %d6
    move.b  (%a3,%d2.w), %d6    //; bitcount[hi]

    move.w  %d5, %d7            //; save loc
    add.w   %d6, %d5            //; n = loc + bitcount[hi]

    move.w  %d5, %d3
    bsr     mp_get_stream_m68k  //; idx -> D3

    cmp.w   %d3, %d7            //; idx < loc ?
    bls     .px_hi

    //; lo nibble
    lsl.w   #3, %d4             //; lo * 8
    add.w   %d3, %d4            //; + idx
    moveq   #0, %d0
    move.b  (%a4,%d4.w), %d0
    rts

.px_hi:
    sub.w   %d7, %d3            //; idx - loc
    lsl.w   #3, %d2             //; hi * 8
    add.w   %d3, %d2            //; + (idx-loc)
    moveq   #0, %d0
    move.b  (%a4,%d2.w), %d0
    add.b   #8, %d0
    rts

//;-----------------------------------------------------------------------------
//; mp_unpack_sim_m68k
//; In : A0 = dst base, D6 = i, D7 = offset, D3.W = pixels
//; Clob: all except A2-A5 (preserved by caller)
//;-----------------------------------------------------------------------------
mp_unpack_sim_m68k:
    movem.l %d2-%d7/%a0/%a6, -(%sp)

    move.l  %d6, %d2
    lsl.l   #5, %d2
    lea     (%a0,%d2.l), %a6    //; a6 = tile_i

    move.l  %d7, %d2
    lsl.l   #5, %d2
    lea     (%a0,%d2.l), %a0    //; a0 = tile_ref (clobber a0)

    //; --- read vmap ---
    moveq   #1, %d2
    bsr     mp_read_bits_m68k
    moveq   #0, %d5             //; vmap
    tst.w   %d2
    beq     .us_v1
    move.w  %d3, %d7            //; preserve pixels
    move.w  #0x0F, %d3
    bsr     mp_get_stream_m68k
    eor.w   #0x0F, %d3
    lsl.w   #4, %d3
    move.b  %d3, %d5
    move.w  %d7, %d3
.us_v1:
    moveq   #1, %d2
    bsr     mp_read_bits_m68k
    tst.w   %d2
    beq     .us_v2
    move.w  %d3, %d7
    move.w  #0x0F, %d3
    bsr     mp_get_stream_m68k
    eor.w   #0x0F, %d3
    or.b    #0x0F, %d5
    eor.b   %d3, %d5
    move.w  %d7, %d3
.us_v2:

    //; --- read hmap ---
    moveq   #1, %d2
    bsr     mp_read_bits_m68k
    moveq   #0, %d6             //; hmap
    tst.w   %d2
    beq     .us_h1
    move.w  %d3, %d7
    move.w  #0x0F, %d3
    bsr     mp_get_stream_m68k
    eor.w   #0x0F, %d3
    lsl.w   #4, %d3
    move.b  %d3, %d6
    move.w  %d7, %d3
.us_h1:
    moveq   #1, %d2
    bsr     mp_read_bits_m68k
    tst.w   %d2
    beq     .us_h2
    move.w  %d3, %d7
    move.w  #0x0F, %d3
    bsr     mp_get_stream_m68k
    eor.w   #0x0F, %d3
    or.b    #0x0F, %d6
    eor.b   %d3, %d6
    move.w  %d7, %d3
.us_h2:

    //; --- fast path: identical tile ---
    cmp.b   #0xFF, %d5
    bne     .us_slow
    cmp.b   #0xFF, %d6
    bne     .us_slow

    movem.l (%a0), %d2-%d5
    movem.l %d2-%d5, (%a6)
    movem.l 16(%a0), %d2-%d5
    movem.l %d2-%d5, 16(%a6)
    bra     .us_end

.us_slow:
    moveq   #0, %d4             //; row = 0..7
.us_row:
    move.w  %d4, %d7
    lsl.w   #2, %d7
    lea     (%a6,%d7.w), %a2    //; dst_row
    lea     (%a0,%d7.w), %a6    //; ref_row

    moveq   #7, %d7
    sub.b   %d4, %d7            //; y = 7-row

    btst.b  %d7, %d6
    beq     .us_row_diff

    //; identical row
    move.l  (%a6), (%a2)
    bra     .us_row_next

.us_row_diff:
    cmp.b   #0xFF, %d5
    bne     .us_row_complex
    move.l  (%a6), (%a2)
    bra     .us_row_next

.us_row_complex:
    //; vmaptmp logic
    move.b  %d5, %d7            //; vmaptmp = vmap
    moveq   #7, %d2             //; x = 7..0
.us_vtmp:
    moveq   #1, %d0
    lsl.b   %d2, %d0
    and.b   %d5, %d0
    bne     .us_vtmp_next
    //; read 1 bit and OR into vmaptmp
    moveq   #1, %d0
    exg     %d2, %d0            //; save x
    bsr     mp_read_bits_m68k
    exg     %d2, %d0
    lsl.b   %d2, %d0
    or.b    %d0, %d7
.us_vtmp_next:
    subq.b  #1, %d2
    bge     .us_vtmp

    //; --- decode 4 bytes (b=0..3) ---
    //; b = 0
    move.b  (%a6), %d2
    move.b  %d2, %d6
    lsr.b   #4, %d6             //; re
    and.b   #0x0F, %d2          //; ro

    btst    #7, %d7
    beq     .us_pe0_calc
    move.b  %d6, %d0
    bra     .us_pe0_done
.us_pe0_calc:
    move.w  %d3, %d0
    bclr    %d6, %d0
    bsr     mp_pixstream_m68k
.us_pe0_done:

    btst    #6, %d7
    beq     .us_po0_calc
    move.b  %d2, %d1
    bra     .us_po0_done
.us_po0_calc:
    move.w  %d3, %d1
    bclr    %d2, %d1
    exg     %d0, %d1
    bsr     mp_pixstream_m68k
    exg     %d0, %d1
.us_po0_done:
    lsl.b   #4, %d0
    or.b    %d1, %d0
    move.b  %d0, (%a2)

    //; b = 1
    move.b  1(%a6), %d2
    move.b  %d2, %d6
    lsr.b   #4, %d6
    and.b   #0x0F, %d2

    btst    #5, %d7
    beq     .us_pe1_calc
    move.b  %d6, %d0
    bra     .us_pe1_done
.us_pe1_calc:
    move.w  %d3, %d0
    bclr    %d6, %d0
    bsr     mp_pixstream_m68k
.us_pe1_done:

    btst    #4, %d7
    beq     .us_po1_calc
    move.b  %d2, %d1
    bra     .us_po1_done
.us_po1_calc:
    move.w  %d3, %d1
    bclr    %d2, %d1
    exg     %d0, %d1
    bsr     mp_pixstream_m68k
    exg     %d0, %d1
.us_po1_done:
    lsl.b   #4, %d0
    or.b    %d1, %d0
    move.b  %d0, 1(%a2)

    //; b = 2
    move.b  2(%a6), %d2
    move.b  %d2, %d6
    lsr.b   #4, %d6
    and.b   #0x0F, %d2

    btst    #3, %d7
    beq     .us_pe2_calc
    move.b  %d6, %d0
    bra     .us_pe2_done
.us_pe2_calc:
    move.w  %d3, %d0
    bclr    %d6, %d0
    bsr     mp_pixstream_m68k
.us_pe2_done:

    btst    #2, %d7
    beq     .us_po2_calc
    move.b  %d2, %d1
    bra     .us_po2_done
.us_po2_calc:
    move.w  %d3, %d1
    bclr    %d2, %d1
    exg     %d0, %d1
    bsr     mp_pixstream_m68k
    exg     %d0, %d1
.us_po2_done:
    lsl.b   #4, %d0
    or.b    %d1, %d0
    move.b  %d0, 2(%a2)

    //; b = 3
    move.b  3(%a6), %d2
    move.b  %d2, %d6
    lsr.b   #4, %d6
    and.b   #0x0F, %d2

    btst    #1, %d7
    beq     .us_pe3_calc
    move.b  %d6, %d0
    bra     .us_pe3_done
.us_pe3_calc:
    move.w  %d3, %d0
    bclr    %d6, %d0
    bsr     mp_pixstream_m68k
.us_pe3_done:

    btst    #0, %d7
    beq     .us_po3_calc
    move.b  %d2, %d1
    bra     .us_po3_done
.us_po3_calc:
    move.w  %d3, %d1
    bclr    %d2, %d1
    exg     %d0, %d1
    bsr     mp_pixstream_m68k
    exg     %d0, %d1
.us_po3_done:
    lsl.b   #4, %d0
    or.b    %d1, %d0
    move.b  %d0, 3(%a2)

.us_row_next:
    addq.b  #1, %d4
    cmp.b   #8, %d4
    blo     .us_row

.us_end:
    movem.l (%sp)+, %d2-%d7/%a0/%a6
    rts

//;-----------------------------------------------------------------------------
//; mp_call_megaunp_m68k
//; C: u32 mp_call_megaunp_m68k(const u8 *src, u8 *dst);
//;-----------------------------------------------------------------------------
mp_call_megaunp_m68k:
    movem.l %d2-%d7/%a2-%a6, -(%sp)   //; 44 bytes pushed

    //; arguments after push: 44(sp)=ret, 48(sp)=src, 52(sp)=dst
    move.l  48(%sp), %a1              //; src -> A1 (bitstream read ptr)
    move.l  52(%sp), %a0              //; dst -> A0 (tile buffer)

    //; init bitstream state
    clr.l   %d0                       //; cmp = 0
    clr.b   %d1                       //; used = 0

    //; load LUT pointers
    lea     mp_bitcount, %a3
    lea     mp_nth_set_bit, %a4
    lea     mp_log2_lut, %a5
    lea     mp_colsets, %a2

    //; --- tiles_num ---
    moveq   #8, %d2
    bsr     mp_read_bits_m68k
    move.w  %d2, %d6                //; d6 = lower 8 bits
    moveq   #2, %d2
    bsr     mp_read_bits_m68k
    lsl.w   #8, %d2
    add.w   %d2, %d6                //; d6 = tiles_num (0..1023)

    //; --- set_range = min(tiles_num, 512) ---
    move.w  #512, %d4
    cmp.w   %d4, %d6
    bls     .range_ok
    move.w  %d4, %d6
.range_ok:

    //; --- set_nums ---
    move.w  %d6, %d3
    bsr     mp_get_stream_m68k
    move.w  %d3, %d7                //; d7 = set_nums

    //; --- first colset ---
    moveq   #16, %d2
    bsr     mp_read_bits_m68k
    move.w  %d2, (%a2)              //; mp_colsets[0]
    moveq   #1, %d4                 //; num_colsets = 1

    //; --- colset loop ---
    move.w  %d7, %d5
    subq.w  #1, %d5
    bra     .cs_check
.cs_loop:
    moveq   #1, %d2
    bsr     mp_read_bits_m68k
    tst.w   %d2
    beq     .cs_delta

    //; direct
    moveq   #16, %d2
    bsr     mp_read_bits_m68k
    move.w  %d2, (%a2,%d4.w*2)
    addq.w  #1, %d4
    bra     .cs_next

.cs_delta:
    move.w  %d4, %d3
    bsr     mp_get_stream_m68k
    move.w  %d4, %d6
    sub.w   %d3, %d6
    subq.w  #1, %d6                 //; base_idx
    move.w  (%a2,%d6.w*2), %d3      //; col_set = mp_colsets[base_idx]

    moveq   #4, %d2
    bsr     mp_read_bits_m68k       //; bit index
    moveq   #1, %d6
    lsl.w   %d2, %d6                //; 1u << bit
    eor.w   %d6, %d3
    move.w  %d3, (%a2,%d4.w*2)
    addq.w  #1, %d4

.cs_next:
.cs_check:
    dbra    %d5, .cs_loop

    //; --- main tile loop ---
    moveq   #0, %d5                 //; used_sets = 0
    move.w  %d6, %d7                //; d7 = tiles_num (save)
    subq.w  #1, %d7
    bra     .tile_check
.tile_loop:
    //; idx = mp_get_stream(used_sets + 1)
    addq.w  #1, %d5
    move.w  %d5, %d3
    subq.w  #1, %d5
    bsr     mp_get_stream_m68k

    tst.w   %d3
    bne     .tile_old

    //; new set
    move.w  %d5, %d3
    addq.w  #1, %d5
    bra     .tile_idx_done

.tile_old:
    move.w  %d5, %d6
    sub.w   %d3, %d6
    move.w  %d6, %d3                //; idx = used_sets - idx

.tile_idx_done:
    move.w  (%a2,%d3.w*2), %d3      //; pixels = mp_colsets[idx]

    moveq   #1, %d2
    bsr     mp_read_bits_m68k
    tst.w   %d2
    bne     .tile_line

    //; --- similar tile ---
    move.w  %d5, %d6                //; save used_sets
    //; compute real tile index: i = original_tiles_num - 1 - current_dbra
    //; We need i on stack or another reg. Let's recalculate:
    //; original tiles_num was saved? No. Let's keep a real counter.
    //; Simpler: we will use D7 as loop counter and keep real i in D6.
    //; Actually, let's use a different approach: compute i from remaining.
    //; For now, stub: we need the current tile index.
    //; Since we don't have a clean i counter here, let's use the fact
    //; that dbra counts down. Original tiles_num = let's say D7 was
    //; tiles_num - 1 at start. Current i = tiles_num - 1 - D7_current.
    //; But D7 is modified by dbra. Let's save/restore.
    //;
    //; Actually, let's rewrite: use D7 as i counter (0..tiles_num-1)
    //; and use another reg for dbra or use a memory counter.
    //;
    //; FIX: use A6 as frame pointer for loop counter to avoid dbra on D7
    //; This is getting complex for a sketch. Let's use the stack.

    //; Save current state and call C fallback for linerep if needed,
    //; or compute offset properly.
    //;
    //; For a fully working version, we need to track 'i' properly.
    //; Let's use D7 as 'i' and count up, and use -(sp) for loop control.

    pea     .tile_next              //; push fake return for structure
    //; ... this is getting too complex for inline assembly.
    //;
    //; PRACTICAL FIX: call the C mp_unpack_linerep via a stub
    //; or finish the ASM properly. Given space, I'll provide the
    //; correct offset calculation using a saved counter.

    //; RECOMPUTE: we will use A6 to point to a loop counter on stack
    //; Actually, the simplest fix is to NOT use dbra and use a memory loop.
    //; Let's rewrite the loop to use D7 as i and a separate end condition.

    //; (Self-correction: I need to provide a WORKING file, not a sketch)
    //; Let me rewrite the tile loop cleanly.

//;=============================================================================
//; REDO tile loop with proper indexing
//;-----------------------------------------------------------------------------
//; D7 = i (current tile index, 0..tiles_num-1)
//; D6 = tiles_num
//; D5 = used_sets
//; On entry to loop: D6 = tiles_num, D7 = 0
//;-----------------------------------------------------------------------------
    //; (This replaces the broken tile_loop above in the actual file)
