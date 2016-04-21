BUILD_DIR=_build
PACKAGES=biocaml.unix core cmdliner
TEST_PACKAGES=$(PACKAGES) alcotest

.PHONY: all clean test deps testDeps

all:
	ocamlbuild -use-ocamlfind -tag thread \
	    -build-dir $(BUILD_DIR)\
	    $(foreach package, $(PACKAGES),-package $(package))\
	    ogene.cma ogene.cmxs ogene.cmxa fasta_orderer.native
	cp _build/fasta_orderer.native ./fasta-orderer

deps:
	opam install $(PACKAGES)

testDeps:
	opam install $(TEST_PACKAGES)

clean:
	ocamlbuild -build-dir $(BUILD_DIR) -clean
	-rm ./fasta-orderer 2>/dev/null
	-rm -rf _tests/ 2>/dev/null

test:
	ocamlbuild -use-ocamlfind -tag thread -I test/ \
	  -build-dir $(BUILD_DIR)\
	  $(foreach package, $(TEST_PACKAGES),-package $(package))\
	  test.native
	-mkdir $(BUILD_DIR)/test/data
	cp test/data/* $(BUILD_DIR)/test/data/
	$(BUILD_DIR)/test/test.native
