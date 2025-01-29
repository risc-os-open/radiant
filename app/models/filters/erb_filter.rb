# Radiant ERB (Embedded Ruby) filter
# ==================================
#
# Provides ERB support for Radiant content. For more about Radiant see
# "http://radiantcms.org/".
#
# The markup filtered herein is processed in the execution context of the
# invoking controller, so you have access to things like Hub view helpers or
# methods such as 'request()'. DO NOT CALL 'render()' however; doing so will
# cause confusion and a Double Render Error exception internally.
#
#
# History
# -------
#
# 2006-07-14 (ADH): Created.
# 2006-07-15 (ADH): Added 'description' field, currently commented out
#                   until wider support in Filters is present.
# 2006-07-25 (ADH): Extended models/behavior.rb to call an extended
#                   filter interface including a hash of instance
#                   variables. Implemented that interface here, using
#                   the ActionView-derived magic first implemented in
#                   the ERB Behavior code to define the hash variables
#                   in the context of the ERB interpreter.
# 2011-03-08 (ADH): Imported into Radiant 0.9.1 as an Extension.
# 2024-12-01 (ADH): Moved into Rails 7 rebuild core.
# 2025-28-01 (ADH): Dramatically simplified; executes ERB code in the calling
#                   controller's binding's context.
#
require 'erb'

class Filters::ErbFilter < ::Filters::TextFilter
  description_file File.dirname(__FILE__) + "/filter_descriptions/erb.html"

  # Options Hash takes a single key ":controller_binding" with a value of
  # the return value of a call to #binding in the invoking controller. This
  # is used as a render context for the ERB template.
  #
  def filter(text, options)
    controller_binding = options[:controller_binding]

    return ERB.new(text).result(controller_binding)
  end
end
