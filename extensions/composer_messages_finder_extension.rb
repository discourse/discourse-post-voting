# frozen_string_literal: true

module PostVoting
  module ComposerMessagesFinderExtension
    def check_sequential_replies
      return if @topic.present? && @topic.is_post_voting?
      super
    end
  end
end
