#!/bin/bash
# Скрипт для создания скриншотов: выделение области → буфер обмена + swappy для редактирования

TMPFILE=$(mktemp).png

# Выделение области через slurp, скриншот grim
grim -g "$(slurp)" "$TMPFILE"

# Отправка в буфер обмена и запуск редактора swappy
wl-copy < "$TMPFILE" && swappy -f "$TMPFILE"

# Уведомление
notify-send "Скриншот сохранён" "Файл: $TMPFILE (в буфере обмена)"

# Очистка временного файла после закрытия swappy
rm -f "$TMPFILE"
