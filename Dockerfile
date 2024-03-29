FROM alpine as build

RUN apk add --no-cache gcc musl-dev git perl make linux-headers
RUN apk add --no-cache upx >/dev/null 2>&1 ||true
RUN wget https://github.com/openssl/openssl/archive/refs/tags/OpenSSL_1_1_1l.tar.gz
RUN tar xf OpenSSL*
RUN (cd openssl-* && ./config && make -j4 && make install_sw -j4)
RUN git clone https://github.com/pymumu/smartdns.git && \
    export VER=$(curl -L https://github.com/pymumu/smartdns/releases/latest|grep -oE '<code class="f5 ml-1">[0-9a-zA-Z]+</code>'|grep -oE '>[0-9a-zA-Z]+<'|grep -oE '[0-9a-zA-Z]+')
RUN (cd smartdns && export STATIC="yes" && make all -j8 VER=$VER)
RUN strip /smartdns/src/smartdns
RUN if [ "$(command -v upx)q" != "q" ];then upx --lzma /smartdns/src/smartdns; fi

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

