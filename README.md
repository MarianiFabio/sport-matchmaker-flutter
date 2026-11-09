# Sport Matchmaker

A mobile application developed in Flutter to organize, discover, and join amateur sports matches in your local area.
The app features real-time dynamic JSON communication with a custom PHP/MySQL backend, which is currently hosted on a remote server for a seamless testing experience.

## Project Structure
- **/lib**: Contains the Flutter Dart code (UI, state management, and network calls).
- **/backend**: Contains the `api.php` file and `sportmatch_data.json` database backup (provided for reference and local fallback).
- **/SQL**: Contains the `CreateTables.txt` scripts representing the MySQL relational schema.
- **/UML**: Contains all Use Case, ER, Class, Deployment, and State Machine diagrams.

## How to Run the App (Zero-Config)
The application is fully configured to communicate with a live remote backend. **No local server (XAMPP/MAMP) or database configuration is required** to evaluate the application.

1. Open the Flutter project in your IDE (VS Code or Android Studio).
2. Run the app using an emulator, physical device, or Chrome web simulator:
   ```bash
   flutter run