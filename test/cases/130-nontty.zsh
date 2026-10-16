# test/cases/130-nontty.zsh — non-interactive safety (piping, no tty)

t_register case_nontty "non-tty safety"

case_nontty() {
    # Each of these is piped through `run`, so stdout is never a tty.
    run 'plug list | cat'
    want 'plug-a' 'list pipes cleanly'

    run 'plug status | cat'
    want 'plugins' 'status pipes cleanly'

    run 'plug help | cat'
    want 'plug' 'help pipes cleanly'

    run 'plug --version | cat'
    want '1.0.0' 'version pipes cleanly'
}
