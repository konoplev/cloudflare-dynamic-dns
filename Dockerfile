FROM python:3.7-alpine

RUN apk update && apk add bash bind-tools curl jq

COPY scripts/update.sh /opt/

CMD ["/opt/update.sh"]
