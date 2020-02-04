FROM maven:3-jdk-11 AS builder

RUN git clone                                                                       \
        --quiet                                                                     \
        --depth=1                                                                   \
        --branch=james-project-3.4.0                                                \
        "https://github.com/apache/james-project.git"                               \
        "/build"                                                                    \
    && cd "/build"                                                                  \
    && mvn package -DskipTests

RUN mkdir -p /james/bin                                                             \
    && mkdir -p /james/conf                                                         \
    && mkdir -p /james/sample/conf/lib                                              \
    && mkdir -p /james/lib                                                          \
    && cp -a                                                                        \
        /build/server/container/guice/jpa-guice/target/james-server-jpa-guice.lib/* \
        /james/lib/                                                                 \
    && cp -a                                                                        \
        /build/server/container/guice/jpa-guice/target/james-server-jpa-guice.jar   \
        /james/lib/                                                                 \
    && cp -a                                                                        \
        /build/server/container/cli/target/james-server-cli.lib/*                   \
        /james/lib/                                                                 \
    && cp -a                                                                        \
        /build/server/container/cli/target/james-server-cli.jar                     \
        /james/lib/                                                                 \
    && cp -a                                                                        \
        /build/server/app/src/main/resources/*                                      \
        /james/sample/conf/                                                         \
    && cp -a                                                                        \
        /build/server/container/guice/jpa-smtp/sample-configuration/*               \
        /james/sample/conf/                                                         \
    && cp -a                                                                        \
        /build/server/app/target/appassembler/bin/*                                 \
        /james/bin/

FROM openjdk:11-jre AS apache-james
LABEL maintainer="fabio.montefuscolo@gmail.com"
COPY --from=builder /james /james

EXPOSE 25 110 143 465 587 993 4000 8000
ENV PATH=$PATH:/james/bin
ENV JAMES_HOME=/james
ENV CLASSPATH_PREFIX=/james/lib/*

VOLUME ["/james/conf", "/var/mail", "/var/store", "/var/users"]
WORKDIR /james

ADD "entrypoint.sh" "/entrypoint.sh"
ENTRYPOINT ["/entrypoint.sh"]

CMD java                                                                            \
    -classpath '/james/conf/lib/*:/james/conf:/james/lib/*'                         \
    -javaagent:/james/lib/openjpa-3.1.0.jar                                         \
    -Dapp.name=run                                                                  \
    -Dapp.home=/james                                                               \
    -Dapp.repo=/james/lib                                                           \
    -Dworking.directory=/james                                                      \
    $JVM_OPTIONS                                                                    \
    org.apache.james.JPAJamesServerMain

