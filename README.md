# DeadZone Guard 🛡️

**An ESP-MESH and Machine Learning-Based Multi-Sensor Safety Monitoring System with Real-Time Mobile and Bangla Voice Alerts**

> IoT-based worker safety monitoring framework designed for hazardous and connectivity-constrained industrial environments.

---

## 📋 Overview

DeadZone Guard integrates ESP32 sensor nodes, painlessMesh networking, MQTT communication, a Python ML server, Firebase Cloud Firestore, and a Flutter mobile application into a unified safety monitoring pipeline.

The system continuously monitors:
- 🔥 Gas levels (MQ-2: LPG/Smoke, MQ-135: Air Quality)
- 🌡️ Temperature & Humidity (DHT21)
- 📳 Vibration events (SW-420)

When hazardous conditions are detected, the system triggers:
- 📱 Real-time mobile dashboard alerts
- 🔊 Bangla voice warnings ("পালাও পালাও, গ্যাস ডিটেক্ট হয়েছে")
- ☁️ Cloud logging to Firebase Firestore
- 🚨 SOS emergency notification

---

## 🏗️ System Architecture

```
ESP32 Node 1 (Sensor) ──┐
                         ├──► painlessMesh ──► ESP32 Gateway ──► MQTT Broker
ESP32 Node 3 (Sensor) ──┘                          │
                                                    ▼
                                           Python ML Server
                                          (Extra Trees Model)
                                                    │
                                         ┌──────────┴──────────┐
                                         ▼                      ▼
                                   Flutter App           Firebase Firestore
                                  (Dashboard +           (sensor_logs +
                                  Voice Alert +           sos_logs)
                                   SOS Button)
```

---

## ✨ Key Features

| Feature | Description |
|---|---|
| **ESP-MESH Network** | Fault-tolerant mesh — one node fails, others continue |
| **Dead Zone Detection** | Auto-detects silent nodes after 30s timeout |
| **ML Classification** | Extra Trees model — 95.08% test accuracy |
| **Vibration Override** | Immediate DANGER on vibration, bypasses ML |
| **Bangla Voice Alert** | 10s continuous danger → Bangla TTS warning |
| **Firebase Firestore** | Cloud storage for sensor logs and SOS events |
| **SOS Button** | One-tap emergency notification with location context |
| **Primary/Backup Node** | Node 1 primary, Node 3 backup — auto failover |

---

## 🤖 ML Model

- **Algorithm:** Extra Trees Classifier
- **Dataset:** 16,066 samples (field-collected + synthetic augmentation)
- **Features:** Temperature, Humidity, MQ-2, MQ-135
- **Classes:** Good | Moderate | Unhealthy for Sensitive Groups | Unhealthy
- **Training Accuracy:** 99.53%
- **Test Accuracy:** 95.08%
- **Macro F1-Score:** 0.95

| Class | Precision | Recall | F1 |
|---|---|---|---|
| Good | 0.98 | 0.97 | 0.97 |
| Moderate | 0.93 | 0.96 | 0.94 |
| Unhealthy | 0.97 | 0.95 | 0.96 |
| Unhealthy for Sensitive Groups | 0.92 | 0.91 | 0.92 |

---

## 🛠️ Hardware Components

| Component | Quantity | Purpose |
|---|---|---|
| ESP32 NodeMCU DEVKITV1 | 3 | Sensor nodes (×2) + Gateway (×1) |
| MQ-2 Gas Sensor | 1 | LPG / Smoke detection |
| MQ-135 Air Quality Sensor | 1 | CO2 / NH3 / Benzene |
| DHT21 Temperature & Humidity | 1 | Temp + Humidity |
| SW-420 Vibration Sensor | 1 | Physical disturbance |
| Piezo Buzzer | 1 | Local audio alert |
| LED | 1 | Visual indicator |

### Pin Configuration (Sensor Nodes)

| Sensor | ESP32 Pin |
|---|---|
| MQ-2 OUT | GPIO 34 |
| MQ-135 A0 | GPIO 32 |
| DHT21 DATA | GPIO 4 |
| SW-420 D0 | GPIO 35 |
| Buzzer (+) | GPIO 27 |
| LED (+) | GPIO 26 |

---

## 📁 Project Structure

```
deadzone-guard/
│
├── arduino/
│   ├── node1_sensor/          # Node 1 — primary sensor node
│   ├── node3_sensor/          # Node 3 — backup sensor node
│   └── node2_gateway/         # Node 2 — MQTT gateway
│
├── ml_server/
│   ├── ml_mqtt_server.py      # Python ML server (MQTT + Firebase)
│   ├── deadzone_guard_model.pkl
│   ├── label_encoder.pkl
│   └── firebase_key.json      # (not included — add your own)
│
├── flutter_app/
│   └── deadzone_guard/        # Flutter mobile application
│       ├── lib/
│       │   ├── main.dart
│       │   ├── mqtt_service.dart
│       │   ├── models/
│       │   │   └── sensor_data.dart
│       │   └── screens/
│       │       ├── dashboard_screen.dart
│       │       ├── zone_detail_screen.dart
│       │       ├── history_screen.dart
│       │       └── firebase_history_screen.dart
│       └── pubspec.yaml
│
├── ml_training/
│   ├── DeadZoneGuard_Training_Improved.ipynb
│   └── deadzone_improved_dataset.csv
│
└── README.md
```

