module KYCocoa

	class CocoaProxy

		def method_missing(name, *args, &block)
			selector_name = name.to_s
			message_args = []
			if (args.size > 0)
				#method(1, :arg1Name, 2, :arg2Name,3) =>method:arg1Name:arg2Name: and [1,2,3]
				selector_name << ":"
				message_args << args[0]

				i = 1
				while i < args.size
					selector_name << args[i].to_s << ":"
					message_args << args[i+1]
					i += 2
				end
			end
			puts "selector name : #{selector_name}"
			puts "args:#{message_args.to_s}"
			do_objc_msgSend(selector_name, message_args)
		end

		alias org_methods methods

		def methods
			objc_methods = objc_instanceMethods
			org_methods + objc_methods
		end

		def is_a?(klass)
			if (klass.class == self.class)
				self.objc_isKindOf(klass)
			else
				super
			end
		end

		def kind_of?(klass)
			is_a?(klass)
		end


		def [](index)
			if(self.objc_isKindOf(NSArray))
				self.objectAtIndex(index)
			else
				super
			end
		end

		def inspect
			description# + "(#{super.inspect})"
		end

		def to_s
			description
		end
	end

	class Pointer
	end
end

