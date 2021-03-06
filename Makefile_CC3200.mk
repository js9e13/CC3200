# Makefile for CC3200
# Author: Yubo Zhi (normanzyb@gmail.com)

TOPDIR	?= $(dir $(lastword $(MAKEFILE_LIST)))
TOPDIR	:= $(TOPDIR)

SDK	?= $(TOPDIR)/cc3200-sdk

# To choose a programming tool for specific platform,
# write a Makefile_platform.mk file.
# However this has no effect on compiling,
# so if flashing is not required then this can be ignored.
#
# * PROGCOM: COM port connected to CC3200 UART interface
#
# e.g. on Windows:
# PROGCOM	= 10
# include $(TOPDIR)/platform/windows/Makefile.mk
#
# e.g. on Linux:
# PROGCOM	= /dev/ttyACM0
# include $(TOPDIR)/platform/linux/Makefile.mk
#
-include $(TOPDIR)/Makefile_platform.mk

OBJCOPY	= $(CROSS_COMPILE)objcopy
OBJDUMP	= $(CROSS_COMPILE)objdump

# Cross compile defines
CROSS_COMPILE	= arm-none-eabi-
SUFFIX	= .axf

# Definitions
CPU	= -mcpu=cortex-m4
#FPU	= -mfpu=fpv4-sp-d16 -mfloat-abi=softfp
MCU_FREQ	= 80000000

DEFS	+= -DF_CPU=$(MCU_FREQ)
INCDIRS	+= $(SDK)/inc $(SDK)/driverlib
LIBS	+= $(SDK)/driverlib/gcc/exe/libdriver.a
OPTLEVEL	?= 0

# Rules
ifndef LIBTRG
EXTRA_TARGETS	+= lst bin
PHONYTRGS	+= lst
endif

include $(TOPDIR)/Makefile_generic.mk

#
# Get the location of libgcc.a from the GCC front-end.
#
LIBGCC:=${shell ${CC} -mthumb -print-libgcc-file-name}

#
# Get the location of libc.a from the GCC front-end.
#
LIBC:=${shell ${CC} -print-file-name=libc.a}

#
# Get the location of libm.a from the GCC front-end.
#
LIBM:=${shell ${CC} -print-file-name=libm.a}

ASFLAG	+= -mthumb \
	   ${CPU}  \
	   ${FPU}  \
	   -MD

CFLAG	+= -mthumb             \
	   ${CPU}              \
	   ${FPU}              \
	   -ffunction-sections \
	   -fdata-sections     \
	   -MD                 \
	   -std=c99            \
	   -g

LDFLAG	+= --gc-sections --entry ${ENTRY} '${LIBM}' '${LIBC}' '${LIBGCC}'

# Following are not needed when building libraries
ifndef LIBTRG

# Rules for building the binary image
PHONYTRGS	+= bin

%.bin: %.axf
	$(call verbose,"GEN	$@",\
	$(OBJCOPY) -O binary $< $@)

# For program
.PHONY: flash

flash: bin
	$(PROGRAM)

endif

# PHONY targets
.PHONY: $(PHONYTRGS)
$(PHONYTRGS): %: $(TRG).%
CLEAN_FILES	+= $(PHONYTRGS:%=$(TRG).%)
