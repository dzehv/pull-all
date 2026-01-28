# pull_all_go installation tool

BINARY=pull_all_go
PREFIX=/usr/local/bin
SOURCE=main.go

.PHONY: all build install clean help

all: build

# compile the tool
build:
	@echo "building $(BINARY)..."
	@go build -o $(BINARY) $(SOURCE)

# system-wide installation
install: build
	@echo "installing $(BINARY) to $(PREFIX)"
	@sudo install -m 755 $(BINARY) $(PREFIX)/$(BINARY)
	@echo "done! you can now use '$(BINARY) -h' for help"

# cleanup
clean:
	@rm -f $(BINARY)
	@echo "cleaned local binary"

# help for make commands
help:
	@echo "available commands:"
	@echo "  make build   - compile $(BINARY)"
	@echo "  make install - install to $(PREFIX) (requires sudo)"
	@echo "  make clean   - delete local binary"
