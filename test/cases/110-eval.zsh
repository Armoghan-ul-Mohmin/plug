# test/cases/110-eval.zsh — cached tool initialisers (plug eval)

t_register case_eval "cached tool inits (eval)"

case_eval() {
    run 'plug eval add myeval "echo export MYEVAL=1"'
    want 'Cached' 'eval add caches the output'
    have_file 'eval output file is written' "$PLUG_DIR/evals/myeval.zsh"

    run '[[ -v MYEVAL ]] && echo EVAloaded'
    want 'EVAloaded' 'cached eval is sourced at startup'

    run 'plug eval list'
    want 'myeval' 'eval list shows the entry'

    run 'plug eval refresh myeval'
    want 'Refreshed' 'eval refresh regenerates the output'

    run 'plug eval remove myeval'
    want 'Removed' 'eval remove deletes the entry'

    run 'plug eval add emp "true"'
    want 'Could not run' 'eval rejects empty output'
}
