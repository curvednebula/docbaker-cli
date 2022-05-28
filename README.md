#  DocBaker for OpenAPI

DokBaker is OpenAPI to PDF document generator.

**[Homepage.](https://curvednebula.com/docbaker/)**

# Compile to platform native binary

[Dart SDK](https://dart.dev/) is required to build and run DocBaker.

**macOS:**
```
dart compile exe cli/main.dart -o bin/docbaker
```

**Windows:**
```
dart compile exe cli/main.dart -o bin/docbaker.exe
```

# Usage
```
Usage: docbaker <openapi.json> [<api2.json> <api3.json> ...] [<options>]
Options:
-o, --output                Output file.
                            (defaults to "api-spec.pdf")
    --title                 Document title.
                            (defaults to "API Spec")
    --subtitle              Document sub title.
    --[no-]merge-schemas    When multiple API files parsed merge all schemas into one section.
-h, --help                  Show this help page.
```

# MIT License

Copyright (c) 2022 CurvedNebula.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
