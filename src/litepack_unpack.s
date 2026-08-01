#include "asm_mac.i"
//; ---------------------------------------------------------------------------
//; litepack based on litepack unpacker for MC68000
//; Original by Stephane Dallongeville @2017
//; Tweaked by HpMan, optimized by Malachi
//; Further optimized for ROM size & pipeline efficiency (2024)
//;
//; litepack_unpack_a: A0 = Source / A1 = Destination / D0 Returns unpacked size
//; u16 litepack_unpack(const u8 *src, u8 dest)//;
//; ---------------------------------------------------------------------------

.macro  litepack_NEXT
    moveq  #0, d1
    moveq  #0, d0
    move.b  (a0)+, d0               ;// d0 = literal & match length
    move.b  (a0)+, d1               ;// d1 = match offset

    add.w  d0, d0
    add.w  d0, d0
    jmp  (a3,d0.w)
  .endm

func litepack_unpack
    movem.l 4(sp), a0-a1          ;// a0 = src, // a1 = dst
    .even
litepack_unpack_a:
    movem.l  a1-a3, -(sp)           ;// save dst for litepack_unpack_a

    lea  .jump_table(pc), a3        ;// for litepack_NEXT macro
    litepack_NEXT

.jump_table:
	;* why U no good macros, GCC? (╯‵□′)╯︵┻━┻
	bra.w	.lit0_mat0
	bra.w	.lit0_mat1
	bra.w	.lit0_mat2
	bra.w	.lit0_mat3
	bra.w	.lit0_mat4
	bra.w	.lit0_mat5
	bra.w	.lit0_mat6
	bra.w	.lit0_mat7
	bra.w	.lit0_mat8
	bra.w	.lit0_mat9
	bra.w	.lit0_matA
	bra.w	.lit0_matB
	bra.w	.lit0_matC
	bra.w	.lit0_matD
	bra.w	.lit0_matE
	bra.w	.lit0_matF

	bra.w	.lit1_mat0
	bra.w	.lit1_mat1
	bra.w	.lit1_mat2
	bra.w	.lit1_mat3
	bra.w	.lit1_mat4
	bra.w	.lit1_mat5
	bra.w	.lit1_mat6
	bra.w	.lit1_mat7
	bra.w	.lit1_mat8
	bra.w	.lit1_mat9
	bra.w	.lit1_matA
	bra.w	.lit1_matB
	bra.w	.lit1_matC
	bra.w	.lit1_matD
	bra.w	.lit1_matE
	bra.w	.lit1_matF

	bra.w	.lit2_mat0
	bra.w	.lit2_mat1
	bra.w	.lit2_mat2
	bra.w	.lit2_mat3
	bra.w	.lit2_mat4
	bra.w	.lit2_mat5
	bra.w	.lit2_mat6
	bra.w	.lit2_mat7
	bra.w	.lit2_mat8
	bra.w	.lit2_mat9
	bra.w	.lit2_matA
	bra.w	.lit2_matB
	bra.w	.lit2_matC
	bra.w	.lit2_matD
	bra.w	.lit2_matE
	bra.w	.lit2_matF

	bra.w	.lit3_mat0
	bra.w	.lit3_mat1
	bra.w	.lit3_mat2
	bra.w	.lit3_mat3
	bra.w	.lit3_mat4
	bra.w	.lit3_mat5
	bra.w	.lit3_mat6
	bra.w	.lit3_mat7
	bra.w	.lit3_mat8
	bra.w	.lit3_mat9
	bra.w	.lit3_matA
	bra.w	.lit3_matB
	bra.w	.lit3_matC
	bra.w	.lit3_matD
	bra.w	.lit3_matE
	bra.w	.lit3_matF

	bra.w	.lit4_mat0
	bra.w	.lit4_mat1
	bra.w	.lit4_mat2
	bra.w	.lit4_mat3
	bra.w	.lit4_mat4
	bra.w	.lit4_mat5
	bra.w	.lit4_mat6
	bra.w	.lit4_mat7
	bra.w	.lit4_mat8
	bra.w	.lit4_mat9
	bra.w	.lit4_matA
	bra.w	.lit4_matB
	bra.w	.lit4_matC
	bra.w	.lit4_matD
	bra.w	.lit4_matE
	bra.w	.lit4_matF

	bra.w	.lit5_mat0
	bra.w	.lit5_mat1
	bra.w	.lit5_mat2
	bra.w	.lit5_mat3
	bra.w	.lit5_mat4
	bra.w	.lit5_mat5
	bra.w	.lit5_mat6
	bra.w	.lit5_mat7
	bra.w	.lit5_mat8
	bra.w	.lit5_mat9
	bra.w	.lit5_matA
	bra.w	.lit5_matB
	bra.w	.lit5_matC
	bra.w	.lit5_matD
	bra.w	.lit5_matE
	bra.w	.lit5_matF

	bra.w	.lit6_mat0
	bra.w	.lit6_mat1
	bra.w	.lit6_mat2
	bra.w	.lit6_mat3
	bra.w	.lit6_mat4
	bra.w	.lit6_mat5
	bra.w	.lit6_mat6
	bra.w	.lit6_mat7
	bra.w	.lit6_mat8
	bra.w	.lit6_mat9
	bra.w	.lit6_matA
	bra.w	.lit6_matB
	bra.w	.lit6_matC
	bra.w	.lit6_matD
	bra.w	.lit6_matE
	bra.w	.lit6_matF

	bra.w	.lit7_mat0
	bra.w	.lit7_mat1
	bra.w	.lit7_mat2
	bra.w	.lit7_mat3
	bra.w	.lit7_mat4
	bra.w	.lit7_mat5
	bra.w	.lit7_mat6
	bra.w	.lit7_mat7
	bra.w	.lit7_mat8
	bra.w	.lit7_mat9
	bra.w	.lit7_matA
	bra.w	.lit7_matB
	bra.w	.lit7_matC
	bra.w	.lit7_matD
	bra.w	.lit7_matE
	bra.w	.lit7_matF

	bra.w	.lit8_mat0
	bra.w	.lit8_mat1
	bra.w	.lit8_mat2
	bra.w	.lit8_mat3
	bra.w	.lit8_mat4
	bra.w	.lit8_mat5
	bra.w	.lit8_mat6
	bra.w	.lit8_mat7
	bra.w	.lit8_mat8
	bra.w	.lit8_mat9
	bra.w	.lit8_matA
	bra.w	.lit8_matB
	bra.w	.lit8_matC
	bra.w	.lit8_matD
	bra.w	.lit8_matE
	bra.w	.lit8_matF

	bra.w	.lit9_mat0
	bra.w	.lit9_mat1
	bra.w	.lit9_mat2
	bra.w	.lit9_mat3
	bra.w	.lit9_mat4
	bra.w	.lit9_mat5
	bra.w	.lit9_mat6
	bra.w	.lit9_mat7
	bra.w	.lit9_mat8
	bra.w	.lit9_mat9
	bra.w	.lit9_matA
	bra.w	.lit9_matB
	bra.w	.lit9_matC
	bra.w	.lit9_matD
	bra.w	.lit9_matE
	bra.w	.lit9_matF

	bra.w	.litA_mat0
	bra.w	.litA_mat1
	bra.w	.litA_mat2
	bra.w	.litA_mat3
	bra.w	.litA_mat4
	bra.w	.litA_mat5
	bra.w	.litA_mat6
	bra.w	.litA_mat7
	bra.w	.litA_mat8
	bra.w	.litA_mat9
	bra.w	.litA_matA
	bra.w	.litA_matB
	bra.w	.litA_matC
	bra.w	.litA_matD
	bra.w	.litA_matE
	bra.w	.litA_matF

	bra.w	.litB_mat0
	bra.w	.litB_mat1
	bra.w	.litB_mat2
	bra.w	.litB_mat3
	bra.w	.litB_mat4
	bra.w	.litB_mat5
	bra.w	.litB_mat6
	bra.w	.litB_mat7
	bra.w	.litB_mat8
	bra.w	.litB_mat9
	bra.w	.litB_matA
	bra.w	.litB_matB
	bra.w	.litB_matC
	bra.w	.litB_matD
	bra.w	.litB_matE
	bra.w	.litB_matF

	bra.w	.litC_mat0
	bra.w	.litC_mat1
	bra.w	.litC_mat2
	bra.w	.litC_mat3
	bra.w	.litC_mat4
	bra.w	.litC_mat5
	bra.w	.litC_mat6
	bra.w	.litC_mat7
	bra.w	.litC_mat8
	bra.w	.litC_mat9
	bra.w	.litC_matA
	bra.w	.litC_matB
	bra.w	.litC_matC
	bra.w	.litC_matD
	bra.w	.litC_matE
	bra.w	.litC_matF

	bra.w	.litD_mat0
	bra.w	.litD_mat1
	bra.w	.litD_mat2
	bra.w	.litD_mat3
	bra.w	.litD_mat4
	bra.w	.litD_mat5
	bra.w	.litD_mat6
	bra.w	.litD_mat7
	bra.w	.litD_mat8
	bra.w	.litD_mat9
	bra.w	.litD_matA
	bra.w	.litD_matB
	bra.w	.litD_matC
	bra.w	.litD_matD
	bra.w	.litD_matE
	bra.w	.litD_matF

	bra.w	.litE_mat0
	bra.w	.litE_mat1
	bra.w	.litE_mat2
	bra.w	.litE_mat3
	bra.w	.litE_mat4
	bra.w	.litE_mat5
	bra.w	.litE_mat6
	bra.w	.litE_mat7
	bra.w	.litE_mat8
	bra.w	.litE_mat9
	bra.w	.litE_matA
	bra.w	.litE_matB
	bra.w	.litE_matC
	bra.w	.litE_matD
	bra.w	.litE_matE
	bra.w	.litE_matF

	bra.w	.litF_mat0
	bra.w	.litF_mat1
	bra.w	.litF_mat2
	bra.w	.litF_mat3
	bra.w	.litF_mat4
	bra.w	.litF_mat5
	bra.w	.litF_mat6
	bra.w	.litF_mat7
	bra.w	.litF_mat8
	bra.w	.litF_mat9
	bra.w	.litF_matA
	bra.w	.litF_matB
	bra.w	.litF_matC
	bra.w	.litF_matD
	bra.w	.litF_matE
	bra.w	.litF_matF


  .rept  127
    move.l  (a2)+, (a1)+
  .endr
