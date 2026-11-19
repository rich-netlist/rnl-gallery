* Fully differential flip-around sample-and-hold with bottom-plate sampling
* In the sampling phase each input is stored on its capacitor, the bottom-plate switch opening first; in the hold
* phase the capacitors flip around to the outputs of the ideal fully differential amplifier fdamp. The two halves
* are mirror images about a horizontal axis.
* @RNL(type="header") { @USE-PACKAGE(name="rnl-std-all", version="0.4"); @VERSION("0.4") }
.model nch nmos level=1 vto=0.5 kp=200u lambda=0.05

* An ideal fully differential amplifier: outp - outn = 1e4 (inp - inn), output common mode 0.9 V
.subckt fdamp inp inn outp outn
EP outp cm inp inn 5000
EN outn cm inn inp 5000
VOCM cm 0 DC 0.9
* @RNL {
*   $IO_PORT @ATTACH &inp => %p_inp;
*   $IO_PORT @ATTACH &inn => %p_inn;
*   $IO_PORT @ATTACH &outp => %p_outp;
*   $IO_PORT @ATTACH &outn => %p_outn;
*   %routed_nets = # @SELECT-NET;
*   {$GROUND_NET_SET $SUPPLY_NET_SET $BIAS_NET_SET} @REMOVE-FROM %routed_nets;
*   %routed_nets @ROUTE-NET;
*
*   /* what the circuit is: the fully differential amplifier, its common-mode reference VOCM, and the two signal ports */
*   %bias_cm = {#VOCM} @AS $BIAS_CIRCUIT;
*   %flow_amp = {#EP #EN}(path) {&inp &inn}(source) {&outp &outn}(load) @AS $SIGNAL_FLOW;
*
*   /* the two halves are mirror images about a horizontal axis, EP above and EN below, the common-mode source on the
*      axis to the right */
*   %half_mirror = #EP(top) #EN(bottom) #VOCM(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %p_in = %p_inp(top) %p_inn(bottom) #VOCM(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %p_out = %p_outp(top) %p_outn(bottom) #VOCM(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*
*   /* the input ports on the left, then the amplifier, the common-mode source, the output ports on the right */
*   %port_order = {%p_in %half_mirror #VOCM %p_out} @ORDER("left-to-right");
*
*   /* the common-mode source's pin 1 faces left, to the amplifier */
*   %vocm_pin_orient = #VOCM:1 @ORIENT("left");
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:741cb732473b6df4.f6af5a8de882caf7", numbering="5eed9a9fbb9f16ca") {
*   %ground_stub_VOCM_n = $GROUND_STUB @ATTACH(gap=3) #VOCM::n;
*   %rt1 = (3, 17);
*   %rt2 = (2, 1);
*   %rt3 = (8, 9);
*   #EP @PLACE(8, 16) => @ORIENT("R0");
*   #EN @PLACE(8, 2) => @ORIENT("MX");
*   #VOCM @PLACE(12, 9) => @ORIENT("R90");
*   %p_inp @PLACE(0, 17) => @ORIENT("R0");
*   %p_inn @PLACE(0, 1) => @ORIENT("MX");
*   %p_outp @PLACE(16, 19) => @ORIENT("MY");
*   %p_outn @PLACE(16, -1) => @ORIENT("R180");
*   %bias_cm @PLACE(8, 9);
*   %flow_amp @PLACE(8, 9);
*   %half_mirror @PLACE(8, 9);
*   %p_in @PLACE(0, 9);
*   %p_out @PLACE(16, 9);
*   %ground_stub_VOCM_n @PLACE(8, 9);
*   %ground_stub_VOCM_n::g @PLACE(16, 7) => @ORIENT("R0");
*   &inp @WIRE(mode="straight") {%p_inp::pin %rt1};
*   &inp @WIRE(mode="straight") {%rt1 (3, 3) #EN::cn};
*   &inp @WIRE(mode="straight") {%rt1 #EP::cp};
*   &inn @WIRE(mode="straight") {%p_inn::pin %rt2};
*   &inn @WIRE(mode="straight") {%rt2 (2, 15) #EP::cn};
*   &inn @WIRE(mode="straight") {%rt2 #EN::cp};
*   &outp @WIRE(mode="straight") {#EP::p (8, 19) %p_outp::pin};
*   &outn @WIRE(mode="straight") {#EN::p (8, -1) %p_outn::pin};
*   &cm @WIRE(mode="straight") {#EN::n %rt3};
*   &cm @WIRE(mode="straight") {%rt3 #EP::n};
*   &cm @WIRE(mode="straight") {%rt3 #VOCM::p};
*   %#1 @WIRE(mode="straight") {#VOCM::n (16, 9) %ground_stub_VOCM_n::g::pin};
*   $JUNCTION @ATTACH %rt1 => @PLACE(3, 17);
*   $JUNCTION @ATTACH %rt2 => @PLACE(2, 1);
*   $JUNCTION @ATTACH %rt3 => @PLACE(8, 9)
* }
.ends fdamp

VCM vcm 0 DC 0.9
VIP inp vcm SIN(0 0.2 50k)
VIN inn vcm SIN(0 -0.2 50k)
VP1 phi1 0 PULSE(0 1.8 0 1n 1n 0.45u 1u)
VP1E phi1e 0 PULSE(0 1.8 0 1n 1n 0.4u 1u)
VP2 phi2 0 PULSE(0 1.8 0.5u 1n 1n 0.45u 1u)
MS1 ap phi1 inp 0 nch W=10u L=0.18u
MS2 bn phi1 inn 0 nch W=10u L=0.18u
CS1 ap xa 1p
CS2 bn xb 1p
MS3 xa phi1e vcm 0 nch W=10u L=0.18u
MS4 xb phi1e vcm 0 nch W=10u L=0.18u
MS5 outp phi2 ap 0 nch W=10u L=0.18u
MS6 outn phi2 bn 0 nch W=10u L=0.18u
XOA xb xa outp outn fdamp
CLD outp outn 0.5p
* @RNL {
*   #XOA @SET-SYMBOL $DIFFERENTIAL_OPAMP_TWISTED;
*   # @SELECT-INSTANCE(model="nch") => @TEXT("", key="model");
*
*   /* vcm is in $BIAS_NET_SET so the bottom-plate switches get bias stubs, and the clocks are
*      unrouted so they get net-label stubs; the three sources are wired to each other on vcm, at
*      high so that the fill's unrouting of vcm does not take them */
*   &vcm @ADD-TO $BIAS_NET_SET;
*   {&phi1 &phi1e &phi2} @UNROUTE-NET(priority="high");
*   %routed_nets = # @SELECT-NET;
*   %routed_nets @ROUTE-NET;
*
*   /* what the circuit is: the pass and reset switches with their matching, the two samplers, the flip-around loop */
*   %pass_switches = {#MS1 #MS2 #MS5 #MS6} @AS $PASS_SWITCH;
*   %reset_switches = {#MS3 #MS4} @AS $RESET_SWITCH;
*   %matched_caps = {#CS1 #CS2} @AS $MATCHED_CAPACITOR;
*   %matched_input_switches = {#MS1 #MS2} @AS $MATCHED_MOS;
*   %matched_reset_switches = {#MS3 #MS4} @AS $MATCHED_MOS;
*   %matched_flip_switches = {#MS5 #MS6} @AS $MATCHED_MOS;
*   %samp_p = {#MS1 #MS3}(switch) {#CS1}(capacitor) @AS $SC_SAMPLER;
*   %samp_n = {#MS2 #MS4}(switch) {#CS2}(capacitor) @AS $SC_SAMPLER;
*   %loop = {#XOA}(forward) {#CS1 #CS2 #MS5 #MS6}(feedback) @AS $FEEDBACK_LOOP;
*   %flow = {#MS1 #MS2 #CS1 #CS2 #XOA}(path) {#VIP #VIN}(source) {#CLD}(load) @AS $SIGNAL_FLOW;
*
*   /* the flip-around switches lie with their sources on the left; the mirrors give the lower half */
*   %flip_source_orient = {#MS5:s #MS6:s} @ORIENT("left");
*
*   /* the two halves are mirror images about one horizontal axis, the amplifier and the load on it */
*   %src_mirror = #VIP(top) #VIN(bottom) #XOA(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %in_mirror = #MS1(top) #MS2(bottom) #XOA(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %cap_mirror = #CS1(top) #CS2(bottom) #XOA(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %bp_mirror = #MS3(top) #MS4(bottom) #XOA(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %fb_mirror = #MS5(top) #MS6(bottom) #XOA(axis) @AS $MIRRORED_VERTICAL_LAYOUT;
*   %center_row = {#XOA #CLD} @ALIGN("y");
*
*   /* from left to right: the sources, the input switches, the sampling capacitors, the bottom-plate switches, the
*      amplifier and the load; the flip-around switches stand over the amplifier */
*   %column_order = {%src_mirror %in_mirror %cap_mirror %bp_mirror #XOA #CLD} @ORDER("left-to-right");
*   %flip_over_amp = {#XOA %fb_mirror} @ALIGN("x");
*
*   /* the sampling circuit, with the sources, is one block */
*   %sampling_group = {#MS1 #MS2 #CS1 #CS2 #MS3 #MS4 #XOA #CLD #MS5 #MS6 #VIP #VIN} @GROUP;
*
*   /* the sources and the load stand upright; the amplifier is flipped about the x axis */
*   %upright_parts = {#VIP #VCM #VP1 #VP1E #VP2 #CLD} @ORIENT("R0");
*   %amp_orient = #XOA @ORIENT("MX");
*
*   /* the common-mode and clock sources in one row, in the order phi1, phi1e, phi2, at least 4 below the flip-around
*      switch MS6 */
*   %clock_row = {#VCM #VP1 #VP1E #VP2} @ALIGN("y") => @GROUP;
*   %clock_order = {#VCM #VP1 #VP1E #VP2} @ORDER("left-to-right");
*   %clock_distance = {{#VCM #VP1 #VP1E #VP2} #MS6} @DISTANCE("bottom-to-top", min=4);
* }
* @RNL(type="generated", priority="high", author="rnl-solver 0.1", hash="sig2:c69e7956345a50fd.8da8d1f8b394fc2d", numbering="eae47c81e94910b8") {
*   %ground_stub_VCM_n = $GROUND_STUB @ATTACH(gap=3) #VCM::n;
*   %ground_stub_VP1_n = $GROUND_STUB @ATTACH(gap=3) #VP1::n;
*   %ground_stub_VP1E_n = $GROUND_STUB @ATTACH(gap=3) #VP1E::n;
*   %ground_stub_VP2_n = $GROUND_STUB @ATTACH(gap=3) #VP2::n;
*   %bias_stub_VCM_p = $BIAS_STUB @ATTACH #VCM::p;
*   %bias_stub_VIP_n = $BIAS_STUB @ATTACH #VIP::n;
*   %bias_stub_VIN_n = $BIAS_STUB @ATTACH #VIN::n;
*   %bias_stub_MS3_s = $BIAS_STUB @ATTACH #MS3::s;
*   %bias_stub_MS4_s = $BIAS_STUB @ATTACH #MS4::s;
*   %net_label_stub_VP1_p = $NET_LABEL_STUB @ATTACH #VP1::p;
*   %net_label_stub_MS1_g = $NET_LABEL_STUB @ATTACH #MS1::g;
*   %net_label_stub_MS2_g = $NET_LABEL_STUB @ATTACH #MS2::g;
*   %net_label_stub_VP1E_p = $NET_LABEL_STUB @ATTACH #VP1E::p;
*   %net_label_stub_MS3_g = $NET_LABEL_STUB @ATTACH #MS3::g;
*   %net_label_stub_MS4_g = $NET_LABEL_STUB @ATTACH #MS4::g;
*   %net_label_stub_VP2_p = $NET_LABEL_STUB @ATTACH #VP2::p;
*   %net_label_stub_MS5_g = $NET_LABEL_STUB @ATTACH #MS5::g;
*   %net_label_stub_MS6_g = $NET_LABEL_STUB @ATTACH #MS6::g;
*   %rt1 = (25, 42);
*   %rt2 = (25, 13);
*   %rt3 = (31, 37);
*   %rt4 = (31, 18);
*   %rt5 = (48, 42);
*   %rt6 = (48, 13);
*   #VCM @PLACE(10, 5) => @ORIENT("R0");
*   #VIP @PLACE(18, 34) => @ORIENT("R0");
*   #VIN @PLACE(18, 21) => @ORIENT("MX");
*   #VP1 @PLACE(18, 5) => @ORIENT("R0");
*   #VP1E @PLACE(51, 5) => @ORIENT("R0");
*   #VP2 @PLACE(69, 5) => @ORIENT("R0");
*   #MS1 @PLACE(21, 42) => @ORIENT("MXR90");
*   #MS2 @PLACE(21, 13) => @ORIENT("R270");
*   #CS1 @PLACE(28, 37) => @ORIENT("R90");
*   #CS2 @PLACE(28, 18) => @ORIENT("MYR90");
*   #MS3 @PLACE(35, 37) => @ORIENT("R90");
*   #MS4 @PLACE(35, 18) => @ORIENT("MYR90");
*   #MS5 @PLACE(44, 42) => @ORIENT("MXR90");
*   #MS6 @PLACE(44, 13) => @ORIENT("R270");
*   #XOA @PLACE(44, 27.5) => @ORIENT("MX");
*   #CLD @PLACE(51, 27.5) => @ORIENT("R0");
*   %#1 @PLACE(21, 8);
*   %#2 @PLACE(21, 8);
*   %#3 @PLACE(21, 8);
*   %#4 @PLACE(21, 8);
*   %#5 @PLACE(21, 8);
*   %#6 @PLACE(21, 8);
*   %matched_caps @PLACE(21, 8);
*   %#7 @PLACE(21, 8);
*   %matched_input_switches @PLACE(21, 8);
*   %#8 @PLACE(21, 8);
*   %matched_reset_switches @PLACE(21, 8);
*   %#9 @PLACE(21, 8);
*   %matched_flip_switches @PLACE(21, 8);
*   %#10 @PLACE(21, 8);
*   %samp_p @PLACE(21, 8);
*   %samp_n @PLACE(21, 8);
*   %loop @PLACE(21, 8);
*   %flow @PLACE(21, 8);
*   %src_mirror @PLACE(18, 27.5);
*   %in_mirror @PLACE(21, 27.5);
*   %cap_mirror @PLACE(28, 27.5);
*   %bp_mirror @PLACE(35, 27.5);
*   %fb_mirror @PLACE(44, 27.5);
*   %ground_stub_VCM_n @PLACE(21, 8);
*   %ground_stub_VCM_n::g @PLACE(10, 1) => @ORIENT("R0");
*   %ground_stub_VP1_n @PLACE(21, 8);
*   %ground_stub_VP1_n::g @PLACE(18, 1) => @ORIENT("R0");
*   %ground_stub_VP1E_n @PLACE(21, 8);
*   %ground_stub_VP1E_n::g @PLACE(51, 1) => @ORIENT("R0");
*   %ground_stub_VP2_n @PLACE(21, 8);
*   %ground_stub_VP2_n::g @PLACE(69, 1) => @ORIENT("R0");
*   %bias_stub_VCM_p @PLACE(21, 8);
*   %bias_stub_VCM_p::b @PLACE(10, 7) => @ORIENT("R0");
*   %bias_stub_VIP_n @PLACE(21, 8);
*   %bias_stub_VIP_n::b @PLACE(18, 32) => @ORIENT("R180");
*   %bias_stub_VIN_n @PLACE(21, 8);
*   %bias_stub_VIN_n::b @PLACE(18, 23) => @ORIENT("R0");
*   %bias_stub_MS3_s @PLACE(21, 8);
*   %bias_stub_MS3_s::b @PLACE(37, 37) => @ORIENT("R270");
*   %bias_stub_MS4_s @PLACE(21, 8);
*   %bias_stub_MS4_s::b @PLACE(37, 18) => @ORIENT("R270");
*   %net_label_stub_VP1_p @PLACE(21, 8);
*   %net_label_stub_VP1_p::l @PLACE(18, 7) => @ORIENT("R270");
*   %net_label_stub_MS1_g @PLACE(21, 8);
*   %net_label_stub_MS1_g::l @PLACE(21, 39) => @ORIENT("R90");
*   %net_label_stub_MS2_g @PLACE(21, 8);
*   %net_label_stub_MS2_g::l @PLACE(21, 16) => @ORIENT("R270");
*   %net_label_stub_VP1E_p @PLACE(21, 8);
*   %net_label_stub_VP1E_p::l @PLACE(51, 7) => @ORIENT("R270");
*   %net_label_stub_MS3_g @PLACE(21, 8);
*   %net_label_stub_MS3_g::l @PLACE(35, 34) => @ORIENT("R90");
*   %net_label_stub_MS4_g @PLACE(21, 8);
*   %net_label_stub_MS4_g::l @PLACE(35, 21) => @ORIENT("R270");
*   %net_label_stub_VP2_p @PLACE(21, 8);
*   %net_label_stub_VP2_p::l @PLACE(69, 7) => @ORIENT("R270");
*   %net_label_stub_MS5_g @PLACE(21, 8);
*   %net_label_stub_MS5_g::l @PLACE(44, 39) => @ORIENT("R90");
*   %net_label_stub_MS6_g @PLACE(21, 8);
*   %net_label_stub_MS6_g::l @PLACE(44, 16) => @ORIENT("R270");
*   &inp @WIRE(mode="straight") {#VIP::p (18, 42) #MS1::s};
*   &inn @WIRE(mode="straight") {#VIN::p (18, 13) #MS2::s};
*   &ap @WIRE(mode="straight") {#MS1::d %rt1};
*   &ap @WIRE(mode="straight") {%rt1 (25, 37) #CS1::p};
*   &ap @WIRE(mode="straight") {%rt1 #MS5::s};
*   &bn @WIRE(mode="straight") {#MS2::d %rt2};
*   &bn @WIRE(mode="straight") {%rt2 (25, 18) #CS2::p};
*   &bn @WIRE(mode="straight") {%rt2 #MS6::s};
*   &xa @WIRE(mode="straight") {#CS1::n %rt3};
*   &xa @WIRE(mode="straight") {%rt3 (31, 28.5) #XOA::inn};
*   &xa @WIRE(mode="straight") {%rt3 #MS3::d};
*   &xb @WIRE(mode="straight") {#CS2::n %rt4};
*   &xb @WIRE(mode="straight") {%rt4 (31, 26.5) #XOA::inp};
*   &xb @WIRE(mode="straight") {%rt4 #MS4::d};
*   &outp @WIRE(mode="straight") {#MS5::d %rt5};
*   &outp @WIRE(mode="straight") {#XOA::outp (48, 28.5) %rt5};
*   &outp @WIRE(mode="straight") {%rt5 (51, 42) #CLD::p};
*   &outn @WIRE(mode="straight") {#MS6::d %rt6};
*   &outn @WIRE(mode="straight") {#XOA::outn (48, 26.5) %rt6};
*   &outn @WIRE(mode="straight") {%rt6 (51, 13) #CLD::n};
*   $JUNCTION @ATTACH %rt1 => @PLACE(25, 42);
*   $JUNCTION @ATTACH %rt2 => @PLACE(25, 13);
*   $JUNCTION @ATTACH %rt3 => @PLACE(31, 37);
*   $JUNCTION @ATTACH %rt4 => @PLACE(31, 18);
*   $JUNCTION @ATTACH %rt5 => @PLACE(48, 42);
*   $JUNCTION @ATTACH %rt6 => @PLACE(48, 13)
* }
.end
