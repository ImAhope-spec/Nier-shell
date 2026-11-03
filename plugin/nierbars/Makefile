# Else exist specifically for clang
ifeq ($(CXX),g++)
    EXTRA_FLAGS = --no-gnu-unique
else
    EXTRA_FLAGS =
endif

CXXFLAGS ?= -O2
CXXFLAGS += -shared -fPIC -std=c++2b -Wno-c++11-narrowing
INCLUDES = `pkg-config --cflags pixman-1 libdrm hyprland libinput libudev wayland-server xkbcommon`
LIBS =
NIER_DEFS ?=

SRC = main.cpp barDeco.cpp BarPassElement.cpp
TARGET = nierbars.so

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) $(LDFLAGS) $(EXTRA_FLAGS) $(INCLUDES) $(NIER_DEFS) $^ $> -o $@ $(LIBS)

clean:
	rm ./$(TARGET)

meson-build:
	mkdir -p build
	cd build && meson .. && ninja

.PHONY: all meson-build clean
