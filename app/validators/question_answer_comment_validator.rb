# frozen_string_literal: true

class QuestionAnswerCommentValidator < ActiveModel::Validator
  def validate(record)
    post_body_validator(record)
  end

  private

  def post_body_validator(record)
    StrippedLengthValidator.validate(
      record, :raw, record.raw, SiteSetting.min_post_length..SiteSetting.qa_comment_max_raw_length
    )
  end
end
