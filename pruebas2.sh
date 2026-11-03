#!/bin/bash
# =====================================================================
# pruebas.sh - Batería de pruebas de complejo.sh (lo muestra TODO)
#
#   bash pruebas.sh            muestra cada prueba: comando, salida,
#                              código de salida y si está bien o mal
#   bash pruebas.sh -fallos    muestra solo las pruebas que fallan
#   bash pruebas.sh | less     para leerlo con calma (q para salir)
#
# Se ejecuta en la misma carpeta que complejo.sh.
# =====================================================================

SCRIPT=./complejo.sh
SOLO_FALLOS=no
if [ "$1" = "-fallos" ]; then SOLO_FALLOS=si; fi

OK=0; MAL=0; N=0; INFO=0; EXTRA=""
LISTA_FALLOS=""
TMPD=./_tmp_pruebas_$$            # carpeta temporal (se borra al final)
mkdir "$TMPD" || exit 1

# Escribe el comando como se teclearía en la terminal
cmd_texto() {
    local a txt="./complejo.sh"
    for a in "$@"; do
        case $a in
            ""|*[\ \(\)\*\<\>\|\&\;]*) txt="$txt \"$a\"" ;;
            *)                        txt="$txt $a" ;;
        esac
    done
    echo "$txt"
}

# Ejecuta complejo.sh y deja la salida (normal + errores) en SALIDA y el código en RC
ejecuta() {
    SALIDA=$(bash "$SCRIPT" "$@" 2>&1)
    RC=$?
    SALIDA=${SALIDA//complejo.sh: /}        # se quita el nombre del script de los errores
}

# Muestra una salida con sangría
sangra() {
    if [ -z "$1" ]; then echo "        (sin salida)"; else echo "$1" | sed 's/^/        /'; fi
}

# Decide si la prueba está bien y lo muestra
#   esperado normal: la salida tiene que ser exactamente esa
#   esperado "~texto": la salida tiene que CONTENER ese texto
# coincide "esperado" código  -> 0 si SALIDA y RC son los esperados
coincide() {
    if [ "$RC" != "$2" ]; then return 1; fi
    case $1 in
        "~"*) case $SALIDA in *"${1#\~}"*) return 0 ;; esac; return 1 ;;
        *)    [ "$SALIDA" = "$1" ] ;;
    esac
}

juzga() {
    local desc=$1 esperado=$2 rc_esperado=$3 comando=$4 bien=no
    N=$((N + 1))
    if coincide "$esperado" "$rc_esperado"; then bien=si; fi

    if [ $bien = si ]; then
        OK=$((OK + 1))
        if [ $SOLO_FALLOS = si ]; then EXTRA=""; return; fi
        echo "[  OK  ] $N. $desc"
    else
        MAL=$((MAL + 1))
        LISTA_FALLOS="$LISTA_FALLOS
   $N. $desc   ->   $comando"
        echo "[FALLO ] $N. $desc"
    fi
    if [ -n "$EXTRA" ]; then echo "$EXTRA"; EXTRA=""; fi
    echo "        \$ $comando"
    sangra "$SALIDA"
    echo "        código de salida: $RC"
    if [ $bien = no ]; then
        echo "        ---- se esperaba ----"
        case $esperado in
            "~"*) echo "        que la salida contenga: ${esperado#\~}" ;;
            *)    sangra "$esperado" ;;
        esac
        echo "        código de salida: $rc_esperado"
    fi
    echo
}

# prueba "descripción" "salida esperada" código argumentos...
prueba() {
    local desc=$1 esperado=$2 rc=$3
    shift 3
    ejecuta "$@"
    juzga "$desc" "$esperado" "$rc" "$(cmd_texto "$@")"
}

