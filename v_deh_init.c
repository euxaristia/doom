// Wrapper to initialize V DEH globals
#include <stdio.h>

// Declaration of the V initialization function
extern void V_DEH_Init(void);

// Function to initialize V DEH globals
// This should be called before any DEH operations
void V_Init_DEH_Globals(void) {
    printf("Initializing V DEH globals...\n");
    V_DEH_Init();
}