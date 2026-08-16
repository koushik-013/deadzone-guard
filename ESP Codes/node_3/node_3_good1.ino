#include "painlessMesh.h"
#include "DHT.h"
#include <WiFi.h>

// =====================================================
//                    MESH CONFIG
// =====================================================

#define MESH_PREFIX    "DeadZoneGuard"
#define MESH_PASSWORD  "deadzone123"
#define MESH_PORT      5555

// =====================================================
//                    WIFI SSID (for channel scan)
// =====================================================

#define WIFI_SSID      "koushik"

// =====================================================
//                    SENSOR PINS
// =====================================================

#define MQ2_PIN        34
#define MQ135_PIN      32
#define DHT_PIN        4
#define DHT_TYPE       DHT21
#define VIBRATION_PIN  35
#define BUZZER_PIN     27
#define LED_PIN        26

#define NODE_NUMBER    3

// =====================================================
//                    THRESHOLDS
// =====================================================

#define MQ2_DANGER      1800
#define MQ2_CRITICAL    2200
#define MQ135_DANGER    2000
#define MQ135_CRITICAL  2800

// =====================================================
//                    OBJECTS
// =====================================================

Scheduler userScheduler;
painlessMesh mesh;
DHT dht(DHT_PIN, DHT_TYPE);

// =====================================================
//              AUTO CHANNEL DETECT
// =====================================================

int getWifiChannel(const char* ssid) {
  Serial.println("Scanning WiFi channel...");

  WiFi.mode(WIFI_STA);
  int n = WiFi.scanNetworks();

  if (n == 0) {
    Serial.println("No networks found! Using default channel 6");
    return 6;
  }

  for (int i = 0; i < n; i++) {
    if (WiFi.SSID(i) == String(ssid)) {
      int ch = WiFi.channel(i);
      Serial.println(
        "Found '" + String(ssid) +
        "' on channel: " + String(ch)
      );
      WiFi.scanDelete();
      return ch;
    }
  }

  WiFi.scanDelete();
  Serial.println("SSID not found! Using default channel 6");
  return 6;
}

// =====================================================
//                    ALERT FUNCTION
// =====================================================

void triggerAlert(String status) {
  if (status == "CRITICAL") {
    for (int i = 0; i < 4; i++) {
      digitalWrite(BUZZER_PIN, HIGH);
      digitalWrite(LED_PIN, HIGH);
      delay(150);
      digitalWrite(BUZZER_PIN, LOW);
      digitalWrite(LED_PIN, LOW);
      delay(150);
    }
  }
  else if (status == "DANGER") {
    digitalWrite(BUZZER_PIN, HIGH);
    digitalWrite(LED_PIN, HIGH);
    delay(500);
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(LED_PIN, LOW);
    delay(300);
  }
  else {
    digitalWrite(BUZZER_PIN, LOW);
    digitalWrite(LED_PIN, LOW);
  }
}

// =====================================================
//                    SEND SENSOR DATA
// =====================================================

void sendSensorData() {

  int mq2Value   = analogRead(MQ2_PIN);
  int mq135Value = analogRead(MQ135_PIN);
  float temp     = dht.readTemperature();
  float humidity = dht.readHumidity();
  int vibration  = digitalRead(VIBRATION_PIN);

  if (isnan(temp) || isnan(humidity)) {
    temp     = 0;
    humidity = 0;
  }

  // MQ2 STATUS
  String mq2Status = "SAFE";
  if (mq2Value > MQ2_DANGER)   mq2Status = "DANGER";
  if (mq2Value > MQ2_CRITICAL) mq2Status = "CRITICAL";

  // MQ135 STATUS
  String mq135Status = "SAFE";
  if (mq135Value > MQ135_DANGER)   mq135Status = "DANGER";
  if (mq135Value > MQ135_CRITICAL) mq135Status = "CRITICAL";

  // OVERALL STATUS
  String gasStatus = "SAFE";
  if (mq2Status == "CRITICAL" || mq135Status == "CRITICAL")
    gasStatus = "CRITICAL";
  else if (mq2Status == "DANGER" || mq135Status == "DANGER")
    gasStatus = "DANGER";

  // VIBRATION
  String vibStatus = (vibration == LOW) ? "VIBRATING" : "STABLE";

  triggerAlert(gasStatus);

  // SERIAL OUTPUT
  Serial.println();
  Serial.println("======================================");
  Serial.print("Node    : "); Serial.println(NODE_NUMBER);
  Serial.print("MQ2     : "); Serial.print(mq2Value);
  Serial.print(" | ");        Serial.println(mq2Status);
  Serial.print("MQ135   : "); Serial.print(mq135Value);
  Serial.print(" | ");        Serial.println(mq135Status);
  Serial.print("Overall : "); Serial.println(gasStatus);
  Serial.print("Temp    : "); Serial.print(temp, 1);
  Serial.println(" C");
  Serial.print("Hum     : "); Serial.print(humidity, 1);
  Serial.println(" %");
  Serial.print("Vib     : "); Serial.println(vibStatus);
  Serial.println("======================================");

  // BUILD + SEND MESH MESSAGE
  String msg =
    "NODE:"    + String(NODE_NUMBER)  +
    "|MQ2:"    + String(mq2Value)     +
    "|MQ2S:"   + mq2Status            +
    "|MQ135:"  + String(mq135Value)   +
    "|MQ135S:" + mq135Status          +
    "|STATUS:" + gasStatus            +
    "|TEMP:"   + String(temp, 1)      +
    "|HUM:"    + String(humidity, 1)  +
    "|VIB:"    + vibStatus;

  mesh.sendBroadcast(msg);
  Serial.println("Mesh Sent → " + msg);
}