# prueba_f "descripción" "salida esperada" código "contenido del fichero" [opciones...]
#   crea un fichero con ese contenido, lo enseña y ejecuta  complejo.sh [opciones] -f fichero
prueba_f() {
    local desc=$1 esperado=$2 rc=$3 contenido=$4
    shift 4
    local f="$TMPD/operaciones.txt"
    printf "%b" "$contenido" > "$f"
    ejecuta "$@" -f "$f"
    SALIDA=${SALIDA//$TMPD\//}
    EXTRA="        contenido de operaciones.txt (\$ = fin de línea, ^M = \\r):
$(cat -vet "$f" | sed 's/^/          | /')"
    case $contenido in
        *'\n'|"") ;;
        *) EXTRA="$EXTRA
          (la última línea NO acaba en Enter)" ;;
    esac
    if [ ! -s "$f" ]; then EXTRA="        (fichero vacío)"; fi
    juzga "$desc" "$esperado" "$rc" "$(cmd_texto "$@" -f) operaciones.txt"
    rm -f "$f"
}

# info "descripción" argumentos...   -> solo enseña lo que pasa, no cuenta como bien ni mal
info() {
    local desc=$1
    shift
    ejecuta "$@"
    INFO=$((INFO + 1))
    if [ $SOLO_FALLOS = si ]; then return; fi
    echo "[ INFO ] $desc"
    echo "        \$ $(cmd_texto "$@")"
    sangra "$SALIDA"
    echo "        código de salida: $RC"
    echo
}

seccion() {
    if [ $SOLO_FALLOS = si ]; then return; fi
    echo
    echo "======================================================================"
    echo "  $1"
    echo "======================================================================"
}

# ---------------------------------------------------------------------
seccion "0. COMPROBACIONES PREVIAS"
if [ ! -f "$SCRIPT" ]; then
    echo "[FALLO ] No hay ningún complejo.sh en esta carpeta ($(pwd))."
    exit 1
fi
CR=$(grep -c $'\r' "$SCRIPT")
if [ "$CR" != 0 ]; then
    echo "[FALLO ] complejo.sh tiene $CR líneas con CRLF (formato Windows): en Linux NO se ejecuta."
    echo "         Arréglalo con:   sed -i 's/\\r\$//' complejo.sh"
    echo "         o en VS Code: abajo a la derecha, CRLF -> LF, y guardar."
    rmdir "$TMPD"
    exit 1
fi
echo "[  OK  ] complejo.sh en formato LF ($(( $(wc -l < "$SCRIPT") )) líneas, $(( $(wc -c < "$SCRIPT") )) bytes)"
if bash -n "$SCRIPT" 2>/dev/null; then echo "[  OK  ] sin errores de sintaxis"; else echo "[FALLO ] errores de sintaxis:"; bash -n "$SCRIPT"; rmdir "$TMPD"; exit 1; fi
if command -v bc >/dev/null; then echo "[  OK  ] bc instalado en $(command -v bc)"; else echo "[FALLO ] no está bc"; rmdir "$TMPD"; exit 1; fi
echo "[ INFO ] sistema: $(uname -s -r)    bash: $BASH_VERSION"

# complejo.sh tiene que terminar: si en 15 s no acaba "-p 2 3", se ha quedado colgado
bash "$SCRIPT" -p 2 3 > "$TMPD/x" 2>&1 &
PID=$!
ESPERA=0
while kill -0 $PID 2>/dev/null && [ $ESPERA -lt 15 ]; do sleep 1; ESPERA=$((ESPERA + 1)); done
if kill -0 $PID 2>/dev/null; then
    kill $PID 2>/dev/null
    echo "[FALLO ] './complejo.sh -p 2 3' no termina (lleva 15 s): se ha quedado colgado."
    echo "         Lo que había escrito:"; sed 's/^/           /' "$TMPD/x" | head -5
    echo "         Si este bc es el de Unix clásico (POSIX), no admite variables de varias"
    echo "         letras (pi) ni comparaciones sueltas como  (1) > (0)."
    rm -f "$TMPD/x"; rmdir "$TMPD"
    exit 1
