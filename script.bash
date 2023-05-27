#!/bin/bash

##### GLOBALS
d_flag=false
v_flag=false
s_flag=false
k_flag=false
h_flag=false

temp_file=$(mktemp XXXXXXX.tmp)


##### GLOBALS ENDS

##### SERVICE PART STARTS

SERVICE_create_user() {
  local user_name=$1
  local is_create_homedir=$2
  local command="useradd"

  if [ "$is_create_homedir" == "y" ]; then
    command+=" -m"
  fi

  command+=" -g \"$user_name\" $user_name"
  sudo bash -c "$command" || echo "Command exit code: " $?
}

SERVICE_update_user() {
  local user_name=$1
  local user_new_name=$2
  local primary_group=$3
  local groups=$4
  local comment=$5
  local homedir=$6
  local login_shell=$7

  local command="usermod -l \"$user_new_name\" -g \"$primary_group\" --groups \"$groups\" -c \"$comment\"
  -d \"$homedir\" -s \"$login_shell\""

  local current_homedir_path
  current_homedir_path=$(grep "$user_name" /etc/passwd | cut -d":" -f6)

  if [ -d "$current_homedir_path" ]; then
    command+=" -m"
  fi

  command+=" $user_name"
  sudo bash -c "$command" || echo "Command exit code: " $?
}

SERVICE_delete_user() {
  local user_name=$1
  userdel "$user_name" || echo "Command exit code: " $?
}

SERVICE_get_user_info() { # Returns info in /etc/passwd format string TODO: Change this search algorithm
  local user_name=$1
  local user_info
  user_info=$(grep "$user_name" /etc/passwd) || echo "Command exit code: " $?
  echo "$user_info"
}

SERVICE_create_group() {
  local group_name=$1
  groupadd "$group_name" || echo "Command exit code: " $?
}

SERVICE_update_group() {
  local group_name=$1
  local group_new_name=$2
  local gid=$3

  local command="groupmod -g \"$gid\" -n \"$group_new_name\" \"$group_name\""

  sudo bash -c "$command" || echo "Command exit code: " $?
}

SERVICE_delete_group() {
  local group_name=$1
  groupdel "$group_name" || echo "Command exit code: " $?
}

SERVICE_get_group_info() { # Returns info in /etc/group format string TODO: Change this search algorithm
  local group_name=$1
  local group_info
  group_info=$(grep "$group_name" /etc/group) || echo "Command exit code: " $?
  echo "$group_info"
}

##### SERVICE PART ENDS
##### FRONTEND/INPUT PART STARTS

INPUT_create_user() {
  echo "Введите имя пользователя:"
  local user_name
  read -r user_name

  echo "Создать домашнюю директорию?(Y/n):"
  local is_create_homedir
  read -r is_create_homedir

  if [ "$is_create_homedir" == "" ]; then
    is_create_homedir="y"
  fi

  SERVICE_create_user "$user_name" "$is_create_homedir"

  echo "Пользователь создан"
}

INPUT_update_user() {
  echo "Введите имя пользователя:"
  local user_name
  read -r user_name

  echo "Введите новое имя пользователя:"
  local user_new_name
  read -r user_new_name

  echo "Введите новую первичную группу:"
  local new_primary_group
  read -r new_primary_group

  echo "Введите через запятую группы, в которых будет состоять пользователь:"
  local new_groups
  read -r new_groups

  echo "Введите новый комментарий пользователя:"
  local new_comment
  read -r new_comment

  echo "Введите путь новой домашней директории:"
  local new_home_dir_path
  read -r new_home_dir_path

  echo "Введите путь до новой оболочки входа:"
  local new_login_shell_path
  read -r new_login_shell_path

  SERVICE_update_user "$user_name" "$user_new_name" "$new_primary_group"
  "$new_groups" "$new_comment" "$new_home_dir_path" "$new_login_shell_path"

  echo "Данные пользователя обновлены"
}

INPUT_delete_user() {
  echo "Введите имя пользователя:"

  local user_name
  read -r user_name
  SERVICE_delete_user "$user_name"

  echo "Пользователь удален"
}

