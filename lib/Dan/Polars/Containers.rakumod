unit module Dan::Polars::Containers:ver<0.0.3>:auth<Steve Roe (librasteve@furnival.net)>;

use NativeCall;

### Helper Items

my regex number {
	\S+                     #grab chars
	<?{ +"$/" ~~ Real }>    #assert coerces via '+' to Real
}

sub carray( $dtype, @items ) {
    my $output := CArray[$dtype].new();
    loop ( my $i = 0; $i < @items; $i++ ) {
        $output[$i] = @items[$i]
    }
    $output
}

### Container Classes (CStruct) that interface to Rust lib.rs ###

# export DEVMODE=1 and manual cargo build for dev
constant $n-path = ?%*ENV<DEVMODE> ?? '../dan/target/debug/dan' !! %?RESOURCES<libraries/dan>;

class SeriesC is repr('CPointer') is export {
    sub se_new_bool(Str, CArray[bool], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_i32(Str, CArray[int32], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_i64(Str, CArray[int64], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_u32(Str, CArray[uint32],size_t) returns SeriesC is native($n-path) { * }
    sub se_new_u64(Str, CArray[uint64],size_t) returns SeriesC is native($n-path) { * }
    sub se_new_f32(Str, CArray[num32], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_f64(Str, CArray[num64], size_t) returns SeriesC is native($n-path) { * }
    sub se_new_str(Str, CArray[Str],   size_t) returns SeriesC is native($n-path) { * }
    sub se_free(SeriesC)   is native($n-path) { * }
    sub se_show(SeriesC)   is native($n-path) { * }
    sub se_head(SeriesC)   is native($n-path) { * }
    sub se_dtype(SeriesC,  &callback (Str --> Str)) is native($n-path) { * }
    sub se_name(SeriesC,   &callback (Str --> Str)) is native($n-path) { * }
    sub se_rename(SeriesC, Str)                returns SeriesC is native($n-path) { * }
    sub se_len(SeriesC)                        returns uint32 is native($n-path) { * }
    sub se_get_bool(SeriesC, CArray[bool], size_t) is native($n-path) { * }
    sub se_get_i32(SeriesC, CArray[int32], size_t) is native($n-path) { * }
    sub se_get_i64(SeriesC, CArray[int64], size_t) is native($n-path) { * }
    sub se_get_u32(SeriesC, CArray[uint32],size_t) is native($n-path) { * }
    sub se_get_u64(SeriesC, CArray[uint64],size_t) is native($n-path) { * }
    sub se_get_f32(SeriesC, CArray[num32], size_t) is native($n-path) { * }
    sub se_get_f64(SeriesC, CArray[num64], size_t) is native($n-path) { * }
    sub se_get_u8(SeriesC, CArray[uint8], size_t) is native($n-path) { * }
    sub se_str_lengths(SeriesC)                returns uint32 is native($n-path) { * }
    sub se_append(SeriesC, SeriesC)            returns SeriesC is native($n-path) { * }

    method new( $name, @data, :$dtype ) {

        if $dtype {

            @data.map({ $_ .= Num if $_ ~~ Rat});                                               #Coerce stray Rats to Num
            @data.map({ $_ .= Num if $_ ~~ Int}) if $dtype eq <f32 f64 num32 num64 Num>.any;    #Coerce stray Ints to Num

            given $dtype {
                when    'i32' { se_new_i32($name, carray( int32, @data), @data.elems) }
                when    'u32' { se_new_u32($name, carray(uint32, @data), @data.elems) }
                when    'i64' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when    'u64' { se_new_u64($name, carray(uint64, @data), @data.elems) }
                when    'f32' { se_new_f32($name, carray( num32, @data), @data.elems) }
                when    'f64' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when  'int32' { se_new_i32($name, carray( int32, @data), @data.elems) }
                when 'uint32' { se_new_u32($name, carray(uint32, @data), @data.elems) }
                when  'int64' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when 'uint64' { se_new_u64($name, carray(uint64, @data), @data.elems) }
                when  'num32' { se_new_f32($name, carray( num32, @data), @data.elems) }
                when  'num64' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when    'str' { se_new_str($name, carray(   Str, @data), @data.elems) }
                when    'Str' { se_new_str($name, carray(   Str, @data), @data.elems) }
                when   'bool' { se_new_bool($name, carray( bool, @data), @data.elems) }
                when   'Bool' { se_new_bool($name, carray( bool, @data), @data.elems) }
                when    'Int' { se_new_i64($name, carray( int64, @data), @data.elems) }
                when    'Num' { se_new_f64($name, carray( num64, @data), @data.elems) }
                when    'Rat' { die "Rats are not implemented by Polars" }
                when   'Real' { die "Rats are not implemented by Polars" }
            }

        } else {

            given @data.are {
                when Bool {   
                    se_new_bool($name, carray(bool, @data), @data.elems );
                }
                when Int {
                    given @data.min, @data.max {
                        when * > -2**31, * < 2**31-1 { se_new_i32($name, carray( int32, @data), @data.elems) }
                        when * >      0, * < 2**32-1 { se_new_u32($name, carray(uint32, @data), @data.elems) }
                        when * > -2**63, * < 2**63-1 { se_new_i64($name, carray( int64, @data), @data.elems) }
                        when * >      0, * < 2**64-1 { se_new_u64($name, carray(uint64, @data), @data.elems) }
                        default { die "Int larger than 2**64 are not implemented by Polars" }
                    }
                }
                when Real {   
                    @data.map({ $_.=Num }) if @data.are ~~ Real;     #Coerce stray Rats & Ints to Num
                    se_new_f64($name, carray(num64, @data), @data.elems );
                }
                when Str {   
                    se_new_str($name, carray(Str, @data), @data.elems );
                }
            }
        }
    }

    submethod DESTROY {           #Free data when the object is garbage collected.
        se_free(self);
    }

    method show {
        se_show(self)
    }

    method head {
        se_head(self)
    }

    method dtype {
        my $out;
        my &line_out = sub ( $line ) {
            $out := $line
        }

        se_dtype(self, &line_out);
        $out
    }

    method name {
        my $out;
        my &line_out = sub ( $line ) {
            $out := $line
        }

        se_name(self, &line_out);
        $out
    }

    method rename( Str $name ) {
        se_rename(self,$name)
    }

    method len {
        se_len(self)
    }

    method str-lengths {
        se_str_lengths(self)
    }

    # viz. https://docs.raku.org/language/nativecall#Arrays
    method get-data {
        my $elems = self.len;

        given self.dtype {
            when 'bool' {
                my $array := CArray[bool].allocate($elems); 
                se_get_bool(self, $array, $elems);
                $array.list
            }
            when 'i32' {
                my $array := CArray[int32].allocate($elems);
                se_get_i32(self, $array, $elems);
                $array.list
            }
            when 'i64' {
                my $array := CArray[int64].allocate($elems);
                se_get_i64(self, $array, $elems);
                $array.list
            }
            when 'u32' {
                my $array := CArray[uint32].allocate($elems);
                se_get_u32(self, $array, $elems);
                $array.list
            }
            when 'u64' {
                my $array := CArray[uint64].allocate($elems);
                se_get_u64(self, $array, $elems);
                $array.list
            }
            when 'f32' {
                my $array := CArray[num32].allocate($elems);
                se_get_f32(self, $array, $elems);
                $array.list
            }
            when 'f64' {
                my $array := CArray[num64].allocate($elems);
                se_get_f64(self, $array, $elems);
                $array.list
            }
            when 'str' {
                my $chars = self.str-lengths;
                   $chars += ($elems-1) * 3;  #pad for join '","' 
                my $array := CArray[uint8].allocate($chars);

                se_get_u8(self, $array, $chars);
                
                Buf.new($array.list).decode.split('","')
            }
        }
    }

    method append( SeriesC $right ) {
        se_append(self,$right)
    }
}


class DataFrameC is repr('CPointer') is export {
    sub df_new() returns DataFrameC  is native($n-path) { * }
    sub df_free(DataFrameC)          is native($n-path) { * }
    sub df_read_csv(DataFrameC, Str) is native($n-path) { * }
    sub df_show(DataFrameC)          is native($n-path) { * }
    sub df_head(DataFrameC)          is native($n-path) { * }
    sub df_height(DataFrameC) returns uint32 is native($n-path) { * }
    sub df_width(DataFrameC) returns uint32 is native($n-path) { * }
    sub df_dtypes(DataFrameC, &callback (Str)) is native($n-path) { * }
    sub df_get_column_names(DataFrameC, &callback (Str)) is native($n-path) { * }
    sub df_rename(DataFrameC, Str, Str)     returns DataFrameC is native($n-path) { * }
    sub df_column(DataFrameC, Str) returns SeriesC is native($n-path) { * }
    sub df_select(DataFrameC, CArray[Str], size_t) returns DataFrameC is native($n-path) { * }
    sub df_with_column(DataFrameC, SeriesC) returns DataFrameC is native($n-path) { * }
    sub df_drop(DataFrameC, Str) returns DataFrameC is native($n-path) { * }
    sub df_vstack(DataFrameC, DataFrameC) returns DataFrameC is native($n-path) { * }

    method new {
        df_new
    }

    submethod DESTROY {              #Free data when the object is garbage collected.
        df_free(self)
    }

    method read_csv( Str \path ) {
        df_read_csv(self, path)
    }

    method show {
        df_show(self)
    }

    method head {
        df_head(self)
    }

    method height {
        df_height(self)
    }

    method width {
        df_width(self)
    }

    method dtypes {
        my @out;
        my &line_out = sub ( $line ) {
            @out.push: $line;
        }

        df_dtypes(self, &line_out);
        @out
    }

    method get_column_names {
        my @out;
        my &line_out = sub ( $line ) {
            @out.push: $line;
        }

        df_get_column_names(self, &line_out);
        @out
    }

    method rename( Str \old_name, Str \new_name --> DataFrameC) {
        df_rename(self, old_name, new_name)
    }

    method column( Str \colname --> SeriesC ) {
        df_column(self, colname)
    }

    method select( Array \colspec ) {
        df_select(self, carray( Str, colspec ), colspec.elems)
    }

    method with_column( SeriesC \column ) {
        df_with_column(self, column)
    }

    method drop( Str \colname --> DataFrameC ) {
        df_drop(self, colname)
    }

    method vstack( DataFrameC \right --> DataFrameC ) {
        df_vstack(self, right)
    }
}

class LazyFrameC is repr('CPointer') is export {
    sub lf_new(DataFrameC)         returns LazyFrameC  is native($n-path) { * }
    sub lf_free(LazyFrameC)                            is native($n-path) { * }
    sub lf_select(LazyFrameC, CArray[Pointer], size_t) is native($n-path) { * }
    sub lf_with_columns(LazyFrameC, CArray[Pointer], size_t) is native($n-path) { * }
    sub lf_groupby(LazyFrameC, CArray[Str], size_t)    is native($n-path) { * }
    sub lf_agg(LazyFrameC, CArray[Pointer], size_t)    is native($n-path) { * }
    sub lf_collect(LazyFrameC)     returns DataFrameC  is native($n-path) { * }
    sub lf_join(LazyFrameC, LazyFrameC, CArray[Pointer], size_t, CArray[Pointer], size_t, Str) 
                                   returns DataFrameC  is native($n-path) { * }

    method new( DataFrameC \df_c ) {
        lf_new( df_c )
    }

    submethod DESTROY {              #Free data when the object is garbage collected.
        lf_free(self);
    }

    method select( Array \exprvec ) {
        lf_select(self, carray( Pointer, exprvec ), exprvec.elems)
    }

    method with_columns( Array \exprvec ) {
        lf_with_columns(self, carray( Pointer, exprvec ), exprvec.elems)
    }

    method groupby( Array \colspec ) {
        lf_groupby(self, carray( Str, colspec ), colspec.elems)
    }

    method agg( Array \exprvec ) {
        lf_agg(self, carray( Pointer, exprvec ), exprvec.elems)
    }

    method collect {
        lf_collect(self)
    }

    method join( LazyFrameC \right, Array \l_colvec, Array \r_colvec, Str \jointype --> DataFrameC ) {
        lf_join(self, right, carray( Pointer, l_colvec ), l_colvec.elems, 
                             carray( Pointer, r_colvec ), r_colvec.elems, jointype)
    }
}

class ExprC is repr('CPointer') is export {
    sub ex_new()                 returns ExprC is native($n-path) { * }
    sub ex_free(ExprC)                         is native($n-path) { * }
    sub ex_col(Str)              returns ExprC is native($n-path) { * }
    sub ex_lit_bool(bool)        returns ExprC is native($n-path) { * }
    sub ex_lit_i32(int32)        returns ExprC is native($n-path) { * }
    sub ex_lit_i64(int64)        returns ExprC is native($n-path) { * }
    sub ex_lit_u32(uint32)       returns ExprC is native($n-path) { * }
    sub ex_lit_u64(uint64)       returns ExprC is native($n-path) { * }
    sub ex_lit_f32(num32)        returns ExprC is native($n-path) { * }
    sub ex_lit_f64(num64)        returns ExprC is native($n-path) { * }
    sub ex_lit_str(Str)          returns ExprC is native($n-path) { * }
    sub ex_alias(ExprC,Str)      returns ExprC is native($n-path) { * }
    ##sub ex_as_struct(ExprC)      returns ExprC is native($n-path) { * }   <-- iamerejh need to seng Array[ExprC] as_struct(&[col("keys"), col("values")])
    sub ex_sum(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_mean(ExprC)           returns ExprC is native($n-path) { * }
    sub ex_min(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_max(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_first(ExprC)          returns ExprC is native($n-path) { * }
    sub ex_last(ExprC)           returns ExprC is native($n-path) { * }
    sub ex_unique(ExprC)         returns ExprC is native($n-path) { * }
    sub ex_count(ExprC)          returns ExprC is native($n-path) { * }
    sub ex_forward_fill(ExprC)   returns ExprC is native($n-path) { * }
    sub ex_backward_fill(ExprC)  returns ExprC is native($n-path) { * }
    sub ex_reverse(ExprC)        returns ExprC is native($n-path) { * }
    sub ex_sort(ExprC)           returns ExprC is native($n-path) { * }
    sub ex_std(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_var(ExprC)            returns ExprC is native($n-path) { * }
    sub ex_exclude(ExprC,CArray[Str], size_t) returns ExprC is native($n-path) { * }
    sub ex__add__(ExprC, ExprC)  returns ExprC is native($n-path) { * }
    sub ex__sub__(ExprC, ExprC)  returns ExprC is native($n-path) { * }
    sub ex__mul__(ExprC, ExprC)  returns ExprC is native($n-path) { * }
    sub ex__div__(ExprC, ExprC)  returns ExprC is native($n-path) { * }
    sub ex__mod__(ExprC, ExprC)  returns ExprC is native($n-path) { * }
    sub ex__floordiv__(ExprC, ExprC)  returns ExprC is native($n-path) { * }

    method new {
        ex_new
    }

    submethod DESTROY {              #Free data when the object is garbage collected.
        ex_free(self)
    }

    method col( Str \colname ) {
        ex_col(colname)
    }

    method lit( \value, :$dtype ) {
        if $dtype {
            given $dtype {
                when    'i32' { ex_lit_i32(value) }
                when    'i64' { ex_lit_i64(value) }
                when    'u32' { ex_lit_u32(value) }
                when    'u64' { ex_lit_u64(value) }
                when    'f32' { ex_lit_f32(value) }
                when    'f64' { ex_lit_f64(value) }
                when  'int32' { ex_lit_i32(value) }
                when  'int64' { ex_lit_i64(value) }
                when 'uint32' { ex_lit_u32(value) }
                when 'uint64' { ex_lit_u64(value) }
                when  'num32' { ex_lit_f32(value) }
                when  'num64' { ex_lit_f64(value) }
                when    'str' { ex_lit_str(value) }
                when    'Str' { ex_lit_str(value) }
                when   'bool' { ex_lit_bool(value) }
                when   'Bool' { ex_lit_bool(value) }
                when    'Int' { ex_lit_u64(value) }
                when    'Num' { ex_lit_f64(value) }
                when    'Rat' { ex_lit_f64(value.Num) }
                when   'Real' { ex_lit_f64(value.Num) }
            }
        } else {
            given value {
                when   Bool { ex_lit_bool(value) }
                when    Int { ex_lit_u64(value) }
                when    Num { ex_lit_f64(value) }
                when    Rat { ex_lit_f64(value.Num) }
                when   Real { ex_lit_f64(value.Num) }
                when    Str { ex_lit_str(value) }
            }
        }
    }

    method alias( Str \colname ) {
        ex_alias(self, colname)
    }

    method sum {
        ex_sum(self)
    }

    method mean {
        ex_mean(self)
    }

    method min {
        ex_min(self)
    }

    method max {
        ex_max(self)
    }

    method first {
        ex_first(self)
    }

    method last {
        ex_last(self)
    }

    method unique {
        ex_unique(self)
    }

    method count {
        ex_count(self)
    }

    method elems {
        ex_count(self)
    }

    method forward_fill {
        ex_forward_fill(self)
    }

    method backward_fill {
        ex_backward_fill(self)
    }

    method reverse {
        ex_reverse(self)
    }

    method sort {
        ex_sort(self)
    }

    method std {
        ex_std(self)
    }

    method var {
        ex_var(self)
    }

    method exclude( Array \colspec ) {
        ex_exclude(self, carray( Str, colspec ), colspec.elems)
    }

    method __add__( ExprC \rhs ) {
        ex__add__(self, rhs)
    }

    method __sub__( ExprC \rhs ) {
        ex__sub__(self, rhs)
    }

    method __mul__( ExprC \rhs ) {
        ex__mul__(self, rhs)
    }

    method __div__( ExprC \rhs ) {
        ex__div__(self, rhs)
    }

    method __mod__( ExprC \rhs ) {
        ex__mod__(self, rhs)
    }

    method __floordiv__( ExprC \rhs ) {
        ex__floordiv__(self, rhs)
    }

    ### APPLY ###

    # apply() is exported directly into client script and acts on the ExprC made by col()
    # its argument is a string in the form of a Rust lambda with |signature| (body) as rtn-type
    # the lambda takes variable 'a: type' if monadic or 'a: type, b: type' if dyadic' 
    # the body is a valid Rust expression 

#`[
dfa.select([col("nrs").apply("|a: i32| (a + 1) as i32").alias("jones")]).head;
--- ------  ---------- ---------- --------------   ----
 |     |        |          |           |             -> method head prints top lines of result
 |     |        |          |           |
 |     |        |          |           -> method alias returns a new Expr
 |     |        |          |
 |     |        |          -> method apply returns a new Expr
 |     |        |
 |     |        -> method col(Str \colname) returns a new (empty) Expr
 |     |
 |     -> method select(Array \exprs) creates a LazyFrame, calls .select(exprs) then .collect
 |
 |
 -> DataFrame object with attributes of pointers to rust DataFrame and LazyFrame structures
 #]

    constant $a-path = ?%*ENV<DEVMODE> ?? '../dan/src/apply' !! %?RESOURCES<libraries/dan>;

    # monadic-real: '|a: i32| (a + 1) as i32'
    sub ap_apply_mr(ExprC) returns ExprC is native($a-path) { * }
    # dyadic-real: '|a: i32, b: i32| (a + b) as i32'
    sub ap_apply_dr(ExprC) returns ExprC is native($a-path) { * }


    method apply( $lambda ) {

        say "lambda is $lambda";

        #viz.https://docs.rs/polars/latest/polars/chunked_array/object/datatypes/index.html#types
        my @types  = <bool      i32   i64    u32    u64     f32     f64 str>;
        my @dtypes = <Boolean Int32 Int64 UInt32 UInt64 Float32 Float64 Utf8>;
        my %type-map = @types Z=> @dtypes;

        use Grammar::Tracer;

        my grammar Lambda {
            token  TOP       { <signature> <body> ' as ' <r-type> }
            rule  signature { '|a:' <a-type> '|' }
            token body      { '(' .*? ')' <?before ' as '> }
            token a-type    { @types }
            token r-type    { @types }
        }

        class Lambda-actions {
           # method body($/) { make 'yo' }  ## not needed
        }

        my $match = Lambda.parse($lambda, actions => Lambda-actions.new);

        my $a-type = $match<signature><a-type>;
        my $d-type = %type-map{$match<r-type>};

        my $pattern = 'mr';

        say "building libapply.so...";

        my $apply-lib = '../dan/src/apply-template.rs'.IO.slurp;

        $apply-lib ~~ s:g|'%ATYPE%'|$a-type|;
        $apply-lib ~~ s:g|'%BODY%' |$match<body>|;
        $apply-lib ~~ s:g|'%RTYPE%'|$match<r-type>|;
        $apply-lib ~~ s:g|'%DTYPE%'|$d-type|;

        #say $apply-lib;    #debug

        chdir '../dan/src';
        spurt 'apply.rs', $apply-lib;

        say qqx`rm libapply.so`;
        say qqx`rustc -L ../target/debug/deps --crate-type cdylib apply.rs`;

        chdir '../../bin';
        sleep 2;            #ubuntu needs to breathe (something to do with so refresh?)

        given $pattern {
            when 'mr' { 
                ap_apply_mr(self)
            }

        }

    }
}