fi
echo "[  OK  ] './complejo.sh -p 2 3' termina: $(cat "$TMPD/x")"
rm -f "$TMPD/x"
if [ -x "$SCRIPT" ]; then echo "[  OK  ] tiene permiso de ejecución"; else echo "[ AVISO] no tiene permiso de ejecución: haz  chmod +x complejo.sh"; fi

# ---------------------------------------------------------------------
seccion "1. EJEMPLOS EXACTOS DEL ENUNCIADO (apartado i.1)"
prueba "rectangulares -> polares"     "3.6056_56.3099 grados"    0  -p 2 3
prueba "polares -> rectangulares"     "1.7321+1.0000i"           0  -r 2 30
prueba "suma rectangulares"           "3.0000+3.0000i"           0  -sr 1 1 2 2
prueba "suma polares"                 "3.0000_45.0000 grados"    0  -sp 1 45 2 45
prueba "resta rectangulares"          "-1.0000-1.0000i"          0  -rr 1 1 2 2
prueba "resta polares"                "1.0000_-135.0000 grados"  0  -rp 1 45 2 45
prueba "multiplica rectangulares"     "0.0000+4.0000i"           0  -mr 1 1 2 2
prueba "multiplica polares"           "2.0000_90.0000 grados"    0  -mp 1 45 2 45
prueba "divide rectangulares"         "0.5000+0.0000i"           0  -dr 1 1 2 2
prueba "divide polares"               "0.5000_0.0000 grados"     0  -dp 1 45 2 45
prueba "ayuda"                        "~Uso:"                    0  -h

seccion "2. FICHERO EXACTO DEL ENUNCIADO (apartado i.2)"
prueba_f "opComplejos.txt del PDF" "5.0000+1.0000i
-11.0000-24.0000i
0.4000_135.0000 grados
4.0000_90.0000 grados" 0 '(2+3i)+(3-2i)\n(10-20j)-(21+4j)\n(4 45)/(10 -90)\n(2 45)*(2 45)\n'

# ---------------------------------------------------------------------
seccion "3. CONVERSIONES EN LOS CUATRO CUADRANTES Y LOS EJES"
prueba "2.o cuadrante"                "1.4142_135.0000 grados"   0  -p -1 1
prueba "3.er cuadrante"               "1.4142_-135.0000 grados"  0  -p -1 -1
prueba "4.o cuadrante"                "1.4142_-45.0000 grados"   0  -p 1 -1
prueba "eje +y"                       "4.0000_90.0000 grados"    0  -p 0 4
prueba "eje -y"                       "4.0000_-90.0000 grados"   0  -p 0 -4
prueba "eje -x"                       "3.0000_180.0000 grados"   0  -p -3 0
prueba "origen"                       "0.0000_0.0000 grados"     0  -p 0 0
prueba "decimales sin 0 delante"      "0.7071_45.0000 grados"    0  -p .5 .5
prueba "polar a 180 grados"           "-1.0000+0.0000i"          0  -r 1 180
prueba "polar a -90 grados"           "0.0000-3.0000i"           0  -r 3 -90
prueba "ángulo de más de una vuelta"  "1.7321+1.0000i"           0  -r 2 390
prueba "módulo negativo"              "-1.7321-1.0000i"          0  -r -2 30

