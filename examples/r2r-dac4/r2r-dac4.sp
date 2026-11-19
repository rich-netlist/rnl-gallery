* Four-bit R-2R ladder DAC, voltage mode, input code 1010
* The series resistors RS1..RS3 and the 2R legs to the four bit sources; the output is taken at the MSB end.
* @RNL(type="header") { @USE-PACKAGE(name="rnl-std-all", version="0.4"); @VERSION("0.4") }
VB0 b0 0 DC 0
VB1 b1 0 DC 1
VB2 b2 0 DC 0
VB3 b3 0 DC 1
RT n0 0 2k
R2B0 n0 b0 2k
R2B1 n1 b1 2k
R2B2 n2 b2 2k
R2B3 out b3 2k
RS1 n0 n1 1k
RS2 n1 n2 1k
RS3 n2 out 1k
* @RNL {
*   $NET_LABEL @ATTACH &out => %pout;
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* what the circuit is: R-2R ladder, the series resistors RS1..RS3 and the 2R legs R2B0..R2B3 to the bit sources, terminated by RT */
*   %matched_series = {#RS1 #RS2 #RS3} @AS $MATCHED_RESISTOR;
*   %matched_legs = {#RT #R2B0 #R2B1 #R2B2 #R2B3} @AS $MATCHED_RESISTOR;
*
*   /* the series resistors are one row, lying, from the LSB on the left to the MSB on the right */
*   %series_row = {#RS1 #RS2 #RS3} @AS $BRANCH_HORIZONTAL;
*
*   /* each leg is a branch from the top down, the 2R resistor and its bit source */
*   %leg0 = {#R2B0 #VB0} @AS $BRANCH;
*   %leg1 = {#R2B1 #VB1} @AS $BRANCH;
*   %leg2 = {#R2B2 #VB2} @AS $BRANCH;
*   %leg3 = {#R2B3 #VB3} @AS $BRANCH;
*
*   /* from the termination at the LSB end, through the legs, to the output at the MSB end */
*   %ladder_order = {#RT %leg0 %leg1 %leg2 %leg3 %pout} @ORDER("left-to-right");
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:e60088d00d58be81.c845985edb2878bc", numbering="4bbe8b8e75cbdfc5") {
*   %ground_stub_VB0_n = $GROUND_STUB @ATTACH(gap=3) #VB0::n;
*   %ground_stub_VB1_n = $GROUND_STUB @ATTACH(gap=3) #VB1::n;
*   %ground_stub_VB2_n = $GROUND_STUB @ATTACH(gap=3) #VB2::n;
*   %ground_stub_VB3_n = $GROUND_STUB @ATTACH(gap=3) #VB3::n;
*   %ground_stub_RT_n = $GROUND_STUB @ATTACH(gap=3) #RT::n;
*   %rt1 = (12, 11);
*   %rt2 = (20, 11);
*   %rt3 = (28, 11);
*   %rt4 = (36, 11);
*   #VB0 @PLACE(12, 0) => @ORIENT("MY");
*   #VB1 @PLACE(20, 0) => @ORIENT("MY");
*   #VB2 @PLACE(28, 0) => @ORIENT("R0");
*   #VB3 @PLACE(36, 0) => @ORIENT("R0");
*   #RT @PLACE(7, 6) => @ORIENT("R0");
*   #R2B0 @PLACE(12, 6) => @ORIENT("R0");
*   #R2B1 @PLACE(20, 6) => @ORIENT("R0");
*   #R2B2 @PLACE(28, 6) => @ORIENT("R0");
*   #R2B3 @PLACE(36, 6) => @ORIENT("R0");
*   #RS1 @PLACE(16, 11) => @ORIENT("R90");
*   #RS2 @PLACE(24, 11) => @ORIENT("R90");
*   #RS3 @PLACE(32, 11) => @ORIENT("R90");
*   %pout @PLACE(38, 11) => @ORIENT("MY");
*   %matched_series @PLACE(20, 4);
*   %#1 @PLACE(20, 4);
*   %matched_legs @PLACE(20, 4);
*   %#2 @PLACE(20, 4);
*   %series_row @PLACE(7, 11);
*   %#3 @PLACE(20, 4);
*   %leg0 @PLACE(12, 4);
*   %#4 @PLACE(20, 4);
*   %leg1 @PLACE(20, 4);
*   %#5 @PLACE(20, 4);
*   %leg2 @PLACE(28, 4);
*   %#6 @PLACE(20, 4);
*   %leg3 @PLACE(36, 4);
*   %#7 @PLACE(20, 4);
*   %ground_stub_VB0_n @PLACE(20, 4);
*   %ground_stub_VB0_n::g @PLACE(12, -4) => @ORIENT("R0");
*   %ground_stub_VB1_n @PLACE(20, 4);
*   %ground_stub_VB1_n::g @PLACE(20, -4) => @ORIENT("R0");
*   %ground_stub_VB2_n @PLACE(20, 4);
*   %ground_stub_VB2_n::g @PLACE(28, -4) => @ORIENT("R0");
*   %ground_stub_VB3_n @PLACE(20, 4);
*   %ground_stub_VB3_n::g @PLACE(36, -4) => @ORIENT("R0");
*   %ground_stub_RT_n @PLACE(20, 4);
*   %ground_stub_RT_n::g @PLACE(7, 2) => @ORIENT("R0");
*   &b0 @WIRE(mode="straight") {#VB0::p #R2B0::n};
*   &b1 @WIRE(mode="straight") {#VB1::p #R2B1::n};
*   &b2 @WIRE(mode="straight") {#VB2::p #R2B2::n};
*   &b3 @WIRE(mode="straight") {#VB3::p #R2B3::n};
*   &n0 @WIRE(mode="straight") {#RT::p (7, 11) %rt1};
*   &n0 @WIRE(mode="straight") {#R2B0::p %rt1};
*   &n0 @WIRE(mode="straight") {%rt1 #RS1::p};
*   &n1 @WIRE(mode="straight") {#RS1::n %rt2};
*   &n1 @WIRE(mode="straight") {#R2B1::p %rt2};
*   &n1 @WIRE(mode="straight") {%rt2 #RS2::p};
*   &n2 @WIRE(mode="straight") {#RS2::n %rt3};
*   &n2 @WIRE(mode="straight") {#R2B2::p %rt3};
*   &n2 @WIRE(mode="straight") {%rt3 #RS3::p};
*   &out @WIRE(mode="straight") {#RS3::n %rt4};
*   &out @WIRE(mode="straight") {#R2B3::p %rt4};
*   &out @WIRE(mode="straight") {%rt4 %pout::pin};
*   $JUNCTION @ATTACH %rt1 => @PLACE(12, 11);
*   $JUNCTION @ATTACH %rt2 => @PLACE(20, 11);
*   $JUNCTION @ATTACH %rt3 => @PLACE(28, 11);
*   $JUNCTION @ATTACH %rt4 => @PLACE(36, 11)
* }
.end
