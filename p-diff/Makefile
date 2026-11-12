EMIT ?= emit

.PHONY: all build test clean

all: build

build:
	mkdir -p build
	$(EMIT) build p-diff

test: build
	./test/run-tests.sh

clean:
	rm -rf build *.log test/*.log
