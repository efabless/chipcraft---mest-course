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
   var(LabId, C-OUT)
   
   
   var(my_design, tt_um_template)
   var(target, FPGA)  /// FPGA or ASIC
   
   
   // ================================================
   // No need to touch anything below this line.
   
   if_ndef(MAKERCHIP, ['set(MAKERCHIP, 0)'])
   // Is this a calculator lab?
   var(CalcLab, m5_if_regex(m5_LabId, ^\(C\)-, (C), 1, 0))
   // ---SETTINGS---
   default_var(my_design, m5_if(m5_CalcLab, tt_um_calc, tt_um_riscv_cpu)) /// Change to tt_um_<your-github-username>_riscv_cpu. (See Tiny Tapeout repo README.md.)
   var(debounce_inputs, 0)         /// 1: Provide synchronization and debouncing on all input signals.
                                   /// 0: Don't provide synchronization and debouncing.
                                   /// m5_if_defined_as(MAKERCHIP, 1, 0, 1): Debounce unless in Makerchip.
   // CPU configs
   var(num_regs, 16)  // 32 for full reg file.
   var(dmem_size, 8)  // A power of 2.
   // --------------
   
   // If debouncing, a user's module is within a wrapper, so it has a different name.
   var(user_module_name, m5_if(m5_debounce_inputs, my_design, m5_my_design))
   var(debounce_cnt, m5_if_defined_as(MAKERCHIP, 1, 8'h03, 8'hff))

\SV
   // Include Tiny Tapeout Lab.
   m4_include_lib(['https:/']['/raw.githubusercontent.com/os-fpga/Virtual-FPGA-Lab/35e36bd144fddd75495d4cbc01c4fc50ac5bde6f/tlv_lib/tiny_tapeout_lib.tlv'])
   m4_include_lib(https:/['']/raw.githubusercontent.com/efabless/chipcraft---mest-course/main/tlv_lib/m5_if(m5_CalcLab, calculator_shell_lib.tlv, risc-v_shell_lib.tlv))
   
   // Solutions
   ///m4_include_makerchip_hidden(['mest_course_solutions.private.tlv'])
