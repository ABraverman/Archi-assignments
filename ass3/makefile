
all: ass3

ass3: ass3.o drone.o printer.o scheduler.o target.o 
	gcc -m32 -Wall -g ass3.o drone.o printer.o scheduler.o target.o  -o ass3
	



scheduler.o: scheduler.s
	nasm -g -f elf scheduler.s -o scheduler.o

ass3.o: ass3.s
	nasm -g -f elf ass3.s -o ass3.o

drone.o: drone.s
	nasm -g -f elf drone.s -o drone.o

printer.o: printer.s
	nasm -g -f elf printer.s -o printer.o

target.o: target.s
	nasm -g -f elf target.s -o target.o


.PHONY: clean

clean: 
	rm -f *.o ass3
