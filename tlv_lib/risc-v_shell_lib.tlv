\m5_TLV_version 1d: tl-x.org
\m5
   use(m5-1.0)
   
   define_vector(WORD, 32)
   var(NUM_INSTRS, 0)

   // Allow register file and dmem sizes to be configurable (small powers of two).
   default_var(num_regs, 16)
   define_hier(XREG, m5_num_regs)
   default_var(dmem_size, 8)
   define_hier(DMEM, m5_dmem_size)
   // A hack to address the fact that the videos reference M4_ macros.
   eval(['m4_define(['M4_IMEM_INDEX_CNT'], ['m5_IMEM_INDEX_CNT'])'])
\SV
   m4_include_lib(['https://raw.githubusercontent.com/stevehoover/warp-v_includes/450357b4993fa480e7fca57dc346e39cba21b6bc/risc-v_defs.tlv'])


// Instruction memory in |cpu at the given stage.
\TLV imem(@_stage)
   // Instruction Memory containing program.
   @_stage
      \SV_plus
         // The program in an instruction memory.
         logic [31:0] instrs [0:m5_NUM_INSTRS-1];
         m5_repeat(m5_NUM_INSTRS, ['assign instrs[m5_LoopCnt] = m5_eval(m5_eval(m5_get(['instr']m5_LoopCnt))); '])
      /m5_IMEM_HIER
         $instr[31:0] = *instrs\[#imem\];
      ?$imem_rd_en
         $imem_rd_data[31:0] = /imem[$imem_rd_addr]$instr;


// A 2-rd 1-wr register file in |cpu that reads and writes in the given stages. If read/write stages are equal, the read values reflect previous writes.
// Reads earlier than writes will require bypass.
\TLV rf(@_rd, @_wr)
   // Reg File
   @_wr
      /m5_XREG_HIER
         $wr = |cpu$rf_wr_en && (|cpu$rf_wr_index != 5'b0) && (|cpu$rf_wr_index == #xreg);
         $value[31:0] = |cpu$reset ?   #xreg           :
                        $wr        ?   |cpu$rf_wr_data :
                                       $RETAIN;
   @_rd
      ?$rf_rd_en1
         $rf_rd_data1[31:0] = /xreg[$rf_rd_index1[m5_XREG_INDEX_RANGE]]>>m4_stage_eval(@_wr - @_rd + 1)$value;
      ?$rf_rd_en2
         $rf_rd_data2[31:0] = /xreg[$rf_rd_index2[m5_XREG_INDEX_RANGE]]>>m4_stage_eval(@_wr - @_rd + 1)$value;
      `BOGUS_USE($rf_rd_data1 $rf_rd_data2) 


// A data memory in |cpu at the given stage. Reads and writes in the same stage, where reads are of the data written by the previous transaction.
\TLV dmem(@_stage)
   // Data Memory
   @_stage
      /m5_DMEM_HIER
         $wr = |cpu$dmem_wr_en && (|cpu$dmem_addr[m5_DMEM_INDEX_RANGE] == #dmem);
         $value[31:0] = |cpu$reset ?   #dmem :
                        $wr        ?   |cpu$dmem_wr_data :
                                       $RETAIN;
                                  
      ?$dmem_rd_en
         $dmem_rd_data[31:0] = /dmem[$dmem_addr[m5_DMEM_INDEX_RANGE]]>>1$value;
      `BOGUS_USE($dmem_rd_data)

\TLV myth_fpga(@_stage)
   @_stage

\TLV cpu_viz(@_stage)
   m4_ifelse_block(m5_if_defined_as(MAKERCHIP, 1, 1, 0), 1, ['
   m5_var(cpu_viz_top, m5_if_defined_as(in_fpga, 0, ['/top'], ['/fpga']))
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['
   |cpu
      /imem[m5_calc(m5_NUM_INSTRS-1):0]   // Declare it in case these is no imem.
      // for pulling default viz signals into CPU
      // and then back into viz
      @0
         $ANY = m5_cpu_viz_top|cpuviz/defaults<>0$ANY;
         `BOGUS_USE($dummy)
         /m5_XREG_HIER
            $ANY = m5_cpu_viz_top|cpuviz/defaults/xreg<>0$ANY;
         /m5_DMEM_HIER
            $ANY = m5_cpu_viz_top|cpuviz/defaults/dmem<>0$ANY;
   // String representations of the instructions for debug.
   \SV_plus
      logic [40*8-1:0] instr_strs [0:m5_NUM_INSTRS];
      // String representations of the instructions for debug.
      m5_repeat(m5_NUM_INSTRS, ['assign instr_strs[m5_LoopCnt] = "m5_eval(['m5_get(['instr_str']m5_LoopCnt)'])"; '])
      assign instr_strs[m5_NUM_INSTRS] = "END                                     ";
   |cpuviz
      @1
         /imem[m5_calc(m5_NUM_INSTRS-1):0]
            $instr[31:0] = m5_cpu_viz_top|cpu/imem<>0$instr;
            $instr_str[40*8-1:0] = *instr_strs[imem];
            \viz_js
               box: {width: 500, height: 18, strokeWidth: 0},
               onTraceData() {
                  let instr_str = '$instr'.asBinaryStr(NaN) + "    " + '$instr_str'.asString();
                  return {objects: {instr_str: new fabric.Text(instr_str, {
                     top: 0,
                     left: 0,
                     fontSize: 14,
                     fontFamily: "monospace",
                     fill: "white"
                  })}};
               },
               where: {left: -450, top: 0}
             
      @0
         /defaults
            {$is_lui, $is_auipc, $is_jal, $is_jalr, $is_beq, $is_bne, $is_blt, $is_bge, $is_bltu, $is_bgeu, $is_lb, $is_lh, $is_lw, $is_lbu, $is_lhu, $is_sb, $is_sh, $is_sw} = '0;
            {$is_addi, $is_slti, $is_sltiu, $is_xori, $is_ori, $is_andi, $is_slli, $is_srli, $is_srai, $is_add, $is_sub, $is_sll, $is_slt, $is_sltu, $is_xor} = '0;
            {$is_srl, $is_sra, $is_or, $is_and, $is_csrrw, $is_csrrs, $is_csrrc, $is_csrrwi, $is_csrrsi, $is_csrrci} = '0;
            $is_load = 1'b0;

            $valid               = 1'b1;
            $rd[4:0]             = 5'b0;
            $rs1[4:0]            = 5'b0;
            $rs2[4:0]            = 5'b0;
            $src1_value[31:0]    = 32'b0;
            $src2_value[31:0]    = 32'b0;

            $result[31:0]        = 32'b0;
            $pc[31:0]            = 32'b0;
            $imm[31:0]           = 32'b0;

            $is_s_instr          = 1'b0;

            $rd_valid            = 1'b0;
            $rs1_valid           = 1'b0;
            $rs2_valid           = 1'b0;
            $rf_wr_en            = 1'b0;
            $rf_wr_index[4:0]    = 5'b0;
            $rf_wr_data[31:0]    = 32'b0;
            $rf_rd_en1           = 1'b0;
            $rf_rd_en2           = 1'b0;
            $rf_rd_index1[4:0]   = 5'b0;
            $rf_rd_index2[4:0]   = 5'b0;

            $ld_data[31:0]       = 32'b0;
            $imem_rd_en          = 1'b0;
            $imem_rd_addr[m5_IMEM_INDEX_CNT-1:0] = {m5_IMEM_INDEX_CNT{1'b0}};
            
            /m5_XREG_HIER
               $value[31:0]      = 32'b0;
               $wr               = 1'b0;
               `BOGUS_USE($value $wr)
               $dummy[0:0]       = 1'b0;
            /m5_DMEM_HIER
               $value[31:0]      = 32'b0;
               $wr               = 1'b0;
               `BOGUS_USE($value $wr) 
               $dummy[0:0]       = 1'b0;
            `BOGUS_USE($is_lui $is_auipc $is_jal $is_jalr $is_beq $is_bne $is_blt $is_bge $is_bltu $is_bgeu $is_lb $is_lh $is_lw $is_lbu $is_lhu $is_sb $is_sh $is_sw)
            `BOGUS_USE($is_addi $is_slti $is_sltiu $is_xori $is_ori $is_andi $is_slli $is_srli $is_srai $is_add $is_sub $is_sll $is_slt $is_sltu $is_xor)
            `BOGUS_USE($is_srl $is_sra $is_or $is_and $is_csrrw $is_csrrs $is_csrrc $is_csrrwi $is_csrrsi $is_csrrci)
            `BOGUS_USE($is_load)
            `BOGUS_USE($valid $rd $rs1 $rs2 $src1_value $src2_value $result $pc $imm)
            `BOGUS_USE($is_s_instr $rd_valid $rs1_valid $rs2_valid)
            `BOGUS_USE($rf_wr_en $rf_wr_index $rf_wr_data $rf_rd_en1 $rf_rd_en2 $rf_rd_index1 $rf_rd_index2 $ld_data)
            `BOGUS_USE($imem_rd_en $imem_rd_addr)
            
            $dummy[0:0]          = 1'b0;
      @_stage
         $ANY = m5_cpu_viz_top|cpu<>0$ANY;
         
         /m5_XREG_HIER
            $ANY = m5_cpu_viz_top|cpu/xreg<>0$ANY;
            `BOGUS_USE($dummy)
         
         /m5_DMEM_HIER
            $ANY = m5_cpu_viz_top|cpu/dmem<>0$ANY;
            `BOGUS_USE($dummy)

         // m5_mnemonic_expr is build for WARP-V signal names, which are slightly different. Correct them.
         m4_define(['m4_modified_mnemonic_expr'], ['m4_patsubst(m5_mnemonic_expr, ['_instr'], [''])'])
         $mnemonic[10*8-1:0] = m4_modified_mnemonic_expr $is_load ? "LOAD      " : $is_s_instr ? "STORE     " : "ILLEGAL   ";
         \viz_js
            box: {left: -470, top: -20, width: 1070, height: 1000, strokeWidth: 0 m5_if_defined_as(in_fpga, 0, [', fill: "#363638"'], [''])},
            render() {
               //
               // PC instr_mem pointer
               //
               let $pc = '$pc';
               let color = !('$valid'.asBool()) ? "gray" :
                                                  "cyan";
               let pcPointer = new fabric.Text("➥", {
                  top: 18 * ($pc.asInt() / 4) - 6,
                  left: -166,
                  fill: color,
                  fontSize: 24,
                  fontFamily: "monospace"
               });
               //
               //
               // Fetch Instruction
               //
               // TODO: indexing only works in direct lineage.  let fetchInstr = new fabric.Text('|fetch/instr_mem[$Pc]$instr'.asString(), {  // TODO: make indexing recursive.
               //let fetchInstr = new fabric.Text('$raw'.asString("--"), {
               //   top: 50,
               //   left: 90,
               //   fill: color,
               //   fontSize: 14,
               //   fontFamily: "monospace"
               //});
               //
               // Instruction with values.
               //
               let regStr = (valid, regNum, regValue) => {
                  return valid ? `x${regNum} (${regValue})` : `xX`;
               };
               let srcStr = ($src, $valid, $reg, $value) => {
                  return $valid.asBool(false)
                             ? `\n      ${regStr(true, $reg.asInt(NaN), $value.asInt(NaN))}`
                             : "";
               };
               let str = `${regStr('$rd_valid'.asBool(false), '$rd'.asInt(NaN), '$result'.asInt(NaN))}\n` +
                         `  = ${'$mnemonic'.asString()}${srcStr(1, '$rs1_valid', '$rs1', '$src1_value')}${srcStr(2, '$rs2_valid', '$rs2', '$src2_value')}\n` +
                         `      i[${'$imm'.asInt(NaN)}]`;
               let instrWithValues = new fabric.Text(str, {
                  top: 70,
                  left: 140,
                  fill: color,
                  fontSize: 14,
                  fontFamily: "monospace"
               });
               return [pcPointer, instrWithValues];
            }
         //
         // Register file
         //
         /m5_XREG_HIER
            \viz_js
               box: {width: 90, height: 18, strokeWidth: 0},
               all: {
                  box: {strokeWidth: 0},
                  init() {
                     let regname = new fabric.Text("Reg File", {
                        top: -20, left: 2,
                        fontSize: 14,
                        fontFamily: "monospace",
                        fill: "white"
                     });
                     return {regname};
                  }
               },
               init() {
                  let reg = new fabric.Text("", {
                     top: 0, left: 0,
                     fontSize: 14,
                     fontFamily: "monospace",
                     fill: "white"
                  });
                  return {reg};
               },
               render() {
                  let mod = '$wr'.asBool(false);
                  let reg = parseInt(this.getIndex());
                  let regIdent = reg.toString();
                  let oldValStr = mod ? `(${'>>1$value'.asInt(NaN).toString()})` : "";
                  this.getObjects().reg.set({
                     text: regIdent + ": " + '$value'.asInt(NaN).toString() + oldValStr,
                     fill: mod ? "cyan" : "white"});
               },
               where: {left: 365, top: -20},
               where0: {left: 0, top: 0}
         //
         // DMem
         //
         /m5_DMEM_HIER
            \viz_js
               box: {width: 100, height: 18, strokeWidth: 0},
               all: {
                  box: {strokeWidth: 0},
                  init() {
                  let memname = new fabric.Text("Mini DMem", {
                        top: -20,
                        left: 2,
                        fontSize: 14,
                        fontFamily: "monospace",
                        fill: "white"
                     });
                     return {memname};
                  }
               },
               init() {
                  let mem = new fabric.Text("", {
                     top: 0,
                     left: 10,
                     fontSize: 14,
                     fontFamily: "monospace",
                     fill: "white"
                  });
                  return {mem};
               },
               render() {
                  let mod = '$wr'.asBool(false);
                  let mem = parseInt(this.getIndex());
                  let memIdent = mem.toString();
                  let oldValStr = mod ? `(${'>>1$value'.asInt(NaN).toString()})` : "";
                  this.getObjects().mem.set({
                     text: memIdent + ": " + '$value'.asInt(NaN).toString() + oldValStr,
                     fill: mod ? "cyan" : "white"});
               },
               where: {left: 458, top: -20},
               where0: {left: 0, top: 0}
   '])    
   '])
