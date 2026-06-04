import customtkinter as ctk
from tkinter import messagebox
from datetime import datetime
import ctypes
import sys
import winreg
import threading
from PIL import Image, ImageDraw
import pystray
import os
import subprocess
import time

# Appearance settings
ctk.set_appearance_mode("System")
ctk.set_default_color_theme("dark-blue")

def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except:
        return False

def run_as_admin():
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, " ".join(sys.argv), None, 1)
    sys.exit()

class SingleInstanceManager:
    """Manage single instance of the application"""
    
    def __init__(self, app_name="YawStar SAC Manager"):
        self.app_name = app_name
        self.mutex_name = f"YawStar_SAC_Manager_Mutex_v1"
        self.mutex = None
        
    def try_acquire(self):
        """Try to acquire mutex, return False if already running"""
        try:
            self.mutex = ctypes.windll.kernel32.CreateMutexW(None, False, self.mutex_name)
            last_error = ctypes.windll.kernel32.GetLastError()
            
            if last_error == 183:  # ERROR_ALREADY_EXISTS
                print("Another instance is already running!")
                self.bring_existing_to_front()
                return False
            print("First instance - starting...")
            return True
        except Exception as e:
            print(f"Mutex error: {e}")
            return True
    
    def bring_existing_to_front(self):
        """Bring existing window to front and show if hidden"""
        try:
            # Try multiple window titles
            titles = ["YawStar SAC Manager", "Smart App Control Manager"]
            hwnd = None
            
            for title in titles:
                hwnd = ctypes.windll.user32.FindWindowW(None, title)
                if hwnd:
                    break
            
            if hwnd:
                # Check if window is hidden
                is_visible = ctypes.windll.user32.IsWindowVisible(hwnd)
                
                if not is_visible:
                    # Window is hidden in tray, restore it
                    print("Window is hidden, restoring...")
                    ctypes.windll.user32.ShowWindow(hwnd, 9)  # SW_RESTORE
                
                # Bring to foreground
                ctypes.windll.user32.ShowWindow(hwnd, 5)  # SW_SHOW
                ctypes.windll.user32.SetForegroundWindow(hwnd)
                ctypes.windll.user32.FlashWindow(hwnd, True)
                print("Existing window restored and brought to front")
                time.sleep(0.3)
            else:
                messagebox.showwarning("Already Running", f"{self.app_name} is already running!\n\nPlease check the system tray.")
        except Exception as e:
            print(f"Error bringing window: {e}")
    
    def release(self):
        """Release mutex on exit"""
        if self.mutex:
            ctypes.windll.kernel32.ReleaseMutex(self.mutex)
            print("Mutex released")

