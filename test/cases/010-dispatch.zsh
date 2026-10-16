# test/cases/010-dispatch.zsh — version, help, and command dispatch

t_register case_dispatch "version, help, dispatch"

case_dispatch() {
    run 'plug --version'
    want 'plug 1.0.0' 'plug --version prints the version'

    run 'plug help'
    want 'OMZ shorthand' 'help renders'
    want 'plug enable'   'help lists the commands'

    run 'plug frobnicate'
    want 'Unknown command' 'unknown command is reported'
    expect 'unknown command exits non-zero' '[[ $T_RC -ne 0 ]]'
}
