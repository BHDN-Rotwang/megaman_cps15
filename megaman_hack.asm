 org  0
   incbin  "build\megaman.bin"
   
qsound_fifo_offset = -$7000
qsound_fifo_head_offset = -$6000
qsound_fifo_tail_offset = -$5FE0

 org $000A9A
	jmp Do_Qsound_Test

 org $01C744
	jmp Initialize_QSound_Fifo

 org $000E52
	jmp Hijack_More_Init

 org $01C6E6
	jmp Hijack_Upload_Audio_Commands

 org $01C714
	jmp Hijack_Add_Audio_Command_To_Fifo
   
; ==============================
;
; QSound screen in attract mode
;
; ==============================
 
 org $18F0
	dc.w	$10

; Free space
 org $163C00
 
;----------------
 Do_Qsound_Test:
	cmpi.l  #$5642194, D0
	cmpi.b  #$77, $f19fff.l
	bne     Do_Qsound_Test ; Wait loop

	lea     $f18000.l, A0 ; QSound mem
	lea     ($1ffe,A0), A1 ; Length
	
	movea.l A0, A3
	move.w  #$1, D1
	moveq   #$0, D3

Do_Qsound_Test_Loop:
	move.w  tbl_qsound_test_data(PC,D3.w), D0
	lea     (A3), A0

Do_Qsound_Test_Loop_2:
	cmpi.l  #$5642194, D0
	move.w  D0, (A0)
	cmp.b   ($1,A0), D0
	;bne     $d6e

	lea     ($2,A0), A0
	cmpa.l  A1, A0
	bls     Do_Qsound_Test_Loop_2

	addq.w  #2, D3
	dbra    D1, Do_Qsound_Test_Loop 
	
Clear_Qsound_Ram:
	lea     $F18000.l, A0
	lea     $F19ff9.l, A1
	moveq   #-$1, D0
  
Clear_Qsound_Ram_Loop:
	cmpi.l  #$5642194, D0
	move.w  D0, (A0)+
	cmpa.l  A1, A0
	bls     Clear_Qsound_Ram_Loop

	lea     $ab4, A6
	jmp     (A6)

tbl_qsound_test_data:
	dc.w	$0000, $5555
;----------------

;----------------
Initialize_QSound_Fifo:
  move.w  #$ff, D6 ; Loop count
  lea     (qsound_fifo_offset,A5), A0

  moveq   #$0, D0
 
Initialize_QSound_Fifo_Loop:
  move.l  D0, (A0)+
  move.l  D0, (A0)+
  move.l  D0, (A0)+
  move.l  D0, (A0)+
  dbra    D6, Initialize_QSound_Fifo_Loop
 
  move.l  D0, (qsound_fifo_tail_offset,A5) ; Clear fifo tail
  move.l  D0, (qsound_fifo_head_offset,A5) ; Clear fifo head

  rts
;----------------

;----------------
Hijack_More_init:
	move.b  #$88, $f19ffb.l
	move.b  #$0, $f19ffd.l
	move.b  #$ff, $f19fff.l

	; Original code from 000ECA
	lea     $ff8000.l, A7
	lea     $ff8000.l, A5
	moveq   #$0, D0
	; Original code from 000ECA

	jmp $000E60
;----------------

;----------------
Hijack_Upload_Audio_Commands:
;  moveq   #$0, D0 ; Ignore stereo on sounds
  
;  tst.b   ($19a,A5)
;  beq     Hijack_Upload_Audio_Commands_Continue

  moveq   #-$1, D0 ; Handle stereo
  
Hijack_Upload_Audio_Commands_Continue:
  move.b  D0, $F19ffd.l

  move.w  (qsound_fifo_head_offset,A5), D0 ; Fifo head
  cmp.w   (qsound_fifo_tail_offset,A5), D0 ; Compare against fifo tail
  beq     Hijack_Upload_Audio_Commands_Exit

  cmpi.b  #-$1, $F1801f.l
  bne     Hijack_Upload_Audio_Commands_Exit

  lea     (qsound_fifo_offset,A5), A4 ; Load fifo location
  move.w  (qsound_fifo_head_offset,A5), D0 ; Load fifo index
  move.b  (A4,D0.w), $F18007.l
  move.b  ($1,A4,D0.w), $F18009.l
  move.b  ($2,A4,D0.w), $F18001.l
  move.b  ($3,A4,D0.w), $F18003.l
  move.b  ($4,A4,D0.w), $F18005.l
  move.b  ($5,A4,D0.w), $F1800d.l
  move.b  ($6,A4,D0.w), $F1800f.l
  move.b  ($7,A4,D0.w), $F18011.l
  move.b  ($8,A4,D0.w), $F18017.l
  move.b  ($9,A4,D0.w), $F18019.l
  move.b  ($a,A4,D0.w), $F18013.l
  move.b  ($b,A4,D0.w), $F18015.l
  move.b  #$0, $F1801f.l
  addi.w  #$10, D0
  andi.w  #$ff0, D0
  move.w  D0, (qsound_fifo_head_offset,A5) ; Update fifo head
  
Hijack_Upload_Audio_Commands_Exit:
  rts
;----------------

;----------------
Hijack_Add_Audio_Command_To_Fifo:
	lsl.l   #$1, D1
	move.w  tbl_sound_mappings(PC,D1.w), D1	

	moveq   #$0, D2
	moveq   #$0, D3

Add_Audio_Command_To_Fifo_No_Stereo
	tst.b   ($92,A5)
	bne     Add_Audio_Command_To_Fifo_Continue

	tst.b   ($81,A5)
	bne     Add_Audio_Command_To_Fifo_Exit

Add_Audio_Command_To_Fifo_Continue:
	lea     (qsound_fifo_offset,A5), A4 ; Load fifo address
	move.w  (qsound_fifo_tail_offset,A5), D0 ; Fifo tail
	move.l  D1, (A4,D0.w)
	move.l  D2, ($4,A4,D0.w)
	move.l  D3, ($8,A4,D0.w)
	addi.w  #$10, D0
	andi.w  #$ff0, D0
	move.w  D0, (qsound_fifo_tail_offset,A5) ; Udate Fifo tail

Add_Audio_Command_To_Fifo_Exit:
    moveq   #$0, D1
	rts
;----------------

tbl_sound_mappings:
	incbin "sound_mappings.bin"
