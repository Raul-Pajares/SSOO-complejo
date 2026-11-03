#!/bin/bash

ANGULO=grados
NOMBRE=${0##*/} #deja solo el fichero, $0 es el path completo del script, ##/ quita todo hasta la última barra, dejando solo el nombre del script
DECIMALES=4 #numero de decimales a los que redondear el resultado
export LC_ALL=C # punto decimal: bc escribe con punto y en Encina (idioma español) printf esperaba coma
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
        C_K="p / 180"
    else
        C_K=1
    fi
    # Se manda a bc por una tubería
    echo "scale = 20; p = 4 * a(1); k = $C_K; $1" | bc -l
}

# mayor a b
#   Devuelve 0 (éxito) si a > b y 1 si no.
#   test solo compara enteros, así que la comparación la hace bc.
function mayor {
    test "$(echo "z = 0; if (($1) > ($2)) z = 1; z" | bc -l)" = 1
}

function rectangulares_a_polares { 
    r=$(calc "sqrt(($1^2)+($2^2))")

    # El ángulo se calcula primero en radianes, según el cuadrante
    if mayor "$1" 0; then                          # x > 0
        ang=$(calc "a(($2) / ($1))")
    elif mayor 0 "$1"; then                        # x < 0
        if mayor 0 "$2"; then                      #   y < 0
            ang=$(calc "a(($2) / ($1)) - p")
        else                                       #   y >= 0
            ang=$(calc "a(($2) / ($1)) + p")
        fi
    else                                           # x = 0
        if mayor "$2" 0; then                      #   y > 0
            ang=$(calc "p / 2")
        elif mayor 0 "$2"; then                    #   y < 0
            ang=$(calc "-p / 2")
        else                                       #   y = 0 (el origen)
            ang=0
        fi
    fi

    # Si se trabaja en grados, se pasa de radianes a grados
    if test "$ANGULO" = grados; then
        ang=$(calc "($ang) * 180 / p")
    fi

    return 0
}

function polares_a_rectangulares { 
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
    if [ $? != 0 ]; then
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
    if [ $? != 0 ]; then
        return 1
    fi

    rectangulares_a_polares $x $y
    return 0
}

function MultiplicaRectangulares {
    if [ $# != 4 ]; then
        error "MultiplicaRectangulares necesita 4 parámetros." 
        return 1 
    fi

    rectangulares_a_polares $1 $2
    local m1=$r
    local a1=$ang

    rectangulares_a_polares $3 $4
    local m2=$r
    local a2=$ang

    MultiplicaPolares $m1 $a1 $m2 $a2
    if [ $? != 0 ]; then
       return 1
    fi

    polares_a_rectangulares $r $ang

    return 0
}

function MultiplicaPolares {
    if [ $# != 4 ]; then
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
        error "DivideRectangulares necesita 4 parámetros." 
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
    local TR_X=$(fmt "$1")
    local TR_Y=$(fmt "$2")
    case $TR_Y in
        -*) echo "$TR_X$TR_Y"i ;;     # la imaginaria ya trae el "-"
        *)  echo "$TR_X+$TR_Y"i ;;    # hay que poner el "+"
    esac
}

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
        NZ_M=$(calc "p")
    fi

    local NZ_V=$(calc "2 * $NZ_M")                 # una vuelta completa

    while mayor "$NZ_A" "$NZ_M"; do                # mientras ang > media vuelta
        NZ_A=$(calc "$NZ_A - $NZ_V")               #le quito una vuelta
    done
    until mayor "$NZ_A" "-$NZ_M"; do               # hasta que ang > -media vuelta
        NZ_A=$(calc "$NZ_A + $NZ_V")               #le añado una vuelta
    done

    ANG=$NZ_A

    return 0
}

# es_cero valor
#   Devuelve 0 (éxito) si el valor es exactamente 0, aunque se escriba 0.0 o -0.
function es_cero {
    test "$(echo "z = 0; if (($1) == 0) z = 1; z" | bc -l)" = 1
}


# fmt valor
#   Redondea "valor" a DECIMALES decimales y lo escribe. 
function fmt {
    local F_CERO=$(printf "%.${DECIMALES}f" 0)     #el cero con DECIMALES decimales (0.0000, 0.00...)
    case $(printf "%.${DECIMALES}f" "$1") in
        "-$F_CERO") echo "$F_CERO" ;;               #si sale -0.0000 lo cambio por 0.0000
        *)          printf "%.${DECIMALES}f\n" "$1" ;;
    esac
}

