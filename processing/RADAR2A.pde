/********************************************************************
 * VISUALISATION RADAR - PROCESSING pour Arduino Nano
 * Communication Serial USB uniquement
 * Version optimisée et fiable
 ********************************************************************/

import processing.serial.*;

// ================= CONFIGURATION =================
String PORT_NAME = "/dev/ttyUSB0"; // Linux
// String PORT_NAME = "COM3";       // Windows
// String PORT_NAME = "/dev/cu.usbmodem14101"; // Mac

int BAUD_RATE = 9600;              // Doit correspondre à l'Arduino

// ================= VARIABLES GLOBALES =================
Serial arduinoPort;
boolean isConnected = false;
String connectionStatus = "Déconnecté";

// Données radar
float angle = 0;
float distance = 0;
int alertLevel = 0;

// Historique pour 360 degrés
float[] distanceHistory = new float[360];
int[] alertHistory = new int[360];

// Couleurs
color backgroundColor = color(10, 15, 30);
color gridColor = color(0, 150, 100, 100);
color sweepColor = color(0, 255, 150);
color objectColor = color(255, 50, 50);
color alertColor = color(255, 0, 0);
color textColor = color(200, 240, 255);

// État
boolean showHelp = true;
boolean autoReconnect = true;
boolean isFullScreen = false;
long lastDataTime = 0;
final long RECONNECT_TIMEOUT = 5000; // 5 secondes

// ================= SETUP =================
void setup() {
  // Taille initiale de la fenêtre
  size(1000, 700);
  surface.setTitle("Radar System - Arduino Nano");
  surface.setResizable(true);
  
  smooth();
  textSize(16);
  
  // Initialiser l'historique
  for (int i = 0; i < 360; i++) {
    distanceHistory[i] = 0;
    alertHistory[i] = 0;
  }
  
  // Connexion initiale
  connectToArduino();
  
  println("Système Radar - Arduino Nano");
  println("Attente de données...");
}

// ================= CONNEXION ARDUINO =================
void connectToArduino() {
  try {
    // Fermer l'ancienne connexion si elle existe
    if (arduinoPort != null) {
      arduinoPort.stop();
      arduinoPort = null;
    }
    
    // Essayer de se connecter
    arduinoPort = new Serial(this, PORT_NAME, BAUD_RATE);
    arduinoPort.bufferUntil('\n');
    arduinoPort.clear();
    
    isConnected = true;
    connectionStatus = "Connecté à " + PORT_NAME;
    lastDataTime = millis();
    
    println("✓ Connecté à: " + PORT_NAME);
    println("✓ Baud rate: " + BAUD_RATE);
    
  } catch (Exception e) {
    isConnected = false;
    connectionStatus = "Erreur connexion";
    println("✗ Erreur: " + e.getMessage());
    println("Vérifiez le port et les permissions");
  }
}

// ================= DRAW =================
void draw() {
  background(backgroundColor);
  
  // Vérifier la connexion
  checkConnection();
  
  // Dessiner le radar
  drawRadar();
  
  // Dessiner les informations
  drawInfoPanel();
  
  // Dessiner la barre d'état
  drawStatusBar();
  
  // Afficher l'aide si nécessaire
  if (showHelp) {
    drawHelp();
  }
}

// ================= DESSIN RADAR =================
void drawRadar() {
  pushMatrix();
  translate(width/2, height/2);
  
  // Cercles concentriques (échelle)
  noFill();
  stroke(gridColor);
  strokeWeight(1);
  
  for (int i = 1; i <= 5; i++) {
    float radius = i * 80;
    ellipse(0, 0, radius * 2, radius * 2);
    
    // Labels des distances
    if (i % 2 == 1) {
      fill(textColor);
      textAlign(CENTER, BOTTOM);
      text((i * 40) + "cm", 0, -radius - 5);
      noFill();
    }
  }
  
  // Lignes des angles
  for (int i = 0; i < 360; i += 30) {
    float x = cos(radians(i)) * 200;
    float y = sin(radians(i)) * 200;
    line(0, 0, x, y);
    
    // Labels des angles
    pushMatrix();
    translate(x * 1.05, y * 1.05);
    rotate(radians(i + 90));
    fill(textColor);
    textAlign(CENTER, CENTER);
    text(i + "°", 0, 0);
    popMatrix();
  }
  
  // Ligne de balayage
  float sweepX = cos(radians(angle)) * 200;
  float sweepY = sin(radians(angle)) * 200;
  stroke(sweepColor);
  strokeWeight(2);
  line(0, 0, sweepX, sweepY);
  
  // Points des objets détectés (historique)
  for (int i = 0; i < distanceHistory.length; i++) {
    if (distanceHistory[i] > 0) {
      // Taille du point selon la distance
      float pointSize = map(distanceHistory[i], 0, 200, 5, 12);
      
      // Couleur selon l'alerte
      if (alertHistory[i] > 0) {
        stroke(alertColor);
        strokeWeight(pointSize + 2);
      } else {
        stroke(objectColor);
        strokeWeight(pointSize);
      }
      
      // Position du point
      float dist = map(distanceHistory[i], 0, 200, 0, 200);
      float pointX = cos(radians(i)) * dist;
      float pointY = sin(radians(i)) * dist;
      point(pointX, pointY);
    }
  }
  
  popMatrix();
}

