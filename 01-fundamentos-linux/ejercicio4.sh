#!/bin/bash

URL="https://es.wikipedia.org/wiki/Wikipedia:Portada"

wget -q -O pagina.txt $URL

if grep -q "$1" pagina.txt; then
  echo "La palabra \"$1\" ha sido encontrada"
else
  echo "No se ha encontrado la palabra \"$1\""
fi