# ---------------------------------------------------------------------
seccion "4. OPERACIONES"
prueba "suma con decimales y negativos"  "3.0000+2.0000i"          0  -sr 2.5 -1 0.5 3
prueba "suma polar (triángulo 3-4-5)"    "5.0000_36.8699 grados"   0  -sp 3 90 4 0
prueba "resta polar"                     "5.0000_143.1301 grados"  0  -rp 3 90 4 0
prueba "multiplica (2+3i)(3-2i)"         "12.0000+5.0000i"         0  -mr 2 3 3 -2
prueba "multiplica polar, pasa de 180"   "6.0000_-160.0000 grados" 0  -mp 2 100 3 100
prueba "multiplica polar, da 180 justo"  "6.0000_180.0000 grados"  0  -mp 2 90 3 90
prueba "multiplica polar, da -180"       "1.0000_180.0000 grados"  0  -mp 1 -90 1 -90
prueba "multiplica polar con decimales"  "3.3750_0.0000 grados"    0  -mp 1.5 0 2.25 0
prueba "divide (1+i)/(1-i)"              "0.0000+1.0000i"          0  -dr 1 1 1 -1
prueba "divide 1/3"                      "0.3333+0.0000i"          0  -dr 1 0 3 0
prueba "divide polar"                    "0.4000_135.0000 grados"  0  -dp 4 45 10 -90
prueba "cero entre algo"                 "0.0000+0.0000i"          0  -dr 0 0 1 1

# ---------------------------------------------------------------------
seccion "5. AMPLIACIÓN 2: -grad Y -rad"
prueba "-grad explícito"              "1.4142_135.0000 grados"   0  -grad -p -1 1
prueba "-rad rect -> polar"           "1.4142_2.3562 radianes"   0  -rad -p -1 1
prueba "-rad polar -> rect"           "1.7320+1.0000i"           0  -rad -r 2 0.5236
prueba "-rad suma polar"              "3.0000_0.7854 radianes"   0  -rad -sp 1 0.7854 2 0.7854
prueba "-rad multiplica, pasa de pi"  "6.0000_-0.2832 radianes"  0  -rad -mp 2 3 3 3

# ---------------------------------------------------------------------
seccion "6. AMPLIACIÓN 1: NOTACIÓN MATEMÁTICA EN LA LÍNEA DE COMANDOS"
prueba "suma"                         "5.0000+1.0000i"           0  "(2+3i)+(3-2i)"
prueba "resta con j"                  "-11.0000-24.0000i"        0  "(10-20j)-(21+4j)"
prueba "multiplica"                   "12.0000+5.0000i"          0  "(2+3i)*(3-2i)"
prueba "divide"                       "3.0000+4.0000i"           0  "(10+5i)/(2-1i)"
prueba "divide polares"               "0.4000_135.0000 grados"   0  "(4 45)/(10 -90)"
prueba "multiplica polares"           "4.0000_90.0000 grados"    0  "(2 45)*(2 45)"
prueba "rectangular por polar"        "-2.8284+14.1421i"         0  "(2+3i)*(4 45)"
prueba "solo imaginaria y real puro"  "4.0000+3.0000i"           0  "(3i)+(4)"
prueba "i por i"                      "-1.0000+0.0000i"          0  "(i)*(i)"
prueba "-i más i"                     "0.0000+0.0000i"           0  "(-i)+(i)"
prueba "signo + delante del operando" "5.0000+1.0000i"           0  "(2+3i)+(+3-2i)"
prueba "varios espacios en polar"     "2.0000_0.0000 grados"     0  "(4   45)/(2 45)"
prueba "-rad con polares"             "0.4000_2.3500 radianes"   0  -rad "(4 0.78)/(10 -1.57)"

