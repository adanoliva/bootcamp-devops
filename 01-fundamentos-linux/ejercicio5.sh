#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Se necesitan únicamente dos parámetros para ejecutar este script"
  exit 1
fi

URL="$1"
PALABRA="$2"

wget -q -O pagina.txt "$URL"

if [ $? -ne 0 ]; then
  echo "Error: no se pudo descargar la URL $URL"
  exit 1
fi

COUNT=$(grep -o "$PALABRA" pagina.txt | wc -l)

if [ $COUNT -eq 0 ]; then
  echo "No se ha encontrado la palabra \"$PALABRA\""
elif [ $COUNT -eq 1 ]; then
  LINEA=$(grep -n "$PALABRA" pagina.txt | cut -d: -f1)
  echo "La palabra \"$PALABRA\" aparece 1 vez"
  echo "Aparece únicamente en la línea $LINEA"
else
  echo "La palabra \"$PALABRA\" aparece $COUNT veces"
fi