class Build {
    method build($dist-path) {
        chdir 'dan';
        warn ' Building Rust Polars library (may take a few minutes).';
        my $proc = Proc::Async.new: <cargo build>;
        $proc.bind-stdout($*ERR);
        my $promise = $proc.start;
        await $promise;
        
        chdir '..';
        mkdir 'resources';
        mkdir 'resources/libraries';
        move 'dan/target/debug/libdan.so', 'resources/libraries/libdan.so';
        
        mkdir 'resources';
        mkdir 'resources/dan';
        mkdir 'resources/dan/src';
        move 'dan/Cargo.toml', 'resources/dan/Cargo.toml';
        move 'dan/src/lib.rs', 'resources/dan/src/lib.rs';
        move 'dan/src/apply-template.rs', 'resources/dan/src/apply-template.rs';
        
        warn 'Build successful';
        
        exit 0
    }
}
