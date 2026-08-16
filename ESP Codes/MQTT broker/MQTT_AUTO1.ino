#include "painlessMesh.h"
#include <WiFi.h>
#include <PubSubClient.h>

#define MESH_PREFIX    "DeadZoneGuard"
#define MESH_PASSWORD  "deadzone123"
#define MESH_PORT      5555

#define WIFI_SSID      "koushik"
#define WIFI_PASSWORD  "12345678"

#define MQTT_SERVER    "10.64.249.52"
#define MQTT_PORT      1883
#define MQTT_TOPIC     "deadzone/sensors"
#define ALERT_TOPIC    "deadzone/alerts"

#define DEAD_ZONE_TIMEOUT  30000
#define HEARTBEAT_INTERVAL 10000
#define QUEUE_SIZE         10

String messageQueue[QUEUE_SIZE];
int queueHead = 0;
int queueTail = 0;
int queueCount = 0;

painlessMesh mesh;
Scheduler userScheduler;
WiFiClient wifiClient;
PubSubClient mqttClient(wifiClient);

unsigned long lastSeenNode1 = 0;
unsigned long lastSeenNode3 = 0;

bool node1AlertSent = false;
bool node3AlertSent = false;

unsigned long lastMqttCheck = 0;
unsigned long lastWifiCheck = 0;
unsigned long lastHeartbeat = 0;


void enqueue(String msg) {
  if (queueCount >= QUEUE_SIZE) {
    queueHead = (queueHead + 1) % QUEUE_SIZE;
    queueCount--;
  }

  messageQueue[queueTail] = msg;
  queueTail = (queueTail + 1) % QUEUE_SIZE;
  queueCount++;
}


String dequeue() {
  if (queueCount <= 0) {
    return "";
  }

  String msg = messageQueue[queueHead];

  queueHead = (queueHead + 1) % QUEUE_SIZE;
  queueCount--;

  return msg;
}


int getWifiChannel(const char* ssid) {

  Serial.println("Scanning WiFi channel...");

  WiFi.mode(WIFI_STA);

  int n = WiFi.scanNetworks();

  for (int i = 0; i < n; i++) {

    if (WiFi.SSID(i) == ssid) {

      int ch = WiFi.channel(i);

      Serial.println(
        "Channel found: " + String(ch)
      );

      WiFi.scanDelete();

      return ch;
    }
  }

  WiFi.scanDelete();

  Serial.println("Fallback channel: 6");

  return 6;
}


void connectWiFi() {

  if (WiFi.status() == WL_CONNECTED) {
    return;
  }

  Serial.println("Connecting WiFi...");

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;

  while (
    WiFi.status() != WL_CONNECTED &&
    attempts < 20
  ) {

    delay(500);

    Serial.print(".");

    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {

    Serial.println();

    Serial.println(
      "WiFi OK: " +
      WiFi.localIP().toString()
    );

  } else {

    Serial.println();
    Serial.println("WiFi Failed!");
  }
}


bool connectMQTT() {

  if (mqttClient.connected()) {
    return true;
  }

  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }

  String clientId =
    "Gateway_" +
    String((uint32_t)ESP.getEfuseMac(), HEX);

  Serial.println("Connecting MQTT...");

  if (mqttClient.connect(clientId.c_str())) {

    Serial.println("MQTT Connected!");

    mqttClient.publish(
      ALERT_TOPIC,
      "GATEWAY|STATUS:ONLINE|MSG:Gateway connected"
    );

    return true;
  }

  Serial.println(
    "MQTT Failed: " +
    String(mqttClient.state())
  );

  return false;
}


void receivedCallback(
  uint32_t from,
  String &msg
) {

  Serial.println("Mesh → " + msg);

  if (msg.indexOf("NODE:1") >= 0) {

    lastSeenNode1 = millis();

    if (node1AlertSent) {

      node1AlertSent = false;

      Serial.println("Node 1 restored!");

      if (mqttClient.connected()) {

        mqttClient.publish(
          ALERT_TOPIC,
          "DEADZONE|NODE:1|STATUS:RESTORED|MSG:Node 1 back online"
        );
      }
    }
  }


  if (msg.indexOf("NODE:3") >= 0) {

    lastSeenNode3 = millis();

    if (node3AlertSent) {

      node3AlertSent = false;

      Serial.println("Node 3 restored!");

      if (mqttClient.connected()) {

        mqttClient.publish(
          ALERT_TOPIC,
          "DEADZONE|NODE:3|STATUS:RESTORED|MSG:Node 3 back online"
        );
      }
    }
  }

  enqueue(msg);
}


