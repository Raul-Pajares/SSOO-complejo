#!/bin/bash
# pruebas.sh - Batería de pruebas para complejo.sh
# Uso (desde la carpeta donde está complejo.sh):   bash pruebas.sh
# Cada prueba compara la salida y el código de salida con lo esperado.

SCRIPT=./complejo.sh
OK=0
MAL=0

# prueba "descripción" "salida esperada" "código esperado" argumentos...
prueba() {
    local desc=$1 esperado=$2 rc_esperado=$3
    shift 3
    local salida rc
    salida=$($SCRIPT "$@" 2>&1)
    rc=$?
    # se quita el nombre del script de los mensajes de error para comparar
    salida=${salida//complejo.sh: /}
    if [ "$salida" = "$esperado" ] && [ "$rc" = "$rc_esperado" ]; then
        OK=$((OK + 1))
        printf "  OK     %-34s %s\n" "$desc" "$*"
    else
        MAL=$((MAL + 1))
        printf "  FALLO  %-34s %s\n" "$desc" "$*"
        printf "         esperado: [%s] rc=%s\n" "$esperado" "$rc_esperado"
        printf "         obtenido: [%s] rc=%s\n" "$salida" "$rc"
    fi
}

# prueba_rc "descripción" código_esperado argumentos...   (solo mira el código de salida)
prueba_rc() {
    local desc=$1 rc_esperado=$2
    shift 2
    $SCRIPT "$@" >/dev/null 2>&1
    local rc=$?
    if [ "$rc" = "$rc_esperado" ]; then
        OK=$((OK + 1))
        printf "  OK     %-34s %s\n" "$desc" "$*"
    else
        MAL=$((MAL + 1))
        printf "  FALLO  %-34s %s\n" "$desc" "$*"
        printf "         esperado: rc=%s   obtenido: rc=%s\n" "$rc_esperado" "$rc"
    fi
}

# prueba_f "descripción" "salida esperada" código "contenido del fichero" [opciones previas...]
#   Crea un fichero temporal con ese contenido y ejecuta:  complejo.sh [opciones] -f fichero
prueba_f() {
    local desc=$1 esperado=$2 rc_esperado=$3 contenido=$4
    shift 4
    local tmp=./_prueba_tmp.txt
    printf "%b" "$contenido" > "$tmp"
    local salida rc
    salida=$($SCRIPT "$@" -f "$tmp" 2>&1)
    rc=$?
    rm -f "$tmp"
    salida=${salida//complejo.sh: /}
    if [ "$salida" = "$esperado" ] && [ "$rc" = "$rc_esperado" ]; then
        OK=$((OK + 1))
        printf "  OK     %-34s %s\n" "$desc" "-f fichero"
    else
        MAL=$((MAL + 1))
        printf "  FALLO  %-34s %s\n" "$desc" "-f fichero"
        printf "         esperado: [%s] rc=%s\n" "$esperado" "$rc_esperado"
        printf "         obtenido: [%s] rc=%s\n" "$salida" "$rc"
    fi
}

echo "=== CONVERSIONES"
prueba "rect -> polar (1.er cuadrante)"   "3.6056_56.3099 grados"    0  -p 2 3
prueba "rect -> polar (2.o cuadrante)"    "1.4142_135.0000 grados"   0  -p -1 1
prueba "rect -> polar (3.er cuadrante)"   "1.4142_-135.0000 grados"  0  -p -1 -1
prueba "rect -> polar (4.o cuadrante)"    "1.4142_-45.0000 grados"   0  -p 1 -1
prueba "rect -> polar (eje +y)"           "4.0000_90.0000 grados"    0  -p 0 4
prueba "rect -> polar (eje -y)"           "4.0000_-90.0000 grados"   0  -p 0 -4
prueba "rect -> polar (eje -x)"           "3.0000_180.0000 grados"   0  -p -3 0
prueba "rect -> polar (origen)"           "0.0000_0.0000 grados"     0  -p 0 0
prueba "polar -> rect"                    "1.7321+1.0000i"           0  -r 2 30
prueba "polar -> rect (180 grados)"       "-1.0000+0.0000i"          0  -r 1 180
prueba "polar -> rect (modulo negativo)"  "-1.7321-1.0000i"          0  -r -2 30

echo "=== SUMA Y RESTA"
prueba "suma rect"                        "3.0000+3.0000i"           0  -sr 1 1 2 2
prueba "suma rect (decimales y negativos)" "3.0000+2.0000i"          0  -sr 2.5 -1 0.5 3
prueba "suma polar"                       "3.0000_45.0000 grados"    0  -sp 1 45 2 45
prueba "suma polar (3-4-5)"               "5.0000_36.8699 grados"    0  -sp 3 90 4 0
prueba "resta rect"                       "-1.0000-1.0000i"          0  -rr 1 1 2 2
prueba "resta polar"                      "5.0000_143.1301 grados"   0  -rp 3 90 4 0

echo "=== MULTIPLICACION Y DIVISION"
prueba "multiplica rect"                  "0.0000+4.0000i"           0  -mr 1 1 2 2
prueba "multiplica rect (2+3i)(3-2i)"     "12.0000+5.0000i"          0  -mr 2 3 3 -2
prueba "multiplica polar"                 "6.0000_70.0000 grados"    0  -mp 2 30 3 40
prueba "multiplica polar (angulo >180)"   "6.0000_-160.0000 grados"  0  -mp 2 100 3 100
prueba "multiplica polar (decimales)"     "3.3750_0.0000 grados"     0  -mp 1.5 0 2.25 0
prueba "divide rect"                      "0.0000+1.0000i"           0  -dr 1 1 1 -1
prueba "divide rect (1/3)"                "0.3333+0.0000i"           0  -dr 1 0 3 0
prueba "divide polar"                     "0.4000_135.0000 grados"   0  -dp 4 45 10 -90

echo "=== RADIANES (-rad) Y GRADOS (-grad)"
prueba "-grad explicito"                  "1.4142_135.0000 grados"   0  -grad -p -1 1
prueba "-rad rect -> polar"               "1.4142_2.3562 radianes"   0  -rad -p -1 1
prueba "-rad polar -> rect"               "1.7320+1.0000i"           0  -rad -r 2 0.5236
prueba "-rad suma polar"                  "3.0000_0.7854 radianes"   0  -rad -sp 1 0.7854 2 0.7854
prueba "-rad multiplica polar"            "6.0000_-0.2832 radianes"  0  -rad -mp 2 3 3 3

echo "=== ERRORES (el codigo de salida tambien cuenta)"
prueba "division polar entre 0"           "error: No se puede dividir entre cero"  1  -dp 4 45 0 10
prueba "division rect entre 0"            "error: No se puede dividir entre cero"  1  -dr 1 1 0 0
prueba "division rect entre 0.0"          "error: No se puede dividir entre cero"  1  -dr 1 1 0.0 0.0
prueba "faltan operandos (4)"             "error: Necesitas 4 parametros"   2  -sr 1 1 2
prueba "faltan operandos (2)"             "error: Necesitas 2 parametros"   2  -p 1
prueba "sobran operandos"                 "error: Necesitas 2 parametros"   2  -p 1 2 3
prueba "no es un numero"                  "error: 'a' no es un número válido"  2  -sr 1 a 2 3
prueba "numero con dos puntos"            "error: '1.2.3' no es un número válido"  2  -p 1.2.3 4
prueba "opcion desconocida"               "error: Opción no valida"         2  -zz 1 2
prueba "-h con parametros"                "error: No se le pueden pasar parámetros a -h"  2  -h 1

echo "=== USO Y OPCIONES"
prueba_rc "sin argumentos"                2  
prueba_rc "-rad solo"                     2  -rad
prueba    "-grad y -rad juntos"           "error: no se pueden usar -grad y -rad a la vez"  2  -grad -rad -p 1 1
prueba    "-rad y -grad juntos"           "error: no se pueden usar -grad y -rad a la vez"  2  -rad -grad -p 1 1
prueba_rc "-h"                            0  -h

echo "=== EXPRESIONES EN NOTACION MATEMATICA"
prueba "suma rect"             "(2+3i) + (3-2i) = 5.0000+1.0000i"             0  "(2+3i)+(3-2i)"
prueba "resta rect con j"      "(10-20j) - (21+4j) = -11.0000-24.0000i"       0  "(10-20j)-(21+4j)"
prueba "multiplica rect"       "(2+3i) * (3-2i) = 12.0000+5.0000i"            0  "(2+3i)*(3-2i)"
prueba "divide rect"           "(10+5i) / (2-1i) = 3.0000+4.0000i"            0  "(10+5i)/(2-1i)"
prueba "divide polar"          "(4 45) / (10 -90) = 0.4000_135.0000 grados"   0  "(4 45)/(10 -90)"
prueba "multiplica polar"      "(2 45) * (2 45) = 4.0000_90.0000 grados"      0  "(2 45)*(2 45)"
prueba "mezcla rect y polar"   "(2+3i) * (4 45) = -2.8284+14.1421i"           0  "(2+3i)*(4 45)"
prueba "solo imaginaria"       "(3i) + (4) = 4.0000+3.0000i"                  0  "(3i)+(4)"
prueba "-rad con polares"      "(4 0.78) / (10 -1.57) = 0.4000_2.3500 radianes"  0  -rad "(4 0.78)/(10 -1.57)"
prueba "falta cerrar parentesis" "error: expresión no válida: '(2+3i)+(3-2i'"  1  "(2+3i)+(3-2i"
prueba "operador no valido"    "error: operador no válido en '(2+3i)x(3-2i)'" 1  "(2+3i)x(3-2i)"
prueba "operando no valido"    "error: operando no válido: '2+a'"             1  "(2+a)+(1)"
prueba "division entre cero"   "error: No se puede dividir entre cero"        1  "(5)/(0)"
prueba "dos argumentos"        "error: la expresión debe ir entre comillas y sola"  2  "(1+i)+(2)" "(3)"

echo "=== FICHERO (-f)"
prueba    "-f sin fichero"      "error: uso: complejo.sh [-grad|-rad] -f fichero"  2  -f
prueba    "-f con dos ficheros" "error: uso: complejo.sh [-grad|-rad] -f fichero"  2  -f a b
prueba    "fichero que no existe" "error: El fichero 'noexiste.txt' no existe o no se puede leer."  2  -f noexiste.txt
prueba_f  "fichero correcto" "$(printf '(2+3i) + (3-2i) = 5.0000+1.0000i\n(4 45) / (10 -90) = 0.4000_135.0000 grados')" 0 '(2+3i)+(3-2i)\n(4 45)/(10 -90)\n'
prueba_f  "vacias y comentarios" "(1+i) + (i) = 1.0000+2.0000i" 0 '\n# comentario\n   \n(1+i)+(i)\n'
prueba_f  "cambio a radianes" "$(printf '(2 0.5) * (2 0.5) = 4.0000_1.0000 radianes\n(2 90) * (3 90) = 6.0000_180.0000 grados')" 0 'radianes\n(2 0.5)*(2 0.5)\ngrados\n(2 90)*(3 90)\n'
prueba_f  "-rad como unidad inicial" "(4 0.78) / (10 -1.57) = 0.4000_2.3500 radianes" 0 '(4 0.78)/(10 -1.57)\n' -rad
prueba_f  "ultima linea sin Enter" "(2+3i) + (3-2i) = 5.0000+1.0000i" 0 '(2+3i)+(3-2i)'
prueba_f  "errores: sigue y devuelve 1" "$(printf '(2+3i) + (3-2i) = 5.0000+1.0000i\nerror: operando no válido: '"'"'2+a'"'"'\nerror: línea 2: no se pudo realizar la operación\n(1+i) + (1-i) = 2.0000+0.0000i')" 1 '(2+3i)+(3-2i)\n(2+a)+(1)\n(1+i)+(1-i)\n'

echo
echo "Resultado: $OK pruebas correctas, $MAL con fallo."
[ "$MAL" = 0 ]
