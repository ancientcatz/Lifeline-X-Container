#!/usr/bin/env bash

WSPATH=${WSPATH:-'ws'}
UUID=${UUID:-'98022679-354b-467d-90d3-f6deeedd75ae'}
WARP_DOMAINS=$(echo "${DOMAINS:-"openai.com;ai.com"}" | tr -d ' ')
WARP_PUB=${WARP_PUB:-'bmXOC+F1FxEMF9dyiK2H5/1SUtzH0JuVo51h2wPfgyo='}
WARP_SECRET=${WARP_SECRET:-'8KKI1b0JpNGwD6SGd7vucT0qgyBanVh8MwOMjUl9tkI='}
WARP_IPV6=${WARP_IPV6:-'2606:4700:110:8502:50d6:b104:46be:71f5/128'}

MIX=$(tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6)
#mv x ${MIX}

generate() {
  cat > config.json <<EOF
{
    "log":{
        "access":"/dev/null",
        "error":"/dev/null",
        "loglevel":"none"
    },
    "inbounds":[
        {
            "port":3001,
            "listen":"127.0.0.1",
            "protocol":"vless",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}"
                    }
                ],
                "decryption":"none"
            },
            "streamSettings":{
                "network":"ws",
                "security":"none",
                "wsSettings":{
                    "acceptProxyProtocol": true,
                    "path":"/vless-${WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ]
            }
        },
        {
            "port":3002,
            "listen":"127.0.0.1",
            "protocol":"vmess",
            "settings":{
                "clients":[
                    {
                        "id":"${UUID}",
                        "alterId":0
                    }
                ]
            },
            "streamSettings":{
                "network":"ws",
                "wsSettings":{
                    "acceptProxyProtocol": true,
                    "path":"/vmess-${WSPATH}"
                }
            },
            "sniffing":{
                "enabled":true,
                "destOverride":[
                    "http",
                    "tls",
                    "quic"
                ]
            }
        }
    ],
    "outbounds":[
EOF
  if [ -n "$WARP_MODE" ] && [ "$WARP_MODE" -eq 1 2>/dev/null ]; then
    echo "WARP with global mode."
  else
    echo "WARP with rule mode."
    cat >> config.json <<EOF
        {
            "protocol":"freedom"
        },
EOF
  fi
  cat >> config.json <<EOF
        {
            "tag":"WARP",
            "protocol":"wireguard",
            "settings":{
                "secretKey":"${WARP_SECRET}",
                "address":[
                    "172.16.0.2/32",
                    "${WARP_IPV6}"
                ],
                "peers":[
                    {
                        "publicKey":"${WARP_PUB}",
                        "allowedIPs":[
                            "0.0.0.0/0",
                            "::/0"
                        ],
                        "endpoint":"162.159.193.10:2408"
                    }
                ],
                "reserved":[78, 135, 76],
                "mtu":1280
            }
        }
    ],
EOF
  if [ -n "$WARP_MODE" ] && [ "$WARP_MODE" -eq 1 2>/dev/null ]; then
    true
  else
    cat >> config.json <<EOF
    "routing":{
        "domainStrategy":"AsIs",
        "rules":[
            {
                "type":"field",
                "domain":[
EOF
    IFS=";" read -ra domain_array <<< "$WARP_DOMAINS"
    for domain in "${domain_array[@]}"; do
      cat >> config.json <<EOF
                    "domain:$domain",
EOF
    done
    sed -i '$s/,$//' config.json
    cat >> config.json <<EOF
                ],
                "outboundTag":"WARP"
            }
        ]
    },
EOF
  fi
  cat >> config.json <<EOF
    "dns":{
        "servers":[
            "1.1.1.1",
            "1.0.0.1",
            "localhost"
        ]
    }
}
EOF
}

#[ -n "${NEZHA_SERVER}" ] && [ -n "${NEZHA_PORT}" ] && [ -n "${NEZHA_KEY}" ] && wget https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -O nezha.sh && chmod +x nezha.sh && echo '0' | ./nezha.sh install_agent ${NEZHA_SERVER} ${NEZHA_PORT} ${NEZHA_KEY}

#nginx
generate
#./${MIX} run