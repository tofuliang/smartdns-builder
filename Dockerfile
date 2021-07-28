FROM alpine as build

RUN apk add --no-cache gcc musl-dev git perl make linux-headers
RUN apk add --no-cache upx >/dev/null 2>&1 ||true
RUN wget https://www.openssl.org/source/old/1.1.1/openssl-1.1.1j.tar.gz
RUN tar xf openssl-*
RUN (cd openssl-* && ./config && make -j4 && make install_sw -j4)
RUN git clone https://github.com/pymumu/smartdns.git
RUN (cd smartdns && export VER="`date +"1.%Y.%m.%d-%H%M"`" && export STATIC="yes" && make all -j8 VER=$VER)
RUN strip /smartdns/src/smartdns
RUN if [ "$(command -v upx)q" != "q" ];then upx /smartdns/src/smartdns; fi

FROM scratch
COPY --from=build /smartdns/src/smartdns /bin/smartdns
COPY --from=build /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
ADD smartdns.conf /smartdns.conf
ADD custom.conf /smartdns/custom.conf
ADD rules /smartdns/rules
EXPOSE 53
EXPOSE 5353
EXPOSE 53/udp
EXPOSE 5353/udp
VOLUME ["/smartdns"]
CMD ["/bin/smartdns","-fxc", "/smartdns.conf","-p","/smartdns.pid"]
