#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include <sys/types.h>

int main(int argc, char *argv[]){
    char *velocidad="normal";

    //VERIFICACIONES DE LOS PARAMETROS
    if(argc!=2&&argc!=3){
        fprintf(stderr, "Error, hemos recibido un numero de parametros inadecuado\n");
        return 1;
    }
    int n_max_procs=atoi(argv[1]);
    if(n_max_procs<3||n_max_procs>34){
        fprintf(stderr, "Error, el numero maximo de procesos esta fuera del rango(3-34)\n");
        return 1;
    }
    if(argc==3){
        if(strcmp("normal", argv[2])&&strcmp("veloz", argv[2])){
            fprintf(stderr, "La velocidad introducida no es ni veloz ni normal\n");
            return 1;
        }
        else{
            velocidad=argv[2];
        }
    }




    return 0;
}