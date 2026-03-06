CA65 ?= ca65
LD65 ?= ld65

BUILD_DIR := build
SRC_DIR := src
EXAMPLES_DIR := examples
CFG := kim1.cfg

CA65FLAGS ?= -g
LD65FLAGS ?=

GAME_SRC := $(SRC_DIR)/asteroids_game.s
DEMO_SRC := $(EXAMPLES_DIR)/read_controller_demo.s

GAME_OBJ := $(BUILD_DIR)/asteroids_game.o
DEMO_OBJ := $(BUILD_DIR)/read_controller_demo.o

GAME_BIN := $(BUILD_DIR)/asteroids_game.bin
DEMO_BIN := $(BUILD_DIR)/read_controller_demo.bin

.PHONY: all clean dirs

all: $(GAME_BIN) $(DEMO_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

dirs: $(BUILD_DIR)

$(GAME_OBJ): $(GAME_SRC) $(SRC_DIR)/nes_controller.s | $(BUILD_DIR)
	$(CA65) $(CA65FLAGS) -o $@ $<

$(DEMO_OBJ): $(DEMO_SRC) $(SRC_DIR)/nes_controller.s | $(BUILD_DIR)
	$(CA65) $(CA65FLAGS) -o $@ $<

$(GAME_BIN): $(GAME_OBJ) $(CFG) | $(BUILD_DIR)
	$(LD65) $(LD65FLAGS) -C $(CFG) -o $@ $<

$(DEMO_BIN): $(DEMO_OBJ) $(CFG) | $(BUILD_DIR)
	$(LD65) $(LD65FLAGS) -C $(CFG) -o $@ $<

clean:
	rm -rf $(BUILD_DIR)
