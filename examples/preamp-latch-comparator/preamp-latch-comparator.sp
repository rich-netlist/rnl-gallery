* Comparator: two diode-loaded preamplifier stages and a StrongARM latch with its reset switches
* The two preamplifiers are NMOS pairs with diode-connected PMOS loads and a biased tail; the latch is clocked,
* with cross-coupled pairs and reset switches. The top level chains them and loads the outputs with capacitors.
* @RNL(type="header") { @USE-PACKAGE(name="rnl-std-all", version="0.4"); @USE-PACKAGE(name="rnl-std-no-instance-labels", version="0.4"); @USE-PACKAGE(name="rnl-std-semantics", version="0.4"); @VERSION("0.4")}
.model nch nmos level=1 vto=0.5 kp=200u lambda=0.1
.model pch pmos level=1 vto=-0.5 kp=80u lambda=0.1

* A fully differential preamplifier with diode loads: outp rises with inp - inn (gain about 2)
.subckt diff_preamp inp inn outp outn vdd vss vbias
M1 outn inp tail vss nch W=16u L=1u
M2 outp inn tail vss nch W=16u L=1u
M3 outn outn vdd vdd pch W=8u L=1u
M4 outp outp vdd vdd pch W=8u L=1u
M5 tail vbias vss vss nch W=8u L=1u
* @RNL {
*   &vdd @ADD-TO $SUPPLY_NET_SET;
*   &vss @ADD-TO $GROUND_NET_SET;
*   $IO_PORT @ATTACH &inp => %p_inp;
*   $IO_PORT @ATTACH &inn => %p_inn;
*   $IO_PORT @ATTACH &outp => %p_outp;
*   $IO_PORT @ATTACH &outn => %p_outn;
*   $IO_PORT @ATTACH &vbias => %p_vbias;
*
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* the static currents (15.2), for the solver to draw them downwards; not criteria */
*   {#M1:d #M2:d #M5:d #M3:s #M4:s} @CURRENT("in");
*   {#M1:s #M2:s #M5:s #M3:d #M4:d} @CURRENT("out");
*
*   /* what the circuit is: an NMOS pair with diode-connected PMOS loads and a biased tail; the ports are mirror images
*      about the tail */
*   %dp = #M1(left) #M2(right) #M5(tail) @AS $DIFFERENTIAL_PAIR_N;
*   %loads = {#M3 #M4} @AS $DIODE_CONNECTED;
*   %load = #M3(left) #M4(right) #M5(axis) @AS $MIRRORED_LAYOUT;
*   %matched_loads = {#M3 #M4} @AS $MATCHED_MOS;
*   %in_mirror = %p_inp(left) %p_inn(right) #M5(axis) @AS $MIRRORED_LAYOUT;
*   %out_mirror = %p_outn(left) %p_outp(right) #M5(axis) @AS $MIRRORED_LAYOUT;
*   %amp = %dp(transconductor) %load(load) @AS $TRANSCONDUCTOR_Z_AMPLIFIER;
*   %flow = {%amp}(path) {%p_inp %p_inn}(source) {%p_outn %p_outp}(load) @AS $SIGNAL_FLOW;
*
*   /* the two sides are branches from the top down: the diode load over the input transistor; the tail below the pair
*      is the pair's own */
*   %br_left = {#M3 #M1} @AS $BRANCH;
*   %br_right = {#M4 #M2} @AS $BRANCH;
*
*   /* the amplifier with its signal ports; the bias port stays outside */
*   %amp_group = %amp %p_inp %p_inn %p_outp %p_outn @GROUP;
*
*   /* the left ports face left, the right ports face right; the bias port is at the tail's gate */
*   %left_ports_orient = {%p_inp %p_outn %p_vbias} @ORIENT("left");
*   %right_ports_orient = {%p_inn %p_outp} @ORIENT("right");
*
*   /* the block symbol: a trapezoid with differential inputs/outputs and spaced bottom pins */
*   $PREAMP_SYM = @DEFINE-SYMBOL(box=[-5, -3, 5, 3]) {
*     (-5, 1) @PIN(terminal="inp", direction="left");
*     (-5, -1) @PIN(terminal="inn", direction="left");
*     (5, 1) @PIN(terminal="outp", direction="right");
*     (5, -1) @PIN(terminal="outn", direction="right");
*     (0, 3) @PIN(terminal="vdd", direction="up");
*     (2, -3) @PIN(terminal="vss", direction="down");
*     (-2, -3) @PIN(terminal="vbias", direction="down");
*     @LINE {(-4, 2.5) (4, 1.5) (4, -1.5) (-4, -2.5) (-4, 2.5)};
*     @LINE {(-5, 1) (-4, 1)};
*     @LINE {(-5, -1) (-4, -1)};
*     @LINE {(4, 1) (5, 1)};
*     @LINE {(4, -1) (5, -1)};
*     @LINE {(0, 2) (0, 3)};
*     @LINE {(2, -1.75) (2, -3)};
*     @LINE {(-2, -2.25) (-2, -3)};
*     @LINE {(-3.6, 1) (-2.8, 1)};
*     @LINE {(-3.2, 1.4) (-3.2, 0.6)};
*     @LINE {(-3.6, -1) (-2.8, -1)};
*     ? @TEXT("${name}", key="name") => @PLACE(0.8, 3.6)
*   };
*   # @SET-SYMBOL $PREAMP_SYM
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:ee1b59b00880997d.da88336667992d41", numbering="19e7479afe485497") {
*   %ground_stub_M5_s = $GROUND_STUB @ATTACH(gap=3) #M5::s;
*   %supply_stub_M3_s = $SUPPLY_STUB @ATTACH(gap=3) #M3::s;
*   %supply_stub_M4_s = $SUPPLY_STUB @ATTACH(gap=3) #M4::s;
*   %io_port_vdd = $IO_PORT @ATTACH &vdd;
*   %io_port_vss = $IO_PORT @ATTACH &vss;
*   %rt1 = (4, 5);
*   %rt2 = (4, 7);
*   %rt3 = (-4, 5);
*   %rt4 = (-4, 7);
*   %rt5 = (0, -3);
*   #M1 @PLACE(-4, 0) => @ORIENT("R0");
*   #M2 @PLACE(4, 0) => @ORIENT("MY");
*   #M3 @PLACE(-4, 10) => @ORIENT("MY");
*   #M4 @PLACE(4, 10) => @ORIENT("R0");
*   #M5 @PLACE(0, -6) => @ORIENT("R0");
*   %p_inp @PLACE(-11, 0) => @ORIENT("R0");
*   %p_inn @PLACE(11, 0) => @ORIENT("R180");
*   %p_outp @PLACE(5, 5) => @ORIENT("R180");
*   %p_outn @PLACE(-5, 5) => @ORIENT("R0");
*   %p_vbias @PLACE(-5, -6) => @ORIENT("R0");
*   %dp @PLACE(0, 0);
*   %#1 @PLACE(0, 0);
*   %#2 @PLACE(0, 0);
*   %#3 @PLACE(0, 0);
*   %#4 @PLACE(0, 0);
*   %load @PLACE(0, 10);
*   %matched_loads @PLACE(0, 0);
*   %#5 @PLACE(0, 0);
*   %in_mirror @PLACE(0, 0);
*   %out_mirror @PLACE(0, 5);
*   %amp @PLACE(0, 0);
*   %flow @PLACE(0, 0);
*   %br_left @PLACE(-4, 0);
*   %#6 @PLACE(0, 0);
*   %br_right @PLACE(4, 0);
*   %#7 @PLACE(0, 0);
*   %ground_stub_M5_s @PLACE(0, 0);
*   %ground_stub_M5_s::g @PLACE(0, -10) => @ORIENT("R0");
*   %supply_stub_M3_s @PLACE(0, 0);
*   %supply_stub_M3_s::s @PLACE(-4, 14) => @ORIENT("R0");
*   %supply_stub_M4_s @PLACE(0, 0);
*   %supply_stub_M4_s::s @PLACE(4, 14) => @ORIENT("R0");
*   %io_port_vdd @PLACE(-16, 10) => @ORIENT("R0");
*   %io_port_vss @PLACE(-16, 0) => @ORIENT("R0");
*   &inp @WIRE(mode="straight") {%p_inp::pin #M1::g};
*   &inn @WIRE(mode="straight") {#M2::g %p_inn::pin};
*   &outp @WIRE(mode="straight") {#M2::d %rt1};
*   &outp @WIRE(mode="straight") {%rt1 %p_outp::pin};
*   &outp @WIRE(mode="straight") {#M4::d %rt2};
*   &outp @WIRE(mode="straight") {%rt2 %rt1};
*   &outp @WIRE(mode="straight") {#M4::g (0, 10) (0, 7) %rt2};
*   &outn @WIRE(mode="straight") {%p_outn::pin %rt3};
*   &outn @WIRE(mode="straight") {%rt3 #M1::d};
*   &outn @WIRE(mode="straight") {#M3::d %rt4};
*   &outn @WIRE(mode="straight") {%rt4 %rt3};
*   &outn @WIRE(mode="straight") {#M3::g (-1, 7) %rt4};
*   &vbias @WIRE(mode="straight") {%p_vbias::pin #M5::g};
*   &tail @WIRE(mode="straight") {#M1::s (-4, -3) %rt5};
*   &tail @WIRE(mode="straight") {%rt5 #M5::d};
*   &tail @WIRE(mode="straight") {#M2::s (4, -3) %rt5};
*   $JUNCTION @ATTACH %rt1 => @PLACE(4, 5);
*   $JUNCTION @ATTACH %rt2 => @PLACE(4, 7);
*   $JUNCTION @ATTACH %rt3 => @PLACE(-4, 5);
*   $JUNCTION @ATTACH %rt4 => @PLACE(-4, 7);
*   $JUNCTION @ATTACH %rt5 => @PLACE(0, -3)
* }
.ends diff_preamp

* A StrongARM latch with the four reset switches: outp goes high when inp > inn as clk rises
.subckt latch inp inn outp outn clk vdd vss
M0 tail clk vss vss nch W=4u L=0.18u
M1 p inp tail vss nch W=4u L=0.18u
M2 q inn tail vss nch W=4u L=0.18u
M3 outn outp p vss nch W=2u L=0.18u
M4 outp outn q vss nch W=2u L=0.18u
M5 outn outp vdd vdd pch W=4u L=0.18u
M6 outp outn vdd vdd pch W=4u L=0.18u
MS1 outn clk vdd vdd pch W=2u L=0.18u
MS2 outp clk vdd vdd pch W=2u L=0.18u
MS3 p clk vdd vdd pch W=2u L=0.18u
MS4 q clk vdd vdd pch W=2u L=0.18u
* @RNL {
*   &vdd @ADD-TO $SUPPLY_NET_SET;
*   &vss @ADD-TO $GROUND_NET_SET;
*   $IO_PORT @ATTACH &inp => %p_inp;
*   $IO_PORT @ATTACH &inn => %p_inn;
*   $IO_PORT @ATTACH &outp => %p_outp;
*   $IO_PORT @ATTACH &outn => %p_outn;
*
*   /* the outputs are named at the drains of the PMOS latch; the clock uses net-label stubs */
*   &clk @UNROUTE-NET(priority="high");
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* the static currents (15.2) while the latch evaluates; not criteria */
*   {#M0:d #M1:d #M2:d #M3:d #M4:d #M5:s #M6:s} @CURRENT("in");
*   {#M0:s #M1:s #M2:s #M3:s #M4:s #M5:d #M6:d} @CURRENT("out");
*
*   /* what the circuit is: a clocked latch, an input pair with a clocked tail, an NMOS and a PMOS cross-coupled pair, and
*      reset switches on the outputs and on the internal nodes */
*   %dp = #M1(left) #M2(right) #M0(tail) @AS $DIFFERENTIAL_PAIR_N;
*   %cc_n = #M3(left) #M4(right) @AS $CROSS_COUPLED_PAIR;
*   %cc_p = #M5(left) #M6(right) @AS $CROSS_COUPLED_PAIR;
*   %tail_switch = #M0 @AS $GROUND_SWITCH;
*   %reset_switches = {#MS1 #MS2 #MS3 #MS4} @AS $RESET_SWITCH;
*   %power_switches = {#MS1 #MS2 #MS3 #MS4} @AS $POWER_SWITCH;
*   %latch_core = {%cc_n %cc_p %dp} @AS $LATCH;
*
*   /* one stack per side from the top down: the PMOS of the latch, the NMOS of the latch, the input transistor; the
*      clocked tail below the pair is the pair's own */
*   %br_left = {#M5 #M3 #M1} @AS $BRANCH;
*   %br_right = {#M6 #M4 #M2} @AS $BRANCH;
*
*   /* the reset switches, the input ports and the output ports are mirror images about the tail */
*   %rst_out_mirror = #MS1(left) #MS2(right) #M0(axis) @AS $MIRRORED_LAYOUT;
*   %rst_int_mirror = #MS3(left) #MS4(right) #M0(axis) @AS $MIRRORED_LAYOUT;
*   %in_mirror = %p_inp(left) %p_inn(right) #M0(axis) @AS $MIRRORED_LAYOUT;
*   %out_mirror = %p_outn(left) %p_outp(right) #M0(axis) @AS $MIRRORED_LAYOUT;
*
*   /* the left switch gates and ports face left, the right ones face right */
*   %rst_gate_left = {#MS1:g #MS3:g} @ORIENT("left");
*   %rst_gate_right = {#MS2:g #MS4:g} @ORIENT("right");
*   %left_ports_orient = {%p_inp %p_outn} @ORIENT("left");
*   %right_ports_orient = {%p_inn %p_outp} @ORIENT("right");
*
*   /* the block symbol: a box with a clock wedge at its clock pin */
*   $LATCH_SYM = @DEFINE-SYMBOL(box=[-5, -3, 5, 3]) {
*     (-5, 1) @PIN(terminal="inp", direction="left");
*     (-5, -1) @PIN(terminal="inn", direction="left");
*     (5, 1) @PIN(terminal="outp", direction="right");
*     (5, -1) @PIN(terminal="outn", direction="right");
*     (0, 3) @PIN(terminal="vdd", direction="up");
*     (2, -3) @PIN(terminal="vss", direction="down");
*     (-2, -3) @PIN(terminal="clk", direction="down");
*     @LINE {(-4, 2) (4, 2) (4, -2) (-4, -2) (-4, 2)};
*     @LINE {(-5, 1) (-4, 1)};
*     @LINE {(-5, -1) (-4, -1)};
*     @LINE {(4, 1) (5, 1)};
*     @LINE {(4, -1) (5, -1)};
*     @LINE {(0, 2) (0, 3)};
*     @LINE {(2, -2) (2, -3)};
*     @LINE {(-2, -2) (-2, -3)};
*     @LINE {(-2.6, -2) (-2, -1.4) (-1.4, -2)};
*     ? @TEXT("${name}", key="name") => @PLACE(0.8, 3.6)
*   };
*   # @SET-SYMBOL $LATCH_SYM
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:00158e493a08bdd7.9734220fcff11042", numbering="f464810c83b5d9a3") {
*   %ground_stub_M0_s = $GROUND_STUB @ATTACH(gap=3) #M0::s;
*   %supply_stub_M5_s = $SUPPLY_STUB @ATTACH(gap=3) #M5::s;
*   %supply_stub_M6_s = $SUPPLY_STUB @ATTACH(gap=3) #M6::s;
*   %supply_stub_MS1_s = $SUPPLY_STUB @ATTACH(gap=3) #MS1::s;
*   %supply_stub_MS2_s = $SUPPLY_STUB @ATTACH(gap=3) #MS2::s;
*   %supply_stub_MS3_s = $SUPPLY_STUB @ATTACH(gap=3) #MS3::s;
*   %supply_stub_MS4_s = $SUPPLY_STUB @ATTACH(gap=3) #MS4::s;
*   %net_label_stub_M0_g = $NET_LABEL_STUB @ATTACH #M0::g;
*   %net_label_stub_MS1_g = $NET_LABEL_STUB @ATTACH #MS1::g;
*   %net_label_stub_MS2_g = $NET_LABEL_STUB @ATTACH #MS2::g;
*   %net_label_stub_MS3_g = $NET_LABEL_STUB @ATTACH #MS3::g;
*   %net_label_stub_MS4_g = $NET_LABEL_STUB @ATTACH #MS4::g;
*   %io_port_clk = $IO_PORT @ATTACH &clk;
*   %io_port_vdd = $IO_PORT @ATTACH &vdd;
*   %io_port_vss = $IO_PORT @ATTACH &vss;
*   %rt1 = (4, 19);
*   %rt2 = (0, 19);
*   %rt3 = (4, 25);
*   %rt4 = (-4, 19);
*   %rt5 = (-4, 20);
*   %rt6 = (1, 20);
*   %rt7 = (-4, 25);
*   %rt8 = (0, 7);
*   %rt9 = (-4, 13);
*   %rt10 = (4, 13);
*   #M0 @PLACE(0, 4) => @ORIENT("R0");
*   #M1 @PLACE(-4, 10) => @ORIENT("R0");
*   #M2 @PLACE(4, 10) => @ORIENT("MY");
*   #M3 @PLACE(-4, 16) => @ORIENT("MY");
*   #M4 @PLACE(4, 16) => @ORIENT("R0");
*   #M5 @PLACE(-4, 28) => @ORIENT("MY");
*   #M6 @PLACE(4, 28) => @ORIENT("R0");
*   #MS1 @PLACE(-16, 28) => @ORIENT("R0");
*   #MS2 @PLACE(16, 28) => @ORIENT("MY");
*   #MS3 @PLACE(-16, 16) => @ORIENT("R0");
*   #MS4 @PLACE(16, 16) => @ORIENT("MY");
*   %p_inp @PLACE(-9, 10) => @ORIENT("R0");
*   %p_inn @PLACE(9, 10) => @ORIENT("R180");
*   %p_outp @PLACE(8, 19) => @ORIENT("R180");
*   %p_outn @PLACE(-8, 19) => @ORIENT("R0");
*   %dp @PLACE(0, 10);
*   %#1 @PLACE(0, 0);
*   %#2 @PLACE(0, 10);
*   %cc_n @PLACE(0, 16);
*   %#3 @PLACE(0, 0);
*   %#4 @PLACE(0, 16);
*   %cc_p @PLACE(0, 28);
*   %#5 @PLACE(0, 0);
*   %#6 @PLACE(0, 28);
*   %tail_switch @PLACE(0, 0);
*   %#7 @PLACE(0, 0);
*   %#8 @PLACE(0, 0);
*   %#9 @PLACE(0, 0);
*   %#10 @PLACE(0, 0);
*   %#11 @PLACE(0, 0);
*   %#12 @PLACE(0, 0);
*   %#13 @PLACE(0, 0);
*   %#14 @PLACE(0, 0);
*   %latch_core @PLACE(0, 0);
*   %br_left @PLACE(-4, 0);
*   %#15 @PLACE(0, 0);
*   %br_right @PLACE(4, 0);
*   %#16 @PLACE(0, 0);
*   %rst_out_mirror @PLACE(0, 28);
*   %rst_int_mirror @PLACE(0, 16);
*   %in_mirror @PLACE(0, 10);
*   %out_mirror @PLACE(0, 19);
*   %ground_stub_M0_s @PLACE(0, 0);
*   %ground_stub_M0_s::g @PLACE(0, 0) => @ORIENT("R0");
*   %supply_stub_M5_s @PLACE(0, 0);
*   %supply_stub_M5_s::s @PLACE(-4, 32) => @ORIENT("R0");
*   %supply_stub_M6_s @PLACE(0, 0);
*   %supply_stub_M6_s::s @PLACE(4, 32) => @ORIENT("R0");
*   %supply_stub_MS1_s @PLACE(0, 0);
*   %supply_stub_MS1_s::s @PLACE(-16, 32) => @ORIENT("R0");
*   %supply_stub_MS2_s @PLACE(0, 0);
*   %supply_stub_MS2_s::s @PLACE(16, 32) => @ORIENT("R0");
*   %supply_stub_MS3_s @PLACE(0, 0);
*   %supply_stub_MS3_s::s @PLACE(-16, 20) => @ORIENT("R0");
*   %supply_stub_MS4_s @PLACE(0, 0);
*   %supply_stub_MS4_s::s @PLACE(16, 20) => @ORIENT("R0");
*   %net_label_stub_M0_g @PLACE(0, 0);
*   %net_label_stub_M0_g::l @PLACE(-3, 4) => @ORIENT("R0");
*   %net_label_stub_MS1_g @PLACE(0, 0);
*   %net_label_stub_MS1_g::l @PLACE(-19, 28) => @ORIENT("R0");
*   %net_label_stub_MS2_g @PLACE(0, 0);
*   %net_label_stub_MS2_g::l @PLACE(19, 28) => @ORIENT("MY");
*   %net_label_stub_MS3_g @PLACE(0, 0);
*   %net_label_stub_MS3_g::l @PLACE(-19, 16) => @ORIENT("R0");
*   %net_label_stub_MS4_g @PLACE(0, 0);
*   %net_label_stub_MS4_g::l @PLACE(19, 16) => @ORIENT("MY");
*   %io_port_clk @PLACE(-22, -7) => @ORIENT("R0");
*   %io_port_vdd @PLACE(-22, -11) => @ORIENT("R0");
*   %io_port_vss @PLACE(-22, -15) => @ORIENT("R0");
*   %cc_n::axis @PLACE(0, 0);
*   %cc_p::axis @PLACE(0, 0);
*   &inp @WIRE(mode="straight") {%p_inp::pin #M1::g};
*   &inn @WIRE(mode="straight") {#M2::g %p_inn::pin};
*   &outp @WIRE(mode="straight") {#M4::d %rt1};
*   &outp @WIRE(mode="straight") {%rt1 %p_outp::pin};
*   &outp @WIRE(mode="straight") {#M3::g (0, 16) %rt2};
*   &outp @WIRE(mode="straight") {#M6::d %rt3};
*   &outp @WIRE(mode="straight") {%rt2 %rt1};
*   &outp @WIRE(mode="straight") {#M5::g (0, 28) %rt2};
*   &outp @WIRE(mode="straight") {%rt3 %rt1};
*   &outp @WIRE(mode="straight") {#MS2::d (16, 25) %rt3};
*   &outn @WIRE(mode="straight") {%p_outn::pin %rt4};
*   &outn @WIRE(mode="straight") {%rt4 #M3::d};
*   &outn @WIRE(mode="straight") {#M5::d %rt7};
*   &outn @WIRE(mode="straight") {%rt5 %rt4};
*   &outn @WIRE(mode="straight") {#M4::g %rt6};
*   &outn @WIRE(mode="straight") {%rt6 %rt5};
*   &outn @WIRE(mode="straight") {#M6::g %rt6};
*   &outn @WIRE(mode="straight") {%rt7 %rt5};
*   &outn @WIRE(mode="straight") {#MS1::d (-16, 25) %rt7};
*   &tail @WIRE(mode="straight") {#M1::s (-4, 7) %rt8};
*   &tail @WIRE(mode="straight") {%rt8 #M0::d};
*   &tail @WIRE(mode="straight") {#M2::s (4, 7) %rt8};
*   &p @WIRE(mode="straight") {#M1::d %rt9};
*   &p @WIRE(mode="straight") {%rt9 #M3::s};
*   &p @WIRE(mode="straight") {#MS3::d (-16, 13) %rt9};
*   &q @WIRE(mode="straight") {#M2::d %rt10};
*   &q @WIRE(mode="straight") {%rt10 #M4::s};
*   &q @WIRE(mode="straight") {#MS4::d (16, 13) %rt10};
*   $JUNCTION @ATTACH %rt1 => @PLACE(4, 19);
*   $JUNCTION @ATTACH %rt2 => @PLACE(0, 19);
*   $JUNCTION @ATTACH %rt3 => @PLACE(4, 25);
*   $JUNCTION @ATTACH %rt4 => @PLACE(-4, 19);
*   $JUNCTION @ATTACH %rt5 => @PLACE(-4, 20);
*   $JUNCTION @ATTACH %rt6 => @PLACE(1, 20);
*   $JUNCTION @ATTACH %rt7 => @PLACE(-4, 25);
*   $JUNCTION @ATTACH %rt8 => @PLACE(0, 7);
*   $JUNCTION @ATTACH %rt9 => @PLACE(-4, 13);
*   $JUNCTION @ATTACH %rt10 => @PLACE(4, 13)
* }
.ends latch

XPRE1 inp inn p1p p1n vdd 0 vb diff_preamp
XPRE2 p1p p1n p2p p2n vdd 0 vb diff_preamp
XL p2p p2n outp outn clk vdd 0 latch
CL1 outp 0 50f
CL2 outn 0 50f
VDD vdd 0 DC 1.8
VB vb 0 DC 0.7
VCLK clk 0 PULSE(0 1.8 0 50p 50p 0.45n 1n)
VIP inp 0 DC 0.905
VIN inn 0 DC 0.895
* @RNL {
*   &vdd @ADD-TO $SUPPLY_NET_SET;
*   &vb @ADD-TO $BIAS_NET_SET;
*   &clk @UNROUTE-NET(priority="high");
*
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* what the circuit is: two preamplifiers and the latch in a chain, driven by two sources, loaded by two capacitors */
*   %chain = {#XPRE1 #XPRE2 #XL} @AS $CASCADE;
*   %matched_load_caps = {#CL1 #CL2} @AS $MATCHED_CAPACITOR;
*   %flow = {#XPRE1 #XPRE2 #XL}(path) {#VIP #VIN}(source) {#CL1 #CL2}(load) @AS $SIGNAL_FLOW;
*
*   /* from left to right the input sources, the chain of two preamplifiers and the latch, the load capacitors */
*   %testbench_order = {{#VIP #VIN} #XPRE1 #XPRE2 #XL {#CL1 #CL2}} @ORDER("left-to-right");
*
*   /* the supply, bias and clock sources in one row below the chain, each under its stage; the supply source stands at
*      least 4 below the chain */
*   %source_row = {#VDD #VB #VCLK} @ALIGN("y");
*   %sources_below = {{#XPRE1 #XPRE2 #XL} {#VB #VCLK}} @ORDER("top-to-bottom");
*   %supply_distance = #VDD {#XPRE1 #XPRE2 #XL} @DISTANCE("bottom-to-top", min=4);
*   %vdd_align = {#VDD #XPRE1} @ALIGN("x");
*   %vb_align = {#VB #XPRE2} @ALIGN("x");
*   %vclk_align = {#VCLK #XL} @ALIGN("x");
*
*   /* only the sources, the loads and the stages are oriented */
*   %upright_parts = {#XPRE1 #XPRE2 #XL #VIP #VIN #CL1 #CL2 #VDD #VB #VCLK} @ORIENT("R0");
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:8cd10070778ac26e.473fdd1334e62618", numbering="1b1f934abea976ef") {
*   %ground_stub_XPRE1_vss = $GROUND_STUB @ATTACH(gap=3) #XPRE1:vss;
*   %ground_stub_XPRE2_vss = $GROUND_STUB @ATTACH(gap=3) #XPRE2:vss;
*   %ground_stub_XL_vss = $GROUND_STUB @ATTACH(gap=3) #XL:vss;
*   %ground_stub_CL1_n = $GROUND_STUB @ATTACH(gap=3) #CL1::n;
*   %ground_stub_CL2_n = $GROUND_STUB @ATTACH(gap=3) #CL2::n;
*   %ground_stub_VDD_n = $GROUND_STUB @ATTACH(gap=3) #VDD::n;
*   %ground_stub_VB_n = $GROUND_STUB @ATTACH(gap=3) #VB::n;
*   %ground_stub_VCLK_n = $GROUND_STUB @ATTACH(gap=3) #VCLK::n;
*   %ground_stub_VIP_n = $GROUND_STUB @ATTACH(gap=3) #VIP::n;
*   %ground_stub_VIN_n = $GROUND_STUB @ATTACH(gap=3) #VIN::n;
*   %supply_stub_XPRE1_vdd = $SUPPLY_STUB @ATTACH(gap=3) #XPRE1:vdd;
*   %supply_stub_XPRE2_vdd = $SUPPLY_STUB @ATTACH(gap=3) #XPRE2:vdd;
*   %supply_stub_XL_vdd = $SUPPLY_STUB @ATTACH(gap=3) #XL:vdd;
*   %supply_stub_VDD_p = $SUPPLY_STUB @ATTACH(gap=3) #VDD::p;
*   %bias_stub_XPRE1_vbias = $BIAS_STUB @ATTACH #XPRE1:vbias;
*   %bias_stub_XPRE2_vbias = $BIAS_STUB @ATTACH #XPRE2:vbias;
*   %bias_stub_VB_p = $BIAS_STUB @ATTACH #VB::p;
*   %net_label_stub_XL_clk = $NET_LABEL_STUB @ATTACH #XL:clk;
*   %net_label_stub_VCLK_p = $NET_LABEL_STUB @ATTACH #VCLK::p;
*   #XPRE1 @PLACE(14, 18) => @ORIENT("R0");
*   #XPRE2 @PLACE(26, 18) => @ORIENT("R0");
*   #XL @PLACE(38, 18) => @ORIENT("R0");
*   #CL1 @PLACE(52, 13) => @ORIENT("R0");
*   #CL2 @PLACE(47, 13) => @ORIENT("R0");
*   #VDD @PLACE(14, 2) => @ORIENT("R0");
*   #VB @PLACE(26, 2) => @ORIENT("R0");
*   #VCLK @PLACE(38, 2) => @ORIENT("R0");
*   #VIP @PLACE(-1, 13) => @ORIENT("R0");
*   #VIN @PLACE(5, 13) => @ORIENT("R0");
*   %chain @PLACE(14, 2);
*   %matched_load_caps @PLACE(14, 2);
*   %#1 @PLACE(14, 2);
*   %flow @PLACE(14, 2);
*   %ground_stub_XPRE1_vss @PLACE(14, 2);
*   %ground_stub_XPRE1_vss::g @PLACE(16, 13) => @ORIENT("R0");
*   %ground_stub_XPRE2_vss @PLACE(14, 2);
*   %ground_stub_XPRE2_vss::g @PLACE(28, 13) => @ORIENT("R0");
*   %ground_stub_XL_vss @PLACE(14, 2);
*   %ground_stub_XL_vss::g @PLACE(40, 13) => @ORIENT("R0");
*   %ground_stub_CL1_n @PLACE(14, 2);
*   %ground_stub_CL1_n::g @PLACE(52, 9) => @ORIENT("R0");
*   %ground_stub_CL2_n @PLACE(14, 2);
*   %ground_stub_CL2_n::g @PLACE(47, 9) => @ORIENT("R0");
*   %ground_stub_VDD_n @PLACE(14, 2);
*   %ground_stub_VDD_n::g @PLACE(14, -2) => @ORIENT("R0");
*   %ground_stub_VB_n @PLACE(14, 2);
*   %ground_stub_VB_n::g @PLACE(26, -2) => @ORIENT("R0");
*   %ground_stub_VCLK_n @PLACE(14, 2);
*   %ground_stub_VCLK_n::g @PLACE(38, -2) => @ORIENT("R0");
*   %ground_stub_VIP_n @PLACE(14, 2);
*   %ground_stub_VIP_n::g @PLACE(-1, 9) => @ORIENT("R0");
*   %ground_stub_VIN_n @PLACE(14, 2);
*   %ground_stub_VIN_n::g @PLACE(5, 9) => @ORIENT("R0");
*   %supply_stub_XPRE1_vdd @PLACE(14, 2);
*   %supply_stub_XPRE1_vdd::s @PLACE(14, 23) => @ORIENT("R0");
*   %supply_stub_XPRE2_vdd @PLACE(14, 2);
*   %supply_stub_XPRE2_vdd::s @PLACE(26, 23) => @ORIENT("R0");
*   %supply_stub_XL_vdd @PLACE(14, 2);
*   %supply_stub_XL_vdd::s @PLACE(38, 23) => @ORIENT("R0");
*   %supply_stub_VDD_p @PLACE(14, 2);
*   %supply_stub_VDD_p::s @PLACE(14, 6) => @ORIENT("R0");
*   %bias_stub_XPRE1_vbias @PLACE(14, 2);
*   %bias_stub_XPRE1_vbias::b @PLACE(12, 15) => @ORIENT("R180");
*   %bias_stub_XPRE2_vbias @PLACE(14, 2);
*   %bias_stub_XPRE2_vbias::b @PLACE(24, 15) => @ORIENT("R180");
*   %bias_stub_VB_p @PLACE(14, 2);
*   %bias_stub_VB_p::b @PLACE(26, 4) => @ORIENT("R0");
*   %net_label_stub_XL_clk @PLACE(14, 2);
*   %net_label_stub_XL_clk::l @PLACE(36, 15) => @ORIENT("R90");
*   %net_label_stub_VCLK_p @PLACE(14, 2);
*   %net_label_stub_VCLK_p::l @PLACE(38, 4) => @ORIENT("R270");
*   &inp @WIRE(mode="straight") {#VIP::p (-1, 19) #XPRE1:inp};
*   &inn @WIRE(mode="straight") {#VIN::p (5, 17) #XPRE1:inn};
*   &p1p @WIRE(mode="straight") {#XPRE1:outp #XPRE2:inp};
*   &p1n @WIRE(mode="straight") {#XPRE1:outn #XPRE2:inn};
*   &p2p @WIRE(mode="straight") {#XPRE2:outp #XL:inp};
*   &p2n @WIRE(mode="straight") {#XPRE2:outn #XL:inn};
*   &outp @WIRE(mode="straight") {#XL:outp (52, 19) #CL1::p};
*   &outn @WIRE(mode="straight") {#XL:outn (47, 17) #CL2::p}
* }
.end
