\m5_TLV_version 1d: tl-x.org
\SV

\TLV cal_viz(@_stage, /_top)
   // Only for Makerchip.
   m4_ifdef(['M4_MAKERCHIP'], ['m4+cal_viz_internal(['@_stage'], ['/_top'])'], [''])

// Visualization for calculator
\TLV cal_viz_internal(@_stage, /_top)
   m4_pushdef(['m4_top'], m4_ifelse(/_top, [''], ['['/top']'], ['['/_top']']))
   m4_ifelse_block(m4_sp_graph_dangerous, 1, [''], ['
   |calc
      @0
         $ANY = m4_top|tb/default<>0$ANY;
         `BOGUS_USE($dummy $rand2 $rand1)
   |tb
      @0
         /default
            $valid = ! m4_top|calc<>0$reset;
            \SV_plus
               always @(posedge clk) $$rand[31:0] <= \$random();
            $rand_op[2:0] = $rand[2:0];
            $rand1[3:0] = $rand[6:3];
            $rand2[3:0] = $rand[10:7];
            $op[2:0] = ((*top.cyc_cnt % 2) != 0)
                           ? $rand_op[2:0]
                           //? ( (*top.cyc_cnt > 33) ? ($rand_op[2:0] % 2) :
                           //    (*top.cyc_cnt > 15) ? $rand_op[2:0] :
                           //                          ((($rand_op[2:0] % 2) != 0) + ($rand_op[2:0] % 4)) )
                           : >>1$op;
            $val1[7:0] = '0;
            $val2[7:0] = '0;
            $out[7:0] = '0;
            $mem[8:0] = 9'h100;   // Indicates to VIZ that there is no memory.
            $dummy = 0;
            `BOGUS_USE($out $mem $valid $val1 $val2 $dummy $rand1 $rand2)
      @_stage   
         $ANY = m4_top|calc<>0$ANY;

         \viz_js
            box: {strokeWidth: 0},
            init() {
               let value_right = 150 + 316 - 30;
               m5_var(value_props, ['left: value_right, top: 150 + 221 + 7, originX: "right", textAlign: "right", fontSize: 22, fontFamily: "Courier New"'])
               let tlvname = new fabric.Text("TL-V", {
                 left: 150 + 130,
                 top: 150 - 40,
                 fontSize: 22,
                 fontFamily: "Times",
                 fill: "white",
               });
               let hexcalname = new fabric.Text("HEX CALCULATOR", {
                 left: 150 + 60,
                 top: 150 - 20,
                 fontSize: 22,
                 fontFamily: "Times",
                 fill: "white",
               });
               let calbox = new fabric.Rect({
                 left: 150,
                 top: 150,
                 fill: "#779",
                 width: 316,
                 height: 366,
                 stroke: "black",
                 strokeWidth: 1,
                 rx: 5, ry: 5,
               });
               let val1box = new fabric.Rect({
                 left: 150 + 28,
                 top: 150 + 83,
                 fill: "#ddd",
                 width: 254 + 14,
                 height: 40,
                 stroke: "black",
                 strokeWidth: 1,
               });
               let val1num = new fabric.Text("", {
                 m5_value_props,
                 top: 150 + 89,
               });
               let val2box = new fabric.Rect({
                 left: 150 + 187,
                 top: 150 + 221,
                 fill: "#ddd",
                 width: 109,
                 height: 40,
                 stroke: "black",
                 strokeWidth: 1,
               });
               let val2num = new fabric.Text("", {
                 m5_value_props,
                 top: 150 + 221 + 7,
               });
               let outbox = new fabric.Rect({
                 left: 150 + 97,
                 top: 150 + 300,
                 fill: "#ddd",
                 width: 199,
                 height: 40,
                 stroke: "black",
                 strokeWidth: 1,
               });
               let outnum = new fabric.Text("", {
                 m5_value_props,
                 top: 150 + 300 + 8,
               });
               let equalname = new fabric.Text("=", {
                 left: 150 + 38,
                 top: 150 + 306,
                 fontSize: 28,
                 fontFamily: "Times",
               });
                 let sumbox = new fabric.Rect({
                 left: 150 + 28,
                 top: 150 + 148,
                 fill: "white",
                 width: 64,
                 height: 64,
                 stroke: "#333",
                 strokeWidth: 1,
                 rx: 3, ry: 3,
               });
               let prodbox = new fabric.Rect({
                 left: 150 + 28,
                 top: 150 + 222,
                 fill: "white",
                 width: 64,
                 height: 64,
                 stroke: "#333",
                 strokeWidth: 1,
                 rx: 3, ry: 3,
               });
               let minbox = new fabric.Rect({
                 left: 150 + 105,
                 top: 150 + 148,
                 fill: "white",
                 width: 64,
                 height: 64,
                 stroke: "#333",
                 strokeWidth: 1,
                 rx: 3, ry: 3,
               });
               let quotbox = new fabric.Rect({
                 left: 150 + 105,
                 top: 150 + 222,
                 fill: "white",
                 width: 64,
                 height: 64,
                 stroke: "#333",
                 strokeWidth: 1,
                 rx: 3, ry: 3,
               });
               let sumicon = new fabric.Text("+", {
                 left: 150 + 28 + 26,
                 top: 150 + 148 + 22,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               let prodicon = new fabric.Text("*", {
                 left: 150 + 28 + 26,
                 top: 150 + 222 + 22,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               let minicon = new fabric.Text("-", {
                 left: 150 + 105 + 26,
                 top: 150 + 148 + 22,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               let quoticon = new fabric.Text("/", {
                 left: 150 + 105 + 26,
                 top: 150 + 222 + 22,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               let membox = new fabric.Rect({
                 left: 105 + 150,
                 top: 150 + 25,
                 fill: "#ddd",
                 width: 191,
                 height: 23,
                 stroke: "black",
                 strokeWidth: 1
               });
               let memname = new fabric.Text("mem", {
                 left: 150 + 28,
                 top: 150 + 25,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               let memarrow = new fabric.Text("->", {
                 left: 150 + 32 + 47,
                 top: 150 + 25,
                 fill: "#779",
                 fontSize: 22,
                 fontFamily: "monospace",
               });
               let recallarrow = new fabric.Text("->", {
                 left: 150 + 38 + 28,
                 top: 150 + 308,
                 fill: "#779",
                 fontSize: 22,
                 fontFamily: "monospace",
               });
               let memnum = new fabric.Text("", {
                 m5_value_props,
                 top: 150 + 25,
               });
               let membuttonbox = new fabric.Rect({
                 left: 150 + 187,
                 top: 150 + 151,
                 fill: "white",
                 width: 45,
                 height: 40,
                 stroke: "#333",
                 strokeWidth: 1,
                 rx: 3, ry: 3,
               });
               let recallbuttonbox = new fabric.Rect({
                 left: 150 + 245,
                 top: 150 + 151,
                 fill: "white",
                 width: 51,
                 height: 40,
                 stroke: "#333",
                 strokeWidth: 1,
                 rx: 3, ry: 3,
               });
               let membuttonname = new fabric.Text("mem", {
                 left: 150 + 187 + 1,
                 top: 150 + 151 + 7,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               let recallbuttonname = new fabric.Text("recall", {
                 left: 150 + 245 + 1,
                 top: 150 + 151 + 7,
                 fontSize: 22,
                 fontFamily: "Times",
               });
               return {tlvname, hexcalname, calbox, val1box, val1num, val2box, val2num, outbox, outnum, equalname, sumbox, minbox, prodbox, quotbox, sumicon, prodicon, minicon, quoticon,  membox, memname, memnum, membuttonbox, recallbuttonbox, membuttonname, recallbuttonname, memarrow, recallarrow};
            },
            render() {
               let valid = '$valid'.asBool(false);
               let has_mem = '$mem'.asInt(NaN) != 0x100;
               let op = has_mem ? '$op'.asInt(NaN) : '$op'.asInt(NaN) & 0x3;
               let mem_mod = has_mem ? '$mem'.asInt(NaN) : 0;
               let is_sum     = valid && (op == 0);
               let is_diff    = valid && (op == 1);
               let is_prod    = valid && (op == 2);
               let is_quot    = valid && (op == 3);
               let is_recall  = valid && (op == 4);
               let is_mem     = valid && (op == 5);
               let is_invalid_op = valid && (op == 6 || op == 7);
               let is_arith  = valid && !is_recall && !is_mem && !is_invalid_op;
               
               // For debugging
               let oldvalval1 = "";
               let oldvalval2 = "";
               let oldvalout = "";
               let oldvalrecall = "";
         
               this.getObjects().val1num.set({
                  text: '$val1'.asInt(NaN).toString(16) + oldvalval1,
                  fill: "blue"});
               this.getObjects().val2num.set({
                  text: '$val2'.asInt(NaN).toString(16) + oldvalval2,
                  fill: is_arith ? "blue" : "grey"});
               this.getObjects().outnum.set({
                  text: '$out'.asInt(NaN).toString(16) + oldvalout,
                  fill: is_arith ? "blue" : "grey"});
               
               this.getObjects().memnum.set({
                  text: mem_mod.toString(16) + oldvalrecall,
                  fill: has_mem ? "blue" : "grey"});
               this.getObjects().sumbox.set({fill: is_sum ?  "#9fc5e8ff" : "white"});
               this.getObjects().minbox.set({fill: is_diff ?  "#9fc5e8ff" : "white"});
               this.getObjects().prodbox.set({fill: is_prod ? "#9fc5e8ff" : "white"});
               this.getObjects().quotbox.set({fill: is_quot ?  "#9fc5e8ff" : "white"});
               this.getObjects().membuttonbox.set({fill: is_mem ? "#9fc5e8ff" : "white"});
               this.getObjects().recallbuttonbox.set({fill: is_recall ?  "#9fc5e8ff" : "white"});
               this.getObjects().memarrow.set({fill: is_mem ? "blue" : "#779"});
               this.getObjects().recallarrow.set({fill: is_recall ?  "blue" : "#779"});
             }
   '])
   m4_popdef(['m4_top'])

// Currently calc solutions calls m4_cpu_viz (a hack to avoid the need to modify Makerchip hidden files). Calc solutions provide their own viz, so make sure cpu_viz is disabled. 
\TLV cpu_viz(@_st)
   // Nothing.