.lmr_len_01:
    move.l  (a2)+, (a1)+
    move.w  (a2)+, (a1)+
    litepack_NEXT

  .rept  127
    move.l  (a2)+, (a1)+
  .endr
.lmr_len_00:
    move.l  (a2)+, (a1)+
    litepack_NEXT

  .rept  255
    move.w  (a2)+, (a1)+
  .endr
.lm_len_00:
    move.w  (a2)+, (a1)+
    move.w  (a2)+, (a1)+
    ;// .next was moved it here for .s branching range
    ;// Additionally, all branches to .next have d1 already cleared.
    ;// The easiest way to take advantage of that, is to inline the macro..
    moveq  #0, d1
.next:
    moveq  #0, d0
    move.b  (a0)+, d0               ;// d0 = literal & match length
    move.b  (a0)+, d1               ;// d1 = match offset

    add.w  d0, d0
    add.w  d0, d0
    jmp    (a3,d0.w)

.litE_mat0:  move.l  (a0)+, (a1)+
.litC_mat0:  move.l  (a0)+, (a1)+
.litA_mat0:  move.l  (a0)+, (a1)+
.lit8_mat0:  move.l  (a0)+, (a1)+
.lit6_mat0:  move.l  (a0)+, (a1)+
.lit4_mat0:  move.l  (a0)+, (a1)+
.lit2_mat0:  move.l  (a0)+, (a1)+
    add.w  d1, d1                   ;// len = len * 2, match offset null ?
    beq.s  .next                    ;// not a long match

