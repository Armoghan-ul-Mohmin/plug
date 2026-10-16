# test/cases/150-maintenance.zsh — clean, logs, selfupdate

t_register case_maintenance "maintenance: clean, logs, selfupdate"

case_maintenance() {
    run 'plug clean'
    want 'Nothing to clean' 'clean reports a tidy state'

    run 'plug logs clear'
    want 'Log cleared' 'logs clear truncates the log'

    run 'plug logs'
    want 'empty' 'logs reports an empty log after clearing'

    run 'plug selfupdate'
    want 'not inside a git checkout' 'selfupdate explains a non-git install'
}
