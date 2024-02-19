#!/bin/sh

_jq_vtype() {
    printf "%s" "$1" | awk -v k="$2" \
'
BEGIN {
    null     = "null"
    num      = "num"
    str      = "str"
    true     = "true"
    false    = "false"
    obj      = "obj"
    arr      = "arr"
    arr_elem = "arr_elem"

    key  = "\""k"\""
    key_nxt = -1
    colon_nxt = -1

    if (k ~ "[[0-9]+]") {
        t = arr_elem
        exit
    }
}

{
    if (key_nxt == -1) {
        idx = index($0, key)
        if(idx == 0) next
        key_nxt = idx + length(key)
    }

    if (colon_nxt == -1) {
        idx = index(substr($0, key_nxt), ":")
        if(idx == 0) {
            key_nxt = 1
            next
        }
        colon_nxt = key_nxt + idx
    }

    len = length($0)
    split($0, chars, "")
    for (i = colon_nxt; i <= len; i++) {
        if (chars[i] == " ") continue

        if (chars[i] == "n")
            t = null
        else if (chars[i] ~ "[0-9]")
            t = num
        else if (chars[i] == "\"")
            t = str
        else if (chars[i] == "t")
            t = true
        else if (chars[i] == "f")
            t = false
        else if (chars[i] == "{")
            t = obj
        else if (chars[i] == "[")
            t = arr

        exit
    }

    colon_nxt = 1
}

END { print t }
'
}

_jq_num() {
    printf "%s" "$1" | awk -v k="$2" \
'
BEGIN { 
    start = -1
    key = "\""k"\""
}

{
    # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html
    if (start == -1) {
        idx = index($0, key)
        if(idx == 0) next
        start = idx + length(key)
    }

    len = length($0)
    split($0, chars, "")
    for (i = start; i <= len; i++) {
        if (v == "") {
            if (chars[i] ~ "[0-9]")
                v = chars[i]
            else if (chars[i] == "n") {
                # null and bool should checked by jq_btype.awk first
                v = "null"
                exit
            }
            continue
        }

        if (chars[i] !~ "[0-9]") exit

        v = v""chars[i]
    }
    
    if (v != "") v = v"\n"
}

END { print v }
'
}

_jq_str() {
    printf "%s" "$1" | awk -v k="$2" \
'
BEGIN { 
    start = -1
    key = "\""k"\""
}

{
    # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html
    if (start == -1) {
        idx = index($0, key)
        if(idx == 0) next
        start = idx + length(key)
    }

    len = length($0)
    split($0, chars, "")
    for (i = start; i <= len; i++) {
        if (v == "") {
            if (chars[i] == "\"") v = chars[i]
            else if (chars[i] == "n") {
                # null and bool should checked by jq_btype.awk first
                v = "null"
                exit
            }
            continue
        }

        v = v""chars[i]

        # ignore " in the value
        if(chars[i - 1] == "\\")
            continue
        
        if (chars[i] == "\"") exit
    }
    
    if (v != "") v = v"\n"
}

END { print v }
'
}

_jq_obj() {
    printf "%s" "$1" | awk -v k="$2" \
'
BEGIN { 
    start = -1
    end = -1
    key = "\""k"\""
}

{
    # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html
    if (start == -1) {
        idx = index($0, key)
        if(idx == 0) next
        start = idx + length(key)
    }

    len = length($0)
    split($0, chars, "")
    for (i = start; i <= len; i++) {
        if (v == "") {
            if (chars[i] == "[" || chars[i] == "{") {
                v = chars[i]
                end = 1
            } else if (chars[i] == "n") {
                # null and bool should checked by jq_btype.awk first
                v = "null"
                exit
            }
            continue
        }

        # prevent closing char at next line
        if (end == 0) exit

        v = v""chars[i]
        
        # ignore ]/} in a str
        if(chars[i - 1] == "\\")
            continue

        if (chars[i] == "[" || chars[i] == "{")
            end += 1
        else if (chars[i] == "]" || chars[i] == "}")
            end -= 1
    }

    # an obj can cross lines
    start = 1
    if (v != "") v = v"\n"
}

END { print v }
'
}