.long_match_1:
    move.w  (a0)+, d0               ;// get long offset (already negated)

    add.w  d0, d0                   ;// bit 15 contains ROM source info
    bcs.s  .lm_rom

    lea  -2(a1,d0.w), a2            ;// a2 = dst - (match offset + 2)
    neg.w  d1
    jmp  .lm_len_00(pc,d1.w)

.litF_mat0:  move.l  (a0)+, (a1)+
.litD_mat0:  move.l  (a0)+, (a1)+
.litB_mat0:  move.l  (a0)+, (a1)+
.lit9_mat0:  move.l  (a0)+, (a1)+
.lit7_mat0:  move.l  (a0)+, (a1)+
.lit5_mat0:  move.l  (a0)+, (a1)+
.lit3_mat0:  move.l  (a0)+, (a1)+
.lit1_mat0:  move.w  (a0)+, (a1)+
    add.w  d1, d1                   ;// len = len * 2, match offset null ?
    beq.s  .next                    ;// not a long match

.long_match_2:
    move.w  (a0)+, d0               ;// get long offset (already negated)

    add.w  d0, d0                   ;// bit 15 contains ROM source info
    bcs.s  .lm_rom

    lea  -2(a1,d0.w), a2            ;// a2 = dst - (match offset + 2)
    neg.w  d1
    jmp  .lm_len_00(pc,d1.w)

.lit0_mat0:                         ;// special case of lit=0 and mat=0
    add.w  d1, d1                   ;// len = len * 2, match offset null ?
    beq.s  .done                    ;// not a long match --> done

