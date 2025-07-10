#include <verilated.h>
#include "Vascon_verilator_wrapper.h"
#include <iostream>
#include <vector>
#include <string>
#include <cassert>
#include <iomanip>
#include "verilated_vcd_c.h"

VerilatedVcdC* tfp = new VerilatedVcdC;

vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

void tick(Vascon_verilator_wrapper* top) {
    top->clk = 0; top->eval(); main_time++; tfp->dump(main_time++);
    top->clk = 1; top->eval(); main_time++; tfp->dump(main_time++);
}

void reset(Vascon_verilator_wrapper* top, int cycles = 5) {
    top->rst = 1;
    for (int i = 0; i < cycles; ++i) tick(top);
    top->rst = 0;
    tick(top);
}

std::vector<uint32_t> hex_to_u32(const std::string& hex) {
    std::vector<uint32_t> res;
    for (size_t i = 0; i < hex.size(); i += 8) {
        res.push_back(static_cast<uint32_t>(std::stoul(hex.substr(i, 8), nullptr, 16)));
    }
    return res;
}

bool run_aead_encrypt(Vascon_verilator_wrapper* top, const std::string& key, const std::string& nonce,
                      const std::string& pt, const std::string& ad, const std::string& expected) {

    auto k = hex_to_u32(key);
    auto npub = hex_to_u32(nonce);
    auto plaintext = hex_to_u32(pt);
    auto assoc = hex_to_u32(ad);
    auto expected_out = hex_to_u32(expected);

    std::cout << "Starting run_aead_encrypt..." << std::endl;
    reset(top);
    top->mode = 1;  // Encrypt
    tick(top);      // BẮT BUỘC: Để FSM thoát khỏi IDLE
    top->mode = 0;  // Clear để tránh giữ mode trong các chu kỳ sau


    for (auto w : k) { top->key = w; top->key_valid = 1; do { tick(top); } while (!top->key_ready); top->key_valid = 0; tick(top); }
    for (auto w : npub) { top->bdi = w; top->bdi_type = 1; top->bdi_valid = 0xF; do { tick(top); } while (!top->bdi_ready); top->bdi_valid = 0; tick(top); }
    for (auto w : assoc) { top->bdi = w; top->bdi_type = 2; top->bdi_valid = 0xF; do { tick(top); } while (!top->bdi_ready); top->bdi_valid = 0; tick(top); }
    for (auto w : plaintext) { top->bdi = w; top->bdi_type = 3; top->bdi_valid = 0xF; do { tick(top); } while (!top->bdi_ready); top->bdi_valid = 0; tick(top); }
    
    size_t idx = 0;
    while (!top->done) {
        std::cout << "!top->done" << std::endl;
        tick(top);
        if (top->bdo_valid && idx < expected_out.size()) {
            if (top->bdo != expected_out[idx]) return false;
            idx++;
        }
    }
    return true;
}

bool run_aead_decrypt(Vascon_verilator_wrapper* top, const std::string& key, const std::string& nonce,
                      const std::string& ct_with_tag, const std::string& ad, const std::string& expected_pt) {

    auto k = hex_to_u32(key);
    auto npub = hex_to_u32(nonce);
    auto ciphertext = hex_to_u32(ct_with_tag);
    auto assoc = hex_to_u32(ad);
    auto expected_out = hex_to_u32(expected_pt);

    reset(top);
    top->mode = 2;  // Decrypt
    tick(top);
    top->mode = 0;

    for (auto w : k) { top->key = w; top->key_valid = 1; do { tick(top); } while (!top->key_ready); top->key_valid = 0; tick(top); }
    for (auto w : npub) { top->bdi = w; top->bdi_type = 1; top->bdi_valid = 0xF; do { tick(top); } while (!top->bdi_ready); top->bdi_valid = 0; tick(top); }
    for (auto w : assoc) { top->bdi = w; top->bdi_type = 2; top->bdi_valid = 0xF; do { tick(top); } while (!top->bdi_ready); top->bdi_valid = 0; tick(top); }
    for (auto w : ciphertext) { top->bdi = w; top->bdi_type = 3; top->bdi_valid = 0xF; do { tick(top); } while (!top->bdi_ready); top->bdi_valid = 0; tick(top); }

    size_t idx = 0;
    while (!top->done) {
        tick(top);
        if (top->bdo_valid && idx < expected_out.size()) {
            if (top->bdo != expected_out[idx]) return false;
            idx++;
        }
    }
    return true;
}