# comprueba_numeros n1 n2 ...
#   Comprueba que todos los argumentos son números válidos (con es_numero).
#   Devuelve 0 si lo son y 1 si alguno no lo es, avisando con error.
function CompruebaNumeros {
    while [ $# != 0 ]; do #mientras el total de parametros(que ira quitando uno por el shift al final de cada iteracion) no sea 0 seguimos verificando
        case $1 in
            +*) error "'$1': no se admite el signo + delante"
            return 1 ;; #sino se genera un bucle infinito
        esac
        if ! es_numero "$1"; then #el ! invierte el resultado: entra si es_numero falla (no es un número)
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
                error "Necesitas 2 parametros"
                return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                return 2
            fi
            
            rectangulares_a_polares "$1" "$2"
            texto_polares "$r" "$ang"
        ;;

        "-r") #llamar a polares_a_rectangulares, 2 argumentos
            if [ $# != 2 ]; then
                error "Necesitas 2 parametros"
                return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                return 2
            fi
            polares_a_rectangulares "$1" "$2"
            texto_rectangulares "$x" "$y"
        ;;

        "-sr") #llamar a SumaRectangulares, 4 argumentos
            if [ $# != 4 ]; then
                error "Necesitas 4 parametros"
                return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                return 2
            fi
            SumaRectangulares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_rectangulares "$x" "$y"
        ;;

        "-sp") #llamar a SumaPolares, 4 argumentos
            if [ $# != 4 ]; then
                error "Necesitas 4 parametros"
                return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                return 2
            fi
            SumaPolares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_polares "$r" "$ang"
        ;;

        "-rr") #llamar a RestaRectangulares, 4 argumentos
            if [ $# != 4 ]; then
                    error "Necesitas 4 parametros"
                    return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                    return 2
            fi
            RestaRectangulares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_rectangulares "$x" "$y"
        ;;

        "-rp") #llamar a RestaPolares, 4 argumentos
            if [ $# != 4 ]; then
                    error "Necesitas 4 parametros"
                    return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                    return 2
            fi
            RestaPolares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_polares "$r" "$ang"
        ;;

        "-mr") #llamar a MultiplicaRectangulares, 4 argumentos
            if [ $# != 4 ]; then
                    error "Necesitas 4 parametros"
                    return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                    return 2
            fi
            MultiplicaRectangulares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_rectangulares "$x" "$y"
        ;;

        "-mp") #llamar a MultiplicaPolares, 4 parametros
            if  [ $# != 4 ]; then
                    error "Necesitas 4 parametros"
                    return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                    return 2
            fi
            MultiplicaPolares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_polares "$r" "$ang"
        ;;

        "-dr") #llamar a DivideRectangulares, 4 parametros
            if  [ $# != 4 ]; then
                    error "Necesitas 4 parametros"
                    return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                    return 2
            fi
            DivideRectangulares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_rectangulares "$x" "$y"
        ;;

        "-dp") #llamar a DividePolares, 4 parametros
            if  [ $# != 4 ]; then
                    error "Necesitas 4 parametros"
                    return 2
            fi
            if ! CompruebaNumeros "$@" ; then
                    return 2
            fi
            DividePolares $1 $2 $3 $4
            if [ $? -ne 0 ]; then
                return 1
            fi
            texto_polares "$r" "$ang"
        ;;

        "-h") #abrir Ayuda, 0 parametros
            if [ $# != 0 ]; then
                error "No se le pueden pasar parámetros a -h"
                return 2
            fi
            uso
        ;;

        *)
            error "Opción no valida"
            return 2
        ;;
        esac
}


