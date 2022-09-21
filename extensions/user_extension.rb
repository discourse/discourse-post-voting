# frozen_string_literal: true

module Upvotes
  module UserExtension
    def self.included(base)
      base.has_many :question_answer_votes
    end
  end
end