//----------------
\m5
   ///use(m5-1.0)
   
   ///nullify(m4_include_lib(https:/['']/raw.githubusercontent.com/efabless/chipcraft---mest-course/main/tlv_lib/m5_if(m5_CalcLab, calculator_shell_lib.tlv, risc-v_shell_lib.tlv)))

   universal_var(input_labels, ['"UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED", "UNUSED"'])
   universal_var(ui_in_expr, ['8'b0'])
   
   /Define labs.
   var(LabCnt, 0)
   fn(define_labs, LabId, ..., {
      /Map ID to number.
      universal_var(lab_\m5_LabId['']_num, m5_LabCnt)
      on_return(increment, LabCnt)
      on_return(if, $# > 0, {
         define_labs($@)
      })
   })

   fn(lab_num, LabId, {
      ~if_var_def(lab_\m5_LabId['']_num, [
         ~get(lab_\m5_LabId['']_num)
      ], [
         errprint_nl(Lab ID "m5_LabId" not defined.)
         ~(0)
      ])
   })

   /Provide code introduced by given LabId, included if lab has been reached.
   fn(lab, LabId, Code, {
      ~eval(['m4_ifelse_block(m5_calc(m5_lab_num(m5_LabId) <= m5_Lab), 1, [
         ~(['// Lab m5_LabId: '])
         on_return(eval, m5_Code)
      ])'])
   })

   fn(reached, LabId, {
      ~calc(m5_Lab >= m5_lab_num(m5_LabId))
   })

   /Define m5_Lab.
   fn(define_lab, {
      universal_var(Lab, m5_lab_num(m5_LabId))
   })
   
   if(m5_CalcLab, [
      define_labs(C-PIPE, C-OUT, C-IN, C-EQUALS, C-2CYC, C-VALID, C-MEM, C-TB, C-MEM2-DISABLED)   /// Note C-TB and C-MEM2-DISABLED labs are no longer part of course.
      define_lab()
      set(input_labels, ['"Value[0]", "Value[1]", "Value[2]", "Value[3]", "Op[0]", "Op[1]", "Op[2]", "="'])
      
      set(ui_in_expr, ['r[7:0]'])
      
      var(OUTPUT_STAGE, m5_if(m5_reached(C-2CYC), 2, 1))
   ])
   else([
      define_labs(PC_BROKEN, FETCH1, FETCH2, TYPE, IMM, FIELDS, FIELDS_VALID, INSTR, RF_RD, RF_RD2, ALU, RF_WR, BR1, BR2,
                  TB, 3CYC_VALID, 3CYC1, 3CYC2, RF_BYPASS, BR_VALID, ALL_INSTR, FULL_ALU, PRAGMAS, LD_REDIR, LD_DATA, DMEM, LD_ST_TB, DONE)
      define_lab()
   
      TLV_fn(riscv_sum_prog, {
         var(Prog, ['
            # /====================\
            # | Sum 1 to 9 Program |
            # \====================/
            #
            # Program for RISC-V Workshop to test RV32I
            # Add 1,2,3,...,9 (in that order).
            #
            # Regs:
            #  x10 (a0): In: 0, Out: final sum
            #  x12 (a2): 10
            #  x13 (a3): 1..10
            #  x14 (a4): Sum
            # 
            # External to function:
            reset:
               ADD x10, x0, x0             # Initialize r10 (a0) to 0.
            # Function:
               ADD x14, x10, x0            # Initialize sum register a4 with 0x0
               ADDI x12, x10, 10            # Store count of 10 in register a2.
               ADD x13, x10, x0            # Initialize intermediate sum register a3 with 0
            loop:
               ADD x14, x13, x14           # Incremental addition
               ADDI x13, x13, 1            # Increment count register by 1
               BLT x13, x12, loop          # If a3 is less than a2, branch to label named <loop>
            done:
               ADD x10, x14, x0            # Store final result to register a0 so that it can be read by main program

            # Optional:
            #   JAL x7, 00000000000000000000  # Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
         '])
         if(m5_reached(LD_ST_TB), ['m5_append_var(Prog, ['
            ld_st_lab:
               SW x10, 4(x0)   # Add SW , LW instructions to check dmem implementation
               LW x15, 4(x0)
         '])'])
         ~assemble(m5_Prog)
      })
   ])


\TLV hidden_solution()
   m5+call(m5_if(m5_CalcLab, calc_solution, cpu_solution))

\TLV calc_solution()
   |calc
   
      // ============================================================================================================
      
      
      @1
         $reset = *reset;
      m4_ifelse_block(m5_reached(C-IN), 1, ['
      @0
         // Board inputs
         m5_if(m5_reached(C-MEM), ['$op[2:0] = *ui_in[6:4];'], ['$op[1:0] = *ui_in[5:4];'])
         $val2[7:0] = {4'b0, *ui_in[3:0]};
         $equals_in = *ui_in[7];
      '])
      @1
         $val1[7:0] = >>m5_OUTPUT_STAGE$out;
         m5_if(m5_reached(C-IN), [''], ['$val2[7:0] = m5_if(m5_reached(C-OUT), ['8'b1'], ['{5'b0, $rand2[2:0]}']);'])
         m5_if(m5_Lab == m5_lab_num(C-OUT), ['$op[1:0] = 2'b00;'])
         m4_ifelse_block(m5_reached(C-EQUALS), 1, ['
         $valid = $reset ? 1'b0 :
                           $equals_in && ! >>1$equals_in;
         '])
         
         m4_ifelse_block(m5_reached(C-MEM2-DISABLED), 1, ['
         /mem_array[7:0]
            $wr = (#mem_array == |calc$val1[2:0]) && (|calc$op[2:0] == 3'b101) && |calc$valid;
            $value[31:0] = |calc$reset ? 32'b0 :
                           $wr         ? |calc>>2$out :
                                          $RETAIN;
         '])
      
      
      m4_ifelse_block(m5_reached(C-VALID), 1, ['
      ?$valid
         @1
            $sum[7:0] = $val1 + $val2;
            $diff[7:0] = $val1 - $val2;
            $prod[7:0] = $val1 * $val2;
            $quot[7:0] = $val1 / $val2;
      @m5_OUTPUT_STAGE
         m4_ifelse_block(m5_reached(C-MEM), 1, ['
         $mem[7:0] = $reset                         ? 8'b0 :
                     $valid && ($op[2:0] == 3'b101) ? m5_if(m5_reached(C-MEM2-DISABLED), ['/mem_array[$val1[2:0]]$value :'], ['$val1 :'])
                                                      >>1$mem;
            '])
      '], ['
      @1
         $sum[7:0] = $val1 + $val2;
         $diff[7:0] = $val1 - $val2;
         $prod[7:0] = $val1 * $val2;
         $quot[7:0] = $val1 / $val2;
      '])
      @m5_OUTPUT_STAGE
         $out[7:0] = $reset ? 8'b0 :
                     m5_if(m5_reached(C-EQUALS), ['! $valid ? >>1$out :'])
                     (m5_if(m5_reached(C-MEM), ['$op == 3'b000'], ['$op[1:0] == 2'b00'])) ? $sum  :
                     (m5_if(m5_reached(C-MEM), ['$op == 3'b001'], ['$op[1:0] == 2'b01'])) ? $diff :
                     (m5_if(m5_reached(C-MEM), ['$op == 3'b010'], ['$op[1:0] == 2'b10'])) ? $prod :
                     m5_if(m5_reached(C-MEM), ['($op == 3'b011) ? $quot :'], ['                      $quot;'])
                     m5_if(m5_reached(C-MEM), ['($op == 3'b100) ? >>2$mem : >>1$out;'])
      m4_ifelse_block(m5_reached(C-OUT), 1, ['
      m5_if(m5_reached(C-2CYC), @3, @1)
         $digit[3:0] = $out[3:0];
         *uo_out =
            $digit == 4'h0 ? 8'b00111111 :
            $digit == 4'h1 ? 8'b00000110 :
            $digit == 4'h2 ? 8'b01011011 :
            $digit == 4'h3 ? 8'b01001111 :
            $digit == 4'h4 ? 8'b01100110 :
            $digit == 4'h5 ? 8'b01101101 :
            $digit == 4'h6 ? 8'b01111101 :
            $digit == 4'h7 ? 8'b00000111 :
            $digit == 4'h8 ? 8'b01111111 :
            $digit == 4'h9 ? 8'b01101111 :
            $digit == 4'hA ? 8'b01110111 :
            $digit == 4'hB ? 8'b01111100 :
            $digit == 4'hC ? 8'b00111001 :
            $digit == 4'hD ? 8'b01011110 :
            $digit == 4'hE ? 8'b01111001 :
                             8'b01110001;
      '], ['
         *uo_out = 8'b0;
      '])
   m5+cal_viz(@m5_OUTPUT_STAGE, /fpga)
   
   // ============================================================================================================
   
   // Connect Tiny Tapeout outputs.
   // (*uo_out connected above.)
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])

\TLV cpu_solution()
   m5+riscv_gen()
   m5+riscv_sum_prog()
   m5_define_hier(IMEM, m5_NUM_INSTRS)
   
   |cpu
      @0
         $reset = *reset;
      
      
      // ============================================================================================================
      // Solutions: Cut this section to provide the shell.
      
      m5_var(rf_rd_stage, @1)
      m5_var(rf_wr_stage, @1)
      
      
      // Define the logic that will be included, based on lab ID.
      m5_lab(PC_BROKEN, ['Next PC
      m5_var(pc_style, 1)
      '])
      m5_var(imem_enable, 0)
      m5_lab(FETCH1, ['Fetch (part 1)
      m5_set(imem_enable, 1)
      '])
      m5_var(fetch_enable, 0)
      m5_lab(FETCH2, ['Fetch (part 2)
      m5_set(fetch_enable, 1)
      '])
      
      m5_lab(TYPE, ['Instruction Types Decode and Immediate Decode
      @1
         // Types
         $is_i_instr = $instr[6:3] == 4'b0000 ||
                       $instr[6:2] == 5'b00100 ||
                       $instr[6:2] == 5'b00110 ||
                       $instr[6:2] == 5'b11001 ;
         
         $is_r_instr = $instr[6:2] == 5'b01011 ||
                       $instr[6:2] == 5'b01100 ||
                       $instr[6:2] == 5'b01110 ||
                       $instr[6:2] == 5'b10100 ;
         
         $is_s_instr = $instr[6:3] == 4'b0100;
         
         $is_b_instr = $instr[6:2] == 5'b11000;
         
         $is_j_instr = $instr[6:2] == 5'b11011;
         
         $is_u_instr = $instr[6:2] == 5'b00101 ||
                       $instr[6:2] == 5'b01101;
      '])
      
      m5_lab(IMM, ['Instruction Immediate Value Decoded
      
         // Immediate
         $imm[31:0]  =  $is_i_instr ? {{21{$instr[31]}}, $instr[30:20]} :
                        $is_s_instr ? {{21{$instr[31]}}, $instr[30:25], $instr[11:7]} :
                        $is_b_instr ? {{20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
                        $is_u_instr ? {$instr[31:12], 12'b0} :
                        $is_j_instr ? {{12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                                       32'b0 ;
      '])
      
      m5_var(fields_style, 0)
      m5_lab(FIELDS, ['Instruction Immediate Valid
      m5_set(fields_style, 1)
      '])
      
      m5_lab(FIELDS_VALID, ['Instruction Field Decode
      m5_set(fields_style, 2)
      @1
         $funct7_valid = $is_r_instr;
         $funct3_valid = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs1_valid    = $is_r_instr || $is_i_instr || $is_s_instr || $is_b_instr;
         $rs2_valid    = $is_r_instr || $is_s_instr || $is_b_instr ;
         $rd_valid     = $is_r_instr || $is_i_instr || $is_u_instr || $is_j_instr;
      '])
      
      m5_var(decode_enable, 0)
      m5_lab(INSTR, ['Instruction Decode
      m5_set(decode_enable, 1)
      m5_var(decode_stage, @1)
      '])
      
      m5_var(rf_enable, 0)
      m5_var(rf_style, 0)
      m5_var(rf_common_rd, 0)
      m5_lab(RF_RD, ['Register File Read
      m5_set(rf_enable, 1)
      m5_set(rf_rd_stage, @1)
      m5_set(rf_wr_stage, @1)
      m5_set(rf_style, 1)
      m5_set(rf_common_rd, 1)
      '])
      
      m5_var(rf_bypass, 0)
      m5_var(rf_rd_data, 0)
      m5_lab(RF_RD2, ['Register File Read (part 2)
      m5_var(rf_rd_data, 1)
      '])
      
      m5_var(alu_style, 0)
      m5_lab(ALU, ['Arithmetic Logic Unit
      m5_set(alu_style, 1)
      m5_var(alu_stage, @1)
      '])
      
      m5_lab(RF_WR, ['Register File Write
      m5_set(rf_style, 2)
      '])
      
      m5_var(br_enable, 0)
      m5_lab(BR1, ['Branches (part 1)
      m5_set(br_enable, 1)
      m5_var(br_stage, @1)
      '])
      
      m5_var(tgt_enable, 0)
      m5_lab(BR2, ['Branches (part 2)
      m5_set(pc_style, 2)
      m5_set(tgt_enable, 1)
      m5_var(tgt_stage, @1)
      '])
      
      m5_var(tb_style, 0)
      m5_lab(TB, ['Testbench
      m5_set(tb_style, 1)
      '])
      
      m5_var(valid_style, 0)
      m5_lab(3CYC_VALID, ['3-Cycle Valid
      m5_set(valid_style, 1)
      '])
      
      m5_lab(3CYC1, ['3-Cycle RISC-V (part 1)
      m5_set(rf_style, 3)
      m5_set(pc_style, 3)
      @1
         $inc_pc[31:0] = $pc + 32'd4;
      @m5_if_eq(m5_LabId, 3CYC1, 1, 3)
         $valid_taken_br = $valid && $taken_br;
      '])
      
      m5_lab(3CYC2, ['3-Cycle RISC-V (part 2)
      m5_set(rf_rd_stage, @2)
      m5_set(rf_wr_stage, @3)
      m5_set(tgt_stage, @2)
      m5_set(alu_stage, @3)
      m5_set(br_stage, @3)
      '])
      
      m5_lab(RF_BYPASS, ['Register File Bypass
      m5_set(rf_bypass, 1)
      '])
      
      m5_lab(BR_VALID, ['Determining Branch Shadow
      m5_set(pc_style, 4)
      m5_set(valid_style, 2)
      '])
      
      m5_lab(ALL_INSTR, ['Complete Instruction Decode
      m5_set(decode_stage, @1)
      @1
         $is_lui     =  $dec_bits[6:0] ==        7'b0110111 ;
         $is_auipc   =  $dec_bits[6:0] ==        7'b0010111 ;
         $is_jal     =  $dec_bits[6:0] ==        7'b1101111 ;
         $is_jalr    =  $dec_bits[9:0] ==   10'b000_1100111 ;
       
         $is_load    =  $opcode        ==        7'b0000011 ;
         
         //$is_sb      =  $dec_bits[9:0] ==   10'b000_0100011 ;
         //$is_sh      =  $dec_bits[9:0] ==   10'b001_0100011 ;
         //$is_sw      =  $dec_bits[9:0] ==   10'b010_0100011 ;
         
         $is_slti    =  $dec_bits[9:0] ==   10'b010_0010011 ;
         $is_sltiu   =  $dec_bits[9:0] ==   10'b011_0010011 ;
         $is_xori    =  $dec_bits[9:0] ==   10'b100_0010011 ;
         $is_ori     =  $dec_bits[9:0] ==   10'b110_0010011 ;
         $is_andi    =  $dec_bits[9:0] ==   10'b111_0010011 ;
         $is_slli    =  $dec_bits      == 11'b0_001_0010011 ;
         $is_srli    =  $dec_bits      == 11'b0_101_0010011 ;
         $is_srai    =  $dec_bits      == 11'b1_101_0010011 ;
         
         $is_sub     =  $dec_bits      == 11'b1_000_0110011 ;
         $is_sll     =  $dec_bits      == 11'b0_001_0110011 ;
         $is_slt     =  $dec_bits      == 11'b0_010_0110011 ;
         $is_sltu    =  $dec_bits      == 11'b0_011_0110011 ;
         $is_xor     =  $dec_bits      == 11'b0_100_0110011 ;
         $is_srl     =  $dec_bits      == 11'b0_101_0110011 ;
         $is_sra     =  $dec_bits      == 11'b1_101_0110011 ;
         $is_or      =  $dec_bits      == 11'b0_110_0110011 ;
         $is_and     =  $dec_bits      == 11'b0_111_0110011 ;
         
      '])
      
      m5_lab(FULL_ALU, ['Complete ALU
      m5_set(alu_style, 2)
      m5_alu_stage
         m5_if(m5_reached(PRAGMAS), /* verilator lint_off WIDTH */)
         $sltu_rslt[31:0]      =   $src1_value < $src2_value ;
         $sltiu_rslt[31:0]     =   $src1_value < $imm;
         m5_if(m5_reached(PRAGMAS), /* verilator lint_on WIDTH */)
      '])
      
      m5_lab(LD_REDIR, ['Redirect Loads
      m5_set(valid_style, 3)
      m5_set(pc_style, 5)
      @3
         $valid_load = $valid && $is_load;
      '])
      
      m5_lab(LD_DATA, ['Load Data
      m5_set(alu_style, 3)
      m5_set(rf_style, 4)
      '])
      
      m5_lab(DMEM, ['Data Memory
      @4
         $dmem_wr_en          = $is_s_instr && $valid;
         $dmem_wr_data[31:0]  = $src2_value;
         $dmem_rd_en          = $valid_load;
         $dmem_addr[2:0]      = $result[4:2];
         
      @5
         $ld_data[31:0]       = $dmem_rd_data;
         
      m4+dmem(@4)
      '])
   
   m5_lab(LD_ST_TB, ['Load/Store in Program
   
   |cpu
      m5_set(tb_style, 2)
   '])
      
      m5_lab(DONE, ['Jumps
      m5_set(valid_style, 4)
      m5_set(pc_style, 6)
      
      @3
         $is_jump    =  $is_jal || $is_jalr;
         $jalr_tgt_pc[31:0]   =  $src1_value + $imm;
         $valid_jump =  $is_jump && $valid;
      '])
   
   
   
      // Logic that changes throughout.

      
      @0
      m4_ifelse_block(m5_pc_style, 1, ['
         $pc[31:0]   =  >>1$reset   ?  32'b0 : 
                                       >>1$pc + 32'd4;
      '], m5_pc_style, 2, ['
         $pc[31:0]   =  >>1$reset      ?  '0 :
                        >>1$taken_br   ?  >>1$br_tgt_pc :
                                          >>1$pc + 32'd4;
      '], m5_pc_style, 3, ['
         $pc[31:0]   =  >>1$reset            ?  '0 :
                        >>3$valid_taken_br   ?  >>3$br_tgt_pc :
                                                >>3$inc_pc ;
      '], m5_pc_style, 4, ['
         $pc[31:0]   =  >>1$reset            ?  '0 :
                        >>3$valid_taken_br   ?  >>3$br_tgt_pc :
                                                >>1$inc_pc ;
      '], m5_pc_style, 5, ['
         $pc[31:0]   =  >>1$reset            ?  '0 :
                        >>3$valid_taken_br   ?  >>3$br_tgt_pc :
                        >>3$valid_load       ?  >>3$inc_pc    :
                                                >>1$inc_pc ;
      '], m5_pc_style, 6, ['
         $pc[31:0]   =  >>1$reset                     ?  '0 :
                        >>3$valid_taken_br            ?  >>3$br_tgt_pc   :
                        >>3$valid_load                ?  >>3$inc_pc      :
                        >>3$valid_jump && >>3$is_jal  ?  >>3$br_tgt_pc   :
                        >>3$valid_jump && >>3$is_jalr ?  >>3$jalr_tgt_pc :
                                                         >>1$inc_pc ;
      '])
      
      m4_ifelse_block(m5_tgt_enable, 1, ['
      m5_tgt_stage
         $br_tgt_pc[31:0] = $pc + $imm;
      '])
      
      m4_ifelse_block(m5_fetch_enable, 1, ['
      @0
         $imem_rd_en                          = !$reset;
         $imem_rd_addr[m5_IMEM_INDEX_CNT-1:0] = $pc[m5_IMEM_INDEX_CNT+1:2];
      @1
         $instr[31:0]                         = $imem_rd_data[31:0];
         //`BOGUS_USE($instr)
      '])
      
      m4_ifelse_block(m5_fields_style, 1, ['
      @1
         $funct7[6:0] = $instr[31:25];
         $funct3[2:0] = $instr[14:12];
         $rs1[4:0]    = $instr[19:15];
         $rs2[4:0]    = $instr[24:20];
         $rd[4:0]     = $instr[11:7];
         $opcode[6:0] = $instr[6:0];
         //`BOGUS_USE($funct7 $funct3 $opcode)
      '], m5_fields_style, 2, ['         // Other fields
      @1
         ?$funct7_valid
            $funct7[6:0] = $instr[31:25];
         ?$funct3_valid
            $funct3[2:0] = $instr[14:12];
         ?$rs1_valid
            $rs1[4:0]    = $instr[19:15];
         ?$rs2_valid
            $rs2[4:0]    = $instr[24:20];
         ?$rd_valid
            $rd[4:0]     = $instr[11:7];
         $opcode[6:0]    = $instr[6:0];
         //`BOGUS_USE($funct7 $funct3 $opcode $funct3)
      '])
      
      m4_ifelse_block(m5_decode_enable, 1, ['
      m5_decode_stage
         $dec_bits[10:0] = {$funct7[5], $funct3, $opcode};
         $is_beq     =  $dec_bits[9:0] ==   10'b000_1100011 ;
         $is_bne     =  $dec_bits[9:0] ==   10'b001_1100011 ;
         $is_blt     =  $dec_bits[9:0] ==   10'b100_1100011 ;
         $is_bge     =  $dec_bits[9:0] ==   10'b101_1100011 ;
         $is_bltu    =  $dec_bits[9:0] ==   10'b110_1100011 ;
         $is_bgeu    =  $dec_bits[9:0] ==   10'b111_1100011 ;
         
         $is_addi    =  $dec_bits[9:0] ==   10'b000_0010011 ;
         $is_add     =  $dec_bits      == 11'b0_000_0110011 ;
      '])
      
      m5_rf_rd_stage
      m4_ifelse_block(m5_rf_common_rd, 1, ['
         $rf_rd_en1           =  $rs1_valid;
         $rf_rd_en2           =  $rs2_valid;
         $rf_rd_index1[4:0]   =  $rs1;
         $rf_rd_index2[4:0]   =  $rs2;
      '])
      
      m4_ifelse_block(m5_rf_enable, 1, ['
      m4_ifelse_block(m5_rf_bypass, 0, ['
      m4_ifelse_block(m5_rf_rd_data, 1, ['
         $src1_value[31:0]    =  $rf_rd_data1;
         $src2_value[31:0]    =  $rf_rd_data2;
      '])
      '], m5_rf_bypass, 1, ['
         $src1_value[31:0] =
              (>>1$rf_wr_index == $rf_rd_index1) && >>1$rf_wr_en
                  ?  >>1$result   :
                     $rf_rd_data1 ;
         $src2_value[31:0] =
              (>>1$rf_wr_index == $rf_rd_index2) && >>1$rf_wr_en
                  ?  >>1$result   :
                     $rf_rd_data2 ;
      '])
      '])
      
      m5_rf_wr_stage
      m4_ifelse_block(m5_rf_style, 1, ['
         $rf_wr_en            =  1'b0;
         $rf_wr_index[4:0]    =  5'b0;
         $rf_wr_data[31:0]    =  32'b0;
      '], m5_rf_style, 2, ['
         $rf_wr_en            =  $rd_valid && $rd != 5'b0;
         $rf_wr_index[4:0]    =  $rd;
         $rf_wr_data[31:0]    =  $result;
      '], m5_rf_style, 3, ['
         $rf_wr_en            =  $rd_valid && $rd != 5'b0 && $valid;
         $rf_wr_index[4:0]    =  $rd;
         $rf_wr_data[31:0]    =  $result;
      '], m5_rf_style, 4, ['
         $rf_wr_en            =  ($rd_valid && $valid && $rd != 5'b0) || >>2$valid_load;
         $rf_wr_index[4:0]    =  >>2$valid_load ? >>2$rd : $rd;
         $rf_wr_data[31:0]    =  >>2$valid_load ? >>2$ld_data : $result;
      '])
      
      m5_if(m5_reached(PRAGMAS), /* verilator lint_off WIDTH */)
      
      m4_ifelse_block(m5_alu_style, 1, ['
      m5_alu_stage
         $result[31:0] =   $is_addi ?  $src1_value + $imm :
                           $is_add  ?  $src1_value + $src2_value :
                                       32'bx;
      '], m5_calc(m5_eq(m5_alu_style, 2) || m5_eq(m5_alu_style, 3)), 1, ['
      m5_alu_stage
         $result[31:0] =   $is_andi    ?  $src1_value & $imm :
                           $is_ori     ?  $src1_value | $imm :
                           $is_xori    ?  $src1_value ^ $imm :
                           m5_if_eq(m5_alu_style, 2, ['$is_addi   '], ['($is_addi || $is_load || $is_s_instr)']) ?  $src1_value + $imm :
                           $is_slli    ?  $src1_value << $imm[5:0]  :
                           $is_srli    ?  $src1_value >> $imm[5:0]  :
                           $is_and     ?  $src1_value & $src2_value :
                           $is_or      ?  $src1_value | $src2_value :
                           $is_xor     ?  $src1_value ^ $src2_value :
                           $is_add     ?  $src1_value + $src2_value :
                           $is_sub     ?  $src1_value - $src2_value :
                           $is_sll     ?  $src1_value << $src2_value[4:0] :
                           $is_srl     ?  $src1_value >> $src2_value[4:0] :
                           $is_sltu    ?  $sltu_rslt :
                           $is_sltiu   ?  $sltiu_rslt :
                           $is_lui     ?  {$imm[31:12], 12'b0} :
                           $is_auipc   ?  $pc + $imm :
                           $is_jal     ?  $pc + 32'd4 :
                           $is_jalr    ?  $pc + 32'd4 :
                           $is_srai    ?  {{32{$src1_value[31]}}, $src1_value} >> $imm[4:0] :
                           $is_slt     ?  (($src1_value[31] == $src2_value[31]) ? $sltu_rslt  : {31'b0, $src1_value[31]}) :
                           $is_slti    ?  (($src1_value[31] == $imm[31])        ? $sltiu_rslt : {31'b0, $src1_value[31]}) :
                           $is_sra     ?  {{32{$src1_value[31]}}, $src1_value} >> $src2_value[4:0] :
                                          32'bx;
      '])
      
      m5_if(m5_reached(PRAGMAS), /* verilator lint_on WIDTH */)
      
      m4_ifelse_block(m5_br_enable, 1, ['
      m5_br_stage
         $taken_br   =  $is_beq  ? ($src1_value == $src2_value) :
                        $is_bne  ? ($src1_value != $src2_value) :
                        $is_blt  ? (($src1_value < $src2_value)  ^ ($src1_value[31] != $src2_value[31])) :
                        $is_bge  ? (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
                        $is_bltu ? ($src1_value < $src2_value)  :
                        $is_bgeu ? ($src1_value >= $src2_value) :
                                   1'b0;
         //`BOGUS_USE($taken_br)
      '])
      
      m4_ifelse_block(m5_valid_style, 1, ['
      @0
         $start = >>1$reset && !$reset;
         $valid = $reset ? 1'b0 :
                  $start ? 1'b1 :
                           >>3$valid ;
      '], m5_valid_style, 2, ['
      @3
         $valid = $reset ? 1'b0 :
                           !(>>1$valid_taken_br || >>2$valid_taken_br);
      '], m5_valid_style, 3, ['
      @3
         $valid = $reset ? 1'b0 :
                           !(>>1$valid_taken_br || >>2$valid_taken_br ||
                             >>1$valid_load     || >>2$valid_load);
      '], m5_valid_style, 4, ['
      @3
         $valid = $reset ? 1'b0 :
                           !(>>1$valid_taken_br || >>2$valid_taken_br ||
                             >>1$valid_load     || >>2$valid_load     ||
                             >>1$valid_jump     || >>2$valid_jump);
      '])
      
      @1
         m4_ifelse_block(m5_tb_style, 1, ['
         *passed = |cpu/xreg[10]>>5$value == (1+2+3+4+5+6+7+8+9);
         '], m5_tb_style, 2, ['
         *passed = |cpu/xreg[15]>>5$value == (1+2+3+4+5+6+7+8+9);
         '], ['
         *passed = *top.cyc_cnt > 80;
         '])
   
   
   *failed = 1'b0;
   
   |cpu
      m4_ifelse_block(m5_imem_enable, 1, ['
      // IMem
      m4+imem(@1)    // Args: (read stage)
      '])
      
      // Args: (read stage, write stage) - if equal, no register bypass is required
      m4_ifelse_block(m5_rf_enable, 1, ['
      m4+rf(m5_rf_rd_stage, m5_rf_wr_stage)
      '])
      
   // ============================================================================================================
   
   // Connect Tiny Tapeout outputs.
   // Note that my_design will be under /fpga_pins/fpga.
   *uo_out = {6'b0, *failed, *passed};
   m5_if_neq(m5_target, FPGA, ['*uio_out = 8'b0;'])
   m5_if_neq(m5_target, FPGA, ['*uio_oe = 8'b0;'])
   
   m5_if_defined_as(MAKERCHIP, 1, ['m4+cpu_viz(@4)'])    // For visualisation, argument should be at least equal to the last stage of CPU logic. @4 would work for all labs.

//----------------
\SV

// ================================================
// A simple Makerchip Verilog test bench driving random stimulus.
// Modify the module contents to your needs.
// ================================================

module top(input logic clk, input logic reset, input logic [31:0] cyc_cnt, output logic passed, output logic failed);
   // Tiny tapeout I/O signals.
   logic [7:0] ui_in, uo_out;
   m5_if_neq(m5_target, FPGA, ['logic [7:0] uio_in, uio_out, uio_oe;'])
   m5_if(m5_CalcLab, ['logic [31:0] r;'])
   m5_if(m5_CalcLab, ['always @(posedge clk) r <= m5_if_defined_as(MAKERCHIP, 1, ['$urandom()'], ['0']);'])
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
   
   assign passed = m5_if(m5_CalcLab, ['top.cyc_cnt > 80'], ['uo_out[0]']);
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
