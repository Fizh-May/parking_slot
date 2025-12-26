# 🚗 ParkFlow – Parking Slot Reservation & Usage Management

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter&logoColor=white)]
[![Firebase](https://img.shields.io/badge/Firebase-Authentication%20%7C%20Firestore-orange?logo=firebase&logoColor=white)]
[![Platform](https://img.shields.io/badge/Platform-Android-green?logo=android&logoColor=white)]
[![Status](https://img.shields.io/badge/Status-Student%20Project-success)]

A **mobile application** built with **Flutter** and **Firebase**, designed to **manage parking slot reservations and usage** in residential areas or organizations.  
The system supports **advance reservations, real-time slot status tracking, and user access control**.

---

## 📌 Project Topic

**Topic 4 – Parking Slot Reservation and Usage Management Application**

Managing parking slots efficiently is challenging due to **high demand** and **limited availability**.  
**ParkFlow** helps administrators and residents track, reserve, and manage parking slots transparently and securely.

---

## 🚀 Features

### 👤 Authentication & User Management
- 🔐 **Google Sign-In** using Firebase Authentication
- 🧑‍💼 **Role-based access** (Admin / Resident)
- ⏳ **Account activation flow**
    - New users are placed in *Pending Activation*
    - Admin approves accounts via Firestore

### 🅿️ Parking Slot Management
- 📋 View parking slot information
- 📊 Track slot status:
    - `Available`
    - `Reserved`
    - `Occupied`
- ⏱️ Extend parking duration when needed

### 📅 Reservation System
- 🗓️ Reserve parking slots for specific time periods
- 🚫 Prevent double-booking
- 🔄 Real-time status updates using Firestore

### 🕓 Usage History
- 🔍 Search parking history:
    - By **user**
    - By **parking slot**
- 📜 Track reservation & usage records

### 📱 User Experience
- 🎨 Clean and modern UI (Material Design)
- 🔄 Reload / refresh account status
- 🔔 Clear feedback for pending or inactive accounts

---

## 🛠 Tech Stack

### Mobile App
- **Framework:** Flutter
- **Language:** Dart
- **UI:** Material Design

### Backend / Cloud
- **Authentication:** Firebase Authentication (Google Sign-In)
- **Database:** Cloud Firestore (NoSQL, real-time)
- **State Handling:** Firebase streams & async services

### Tools
- Git & GitHub
- Android Emulator / Physical Device

---

## 📂 Project Structure

```txt
lib/
├── screen/
│   ├── login.dart
│   ├── waiting_active_screen.dart
│   ├── dashboard.dart
│   └── ...
├── services/
│   ├── auth.dart
│   ├── user.dart
│   └── ...
├── main.dart