INPUT_get_user_info() {
  echo
  echo "Введите имя пользователя:"

  local user_name
  read -r user_name

  local user_info
  user_info=$(SERVICE_get_user_info "$user_name")

  local user_info_array
  IFS=":" read -r -ra user_info_array <<<"$user_info"

  echo
  echo "Информация о пользователе:"
  echo "Имя пользователя: " "${user_info_array[0]}"
  echo "UID: " "${user_info_array[2]}"
  echo "GID: " "${user_info_array[3]}"
  echo "Комментарий: " "${user_info_array[4]}"
  echo "Домашняя директория: " "${user_info_array[5]}"
  echo "Оболочка входа: " "${user_info_array[6]}"
}

INPUT_create_group() {
  echo "Введите имя группы:"

  local group_name
  read -r group_name
  SERVICE_create_group "$group_name"

  echo "Группа создана"
}

INPUT_update_group() {
  echo "Введите имя группы:"
  local group_name
  read -r group_name

  echo "Введите новое название группы:"
  local group_new_name
  read -r group_new_name

  echo "Введите новый gid:"
  local gid
  read -r gid

  SERVICE_update_group "$group_name" "$group_new_name" "$gid"

  echo "Данные пользователя обновлены"
}

INPUT_delete_group() {
  echo "Введите имя группы:"

  local group_name
  read -r group_name

  SERVICE_delete_group "$group_name"

  echo "Группа удалена"
}

INPUT_get_group_info() {
  echo
  echo "Введите имя группы:"

  local group_name
  read -r group_name

  local group_info
  group_info=$(SERVICE_get_group_info "$group_name")

  local group_info_array
  IFS=":" read -r -ra group_info_array <<<"$group_info"

  echo
  echo "Информация о пользователе:"
  echo "Название группы: " "${group_info_array[0]}"
  echo "GID: " "${group_info_array[2]}"
  echo "Пользователи: " "${group_info_array[3]}"
}

INPUT_choose_option() {
  local choice=$1

  case $choice in
  1)
    INPUT_create_user
    ;;
  2)
    INPUT_update_user
    ;;
  3)
    INPUT_delete_user
    ;;
  4)
    INPUT_get_user_info
    ;;
  5)
    INPUT_create_group
    ;;
  6)
    INPUT_update_group
    ;;
  7)
    INPUT_delete_group
    ;;
  8)
    INPUT_get_group_info
    ;;
  9)
    script_exit
    ;;
  esac
}

INPUT_show_user_menu() {
  echo "1) Добавить пользователя"
  echo "2) Изменить пользователя"
  echo "3) Удалить пользователя"
  echo "4) Информация о пользователе"
  echo "5) Добавить группу"
  echo "6) Изменить группу"
  echo "7) Удалить группу"
  echo "8) Информация о группе"
  echo "9) Выход"
}

INPUT_serve_user_menu() {
  local user_choice

  while true; do
    INPUT_show_user_menu
    echo
    read -r user_choice
    INPUT_choose_option "$user_choice"
    echo
  done
}

##### FRONTEND/INPUT PART ENDS

##### FLAGS HANDLING STARTS

FLAGS_d_handler() {
  if [ $d_flag == false ]; then
    return
  fi

  echo "Удалить предыдущий файл или продолжить запись в него?(1/2)"

  local log_file_choice
  read -r log_file_choice

  if [ "$log_file_choice" == 1 ]; then
    exec > >(tee script_KVA.out) 2>&1
  elif [ "$log_file_choice" == 2 ]; then
    exec > >(tee -a script_KVA.out) 2>&1
  fi

  echo
  echo "Время запуска скрипта: $(ps -p $$ -o start=)"
  echo
}

FLAGS_v_handler() {
  if [ $v_flag == false ]; then
    return 0
  fi
  set -vx
}

FLAGS_s_handler() {
  if [ $s_flag == false ]; then
    return
  fi

  local script_procs_count
  script_procs_count=$(pgrep -c "$(basename "$0")")

  if [ "$script_procs_count" -gt 1 ]; then
    echo "Запущены другие экземпляры скрипта: $((script_procs_count-1))"
    exit 3
  fi
}

FLAGS_k_handler() {
  if [ $k_flag == false ]; then
    return
  fi

  ps -eo pid,ppid,uid,gid,tty,start,cmd | grep "$(basename "$0")"

  echo "Завершить все запущенные экземпляры скрипта?(Y/n):"
  local is_kill_all_script_procs
  read -r is_kill_all_script_procs

  if
    [ "$is_kill_all_script_procs" == "Y" ] ||
    [ "$is_kill_all_script_procs" == "y" ] ||
    [ "$is_kill_all_script_procs" == "" ]
  then
    echo "SIGTERM или SIGKILL?(1/2)"
    local signal_choice
    read -r signal_choice

    if [ "$signal_choice" == 1 ]; then
      pkill --signal SIGTERM "$(basename "$0")"
    elif [ "$signal_choice" == 2 ]; then
      pkill --signal SIGKILL "$(basename "$0")"
    fi
  fi
  echo
}