class SACManagerGUI(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("YawStar SAC Manager")
        
        # Window Icon
        if os.path.exists(r"Assets\Main_Icon.ico"):
            try:
                self.iconbitmap(r"Assets\Main_Icon.ico")
            except:
                pass

        # Load Pyidaungsu font
        font_path = os.path.join(os.path.dirname(__file__), "Assets", "Pyidaungsu.ttf")
        if os.path.exists(font_path):
            try:
                ctk.FontManager.load_font(font_path)
                print("Pyidaungsu font loaded successfully!")
            except Exception as e:
                print(f"Font loading failed: {e}")

        # Window Center
        window_width, window_height = 450, 420
        screen_width = self.winfo_screenwidth()
        screen_height = self.winfo_screenheight()
        center_x = int(screen_width/2 - window_width / 2)
        center_y = int(screen_height/2 - window_height / 2) - 50
        self.geometry(f'{window_width}x{window_height}+{center_x}+{center_y}')
        self.resizable(False, False)

        # Handle window close (hide to tray instead of quit)
        self.protocol('WM_DELETE_WINDOW', self.hide_window)

        # UI Layout
        self.grid_columnconfigure(0, weight=1)
        
        self.label_title = ctk.CTkLabel(self, text="YawStar SAC Manager", font=ctk.CTkFont(size=20, weight="bold"))
        self.label_title.grid(row=0, column=0, padx=20, pady=(20, 10))

        # Status Frame
        self.status_frame = ctk.CTkFrame(self)
        self.status_frame.grid(row=1, column=0, padx=20, pady=10, sticky="nsew")
        self.status_frame.grid_columnconfigure(0, weight=1)
        
        # Try to use Pyidaungsu font, fallback to default
        try:
            header_font = ctk.CTkFont(family="Pyidaungsu", size=26, weight="bold")
            button_font = ctk.CTkFont(family="Pyidaungsu", size=15, weight="normal")
            small_font = ctk.CTkFont(family="Pyidaungsu", size=11)
        except:
            header_font = ctk.CTkFont(size=26, weight="bold")
            button_font = ctk.CTkFont(size=15, weight="normal")
            small_font = ctk.CTkFont(size=11)
        
        # Current Status Label
        ctk.CTkLabel(
            self.status_frame, 
            text="လက်ရှိ အခြေအနေ",
            font=header_font,
            height=40,          
            pady=5              
        ).grid(row=0, column=0, pady=(10, 0))
        
        self.status_var = ctk.StringVar(value="စစ်ဆေးနေသည်...")
        self.status_label = ctk.CTkLabel(
            self.status_frame, 
            textvariable=self.status_var, 
            font=ctk.CTkFont(size=18, weight="bold")
        )
        self.status_label.grid(row=1, column=0, pady=(0, 10))

        # Buttons
        self.btn_on = ctk.CTkButton(
            self, 
            text="Turn ON (အပြည့်အဝဖွင့်)", 
            command=lambda: self.set_sac_mode(1), 
            height=50, 
            font=button_font
        )
        self.btn_on.grid(row=2, column=0, padx=40, pady=10, sticky="ew")

        self.btn_eval = ctk.CTkButton(
            self, 
            text="Evaluation Mode (စမ်းသပ်)", 
            command=lambda: self.set_sac_mode(2), 
            height=50, 
            font=button_font
        )
        self.btn_eval.grid(row=3, column=0, padx=40, pady=10, sticky="ew")

        self.btn_off = ctk.CTkButton(
            self, 
            text="Turn OFF (အပြီးပိတ်ရန်)", 
            height=50, 
            font=button_font, 
            fg_color="#d32f2f", 
            hover_color="#b71c1c", 
            command=self.confirm_turn_off
        )
        self.btn_off.grid(row=4, column=0, padx=40, pady=(20, 10), sticky="ew")

        # Programmer Name
        self.programmer_label = ctk.CTkLabel(
            self, 
            text="Programmed by YawHackka", 
            font=small_font,
            text_color="gray"
        )
        self.programmer_label.grid(row=5, column=0, padx=20, pady=(0, 15), sticky="e")

        # System Tray setup
        self.tray_icon = None
        self.setup_tray()
        self.update_status()

    def create_icon_image(self, color):
        """Create icon image for system tray"""
        image = Image.new('RGB', (64, 64), color=(255, 255, 255))
        d = ImageDraw.Draw(image)
        d.ellipse((10, 10, 54, 54), fill=color)
        return image

    def setup_tray(self):
        """Setup system tray icon"""
        menu = (
            pystray.MenuItem('Open', self.show_window, default=True),
            pystray.MenuItem('Quit', self.quit_app)
        )
        self.tray_icon = pystray.Icon(
            "YawStar_SAC_Manager", 
            self.create_icon_image("gray"), 
            "YawStar SAC Manager", 
            menu
        )
        threading.Thread(target=self.tray_icon.run, daemon=True).start()

    def update_status(self):
        """Update SAC status display"""
        status = self.get_sac_status()
        self.status_var.set(status)
        
        if "OFF" in status:
            self.status_label.configure(text_color="#ff4444")
            if self.tray_icon:
                self.tray_icon.icon = self.create_icon_image("red")
        elif "ON" in status:
            self.status_label.configure(text_color="#00C851")
            if self.tray_icon:
                self.tray_icon.icon = self.create_icon_image("green")
        else:
            self.status_label.configure(text_color="#ffbb33")
            if self.tray_icon:
                self.tray_icon.icon = self.create_icon_image("orange")
    
    def hide_window(self):
        """Hide window to system tray"""
        self.withdraw()
        if self.tray_icon:
            try:
                self.tray_icon.notify(
                    message="နောက်ကွယ်မှာ အလုပ်လုပ်နေဆဲပါ\nNotification Area မှာ ရှာနိုင်ပါတယ်...\nအကယ်လို့ ပိတ်ချင်ရင် Right Click > Quit ကို နှိပ်ပြီးပိတ်နိုင်ပါတယ်..",
                    title="YawStar SAC Manager"
                )
            except Exception as e:
                print(f"Notification Error: {e}")

    def show_window(self):
        """Show window from system tray"""
        self.after(0, lambda: self.deiconify())
        self.after(100, self.lift)
        self.after(100, self.focus_force)

    def quit_app(self):
        """Quit application completely"""
        if self.tray_icon:
            self.tray_icon.stop()
        self.quit()
        self.destroy()

    def get_sac_status(self):
        """Get current SAC status from registry"""
        try:
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\CI\Policy", 0, winreg.KEY_READ)
            value, _ = winreg.QueryValueEx(key, "VerifiedAndReputablePolicyState")
            winreg.CloseKey(key)
            if value == 2:
                return "ON (Evaluation Mode)"
            if value == 1:
                return "ON (အလုပ်လုပ်နေတယ်)"
            if value == 0:
                return "OFF (ပိတ်ထားတယ်)"
        except:
            pass
        return "SAC Status မသိရပါ"

    def set_sac_mode(self, value):
        """Set SAC mode (1=ON, 2=Evaluation, 0=OFF)"""
        try:
            now = datetime.now()
            print(now.strftime("%Y-%m-%d %H:%M:%S"))
            
            if value == 1:
                print("Turning on SAC")
            elif value == 2:
                print("Evaluation Mode")
            else:
                print("Turning Off SAC")
            
            # Update registry
            key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Control\CI\Policy", 0, winreg.KEY_SET_VALUE)
            winreg.SetValueEx(key, "VerifiedAndReputablePolicyState", 0, winreg.REG_DWORD, value)
            winreg.CloseKey(key)
            
            # Run CiTool.exe
            run_citool_auto_enter()
            
            messagebox.showinfo("Success", "SAC settings was successfully changed.")
            self.update_status()
            
        except Exception as e:
            messagebox.showerror("Error", f"မအောင်မြင်ပါ: {e}")

    def confirm_turn_off(self):
        """Confirm before turning off SAC"""
        if messagebox.askyesno("Confirm", "Are you sure to turn off SAC?"):
            self.set_sac_mode(0)

def run_citool_auto_enter():
    """Run CiTool.exe -r without showing window"""
    try:
        SW_HIDE = 0
        CREATE_NO_WINDOW = 0x08000000
        
        startupinfo = subprocess.STARTUPINFO()
        startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startupinfo.wShowWindow = SW_HIDE
        
        process = subprocess.Popen(
            ["CiTool.exe", "-r"],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            startupinfo=startupinfo,
            creationflags=CREATE_NO_WINDOW
        )
        
        stdout, stderr = process.communicate(input="\n", timeout=30)
        
        if process.returncode == 0:
            print("✅ Success!")
            return True
        else:
            print(f"❌ Failed! Error code: {process.returncode}")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ Timeout!")
        process.kill()
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    # Create mutex manager with correct app name
    mutex_manager = SingleInstanceManager("YawStar SAC Manager")
    
    # Check if already running
    if not mutex_manager.try_acquire():
        print("Exiting due to duplicate instance")
        sys.exit()

    # Check Windows version and admin rights
    ver = sys.getwindowsversion()
    if ver.build >= 26200:
        if not is_admin():
            run_as_admin()
        else:
            app = SACManagerGUI()
            
            # Release mutex when app closes
            original_quit = app.quit
            def on_quit():
                mutex_manager.release()
                original_quit()
            app.quit = on_quit
            
            app.mainloop()
    else:
        messagebox.showinfo(
            "Notice", 
            f"This program can only be used on Windows versions with build number 26200 or higher.\n\nYour Windows build number: {ver.build}"
        )