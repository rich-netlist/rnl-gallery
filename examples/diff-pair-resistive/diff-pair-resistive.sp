* Resistively loaded NMOS differential pair with a current-source tail
* Two NMOS transistors with matched resistor loads and an ideal tail current source, driven by two input sources.
* @RNL(type="header") { @USE-PACKAGE(name="rnl-std-all", version="0.4"); @VERSION("0.4") }
.model nch nmos level=1 vto=0.5 kp=200u lambda=0.1
VDD vdd 0 DC 1.8
VIP inp 0 DC 0.9 AC 0.5
VIN inn 0 DC 0.9 AC 0.5 180
RD1 vdd outn 10k
RD2 vdd outp 10k
M1 outn inp tail 0 nch W=10u L=0.5u
M2 outp inn tail 0 nch W=10u L=0.5u
ITAIL tail 0 DC 100u
* @RNL {
*   &vdd @ADD-TO $SUPPLY_NET_SET;
*   $NET_LABEL @ATTACH &outn => %po_n;
*   $NET_LABEL @ATTACH &outp => %po_p;
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* the static currents (15.2), for the solver to draw them downwards; not criteria */
*   {#RD1:p #RD2:p #M1:d #M2:d #ITAIL:p} @CURRENT("in");
*   {#RD1:n #RD2:n #M1:s #M2:s #ITAIL:n} @CURRENT("out");
*
*   /* what the circuit is: an NMOS pair with matched resistor loads and an ideal tail current source */
*   %dp = #M1(left) #M2(right) #ITAIL(tail) @AS $DIFFERENTIAL_PAIR_N;
*   %rd = {#RD1 #RD2} @AS $MATCHED_RESISTOR;
*   %amp = %dp(transconductor) %rd(load) @AS $TRANSCONDUCTOR_Z_AMPLIFIER;
*   %flow = {%dp #RD1 #RD2}(path) {#VIP #VIN}(source) {&outn &outp}(load) @AS $SIGNAL_FLOW;
*
*   /* each side is a branch from the top down, the load resistor right above its transistor; the pair and the tail are
*      the pair's own */
*   %left_branch = {#RD1 #M1} @AS $BRANCH;
*   %right_branch = {#RD2 #M2} @AS $BRANCH;
*
*   /* from left to right the supply source, the input source, the two sides, the other input source */
*   %column_order = {#VDD #VIP %left_branch %right_branch #VIN} @ORDER("left-to-right");
*
*   /* the input sources are mirror images about the pair's axis, the output tags too */
*   %src_mirror = #VIP(left) #VIN(right) #ITAIL(axis) @AS $MIRRORED_LAYOUT;
*   %tag_mirror = %po_n(left) %po_p(right) #ITAIL(axis) @AS $MIRRORED_LAYOUT;
*
*   /* only the supply, the input source and the tail source are oriented */
*   %upright_parts = {#VDD #VIP #ITAIL} @ORIENT("R0")
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:85bf1f81000fa4af.07ad5fc0c2e52bf1", numbering="b61c569796575860") {
*   %ground_stub_VDD_n = $GROUND_STUB @ATTACH(gap=3) #VDD::n;
*   %ground_stub_VIP_n = $GROUND_STUB @ATTACH(gap=3) #VIP::n;
*   %ground_stub_VIN_n = $GROUND_STUB @ATTACH(gap=3) #VIN::n;
*   %ground_stub_ITAIL_n = $GROUND_STUB @ATTACH(gap=3) #ITAIL::n;
*   %supply_stub_VDD_p = $SUPPLY_STUB @ATTACH(gap=3) #VDD::p;
*   %supply_stub_RD1_p = $SUPPLY_STUB @ATTACH(gap=3) #RD1::p;
*   %supply_stub_RD2_p = $SUPPLY_STUB @ATTACH(gap=3) #RD2::p;
*   %rt1 = (15, 6);
*   %rt2 = (25, 6);
*   %rt3 = (20, -3);
*   #VDD @PLACE(-1, 11) => @ORIENT("R0");
*   #VIP @PLACE(0, -3) => @ORIENT("R0");
*   #VIN @PLACE(40, -3) => @ORIENT("MY");
*   #RD1 @PLACE(15, 11) => @ORIENT("R0");
*   #RD2 @PLACE(25, 11) => @ORIENT("MY");
*   #M1 @PLACE(15, 0) => @ORIENT("R0");
*   #M2 @PLACE(25, 0) => @ORIENT("MY");
*   #ITAIL @PLACE(20, -6) => @ORIENT("R0");
*   %po_n @PLACE(15, 6) => @ORIENT("R180");
*   %po_p @PLACE(25, 6) => @ORIENT("MX");
*   %dp @PLACE(20, 0);
*   %#1 @PLACE(0, 0);
*   %#2 @PLACE(20, 0);
*   %rd @PLACE(0, 0);
*   %#3 @PLACE(0, 0);
*   %amp @PLACE(0, 0);
*   %flow @PLACE(0, 0);
*   %left_branch @PLACE(15, 0);
*   %#4 @PLACE(0, 0);
*   %right_branch @PLACE(25, 0);
*   %#5 @PLACE(0, 0);
*   %src_mirror @PLACE(20, -3);
*   %tag_mirror @PLACE(20, 6);
*   %ground_stub_VDD_n @PLACE(0, 0);
*   %ground_stub_VDD_n::g @PLACE(-1, 7) => @ORIENT("R0");
*   %ground_stub_VIP_n @PLACE(0, 0);
*   %ground_stub_VIP_n::g @PLACE(0, -7) => @ORIENT("R0");
*   %ground_stub_VIN_n @PLACE(0, 0);
*   %ground_stub_VIN_n::g @PLACE(40, -7) => @ORIENT("R0");
*   %ground_stub_ITAIL_n @PLACE(0, 0);
*   %ground_stub_ITAIL_n::g @PLACE(20, -10) => @ORIENT("R0");
*   %supply_stub_VDD_p @PLACE(0, 0);
*   %supply_stub_VDD_p::s @PLACE(-1, 15) => @ORIENT("R0");
*   %supply_stub_RD1_p @PLACE(0, 0);
*   %supply_stub_RD1_p::s @PLACE(15, 15) => @ORIENT("R0");
*   %supply_stub_RD2_p @PLACE(0, 0);
*   %supply_stub_RD2_p::s @PLACE(25, 15) => @ORIENT("R0");
*   &inp @WIRE(mode="straight") {#VIP::p (0, 0) #M1::g};
*   &inn @WIRE(mode="straight") {#M2::g (40, 0) #VIN::p};
*   &outn @WIRE(mode="straight") {%rt1 #RD1::n};
*   &outn @WIRE(mode="straight") {#M1::d %rt1};
*   &outn @WIRE(mode="straight") {%rt1 %po_n::pin};
*   &outp @WIRE(mode="straight") {%rt2 #RD2::n};
*   &outp @WIRE(mode="straight") {#M2::d %rt2};
*   &outp @WIRE(mode="straight") {%rt2 %po_p::pin};
*   &tail @WIRE(mode="straight") {#M1::s (15, -3) %rt3};
*   &tail @WIRE(mode="straight") {%rt3 #ITAIL::p};
*   &tail @WIRE(mode="straight") {#M2::s (25, -3) %rt3};
*   $JUNCTION @ATTACH %rt1 => @PLACE(15, 6);
*   $JUNCTION @ATTACH %rt2 => @PLACE(25, 6);
*   $JUNCTION @ATTACH %rt3 => @PLACE(20, -3)
* }
.end
