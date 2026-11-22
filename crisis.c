#define __USE_POSIX
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
#include<time.h>
#include <fcntl.h>
#include <signal.h>
#include <errno.h>
#include <sys/wait.h>
#define MAX_HIJOS 34
static pid_t hijos[MAX_HIJOS]; //para albergar los pids de todos los hijos
static pid_t pidMatriz;

static int numeroHijos = 0; //para contar el numero de hijos que tienen
void manejarSigint(int sig);
void manejarSigterm(int sig);
void manejarSigchld(int sig);
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
    char mensaje[128];
    sprintf(mensaje, "Numero maximo de procesos pasado por linea de ordenes: %d\n", n_max_procs);
    write(1, mensaje, strlen(mensaje));
    pidMatriz=getpid();
    struct sigaction ss;
        ss.sa_handler=manejarSigterm;
        sigemptyset(&ss.sa_mask);
        sigaddset(&ss.sa_mask, SIGTERM);
        sigaddset(&ss.sa_mask, SIGINT);
        sigaddset(&ss.sa_mask, SIGCHLD);
        ss.sa_flags=0;
        sigaction(SIGTERM, &ss, NULL);
    struct sigaction sigint;
        sigint.sa_handler = manejarSigint;
        sigemptyset(&sigint.sa_mask);
        sigaddset(&sigint.sa_mask, SIGTERM);
        sigaddset(&sigint.sa_mask, SIGINT);
        sigaddset(&sigint.sa_mask, SIGCHLD);
        sigint.sa_flags = 0;
        sigaction(SIGINT, &sigint, NULL);
    
    struct sigaction saHijo;
        saHijo.sa_handler = manejarSigchld;
        sigemptyset(&saHijo.sa_mask);
        sigaddset(&saHijo.sa_mask, SIGTERM);
        sigaddset(&saHijo.sa_mask, SIGINT);
        sigaddset(&saHijo.sa_mask, SIGCHLD);
        saHijo.sa_flags = 0; 
        sigaction(SIGCHLD, &saHijo, NULL);

    sigset_t mascara;
        sigemptyset(&mascara);
        sigaddset(&mascara, SIGTERM);
        sigaddset(&mascara, SIGINT);
        sigaddset(&mascara, SIGCHLD);
    //PREPARADOS DEL FICHERO Y DATOS DE LA MATRIZ
    int uno=1;
    char buffer[64]={0};//Imprimimos el pid del padre inicial antes de empezar a crear hijos
    sprintf(buffer, "V(%d)\n", getpid());
    if(write(1, buffer, strlen(buffer))==-1){
        perror("Error imprimiendo pid");
        exit(1);
    }
    int fd = open("contador.txt", O_RDWR | O_CREAT | O_TRUNC, 0644);
    if(fd==-1){
        perror("No se ha podido abrir el fichero");
        exit(1);
    }
    if(write(fd, &uno, sizeof(int))==-1){
        perror("Error escribiendo el fichero");
        close(fd);
        exit(1);
    }
    close(fd);
    //COMIENZO DEL TRABAJO CON LOS HIJOS
    while(1){
        if(!strcmp(velocidad,"normal")) sleep(rand()%4+1);

        if(getpid()!=pidMatriz&&(rand()%2!=0)){//si no soy la matriz padre ni coincide que quiero crear, entonces destruyo
            kill(getpid(), SIGTERM);
        }
        else{//o soy la matriz padre o me tocó crear proceso
            sigprocmask(SIG_BLOCK, &mascara, NULL);
            if(puedeCrearProceso(n_max_procs)){
                pid_t pid=fork();
                if(pid==-1){
                    perror("No se ha podido crear ningun proceso");
                    decrementarProceso();
                    return 1;
                }
                else if(pid==0){
                    numeroHijos=0;
                    srand(time(NULL) ^ getpid()); //lo cambie y lo añadi porque siempre salian los mismos numeros
                    sprintf(buffer, "V(%d)\n", getpid());
                        if(write(1, buffer, strlen(buffer))==-1){
                            perror("Error imprimiendo pid");
                            exit(1);
                        }
                }
                else if(pid>0){
                    hijos[numeroHijos]=pid;//metemos el pid de su hijo en el array de sus hijos
                    numeroHijos++;//ha tenido un nuevo hijo
                }
            }
            sigprocmask(SIG_UNBLOCK, &mascara, NULL);
        }
    }

    return 0;
}