// =====================================================
//                    TASK
// =====================================================

Task taskSend(TASK_SECOND * 2, TASK_FOREVER, &sendSensorData);

// =====================================================
//                    CALLBACKS
// =====================================================

void receivedCallback(uint32_t from, String &msg) {
  Serial.println();
  Serial.println("======================================");
  Serial.print("Received From Node: "); Serial.println(from);
  Serial.print("Message: ");           Serial.println(msg);
  Serial.println("======================================");

  if (msg.indexOf("STATUS:CRITICAL") >= 0)
    triggerAlert("CRITICAL");
  else if (msg.indexOf("STATUS:DANGER") >= 0)
    triggerAlert("DANGER");
}

void newConnectionCallback(uint32_t nodeId) {
  Serial.println();
  Serial.println("======================================");
  Serial.println("NEW MESH NODE CONNECTED");
  Serial.print("Node ID: "); Serial.println(nodeId);
  Serial.println("======================================");
  digitalWrite(BUZZER_PIN, HIGH);
  delay(100);
  digitalWrite(BUZZER_PIN, LOW);
}

void changedConnectionCallback() {
  Serial.println();
  Serial.println("Mesh connection changed.");
  Serial.print("Connected nodes: ");
  Serial.println(mesh.getNodeList().size());
}

void nodeTimeAdjustedCallback(int32_t offset) {
  Serial.print("Node time adjusted: ");
  Serial.println(offset);
}

// =====================================================
//                    SETUP
// =====================================================

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(MQ2_PIN,       INPUT);
  pinMode(MQ135_PIN,     INPUT);
  pinMode(VIBRATION_PIN, INPUT);
  pinMode(BUZZER_PIN,    OUTPUT);
  pinMode(LED_PIN,       OUTPUT);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN,    LOW);

  dht.begin();

  Serial.println("======================================");
  Serial.println("   DEADZONE GUARD — NODE 3 (BACKUP)");
  Serial.println("======================================");

  // ── Auto WiFi Channel Detection ──
  int meshChannel = getWifiChannel(WIFI_SSID);

  // ── Mesh Init ──
  mesh.init(
    MESH_PREFIX,
    MESH_PASSWORD,
    &userScheduler,
    MESH_PORT,
    WIFI_AP_STA,
    meshChannel   // ← auto detected
  );

  mesh.onReceive(&receivedCallback);
  mesh.onNewConnection(&newConnectionCallback);
  mesh.onChangedConnections(&changedConnectionCallback);
  mesh.onNodeTimeAdjusted(&nodeTimeAdjustedCallback);

  userScheduler.addTask(taskSend);
  taskSend.enable();

  // Startup beep
  digitalWrite(BUZZER_PIN, HIGH);
  digitalWrite(LED_PIN,    HIGH);
  delay(300);
  digitalWrite(BUZZER_PIN, LOW);
  digitalWrite(LED_PIN,    LOW);

  Serial.println("======================================");
  Serial.println("       NODE 3 READY");
  Serial.println("======================================");
  Serial.print("Node ID : "); Serial.println(mesh.getNodeId());
  Serial.print("Channel : "); Serial.println(meshChannel);
  Serial.println("======================================");
}

// =====================================================
//                    LOOP
// =====================================================

void loop() {
  mesh.update();
  delay(10);
}