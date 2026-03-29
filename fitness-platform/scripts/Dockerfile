FROM alpine:3.21
RUN apk add --no-cache mariadb-client aws-cli tzdata
COPY backup.sh /backup.sh
RUN chmod +x /backup.sh
