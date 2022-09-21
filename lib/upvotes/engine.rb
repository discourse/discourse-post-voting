# frozen_string_literal: true

module ::Upvotes
  CREATE_AS_UPVOTES_DEFAULT = "create_as_qa_default"

  class Engine < Rails::Engine
    engine_name 'upvotes'
    isolate_namespace Upvotes
  end
end
