#!/bin/bash

# ===================== 🌍 Multilang =====================
declare -A TEXT_UK=(
    [select_file_info]="🔔 Натисніть Enter, щоб відкрити вікно вибору файлу..."
    [select_file]="Оберіть .3mf архів"
    [no_file_selected]="❗️ Файл не вибрано або дія скасована."
    [not_found]="❗️ Не знайдено файлів plate_*.gcode"
    [plates_found]="стола(ів)-знайдено:"
    [no_signature]="❗️ У файлі %s не виявлено підпису « \xabMade by FactorianDesigns» \xabMade by FactorianDesigns\xbb.\n⛔️ Даний G-code, ймовірно, не створений із шаблону автоматизації.\n🔧 Будь ласка, перевірте налаштування слайсера або профіль експорту."
    [merge_question]="❓ Скомбінувати всі в один файл plate_1.gcode? (y/N): "
    [enter_temp]="🛠️ Яку виставити температуру стола для автоматичного скидання деталі? (Enter для 25°C): "
    [merge_start]="➡️ Об'єднання у plate_1.gcode"
    [copy_prompt]="📝 Скільки копій вам потрібно надрукувати з %s? (Enter для 1): "
    [copy_prompt_sep]="📝 Скільки копій вам потрібно надрукувати для %s? (Enter для 1): "
    [copy_done]="✅ Копіювання завершено."
    [merge_done]="✅ Створено plate_1.gcode. Інші plate-файли видалено."
    [process_each]="➡️ Обробка кожного plate-файлу окремо"
    [summary_title]="============================== ПІДСУМКИ =============================="
    [summary_saved]="📦 Збережено як: %s"
    [summary_temp]="♨️  Температура стола під час скидання: %s °C"
    [summary_format]="📋 Формат друку: %s"
    [summary_total]="⚖️  Загальна вага: %s г"
    [summary_size]="📏 Розмір архіву: %s"
    [summary_end]="====================================================================="
    [print_mode_merged]="Об'єднано в один стіл"
    [print_mode_separated]="Роздільний друк по столах"
)

declare -A TEXT_EN=(
    [select_file_info]="🔔 Press Enter to open the file selection window..."
    [lang_detected]="🌍 System language detected: English (en)"
    [lang_prompt]="🔧 Choose interface language (uk/en) [Enter = %s]: "
    [lang_fallback]="🌍 Language not detected. Defaulting to: Ukrainian (uk)"
    [select_file]="Select a .3mf archive"
    [no_file_selected]="❌ No file selected or action canceled."
    [not_found]="❌ No plate_*.gcode files found"
    [plates_found]="plate(s)-found:"
    [no_signature]="❌ File %s is missing the signature 'Made by FactorianDesigns'.\n⛔️ This G-code may not be generated from an automation template.\n🔧 Please check slicer settings or export profile."
    [merge_question]="❓ Merge all into plate_1.gcode? (y/N): "
    [enter_temp]="🛠️ Set bed temp for auto-release (Enter for 25°C): "
    [merge_start]="➡️ Merging into plate_1.gcode"
    [copy_prompt]="📝 How many copies to print from %s? (Enter for 1): "
    [copy_prompt_sep]="📝 How many copies to print for %s? (Enter for 1): "
    [copy_done]="✅ Copying completed."
    [merge_done]="✅ plate_1.gcode created. Other plate files removed."
    [process_each]="➡️ Processing each plate file separately"
    [summary_title]="============================== SUMMARY =============================="
    [summary_saved]="📦 Saved as: %s"
    [summary_temp]="♨️  Bed temperature for release: %s °C"
    [summary_format]="📋 Print format: %s"
    [summary_total]="⚖️  Total filament weight: %s g"
    [summary_size]="📏 Archive size: %s"
    [summary_end]="====================================================================="
    [print_mode_merged]="Merged into one plate"
    [print_mode_separated]="Separate printing per plate"
)

# ===================== 📦 Lang Choose =====================
DEFAULT_LANG=${LANG%%.*}
DEFAULT_CODE=${DEFAULT_LANG:0:2}

if [[ "$DEFAULT_CODE" == "uk" ]]; then
    SUGGESTED_LANG="uk"
    declare -n TEXT=TEXT_UK
    echo "${TEXT[lang_detected]}"
elif [[ "$DEFAULT_CODE" == "en" ]]; then
    SUGGESTED_LANG="en"
    declare -n TEXT=TEXT_EN
    echo "${TEXT[lang_detected]}"
