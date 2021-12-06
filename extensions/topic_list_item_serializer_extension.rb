# frozen_string_literal: true

module QuestionAnswer
  module TopicListItemSerializerExtension
    def self.included(base)
      base.attributes :qa_enabled,
                      :answer_count
    end

    def qa_enabled
      true
    end

    def include_qa_enabled?
      object.qa_enabled
    end

    def answer_count
      object.answer_count
    end

    def include_answer_count?
      include_qa_enabled?
    end

    # For Q&A topics, we always want to link to the first post because timeline
    # ordering is not consistent with last unread.
    def last_read_post_number
      return nil if include_qa_enabled?
      super
    end

    def include_last_read_post_number?
      if include_qa_enabled?
        true
      else
        super
      end
    end
  end
end
