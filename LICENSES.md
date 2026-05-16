# Open Source Licenses

This document lists all open source dependencies used in the My Stream podcast player application and their licenses.

## Direct Dependencies

### Audio & Media
| Package | Version | License |
|---------|---------|---------|
| just_audio | 0.9.46 | MIT |
| audio_service | 0.18.18 | MIT |
| audio_session | 0.1.25 | MIT |

### State Management
| Package | Version | License |
|---------|---------|---------|
| provider | 6.1.5+1 | MIT |

### Database & Storage
| Package | Version | License |
|---------|---------|---------|
| sqflite | 2.4.2 | BSD-2-Clause |
| path | 1.9.1 | BSD-3-Clause |
| path_provider | 2.1.5 | BSD-3-Clause |
| shared_preferences | 2.5.4 | BSD-3-Clause |

### Networking & API
| Package | Version | License |
|---------|---------|---------|
| http | 1.6.0 | BSD-3-Clause |
| podcast_search | 0.7.14 | BSD-3-Clause |
| webfeed_revised | 0.8.0 | MIT |
| dio | 5.9.1 | MIT |

### UI & Utilities
| Package | Version | License |
|---------|---------|---------|
| cached_network_image | 3.4.1 | MIT |
| intl | 0.19.0 | BSD-3-Clause |
| url_launcher | 6.3.2 | BSD-3-Clause |
| permission_handler | 11.4.0 | MIT |
| cupertino_icons | 1.0.8 | MIT |

## Key Transitive Dependencies

### Core Libraries
| Package | Version | License |
|---------|---------|---------|
| flutter_cache_manager | 3.4.1 | MIT |
| rxdart | 0.28.0 | Apache-2.0 |
| xml | 6.6.1 | MIT |
| crypto | 3.0.7 | BSD-3-Clause |
| uuid | 4.5.2 | MIT |

### Platform Interfaces
| Package | Version | License |
|---------|---------|---------|
| plugin_platform_interface | 2.1.8 | BSD-3-Clause |
| sqflite_platform_interface | 2.4.0 | BSD-2-Clause |
| audio_service_platform_interface | 0.1.3 | MIT |
| just_audio_platform_interface | 4.6.0 | MIT |

### Platform-Specific Implementations
| Package | Version | License |
|---------|---------|---------|
| sqflite_android | 2.4.2+2 | BSD-2-Clause |
| sqflite_darwin | 2.4.2 | BSD-2-Clause |
| path_provider_android | 2.2.22 | BSD-3-Clause |
| path_provider_linux | 2.2.1 | BSD-3-Clause |
| path_provider_windows | 2.3.0 | BSD-3-Clause |
| permission_handler_android | 12.1.0 | MIT |
| permission_handler_apple | 9.4.7 | MIT |

### Web Support
| Package | Version | License |
|---------|---------|---------|
| audio_service_web | 0.1.4 | MIT |
| just_audio_web | 0.4.16 | MIT |
| cached_network_image_web | 1.3.1 | MIT |
| url_launcher_web | 2.4.2 | BSD-3-Clause |

## Development Dependencies

| Package | Version | License |
|---------|---------|---------|
| flutter_lints | 6.0.0 | BSD-3-Clause |
| flutter_test | SDK | BSD-3-Clause |

## License Types Summary

- **MIT License**: 18 packages
- **BSD-3-Clause**: 15 packages  
- **BSD-2-Clause**: 4 packages
- **Apache-2.0**: 1 package

## License Texts

### MIT License
```
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
```

### BSD-3-Clause License
```
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

### Apache License 2.0
```
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Compliance Notes

All dependencies use permissive open source licenses (MIT, BSD, Apache 2.0) that allow:
- ✅ Commercial use
- ✅ Modification
- ✅ Distribution
- ✅ Private use

**Attribution Requirements:**
- MIT and BSD licenses require copyright notices to be included in distributions
- Apache 2.0 requires a copy of the license and attribution notices

## Viewing Licenses in App

Flutter provides a built-in license viewer. To display all licenses in your app, use:

```dart
showLicensePage(
  context: context,
  applicationName: 'My Stream',
  applicationVersion: '1.0.0',
);
```

This is already available in the Settings screen via the "Licenses" option.

---

*Last updated: 2026-02-15*
*Total packages: 100+ (including transitive dependencies)*
