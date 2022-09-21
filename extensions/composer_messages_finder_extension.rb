# frozen_string_literal: true

module Upvotes
  module ComposerMessagesFinderExtension
    def check_sequential_replies
      return if @topic.present? && @topic.is_upvotes?
      super
    end
  end
end