else
    SUGGESTED_LANG="en"
    declare -n TEXT=TEXT_EN
    echo "${TEXT[lang_fallback]}"
fi

read -p "$(printf "${TEXT[lang_prompt]}" "$SUGGESTED_LANG")" USER_INPUT
LANG_CODE=${USER_INPUT,,}
LANG_CODE=${LANG_CODE:-$SUGGESTED_LANG}
[[ "$LANG_CODE" != "uk" && "$LANG_CODE" != "en" ]] && LANG_CODE="uk"

declare -n TEXT_REF=TEXT_${LANG_CODE^^}

get_text() {
    local key=$1
    echo "${TEXT_REF[$key]}"
}



# ===================== 📦 Main Script =====================

REQUIRED_TOOLS=("zenity" "unzip" "zip" "sed")
for TOOL in "${REQUIRED_TOOLS[@]}"; do
    if ! command -v "$TOOL" &> /dev/null; then
        echo "❌ Missing: $TOOL"
        echo "   Install with: sudo apt install $TOOL"
        exit 1
    fi
done
read -p "$(get_text select_file_info)" 

ARCHIVE_PATH=$(zenity --file-selection --title="$(get_text select_file)" --file-filter="*.3mf")
[[ -z "$ARCHIVE_PATH" ]] && { echo "$(get_text no_file_selected)"; exit 1; }

BASENAME=$(basename -- "$ARCHIVE_PATH")ys
NAME="${BASENAME%.gcode.3mf}"
ARCHIVE_DIR=$(dirname "$ARCHIVE_PATH")
TMP_DIR=$(mktemp -d)

unzip -q "$ARCHIVE_PATH" -d "$TMP_DIR"