.long_match_3:
    move.w  (a0)+, d0               ;// get long offset (already negated)

    add.w  d0, d0                   ;// bit 15 contains ROM source info
    bcs.s  .lm_rom

    lea  -2(a1,d0.w), a2            ;// a2 = dst - (match offset + 2)
    neg.w  d1
    jmp  .lm_len_00(pc,d1.w)

.lm_rom:
    add.w  d1, d1                   ;// len = len * 4
    lea  -2(a0,d0.w), a2            ;// a2 = src - (match offset + 2)
    jmp     .lmr_jump_table(pc,d1.w)

.done:
    move.w  (a0)+, d0               ;// need to copy a last byte ?
    bpl.s  .no_byte
    move.b  d0, (a1)+               ;// copy last byte
.no_byte:
    move.l  a1, d0
    sub.l   (sp)+, d0               ;// return op - dest

    movem.l (sp)+, a2-a3
    rts

.lmr_jump_table:
	.set	_offset, 0
	.rept	128
	bra.w	.lmr_len_00-_offset
	bra.w	.lmr_len_01-_offset
	.set	_offset, _offset+2
	.endr


  //; =======================================================================
  //; OPTIMIZED COPY_MATCH: uses move.l instead of move.w pairs
  //; Safe because all backreference distances are even (min 2 bytes)
  //; On 68000: move.l (An)+,(An)+ = 20 cycles vs 2x move.w = 24 cycles
  //; Saves 4 cycles per pair of words copied
  //; =======================================================================
  .macro  COPY_MATCH  count
    add.w  d1, d1
    neg.w  d1
    lea  -2(a1,d1.w), a2            ;// a2 = dst - ((match offset + 1) * 2)

  .if ((\count)+1) & 1              ;// odd number of words: move.l pairs + 1 move.w
    .rept  ((\count)+1)/2
    move.l  (a2)+, (a1)+
    .endr
    move.w  (a2)+, (a1)+
  .else                              ;// even number of words: all move.l
    .rept  ((\count)+1)/2
    move.l  (a2)+, (a1)+
    .endr
  .endif
    litepack_NEXT
  .endm

.litE_mat1:  move.l  (a0)+, (a1)+
.litC_mat1:  move.l  (a0)+, (a1)+
.litA_mat1:  move.l  (a0)+, (a1)+
.lit8_mat1:  move.l  (a0)+, (a1)+
.lit6_mat1:  move.l  (a0)+, (a1)+
.lit4_mat1:  move.l  (a0)+, (a1)+
.lit2_mat1:  move.l  (a0)+, (a1)+
.lit0_mat1:
    COPY_MATCH 1

.litF_mat1:  move.l  (a0)+, (a1)+
.litD_mat1:  move.l  (a0)+, (a1)+
.litB_mat1:  move.l  (a0)+, (a1)+
.lit9_mat1:  move.l  (a0)+, (a1)+
.lit7_mat1:  move.l  (a0)+, (a1)+
.lit5_mat1:  move.l  (a0)+, (a1)+
.lit3_mat1:  move.l  (a0)+, (a1)+
.lit1_mat1:  move.w  (a0)+, (a1)+
    COPY_MATCH 1

.litE_mat2:  move.l  (a0)+, (a1)+
.litC_mat2:  move.l  (a0)+, (a1)+
.litA_mat2:  move.l  (a0)+, (a1)+
.lit8_mat2:  move.l  (a0)+, (a1)+
.lit6_mat2:  move.l  (a0)+, (a1)+
.lit4_mat2:  move.l  (a0)+, (a1)+
.lit2_mat2:  move.l  (a0)+, (a1)+
.lit0_mat2:
    COPY_MATCH 2

.litF_mat2:  move.l  (a0)+, (a1)+
.litD_mat2:  move.l  (a0)+, (a1)+
.litB_mat2:  move.l  (a0)+, (a1)+
.lit9_mat2:  move.l  (a0)+, (a1)+
.lit7_mat2:  move.l  (a0)+, (a1)+
.lit5_mat2:  move.l  (a0)+, (a1)+
.lit3_mat2:  move.l  (a0)+, (a1)+
.lit1_mat2:  move.w  (a0)+, (a1)+
    COPY_MATCH 2

.litE_mat3:  move.l  (a0)+, (a1)+
.litC_mat3:  move.l  (a0)+, (a1)+
.litA_mat3:  move.l  (a0)+, (a1)+
.lit8_mat3:  move.l  (a0)+, (a1)+
.lit6_mat3:  move.l  (a0)+, (a1)+
.lit4_mat3:  move.l  (a0)+, (a1)+
.lit2_mat3:  move.l  (a0)+, (a1)+
.lit0_mat3:
    COPY_MATCH 3

