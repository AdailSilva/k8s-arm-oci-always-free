# ─────────────────────────────────────────────────────────────
# Stage 1: Build
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jdk-jammy AS builder

WORKDIR /build

COPY pom.xml .
COPY src ./src

# Download dependencies first (Docker layer cache)
RUN apt-get update && apt-get install -y maven && \
    mvn dependency:go-offline -B -q

# Build the fat jar
RUN mvn package -DskipTests -B -q

# ─────────────────────────────────────────────────────────────
# Stage 2: Runtime (ARM64 compatible)
# ─────────────────────────────────────────────────────────────
FROM eclipse-temurin:21-jre-jammy

LABEL maintainer="AdailSilva <adail101@hotmail.com>"
LABEL org.opencontainers.image.title="k8s-dashboard-backend"
LABEL org.opencontainers.image.description="Kubernetes Dashboard - Spring Boot Backend"

WORKDIR /app

# Create non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

COPY --from=builder /build/target/k8s-dashboard-backend-*.jar app.jar

# Set correct ownership
RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 8080

# Use in-cluster config by default
ENV K8S_IN_CLUSTER=true

ENTRYPOINT ["java", \
  "-XX:+UseContainerSupport", \
  "-XX:MaxRAMPercentage=75.0", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar"]
