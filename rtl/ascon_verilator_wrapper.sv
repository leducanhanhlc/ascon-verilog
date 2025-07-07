`ifndef ASCON_VERILATOR_WRAPPER
`define ASCON_VERILATOR_WRAPPER

`include "config.sv"
`include "functions.sv"
`include "asconp.sv"
`include "ascon_core.sv"

module ascon_verilator_wrapper (
    input  logic             clk,
    input  logic             rst,

    // Key input
    input  logic [CCW-1:0]   key,
    input  logic             key_valid,
    output logic             key_ready,

    // Data input
    input  logic [CCW-1:0]   bdi,
    input  logic [CCW/8-1:0] bdi_valid,
    output logic             bdi_ready,
    input  logic [3:0]       bdi_type,
    input  logic             bdi_eot,
    input  logic             bdi_eoi,

    // Mode select
    input  logic [3:0]       mode,

    // Data output
    output logic [CCW-1:0]   bdo,
    output logic             bdo_valid,
    input  logic             bdo_ready,
    output logic [3:0]       bdo_type,
    output logic             bdo_eot,
    input  logic             bdo_eoo,

    // Auth result
    output logic             auth,
    output logic             auth_valid,

    // Done flag
    output logic             done
);

  // Instantiate the ASCON core directly
  ascon_core u_ascon_core (
      .clk(clk),
      .rst(rst),

      .key(key),
      .key_valid(key_valid),
      .key_ready(key_ready),

      .bdi(bdi),
      .bdi_valid(bdi_valid),
      .bdi_ready(bdi_ready),
      .bdi_type(bdi_type),
      .bdi_eot(bdi_eot),
      .bdi_eoi(bdi_eoi),

      .mode(mode),

      .bdo(bdo),
      .bdo_valid(bdo_valid),
      .bdo_ready(bdo_ready),
      .bdo_type(bdo_type),
      .bdo_eot(bdo_eot),
      .bdo_eoo(bdo_eoo),

      .auth(auth),
      .auth_valid(auth_valid),

      .done(done)
  );

endmodule

`endif  // ASCON_VERILATOR_WRAPPER
