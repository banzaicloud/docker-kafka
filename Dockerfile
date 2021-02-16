FROM gradle:jdk11 AS kafka_build

ARG scala_version=2.13
ARG kafka_repo_url=https://github.com/banzaicloud/kafka.git
ARG kafka_repo_tag=2.7.0-bzc.1
ARG kafka_base_dir=/var/tmp/kafka
ARG kafka_release_dir=$kafka_base_dir/release

ENV REPO_URL=$kafka_repo_url
ENV REPO_TAG=$kafka_repo_tag

RUN mkdir -p $kafka_release_dir
RUN mkdir -p $kafka_release_dir/libs
RUN mkdir -p $kafka_release_dir/logs

WORKDIR $kafka_base_dir
RUN git clone $REPO_URL

WORKDIR $kafka_base_dir/kafka
RUN git checkout $REPO_TAG
RUN ./gradlew -PscalaVersion=$scala_version clean jar
RUN find . -name "*jar" -type f | grep -v "upgrade-system-tests" | grep -v "fork" | xargs -I{} cp -v {} $kafka_release_dir/libs
RUN cp -r ./bin $kafka_release_dir
RUN rm -rf $kafka_release_dir/bin/windows
RUN cp -r ./config $kafka_release_dir
RUN cp NOTICE $kafka_release_dir
RUN cp LICENSE $kafka_release_dir


FROM openjdk:11-jre-slim

ARG scala_version=2.13
ARG kafka_version=2.7.0
ARG kafka_base_dir=/var/tmp/kafka
ARG kafka_release_dir=$kafka_base_dir/release

ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    KAFKA_HOME=/opt/kafka

ENV PATH=${PATH}:${KAFKA_HOME}/bin

RUN mkdir ${KAFKA_HOME} && apt-get update && apt-get install curl -y && apt-get clean

COPY --from=kafka_build $kafka_release_dir ${KAFKA_HOME}

RUN chmod a+x ${KAFKA_HOME}/bin/*.sh

ADD VERSION .

CMD ["kafka-server-start.sh"]
