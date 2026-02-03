# ~/.config/fish/config.fish
# --- Safe, guarded fish config derived from your original ---

# Ensure core PATH includes user bins first, then system bins.
# (Put user bins earlier so custom commands override system ones if needed.)
set -gx PATH $HOME/.cargo/bin $HOME/.local/bin $HOME/.lmstudio/bin $PATH /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin

# --------------------
if not status is-interactive
    exit
end

# starship prompt (only if installed)
if type -q starship
    starship init fish | source
end

# Interactive session guards
if status is-interactive
    set -g fish_greeting ""
end

# Show sequences file only if present and readable (and not in VS Code)
if test -f $HOME/.local/state/quickshell/user/generated/terminal/sequences.txt -a -r $HOME/.local/state/quickshell/user/generated/terminal/sequences.txt
    # avoid spamming VS Code integrated terminal
    if not set -q VSCODE_PID
        cat $HOME/.local/state/quickshell/user/generated/terminal/sequences.txt
    end
end

# Aliases (kept)
alias pamcan pacman
alias pac pacman
alias ls 'eza --icons'

# Safe "clear" that shows image only when kitty is available and not in VS Code
function show_image_and_clear
    # Use tput only if available
    if type -q tput
        tput reset 2>/dev/null
    else
        # fallback: clear terminal the "dumb" way
        printf '\033c'
    end

    # Display the image only if kitty is installed and we are in a real terminal (not VS Code)
    #if type -q kitty -a not set -q VSCODE_PID
    # guard the file exists
    #   if test -f $HOME/.config/fish/mai_resized.jpg
    #   # ignore kitty errors
    #   kitty icat --align=left $HOME/.config/fish/mai_resized.jpg 2>/dev/null || true
    #end
    #end

    # Reset terminal attributes if tput exists
    if type -q tput
        tput sgr0 2>/dev/null
    end

    printf '\n'
end

# alias clear calls the above function in a guarded way
alias clear show_image_and_clear

# quick alias
alias q 'qs -c ii'

# Environment variables
set -gx EDITOR code
set -gx VISUAL code
set -gx BROWSER firefox

# fastfetch (only if installed and interactive and not in VS Code)
# --- guarded fastfetch: runs only in real interactive terminals (not VS Code) ---
if status is-interactive
    # ensure we are a proper TTY (not a headless or weird pseudo terminal)
    if test -t 1
        # avoid running inside VS Code by checking multiple indicators (VSCODE_PID and TERM_PROGRAM)
        if not set -q VSCODE_PID; and not set -q TERM_PROGRAM; or test "$TERM_PROGRAM" != vscode
            # run fastfetch only if it's installed
            if type -q fastfetch
                fastfetch 2>/dev/null || true
            end
        end
    end
end

# Make lineno/other functions safe
function linoffice
    if test -x $HOME/.local/bin/linoffice/linoffice.sh
        $HOME/.local/bin/linoffice/linoffice.sh $argv
    else
        echo "linoffice not found"
    end
end

# Friendly "command not found" handler (kept)
function fish_command_not_found
    set_color red
    echo "Oops, you entered the wrong command!"
    set_color normal
    echo "fish: Unknown command: $argv"
end

# --- safe uname usage if any prompt code expects it ---
if type -q uname
    set -g __fish_uname (uname)
end

# End of config

# pnpm
set -gx PNPM_HOME "/home/zoro/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