void decrementarProceso(){
    int procesosVivos;

    int fd = open("contador.txt", O_RDWR);
    if(fd==-1) return;//como es void vuelvo sin hacer nada

    while (lockf(fd, F_LOCK, 0)==-1){ //BLOQUEO--------
        if (errno != EINTR) {
            perror("Error al bloquear");
            close(fd);
            return;
        }
    }
    if (read(fd, &procesosVivos, sizeof(int)) == sizeof(int)) {
        procesosVivos--;
        lseek(fd, 0, SEEK_SET);
        if(write(fd, &procesosVivos, sizeof(int))==-1){
            perror("Error escribiendo numero de procesos");
            exit(1);
        }
    }
    lseek(fd, 0, SEEK_SET);
    lockf(fd, F_ULOCK, 0);//DESBLOQUEO------
    close(fd);
}

int puedeCrearProceso(int n_max_procs){
    int exito=0;
    int procesosVivos;
    int fd = open("contador.txt", O_RDWR);
    if(fd==-1){
        return 0; //que en el if qeu ejecuto significa que no se puede
    }

    while (lockf(fd, F_LOCK, 0)==-1){ //BLOQUEO--------
        if (errno != EINTR) {
            perror("Error al bloquear");
            close(fd);
            return 0;
        }
    }

    if(read(fd, &procesosVivos, sizeof(int))==sizeof(int)){
        if(procesosVivos<n_max_procs){
            procesosVivos++;
            lseek(fd, 0, SEEK_SET);
            if(write(fd, &procesosVivos, sizeof(int))==sizeof(int)){
                exito=1;
            }
        }
    }

    lseek(fd, 0, SEEK_SET);
    lockf(fd, F_ULOCK, 0);//DESBLOQUEO------
    close(fd);
    return exito;

}

void manejarSigterm(int sig){
    int estado;
    for(int i=0; i<numeroHijos;i++){
        kill(hijos[i], SIGTERM);
    }

    while(numeroHijos>0){
        pid_t p=wait(&estado);
        if(p==-1){
            if(errno==EINTR){
                continue;
            }
            break;
        }

    decrementarProceso();
    numeroHijos--;
    }

    char buffer[64]={0};
    sprintf(buffer, "M(%d)\n", getpid());
    write(1, buffer, strlen(buffer));
    exit(0);

}

void manejarSigint(int sig){
    int estado;
    if (getpid() == pidMatriz){
        for(int i=0; i<numeroHijos; i++){
            kill(hijos[i], SIGTERM);
        }

        while(numeroHijos>0){
            pid_t p=wait(&estado);
            if(p==-1){
                if(errno==EINTR){
                    continue;
                }
                break;
            }

            decrementarProceso();
            numeroHijos--;
        }

        unlink("contador.txt");
        char buffer[64];
        sprintf(buffer, "M(%d)\n", getpid());
        write(1, buffer, strlen(buffer));
        write(1, "Programa acabado correctamente\n", strlen("Programa acabado correctamente\n"));
        exit(0);
    }
}

void manejarSigchld(int sig) {
    int estado;
    pid_t pid;

    while ((pid=waitpid(-1, &estado, WNOHANG))>0){
        for (int i=0;i<numeroHijos;i++){
            if (hijos[i]==pid){
                hijos[i]=hijos[numeroHijos - 1];
                numeroHijos--;
                break;
            }
        }
        decrementarProceso();
    }
}