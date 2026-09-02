# pgloader v4 — Clojure/JVM rewrite, prebuilt JAR from the v4-dev release channel
# https://github.com/dimitri/pgloader/pull/1705
# The ghcr :latest tag still serves the old SBCL 3.6.10 build (deadlocks + broken MySQL auth),
# so we ship the v4 JAR ourselves
FROM eclipse-temurin:21-jre-alpine

RUN wget -q -O /usr/local/lib/pgloader.jar \
        https://github.com/dimitri/pgloader/releases/download/v4-dev/pgloader.jar \
    && printf '#!/bin/sh\nexec java -jar /usr/local/lib/pgloader.jar "$@"\n' > /usr/local/bin/pgloader \
    && chmod +x /usr/local/bin/pgloader

ENTRYPOINT ["pgloader"]
