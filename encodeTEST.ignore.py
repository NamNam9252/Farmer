import base91
import zlib
import smaz

SMAZ_FLAG = 0x01
ZLIB_FLAG = 0x02
RAW_FLAG  = 0x00
THRESHOLD = 100


def encode(text: str) -> str:
    raw = text.encode("utf-8")

    if len(raw) < THRESHOLD:
        smazed = smaz.compress(text)

        if len(smazed) < len(raw):
            payload = bytes([SMAZ_FLAG]) + smazed
        else:
            payload = bytes([RAW_FLAG]) + raw
    else:
        zlibbed = zlib.compress(raw, level=9)
        payload = bytes([ZLIB_FLAG]) + zlibbed

    return base91.encode(payload)

def decode(sms_text: str) -> str:
    payload = bytes(base91.decode(sms_text))

    flag = payload[0]
    data = payload[1:]

    if flag == SMAZ_FLAG:
        return smaz.decompress(data)

    if flag == ZLIB_FLAG:
        return zlib.decompress(data).decode("utf-8")

    return data.decode("utf-8")


# --- test ---
msg = "What is the weather tomorrow?"
enc = encode(msg)
print(f"|{enc}|")
print(decode("l_qHTf_QW>73iydFS!gw.WzG!u0hO:}lm_RyEccIf6TESC*mnIXbMAnIg.u=>Q/1Y"))

print("Original :", len(msg), "chars")
print("Encoded  :", len(enc), "chars")
print("Decoded  :", decode(enc))