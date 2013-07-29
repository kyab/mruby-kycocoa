MRuby::Gem::Specification.new('mruby-kycocoa') do |spec|

	spec.license = 'MIT'
 	spec.authors = 'kyab'

 	#note:libffi ship with Mac OSX does not work.
 	MRUBY_KYCOCOA_LIBFFI_LIB_DIR = "/usr/local/opt/libffi/lib"
 	MRUBY_KYCOCOA_LIBFFI_INCLUDE_DIR = "/usr/local/opt/libffi/lib/libffi-3.0.13/include"
 	
 	spec.linker.flags << %W(-framework Foundation)
 	spec.linker.library_paths << MRUBY_KYCOCOA_LIBFFI_LIB_DIR
 	spec.linker.libraries << "ffi"
 	spec.objc.include_paths << MRUBY_KYCOCOA_LIBFFI_INCLUDE_DIR

end

	# /*
	# Generally there are no consequences of this for you. If you build your
	# own software and it requires this formula, you'll need to add to your
	# build variables:

	#     LDFLAGS:  -L/usr/local/opt/libffi/lib
	# */	