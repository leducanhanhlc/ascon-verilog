// obi_ascon.sv
// ============================================================================

`include "common_cells/registers.svh"

module obi_ascon #(
    parameter CCW = 64  // Ascon core word size
)(
    input  logic        clk,
    input  logic        rst_n,

    // 32-bit OBI Interface
    input  logic [31:0] wdata_i,
    input  logic [3:0]  addr_i,
    input  logic        wen_i,
    input  logic        ren_i,
    output logic [31:0] rdata_o,

    // Optional debug signals
    output logic        busy_o,
    output logic        done_o,
    output logic        auth_o
);

    // ======================================================
    // Internal signals connecting regs and controller
    // ======================================================
    logic [127:0] key;
    logic         key_valid;
    logic [127:0] nonce;
    logic [31:0]  data_in;
    logic         data_in_valid;
    logic         start_enc;
    logic         start_dec;

    logic [31:0]  data_out;
    logic         data_out_valid;
    logic         busy;
    logic         done;
    logic         auth;

    // ======================================================
    // Register block
    // ======================================================
    ascon_regs regs_i (
        .clk_i(clk),
        .rst_ni(rst_n),

        // OBI interface
        .wdata_i(wdata_i),
        .addr_i(addr_i),
        .wen_i(wen_i),
        .ren_i(ren_i),
        .rdata_o(rdata_o),

        // Controller interface
        .key_o(key),
        .key_valid_o(key_valid),
        .nonce_o(nonce),
        .data_in_o(data_in),
        .data_in_valid_o(data_in_valid),
        .start_enc_o(start_enc),
        .start_dec_o(start_dec),
        .data_out_i(data_out),
        .data_out_valid_i(data_out_valid),
        .busy_i(busy),
        .done_i(done),
        .auth_i(auth)
    );

    // ======================================================
    // Controller
    // ======================================================
    ascon_controller ctrl_i (
        .clk_i(clk),
        .rst_ni(rst_n),
        .holo(rst_n), 

        // Control signals from regs
        .key_i(key),
        .key_valid_i(key_valid),
        .nonce_i(nonce),
        .data_in_i(data_in),
        .data_in_valid_i(data_in_valid),
        .start_enc_i(start_enc),
        .start_dec_i(start_dec),

        // Output to regs
        .data_out_o(data_out),
        .data_out_valid_o(data_out_valid),
        .busy_o(busy),
        .done_o(done),
        .auth_o(auth)
    );

    // ======================================================
    // Optional top-level outputs
    // ======================================================
    assign busy_o = busy;
    assign done_o = done;
    assign auth_o = auth;

endmodule
