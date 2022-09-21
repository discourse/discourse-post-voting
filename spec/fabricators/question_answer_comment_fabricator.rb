# frozen_string_literal: true

Fabricator(:upvotes_comment, class_name: :question_answer_comment) do
  user
  post
  raw "Hello world"
end
