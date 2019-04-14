ifndef DYNAMODB_CONFIG_FILE
	DYNAMODB_CONFIG_FILE=.dynamodb.sh
endif

ifndef ENV_FILE
	ENV_FILE=env.json
endif

ifndef MYTABLE_SCHEMA_FILE
	MYTABLE_SCHEMA_FILE=mytable.schema.json
endif

GO_BUILD_CMD=GOOS=linux go build

-include ${DYNAMODB_CONFIG_FILE}
export

check-config-file-exists:
	if [ ! -e "${DYNAMODB_CONFIG_FILE}" ]; then echo "no config file"; false; fi

start-dynamodb:
ifdef DYNAMODB_CONTAINER_ID
	docker start ${DYNAMODB_CONTAINER_ID}
else
	$(eval DYNAMODB_CONTAINER_ID=$(shell docker run -d -p 8000 amazon/dynamodb-local 2> /dev/null))
	echo "DYNAMODB_CONTAINER_ID=${DYNAMODB_CONTAINER_ID}" >> ${DYNAMODB_CONFIG_FILE}
endif
	$(aws --endpoint-url "http://0.0.0.0:${docker port ${DYNAMODB_CONTAINER_ID} 8000/tcp | cut -c 9-}" \
		dynamodb describe-table --table-name MyTable 2>&1 >/dev/null || ${MAKE} init-dynamodb)

stop-dynamodb: check-config-file-exists
	docker stop "${DYNAMODB_CONTAINER_ID}"

init-dynamodb: check-config-file-exists
	aws --endpoint-url="http://0.0.0.0:${shell docker port ${DYNAMODB_CONTAINER_ID} 8000/tcp | cut -c 9-}" \
		dynamodb create-table --cli-input-json file://${MYTABLE_SCHEMA_FILE}

build:
	cd cmd/my-command/ && ${GO_BUILD_CMD}

run: update-env-file build
	echo {} | sam local invoke -n ${ENV_FILE} MyCommandFunction

update-env-file: check-config-file-exists
	echo '{"MyCommandFunction": {"ENDPOINT_OVERRIDE": "http://docker.for.mac.localhost:${shell docker port ${DYNAMODB_CONTAINER_ID} 8000/tcp | cut -c 9-}/"}}' > ${ENV_FILE}

clean:
ifdef DYNAMODB_CONTAINER_ID
	docker rm -f ${DYNAMODB_CONTAINER_ID} || true
endif
	-rm ${DYNAMODB_CONFIG_FILE}
	-rm ${ENV_FILE}
	-rm cmd/my-command/my-command