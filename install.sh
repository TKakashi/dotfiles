#!/bin/bash
# Включаем строгий режим для немедленного выхода при ошибках
set -euo pipefail

# ──────────────────────────────────────────────
# Установочный скрипт dotfiles для Hyprland
# ──────────────────────────────────────────────

echo "===== Установка dotfiles для Hyprland ====="

# 1. Проверка, что система — Arch Linux
if [ ! -f /etc/arch-release ]; then
    echo "❌ Этот скрипт предназначен только для Arch Linux."
    exit 1
fi

# 2. Запрос подтверждения
read -rp "Продолжить установку? Будут установлены пакеты и изменены конфиги. (y/N) " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Отмена."
    exit 0
fi

# 3. Убедимся, что установлены базовые инструменты
if ! command -v git &>/dev/null || ! command -v base-devel &>/dev/null; then
    echo "📦 Устанавливаю base-devel и git..."
    sudo pacman -S --needed --noconfirm base-devel git
fi

# 4. Установка AUR-хелпера (yay), если его нет
if ! command -v yay &>/dev/null; then
    echo "📦 yay не найден. Устанавливаю из AUR..."
    tempdir=$(mktemp -d)
    # Явная проверка успешности клонирования
    if git clone https://aur.archlinux.org/yay.git "$tempdir/yay"; then
        cd "$tempdir/yay"
        makepkg -si --noconfirm
        cd -
    else
        echo "❌ Ошибка: не удалось клонировать репозиторий yay." >&2
        rm -rf "$tempdir"
        exit 1
    fi
    rm -rf "$tempdir"
fi

# 5. Установка официальных пакетов
echo "📦 Установка официальных пакетов..."
# Читаем список, удаляя комментарии и пустые строки
grep -vE '^\s*(#|$)' packages/official.txt | sudo pacman -S --needed --noconfirm -

# 6. Установка AUR-пакетов
echo "📦 Установка AUR-пакетов..."
yay -S --needed --noconfirm $(grep -vE '^\s*(#|$)' packages/aur.txt)

# 7. Резервное копирование существующих конфигов и создание симлинков
BACKUP_DIR="$HOME/dotfiles_backup_$(date +%Y%m%d%H%M%S)"
echo "📁 Резервное копирование существующих конфигов в $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Функция для аккуратного раскладывания файлов из config/ в $HOME
stow_config() {
    local app="$1"
    local src="config/$app"
    echo "   🔗 Настройка $app..."

    # Рекурсивно проходим по всем файлам и каталогам внутри src
    while IFS= read -r -d '' file; do
        # Определяем относительный путь от src
        rel="${file#$src/}"
        target="$HOME/$rel"

        # Если на целевом месте уже есть обычный файл/каталог (не симлинк) — делаем бэкап
        if [ -e "$target" ] && [ ! -L "$target" ]; then
            mkdir -p "$(dirname "$BACKUP_DIR/$rel")"
            mv "$target" "$BACKUP_DIR/$rel"
            echo "      ⚠️  Создан бэкап: $target → $BACKUP_DIR/$rel"
        fi

        # Создаём родительский каталог, если нужно
        mkdir -p "$(dirname "$target")"

        # Удаляем существующий симлинк/файл (после бэкапа) и создаём новый симлинк
        rm -f "$target"
        ln -s "$(realpath "$file")" "$target"
    done < <(find "$src" -type f -print0)
}

# Применяем stow_config ко всем подкаталогам в config/
for d in config/*/; do
    app=$(basename "$d")
    stow_config "$app"
done

# 8. Копируем обои для hyprpaper (если есть)
WALLPAPER_SRC="wallpapers/wallpaper.jpg"
WALLPAPER_DST="$HOME/.config/hypr/wallpaper.jpg"
if [ -f "$WALLPAPER_SRC" ]; then
    mkdir -p "$(dirname "$WALLPAPER_DST")"
    if [ ! -f "$WALLPAPER_DST" ]; then
        echo "🖼️ Копирую обои в $WALLPAPER_DST"
        cp "$WALLPAPER_SRC" "$WALLPAPER_DST"
    fi
else
    echo "⚠️  Пример обоев не найден ($WALLPAPER_SRC). Поместите свои обои в $WALLPAPER_DST или измените hyprpaper.conf"
fi

# 9. Установка Zsh оболочкой по умолчанию
if command -v zsh &>/dev/null; then
    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "🐚 Меняю оболочку по умолчанию на Zsh..."
        if chsh -s "$(which zsh)" "$USER"; then
            echo "✅ Оболочка изменена на Zsh. Изменения вступят в силу после перезахода в систему."
        else
            echo "❌ Не удалось изменить оболочку. Попробуйте вручную: chsh -s $(which zsh)" >&2
        fi
    fi
fi

# 10. Делаем исполняемыми все скрипты в .local/bin
if [ -d "$HOME/.local/bin" ]; then
    echo "🔧 Устанавливаю права на выполнение для пользовательских скриптов..."
    chmod +x "$HOME/.local/bin"/*
fi

echo ""
echo "✅ Установка завершена!"

# 11. Включение NetworkManager, если он не активен
if ! systemctl is-enabled NetworkManager.service &>/dev/null; then
    echo "🔌 Включаю NetworkManager..."
    sudo systemctl enable --now NetworkManager.service
else
    echo "✅ NetworkManager уже включён."
fi
