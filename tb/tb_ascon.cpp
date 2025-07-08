#include <verilated.h>
#include "Vascon_verilator_wrapper.h"
#include <iostream>
#include <vector>
#include <cassert>

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

void tick(Vascon_verilator_wrapper* top) {
    top->clk = 0;
    top->eval();
    main_time++;

    top->clk = 1;
    top->eval();
    main_time++;
}

void reset(Vascon_verilator_wrapper* top, int cycles = 5) {
    top->rst = 1;
    for (int i = 0; i < cycles; ++i) tick(top);
    top->rst = 0;
    tick(top);
}

void load_key(Vascon_verilator_wrapper* top, const std::vector<uint32_t>& key) {
    for (auto word : key) {
        top->key = word;
        top->key_valid = 1;
        do {
            tick(top);
        } while (!top->key_ready);
        top->key_valid = 0;
        tick(top);
    }
}

void send_data(Vascon_verilator_wrapper* top, const std::vector<uint32_t>& data, uint8_t type) {
    for (auto word : data) {
        top->bdi = word;
        top->bdi_type = type;
        top->bdi_valid = 0xF;
        top->bdi_eot = 0;
        top->bdi_eoi = 0;
        do {
            tick(top);
        } while (!top->bdi_ready);
        top->bdi_valid = 0;
        tick(top);
    }
}

void read_output(Vascon_verilator_wrapper* top) {
    while (!top->done) {
        tick(top);
        if (top->bdo_valid) {
            std::cout << "Output: 0x" << std::hex << top->bdo << std::endl;
        }
    }
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    auto* top = new Vascon_verilator_wrapper;

    reset(top);

    // Example key, plaintext, associated data (replace with actual test vectors)
    std::vector<uint32_t> key = {0x00112233, 0x44556677, 0x8899aabb, 0xccddeeff};
    std::vector<uint32_t> nonce = {0x12345678, 0x9abcdef0};
    std::vector<uint32_t> ad = {0xdeadbeef};
    std::vector<uint32_t> pt = {0x11223344, 0x55667788};

    top->mode = 0x1; // Example mode, replace by correct enum

    load_key(top, key);
    send_data(top, nonce, 0x1); // nonce type
    send_data(top, ad, 0x2);    // AD type
    send_data(top, pt, 0x3);    // PT type

    read_output(top);

    delete top;
    return 0;
}