PLATE_DIR="$TMP_DIR/Metadata"
mapfile -t PLATES < <(find "$PLATE_DIR" -type f -name "plate_*.gcode" | sort)
[[ ${#PLATES[@]} -eq 0 ]] && { echo "$(get_text not_found)"; rm -rf "$TMP_DIR"; exit 2; }

for PLATE in "${PLATES[@]}"; do
    if ! grep -q "Made by FactorianDesigns" "$PLATE"; then
        printf "$(get_text no_signature)\n" "$(basename "$PLATE")"
        rm -rf "$TMP_DIR"
        exit 3
    fi
done

echo "🔍 ${#PLATES[@]} $(get_text plates_found)"
for p in "${PLATES[@]}"; do echo " - $(basename "$p")"; done

read -p "$(get_text merge_question)" MERGE_ANSWER
read -p "$(get_text enter_temp)" DROP_TEMP
DROP_TEMP=${DROP_TEMP:-25}
TARGET_TEMP=$((DROP_TEMP - 4))

MERGE_INFO=()
WEIGHT_INFO=()
TOTAL_WEIGHT=0

if [[ "$MERGE_ANSWER" == "y" ]]; then
    echo "$(get_text merge_start)"
    BUFFER_FILE="$PLATE_DIR/merged.tmp.gcode"
    > "$BUFFER_FILE"
    echo "; === AUTO-MERGED ===" >> "$BUFFER_FILE"

    for ((i = 0; i < ${#PLATES[@]}; i++)); do
        SRC="${PLATES[$i]}"
        INDEX=$((i + 1))
        BASENAME_SRC=$(basename "$SRC")

        printf "$(get_text copy_prompt)" "$BASENAME_SRC"
        read REPEAT
        REPEAT=${REPEAT:-1}

        echo "; === PLATE $INDEX ($REPEAT copies) ===" >> "$BUFFER_FILE"
        RAW_WEIGHT=$(grep -iE 'filament weight.*[0-9]' "$SRC" | grep -Eo '[0-9]+[.,][0-9]+' | sed 's/,/./' | head -n1)
        WEIGHT_PER_COPY=${RAW_WEIGHT:-0}
        WEIGHT_TOTAL=$(awk "BEGIN { printf \"%.2f\", $WEIGHT_PER_COPY * $REPEAT }")
        TOTAL_WEIGHT=$(awk "BEGIN { printf \"%.2f\", $TOTAL_WEIGHT + $WEIGHT_TOTAL }")
        WEIGHT_INFO+=("🧩 Plate $INDEX – $REPEAT × ${WEIGHT_PER_COPY}g = ${WEIGHT_TOTAL}g")

        CONTENT=$(grep -q "M190 S22" "$SRC" && sed "s/M190 S22/M190 S$TARGET_TEMP/g" "$SRC" || cat "$SRC")
        for ((j = 1; j <= REPEAT; j++)); do
            PROGRESS=$((j * 100 / REPEAT))
            FILLED=$((PROGRESS / 5))
            EMPTY=$((20 - FILLED))
            BAR=$(printf "%0.s█" $(seq 1 $FILLED))$(printf "%0.s░" $(seq 1 $EMPTY))
            echo -ne "\r   ➤ $j/$REPEAT [$BAR]"
            echo "$CONTENT" >> "$BUFFER_FILE"
        done
        echo ""
        MERGE_INFO+=("${INDEX}-${REPEAT}")
    done

    mv "$BUFFER_FILE" "$PLATE_DIR/plate_1.gcode"
    find "$PLATE_DIR" -type f -name "plate_*.gcode" ! -name "plate_1.gcode" -delete
    echo "$(get_text merge_done)"
else
    echo "$(get_text process_each)"
    for PLATE in "${PLATES[@]}"; do
        BASENAME_PLATE=$(basename "$PLATE")
        INDEX=$(echo "$BASENAME_PLATE" | grep -oP 'plate_\K[0-9]+')

        printf "$(get_text copy_prompt_sep)" "$BASENAME_PLATE"
        read REPEAT
        REPEAT=${REPEAT:-1}
        ORIGINAL="$PLATE"

        if grep -q "M190 S22" "$PLATE"; then
            sed "s/M190 S22/M190 S$TARGET_TEMP/g" "$PLATE" > "$PLATE.tmp" && mv "$PLATE.tmp" "$PLATE"
        fi

        CONTENT=$(cat "$PLATE")
        COPIES=$((REPEAT - 1))
        for ((j = 1; j <= COPIES; j++)); do
            PROGRESS=$((j * 100 / COPIES))
            FILLED=$((PROGRESS / 5))
            EMPTY=$((20 - FILLED))
            BAR=$(printf "%0.s█" $(seq 1 $FILLED))$(printf "%0.s░" $(seq 1 $EMPTY))
            echo -ne "\r   ➤ $j/$COPIES [$BAR]"
            echo "$CONTENT" >> "$PLATE"
        done
        echo ""

        MERGE_INFO+=("${INDEX}-${REPEAT}")

        RAW_WEIGHT=$(grep -iE 'filament weight.*[0-9]' "$ORIGINAL" | grep -Eo '[0-9]+[.,][0-9]+' | sed 's/,/./' | head -n1)
        WEIGHT_PER_COPY=${RAW_WEIGHT:-0}
        WEIGHT_TOTAL=$(awk "BEGIN { printf \"%.2f\", $WEIGHT_PER_COPY * $REPEAT }")
        TOTAL_WEIGHT=$(awk "BEGIN { printf \"%.2f\", $TOTAL_WEIGHT + $WEIGHT_TOTAL }")
        WEIGHT_INFO+=("🧩 Plate $INDEX – $REPEAT × ${WEIGHT_PER_COPY}g = ${WEIGHT_TOTAL}g")
    done
    echo "$(get_text copy_done)"
fi

MERGE_TAG=$(IFS=_; echo "${MERGE_INFO[*]}")
OUTPUT_ARCHIVE="${ARCHIVE_DIR}/${NAME}_automated"
[[ "$MERGE_ANSWER" == "y" ]] && OUTPUT_ARCHIVE+="_merged"
OUTPUT_ARCHIVE+="(${MERGE_TAG}).gcode.3mf"

cd "$TMP_DIR" && zip -rq "$OUTPUT_ARCHIVE" ./* && cd -
rm -rf "$TMP_DIR"
ARCHIVE_SIZE=$(du -h "$OUTPUT_ARCHIVE" | cut -f1)
FORMAT=$(get_text print_mode_separated)
[[ "$MERGE_ANSWER" == "y" ]] && FORMAT=$(get_text print_mode_merged)

echo -e "\n\033[1;32m$(get_text summary_title)\033[0m"
printf "$(get_text summary_saved)\n" "$OUTPUT_ARCHIVE"
printf "$(get_text summary_temp)\n" "$DROP_TEMP"
printf "$(get_text summary_format)\n" "$FORMAT"
printf '%s\n' "${WEIGHT_INFO[@]}"
printf "$(get_text summary_total)\n" "$TOTAL_WEIGHT"
printf "$(get_text summary_size)\n" "$ARCHIVE_SIZE"
echo -e "\033[1;32m$(get_text summary_end)\033[0m"
