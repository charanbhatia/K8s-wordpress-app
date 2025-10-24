FROM mysql:8.0

ENV MYSQL_ROOT_PASSWORD=rootpass
ENV MYSQL_DATABASE=wordpress
ENV MYSQL_USER=wpuser
ENV MYSQL_PASSWORD=wppass

COPY custom.cnf /etc/mysql/conf.d/custom.cnf

RUN chmod 644 /etc/mysql/conf.d/custom.cnf

EXPOSE 3306

CMD ["mysqld"]
