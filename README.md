# YawStar SAC Manager

An advanced, lightweight, and real-time GUI utility designed to manage Windows 11 **Smart App Control (SAC)** and **Windows Defender Application Control (WDAC)** states without requiring a system reboot. 

Developed entirely in Python using `CustomTkinter` and `pystray`, this tool leverages enterprise-grade Code Integrity mechanisms to toggle SAC settings instantly.

---

## ✨ Features

- **Instant Toggle:** Change SAC states (ON, Evaluation, OFF) instantly without needing a system restart.
- **Under-the-Hood Innovation:** Uses the native Windows `CiTool.exe` to force-refresh Code Integrity policies in real-time.
- **Smart App Control Bypass Design:** Avoids PyInstaller binary blocks by executing inside a virtual environment (`venv`) through the trusted Windows interpreter (`pythonw.exe`), guaranteeing **Zero False Positives**.
- **Modern UI/UX:** Built with a beautiful dark-themed `CustomTkinter` GUI and full System Tray integration (`pystray`) for background monitoring.
- **Localization:** Supports native Burmese language display with embedded `Pyidaungsu` font rendering.

---

## 🛠️ System Requirements

> [!WARNING]
> **Windows 11 Build 26200 or Higher Required (Version 24H2+)**
> This utility strictly requires `CiTool.exe`, which is only shipped by default in modern Windows 11 Client architectures starting from Build 26200. It will not function on older builds (e.g., 22H2/23H2).

- **OS:** Windows 11 (64-bit compatible)
- **Privileges:** Administrator Rights (required to modify Registry and reload Code Integrity policies)
- **Python:** Python 3.10+ (Recommended)

---

## 🚀 How It Works (The Logic)

Typically, modifying the `VerifiedAndReputablePolicyState` Registry key requires a complete system reboot to take effect. **YawStar SAC Manager** bypasses this limitation with a two-step mechanism:

1. **Registry Manipulation:** Modifies the secure state bits inside `HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy`.
2. **Policy Refreshing:** Executes `CiTool.exe -r` in a hidden background process to signal the Windows Kernel to reload all active security policies immediately.

Moreover, instead of compiling into an untrusted standalone `.exe` which SAC might flag, it runs directly via `pythonw.exe` utilizing the local environment's established reputation.

---

## 📦 Understanding the Virtual Environment (venv)

To guarantee that Windows Smart App Control (SAC) never blocks this manager, this project runs directly as a raw Python script inside a isolated **Virtual Environment (`venv`)** instead of being compiled into an untrusted standalone executable. 

Running inside a `venv` provides two major benefits:
1. **Zero False Positives:** Bypasses SAC and Antivirus heuristics by running through the officially signed and trusted `pythonw.exe` interpreter binary.
2. **Dependency Isolation:** Keeps the required third-party libraries (`customtkinter`, `pystray`, `Pillow`) confined strictly within the project folder without affecting your global Python installation.

---

## 💻 Installation & Setup

Follow these step-by-step instructions to clone, configure the virtual environment, and run the application.

### 1. Clone the Repository
Open your terminal or command prompt and run:
```bash
git clone https://github.com/YawStar/yawstar-sac-manager.git
cd yawstar-sac-manager
pip install -r requirement.txt
Launcher.bat
