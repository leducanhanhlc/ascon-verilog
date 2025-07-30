module ascon_regs #(
  parameter int ADDR_WIDTH = 8,
  parameter int DATA_WIDTH = 32
)(
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // SBR/OBI bus interface (simplified, similar to SBR-lite)
  input  logic                  req_i,
  input  logic                  we_i,
  input  logic [ADDR_WIDTH-1:0] addr_i,
  input  logic [DATA_WIDTH-1:0] wdata_i,
  output logic [DATA_WIDTH-1:0] rdata_o,
  output logic                  rvalid_o,

  // Control signal to controller/core
  output logic [3:0]            mode_o,
  output logic                  start_o,
  input  logic                  done_i,
  input  logic                  auth_i,

  output logic [31:0]           key_o [0:3],
  output logic [31:0]           nonce_o [0:2],

  output logic [31:0]           bdi_data_o,
  output logic [3:0]            bdi_type_o,
  output logic                  bdi_valid_o,

  input  logic [31:0]           bdo_data_i,
  input  logic                  bdo_valid_i
);
  // Định nghĩa các thanh ghi bên trong module
  logic [31:0] ctrl_reg;
  logic [3:0]  bdi_type_reg;
  logic [31:0] bdi_reg;
  logic [31:0] bdo_reg;
  logic        bdi_valid_q;

  logic [31:0] key_regs  [0:3];
  logic [31:0] nonce_regs[0:2];

  // Tín hiệu start chỉ active 1 cycle
  logic start_pulse;

  // Write logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      ctrl_reg      <= 0;
      bdi_type_reg  <= 0;
      bdi_reg       <= 0;
      bdi_valid_q   <= 0;
      for (int i = 0; i < 4; i++) key_regs[i] <= 0;
      for (int i = 0; i < 3; i++) nonce_regs[i] <= 0;
    end else begin
      bdi_valid_q <= 0;
      if (req_i && we_i) begin
        unique case (addr_i)
          8'h00: ctrl_reg     <= wdata_i;
          8'h08: key_regs[0]  <= wdata_i;
          8'h0C: key_regs[1]  <= wdata_i;
          8'h10: key_regs[2]  <= wdata_i;
          8'h14: key_regs[3]  <= wdata_i;
          8'h20: nonce_regs[0]<= wdata_i;
          8'h24: nonce_regs[1]<= wdata_i;
          8'h28: nonce_regs[2]<= wdata_i;
          8'h30: begin
            bdi_reg      <= wdata_i;
            bdi_valid_q  <= 1'b1;
          end
          8'h34: bdi_type_reg <= wdata_i[3:0];
          default:;
        endcase
      end
    end
  end

  // Read logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rdata_o <= 0;
      rvalid_o <= 0;
    end else begin
      rvalid_o <= 0;
      if (req_i && !we_i) begin
        rvalid_o <= 1;
        unique case (addr_i)
          8'h04: rdata_o <= {30'b0, auth_i, done_i};  // STATUS
          8'h38: rdata_o <= bdo_data_i;
          default: rdata_o <= 32'hDEAD_BEEF;
        endcase
      end
    end
  end

  assign start_pulse = ctrl_reg[0];

  assign start_o     = start_pulse;
  assign mode_o      = ctrl_reg[4:1];

  assign key_o       = key_regs;
  assign nonce_o     = nonce_regs;

  assign bdi_data_o  = bdi_reg;
  assign bdi_type_o  = bdi_type_reg;
  assign bdi_valid_o = bdi_valid_q;

endmodule
