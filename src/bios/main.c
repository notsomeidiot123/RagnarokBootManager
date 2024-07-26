void bmain(){
    unsigned short *testptr = (void *)0xb8000;
    *testptr = 0xf41;
    for (;;);
}