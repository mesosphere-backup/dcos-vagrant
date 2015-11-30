FROM java:8
COPY gs-spring-boot-0.1.0.jar /var/tmp/java-spring/
WORKDIR /var/tmp/java-spring
CMD ["java", "-Xmx256m", "-jar", "gs-spring-boot-0.1.0.jar", "--server.port=3060", "--endpoints.shutdown.enabled=true"]