bool run_hash(Vascon_verilator_wrapper* top, size_t msg_len, const std::vector<uint32_t>& expected) {
    reset(top);
    top->mode = 3;
    tick(top);
    top->mode = 0;

    for (size_t i = 0; i < msg_len; i += 4) {
        uint32_t w = ((i+3) << 24) | ((i+2) << 16) | ((i+1) << 8) | i;
        top->bdi = w;
        top->bdi_type = 0;
        top->bdi_valid = 0xF;
        do { tick(top); } while (!top->bdi_ready);
        top->bdi_valid = 0;
        tick(top);
    }

    size_t idx = 0;
    while (!top->done) {
        tick(top);
        if (top->bdo_valid && idx < expected.size()) {
            if (top->bdo != expected[idx]) return false;
            idx++;
        }
    }
    return true;
}

int main(int argc, char** argv) {
    std::cout << "Starting simulation..." << std::endl;
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);  // enable trace globally
    auto* top = new Vascon_verilator_wrapper;

    top->trace(tfp, 99);  // depth 99 là đủ cho các module nhỏ
    tfp->open("ascon_trace.vcd");   

    std::vector<std::tuple<std::string, std::string, std::string, std::string, std::string>> aead_kats = {
        {"000102030405060708090A0B0C0D0E0F", "000102030405060708090A0B0C0D0E0F", "",     "",     "4427D64B8E1E1451FC445960F0839BB0"},
        {"000102030405060708090A0B0C0D0E0F", "000102030405060708090A0B0C0D0E0F", "",     "00",   "103AB79D913A0321287715A979BB8585"},
        {"000102030405060708090A0B0C0D0E0F", "000102030405060708090A0B0C0D0E0F", "",     "0001", "A50E88E30F923B90A9C810181230DF10"},
        {"000102030405060708090A0B0C0D0E0F", "000102030405060708090A0B0C0D0E0F", "",     "000102", "AE214C9F66630658ED8DC7D31131174C"},
        {"000102030405060708090A0B0C0D0E0F", "000102030405060708090A0B0C0D0E0F", "",     "00010203", "C6FF3CF70575B144B955820D9BC7685E"},
    };

    std::vector<std::vector<uint32_t>> hash_kats = {
        {0x0B3BE585,0x0F2F6B98,0xCAF29F8F,0xDEA89B64,0xA1FA70AA,0x249B8F83,0x9BD53BAA,0x304D92B2},
        {0x07286210,0x35AF3ED2,0xBCA03BF6,0xFDE900F9,0x456F5330,0xE4B5EE23,0xE7F6A1E7,0x0291BC80},
        {0x6115E7C9,0xC4081C27,0x97FC8FE1,0xBC57A836,0xAFA1C538,0x1E556DD5,0x83860CA2,0xDFB48DD2},
        {0x265AB89A,0x609F5A05,0xDCA57E83,0xFBBA700F,0x9A2D2C42,0x11BA4CC9,0xF0A1A369,0xE17B915C},
        {0xD7E4C7ED,0x9B8A325C,0xD08B9EF2,0x59F88770,0x54ECD830,0x4FE1B2D7,0xFD847137,0xDF6727EE},
    };

    for (size_t i = 0; i < aead_kats.size(); ++i) {
        auto& [k, n, pt, ad, ct] = aead_kats[i];
        bool enc_ok = run_aead_encrypt(top, k, n, pt, ad, ct);
        std::cout << "AEAD encrypt vector " << i << ": " << (enc_ok ? "PASS" : "FAIL") << std::endl;

        bool dec_ok = run_aead_decrypt(top, k, n, ct, ad, pt);
        std::cout << "AEAD decrypt vector " << i << ": " << (dec_ok ? "PASS" : "FAIL") << std::endl;
    }

    for (size_t i = 0; i < hash_kats.size(); ++i) {
        bool ok = run_hash(top, i, hash_kats[i]);
        std::cout << "HASH vector " << i << ": " << (ok ? "PASS" : "FAIL") << std::endl;
    }

    delete top;
    tfp->close();
    delete tfp;
    return 0;
}
