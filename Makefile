
run: start

start:
	docker-compose -f docker/docker-compose.yml up -d

stop:
	docker-compose -f docker/docker-compose.yml stop

logs:
	docker-compose -f docker/docker-compose.yml logs -f

test: start
	mix test

coveralls.github: start
	mix coveralls.github

psql:
	psql -h localhost -U postgres

.PHONY: start test logs stop run