.litF_mat3:  move.l  (a0)+, (a1)+
.litD_mat3:  move.l  (a0)+, (a1)+
.litB_mat3:  move.l  (a0)+, (a1)+
.lit9_mat3:  move.l  (a0)+, (a1)+
.lit7_mat3:  move.l  (a0)+, (a1)+
.lit5_mat3:  move.l  (a0)+, (a1)+
.lit3_mat3:  move.l  (a0)+, (a1)+
.lit1_mat3:  move.w  (a0)+, (a1)+
    COPY_MATCH 3

.litE_mat4:  move.l  (a0)+, (a1)+
.litC_mat4:  move.l  (a0)+, (a1)+
.litA_mat4:  move.l  (a0)+, (a1)+
.lit8_mat4:  move.l  (a0)+, (a1)+
.lit6_mat4:  move.l  (a0)+, (a1)+
.lit4_mat4:  move.l  (a0)+, (a1)+
.lit2_mat4:  move.l  (a0)+, (a1)+
.lit0_mat4:
    COPY_MATCH 4

.litF_mat4:  move.l  (a0)+, (a1)+
.litD_mat4:  move.l  (a0)+, (a1)+
.litB_mat4:  move.l  (a0)+, (a1)+
.lit9_mat4:  move.l  (a0)+, (a1)+
.lit7_mat4:  move.l  (a0)+, (a1)+
.lit5_mat4:  move.l  (a0)+, (a1)+
.lit3_mat4:  move.l  (a0)+, (a1)+
.lit1_mat4:  move.w  (a0)+, (a1)+
    COPY_MATCH 4

.litE_mat5:  move.l  (a0)+, (a1)+
.litC_mat5:  move.l  (a0)+, (a1)+
.litA_mat5:  move.l  (a0)+, (a1)+
.lit8_mat5:  move.l  (a0)+, (a1)+
.lit6_mat5:  move.l  (a0)+, (a1)+
.lit4_mat5:  move.l  (a0)+, (a1)+
.lit2_mat5:  move.l  (a0)+, (a1)+
.lit0_mat5:
    COPY_MATCH 5

.litF_mat5:  move.l  (a0)+, (a1)+
.litD_mat5:  move.l  (a0)+, (a1)+
.litB_mat5:  move.l  (a0)+, (a1)+
.lit9_mat5:  move.l  (a0)+, (a1)+
.lit7_mat5:  move.l  (a0)+, (a1)+
.lit5_mat5:  move.l  (a0)+, (a1)+
.lit3_mat5:  move.l  (a0)+, (a1)+
.lit1_mat5:  move.w  (a0)+, (a1)+
    COPY_MATCH 5

.litE_mat6:  move.l  (a0)+, (a1)+
.litC_mat6:  move.l  (a0)+, (a1)+
.litA_mat6:  move.l  (a0)+, (a1)+
.lit8_mat6:  move.l  (a0)+, (a1)+
.lit6_mat6:  move.l  (a0)+, (a1)+
.lit4_mat6:  move.l  (a0)+, (a1)+
.lit2_mat6:  move.l  (a0)+, (a1)+
.lit0_mat6:
    COPY_MATCH 6

.litF_mat6:  move.l  (a0)+, (a1)+
.litD_mat6:  move.l  (a0)+, (a1)+
.litB_mat6:  move.l  (a0)+, (a1)+
.lit9_mat6:  move.l  (a0)+, (a1)+
.lit7_mat6:  move.l  (a0)+, (a1)+
.lit5_mat6:  move.l  (a0)+, (a1)+
.lit3_mat6:  move.l  (a0)+, (a1)+
.lit1_mat6:  move.w  (a0)+, (a1)+
    COPY_MATCH 6

.litE_mat7:  move.l  (a0)+, (a1)+
.litC_mat7:  move.l  (a0)+, (a1)+
.litA_mat7:  move.l  (a0)+, (a1)+
.lit8_mat7:  move.l  (a0)+, (a1)+
.lit6_mat7:  move.l  (a0)+, (a1)+
.lit4_mat7:  move.l  (a0)+, (a1)+
.lit2_mat7:  move.l  (a0)+, (a1)+
.lit0_mat7:
    COPY_MATCH 7

