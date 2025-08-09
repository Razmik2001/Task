#!/usr/bin/env tclsh
package require fileutil

# Рекурсивный поиск лог-файлов
proc find_log_files {dir} {
    set files {}
    foreach f [fileutil::findByPattern $dir *.log] {
        lappend files $f
    }
    return $files
}

proc only_txt {line keyword} {
    set pos [string first [string tolower $keyword] [string tolower $line]]
    if {$pos == -1} {
        return ""
    }
    set start [expr {$pos + [string length $keyword]}]
    while {$start < [string length $line]} {
        if {[string index $line $start] in { " " ":"} } {
            incr start
        } else {
            break
        }
    }
    return [string range $line $start end]
}

proc parse_log_file {filepath} {
    set errors [dict create]
    set warnings [dict create]
    set infos [dict create]

    set fh [open $filepath r]
    set line_num 0
    while {[gets $fh line] >= 0} {
        incr line_num
        if {[regexp -nocase {error} $line]} {
            dict set errors $line_num [only_txt $line "error"]
        } elseif {[regexp -nocase {warning} $line]} {
            dict set warnings $line_num [only_txt $line "warning"]
        } elseif {[regexp -nocase {info} $line]} {
            dict set infos $line_num [only_txt $line "info"]
        }
    }
    close $fh

    return [dict create Error $errors Warning $warnings Info $infos]
}

proc escape_json_string {str} {
    # Простейшее экранирование кавычек и обратных слэшей
    regsub -all {\\} $str {\\\\} str
    regsub -all {"} $str {\\\"} str
    regsub -all {\n} $str {\\n} str
    return $str
}

proc dict_to_json_string {dictVal} {
    set json "{"
    set firstCategory 1
    foreach {category content} $dictVal {
        if {!$firstCategory} {
            append json ","
        }
        set firstCategory 0
        append json "\"$category\":{"
        
        set firstEntry 1
        foreach {lineNum msg} $content {
            if {!$firstEntry} {
                append json ","
            }
            set firstEntry 0
            set msgEscaped [escape_json_string $msg]
            append json "\"$lineNum\":\"$msgEscaped\""
        }
        append json "}"
    }
    append json "}"
    return $json
}

proc full_result_to_json {fullDict} {
    set json "{"
    set firstFile 1
    foreach {filename categoriesDict} $fullDict {
        if {!$firstFile} {
            append json ","
        }
        set firstFile 0
        append json "\"$filename\":"
        append json [dict_to_json_string $categoriesDict]
    }
    append json "}"
    return $json
}

# Основной код

if {[llength $::argv] == 0} {
    puts "Usage: $argv0 path1 [path2 ...]"
    exit 1
}

set result [dict create]

foreach path $::argv {
    set log_files [find_log_files $path]
    foreach file $log_files {
        dict set result [file tail $file] [parse_log_file $file]
    }
}

set json_output [full_result_to_json $result]

set out [open "output.json" w]
puts $out $json_output
close $out

puts "JSON saved to output.json"
