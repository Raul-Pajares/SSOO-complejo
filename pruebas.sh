#!/bin/bash
# pruebas.sh - Batería de pruebas para complejo.sh
# Uso (desde la carpeta donde está complejo.sh):   bash pruebas.sh
# Cada prueba compara la salida y el código de salida con lo esperado.
#usar sed -i 's/\r$//' complejo.sh pruebas.sh y luego file pruebas.sh y file complejo.sh y luego ejecutar bash
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
prueba "faltan operandos (4)"             "Necesitas 4 parametros"   2  -sr 1 1 2
prueba "faltan operandos (2)"             "Necesitas 2 parametros"   2  -p 1
prueba "sobran operandos"                 "Necesitas 2 parametros"   2  -p 1 2 3
prueba "no es un numero"                  "error: 'a' no es un número válido"  2  -sr 1 a 2 3
prueba "numero con dos puntos"            "error: '1.2.3' no es un número válido"  2  -p 1.2.3 4
prueba "opcion desconocida"               "Opción no valida"         2  -zz 1 2
prueba "-h con parametros"                "No se le pueden pasar parámetros a -h"  2  -h 1

echo
echo "Resultado: $OK pruebas correctas, $MAL con fallo."
[ "$MAL" = 0 ]