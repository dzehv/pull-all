# pull_all_go builder

BINARY=pull_all_go
PREFIX=/usr/local/bin

.PHONY: all build install clean help

all: build

# build the binary using local go files
build:
	@echo "building $(BINARY)..."
	@go build -o $(BINARY) main.go

# install with sudo for system-wide access
install: build
	@echo "installing to $(PREFIX)..."
	@sudo install -m 755 $(BINARY) $(PREFIX)/$(BINARY)
	@echo "done. you can now use '$(BINARY) -d <path>'"

# clean build artifacts
clean:
	@rm -f $(BINARY)
	@echo "cleaned."

# help target
help:
	@echo "usage:"
	@echo "  make build    - compile binary"
	@echo "  make install  - install to $(PREFIX)"
	@echo "  make clean    - remove binary"
