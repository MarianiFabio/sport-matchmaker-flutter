# Sport Matchmaker

A mobile application developed in Flutter to organize, discover, and join amateur sports matches in your local area.
The app features real-time dynamic JSON communication with a custom PHP/MySQL backend.

## Project Structure
- **/lib**: Contains the Flutter dart code (UI, state management, and network calls).
- **/backend**: Contains the `api.php` file and `sportmatch_data.json` database.
- **/SQL**: Contains the `CreateTables.txt` script to build the MySQL relational schema.
- **/UML**: Contains all Use Case, ER, Class, Deployment, and State Machine diagrams.

## How to Run the App (Zero-Config DB Option)

The easiest way to run the backend for this project is to use the built-in JSON fallback.

1.  Copy the `backend/api.php` file into your local server directory (e.g., `C:\xampp\htdocs\sportmatch\api.php`).
2.  Start Apache on your local server. (MySQL is **optional**: if MySQL is off, `api.php` will automatically create and read from a local `sportmatch_data.json` file to ensure the app works flawlessly).
3.  Open the Flutter project in your IDE (VS Code or Android Studio).
4.  Run the app using an emulator or Chrome web simulator:
    ```bash
    flutter run
    ```
*(Note: In the dart files, the API URL is dynamically set to `10.0.2.2` for Android Emulators and `localhost` for Web/Desktop).*

## How to Run with MySQL (Full Database Option)
If you wish to test the full SQL capabilities:
1. Start Apache and MySQL in XAMPP.
2. Open `http://localhost/phpmyadmin`.
3. Create a new database named `sportmatch_db`.
4. The `api.php` file will automatically detect the database and build the necessary tables on the first run.
5. Launch the Flutter app.

## Features Included in Demo
- Login & Registration
- Live Match Feed with advanced multi-tier filtering (Sport Category, Format, Time, Cost).
- Dynamic Match Details & Roster viewing.
- Real-time Match Joining and slot updates.
- Create new Matches with smart capacities based on Sport Format.
- Profile Management & Settings synced to the server.