// ============================================================================
// ascon_controller.sv
// Controller for ASCON core, handling input/output from 32-bit OBI interface
// Supports AEAD (AD + MSG) processing
// ============================================================================
module ascon_controller #(
    parameter CCW = 64
) (
    input  logic          clk_i,
    input  logic          rst_ni,

    // From registers
    input  logic [CCW*2-1:0] key_i,          // 128-bit key from 2x32-bit words
    input  logic             key_valid_i,
    input  logic [CCW*2-1:0] nonce_i,        // 128-bit nonce from 2x32-bit words
    input  logic [31:0]      data_in_i,      // 32-bit input from reg block
    input  logic             data_in_valid_i,
    input  logic             start_enc_i,
    input  logic             start_dec_i,

    // To registers
    output logic [31:0]      data_out_o,     // 32-bit output to reg block
    output logic             data_out_valid_o,
    output logic             busy_o,
    output logic             auth_o,
    output logic             done_o
);

    // -------------------------
    // Signals to connect ASCON core
    // -------------------------
    logic [127:0] core_bdi;
    logic [3:0]   core_bdi_valid;
    e_data_type   core_bdi_type;
    logic         core_bdi_eot;
    logic         core_bdi_eoi;

    logic [127:0] core_bdo;
    logic         core_bdo_valid;
    e_data_type   core_bdo_type;
    logic         core_bdo_eot;

    logic [127:0] core_key;
    logic [127:0] core_nonce;
    logic         core_key_valid;

    logic core_bdo_ready = 1'b1; // always ready in controller
    logic core_auth, core_auth_valid, core_done;

    // -------------------------
    // Flatten 32-bit input to 128-bit for core
    // -------------------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            core_bdi <= '0;
            core_bdi_valid <= '0;
            core_bdi_type <= D_NULL;
            core_bdi_eot <= 1'b0;
            core_bdi_eoi <= 1'b0;
            core_key <= '0;
            core_nonce <= '0;
            core_key_valid <= 1'b0;
        end else begin
            // feed key/nonce once at start
            core_key <= key_i;
            core_nonce <= nonce_i;
            core_key_valid <= key_valid_i;

            // feed data_in_i to core as 128-bit block (replicate if needed)
            core_bdi[31:0]   <= data_in_i;
            core_bdi[63:32]  <= data_in_i;
            core_bdi[95:64]  <= data_in_i;
            core_bdi[127:96] <= data_in_i;
            core_bdi_valid <= data_in_valid_i ? 4'hF : 4'h0;
            core_bdi_type  <= D_MSG;   // For simplicity, assume message (could extend for AD)
            core_bdi_eot   <= start_enc_i | start_dec_i; // example
            core_bdi_eoi   <= start_enc_i | start_dec_i;
        end
    end

    // -------------------------
    // Instantiate ASCON core
    // -------------------------
    ascon_core u_ascon_core (
        .clk         (clk_i),
        .rst         (~rst_ni),
        .key         (core_key),
        .key_valid   (core_key_valid),
        .key_ready   (),          // unused
        .bdi         (core_bdi),
        .bdi_valid   (core_bdi_valid),
        .bdi_ready   (),          // optional handshake
        .bdi_type    (core_bdi_type),
        .bdi_eot     (core_bdi_eot),
        .bdi_eoi     (core_bdi_eoi),
        .mode        (start_enc_i ? M_ENC : M_DEC),
        .bdo         (core_bdo),
        .bdo_valid   (core_bdo_valid),
        .bdo_ready   (core_bdo_ready),
        .bdo_type    (core_bdo_type),
        .bdo_eot     (core_bdo_eot),
        .bdo_eoo     (1'b0),
        .auth        (core_auth),
        .auth_valid  (core_auth_valid),
        .done        (core_done)
    );

    // -------------------------
    // Map core output to register block
    // -------------------------
    assign data_out_o       = core_bdo[31:0]; // send lower 32-bit word
    assign data_out_valid_o = core_bdo_valid;
    assign busy_o           = !core_done;
    assign auth_o           = core_auth;
    assign done_o           = core_done;

endmodule
