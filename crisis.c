#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include<time.h>
#include <fcntl.h>
#include <signal.h>

#define MAX_HIJOS 34
static pid_t hijos[MAX_HIJOS]; //para albergar los pids de todos los hijos
static int numeroHijos = 0; //para contar el numero de hijos que tienen
void manejarSigint(int sig);
void manejarSigterm(int sig);
void decrementarProceso(void);
int puedeCrearProceso(int n_max_procs);

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

    struct sigaction ss;
        ss.sa_handler=manejarSigterm;
        sigemptyset(&ss.sa_mask);
        ss.sa_flags=0;
        sigaction(SIGTERM, &ss, NULL);
    struct sigaction sigint;
        sigint.sa_handler = manejarSigint;
        sigemptyset(&sigint.sa_mask);
        sigint.sa_flags = 0;
        sigaction(SIGINT, &sigint, NULL);
    //PREPARADOS DEL FICHERO Y DATOS DE LA MATRIZ
    pid_t pidMatriz=getpid();

    char buffer[64];//Imprimimos el pid del padre inicial antes de empezar a crear hijos
    sprintf(buffer, "V(%d)\n", getpid());
    write(1, buffer, strlen(buffer));
    int fd = open("contador.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if(fd==-1){
        perror("No se ha podido abrir el fichero");
        exit(1);
    }
    sprintf(buffer, "1\n");
    write(fd, buffer, strlen(buffer));
    close(fd);
    //COMIENZO DEL TRABAJO CON LOS HIJOS
    while(1){
        if(!strcmp(velocidad,"normal")) sleep(rand()%4+1);

            if(getpid()!=pidMatriz&&(rand()%2!=0)){//si no soy la matriz padre ni coincide que quiero crear, entonces destruyo
                manejarSigterm(SIGTERM);
            }
            else{//o soy la matriz padre o me tocó crear proceso
                if(puedeCrearProceso(n_max_procs)){
                    pid_t pid=fork();
                    if(pid==-1){
                        perror("No se ha podido crear ningun proceso");
                        return 1;
                    }
                    else if(pid==0){
                        numeroHijos=0;
                        sprintf(buffer, "V(%d)\n", getpid());
                        write(1, buffer, strlen(buffer));
                    }
                    else if(pid>0){
                        hijos[numeroHijos]=pid;//metemos el pid de su hijo en el array de sus hijos
                        numeroHijos++;//ha tenido un nuevo hijo
                    }
                }

                }
            }

    return 0;
}

void decrementarProceso(){
    char procesos[4];

    int fd = open("contador.txt", O_RDWR);
    if(fd==-1) return;//como es void vuelvo sin hacer nada

    lockf(fd, F_LOCK, 0); //BLOQUEO------
    lseek(fd, 0, SEEK_SET);
    read(fd, procesos, sizeof(procesos)-1);
    int procesosVivos=atoi(procesos)-1;
    lseek(fd, 0, SEEK_SET); // Volvemos al principio para sobrescribir
    sprintf(procesos, "%d\n", procesosVivos);
    write(fd, procesos, strlen(procesos));
    lockf(fd, F_ULOCK, 0);//DESBLOQUEO------
    close(fd);
}

int puedeCrearProceso(int n_max_procs){
    int exito=0;
    int fd = open("contador.txt", O_RDWR);
    char procesos[4]; //le pongo 4 por que son maximo numeros de 2 cifras mas el caracter nulo y el de final de cadena
    if(fd==-1){
        return 0; //que en el if qeu ejecuto significa que no se puede
    }

    lockf(fd, F_LOCK, 0); //BLOQUEO------
    lseek(fd, 0, SEEK_SET);
    read(fd, procesos, sizeof(procesos)-1);
    int procesosVivos =atoi(procesos);
    if(procesosVivos<n_max_procs){
        procesosVivos++;
        lseek(fd, 0, SEEK_SET);
        sprintf(procesos, "%d\n", procesosVivos);
        write(fd, procesos, strlen(procesos));
        exito=1;
    }
    lockf(fd, F_ULOCK, 0);//DESBLOQUEO------
    close(fd);
    return exito;

}

void manejarSigterm(int sig){
    for(int i=0; i<numeroHijos;i++){
        kill(hijos[i], SIGTERM);
    }
    decrementarProceso();
    char buffer[64];
    sprintf(buffer, "M(%d)\n", getpid());
    write(1, buffer, strlen(buffer));
    exit(0);

}

void manejarSigint(int sig){
    for(int i=0; i<numeroHijos; i++){
        kill(hijos[i], SIGTERM);
    }
    unlink("contador.txt");
    printf("Sistema acabado correctamente");
    exit(0);
}