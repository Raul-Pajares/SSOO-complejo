#!/bin/bash

ANGULO=grados
NOMBRE=${0##*/} #deja solo el fichero, $0 es el path completo del script, ##/ quita todo hasta la última barra, dejando solo el nombre del script

function error {
    echo "$NOMBRE: error: $*" >&2 #Se redirige al canal de errores
}

function uso {
    echo "Uso:"
    echo "  $NOMBRE [-grad|-rad] OPCION operandos..."
    echo "  $NOMBRE [-grad|-rad] \"(a+bi)op(c+di)\"" 
    echo "  $NOMBRE [-grad|-rad] -f fichero"
    echo "  $NOMBRE -h"
    echo
    echo "Conversiones:"
    echo "  -p  x y              rectangulares (x+iy) -> polares"
    echo "  -r  mod arg          polares (mod, arg)   -> rectangulares"
    echo
    echo "Operaciones (cuatro operandos: x1 y1 x2 y2  ó  mod1 arg1 mod2 arg2):"
    echo "  -sr x1 y1 x2 y2      suma           en rectangulares"
    echo "  -sp m1 a1 m2 a2      suma           en polares"
    echo "  -rr x1 y1 x2 y2      resta          en rectangulares"
    echo "  -rp m1 a1 m2 a2      resta          en polares"
    echo "  -mr x1 y1 x2 y2      multiplicación en rectangulares"
    echo "  -mp m1 a1 m2 a2      multiplicación en polares"
    echo "  -dr x1 y1 x2 y2      división       en rectangulares"
    echo "  -dp m1 a1 m2 a2      división       en polares"
    echo
    echo "Otras opciones:"
    echo "  -f fichero           lee las operaciones de un fichero de texto"
    echo "  -grad                ángulos en grados (por defecto)"
    echo "  -rad                 ángulos en radianes"
    echo "                       (-grad y -rad se ponen antes que el resto)"
    echo "  -h                   muestra esta ayuda"
    echo
    echo "Notación matemática (por la línea de comandos o en el fichero):"
    echo "  Rectangular:  a+bi  (también vale \"j\")      Polar:  \"mod arg\"  (con espacio)"
    echo "  Ejemplos:     $NOMBRE \"(2+3i)+(3-2i)\""
    echo "                $NOMBRE -rad \"(4 0.78)/(10 -1.57)\""
    echo
    echo "Formato del fichero (una operación por línea):"
    echo "  (2+3i)+(3-2i)"
    echo "  (4 45)/(10 -90)"
    echo "  radianes                 <- cambia la unidad a partir de esa línea"
    echo "  (2 0.5)*(2 0.5)"
    echo "  # las líneas vacías y las que empiezan por # se ignoran"
    echo "  Con dos operandos polares el resultado sale en polares; en cualquier"
    echo "  otro caso, en rectangulares."
}

# es_numero valor
# Comprueba si "valor" es un número decimal válido
# Devuelve 0 si lo es y 1 si no.
function es_numero {
    local EN_N=$1 #numero con signo
    local EN_R #numero sin signo
    case $EN_N in
        #Si empieza por un signo, lo quita para la comprobación
        [+-]*) EN_R=${EN_N#?} ;; # quita el signo inicial
        *)     EN_R=$EN_N ;;
    esac

    case $EN_R in
        ""|*[!0-9.]*|*.*.*) return 1 ;; # vacío, caracteres raros o 2 puntos
        *[0-9]*)            return 0 ;; # al menos un dígito
    esac
    return 1
}


# calc "expresión"
#   Ejecuta la cuenta con bc y escribe el resultado.
#   Deja definidos pi y k para poder usarlos en la expresión.
function calc {
    # k convierte la unidad actual a radianes:
    #   en grados   -> k = pi/180
    #   en radianes -> k = 1
    if test "$ANGULO" = grados; then #este angulo definido en la parte superior del script es el que se puede cambiar con los parametros -grad y -rad
        C_K="pi / 180"
    else
        C_K=1
    fi
    # Se manda a bc por una tubería
    echo "scale = 20; pi = 4 * a(1); k = $C_K; $1" | bc -l
}

# mayor a b
#   Devuelve 0 (éxito) si a > b y 1 si no.
#   test solo compara enteros, así que la comparación la hace bc.
function mayor {
    test "$(echo "($1) > ($2)" | bc -l)" = 1
}

