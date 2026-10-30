#!/bin/bash
function error{
    echo "$NOMBRE: error: $*" >&2 #Se redirige al canal de errores
}
function uso {
    echo "Uso:"

}
function PasarACoordenadasPolares { #PENDIENTE DE REVISION
x=$1 #la x a la que hacerle el modulo
y=$2 #la y a la que hacerle el modulo
(scale=2) #he ajustado la precision a 2 decimales(eso se le envia al bc)
r=$(echo "scale=2; sqrt(($x^2)+($y^2))" | bc -l)
fi=$(echo "scale=2; arctan($y/$x)" | bc -l)
return 0
}

function PasarACoordenadasRectangulares {
}
function SumaRectangulares {
}
function SumaPolares {
}
function RestaRectangulares {
}
function RestaPolares {
}
function MultiplicaRectangulares {
}
function MultiplicaPolares {
}
function DivideRectangulares {
}
function DividePolares {
}

exit 0;

