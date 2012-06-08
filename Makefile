#########################################################################
#									#
#	Makefile							#
#	ref: http://www.zap.org.au/elec2041-cdrom/examples/templates/Makefile.template-asm #
#									#
#########################################################################

# Variables

TARGET		= example1
AS        = arm-none-eabi-as
LD        = arm-none-eabi-ld
DUMP	  = arm-none-eabi-objdump
CP	  = cp

ASFLAGS   = --gdwarf2
LDFLAGS   = -T cq_frk_fm3_rom.ld
LOADLIBES =
LDLIBS    =

# Jobs
all:		start.o $(TARGET).out
$(TARGET).out:	$(TARGET).o
$(TARGET).o:	$(TARGET).s
start.o:	start.s
clean:
	-rm -f $(TARGET).out $(TARGET).o start.o $(TARGET).list
%.o: %.s
	$(AS) -mcpu=cortex-m3 -mthumb $(ASFLAGS) $< -o $@
%.out:
	$(LD) $(LDFLAGS) $+ $(LOADLIBES) $(LDLIBS) -o $@
	$(DUMP) -S $(TARGET).out >> $(TARGET).list
	$(CP)	$(TARGET).out ../

# Rules

.PHONY:	all clean
.DEFAULT:
.SUFFIXES:
