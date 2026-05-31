# 🚀 Système Radar avec Arduino Nano

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Arduino](https://img.shields.io/badge/Arduino-Nano-00979D)](https://www.arduino.cc/)
[![Processing](https://img.shields.io/badge/Processing-3.5.4-006699)](https://processing.org/)

## 📝 Description
Système radar complet utilisant Arduino Nano, capteur HC-SR04, servo moteur,
LED RGB et afficheur LCD I2C. Visualisation graphique en temps réel avec Processing.

## ✨ Fonctionnalités
- ✅ Balayage radar 0° à 180°
- ✅ Détection d'objets 2-200 cm
- ✅ Alerte sonore (buzzer) avec fréquence variable
- ✅ Indication visuelle (LED RGB) par couleur
- ✅ Affichage LCD 16x2 en temps réel
- ✅ Visualisation Processing graphique
- ✅ Communication série USB

## 📋 Matériel nécessaire
- Arduino Nano
- Capteur ultrason HC-SR04
- Servo moteur SG90
- LED RGB (module avec résistances)
- Buzzer passif
- Afficheur LCD I2C 16x2
- Breadboard et câbles Dupont

## 🔌 Schéma de câblage
<img width="401" height="463" alt="Capture d’écran du 2026-05-15 21-54-43" src="https://github.com/user-attachments/assets/1f466076-05b9-4734-b43c-cd82dbcd290a" />

| 🟢 Arduino | 🔵 Composant | 🟠 Connexion |
|------------|--------------|--------------|
| **D7** | HC-SR04 | `Trig` |
| **D8** | HC-SR04 | `Echo` |
| **D9** | Servo | `Signal` |
| **D12** | Buzzer | `+` |
| **D5** | LED RGB | `Rouge` |
| **D3** | LED RGB | `Vert` |
| **D6** | LED RGB | `Bleu` |
| **A4** | LCD I2C | `SDA` |
| **A5** | LCD I2C | `SCL` |
| **5V** | Tous | `VCC` |
| **GND** | Tous | `GND` |
