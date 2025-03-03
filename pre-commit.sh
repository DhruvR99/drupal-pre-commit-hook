#!/bin/bash

# Redirect output to stderr.
exec 1>&2

# Color codes for the error message.
redclr=$(tput setaf 1)
greenclr=$(tput setaf 2)
blueclr=$(tput setaf 4)
reset=$(tput sgr0)

# Printing the notification in the display screen.
echo  "${blueclr}"
echo "................................. Validating your codes  ……..…………....."
echo "-----------------------------------------------------------${reset}"

# Mentioning the directories which should be excluded.
dir_exclude='\/kint\/|\/contrib\/|\/devel\/|\/libraries\/|\/vendor\/|\.info$|\.png$|\.gif$|\.jpg$|\.ico$|\.patch$|\.htaccess$|\.sh$|\.ttf$|\.woff$|\.eot$|\.svg$'

# Checking for debugging keywords in the committing code base.
keywords=(ddebug_backtrace debug_backtrace dpm print_r var_dump dump console\.log)

keywords_for_grep=$(printf "|%s" "${keywords[@]}")
keywords_for_grep=${keywords_for_grep:1}

# Flags for the counter.
syntax_error_found=0
debugging_function_found=0
merge_conflict=0
coding_standard_error=0

# Checking for PHP syntax errors.
changed_files=$(git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | egrep '\.theme$|\.module$|\.inc|\.php$')
echo "Verify changes ${changed_files}"
if [ -n "$changed_files" ]; then
  for FILE in $changed_files; do
    php -l "$FILE" > /dev/null 2>&1
    compiler_result=$?
    if [ $compiler_result -eq 255 ]; then
      if [ $syntax_error_found -eq 0 ]; then
        echo "${redclr}"
        echo "# Compilation error(s):"
        echo "=========================${reset}"
      fi
      syntax_error_found=1
      php -l "$FILE"
    fi
  done
fi

# Checking for debugging functions.
files_changed=$(git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | egrep -v "$dir_exclude")
if [ -n "$files_changed" ]; then
  for FILE in $files_changed; do
    for keyword in "${keywords[@]}"; do
      pattern="^\+(.*)?$keyword(.*)?"
      resulted_files=$(git diff --cached "$FILE" | egrep -x "$pattern")
      if [ ! -z "$resulted_files" ]; then
        if [ $debugging_function_found -eq 0 ]; then
          echo "${redclr}"
          echo "Validating keywords"
          echo "================================================${reset}"
        fi
        debugging_function_found=1
        echo "Debugging function: $keyword"
        git grep -n "$keyword" "$FILE" | awk -F ':' '{printf "Found in %s on line %s\n", $1, $2}'
      fi
    done
  done
fi

# Check if .ddev directory exists and set prefix accordingly
ddev_prefix=""
if [ -d ".ddev" ]; then
  ddev_prefix="ddev exec "
fi

# Checking for Drupal coding standards.
changed_files=$(git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | egrep -v "$dir_exclude" | egrep '\.php$|\.module$|\.inc$|\.install$|\.test$|\.profile$|\.theme$|\.js$|\.css$|\.info$|\.txt$|\.yml$')
if [ -n "$changed_files" ]; then
  phpcs_result=$(${ddev_prefix}phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme,css,info,txt,md,yml --report=csv $changed_files)
  
  if [[ -n "$phpcs_result" && "$phpcs_result" != "File,Line,Column,Type,Message,Source,Severity,Fixable" ]]; then
    echo "${redclr}"
    echo "# Hey Buddy, The hook found some issue(s)."
    echo "---------------------------------------------------------------------------------------------${reset}"
    ${ddev_prefix}phpcs --standard=Drupal --extensions=php,module,inc,install,test,profile,theme,css,info,txt,md,yml $changed_files
    echo "<=======> Run the command below to fix the issue(s):"
    echo "# ${ddev_prefix}phpcbf --standard=Drupal --extensions=php,module,inc,install,test,profile,theme,css,info,txt,md,yml your_custom_module_or_file_path"
    echo "<====================================================>"
    echo "# To skip the Drupal Coding standard issue(s), use this command: git commit -m 'your commit message' --no-verify"
    echo "-----------------------------------------------------------------------------------------------------------------------------------------${reset}"
    coding_standard_error=1
  fi
fi

# Checking for merge conflict markers.
files_changed=$(git diff-index --diff-filter=ACMRT --cached --name-only HEAD --)
if [ -n "$files_changed" ]; then
  for FILE in $files_changed; do
    resulted_files=$(egrep -in "(<<<<|====|>>>>)" "$FILE")
    if [ ! -z "$resulted_files" ]; then
      if [ $merge_conflict -eq 0 ]; then
        echo "${redclr}"
        echo "-----------------------Unable to commit the file(s):------------------------"
        echo "-----------------------------------${reset}"
      fi
      merge_conflict=1
      echo "$FILE"
    fi
  done
fi

# Printing final result
errors_found=$((syntax_error_found + debugging_function_found + merge_conflict + coding_standard_error))
if [ $errors_found -eq 0 ]; then
  echo "${greenclr}"
  echo "Wow! It is clean code"
  echo "${reset}"
else
  echo "${redclr}"
  echo "Please correct the errors mentioned above. We are aborting your commit."
  echo "${reset}"
  exit 1
fi