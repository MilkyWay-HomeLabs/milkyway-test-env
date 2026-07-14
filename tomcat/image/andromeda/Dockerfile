FROM tomcat:10.1-jdk21-temurin
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["catalina.sh", "run"]