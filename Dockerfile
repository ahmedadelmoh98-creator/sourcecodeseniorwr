# Stage 1: Build the Java application into a WAR file
FROM maven:3.9-eclipse-temurin-11 AS build

WORKDIR /src

COPY pom.xml .

COPY src ./src

RUN mvn -B clean package -DskipTests=true

# Stage 2: Run the application using Tomcat
FROM tomcat:9-jdk11

RUN rm -rf /usr/local/tomcat/webapps/*

COPY --from=build /src/target/*.war /usr/local/tomcat/webapps/ROOT.war

EXPOSE 8080

CMD ["catalina.sh", "run"]
