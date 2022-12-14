# frozen_string_literal: true

module ::PostVoting
  CREATE_AS_POST_VOTING_DEFAULT = "create_as_post_voting_default"

  class Engine < Rails::Engine
    engine_name 'post_voting'
    isolate_namespace PostVoting
  end
end
