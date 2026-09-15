FROM mcr.microsoft.com/azure-cli:latest
RUN apk add --no-cache postgresql16-client bash gzip
COPY pg_backup.sh pg_restore.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/pg_backup.sh /usr/local/bin/pg_restore.sh
ENTRYPOINT ["/usr/local/bin/pg_backup.sh"]
