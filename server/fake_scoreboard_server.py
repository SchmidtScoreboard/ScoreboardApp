from flask import Flask, jsonify
import socket
import json
import time

app = Flask(__name__)

def get_response():
    time.sleep(5) 
    with open("scoreboard_settings.json") as f:
        settings = json.load(f)
        return jsonify(settings)

@app.route('/<path:text>', methods=['GET', 'POST'])
def all_routes(text):
    return get_response()

@app.route('/', methods=['GET', 'POST'])
def root():
    return get_response()

def alphabet():
    out = []
    for c in range(ord("A"), ord("Z") + 1):
        out.append(chr(c))
    return out


def ip_to_code(ip_address):
    out = ""
    alph = alphabet()
    octets = [int(x) for x in ip_address.split(".")]
    for octet in octets:
        mod = octet // len(alph)
        rem = octet % len(alph)
        out += "{}{}".format(alph[mod], alph[rem])
    return out

def get_ip_address():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))  # attempt to connect, and then get hostname
        return s.getsockname()[0]
    except:
        return ""

if __name__ == "__main__":
    print(ip_to_code(get_ip_address()))
    app.run(debug=True, host="0.0.0.0", port=5005)