---

## 🚀 Setup Guide

### 1. Arduino (ESP32 Nodes)

**Install libraries:**
- `painlessMesh` by Coopdis, Scotty (v1.5.7)
- `DHT sensor library` by Adafruit
- `PubSubClient` by Nick O'Leary

**Board settings:**
- Board: `ESP32 Dev Module`
- Upload Speed: `115200`

**Upload order:**
1. Upload `node1_sensor` to Node 1 ESP32
2. Upload `node3_sensor` to Node 3 ESP32
3. Upload `node2_gateway` to Node 2 ESP32 (Gateway)

> **Note:** WiFi channel is auto-detected from SSID scan — no manual configuration needed.

---

### 2. MQTT Broker

Install Mosquitto:
```bash
# Windows
# Download from https://mosquitto.org/download/

# macOS
brew install mosquitto
```

Add to `mosquitto.conf`:
```
listener 1883
allow_anonymous true

listener 9001
protocol websockets
allow_anonymous true
```

Run:
```bash
mosquitto -c mosquitto.conf -v
```

---

### 3. Python ML Server

**Install dependencies:**
```bash
pip install paho-mqtt joblib numpy scikit-learn firebase-admin
```

**Setup Firebase:**
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create project → Firestore Database
3. Project Settings → Service Accounts → Generate new private key
4. Save as `firebase_key.json` in `ml_server/` folder

**Configure `ml_mqtt_server.py`:**
```python
MQTT_BROKER = "your_laptop_ip"   # e.g. 192.168.0.194
MQTT_PORT   = 1883
```

**Run:**
```bash
python ml_mqtt_server.py
```

---

### 4. Flutter App

**Install dependencies:**
```bash
cd flutter_app/deadzone_guard
flutter pub get
```

**Configure Firebase:**
```bash
flutterfire configure
```

**Update MQTT broker IP in `mqtt_service.dart`:**
```dart
static const String _broker = 'your_laptop_ip';
```

**Build APK:**
```bash
flutter build apk --debug
```

---

## 📡 MQTT Topics

| Topic | Publisher | Subscriber | Content |
|---|---|---|---|
| `deadzone/sensors` | Gateway | ML Server, Flutter | Raw sensor data |
| `deadzone/ml_result` | ML Server | Flutter | ML prediction JSON |
| `deadzone/alerts` | Gateway, ML Server | Flutter | Dead zone & safety alerts |
| `deadzone/sos` | Flutter | Flutter, Gateway | SOS emergency events |

---

## 🔔 Alert Logic

```
Sensor Data (every 2s)
        ↓
Vibration = VIBRATING?
        ↓ YES → DANGER (100% confidence, bypasses ML)
        ↓ NO
MQ2 > 2200 or MQ135 > 2800?
        ↓ YES → Unhealthy (100% confidence, bypasses ML)
        ↓ NO
Extra Trees ML Model
        ↓
Good / Moderate / Unhealthy for Sensitive Groups / Unhealthy
        ↓
Flutter App — 10s continuous DANGER?
        ↓ YES
🔊 Bangla Voice Alert
```

---

## 🗄️ Firebase Collections

**`sensor_logs`** — every ML prediction:
```json
{
  "node": 1,
  "prediction": "Good",
  "confidence": 97.36,
  "reason": "ML MODEL",
  "temperature": 29.8,
  "humidity": 99.2,
  "mq2": 142,
  "mq135": 118,
  "vibration": "STABLE",
  "timestamp": "2026-08-06T..."
}
```

**`sos_logs`** — SOS events:
```json
{
  "node": 1,
  "status": "ACTIVE",
  "message": "SOS triggered by user",
  "temperature": 29.8,
  "mq2": 142,
  "timestamp": "2026-08-06T..."
}
```

---

## 📄 Paper

This system was presented at:

> **DeadZone Guard: An ESP-MESH and Machine Learning-Based Multi-Sensor Safety Monitoring System with Real-Time Mobile and Bangla Voice Alerts**
> Koushik Biswas et al.
> Department of Internet of Things and Robotics Engineering
> Bangabandhu Sheikh Mujibur Rahman Digital University, Bangladesh

---

## 👥 Team

| Member | Role |
|---|---|
| Koushik Biswas | Hardware, ESP32 Mesh, ML Server |
| [Teammate 2] | Flutter App, Firebase |
| [Teammate 3] | ML Training, Paper Writing |

---

## 📜 License

MIT License — feel free to use, modify, and distribute with attribution.

---

## 🙏 Acknowledgements

- [painlessMesh](https://github.com/gmag11/painlessMesh) — ESP32 mesh networking
- [PubSubClient](https://github.com/knolleary/pubsubclient) — MQTT client
- [Flutter TTS](https://pub.dev/packages/flutter_tts) — Bangla voice alerts
- [Firebase](https://firebase.google.com) — Cloud storage