function rectangulares_a_polares { #PENDIENTE DE REVISION
##BORRAR
x=$1 #la x a la que hacerle el modulo
y=$2 #la y a la que hacerle el modulo
(scale=2) #he ajustado la precision a 2 decimales(eso se le envia al bc)
r=$(echo "scale=2; sqrt(($x^2)+($y^2))" | bc -l)
ang=$(echo "scale=2; arctan($y/$x)" | bc -l)
##BORRAR

#HECHO CON calc
r=$(calc "sqrt(($1^2)+($2^2))")

    # El ángulo se calcula primero en radianes, según el cuadrante
    if mayor "$1" 0; then                          # x > 0
        ang=$(calc "a(($2) / ($1))")
    elif mayor 0 "$1"; then                        # x < 0
        if mayor 0 "$2"; then                      #   y < 0
            ang=$(calc "a(($2) / ($1)) - pi")
        else                                       #   y >= 0
            ang=$(calc "a(($2) / ($1)) + pi")
        fi
    else                                           # x = 0
        if mayor "$2" 0; then                      #   y > 0
            ang=$(calc "pi / 2")
        elif mayor 0 "$2"; then                    #   y < 0
            ang=$(calc "-pi / 2")
        else                                       #   y = 0 (el origen)
            ang=0
        fi
    fi

    # Si se trabaja en grados, se pasa de radianes a grados
    if test "$ANGULO" = grados; then
        ang=$(calc "($ang) * 180 / pi")
    fi

    return 0
}

function polares_a_rectangulares { ##FALTA POR ACTUALIZAR
    ##BORRAR
    m=$1 #el modulo 
    a=$2 #el argumento (en grados)
    #se pasa el argumento y se pasa a radianes con 4*a(1)=pi y se calcula el coseno
    x=$(echo "scale=20; $m * c($a * 4 * a(1)/180)" | bc -l) #se pasa el argumento y se pasa a radianes con 4*a(1)=pi y se calcula el coseno
    y=$(echo "scale=20; $m * s($a * 4 * a(1)/180)" | bc -l)
    
    ##BORRAR

    #HECHO CON calc
    x=$(calc "$1 * c(($2) * k)")
    y=$(calc "$1 * s(($2) * k)")
    return 0
}

function SumaRectangulares {
    if [ $# -ne 4 ]; then
    echo "Error, la funcion necesita 4 parmetros." 
    exit 1 #o return 1, ya vere si hay que cambiarlo
    fi
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4

    #Calculo de coordenadas parte real#
    x=$(echo "scale=2; $x1 + $x2" | bc -l)
    #Calculo de coordenadas parte imaginaria#
    y=$(echo "scale=2; $y1 + $y2" | bc -l)
    
    return 0
}

function SumaPolares {
    polares_a_rectangulares $1 $2
    local x1=$x
    local y1=$y
    
    polares_a_rectangulares $3 $4

    local x2=$x
    local y2=$y

    SumaRectangulares $x1 $y1 $x2 $y2

    rectangulares_a_polares $x $y

    return 0
}

function RestaRectangulares {
    if [ $# -ne 4 ]; then
    echo "Error, la funcion necesita 4 parmetros." 
    exit 1 #o return 1, ya vere si hay que cambiarlo
    fi
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4

    #Calculo de coordenadas parte real#
    x=$(echo "scale=2; $x1 - $x2" | bc -l)
    #Calculo de coordenadas parte imaginaria#
    y=$(echo "scale=2; $y1 - $y2" | bc -l)
    
    return 0
}

function RestaPolares {
    polares_a_rectangulares $1 $2
    local x1=$x
    local y1=$y
    
    polares_a_rectangulares $3 $4

    local x2=$x
    local y2=$y

    RestaRectangulares $x1 $y1 $x2 $y2

    rectangulares_a_polares $x $y

    return 0
}

function MultiplicaRectangulares {

    rectangulares_a_polares $1 $2
    local m1=$r
    local a1=$ang

    rectangulares_a_polares $3 $4
    local m2=$r
    local a2=$ang

    MultiplicaPolares $m1 $a1 $m2 $a2

    polares_a_rectangulares $r $ang

    return 0
}
function MultiplicaPolares {
}
function DivideRectangulares {
}
function DividePolares {
    if es_cero "$3"; then
        error "división por cero"
        return 1
    fi

    r=$(echo "scale=20; $1 / $3" | bc -l)
    ang=$(echo "scale=20; $2 - $4" | bc -l)

    return 0
}

# es_cero valor
#   Devuelve 0 (éxito) si el valor es exactamente 0, aunque se escriba 0.0 o -0.
function es_cero {
    test "$(echo "($1) == 0" | bc -l)" = 1
}

exit 0;