// ================= PANEL INFORMATIONS =================
void drawInfoPanel() {
  float x = width - 250;
  float y = 50;
  
  // Fond du panel
  fill(20, 25, 40, 200);
  stroke(100, 150, 200);
  strokeWeight(2);
  rect(x, y, 220, 300, 10);
  
  // Titre
  fill(textColor);
  textAlign(LEFT);
  textSize(18);
  text("RADAR SYSTEM", x + 20, y + 30);
  textSize(14);
  
  // Données en temps réel
  text("Angle: " + nf(angle, 0, 1) + "°", x + 20, y + 70);
  text("Distance: " + nf(distance, 0, 1) + " cm", x + 20, y + 100);
  
  // État d'alerte
  if (alertLevel > 0) {
    fill(alertColor);
    text("ALERTE! Objet proche", x + 20, y + 130);
  } else {
    fill(sweepColor);
    text("Surveillance normale", x + 20, y + 130);
  }
  
  fill(textColor);
  
  // Statistiques
  text("=== STATISTIQUES ===", x + 20, y + 170);
  text("Points détectés: " + countDetectedObjects(), x + 20, y + 200);
  text("Portée max: " + getMaxDistance() + " cm", x + 20, y + 230);
  
  // Contrôles
  text("=== CONTROLES ===", x + 20, y + 270);
  text("H: Aide", x + 20, y + 300);
  text("R: Reconnexion", x + 20, y + 325);
  text("F: Plein écran (" + (isFullScreen ? "ON" : "OFF") + ")", x + 20, y + 350);
}

// ================= BARRE D'ÉTAT =================
void drawStatusBar() {
  // Fond
  fill(20, 25, 35);
  noStroke();
  rect(0, height - 40, width, 40);
  
  // Texte d'état
  fill(isConnected ? color(0, 255, 100) : color(255, 50, 50));
  textAlign(LEFT);
  text(connectionStatus, 20, height - 15);
  
  // LED indicateur
  fill(isConnected ? color(0, 255, 0) : color(255, 0, 0));
  ellipse(15, height - 25, 10, 10);
  
  // Temps depuis dernière donnée
  if (isConnected) {
    long timeSinceData = millis() - lastDataTime;
    if (timeSinceData > 1000) {
      fill(255, 200, 0);
      text("Dernière donnée: " + (timeSinceData/1000) + "s", 200, height - 15);
    }
  }
}

// ================= AIDE =================
void drawHelp() {
  // Fond semi-transparent
  fill(0, 0, 0, 200);
  noStroke();
  rect(0, 0, width, height);
  
  // Fenêtre d'aide
  fill(30, 40, 60);
  stroke(100, 150, 200);
  strokeWeight(2);
  rect(width/2 - 200, height/2 - 150, 400, 300, 15);
  
  // Texte d'aide
  fill(textColor);
  textAlign(CENTER);
  textSize(20);
  text("AIDE - CONTROLES", width/2, height/2 - 100);
  
  textAlign(LEFT);
  textSize(14);
  text("• H: Afficher/Cacher cette aide", width/2 - 180, height/2 - 50);
  text("• R: Reconnexion Arduino", width/2 - 180, height/2 - 20);
  text("• F: Plein écran (" + (isFullScreen ? "ON" : "OFF") + ")", width/2 - 180, height/2 + 10);
  text("• C: Effacer l'historique", width/2 - 180, height/2 + 40);
  text("• ESPACE: Pause/Reprise", width/2 - 180, height/2 + 70);
  
  text("• Format données Arduino:", width/2 - 180, height/2 + 110);
  text("  angle,distance,alerte", width/2 - 160, height/2 + 140);
  
  // Bouton Fermer
  fill(255, 100, 100);
  rect(width/2 - 50, height/2 + 170, 100, 35, 8);
  fill(255);
  textAlign(CENTER, CENTER);
  text("FERMER (H)", width/2, height/2 + 187);
}

