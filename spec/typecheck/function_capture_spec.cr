require "../spec_helper.cr"

describe "Function Captures" do
  # Function captures are actually very simple to type. Since Functors are
  # given their own unique type representation, the only assertion that has
  # to be made is that the value of the capture is indeed a Functor.
  #
  # The resulting type of a function capture is just the functor type being
  # captured.
  it_types %q(
    def foo; end
    &foo
  ), "Functor(foo)"

  # Trying to capture a function that does not exist raises an error.
  it_does_not_type %q(&bar), /no function with the name `bar` exists for type `main`/
  it_does_not_type %q(
    deftype Foo; end
    &Foo.bar
  ), /no function with the name `bar` exists for type `type\(foo\)`/

  # Capturing allows reaching into modules, types, and instances to pull out
  # functions.
  it_types %q(
    defmodule Foo
      def foo; end
    end

    &Foo.foo
  ), "Functor(foo)"

  it_types %q(
    deftype Foo
      defstatic foo; end
    end

    &Foo.foo
  ), "Functor(foo)"

  it_types %q(
    deftype Foo
      def foo; end
    end

    &(%Foo{}.foo)
  ), "Functor(foo)"

  # Captured functions should be directly invocable.
  it_types %q(
    def foo(a, b); b; end
    bar = &foo
    bar(1, 2)
  ), "Integer"

  # Invoking captured functions has the same semantics as calling the
  # function normally, including clause matching.
  it_does_not_type %q(
    def foo(a); end
    bar = &foo
    bar()
  ), /no matching clause/
  it_does_not_type %q(
    def foo(a); end
    bar = &foo
    bar(1, 2)
  ), /no matching clause/

  # Captured functions, when assigned to variables, act just like any other
  # normal variable. Without explicitly writing them as Calls (with
  # parentheses), the functor does not get called.
  it_types %q(
    def foo(a, b); b; end
    bar = &foo
    bar
  ), "Functor(foo)"


  # AnonymousFunctions are similar to FunctionCaptures, where the resulting
  # type is just the full Functor being defined.
  #
  # The name of an AnonymousFunction's Functor type is created using the file
  # location of the definition.
  it_types %q(
    fn ->() { } end
  ), /Functor\(.+foo.mt:2:5\)/, fake_file="foo.mt"

  it_types %q(
    fn
      ->() { }
      ->(a, b) { a + b }
    end
  ), /Functor\(.+foo.mt:2:5\)/, fake_file="foo.mt"


  # Assigning an anonymous function to a variable acts just like a function
  # capture to that variable.
  it_types %q(
    bar = fn ->(a, b) { b } end
    bar(1, 2)
  ), "Integer"

  # Like FunctionCaptures, AnonymousFunctions can be given as regular
  # parameters to functions.
  it_types %q(
    def foo(proc); proc; end
    foo(fn ->() { } end)
  ), /Functor\(.+foo.mt:3:9\)/, fake_file="foo.mt"


  # Block parameters are evaluated at the argument side of a Call. Similar to
  # function captures, the are resolved to a Functor type, but only ever with
  # a single clause as defined by the syntax of blocks. Similar to an
  # AnonymousFunction, the name of the block in the Functor type is defined as
  # the location of the definition.
  it_types %q(
    def foo(&block); block; end
    foo{ 2 }
  ), /Functor\(.+foo.mt:3:8\)/, fake_file="foo.mt"
  it_types %q(
    def foo(&block); block; end
    foo do
      2
    end
  ), /Functor\(.+foo.mt:3:9\)/, fake_file="foo.mt"

  # Calling a function that does not accept a block with a block parameter is
  # considered a non-match.
  it_does_not_type %q(
    def foo(); 1; end
    foo{ 2 }
  ), /no matching clause/
  # The inverse is also true
  it_does_not_type %q(
    def foo(&block); block; end
    foo()
  ), /no matching clause/

  # From within a function, the block becomes a local variable and can be
  # invoked directly, exactly like a captured function.
  it_types %q(
    def foo(&block); block(); end
    foo{ 2 }
  ), "Integer"

  it_types %q(
    def foo(a, b, &block); block(a, b); end
    foo(1, 2){ |a, b| b }
  ), "Integer"


  # FunctionCaptures given as the last argument to a Call are treated as the
  # block parameter for that Call. This works both with capturing normal
  # functions and inlined AnonymousFunctions.
  it_types %q(
    def foo(&block); block; end
    foo(&fn ->() { } end)
  ), /Functor\(.+foo.mt:3:10\)/, fake_file="foo.mt"

  it_types %q(
    def foo(&block); block; end
    foo(&fn
      ->() { }
      ->(a) { a }
    end)
  ), /Functor\(.+foo.mt:3:10\)/, fake_file="foo.mt"

  it_does_not_type %q(
    def foo(); 1; end
    foo(&fn ->() { } end)
  ), /no matching clause/

  it_types %q(
    def foo(&block); block(1); end
    foo(&fn ->(a) { a } end)
  ), "Integer"

  it_types %q(
    def foo(a, b, &block); block(a, b); end
    foo(1, 2, &fn ->(a, b) { b } end)
  ), "Integer"


  it_types %q(
    def foo(&block); block; end
    def bar; 2; end
    foo(&bar)
  ), "Functor(bar)"

  it_does_not_type %q(
    def foo(); 1; end
    def bar; 2; end
    foo(&bar)
  ), /no matching clause/

  it_types %q(
    def foo(&block); block(); end
    def bar; "hello"; end
    foo(&bar)
  ), "String"

  it_types %q(
    def foo(a, b, &block); block(a, b); end
    def bar(a, b); b; end
    foo(1, 2, &bar)
  ), "Integer"

  # Without the explicit, inline function capture, previously-captured
  # functions are always passed as normal parameters.
  it_does_not_type %q(
    def foo(&block); block; end
    def bar; 1; end
    func = &bar
    foo(func)
  ), /no matching clause/

  it_does_not_type %q(
    def foo(&block); block; end
    func = fn ->() { } end
    foo(func)
  ), /no matching clause/

  # With this, multiple procs can be passed in a single Call as normal
  # parameters, rather than as block parameters.
  it_types %q(
    def foo(callback, &block); block(&callback); end
    def bar(&proc); proc(); end
    foo(fn ->() { 1 } end, &bar)
  ), "Integer"
end
