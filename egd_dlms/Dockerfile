ARG BUILD_FROM
FROM $BUILD_FROM

# HA base images ship bashio for reading /data/options.json in shell scripts.
RUN apk add --no-cache python3 py3-pip socat git

RUN git clone --depth 1 --branch master https://github.com/lhubac/egd-dlms.git /opt/egd-dlms \
    && pip install --break-system-packages --no-cache-dir -e /opt/egd-dlms

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