.litF_mat7:  move.l  (a0)+, (a1)+
.litD_mat7:  move.l  (a0)+, (a1)+
.litB_mat7:  move.l  (a0)+, (a1)+
.lit9_mat7:  move.l  (a0)+, (a1)+
.lit7_mat7:  move.l  (a0)+, (a1)+
.lit5_mat7:  move.l  (a0)+, (a1)+
.lit3_mat7:  move.l  (a0)+, (a1)+
.lit1_mat7:  move.w  (a0)+, (a1)+
    COPY_MATCH 7

.litE_mat8:  move.l  (a0)+, (a1)+
.litC_mat8:  move.l  (a0)+, (a1)+
.litA_mat8:  move.l  (a0)+, (a1)+
.lit8_mat8:  move.l  (a0)+, (a1)+
.lit6_mat8:  move.l  (a0)+, (a1)+
.lit4_mat8:  move.l  (a0)+, (a1)+
.lit2_mat8:  move.l  (a0)+, (a1)+
.lit0_mat8:
    COPY_MATCH 8

.litF_mat8:  move.l  (a0)+, (a1)+
.litD_mat8:  move.l  (a0)+, (a1)+
.litB_mat8:  move.l  (a0)+, (a1)+
.lit9_mat8:  move.l  (a0)+, (a1)+
.lit7_mat8:  move.l  (a0)+, (a1)+
.lit5_mat8:  move.l  (a0)+, (a1)+
.lit3_mat8:  move.l  (a0)+, (a1)+
.lit1_mat8:  move.w  (a0)+, (a1)+
    COPY_MATCH 8

.litE_mat9:  move.l  (a0)+, (a1)+
.litC_mat9:  move.l  (a0)+, (a1)+
.litA_mat9:  move.l  (a0)+, (a1)+
.lit8_mat9:  move.l  (a0)+, (a1)+
.lit6_mat9:  move.l  (a0)+, (a1)+
.lit4_mat9:  move.l  (a0)+, (a1)+
.lit2_mat9:  move.l  (a0)+, (a1)+
.lit0_mat9:
    COPY_MATCH 9

.litF_mat9:  move.l  (a0)+, (a1)+
.litD_mat9:  move.l  (a0)+, (a1)+
.litB_mat9:  move.l  (a0)+, (a1)+
.lit9_mat9:  move.l  (a0)+, (a1)+
.lit7_mat9:  move.l  (a0)+, (a1)+
.lit5_mat9:  move.l  (a0)+, (a1)+
.lit3_mat9:  move.l  (a0)+, (a1)+
.lit1_mat9:  move.w  (a0)+, (a1)+
    COPY_MATCH 9

.litE_matA:  move.l  (a0)+, (a1)+
.litC_matA:  move.l  (a0)+, (a1)+
.litA_matA:  move.l  (a0)+, (a1)+
.lit8_matA:  move.l  (a0)+, (a1)+
.lit6_matA:  move.l  (a0)+, (a1)+
.lit4_matA:  move.l  (a0)+, (a1)+
.lit2_matA:  move.l  (a0)+, (a1)+
.lit0_matA:
    COPY_MATCH 10

.litF_matA:  move.l  (a0)+, (a1)+
.litD_matA:  move.l  (a0)+, (a1)+
.litB_matA:  move.l  (a0)+, (a1)+
.lit9_matA:  move.l  (a0)+, (a1)+
.lit7_matA:  move.l  (a0)+, (a1)+
.lit5_matA:  move.l  (a0)+, (a1)+
.lit3_matA:  move.l  (a0)+, (a1)+
.lit1_matA:  move.w  (a0)+, (a1)+
    COPY_MATCH 10

.litE_matB:  move.l  (a0)+, (a1)+
.litC_matB:  move.l  (a0)+, (a1)+
.litA_matB:  move.l  (a0)+, (a1)+
.lit8_matB:  move.l  (a0)+, (a1)+
.lit6_matB:  move.l  (a0)+, (a1)+
.lit4_matB:  move.l  (a0)+, (a1)+
.lit2_matB:  move.l  (a0)+, (a1)+
.lit0_matB:
    COPY_MATCH 11

.litF_matB:  move.l  (a0)+, (a1)+
.litD_matB:  move.l  (a0)+, (a1)+
.litB_matB:  move.l  (a0)+, (a1)+
.lit9_matB:  move.l  (a0)+, (a1)+
.lit7_matB:  move.l  (a0)+, (a1)+
.lit5_matB:  move.l  (a0)+, (a1)+
.lit3_matB:  move.l  (a0)+, (a1)+
.lit1_matB:  move.w  (a0)+, (a1)+
    COPY_MATCH 11

