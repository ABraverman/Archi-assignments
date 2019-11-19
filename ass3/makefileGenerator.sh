#!/bin/bash
clear
rm -f makefile

objects_files=""
shopt -s nullglob

for filename in *.c; do
    objects_files="${filename%.*}.o ${objects_files}" 
done

for filename in *.s; do
    objects_files="${filename%.*}.o ${objects_files}" 
done

echo -e "$1 : ${objects_files}  
\tgcc -m32 -g -Wall -o $1 ${objects_files}" >> makefile
    
echo "" >> makefile

for filename in *.c; do
echo -e "${filename%.*}.o : ${filename} 
\tgcc -g -Wall -m32 -c -o ${filename%.*}.o  ${filename}" >> makefile 
done 
echo "" >> makefile
for filename in *.s; do
echo -e "${filename%.*}.o : ${filename} 
\tnasm -g -f elf32 -w+all -o ${filename%.*}.o  ${filename}" >> makefile 
done 
echo "" >> makefile

echo -e ".PHONY: clean
clean: 
\trm -f *.o $1" >> makefile

make clean 
make
