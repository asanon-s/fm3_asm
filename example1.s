	.text
	.global	_start
	.code	16
	.syntax	unified
	.type	_start, function
_start:
	/* Start of main program */

	movs	R0, #10
	movs	R1, #0
	/* Calculate 10+9+8+...+1 */

loop:
	adds	R1, R0
	subs	R0, #1
	bne	loop
	/* Result is now in R1 */
@	ldr	R0, =Result
@	str	R1, [R0]
deadloop:
	b	deadloop
	.end
	
