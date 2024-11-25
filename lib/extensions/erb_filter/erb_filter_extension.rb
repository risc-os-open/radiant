# Radiant ERB (Embedded Ruby) filter
# ==================================
#
# Provides ERB support for Radiant content. For more about Radiant see
# "http://radiantcms.org/".
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

require_dependency 'application_controller'

class ErbFilterExtension < Radiant::Extension
  version "2.0"
  description "Allows the use of ERB within pages, with support for Rails request and session details"
  url "http://pond.org.uk/"

  def activate
    ErbFilter
    Page.send :include, ErbTags
  end
end
