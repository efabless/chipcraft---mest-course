\m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
\m5
   use(m5-1.0)
   
   
   // #############################
   // #                           #
   // #  Controller for PmodKYPD  #
   // #           (WIP)           #
   // #############################
   
   // ========
   // Settings
   // ========
   
   //-------------------------------------------------------
   // Build Target Configuration
   //
   // To build within Makerchip for the FPGA or ASIC:
   //   o Use first line of file: \m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
   //   o set(MAKERCHIP, 0)
   //   o var(target, FPGA)  // or ASIC
   set(MAKERCHIP, 0)   /// 1 (or commented out) for simulating in Makerchip.
   var(my_design, tt_um_template)   /// The name of your top-level TT module, to match your info.yml.
   var(target, FPGA)  /// FPGA or ASIC
   //-------------------------------------------------------
   
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])

// In:
//   $_ready: Able to receive a button press.
//   $_led_out: The chip output to PmodKYPD can be shared with led output values.
//              Outputs will be drivn by PmodKYPD a small percentage of the time that is
//              inperceptible to LEDs that share the output. This value is driven on $_pmod_out
//              when PmodKYPD is not using them. Use 8'b0 is not used.
// Out:
//   /_name$button_pressed: [boolean] Was a button/key pressed?
//   /_name$digit_pressed[3:0]: The hex digit pressed if $button_pressed, held until the next $button_pressed.
// Params:
//   /_top
//   /_name
//   $_pmod_in: The name and range of the output signal that drives the Pmod input.
//   $_pmod_out: The name and range of the input signal that receives the Pmod output.
//   $_ready
//   $_led_out
\TLV PmodKYPD(/_top, /_name, $_pmod_in, $_pmod_out, $_ready, $_led_out)
   /_name
      $reset = /_top$reset;
      
      // Connect the Pmod to uo_out[3:0] and ui_in[3:0].
      $_pmod_in = $sampling ? 4'b1 << $col : /_top$_led_out;
      $row[3:0] = $_pmod_out;
      // Run fast in Makerchip simulation.
      m5_var(SeqWidth, m5_if(m5_MAKERCHIP, 5, 12)) /// Number of bits counting one sample to the next. 22 for 1/4 sec per poll
      m5_var(SampleWidth, m5_if(m5_MAKERCHIP, 2, 7))  /// Number of bits counting sample window.
      
      // Sample once every 2^m5_SeqWidth cycles.
      // Sample input 2^m5_SampleWidth cycles after driving input.
      // When not driving outputs, drive $_led_out.
      // Determine when to update column keypad input
      // and when to sample keypad output.
      $Seq[m5_calc(m5_SeqWidth - 1 + 2):0] <=
         $reset ? 0 : $Seq + 1;
      $sampling = $Seq[m5_calc(m5_SeqWidth - 1):m5_SampleWidth] == m5_calc(m5_SeqWidth - m5_SampleWidth)'b0;
      $sample = $sampling && $Seq[m5_calc(m5_SampleWidth - 1):0] == ~ m5_SampleWidth'b0;

      // Update column keypad input.
      $col[1:0] = $Seq[m5_calc(m5_SeqWidth - 1 + 2):m5_SeqWidth];
      
      // Update button states for the selected column.
      $Button[15:0] <=
         $reset ? 16'b0 :
         $sample ? {$col == 2'h3 ? $row : $Button[15:12],
                    $col == 2'h2 ? $row : $Button[11:8],
                    $col == 2'h1 ? $row : $Button[7:4],
                    $col == 2'h0 ? $row : $Button[3:0]} :
                   $Button;
      
      //
      // Report pressed buttons (only once)
      //
      
      // Check one button each cycle.
      
      // Pressed buttons that have been reported (to avoid reporting twice).
      $Reported[15:0] <=
         $reset
            ? 16'b0 :
         // default: button is pressed and not previously or just reported.
              $Button & ($Reported | ($check_mask & {16{$report_button}}));
      
      // Can only reset to zero, so have to start with encoded count.
      $CheckButton[3:0] <=
         $reset
            ? 4'h0 :
         $_ready
            ? $CheckButton + 4'h1 :
         // default
              $CheckButton;
      $check_mask[15:0] = 16'b1 << $CheckButton;
      // Is the check button pressed and not reported.
      $report_button = $_ready && | ($check_mask & $Button & ~ $Reported);
      
      // Report it.
      $digits[63:0] = 64'h123A_456B_789C_0FED;
      $digit_pressed[3:0] = $report_button ? $digits[($CheckButton * 4) +: 4] : $RETAIN;
      
\TLV my_design()
   |pipe
      @-1
         $reset = *reset || *ui_in[7];
      @0
         m5+PmodKYPD(|pipe, /keypad, *uo_out[3:0], *ui_in[3:0], 1'b1, $segments[3:0])
         m5+sseg_decoder($segments_n, /keypad$digit_pressed)
         $segments[6:0] = ~ $segments_n;
         *uo_out[7:4] = {1'b0, $segments[6:4]};
   
   // Connect Tiny Tapeout outputs. Note that uio_ outputs are not available in the Tiny-Tapeout-3-based FPGA boards.
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])
   
\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0]uio_in,  uio_out, uio_oe;'])
   logic [31:0] r;  // a random value
   always @(posedge clk) r <= m5_if(m5_MAKERCHIP, ['$urandom()'], ['0']);
   assign ui_in = 8'h02;
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   /*
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         ui_in = 8'h0;
      #10 // Step 5 cycles, past reset.
         ui_in = 8'hFF;
      // ...etc.
   end
   */

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 60;
   assign failed = 1'b0;
endmodule


// Provide a wrapper module to debounce input signals if requested.
m5_if(m5_debounce_inputs, ['m5_tt_top(m5_my_design)'])
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
   logic rst, sync_rst;
   always @(posedge clk or negedge rst_n)
      if (! rst_n)
         rst <= 1;
      else
         rst <= 0;
   always @(posedge clk)
      sync_rst <= rst;
   logic reset;
   always @(posedge clk)
      reset <= sync_rst;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])

\SV
endmodule
