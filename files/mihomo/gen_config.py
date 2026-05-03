#!/usr/bin/env python3
"""从机场订阅链接生成 mihomo 配置文件。

用法：
    python3 gen_config.py <订阅链接> [输出路径]

示例：
    python3 gen_config.py "https://example.com/api/v1/client/subscribe?token=xxx"
    python3 gen_config.py "https://example.com/api/v1/client/subscribe?token=xxx" ~/.config/mihomo/config.yaml
"""
import base64
import sys
import urllib.parse
import urllib.request

import yaml


def fetch_subscription(url):
    """下载订阅内容，返回 base64 解码后的文本。"""
    req = urllib.request.Request(url)
    raw = urllib.request.urlopen(req, timeout=15).read()
    try:
        return base64.b64decode(raw).decode()
    except Exception:
        return raw.decode()


def parse_vless(body):
    """解析 vless:// 链接，返回 proxy 字典或 None。"""
    at_idx = body.index("@")
    uuid = body[:at_idx]
    rest = body[at_idx + 1:]
    q_idx = rest.find("?")
    hash_idx = rest.find("#")

    if q_idx == -1:
        server_port = rest[:hash_idx] if hash_idx != -1 else rest
        params_str = ""
    else:
        server_port = rest[:q_idx]
        params_str = rest[q_idx + 1:hash_idx] if hash_idx != -1 else rest[q_idx + 1:]

    name = urllib.parse.unquote(rest[hash_idx + 1:]) if hash_idx != -1 else "unnamed"

    colon_idx = server_port.rfind(":")
    server = server_port[:colon_idx]
    port = int(server_port[colon_idx + 1:])

    if server == "127.0.0.1":
        return None

    params = dict(urllib.parse.parse_qsl(params_str))
    security = params.get("security", "none")
    flow = params.get("flow", "")
    sni = params.get("sni", "")
    fp = params.get("fp", "")
    pbk = params.get("pbk", "")
    sid = params.get("sid", "")
    spx = params.get("spx", "")
    net_type = params.get("type", "tcp")

    proxy = {
        "name": name,
        "type": "vless",
        "server": server,
        "port": port,
        "uuid": uuid,
        "network": net_type,
        "tls": security in ("reality", "tls"),
        "flow": flow if flow else None,
    }

    if security == "reality":
        opts = {}
        if pbk:
            opts["public-key"] = pbk
        if sid:
            opts["short-id"] = sid
        if spx:
            opts["spider-x"] = urllib.parse.unquote(spx)
        if opts:
            proxy["reality-opts"] = opts

    if sni:
        proxy["servername"] = sni
    if fp:
        proxy["client-fingerprint"] = fp

    return {k: v for k, v in proxy.items() if v is not None}


def parse_ss(body):
    """解析 ss:// 链接，返回 proxy 字典或 None。"""
    hash_idx = body.find("#")
    name = urllib.parse.unquote(body[hash_idx + 1:]) if hash_idx != -1 else "unnamed"
    main = body[:hash_idx] if hash_idx != -1 else body

    at_idx = main.rfind("@")
    if at_idx == -1:
        return None

    encoded = main[:at_idx]
    server_port = main[at_idx + 1:]
    decoded = base64.b64decode(encoded + "==").decode()
    method, password = decoded.split(":", 1)
    colon_idx = server_port.rfind(":")
    server = server_port[:colon_idx]
    port = int(server_port[colon_idx + 1:])

    if server == "127.0.0.1":
        return None

    return {
        "name": name,
        "type": "ss",
        "server": server,
        "port": port,
        "cipher": method,
        "password": password,
    }


