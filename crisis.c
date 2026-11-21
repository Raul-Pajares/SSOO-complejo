#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include <sys/types.h>
#include<time.h>

int main(int argc, char *argv[]){
    srand(time(NULL));
    char *velocidad="normal";

    //VERIFICACIONES DE LOS PARAMETROS ANTES DE EMPEZAR
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

    //COMIENZO DE LOS FORKS()
    char buffer[64];//Imprimimos el pid del padre inicial antes de empezar a crear hijos
    sprintf(buffer, "V(%d)\n", getpid());
    write(1, buffer, strlen(buffer));
    while(1){
        if(!strcmp(velocidad,"normal")) sleep(rand()%4+1);
        pid_t pid=fork();
        if(pid==-1){
            perror("No se ha podido crear ningun proceso");
            return 1;
        }
        else if(pid==0){
            sprintf(buffer, "V(%d)\n", getpid());
            write(1, buffer, strlen(buffer));

            int opcion=rand()%2;
            if(opcion!=0){
                sprintf(buffer, "M(%d)\n", getpid());
                write(1, buffer, strlen(buffer));
                exit(0);
            }
        }
        else if(pid>0){
        }
    }

    return 0;
}