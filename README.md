# Supervisor

Our supervisor app.
## Page Flow and Functionality

1.  **Splash Screen:** The app starts with a splash screen that displays an animation and then automatically navigates to the Login Page.

2.  **Login Page:**
    *   **Functionality:** Allows supervisors to log in using their phone number and password. It includes input validation and error handling.
    *   **Page Flow:** Upon successful login, the app saves the supervisor's access token, name, phone number, and a list of their assigned buses to secure storage. It then navigates to the Select Bus Page.

3.  **Select Bus Page:**
    *   **Functionality:** Displays a list of buses assigned to the logged-in supervisor. The supervisor can select one bus to manage.
    *   **Page Flow:** After the supervisor selects a bus and clicks the proceed button, the app saves the selected bus ID to secure storage and navigates to the Home Page.

4.  **Home Page:**
    *   **Functionality:** This is the main dashboard for the supervisor. It displays the following options:
        *   **Start/Manage Bus:** A button that either starts a new journey or manages an ongoing one.
        *   **Seat Management:** A button to showing available seats
        *   **Seat Request:** A button that shows the number of pending seat requests and navigates to the Seat Request Page.
        *   **Inbox:** Currently inactive
        *   **Account:** A button to view account information and logout.

5.  **Seat Request Page:**
    *   **Functionality:** Displays a list of pending seat booking requests from passengers. The supervisor can accept or reject each request.

6.  **Manage Bus/Journey Page:**
    *   **Functionality:** Allows the supervisor to end the bus's journey, add boarding point, including updating its live location.

## Getting Started

This project is a Flutter application. To get started, you'''ll need to have Flutter installed. You can find instructions on how to install Flutter [here](https://docs.flutter.dev/get-started/install).

Once you have Flutter installed, you can clone this repository and run the following command to install the dependencies:

```bash
flutter pub get
```

Then, you can run the app using:

```bash
flutter run
```

## Features

* (Please add a list of your app'''s features here)

## Dependencies

This project uses the following dependencies:

* [flutter](https://flutter.dev/)
* [lottie](https://pub.dev/packages/lottie)
* [http](https://pub.dev/packages/http)
* [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
* [flutter_map](https://pub.dev/packages/flutter_map)
* [latlong2](https://pub.dev/packages/latlong2)
* [geolocator](https://pub.dev/packages/geolocator)
* [intl](https://pub.dev/packages/intl)
* [cupertino_icons](https://pub.dev/packages/cupertino_icons)
* [provider](https://pub.dev/packages/provider)
* [shared_preferences](https://pub.dev/packages/shared_preferences)

## Dev Dependencies

* [flutter_test](https://pub.dev/packages/flutter_test)
* [flutter_lints](https://pub.dev/packages/flutter_lints)
