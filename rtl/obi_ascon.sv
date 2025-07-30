// SPDX-License-Identifier: Apache-2.0 WITH SHL-2.1
// Module: obi_ascon
// Description: ASCON wrapper with OBI slave interface

module obi_ascon #(
  parameter int unsigned OBI_ADDR_WIDTH = 32,
  parameter int unsigned OBI_DATA_WIDTH = 32
) (
  // Clock & Reset
  input  logic                  clk_i,
  input  logic                  rst_ni,

  // OBI slave port (connected to CPU)
  input  logic                  obi_req_i,
  output logic                  obi_gnt_o,
  input  logic [OBI_ADDR_WIDTH-1:0] obi_addr_i,
  input  logic                  obi_we_i,
  input  logic [OBI_DATA_WIDTH-1:0] obi_wdata_i,
  input  logic [3:0]            obi_be_i,
  output logic                  obi_rvalid_o,
  output logic [OBI_DATA_WIDTH-1:0] obi_rdata_o,

  // Optional interrupt
  output logic                  irq_o
);

  // ----------------------------------
  // Internal Signals
  // ----------------------------------
  logic                  reg_we;
  logic                  reg_re;
  logic [OBI_ADDR_WIDTH-1:0] reg_addr;
  logic [OBI_DATA_WIDTH-1:0] reg_wdata;
  logic [3:0]            reg_be;
  logic [OBI_DATA_WIDTH-1:0] reg_rdata;
  logic                  reg_rvalid;

  // Control & Status signals to core
  // (expand as needed based on ascon_regs/controller interface)
  logic [3:0]            mode;
  logic                  start;
  logic                  done;
  logic                  error;
  logic [OBI_DATA_WIDTH-1:0] data_in;
  logic [3:0]            data_in_valid;
  logic                  data_in_last;
  logic [3:0]            data_out_valid;
  logic [OBI_DATA_WIDTH-1:0] data_out;
  logic                  data_out_last;
  logic                  auth_ok;
  logic                  auth_valid;

  // ----------------------------------
  // Register Block
  // ----------------------------------
  ascon_regs u_regs (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    // OBI connection
    .req_i         (obi_req_i),
    .gnt_o         (obi_gnt_o),
    .addr_i        (obi_addr_i),
    .we_i          (obi_we_i),
    .be_i          (obi_be_i),
    .wdata_i       (obi_wdata_i),
    .rvalid_o      (obi_rvalid_o),
    .rdata_o       (obi_rdata_o),
    // Control signals out
    .reg_we_o      (reg_we),
    .reg_re_o      (reg_re),
    .reg_addr_o    (reg_addr),
    .reg_wdata_o   (reg_wdata),
    .reg_be_o      (reg_be),
    // Status from controller/core
    .reg_rdata_i   (reg_rdata),
    .reg_rvalid_i  (reg_rvalid),
    .irq_o         (irq_o)
  );

  // ----------------------------------
  // Controller Block
  // ----------------------------------
  ascon_controller u_ctrl (
    .clk_i         (clk_i),
    .rst_ni        (rst_ni),
    // Register IF
    .reg_we_i      (reg_we),
    .reg_re_i      (reg_re),
    .reg_addr_i    (reg_addr),
    .reg_wdata_i   (reg_wdata),
    .reg_be_i      (reg_be),
    .reg_rdata_o   (reg_rdata),
    .reg_rvalid_o  (reg_rvalid),
    // Control out
    .mode_o        (mode),
    .start_o       (start),
    // Status in
    .done_i        (done),
    .error_i       (error),
    .auth_ok_i     (auth_ok),
    .auth_valid_i  (auth_valid),
    // Data in/out interface
    .data_in_o     (data_in),
    .data_in_valid_o(data_in_valid),
    .data_in_last_o(data_in_last),
    .data_out_i    (data_out),
    .data_out_valid_i(data_out_valid),
    .data_out_last_i(data_out_last)
  );

  // ----------------------------------
  // ASCON Core
  // ----------------------------------
  ascon_core u_core (
    .clk           (clk_i),
    .rst           (~rst_ni),
    .mode          (mode),
    .start         (start),
    .bdi           (data_in),
    .bdi_valid     (data_in_valid),
    .bdi_eot       (data_in_last),
    .bdi_eoi       (data_in_last), // simplified assumption
    .bdo           (data_out),
    .bdo_valid     (data_out_valid),
    .bdo_eoo       (data_out_last),
    .auth          (auth_ok),
    .auth_valid    (auth_valid)
  );

endmodule
