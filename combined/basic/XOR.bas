   10 rem copyright 1990 compute! publications inc. - all rights reserved
   11 rem back-prop xor demo / k.e. martin / gazette feb 1990
   12 rem needs bp.ml at $c000  (peek(49153)=24 and peek(49157)=196)
   13 rem sys 49152 fpe,spe,tpe,np,rate,momen,err
   14 rem sys 49167 pn,in$,teach$  - store training pair
   15 rem sys 49164 se - learn until te<=epsilon; se=1 prints te
   16 rem sys 49155 pat$ - recognize; layer-3 output in o3()
   20 print"{clr}{gry2}{swlc}":poke53280,0:poke53281,11
   30 if peek(49153)<>24 or peek(49157)<>196 then load"bp.ml",8,1
   35 rem fixed rnd seed so w1/w2 init matches a known run
   40 x=rnd(-33333)
   45 rem 2-2-1 net, 4 pairs, rate=.25 momentum=.9 err=.02
   50 sys 49152,2,2,1,4,0.25,0.9,0.02
   55 rem classic xor truth table as 0/1 strings
   60 sys 49167,1,"00","0"
   70 sys 49167,2,"10","1"
   80 sys 49167,3,"01","1"
   90 sys 49167,4,"11","0"
   95 rem learn; hold run/stop to break after the current trial
  100 print"Learning Patterns"
  110 print
  120 print"The total error is:"
  130 ti$="000000"
  140 sys 49164,1
  150 print"Time spent learning : ";ti$
  160 print"{down}Results:{down}"
  165 rem forward pass; int(o3(1)+.5) is the 0/1 decision
  170 sys49155,"00"
  180 print "0 xor 0 =";int(o3(1)+0.5);
  190 print " (";o3(1);")"
  200 sys49155,"10"
  210 print "1 xor 0 =";int(o3(1)+0.5);
  220 print " (";o3(1);")"
  230 sys49155,"01"
  240 print "0 xor 1 =";int(o3(1)+0.5);
  250 print " (";o3(1);")"
  260 sys49155,"11"
  270 print "1 xor 1 =";int(o3(1)+0.5);
  280 print " (";o3(1);")"
