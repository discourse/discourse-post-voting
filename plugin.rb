# frozen_string_literal: true

# name: discourse-post-voting
# about: Allows a topic's post to be voted on
# version: 0.0.1
# authors: Alan Tan
# url: https://github.com/discourse/discourse-post-voting
# transpile_js: true

%i[common mobile desktop].each do |type|
  register_asset "stylesheets/#{type}/post-voting.scss", type
end
register_asset "stylesheets/common/post-voting-crawler.scss"

enabled_site_setting :post_voting_enabled

after_initialize do
  # a bit hacky, but we need this default enabled for tests so
  # fab! calls work, without this we need to amend the boot process
  SiteSetting.post_voting_enabled = true if Rails.env.test?

  %w[
    ../lib/post_voting/engine.rb
    ../lib/post_voting/vote_manager.rb
    ../lib/post_voting/guardian.rb
    ../lib/post_voting/comment_creator.rb
    ../extensions/post_extension.rb
    ../extensions/post_serializer_extension.rb
    ../extensions/topic_extension.rb
    ../extensions/topic_list_item_serializer_extension.rb
    ../extensions/topic_view_serializer_extension.rb
    ../extensions/topic_view_extension.rb
    ../extensions/user_extension.rb
    ../extensions/composer_messages_finder_extension.rb
    ../app/validators/post_voting_comment_validator.rb
    ../app/controllers/post_voting/votes_controller.rb
    ../app/controllers/post_voting/comments_controller.rb
    ../app/models/post_voting_vote.rb
    ../app/models/post_voting_comment.rb
    ../app/serializers/basic_voter_serializer.rb
    ../app/serializers/post_voting_comment_serializer.rb
    ../config/routes.rb
  ].each { |path| load File.expand_path(path, __FILE__) }

  if respond_to?(:register_svg_icon)
    register_svg_icon "angle-up"
    register_svg_icon "info"
  end

  register_post_custom_field_type("vote_history", :json)
  register_post_custom_field_type("vote_count", :integer)

  reloadable_patch do
    Post.include(PostVoting::PostExtension)
    Topic.include(PostVoting::TopicExtension)
    PostSerializer.include(PostVoting::PostSerializerExtension)
    TopicView.prepend(PostVoting::TopicViewExtension)
    TopicViewSerializer.include(PostVoting::TopicViewSerializerExtension)
    TopicListItemSerializer.include(PostVoting::TopicListItemSerializerExtension)
    User.include(PostVoting::UserExtension)
    Guardian.include(PostVoting::Guardian)
    ComposerMessagesFinder.prepend(PostVoting::ComposerMessagesFinderExtension)
  end

  # TODO: Performance of the query degrades as the number of posts a user has voted
  # on increases. We should probably keep a counter cache in the user's
  # custom fields.
  add_to_class(:user, :vote_count) { Post.where(user_id: self.id).sum(:qa_vote_count) }

  add_to_serializer(:user_card, :vote_count) { object.vote_count }

  add_to_class(:topic_view, :user_voted_posts) do |user|
    @user_voted_posts ||= {}

    @user_voted_posts[user.id] ||= begin
      PostVotingVote.where(user: user, post: @posts).distinct.pluck(:post_id)
    end
  end

  add_to_class(:topic_view, :user_voted_posts_last_timestamp) do |user|
    @user_voted_posts_last_timestamp ||= {}

    @user_voted_posts_last_timestamp[user.id] ||= begin
      PostVotingVote
        .where(user: user, post: @posts)
        .group(:votable_id, :created_at)
        .pluck(:votable_id, :created_at)
    end
  end

  TopicView.apply_custom_default_scope do |scope, topic_view|
    if topic_view.topic.is_post_voting? &&
         !topic_view.instance_variable_get(:@replies_to_post_number) &&
         !topic_view.instance_variable_get(:@post_ids)
      scope = scope.where(reply_to_post_number: nil)

      if topic_view.instance_variable_get(:@filter) != TopicView::ACTIVITY_FILTER
        scope =
          scope
            .where.not(post_type: [Post.types[:whisper], Post.types[:small_action]])
            .unscope(:order)
            .order("CASE post_number WHEN 1 THEN 0 ELSE 1 END, qa_vote_count DESC, post_number ASC")
      end

      scope
    else
      scope
    end
  end

  TopicView.on_preload do |topic_view|
    next if !topic_view.topic.is_post_voting?

    post_ids = topic_view.posts.pluck(:id)
    next if post_ids.blank?

    post_ids_sql = post_ids.join(",")

    comment_ids_sql = <<~SQL
    SELECT
      post_voting_comments.id
    FROM post_voting_comments
    INNER JOIN LATERAL (
      SELECT 1
      FROM (
        SELECT
          comments.id
        FROM post_voting_comments comments
        WHERE comments.post_id = post_voting_comments.post_id
        AND comments.deleted_at IS NULL
        ORDER BY comments.id ASC
        LIMIT #{TopicView::PRELOAD_COMMENTS_COUNT}
      ) X
      WHERE X.id = post_voting_comments.id
    ) Y ON true
    WHERE post_voting_comments.post_id IN (#{post_ids_sql})
    AND post_voting_comments.deleted_at IS NULL
    SQL

    topic_view.comments = {}
    PostVotingComment
      .includes(:user)
      .where("id IN (#{comment_ids_sql})")
      .order(id: :asc)
      .each do |comment|
        topic_view.comments[comment.post_id] ||= []
        topic_view.comments[comment.post_id] << comment
      end

    topic_view.comments_counts = PostVotingComment.where(post_id: post_ids).group(:post_id).count

    topic_view.posts_user_voted = {}
    topic_view.comments_user_voted = {}

    if topic_view.guardian.user
      PostVotingVote
        .where(user: topic_view.guardian.user, votable_type: "Post", votable_id: post_ids)
        .pluck(:votable_id, :direction)
        .each { |post_id, direction| topic_view.posts_user_voted[post_id] = direction }

      PostVotingVote
        .joins(
          "INNER JOIN post_voting_comments comments ON comments.id = post_voting_votes.votable_id",
        )
        .where(user: topic_view.guardian.user, votable_type: "PostVotingComment")
        .where("comments.post_id IN (?)", post_ids)
        .pluck(:votable_id)
        .each { |votable_id| topic_view.comments_user_voted[votable_id] = true }
    end

    topic_view.posts_voted_on =
      PostVotingVote.where(votable_type: "Post", votable_id: post_ids).distinct.pluck(:votable_id)
  end

  add_permitted_post_create_param(:create_as_post_voting)

  # TODO: Core should be exposing the following as proper plugin interfaces.
  NewPostManager.add_plugin_payload_attribute(:subtype)
  TopicSubtype.register(Topic::POST_VOTING_SUBTYPE)

  NewPostManager.add_handler do |manager|
    if !manager.args[:topic_id] && manager.args[:create_as_post_voting] == "true" &&
         (manager.args[:archetype].blank? || manager.args[:archetype] == Archetype.default)
      manager.args[:subtype] = Topic::POST_VOTING_SUBTYPE
    end

    false
  end

  register_category_custom_field_type(PostVoting::CREATE_AS_POST_VOTING_DEFAULT, :boolean)
  if Site.respond_to? :preloaded_category_custom_fields
    Site.preloaded_category_custom_fields << PostVoting::CREATE_AS_POST_VOTING_DEFAULT
  end
  add_to_class(:category, :create_as_post_voting_default) do
    ActiveModel::Type::Boolean.new.cast(
      self.custom_fields[PostVoting::CREATE_AS_POST_VOTING_DEFAULT],
    )
  end
  add_to_serializer(:basic_category, :create_as_post_voting_default) do
    object.create_as_post_voting_default
  end

  add_model_callback(:post, :before_create) do
    if SiteSetting.post_voting_enabled && self.is_post_voting_topic? && self.via_email &&
         self.reply_to_post_number == 1
      self.reply_to_post_number = nil
    end
  end

  register_user_destroyer_on_content_deletion_callback(
    Proc.new do |user|
      PostVotingComment.where(user_id: user.id).delete_all
      PostVoting::VoteManager.bulk_remove_votes_by(user)
    end,
  )
end
