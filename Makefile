#### Toolchain ####
CC 	:= $(PREFIX)avr-gcc
CXX	:= $(PREFIX)avr-g++
OBJCOPY := $(PREFIX)avr-objcopy
SIZE    := $(PREFIX)avr-size
NM      := $(PREFIX)avr-nm
AVRDUDE := $(PREFIX)avrdude
RM	:= rm -f

CXX_EMBEDDED_OPTS := -fno-exceptions -fno-rtti

#### Project settings ####
MCU		:= attiny414
TARGET  := image
CFLAGS  := -std=c99 -Wall -O2
CXXFLAGS  := -Wall -O2

LDFLAGS := \
	-Wl,--gc-sections \
	-Wl,--print-gc-sections

LIBS := 

#### AVRDUDE settings ####
AVRDUDE_MCU 		:= t414
AVRDUDE_PROGRAMMER  := serialupdi
AVRDUDE_BAUD		:= 9600
AVRDUDE_PORT		:= /dev/ttyAMA1

AVRDUDE_FLAGS := \
	-p $(AVRDUDE_MCU) \
	-c $(AVRDUDE_PROGRAMMER) \
	-P $(AVRDUDE_PORT) \
	-b $(AVRDUDE_BAUD) \


#### Definitions ####
C_SRC := $(wildcard *.c)
CXX_SRC := $(wildcard *.cpp)
C_HEADERS := $(wildcard *.h)
CXX_HEADERS := $(wildcard *.hpp)
C_OBJ := $(C_SRC:.c=.o)
CXX_OBJ := $(CXX_SRC:.cpp=.o)
OBJS  := $(C_OBJ) $(CXX_OBJ)

ifeq ($(V), 1)
	VERBOSE := 1
endif


AT := $(if $(VERBOSE),,@)
ECHO := $(if $(VERBOSE),##,echo)

#### Targets ####
.PHONY: all clean size flash

all: $(TARGET).hex

%.o: %.c Makefile $(C_HEADERS)
	@$(ECHO) CC "      " $@
	$(AT) $(CC) -imacros config.h -Iinclude -c $< -mmcu=$(MCU) $(CFLAGS) -o $@

%.o: %.cpp Makefile $(CXX_HEADERS)
	@$(ECHO) CXX "     " $@
	$(AT) $(CXX) -c $< -mmcu=$(MCU) $(CXX_EMBEDDED_OPTS) $(CXXFLAGS) -o $@

%.hex: %.elf Makefile
	@$(ECHO) OBJCOPY " " $@
	$(AT) $(OBJCOPY) -O ihex -j .text -j .rodata -j .data  $< $@

$(TARGET).elf: $(OBJS) Makefile
	@$(ECHO) LD "      " $@
	$(AT) $(CC) -mmcu=$(MCU) -o $@ $(OBJS) $(LDFLAGS) $(LIBS)

flash: $(TARGET).hex
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U flash:w:$(TARGET).hex

remote-flash: $(TARGET).hex
	scp $< rpi.tmf:/tmp/$<
	ssh rpi.tmf /usr/local/bin/avrdude $(AVRDUDE_FLAGS) -U flash:w:/tmp/$^

fuses:
	$(AVRDUDE) $(AVRDUDE_FLAGS) -U lfuse:w:$(LFUSE):m -U hfuse:w:$(HFUSE):m

clean:
	$(RM) $(OBJS) $(TARGET).elf $(TARGET).hex

size: $(TARGET).elf
	$(SIZE) $(TARGET).elf

analyze: $(TARGET).elf
	$(NM) -S --size-sort -t decimal $(TARGET).elf
