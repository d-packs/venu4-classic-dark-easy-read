# Building on Windows — step by step (no experience needed)

This guide is for people who have **never used a command line**. You set things up once
(about 30–40 minutes, mostly waiting), and after that, building your own watch face is a
single command. **Windows 11 is recommended.**

You'll end up with two watch files you copy onto your Venu 4:
- one with the **day + date** window,
- one with a plain **"3"**.

### Before you start
- A free **Garmin account** — make one at <https://www.garmin.com> if you don't have it.
- (Optional) your **logo** saved as a PNG file. White-on-transparent looks best; plain
  dark-on-white art also works. No logo = the dial's logo area is left empty.

> Tip: in the black "Ubuntu" window you'll use below, **right-click = paste**. Paste each
> grey block, then press **Enter**. If it asks for a password, type the one you created
> (the screen stays blank while you type — that's normal) and press Enter.

---

## Step 1 — Install "WSL" (a free Linux that runs inside Windows)

1. Click **Start**, type `PowerShell`.
2. **Right-click** "Windows PowerShell" → **Run as administrator** → **Yes**.
3. Paste this and press **Enter**:
   ```
   wsl --install
   ```
4. When it finishes, **restart your PC**.
5. After restarting, a black **Ubuntu** window opens by itself and says "Installing…". Wait.
   When prompted, type a **username** (lowercase, no spaces) and a **password** (twice).
   Write the password down.
   - If no window appears: click **Start**, type `Ubuntu`, click it.

## Step 2 — Install the build tools

In the Ubuntu window, paste this and press **Enter** (type your password if asked, wait for it to finish):
```
sudo apt update && sudo apt install -y python3 python3-pil openjdk-17-jre openssl git
```

## Step 3 — Download the project

Paste and **Enter**:
```
cd ~ && git clone https://github.com/d-packs/venu4-classic-dark-easy-read.git && cd venu4-classic-dark-easy-read
```

## Step 4 — Install Garmin's "Connect IQ SDK" (one time)

This is Garmin's official toolkit that turns the project into a watch file.

1. In your normal Windows web browser, open <https://developer.garmin.com/connect-iq/sdk/>
   and download the **SDK Manager for Linux** (a `.zip`). It lands in your **Downloads** folder.
2. In the Ubuntu window, open your Windows Downloads folder in Windows Explorer:
   ```
   explorer.exe .
   ```
   …actually, easier — unzip and run it straight from Ubuntu. Paste these **one block at a time**:
   ```
   mkdir -p ~/ciq && cd ~/ciq
   cp /mnt/c/Users/*/Downloads/connectiq-sdk-manager-linux*.zip . 2>/dev/null || true
   unzip -o connectiq-sdk-manager-linux*.zip
   ./sdkmanager
   ```
   If the `cp` line can't find the file (different Downloads location), drag the `.zip` into
   the Ubuntu home folder using Windows Explorer at `\\wsl$\Ubuntu\home\<your-username>\ciq`,
   then re-run the last two lines.
3. A **Garmin SDK Manager** window opens (Windows 11 shows Linux app windows automatically).
   - **Sign in** with your Garmin account.
   - **SDK** tab → install the **latest** SDK (accept the agreement).
   - **Devices** tab → find **Venu 4** → install it.
   - Close the SDK Manager window.

> If no window appears in step 3, you're likely on Windows 10 — Linux apps need Windows 11
> (or an extra "X server" setup). Upgrading to Windows 11 is the easy fix.

## Step 5 — Add your logo (optional)

Open the project's `assets` folder in Windows Explorer:
```
cd ~/venu4-classic-dark-easy-read && explorer.exe assets
```
Drag your logo into that window and make sure it's named exactly **`logo.png`**.
(Skip this step to build with an empty logo area.)

## Step 6 — Build it

Paste and **Enter**:
```
cd ~/venu4-classic-dark-easy-read && ./build-your-own.sh
```
The first time, it makes a signing key automatically. When you see **BUILD SUCCESSFUL** twice,
you're done.

### What you get and where it is

The build produces **two finished watch-face files** (ending in `.prg`) in the project's
**`bin`** folder:

- **`FieldInverted-Widget.prg`** — the face **with** the day + date window.
- **`FieldInverted-Plain.prg`** — the face **with a plain "3"** instead.

You only need one (whichever you like); you can also install both and they'll appear as two
separate faces. The folder, in Windows terms, is:
```
\\wsl$\Ubuntu\home\<your-username>\venu4-classic-dark-easy-read\bin
```
The quickest way to open it is to run this in the Ubuntu window:
```
cd ~/venu4-classic-dark-easy-read && explorer.exe bin
```

## Step 7 — Copy the face onto your watch

1. From Step 6 you should have an Explorer window open on the **`bin`** folder showing the two
   `.prg` files. (If not: `cd ~/venu4-classic-dark-easy-read && explorer.exe bin`.)
2. Plug the Venu 4 into the PC with its USB cable and **unlock the watch** if it asks. It shows
   up in Windows Explorer like a USB drive — usually named **"Venu 4"** (it may contain a folder
   called **"Primary"** or **"Internal Storage"**).
3. On the watch, open the **`GARMIN`** folder, then the **`Apps`** folder inside it.
4. **Drag the `.prg` file you want straight into that `Apps` folder.**
   > **Important:** the file goes **loose inside `Apps`** — do **not** create a new folder for
   > it, and don't rename it. Correct: `GARMIN\Apps\FieldInverted-Widget.prg`.
   > Wrong: `GARMIN\Apps\FieldInverted\FieldInverted-Widget.prg` (the watch won't find it).
5. Right-click the watch drive → **Eject**, then unplug.
6. On the watch, open the watch-face list (long-press the main screen, or Settings → Watch Face)
   and pick **Field Inverted**.

---

## Building again later

Once set up, you never repeat steps 1–4. To rebuild (e.g. after swapping your logo):
```
cd ~/venu4-classic-dark-easy-read && ./build-your-own.sh
```

## If something goes wrong

- **`./build-your-own.sh` says the SDK isn't found** → finish Step 4 (install the SDK *and* the
  Venu 4 device in the SDK Manager).
- **`python3 ... Pillow not found`** → re-run Step 2.
- **The SDK Manager window never opens** → you're probably on Windows 10; use Windows 11.
- **The watch doesn't show up in Explorer** → unlock it, try a different USB cable/port, and make
  sure it's not in a charging-only state.