# ---------------------------------------------------------------------
seccion "7. FICHEROS (-f) Y AMPLIACIÓN 3: grados / radianes DENTRO DEL FICHERO"
prueba_f "vacías, comentarios y cambio de unidad" "5.0000+1.0000i
4.0000_1.0000 radianes
6.0000_180.0000 grados" 0 '# comentario\n\n   \n(2+3i)+(3-2i)\nradianes\n(2 0.5)*(2 0.5)\ngrados\n(2 90)*(3 90)\n'
prueba_f "-rad: el fichero empieza en radianes" "0.4000_2.3500 radianes" 0 '(4 0.78)/(10 -1.57)\n' -rad
prueba_f "última línea sin Enter" "5.0000+1.0000i
2.0000+0.0000i" 0 '(2+3i)+(3-2i)\n(1+i)+(1-i)'
prueba_f "tabuladores y espacios al principio y al final" "2.0000+0.0000i" 0 '\t  (1+i)+(1-i)  \t\n'
prueba_f "una línea mala: avisa con su número, sigue y devuelve 1" "5.0000+1.0000i
error: operando no válido: '2+a'
error: línea 2: no se pudo realizar la operación
2.0000+0.0000i" 1 '(2+3i)+(3-2i)\n(2+a)+(1)\n(1+i)+(1-i)\n'
prueba_f "división entre cero en el fichero" "~línea 1:" 1 '(5)/(0)\n(1+i)+(1-i)\n'
prueba_f "fichero vacío" "" 0 ''
prueba_f "fichero solo con comentarios" "" 0 '# nada\n# que hacer\n'

