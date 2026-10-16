# test/cases/170-omz.zsh — Oh My Zsh specifics

t_register case_omz "Oh My Zsh specifics"

case_omz() {
    run 'plug install omz:git@feature'
    want 'Cannot pin an Oh My Zsh plugin to a branch' '@branch on an omz plugin warns'

    run 'plug install omz:nope'
    want "has no plugin named 'nope'" 'unknown omz plugin is reported'

    run 'plug list'
    want 'omz:docker' 'omz plugins are listed with the omz: prefix'
}
