CC := gcc
CFLAGS := -Wall -Wno-incompatible-function-pointer-types

# Detect OS
UNAME_S := $(shell uname -s)

# macOS specific settings
ifeq ($(UNAME_S),Darwin)
    CFLAGS += -I/opt/homebrew/include
    LIBS := -L/opt/homebrew/lib -lusb -lm
else
    # Linux settings
    LIBS := -lusb -lrt -lm
endif

ifeq ($(UNAME_S),Darwin)
    td-usb: td-usb.c device_types.c ./linux/tdhid-libusb.c ./macos/tdtimer-macos.c tddevice.c ./devices/*.c
	    $(CC) $(CFLAGS) td-usb.c device_types.c tddevice.c ./linux/tdhid-libusb.c ./macos/tdtimer-macos.c ./devices/*.c -o td-usb $(LIBS)
else
    td-usb: td-usb.c device_types.c ./linux/tdhid-libusb.c ./linux/tdtimer-posix.c tddevice.c ./devices/*.c
	    $(CC) $(CFLAGS) td-usb.c device_types.c tddevice.c ./linux/tdhid-libusb.c ./linux/tdtimer-posix.c ./devices/*.c -o td-usb $(LIBS)
endif

clean:
	rm td-usb
	rm -f *.o
