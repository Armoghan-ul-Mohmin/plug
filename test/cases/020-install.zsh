# test/cases/020-install.zsh — install git, omz:name, omz shorthand, @branch

t_register case_install "install: git, omz shorthand, @branch"

case_install() {
    run 'plug install user1/plug-a user1/plug-b'
    want 'Installed' 'installs git plugins'
    have_dir 'plug-a cloned' "$PLUG_DIR/plugins/user1__plug-a/.git"
    have_dir 'plug-b cloned' "$PLUG_DIR/plugins/user1__plug-b/.git"

    run 'plug install user2/plug-c omz docker'
    want 'Installed' 'installs with the omz shorthand'
    no 'Invalid plugin name: docker' 'omz shorthand is converted mid-args'
    have_dir 'omz:docker installed' "$PLUG_DIR/omz/plugins/docker"

    run 'plug install user1/plug-a@main'
    no 'Invalid plugin name' '@branch is accepted'
    want 'main' 'branch pin is reported'

    run 'plug list'
    want 'plug-a' 'list shows the installed plugin'
    file_has_line 'branches.txt records the pin' "$PLUG_DIR/branches.txt" 'user1/plug-a main'

    run 'plug install'
    want 'Usage' 'install without args shows usage'
}
