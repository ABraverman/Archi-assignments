#include <stdio.h>
#define	MAX_LEN 34			/* maximal input string size */
					/* enough to get 32-bit string + '\n' + null terminator */
extern void assFunc(int x, int y);

int main(int argc, char** argv) {
  
    char buf[MAX_LEN ];
    int x;
    int y;

    fgets(buf, MAX_LEN, stdin);		/* get user input to x */ 
    sscanf(buf, "%d", &x);

    fgets(buf, MAX_LEN, stdin);		/* get user input y */ 
    sscanf(buf, "%d", &y);

    assFunc(x, y);		/* call your assembly function */

    return 0;
}

char c_checkValidity(int x, int y) {

    if (x < 0){
        return 0;
    }
    
    if ( (y < 0) || (y > (1 << 15)) )  {
        return 0;
    }

    return 1;
    
}