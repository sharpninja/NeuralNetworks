   10 rem copyright 1990 compute! publications inc. - all rights reserved
   11 rem competitive-learning dipole / k.e. martin / gazette mar 1990
   12 rem needs cl.ml at $c000  (peek(49153)=24 and peek(49157)=194)
   13 rem sys 49152 p1,p2,np,rate   - init (no teacher)
   14 rem sys 49167 pn,pat$         - store input pattern
   15 rem sys 49164,1 - one pass; see errata for large counts
   16 rem sys 49155 pat$            - recognize; winner in o2()
   17 rem sys 49170 file$ / sys 49173 file$  save/load network
   20 print"{clr}{gry2}{swlc}":poke53280,0:poke53281,11
   30 if peek(49153)<>24 or peek(49157)<>194 then load"cl.ml",8,1
   35 rem fixed rnd seed so w1 init is repeatable
   40 x=rnd(-33333)
   45 rem 16 inputs (4x4 grid), 2 outputs, 24 dipoles, rate=.1
   50 print"Initializing"
   60 sys 49152,16,2,24,0.1
   65 rem sum w1(k,1..16) is approx 1; winner learns the input
   70 print"Loading patterns"
   75 rem patterns 1-12: adjacent horizontal dipoles on the grid
   80 sys 49167,1,"1100000000000000"
   90 sys 49167,2,"0110000000000000"
  100 sys 49167,3,"0011000000000000"
  110 sys 49167,4,"0000110000000000"
  120 sys 49167,5,"0000011000000000"
  130 sys 49167,6,"0000001100000000"
  140 sys 49167,7,"0000000011000000"
  150 sys 49167,8,"0000000001100000"
  160 sys 49167,9,"0000000000110000"
  170 sys 49167,10,"0000000000001100"
  180 sys 49167,11,"0000000000000110"
  190 sys 49167,12,"0000000000000011"
  195 rem patterns 13-24: adjacent vertical dipoles on the grid
  200 sys 49167,13,"1000100000000000"
  210 sys 49167,14,"0100010000000000"
  220 sys 49167,15,"0010001000000000"
  230 sys 49167,16,"0001000100000000"
  240 sys 49167,17,"0000100010000000"
  250 sys 49167,18,"0000010001000000"
  260 sys 49167,19,"0000001000100000"
  270 sys 49167,20,"0000000100010000"
  280 sys 49167,21,"0000000010001000"
  290 sys 49167,22,"0000000001000100"
  300 sys 49167,23,"0000000000100010"
  310 sys 49167,24,"0000000000010001"
  315 rem 400 passes; article reports over 60 minutes total
  320 print"{clr}"
  325 rem print w1 rows scaled by 1000000; sum approx 1000000
  330 for i=1 to 400
  340 sys 49164,1
  350 t=0
  360 print"{home}"
  370 for j= 1 to 16
  380 a=int(w1(1,j)*1000000)
  390 t=t+a
  400 if a < 10 then print" ";
  410 if a < 100 then print" ";
  420 if a < 1000 then print" ";
  430 if a < 10000 then print" ";
  440 if a < 100000 then print" ";
  450 print a,
  460 next j
  470 print:print t
  480 print
  490 t=0
  500 for j= 1 to 16
  510 a=int(w1(2,j)*1000000)
  520 t=t+a
  530 if a < 10 then print" ";
  540 if a < 100 then print" ";
  550 if a < 1000 then print" ";
  560 if a < 10000 then print" ";
  570 if a < 100000 then print" ";
  580 print a,
  590 next j
  600 print:print t
  610 next i
  620 end