# recorta "texto"
#   Deja en Recortado el texto sin espacios al principio ni al final.
function Recorta {
    local cadena="$1"
    local longitud=${#cadena}

    if [ -z "$cadena" ]; then #-z si la cadena esta vacia
        Recortado=""
        return 0
    fi

    while [ "${cadena:0:1}" = " " ]; do #ver si el primero es espacio y quitarlo
        cadena="${cadena:1}"
    done


    longitud=${#cadena} #guardar la longitud

    while  mayor "$longitud" 0 && [ "${cadena:$((longitud - 1)):1}" = " " ]; do #ver si la longitud es mayor que 0 junto a que el ultimo espacio sea un 0
        longitud=$((longitud - 1))
        cadena="${cadena:0:$longitud}" #le quitamos el ultimo espacio
    done

    Recortado="$cadena" 
}

# parse_operando "texto"
#   Analiza un complejo escrito como "a+bi" (o con j), "bi", real puro o
#   polar "mod arg". Deja el tipo en P_T (r o p) y los valores en P_A y P_B.
#   Devuelve 1 si el texto no es un complejo válido.
function parse_operando {
    local original=$1
    local texto cuerpo inicial num resto

    Recorta "$1"
    texto="$Recortado"

    case $texto in
        *[ij])                                   # ACABA EN i O j: RECTANGULAR
            cuerpo=${texto%?}                    # se quita la i o la j del final
            case $cuerpo in                      # si empieza por signo, se aparta y se guarda en inicial
                [+-]*) inicial=${cuerpo%"${cuerpo#?}"}; cuerpo=${cuerpo#?} ;;
                *)     inicial= ;;
            esac
            
            num=${cuerpo##*[+-]}                 # lo que hay detras del ultimo signo
            if [ "$num" = "$cuerpo" ]; then      # no hay signo en medio: "3i"
                P_A=0
                P_B=$inicial$num
            else                                 # hay signo en medio: "2+3i"
                resto=${cuerpo%"$num"}           # "2+"
                P_A=$inicial${resto%?}           # "2"
                P_B=${resto#"${resto%?}"}$num    # "+3"
            fi
            case $P_B in                         # "i" equivale a "1i"
                ""|"+"|"-") P_B=${P_B}1 ;;
            esac
            P_T=r
            ;;
        *" "*)                                   # TIENE UN ESPACIO: POLAR "mod arg"
            P_A=${texto%% *} #se guarda mod
            Recorta "${texto#* }" #puede haber espacios por lo que se recorta el resto
            P_B=$Recortado
            P_T=p
            ;;
        *)                                       # NINGUNA DE LAS DOS: real puro RECTANGULAR
            P_A=$texto
            P_B=0
            P_T=r
            ;;
    esac
 
    es_numero "$P_A"
    if [ $? -ne 0 ]; then
        error "operando no válido: '$original'"
        return 1
    fi
    es_numero "$P_B"
    if [ $? -ne 0 ]; then
        error "operando no válido: '$original'"
        return 1
    fi
 
    P_A=${P_A#+}                                 # bc no entiende un + delante
    P_B=${P_B#+}
    return 0
   
}

# evalua_expresion "(op1)operador(op2)"
#   Separa los dos operandos y el operador, calcula y escribe
#   "expresión = resultado". Si los dos operandos son polares el resultado
#   sale en polares; en cualquier otro caso, en rectangulares.
function evalua_expresion {
    local expresion
    Recorta "$1"
    expresion=$Recortado

    local x1 y1 x2 y2 

    local temp="${expresion#*(}" #aislamos cortando todo antes del 1 parentesis (
    local ope1="${temp%%)*}" #aislamos cortando todo despues del 1 parentesis ), o lo que es lo mismo, quitar todo despues del ultimo ) empezando por la izquierda

    local resto="${expresion#*)}" #dejo solo el operador y el 2 operando
    Recorta "$resto" #quito los espacios que pueda haber antes del operador
    resto=$Recortado
    local operador="${resto:0:1}" #cojo el primer caracter del resto que es el operador

    temp="${resto#*(}" #elimino todo antes del primer (
    local ope2="${temp%)*}" #elimino todo despues del ultimo parentesis(el parentesis incluido)

    local esPolar1=false
    local esPolar2=false

    parse_operando "$ope1"
    if [ $? != 0 ]; then
     return 1
    fi
    x1="$P_A"
    y1="$P_B"
    if [ "$P_T" = p ]; then #parse_operando deja en P_T si es polar (p) o rectangular (r)
        esPolar1=true
    fi

    parse_operando "$ope2"
    if [ $? != 0 ]; then
        return 1
     fi
    x2="$P_A"
    y2="$P_B"
    if [ "$P_T" = p ]; then #parse_operando deja en P_T si es polar (p) o rectangular (r)
        esPolar2=true
    fi
    
    if [ "$esPolar1" = true ] && [ "$esPolar2" = true ]; then
    case "$operador" in
        "+") EjecutaOpcion -sp "$x1" "$y1" "$x2" "$y2"
        ;;
        "-") EjecutaOpcion -rp "$x1" "$y1" "$x2" "$y2"
        ;;
        "*") EjecutaOpcion -mp "$x1" "$y1" "$x2" "$y2"
        ;;
        "/") EjecutaOpcion  -dp "$x1" "$y1" "$x2" "$y2"
        ;;
        *) error "operador no válido en '$1'"
        return 1 
        ;;
    esac
    else
        if [ "$esPolar1" = true ]; then
            polares_a_rectangulares "$x1" "$y1"
            x1="$x"
            y1="$y"
        fi
        
        if [ "$esPolar2" = true ]; then 
            polares_a_rectangulares "$x2" "$y2"
            x2="$x"
            y2="$y"
        fi

        case "$operador" in
            "+") EjecutaOpcion -sr "$x1" "$y1" "$x2" "$y2"
            ;;
            "-") EjecutaOpcion -rr "$x1" "$y1" "$x2" "$y2"
            ;;
            "*") EjecutaOpcion -mr "$x1" "$y1" "$x2" "$y2"
            ;;
            "/") EjecutaOpcion  -dr "$x1" "$y1" "$x2" "$y2"
            ;;
            *) error "operador no válido en '$1'"
            return 1
            ;;
        esac
    fi 

}

