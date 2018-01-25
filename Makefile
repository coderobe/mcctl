bin/mcctl:
	shards build

.PHONY: clean
clean:
	rm -rf bin

.PHONY: all
all: bin/mcctl

.PHONY: install
install:
	install -Dm755 bin/mcctl "$(DESTDIR)/usr/bin/mcctl"

.PHONY: uninstall
uninstall:
	rm "$(DESTDIR)/usr/bin/mcctl"