# ---------------------------------------------------------------------
seccion "8. CONTROL DE ARGUMENTOS"
prueba "sin argumentos: muestra la ayuda"     "~Uso:"                       2
prueba "-rad solo: muestra la ayuda"          "~Uso:"                       2  -rad
prueba "opción que no existe"                 "~error"                      2  -x 1 2
prueba "-h con parámetros"                    "~error"                      2  -h 1
prueba "-grad y -rad juntos"                  "~a la vez"                   2  -grad -rad -p 1 1
prueba "-rad y -grad juntos"                  "~a la vez"                   2  -rad -grad -p 1 1
prueba "-p sin operandos"                     "~Necesitas 2"                2  -p
prueba "-p con 1 operando"                    "~Necesitas 2"                2  -p 1
prueba "-p con 3 operandos"                   "~Necesitas 2"                2  -p 1 2 3
prueba "-sr con 3 operandos"                  "~Necesitas 4"                2  -sr 1 2 3
prueba "-sr con 5 operandos"                  "~Necesitas 4"                2  -sr 1 2 3 4 5
prueba "-grad/-rad detrás de la opción"       "~Necesitas 2"                2  -p 1 1 -rad
prueba "letra en vez de número"               "~no es un número válido"     2  -p a 3
prueba "letra en el 3.er operando"            "~no es un número válido"     2  -sr 1 2 x 4
prueba "número con dos puntos"                "~no es un número válido"     2  -p 1.2.3 4
prueba "número con exponente"                 "~no es un número válido"     2  -p 1e3 4
prueba "número con coma decimal"              "~no es un número válido"     2  -p 3,5 4
prueba "operando vacío"                       "~no es un número válido"     2  -p "" 4
prueba "solo un signo"                        "~no es un número válido"     2  -p - 4
prueba "-f sin fichero"                       "~uso:"                       2  -f
prueba "-f con dos ficheros"                  "~uso:"                       2  -f a b
prueba "-f fichero que no existe"             "~no existe"                  2  -f noexiste.txt
prueba "-f con un directorio"                 "~no existe"                  2  -f /tmp
prueba "expresión partida en dos argumentos"  "~entre comillas"             2  "(1+i)+(2)" "(3)"
if [ "$EUID" != 0 ]; then
    printf '(1+i)+(1-i)\n' > "$TMPD/noleer.txt"; chmod 000 "$TMPD/noleer.txt"
    ejecuta -f "$TMPD/noleer.txt"; SALIDA=${SALIDA//$TMPD\//}
    juzga "-f fichero sin permiso de lectura" "~no se puede leer" 2 "./complejo.sh -f noleer.txt (chmod 000)"
    rm -f "$TMPD/noleer.txt"
fi

# ---------------------------------------------------------------------
seccion "9. COMPROBACIÓN LÓGICA DE ERRORES"
prueba "divide polar entre módulo 0"          "~dividir entre cero"   1  -dp 4 45 0 10
prueba "divide rect entre 0+0i"               "~dividir entre cero"   1  -dr 1 1 0 0
prueba "divide entre 0.0 y -0.000"            "~dividir entre cero"   1  -dr 1 1 0.0 -0.000
prueba "expresión: divide entre 0"            "~dividir entre cero"   1  "(5)/(0)"
prueba "expresión: operador que no existe"    "~operador no válido"   1  "(2+3i)x(3-2i)"
prueba "expresión: operador ^"                "~operador no válido"   1  "(2+3i)^(1)"
prueba "expresión: letras en el operando"     "~operando no válido"   1  "(2+a)+(1)"
prueba "expresión: rectangular sin i"         "~operando no válido"   1  "(2+3)+(1)"
prueba "expresión: polar con 3 números"       "~operando no válido"   1  "(4 45 3)+(1)"
prueba "expresión: i mayúscula"               "~operando no válido"   1  "(2+3I)+(1)"
prueba "expresión: paréntesis vacíos"         "~error"                1  "()+()"
prueba "expresión: un solo operando"          "~error"                1  "(2+3i)"
prueba "expresión: tres operandos"            "~error"                1  "(1+2i)+(2+3i)+(3+4i)"

# ---------------------------------------------------------------------
seccion "10. CASOS LÍMITE (los fallos que encontramos)"
prueba "+ delante en -p"                      "5.0000_53.1301 grados"   0  -p +3 4
prueba "+ delante en -sr"                     "4.0000+6.0000i"          0  -sr +1 +2 3 4
prueba "+ delante en -r"                      "1.7321+1.0000i"          0  -r +2 +30
prueba "+ delante en -dp"                     "2.0000_45.0000 grados"   0  -dp +4 45 2 0
prueba "espacio dentro del paréntesis (1)"    "3.0000+3.0000i"          0  "( 2+3i)+(1)"
prueba "espacio dentro del paréntesis (2)"    "2.0000+3.0000i"          0  "(2+3i )*(1)"
prueba "espacio dentro del paréntesis (3)"    "7.0000-1.0000i"          0  "(5)+( 2-1i)"
prueba "espacio dentro de un polar"           "8.0000_90.0000 grados"   0  "( 4 45)*(2 45)"
prueba "espacios alrededor del operador"      "5.0000+1.0000i"          0  "(2+3i) + (3-2i)"
prueba_f "espacios dentro y fuera en un fichero" "5.0000+1.0000i
5.0000+1.0000i" 0 '(2+3i) + (3-2i)\n( 2+3i )+( 3-2i )\n'

# ---------------------------------------------------------------------
seccion "11. SOLO INFORMATIVO (no cuenta: decidido no tratarlo o es opcional)"
info "paréntesis sin cerrar"                  "(2+3i)+(3-2i"
info "falta el ( del 2.o operando"            "(2+3i)+3-2i)"
info "basura detrás de la expresión"          "(2+3i)+(3-2i)xyz"
info "espacio antes del primer paréntesis"    " (1+i)+(1-i)"
info "resultado cero en polares (ángulo)"     "(1 0)+(1 180)"
info "módulo negativo en polares"             -mp -2 30 3 40
printf '(2+3i)+(3-2i)\r\nradianes\r\n(2 0.5)*(2 0.5)\r\n' > "$TMPD/crlf.txt"
info "fichero de datos con CRLF (hecho en Windows)" -f "$TMPD/crlf.txt"
rm -f "$TMPD/crlf.txt"

# ---------------------------------------------------------------------
rmdir "$TMPD" 2>/dev/null
echo
echo "======================================================================"
echo "  RESUMEN:  $N pruebas  ->  $OK correctas,  $MAL con fallo   ($INFO solo informativas)"
echo "======================================================================"
if [ $MAL != 0 ]; then
    echo "  Pruebas que fallan:$LISTA_FALLOS"
    echo
fi
[ $MAL = 0 ]