#include <stdio.h>
#include <string.h>
extern const unsigned char engine[];
extern unsigned __fastcall__ run_counter(unsigned n);
static unsigned cases[] = {0,1,2,255,256,257,400,511,512,513,1000,32767};
int main(void) {
    unsigned i,n,got,expected;
    memcpy((void*)0xc000,engine,2446);
    /* Replace the expensive epoch with a 16-bit call counter at $0400.
       Replace only the RUN/STOP call target with a no-key stub.
       The counter arithmetic and branches remain byte-identical; the JSR target at $C618-$C619 is the only edit in that region. */
    memcpy((void*)0xc3e6,"\xee\x00\x04\xd0\x03\xee\x01\x04\x60",9);
    memcpy((void*)0xc3f0,"\xa9\x01\x60",3);
    *(unsigned char*)0xc618=0xf0;
    *(unsigned char*)0xc619=0xc3;
    /* Prove every other byte of the exercised counter region is original. */
    for(i=0x606;i<=0x62b;++i) {
        if(i!=0x618 && i!=0x619 && ((unsigned char*)0xc000)[i]!=engine[i])
            return 2;
    }
    for(i=0;i<sizeof(cases)/sizeof(cases[0]);++i) {
        n=cases[i]; *(unsigned*)0x0400=0;
        got=run_counter(n);
        expected=(n>255 && (n&255)) ? n-256 : n;
        printf("requested=%u epochs=%u %s\n",n,got,got==expected?"observed":"UNEXPECTED");
        if(got!=expected)return 1;
    }
    return 0;
}
