# Bitacora

Bitacora is a powerful Flutter-based database management and monitoring application that provides a modern interface for interacting with various database systems.

## Features

- **Multi-Database Support**: Connect to multiple database systems simultaneously
- **Real-Time Monitoring**: Track database connection status and table updates
- **Table Management**: View and manage database tables with intuitive controls
- **Data Operations**: 
  - Insert new records
  - Edit existing data
  - Delete records
  - Custom queries
- **Smart Table Handling**: Automatic detection of table properties and relationships
- **Cross-Platform**: Works on multiple platforms thanks to Flutter
- **Dark/Light Theme**: Supports system theme preferences
- **Internationalization**: Supports multiple languages (English, Spanish, French, Chinese)

## Technical Details

- Built with Flutter
- Uses BLoC pattern for state management
- Supports various database clients:
  - SQLite
  - PostgreSQL
  - BigQuery
- Persistent storage for connection settings
- Real-time connection status monitoring
- Material Design 3 UI

## Getting Started

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run
   ```

## Requirements

- Flutter SDK
- Supported databases:
  - SQLite (included)
  - PostgreSQL (requires server connection)
  - BigQuery (requires credentials)

## License

This project is licensed under the MIT License - see the LICENSE file for details.