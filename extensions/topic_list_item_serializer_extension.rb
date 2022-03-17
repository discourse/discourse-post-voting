# frozen_string_literal: true

module QuestionAnswer
  module TopicListItemSerializerExtension
    def self.included(base)
      base.attributes :qa_enabled
    end

    def qa_enabled
      object.qa_enabled
    end

    def include_qa_enabled?
      object.qa_enabled
    end
  end
end
