# FarmConnect 🥔📱🚛

**FarmConnect** is a Flutter mobile app designed to empower smallholder farmers in the Sebei region of Uganda (Kapchorwa, Kween, and Bukwo) by providing direct access to urban produce markets through trusted local agents and ethical delivery coordination.

## 🚀 Vision

To end exploitation by middlemen and transport cartels, improve farmer income, and digitize rural produce aggregation using affordable, accessible tools (mobile apps and USSD).

---

## 📱 Core Features

- **USSD Access for Farmers**: Farmers without smartphones can check market prices, list produce, and find agents using short codes. *(Planned)*
- **Mobile App for Agents**: Manage farmer listings, aggregate produce, and coordinate deliveries.
- **Buyer Portal**: Urban buyers browse produce, place orders, and pay via Mobile Money.
- **Delivery Coordination**: Ethical transporters fulfill deliveries transparently.
- **Escrow Payments**: Secure payment system for all stakeholders.

---

## 🧑‍🤝‍🧑 Stakeholders

- Farmers (tech and non-tech users)
- Agents (local coordinators)
- Buyers (urban market customers)
- Delivery Agents (logistics partners)
- Admins (platform managers)

---

## 🛠 Tech Stack

- Backend: Node.js, Express, PostgreSQL
- Frontend: Flutter (Android & iOS mobile app)
- USSD: Africa’s Talking API *(planned)*
- Payments: MTN, Airtel Mobile Money APIs

---

## 📂 Folder Structure

-farmconnect/
-├── backend/ # Backend Node.js API server
-├── frontend/
-│ └── flutter_app/ # Flutter mobile app source code
-├── ussd/ # USSD gateway integrations (planned)
-└── README.md # This file


---

## 📲 Running the Flutter App

1. Ensure Flutter SDK is installed and configured on your machine.
2. Connect an Android or iOS device/emulator.
3. Run these commands inside the Flutter app directory:

```bash
cd frontend/flutter_app
flutter pub get
flutter run

🎨 Theme & UI
The app uses a green-based color scheme to reflect agriculture, growth, and trust, creating a fresh and welcoming user experience.
```

## License
### MIT License