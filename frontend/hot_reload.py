"""
Flutter hot-reload watcher for Flutter web (Chrome).

Starts `flutter run -d chrome`, watches lib/**/*.dart for changes,
and sends 'r' (hot reload) to the Flutter process stdin automatically.

Usage:
    python hot_reload.py          # hot reload on save
    python hot_reload.py --restart  # hot restart on save (R instead of r)
"""
import sys
import time
import subprocess
import threading
import re
from pathlib import Path

FLUTTER  = r"C:\Users\ulkap\Flutter\flutter\bin\flutter.bat"
LIB_DIR  = Path(__file__).parent / "lib"
CMD      = "R" if "--restart" in sys.argv else "r"
LABEL    = "Hot restart" if CMD == "R" else "Hot reload"

_debounce_timer: threading.Timer | None = None
_lock = threading.Lock()
_proc: subprocess.Popen | None = None


def send_reload():
    global _proc
    if _proc and _proc.poll() is None:
        print(f"[hot_reload] {LABEL}…", flush=True)
        _proc.stdin.write(CMD + "\n")
        _proc.stdin.flush()
    else:
        print("[hot_reload] Flutter not running.", flush=True)


def debounced_reload():
    global _debounce_timer
    with _lock:
        if _debounce_timer:
            _debounce_timer.cancel()
        _debounce_timer = threading.Timer(0.4, send_reload)
        _debounce_timer.start()


def watch_files():
    from watchdog.observers import Observer
    from watchdog.events import FileSystemEventHandler

    class Handler(FileSystemEventHandler):
        def on_modified(self, event):
            if not event.is_directory and str(event.src_path).endswith(".dart"):
                print(f"[hot_reload] Changed: {Path(event.src_path).name}", flush=True)
                debounced_reload()

    observer = Observer()
    observer.schedule(Handler(), str(LIB_DIR), recursive=True)
    observer.start()
    return observer


def pipe_output(stream, prefix=""):
    for line in iter(stream.readline, ""):
        print(prefix + line, end="", flush=True)


def main():
    global _proc

    print(f"[hot_reload] Starting Flutter ({LABEL} on .dart save)…", flush=True)
    _proc = subprocess.Popen(
        [FLUTTER, "run", "-d", "chrome", "--web-port", "3000"],
        cwd=str(Path(__file__).parent),
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    # Pipe Flutter output to our stdout
    out_thread = threading.Thread(target=pipe_output, args=(_proc.stdout,), daemon=True)
    out_thread.start()

    # Give Flutter time to start up before watching for changes
    print("[hot_reload] Waiting for Flutter to start…", flush=True)
    time.sleep(15)

    # Start file watcher
    observer = watch_files()
    print(f"[hot_reload] Watching {LIB_DIR} — save any .dart file to {LABEL.lower()}.\n", flush=True)

    try:
        _proc.wait()
    except KeyboardInterrupt:
        print("\n[hot_reload] Stopping…", flush=True)
        if _proc.poll() is None:
            _proc.stdin.write("q\n")
            _proc.stdin.flush()
            _proc.wait(timeout=5)
    finally:
        observer.stop()
        observer.join()
        print("[hot_reload] Done.", flush=True)


if __name__ == "__main__":
    main()
