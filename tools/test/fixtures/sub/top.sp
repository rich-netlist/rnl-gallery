* A subcircuit with a block symbol, and its use
* @RNL(type="header") { @USE-PACKAGE(name="rnl-std-all", version="0.4"); @VERSION("0.4") }
* @RNL { # @SELECT-PIN(recursive=true) => @REMOVE-FROM $LABEL_FILL_SET; $SUPPLY_NET_SET @REMOVE-FROM $PORT_FILL_SET; $GROUND_NET_SET @REMOVE-FROM $PORT_FILL_SET }
.subckt amp in out vdd vss
R1 in out 1k
R2 out vss 1k
C1 out vdd 1p
* @RNL {
*   %block_symbol = @DEFINE-SYMBOL(box=[-4, -3, 4, 3]) {
*     @RECTANGLE {(-4, -3) (4, 3)}
*   };
*   # @SET-SYMBOL %block_symbol
* }
.ends
X1 a b c d amp
Vdd c 0 1.8
