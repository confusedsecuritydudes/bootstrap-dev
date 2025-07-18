

## ⚡ New-Device Quick-Start

> Goal: take a freshly imaged Windows 11 box from **zero** to a fully bootstrapped WSL Ubuntu dev environment in \~5 minutes.

### 0 . Prerequisites on Windows

1. **Enable WSL 2** (Admin PowerShell):

   ```powershell
   wsl --install
   ```

   *If the command complains it already exists, you’re good.*

2. **Install Ubuntu** from the Microsoft Store **or**:

   ```powershell
   wsl --install -d Ubuntu
   ```

3. *(Optional but recommended)* Install **Docker Desktop** and check
   *Settings → Resources → WSL Integration → Ubuntu*.

4. *(Optional)* Install **Visual Studio Code** (standard Windows installer).

---

### 1 . Grab the bootstrap repo

Launch the new Ubuntu shell and run:

```bash
# Choose a folder that survives distro exports; $HOME is fine
git clone https://github.com/<your-user>/bootstrap-dev.git
cd bootstrap-dev
```

*(HTTPS clone needs no SSH key yet; we’ll generate the key later.)*

---

### 2 . Run the bootstrap script

```bash
chmod +x bootstrap.sh              # first time only
./bootstrap.sh
```

What happens:

* Installs apt basics, `nvm`, Node 22, Docker group membership, `pipx`, etc.
* Creates the standard folder layout `~/dev/{projects,configs,scripts}`.
* Exports your VS Code extension list to `~/dev/configs/vscode-extensions.txt`.

The script is **idempotent**—re-run it at any time and it only fixes what’s missing.

> **Heads-up:** If the script adds you to the `docker` group it prints a
> message. *Close all WSL windows and open a new one* so new group
> membership and `PATH` tweaks take effect.

---

### 3 . Generate an SSH key & load it into GitHub

```bash
ssh-keygen -t ed25519 -C "$(hostname)-wsl" -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Copy the key, add it to **GitHub → Settings → SSH & GPG keys**, name it “WSL-\$(hostname)”.

```bash
# test
ssh -T git@github.com
```

---
### 4 . Clone your dev stack repositories

Now that SSH works:

```bash
cd ~/dev/configs
git clone git@github.com:<your-user>/home-dev-stacks.git
```


### 5 . Clone your real code repositories

Now we have our docker containers started (for n8n etc):

```bash
cd ~/dev/projects
git clone git@github.com:<your-user>/<private-repo>.git
```

Repeat for any other repos.

---

### 6 . Restore project-level Python/Node deps

Inside each project (example):

```bash
cd ~/dev/projects/claude-mcp
# Python
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
# Node
nvm use 22
npm install
```

---

### 7 . Import secrets (if any)

The bootstrap script will source any file you drop into **`~/.config/secrets/`**.
Copy your `anthropic.env`, `.npmrc`, etc. into that folder **manually or via 1Password/Bitwarden CLI**.

---

### 8 . (Optional) Restore a complete WSL image

If you exported a tarball on your old machine:

```powershell
wsl --import Ubuntu C:\WSL\Ubuntu C:\Path\To\ubuntu-2025-07-16.tar --version 2
```

That skips steps 1-6 entirely.

---

#### Verify it worked

```bash
node -v        # v22.x
pipx --version
docker run hello-world
code .         # should open VS Code with "WSL:Ubuntu" in status bar
```

Enjoy your freshly-minted dev environment! 🎉

