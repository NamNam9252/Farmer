import { encode, decode } from "../src/modules/sms/sms.codec.ts";
import { buildPacket } from "../src/modules/sms/sms.parser.ts";

const samples = [
  "hello world",
  "market price wheat?",
  "こんにちは",
  "नमस्ते किसान",
  "emoji 😀 test",
  "a".repeat(120),
  JSON.stringify({ q: "soil moisture low", x: 42 }),
];

let failures = 0;

for (const s of samples) {
  const enc = encode(s);
  let dec = "";
  let ok = false;

  try {
    dec = decode(enc);
    ok = dec === s;
  } catch (e) {
    dec = `[THREW] ${e instanceof Error ? e.message : String(e)}`;
  }

  console.log("---");
  console.log("sample:", JSON.stringify(s));
  console.log("encodedLen:", Buffer.byteLength(enc, "utf-8"));
  console.log("decodedMatches:", ok);
  if (!ok) {
    failures += 1;
    console.log("decoded:", JSON.stringify(dec));
  }

  const packetContent = buildPacket("Ab", 0, 1, 2, Buffer.from(enc, "utf-8"));

  let packetDecoded = "";
  let packetDecodeOk = false;
  try {
    packetDecoded = decode(packetContent);
    packetDecodeOk = packetDecoded === s;
  } catch {
    packetDecodeOk = false;
  }

  console.log("decode(packetContent)MatchesOriginal:", packetDecodeOk);
  if (!packetDecodeOk) {
    console.log("decode(packetContent)Preview:", JSON.stringify(packetDecoded.slice(0, 120)));
  }
}

console.log("---");
console.log("totalFailures:", failures);