.litE_matC:  move.l  (a0)+, (a1)+
.litC_matC:  move.l  (a0)+, (a1)+
.litA_matC:  move.l  (a0)+, (a1)+
.lit8_matC:  move.l  (a0)+, (a1)+
.lit6_matC:  move.l  (a0)+, (a1)+
.lit4_matC:  move.l  (a0)+, (a1)+
.lit2_matC:  move.l  (a0)+, (a1)+
.lit0_matC:
    COPY_MATCH 12

.litF_matC:  move.l  (a0)+, (a1)+
.litD_matC:  move.l  (a0)+, (a1)+
.litB_matC:  move.l  (a0)+, (a1)+
.lit9_matC:  move.l  (a0)+, (a1)+
.lit7_matC:  move.l  (a0)+, (a1)+
.lit5_matC:  move.l  (a0)+, (a1)+
.lit3_matC:  move.l  (a0)+, (a1)+
.lit1_matC:  move.w  (a0)+, (a1)+
    COPY_MATCH 12

.litE_matD:  move.l  (a0)+, (a1)+
.litC_matD:  move.l  (a0)+, (a1)+
.litA_matD:  move.l  (a0)+, (a1)+
.lit8_matD:  move.l  (a0)+, (a1)+
.lit6_matD:  move.l  (a0)+, (a1)+
.lit4_matD:  move.l  (a0)+, (a1)+
.lit2_matD:  move.l  (a0)+, (a1)+
.lit0_matD:
    COPY_MATCH 13

.litF_matD:  move.l  (a0)+, (a1)+
.litD_matD:  move.l  (a0)+, (a1)+
.litB_matD:  move.l  (a0)+, (a1)+
.lit9_matD:  move.l  (a0)+, (a1)+
.lit7_matD:  move.l  (a0)+, (a1)+
.lit5_matD:  move.l  (a0)+, (a1)+
.lit3_matD:  move.l  (a0)+, (a1)+
.lit1_matD:  move.w  (a0)+, (a1)+
    COPY_MATCH 13

.litE_matE:  move.l  (a0)+, (a1)+
.litC_matE:  move.l  (a0)+, (a1)+
.litA_matE:  move.l  (a0)+, (a1)+
.lit8_matE:  move.l  (a0)+, (a1)+
.lit6_matE:  move.l  (a0)+, (a1)+
.lit4_matE:  move.l  (a0)+, (a1)+
.lit2_matE:  move.l  (a0)+, (a1)+
.lit0_matE:
    COPY_MATCH 14

.litF_matE:  move.l  (a0)+, (a1)+
.litD_matE:  move.l  (a0)+, (a1)+
.litB_matE:  move.l  (a0)+, (a1)+
.lit9_matE:  move.l  (a0)+, (a1)+
.lit7_matE:  move.l  (a0)+, (a1)+
.lit5_matE:  move.l  (a0)+, (a1)+
.lit3_matE:  move.l  (a0)+, (a1)+
.lit1_matE:  move.w  (a0)+, (a1)+
    COPY_MATCH 14

.litE_matF:  move.l  (a0)+, (a1)+
.litC_matF:  move.l  (a0)+, (a1)+
.litA_matF:  move.l  (a0)+, (a1)+
.lit8_matF:  move.l  (a0)+, (a1)+
.lit6_matF:  move.l  (a0)+, (a1)+
.lit4_matF:  move.l  (a0)+, (a1)+
.lit2_matF:  move.l  (a0)+, (a1)+
.lit0_matF:
    COPY_MATCH 15

.litF_matF:  move.l  (a0)+, (a1)+
.litD_matF:  move.l  (a0)+, (a1)+
.litB_matF:  move.l  (a0)+, (a1)+
.lit9_matF:  move.l  (a0)+, (a1)+
.lit7_matF:  move.l  (a0)+, (a1)+
.lit5_matF:  move.l  (a0)+, (a1)+
.lit3_matF:  move.l  (a0)+, (a1)+
.lit1_matF:  move.w  (a0)+, (a1)+
    COPY_MATCH 15

;// -------------------------------------------------------------------------------------------------
;// Aplib decruncher for MC68000 "gcc version"
;// by MML 2010
;// Size optimized (164 bytes) by Franck "hitchhikr" Charlet.
;// More optimizations by r57shell.
;// Further optimizations: inline get_bit (~30-50% speed gain),
;// unsigned offset comparisons, dead code removal, direct dbf on d2.
;//
;// aplibx_decrunch: A0 = Source / A1 = Destination / D0 Returns unpacked size
;// u32 aplibx_unpack(u8 *src, u8 *dest);
;// -------------------------------------------------------------------------------------------------

