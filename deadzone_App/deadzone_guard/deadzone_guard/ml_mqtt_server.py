import json
import joblib
import numpy as np
import paho.mqtt.client as mqtt


# ============================================================
# CONFIG
# ============================================================

MQTT_BROKER = "10.64.249.52"
MQTT_PORT = 1883

INPUT_TOPIC = "deadzone/sensors"
OUTPUT_TOPIC = "deadzone/ml_result"

MODEL_PATH = "deadzone_guard_model.pkl"
ENCODER_PATH = "label_encoder.pkl"


# ============================================================
# LOAD MODEL
# ============================================================

print("Loading ML model...")

model = joblib.load(MODEL_PATH)
label_encoder = joblib.load(ENCODER_PATH)

print("✅ ML model loaded")
print("Classes:", list(label_encoder.classes_))


# ============================================================
# PARSE ESP32 MESSAGE
# ============================================================

def parse_sensor_message(message):

    data = {}

    parts = message.split("|")

    for part in parts:

        if ":" in part:

            key, value = part.split(":", 1)

            data[key.strip().upper()] = value.strip()

    return data


# ============================================================
# ML PREDICTION
# ============================================================

def predict_sensor(data):

    try:

        node = int(data.get("NODE", 0))

        temperature = float(data["TEMP"])
        humidity = float(data["HUM"])
        mq2 = float(data["MQ2"])
        mq135 = float(data["MQ135"])

        vibration = data.get("VIB", "STABLE").upper()

        # ----------------------------------------------------
        # VIBRATION SAFETY RULE
        # ----------------------------------------------------

        if vibration == "VIBRATING":

            return {
                "node": node,
                "prediction": "DANGER",
                "reason": "VIBRATION DETECTED",
                "confidence": 100.0,
                "temperature": temperature,
                "humidity": humidity,
                "mq2": mq2,
                "mq135": mq135,
                "vibration": vibration
            }

        # ----------------------------------------------------
        # ML MODEL
        # Features:
        # temperature
        # humidity
        # mq2
        # mq135
        # ----------------------------------------------------

        X = np.array([
            [temperature, humidity, mq2, mq135]
        ])

        prediction_number = model.predict(X)[0]

        prediction_label = label_encoder.inverse_transform(
            [prediction_number]
        )[0]

        # Confidence
        confidence = None

        if hasattr(model, "predict_proba"):

            probabilities = model.predict_proba(X)[0]

            confidence = float(
                np.max(probabilities) * 100
            )

        return {
            "node": node,
            "prediction": str(prediction_label),
            "reason": "ML MODEL",
            "confidence": round(confidence, 2) if confidence else None,
            "temperature": temperature,
            "humidity": humidity,
            "mq2": mq2,
            "mq135": mq135,
            "vibration": vibration
        }

    except Exception as e:

        print("❌ Prediction error:", e)

        return None


# ============================================================
# MQTT CONNECT
# ============================================================

def on_connect(client, userdata, flags, reason_code, properties=None):

    if reason_code == 0:

        print("=================================")
        print("MQTT CONNECTED")
        print("=================================")

        client.subscribe(INPUT_TOPIC)

        print("Subscribed:", INPUT_TOPIC)

    else:

        print("❌ MQTT connection failed:", reason_code)


# ============================================================
# MQTT MESSAGE RECEIVED
# ============================================================

def on_message(client, userdata, msg):

    raw_message = msg.payload.decode("utf-8")

    print("\n=================================")
    print("ESP32 DATA RECEIVED")
    print("=================================")

    print(raw_message)

    # Parse
    sensor_data = parse_sensor_message(raw_message)

    print("\nParsed data:")
    print(sensor_data)

    # ML prediction
    result = predict_sensor(sensor_data)

    if result is None:

        return

    print("\n=================================")
    print("ML RESULT")
    print("=================================")

    print("Node       :", result["node"])
    print("Prediction :", result["prediction"])
    print("Reason     :", result["reason"])
    print("Confidence :", result["confidence"])
    print("Vibration  :", result["vibration"])

    # --------------------------------------------------------
    # Publish JSON to Flutter
    # --------------------------------------------------------

    output = json.dumps(result)

    client.publish(
        OUTPUT_TOPIC,
        output,
        qos=1
    )

    print("\n✅ Published to:", OUTPUT_TOPIC)
    print(output)


# ============================================================
# MQTT CLIENT
# ============================================================

client = mqtt.Client(
    mqtt.CallbackAPIVersion.VERSION2,
    client_id="DeadZone_ML_Server"
)

client.on_connect = on_connect
client.on_message = on_message


# ============================================================
# START
# ============================================================

print("\n=================================")
print("DEADZONE GUARD ML SERVER")
print("=================================")

print("Broker :", MQTT_BROKER)
print("Port   :", MQTT_PORT)
print("Input  :", INPUT_TOPIC)
print("Output :", OUTPUT_TOPIC)

print("\nConnecting to MQTT...")

client.connect(
    MQTT_BROKER,
    MQTT_PORT,
    60
)

print("Waiting for ESP32 sensor data...\n")

client.loop_forever()