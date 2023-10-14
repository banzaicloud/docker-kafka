FROM alpine:latest AS kafka_dist

ARG scala_version=2.13
ARG kafka_version=3.4.1
ARG kafka_distro_base_url=https://dlcdn.apache.org/kafka

ENV kafka_distro=kafka_$scala_version-$kafka_version.tgz
ENV kafka_distro_sha512=$kafka_distro.sha512

WORKDIR /var/tmp
RUN apk add --no-cache coreutils
RUN wget -q $kafka_distro_base_url/$kafka_version/$kafka_distro
RUN wget -q $kafka_distro_base_url/$kafka_version/$kafka_distro_sha512
RUN set -e; \
    # Calculate the SHA-512 checksum of the downloaded file
    calculated_checksum=$(sha512sum $kafka_distro | awk '{print $1}'); \
    \
    # Extract and format the provided SHA-512 checksum from the file
    provided_checksum=$(tr -d ' \n' < $kafka_distro_sha512 | cut -d':' -f2 | tr 'A-F' 'a-f'); \
    \
    echo "Calculated checksum: $calculated_checksum"; \
    echo "Provided checksum:   $provided_checksum"; \
    # Compare the two checksums and exit if they don't match
    if [ "$calculated_checksum" != "$provided_checksum" ]; then \
        echo "SHA-512 values do NOT match!"; \
        exit 1; \
    else \
        echo "SHA-512 values match!"; \
    fi

RUN tar -xzf $kafka_distro
RUN rm -r kafka_$scala_version-$kafka_version/bin/windows


FROM eclipse-temurin:17.0.3_7-jre

ARG scala_version=2.13
ARG kafka_version=3.4.1

ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    KAFKA_HOME=/opt/kafka

ENV PATH=${PATH}:${KAFKA_HOME}/bin

RUN mkdir ${KAFKA_HOME} && apt-get update && apt-get install curl -y && apt-get clean

COPY --from=kafka_dist /var/tmp/kafka_$scala_version-$kafka_version ${KAFKA_HOME}

RUN chmod a+x ${KAFKA_HOME}/bin/*.sh

CMD ["kafka-server-start.sh"]
