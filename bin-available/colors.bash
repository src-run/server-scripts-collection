ui_reset='\033[21m\033[22m\033[24m\033[25m\033[27m\033[28m\033[0m'

ui_powerline_char_n=(pointingarrow arrowleft arrowright arrowrightdown arrowdown plusminus branch refersto ok fail lightnight cog heart star saxophone thumbsup)
ui_powerline_char_i=0
ui_powerline_pointingarrow='\u27a1'
ui_powerline_arrowleft='\ue0b2'
ui_powerline_arrowright='\ue0b0'
ui_powerline_arrowrightdown='\u2198'
ui_powerline_arrowdown='\u2b07'
ui_powerline_plusminus='\ue00b1'
ui_powerline_branch='\ue0a0'
ui_powerline_refersto='\u27a6'
ui_powerline_ok='\u2714'
ui_powerline_fail='\u2718'
ui_powerline_lightning='\u26a1'
ui_powerline_cog='\u2699'
ui_powerline_heart='\u2764'
ui_powerline_star='\u2b50'
ui_powerline_saxophone='\u1f3b7'
ui_powerline_thumbsup='\u1f44d'

ui_color_name_n=(default black red green yellow blue magenta cyan lightgray darkgray lightred lightgreen lightyellow lightblue lightmagenta lightcyan white)
ui_color_name_i=0
ui_color_black='\033[0;30m'
ui_color_red='\033[0;31m'
ui_color_green='\033[0;32m'
ui_color_yellow='\033[0;33m'
ui_color_blue='\033[0;34m'
ui_color_magenta='\033[0;35m'
ui_color_cyan='\033[0;36m'
ui_color_lightgray='\033[0;37m'
ui_color_darkgray='\033[0;90m'
ui_color_lightred='\033[0;91m'
ui_color_lightgreen='\033[0;92m'
ui_color_lightyellow='\033[0;93m'
ui_color_lightblue='\033[0;94m'
ui_color_lightmagenta='\033[0;95m'
ui_color_lightcyan='\033[0;96m'
ui_color_white='\033[0;97m'

ui_color_bold='\033[1m'
ui_color_dim='\033[2m'
ui_color_underline='\033[4m'
ui_color_blink='\033[5m'
ui_color_invert='\033[7m'
ui_color_invisible='\033[8m'

for i in 1 2 3 4 5 6 7 8 20 18 17; do
  printf '[%d] ' "${i}"
done
printf '\n'

for f in "${ui_powerline_pointingarrow}" "${ui_powerline_arrowleft}" "${ui_powerline_arrowright}" "${ui_powerline_arrowrightdown}" "${ui_powerline_arrowdown}" "${ui_powerline_plusminus}" "${ui_powerline_branch}" "${ui_powerline_refersto}" "${ui_powerline_ok}" "${ui_powerline_fail}" "${ui_powerline_lightning}" "${ui_powerline_cog}" "${ui_powerline_heart}" "${ui_powerline_star}" "${ui_powerline_saxophone}" "${ui_powerline_thumbsup}"; do

    echo -en "$(
        printf 'FONT-CHAR[%s]' "${ui_powerline_char_n[${ui_powerline_char_i}]}"
    )"

    for c in "${ui_reset}" "${ui_color_black}" "${ui_color_red}" "${ui_color_green}" "${ui_color_yellow}" "${ui_color_blue}" "${ui_color_magenta}" "${ui_color_cyan}" "${ui_color_lightgray}" "${ui_color_darkgray}" "${ui_color_lightred}" "${ui_color_lightgreen}" "${ui_color_lightyellow}" "${ui_color_lightblue}" "${ui_color_lightmagenta}" "${ui_color_lightcyan}" "${ui_color_white}"; do

        echo -en "$(
            printf '\n  %12s => "%s"' "${ui_color_name_n[${ui_color_name_i}]}" "${c}${f}${ui_reset}"
        )"


        ui_color_name_i=$((${ui_color_name_i} + 1))
        if [[ ${ui_color_name_i} -gt $((${#ui_color_name_n[@]} - 1)) ]]; then
            ui_color_name_i=0
        fi

    done

    printf '\n'

    ui_powerline_char_i=$((${ui_powerline_char_i} + 1))
    if [[ ${ui_powerline_char_i} -gt ${#ui_powerline_char_n[@]} ]]; then
        ui_powerline_char_i=0
    fi

done