# procesa_linea "línea"
#   Trata una línea del fichero. Ignora las vacías y las que empiezan por #,
#   cambia la unidad con "grados" o "radianes" y evalúa el resto.

function procesa_linea {
    Recorta "$1"
    local linea="$Recortado"
    
    case "$linea" in
        "") return 0 ;; # línea vacía
        "#"*) return 0 ;; # comentario
        "grados"|"Grados"|"GRADOS") ANGULO=grados; return 0 ;;
        "radianes"|"Radianes"|"RADIANES") ANGULO=radianes; return 0 ;;
        *) evalua_expresion "$linea" 
            if [ $? -ne 0 ]; then
                error "línea $2: no se pudo realizar la operación"
                return 1
            fi;;
    esac
    
    return 0
}


# procesa_fichero fichero
#   Lee el fichero línea a línea y llama a procesa_linea con cada una.
#   Devuelve 0 si todas fueron bien, 1 si alguna línea dio error y
#   2 si el fichero no existe o no se puede leer.

function procesa_fichero {
    local fichero="$1"

    # Validar que se ha pasado una ruta y que el fichero existe y es legible
    if [ -z "$fichero" ] || [ ! -f "$fichero" ] || [ ! -r "$fichero" ]; then #1.falta el nombre del fichero, 2. no existe, 3. no se puede leer
        error "El fichero '$fichero' no existe o no se puede leer."
        return 2
    fi

    local LINEA
    local n=0           # número de línea
    local errores=0     # líneas que han fallado

    while read -r LINEA; do    # lee una línea cada vuelta
        n=$((n + 1))                       # sube el contador de línea
        procesa_linea "$LINEA" "$n"
        if [ $? -ne 0 ]; then
            errores=$((errores + 1))           
        fi
    done < "$fichero" # lee el fichero línea a línea y lo manda al bucle

    # Si la última línea no acaba en Enter, read la deja en LINEA pero el
    # bucle termina sin procesarla: se trata aquí
    if [ -n "$LINEA" ]; then #si la línea no está vacía, la procesa
        n=$((n + 1))
        procesa_linea "$LINEA" "$n"
        if [ $? -ne 0 ]; then
            errores=$((errores + 1))
        fi
    fi

    # Si hay errores, devolvemos 1
    if [ $errores -ne 0 ]; then
        return 1
    fi
    return 0
}


# ===== PROGRAMA PRINCIPAL =====

# 1. Unidad de los ángulos (opcional, siempre el primer argumento)
case $1 in
    -grad) ANGULO=grados;   shift ;;
    -rad)  ANGULO=radianes; shift ;;
esac

# 2. No se pueden poner -grad y -rad a la vez
case $1 in
    -grad|-rad)
        error "no se pueden usar -grad y -rad a la vez"
        exit 2
        ;;
esac

# 3. Se decide qué se pide: fichero, expresión matemática u opción
case $1 in
    -f)                                  # -f fichero
        if [ $# -ne 2 ]; then
            error "uso: $NOMBRE [-grad|-rad] -f fichero"
            exit 2
        fi
        procesa_fichero "$2"
        exit $?
        ;;
    "("*)                                # "(a+bi)op(c+di)"
        if [ $# -ne 1 ]; then
            error "la expresión debe ir entre comillas y sola"
            exit 2
        fi
        evalua_expresion "$1"
        exit $?
        ;;
    *)                                   # -p, -r, -sr, ..., -h
        EjecutaOpcion "$@"
        exit $?
        ;;
esac