#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <time.h>

int main(void)
{
    int i;

    srand(time(NULL) ^ getpid());
    printf("rand()%%2 seguidos:      ");
    for (i = 0; i < 30; i++)
        printf("%d", rand() % 2);
    printf("\n");

    srand(time(NULL) ^ getpid());
    printf("como en crisis (2 rand): ");
    for (i = 0; i < 30; i++)
    {
        rand();                     /* El del sleep. */
        printf("%d", rand() % 2);   /* El de crear o morir. */
    }
    printf("\n");
    return 0;
}
