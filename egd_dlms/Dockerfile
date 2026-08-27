ARG BUILD_FROM
FROM $BUILD_FROM

# HA base images ship bashio for reading /data/options.json in shell scripts.
RUN apk add --no-cache python3 py3-pip socat git

# Vlastní fork, viz https://github.com/blesk89/egd-dlms.
#
# CACHE BUST: bez tohohle ARG Docker při rebuildu recykluje starou vrstvu
# "git clone" (stejný příkaz = stejný cache klíč), takže nová oprava v
# master větvi fork se nikdy nepropsala, i po zvýšení verze add-onu.
# Při KAŽDÉ aktualizaci egd-dlms forku sem vlož nový commit hash, ať se
# vynutí čerstvý git clone.
ARG EGD_DLMS_REF=f57d63aa
RUN git clone --depth 1 --branch master https://github.com/blesk89/egd-dlms.git /opt/egd-dlms \
    && echo "egd-dlms pinned-ref: ${EGD_DLMS_REF}" \
    && pip install --break-system-packages --no-cache-dir -e /opt/egd-dlms

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]


