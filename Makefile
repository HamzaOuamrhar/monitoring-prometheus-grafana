all:
	docker compose up -d

down:
	docker compose down

clean:
	docker compose down --rmi all
	docker volume rm $$(docker volume ls -q)

super_clean: clean
	docker system prune -a

build:
	docker compose up -d --build

g:
	docker exec -it grafana bash

p:
	docker exec -it prometheus-proxy bash

re: clean all