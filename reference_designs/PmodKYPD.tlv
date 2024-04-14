\m5_TLV_version 1d --inlineGen --noDirectiveComments --noline --clkAlways --bestsv --debugSigsYosys: tl-x.org
//
\m5
   /**
   use(m5-1.0)
   
   
   // #############################
   // #                           #
   // #  Controller for PmodKYPD  #
   // #                           #
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
   
   // !!!!! Careful, the latency of debouncing could be greater than the sample window.
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_neq(m5_MAKERCHIP, 1): Debounce unless in Makerchip.
   
   // ======================
   // Computed From Settings
   // ======================
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_eq(m5_MAKERCHIP, 1, 8'h03, 8'hff))
   **/
\SV
   // Include Tiny Tapeout Lab.
   ///m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])

// A controller for PmodKYPD (keypad).
//
// The keypad is sampled one row at a time, a small fraction of the time. When sampling (/_name$sampling),
// /_name$sample_row_mask[3:0] must be driven to PmodKYPD (via *uo_out). Otherwise, it does not matter what is driven
// to PmodKYPD. Thus, most of the time, *uo_out can be driven for other purposes, most notably, driving
// a 7-segment display or other LEDs. Since the values driven to PmodKYPD are driven a small fraction of
// the time, they have a (hopefully) imperceptible impact on the LEDs.
//
// In:
//   $_ready: Able to receive a button press. Drive @_first_stage+1.
// Out:
//   /_name$button_pressed: [boolean] Was a button/key pressed?
//   /_name$digit_pressed[3:0]: The hex digit pressed if $button_pressed, held until the next $button_pressed.
//   /_name$sample_row_mask: The input values for the Pmod (if /_name$sampling)
//   /_name$sampling: The Pmod must be sampling (driven with /_name$pmod_in).
// Params:
//   /_top
//   /_name
//   @_first_stage: The first stage of logic in the pipeline.
//   $_pmod_out: The name and range of the input signal that receives the Pmod output.
//               Should be driven in the same stage that drives *uo_out and receives *ui_in -- @_first_stage + 1).
//   $_ready
//   _where: Visualization uses "where: {_where}."
\TLV PmodKYPD(/_top, /_name, @_first_stage, $_pmod_out, $_ready, _where)
   /_name
      // Pipelined logic to poll the keypad.
      // Determine a fixed sequence of polling that will:
      //   - Drive a keypad row to read, and hold it for the duration of the "sample window".
      //   - Receive row data (1 bit per column) back from keypad, reading it at the last cycle of the sample window.
      //   - Update array of button states ($Button).
      // Independently, scan button states one button at a time, reporting new button presses and remembering those
      // that have been reported while still pressed.
      @_first_stage
         $reset = /_top$reset;
         
         // Run fast in Makerchip simulation.
         m5_var(SeqWidth, m5_if(m5_MAKERCHIP, 4, 17))    /// 12 Number of bits counting one sample to the next. 22 for 1/4 sec per poll
         m5_var(SampleWidth, m5_if(m5_MAKERCHIP, 2, 13))  /// 7 Number of bits counting sample window.
         
         // Sample once every 2^m5_SeqWidth cycles.
         // Sample input 2^m5_SampleWidth cycles after driving input.
         // When not driving outputs, drive $_led_out.
         // Determine when to update column keypad input
         // and when to sample keypad output.
         $Seq[m5_calc(m5_SeqWidth - 1 + 2):0] <=
            $reset ? 0 : $Seq + 1;
         $sampling = $Seq[m5_calc(m5_SeqWidth - 1):m5_SampleWidth] == m5_calc(m5_SeqWidth - m5_SampleWidth)'b0;
         $sample = $sampling && ($Seq[m5_calc(m5_SampleWidth - 1):0] == ~m5_SampleWidth'b0);
         
         // Update column keypad input.
         ?$sampling
            $row_sel[1:0] = $Seq[m5_calc(m5_SeqWidth - 1 + 2):m5_SeqWidth];
         $sample_row_mask[3:0] = 4'b1 << $row_sel;
      @m4_stage_eval(@_first_stage + 1)
         ?$sample
            $row[3:0] = /_top$_pmod_out;  // A row of data from keypad, indexed by column.
         $sample_or_reset = $sample || $reset;
         ?$sample_or_reset
            // Update button states for the selected column.
            $Button[15:0] <=
               $reset ? 16'b0 :
                        {$row_sel == 2'h3 ? $row : $Button[15:12],
                         $row_sel == 2'h2 ? $row : $Button[11:8],
                         $row_sel == 2'h1 ? $row : $Button[7:4],
                         $row_sel == 2'h0 ? $row : $Button[3:0]};
         
         
      //
      // Report pressed buttons (only once)
      //
      
      // Check one button each cycle.
      // Use the same pipeline as polling, aligned so that $Button, $Reported, and $CheckButton update
      // at the same stage.
      @m4_stage_eval(@_first_stage + 1)
         // Pressed buttons that have been reported (to avoid reporting twice).
         $Reported[15:0] <=
            $reset
               ? 16'b0 :
            // default: button is pressed and not previously or just reported.
                 $Button & ($Reported | ($check_mask & {16{$report_button}}));
         
         // Can only reset to zero on TT3 FPGA demo board, so have to start with encoded count.
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
         //$digits[63:0] = 64'h1470_258F_369E_ABCD;
         $digit_pressed[3:0] = $reset ? 4'hF : $report_button ? $digits[($CheckButton * 4) +: 4] : $RETAIN;

         /row[3:0]
            \viz_js
               box: {width: 400, height: 100, strokeWidth: 0},
               layout: {left: 0,
                        top(i) {return (3 - i) * 100}}
            /col[3:0]
               \viz_js
                  box: {width: 100, height: 100, strokeWidth: 0},
                  layout: {left(i) {return (3 - i) * 100},
                           top: 0},
                  init() {
                     key_index = this.getIndex("row") * 4 + this.getIndex("col");
                     return {
                        state: new fabric.Circle({left: 15, top: 15, radius: 35, fill: "black", strokeWidth: 5, stroke: "gray"}),
                        index: new fabric.Text(key_index.toString(), {fill: "white"}),
                        key_label: new fabric.Text('/_name$digits'.asHexStr()[15 - key_index].toUpperCase(), {left: 50, top: 50, originX: "center", originY: "center", fill: "white"}),
                     }
                  },
                  renderFill() {
                    return '/_name$sampling'.asBool()
                        ? ('/_name$row_sel'.asInt() == this.getIndex("row") ? (('/_name$row'.asInt() >> this.getIndex("col")) & 1) != 0 ? "blue" : "cyan" : "black") :
                             "gray";
                  },
                  render() {
                     let getBit = (sig) => {
                        return sig.asInt() >> (this.getIndex("row") * 4 + this.getIndex("col")) & 1 != 0;
                     }
                     this.getObjects().state.set({
                        fill: getBit('/_name$Reported') ? "gray" : getBit('/_name$Button') ? "blue" : "black"
                     })
                  }

         \viz_js
            where: {_where}
\TLV example_PmodKYPD_design()
   |pipe
      @-1
         $reset = *reset || *ui_in[7];
      
      m5+PmodKYPD(|pipe, /keypad, @0, $ui_in[3:0], 1'b1, ['left: 40, top: 80, width: 20, height: 20'])
      
      @2
         m5+sseg_decoder($segments_n, /keypad$digit_pressed)
      @1
         // Re-align output for 7-seg to combine with keypad input.
         $sseg_out[7:0] = {1'b0, ~ >>2$segments_n};
         // Drive to PmodKYPD if sampling, otherwise, drive for 7-seg display.
         *uo_out = /keypad$sampling ? {4'b0, /keypad$sample_row_mask} : $sseg_out;
         // Output goes to PmodKYPD, and PmodKYPD responds on *ui_in (with unknown delay, absorbed by sample window).
         $ui_in[7:0] = *ui_in;
         \viz_js
            box: {width: 100, height: 100, strokeWidth: 0}
   
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
   
   // A fake PmodKYPD.
   // Pmod in: uo_out[3:0]
   // Pmod out: ui_in[3:0]
   logic [15:0] button;
   logic [3:0] col_button;
   logic [3:0] col_sel = uo_out[3:0];
   
   assign ui_in[3:0] =
       ({4{col_sel[0]}} & button[3:0]) |
       ({4{col_sel[1]}} & button[7:4]) |
       ({4{col_sel[2]}} & button[11:8]) |
       ({4{col_sel[3]}} & button[15:12]);
   
   
   assign ui_in[7:4] = 4'b0000;
   m5_if_neq(m5_target, FPGA, ['assign uio_in = 8'b0;'])
   logic ena = 1'b0;
   logic rst_n = ! reset;
   
   // Or, to provide specific inputs at specific times (as for lab C-TB) ...
   // BE SURE TO COMMENT THE ASSIGNMENT OF INPUTS ABOVE.
   // BE SURE TO DRIVE THESE ON THE B-PHASE OF THE CLOCK (ODD STEPS).
   // Driving on the rising clock edge creates a race with the clock that has unpredictable simulation behavior.
   initial begin
      #1  // Drive inputs on the B-phase.
         button = 16'b0000_0000_0000_0000;
      #10 // Step 5 cycles, past reset.
         button = 16'b0000_0000_0000_0000;
      #200
         button = 16'b0000_0000_0000_0001;
      #200
         button = 16'b0000_0000_0000_0000;
   end

   // Instantiate the Tiny Tapeout module.
   m5_user_module_name tt(.*);
   
   assign passed = top.cyc_cnt > 600;
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
   logic reset = ! rst_n;
   
\TLV
   /* verilator lint_off UNOPTFLAT */
   // Connect Tiny Tapeout I/Os to Virtual FPGA Lab.
   m5+tt_connections()
   
   // Instantiate the Virtual FPGA Lab.
   m5+board(/top, /fpga, 7, $, , my_design)
   // Label the switch inputs [0..7] (1..8 on the physical switch panel) (top-to-bottom).
   m5+tt_input_labels_viz(['"KYPD row0", "KYPD row1", "KYPD row2", "KYPD row3", "D:Mask", "D:High/Dbg", "D:Reported", "Reset"'])

\SV
endmodule
