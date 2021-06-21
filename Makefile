
start:
	docker-compose -f docker/docker-compose.yml up -d

test: start
	mix test

coveralls.github: start
	mix coveralls.github

.PHONY: start test