void newConnectionCallback(uint32_t nodeId) {

  Serial.println(
    "New node: " +
    String(nodeId)
  );
}


void changedConnectionCallback() {

  size_t nodeCount =
    mesh.getNodeList().size();

  Serial.println(
    "Mesh changed. Nodes: " +
    String(nodeCount)
  );

  if (nodeCount == 0) {

    Serial.println(
      "All nodes disconnected — waiting..."
    );
  }
}


void setup() {

  Serial.begin(115200);

  delay(1000);

  WiFi.mode(WIFI_AP_STA);

  int meshChannel =
    getWifiChannel(WIFI_SSID);

  connectWiFi();

  mqttClient.setServer(
    MQTT_SERVER,
    MQTT_PORT
  );

  mqttClient.setKeepAlive(60);
  mqttClient.setSocketTimeout(10);

  connectMQTT();


  mesh.setDebugMsgTypes(
    ERROR | STARTUP
  );

  mesh.init(
    MESH_PREFIX,
    MESH_PASSWORD,
    &userScheduler,
    MESH_PORT,
    WIFI_AP_STA,
    meshChannel
  );

  mesh.stationManual(
    WIFI_SSID,
    WIFI_PASSWORD
  );

  mesh.setContainsRoot(true);

  mesh.onReceive(
    &receivedCallback
  );

  mesh.onNewConnection(
    &newConnectionCallback
  );

  mesh.onChangedConnections(
    &changedConnectionCallback
  );


  Serial.println(
    "======================================"
  );

  Serial.println(
    "  DEADZONE GUARD — GATEWAY READY"
  );

  Serial.println(
    "  Dead Zone Detection: ACTIVE"
  );

  Serial.print(
    "  Mesh Channel: "
  );

  Serial.println(meshChannel);

  Serial.println(
    "======================================"
  );
}


void loop() {

  mesh.update();


  if (
    millis() - lastWifiCheck >
    10000
  ) {

    lastWifiCheck = millis();

    if (WiFi.status() != WL_CONNECTED) {
      connectWiFi();
    }
  }


  if (
    millis() - lastMqttCheck >
    1000
  ) {

    lastMqttCheck = millis();


    if (!mqttClient.connected()) {
      connectMQTT();
    }


    if (
      mqttClient.connected() &&
      queueCount > 0
    ) {

      String msg = dequeue();

      if (msg.length() > 0) {

        bool ok =
          mqttClient.publish(
            MQTT_TOPIC,
            msg.c_str()
          );

        if (ok) {

          Serial.println(
            "MQTT OK → " + msg
          );

        } else {

          Serial.println(
            "MQTT Publish Failed"
          );

          enqueue(msg);
        }
      }
    }


    if (mqttClient.connected()) {

      unsigned long now = millis();


      if (
        lastSeenNode1 > 0 &&
        !node1AlertSent &&
        (now - lastSeenNode1) >
        DEAD_ZONE_TIMEOUT
      ) {

        mqttClient.publish(
          ALERT_TOPIC,
          "DEADZONE|NODE:1|STATUS:DEAD|MSG:Node 1 not responding for 30s"
        );

        Serial.println(
          "DEAD ZONE ALERT: Node 1!"
        );

        node1AlertSent = true;
      }


      if (
        lastSeenNode3 > 0 &&
        !node3AlertSent &&
        (now - lastSeenNode3) >
        DEAD_ZONE_TIMEOUT
      ) {

        mqttClient.publish(
          ALERT_TOPIC,
          "DEADZONE|NODE:3|STATUS:DEAD|MSG:Node 3 not responding for 30s"
        );

        Serial.println(
          "DEAD ZONE ALERT: Node 3!"
        );

        node3AlertSent = true;
      }
    }
  }


  if (
    millis() - lastHeartbeat >
    HEARTBEAT_INTERVAL
  ) {

    lastHeartbeat = millis();

    mesh.sendBroadcast(
      "GATEWAY:ALIVE"
    );

    Serial.println(
      "Heartbeat sent"
    );
  }


  if (mqttClient.connected()) {
    mqttClient.loop();
  }
}