# test/cases/040-inspect.zsh — status, list, info, doctor, profile

t_register case_inspect "inspect: list, status, info, doctor, profile"

case_inspect() {
    run 'plug list'
    has $'\t' && pass 'list is tab-separated when not a tty' \
              || fail 'list is tab-separated when not a tty'

    run 'plug status'
    want 'plug-a'   'status shows the plugins'
    want 'plugins'  'status shows the summary'

    run 'plug info'
    want 'data' 'info shows the paths'

    run 'plug doctor'
    want 'healthy' 'doctor reports a healthy setup'

    run 'plug profile'
    want 'measure startup' 'profile measures startup'
}
