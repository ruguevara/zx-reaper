; Interrupt vector table for IM 2: 257 bytes of $85
;
; With I = $84 (set by StartUp) the CPU reads the vector from $84xx, where xx
; is whatever the data bus carries during the interrupt acknowledge ($FF on a
; Spectrum, but not guaranteed). All 257 bytes are $85, so every vector is
; $8585, the interrupt handler InterruptHandler (the table is one byte longer
; than a page so that the vector for $FF, read from $84FF and $8500, is also
; $8585).
;
; Hardware: read by the CPU during the 50 Hz frame interrupt.
Im2Table:
  DEFS $0101,$85
