FROM ghcr.io/sa4zet-org/docker.img.debian:latest AS build-stage

ARG docker_img
ENV DOCKER_TAG=$docker_img

RUN apt-get update
RUN apt-get -y install \
  dovecot-core \
  dovecot-imapd \
  dovecot-managesieved \
  dovecot-sieve \
  fetchmail \
  opendkim \
  opendkim-tools \
  postfix \
  postfix-policyd-spf-python \
  supervisor
RUN usermod -aG opendkim,dovecot postfix
RUN usermod -aG postfix dovecot
RUN usermod -aG postfix opendkim
RUN mkdir --mode=755 /var/spool/postfix/pid
RUN mkdir --mode=770 /var/spool/postfix/opendkim/
RUN chown opendkim:postfix /var/spool/postfix/opendkim/
RUN rm /etc/dovecot/conf.d/10-ssl.conf
RUN apt-get --purge -y autoremove
RUN apt-get clean
RUN rm -rf /tmp/* /var/lib/apt/lists/*

COPY etc/ /etc/

FROM ghcr.io/sa4zet-org/docker.img.debian:latest AS final-stage
COPY --from=build-stage / /

ENV DOCKER_TAG=ghcr.io/sa4zet-org/docker.img.mail

HEALTHCHECK \
  --interval=3m \
  --retries=2 \
  --timeout=2s \
  CMD /usr/bin/supervisorctl --username admin --password admin status || exit 1

ENTRYPOINT ["/usr/bin/supervisord", "--nodaemon" ,"--configuration", "/etc/supervisor/supervisord.conf"]
