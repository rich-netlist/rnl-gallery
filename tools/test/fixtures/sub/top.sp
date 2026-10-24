* A subcircuit with a block symbol, and its use
* @RNL(type="header") { @VERSION("0.3") }
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