def generate_config(proxies):
    """生成 mihomo 配置字典。"""
    info_keywords = ["剩余流量", "套餐到期", "过滤掉", "距离", "官网"]
    proxies = [p for p in proxies if not any(k in p["name"] for k in info_keywords)]
    proxy_names = [p["name"] for p in proxies]
    print(f"Found {len(proxies)} proxies", file=sys.stderr)

    return {
        "mixed-port": 7890,
        "allow-lan": False,
        "bind-address": "*",
        "mode": "rule",
        "log-level": "info",
        "external-controller": "127.0.0.1:9090",
        "external-ui": "~/.config/mihomo/ui",
        "proxies": proxies,
        "proxy-groups": [
            {
                "name": "PROXY",
                "type": "select",
                "proxies": ["Auto", "DIRECT"] + proxy_names,
            },
            {
                "name": "Auto",
                "type": "url-test",
                "proxies": proxy_names,
                "url": "https://www.gstatic.com/generate_204",
                "interval": 300,
                "tolerance": 50,
            },
        ],
        "rules": [
            "DOMAIN-SUFFIX,google.com,PROXY",
            "DOMAIN-SUFFIX,github.com,PROXY",
            "DOMAIN-SUFFIX,github.io,PROXY",
            "DOMAIN-SUFFIX,githubusercontent.com,PROXY",
            "DOMAIN-SUFFIX,youtube.com,PROXY",
            "DOMAIN-SUFFIX,googlevideo.com,PROXY",
            "DOMAIN-SUFFIX,ggpht.com,PROXY",
            "DOMAIN-SUFFIX,twitter.com,PROXY",
            "DOMAIN-SUFFIX,x.com,PROXY",
            "DOMAIN-SUFFIX,twimg.com,PROXY",
            "DOMAIN-SUFFIX,telegram.org,PROXY",
            "DOMAIN-SUFFIX,t.me,PROXY",
            "DOMAIN-SUFFIX,telegram.me,PROXY",
            "DOMAIN-SUFFIX,openai.com,PROXY",
            "DOMAIN-SUFFIX,ai.com,PROXY",
            "DOMAIN-SUFFIX,anthropic.com,PROXY",
            "DOMAIN-SUFFIX,claude.ai,PROXY",
            "DOMAIN-SUFFIX,wikipedia.org,PROXY",
            "DOMAIN-SUFFIX,reddit.com,PROXY",
            "DOMAIN-SUFFIX,redd.it,PROXY",
            "DOMAIN-SUFFIX,redditmedia.com,PROXY",
            "DOMAIN-SUFFIX,medium.com,PROXY",
            "DOMAIN-SUFFIX,instagram.com,PROXY",
            "DOMAIN-SUFFIX,cdninstagram.com,PROXY",
            "DOMAIN-SUFFIX,facebook.com,PROXY",
            "DOMAIN-SUFFIX,fbcdn.net,PROXY",
            "DOMAIN-SUFFIX,netflix.com,PROXY",
            "DOMAIN-SUFFIX,nflxvideo.net,PROXY",
            "DOMAIN-SUFFIX,nflximg.net,PROXY",
            "DOMAIN-KEYWORD,google,PROXY",
            "DOMAIN-SUFFIX,cn,DIRECT",
            "DOMAIN-KEYWORD,baidu,DIRECT",
            "DOMAIN-KEYWORD,alibaba,DIRECT",
            "DOMAIN-KEYWORD,taobao,DIRECT",
            "DOMAIN-KEYWORD,tencent,DIRECT",
            "DOMAIN-KEYWORD,qq.com,DIRECT",
            "DOMAIN-KEYWORD,jd.com,DIRECT",
            "DOMAIN-KEYWORD,163.com,DIRECT",
            "DOMAIN-KEYWORD,bilibili,DIRECT",
            "DOMAIN-KEYWORD,douyin,DIRECT",
            "DOMAIN-KEYWORD,bytedance,DIRECT",
            "DOMAIN-KEYWORD,aliyun,DIRECT",
            "MATCH,PROXY",
        ],
    }


def main():
    if len(sys.argv) < 2:
        print("用法: python3 gen_config.py <订阅链接> [输出路径]", file=sys.stderr)
        sys.exit(1)

    sub_url = sys.argv[1]
    output = sys.argv[2] if len(sys.argv) > 2 else None

    data = fetch_subscription(sub_url)

    proxies = []
    for line in data.strip().splitlines():
        line = line.strip()
        if not line:
            continue
        if line.startswith("vless://"):
            p = parse_vless(line[len("vless://"):])
            if p:
                proxies.append(p)
        elif line.startswith("ss://"):
            p = parse_ss(line[len("ss://"):])
            if p:
                proxies.append(p)

    config = generate_config(proxies)
    result = yaml.dump(config, allow_unicode=True, default_flow_style=False, sort_keys=False)

    if output:
        with open(output, "w") as f:
            f.write(result)
        print(f"Config written to {output}", file=sys.stderr)
    else:
        print(result)


if __name__ == "__main__":
    main()