func aplibx_unpack
    movem.l 4(%a7),%a0-%a1

aplibx_decrunch:
    movem.l %a2/%a6/%d2-%d5,-(%a7)     ;// a3-a5 removidos (3 regs a menos)

    move.l  %a1,%a6
    moveq   #-128,%d3                   ;// bit buffer, bit 7 = sentinel

.copy_byte:
    move.b  (%a0)+,(%a1)+

.next_sequence_init:
    moveq   #2,%d1                      ;// LWM = 2 (apos literal)

.next_sequence:
    ;// ---- get_bit inline #1 ----
    add.b   %d3,%d3
    bne.b   .gs1_ok
    move.b  (%a0)+,%d3
    addx.b  %d3,%d3
.gs1_ok:
    bcc.b   .copy_byte                  ;// %0 -> byte literal

    ;// ---- get_bit inline #2 ----
    add.b   %d3,%d3
    bne.b   .gs2_ok
    move.b  (%a0)+,%d3
    addx.b  %d3,%d3
.gs2_ok:
    bcc.b   .code_pair                  ;// %10 -> code pair

    ;// ---- get_bit inline #3 ----
    moveq   #0,%d0
    add.b   %d3,%d3
    bne.b   .gs3_ok
    move.b  (%a0)+,%d3
    addx.b  %d3,%d3
.gs3_ok:
    bcc.b   .short_match                ;// %110 -> short match

    ;// %111 -> offset de 4 bits
    moveq   #4-1,%d5
.get_4_bits:
    add.b   %d3,%d3
    bne.b   .gb4_ok
    move.b  (%a0)+,%d3
    addx.b  %d3,%d3
.gb4_ok:
    roxl.l  #1,%d0
    dbf     %d5,.get_4_bits
    beq.b   .write_byte                 ;// offset 0 -> escrever 0x00

    move.l  %a1,%a2
    suba.l  %d0,%a2
    move.b  (%a2),%d0

.write_byte:
    move.b  %d0,(%a1)+
    bra     .next_sequence_init

.short_match:
    moveq   #3,%d2
    move.b  (%a0)+,%d0
    lsr.b   #1,%d0
    beq.b   .end_decrunch               ;// offset 0 -> fim da descompressao
    bcs.b   .domatch_new_lastpos
    moveq   #2,%d2
    bra.b   .domatch_new_lastpos

.code_pair:
    bsr     .decode_gamma
    sub.w   %d1,%d2
    bne.b   .normal_code_pair
    move.l  %d4,%d0                     ;// reusar old_offset
    bsr     .decode_gamma
    bra     .copy_code_pair

.normal_code_pair:
    subq.l  #1,%d2
    lsl.l   #8,%d2
    move.b  (%a0)+,%d2
    move.l  %d2,%d0
    bsr     .decode_gamma

    ;// Ajustar comprimento por range do offset (UNSIGNED)
    cmp.w   #128,%d0
    bcs.b   .lt_128                     ;// < 128: length += 2
    cmp.w   #1280,%d0
    bcs.b   .domatch_new_lastpos        ;// 128..1279: sem ajuste
    addq.l  #1,%d2
    cmp.w   #32000,%d0
    bcs.b   .domatch_new_lastpos        ;// 1280..31999: length += 1
    addq.l  #1,%d2                      ;// >= 32000: length += 2
    bra.b   .domatch_new_lastpos
.lt_128:
    addq.l  #2,%d2                      ;// < 128: length += 2

.domatch_new_lastpos:
    move.l  %d0,%d4                     ;// old_offset = offset
.copy_code_pair:
    move.l  %a1,%a2
    suba.l  %d0,%a2

    subq.w  #1,%d2                      ;// dbf precisa de N-1
.copy_loop:
    move.b  (%a2)+,(%a1)+
    dbf     %d2,.copy_loop

    moveq   #1,%d1                      ;// LWM = 1 (apos match)
    bra     .next_sequence

    .even
.decode_gamma:
    moveq   #1,%d2

.gamma_loop:
    add.b   %d3,%d3
    bne.b   .gb1_ok
    move.b  (%a0)+,%d3
    addx.b  %d3,%d3
.gb1_ok:
    addx.l  %d2,%d2

    add.b   %d3,%d3
    bne.b   .gb2_ok
    move.b  (%a0)+,%d3
    addx.b  %d3,%d3
.gb2_ok:
    bcs.b   .gamma_loop
    rts

.end_decrunch:
    move.l  %a1,%d0
    sub.l   %a6,%d0

    movem.l (%a7)+,%a2/%a6/%d2-%d5
    rts
