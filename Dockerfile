FROM nginx:latest
EXPOSE 80
WORKDIR /app
USER root

COPY nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh ./

RUN apt-get update && apt-get install -y wget unzip iproute2 systemctl &&\
    wget -O x.zip $(wget -qO- "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep -m1 -o "https.*linux-64.*zip") &&\
    unzip x.zip xray geoip.dat geosite.dat &&\
    rm -r x.zip &&\
    mv xray x &&\
    chmod -v 755 x entrypoint.sh

ENTRYPOINT [ "./entrypoint.sh" ]