# Compile to platform native binary

## macOS
dart compile exe cli/main.dart -o bin/docbaker

## Windows
dart compile exe cli/main.dart -o bin/docbaker.exe

# Run
dart cli/main.dart openapi.json --title "My REST API Spec" --subtitle "v1.0.0"
