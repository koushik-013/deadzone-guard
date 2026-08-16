import json
import joblib
import numpy as np
import paho.mqtt.client as mqtt
import firebase_admin
from firebase_admin import credentials, firestore
from datetime import datetime, timezone


MQTT_BROKER = "10.64.249.52"
MQTT_PORT = 1883

INPUT_TOPIC = "deadzone/sensors"
OUTPUT_TOPIC = "deadzone/ml_result"

MODEL_PATH = "deadzone_guard_model.pkl"
ENCODER_PATH = "label_encoder.pkl"
FIREBASE_KEY = "firebase_key.json"

MQ2_DANGER_THRESHOLD = 1800
MQ135_DANGER_THRESHOLD = 2000


print("========================================")
print("       DEADZONE GUARD ML SERVER")
print("========================================")


print("\nLoading ML model...")

try:
    model = joblib.load(MODEL_PATH)
    label_encoder = joblib.load(ENCODER_PATH)

    print("Model loaded successfully")
    print("Classes:", list(label_encoder.classes_))

except Exception as e:
    print("Model loading failed:", e)
    raise


print("\nInitializing Firebase...")

try:
    cred = credentials.Certificate(FIREBASE_KEY)

    firebase_admin.initialize_app(cred)

    db = firestore.client()

    print("Firebase connected successfully")

except Exception as e:
    print("Firebase initialization failed:", e)
    raise


def parse_sensor_message(message):

    data = {}

    for part in message.split("|"):

        if ":" in part:

            key, value = part.split(":", 1)

            data[key.strip().upper()] = value.strip()

    return data


def predict_sensor(data):

    try:

        node = int(data.get("NODE", 0))

        temperature = float(data["TEMP"])

        humidity = float(data["HUM"])

        mq2 = float(data["MQ2"])

        mq135 = float(data["MQ135"])

        mq2 = max(0, min(4095, mq2))

        mq135 = max(0, min(4095, mq135))

        vibration = data.get("VIB", "STABLE").upper()


        base = {
            "node": node,
            "temperature": temperature,
            "humidity": humidity,
            "mq2": mq2,
            "mq135": mq135,
            "vibration": vibration
        }


        if vibration == "VIBRATING":

            print("VIBRATION DETECTED")

            return {
                **base,
                "prediction": "DANGER",
                "reason": "VIBRATION DETECTED",
                "confidence": 100.0
            }


        if (
            mq2 >= MQ2_DANGER_THRESHOLD
            or
            mq135 >= MQ135_DANGER_THRESHOLD
        ):

            danger_sensor = []

            if mq2 >= MQ2_DANGER_THRESHOLD:

                danger_sensor.append(
                    f"MQ2 HIGH ({mq2:.0f})"
                )

            if mq135 >= MQ135_DANGER_THRESHOLD:

                danger_sensor.append(
                    f"MQ135 HIGH ({mq135:.0f})"
                )

            reason = (
                "GAS DETECTED - "
                + " + ".join(danger_sensor)
            )

            print("GAS SAFETY OVERRIDE")

            print("MQ2:", mq2)

            print("MQ135:", mq135)

            return {
                **base,
                "prediction": "DANGER",
                "reason": reason,
                "confidence": 100.0
            }


        X = np.array(
            [[
                temperature,
                humidity,
                mq2,
                mq135
            ]],
            dtype=float
        )


        prediction_number = model.predict(X)[0]


        prediction_label = str(
            label_encoder.inverse_transform(
                [prediction_number]
            )[0]
        )


        confidence = None


        if hasattr(model, "predict_proba"):

            probabilities = model.predict_proba(X)[0]

            confidence = float(
                np.max(probabilities) * 100
            )


        return {
            **base,
            "prediction": prediction_label,
            "reason": "ML MODEL",
            "confidence": (
                round(confidence, 2)
                if confidence is not None
                else None
            )
        }


    except Exception as e:

        print("Prediction error:", e)

        return None


def save_to_firestore(result):

    try:

        doc_data = {
            **result,
            "timestamp": datetime.now(timezone.utc)
        }

        db.collection("sensor_logs").add(doc_data)

        print(
            "Saved to Firestore -> sensor_logs"
        )

    except Exception as e:

        print(
            "Firestore save error:",
            e
        )


