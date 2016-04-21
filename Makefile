.PHONY: all clean

all:
	ocamlbuild -use-ocamlfind -tag thread -package cmdliner -package core -package biocaml.unix order.native
	mv order.native fasta-orderer

clean:
	rm ./order

