VERILATOR = verilator
TOP_MODULE = ascon_verilator_wrapper
SRC_DIR = ../rtl
SRC_FILES = $(SRC_DIR)/ascon_verilator_wrapper.sv $(SRC_DIR)/ascon_core.sv $(SRC_DIR)/config.sv $(SRC_DIR)/functions.sv $(SRC_DIR)/asconp.sv
CXX_SRCS = tb_ascon.cpp

OBJ_DIR = obj_dir
BIN = sim_out

all: $(BIN)

$(BIN): $(SRC_FILES) $(CXX_SRCS)
	$(VERILATOR) --cc --exe --build --trace \
		-I$(SRC_DIR) \
		--top-module $(TOP_MODULE) \
		$(SRC_FILES) $(CXX_SRCS)

run: $(BIN)
	./$(OBJ_DIR)/V$(TOP_MODULE)

clean:
	rm -rf $(OBJ_DIR) $(BIN)

.PHONY: all run clean