// ================= UTILITAIRES =================
void checkConnection() {
  if (!isConnected && autoReconnect) {
    if (frameCount % 60 == 0) { // Toutes les secondes
      println("Tentative de reconnexion...");
      connectToArduino();
    }
  }
  
  // Timeout si pas de données depuis trop longtemps
  if (isConnected && (millis() - lastDataTime > RECONNECT_TIMEOUT)) {
    println("Timeout - Reconnexion...");
    isConnected = false;
    connectionStatus = "Timeout - Reconnexion";
  }
}

int countDetectedObjects() {
  int count = 0;
  for (float d : distanceHistory) {
    if (d > 0) count++;
  }
  return count;
}

float getMaxDistance() {
  float max = 0;
  for (float d : distanceHistory) {
    if (d > max) max = d;
  }
  return max;
}

// ================= GESTION DONNÉES SÉRIE =================
void serialEvent(Serial port) {
  try {
    String data = port.readStringUntil('\n');
    if (data == null) return;
    
    data = data.trim();
    lastDataTime = millis();
    
    // Format attendu: "angle,distance,alerte"
    String[] parts = split(data, ',');
    
    if (parts.length >= 2) {
      // Angle
      angle = float(parts[0]);
      
      // Distance
      distance = float(parts[1]);
      
      // Alerte (optionnel)
      if (parts.length >= 3) {
        alertLevel = int(parts[2]);
      } else {
        alertLevel = (distance > 0 && distance < 20) ? 1 : 0;
      }
      
      // Mettre à jour l'historique
      int angleIndex = int(angle);
      if (angleIndex >= 0 && angleIndex < 360) {
        distanceHistory[angleIndex] = distance;
        alertHistory[angleIndex] = alertLevel;
      }
      
      // Debug (optionnel)
      // println("Angle: " + angle + "°, Distance: " + distance + "cm, Alerte: " + alertLevel);
    }
    
  } catch (Exception e) {
    println("Erreur traitement données: " + e.getMessage());
  }
}

// ================= GESTION CLAVIER =================
void keyPressed() {
  switch(key) {
    case 'h':
    case 'H':
      showHelp = !showHelp;
      break;
      
    case 'r':
    case 'R':
      println("Reconnexion manuelle...");
      connectToArduino();
      break;
      
    case 'f':
    case 'F':
      toggleFullscreen();
      break;
      
    case 'c':
    case 'C':
      // Effacer l'historique
      for (int i = 0; i < 360; i++) {
        distanceHistory[i] = 0;
        alertHistory[i] = 0;
      }
      println("Historique effacé");
      break;
      
    case ' ':
      // Pause/Reprise (à implémenter si besoin)
      println("Espace - Pause/Reprise");
      break;
  }
}

void toggleFullscreen() {
  if (isFullScreen) {
    // Retour à la taille normale
    size(1000, 700);
    isFullScreen = false;
    println("Mode fenêtré");
  } else {
    // Passage en plein écran
    fullScreen();
    isFullScreen = true;
    println("Mode plein écran");
  }
}

// ================= CODE ARDUINO NANO CORRESPONDANT =================
/*

// Code Arduino Nano simple et fiable
#include <Servo.h>

const int trigPin = 2;
const int echoPin = 3;
const int servoPin = 9;
const int buzzerPin = 8;

Servo radarServo;
int angle = 0;
int increment = 1;

void setup() {
  Serial.begin(9600);
  
  pinMode(trigPin, OUTPUT);
  pinMode(echoPin, INPUT);
  pinMode(buzzerPin, OUTPUT);
  
  radarServo.attach(servoPin);
  radarServo.write(0);
  delay(1000);
}

void loop() {
  // Contrôle servo
  radarServo.write(angle);
  delay(30);
  
  // Mesure distance
  int distance = measureDistance();
  
  // Buzzer (optionnel)
  if (distance > 0 && distance < 20) {
    digitalWrite(buzzerPin, HIGH);
    delay(50);
    digitalWrite(buzzerPin, LOW);
  }
  
  // Envoi données au format "angle,distance,alerte"
  Serial.print(angle);
  Serial.print(",");
  Serial.print(distance);
  Serial.print(",");
  Serial.println((distance > 0 && distance < 20) ? "1" : "0");
  
  // Mise à jour angle
  angle += increment;
  if (angle >= 180 || angle <= 0) {
    increment = -increment;
  }
}

int measureDistance() {
  digitalWrite(trigPin, LOW);
  delayMicroseconds(2);
  digitalWrite(trigPin, HIGH);
  delayMicroseconds(10);
  digitalWrite(trigPin, LOW);
  
  long duration = pulseIn(echoPin, HIGH, 30000);
  int distance = duration * 0.034 / 2;
  
  if (distance > 200) distance = 200;
  if (distance < 2) distance = 0;
  
  return distance;
}

*/
