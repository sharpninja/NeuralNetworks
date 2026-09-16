   10 rem copyright 1990 compute! publications inc. - all rights reserved
   11 rem back-prop encode demo / k.e. martin / gazette feb 1990
   12 rem needs bp.ml at $c000  (peek(49153)=24 and peek(49157)=196)
   13 rem sys 49152 fpe,spe,tpe,np,rate,momen,err
   14 rem sys 49167 pn,in$,teach$  - store training pair
   15 rem sys 49164 se - learn until te<=epsilon; se=1 prints te
   16 rem sys 49155 pat$ - recognize; o2=hidden, o3=output
   20 print"{clr}{gry2}{swlc}":poke53280,0:poke53281,11
   30 if peek(49153)<>24 or peek(49157)<>196 then load"bp.ml",8,1
   35 rem fixed rnd seed so weight init is repeatable
   40 x=rnd(-11111)
   45 rem 4-2-4 net, 4 pairs, rate=.25 momentum=.9 err=.02
   50 sys 49152,4,2,4,4,0.25,0.9,0.02
   55 rem 4-bit one-hot encode; hidden layer must store 4 patterns
   60 sys 49167,1,"1000","0010"
   70 sys 49167,2,"0100","0001"
   80 sys 49167,3,"0010","1000"
   90 sys 49167,4,"0001","0100"
   95 rem article reports 27 min 49 sec for this training run
  100 print"Learning Patterns"
  110 print
  120 print"The total error is:"
  130 ti$="000000"
  140 sys 49164,1
  150 print"Time spent learning : ";ti$:print:print"Results:"
  160 print"   Layer      Layer       Layer"
  170 print"    One        Two        Three"
  175 rem print layer1 --> layer2 (o2) --> layer3 (o3)
  180 sys49155,"1000"
  190 print "1  0  0  0 -->";int(o2(1)+0.5);int(o2(2)+0.5);"-->";
  200 for i= 1 to 4
  210 print int(o3(i)+0.5);
  220 next i
  230 print
  240 sys49155,"0100"
  250 print "0  1  0  0 -->";int(o2(1)+0.5);int(o2(2)+0.5);"-->";
  260 for i= 1 to 4
  270 print int(o3(i)+0.5);
  280 next i
  290 print
  300 sys49155,"0010"
  310 print "0  0  1  0 -->";int(o2(1)+0.5);int(o2(2)+0.5);"-->";
  320 for i= 1 to 4
  330 print int(o3(i)+0.5);
  340 next i
  350 print
  360 sys49155,"0001"
  370 print "0  0  0  1 -->";int(o2(1)+0.5);int(o2(2)+0.5);"-->";
  380 for i= 1 to 4
  390 print int(o3(i)+0.5);
  400 next i
  410 print
