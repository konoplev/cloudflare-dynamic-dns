FROM python:3.9-alpine3.12

RUN apk update && apk add bash bind-tools curl jq

COPY scripts/update.sh /opt/

CMD ["/opt/update.sh"]
