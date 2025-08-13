// ============================================================================
// ascon_regs.sv
// ASCON Register Block (32-bit OBI interface)
// ============================================================================
module ascon_regs (
    input  logic         clk_i,
    input  logic         rst_ni,

    // OBI Interface (32-bit)
    input  logic [31:0]  wdata_i,
    input  logic [3:0]   addr_i,
    input  logic         wen_i,
    input  logic         ren_i,
    output logic [31:0]  rdata_o,

    // Connection to controller
    output logic [127:0] key_o,
    output logic         key_valid_o,
    output logic [127:0] nonce_o,
    output logic [31:0]  data_in_o,
    output logic         data_in_valid_o,
    input  logic [31:0]  data_out_i,
    input  logic         data_out_valid_i,
    output logic         start_enc_o,
    output logic         start_dec_o,
    input  logic         busy_i,
    input  logic         done_i,
    input  logic         auth_i
);

    // Internal registers
    logic [127:0] key_r;
    logic [127:0] nonce_r;
    logic [31:0]  data_in_r;
    logic         start_enc_r, start_dec_r;
    logic         key_valid_r, data_in_valid_r;

    // Write logic
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            key_r           <= '0;
            nonce_r         <= '0;
            data_in_r       <= '0;
            start_enc_r     <= 1'b0;
            start_dec_r     <= 1'b0;
            key_valid_r     <= 1'b0;
            data_in_valid_r <= 1'b0;
        end else begin
            key_valid_r     <= 1'b0; // clear after one cycle
            data_in_valid_r <= 1'b0;
            if (wen_i) begin
                unique case (addr_i)
                    4'h0: key_r[31:0]      <= wdata_i;
                    4'h1: key_r[63:32]     <= wdata_i;
                    4'h2: key_r[95:64]     <= wdata_i;
                    4'h3: key_r[127:96]    <= wdata_i;
                    4'h4: nonce_r[31:0]    <= wdata_i;
                    4'h5: nonce_r[63:32]   <= wdata_i;
                    4'h6: nonce_r[95:64]   <= wdata_i;
                    4'h7: nonce_r[127:96]  <= wdata_i;
                    4'h8: data_in_r        <= wdata_i;
                    4'h9: start_enc_r      <= wdata_i[0];
                    4'hA: start_dec_r      <= wdata_i[0];
                    default: ;
                endcase
            end

            // Generate valid strobes
            if (wen_i && (addr_i >= 4'h0 && addr_i <= 4'h3)) key_valid_r <= 1'b1;
            if (wen_i && (addr_i == 4'h8)) data_in_valid_r <= 1'b1;
        end
    end

    // Read logic
    always_comb begin
        unique case (addr_i)
            4'h0: rdata_o = key_r[31:0];
            4'h1: rdata_o = key_r[63:32];
            4'h2: rdata_o = key_r[95:64];
            4'h3: rdata_o = key_r[127:96];
            4'h4: rdata_o = nonce_r[31:0];
            4'h5: rdata_o = nonce_r[63:32];
            4'h6: rdata_o = nonce_r[95:64];
            4'h7: rdata_o = nonce_r[127:96];
            4'h8: rdata_o = data_out_i;
            4'h9: rdata_o = {31'd0, start_enc_r};
            4'hA: rdata_o = {31'd0, start_dec_r};
            4'hB: rdata_o = {29'd0, auth_i, done_i, busy_i};
            default: rdata_o = 32'd0;
        endcase
    end

    // Outputs to controller
    assign key_o           = key_r;
    assign key_valid_o     = key_valid_r;
    assign nonce_o         = nonce_r;
    assign data_in_o       = data_in_r;
    assign data_in_valid_o = data_in_valid_r;
    assign start_enc_o     = start_enc_r;
    assign start_dec_o     = start_dec_r;

endmodule
