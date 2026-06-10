$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$cmake = (Get-Command cmake -ErrorAction SilentlyContinue).Source
if (-not $cmake -and (Test-Path "C:\Program Files\CMake\bin\cmake.exe")) {
    $cmake = "C:\Program Files\CMake\bin\cmake.exe"
}
if (-not $cmake) {
    throw "cmake was not found"
}

$zig = (Get-Command zig -ErrorAction SilentlyContinue).Source
if (-not $zig) {
    throw "zig was not found"
}

$ninja = (Get-Command ninja -ErrorAction SilentlyContinue).Source
if (-not $ninja) {
    throw "ninja was not found"
}

$targetDir = Join-Path $root "lib\windows\x64"
New-Item -ItemType Directory -Force -Path $targetDir | Out-Null

Push-Location (Join-Path $root "thirdparty\glfw")
try {
    Remove-Item -Recurse -Force -LiteralPath "build-zig" -ErrorAction SilentlyContinue
    & $cmake -G Ninja -S . -B build-zig `
        -DCMAKE_TOOLCHAIN_FILE="$root/cmake/zig-windows-gnu.cmake" `
        -DCMAKE_BUILD_TYPE=Release `
        -DGLFW_BUILD_EXAMPLES=OFF `
        -DGLFW_BUILD_TESTS=OFF `
        -DGLFW_BUILD_DOCS=OFF
    & $cmake --build build-zig -j 4
    Copy-Item -Force -LiteralPath "build-zig\src\libglfw3.a" -Destination (Join-Path $targetDir "libglfw3.a")
}
finally {
    Pop-Location
}

Push-Location (Join-Path $root "thirdparty\SDL")
try {
    Remove-Item -Recurse -Force -LiteralPath "build-zig" -ErrorAction SilentlyContinue
    & $cmake -G Ninja -S . -B build-zig `
        -DCMAKE_TOOLCHAIN_FILE="$root/cmake/zig-windows-gnu.cmake" `
        -DCMAKE_BUILD_TYPE=Release `
        -DSDL_SHARED=OFF `
        -DSDL_STATIC=ON `
        -DSDL_TEST=OFF
    & $cmake --build build-zig -j 4
    Copy-Item -Force -LiteralPath "build-zig\libSDL2.a" -Destination (Join-Path $targetDir "libSDL2.a")
}
finally {
    Pop-Location
}

Push-Location (Join-Path $root "lib")
try {
    Remove-Item -Recurse -Force -LiteralPath "build-zig" -ErrorAction SilentlyContinue
    & $cmake -G Ninja -S . -B build-zig `
        -DCMAKE_TOOLCHAIN_FILE="$root/cmake/zig-windows-gnu.cmake" `
        -DCMAKE_BUILD_TYPE=Release
    & $cmake --build build-zig -j 4
    Copy-Item -Force -LiteralPath "build-zig\cimgui.a" -Destination (Join-Path $targetDir "cimgui.a")
}
finally {
    Pop-Location
}
