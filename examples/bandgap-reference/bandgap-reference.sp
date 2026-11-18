* CMOS bandgap reference: PTAT core with PNP diodes 1:8, an ideal op-amp, and an output branch
* The op-amp XEA holds X and Y equal, R1 sets a PTAT current from the 1:8 PNP pair Q1/Q2, three PMOS mirror it,
* and the output branch R2 + Q3 gives about 1.23 V at vbg.
* @RNL(type="header") { @USE-PACKAGE(name="rnl-std-all", version="0.4"); @VERSION("0.4") }
.model pch pmos level=1 vto=-0.5 kp=80u lambda=0.05
.model pnp1 pnp is=1e-16 bf=100

* An ideal op-amp: an open-loop gain of 1e5
.subckt opamp inp inn out
E1 out 0 inp inn 1e5
* @RNL {
*   $IO_PORT @ATTACH &inp => %p_inp;
*   $IO_PORT @ATTACH &inn => %p_inn;
*   $IO_PORT @ATTACH &out => %p_out;
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* what the circuit is: an amplifier E1 with the inputs on the left and the output on the right */
*   %flow_op = {#E1}(path) {&inp &inn}(source) {&out}(load) @AS $SIGNAL_FLOW;
*
*   /* the inputs on the left, + above -, the output on the right */
*   %port_order = {{%p_inp %p_inn} #E1 %p_out} @ORDER("left-to-right");
*   %input_order = {%p_inp %p_inn} @ORDER("top-to-bottom");
*   # @SET-SYMBOL(terminals=[[1, "inp"], [2, "inn"], [3, "out"]]) $OPAMP
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:1c9b1d871db7dfed.724f97e222e80040") {
*   %ground_stub_E1_n = $GROUND_STUB @ATTACH(gap=3) #E1::n;
*   #E1 @PLACE(11, 1) => @ORIENT("R0");
*   %p_inp @PLACE(1, 2) => @ORIENT("R0");
*   %p_inn @PLACE(5, 0) => @ORIENT("R0");
*   %p_out @PLACE(12, 6) => @ORIENT("MY");
*   %flow_op @PLACE(11, -3);
*   %ground_stub_E1_n @PLACE(11, -3);
*   %ground_stub_E1_n::g @PLACE(11, -3) => @ORIENT("R0");
*   &inp @WIRE(mode="straight") {%p_inp::pin #E1::cp};
*   &inn @WIRE(mode="straight") {%p_inn::pin #E1::cn};
*   &out @WIRE(mode="straight") {#E1::p (11, 6) %p_out::pin}
* }
.ends opamp

VDD vdd 0 DC 1.8
MP1 x vg vdd vdd pch W=8u L=1u
MP2 y vg vdd vdd pch W=8u L=1u
MP3 vbg vg vdd vdd pch W=8u L=1u
Q1 0 0 x pnp1 1
R1 y e2 5.4k
Q2 0 0 e2 pnp1 8
R2 vbg e3 57k
Q3 0 0 e3 pnp1 1
XEA y x vg opamp
* @RNL {
*   &vdd @ADD-TO $SUPPLY_NET_SET;
*   $NET_LABEL @ATTACH &vbg => %pvbg;
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* each PNP is a diode, base tied to collector, with one ground under the collector; the three stand in one row */
*   %w_q1 = &0 @WIRE(mode="vertical-horizontal") {#Q1:b #Q1:c};
*   %w_q2 = &0 @WIRE(mode="vertical-horizontal") {#Q2:b #Q2:c};
*   %w_q3 = &0 @WIRE(mode="vertical-horizontal") {#Q3:b #Q3:c};
*   %gq1 = $GROUND_STUB @ATTACH(gap=1) #Q1:c;
*   %gq2 = $GROUND_STUB @ATTACH(gap=1) #Q2:c;
*   %gq3 = $GROUND_STUB @ATTACH(gap=1) #Q3:c;
*   %pnp_row = {#Q1 #Q2 #Q3} @ALIGN("y");
*
*   /* the static currents (15.2), for the solver to draw them downwards; not criteria */
*   {#MP1:s #MP2:s #MP3:s #R1:p #R2:p #Q1:e #Q2:e #Q3:e} @CURRENT("in");
*   {#MP1:d #MP2:d #MP3:d #R1:n #R2:n #Q1:c #Q2:c #Q3:c} @CURRENT("out");
*
*   /* what the circuit is: the PMOS mirror MP1..MP3 forces equal voltages on the 1:8 PNP pair through the op-amp XEA;
*      R1 sets the PTAT current, and the output branch R2 + Q3 sums it with the diode voltage */
*   %cm = {#MP1}(ref) {#MP2 #MP3}(out) @AS $CURRENT_MIRROR_P;
*   %matched_pmos = {#MP1 #MP2 #MP3} @AS $MATCHED_MOS;
*   %matched = {#Q1 #Q2 #Q3} @AS $MATCHED_BJT;
*   %diode_pnps = {#Q1 #Q2 #Q3} @AS $DIODE_CONNECTED;
*   %bg = {#MP1 #MP2 #MP3 #Q1 #Q2 #Q3 #R1 #R2 #XEA} @AS $BIAS_CIRCUIT;
*
*   /* the three supply-to-ground paths, each a branch from the top down: MP1 over Q1 (X), MP2 over R1 over Q2 (Y),
*      MP3 over R2 over Q3 (output) */
*   %x_branch = {#MP1 #Q1} @AS $BRANCH;
*   %y_branch = {#MP2 #R1 #Q2} @AS $BRANCH;
*   %out_branch = {#MP3 #R2 #Q3} @AS $BRANCH;
*
*   /* from left to right X, the op-amp, Y, the output branch and the output tag; the supply source stands at least 4
*      to the left of X */
*   %column_order = {%x_branch #XEA %y_branch %out_branch %pvbg} @ORDER("left-to-right");
*   %supply_distance = #VDD %x_branch @DISTANCE("left-to-right", min=4);
*
*   /* the first two branches and the op-amp form the core */
*   %core_group = {%x_branch #XEA %y_branch} @GROUP;
*
*   /* the output of the op-amp XEA points up, towards the gates of the mirror */
*   %xea_output_up = #XEA:out @ORIENT("up");
*
*   /* the supply source is turned */
*   %supply_orient = {#VDD} @ORIENT("R0");
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:028662fe228b8f05.5a8ba1bea1a840fb", numbering="0c944fb883d19335") {
*   %ground_stub_VDD_n = $GROUND_STUB @ATTACH(gap=3) #VDD::n;
*   %supply_stub_VDD_p = $SUPPLY_STUB @ATTACH(gap=3) #VDD::p;
*   %supply_stub_MP1_s = $SUPPLY_STUB @ATTACH(gap=3) #MP1::s;
*   %supply_stub_MP2_s = $SUPPLY_STUB @ATTACH(gap=3) #MP2::s;
*   %supply_stub_MP3_s = $SUPPLY_STUB @ATTACH(gap=3) #MP3::s;
*   %rt1 = (15, 10);
*   %rt2 = (20, 20);
*   %rt3 = (20, 23);
*   %rt4 = (25, 10);
*   %rt5 = (33, 11);
*   #VDD @PLACE(8, 0) => @ORIENT("R0");
*   #MP1 @PLACE(15, 23) => @ORIENT("MY");
*   #MP2 @PLACE(25, 23) => @ORIENT("R0");
*   #MP3 @PLACE(33, 23) => @ORIENT("R0");
*   #Q1 @PLACE(15, 0) => @ORIENT("MY");
*   #R1 @PLACE(25, 6) => @ORIENT("R0");
*   #Q2 @PLACE(25, 0) => @ORIENT("MY");
*   #R2 @PLACE(33, 6) => @ORIENT("R0");
*   #Q3 @PLACE(33, 0) => @ORIENT("R0");
*   #XEA @PLACE(20, 15) => @ORIENT("MXR90");
*   %pvbg @PLACE(35, 11) => @ORIENT("MY");
*   %gq1 @PLACE(5.58, 23);
*   %gq1::g @PLACE(15, -3) => @ORIENT("R0");
*   %gq2 @PLACE(5.58, 23);
*   %gq2::g @PLACE(25, -3) => @ORIENT("R0");
*   %gq3 @PLACE(5.58, 23);
*   %gq3::g @PLACE(33, -3) => @ORIENT("R0");
*   %cm @PLACE(5.58, 23);
*   %matched_pmos @PLACE(5.58, 23);
*   %#4 @PLACE(5.58, 23);
*   %matched @PLACE(5.58, 23);
*   %#5 @PLACE(5.58, 23);
*   %#6 @PLACE(5.58, 23);
*   %#7 @PLACE(5.58, 23);
*   %#8 @PLACE(5.58, 23);
*   %bg @PLACE(5.58, 23);
*   %x_branch @PLACE(15, 4.21);
*   %#9 @PLACE(5.58, 23);
*   %y_branch @PLACE(25, 4);
*   %#10 @PLACE(5.58, 23);
*   %out_branch @PLACE(33, 4);
*   %#11 @PLACE(5.58, 23);
*   %ground_stub_VDD_n @PLACE(5.58, 23);
*   %ground_stub_VDD_n::g @PLACE(8, -4) => @ORIENT("R0");
*   %supply_stub_VDD_p @PLACE(5.58, 23);
*   %supply_stub_VDD_p::s @PLACE(8, 4) => @ORIENT("R0");
*   %supply_stub_MP1_s @PLACE(5.58, 23);
*   %supply_stub_MP1_s::s @PLACE(15, 27) => @ORIENT("R0");
*   %supply_stub_MP2_s @PLACE(5.58, 23);
*   %supply_stub_MP2_s::s @PLACE(25, 27) => @ORIENT("R0");
*   %supply_stub_MP3_s @PLACE(5.58, 23);
*   %supply_stub_MP3_s::s @PLACE(33, 27) => @ORIENT("R0");
*   &x @WIRE(mode="straight") {#Q1::e %rt1};
*   &x @WIRE(mode="straight") {%rt1 #MP1::d};
*   &x @WIRE(mode="straight") {%rt1 (19, 10) #XEA::inn};
*   &vg @WIRE(mode="straight") {#MP1::g %rt3};
*   &vg @WIRE(mode="straight") {#XEA::out %rt2};
*   &vg @WIRE(mode="straight") {%rt2 %rt3};
*   &vg @WIRE(mode="straight") {%rt2 (28, 20) (28, 23) #MP3::g};
*   &vg @WIRE(mode="straight") {%rt3 #MP2::g};
*   &y @WIRE(mode="straight") {#XEA::inp (21, 10) %rt4};
*   &y @WIRE(mode="straight") {#R1::p %rt4};
*   &y @WIRE(mode="straight") {%rt4 #MP2::d};
*   &vbg @WIRE(mode="straight") {#R2::p %rt5};
*   &vbg @WIRE(mode="straight") {%rt5 #MP3::d};
*   &vbg @WIRE(mode="straight") {%rt5 %pvbg::pin};
*   &e2 @WIRE(mode="straight") {#Q2::e #R1::n};
*   &e3 @WIRE(mode="straight") {#Q3::e #R2::n};
*   $JUNCTION @ATTACH %rt1 => @PLACE(15, 10);
*   $JUNCTION @ATTACH %rt2 => @PLACE(20, 20);
*   $JUNCTION @ATTACH %rt3 => @PLACE(20, 23);
*   $JUNCTION @ATTACH %rt4 => @PLACE(25, 10);
*   $JUNCTION @ATTACH %rt5 => @PLACE(33, 11);
*   $JUNCTION @ATTACH #Q1:c => @PLACE(15, -2);
*   $JUNCTION @ATTACH #Q2:c => @PLACE(25, -2);
*   $JUNCTION @ATTACH #Q3:c => @PLACE(33, -2)
* }
.end
