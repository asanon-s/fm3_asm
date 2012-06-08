/* define constants */
	.equ	STACK_TOP,		0x2000800
	.equ	FM3_FLASH_IF_BASE,	0x40000000
	.equ	FM3_CRG_BASE,		0x40010000
	.equ	FM3_HWWDT_BASE,		0x40011000
	.equ	FM3_CRTRIM_BASE,	0x4002E000
	.equ	FM3_HWWDT_LOCK,		0xc00
	.equ	FM3_HWWDT_CTL,		0x008
	.equ	FM3_CRG_BSC_PSR,	0x10
	.equ	FM3_CRG_APBC0_PSR,	0x14
	.equ	FM3_CRG_APBC1_PSR,	0x18
	.equ	FM3_CRG_APBC2_PSR,	0x1C
	.equ	FM3_CRG_SWC_PSR,	0x20
	.equ	FM3_CRG_TTC_PSR,	0x28
	.equ	FM3_CRG_CSW_TMR,	0x30
	.equ	FM3_CRG_PSW_TMR,	0x34
	.equ	FM3_CRTRIM_MCR_RLR,	0x0c
	.equ	FM3_CRTRIM_MCR_FTRM,	0x04
	.equ	FM3_CRG_SCM_CTL,	0x00
	.equ	FM3_CRG_SCM_STR,	0x04
	.equ	FM3_FLASH_IF_CRTRMM,	0x100
	.equ	FM3_CRG_PSW_TMR,	0x34
	.equ	FM3_CRG_PLL_CTL1,	0x38
	.equ	FM3_CRG_PLL_CTL2,	0x3c
	/* consts */
	.equ	FM3_UNLOCK,		0x1ACCE551
	.text
	.global	_init
	.global InputData
	.global Result
	.code	16
	.syntax	unified
_init:
	.word	STACK_TOP, init
	.type	init, function
	/* Start of main program */

init:	
	/* stop hardware watchdog timer */
	ldr	r1, =FM3_HWWDT_BASE	@ hardware watchdog timer base
	ldr	r0, =FM3_UNLOCK		@ unlock watchdog timer register
	str	r0, [r1, #FM3_HWWDT_LOCK]

	eor	r0, 0xffffffff		@ unlock hwwd configuration register
	str	r0, [r1, #FM3_HWWDT_LOCK]

	ldr	r0, =0		@ stop hwwd timer
	str	r0, [r1, #FM3_HWWDT_CTL]

	/* clock configuration ref: "mn706 00002 5v0 j" fig 4-1 */
	ldr	r1, =FM3_CRG_BASE @ base clock prescaler
	mov	r0, #0	
	strb	r0, [r1, #FM3_CRG_BSC_PSR]
	
	mov	r0, #0x02	@ prescaler
	strb	r0, [r1, #FM3_CRG_APBC0_PSR]
	
	mov	r0, #0x82	@ prescaler, enable PCLK1, 1/4
	strb	r0, [r1, #FM3_CRG_APBC1_PSR]

	mov	r0, #0x82	@ prescaler, enable PCLK2, 1/4
	strb	r0, [r1, #FM3_CRG_APBC2_PSR]

	mov	r0, #0x83	@ software prescaler, enable test b, 1/8
	strb	r0, [r1, #FM3_CRG_SWC_PSR]

	mov	r0, #0		@ trace clock prescaler register
	strb	r0, [r1, #FM3_CRG_TTC_PSR]

	mov	r0, #0x5C	@ clock stabilization timer
	strb	r0, [r1, #FM3_CRG_CSW_TMR]

	ldrb	r0, [r1, #FM3_CRG_SCM_CTL] @ read SCM_CTL
	orr	r0, r0, #0x2		@ main clock enable
	strb	r0, [r1, #FM3_CRG_SCM_CTL]

	/* wait */
mordy_loop:	
	ldrb	r0, [r1, #FM3_CRG_SCM_STR] @ read
	and	r0, #0x02
	cbnz	r0, mordy_next	@ if r0 == 0 then goto mordy_loop
	b	mordy_loop	@ loop 

mordy_next:
	mov	r0, #0x00		@ set PLL wait time
	strb	r0, [r1, #FM3_CRG_PSW_TMR]

	mov	r0, #0x01		@ set VCO clock as 1/2
	strb	r0, [r1, #FM3_CRG_PLL_CTL1]

	mov	r0, #0x23		@ set PLL feedback as 1/36 
	strb	r0, [r1, #FM3_CRG_PLL_CTL2]

	ldrb	r0, [r1, #FM3_CRG_SCM_CTL] @ PLL enable
	orr	r0, #0x10
	strb	r0, [r1, #FM3_CRG_SCM_CTL]

pll_loop:
	ldrb	r0, [r1, #FM3_CRG_SCM_STR] @ read
	and	r0, #0x10
	cbnz	r0, pll_next	@ if r0 == 0 then goto pll_loop
	b	pll_loop

pll_next:	
	ldrb	r0, [r1, #FM3_CRG_SCM_CTL] @ change master clock to PLL
	orr	r0, #0x40
	strb	r0, [r1, #FM3_CRG_SCM_CTL]
	and	r0, #0xE0
mstclk_wait:
	ldrb	r2, [r1, #FM3_CRG_SCM_STR]
	and	r2, #0xE0
	cmp	r0, r2
	bne	mstclk_wait	@ if r0 != r2, then goto mstclk_wait

	/* configure CR trimming */
	ldr	r1, =FM3_FLASH_IF_BASE
	ldr	r0, [r1, #FM3_FLASH_IF_CRTRMM]
	ldr	r2, =0x000003ff
	and	r0, r2
	cmp	r0, r2
	beq	crtrim_done

	ldr	r1, =FM3_CRTRIM_BASE
	ldr	r0, =FM3_UNLOCK
	str	r0, [r1, #FM3_CRTRIM_MCR_RLR]	@ unlock

	ldr	r1, =FM3_FLASH_IF_BASE @ read from FLASH
	ldr	r0, [r1, #FM3_FLASH_IF_CRTRMM]
	ldr	r1, =FM3_CRTRIM_BASE
	str	r0, [r1, #FM3_CRTRIM_MCR_FTRM] @ write to config reg

	mov	r0, #0
	str	r0, [r1, #FM3_CRTRIM_MCR_RLR]	@ lock

crtrim_done:
	mov	r0, #0		@ clear registers
	mov	r1, #0		
	mov	r2, #0
	b	_start		@ jump to start function

	.end
	
