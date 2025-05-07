# 🖨️ plates.sh — Automate G-code Duplication in .3mf Archives

`plates.sh` is a terminal utility script designed to simplify the duplication of G-code content inside `.3mf` archives, supporting multi-language interaction, customizable duplication, print bed cooldown automation, and summary output for printing setup.

---

## 🌟 Features

- 📦 **Works with .3mf archives** containing `plate_*.gcode` files.
- 🔁 **Duplicate any plate N times** — useful for mass-printing identical models.
- 🔗 **Merge mode**: Combine multiple plates into a single `plate_1.gcode` file.
- ♨️ **Automatically updates** `M190 S22` lines with a custom bed temperature.
- 🖋️ **Signature check**: Ensures each G-code file contains `Made by FactorianDesigns` to avoid using foreign or malformed files.
- ⚖️ **Calculates filament weight** per plate based on slicer comments.
- 🌐 **Multilingual support**: Interface available in English and Ukrainian.
- 📊 **Clear summary output**: Includes format, temperature, filament usage, and file size.
- 📈 **Progress bars** while copying.

---

## 🔧 Requirements

Make sure the following utilities are installed:

```bash
sudo apt install zenity unzip zip sed
```

---

## 🚀 How to Use

1. Launch the script:

   ```bash
   bash plates.sh
   ```

2. Follow prompts to:

   - Choose interface language (auto-detected or manual).
   - Select a `.3mf` archive.
   - Decide whether to merge plates or process separately.
   - Set print bed cooldown temperature.
   - Enter number of copies for each plate.

3. Script will process the files and output a new `.3mf` archive with duplication applied.

---

## 📁 Example Output File Name

```bash
22cap_best_automated_merged(1-3_2-2).gcode.3mf
```

Where:

- `merged` = merged into one plate.
- `1-3` = 3 copies of plate 1.
- `2-2` = 2 copies of plate 2.

---

## 🛡️ G-code Signature Check

This script **refuses to operate** if any G-code file inside the archive does not contain the signature `Made by FactorianDesigns`. This ensures all files follow your automation standard.

---

## 🗨️ Localization

If your system language is `uk` or `en`, the script will suggest that language. You can override it during the prompt. The language will affect all displayed messages and summaries.

---

## 📋 Example Summary Output

```
============================== SUMMARY ==============================
📦 Saved as: /home/user/Downloads/example_automated(1-3_2-2).gcode.3mf
♨️  Bed temperature for release: 25 °C
📋 Print format: Merged into one plate
🧩 Plate 1 – 3 × 23.12g = 69.36g
🧩 Plate 2 – 2 × 40.38g = 80.76g
⚖️  Total filament weight: 150.12 g
📏 Archive size: 2.6M
=====================================================================
```

