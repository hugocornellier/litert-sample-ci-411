"""Rewrites flutter_litert 4.0.0's linux/ and windows/CMakeLists.txt so the
plugin bundles only its TFLite C library and custom ops: the CMake half of the
sample's flutter_litert-3.9.3.patch, re-done for 4.0.0's files."""
import sys

root = sys.argv[1]
END = 'set(flutter_tflite_bundled_libraries ${flutter_tflite_bundled_libraries} PARENT_SCOPE)'

LINUX = '''# ci4 variant C: no LiteRT runtime from this plugin on Linux (no download).
# flutter_edge_ai_litertlm ships libLiteRt.so and libLiteRtWebGpuAccelerator.so
# as native assets with the same file names.
set(flutter_litert_bundled_libraries "$<TARGET_FILE:tflite_custom_ops>")
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
  list(APPEND flutter_litert_bundled_libraries
    "${CMAKE_CURRENT_SOURCE_DIR}/lib/libtensorflowlite_c-linux.so")
endif()
set(flutter_tflite_bundled_libraries ${flutter_litert_bundled_libraries})

'''

WINDOWS = '''# ci4 variant C: no LiteRT runtime, accelerator or DXC from this plugin on
# Windows (no downloads). flutter_edge_ai_litertlm ships them as native assets
# with the same file names.
set(flutter_litert_bundled_libraries
  "${CMAKE_CURRENT_SOURCE_DIR}/libtensorflowlite_c-win.dll"
  "$<TARGET_FILE:tflite_custom_ops>"
)
set(flutter_tflite_bundled_libraries ${flutter_litert_bundled_libraries})

'''


def rewrite(path, start_marker, body):
    s = open(path, newline='').read()
    nl = '\r\n' if '\r\n' in s else '\n'
    s = s.replace('\r\n', '\n')
    a = s.index(start_marker)
    b = s.index(END)
    s = s[:a] + body + s[b:]
    open(path, 'w', newline='').write(s.replace('\n', nl))
    print(f'rewrote {path}')


rewrite(f'{root}/linux/CMakeLists.txt', '# The WebGPU GPU accelerator', LINUX)
rewrite(f'{root}/windows/CMakeLists.txt', 'set(FLUTTER_LITERT_TFLITE_DLL', WINDOWS)
