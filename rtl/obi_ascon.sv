// obi_ascon.sv
// OBI slave wrapper for ASCON core with interrupt support (no top-level busy/done/auth)
// ============================================================================
`include "common_cells/registers.svh"

module obi_ascon #(
    /// OBI configuration
    parameter obi_pkg::obi_cfg_t ObiCfg = obi_pkg::ObiDefaultConfig,
    /// OBI request struct type
    parameter type obi_req_t = logic,
    /// OBI response struct type
    parameter type obi_rsp_t = logic,
    parameter CCW = 64  // Ascon core word size
)(
    input  logic clk_i,
    input  logic rst_ni,

    // OBI slave interface
    input  obi_req_t obi_req_i,
    output obi_rsp_t obi_rsp_o,

    // Interrupt
    output logic irq_o
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

    // Interrupt register
    logic irq_r;

    // ======================================================
    // Register block
    // ======================================================
    ascon_regs regs_i (
        .clk_i(clk_i),
        .rst_ni(rst_ni),

        // 32-bit OBI interface
        .wdata_i(obi_req_i.a.wdata),
        .addr_i(obi_req_i.a.addr[3:0]),
        .wen_i(obi_req_i.a.we),
        .ren_i(obi_req_i.req & !obi_req_i.a.we),
        .rdata_o(),

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
        .clk_i(clk_i),
        .rst_ni(rst_ni),

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
    // Interrupt logic
    // ======================================================
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            irq_r <= 1'b0;
        else
            irq_r <= (done | auth);  // set interrupt when done or auth
    end

    assign irq_o = irq_r;

    // ======================================================
    // OBI response
    // ======================================================
    logic req_q;
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)
            req_q <= 1'b0;
        else
            req_q <= obi_req_i.req;
    end

    assign obi_rsp_o.gnt     = obi_req_i.req;
    assign obi_rsp_o.rvalid  = req_q;
    assign obi_rsp_o.r.rdata = '0; // ascon_regs handles rdata internally
    assign obi_rsp_o.r.rid   = obi_req_i.a.aid;
    assign obi_rsp_o.r.err   = 1'b0;
    assign obi_rsp_o.r.r_optional = '0;

endmodule