def on_connect(
    client,
    userdata,
    flags,
    reason_code,
    properties=None
):

    if reason_code == 0:

        print("\n========================================")
        print("MQTT CONNECTED")
        print("========================================")

        print(
            "Broker:",
            MQTT_BROKER
        )

        print(
            "Input Topic:",
            INPUT_TOPIC
        )

        print(
            "Output Topic:",
            OUTPUT_TOPIC
        )


        client.subscribe(
            INPUT_TOPIC,
            qos=1
        )

        print(
            "Subscribed:",
            INPUT_TOPIC
        )

    else:

        print(
            "MQTT connection failed:",
            reason_code
        )


def on_message(client, userdata, msg):

    try:

        raw_message = msg.payload.decode(
            "utf-8"
        )


        print("\n========================================")
        print("ESP32 DATA RECEIVED")
        print("========================================")

        print(raw_message)


        if "GATEWAY:ALIVE" in raw_message:

            print(
                "Gateway heartbeat ignored"
            )

            return


        sensor_data = parse_sensor_message(
            raw_message
        )


        print("\nParsed data:")

        print(sensor_data)


        if "NODE" not in sensor_data:

            print(
                "Invalid sensor message ignored"
            )

            return


        result = predict_sensor(
            sensor_data
        )


        if result is None:

            print(
                "Prediction failed"
            )

            return


        print("\n========================================")
        print("DEADZONE GUARD ML RESULT")
        print("========================================")

        print(
            "Node       :",
            result["node"]
        )

        print(
            "Prediction :",
            result["prediction"]
        )

        print(
            "Reason     :",
            result["reason"]
        )

        print(
            "Confidence :",
            result["confidence"]
        )

        print(
            "Temperature:",
            result["temperature"]
        )

        print(
            "Humidity   :",
            result["humidity"]
        )

        print(
            "MQ2        :",
            result["mq2"]
        )

        print(
            "MQ135      :",
            result["mq135"]
        )

        print(
            "Vibration  :",
            result["vibration"]
        )


        output = json.dumps(
            result
        )


        publish_result = client.publish(
            OUTPUT_TOPIC,
            output,
            qos=1
        )


        if (
            publish_result.rc
            == mqtt.MQTT_ERR_SUCCESS
        ):

            print(
                "\nPublished to:",
                OUTPUT_TOPIC
            )

            print(output)

        else:

            print(
                "MQTT publish failed:",
                publish_result.rc
            )


        save_to_firestore(
            result
        )


    except Exception as e:

        print(
            "MQTT message handling error:",
            e
        )


client = mqtt.Client(
    mqtt.CallbackAPIVersion.VERSION2,
    client_id="DeadZone_ML_Server"
)


client.on_connect = on_connect

client.on_message = on_message


client.reconnect_delay_set(
    min_delay=1,
    max_delay=30
)


print("\n========================================")
print("SERVER CONFIGURATION")
print("========================================")

print(
    "Broker       :",
    MQTT_BROKER
)

print(
    "Port         :",
    MQTT_PORT
)
print(
    "Input Topic  :",
    INPUT_TOPIC
)
print(
    "Output Topic :",
    OUTPUT_TOPIC
)
print(
    "Model        :",
    MODEL_PATH
)
print(
    "Encoder      :",
    ENCODER_PATH
)
print(
    "MQ2 Danger   :",
    MQ2_DANGER_THRESHOLD
)
print(
    "MQ135 Danger :",
    MQ135_DANGER_THRESHOLD
)
print("\nConnecting to MQTT...")
try:

    client.connect(
        MQTT_BROKER,
        MQTT_PORT,
        60
    )
except Exception as e:

    print(
        "MQTT connection error:",
        e
    )
    raise

print("\n========================================")
print("SERVER STARTED")
print("========================================")
print(
    "Waiting for ESP32 sensor data..."
)
try:
    client.loop_forever()
except KeyboardInterrupt:
    print(
        "\nServer stopped by user."
    )
    try:
        client.disconnect()
    except Exception:
        pass