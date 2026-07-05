require 'mkmf'

# The native rtsafe solver is optional. If it can't be built — no working C
# compiler, or create_makefile fails — write a do-nothing Makefile so
# `gem install` still succeeds; at runtime the require is rescued and the gem
# falls back to the pure-Ruby solver.
def skip_native(reason)
  warn "xirr: skipping native extension (#{reason}); using pure Ruby."
  File.write('Makefile', "all:\n\t@true\ninstall:\n\t@true\nclean:\n\t@true\n")
  true
end

# try_compile actually exercises the toolchain, which create_makefile does not.
if !try_compile('int main(void){return 0;}')
  skip_native('no working C compiler')
else
  begin
    $CFLAGS << ' -O3'
    create_makefile('xirr/xirr_native')
  rescue StandardError => e
    skip_native(e.message)
  end
end
