# test/cases/140-cache.zsh — the generated startup cache

t_register case_cache "startup cache"

case_cache() {
    have_file 'cache.zsh is generated' "$PLUG_DIR/cache.zsh"

    # The cache must source each plugin from its clone path, not from the eval
    # directory. (Regression: ${(qq)VAR/$n.zsh} was mis-parsed by zsh as a
    # pattern substitution and emitted the eval dir instead of dir/name.zsh.)
    run "grep -F 'user1__plug-a' $PLUG_DIR/cache.zsh >/dev/null && echo HASCLONE"
    want 'HASCLONE' 'cache sources the plugin from its clone path'

    run 'plug cache rebuild'
    want 'rebuilt' 'cache rebuild regenerates the cache'

    run 'plug cache show'
    want 'PLUG_LOADED' 'cache show prints the generated script'

    run 'plug cache clear'
    want 'removed' 'cache clear removes the cache'
    absent_file 'cache.zsh is gone after clear' "$PLUG_DIR/cache.zsh"

    run 'plug cache rebuild'
    have_file 'cache is rebuilt after clear' "$PLUG_DIR/cache.zsh"
}
