// SPDX-License-Identifier: SHL-0.51
`include "common_cells/registers.svh"

module ascon_controller #(
  parameter obi_pkg::obi_cfg_t ObiCfg      = obi_pkg::ObiDefaultConfig,
  parameter type               obi_req_t   = logic,
  parameter type               obi_rsp_t   = logic
)(
  input  logic     clk_i,
  input  logic     rst_ni,

  // OBI Slave (from CPU)
  input  obi_req_t obi_req_i,
  output obi_rsp_t obi_rsp_o,

  // Kết nối đến ASCON Core
  output logic                 ascon_start_o,
  output logic [2:0]           ascon_mode_o,
  output logic [127:0]         ascon_key_o,
  output logic [127:0]         ascon_nonce_o,
  output logic [127:0]         ascon_data_in_o,
  output logic                 ascon_data_valid_o,
  input  logic [127:0]         ascon_data_out_i,
  input  logic                 ascon_done_i
);

  // ----------------------------
  // Tín hiệu nội bộ
  // ----------------------------
  logic                   reg_we;
  logic                   reg_re;
  logic [ObiCfg.AddrWidth-1:0] reg_addr;
  logic [ObiCfg.DataWidth-1:0] reg_wdata;
  logic [ObiCfg.DataWidth-1:0] reg_rdata;
  logic                   reg_error;

  // ----------------------------
  // Giao tiếp thanh ghi (regs)
  // ----------------------------
  ascon_regs #(
    .ObiCfg   (ObiCfg)
  ) u_ascon_regs (
    .clk_i      (clk_i),
    .rst_ni     (rst_ni),
    .addr_i     (reg_addr),
    .we_i       (reg_we),
    .re_i       (reg_re),
    .wdata_i    (reg_wdata),
    .rdata_o    (reg_rdata),
    .err_o      (reg_error),

    // Xuất tín hiệu đến FSM và Core
    .start_o        (ascon_start_o),
    .mode_o         (ascon_mode_o),
    .key_o          (ascon_key_o),
    .nonce_o        (ascon_nonce_o),
    .data_in_o      (ascon_data_in_o),
    .data_valid_o   (ascon_data_valid_o),

    // Nhận kết quả từ Core
    .data_out_i     (ascon_data_out_i),
    .done_i         (ascon_done_i)
  );

  // ----------------------------
  // Giao tiếp OBI SBR (Slave Bus)
  // ----------------------------
  logic req_q;
  logic [ObiCfg.IdWidth-1:0] id_q;
  `FF(req_q, obi_req_i.req, '0)
  `FF(id_q , obi_req_i.a.aid, '0)

  assign reg_addr  = obi_req_i.a.addr;
  assign reg_we    = obi_req_i.a.we & obi_req_i.req;
  assign reg_re    = ~obi_req_i.a.we & obi_req_i.req;
  assign reg_wdata = obi_req_i.a.wdata;

  assign obi_rsp_o.gnt        = obi_req_i.req;
  assign obi_rsp_o.rvalid     = req_q;
  assign obi_rsp_o.r.rdata    = reg_rdata;
  assign obi_rsp_o.r.err      = reg_error;
  assign obi_rsp_o.r.rid      = id_q;
  assign obi_rsp_o.r.r_optional = '0;

endmodule
