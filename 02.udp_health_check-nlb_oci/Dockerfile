# syntax=docker/dockerfile:1

FROM --platform=$BUILDPLATFORM eclipse-temurin:17-jdk AS build
WORKDIR /src
COPY UdpHealthCheckServer.java .
RUN javac UdpHealthCheckServer.java

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /src/UdpHealthCheckServer.class .
#CMD ["java", "UdpHealthCheckServer", "1700"]
CMD ["java", "UdpHealthCheckServer", "1710"]
