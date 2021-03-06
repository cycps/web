.PHONY: all
all: site container

.PHONY: site
site:
	rake

.PHONY: container
container:
	docker build -t web .

.PHONY: run
run:
	docker run -d -p 443:443 --hostname=web --name=web web

.PHONY: debug
debug:
	docker run -i -t -p 443:443 --hostname=web --name=web web || echo "\n"
