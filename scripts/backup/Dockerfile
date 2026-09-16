FROM mcr.microsoft.com/azure-cli:latest
# azure-cli:latest is Azure Linux 3.0 (tdnf); postgresql package provides pg_dump/psql 16.
RUN tdnf install -y postgresql gzip && tdnf clean all
COPY pg_backup.sh pg_restore.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/pg_backup.sh /usr/local/bin/pg_restore.sh
ENTRYPOINT ["/usr/local/bin/pg_backup.sh"]
