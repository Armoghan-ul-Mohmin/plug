# test/cases/120-completion.zsh — managed completions (add / gen / list / remove)

t_register case_completion "managed completions"

case_completion() {
    print -r -- '#compdef faketool' > "$HOME/_faketool"
    run "plug completion add $HOME/_faketool"
    want 'Installed completion' 'completion add copies the file'
    have_file 'completion file is copied' "$PLUG_DIR/completions/_faketool"

    run 'plug completion gen mytool echo "#compdef mytool"'
    want 'Generated' 'completion gen runs the command'
    have_file 'generated completion exists' "$PLUG_DIR/completions/_mytool"

    run 'plug completion list'
    want '_faketool' 'completion list shows added files'
    want '_mytool'   'completion list shows generated files'

    run 'plug completion remove _mytool'
    want 'Removed completion' 'completion remove deletes the file'
}
