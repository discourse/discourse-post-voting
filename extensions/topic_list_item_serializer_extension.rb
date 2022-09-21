# frozen_string_literal: true

module Upvotes
  module TopicListItemSerializerExtension
    def self.included(base)
      base.attributes :is_upvotes
    end

    def is_upvotes
      object.is_upvotes?
    end

    def include_is_upvotes?
      object.is_upvotes?
    end
  end
end