FLAGS_h_handler() {
  if [ "$h_flag" == false ]; then
    return
  fi

  echo "Автор скрипта: Кибисов Владимир"
  echo "$(basename "$0") [-dvskh]"
  echo "-h - информация о скрипте"
  echo "-d - дублирование вывода в файл script_KVA.out"
  echo "-v - вывод исполняемых строк скрипта и вызываемых команд в терминал"
  echo "-s - проверка, является ли текущий процесс скрипта единственный"
  echo "-k - просмотр и опциональное закрытие всех запущенных процессов скрипта"

  echo
  echo "Текущие дата и время: $(date)"
  echo "Название временного файла: $temp_file"
  echo "Имя системы: $(uname -srv)"
  echo "Имя текущего терминала: $(tty)"

  echo "RUID: $(id -ru)($(id -run))"
  echo "EUID: $(id -u)($(id -un))"
  if [ "$(id -u)" == 0 ] || [ "$(id -g)" == 0 ]; then
    echo "Скрипт запущен пользователем root или администратором"
  fi

  echo "RGID: $(id -rg)($(id -rgn))"
  echo "EGID: $(id -g)($(id -gn))"

  echo "PID: $$"
  echo "Имя файла скрипта: $(basename "$0")"
  echo "Путь до скрипта: $0"
  echo "Командная строка, используемая при запуске скрипта: $(ps -p $$ -o cmd)"

  echo "Размер файла: $(stat -c "%s" "$0") байт"
  echo "Права доступа: $(stat -c "%A" "$0")"
  echo "Время последней модификации: $(stat -c "%y" "$0")"
  echo "Владелец-пользователь скрипта: $(stat -c "%u(%U)" "$0")"
  echo "Владелец-группа скрипта: $(stat -c "%g(%G)" "$0")"

  echo
  echo "Продолжить работу скрипта?(Y/n):"
  local is_continue_script_execution
  read -r is_continue_script_execution

  if
    [ "$is_continue_script_execution" == "Y" ] ||
    [ "$is_continue_script_execution" == "y" ] ||
    [ "$is_continue_script_execution" == "" ];
  then
    return 0
  elif [ "$is_continue_script_execution" == "n" ]; then
    exit 2
  fi
}

FLAGS_flags_handlers() {
  FLAGS_d_handler
  FLAGS_v_handler
  FLAGS_s_handler
  FLAGS_k_handler
  FLAGS_h_handler
}

##### FLAGS HANDLING ENDS

##### UTILS STARTS

script_exit() {
  rm "$temp_file"
  echo "Скрипт завершен"
  if [ $d_flag == true ]; then
    date "+Время завершения работы: %H:%M:%S"
  fi
  exit 0
}

create_temp_info() {
  {
    echo "KVA"
    basename "$0"
    echo "$$"
    date "+%d-%m-%y %H:%M:%S (%Z)"
  } >>"$temp_file"
}

##### UTILS ENDS

##### SIGNALS STARTS

SIGINT_handler() {
  echo "Вы действительно хотите выйти?(Y/n):"
  local user_choice
  read -r user_choice
  if
    [ "$user_choice" == "Y" ] ||
    [ "$user_choice" == "y" ] ||
    [ "$user_choice" == "" ]
  then
    exit 1
  fi
}

create_signals_handlers() {
  trap SIGINT_handler SIGINT
  trap script_exit SIGQUIT
  trap script_exit SIGTERM

  trap '
  ps -p $$ -o start,etime,time;
  echo;
  ' SIGUSR1

  trap '
  lsof -p $$;
  echo;
  ' SIGUSR2
}

##### SIGNALS ENDS

##### ENTRY POINT

main() {
  create_temp_info
  FLAGS_flags_handlers
  create_signals_handlers
  INPUT_serve_user_menu
}

while getopts "dvskh" flag; do
  case $flag in
  d)
    d_flag=true;
    ;;
  v)
    v_flag=true;
    ;;
  s)
    s_flag=true;
    ;;
  k)
    k_flag=true;
    ;;
  h)
    h_flag=true;
    ;;
  *)
    echo "Wrong flag"
    exit 1
    ;;
  esac
done

main
