#!/bin/bash
function error{
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
PasarACoordenadasPolares{
}
PasarACoordenadasRectangulares{
}
SumaRectangulares{
}
SumaPolares{
}
RestaRectangulares{
}
RestaPolares{
}
MultiplicaRectangulares{
}
MultiplicaPolares{
}
DivideRectangulares{
}
DividePolares{
}

exit 0;

