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
#x=$1 #la x a la que hacerle el modulo
#y=$2 #la y a la que hacerle el modulo
#(scale=2) #he ajustado la precision a 2 decimales(eso se le envia al bc)
#r=$(echo "scale=2; sqrt(($x^2)+($y^2))" | bc -l)
#ang=$(echo "scale=2; arctan($y/$x)" | bc -l)
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
    #m=$1 #el modulo 
    #a=$2 #el argumento (en grados)
    #se pasa el argumento y se pasa a radianes con 4*a(1)=pi y se calcula el coseno
    #x=$(echo "scale=20; $m * c($a * 4 * a(1)/180)" | bc -l) #se pasa el argumento y se pasa a radianes con 4*a(1)=pi y se calcula el coseno
    #y=$(echo "scale=20; $m * s($a * 4 * a(1)/180)" | bc -l)
    ##BORRAR

    #HECHO CON calc
    x=$(calc "$1 * c(($2) * k)")
    y=$(calc "$1 * s(($2) * k)")
    return 0
}

function SumaRectangulares {
    if [ $# != 4 ]; then
        error "SumaRectangulares necesita 4 parámetros." 
        return 1 
    fi
    
    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4

    #Calculo de coordenadas parte real
    x=$(calc "($x1) + ($x2)") 
    #Calculo de coordenadas parte imaginaria
    y=$(calc "($y1) + ($y2)")
    
    return 0
}

function SumaPolares {
    if [ $# != 4 ]; then
        error "SumaPolares necesita 4 parámetros." 
        return 1 
    fi

    polares_a_rectangulares $1 $2
    local x1=$x
    local y1=$y
    
    polares_a_rectangulares $3 $4
    local x2=$x
    local y2=$y

    SumaRectangulares $x1 $y1 $x2 $y2
    if [ $? -ne 0 ]; then
        return 1
    fi

    rectangulares_a_polares $x $y
    return 0
}

function RestaRectangulares {
    if [ $# != 4 ]; then
        error "RestaRectangulares necesita 4 parámetros." 
        return 1 
    fi

    local x1=$1
    local y1=$2
    local x2=$3
    local y2=$4

    #Calculo de coordenadas parte real#
    x=$(calc "($x1) - ($x2)")
    #Calculo de coordenadas parte imaginaria#
    y=$(calc "($y1) - ($y2)")
    return 0
}

function RestaPolares {
    if [ $# != 4 ]; then
        error "RestaPolares necesita 4 parámetros." 
        return 1 
    fi
    polares_a_rectangulares $1 $2
    local x1=$x
    local y1=$y
    
    polares_a_rectangulares $3 $4
    local x2=$x
    local y2=$y

    RestaRectangulares $x1 $y1 $x2 $y2
    if [ $? -ne 0 ]; then
        return 1
    fi
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
    if [ $# -ne 4 ]; then
        error "MultiplicaPolares necesita 4 parámetros."
        return 1
    fi

    local modulo1=$1
    local angulo1=$2
    local modulo2=$3
    local angulo2=$4

    r=$(echo "scale=20; $modulo1 * $modulo2" | bc -l)
    ang=$(echo "scale=20; $angulo1 + $angulo2" | bc -l)
    return 0

}
function DivideRectangulares {
    if [ $# -ne 4 ]; then
        error "DivideRectangulares necesita 4 parmetros." 
        return 1
    fi


    rectangulares_a_polares $1 $2 #paso a polares la primera
    local modulo1=$r
    local angulo1=$ang

    rectangulares_a_polares $3 $4 #paso a polares la segunda
    local modulo2=$r
    local angulo2=$ang

    DividePolares $modulo1 $angulo1 $modulo2 $angulo2
    if [ $? -ne 0 ]; then
        return 1
    fi

    polares_a_rectangulares $r $ang

    return 0

}
function DividePolares {
    if [ $# -ne 4 ]; then
        error "DividePolares necesita 4 parámetros."
        return 1
    fi

    if es_cero "$3"; then
        error "No se puede dividir entre cero"
        return 1
    fi

    r=$(echo "scale=20; $1 / $3" | bc -l)
    ang=$(echo "scale=20; $2 - $4" | bc -l)

    return 0
}

# Escribe el número complejo x+iy como "a+bi" o "a-bi".
function texto_rectangulares {
    #Cogemos los valores de los parámetros y los guardamos en variables locales
    local TR_X=$1
    local TR_Y=$2
    case $TR_Y in
        -*) echo "$TR_X$TR_Y"i ;;     # la imaginaria ya trae el "-"
        *)  echo "$TR_X+$TR_Y"i ;;    # hay que poner el "+"
    esac
}

# Escribe el número complejo mod arg como "mod arg" (con espacio). SE PUEDE USAR CUALQUIERA DE LAS 2
function TextoPolares {
    local TP_M=$1 #modulo
    local TP_A=$2 #argumento (ya viene en la unidad actual: grados o radianes)
    local TP_VUELTA #una vuelta completa

    if test "$ANGULO" = grados; then
        TP_VUELTA=360
    else
        TP_VUELTA=$(echo "scale=20; 2 * (4*a(1))" | bc -l)
    fi

    #mientras el angulo de una vuelta o mas, le quito una vuelta
    while test "$(echo "$TP_A >= $TP_VUELTA" | bc -l)" = 1; do
        TP_A=$(calc "$TP_A - $TP_VUELTA")
    done

    echo "$(fmt "$TP_M") $(fmt "$TP_A")" #imprimo las dos partes redondeadas
}

# Escribe el número complejo x+iy como "a+bi" o "a-bi".

#Se va a utilizar la convención del angulo que se representa desde -mediavuelta, mediavuelta
function texto_polares {
    normaliza "$2" #se normaliza el angulo para que quede entre -mediavuelta y mediavuelta
    echo "$(fmt "$1")_$(fmt "$ANG") $ANGULO"
    return 0
}

function normaliza {
    local NZ_A=$1
    local NZ_M
    if test "$ANGULO" = grados; then
        NZ_M=180
    else
        NZ_M=$(calc "pi")
    fi

    local NZ_V=$(calc "2 * $NZ_M")                 # una vuelta completa

    while mayor "$NZ_A" "$NZ_M"; do                # mientras ang > media vuelta
        NZ_A=$(calc "$NZ_A - $NZ_V")           #   le quito una vuelta
    done
    until mayor "$NZ_A" "-$NZ_M"; do               # hasta que ang > -media vuelta
        NZ_A=$(calc "$NZ_A + $NZ_V")           #   le añado una vuelta
    done

    ANG=$NZ_A

    return 0
}


# es_cero valor
#   Devuelve 0 (éxito) si el valor es exactamente 0, aunque se escriba 0.0 o -0.
function es_cero {
    test "$(echo "$1 == 0" | bc -l)" = 1
}

#BORRAR
# fmt valor
#   Redondea "valor" a DECIMALES decimales y lo escribe. Evita el "-0.0000".
#function fmt {

#    redondeado=$(echo "scale=2; ($1+0.005)/1" | bc -l) #en un principio con el +0,005 bastaria para un redondeo a las 
    #centenas, pero el scale solo se activa al hacer una cuenta con bc y no me cortaria donde quiero,
    #asi que lo he dividido entre 1
#    if [ $redondeado = -0.00 ]; then
#    redondeado=0.00 #ahi si me ha salido el problema ese del cero negativo lo cambio por el positivo y tirando
#    fi
#}
#BORRAR

function fmt {
    case $(printf "%.${DECIMALES}f" "$1") in
        -0.0000) echo 0.0000 ;;
        *)       printf "%.${DECIMALES}f\n" "$1" ;;
    esac
}

# comprueba_numeros n1 n2 ...
#   Comprueba que todos los argumentos son números válidos (con es_numero).
#   Devuelve 0 si lo son y 1 si alguno no lo es, avisando con error.
function CompruebaNumeros {
    while [ $# != 0 ]; do #mientras el total de parametros(que ira quitando uno por el shift al final de cada iteracion) no sea 0 seguimos verificando
        if ! es_numero "$1"; then #si tu haces un if 1 se ejecuta siempre, asi que aqui como es_numero da un 0, si lo cambio a lo contrario ejecuta el if
            error "'$1' no es un número válido"
            return 1
        fi
        shift 1 #el shift quita uno a los argumentos totales y $1 pasa a ser el siguiente($2)
    done
    return 0
}


# ejecuta_opcion opcion operandos...
#   Gestiona las opciones -p, -r, -sr, -sp, -rr, -rp, -mr, -mp, -dr y -dp.
#   Comprueba el número de operandos y que sean números, llama a la operación
#   y escribe el resultado. Devuelve 0 si va bien, 1 si falla la operación
#   (por ejemplo, división por cero) y 2 si el uso es incorrecto.
function EjecutaOpcion {
    local seleccion
    seleccion=$1
    shift 1 # aqui como esta guardado le voy a quitar lo primero para que me de menos primeros
    case $seleccion in
    "-p") #llamar a rectangulares_a_polares, 2 argumentos
        if [ $# != 2 ]; then
            echo "Necesitas 2 parametros"
            return 2
        fi
        if ! CompruebaNumeros "$@" ; then
            return 2
        fi
        rectangulares_a_polares $1 $2
    ;;

    "-r") #llamar a polares_a_rectangulares, 2 argumentos
        if [ $# != 2 ]; then
            echo "Necesitas 2 parametros"
            return 2
        fi
        if ! CompruebaNumeros "$@" ; then
            return 2
        fi
        polares_a_rectangulares $1 $2
    ;;

    "-sr") #llamar a SumaRectangulares, 4 argumentos
        if [ $# != 4 ]; then
            echo "Necesitas 4 parametros"
            return 2
        fi
        if ! CompruebaNumeros "$@" ; then
            return 2
        fi
        SumaRectangulares $1 $2 $3 $4
    ;;

    "-sp") #llamar a SumaPolares, 4 argumentos
        if [ $# != 4 ]; then
            echo "Necesitas 4 parametros"
            return 2
        fi
        if ! CompruebaNumeros "$@" ; then
            return 2
        fi
        SumaPolares $1 $2 $3 $4
    ;;

    "-rr") #llamar a RestaRectangulares, 4 argumentos
        if [ $# != 4 ]; then
                echo "Necesitas 4 parametros"
                return 2
        fi
        if ! CompruebaNumeros "$@" ; then
                return 2
        fi
        RestaRectangulares $1 $2 $3 $4
    ;;

    "-rp") #llamar a RestaPolares, 4 argumentos
        if [ $# != 4 ]; then
                echo "Necesitas 4 parametros"
                return 2
        fi
        if ! CompruebaNumeros "$@" ; then
                return 2
        fi
        RestaPolares $1 $2 $3 $4
    ;;

    "-mr") #llamar a MultiplicaRectangulares, 4 argumentos
        if [ $# != 4 ]; then
                echo "Necesitas 4 parametros"
                return 2
        fi
        if ! CompruebaNumeros "$@" ; then
                return 2
        fi
        MultiplicaRectangulares $1 $2 $3 $4
    ;;

    "-mp") #llamar a MultiplicaPolares, 4 parametros
        if  [ $# != 4 ]; then
                echo "Necesitas 4 parametros"
                return 2
        fi
        if ! CompruebaNumeros "$@" ; then
                return 2
        fi
        MultiplicaPolares $1 $2 $3 $4
    ;;

    "-dr") #llamar a DivideRectangulares, 4 parametros
        if  [ $# != 4 ]; then
                echo "Necesitas 4 parametros"
                return 2
        fi
        if ! CompruebaNumeros "$@" ; then
                return 2
        fi
        DivideRectangulares $1 $2 $3 $4
    ;;

    "-dp") #llamar a DividePolares, 4 parametros
        if  [ $# != 4 ]; then
                echo "Necesitas 4 parametros"
                return 2
        fi
        if ! CompruebaNumeros "$@" ; then
                return 2
        fi
        DividePolares $1 $2 $3 $4
    ;;

    "-h") #abrir Ayuda, 0 parametros
        if [ $# != 0 ]; then
            echo "No se le pueden pasar parámetros a -h"
            return 2
        fi
        uso
    ;;

    *)
        echo "Opción no valida"
        return 2
    ;;
    esac
}

# recorta "texto"
#   Deja en RECORTADO el texto sin espacios al principio ni al final.

# parse_operando "texto"
#   Analiza un complejo escrito como "a+bi" (o con j), "bi", real puro o
#   polar "mod arg". Deja el tipo en P_T (r o p) y los valores en P_A y P_B.
#   Devuelve 1 si el texto no es un complejo válido.

# evalua_expresion "(op1)operador(op2)"
#   Separa los dos operandos y el operador, calcula y escribe
#   "expresión = resultado". Si los dos operandos son polares el resultado
#   sale en polares; en cualquier otro caso, en rectangulares.

# procesa_linea "línea"
#   Trata una línea del fichero. Ignora las vacías y las que empiezan por #,
#   cambia la unidad con "grados" o "radianes" y evalúa el resto.

# procesa_fichero fichero
#   Lee el fichero línea a línea y llama a procesa_linea con cada una.
#   Devuelve 0 si todas fueron bien y 1 si alguna dio error.

exit 0;