_jq_arr_elem() {
    printf "%s" "$1" | awk -v k="$2" \
'
# [0,"",{},[],]
BEGIN { 
    start = -1
    elem_start = -1
    elem_idx = k
}

{
    # https://www.gnu.org/software/gawk/manual/html_node/String-Functions.html
    if (start == -1) {
        if (elem_idx == 0) {
            idx = index($0, "[")
            if(idx == 0) next
            start = idx + 1
        } else {
            idx = 0
            if (elem_start == -1) {
                idx = index($0, "[")
                if(idx == 0) next
                elem_start = 1
            }

            len = length($0)
            split($0, chars, "")
            for (i = idx + 1; i <= len; i++) {
                if (chars[i] == "\"") {
                    if (in_str == 0 ) {
                        in_str = 1
                    } else if (chars[i - 1] != "\\") {
                        in_str = 0
                    }
                    continue
                }

                # ignore closing char in a str
                if (in_str == 1) continue

                # prevent closing char at next line
                if (nested_obj_count == 0 && chars[i] == ",") {
                    comma_count += 1
                    if (comma_count == elem_idx) {
                        start = i + 1
                        break
                    }
                }

                if (chars[i] == "[" || chars[i] == "{")
                    nested_obj_count += 1
                else if (chars[i] == "]" || chars[i] == "}")
                    nested_obj_count -= 1
            }
            
            if (comma_count < elem_idx) next
        }
    }

    len = length($0)
    split($0, chars, "")
    for (i = start; i <= len; i++) {
        if (v == "") {
            if (chars[i] != " ") {
                # null and bool should checked by jq_btype.awk first
                if (chars[i] == "n") {
                    v = "null"
                    exit
                }

                v = chars[i]
                if (chars[i] == "[" || chars[i] == "{")
                    nested_obj_count = 1
            }
            continue
        }

        # prevent closing char at next line
        if (nested_obj_count == 0 &&
            (chars[i] == "," || chars[i] == "]"))
            exit

        v = v""chars[i]
        
        # ignore closing char in a str
        if(chars[i - 1] == "\\")
            continue
        
        if (chars[i] == "[" || chars[i] == "{")
            nested_obj_count += 1
        else if (chars[i] == "]" || chars[i] == "}")
            nested_obj_count -= 1
    }

    # an arr elem can cross lines
    start = 1
    if (v != "") v = v"\n"
}

END { print v }
'
}

jq_strip_quotes() {
    printf "%s" "$1" |
        sed -e 's/^"//' -e 's/"$//'
}

jqv() {
    printf "%s" "$1" |
        jq - "$2" "$3"
}

# jq t.json 'user.events[0]'
# https://jsonformatter.curiousconcept.com
jq() {
    content="$(cat "$1")"
    keys=$(echo "$2" |
        sed -r 's/(.+)\[/\1\.\[/g')

    OLD_IFS=$IFS
    IFS="."
    for k in $keys; do
        k="$(jq_strip_quotes "$k")"
        vt=$(_jq_vtype "$content" "$k")
        case $vt in
        null | 'true' | 'false')
            echo "$vt"
            return
            ;;
        num)
            awk_f="_jq_num"
            ;;
        str)
            awk_f="_jq_str"
            ;;
        obj | arr)
            awk_f="_jq_obj"
            ;;
        arr_elem)
            # shellcheck disable=2034
            awk_f="_jq_arr_elem"
            k="$(echo "$k" |
                sed -r 's/\[(.+?)\]/\1/')"
            ;;
        *) return ;;
        esac
        content="$("$awk_f" "$content" "$k")"
    done
    IFS=$OLD_IFS

    [ "$3" = "-s" ] && {
        jq_strip_quotes "$content"
        return
    }
    # do not use echo
    printf "%s" "$content"
}

# jq "$@"
