\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   // ==========================================
   // Provides reference solutions
   // without visibility to source code.
   // ==========================================
   
   // ----------------------------------
   // Instructions:
   //    - When stuck on a particular lab, provide the LabId below, and compile/simulate.
   //    - A reference solution will build, but the source code will not be visible.
   //    - You may use waveforms, diagrams, and visualization to understand the proper circuit, but you
   //      will have to come up with the code. Logic expression syntax can be found by hovering over the
   //      signal assignment in the diagram.
   // ----------------------------------
   
   // Provide the Lab ID given at the lower right of the slide.
   var(LabId, DONE)
   
   
   // To build within Makerchip for the FPGA or ASIC:
   //   o Use first line of file: \m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
   //   o set(MAKERCHIP, 0)
   //   o var(target, FPGA)  // or ASIC
   //set(MAKERCHIP, 0)
   var(my_design, tt_um_template)
   var(target, FPGA)  /// FPGA or ASIC
   
   
   // ================================================
   // No need to touch anything below this line.
   
   // Is this a calculator lab?
   var(CalcLab, m5_if_regex(m5_LabId, ^\(C\)-, (C), 1, 0))
   // ---SETTINGS---
   default_var(my_design, m5_if(m5_CalcLab, tt_um_calc, tt_um_riscv_cpu)) /// Change to tt_um_<your-github-username>_riscv_cpu. (See Tiny Tapeout repo README.md.)
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   // CPU configs
   var(num_regs, 16)  // 32 for full reg file.
   var(dmem_size, 8)  // A power of 2.
   // --------------
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])

   // Default Makerchip TL-Verilog Code Template
   m4_include_makerchip_hidden(['mest_course_solutions.private.tlv'])


// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0]uio_in,  uio_out, uio_oe;'])
   m5_if(m5_CalcLab, ['logic [31:0] r;'])
   m5_if(m5_CalcLab, ['always @(posedge clk) r <= m5_if(m5_MAKERCHIP, ['$urandom()'], ['0']);'])
   m5_if_eq(m5_LabId, C-TB, [''], ['assign ui_in = m5_ui_in_expr;'])
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   m4_ifelse_block(m5_LabId, C-TB, ['
   initial begin
      #1
         ui_in = 8'h0;
      #10  // Step over reset.
         ui_in = 8'h01;
      #10
         ui_in = 8'h81;
      #10
         ui_in = 8'h02;
      #10
         ui_in = 8'h82;
   end
   '])

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = m5_if(m5_CalcLab, ['top.cyc_cnt > 60'], ['uo_out[0]']);
   assign failed = m5_if(m5_CalcLab, ['1'b0'],             ['uo_out[1]']);
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
// The above macro expands to multiple lines. We enter a new \SV block to reset line tracking.
\SV



// =======================
// The Tiny Tapeout module
// =======================

module m5_user_module_name (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    m5_if_eq(m5_target, FPGA, ['/']['*'])   // The FPGA is based on TinyTapeout 3 which has no bidirectional I/Os (vs. TT6 for the ASIC).
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    m5_if_eq(m5_target, FPGA, ['*']['/'])
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
   m5_if(m5_CalcLab, [''], ['logic passed, failed;  // Connected to uo_out[0] and uo_out[1] respectively, which connect to Makerchip passed/failed.'])

   wire reset = ! rst_n;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , hidden_solution)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(m5_input_labels)

\SV
endmodule
