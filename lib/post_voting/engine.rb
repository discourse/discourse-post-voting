# frozen_string_literal: true

module ::PostVoting
  CREATE_AS_QA_DEFAULT = "create_as_qa_default"

  class Engine < Rails::Engine
    engine_name 'question_answer'
    isolate_namespace PostVoting
  end
end