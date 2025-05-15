# EcoFund

EcoFund is a solar energy investment platform that connects homeowners, investors, and vendors. It facilitates the funding and installation of solar panels and manages monthly energy payments through a manual UPI-based flow. The platform is built to work without KYC or IoT integration.

---

## Tech Stack

**Frontend**

* Flutter (Dart)
* SharedPreferences for local storage
* Firebase Cloud Messaging (FCM) for notifications

**Backend**

* Node.js with Express.js framework
* PostgreSQL database
* JWT for authentication
* Firebase Cloud Messaging (FCM)
---

## Features

* Universal registration requiring UPI ID and PAN card details
* Homeowners submit properties and get assigned vendors automatically by city
* Vendors verify properties, submit quotes, and log monthly energy production
* Investors browse and invest in properties (each property split into 1000 units)
* Homeowners pay monthly based on energy produced; payments confirmed manually in-app
* Real-time notifications for key events using FCM
* Dashboard views for homeowners, investors, and vendors showing relevant data and progress
* Graphs for energy output, savings, and carbon offset tracking

---

## Project Structure

```
EcoFund/
├── Frontend/    # Flutter mobile app
├── Backend/     # Node.js + Express + PostgreSQL API
```

---

## Getting Started

### Clone the Repository

```
git clone https://github.com/vishruth-r/ecofund.git
cd ecofund
```

### Backend Setup

1. Navigate to the Backend directory:

```
cd Backend
```

2. Install dependencies:

```
npm install
```

3. Create a `.env` file in the Backend folder with the following variables:

```
PORT=5000
DB_URL=postgres://user:password@localhost:5432/ecofund
JWT_SECRET=your_secret_key
FCM_SERVER_KEY=your_fcm_server_key (optional if using Firebase service account)
```

4. Start the backend server:

```
npm start
```

The backend will be available at `http://localhost:5000`.

---

### Frontend Setup

1. Navigate to the Frontend directory:

```
cd ../Frontend
```

2. Get Flutter dependencies:

```
flutter pub get
```

3. Run the Flutter app on an emulator or connected device:

```
flutter run
```

---

## Firebase Setup (for Notifications)

To enable push notifications via Firebase Cloud Messaging (FCM), follow these steps:

1. **Create a Firebase project:**

* Go to the [Firebase Console](https://console.firebase.google.com/)
* Create a new project if you haven’t already

2. **Use Firebase CLI for setup:**

* Install Firebase CLI if not already installed:

  ```
  npm install -g firebase-tools
  ```

* Login to Firebase:

  ```
  firebase login
  ```

* Initialize Firebase in your project root:

  ```
  firebase init
  ```

  This will configure necessary files and services.

3. **Add Android and iOS apps in Firebase Console:**

* Register your app package names:

  * Android: `applicationId` from `android/app/build.gradle`
  * iOS: your Xcode bundle identifier
* Download the configuration files:

  * `google-services.json` for Android → place in `android/app/`
  * `GoogleService-Info.plist` for iOS → place in `ios/Runner/`

4. **Backend configuration for sending notifications:**

* Although Firebase CLI sets up the client side, your backend needs credentials to send FCM messages.
* You have two options:

  * **Use FCM Server Key:**

    * Go to Firebase Console > Project Settings > Cloud Messaging tab
    * Copy the **Server key**
    * Set it as `FCM_SERVER_KEY` in your backend `.env` file

  * **Use Firebase Service Account:**

    * In Firebase Console, go to Project Settings > Service accounts
    * Generate a new private key JSON file
    * Use this JSON in your backend to authenticate server-to-server FCM messaging securely

5. **Run the app:**

* Your Flutter app will now be able to receive push notifications sent by your backend via FCM.

---

## User Roles and Responsibilities

### Homeowners

* Register and submit property details including UPI and PAN
* Automatically assigned a vendor based on property city
* Receive vendor quote and approve payment via UPI QR code or UPI ID
* View monthly energy production, savings, and carbon offset data
* Make monthly payments based on energy usage, confirm payment in-app

### Vendors

* Verify homeowner properties physically
* Submit installation quotes through the app
* Log monthly energy production manually
* Receive payments from EcoFund post installation and funding

### Investors

* Browse available solar panel projects open for investment
* Invest in units of the property (up to 1000 units per property)
* Track investment progress and expected returns
* Receive returns as homeowners make monthly payments

---

## Payment Flow

* All payments are manual and done via UPI using QR codes or UPI IDs displayed in the app
* No payment gateway or automated transaction processing is integrated
* Users manually confirm payments by clicking a “Payment Completed” button in the app
* EcoFund manages distribution of payments to vendors and investors

---

## Notes

* Vendors enter consumption and energy data manually
* Property funding immediately triggers installation (assumed)
* Notifications for all key events are sent through Firebase Cloud Messaging

---

## License

This project is licensed under the MIT License.

---

